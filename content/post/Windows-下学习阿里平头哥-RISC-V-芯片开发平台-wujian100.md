---
title: Windows 下学习阿里平头哥 RISC-V 芯片开发平台 wujian100
tags:
  - RISC-V
  - 平头哥
  - Verilog
  - IC Design
categories:
  - IC Design
  - 其他
abbrlink: 41199
date: 2019-11-09 14:59:55
---

## 前言

上个月，在第六届互联网大会上，阿里的平头哥，对，就是那个人狠话不多的公司！他们宣布开源了 wujian100 这个芯片设计平台。搭载基于 RISC-V 架构的玄铁 902 处理器。
基础硬件代码和配套软件代码发布在了 GitHub 上了，使用的是 MIT 许可证。大家也都可以去下载学习。

GitHub 链接：[https://github.com/T-head-Semi/wujian100_open](https://github.com/T-head-Semi/wujian100_open)

## 介绍视频

<iframe src="//player.bilibili.com/player.html?aid=74527234&bvid=BV1cE411B7xi&cid=127477207&p=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true"> </iframe>

[https://www.bilibili.com/video/av74527234](https://www.bilibili.com/video/av74527234)

# 搭建仿真环境

## 安装 Linux 环境

我们要去学习 wujian100 这个代码，首先要去搭建一下运行仿真的环境。跑无剑这个仿真是需要 Linux 环境的，所以我就安装了 WSL（ Windows subsystem of Linux），我这里呢安装了 Ubuntu 18.04 的版本。要安装 WSL ，首先要去 控制面板->程序->启用或关闭 Windows 功能 勾选开启 适用于 Linux 的 Windows 子系统 这个选项，这样你就可以去微软应用商店正常安装 Linux 子系统了。

安装好子系统之后，我们直接进入到子系统下面进行操作就可以了。

## 新建目录 Clone 官方代码

首先我们按照官方在 GitHub 上的教程新建一个项目目录，然后进入到目录， clone 官方发布的代码。

```bash
$ mkdir test_prj
$ cd test_prj
$ git clone https://github.com/T-head-Semi/wujian100_open.git
```

## 安装 RISC-V 工具链

接下来，新建工具链目录，去官方给定的地址下载编译代码需要的 risc-v 工具链，解开压缩包，找到 `riscv64-elf-x86_64-20190731.tar.gz` 这个工具链，拷贝到工具链目录，解压安装工具链即可。

```bash
$ mkdir riscv_toolchain
$ cd riscv_toolchain
# 下面这条命令不一定跟我一样，工具链下载后的具体路径根据你自己的系统确定
$ cp /mnt/d/download/T-Head\ Tools\ package/T-Head\ RISC-V\ Toolchain-V1.2.2/riscv64-elf-x86_64-20190731.tar.gz ./

$ tar -zxvf riscv64-elf-x86_64-20190731.tar.gz
```

## 安装仿真工具

仿真工具可以选择官方推荐的 VCS 仿真，但是我这里呢使用 iverilog 进行仿真， gtkwave 来查看波形文件，verilator 是编辑软件。然后由于我这边安装的 ubuntu18.04 默认没有安装 make 工具，所以也一起安装了。

```bash
$ sudo apt install iverilog gtkwave verilator
$ sudo apt install make
```

注：有些同学可能是 Ubuntu 16.04 版本，直接通过 apt 命令安装 iverilog 会自动安装一个版本较低的，低版本运行这个仿真是有问题的，这时建议同学自己手动编译安装 10.0 以上版本的 iverilog 。

## 编辑 setup 脚本，配置环境变量

工具安装完成之后，编辑 setup 脚本并通过执行它，来设置 EDA 环境变量。
由于原本的脚本是 csh 在 bash 环境下有一些不兼容的地方，所以我这里做了一些修改，修改内容如下：

setup.sh 脚本内容:
```bash
#Copyright (c) 2019 Alibaba Group Holding Limited
#
#Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:


#set VCS path
#setenv VCS_HOME
#set path=($VCS_HOME/linux/bin $path)

#set VCS license
#setenv SNPSLMD_LICENSE_FILE

#set iverilog path
export iverilog_path=(/usr/bin)
export gtkwave_path=(/usr/bin)
export path=($iverilog_path:$path)
export path=($gtkwave_path:$path)


#set tools path
export TOOL_PATH='../../riscv_toolchain'

export wujian100_open_PATH='`pwd | perl -pe "s/wujian100_open.*/wujian100_open\//"`'
```

```bash
$ cd ../wujian100_open/tools
$ vim setup.sh
$ chmod +x setup.sh
$ source setup.sh
```

## 运行仿真
接下来，进入到 workdir 目录下运行仿真，然后通过 gtkwave 打开仿真波形。

```bash
$ cd ../workdir
$ ../tools/run_case -sim_tool iverilog ../case/timer/timer_test.c
```

当你看到 Hello Friend！ 就表明你的仿真就跑起来了。

```bash
VCD info: dumpfile test.vcd opened for output.
        ******START TO LOAD PROGRAM******

Hello Friend!

timer test successfully
***************************************

*              Test Pass              *

***************************************

Step4 (Run simulation) is finished
```

用 gtkwave 打开 workdir 目录下的 test.vcd 波形文件，查看仿真波形，（打开波形文件需要图形化界面，我这里还安装了 VcXsrv，具体安装方法请自行搜索一下）波形图如下

```bash
$ gtkwave test.vcd
```

![wujian100_test_wave](https://s2.ax1x.com/2019/11/24/MOr25R.png)


好了，到这里你的仿真就跑起来了，然后接下来就是进行综合生成 bit 流文件了，下一篇文章在来更新 vivado 综合的步骤。

## 跑通仿真视频教程

<iframe src="//player.bilibili.com/player.html?aid=76320581&amp;cid=130546912&amp;page=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" width: 100%; height: 100%;></iframe>

Done!
