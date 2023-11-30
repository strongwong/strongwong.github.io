---
title: 总线- SoC 内部的主干道
tags:
  - SoC
  - AMBA
  - IC Design
categories:
  - IC Design
  - 其他
abbrlink: 15375
date: 2018-11-12 11:35:18
---

## 总线—— SoC 内部的主干道

开坑！从今天开始来聊一点数字 IC 的一些知识！首先来看一看总线
平日里我们都在讲总线总线，连接各模块的公共线，那它在 ARM 芯片中起到了啥木作用，来胡乱绉一通。


<!-- more -->

### 总线的功能

总线通俗得理解可以完成以下功能：

> - 提供时钟
> - 分配（管理）地址 
> - 响应中断
> - 传输数据
> - 传送控制信号

## USB 总线

以平日里最常见的 USB 为例，USB 其实也是一种总线如下图所示，通常我们计算机连接到 USB 后，USB 提供的总线可以拓展连接到我们的外设，例如 U 盘、键盘、鼠标等……但是设备本身不会与 CPU 进行通信，它们只与 USB HOST 进行通信，USB HOST 会给它们分配相应的中断。一旦 USB 设备插入 USB 接口引起物理上的电平变化便会有中断，此刻的中断并非 CPU 的中断，此时的中断是 USB HOST 的中断，此中断经一定的处理后发送至 CPU 后，CPU监测到是 USB HOST 中断，便将中断交付 USB HOST 进行处理。再来看地址的问题，CPU 是无法直接访问到你的设备的，红色方框内可以看做是一个“`家族`”，CPU 只能访问到其“`家长`” USB HOST，USB HOST 访问具体设备才用到地址访问。例如此时 U 盘的地址是 0x0007H，若此地址直接由 CPU 访问的话 CPU 最终只会访问到内存的 0x0007H，而非我们的 U 盘，因此将此地址交付 USB HOST 进行访问才能实现。这里就能看出不仅仅内存有地址，引入总线后，各个外设也有了对应的地址。

![usb](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/USB.png)

## AMBA 总线

回到 ARM 上来，ARM 的总线遵循 AMBA（ARM 爸——安谋爸爸）的总线规范，ARM 为了让大家能尽可能地接外设变作了个 AMBA 总线规范，通常 AMBA 规范下常见的总线分别是 AHB（高速总线），APB（外设总线），ASB（AHB 备胎）如图所示。

![amba](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/amba.png)

我们可以把 APB 总线当做乡村公路，AHB 总线当做一条省道，把这两条路连接起来的“`十字路`”可以叫做“`Bus bridges`”。AHB 上的设备通常速度较快例如：内存控制器，NAND Flash …… APB 就较慢，例如 UART，GPIO ……最直观的 UART 通常我们最快设置的波特率大概就 115200，还不到 M 级，因此就放在乡村公路跑就可以了。那么不同的路就要跑不同的频率，那么通常设计的外设的 controller 时，其控制时钟就由总线提供，以保证操作的同步性，那么在 IP 中我们就可以看到有叫做 HCLK（AHB）的信号和 PCLK（APB）的信号。我们还可以看到在 M3 和总线之间还有一个模块叫做 BusMatrix，其主要负责多主设备和多从设备的交互和仲裁，目的是为了提高不同主机访问不同外设情况下的带宽，另外一个就是简化 Bus Master 的协议设计（今后有机会进去分析）。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/hclk_pclk.jpg)

## FCLK、HCLK、PCLK

我们都知道的是芯片内部的“`心跳`”是由外部晶振给的，外部晶振通常就十几二十兆，但芯片内部动辄七八十兆甚至上 G，那这里就离不开一个叫 CLKCNTL 的东西，它负责提各个部分的“`心跳`”。刚才我们也说到 APB 和 AHB 是不同速度的公路，因此它们的工作频率是不同的（实际上可以相同的，但其分类的意义就不大了），而 CPU 本身的工作频率也是不同的。如图所示，给 ARM 用的是 FCLK（全局时钟）， 你可以将 PLL 出来的 70MHz 频率分频多少给 FCLK，将 70MHz 频率分频多少给 HCLK,PCLK 这就是 CLKCNTL 做的事，CLKCNTL 分配出来的 FCLK,HCLK,PCLK 三者成一定的倍数关系。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/ambaclk.png)

具体到 AHB,APB 总线协议和使用应用，今后我们将会逐一胡扯乱绉。技术不到家全靠虾扯蛋，错误应该是满天飞，望各位大神指正。先挖个坑，下次更 AHB 总线下 SRAM 的控制器设计。

**By Ricky**