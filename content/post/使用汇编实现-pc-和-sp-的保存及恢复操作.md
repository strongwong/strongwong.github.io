---
title: 使用汇编实现 pc 和 sp 的保存及恢复操作
tags:
  - ARM
  - CM3
categories:
  - 学习
  - 嵌入式
abbrlink: 27588
date: 2019-01-13 19:32:27
---
## 前言

在 ARM Cortex 系列的芯片中本来就有一套保护现场的机制，例如当产生了一个中断时，会自动将当前寄存器的值入栈，并在 lr（r14） 寄存器中保存将要返回的 pc 值，在中断服务程序执行完成后将 pc 恢复到之前的位置。如果在执行中断服务程序的时候又发生了优先级更高的中断，也就是说发生了中断嵌套，这是将再次进行现场保护，同时 lr 值会被压栈（上一次的 pc ），新的 lr 生成。

但是在一些场景下，这样的机制就不太好用了，比如说要进入 sleep 模式 cpu 掉电了，想要恢复到掉电前的状态。这样的话就需要我们自己实现保护现场了，下面就来简单介绍一下我的实现。

<!-- more -->

## 硬件及 IDE 环境

- 硬件: Cortex-M3 FPGA 开发板
- IDE: IAR 8.22.1

在进行 FPGA 验证之前，还跑了 RTL 的仿真，从仿真波形的结果来看也是正确的。

## c 文件

现场保护主要就是保存当前的运行状态，在从 sleep 模式唤醒后将保存的状态恢复，使 cpu 回到到 sleep 之前的状态。在我们这里最主要的是保存 pc 和 sp 的值，cpu 唤醒之后恢复 pc 和 sp 就好，所以我们需要将进入 sleep 之前的 pc 和 sp 保存即可。

在进入 sleep 模式中，虽然 cpu 掉电了，但是 SRAM 还是维持着的，所以我们可以使用一个全局变量（存储在 SRAM 中）来保存 pc 和 sp 的值。

“xxx.c” 文件中部分代码：

```c
// 函数及变量的声明和引用
extern void Save_PC_SP(void)
extern void Restore_PC_SP(void)
extern u32 pc_save;
extern u32 sp_save;

//······
// 在执行 sleep 指令（WFI/WFE）之前保存 pc、sp
Save_PC_SP();    // 保存 pc 和 sp
__WFI();         // 睡眠
__NOP();
__NOP();
__NOP();

//······
```

## s 汇编文件

“xxx.s”文件中的部分代码：

```armasm
;函数及变量的声明和引用
PUBLIC  Save_PC_SP
PUBLIC  Restore_PC_SP

IMPORT  pc_save
IMPORT  sp_save

;唤醒后判断的代码
    THUMB

    PUBWEAK Reset_Handler
    SECTION .text:CODE:REORDER:NOROOT(2)
Reset_Handler
    LDR R0, =0x4001f000
    LDR R1, [R0]
    CMP R1, #1
    BEQ __iar_program_start
    B   Restore_PC_SP


;Save pc sp 的代码

    SECTION .text:CODE:NOROOT
Save_PC_SP
    LDR R0, =0x4001f000
    MOV R1, #1
    STR R1, [R0]
    LDR R0, =sp_save
    LDR R2, =pc_save
    MOV R1, R13
    STR R1, [R0]
    MOV R1, LR
    STR R1, [R2]
    BX  LR


;Restore pc sp 的代码
    
    SECTION .text:CODE:NOROOT
Restore_PC_SP
    LDR R0,  =sp_save
    LDR R1,  [R0]
    MOV R13, R1
    LDR R0,  =pc_save
    LDR R1,  [R0]
    ADD R1,  R1, #0x8
    MOV PC,  R1
    NOP
    NOP
    NOP

```

在汇编文件中主要实现的是 save 和 restore 的操作，以及恢复过程的判断。因为我们的设计是从睡眠唤醒是从 Reset 起来的，这就导致第一次 cpu 的正常启动会和 restore 发生冲突，所以我这里选择了一个不会掉电的寄存器来作为是否进行 restore 的判断。

还有就是加 NOP 指令是因为 Cortex-M3 是三级流水线，为了防止 cpu 因为 pc 的预取而发生错误。

