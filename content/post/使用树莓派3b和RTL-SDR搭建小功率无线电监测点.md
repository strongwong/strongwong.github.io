---
title: 使用树莓派 3b 和 RTL_SDR 搭建小功率无线电监测点
tags:
  - SDR
  - 树莓派
categories:
  - 无线电
abbrlink: 59296
date: 2018-09-16 20:03:40
---

最近看了两部关于无线电相关的电影（『时空接触』、『黑洞频率』），对与无线电产生了很大的兴趣。现代由于互联网的发展，玩无线电的人越来越少了，了解无线电知识的人也不多了。但是还是有很多人在学习和使用软件定义无线电( Software Defined Radio -- SDR )，软件无线电可以做很多神奇事情！！

<!-- more -->
## SDR 是个什么东西？
> "软件无线电"( Software Defined Radio -- SDR )。实际上软件无线电技术的研究和开发已经有几十年的历史了，其中传统上以硬件实现的组件（例如混频器，滤波器，放大器，调制器\解调器，检测器等），通过个人计算机或嵌入式系统上的软件实现。最初源于美军的多制式电台项目，应用在军事领域。
> 在 21 世纪初，由于众多公司的努力，使得它已从军事领域转向民用领域，成为经济的、应用广泛的、全球第三代移动通信系统的战略基础。
> 到今天我们日常使用的移动通信系统中就在大量使用软件无线电技术， 比如基站中的信号处理大量的使用可编程的 FPGA 和 DSP 完成，比如手机当中的基带处理器也越来越多的采用软解调的方法(少数运算量特别大实时性要求特别高的模块除外，比如 turbo 解码器、扩频相关器等，这些模块往往在基带处理器中嵌入一些高度定制化"硬"核来实现)。

所以我们想要监听周围的无线电信号，自然是需要一个硬件的。

## 需要的硬件

- RTL-SDR (或者 HackRF等)
- Raspberry Pi 3 (或者 Linux 系统的电脑)
- 有网络
- 高频天线

我选择的是一根支持 rtl-sdr 的电视棒，就是采用 RTL2832u (频率范围为 64-1700mh )解调芯片的。这是瑞晟( Realtek )的一个芯片型号，原本是做电视棒芯片的。后来被人发现这个芯片具有非常广的频率接收范围，然后就被用来做 sdr 应用了。十分廉价！

## 安装 RTL_SDR 驱动程序
硬件已经有了，接下来就是安装相关的软件驱动，才可以使用

打开一个 Terminal 窗口，进入到你的 home 目录下。先更新一下系统的软件，然后开始安装需要的软件依赖。具体操作如下：
```bash
$ cd ~
$ sudo apt-get update
$ sudo apt-get install git
$ sudo apt-get install cmake
$ sudo apt-get install build-essential
$ sudo apt-get install libusb-1.0-0-dev
```

相关的依赖软件安装完成后，接下来下载 RTL2832u Osmocom 的驱动源代码，进行编译安装
```bash
$ git clone git://git.osmocom.org/rtl-sdr.git
$ cd rtl-sdr
$ mkdir -p build
$ cd build
$ cmake ../ -DINSTALL_UDEV_RULES=ON
$ make
$ sudo make install
$ sudo ldconfig
$ sudo cp ../rtl-sdr.rules /etc/udev/rules.d
```
将使用电视棒作为电视设备自动加载的默认驱动程序列入黑名单，因为它不能让电视棒作为 SDR 使用，并且将会与我们刚刚安装的新 Osmocom 驱动程序发生冲突

- 1. 以 administrator 权限打开 `/etc/modprobe.d` 文件夹
- 2. 在该目录下创建一个叫 `blacklist-rtl.conf` 的新文件，打开文件，在文件中加入 `blacklist dvb_usb_rtl28xxu` 这条指令
- 3. 保存文件，并重启

机器重启后，将电视棒插入 usb 接口，打开 Terminal 窗口，输入 `rtl_test -t` 命令，测试电视棒是否能够被正常驱动。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/rtl_test.png)
不用担心 PLL 未锁定或未找到 E4000 调谐器或 R820T 而不是 R820T2 等消息。如果你看到跟上图一样的内容，那么说明你的驱动程序安装成功了，并且电视棒成功运行。 接着你就可以安装一些应用程序，来收听无线电信号。

## 安装 dump1090 
电视棒的 rtl_sdr 驱动程序安装好了之后，我们在安装一个 dump1090 应用程序，这样我们就可以接收飞机的信号。
能很容易的捕获到飞机是飞机在飞行过程中要不断的报告自身的飞行状态(在 1090Mhz 频率进行广播)，这就是 ADS-B( 广播式自动相关监视系统) ，即一种航空交通监视系统，而且是使用全球性导航卫星系统、飞机xo的航电设备和地面基础设施， 能够在飞机和航管地面站 ( air-to-ground 即 aircraft to ATS ) 或是空对空 ( air-to-air 即 aircraft to aircraft )之间准确和迅速自动地传送飞行讯息； 其中包括有飞机的识别、位置、高度、速度和其他数据或信息。简单来说 ADS-B 是由飞机直接发出的数据包，让地面或其他飞机可以得知它的位置、高度、速度等信息。ADS-B 利用 112 个未加密的脉冲字在 978Mhz、1090Mhz 发射的信号。我们使用电视棒捕获这些信号，并通过 dump1090 将捕获到信号解析成飞机飞行的信息，生成地图。这样我们就能知道飞机的实时位置及其他信息。

打开一个新的 Terminal 窗口，安装 dump1090，并开启 dump1090 服务，然后我们就可以在 Terminal 窗口和浏览器中查看到飞行信息
```bash
$ cd ~
$ git clone git://github.com/tedsluis/dump1090.git
$ cd dump1090
$ make    # 编译源码
$ ./dump1090 --interactive --net --enable-agc		# run dump1090
```
收到的飞机的飞行信息如下图，dump 在启动时会开启自带的 WEB 服务器，并且 WEB 调用了谷歌地图的 API 接收到飞机的一些信息后会在页面地图上描绘出飞机的轨迹(谷歌地图目前需要科学上网)
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/dump1090.png)
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/dump1090air.png)
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/dump1090air2.png)
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/air.jpg)

## 安装 GQRX 收听各频率的广播
我们可以收听广播或者火腿(无线电爱好者)的呼叫。但是这里我在树莓派上没有安装成功。因为 GUN Radio 安装不成功的问题。
不过我在 windows 上听到了广播。
