---
title: 数字 IC 设计流程
tags:
  - IC Design
categories:
  - IC Design
  - 其他
abbrlink: 44968
date: 2019-01-13 18:41:35
---
## 0x00

最近即将开始要带着学弟们入门数字 IC 的设计，但很多学弟对于接下来要做什么是迷茫的，很多练就了各式各样的基本功却不知道如何施展，因此这里简单介绍一下数字 IC 设计的全过程及相关的设计工具及涉及到的相关职位，如果有写的不合适或者不正确的地方还请各位提出~

<!-- more -->

详见下图:

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E6%95%B0%E5%AD%97IC%E8%AE%BE%E8%AE%A1%E5%85%A8%E8%BF%87%E7%A8%8B%E7%9B%B8%E5%85%B3%E5%B7%A5%E5%85%B7.png)

## 0x01

看了上图之后很多学弟就又问了，那平时我们都是 vivado，quartus，FPGA …… 为啥感觉和上面的都不沾边呢，这里说一点个人的看法，如果不是做硬件并行加速或者 FPGA 的嵌入式开发，那么平日 FPGA 的最大作用就是 —— 功能验证性工具。因为流片的价格非常昂贵，很少有实验室或者学校会让你不断地流片来实现你的设计，另外的，一个实验室如果没有同时具备设计，验证，版图 ……（全栈）技能同学的话要想能流片（同时具备以上技能）其实也很难的。那么这时 FPGA 就可以验证你的设计是否在一定程度上是正确的。

## 0x02

我们最后再来看一下数字前端的设计流程，如下图所示~

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E6%95%B0%E5%AD%97%E5%89%8D%E7%AB%AF%E8%AE%BE%E8%AE%A1%E6%B5%81%E7%A8%8B%E5%9B%BE.png)

之前的 sdram 设计剩余部分,我们将尽快更新~

**By Ricky**
