---
title: 在 Jetson TX2 上安装 ROS 机器人操作系统
tags:
  - Jetson TX2
  - ROS
categories:
  - 学习
  - 毕业设计
abbrlink: 58888
date: 2018-08-26 21:17:26
---

### ROS 机器人操作系统
关于 ROS ( Robot Operating System 机器人操作系统)，这里做一下简单的介绍。ROS 就是一个机器人软件平台，类似于个人电脑的操作系统( Windows、Linux、Mac OS 等)，智能手机的操作系统( Android、iOS 等)。机器人和电脑、手机一样可以通过各种硬件组合的硬件模块组成，自然就出现了用来管理这些硬件的操作系统。操作系统提供了基于硬件抽象的软件开发环境，存在提供各种服务的应用程序。
ROS 就是这样一个提供了类似操作系统的硬件抽象。在 ROS 维基中将 ROS 定义为 “ ROS 是一个开放源代码的机器人元操作系统。它提供了我们对操作系统期望的服务，包括硬件抽象、低级设备控制、常用功能的实现、进程之间的消息传递以及功能包管理。它还提供了用于在多台计算机之间获取、构建、编写和运行代码的工具和库。 ”
因此，ROS 并不是一种新的操作系统，确切的说，ROS 是一种元级操作系统。是基于现有操作系统的，利用应用程序和分布式计算资源之间的虚拟化层来运用分布式计算资源来执行调度、加载、监视、错误处理等任务的系统。同时提供一个或多个操作系统下的数据通信。

<!-- more -->

对于 ROS 的安装，之前官方网站上是没有中文教程的，对于我这种塑料英语，直接看官网英文教程还是蛮有难度的。不过好在现在 ROS 官网已经有中文版的安装教程了。直接参考官网上的教程安装就好了！
官网安装教程：[http://wiki.ros.org/cn/kinetic/Installation](http://wiki.ros.org/cn/kinetic/Installation)

### ROS 版本
虽然官方已经有了中文版本的安装教程，但是我这里还是简单记录一下。
首先，ROS 目前大家使用的主流版本还是 ROS 1.0 的版本，ROS 1.0 版本目前只支持 Linux 系统。而对 ROS 兼容性最好的就是 Ubuntu 操作系统了，恰好我们的 Jetson TX2 就是 Ubuntu 系统。

这里还要说明的是，我们在 TX2 上安装 ROS 系统，并不是要直接在 TX2 上来做开发的(虽然也可以)， TX2 主要是作为部署端的。因此，还需要有一台 Ubuntu 电脑也需要安装上 ROS 来进行开发工作，安装步骤相同。

其次， Ubuntu 和 ROS 都有很多版本，各版本之间是存在兼容性问题的。ROS 和 Ubuntu 之间的版本对应关系如下表：


| ROS 版本 | 发布日期 | 对应的 Ubuntu 版本 | 停止支持日期 |
|:---:|:---:|:------:|:---:|
| ROS Melodic | 2018.5.23 | Ubuntu 18.04(Bionic)/Ubuntu 17.10(Artful) | 2023.5 |
| ROS Lunar | 2017.5.23 | Ubuntu 17.04(Zesty)/Ubuntu 16.10(Yakkety)/Ubuntu16.04(Xenial) | 2019.5 |
| ROS Kinetic(推荐) | 2016.5.23 | Ubuntu 16.04(Xenial)/Ubuntu 15.10(Wily) | 2021.4 |
| ROS Jade | 2015.5.23 | Ubuntu 15.04(Wily)/Ubuntu LTS 14.04(Trusty) | 2017.5 |
| ROS Kinetic | 2014.7.22 | Ubuntu LTS 14.04(Trusty) | 2019.4 |

目前主流版本还是 ROS Kinetic 且支持时间较长，今年新出的 Melodic 版资料相对较少。所以推荐安装 ROS Kinetic 版本。

### 安装
#### 软件中心配置
打开软件和更新对话框，配置你的 Ubuntu 软件仓库( repositories )以允许“restricted”，“universe”和“multiverse”这三种安装模式。如下图：
![](https://photo.ishield.cn/pic/5b89420e9dc6d659595a1950)
配置完成关闭窗口。
#### 添加source.list
设置你的电脑可以从 packages.ros.org 接收软件。
打开一个 Terminal ( Ctrl+Alt+T )，输入以下命令：
```$
$ sudo sh -c 'echo “deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc)main”> /etc/apt/sources.list.d/ros-latest.list'
```
这个镜像国内会比较慢，建议更换为国内镜像源，就是把上面的命令更换一下。官方[镜像](http://wiki.ros.org/ROS/Installation/UbuntuMirrors)
#### 添加密钥
```$
$ sudo apt-key adv --keyserver hkp：//ha.pool.sks-keyservers.net:80 --recv-key 421C365BD9FF1F717815A3895523BAEEB01FA116
```
如果你遇到连接到 keyserver 的问题，你可以在以上命令尝试替换 hkp://pgp.mit.edu:80 或 hkp://keyserver.ubuntu.com:80 
密钥可以根据服务器的操作发生变更，如有变化，请参考[官方wiki](http://wiki.ros.org/cn/kinetic/Installation/Ubuntu)页面。
#### 安装 ROS
首先，确保你的系统软件是最新版本
```bash
$ sudo apt-get update
```
接下来，就可以安装 ROS 了，但是 ROS Kinetic 也有好几个版本，这里我们安装全功能版本(包括ROS、rqt、RViz、机器人相关的库、仿真和导航等等。部署端一般基础版就可以了)。
```bash
$ sudo apt-get install ros-kinetic-desktop-full
```
这里可能会要等待几分钟，因网速而定。如果一切顺利的话，那就安装完了。
安装完成后，可以使用下面的命令查看可使用的软件包(可以搜索到大约1600多个功能包)：
```bash
$ apt-cache search ros-kinetic
```
> 如果想个别安装功能包，请使用如下命令:
> ```bash
> $ sudo apt-get install ros-kinetic-[功能包名称]
> ```
现在是安装完了，但是我们还需要初始化 ROS 以及配置环境变量
#### 初始化 rosdep
在开始使用 ROS 之前还需要初始化 rosdep 。rosdep 可以方便地在需要编译某些源码的时候为其安装一些系统依赖，同时也是某些 ROS 核心功能组件所必需用到的工具。
```bash
$ sudo rosdep init
$ rosdep update
```
#### 配置环境
如果每次打开一个新的终端时 ROS 环境变量都能够自动配置好(即添加到 bash 会话中)，那将会方便很多：
```$
$ echo "source /opt/ros/kinetic/setup.bash" >> ~/.bashrc
$ source ~/.bashrc
```
可以使用 gedit 或者 vi 等编辑器打开 bashrc 文件查看是否配置成功。在 bashrc 文件最底部我们可以看到已经有了很多设置。不要修改以前的设置，如果你需要修改的话在最底部添加就好了。
```bash
# Set ROS Kinetic
source /opt/ros/kinetic/setup.bash
source ~/catkin_ws/devel/setup.bash

# Set ROS Network
export ROS_HOSTNAME=xxx.xxx.xxx.xxx
export ROS_MASTER_URI=http://${ROS_HOSTNAME}:11311
```

#### 安装构建依赖
到目前为止，已经安装了运行核心 ROS 包所需的内容。为了创建和管理自己的 ROS 工作区，有各种各样的工具和需求分别分布。例如：rosinstall 是一个经常使用的命令行工具，它能够轻松地从一个命令下载许多 ROS 包的源树。

要安装这个工具和其他构建 ROS 包的依赖项，请运行:
```bash
$ sudo apt-get install python-rosinstall python-rosinstall-generator python-wstool build-essential
```
好！到这里，ROS 就基本安装完成了。下面就来测试一下，看看是否可以正常运行。

### 测试 ROS
首先，启动 ROS 环境
输入 roscore 命令，测试测试结果如下：
```$
$ roscore
... logging to /home/ubuntu/.ros/log/3e61b674-03cf-11e8-ac54-9cb70ddc3658/roslaunch-ubuntu-31481.log
Checking log directory for disk usage. This may take awhile.
Press Ctrl-C to interrupt
Done checking log file disk usage. Usage is <1GB.
started roslaunch server http://ubuntu:11311/
ros_comm version 1.12.12
SUMMARY
========
PARAMETERS
 * /rosdistro: kinetic
 * /rosversion: 1.12.12
NODES
auto-starting new master
process[master]: started with pid [31495]
ROS_MASTER_URI=http://ubuntu:11311/
setting /run_id to 3e61b674-03cf-11e8-ac54-9cb70ddc3658
process[rosout-1]: started with pid [31508]
started core service [/rosout]
```
如果看到 started core service [/rosout] ，那就说明安装成功了！退出按『Ctrl+c』。

如果你安装过程中出现了问题，可以尝试换个网络，或者多试几次吧，有时候服务器就是连不上！\*_\*

