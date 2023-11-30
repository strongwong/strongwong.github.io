---
title: 初窥 SDRAM
tags:
  - SDRAM
  - IC Design
categories:
  - IC Design
  - SDRAM
abbrlink: 1740
date: 2018-11-24 17:21:08
---

## 前言
上次挖的坑现在来填，在我们把 SDRAM 控制器接进 AHB 总线之前，我们先来设计一个 SDRAM 控制器。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/hexo_img.jpg)

<!-- more -->

引用知乎上看见的一段话：
> 在做这个 SDRAM 控制器之前，博主有一个疑问，对于学生来说，是否有必要学习用纯 Verilog 写一个 SDRAM 控制器？因为目前广告厂（X）和牙膏厂（A）都有了 DDR IP Core，而 SDRAM 的控制 IP 更是漫天飞舞，对于要实现一个应用可以直接调用 IP Core，只需要对其接口操作即可。对于开发者来说，与其费时费力用 Verilog 去写一个性能差而且老的 SDRAM 控制器，还不如直接调用官方经过打磨的更为先进 IP Core。所以博主特地来号称平均学历 211，平均月薪 7、8 万的知（bi）乎提出了这个问题，得到的解答博主总结大致如下。
>
> 对于学生这个身份来说，应该是要以学习为主要目的，虽然说目前企业为了加快项目进度会直接使用 IP Core，但是我们以学为本的初衷不应该为了避过难点而直接不去尝试，就比如我们刚开始学 Verilog 的时候肯定都会写过分频器，那么为什么不直接去学更简单精度更高 PLL IP Core 呢？从一个新手逐渐成长成一个老手都是由简单到复杂，由基础到提升，这是一个必经的过程。这也就是很多高校还是会开设汇编语言编写单片机的课程，学 FPGA 全用 IP Core 和学单片机全用库函数是一个道理。这是其一。
>
> 第二，写一个 SDRAM 控制器还是可以锻炼一些典型的技能。
> - 看官方文档
> - 根据时序图设计 SDRAM 逻辑，使用状态机
> - 配合仿真模型写测试仿真
> - 调试，提高频率，让你的 SDRAM 跑的更快
> - 研究时序约束
> 
> 这一套做下来，你就可以提高一个层次了，经历过和没经历过是有质的区别。其实博主在提问的时候心中早已有了答案，只是还没有足够的信念去完成这个事情，当时看到很多业界前辈都支持去写的时候，博主心里也是比较开心的。之前博主已经学一些 SDRAM 的基础知识，只是当时水平还不够，没有坚持下去，心里一直不甘。趁着最近两个月之内没有什么事情要忙，所以决定要再次死磕 SDRAM。

## 正文
### SDRAM 基本介绍
关于 SDRAM 的基本概念，在这再引用《终极内存指南》这篇文章中的一段话:
> SDRAM（Synchronous Dynamic Random Access Memory），同步动态随机存储器。同步是指 Memory 工作需要同步时钟，内部的命令的发送与数据的传输都以它为基准；动态是指存储阵列需要不断刷新来保证存储的数据不丢失，因为 SDRAM 中存储数据是通过电容来工作的，大家知道电容在自然放置状态是会有放电的，如果电放完了，也就意味着 SDRAM 中的数据丢失了，所以 SDRAM 需要在电容的电量放完之前进行刷新；随机是指数据不是线性依次存储，而是自由指定地址进行数据的读写。

下面再简单看一下 SDRAM 的内部结构。
对于 SDRAM 的内容结构，就如同 Excel 的表格（如下图所示），即一个单元格就是一个存储地址。要确定具体的存储位置，只需要知道行地址（row-address ）和列地址（column address ）即可。
![excel](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/Excel.jpg)

一个常见的 SDRAM 中的一个 BANK 就有如上图所示的 13 行 9 列，通常一个 SDRAM 中有 4 个 BANK，那么 SDRAM（DDR 类似）的计算公式就是：

> SDRAM(DDR容量) = 2^(row-address) × 2^(column-address) × 2^(bank-address) × datawidth
> = 2^(row-address) × 2^(column-address) × bank数 × datawidth


以 DE10-LITE 开发板板载的 SDRAM-IS42S16320D-7TL 为例，标称为 64MB。根据芯片手册（如下图所示）我们可以看见其行地址宽度为 13，列地址宽度为 9（此时数据位宽为 32），则根据公式我们可以算出其容量确实为 64MB

> 2^13 × 2^9 × 4 × 32 = 536870912 b
> ⇒ 536870912 b ÷ 1024 = 524288 kb
> ⇒ 524288 kb ÷ 1024 = 512 Mb
> ⇒ 512 Mb ÷ 8 = 64 MB

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/DE10_lite_sdram.jpg)

### SDRAM 芯片介绍
既然都打开了芯片手册（IS42S16320D-7TL），那就不要关上了，那我们再来看看芯片手册中的那些重要参数。
首先我们在第一页就可以看到它的刷新周期是 64ms（这个重要参数将在后面进行具体介绍）
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/sdram_64ms.jpg)

在上文中我们已经提到了该芯片的行地址和列地址，我们需要注意的是其行列地址是复用的，其他相关引脚的功能描述都有介绍。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/IS42S16320D_7TL_sdram.jpg)

### SDRAM 的初始化及寄存器的配置
SDRAM 初始化时序图如图所示，首先上电后，电源 Vcc 及 CLK 稳定时间至少 100us，然后对所有 BANK 进行预充电（precharge），经过 tRP 后给 auto refresh 命令，再经过 tRC 后再次 auto refresh 命令，再进过 tRC 后进行模式寄存器的配置。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/sdram_%E6%97%B6%E5%BA%8F.jpg)

那么以上命令是如何实现的呢，当时就是给与相应管脚的高低电平控制，由此实现，那么这就回到了我们数电的功能真值表（在之前我们就有提到过，数字 IC 终归是数字电路，不要把它搞成了编程项目），我们将下图的真值表以使用顺序总结为表格形式，方便接下来的 RTL 表述。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/%E7%9C%9F%E5%80%BC%E8%A1%A8.jpg)

| CMD   | CS | RAS | CAS | WE |
|:---:|:---:|:---:|:---:|:---:|
| Precharge | 0 | 0 | 1 | 0 |
| Auto-Refresh | 0 | 0 | 0 | 1 |
| Nop | 0 | 1 | 1 | 1 |
| Mode | 0 | 0 | 0 | 0 |

在了解到命令描述后我们还需要注意时间的间隔，在时序图中只告知了我们 T = 100us，而其余的 tRP，tRC，tMRD 均未告诉我们，这是因为通常一个芯片手册中有多种型号的芯片，因此我们需要去查看 AC characteristic 表格，根据芯片型号去确定时间。我们的板载芯片型号为 IS42S16320D-7TL，因此我们选择 `-7` 对应的时间，则 tRP = 15ns，tRC = 60ns，tMRD = 14ns

接下来我们就要进入到模式配置，模式配置的配置说明如下图所示：
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/Mode_reg_config.jpg)

A0-A2 为突发长度控制，即表示单次读或者写的时候的数据『长度』，本次突发长度参数我们设为 010。A3 突发模式通常设为 0。A4-A6 为潜伏期控制，专门针对读命令时，当给出读命令后，若有设置 CAS latency 则会延迟相应的周期数后给出数据，本次潜伏期参数我们设为 011，A9 突发模式通常设为 0。则最终我们初始化设置参数为 13'b0_0000_0011_0010

至此，我们便可以开始着手设计我们的初始化模块了，首先时序图上 T = 100us Min，则我们取 200us = 200,000ns 在不经过 PLL 的前提下，DE10LITE 开发板默认提供的时钟频率为 50MHz，则一个周期为 20ns，因此 T 延时可以取 10,000clk。延时后我们执行 precharge 命令。之后执行 tRP = 15ns Min，我们的 tRP 延迟就可以取 1clk（至少满足 15ns 的最低要求），然后执行 auto refresh 命令，tRC = 60ns Min 则延迟可取为 4clk，然后再次执行 auto refresh 命令，在这期间一共 9 个 clk。具体的设计可以首先设计一个 200us 的不自清零的计数器；设计一个对应的 200us 计数器标志位；针对 tRP 和 tRC 设计一个计数器，分别实现监测计数到对应的周期发出对应的命令；命令寄存器用来存放对应的命令；最后完成初始化操作后给一个初始化完成的标志位信号。

下面是具体实现的描述语言：
<font color=#FF4500 > {% fold sdram_init.v  %}
```verilog
/*
File name: sdram_init
Function: Power on initialization for IS42S16320D-7TL SDRAM
Module name: sdram_init
Author: Ricky
Time: 20181119
*/

module sdram_init(
	//system signals
	input					sys_clk				,
	input					sys_rst_n			,
	
	//others
	output reg		    [3:0] 	cmd_reg				,
	output wire		    [12:0] 	sdram_addr			,
	output wire				init_flag
	
);

/*============================================================================== 
**********************Define Parameter and inside Signals***********************


Note: 	syssys_clk=50MHz
		T|min=100us >>> 200us=200,000ns >>> 10,000sys_clk >>> [13:0] cnt_200us
		tRP|min=15ns >>> 20ns >>> 1sys_clk >>> [4:0] cnt_cmd
		tRC|min=60ns >>> 80ns >>> 4sys_clk >>> [4:0] cnt_cmd
===============================================================================*/
reg [13:0] 		cnt_200us		;
wire 			cnt_200us_flag	;
reg [4:0]		cnt_cmd			;

//define sdram initial cmd
localparam		precharge    = 4'b0010;
localparam		auto_refresh = 4'b0001;
localparam		nop			 = 4'b0111;
localparam 		modeset		 = 4'b0000;

/*============================================================================== 
**********************************Main Logic************************************
==============================================================================*/
//T=200us  counter
always @(posedge sys_clk or negedge sys_rst_n) begin
	if(~sys_rst_n)
		cnt_200us <= 13'd0;
	else
		if(cnt_200us_flag == 1'b0)
			cnt_200us <= cnt_200us + 1'b1;
		else
			cnt_200us <= cnt_200us;
end

//cmd counter
always @(posedge sys_clk or negedge sys_rst_n) begin
	if(~sys_rst_n) 
		cnt_cmd <= 4'd0;
	else
		if (cnt_200us_flag == 1'b1 && init_flag == 1'b0)
			cnt_cmd <= cnt_cmd + 1'b1;
end

//cmd
always @(posedge sys_clk or negedge sys_rst_n) begin
	if(~sys_rst_n) 
		cmd_reg <= nop;
	else
		if(cnt_200us_flag == 1'b1)
			case(cnt_cmd)
				0: 			cmd_reg <= precharge	;
				1: 			cmd_reg <= auto_refresh	;
				5: 			cmd_reg <= auto_refresh	;
				9: 			cmd_reg <= modeset	;
				default: 	        cmd_reg <= nop		;
			endcase
end

assign cnt_200us_flag = (cnt_200us >= 10000) ? 1'b1:1'b0;
assign init_flag = (cnt_cmd >= 9) ? 1'b1:1'b0;
assign sdram_addr = (cmd_reg == modeset) ? 13'b0000000110010 : 13'b0010000000000;

endmodule
```
{% endfold %}
</font>

<font color=#FF4500 > {% fold sdram_top.v %} 
```verilog
 /*
File name: sdram_top
Author: Ricky
Time: 20181121
*/
module sdram(
	//system signals
	input			sys_clk			,
	input			sys_rst_n		,
	//sdram pin
	output wire		sdram_clk		,
	output wire     [12:0]	sdram_addr		,
	output wire     [1:0] 	sdram_bank		,
	output wire		sdram_cas_n		,
	output wire		sdram_cke		,
	output wire		sdram_cs_n		,
	output wire	[1:0]	sdram_dqm		,
	output wire		sdram_ras_n		,
	output wire		sdram_we_n		,
	
	inout		[15:0]	sdram_dq
);

/*============================================================================== 
**********************Define Parameter and inside Signals***********************
===============================================================================*/
wire init_flag		;
wire [3:0] init_cmd_reg	;
wire [12:0] init_addr	;

/*============================================================================== 
**********************************Main Logic************************************
==============================================================================*/
assign sdram_addr = init_addr;
assign {sdram_cs_n, sdram_ras_n, sdram_cas_n, sdram_we_n} = init_cmd_reg;
assign sdram_clk = ~sys_clk;

assign sdram_dqm = 2'b00;
assign sdram_cke = 1'b1;

//instantiating sdram_init module
sdram_init sdram_init(
	//system signals
	.		sys_clk			(sys_clk)			,
	.		sys_rst_n		(sys_rst_n)			,
		//others
	.		cmd_reg			(init_cmd_reg)		,
	.		sdram_addr		(init_addr)			,
	.		init_flag       (init_flag)
	
);

endmodule
```
{% endfold %}
</font>

<font color=#FF4500 > {% fold sdram_tb.v %}
```verilog
/*
File name: sdram_tb
Function: Testbench for power on initialization for IS42S16320D-7TL SDRAM
Author: Ricky
Time: 20181123
*/
`timescale 1ns/1ns
module sdram_tb;

reg			sys_clk;
reg 		sys_rst_n;
wire				sdram_clk		;
wire		[12:0]	sdram_addr		;
wire 		[1:0] 	sdram_bank		;
wire				sdram_cas_n		;
wire				sdram_cke		;
wire				sdram_cs_n		;	
wire		[1:0]	sdram_dqm		;
wire				sdram_ras_n		;
wire				sdram_we_n		;

wire		[15:0]	sdram_dq		;

initial begin
	sys_clk = 1;
	sys_rst_n <= 0;
	#100
	sys_rst_n <= 1;
end

// 20ns/clock
always #10 sys_clk = ~sys_clk;

/* defparam	sdram_model_plus.addr_bits =	13			;
defparam	sdram_model_plus.data_bits = 	16			;	
defparam	sdram_model_plus.col_bits  =	9 			;
defparam	sdram_model_plus.mem_sizes =	2*1024*1024	; */

//instantiating sdram_init module
sdram sdraminit(
	//system signals
	.sys_clk                 (sys_clk  )		,
	.sys_rst_n               (sys_rst_n)		,
	//sdram pin
	.sdram_clk               (sdram_clk)		,
	.sdram_addr              (sdram_addr)		,
	.sdram_bank              (sdram_bank)		,
	.sdram_cas_n             (sdram_cas_n)		,
	.sdram_cke               (sdram_cke)		,	
	.sdram_cs_n              (sdram_cs_n)		,
	.sdram_dqm               (sdram_dqm)		,
	.sdram_ras_n             (sdram_ras_n)		,
	.sdram_we_n              (sdram_we_n)		,
	
	.sdram_dq                 (sdram_dq)
);

//instantiating sdram_model module
sdram_model_plus sdram(
	.Dq					(sdram_dq)				, 
	.Addr				(sdram_addr)			, 
	.Ba					(sdram_bank)			, 
	.Clk				(sdram_clk)				, 
	.Cke				(sdram_cke)				, 
	.Cs_n				(sdram_cs_n)			, 
	.Ras_n				(sdram_ras_n)			, 
	.Cas_n				(sdram_cas_n)			, 
	.We_n				(sdram_we_n)			, 
	.Dqm				(sdram_dqm)				,
	.Debug				(1'b1)
);

endmodule
```
{% endfold %}
</font>

仿真模型（见附件）一共有两个分别是镁光官方仿真模型以及国内大神基于镁光模型进行修改后便于调试的版本，使用任意一版均可。这里我采用的是 sdram_model.v

<font color=#FF4500 > {% fold sdram_model.v %}
```verilog
/***************************************************************************************
作者：    李晟
2003-08-27    V0.1    李晟 
 
 添加内存模块倒空功能，在外部需要创建事件：sdram_r ,本SDRAM的内容将会按Bank 顺序damp out 至文件
 sdram_data.txt 中
×××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××××*/
//2004-03-04    陈乃奎    修改原程序中将BANK的数据转存入TXT文件的格式
//2004-03-16    陈乃奎    修改SDRAM 的初始化数据
//2004/04/06    陈乃奎    将SDRAM的操作命令以字符形式表示，以便用MODELSIM监视
//2004/04/19    陈乃奎    修改参数 parameter tAC  =   8;
//2010/09/17    罗瑶    修改sdram的大小，数据位宽，dqm宽度;
/****************************************************************************************
*
*    File Name:  sdram_model.V  
*      Version:  0.0f
*         Date:  July 8th, 1999
*        Model:  BUS Functional
*    Simulator:  Model Technology (PC version 5.2e PE)
*
* Dependencies:  None
*
*       Author:  Son P. Huynh
*        Email:  sphuynh@micron.com
*        Phone:  (208) 368-3825
*      Company:  Micron Technology, Inc.
*        Model:  sdram_model (1Meg x 16 x 4 Banks)
*
*  Description:  64Mb SDRAM Verilog model
*
*   Limitation:  - Doesn't check for 4096 cycle refresh
*
*         Note:  - Set simulator resolution to "ps" accuracy
*                - Set Debug = 0 to disable $display messages
*
*   Disclaimer:  THESE DESIGNS ARE PROVIDED "AS IS" WITH NO WARRANTY 
*                WHATSOEVER AND MICRON SPECIFICALLY DISCLAIMS ANY 
*                IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR
*                A PARTICULAR PURPOSE, OR AGAINST INFRINGEMENT.
*
*                Copyright ?1998 Micron Semiconductor Products, Inc.
*                All rights researved
*
* Rev   Author          Phone         Date        Changes
* ----  ----------------------------  ----------  ---------------------------------------
* 0.0f  Son Huynh       208-368-3825  07/08/1999  - Fix tWR = 1 Clk + 7.5 ns (Auto)
*       Micron Technology Inc.                    - Fix tWR = 15 ns (Manual)
*                                                 - Fix tRP (Autoprecharge to AutoRefresh)
*
* 0.0a  Son Huynh       208-368-3825  05/13/1998  - First Release (from 64Mb rev 0.0e)
*       Micron Technology Inc.
****************************************************************************************/

`timescale 1ns / 100ps

module sdram_model_plus (Dq, Addr, Ba, Clk, Cke, Cs_n, Ras_n, Cas_n, We_n, Dqm,Debug);

    parameter addr_bits =    13;
    parameter data_bits =    16;
    parameter col_bits  =    9;
    parameter mem_sizes =    4*1024*1024 -1;//1 Meg 

    inout     [data_bits - 1 : 0] Dq;
    input     [addr_bits - 1 : 0] Addr;
    input                 [1 : 0] Ba;
    input                         Clk;
    input                         Cke;
    input                         Cs_n;
    input                         Ras_n;
    input                         Cas_n;
    input                         We_n;
    input                 [1 : 0] Dqm;          //高低各8bit
    //added by xzli
    input              Debug;

    reg       [data_bits - 1 : 0] Bank0 [0 : mem_sizes];//存储器类型数据
    reg       [data_bits - 1 : 0] Bank1 [0 : mem_sizes];
    reg       [data_bits - 1 : 0] Bank2 [0 : mem_sizes];
    reg       [data_bits - 1 : 0] Bank3 [0 : mem_sizes];

    reg                   [1 : 0] Bank_addr [0 : 3];                // Bank Address Pipeline
    reg        [col_bits - 1 : 0] Col_addr [0 : 3];                 // Column Address Pipeline
    reg                   [3 : 0] Command [0 : 3];                  // Command Operation Pipeline
    reg                   [3 : 0] Dqm_reg0, Dqm_reg1;               // DQM Operation Pipeline
    reg       [addr_bits - 1 : 0] B0_row_addr, B1_row_addr, B2_row_addr, B3_row_addr;

    reg       [addr_bits - 1 : 0] Mode_reg;
    reg       [data_bits - 1 : 0] Dq_reg, Dq_dqm;
    reg       [col_bits - 1 : 0] Col_temp, Burst_counter;

    reg                           Act_b0, Act_b1, Act_b2, Act_b3;   // Bank Activate
    reg                           Pc_b0, Pc_b1, Pc_b2, Pc_b3;       // Bank Precharge

    reg                   [1 : 0] Bank_precharge     [0 : 3];       // Precharge Command
    reg                           A10_precharge      [0 : 3];       // Addr[10] = 1 (All banks)
    reg                           Auto_precharge     [0 : 3];       // RW AutoPrecharge (Bank)
    reg                           Read_precharge     [0 : 3];       // R  AutoPrecharge
    reg                           Write_precharge    [0 : 3];       //  W AutoPrecharge
    integer                       Count_precharge    [0 : 3];       // RW AutoPrecharge (Counter)
    reg                           RW_interrupt_read  [0 : 3];       // RW Interrupt Read with Auto Precharge
    reg                           RW_interrupt_write [0 : 3];       // RW Interrupt Write with Auto Precharge

    reg                           Data_in_enable;
    reg                           Data_out_enable;

    reg                   [1 : 0] Bank, Previous_bank;
    reg       [addr_bits - 1 : 0] Row;
    reg        [col_bits - 1 : 0] Col, Col_brst;

    // Internal system clock
    reg                           CkeZ, Sys_clk;

    reg    [24:0]    dd;
    
    // Commands Decode
    wire      Active_enable    = ~Cs_n & ~Ras_n &  Cas_n &  We_n;
    wire      Aref_enable      = ~Cs_n & ~Ras_n & ~Cas_n &  We_n;
    wire      Burst_term       = ~Cs_n &  Ras_n &  Cas_n & ~We_n;
    wire      Mode_reg_enable  = ~Cs_n & ~Ras_n & ~Cas_n & ~We_n;
    wire      Prech_enable     = ~Cs_n & ~Ras_n &  Cas_n & ~We_n;
    wire      Read_enable      = ~Cs_n &  Ras_n & ~Cas_n &  We_n;
    wire      Write_enable     = ~Cs_n &  Ras_n & ~Cas_n & ~We_n;

    // Burst Length Decode
    wire      Burst_length_1   = ~Mode_reg[2] & ~Mode_reg[1] & ~Mode_reg[0];
    wire      Burst_length_2   = ~Mode_reg[2] & ~Mode_reg[1] &  Mode_reg[0];
    wire      Burst_length_4   = ~Mode_reg[2] &  Mode_reg[1] & ~Mode_reg[0];
    wire      Burst_length_8   = ~Mode_reg[2] &  Mode_reg[1] &  Mode_reg[0];

    // CAS Latency Decode
    wire      Cas_latency_2    = ~Mode_reg[6] &  Mode_reg[5] & ~Mode_reg[4];
    wire      Cas_latency_3    = ~Mode_reg[6] &  Mode_reg[5] &  Mode_reg[4];

    // Write Burst Mode
    wire      Write_burst_mode = Mode_reg[9];

    wire      Debug;        // Debug messages : 1 = On; 0 = Off
    wire      Dq_chk           = Sys_clk & Data_in_enable;      // Check setup/hold time for DQ

    reg        [31:0]    mem_d;
    
    event    sdram_r,sdram_w,compare;
    
    
   
   
    assign    Dq               = Dq_reg;                        // DQ buffer

    // Commands Operation
    `define   ACT       0
    `define   NOP       1
    `define   READ      2
    `define   READ_A    3
    `define   WRITE     4
    `define   WRITE_A   5
    `define   PRECH     6
    `define   A_REF     7
    `define   BST       8
    `define   LMR       9

//    // Timing Parameters for -75 (PC133) and CAS Latency = 2
//    parameter tAC  =   8;    //test 6.5
//    parameter tHZ  =   7.0;
//    parameter tOH  =   2.7;
//    parameter tMRD =   2.0;     // 2 Clk Cycles
//    parameter tRAS =  44.0;
//    parameter tRC  =  66.0;
//    parameter tRCD =  20.0;
//    parameter tRP  =  20.0;
//    parameter tRRD =  15.0;
//    parameter tWRa =   7.5;     // A2 Version - Auto precharge mode only (1 Clk + 7.5 ns)
//    parameter tWRp =  0.0;     // A2 Version - Precharge mode only (15 ns)

    // Timing Parameters for -7 (PC143) and CAS Latency = 3
    parameter tAC  =   6.5;    //test 6.5
    parameter tHZ  =   5.5;
    parameter tOH  =   2;
    parameter tMRD =   2.0;     // 2 Clk Cycles
    parameter tRAS =  48.0;
    parameter tRC  =  70.0;
    parameter tRCD =  20.0;
    parameter tRP  =  20.0;
    parameter tRRD =  14.0;
    parameter tWRa =   7.5;     // A2 Version - Auto precharge mode only (1 Clk + 7.5 ns)
    parameter tWRp =  0.0;     // A2 Version - Precharge mode only (15 ns)
    
    // Timing Check variable
    integer   MRD_chk;
    integer   WR_counter [0 : 3];
    time      WR_chk [0 : 3];
    time      RC_chk, RRD_chk;
    time      RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3;
    time      RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3;
    time      RP_chk0, RP_chk1, RP_chk2, RP_chk3;

    integer    test_file;
    
    //*****display the command of the sdram**************************************
    
    parameter    Mode_Reg_Set    =4'b0000;
    parameter    Auto_Refresh    =4'b0001;
    parameter    Row_Active    =4'b0011;
    parameter    Pre_Charge    =4'b0010;
    parameter    PreCharge_All    =4'b0010;
    parameter    Write        =4'b0100;
    parameter    Write_Pre    =4'b0100;
    parameter    Read        =4'b0101;
    parameter    Read_Pre    =4'b0101;
    parameter    Burst_Stop    =4'b0110;
    parameter    Nop        =4'b0111;
    parameter    Dsel        =4'b1111;

    wire    [3:0]    sdram_control;
    reg            cke_temp;
    reg        [8*13:1]    sdram_command;
   
    always@(posedge Clk)
    cke_temp<=Cke;

    assign    sdram_control={Cs_n,Ras_n,Cas_n,We_n};

    always@(sdram_control or cke_temp)
    begin
        case(sdram_control)
            Mode_Reg_Set:    sdram_command<="Mode_Reg_Set";
            Auto_Refresh:    sdram_command<="Auto_Refresh";
            Row_Active:    sdram_command<="Row_Active";
            Pre_Charge:    sdram_command<="Pre_Charge";
            Burst_Stop:    sdram_command<="Burst_Stop";
            Dsel:        sdram_command<="Dsel";

            Write:        if(cke_temp==1)
                        sdram_command<="Write";
                    else
                        sdram_command<="Write_suspend";
                        
            Read:        if(cke_temp==1)
                        sdram_command<="Read";
                    else
                        sdram_command<="Read_suspend";
                        
            Nop:        if(cke_temp==1)
                        sdram_command<="Nop";
                    else
                        sdram_command<="Self_refresh";
                        
            default:    sdram_command<="Power_down";
        endcase
    end

    //*****************************************************
    
    initial 
        begin
        //test_file=$fopen("test_file.txt");
    end

    initial 
        begin
        Dq_reg = {data_bits{1'bz}};
        {Data_in_enable, Data_out_enable} = 0;
        {Act_b0, Act_b1, Act_b2, Act_b3} = 4'b0000;
        {Pc_b0, Pc_b1, Pc_b2, Pc_b3} = 4'b0000;
        {WR_chk[0], WR_chk[1], WR_chk[2], WR_chk[3]} = 0;
        {WR_counter[0], WR_counter[1], WR_counter[2], WR_counter[3]} = 0;
        {RW_interrupt_read[0], RW_interrupt_read[1], RW_interrupt_read[2], RW_interrupt_read[3]} = 0;
        {RW_interrupt_write[0], RW_interrupt_write[1], RW_interrupt_write[2], RW_interrupt_write[3]} = 0;
        {MRD_chk, RC_chk, RRD_chk} = 0;
        {RAS_chk0, RAS_chk1, RAS_chk2, RAS_chk3} = 0;
        {RCD_chk0, RCD_chk1, RCD_chk2, RCD_chk3} = 0;
        {RP_chk0, RP_chk1, RP_chk2, RP_chk3} = 0;
        $timeformat (-9, 0, " ns", 12);
        //$readmemh("bank0.txt", Bank0);
        //$readmemh("bank1.txt", Bank1);
        //$readmemh("bank2.txt", Bank2);
        //$readmemh("bank3.txt", Bank3);
/*      
       for(dd=0;dd<=mem_sizes;dd=dd+1)
            begin
                Bank0[dd]=dd[data_bits - 1 : 0];
                Bank1[dd]=dd[data_bits - 1 : 0]+1;
                Bank2[dd]=dd[data_bits - 1 : 0]+2;
                Bank3[dd]=dd[data_bits - 1 : 0]+3;
            end
*/            
      initial_sdram(0);
      end
 
        task    initial_sdram; 
 
         input        data_sign;
         reg    [3:0]    data_sign;
          
               for(dd=0;dd<=mem_sizes;dd=dd+1)
            begin
                mem_d = {data_sign,data_sign,data_sign,data_sign,data_sign,data_sign,data_sign,data_sign};
                if(data_bits==16)
                    begin
                        Bank0[dd]=mem_d[15:0];
                        Bank1[dd]=mem_d[15:0];
                        Bank2[dd]=mem_d[15:0];
                        Bank3[dd]=mem_d[15:0];
                    end
                else if(data_bits==32)
                    begin
                        Bank0[dd]=mem_d[31:0];
                        Bank1[dd]=mem_d[31:0];
                        Bank2[dd]=mem_d[31:0];
                        Bank3[dd]=mem_d[31:0];
                    end
            end    
          
               endtask

    // System clock generator
    always
        begin
               @(posedge Clk)
                   begin
                        Sys_clk = CkeZ;
                        CkeZ = Cke;
                end
            @(negedge Clk) 
                begin
                        Sys_clk = 1'b0;
                end
        end

    always @ (posedge Sys_clk) begin
        // Internal Commamd Pipelined
        Command[0] = Command[1];
        Command[1] = Command[2];
        Command[2] = Command[3];
        Command[3] = `NOP;

        Col_addr[0] = Col_addr[1];
        Col_addr[1] = Col_addr[2];
        Col_addr[2] = Col_addr[3];
        Col_addr[3] = {col_bits{1'b0}};

        Bank_addr[0] = Bank_addr[1];
        Bank_addr[1] = Bank_addr[2];
        Bank_addr[2] = Bank_addr[3];
        Bank_addr[3] = 2'b0;

        Bank_precharge[0] = Bank_precharge[1];
        Bank_precharge[1] = Bank_precharge[2];
        Bank_precharge[2] = Bank_precharge[3];
        Bank_precharge[3] = 2'b0;

        A10_precharge[0] = A10_precharge[1];
        A10_precharge[1] = A10_precharge[2];
        A10_precharge[2] = A10_precharge[3];
        A10_precharge[3] = 1'b0;

        // Dqm pipeline for Read
        Dqm_reg0 = Dqm_reg1;
        Dqm_reg1 = Dqm;

        // Read or Write with Auto Precharge Counter
        if (Auto_precharge[0] == 1'b1) begin
            Count_precharge[0] = Count_precharge[0] + 1;
        end
        if (Auto_precharge[1] == 1'b1) begin
            Count_precharge[1] = Count_precharge[1] + 1;
        end
        if (Auto_precharge[2] == 1'b1) begin
            Count_precharge[2] = Count_precharge[2] + 1;
        end
        if (Auto_precharge[3] == 1'b1) begin
            Count_precharge[3] = Count_precharge[3] + 1;
        end

        // tMRD Counter
        MRD_chk = MRD_chk + 1;

        // tWR Counter for Write
        WR_counter[0] = WR_counter[0] + 1;
        WR_counter[1] = WR_counter[1] + 1;
        WR_counter[2] = WR_counter[2] + 1;
        WR_counter[3] = WR_counter[3] + 1;

        // Auto Refresh
        if (Aref_enable == 1'b1) begin
            if (Debug) $display ("at time %t AREF : Auto Refresh", $time);
            // Auto Refresh to Auto Refresh
            if (($time - RC_chk < tRC)&&Debug) begin
                $display ("at time %t ERROR: tRC violation during Auto Refresh", $time);
            end
            // Precharge to Auto Refresh
            if (($time - RP_chk0 < tRP || $time - RP_chk1 < tRP || $time - RP_chk2 < tRP || $time - RP_chk3 < tRP)&&Debug) begin
                $display ("at time %t ERROR: tRP violation during Auto Refresh", $time);
            end
            // Precharge to Refresh
            if (Pc_b0 == 1'b0 || Pc_b1 == 1'b0 || Pc_b2 == 1'b0 || Pc_b3 == 1'b0) begin
                $display ("at time %t ERROR: All banks must be Precharge before Auto Refresh", $time);
            end
            // Record Current tRC time
            RC_chk = $time;
        end
        
        // Load Mode Register
        if (Mode_reg_enable == 1'b1) begin
            // Decode CAS Latency, Burst Length, Burst Type, and Write Burst Mode
            if (Pc_b0 == 1'b1 && Pc_b1 == 1'b1 && Pc_b2 == 1'b1 && Pc_b3 == 1'b1) begin
                Mode_reg = Addr;
                if (Debug) begin
                    $display ("at time %t LMR  : Load Mode Register", $time);
                    // CAS Latency
                    if (Addr[6 : 4] == 3'b010)
                        $display ("                            CAS Latency      = 2");
                    else if (Addr[6 : 4] == 3'b011)
                        $display ("                            CAS Latency      = 3");
                    else
                        $display ("                            CAS Latency      = Reserved");
                    // Burst Length
                    if (Addr[2 : 0] == 3'b000)
                        $display ("                            Burst Length     = 1");
                    else if (Addr[2 : 0] == 3'b001)
                        $display ("                            Burst Length     = 2");
                    else if (Addr[2 : 0] == 3'b010)
                        $display ("                            Burst Length     = 4");
                    else if (Addr[2 : 0] == 3'b011)
                        $display ("                            Burst Length     = 8");
                    else if (Addr[3 : 0] == 4'b0111)
                        $display ("                            Burst Length     = Full");
                    else
                        $display ("                            Burst Length     = Reserved");
                    // Burst Type
                    if (Addr[3] == 1'b0)
                        $display ("                            Burst Type       = Sequential");
                    else if (Addr[3] == 1'b1)
                        $display ("                            Burst Type       = Interleaved");
                    else
                        $display ("                            Burst Type       = Reserved");
                    // Write Burst Mode
                    if (Addr[9] == 1'b0)
                        $display ("                            Write Burst Mode = Programmed Burst Length");
                    else if (Addr[9] == 1'b1)
                        $display ("                            Write Burst Mode = Single Location Access");
                    else
                        $display ("                            Write Burst Mode = Reserved");
                end
            end else begin
                $display ("at time %t ERROR: all banks must be Precharge before Load Mode Register", $time);
            end
            // REF to LMR
            if ($time - RC_chk < tRC) begin
                $display ("at time %t ERROR: tRC violation during Load Mode Register", $time);
            end
            // LMR to LMR
            if (MRD_chk < tMRD) begin
                $display ("at time %t ERROR: tMRD violation during Load Mode Register", $time);
            end
            MRD_chk = 0;
        end
        
        // Active Block (Latch Bank Address and Row Address)
        if (Active_enable == 1'b1) begin
            if (Ba == 2'b00 && Pc_b0 == 1'b1) begin
                {Act_b0, Pc_b0} = 2'b10;
                B0_row_addr = Addr [addr_bits - 1 : 0];
                RCD_chk0 = $time;
                RAS_chk0 = $time;
                if (Debug) $display ("at time %t ACT  : Bank = 0 Row = %d", $time, Addr);
                // Precharge to Activate Bank 0
                if ($time - RP_chk0 < tRP) begin
                    $display ("at time %t ERROR: tRP violation during Activate bank 0", $time);
                end
            end else if (Ba == 2'b01 && Pc_b1 == 1'b1) begin
                {Act_b1, Pc_b1} = 2'b10;
                B1_row_addr = Addr [addr_bits - 1 : 0];
                RCD_chk1 = $time;
                RAS_chk1 = $time;
                if (Debug) $display ("at time %t ACT  : Bank = 1 Row = %d", $time, Addr);
                // Precharge to Activate Bank 1
                if ($time - RP_chk1 < tRP) begin
                    $display ("at time %t ERROR: tRP violation during Activate bank 1", $time);
                end
            end else if (Ba == 2'b10 && Pc_b2 == 1'b1) begin
                {Act_b2, Pc_b2} = 2'b10;
                B2_row_addr = Addr [addr_bits - 1 : 0];
                RCD_chk2 = $time;
                RAS_chk2 = $time;
                if (Debug) $display ("at time %t ACT  : Bank = 2 Row = %d", $time, Addr);
                // Precharge to Activate Bank 2
                if ($time - RP_chk2 < tRP) begin
                    $display ("at time %t ERROR: tRP violation during Activate bank 2", $time);
                end
            end else if (Ba == 2'b11 && Pc_b3 == 1'b1) begin
                {Act_b3, Pc_b3} = 2'b10;
                B3_row_addr = Addr [addr_bits - 1 : 0];
                RCD_chk3 = $time;
                RAS_chk3 = $time;
                if (Debug) $display ("at time %t ACT  : Bank = 3 Row = %d", $time, Addr);
                // Precharge to Activate Bank 3
                if ($time - RP_chk3 < tRP) begin
                    $display ("at time %t ERROR: tRP violation during Activate bank 3", $time);
                end
            end else if (Ba == 2'b00 && Pc_b0 == 1'b0) begin
                $display ("at time %t ERROR: Bank 0 is not Precharged.", $time);
            end else if (Ba == 2'b01 && Pc_b1 == 1'b0) begin
                $display ("at time %t ERROR: Bank 1 is not Precharged.", $time);
            end else if (Ba == 2'b10 && Pc_b2 == 1'b0) begin
                $display ("at time %t ERROR: Bank 2 is not Precharged.", $time);
            end else if (Ba == 2'b11 && Pc_b3 == 1'b0) begin
                $display ("at time %t ERROR: Bank 3 is not Precharged.", $time);
            end
            // Active Bank A to Active Bank B
            if ((Previous_bank != Ba) && ($time - RRD_chk < tRRD)) begin
                $display ("at time %t ERROR: tRRD violation during Activate bank = %d", $time, Ba);
            end
            // Load Mode Register to Active
            if (MRD_chk < tMRD ) begin
                $display ("at time %t ERROR: tMRD violation during Activate bank = %d", $time, Ba);
            end
            // Auto Refresh to Activate
            if (($time - RC_chk < tRC)&&Debug) begin
                $display ("at time %t ERROR: tRC violation during Activate bank = %d", $time, Ba);
            end
            // Record variables for checking violation
            RRD_chk = $time;
            Previous_bank = Ba;
        end
        
        // Precharge Block
        if (Prech_enable == 1'b1) begin
            if (Addr[10] == 1'b1) begin
                {Pc_b0, Pc_b1, Pc_b2, Pc_b3} = 4'b1111;
                {Act_b0, Act_b1, Act_b2, Act_b3} = 4'b0000;
                RP_chk0 = $time;
                RP_chk1 = $time;
                RP_chk2 = $time;
                RP_chk3 = $time;
                if (Debug) $display ("at time %t PRE  : Bank = ALL",$time);
                // Activate to Precharge all banks
                if (($time - RAS_chk0 < tRAS) || ($time - RAS_chk1 < tRAS) ||
                    ($time - RAS_chk2 < tRAS) || ($time - RAS_chk3 < tRAS)) begin
                    $display ("at time %t ERROR: tRAS violation during Precharge all bank", $time);
                end
                // tWR violation check for write
                if (($time - WR_chk[0] < tWRp) || ($time - WR_chk[1] < tWRp) ||
                    ($time - WR_chk[2] < tWRp) || ($time - WR_chk[3] < tWRp)) begin
                    $display ("at time %t ERROR: tWR violation during Precharge all bank", $time);
                end
            end else if (Addr[10] == 1'b0) begin
                if (Ba == 2'b00) begin
                    {Pc_b0, Act_b0} = 2'b10;
                    RP_chk0 = $time;
                    if (Debug) $display ("at time %t PRE  : Bank = 0",$time);
                    // Activate to Precharge Bank 0
                    if ($time - RAS_chk0 < tRAS) begin
                        $display ("at time %t ERROR: tRAS violation during Precharge bank 0", $time);
                    end
                end else if (Ba == 2'b01) begin
                    {Pc_b1, Act_b1} = 2'b10;
                    RP_chk1 = $time;
                    if (Debug) $display ("at time %t PRE  : Bank = 1",$time);
                    // Activate to Precharge Bank 1
                    if ($time - RAS_chk1 < tRAS) begin
                        $display ("at time %t ERROR: tRAS violation during Precharge bank 1", $time);
                    end
                end else if (Ba == 2'b10) begin
                    {Pc_b2, Act_b2} = 2'b10;
                    RP_chk2 = $time;
                    if (Debug) $display ("at time %t PRE  : Bank = 2",$time);
                    // Activate to Precharge Bank 2
                    if ($time - RAS_chk2 < tRAS) begin
                        $display ("at time %t ERROR: tRAS violation during Precharge bank 2", $time);
                    end
                end else if (Ba == 2'b11) begin
                    {Pc_b3, Act_b3} = 2'b10;
                    RP_chk3 = $time;
                    if (Debug) $display ("at time %t PRE  : Bank = 3",$time);
                    // Activate to Precharge Bank 3
                    if ($time - RAS_chk3 < tRAS) begin
                        $display ("at time %t ERROR: tRAS violation during Precharge bank 3", $time);
                    end
                end
                // tWR violation check for write
                if ($time - WR_chk[Ba] < tWRp) begin
                    $display ("at time %t ERROR: tWR violation during Precharge bank %d", $time, Ba);
                end
            end
            // Terminate a Write Immediately (if same bank or all banks)
            if (Data_in_enable == 1'b1 && (Bank == Ba || Addr[10] == 1'b1)) begin
                Data_in_enable = 1'b0;
            end
            // Precharge Command Pipeline for Read
            if (Cas_latency_3 == 1'b1) begin
                Command[2] = `PRECH;
                Bank_precharge[2] = Ba;
                A10_precharge[2] = Addr[10];
            end else if (Cas_latency_2 == 1'b1) begin
                Command[1] = `PRECH;
                Bank_precharge[1] = Ba;
                A10_precharge[1] = Addr[10];
            end
        end
        
        // Burst terminate
        if (Burst_term == 1'b1) begin
            // Terminate a Write Immediately
            if (Data_in_enable == 1'b1) begin
                Data_in_enable = 1'b0;
            end
            // Terminate a Read Depend on CAS Latency
            if (Cas_latency_3 == 1'b1) begin
                Command[2] = `BST;
            end else if (Cas_latency_2 == 1'b1) begin
                Command[1] = `BST;
            end
            if (Debug) $display ("at time %t BST  : Burst Terminate",$time);
        end
        
        // Read, Write, Column Latch
        if (Read_enable == 1'b1 || Write_enable == 1'b1) begin
            // Check to see if bank is open (ACT)
            if ((Ba == 2'b00 && Pc_b0 == 1'b1) || (Ba == 2'b01 && Pc_b1 == 1'b1) ||
                (Ba == 2'b10 && Pc_b2 == 1'b1) || (Ba == 2'b11 && Pc_b3 == 1'b1)) begin
                $display("at time %t ERROR: Cannot Read or Write - Bank %d is not Activated", $time, Ba);
            end
            // Activate to Read or Write
            if ((Ba == 2'b00) && ($time - RCD_chk0 < tRCD))
                $display("at time %t ERROR: tRCD violation during Read or Write to Bank 0", $time);
            if ((Ba == 2'b01) && ($time - RCD_chk1 < tRCD))
                $display("at time %t ERROR: tRCD violation during Read or Write to Bank 1", $time);
            if ((Ba == 2'b10) && ($time - RCD_chk2 < tRCD))
                $display("at time %t ERROR: tRCD violation during Read or Write to Bank 2", $time);
            if ((Ba == 2'b11) && ($time - RCD_chk3 < tRCD))
                $display("at time %t ERROR: tRCD violation during Read or Write to Bank 3", $time);
            // Read Command
            if (Read_enable == 1'b1) begin
                // CAS Latency pipeline
                if (Cas_latency_3 == 1'b1) begin
                    if (Addr[10] == 1'b1) begin
                        Command[2] = `READ_A;
                    end else begin
                        Command[2] = `READ;
                    end
                    Col_addr[2] = Addr;
                    Bank_addr[2] = Ba;
                end else if (Cas_latency_2 == 1'b1) begin
                    if (Addr[10] == 1'b1) begin
                        Command[1] = `READ_A;
                    end else begin
                        Command[1] = `READ;
                    end
                    Col_addr[1] = Addr;
                    Bank_addr[1] = Ba;
                end

                // Read interrupt Write (terminate Write immediately)
                if (Data_in_enable == 1'b1) begin
                    Data_in_enable = 1'b0;
                end

            // Write Command
            end else if (Write_enable == 1'b1) begin
                if (Addr[10] == 1'b1) begin
                    Command[0] = `WRITE_A;
                end else begin
                    Command[0] = `WRITE;
                end
                Col_addr[0] = Addr;
                Bank_addr[0] = Ba;

                // Write interrupt Write (terminate Write immediately)
                if (Data_in_enable == 1'b1) begin
                    Data_in_enable = 1'b0;
                end

                // Write interrupt Read (terminate Read immediately)
                if (Data_out_enable == 1'b1) begin
                    Data_out_enable = 1'b0;
                end
            end

            // Interrupting a Write with Autoprecharge
            if (Auto_precharge[Bank] == 1'b1 && Write_precharge[Bank] == 1'b1) begin
                RW_interrupt_write[Bank] = 1'b1;
                if (Debug) $display ("at time %t NOTE : Read/Write Bank %d interrupt Write Bank %d with Autoprecharge", $time, Ba, Bank);
            end

            // Interrupting a Read with Autoprecharge
            if (Auto_precharge[Bank] == 1'b1 && Read_precharge[Bank] == 1'b1) begin
                RW_interrupt_read[Bank] = 1'b1;
                if (Debug) $display ("at time %t NOTE : Read/Write Bank %d interrupt Read Bank %d with Autoprecharge", $time, Ba, Bank);
            end

            // Read or Write with Auto Precharge
            if (Addr[10] == 1'b1) begin
                Auto_precharge[Ba] = 1'b1;
                Count_precharge[Ba] = 0;
                if (Read_enable == 1'b1) begin
                    Read_precharge[Ba] = 1'b1;
                end else if (Write_enable == 1'b1) begin
                    Write_precharge[Ba] = 1'b1;
                end
            end
        end

        //  Read with Auto Precharge Calculation
        //      The device start internal precharge:
        //          1.  CAS Latency - 1 cycles before last burst
        //      and 2.  Meet minimum tRAS requirement
        //       or 3.  Interrupt by a Read or Write (with or without AutoPrecharge)
        if ((Auto_precharge[0] == 1'b1) && (Read_precharge[0] == 1'b1)) begin
            if ((($time - RAS_chk0 >= tRAS) &&                                                      // Case 2
                ((Burst_length_1 == 1'b1 && Count_precharge[0] >= 1) ||                             // Case 1
                 (Burst_length_2 == 1'b1 && Count_precharge[0] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[0] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[0] >= 8))) ||
                 (RW_interrupt_read[0] == 1'b1)) begin                                              // Case 3
                    Pc_b0 = 1'b1;
                    Act_b0 = 1'b0;
                    RP_chk0 = $time;
                    Auto_precharge[0] = 1'b0;
                    Read_precharge[0] = 1'b0;
                    RW_interrupt_read[0] = 1'b0;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 0", $time);
            end
        end
        if ((Auto_precharge[1] == 1'b1) && (Read_precharge[1] == 1'b1)) begin
            if ((($time - RAS_chk1 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[1] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[1] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[1] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[1] >= 8))) ||
                 (RW_interrupt_read[1] == 1'b1)) begin
                    Pc_b1 = 1'b1;
                    Act_b1 = 1'b0;
                    RP_chk1 = $time;
                    Auto_precharge[1] = 1'b0;
                    Read_precharge[1] = 1'b0;
                    RW_interrupt_read[1] = 1'b0;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 1", $time);
            end
        end
        if ((Auto_precharge[2] == 1'b1) && (Read_precharge[2] == 1'b1)) begin
            if ((($time - RAS_chk2 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[2] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[2] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[2] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[2] >= 8))) ||
                 (RW_interrupt_read[2] == 1'b1)) begin
                    Pc_b2 = 1'b1;
                    Act_b2 = 1'b0;
                    RP_chk2 = $time;
                    Auto_precharge[2] = 1'b0;
                    Read_precharge[2] = 1'b0;
                    RW_interrupt_read[2] = 1'b0;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 2", $time);
            end
        end
        if ((Auto_precharge[3] == 1'b1) && (Read_precharge[3] == 1'b1)) begin
            if ((($time - RAS_chk3 >= tRAS) &&
                ((Burst_length_1 == 1'b1 && Count_precharge[3] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge[3] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge[3] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge[3] >= 8))) ||
                 (RW_interrupt_read[3] == 1'b1)) begin
                    Pc_b3 = 1'b1;
                    Act_b3 = 1'b0;
                    RP_chk3 = $time;
                    Auto_precharge[3] = 1'b0;
                    Read_precharge[3] = 1'b0;
                    RW_interrupt_read[3] = 1'b0;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 3", $time);
            end
        end

        // Internal Precharge or Bst
        if (Command[0] == `PRECH) begin                         // Precharge terminate a read with same bank or all banks
            if (Bank_precharge[0] == Bank || A10_precharge[0] == 1'b1) begin
                if (Data_out_enable == 1'b1) begin
                    Data_out_enable = 1'b0;
                end
            end
        end else if (Command[0] == `BST) begin                  // BST terminate a read to current bank
            if (Data_out_enable == 1'b1) begin
                Data_out_enable = 1'b0;
            end
        end

        if (Data_out_enable == 1'b0) begin
            Dq_reg <= #tOH {data_bits{1'bz}};
        end

        // Detect Read or Write command
        if (Command[0] == `READ || Command[0] == `READ_A) begin
            Bank = Bank_addr[0];
            Col = Col_addr[0];
            Col_brst = Col_addr[0];
            if (Bank_addr[0] == 2'b00) begin
                Row = B0_row_addr;
            end else if (Bank_addr[0] == 2'b01) begin
                Row = B1_row_addr;
            end else if (Bank_addr[0] == 2'b10) begin
                Row = B2_row_addr;
            end else if (Bank_addr[0] == 2'b11) begin
                Row = B3_row_addr;
            end
            Burst_counter = 0;
            Data_in_enable = 1'b0;
            Data_out_enable = 1'b1;
        end else if (Command[0] == `WRITE || Command[0] == `WRITE_A) begin
            Bank = Bank_addr[0];
            Col = Col_addr[0];
            Col_brst = Col_addr[0];
            if (Bank_addr[0] == 2'b00) begin
                Row = B0_row_addr;
            end else if (Bank_addr[0] == 2'b01) begin
                Row = B1_row_addr;
            end else if (Bank_addr[0] == 2'b10) begin
                Row = B2_row_addr;
            end else if (Bank_addr[0] == 2'b11) begin
                Row = B3_row_addr;
            end
            Burst_counter = 0;
            Data_in_enable = 1'b1;
            Data_out_enable = 1'b0;
        end

        // DQ buffer (Driver/Receiver)
        if (Data_in_enable == 1'b1) begin                                   // Writing Data to Memory
            // Array buffer
            if (Bank == 2'b00) Dq_dqm [data_bits - 1  : 0] = Bank0 [{Row, Col}];
            if (Bank == 2'b01) Dq_dqm [data_bits - 1  : 0] = Bank1 [{Row, Col}];
            if (Bank == 2'b10) Dq_dqm [data_bits - 1  : 0] = Bank2 [{Row, Col}];
            if (Bank == 2'b11) Dq_dqm [data_bits - 1  : 0] = Bank3 [{Row, Col}];
            // Dqm operation
            if (Dqm[0] == 1'b0) Dq_dqm [ 7 : 0] = Dq [ 7 : 0];
            if (Dqm[1] == 1'b0) Dq_dqm [15 : 8] = Dq [15 : 8];
            //if (Dqm[2] == 1'b0) Dq_dqm [23 : 16] = Dq [23 : 16];
           // if (Dqm[3] == 1'b0) Dq_dqm [31 : 24] = Dq [31 : 24];
            // Write to memory
            if (Bank == 2'b00) Bank0 [{Row, Col}] = Dq_dqm [data_bits - 1  : 0];
            if (Bank == 2'b01) Bank1 [{Row, Col}] = Dq_dqm [data_bits - 1  : 0];
            if (Bank == 2'b10) Bank2 [{Row, Col}] = Dq_dqm [data_bits - 1  : 0];
            if (Bank == 2'b11) Bank3 [{Row, Col}] = Dq_dqm [data_bits - 1  : 0];
            if (Bank == 2'b11 && Row==10'h3 && Col[7:4]==4'h4)
                $display("at time %t WRITE: Bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", $time, Bank, Row, Col);
            //$fdisplay(test_file,"bank:%h    row:%h    col:%h    write:%h",Bank,Row,Col,Dq_dqm);
            // Output result
            if (Dqm == 4'b1111) begin
                if (Debug) $display("at time %t WRITE: Bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", $time, Bank, Row, Col);
            end else begin
                if (Debug) $display("at time %t WRITE: Bank = %d Row = %d, Col = %d, Data = %d, Dqm = %b", $time, Bank, Row, Col, Dq_dqm, Dqm);
                // Record tWR time and reset counter
                WR_chk [Bank] = $time;
                WR_counter [Bank] = 0;
            end
            // Advance burst counter subroutine
            #tHZ Burst;
        end else if (Data_out_enable == 1'b1) begin                         // Reading Data from Memory
            //$display("%h    ,    %h,    %h",Bank0,Row,Col);
            // Array buffer
            if (Bank == 2'b00) Dq_dqm [data_bits - 1  : 0] = Bank0 [{Row, Col}];
            if (Bank == 2'b01) Dq_dqm [data_bits - 1  : 0] = Bank1 [{Row, Col}];
            if (Bank == 2'b10) Dq_dqm [data_bits - 1  : 0] = Bank2 [{Row, Col}];
            if (Bank == 2'b11) Dq_dqm [data_bits - 1  : 0] = Bank3 [{Row, Col}];
                
            // Dqm operation
            if (Dqm_reg0[0] == 1'b1) Dq_dqm [ 7 : 0] = 8'bz;
            if (Dqm_reg0[1] == 1'b1) Dq_dqm [15 : 8] = 8'bz;
            if (Dqm_reg0[2] == 1'b1) Dq_dqm [23 : 16] = 8'bz;
            if (Dqm_reg0[3] == 1'b1) Dq_dqm [31 : 24] = 8'bz;
            // Display result
            Dq_reg [data_bits - 1  : 0] = #tAC Dq_dqm [data_bits - 1  : 0];
            if (Dqm_reg0 == 4'b1111) begin
                if (Debug) $display("at time %t READ : Bank = %d Row = %d, Col = %d, Data = Hi-Z due to DQM", $time, Bank, Row, Col);
            end else begin
                if (Debug) $display("at time %t READ : Bank = %d Row = %d, Col = %d, Data = %d, Dqm = %b", $time, Bank, Row, Col, Dq_reg, Dqm_reg0);
            end
            // Advance burst counter subroutine
            Burst;
        end
    end

    //  Write with Auto Precharge Calculation
    //      The device start internal precharge:
    //          1.  tWR Clock after last burst
    //      and 2.  Meet minimum tRAS requirement
    //       or 3.  Interrupt by a Read or Write (with or without AutoPrecharge)
    always @ (WR_counter[0]) begin
        if ((Auto_precharge[0] == 1'b1) && (Write_precharge[0] == 1'b1)) begin
            if ((($time - RAS_chk0 >= tRAS) &&                                                          // Case 2
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [0] >= 1) ||   // Case 1
                 (Burst_length_2 == 1'b1 && Count_precharge [0] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [0] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [0] >= 8))) ||
                 (RW_interrupt_write[0] == 1'b1 && WR_counter[0] >= 2)) begin                           // Case 3 (stop count when interrupt)
                    Auto_precharge[0] = 1'b0;
                    Write_precharge[0] = 1'b0;
                    RW_interrupt_write[0] = 1'b0;
                    #tWRa;                          // Wait for tWR
                    Pc_b0 = 1'b1;
                    Act_b0 = 1'b0;
                    RP_chk0 = $time;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 0", $time);
            end
        end
    end
    always @ (WR_counter[1]) begin
        if ((Auto_precharge[1] == 1'b1) && (Write_precharge[1] == 1'b1)) begin
            if ((($time - RAS_chk1 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [1] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge [1] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [1] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [1] >= 8))) ||
                 (RW_interrupt_write[1] == 1'b1 && WR_counter[1] >= 2)) begin
                    Auto_precharge[1] = 1'b0;
                    Write_precharge[1] = 1'b0;
                    RW_interrupt_write[1] = 1'b0;
                    #tWRa;                          // Wait for tWR
                    Pc_b1 = 1'b1;
                    Act_b1 = 1'b0;
                    RP_chk1 = $time;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 1", $time);
            end
        end
    end
    always @ (WR_counter[2]) begin
        if ((Auto_precharge[2] == 1'b1) && (Write_precharge[2] == 1'b1)) begin
            if ((($time - RAS_chk2 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [2] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge [2] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [2] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [2] >= 8))) ||
                 (RW_interrupt_write[2] == 1'b1 && WR_counter[2] >= 2)) begin
                    Auto_precharge[2] = 1'b0;
                    Write_precharge[2] = 1'b0;
                    RW_interrupt_write[2] = 1'b0;
                    #tWRa;                          // Wait for tWR
                    Pc_b2 = 1'b1;
                    Act_b2 = 1'b0;
                    RP_chk2 = $time;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 2", $time);
            end
        end
    end
    always @ (WR_counter[3]) begin
        if ((Auto_precharge[3] == 1'b1) && (Write_precharge[3] == 1'b1)) begin
            if ((($time - RAS_chk3 >= tRAS) &&
               (((Burst_length_1 == 1'b1 || Write_burst_mode == 1'b1) && Count_precharge [3] >= 1) || 
                 (Burst_length_2 == 1'b1 && Count_precharge [3] >= 2) ||
                 (Burst_length_4 == 1'b1 && Count_precharge [3] >= 4) ||
                 (Burst_length_8 == 1'b1 && Count_precharge [3] >= 8))) ||
                 (RW_interrupt_write[3] == 1'b1 && WR_counter[3] >= 2)) begin
                    Auto_precharge[3] = 1'b0;
                    Write_precharge[3] = 1'b0;
                    RW_interrupt_write[3] = 1'b0;
                    #tWRa;                          // Wait for tWR
                    Pc_b3 = 1'b1;
                    Act_b3 = 1'b0;
                    RP_chk3 = $time;
                    if (Debug) $display ("at time %t NOTE : Start Internal Auto Precharge for Bank 3", $time);
            end
        end
    end

    task Burst;
        begin
            // Advance Burst Counter
            Burst_counter = Burst_counter + 1;

            // Burst Type
            if (Mode_reg[3] == 1'b0) begin                                  // Sequential Burst
                Col_temp = Col + 1;
            end else if (Mode_reg[3] == 1'b1) begin                         // Interleaved Burst
                Col_temp[2] =  Burst_counter[2] ^  Col_brst[2];
                Col_temp[1] =  Burst_counter[1] ^  Col_brst[1];
                Col_temp[0] =  Burst_counter[0] ^  Col_brst[0];
            end

            // Burst Length
            if (Burst_length_2) begin                                       // Burst Length = 2
                Col [0] = Col_temp [0];
            end else if (Burst_length_4) begin                              // Burst Length = 4
                Col [1 : 0] = Col_temp [1 : 0];
            end else if (Burst_length_8) begin                              // Burst Length = 8
                Col [2 : 0] = Col_temp [2 : 0];
            end else begin                                                  // Burst Length = FULL
                Col = Col_temp;
            end

            // Burst Read Single Write            
            if (Write_burst_mode == 1'b1) begin
                Data_in_enable = 1'b0;
            end

            // Data Counter
            if (Burst_length_1 == 1'b1) begin
                if (Burst_counter >= 1) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_2 == 1'b1) begin
                if (Burst_counter >= 2) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_4 == 1'b1) begin
                if (Burst_counter >= 4) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end else if (Burst_length_8 == 1'b1) begin
                if (Burst_counter >= 8) begin
                    Data_in_enable = 1'b0;
                    Data_out_enable = 1'b0;
                end
            end
        end
    endtask
    
    //**********************将SDRAM内的数据直接输出到外部文件*******************************//

/*    
   integer    sdram_data,ind;


    always@(sdram_r)
    begin
           sdram_data=$fopen("sdram_data.txt");
           $display("Sdram dampout begin ",sdram_data);
//           $fdisplay(sdram_data,"Bank0：");
           for(ind=0;ind<=mem_sizes;ind=ind+1)
                    $fdisplay(sdram_data,"%h    %b",ind,Bank0[ind]);
//           $fdisplay(sdram_data,"Bank1：");
           for(ind=0;ind<=mem_sizes;ind=ind+1)
                    $fdisplay(sdram_data,"%h    %b",ind,Bank1[ind]);
//           $fdisplay(sdram_data,"Bank2：");
           for(ind=0;ind<=mem_sizes;ind=ind+1)
                    $fdisplay(sdram_data,"%h    %b",ind,Bank2[ind]);
//               $fdisplay(sdram_data,"Bank3：");
           for(ind=0;ind<=mem_sizes;ind=ind+1)
                    $fdisplay(sdram_data,"%h    %b",ind,Bank3[ind]);
                                      
          $fclose("sdram_data.txt");        
      //->compare;
      end        
*/
    integer    sdram_data,sdram_mem;
    reg    [24:0]    aa,cc;
    reg    [24:0]    bb,ee;
    
    always@(sdram_r)
    begin
           $display("Sdram dampout begin ",$realtime);
           sdram_data=$fopen("sdram_data.txt");
           for(aa=0;aa<4*(mem_sizes+1);aa=aa+1)
               begin
               bb=aa[18:0];
            if(aa<=mem_sizes)
                $fdisplay(sdram_data,"%0d    %0h",aa,Bank0[bb]);
            else if(aa<=2*mem_sizes+1)
                        $fdisplay(sdram_data,"%0d    %0h",aa,Bank1[bb]);
            else if(aa<=3*mem_sizes+2)
                $fdisplay(sdram_data,"%0d    %0h",aa,Bank2[bb]);
            else
                $fdisplay(sdram_data,"%0d    %0h",aa,Bank3[bb]);
              end                        
          $fclose("sdram_data.txt"); 
          
          sdram_mem=$fopen("sdram_mem.txt");
          for(cc=0;cc<4*(mem_sizes+1);cc=cc+1)
              begin
               ee=cc[18:0];
            if(cc<=mem_sizes)
                $fdisplay(sdram_mem,"%0h",Bank0[ee]);
            else if(cc<=2*mem_sizes+1)
                        $fdisplay(sdram_mem,"%0h",Bank1[ee]);
            else if(cc<=3*mem_sizes+2)
                $fdisplay(sdram_mem,"%0h",Bank2[ee]);
            else
                $fdisplay(sdram_mem,"%0h",Bank3[ee]);
              end                        
          $fclose("sdram_mem.txt");        
     
      end        



//    // Timing Parameters for -75 (PC133) and CAS Latency = 2
//    specify
//        specparam
////                    tAH  =  0.8,                                        // Addr, Ba Hold Time
////                    tAS  =  1.5,                                        // Addr, Ba Setup Time
////                    tCH  =  2.5,                                        // Clock High-Level Width
////                    tCL  =  2.5,                                        // Clock Low-Level Width
//////                    tCK  = 10.0,                                       // Clock Cycle Time  100mhz
//////                    tCK  = 7.5,                        // Clock Cycle Time  133mhz
////                    tCK  =  7,                                // Clock Cycle Time  143mhz
////                    tDH  =  0.8,                                        // Data-in Hold Time
////                    tDS  =  1.5,                                        // Data-in Setup Time
////                    tCKH =  0.8,                                        // CKE Hold  Time
////                    tCKS =  1.5,                                        // CKE Setup Time
////                    tCMH =  0.8,                                        // CS#, RAS#, CAS#, WE#, DQM# Hold  Time
////                    tCMS =  1.5;                                        // CS#, RAS#, CAS#, WE#, DQM# Setup Time
//                    tAH  =  1,                                        // Addr, Ba Hold Time
//                    tAS  =  1.5,                                        // Addr, Ba Setup Time
//                    tCH  =  1,                                        // Clock High-Level Width
//                    tCL  =  3,                                        // Clock Low-Level Width
////                    tCK  = 10.0,                                       // Clock Cycle Time  100mhz
////                    tCK  = 7.5,                        // Clock Cycle Time  133mhz
//                    tCK  =  7,                                // Clock Cycle Time  143mhz
//                    tDH  =  1,                                        // Data-in Hold Time
//                    tDS  =  2,                                        // Data-in Setup Time
//                    tCKH =  1,                                        // CKE Hold  Time
//                    tCKS =  2,                                        // CKE Setup Time
//                    tCMH =  0.8,                                        // CS#, RAS#, CAS#, WE#, DQM# Hold  Time
//                    tCMS =  1.5;                                        // CS#, RAS#, CAS#, WE#, DQM# Setup Time
//        $width    (posedge Clk,           tCH);
//        $width    (negedge Clk,           tCL);
//        $period   (negedge Clk,           tCK);
//        $period   (posedge Clk,           tCK);
//        $setuphold(posedge Clk,    Cke,   tCKS, tCKH);
//        $setuphold(posedge Clk,    Cs_n,  tCMS, tCMH);
//        $setuphold(posedge Clk,    Cas_n, tCMS, tCMH);
//        $setuphold(posedge Clk,    Ras_n, tCMS, tCMH);
//        $setuphold(posedge Clk,    We_n,  tCMS, tCMH);
//        $setuphold(posedge Clk,    Addr,  tAS,  tAH);
//        $setuphold(posedge Clk,    Ba,    tAS,  tAH);
//        $setuphold(posedge Clk,    Dqm,   tCMS, tCMH);
//        $setuphold(posedge Dq_chk, Dq,    tDS,  tDH);
//    endspecify

endmodule
```
{% endfold %}
</font>

### 仿真结果

我们可以看到基于 sdram_model.v 运行了 201us 个周期后，modelsim 上打印信息显示我们初始化的操作是正确的。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/sdram%E4%BB%BF%E7%9C%9F%E6%95%B0%E6%8D%AE.jpg)

仿真波形如图所示：
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/sdram/sdram%E4%BB%BF%E7%9C%9F%E6%B3%A2%E5%BD%A2.jpg)

### 小结
我们依芯片手册成功实现了 sdram 的上电初始化，接下来我们将继续进行后续的操作，我们将尽快更新~

### 附件
SDRAM 仿真模型文件：[点击下载，提取码:yihx](https://pan.baidu.com/s/1hIPdYfLONydeHYugL0hKig)

**By Ricky**
