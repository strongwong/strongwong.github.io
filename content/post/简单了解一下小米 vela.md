---
title: 简单了解一下小米 vela
tags:
  - 嵌入式
  - NuttX
categories:
  - 嵌入式
date: 2021-01-12
draft: false
---

## 0x00 小米 vela
前段时间小米推出了 vela 物联网平台，vela 就是基于 NuttX 打造的物联网开发平台。

小米对 NuttX 的评价：

> 1. NuttX 对 POSIX 标准有原生兼容：NuttX 是可商用化 RTOS 中唯一一个对 POSIX API 有原生支持的实时操作系统，所以很多 Linux 社区的开源软件可以很方便的移植到 NuttX 上，这样可以极大的简化开源软件移植，方便代码复用，降低学习曲线，其它 RTOS 需要适配层把 POSIX API 转成内部 API，而且通常只兼容一小部分的 POSIX 接口。
> 2. 完成度高：NuttX 集成了文件系统、网络协议栈、图形库和驱动框架，减少开发成本。
> 3. 模块化设计：所有组件甚至组件内部特性，都可以通过配置 Kconfig 来调整或关闭，可按需对系统进行裁剪，适用于不同产品形态。
> 4. 代码精简：所有组件都是从头编码，专门对代码和数据做了优化设计。
> 5. 轻量级：虽然 NuttX 实现了传统操作系统的所有功能，但是最终生成的代码尺寸还是可以很小（最小配置不到 32KB，最大配置不超过 256KB）。
> 6. 和 Linux 系统的兼容性：因为 NuttX 整体设计、代码组织，编译过程和 Linux 非常接近，将会极大地降低 Android/Linux 开发者的迁移成本。
> 7. 活跃开放的社区：很多厂商（比如小米、Sony，乐鑫、NXP 等）和开源爱好者都在积极回馈社区。

不难看出小米对 NuttX 的评价很不错。所以我也来赶紧学习一波，做了一个简单的了解，作为自己的技术储备。

## 0x01 安装配置
环境： Ubuntu20.04 系统、ARM GUN 2019q4 版本 gcc、openocd 0.10 版本

安装 ARM gcc 工具链，如果开发板是用其他的架构 cpu 请去安装其他架构下相应的版本工具链，我这里是 ARM 的。

```bash
sudo mkdir /opt/gcc
sudo chgrp -R users /opt/gcc
cd /opt/gcc
wget https://developer.arm.com/-/media/Files/downloads/gnu-rm/9-2019q4/gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
tar xf gcc-arm-none-eabi-9-2019-q4-major-x86_64-linux.tar.bz2
```
配置工具链到系统环境变量
```bash
echo "export PATH=/opt/gcc/gcc-arm-none-eabi-9-2019-q4-major/bin:$PATH" >> ~/.bashrc
```
下载 nuttx 、apps、tools 三个 nuttx 系统源码及构建工具

```bash
mkdir nuttxWS
cd nuttxWS
git clone https://github.com/apache/incubator-nuttx.git nuttx
git clone https://github.com/apache/incubator-nuttx-apps apps
git clone https://bitbucket.org/nuttx/tools.git tools
```

安装 kconfig ，构建工具。注意：低于 ubuntu20 版本的安装要少许麻烦一些
```bash
$ apt install kconfig-frontends
```
查看 nuttx 支持的板卡
```bash
$ cd nuttxWS
$ ./tools/configure.sh -L | less
```
选择相应的板卡及其支持的应用程序进行配置
```bash
$ cd nuttxWS
$ ./tools/configure.sh -l <board-name>:<config-dir>
# for instance:
$ ./tools/configure.sh -l stm32f103-minimum:nsh
```
运行 menuconfig 进行自定义配置
```bash
$ make menuconfig
```

## 0x02 编译运行
配置完成后编译 NuttX 系统
```bash
$ make -j$(nproc)
```
编译完成后会在 nuttx 目录下生成一个 nuttx.bin 文件，接下来把他下载到板子是运行
首先安装 openocd
```bash
$ sudo apt install openocd
```
如果使用 apt 安装的 openocd 版本过低，就自己从源码安装一下 openocd 即可

Openocd 安装好之后，正确连接板卡和电脑，下载程序。
烧写程序之前可以先打开串口，当系统正常运行起来之后可以在串口中观察到 nsh> 命令行。注意，我这边是 stlink 的虚拟串口所以是 ACM0，你的如果不是虚拟串口，可能是 USB0 之类的。
```bash
$  picocom -b 115200 /dev/ttyACM0
```
下载程序需要注意正确选择你使用的下载器和板卡对应的 .cfg 文件
```bash
$ cd nuttxWS
$ openocd -f interface/stlink-v2-1.cfg -f target/stm32f1x.cfg -c 'init'  -c 'program nuttx.bin 0x08000000 verify reset' -c 'shutdown'
```
如果程序正常运行了就可以在中观察到信息，输入 help 命令就可以查看支持的命令列表。如果没有看到信息，reset 一下板子。

修改配置编译一个 blinking 控制 led 的程序

回到 nuttx 目录下清除原来的配置，重新生成，在 menuconfig 中检查 led 相关配置是否设置成功。在 NSH library 中使能 printf 功能。
```bash
$ cd nuttxWS/nuttx
$ make distclean
$ ./tools/configure.sh -l stm32f103-minimum:userled
$ make menuconfig
$ make -j$(nproc)
```
编译完成后下载到板卡上，打开串口，按一下 reset 连接上板子就可以在串口看到输出的信息了。直接执行 leds ，可以看到板卡上的 led 已经正常运行起来了。

今天就先点个灯了解一下，其他的内容，等我翻翻 NuttX 源码在学习一下。