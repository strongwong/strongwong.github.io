---
title: ROS 基础知识
tags:
  - ROS
categories:
  - 学习
  - 毕业设计
abbrlink: 24706
date: 2018-09-01 10:59:46
---
### ROS 基础知识
上一篇，我们已经正确的安装好了 ROS ，但是在使用 ROS 进行机器人开发工作之前，我们先来了解一点 ROS 的基础知识，以便于后面的开发使用。当然我这里自然是没有 ROS wiki 上介绍的详细，要想学习更多的操作请先看 ROS wiki 上的[入门教程](http://wiki.ros.org/cn/ROS/StartGuide)
这里我只简单介绍一下，在我的项目中会用到的一些操作。

<!-- more -->

### 创建工作空间
ROS 使用一个名为 catkin 的 ROS 专用构建系统。为了使用它，用户需要创建并初始化 catkin 工作空间，如下所示。除非用户创建新的工作空间，否则此设置只需设置一次。工作空间（ workspace ）简单来说就是一个存放工程开发相关文件的文件夹。主要目录结构如下：
- src: 代码空间 ( source space )
- build: 编译空间 ( build space )
- devel: 开发空间 ( development space )
- install: 安装空间 ( install space )

![catkin 编译系统下的工作空间结构](https://ww3.sinaimg.cn/large/005YhI8igy1fuvaso3mffj30lf0jfq3c)

#### 创建工作空间
```bash
$ mkdir -p ~/catkin_ws/src   # 创建工作空间机源码空间
$ cd ~/catkin_ws/src
$ catkin_init_workspace      # 初始化工作空间
```
#### 编译工作空间
目前，只有 src 目录和 CMakeLists.txt 文件(运行初始化命令后就会生成)在 catkin 工作目录中，即使 src 目录中没有源代码，我们仍然可以使用 catkin_make 命令来进行构建。
```bash
$ cd ~/catkin_ws/
$ catkin_make
```
如果构建没有问题，运行 ls 命令。除了自己创建的 src 目录之外，还出现了一个新的 build 和 devel 目录。 catkin 的构建系统的相关文件保存在 build 目录中，构建后的可执行文件保存在 devel 目录中。
#### 设置环境变量
```bash
$ source ~/catkin_ws/devel/setup.bash
```
#### 检查环境变量
```bash
$ echo $ROS_PACKAGE_PATH
/home/ubuntu/catkin_ws/src:/opt/ros/kinetic/share:/opt/ros/kinetic/stacks
```

### 创建功能包
一个功能包它是是构成 ROS 的基本单元。 ROS 应用程序是以功能包为单位开发的。功能包包括至少一个以上的节点或拥有用于运行其他功能包的节点的配置文件。它还包含功能包所需的所有文件，如用于运行各种进程的 ROS 依赖库、数据集和配置文件等。
#### 创建功能包
```bash
$ cd ~/catkin_ws/src
# 创建功能包命令格式如下：
$ catkin_create_pkg [功能包名称] [依赖功能包 1] [依赖功能包 n]
```
「catkin_create_pkg」命令在创建用户功能包时会生成 catkin 构建系统所需的 CMakeLists.txt 和 package.xml 文件的包目录。
**注：同一个工作空间下，不允许存在同名功能包；在不同工作空间下，允许存在同名功能包。**
#### 编译功能包
```bash
$ cd ~/catkin_ws
$ catkin_make
```

### ROS 通信
为了最大化用户的可重用性，ROS 是以节点的形式开发的，而节点是根据其目的细分的可执行程序的最小单位。节点则通过消息（ message ）与其他的节点交换数据，最终成为一个大型的程序。这里的关键概念是节点之间的消息通信，它分为三种。单向消息发送/接收方式的话题（ topic ）；双向消息请求/响应方式的服务（ service ）；双向消息目标（ goal ）/结果（ result ）/反馈（ feedback ）方式的动作（ action ）。另外，节点中使用的参数可以从外部进行修改。这在大的框架中也可以被看作消息通信。如下图所示：
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E6%B6%88%E6%81%AF%E9%80%9A%E4%BF%A1.jpg)

| 种类 | 区别 | 方向 | 响应 |
| :---: | :---: | :---: | :---: |
| 话题 | 异步 | 单向 | 连续单向地发送/接收数据的情况 |
| 服务 | 同步 | 双向 | 需要对请求给出即时响应的情况 |
| 动作 | 异步 | 双向 | 请求与响应之间需要太长的时间，所以难以使用服务的情况，或需要中途反馈值的情况 |

#### 话题通信
话题消息通信是指发送信息的发布者和接收信息的订阅者以话题消息的形式发送和接收信息。希望接收话题的订阅者节点接收的是与在主节点中注册的话题名称对应的发布者节点的信息。基于这个信息，订阅者节点直接连接到发布者节点来发送和接收消息。另外，单个发布者可以与多个订阅者进行通信，相反，一个订阅者可以在单个话题上与多个发布者进行通信。当然，这两家发布者都可以和多个订阅者进行通信。

#### 服务通信
服务消息通信是指请求服务的服务客户端与负责服务响应的服务服务器之间的同步双向服务消息通信。前述的发布和订阅概念的话题通信方法是一种异步方法，是根据需要传输和接收给定数据的一种非常好的方法。然而，在某些情况下，需要一种同时使用请求和响应的同步消息交换方案。因此，ROS 提供叫做服务的消息同步方法。
一个服务被分成服务服务器和服务客户端，其中服务服务器只在有请求（ request ）的时候才响应（response），而服务客户端会在发送请求后接收响应。与话题不同，服务是一次性消息通信。因此，当服务的请求和响应完成时，两个连接的节点将被断开。该服务通常被用作请求机器人执行特定操作时使用的命令，或者用于根据特定条件需要产生事件的节点。由于它是一次性的通信方式，又因为它在网络上的负载很小，所以它也被用作代替话题的手段，因此是一种非常有用的通信手段。

#### 动作通信
动作消息通信是在如下情况使用的消息通信方式：服务器收到请求后直到响应所需的时间较长，且需要中途反馈值。这与服务非常相似，服务具有与请求和响应分别对应的目标（ goal ）和结果（ result ）。除此之外动作中还多了反馈（ feedback ）。收到请求后需要很长时间才能响应，又需要中间值时，使用这个反馈发送相关的数据。消息传输方案本身与异步方式的话题（ topic ）相同。反馈在动作客户端（ action client ）和动作服务器（ action server ）之间执行异步双向消息通信，其中动作客户端设置动作目标（ goal ），而动作服务器根据目标执行指定的工作，并将动作反馈和动作结果发送给动作客户端。

### 消息通信过程
主节点管理节点信息，每个节点根据需要与其他节点进行连接和消息通信。以话题消息为例，具体通信步骤如下。
#### 运行主节点
节点之间的消息通信当中，管理连接信息的主节点是为使用 ROS 必须首先运行的必需元素。ROS 主节点使用 roscore 命令来运行，并使用 XMLRPC 运行服务器。主节点为了节点与节点的连接，会注册节点的名称、话题、服务、动作名称、消息类型、URI 地址和端口，并在有请求时将此信息通知给其他节点。
运行 `roscore` 命令就启动了主节点。
#### 运行订阅者节点
订阅者节点使用 rosrun 或 roslaunch 命令来运行。订阅者节点在运行时向主节点注册其订阅者节点名称、话题名称、消息类型、URI 地址和端口。主节点和节点使用 XMLRPC 进行通信。
```$
$ rosrun PACKAGE_NAME NODE_NAME
$ roslaunch PACKAGE_NAME LAUNCH_NAME
```
#### 运行发布者节点
发布者节点（与订阅者节点类似）使用 rosrun 或 roslaunch 命令来运行。发布者节点向主节点注册发布者节点名称、话题名称、消息类型、 URI 地址和端口。主节点和节点使用 XMLRPC 进行通信。
#### 通知发布者信息
主节点向订阅者节点发送此订阅者希望访问的发布者的名称、话题名称、消息类型、 URI 地址和端口等信息。主节点和节点使用 XMLRPC 进行通信。
#### 订阅者节点的连接请求
订阅者节点根据从主节点接收的发布者信息，向发布者节点请求直接连接。在这种情况下，要发送的信息包括订阅者节点名称、话题名称和消息类型。发布者节点和订阅者节点使用 XMLRPC 进行通信。
#### 发布者节点的连接响应
发布者节点将 TCP 服务器的 URI 地址和端口作为连接响应发送给订阅者节点。发布者节点和订阅者节点使用 XMLRPC 进行通信。
#### TCPROS 连接
订阅者节点使用 TCPROS 创建一个与发布者节点对应的客户端，并直接与发布者节点连接。节点间通信使用一种称为 TCPROS 的 TCP/IP 方式。
#### 发送消息
发布者节点向订阅者节点发送消息。节点间通信使用一种称为 TCPROS 的 TCP/IP 方式。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/%E8%AF%9D%E9%A2%98%E6%B6%88%E6%81%AF%E9%80%9A%E4%BF%A1%E6%A8%A1%E5%9E%8B.jpg)
服务消息，服务服务器和客户端之间的连接与上述发布者和订阅者之间的 TCPROS 连接相同，但是与话题不同，服务只连接一次，在执行请求和响应之后彼此断开连接。如果有必要，需要重新连接。
动作消息，动作（ action ）在执行的方式上好像是在服务（ service ）的请求（ goal ）和响应( result ）之间仅仅多了中途反馈环节，但实际的运作方式与话题相同。事实上，如果使用 rostopic 命令来查阅话题，那么可以看到该动作的 goal、status、cancel、result 和 feedback 等五个话题。动作服务器和客户端之间的连接与上述发布者和订阅中的 TCPROS 连接相同，但某些用法略有不同。例如，动作客户端发送取消命令或服务器发送结果值会中断连接等。


