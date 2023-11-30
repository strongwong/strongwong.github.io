---
title: 关于 ARM Cortex-M3 的启动文件分析及分散加载
tags:
  - ARM
  - CM3
  - 启动文件
  - 分散加载
categories:
  - 学习
  - 嵌入式
abbrlink: 42720
date: 2018-09-07 11:22:44
---
## 关于 ARM Cortex-M3 的启动文件分析及分散加载

下面以 ARM Cortex-M3 裸核的启动代码为例，做一下简单的分析。首先，在启动文件中完成了三项工作：
- 堆栈以及堆的初始化
- 定位中断向量表
- 调用 Reset Handler

<!-- more -->

在介绍之前，我们先了解一下 ARM 芯片启动文件中涉及到的一些汇编指令的用法。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E6%B1%87%E7%BC%96%E6%8C%87%E4%BB%A4.jpg)

补充一下，其中 DCD 相当于 C 语言当中的 &，定义地址。

## 堆栈以及堆的初始化
### 堆栈的初始化
 
![Startup_xxx.s 中的堆栈初始化代码](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E5%90%AF%E5%8A%A8%E6%96%87%E4%BB%B6%E5%A0%86%E6%A0%88%E5%88%9D%E5%A7%8B%E5%8C%96%E4%BB%A3%E7%A0%81.jpg)

`Stack_Size  EQU  0x00000400`
这个语句相当于 Stack_Size 这个标号（标号：链接器的术语，下文中提到的所有“标号”，指的都是指的链接器中的标号）等于 0x00000400 相当于 C 语言中的 `#define  Stack_Size  0x00000400` ，也就是说此语句只是一个声明，并未分配地址。

```$
AREA    STACK, NOINIT, READWRITE, ALIGN=3
```
此语句定义了一个叫 STACK 的代码段，并指明 8 字节对齐（ALIGN = 3）。其中 NOINIT 表示未初始化，READWRITE 表示可读可写，ALIGN = 3，即表示 2^3 = 8，八字节对齐。

```$
Stack_Mem    SPACE   Stack_Size
```
这里是为 Stack_Mem 分配 Stack_Size 大小的一块内存区域，注意这里分配的是 RAM ，即分配了大小为 1KB 的内存空间（0x00000400 = 1024）。

```$
__initial_sp
```
紧跟着栈分配内存后，所以其为栈顶（满递减栈）。此标号有一层隐含的意思就是在 M3 中堆栈是满递减堆栈，因为它指定了堆栈指针位于堆栈的高地址（在 Stack_Mem 之后），具体如下图所示。
 
![堆栈指针 sp 位置](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E5%A0%86%E6%A0%88%E6%8C%87%E9%92%88.jpg)

上图来自 Cortex_M3 的一个工程的 xxx.map 文件。可以看出栈的起始地址为 0x20000c68，大小为 1024 字节（即 0x00000400 = Stack_Size）。而堆栈指针的位置在 0x20001068，其等于栈的起始地址 0x2000c68 + 0x00000400，说明本系列的 Cortex_M3 微控制器的堆栈为满递减堆栈。
所以 __initial_sp 为 1KB 空间栈的栈顶，栈主要用于局部变量和形参的调用过程的临时存储，属于编译器自动分配和释放的内存，所以这里需要注意如果你的函数所占的内存过大，那么这个空间应调整其大小但一定要小于内部 SRAM 的大小。堆是程序员空间是程序员进行分配和释放的，如果程序中未释放最后由系统回收。

### 堆的初始化
 
![Startup_xxx.s 中的堆初始化代码](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E5%A0%86%E5%88%9D%E5%A7%8B%E5%8C%96.jpg)

堆的初始化过程与堆栈的初始化相同。

## 中断向量表的初始化
 
![中断向量表的初始化代码（部分）](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E4%B8%AD%E6%96%AD%E5%90%91%E9%87%8F%E8%A1%A8.jpg)

`PRESERVE8` 指定了以下的代码为 8 字节对齐，这是 keil 编译器的一个编程要求，对齐情况如下图所示：
 
![xxx.list文件中的8字节对齐示意图](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/8%E5%AD%97%E8%8A%82%E5%AF%B9%E9%BD%90.jpg)

`THUMB` 指定了接下来的代码为 THUMB 指令集。

```$
AREA    RESET, DATA, READONLY
```
此语句声明 RESET 数据段。
```$
EXPORT  __Vectors
```
导出向量表标号，EXPORT 作用类似于 C 语言中的 extern。之后的代码就是为向量表分配存储区域。中断向量表从 FLASH 的 0x00000000 地址开始放置，以 4 个字节为一个单位，地址 0 存放的是栈顶指针（ sp ）的地址，0x00000004 存放的是复位程序的地址，往后以此类推，这里我们只设置了一个 Reset_Handler 向量。从代码上看，向量表中存放的都是中断服务函数的函数名，可我们知道 C 语言中的函数名就是一个地址。（由此我们知道，中断函数的函数名都已经知道了，我们在写对应的中断服务程序时，从对应的地址取服务例程的入口地址并跳入执行）。但是此处有一个要注意的，就是 0 号地址不是什么入口地址，而是给出的复位后的 MSP 的初值。

## 调用 Reset Handler
 
![调用 Reset Handler 的代码](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/reset_handler.jpg)

此段代码只完成了一个功能，引导程序进入 __main 。 __main 的具体行为在后面做具体描述。
`PROC` 与 `ENDP` 两个关键字组合在汇编中定义了一段子函数。
用户堆栈的初始化
 
![具体的堆栈以及堆的初始化行为](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E5%A0%86%E6%A0%88%E5%88%9D%E5%A7%8B%E5%8C%96%E5%85%B7%E4%BD%93%E4%BB%A3%E7%A0%81.jpg)

这一部分也就是把初始化的堆栈地址赋值给单片机的对应寄存器以方便 C 程序进行分配释放使用。

## 其他代码
有一些芯片厂商对芯片的加密的加密级别的代码也会放在这里，芯片上电后会自动读取这一地址的值以确定芯片的加密方式。

## ARM 芯片的启动过程详解
接下来介绍 __main 函数的具体实现过程。
首先在介绍 __main 函数之前，我们先了解一些关于 ARM 芯片在启动过程中的基本知识。
“ ARM 程序”是指在 ARM 系统中正在执行的程序，而非保存在 ROM 中的 .bin(.axf,.hex)映像（ image ）文件。
一个 ARM 程序包含 3 部分：RO ，RW 和 ZI
- RO 就是只读数据，是程序中指令和常量；
- RW 是可读写的数据，程序中已初始化变量；
- ZI 是程序中未初始化的变量和初始化为 0 的变量。
简单理解就是：
	RO 就是 readonly ，RW 就是 read/write，ZI 就是 zero initial。
 
![ARM 芯片的启动过程详解](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/arm%E8%8A%AF%E7%89%87%E5%90%AF%E5%8A%A8%E6%B5%81%E7%A8%8B.jpg)

注意，以上的过程并非绝对的，不同的 ARM 架构或者是不同的代码以上的执行过程是不同的。
复位处理程序是在汇编器中编写的短模块，系统一启动就立即执行。复位处理程序最少要为应用程序的运行模式初始化堆栈指针。对于具有本地内存系统（如缓存、TCM 、MMU 和 MPU）的处理器，某些配置必须在初始化过程的这一阶段完成。复位处理程序在执行之后，通常跳到 __main 以开始 C 库初始化序列。
__main 中的 __scatterload 负责设置内存，而 __rt_entry 负责设置运行时的环境。__scatterload 中负责把 RO/RW （非零）输出段从装载域地址复制到运行域地址（执行代码和数据复制、解压缩），并完成 ZI 段运行域数据的 0 初始化工作。然后跳到 __rt_entry 设置堆栈和堆、初始化库函数和静态数据。然后，__rt_entry 跳转到应用程序的入口 main() 。主应用程序结束执行后，__rt_entry 将库关闭，然后把控制权交换给调试器。函数标签 main() 具有特殊含义。Main() 函数的存在强制链接器链接到 __main 和 __rt_entry 中的代码。如果没有标记为 main() 的函数，则没有链接到初始化序列，因而部分标准 C 库功能得不到支持。

## 结合代码来看芯片启动过程
上电后硬件设置 sp 、pc ，刚上电复位后，硬件会自动根据向量表地址找到向量表。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sp_pc.jpg)

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sp_pc1.jpg)
  
在离开复位状态后， CM3 做的第一件事就是读取下列两个 32 位整数的值：
- 1.从地址 0x0000 0000 处取出 MSP 的初始值。
- 2.从地址 0x0000 0004 处取出 PC 的初始值，这个值是复位向量， LSB 必须是 1 。 然后从这个值所对应的地址处取指。
硬件自动从 0x0000 0000 位置处读取数据赋给栈指针 sp，然后从 0x0000 0004 位置处读取数据赋给 pc 指针，完成复位，结果为：
```$
SP = 0x2000 1068 
PC = 0x0000 011D
```
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/reset%E5%90%AF%E5%8A%A8.jpg)
 
这与传统的 ARM 架构不同——其实也和绝大多数的其它单片机不同。传统的 ARM 架构总是从 0 地址开始执行第一条指令。它们的 0 地址处总是一条跳转指令。在 CM3 中，在 0 地址处提供 MSP 的初始值，然后紧跟着就是向量表。向量表中的数值是 32 位的地址，而不是跳转指令。向量表的第一个条目指向复位后应执行的第一条指令，就是我们上面分析的 Reset_Handler 这个函数。

进入__main
```C
LDR   R0, =__main
BX　　R0
```
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/__main%E4%BB%A3%E7%A0%81.jpg)

执行上两条指令，跳转到 __main 程序段运行，__main 的地址是 0x0000 0080 ，上一步指令 pc = 0x0000 011D 的地址没有对齐，硬件自动对齐到 0x0000 011C，执行 __main。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/0x0000012c.jpg)

pc 指针通过立即数寻址，跳转到 0x0000 0081 处执行，同上这里也会自动对齐到 0x0000 0080 处。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/0x00000088.jpg)

在 __scatterload 函数中又会进入 __scatterload_copy ，在 __scatterload_copy 中进行代码搬运，主要是加载已经初始化的数据段和未初始化的数据段，同时还会初始化栈空间，即 ZI 段清零（其中搬运次数由代码中声明的变量类型和变量多少来决定）。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/ZI%E6%AE%B5%E6%B8%85%E9%9B%B6.jpg)

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/__rt_entry.jpg)
 
然后会跳转到 __rt_entry 函数执行，__rt_entry 是使用 ARM C 库的程序的起点。将所有分散加载区重新定位到其执行地址后，会将控制权传递给 __rt_entry 。如下图，在 __rt_entry 中主要实现如下几个功能：
- 1.设置用户的堆和堆栈
- 2.调用 __rt_lib_init 以初始化 C 库
- 3.调用 main()
- 4.调用 __rt_lib_shutdown 以关闭 C 库
- 5.退出

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/C_library.jpg)

__rt_lib_init 函数是库函数初始化函数，它与 __rt_lib_shutdown 配合使用。并且这个函数紧靠 __rt_stackheap_init() 后面调用，即紧跟堆和堆栈初始化后面调用，并且传递一个要用作堆的初始内存块。此函数是标准ARM库初始化函数，不能重新实现此函数。

**注意：最后两步是在程序退出 main() 函数的时候才会执行，而我们嵌入式程序一般都是死循环，所以基本上不会执行这两个过程。还有以上过程是针对使用标准 C Library 而言的，不包括使用 MDK 提供的 microlib 库的情况。**

在 __rt_entry_main 中，用户程序就开始正式执行了（进入 C 的世界）。在此之前初始化 MSP 是必需的，因为可能第 1 条指令还没来得及执行，就发生了 NMI 或是其它 fault。 MSP 初始化好后就已经为它们的服务例程准备好了堆栈。这也就是 __main 中做的事情。

## 最后关于 microlib 库
Microlib 是缺省 C 库的备选库。它旨在与需要装入到极少量内存中的深层嵌入式应用程序配合使用。这些应用程序不在操作系统中运行，因此 microlib 进行了高度优化以使代码变得很小，当然它的功能相比缺省 C 库少，并且根本不具备某些 ISO C 特性。某些库函数的运行速度也比较慢，比如 memcpy()。 

Microlib与缺省C库之间的主要差异是：

> Microlib 不符合 ISO C 库标准。不支持，某些 ISO 特性，并且其他特性具有的功能也比较少；
> Microlib 不符合 IEEE754 二进制浮点算法标准；
> Microlib 进行了高度优化以使代码变得很小；
> 无法对区域设置进行配置。缺省 C 区域设置是唯一可用的区域设置；
> 不能将 main() 声明为使用参数，并且不能返回内容；
> 不支持 stdio ，但未缓冲的 stdin、stdout 和 stderr 除外；
> Microlib 对 C99 函数提供有限的支持；
> Microlib 不支持操作系统函数；
> Microlib 不支持与位置无关的代码；
> Microlib 不提供互斥锁来防止非线程安全的代码；
> Microlib 不支持宽字符或多字节字符串；
> 与stdlib 不同， microlib 不支持可选的单或双区内存模型。 Microlib 只提供双区内存模型，即单独的堆栈和堆区。

## 关于生成的 xxx.map 文件
想要更好的了解启动代码的运行机制，我们就有必要了解一下由 Keil 的链接器“ armlink ”生成的描述文件，即 xxx.map 文件。

![目标文件的组成](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/map%E6%96%87%E4%BB%B6.jpg)

上图即是 armlink 的链接器为测试代码生成的 xxx.map 文件中的一部分，其描述了镜像文件的组成信息，其中可以明显看到其由两部分构成：
- User Code 生成的目标文件
- C Library 生成的目标文件

可见我们在上文中所描述的启动过程中看到的 __main 、 __rt_entry 、 __scartterload 以及 __rt_lib_init 等，就是 C library 中的代码。
所以，我们每次烧录的可执行的 ARM 的 bin 文件中不仅有开发者编写的代码，还有 C Library 的代码。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/map%E4%B8%ADRW%E6%AE%B5.jpg)
上图为存放在RAM中的RW段。


## 关于分散加载
### 基本概念
由于 ARM Cortex-M3 系列是哈佛架构，哈佛架构是一种将程序指令存储和数据存储分开的存储器结构，所以它在运行时，指令存储在片内的 flash 上，数据存储在片内 SRAM 中。因此程序是可以直接在 flash 上运行的，而不是先将 flash 上的程序全部搬运到 RAM 在运行。
由此，我们也可以深入了解一下 ARM 映像（镜像）文件。 ARM 映像文件其实就是源文件经编译器生成的目标文件 .obj（object file）和相应的 C/C++ 运行时库（ Runtime Library ）经过连接器的处理后，生成的 axf 格式的映像文件，它可以直接烧录到目标设备的 ROM 中直接运行或加载后运行。
### 映像文件的类型
常见的映像文件还包括 bin 、 hex 和 elf 文件，在 keil 调试过程中，调试器生成 axf 文件也是一种映像文件。
Bin 文件是纯粹的二进制机器代码，或者说是“顺序格式”。按照汇编代码顺序翻译成的二进制机器码，内部没有地址标记。 Bin 文件是直接的内存映像表示，二进制文件大小即为文件所包含的数据的实际大小。
Hex 文件是 Intel 标准的十六进制文件，通常用来保存单片机或其他处理器的目标程序代码。它保存物理程序存储区中的目标代码映像。一般的编程器都支持这种格式。就是机器代码的十六进制形式，并且是用一定文件格式的 ASCII 码来表示。在 Hex 文件里面，每一行代表一个记录。每条记录都由一个冒号“：”打头，其格式如下：
** :BBAAAATTHHHH...HHHHCC **
> BB:字节个数。 
> AAAA:数据记录的开始地址,高位在前,低位在后。
> TT: Type 
> 00 数据记录，用来记录数据。
> 01 记录结束，放在文件末尾，用来标识文件结束。
> 02 用来标识扩展段地址的记录 
> 04 扩展地址记录(表示 32 位地址的前缀)
> HHHH:一个字( Word )的数据记录,高字节在前,低字节在后。TT 之后共有 BB/2 个字的数据 。
> CC: 占据一个 Byte 的 CheckSum 

ELF（ Executableand linking format ）文件是 x86 Linux 系统下的一种常用目标文件( objectfile )格式，有三种主要类型:
> (1)适于连接的可重定位文件( relocatablefile )，可与其它目标文件一起创建可执行文件和共享目标文件。
> (2)适于执行的可执行文件( executable file )，用于提供程序的进程映像，加载到内存执行。
> (3)共享目标文件( shared object file )，连接器可将它与其它可重定位文件和共享目标文件连接成其它的目标文件，动态连接器又可将它与可执行文件和其它共享目标文件结合起来创建一个进程映像。
Axf 文件由 ARM 编译器产生，除了包含 bin 的内容之外，还附加其他调试信息，这些调试信息加在可执行的二进制数据之前。调试时这些调试信息不会下载到 RAM 中，真正下载到 RAM 中的信息仅仅是可执行代码。因此，如果 ram 的大小小于 axf 文件的大小，程序是完全有可能在 ram 中调试的，只要 axf 除去调试信息后文件大小小于 ram 的大小即可。

** 总结：**
- （1） axf 和 elf 都是编译器生成的可执行文件。区别是：ADS 编译出来的是 AXF 文件。gcc 编译出来的是 ELF 文件。两者虽然很像，但还是有差别的。这是文件格式的差别，不涉及调试格式。
- （2）axf/elf 是带格式的映象，bin 是直接的内存映象的表示。
- （3）Linux OS 下，ELF 通常就是可执行文件，通常 `gcc -o test test.c `，生成的 test 文件就是 ELF 格式的，在 Linux Shell 下输入 `./test` 就可以执行。在 Embedded 中，上电开始运行，没有 OS 系统，如果将 ELF 格式的文件烧写进去，包含一些 ELF 格式的东西，arm 运行碰到这些指令，就会导致失败，如果用 bin 文件，程序就可以一步一步运行。
所以最终放进 flash 的是 bin 文件。 elf 文件可转化为 hex 和 bin 两种文件， hex 也可以直接转换为 bin 文件，但是 bin 要转化为 hex 文件必须要给定一个基地址。而 hex 和 bin 不能转化为 elf 文件，因为 elf 的信息量要大。 Axf 文件可以转化为 bin 文件，KEIL 下可用以下命令 `fromelf -nodebug xx.axf -bin xx.bin` 即可。

### 映像文件的组成
镜像文件组成如下图所示：

![镜像文件的组成](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E9%95%9C%E5%83%8F%E6%96%87%E4%BB%B6.jpg)

可执行文件由映像、区（域）、输出节（段）和输入节（段）的层次结构构成：
> 映像由一个或多个区组成。每个区由一个或多个输出节组成。
> 每个输出节包含一个或多个输入节。
> 输入节是对象文件中的代码和数据信息。
> 输入节：输入节包含代码、初始化数据，或描述未初始化的或在映像执行之前必须设定为 0 的内存片段。这些特性通过 RO 、 RW 和 ZI 这样的属性来表示。
> 输出节：一个输出节由若干个具有相同 RO 、 RW 或 ZI 属性的相邻输入节组成。输出节的属性与组成它的输入节的属性相同 。
> 区：一个区由一个、两个或者三个相邻的输出节组成。区中的输出节根据其属性排序。首先是 RO 输出节，然后是 RW 输出节，最后是 ZI 输出节。区通常映射到物理内存设备，如 ROM 、 RAM 或外围设备。

有时候用户希望将不同代码放在不同存储空间，也就是通过编译器生成的映像文件需要包含多个域，每个域在加载和运行时可以有不同的地址。要生成这样的映像文件，必须通过某种方式告知编译器相关的地址映射关系。在 Keil/ADS/IAR 等编译工具中，可通过分散加载机制实现。分散加载通过配置文件实现，这样的文件就称为分散加载文件。
分散加载( scatter loading )为 \*.scf 文件。它提供这样一种机制：可以将内存变量定位于不同的物理地址上的存储器或端口，通过访问内存变量即可达到访问外部存储器或外设的目的；同时通过分散加载，让大多数程序代码在高速的内部 RAM 中运行，从而使得系统的实时性大大增强。这样，定位在 RAM 存储器的代码和数据就在 RAM 存储器中运行，而不再从 ROM 存储器中取数据或取指令，从而大大提高了 CPU 的运行速率和效率。
编译过程
![编译过程](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E7%BC%96%E8%AF%91%E8%BF%87%E7%A8%8B.jpg)
加载过程
![简单的加载过程](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E7%AE%80%E5%8D%95%E5%8A%A0%E8%BD%BD.jpg)
 
![输出的map文件](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E8%BE%93%E5%87%BA%E7%9A%84map%E5%A4%A7%E5%B0%8F.jpg)

ROM（Flash）size = Code + RO_Data + RW_Data = 0.5kb；
RAM size = RW_Data + ZI_Data = 4.1kb。

加载时域的描述
sct 文件
![.sct文件](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sct%E6%96%87%E4%BB%B6.jpg)

LR_IROM1 加载区域名，用于“ Linker ”区别不同的加载区域，最多 31 个字符；用来保存永久性数据（程序和只读变量）的区域；
ER_IROM1 执行区域名；程序执行时，从加载区域将数据复制到相应执行区后才能被正确执行；


例如：
```$
LR_IROM1 0x00000000  0x00040000  {    ; load region size_region
  ER_IROM1 0x00000000  0x00010000  {  ; load address = execution address
   *.o (RESET, +First)
   *(InRoot$$Sections)
   .ANY (+RO)
  }
  RW_IRAM1 0x20010000  0x00010000  {  ; RW data
   .ANY (+RW +ZI)
  }
}
```

LR_IROM1 0x00000000 0x00040000 
定义一个加载时域，域基址：0x00000000，域大小为 0x00040000，对应实际 Flash 的大小
ER_IROM1 0x00000000 0x00010000
定义一个运行时域，第一个运行时域必须和加载时域起始地址相同，否则库不能加载到该时域的错误，其域大小一般也和加载时域大小相同，但是我们这里没有 flash ，只有 128k 的 RAM ，这里分配 64k 作为程序存储器，所以这里是 0x00010000 大小。

*.o (RESET, +First) 
将 RESET 段最先加载到本域的起始地址外，即 RESET 的起始地址为 0，RESET 存储的是向量表

.ANY (+RO) 
加载所有匹配目标文件的只读属性数据，包含：RW-Code、RO-Data。

RW_IRAM1 0x20010000 0x00010000
定义一个运行时域，域基址：0x20010000，域大小为 0x00010000 ，对应实际 RAM 大小，这时就不能从 0x20000000 开始了，因为实际 RAM 中前 64K 已经用于程序存储了，所以运行段向后偏移 0x00010000 大小，起始地址从 0x20010000 开始。之前就是因为这里的内存分配不对，地址从 0x20000000 开始，结果程序在搬运初始化过程中，把自己清零了，导致代码在进入 mian() 函数以后就跑飞了。

* (+RW +ZI) 
加载所有区配目标文件的 RW-Data、ZI-Data 这里也可以用 .ANY 替代 \* 号 


下图为 STM32 的 sct 文件：
 
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/stm32sct.jpg)

下面为 OnSemiconductor RSL10 芯片的 sct 文件，编译环境为 eclipse 加 armlink。

```$
SECTIONS 0x00100000
{
    ; For Cortex-M devices, the beginning of the startup code is stored in
    ; the .interrupt_vector section, which goes to FLASH. All other code
	; follows this section.
;对于 Cortex-M 设备，启动代码的开头存储在 .interrupt_vector 部分，该部分转到 FLASH 。 所有其他代码都在本节后面。
    FLASH 0x00100000 0x60000 
{
; Flash 起始地址为 0x00100000 大小为 0x60000  384k

        * (RESET +FIRST)
        
        ; Remaining program code
; 只读代码部分
        * (+RO)
      
        ; All remaining DSP code 
; DSP 代码
        * (.dsp, .dsp.*)
    }

; Define the data sections
; 定义运行域
    DRAM 0x20000000 (0x6000 - 2048) 
{
; DRAM 起始地址 0x20000000 大小 0x6000  大约 24k
        ; Place the system clock variable first
; 首先放置系统时钟变量
        * (.systemclock +FIRST)

        ; Place the defined data sections
; 放置已定义的数据部分
        * (.data_begin, .data_begin.*)
        * (.data, .data.*)
        * (.data_end, .data_end.*)
    
        ; Place all remaining read-write and zero-initialized data 
; 放置所有剩余的读写和零初始化数据
        * (+RW)
        * (+ZI)
    }

; Define a heap region
; 定义堆区域 起始地址 0x20005800 大小 0x400  1k
    ARM_LIB_HEAP 0x20005800 EMPTY 0x400
    { }

; Define a stack region
; 定义栈区域 起始地址 0x20005C00  大小 0x400 1k
    ARM_LIB_STACK 0x20005C00 EMPTY 0x400
    { }
}
```