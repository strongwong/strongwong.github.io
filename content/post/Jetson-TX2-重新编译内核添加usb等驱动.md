---
title: Jetson TX2 重新编译内核添加usb等驱动
tags:
  - Jetson TX2
  - Nvidia
  - 内核编译
  - 驱动
categories:
  - 学习
  - 毕业设计
abbrlink: 24166
date: 2018-08-20 18:55:00
---
### Jetson TX2 重新编译内核添加usb驱动
上一篇我们已经简单说明了怎么给 Jetson TX2 刷机，Jetson TX2 虽然已经成功完成刷机了，但是 Nvidia 的默认配置是禁用了一些驱动的，比如说板子上的 UART 串口就不可以用，需要用户自己安装，重新编译新的镜像。
本文这里就简单介绍一下，添加驱动并重新编译镜像。
在 GitHub 上有别人开源的编译新镜像的脚本文件，在 Jetsonhacks 的仓库里有。这里我们就使用他的脚本文件。

<!-- more -->

### 下载脚本
首先从 GitHub 上下载编译脚本
```$
$ git clone https://github.com/jetsonhacks/buildJetsonTX2Kernel.git
```
如果你是 JetPack3.2.1 版本，直接使用 git 下载的话没有问题，因为目前他更新到的最新版本是 JetPack 3.2.1 内核版本为 28.2.1 (2018-8-20)。但是我安装的是 JetPack 3.1 对应的内核版本是 28.1 所以是不能直接使用的。因此需要下载对应的内核版本的脚本才可以使用。
JetPack 3.1 版本的话就需要下载这个。
`
https://github.com/jetsonhacks/buildJetsonTX2Kernel/archive/vL4T28.1.tar.gz
`

### 解压，获取源码
下载好之后，解压缩，进入解压出来的文件夹，打开 Terminal 运行 getKernelSources.sh 脚本获取内核源码。
```$
$ ./getKernelSources.sh	
```
### 添加配置
下载完成之后就会打开一个 xconfig 配置界面。
设置你的镜像名称。打开设置 Genral Setup->Local version - append to kernel release，双击 Local version - append to kernel release
在文本框中输入名字，如我这里为 -jetsonbot-v0.1 ， 回车；如下图所示：
![](https://photo.ishield.cn/pic/5b8269849dc6d6533b592669)

在 xconfig 中按 Ctrl+F ，会弹出一个搜索框，输入你想要添加的设备驱动，比如可以添加 USB ACM， CH341 和 cp210x 串口驱动等，在搜索结果中选择对应的驱动，选中框打上勾即可。
我这里搜索的是 ACM 驱动，如下图所示：
![](https://photo.ishield.cn/pic/5b826b089dc6d6533b59266f)

设置好了之后，一定要保存你的设置， File->Save

### 编译新内核
保存好设置，关闭 xconfig 配置窗口，准备开始编译内核，编译过程大约需要 20 分钟。
运行 makeKernel.sh 脚本，开始编译新的内核。
```$
$ ./makeKernel.sh
```

### 重启
编译过程中，你可以去喝杯 coffee 放松一下，等待编译完成。
编译结束后，运行 copyImage.sh 脚本，将新编译的镜像文件拷贝到  /boot 目录下。拷贝完成重启 TX2 即可。
```$
$ ./copyImage.sh
$ reboot
```

### 结束语
至此，我们添加有 USB 串口相关驱动的镜像就在 TX2 上被安装好了，这样就可以愉快的使用串口了。快使用新镜像进行开发吧！
