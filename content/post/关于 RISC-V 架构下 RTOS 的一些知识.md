---
title: 关于 RISC-V 架构下 RTOS 的一些知识
tags:
  - RISC-V
  - IC Design
  - wujian100
  - RTOS
categories:
  - IC Design
  - RISC-V
  - 嵌入式
date: 2020-04-07
---

## 0x00
之前的 blog 有介绍了一些，wujian100 的一些知识，包括综合、测试等。最近就想在 wujian100 上看看能不能移植一下比较常见的一些 `RTOS` (**Real Time Operating System,实时操作系统**)上去试试，比如 Free RTOS、RT-Thread等。结果发现这里还是有一些坑的。虽然 FreeRTOS 和 RTT 都支持 RISC-V 的芯片了，但是 wujian100 这个是 RISC-V “E” 基础架构，也就是 RV32E 就是 标准嵌入式扩展 指令集（这个版本降低了核心的开销，CPU 寄存器裁剪了一半，为 16 个）。但是 FreeRTOS 和 RTT 目前支持的版本都是 32 个寄存器的，对于任务或者说线程的上下文切换时对栈帧的操作还是有一些差异。然后呢也想对比一下 ARM 架构和 RISC-V 架构下嵌入式实时操作系统处理的一些区别，这里呢就想做一些的简单记录。

## ARM 和 RISC-V 架构的区别
由于我是先学的 ARM 也相对了解一些，所以做什么总是想拿来和 ARM 对比一下，看看能不能套在 ARM 上，这也对自己理解也有一些帮助。缺点就是会产生一些先入为主的观念。

一个最简单的 RTOS 应该至少要实现一个多任务管理的功能，所以 RTOS 也可以叫实时多任务操作系统。那么一个简单的 RTOS 的核心就是怎么处理多任务或者说多线程之间的切换，这里我们也叫做上下文切换，所以上下文切换机制的实现就非常重要，这就要牵扯到不同架构的 CPU 会有不同的处理方式。

## ARM 架构下 RTOS 的一般处理过程
这里以 Cortex-M3 为例，在 ARM 架构中有一组 `特殊功能寄存器组`，很多时候就是专门留给 OS 使用的。其中由 `CONTROL[0:1]` 寄存器来定义 CPU 的特权等级。这里就要提到在 ARM 架构中的双堆栈机制，在 CM3 内核中支持两个堆栈，一个是 MSP（主堆栈指针）指向的主堆栈和 PSP（线程堆栈指针）指向的线程堆栈。通过配置 CONTROL 寄存器的两个位来选择特权级别和使用不同的堆栈指针（还有一个骚操作就是从异常返回时修改 LR 的 bit1 和 bit2 也可以切换模式和堆栈，我们可以在很多开源的 RTOS 中见到）。这样通过这两个寄存器的配置就可以分开对待用户程序和系统程序，避免因用户级程序的问题对系统造成危害。同时在出入异常处理时这两个堆栈指针是通过硬件自动切换的，对于现场的保存就不需要软件来处理了。而且在 Handler 或者说异常中只能使用 MSP（主堆栈指针）。

|CONTROL[0]	| CONTROL[1] |	组合  | 模式 |
| --------- | ---------- | ------ | ---- |
|特权选择	 | 堆栈指针选择 |      |      |
|0	|0	|特权级+MSP	|Handler 模式和 Kernel(OS) |
|0	|1	|特权级+PSP	|线程模式  |
|1	|0	|用户级+MSP	|错误用法  |
|1	|1	|用户级+PSP	|线程模式  |

由于有了这样的机制，在 RTOS 中对于任务切换就带来了很多便利，通常情况下都是通过 SVCall(即 SVC，System service Call,系统服务调用)和 PendSV(Pendable request for system serivce,可挂起系统调用)这两个异常来完成系统特权和任务上下文的切换。当然也可以先不考虑特权模式和用户模式，那么就可以仅通过 PendSV 异常来完成任务上下文切换即可。这里可以参考一下 FreeRTOS 的处理代码：

```c
// SVCHandler 进行任务切换
__asm void vPortSVCHandler( void )
{
    extern pxCurrentTCB;    // 外部参数，当前任务控制块指针

    PRESERVE8

    ldr r3, = pxCurrentTCB  // 加载 pxCurrentTCB 的地址到 r3
    ldr r1, [r3]            // 加载 pxCurrentTCB 到 r1
    ldr r0, [r1]            // 加载 pxCurrentTCB 指向的值到 r0, 即当前第一个任务的任务栈栈顶指针
    ldmia r0!, {r4-r11}     // 以 r0 为基地址，将栈里面的内容加载到 r4-r11 寄存器，同时 r0 会递增
    msr psp, r0             // 将 r0 的值，即任务栈指针更新到 psp
    isb
    mov r0, #0              // 将 r0 的值，设置为 0
    msr basepri, r0         // 将 basepri 寄存器设置为0，即所有的中断都没有被屏蔽

    //骚操作
    orr r14, #0x0d          // 当从 SVC 中断服务退出前，通过向 R14 最后4位按位或上0x0d,
                            // 使得硬件在退出时，使用进程堆栈指针 PSP 完成出栈操作并返回后进入线程模式、返回 Thumb 状态
                            //  r14 的 bit1 : 0 PSP 1 MSP；bit2: 0 特权模式  1 用户模式

    bx r14                  // 异常返回，这个时候栈中的剩下内容将会自动加载到 CPU 寄存器
                            // xPSR,PC(任务入口地址),R14,R12,R3,R2,R1,R0(任务形参) 同时 PSP 的值也将更新，即指向任务栈的栈顶
}
```

```c
__asm void xPortPendSVHandler(void)
{
    extern pxCurrentTCB;        // 外部参数，当前任务控制块指针
    extern vTaskSwitchContext;  // 外部函数，当前任务切换函数

    PRESERVE8

    // 当进入 PendSVC Handler 时，上一个任务运行环境，即：
    // xPSR,PC(任务入口地址),R14,R12,R3,R2,R1,R0(任务形参),这些将自动保存到任务栈中，剩下的r4-r11需要手动保存
    // 获取任务栈指针到 r0
    mrs r0, psp
    isb

    ldr r3, =pxCurrentTCB   // 加载 pxCurrentTCB 的地址到 r3
    ldr r2, [r3]            // 加载 pxCurrentTCB 到 r2

    stmdb r0!, {r4-r11}     // 将 CPU 寄存器 r4-r11 的值存储到 r0 指向的地址
    str r0, [r2]            // 将任务栈的新的栈顶指针存储到当前任务TCB的第一个成员，即栈顶指针

    stmdb sp!,{r3,r14}      // 将 r3 和 r14 临时压入堆栈，因为即将调用函数
                            // 调用函数时，返回地址自动保存到 r14 中，导致 r14 的值会被覆盖，所以 r14 的值需要入栈保护
                            // r3 保存的当前激活的任务 TCB 指针( pxCurrentTCB ),函数调用后会用到，因此也需要入栈保护

    mov r0, #configMAX_SYSCALL_INTERRUPT_PRIORITY    // 进入临界段
    msr basepri, r0         // 屏蔽所有中断
    dsb
    isb
    bl vTaskSwitchContext   // 调用函数 vTaskSwitchContext，寻找新的任务运行，通过使变量 pxCurrentTCB 指向新的任务来实现任务切换
    mov r0, #0              // 退出临界段
    msr basepri, r0
    ldmia sp!, {r3,r14}     // 恢复 r3, r14

    ldr r1, [r3]
    ldr r0, [r1]            // 当前激活的任务 TCB 第一项保存了任务堆栈的栈顶指针，现在栈顶值存入了 r0
    ldmia r0!,{r4-r11}      // 出栈
    msr psp, r0
    isb
    bx r14                  // 异常发生时，R14 中保存异常返回标志，包括返回后进入线程模式还是处理器模式
                            // 使用 psp 堆栈指针还是 msp 堆栈指针，当调用 bx r14 指令后，硬件会知道要从硬件返回
                            // 然后出栈，这个时候堆栈指针 psp 硬件指向了 新任务堆栈的正确位置
                            // 当新任务的运行地址被出栈到 pc 寄存器后，新的任务也会被执行
    nop
}
```

这两个汇编函数就完成了 ARM 架构下的任务切换机制。其实对于任务上下文切换就是任务现场的保存和恢复，这个现场就是当前的 CPU 运行状态，也就是 CPU 各个寄存器的状态的保存与恢复。这其中也包括很重要的栈帧切换。当然仅仅靠这两个函数也是不完全可靠的，还有一些临界段的处理函数来共同保证任务的安全切换。

## RISC-V 架构下的 RTOS 一般处理过程
在 RISC-V 架构中，也有不同的特权级别，目前主要定义了三种特权级别，分别是**机器模式（Machine Mode，M-mode）、监管模式（Supervisor Mode,S-mode）和用户模式（User Mode,U-Mode）**， 通过 **CSRs(control and status registers,控制状态寄存器)** 的 *bit11*、*bit12* (即 MPP 位)两个位的不同编码来实现不同特权模式的切换，在不同特权模式下都有单独的 CSRs。这里需要说明的是我这个 MPP 指的是 Machine-Level CSRs 中 mstatus 寄存器（即 M-mode status register）的控制位。

|Level |	MPP[12:11] |模式 |简写 |
|------|-------------|-----|-----|
|0	|0 |0	|User/Application |	U
|1	|0 |1	|Supervisor |	S
|2	|1 |0	|Reserved |（Hypervisor）|	（保留）
|3	|1 |1	|Machine |	M |

但是一个 RISC-V 处理器的实现并不要求同时支持这三种特权级，接受以下的一些实现组合，降低实现成本：

|Number of levels |	Supported Modes |	Intended Usage |
|1	| M	 | Simple embedded systems |
|2	| M,U	| Secure embedded systems |
|3	| M,S,U	| Systems running Unix-like operating systems |

上图中可以看出，这三种模式只有 M-mode 是必须要实现的，其它两种模式是可选的。M-mode 是 RISC-V 中 **hart（hardware thread，硬件线程）**可以执行的最高权限模式。在 M 模式下运行的 hart 对内存，I/O 和一些对于启动和配置系统来说必要的底层功能有着完全的使用权。因此它是唯一所有标准 RISC-V 处理器都必须实现的权限模式。实际上简单的 RISC-V 微控制器仅支持 M 模式。

好了，上面说的是特权模式和 ARM 的区别，下面就是堆栈指针的区别。上文已经提到 ARM 中有 MSP 和 PSP 之分，且在 handler 中只能使用 MSP，也就意味着 OS 和线程模式使用不同的栈。并且出入异常的栈帧切换由硬件完成。

而在 RISC-V 架构处理器中，没有区分异常、中断和线程模式使用的栈帧，在进入和退出中断处理模式时没有硬件自动保存和恢复上下文（通用寄存器）的操作，因此需要软件明确地使用（汇编语言编写的）指令进行上下文的保存和恢复。并且还要区分 ecall（environment call for U/S/M-mode，不同特权模式下的环境调用异常）。

所以 RISC-V 这一块的处理要复杂一些，有大量的 RISC-V 汇编，具体的代码我就不贴了，有兴趣的可以去看一下 FreeRTOS 的源码。链接：[https://github.com/FreeRTOS/FreeRTOS-Kernel/blob/master/portable/GCC/RISC-V/portASM.s](https://github.com/FreeRTOS/FreeRTOS-Kernel/blob/master/portable/GCC/RISC-V/portASM.s)

下表是 RISC-V RV32I 基础指令集寄存器结构，但 RV32E 基础指令集只有 **x0-x15**。

|Register	| ABI Name	| Description	| Saver |
|---|---|---|---|
|x0	|zero	|Hard-wired |zero	|- |
|x1	|ra	|Return |address |	Caller |
|x2	|sp	|Stack |pointer	| Callee |
|x3	|gp	|Global |pointer |	- |
|x4	|tp	|Thread |pointer |	- |
|x5-7|	t0-2	|Temporaries |	Caller |
|x8	|s0/fp |	Saved register/Frame pointer |	Callee |
|x9	|s1	| Saved |register |	Callee
|x10-11	|a0-1	|Function Arguments/return values	| Caller
|x12-17	|a2-7	|Function arguments	| Caller
|x18-27	|s2-11	|Saved registers	| Callee
|x28-31	|t3-6	|Temporaries	| Caller

上表中虽然对各个寄存器有了一些描述，在 RISC-V 指令集中并没有指定专用的堆栈指针或子程序返回地址链接寄存器等，事实上指令编码允许将任何 x 寄存器用于这些目的。 但是，标准软件调用约定使用寄存器 x1 来保存呼叫的返回地址，而寄存器 x5 可用作备用链接寄存器。 标准调用约定使用寄存器 x2 作为堆栈指针。硬件可能会选择加速使用 x1 或 x5 的函数调用和返回。（不知道这段 Google 翻译的描述是否准确，大家可以去阅读《riscv-spec-20191213》的 2.1 节原文参考）

## 在 wujian100 RISC-V 开源平台上实现简单的任务调度系统
在了解了上面的一些区别后，我准备尝试移植 FreeRTOS 或者 RT-Thread 到 wujian100 上试试，但是我发现它们大多是只支持了以 RV32I 为基础指令集的处理器。而 wujian100 是 E902，是 RV32E 基础指令集，在底层汇编的处理上有一些不同，可能还要做一些修改。所以我就想试着把我之前学习 FreeRTOS 时，实现的仅有任务调度功能的极简版 FreeRTOS 放上去试试，因为代码量比较少。

接下来，我就尝试在 wujian100 开源的 SDK 中移花接木，把我自己这个极简的小操作系统移植上去。在仔细翻阅了 wujian 开源的代码后发现他们这里提供了一个 AliOS 的内核，叫 rhino 内核。在他们这个内核的底层是有实现一些上下文切换的代码的，于是我就基于这个底层把我的上层接上去。当然这过程中还要修改很多东西，这里就不一一详述，直接看这段汇编代码是怎么处理的，这里我已经做了一些修改，我的两个小任务也转起来了。

```c
#define MSTATUS_PRV1 0x1880

.global cpu_intrpt_save
.type cpu_intrpt_save, %function
cpu_intrpt_save:
    csrr    a0, mstatus  // 读控制状态寄存器，写入 a0，并返回到 psr 返回值中,psr 是外部定义的一个变量，恢复时会使用
    csrc    mstatus, 8  // 将控制状态寄存器清零。清零对应的标志位，该语句即为清除 MIE ，即禁止全局中断使能。就是禁用中断
    ret

.global cpu_intrpt_restore
.type cpu_intrpt_restore, %function
cpu_intrpt_restore:
    csrw    mstatus, a0   // a0 是传进来的参数，即上一次保存的控制状态寄存器的值，对于 a0 中每一个为 1 的位，把 mstatus 中对应的位进行置位
    ret

.global cpu_task_switch
.type cpu_task_switch, %function
cpu_task_switch:                // 主动任务切换调度
    la     a0, g_intrpt_level_1 // g_intrpt_level_1 是一个全局变量，用于保存当前中断嵌套的层级；这里是将其地址加载到 a0 中
    lb     a0, (a0)             //  将 a0 地址的数据加载到 a0 中
    beqz   a0, __task_switch    // beqz 是对于零时的分支指令，如果等于零，就执行 __task_switch 函数，也就是意味着当前没有中断嵌套

    la     a0, pxCurrentTCB      // 如果不等于零，即有中断嵌套，就进行下面的操作；加载 pxCurrentTCB 的地址到 a0,即获取当前任务指针
    la     a1, g_ReadyTasksLists // 加载 g_ReadyTasksLists 的地址到 a1，即获取当前最高优先级的就绪任务指针
    lw     a2, (a1)  // 加载就绪任务指针到 a2  (lw 指令读取一个字，即4个字节的数据 到 a2
    sw     a2, (a0)  // 将 a2 的低4个字节存储到 a0（即将就绪任务指针放到当前任务）

    ret

.global cpu_intrpt_switch
.type cpu_intrpt_switch, %function
cpu_intrpt_switch:   // 中断中的任务切换 操作和上面类似
    la     a0, pxCurrentTCB
    la     a1, g_ReadyTasksLists
    lw     a2, (a1)
    sw     a2, (a0)

    ret

.global cpu_first_task_start
.type cpu_first_task_start, %function
cpu_first_task_start:      // 第一次进入任务时是不用返回的
    j       __task_switch_nosave

.type __task_switch, %function
__task_switch:    // 任务切换函数
    addi    sp, sp, -60  // 规划保存数据需要的栈帧大小
// 保存现场，将寄存器的数据保存到栈帧中
    sw      x1, 0(sp)
    sw      x3, 4(sp)
    sw      x4, 8(sp)
    sw      x5, 12(sp)
    sw      x6, 16(sp)
    sw      x7, 20(sp)
    sw      x8, 24(sp)
    sw      x9, 28(sp)
    sw      x10, 32(sp)
    sw      x11, 36(sp)
    sw      x12, 40(sp)
    sw      x13, 44(sp)
    sw      x14, 48(sp)
    sw      x15, 52(sp)

    sw      ra, 56(sp)

    la      a1, pxCurrentTCB // 将当前任务控制块指针地址，加载到 a1
    lw      a1, (a1)         // 将任务控制块指针地址加载到 a1
    sw      sp, (a1)         // 将栈指针加载到当前任务控制块指针地址

__task_switch_nosave:        // 第一次进入任务入口，接下来切换任务指针
    la      a0, g_ReadyTasksLists
    la      a1, pxCurrentTCB
    lw      a2, (a0)
    sw      a2, (a1)

    lw      sp, (a2)

    /* Run in machine mode */
    li      t0, MSTATUS_PRV1
    csrs    mstatus, t0  // 将对于 t0 对应为 1 的每一位置位，即 mpp 设置为 11，machine mode 运行；mpie 置位，用于保存发生异常时 mie 的值；即切换到 M-mode

    lw      t0, 56(sp)   // 将 56(sp) 低 4个字节的数据加载到 t0，即返回地址
    csrw    mepc, t0     // 将 t0 写入 mepc  这里需要注意的是，栈区的数据，在任务初始化的时候就要初始化好，包括第一次启动
// 加载栈帧数据
    lw      x1, 0(sp)
    lw      x3, 4(sp)
    lw      x4, 8(sp)
    lw      x5, 12(sp)
    lw      x6, 16(sp)
    lw      x7, 20(sp)
    lw      x8, 24(sp)
    lw      x9, 28(sp)
    lw      x10, 32(sp)
    lw      x11, 36(sp)
    lw      x12, 40(sp)
    lw      x13, 44(sp)
    lw      x14, 48(sp)
    lw      x15, 52(sp)

    addi    sp, sp, 60
    mret   // M-mode 特有指令，返回时将 PC 指针设置为 mepc,将 mpie 复制到 mie 恢复之前的中断设置，并将特权模式设置为 mpp 中的值；这里就可以完成特权模式的切换(M-U or U-M)

.global Default_IRQHandler
.type   Default_IRQHandler, %function
Default_IRQHandler:    // 异常、中断处理，这里也需要保存现场，处理类似
    addi    sp, sp, -60

    sw      x1, 0(sp)
    sw      x3, 4(sp)
    sw      x4, 8(sp)
    sw      x5, 12(sp)
    sw      x6, 16(sp)
    sw      x7, 20(sp)
    sw      x8, 24(sp)
    sw      x9, 28(sp)
    sw      x10, 32(sp)
    sw      x11, 36(sp)
    sw      x12, 40(sp)
    sw      x13, 44(sp)
    sw      x14, 48(sp)
    sw      x15, 52(sp)

    csrr    t0, mepc
    sw      t0, 56(sp)

    la      a0, pxCurrentTCB
    lw      a0, (a0)
    sw      sp, (a0)

    la      sp, g_top_irqstack

    csrr    a0, mcause     // 读取异常类型
    andi    a0, a0, 0x3FF
    slli    a0, a0, 2
// 处理异常
    la      a1, g_irqvector
    add     a1, a1, a0
    lw      a2, (a1)
    jalr    a2
// 退出异常，恢复
    la      a0, pxCurrentTCB
    lw      a0, (a0)
    lw      sp, (a0)

    csrr    a0, mcause
    andi    a0, a0, 0x3FF

    /* clear pending *///清除挂起的异常
    li      a2, 0xE000E100
    add     a2, a2, a0
    lb      a3, 0(a2)
    li      a4, 1
    not     a4, a4
    and     a5, a4, a3
    sb      a5, 0(a2)

    /* Run in machine mode */
    li      t0, MSTATUS_PRV1
    csrs    mstatus, t0

    lw      t0, 56(sp)
    csrw    mepc, t0

    lw      x1, 0(sp)
    lw      x3, 4(sp)
    lw      x4, 8(sp)
    lw      x5, 12(sp)
    lw      x6, 16(sp)
    lw      x7, 20(sp)
    lw      x8, 24(sp)
    lw      x9, 28(sp)
    lw      x10, 32(sp)
    lw      x11, 36(sp)
    lw      x12, 40(sp)
    lw      x13, 44(sp)
    lw      x14, 48(sp)
    lw      x15, 52(sp)

    addi    sp, sp, 60
    mret
```

除了上面的汇编部分，还有几个主要函数如下，代码工程我后面整理好会上传到我的 Github 上。

```c
void TaskSwitching_example(void)
{
    prvInitTaskLists();

    Task1_Handle = xTaskCreateStatic(  Task1_Entry,
                                       "Task1_Entry",
                                       TASK1_STACK_SIZE,
                                       NULL,
									                     1,
                                       Task1Stack,
                                       &Task1TCB );
    // 核心就是插入函数 vListInsert, 将任务插入到就绪列表中
    vListInsert(&pxReadyTasksLists[1], &Task1TCB.xStateListNode);

    Task2_Handle = xTaskCreateStatic(  Task2_Entry,
                                       "Task2_Entry",
                                       TASK2_STACK_SIZE,
                                       NULL,
									                     2,
                                       Task2Stack,
                                       &Task2TCB );
    vListInsert(&pxReadyTasksLists[2], &Task2TCB.xStateListNode);
    vTaskStartScheduler();  //去启动第一个任务
}

void vTaskSwitchContext(void)
{
    // 轮流切换两个任务，我这里任务暂时是手动切换的，没使用优先级
    if( pxCurrentTCB == &Task1TCB)
    {
        g_ReadyTasksLists[0] =& Task2TCB;
    }
    else
    {
        g_ReadyTasksLists[0] =& Task1TCB;
    }
}

void wjYIELD(void)
{
	PSRC_ALL();
	portDISABLE_INTERRUPTS();
	vTaskSwitchContext();
	cpu_task_switch();
	portENABLE_INTERRUPTS();
}

// 第一个任务函数 Task1 入口函数 ；task2 和 task1 一样
void Task1_Entry(void *p_arg)
{
    for(;;)
    {
        flag1 = 1;
		    printf("flag1 = %d \n", flag1);
        delay( 100 );
//        vTaskDelay( 20 );
        flag1 = 0;
		    printf("flag1 = %d \n", flag1);
        delay( 100 );
//        vTaskDelay( 20 );
		    wjYIELD(); // 注意，这里是手动切换任务
    }
}

int main(void)
{
	TaskSwitching_example();
	return 0;
}
```

好了，差不多就这些了。

![wujian_CamelOS](https://s1.ax1x.com/2020/04/09/G53CV0.jpg)

## 踩坑总结
通过这次研究，明白了 ARM 和 RISC-V 架构上的异同，加深了自己对两种架构的理解，相信对以后的学习也更加有帮助。
还有就是 wujian100 的开源资料中并没有提供特权架构的相关文档，异常和中断向量表规划也没有具体的说明文档，目前有限的文档中只介绍了外设 IP 的说明，所以在后续的软件开发增加了很多障碍。只有去扒他们提供的 SDK 中的源代码，通过源码来了解他们的架构，还有一点就是他们提供的代码及资料和阿里体系的东西相对耦合或者说兼容。跟开源社区现有的资料和体系不能很好融合。

## 参考资料

>《RISC-V-Reader-Chinese-v2p1》
>
> 《riscv-spec-20191213》
>
> 《riscv-privileged-20190608-1》
>
> 《Cortex-M3权威指南》
>
> 《computer organization and design》
>
>  https://github.com/FreeRTOS/FreeRTOS-Kernel/tree/master/portable/GCC/RISC-V
>