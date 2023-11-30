---
title: SDRAM 两次踏进同一条河
tags:
  - SDRAM
  - IC Design
categories:
  - IC Design
  - SDRAM
abbrlink: 10363
date: 2018-12-06 20:48:31
---

> *人不能两次踏进同一条河，但 SDRAM 可以*
> *——SDRAM的刷新*

## 前言
上周去了趟深圳，所以摸鱼拖更了，在那边发现真的是机遇越大的地方努力的脚步就越匆忙，某企业的 boss 是位国家科学技术奖的获得者，公司已经上市了，却依然吃 13 元的小店套餐，而且饭几乎是倒进嘴里的，5 分钟左右吃完马上就又去和合作对象谈判去了！
……
所以我们更要加油了，不然只会被大佬们越拉越远 …… 加油吧！

<!-- more -->

在初窥 sdram 中我们留了一个坑——首先我们在第一页就可以看到它的刷新周期是 64ms（这个重要参数将在后面进行具体介绍）
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/sdram_64ms.jpg)

今天我们就来填这个坑......

「人不能两次踏进同一条河流」是古希腊哲学家赫拉克利特说的。阐述「变」的哲学在米利都学派和毕达戈拉斯学派之后，爱菲斯的赫拉克利特创立了一种变的哲学。他的哲学充满了辩证法思想，对后来辩证法的发展产生过重大影响。

他形象地表达了他关于变的思想，说：「太阳每天都是新的。」他把存在的东西比作一条河，声称人不能两次踏进同一条河。因为当人第二次进入这条河时，是新的水流而不是原来的水流在流淌。SDRAM 不断地刷新，但却能保证刷新后的数据与刷新前一致，人踏进河是为什么我不知道，但是 SDRAM 正是为了保证内部电容的电量最终实现数据的不丢失才会不断地刷新。我们人做不到的事，就用 RTL 让 SDRAM 帮我们做了吧。

## 参数分析
首先我们来看 SDRAM 参数：8K Refresh Cycles/64 ms，意味着：
- 刷新速率 = 64ms / 8192 行 => 7us；
- 刷新时钟周期 = 7us * CPU 运行频率；

例：CPU 运行频率 50MHz 时钟周期 = 7.81us * 50MHz = 390.5；64ms 为刷新周期最大值，为保证可靠运行，实际刷新实间要稍小于 64ms；例：时钟周期 = 390.5 ≈ 380

这就意味着每 380 个时钟周期，我们便需要对我们的 SDRAM 进行一次刷新，那么进行刷新的时候需要进行哪些操作呢？我们还是回到我们的数据手册中。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/auto-refresh.jpg)

如图示，我们可以看到首先是要进行一次预充电操作(precharge)（同时选中所有的 bank），在经过 tRP 延时后进行一次自刷新操作(auto refresh)，再经过一次 tRC 后又进行一次自刷新操作(auto refresh)【注：实际使用中可以只进行一次自刷新操作】，最后进入到我们下一步 ……

那么根据第一篇《初窥 SDRAM》后我们知道以上的几个操作对应的指令码分别为：

| CMD | CS  | RAS | CAS | WE  |
|:---:|:---:|:---:|:---:|:---:|
| Precharge | 0 | 0 | 1 | 0 |
| Auto-Refresh | 0 | 0 | 0 | 1 |
| Nop | 0 | 1 | 1 | 1 |

延时 tRP，tRC 则分别对应 15ns（至少 1 个周期，实际操作中取 1 个周期），60ns （至少 3 个周期，实际操作中取 4 个周期）。

那么我们的设计即可为：一个 8us 的定时器，控制刷新的周期，作为刷新的开始信号；一个命令计数器，用于记录对应的延时节点（tRP，tRC）；最后即为达到对应节点输出对应指令即可。

由此踏进的河流变和 8us 前的河流是同一条河流的 ……

## 实现代码
具体实现代码如下:
上代码！
<!-- more <font color=#FF4500 > {% fold sdram_autoref.v  %} -->
```verilog
/*
File name: sdram_autoref
Function: Auto refresh for IS42S16320D-7TL SDRAM
Module name: sdram_autoref
Author: Ricky
Time: 20181130
*/

module sdram_autoref(
	//system signals
	input                   sys_clk    ,
	input                   sys_rst_n  ,

	//others
	input                   init_flag  ,
	input                   ref_en     ,

	output reg              ref_req    ,
	output wire             ref_flag   ,
	output reg   [3:0]      cmd_reg    ,
	output wire  [12:0] 	sdram_addr
);

/*==============================================================================
**********************Define Parameter and inside Signals***********************

Note: sys_clk=50MHz
      tRP|min=15ns >>> 20ns >>> 1sys_clk >>> [4:0] cnt_cmd
      tRC|min=60ns >>> 80ns >>> 4sys_clk >>> [4:0] cnt_cmd
      8K refresh cycles every 64ms >>> 8us >>> 380sys_clk
===============================================================================*/

reg [4:0]     cnt_cmd      ;
reg [8:0]     cnt_ref      ;
reg   	      flag_ref     ;

localparam delay_8us = 380 ;

//define sdram autorefresh cmd
localparam  precharge    = 4'b0010;
localparam  auto_refresh = 4'b0001;
localparam  nop          = 4'b0111;

/*==============================================================================
**********************************Main Logic************************************
==============================================================================*/

//auto_refresh counter
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
        cnt_ref <= 9'b0;
    else if(cnt_ref >= delay_8us)
            cnt_ref <= 9'b0;
    else if(init_flag == 1'b1)
            cnt_ref <= cnt_ref + 1'b1;
end

//ref flag signal
always  @(posedge sys_clk or negedge sys_rst_n) begin
        if(sys_rst_n == 1'b0)
                flag_ref        <=      1'b0;
        else if(ref_flag == 1'b1)
                flag_ref        <=      1'b0;
        else if(ref_en == 1'b1)
                flag_ref        <=      1'b1;
end

//cmd counter
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
        cnt_cmd <= 4'd0;
    else if (flag_ref == 1'b1)
             cnt_cmd <= cnt_cmd + 1'b1;
    else     cnt_cmd <= 4'b0;
end

//cmd
always @(posedge sys_clk or negedge sys_rst_n) begin
    if(~sys_rst_n)
        cmd_reg <= nop;
    else
        case(cnt_cmd)
            1:       cmd_reg <= precharge;
            2:       cmd_reg <= auto_refresh;
            6:       cmd_reg <= auto_refresh;
            default  cmd_reg <= nop;
        endcase
end

//request signal(8K refresh cycles every 64ms >>> 8us >>> 380sys_clk)
always @(posedge sys_clk or negedge sys_rst_n)begin
    if(~sys_rst_n)
        ref_req <= 1'b0;
    else if(ref_en)
        ref_req <= 1'b0;
    else if(cnt_ref >= delay_8us)
        ref_req <= 1'b1;
end

assign sdram_addr = 13'b0010000000000;
assign ref_flag   = (cnt_cmd >= 9)? 1'b1 : 1'b0;

endmodule
```
{% endfold %}
</font>

实现后我们可以看到毎 8us 完成一次所有 bank 的刷新

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/vsimrun.jpg)

## 仿真波形
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/refresh-wave.jpg)
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/refresh-wave1.jpg)

**By Ricky**
