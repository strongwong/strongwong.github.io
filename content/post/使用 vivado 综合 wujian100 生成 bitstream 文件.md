---
title: 使用 vivado 综合 wujian100 生成 bitstream 文件
tags:
  - RISC-V
  - 平头哥
  - Verilog
  - IC Design
  - wujian100
categories:
  - IC Design
  - RISC-V
date: 2019-11-24
---

## 综合环境

上一篇 blog 呢，我记录一下运行 wujian100 的一些仿真过程，这篇 blog 我将简单介绍一下使用 vivado 来综合 wujian100 需要注意的一些地方。

首先，说明一下我的综合环境，我是在 WSL 下安装的 vivado 2018.3 版本，然后是完全 vivado 环境下综合生成 bitstream 文件，因为没有安装 synplify，所以就没有使用官方推荐的 synplify 进行综合。

> 系统：Windows 10 ， WSL Ubuntu 18.04
>
> 软件: vivado 2018.3


## 安装 vivado

首先，你如果没有安装 vivado 就先安装一下 vivado，在命令行下自己运行 ./xsetup 即可，安装完成后记得设置一下环境变量，具体的安装方法，我这里就不做详细介绍了，请自行搜索。

```bash
$ ./xsetup
```

## 打开 vivado 新建工程

接下来，我们进入到 wujian100_open 的 fpga->vivado 目录下，在命令行下输入 vivado ，启动 vivado。

```bash
$ vivado
```

![start_vivado.png](https://s2.ax1x.com/2019/12/01/QeXyMn.md.png)

vivado 启动完成之后，我们来创建应该新工程，点击 Create project ，Next->填写工程名称，Next-> 选择 RTL Project，Next-> 选择 wujian100 这个开发板对应的 FPGA 型号 xc7a200tfbg484-1，最后 Finish 即可，工程创建结束。

![QejBTK.png](https://s2.ax1x.com/2019/12/01/QejBTK.png)
![QexDRe.png](https://s2.ax1x.com/2019/12/01/QexDRe.png)
![QexvJU.png](https://s2.ax1x.com/2019/12/01/QexvJU.png)

## 添加源码综合

工程创建完了之后我们添加 wujian100 的源码来进行综合。这里需要注意的是源码中有两个 top 文件，我们这里添加 wujian100_open_fpga_top.v 文件。然后添加 soc目录下的源码，都添加完成之后，vivado 会自动分析，这时我们会看到有错误，这是因为这四个文件是头文件，我们需要手动更改一下文件格式。

![QmFW80.png](https://s2.ax1x.com/2019/12/01/QmFW80.png)

接下来我们继续添加约束文件，这里的管脚约束文件，我们就是所以官方提供的这个即可，时序约束文件这里使用一位群友提供的即可。把这个时序约束文件和官方的 xdc 放在一个目录下就可以了，添加完成之后，我们进行综合即可。但是在综合之前我们需要更改一下官方的 xdc，有一个地方在 vivado 下进行综合会报错，就是第 33 行这句， 把 _c 去掉即可。还有一个地方需要注意的是把 wujian100_open_fpga_top.v 的优先级调一下。

时序约束文件：
```bash
create_clock -name {EHS} [get_ports PIN_EHS] -period 50 -waveform {0 25}
create_clock  -name {JTAG_CLK} [get_ports PAD_JTAG_TCLK] -period 1000 -waveform {0 500}

set_clock_groups -asynchronous -name {clkgroup_1} -group [get_clocks {EHS JTAG_CLK}]

set_false_path -through [get_ports PIN_EHS]

#set_clock_groups -name {Inferred_clkgroup_0} -asynchronous -group [get_clocks {wujian100_open_top|PAD_JTAG_TCLK}]

set_property ASYNC_REG TRUE [get_cells {x_aou_top/x_rtc0_sec_top/x_rtc_pdu_top/x_rtc_clr_sync/pclk_load_sync2_reg}]
set_property ASYNC_REG TRUE [get_cells {x_aou_top/x_rtc0_sec_top/x_rtc_pdu_top/x_rtc_clr_sync/rtc_load_sync2_reg}]
set_property ASYNC_REG TRUE [get_cells {x_aou_top/x_rtc0_sec_top/x_rtc_pdu_top/x_rtc_clr_sync/pclk_load_sync1_reg}]
set_property ASYNC_REG TRUE [get_cells {x_aou_top/x_rtc0_sec_top/x_rtc_pdu_top/x_rtc_clr_sync/rtc_load_sync1_reg}]
set_property ASYNC_REG TRUE [get_cells {x_cpu_top/CPU/x_cr_had_top/A15d/A74/A10b_reg}]
set_property ASYNC_REG TRUE [get_cells {x_cpu_top/CPU/x_cr_had_top/A15d/A74/A18597_reg}]
set_property ASYNC_REG TRUE [get_cells {x_cpu_top/CPU/x_cr_had_top/A15d/A1862d/A10b_reg}]
set_property ASYNC_REG TRUE [get_cells {x_cpu_top/CPU/x_cr_had_top/A15d/A1862d/A18597_reg}]
set_property ASYNC_REG TRUE [get_cells {x_cpu_top/CPU/x_cr_had_top/A15d/A75/A10b_reg}]
set_property ASYNC_REG TRUE [get_cells {x_cpu_top/CPU/x_cr_had_top/A15d/A75/A18597_reg}]
```

```bash
# set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PAD_JTAG_TCLK_c]
# 改成下面的
set_property CLOCK_DEDICATED_ROUTE FALSE [get_nets PAD_JTAG_TCLK]
```

## 综合完成生成 bit 文件

![QmM4H0.png](https://s2.ax1x.com/2019/12/01/QmM4H0.png)

综合完成之后呢，我们可以看到啊，这个时序约束都是符合要求的，接下来，我们就可以输出比特流文件上 FPGA 做实验了。

## 视频教程

### vivado 综合

<iframe src="//player.bilibili.com/player.html?aid=77962964&amp;cid=133377281&amp;page=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" width: 100%; height: 100%; left: 0; top: 0;></iframe>

### 上 FPGA 测试

<iframe src="//player.bilibili.com/player.html?aid=79137613&amp;cid=135422810&amp;page=1" scrolling="no" border="0" frameborder="no" framespacing="0" allowfullscreen="true" width: 100%; height: 100%; left: 0; top: 0;></iframe>

