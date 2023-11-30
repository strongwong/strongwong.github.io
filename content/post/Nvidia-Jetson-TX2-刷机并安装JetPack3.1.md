---
title: Nvidia Jetson TX2 刷机并安装JetPack3.1
tags:
  - Jetson TX2
  - Nvidia
  - 刷机
categories:
  - 学习
  - 毕业设计
abbrlink: 55425
date: 2018-08-12 20:15:29
---
## Nvidia Jetson TX2 刷机并安装 JetPack3.1

上篇，我已经简单介绍了一下我的整个小车的物理框架和软件架构。下面我可能会分成几次推文，介绍一下搭建小车的具体过程。
本次主要记录一下给 Nvidia Jetson TX2 开发板刷机的过程。

<!-- more -->

### 准备工具
1.一块Jetson TX2 开发板

2.一台安装 Ubuntu 系统的独立主机(不建议使用虚拟机，推荐使用 Ubuntu 16.04)

3.一台路由器

4.两根网线，一根 micro usb 数据线

### 准备工作
1.首先需要从 Nvidia 的官方网站上下载 Jet Pack3.1 的安装包，使用 Ubuntu host 直接下载或者下载好拷贝到 host 上也可以。(我当时最新的是 Jet Pack3.1 ，现在已经到 3.3 了，你也可以使用最新的版本。下载的话需要 Nvidia 账号才可以)
下载网址：[https://developer.nvidia.com/embedded/jetpack](https://developer.nvidia.com/embedded/jetpack)

2.将 TX2 开发板和主机都通过网线连接到一台路由器上。准备好 TX2 开发板和 Ubuntu Host 之后就可以开始刷机了。

### 安装
下载好 Jet Pack3.1 安装包后，打开 Terminal 进入到安装包所在的目录，执行下面这条命令运行安装包。运行效果如下图。(如果文件没有执行权限可以使用 chmod -x file 命令来改变执行权限)

`$
 ./JetPack-L4T-3.1-linux-x64.run
`

运行完会弹出 JetPack L4T 3.1 Installer, 一路 Next 就好，如下图：
![](https://files.catbox.moe/n9dnwk.png)

注意选择 Jetson TX2 开发板
![](https://photo.ishield.cn/pic/5b702af99dc6d6522bb72f67)

点击 Next 之后会提示输入密码，待安装完成后，就会进入 JetPack L4T Component Manager。(这里要注意，如果网络不好可能会要等很久也出不来安装包信息，所以一定要保证网络环境好，可能有一些包还需要科学上网。)
如果你的包加载好了，检查一下 CUDA Toolkit 和 OpenCV for Tegra 这两个包是否选择了，这两个一定要安装。选择好之后，点击 Next 。在弹出的弹框中勾选所有协议，等待各种包下载完成。
![](https://photo.ishield.cn/pic/5b702c3e9dc6d6522bb72f6c)
![](https://photo.ishield.cn/pic/5b702b289dc6d6522bb72f68)

下载完成后，选择 Host 和 TX2 的连接方式，我们选择第一项，通过同一路由器连接在同一网络。网口选择保持默认就好。
![](https://files.catbox.moe/hvd0oi.png)

接下来就是将包移动到 TX2 开发板上。文件较大，可能要等一会。执行下一步后，会出现一个提示重启 TX2 的步骤。按照提示进行操作。

第一步，将 TX2 关机， 拔下电源，使用 micro usb 数据线将 TX2 与 Host 相连。

第二步，重新插上电源，启动 TX2 ，同时按住 rec 和 rst 两个按键两秒钟， 然后松开 rst 按键，按住 rec 按键 3 秒钟。

第三步，这时在 Host 端，重新打开一个 terminal，查看 usb 端口信息(使用命令 lsusb 就可以查看)，这时应该就可以看 ID 为 0955:7C18 的叫 Nvidia Corp 的端口，就说明 TX2 已经进入 REC 模式并和 host 连接好了，这时回到有重启步骤的窗口，按回车 Enter，就开始 TX2 固件更新了。
![](https://photo.ishield.cn/pic/5b702bda9dc6d6522bb72f6a)
![](https://photo.ishield.cn/pic/5b702bf19dc6d6522bb72f6b)

安装完成后 TX2 就会重新启动，然后接下来会进行 CUDA 等一些软件的安装。

至此，Nvidia TX2 的安装就基本完成了。就可以愉快的在 Jetson TX2 上进行开发啦！


### 结束语
在 TX2 上进行基本开发的环境就已经基本搭建好了，但是大型的开发可能 TX2 本身自带的 30 多个 G 内存可能是不够的，因此我们可能还需要一个容量较大的 SSD 来放系统。还有就是 TX2 开发板默认的镜像设置可能会有一些端口没有开放，为了跟好的开发，所以后面需要我们自己重新编译镜像。这些在后面我会继续介绍。