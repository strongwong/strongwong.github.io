---
title: 什么是超低功耗基准测试——ULPMark Benchmark
tag:
  - ULPMark
  - Benchmark
  - EEMBC
  - 基准测试

date: 2021-03-20
---

## 0x00 前言
说起嵌入式领域的一些基准测试，大家可能更了解的是 Coremark Benchmark，也就是大家常说的 CPU (中央处理器)性能基准测试。ULPMark Benchmark 也和 Coremark 类似，ULPMark 即“Ultra-Low Power Mark” 超低功耗评分；二者都是由 EEMBC (嵌入式微处理器基准测试联盟)开发的一套用 C 语言编写的、易于移植的标准测试程序。略有不同的是 Coremark 是专门为测试处理器核心性能而设计的，而 ULPMark 是为了评价一款 MCU 的低功耗性能而设计的。在嵌入式领域中对一款芯片的评价一般来说都会非常关心两个指标，一个就是性能，另一个就是功耗。所以性能就看 Coremark 评分，低功耗就看 ULPMark 评分。Coremark 网上资料有很多，这里我就不做过多介绍了，那么低功耗性能测试为什么是 ULPMark 呢？

## 0x01 为什么低功耗 MCU 测评采用 ULPMark
首先，ULPMark 的测试代码与 Coremark 一样，几乎是一套与硬件无关的算法，是一套很标准化的测试，在不同的厂商的不同处理器上都可以运行，且使用相同的电流测试板记录电流数据，所以说大家几乎都是在相同的平台下进行测试的，这样在不同的处理器之间就具有可比性。
第二，所有人发布的测试评分提交给 EEMBC 组织时，都需要提供完整的操作流程说明，及测试代码包括测 bin 文件。所以在 EEMBC 官网上可以看到的评分(尤其是 EEMBC check 过，打勾的评分)，你拿对应被测件，按照发布的流程使用对应的 bin 文件，你几乎都可以复现出厂商在 EEMBC 上发布的评分。
其次，著名的低功耗芯片厂商几乎都在使用 ULPMark 作为测试标准，包括 Ambiq、Analog、TI、Renesas、ST、On Semi、NXP 等著名的嵌入式芯片厂商。
最后， EEMBC 也是一个很可靠的组织，他们致力于开发基准测试，他们发布过很多的基准测试，广泛应用于电信、网络、汽车电子、消费电子等领域。

那么 ULPMark 怎么测，都测些什么呢？

## 0x02 ULPMark 测试有什么
ULPMark 测试目前有三个部分，分别是 ULPMark-CoreProfile、ULPMark-PeripheralProfile 和 ULPMark-CoreMark。

|ULPMark 变体	| 测什么 |
|:--|:--|
|ULPMark-CoreProfile	|核心在深度睡眠模式下真正的能量消耗|
|ULPMark-PeripheralProfile	|普通外围设备的能量对深度睡眠的影响|
|ULPMark-CoreMark	|活跃功耗，使用 CoreMark 作为工作负载|

但在实际的测试对比中，大家一般都比较关心 CoreProfile 和 PeripheralProfile 两项评分，大多数情况下大家都是对比的 CoreProfile 的评分，简写 ULPMark-CP。也就是在深度睡眠下整个芯片的能量消耗；因为在低功耗的应用场景下，该芯片设备可能是单电池供电，需要运行长达 10 年的时间，所以芯片设备绝大部分时间应该都是处在深度睡眠的模式，偶尔唤醒处理部分任务。

因此，ULPMark-CP 的测试就是类似于这样的一个场景设计的。ULPMark-CP 基准测试在长时间睡眠中运行，然后短暂唤醒以执行最少的处理，从而模仿一个节能的边缘节点。如下图：

![ULPMark-CP](https://z3.ax1x.com/2021/03/20/64lMyq.png)

从上图中可以看到 ULPMark-CP 测试中，主要测量的就是在睡眠状态下的能量消耗，以及与活跃模式之间的切换，活跃模式时会运行一组工作负载，整个测试是以一秒为周期运行的，将工作负载与较长时间的不活动相结合交替运行，从而使用芯片的低功耗模式。

虽然基准测试的活跃部分仅运行了总运行时间的约 3％，但它要求通过使用 “保留 RAM” 在深度睡眠期间保存数据。由于很少有休眠的边缘节点在每个睡眠周期之后都清除它的 RAM，因此保留 RAM ，减少 RAM 数据重新刷新的成本，才能体现睡眠模式的真正能量消耗。

所以 ULPMark-CP 的评分基本上就可以看出一颗芯片的低功耗应用场景下的低功耗性能。

说了这么多，那 ULPMark-CP 都运行了些什么呢？ 要想知道那就要看测试代码了，但是 ULPMark 测试程序是需要授权的。不过 ULPMark 可以通过学校申请免费的学术授权，不过也只能是学术团队内部使用。

![License 申请](https://z3.ax1x.com/2021/03/21/64850x.png)

所以代码不宜直接公开，这里就简述一下其功能。

休眠时当然就是休眠了，那么在 Active 阶段，主要执行了以下操作：

> 会运行两次 Workload，每个 Workload 都包含以下几个工作：
> · 快速切换GPIO指示端口20次
> · 运行 24 次 16-bit 的滤波器运算，并根据每次的运算结果来设置状态机
> · 使用状态机的输出作为输入来运行 bin to LCD 转换功能，即模拟 LCD 显示器
> · 在基于上一步选择的字符串上运行子字符串搜索
> · 在搜索到的字符串上运行字节拷贝
> · 然后对上一步结果进行一个小的冒泡排序
> · 最后，根据输入和先前的状态对字符串的位进行排列
> · 执行完就进入休眠，等待下一次被唤醒，每一秒一次，无限重复

## 0x03 ULPMark 如何使用
如果你申请到了 ULPMark 的学术授权版本，那么应该怎么移植使用它呢？

通常你获得的 ULPMark-CP 的代码目录应该是这样的，如图。也有可能我这个版本比较老，和你新申请的可能会略有不同。但我想大体上应该是差不多的。

![ULPMark-CP TOC](https://z3.ax1x.com/2021/03/21/648XjA.png)

```bash
.
├── benchmarks
│   └── CoreProfile   # ULPMark-CP 核心代码
├── Platforms         # 相对应的芯片平台及开发板相关配置
│   └── ARM
│       ├── Board
│       └── Platform
├── TES               # RTC 中断唤醒时的调度
└── ulpbench.c
```

通常你只需要去修改 Platforms 下的文件， porting 到你的芯片上即可。一般情况下包括 系统时钟的设置，Low Power 模式的设置，相应 GPIO 引脚的设置，以及低功耗 RTC 的设置，当然还包括 RTC 中断的设置。将这些接口设置好基本上就完成了移植工作。然后将代码编译，烧写进芯片中。
软件代码准备好了之后，就是测量 ULPMark 测试代码在芯片上运行时产生的功耗了。那么如何测量呢？

## 0x04 ULPMark 测量使用的板子
测量我们的芯片在低功耗模式下的实际功耗，EEMBC 和 ST 合作，开发了一套标准的能量消耗监测板 EMON (Energy Monitor LPM01A)，Energy Monitor 能量监测板如下图，这块板子的详细信息可以在 ST 官网获取到，这里也就不做过多介绍了，链接：LPM01A

![EMON LPM01A](https://z3.ax1x.com/2021/03/21/64TiPx.png)

![LPM01A top layout](https://z3.ax1x.com/2021/03/21/64TTyD.png)

通常情况下，我们的被测板可能是不符合 Arduino Uno 和 Arduino Nano 接口的，所以我们一般直接使用 CN14 的基本插接口。
被测板的所有供电都由 Energy Monitor 提供，将 EMON CN14 接口中的 Vout 和 GND 分别连接到 DUT (被测件) 的 VDD 和 GND 上即可。如下图所示。

![EMON connect DUT](https://z3.ax1x.com/2021/03/21/64HDrF.png)

这里还需要在 ST 官网下载并安装相应的上位机软件，安装完成后，在 PC 上启动 STM32CubeMonitor-Power 软件，打开窗口后如下图所示。

![ST Mon Pwr](https://z3.ax1x.com/2021/03/21/64qc1x.png)

点击 TAKE CONTROL 连接能量监测板，在窗口中设置好需要的采样率、时间、电流、电压等参数后，点击 START ACQUISITION 按钮，就可以看到 DUT 运行时对应的电流消耗。
点击 ULP BENCH 标签栏后，同样设置好需要的参数后，点击运行，就可以直接获得 ULPMark 评分，如下图，评分越高代表低功耗性能越好。

![ULP BENCH](hhttps://z3.ax1x.com/2021/03/21/64O4fA.png)

## 0x05 ULPMark 的评分是如何计算的？
那么 ULP Benchmark 的评分是如何计算的呢？如果我们手上没有 Energy Monitor 这个能量监测板，我们有没有其他办法计算出我们的低功耗性能？
ULP Benchmark 的计算公式是这样的：

![ULP Score](https://z3.ax1x.com/2021/03/21/64XWuV.jpg)

就是 1000 除以，在 10 次 ULP 周期中取其中 5 次的能量均值，计算出得分，所以这个评分的单位就是 uJ/s 即 μ焦/秒。

所以根据这个公式，我们只要知道了我们芯片在单位时间内的能量消耗，就可以计算我们的低功耗评分。那么如何知道消耗的能量呢，那当然就是测量在单位时间内，额定电压下的电流消耗值，这样我们就可以计算了。虽然这样说起来简单，但是要想精确的测量在睡眠模式下的电流是不容易的，因为一般的低功耗芯片在深度睡眠模式下的电流消耗都是以 nA 计算的，一般的电流源无法做到这么精确。但方法总是有的。

假设我们在 3V 的电压下，测量到了相应的电流消耗，那么我们计算公式就可以这样写了。

![3V ULP Score](https://z3.ax1x.com/2021/03/21/64zZVK.jpg)

当然，这个地方的电流还是粗略的，如果你还想在更加精确的分析，那么还应该去把 Active Current 和 Sleep Current 分开计算，然后在计算总的能量消耗。除此之外，不同编译器不同优化选项编译出的代码对于电流的消耗也存在一些差异。

## 0x06 总结
好了，到这里关于 ULPMark 的介绍就基本完成了，相信通过本文的简单介绍，你应该对 ULPMark 有了一定的认识，让我们一起学习进步，欢迎大家和我交流！
贴一张目前 ULPMark-CP 目前的评分排行榜(前 25 名)

![65iQxg.png](https://z3.ax1x.com/2021/03/21/65iQxg.png)

### 参考链接：
https://www.eembc.org/ulpmark/
https://www.eembc.org/ulpmark/scores.php