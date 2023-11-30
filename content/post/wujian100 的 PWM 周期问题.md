---
title: wujian100 的 PWM 周期问题
tags:
  - PWM
  - 数字前端
  - IC Design
categories:
  - IC Design
  - RISC-V
date: 2020-08-02
---

PWM 波形发生器实验结果
在 wujian100 的样例程序代码如下：

```c
int32_t  pwm_signal_test(uint32_t pwm_idx, uint8_t pwm_ch)
{
    int32_t ret;
    pwm_handle_t pwm_handle;

    example_pin_pwm_init();

    pwm_handle = csi_pwm_initialize(pwm_idx);

    if (pwm_handle == NULL) {
        printf("csi_pwm_initialize error\n");
        return -1;
    }

    ret = csi_pwm_config(pwm_handle, pwm_ch, 3000, 1500); //设置pwm周期3ms

    if (ret < 0) {
        printf("csi_pwm_config error\n");
        return -1;
    }

    csi_pwm_start(pwm_handle, pwm_ch);
    mdelay(20);

    ret = csi_pwm_config(pwm_handle, pwm_ch, 200, 150); //设置pwm周期200us

    if (ret < 0) {
        printf("csi_pwm_config error\n");
        return -1;
    }

    mdelay(20);
    csi_pwm_stop(pwm_handle, pwm_ch);

    csi_pwm_uninitialize(pwm_handle);

    return 0;

}
```

其中有两句配置函数
```c
ret = csi_pwm_config(pwm_handle, pwm_ch, 3000, 1500); //设置pwm周期3ms，占空比1500/3000
ret = csi_pwm_config(pwm_handle, pwm_ch, 200, 150); //设置pwm周期200us占空比50/200
```
这两句都是用来配置 pwm 周期的，是实际测试中 pwm 周期和占空比都没有问题。但是如果设置 pwm 周期为 5ms 时，需要修改这句话为：
```c
ret = csi_pwm_config(pwm_handle, pwm_ch, 5000, 2500);
```
在实际测试过程中会发现，他的周期实际是 2.5ms 并不是预期的 5ms，如果设置为 100ms 会发现 pwm 的实际输出周期是 2.5ms。实际输出是有问题的。

## 查找问题
### 检查软件问题
跟踪 csi_pwm_config 函数，发现在函数中会根据设置的周期进行时钟配置：
drv_pwm_config_clockdiv(handle, channel, cnt_div[count_div]); 由于 pwm 计数器是 16 位，所以软件会根据设置的周期值计算出要配置的数值，如果该数值超过 0xffff，就会设置分频系数，直到需要计数的值小于 0xffff 为止。

继续跟踪
```c
drv_pwm_config_clockdiv(handle, channel, cnt_div[count_div]);
```
我们可以看到

```c
void drv_pwm_config_clockdiv(pwm_handle_t handle, uint8_t channel, uint32_t div)
{
    PWM_NULL_PARAM_CHK_NORETVAL(handle);

    wj_pwm_priv_t *pwm_priv = handle;
    wj_pwm_reg_t *addr = (wj_pwm_reg_t *)(pwm_priv->base);
    addr->PWMCFG &= ~(7 << 24);

    switch (div) {
        case 1:
            addr->PWMCFG &= ~(PWM_CFG_CNTDIV_EN);
            break;

        case 2:
            addr->PWMCFG |= PWM_CFG_CNTDIV_EN | PWM_CFG_CNTDIV_2;
            break;

        case 5:
            addr->PWMCFG |= PWM_CFG_CNTDIV_EN | PWM_CFG_CNTDIV_5;
            break;
    ........
```

这个函数会对寄存器 PWMCFG 的第 25 位到第 27 位进行了赋值操作，查找数据手册发现

![PWMCFG](https://verimake.com/assets/files/2022-02-16/1645000545-562446-4.png)

第 28 位是分频使能，第 26 到 24 位是分频系数设置。

在 csi 库里提供了一个函数可以读取这几位的值来查看分频的设置：
```c
/**
  \brief       get pwm clock division.
  \param[in]   handle   pwm handle to operate.
  \param[in]   channel  channel num.
  \return      div      clock div.
*/
uint33_t drv_pwm_get_clockdiv(pwm_handle_t handle, uint8_t channel)
```

通过这个函数可以得到 PWMCFG 寄存器里的分频系数 cntdiv 的值。通过实验我们发现分频系数的值配置到寄存器里了，并且读回来的值也是配置的值。

**总结：所以软件上对于 pwm 的配置是没有问题的，配置 pwm 周期不是预期值不是软件问题。**

## 检查硬件问题
排除软件问题，那么出现 pwm 周期非预期值他的问题就只可能是 pwm 外设在设计时的硬件问题了。我们查找 wujian100 内部设计的问题，为了方便查看我们使用 verdi 来查看跟踪模块设计，这样效率高。

首先第一步配置 wujian100 工作路径：在 linux 系统中利用 source 将 wujian100 工作目录添加到系统环境变量。

第二步 tb 目录下的 tb_file.list 文件，这个文件里加载的顶层文件是 wujian100_open_top.v，并不是我们生成bit文件时的 wujian100_open_fpga_top.v 文件（该文件在 fpga 目录下），我们首先赋值 fpga 目录下的 wujian100_open_fpga_top.v 到 soc 目录下。修改文件 tb_file.list 里的第 3 行，将 wujian100_open_top.v 替换为 wujian100_open_fpga_top.v

第三步进入 tb 目录。使用 verdi -f tb_file.list 打开软件 verdi 并加载 tb_file.list 里列出的文件。（前提是你的 linux 系统安装了 verdi 软件）。

以上三步正确就会打开 wujian100 设计的模块图。

![wujian100 top](https://verimake.com/assets/files/2022-02-16/1645000585-452589-5.png)

查看选中打开该文件，查看文件名是不是wujian100_open_fpga_top.v

![wujian100_open_fpga_top.v](	https://verimake.com/assets/files/2022-02-16/1645000609-941857-5.png)

然后打开原理图。点击如图按钮：

![原理图](https://verimake.com/assets/files/2022-02-16/1645000638-957614-7.png)

打开 wujian100 的设计如图：

![wujian100](https://verimake.com/assets/files/2022-02-16/1645000667-457677-8.png)

接下来可以按文件查找相应模块，也可以双击原理图上的模块一层一层进入。

pwm 模块位于 PDU 下的 ahb1 上。一层一层进入查看下，定位到 pwm：

![pwm_sec_top](https://verimake.com/assets/files/2022-02-16/1645000688-38656-9.png)

继续进入 pwm_sec_top ,再进入 pwm 就是 pwm 外设的内部了。

![pwm_ctrl & pwm_aphif](https://verimake.com/assets/files/2022-02-16/1645000709-730693-10.png)

在这里有两部分，一个是 aphif 负责总线，ctrl 就是 pwm 的实际实现了。
进入 pwm_ctrl:

![pwm_ctrl](https://verimake.com/assets/files/2022-02-16/1645000735-911955-11.png)

我们发现有六个 pwm_gen。和数据手册上介绍的一样。

![6pwm_gen](https://verimake.com/assets/files/2022-02-16/1645000757-957734-12.png)

我们现在定位到左下角，放大看，这部分就是pwm的时钟部分：

![pwm_gen](https://verimake.com/assets/files/2022-02-17/1645088012-34467-image.png)

我们在 view 菜单下打开端口名称显示和模块内部端口名称显示。在图上我们可以看到 cntdiv[3:0] 控制了分频系数，分频系数会通过分频器（图上的 f）对 pclk 系统时钟进行分频，然后通过 gated_clk_cell 控制时钟的通过然后通过 clk_mux2 选择器送到后续的 pwm 发生器上作为发生器的时钟。我们双击模块就能够查看各自对应的 verilog 代码。我们在逐个查找时发现 gated_clk_cell（如下图）它的结构有问题 gated_clk_cell 双击它，查看它内部结构：

![gated_clk_cell](https://verimake.com/assets/files/2022-02-17/1645087886-987609-image.png)

如图这样一个很奇怪的结构，**直接就是 clk_in 输入，直接送到 clk_out 输出上去了。**结合上一张图我们可以看出 clk_in 就是 pclk 系统时钟，这样导致前面的分频没有任何作用，pclk 将会直接送到 pwm 发生器上作为 pwm 的时钟。这样不论你有没有设置分频，pwm 就只有系统时钟 pclk（21M)。这样 pwm 的信号周期无法修改。

反过来推到下，我们之前的实验设置周期 6ms 是得到的结果是 2.5ms，其实我们的分频系数是 2，由于时钟没有分频，导致我们的输出周期是 2.5ms，如果分频成功我们的周期就会是 2.5*2=5ms，同理，10ms 时的分频系数是 4。有兴趣的可以根据 sdk 提供的代码推到下，也可以用

```c
uint33_t drv_pwm_get_clockdiv(pwm_handle_t handle, uint8_t channel)
```
这个函数查看分频系数，然后分析下。

我们直到了问题出在模块 gated_clk_cell 上了，我们定位到模块对应的 verilog 文件，查找到代码位于 pwm.v 文件的 4186 行例化了一个叫做 gated_clk_cell 的模块，我们双击 gated_clk_cell 进入内部，双击模块定位到了 common.v 文件的 66 行，代码如下：

```verilog
`ifdef FPGA
assign clk_out = clk_in;
`else
Standard_Cell_CLK_GATE x_gated_clk_cell(
             .CK  (clk_in),
             .SE  (SE),
             .EN   (clk_en_bf_latch),
             .Q   (clk_out)
             );
`endif
```

这下一目了然了，由于定义了 FPGA 这个量，导致 assign clk_out=clk_in; 而下面的模块没有实现，所以最主要原因就是定义了 FPGA 这个量，这个量在哪里定义的呢，就是在 wujian100_open_fpga_top.v 这个文件的最开头定义的（第 37 行）：

![wujian100_open_fpga_top.v](https://verimake.com/assets/files/2022-02-16/1645000890-755634-15.png)

将这行用 // 注释，然后在 verdi 中点击 file 下选择 reload 设计，重新加载文件，我们再查看 geted_clk_cell 模块，得到如下图：

![geted_clk_cell 改](https://verimake.com/assets/files/2022-02-16/1645000913-900091-16.png)

这样 clk_in 不会直接送到 clk_out 输出了。

修改后用 vivado 重新分析综合生成 bit，下载到开发板上，我们发现输出的 pwm 的周期输出正确了。6ms，10ms 的周期也能生成了。

这里有一点注意，修改后源码用 vivado 建立工程，用 vivado 去 Synthesis，不要用官方方法，用 Synplify_pro 去 Synthesis。不然生成的 bit 下载开发板，输出的 pwm 周期会小一半。例如 11ms 周期只能输出 5ms。有兴趣的可以试下。

## 后续问题
查看这张结构图

![PWM](https://verimake.com/assets/files/2022-02-16/1645000937-329048-17.png)

仔细查看，不难发现，它的六个 pwm_gen 都是用的一个时钟源，都是 pclk 通过分频之后的时钟直接连接在了每一个 pwn_gen 的时钟上，六个时钟都是一个源，那么就会造成一个问题，他的六组 pwm 发生器只能同时产生一个频率（周期）的信号，例如 ch1 产生了 5ms，那个这时 ch2 也只能产生 5ms，没法产生 10ms 周期的 pwm，所有通道的周期都会被最后那个设置改成同一个频率，就是因为他们的时钟是同一个。这将怎么解决，有一个思路，就是每一个 pwm_gen 有各自的分频模块。怎么解决下一篇介绍。

本文转自 Verimake 论坛：
https://verimake.com/topics/122
