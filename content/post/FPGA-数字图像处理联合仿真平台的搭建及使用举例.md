+++
author = "BH6BAO"
title = "FPGA 数字图像处理联合仿真平台的搭建及使用举例"
date = "2019-09-02 21:25:33"
description = "一个 FPGA 数字图像处理例子."
tags = [
    "数字图像处理",
    "FPGA仿真",
    "Verilog",
    "IC Design",
]
categories = [
    "IC Design",
    "syntax",
]
series = ["IC Design"]
+++

## 前言
随着物联网技术的不断发展，对边缘计算的性能要求愈发苛刻，传统的 IoT 级别的 SoC 或者 MCU 难以应对诸如图像识别的场景需求，因此 FPGA + MCU 或 FPGA + SoC 的异构架构愈来愈多地应用于上述场景中，以满足相关需求。（以上这段话毫无意义，只是为了凑字数，另外为了纪念第三次憾负的开场白）

<!-- more -->

当前 FPGA 发展火热，众多开发者使用 FPGA 来完成部分图像处理的部分功能，但众所周知纯 FPGA 开发（或者数字 IC 设计）与常见的 ARM A 系列（with OS）或者桌面端 PC 在图像处理开发过程中最大的差别在于过程的可视化。开发过程中的可视化多少会影响到开发者对于图像处理的判断与取舍，简而言之，如果开发者都不知道经过了这一步处理后图像变成了什么样，那还如何继续接下来的步骤。因此分享交流一下在本次车牌识别设计中我们所用到的数字图像处理的联合仿真平台（*注：本文仅仅介绍平台使用方式，不介绍过程中涉及到的数字图像处理原理*），如果有更好的方式，希望大家可以留言给予建议~

## 首先是我们所需要的软件工具：
本次我们的开发环境为 Win10 所用到的软件工具分别为：`Modelsim(10.5B)`, `MATLAB(R2019a)`

然后简述一下我们的操作过程（以图片 RGB 色域转换 YCbCr 色域处理为例），整体过程可简述如下：通过 MATLAB 将图片文件转换为 `.txt` 格式文件，使用 Verilog 读取相应文件后完成相应图像处理操作后输出为 `.txt` 文件，再次使用 MATLAB 将输出的 `.txt` 格式文件转换为图片文件并查看。以上步骤的意义在于不仅可以实现数字图像处理的单步可视化，还可以同原始的 MATLAB 对应的处理效果进行对比。(后期我们也会更新，直接使用 Verilog 完成图像读取并输出结果查看的方法)

首先我们通过以下程序(亦可查看附带工程中的 `IMG2TXT.m` 文件)在 MATLAB 端将图片生成 R,G,B 色域对应的 `.txt` 格式文件。并同时通过 MATLAB 生成 YCbCr 色域下三个分量的图像予以显示。
其关键代码如下：

```matlab
clear all
close all
clc
img = imread('test.jpg');
[a,b,c]= size(img);
R1=img(:,:,1);
G1=img(:,:,2);
B1=img(:,:,3);

fidR1= fopen('testR.txt','w');
fidG1= fopen('testG.txt','w');
fidB1= fopen('testB.txt','w');
for i=1:a
    for j= 1:b
      fprintf(fidR1,'%d\n',R1(i,j)); %frame1
      fprintf(fidG1,'%d\n',G1(i,j));
      fprintf(fidB1,'%d\n',B1(i,j));
    end
end
fclose(fidR1);
fclose(fidG1);
fclose(fidB1);

```

## RGB 色域文件生成
生成对应 RGB 色域 `.txt` 格式文件如下图所示：

![RGB.txt](https://s2.ax1x.com/2019/09/02/nidDTs.png)

生成 YCbCr 色域对应分量图片(详见工程文件 `YCbCr.m` )，如下图所示：

![YCbCr](https://s2.ax1x.com/2019/09/02/niwnNn.png)

## Verilog 处理
然后在我们的 Modelsim 工程中对 `.txt` 格式文件进行读取(亦可查看工程中附带的 imread.v 文件)，进一步的完成图像处理对应的操作后，输出对应 `.txt` 格式文件（亦可查看工程中附带 imwrite.v 文件）。
其 txt 读取关键代码如下：

```verilog
initial begin
  fR = $fopen("testR.txt","r");   // read in testR.txt
  fG = $fopen("testG.txt","r");
  fB = $fopen("testB.txt","r");
  if(fR == `NULL || fG == `NULL || fB == `NULL) begin
    $display("data_file handle was NULL");
	$finish;
  end
  else begin
    $fscanf(fR,"%d;\n",R);
	$fscanf(fG,"%d;\n",G);
	$fscanf(fB,"%d;\n",B);
  end
end

always @(posedge pixel_clk or negedge reset_n) begin
  if(reset_n == 0) begin
    R = 8'd0;
	G = 8'd0;
	B = 8'd0;
  end
  else if(de) begin
    if(fR != 0 && fG != 0 && fB != 0) begin
	 $fscanf(fR,"%d;\n",R);
	 $fscanf(fG,"%d;\n",G);
	 $fscanf(fB,"%d;\n",B);
	 $display("time=[%d],%d,%d,%d",$realtime,R,G,B);
	end
  end

end
```

完成处理后生成 txt 关键代码如下：

```verilog
initial begin
  fR = $fopen("R.txt","w");
  fG = $fopen("G.txt","w");
  fB = $fopen("B.txt","w");
  if(fR == `NULL || fG == `NULL || fB == `NULL) begin
    $display("can not open R.txt or G.txt or B.txt");
	$finish;
  end
end

always @(posedge pixel_clk or negedge reset_n) begin
  if(de) begin
    $display("////////////////////////////////////");
    $display("time=[%d],%d,%d,%d",$realtime,R,G,B);
    $fwrite(fR,"%d\n",R);
	$fwrite(fG,"%d\n",G);
	$fwrite(fB,"%d\n",B);
  end
end
```

## 处理结果
最终在 MATLAB 端将仿真生成输出的 `.txt` 文件转换还原为图片（亦可查看工程中附带的 TXT2IMG.M 文件）。

```matlab
clear all
close all
clc

imgori = imread('test.jpg');
[a,b,c]= size(imgori);

img1R = uint8(textread('R.txt','%u'));
img1G = uint8(textread('G.txt','%u'));
img1B = uint8(textread('B.txt','%u'));

img1(:,:,1) = reshape(img1R,[b,a]);
img1(:,:,2) = reshape(img1G,[b,a]);
img1(:,:,3) = reshape(img1B,[b,a]);

img=flipdim(img1,1);

figure,
subplot(221),imshow(imrotate(img,-90)),title('YCbCr');
subplot(222),imshow(imrotate(img(:,:,1),-90)),title('Y');
subplot(223),imshow(imrotate(img(:,:,2),-90)),title('Cb');
subplot(224),imshow(imrotate(img(:,:,3),-90)),title('Cr');
```

由于常见的 FPGA 数字图像处理为了减少数据读取对于缓存资源的消耗，通常其处理步骤在视频流完成，因此本次工程中我们在 VGA 模拟时序中完成相应操作。完成仿真如波形下图所示：

![Waveform](https://s2.ax1x.com/2019/09/02/ni04iR.png)

生成结果 `.txt` 文件如下图所示:
![Outfile](https://s2.ax1x.com/2019/09/02/ni0Xod.png)

将生成结果 `.txt` 文件放回 MATLAB 工程路径下最终实现效果如下图所示：

![Outfile of FPGA](https://s2.ax1x.com/2019/09/02/niB6fI.png)

## MATLAB vs HDL数字图像处理 结果对比
将图像放大后，可以明显发现通过数字思想处理得到的图片结果相较于 MATLAB 直接转换得到的结果存在一定的差距，Cr 分量下表现的最为明显，具体原因在此不具体展开分析。其对比如下图（*注：左侧为 MATLAB 处理结果右侧为 verilog 处理结果*）

![Matlab vs HDL](https://s2.ax1x.com/2019/09/02/niwkjS.png)

之后我们将逐步介绍本次我们 ARM 杯车牌识别系统的每个实现过程~

 <font color=#FF0000 size=6>  并公开全套设计源码！！！ </font>

举例部分全部代码详见 GitHub 仓库：[https://github.com/strongwong/FPGA-DIP](https://github.com/strongwong/FPGA-DIP)

**By Ricky**
