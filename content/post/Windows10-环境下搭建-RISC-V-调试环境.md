---
title: Windows10 环境下搭建 RISC-V 调试环境
tags:
  - RISC-V
categories:
  - 学习
  - 嵌入式
abbrlink: 48045
date: 2019-03-11 10:32:02
---

## 环境要求
### 软件环境

- IDE: [GNU MCU Eclipse IDE for C/C++ Developers](https://github.com/gnu-mcu-eclipse/org.eclipse.epp.packages/releases)
- IDE 插件: [GNU MCU Eclipse plug-ins](https://github.com/gnu-mcu-eclipse/eclipse-plugins/releases)
- GCC/GDB 工具: [GNU MCU Eclipse RISC-V Embedded GCC](https://github.com/gnu-mcu-eclipse/riscv-none-gcc/releases)
- 调试工具: [GNU MCU Eclipse OpenOCD](https://github.com/gnu-mcu-eclipse/openocd/releases)
- make 工具: [GNU MCU Eclipse Windows Build Tools](https://github.com/gnu-mcu-eclipse/windows-build-tools/releases)
- Zadig 工具: [Zadig](https://zadig.akeo.ie/)

### 硬件要求

- 目标 RISC-V 芯片
- 调试器： J-Link，FT2232 或其他含有标准 JTAG 接口的调试器

<!-- more -->

## 配置环境

以下内容来自 ChenRQ 同学！

启动 IDE: GNU MCU Eclipse IDE for C/C++ Developers，Eclipse 基于 Java 开发，运行时需要 Java 的运行环境(JRE)，如没有请自行安装。

## 新建一个工程

![新建工程](https://i.loli.net/2019/02/26/5c7540a7474bf.png)

工程类型选择 Hello World RISC-V C Project，工具链选择 RISC-V Cross GCC 如下所示

![项目类型设置](https://i.loli.net/2019/02/26/5c754155033e4.png)

使用默认配置 next 至 GNU 工具链选择， 文件路径应指向为您的 RISC-V Embedded GCC 目录下的 bin 文件夹，如下图所示

![工具链路径设置](https://i.loli.net/2019/02/26/5c7542f86b719.png)

完成后点击 Finish 由此完成工程项目的创建。创建完成后，我们可以看到还有一个报错， 如下图所示

![工程创建完成界面](https://i.loli.net/2019/02/26/5c7543a17226b.png)

因此我们还需要继续对项目进行配置。

## 工程相关配置

对工程右键选择 “properties”，在 MCU 选栏中配置 Build Tools Path，该路径应指向您的 Build Tools 目录下的 bin 文件夹，如下图所示

![Build Tools 路径配置](https://i.loli.net/2019/02/26/5c7544fd07eb8.png)

继续配置 OpenOCD Path，路径为 OpenOCD 目录下的 bin 文件夹，如下图所示，并点击apply

![OpenOCD 路径配置](https://i.loli.net/2019/02/26/5c75487c1f6cf.png)

再配置 RISC-V Toolchain Path（若新建项目时已配置过工具链路径，可以跳过此步骤），配置路径与工程建立时选择的工具链路径相同。

## 配置编译和链接选项

继续在 “properties” 窗口中，选择 C/C++ Build 中的 settings，在 Tool Settings 中 Target Processor 进行配置，由于是 RISC-V，因此架构 (architecture) 选择 RV32I 并勾选乘法指令拓展(RVM)，原子指令拓展(RVA)及压缩指令拓展(RVC)，ABI 调用选择 ILP32(表明为 32 位架构无浮点型，PS: ilp32f 和 ilp32d 则分别表示单精度浮点和双精度浮点)，Code Model 选择 Medium Low，勾选整数除法指令(-mdiv)，如下图所示，并点击 apply

![Target Processor 配置](https://i.loli.net/2019/02/26/5c7548ff7b8fb.png)

继续配置 Optimization，Level 选择 -O2，如下图所示，并点击 apply

![Optimization 配置](https://i.loli.net/2019/02/26/5c7549557f2eb.png)

继续配置 Debugging，Level 选择 -g，如下图所示，并点击 apply

![Debugging 配置](https://i.loli.net/2019/02/26/5c7549be00c12.png)

在 Tool Settings 中选择 GNU RISC-V Cross C Linker 的 General，点击右上角+号，弹窗中选择 Workspace 选择路径您芯片对应的 lds 文件，用于对地址区间进行约束，如下图所示

![链接脚本配置](https://i.loli.net/2019/02/26/5c754a785cc2d.png)

勾选对应选项后，点击 apply,如下图所示

![链接选项配置](https://i.loli.net/2019/02/26/5c754ad5a9b74.png)

在 Tool Settings 中选择 GNU RISC-V Cross C Linker 的 Miscellaneous 进行勾选，如下图所示，并点击 apply

![链接杂项配置](https://i.loli.net/2019/02/26/5c754b533251d.png)

添加您的工程汇编类型的头文件路径，方法如下图所示

![添加工程汇编头文件目录](https://i.loli.net/2019/02/26/5c754c158df6a.png)

添加您的工程 C/C++ 类型的头文件路径，方法如下图所示

![ 添加工程 C/C++ 头文件目录](https://i.loli.net/2019/02/26/5c754c158df6a.png)

待续... 

后续测试进行中...

转载自 Kismet 的 Blog: 
[https://blog.asicfans.com/2019/01/25/windows10-%E7%8E%AF%E5%A2%83%E4%B8%8B%E6%90%AD%E5%BB%BA-risc-v-%E8%B0%83%E8%AF%95%E7%8E%AF%E5%A2%83/](https://blog.asicfans.com/2019/01/25/windows10-%E7%8E%AF%E5%A2%83%E4%B8%8B%E6%90%AD%E5%BB%BA-risc-v-%E8%B0%83%E8%AF%95%E7%8E%AF%E5%A2%83/)
