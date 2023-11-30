---
title: 用 Kindle 做树莓派的显示屏
tags:
  - 树莓派
  - Kindle
categories:
  - 折腾
date: 2020-05-24
---

## 一、工具
1. 树莓派3b 一台
2. Kindle PaperWhite 1 一台
3. 无线键鼠一套
4. 无线路由器 or USB 数据线

## 二、Kindle 越狱

首先，按照网上的教程把 Kindle 越狱。但是我手上这台 kindle 是 *5.6.1.1* 的最高版本了。不能直接越狱，需要先把其刷机，强行固件降级到 5.4.4 版本才能越狱。越狱前注意事项，建议遵守：

- 确认 Kindle 已绑定亚马逊账号；
- 确认 Kindle 电量处于充满状态；
- 确认 Kindle 的特惠广告已关闭；
- 确认 Kindle 已停用 设备密码和家长监护设置；
- 确认 Kindle 已开启飞行模式处于离线状态。

### 2.1 固件降级

如果你的 KPW1 也和我一样是高于 *5.4.4* 的版本，需要先把固件降级到 *5.4.4*。可以前往书伴的 『[固件大全](https://bookfere.com/update)』 下载 *5.4.4* 版本固件，然后把 Kindle 连接到电脑直到出现 Kindle 磁盘。把下载到的固件文件 update_kindle_5.4.4.bin 放到 Kindle 的根目录。**不要拔出数据线，直接长按电源键直到开始更新。** 没有问题继续下一步。

### 2.2 开始越狱

下载越狱文件『[kindle-jailbreak-1.14.N.zip](https://pan.baidu.com/s/1o86ja8i)』。解压得到压缩包 kindle-5.4-jailbreak.zip，将其再次解压，得到一个名为 kindle-5.4-jailbreak 的文件夹。文件夹内有如下所示七个文件：

- bridge.conf
- bridge.sh
- developer.keystore
- gandalf
- jb.sh
- json_simple-1.1.jar
- Update_jb_$(cd mnt && cd us && sh jb.sh).bin

把这些文件拷贝到 Kindle 根目录，安全弹出磁盘。在 Kindle 中依次点击『 *首页 -> 菜单（屏幕右上角）-> 设置 -> 菜单（屏幕右上角）-> 更新您的 Kindle*』。点击菜单后系统不会重启也不会有其它任何反应，在这期间不要有任何操作，直到屏幕下方出现 『 ** **JAILBREAK** ** 』的字样时，表示越狱已成功。

![越狱](https://s1.ax1x.com/2020/05/24/tS3hOU.jpg)

### 2.3 升级固件
最后前往书伴的 『[固件大全](https://bookfere.com/update)』下载最新的 5.6.1.1 版本固件，将固件文件放到 Kindle 根目录，依次点击菜单『 *首页 -> 菜单（屏幕右上角）-> 设置 -> 菜单（屏幕右上角）-> 更新您的 Kindle*』。等待更新完毕，便得到一个有着最新版本固件的越狱了的 Kindle 系统，你可以进行安装MRPI、KUAL、kterm 、USBNetwork 等插件来完成接下来的操作。

## 三、安装插件
### 3.1 安装 MobileRead Package Installer (MRPI) —— 插件安装器

- 下载 MRPI：百度网盘【提取码：xwbg】
- 官方指南：KUAL: Kindle Unified Application Launcher (v 2.6)
  ★ 安装步骤：

> 1. 用 USB 数据线将 Kindle 连接到电脑上，直到出现 Kindle 磁盘；
> 2. 解压缩下载到的 kual-mrinstaller-1.7.N-xxx.tar.xz 得到一个文件夹；
> 3. 把文件夹内的 extensions 和 mrpackages 拷贝到 Kindle 根目录下。

### 3.2 安装 KUAL —— 插件程序启动器
KUAL (即 Kindle Unified Application Launcher)，是一款插件启动器。安装KUAL之后，你可以下载或自己编写插件并通过KUAL启动。

- 下载 KUAL：[百度网盘](https://pan.baidu.com/s/1DadoxnlX7u3pjVjrntt_Yw)【提取码：4kb1】
- 官方指南：KUAL: [Kindle Unified Application Launcher (v 2.6)](https://www.mobileread.com/forums/showthread.php?t=203326)

  ★ 安装步骤：

> 1. 用 USB 数据线将 Kindle 连接到电脑上，直到出现 Kindle 磁盘；
> 2. 解压缩下载到的 KUAL-v2.x-xxx.tar.xz 得到一个文件夹；
> 3. 在文件夹中找到 KUAL-KDK-2.0.azw2 拷贝到 Kindle 的 Documents 文件夹中；
> 4. 弹出 Kindle 磁盘，打开 Kindle，可以看到一个名 Kindle LAUNCHER 的文档，正常情况下，点开此图标应显示菜单。

### 3.3 安装 Kterm

*kterm* 是 Kindle 的终端控制台，安装之后可以在 Kindle 进行 shell 的交互操作。

下载 Kterm: [官方页面](https://github.com/bfabiszewski/kterm/releases/download/v2.6/kterm-kindle-2.6.zip) | [百度网盘](http://pan.baidu.com/s/1c0ja8hE)
官方说明： [https://www.fabiszewski.net/kindle-terminal/](https://www.fabiszewski.net/kindle-terminal/)

★ 安装步骤：

> 1. 首先确保安装好了 *KUAL* 和 *MRPI*;
> 2. 下载 kterm-kindle-2.6.zip，解压得到 *Kterm* 文件夹；
> 3. 将 Kterm 整个文件夹，复制到 Kindle 根目录下的 extensions 文件夹中；弹出 kindle，重启即可。

点击 Kindle 中的 *Kindle LAUNCHER -> Kterm*，即可打开 shell 使用。如果 Kindle 和树莓派连接到了同一个 wifi 下的话，就可以直接通过 Kterm 窗口使用 SSH 登录到树莓派使用了。

```bash
$ ssh pi@10.0.0.31    # ssh $user@ip
```

接着输入账户密码就可以登录了。

![Kindle Shell](https://s1.ax1x.com/2020/05/24/tSZ8CF.png)

### 3.4 安装 USBNetwork Hack – 无线管理 Kindle
USBNetwork 是一款 Kindle 插件，它可以让我们通过 WiFi 直接连接到 Kindle 并对其进行传送文件、管理等操作。可以通过 USB 连接 Kindle 和树莓派，通过把 Kindle 当成一块 USB 网卡，这样 Kindle 就可以和树莓派建立物理连接了。

- 下载 USBNetwork：[官方页面](https://www.mobileread.com/forums/showthread.php?t=225030) | [百度网盘](https://pan.baidu.com/s/1qAgVhwfLXY2Z6VyHh5PCEw)【提取码：9tgy】
- 官方指南：[K5/PW USBNetwork](https://www.mobileread.com/forums/showthread.php?t=186645)
★ 安装步骤：

> 1. 首先确保安装了 KUAL 及其插件 MRPI；
> 2. 用 USB 数据线将 Kindle 连接到电脑上，直到出现 Kindle 磁盘；
> 3. 解压缩下载到的 kindle-usbnet-0.22.N-xxx.tar.xz 压缩包，得到一个文件夹；
> 4. 把文件夹内的 Update_usbnet_0.22.N_install_touch_pw.bin 拷贝到 Kindle 里 mrpackages 文件夹中；
> 5. 弹出 Kindle 磁盘，点击 Kindle 中的 Kindle LAUNCHER，依次点击 Helper -> Install MR Packages；
> 6. 耐心等待 usbnet 安装，直到安装完成后 Kindle 重启完毕；
> 7. 重启完成后，重新用 USB 数据线将 Kindle 连接到电脑上，直到出现 Kindle 磁盘；
> 8. 在 Kindle 根目录可以看到『 usbnet 』文件夹，把此文件夹里名为『 DISABLED_auto 』的文件名改为『auto 』；
> 9. 然后在此文件夹里的『 etc 』文件夹中找到『 config 』，并用纯文本编辑器（不建议使用记事本，建议使用VS Code 等代码编辑器）打开。找到『 USE_WIFI 』改为 true，『 USE_WIFI_SSHD_ONLY 』改为 false ，保存并关闭；
> 10. 这样就可以通过 WIFI 和 USBNet 登录 Kindle 了。完成这些步骤之后，点击弹出/移除设备，断开 Kindle 与电脑的连接，重启 Kindle。

## 四、 配置树莓派，连接 Kindle

连接 Kindle 和 树莓派有两种方式，一种是把 Kindle 和树莓派连接到同一个 WIFI；另一种就是让 Kindle 作为 USB 网卡，通过 USBNet 的方式用 USB 数据线物理连接树莓派。但是想让 Kindle 作为屏幕使用，其实就是通过 screen、tmux 等软件共享屏幕。我这里安装的是 tmux。

### 4.1 安装 tmux

```bash
$ sudo apt update
$ sudo apt install tmux
```
在 *~/.bashrc* 文件最后添加一段脚本，自动运行 tmux。

```bash
# start tmux on console(not ssh)
if command -v tmux>/dev/null; then
      if [[ "$(tty)" =~ /dev/tty ]] && [ -z "$TMUX" ]; then
          # We're on a TTY and *not* in tmux
          exec tmux -u
      fi
fi
```

### 4.2 通过 WIFI 连接树莓派
点击 Kindle 中的 *Kindle LAUNCHER -> Kterm*,通过 SSH 连接树莓派；在这之前你需要先查看一下树莓派的 IP 地址是多少。

```bash
$ ssh pi@10.0.0.31 -t "tmux attach"
```
接着输入账户密码就可以登录了。

### 4.3 通过 USBNet 连接树莓派

首先打开 *Kindle LAUNCHER -> USBNetwork -> Toggle USBNetwork*，将模式切换到 *USB Network* 模式；当前状态可点击 *USBNetwork Status* 查看，成功的话提示USBNetwork enabled。
可以打开 *kterm* 使用 *ifconfig* 命令查看网卡的地址。注意这里默认是 *192.168.15.x* 网段，和网上常见的 *192.168.2.x* 网段不同。这个配置是可以在 *usbnet* 的 *config* 文件修改的。

接下来将树莓派和 kindle 用 USB 数据线连接，输入 *lsusb* 命令，，如果看到 *Linux-USB Ethernet/RNDIS Gadget* 这样的设备说明连接成功。

编辑 */etc/network/interfaces* 添加网卡配置:

```bash
$ sudo vi /etc/network/interfaces
# Kindle USBNet
allow-hotplug usb0
mapping hotplug
script grep
map usb0
iface usb0 inet static
address 192.168.15.1
netmask 255.255.255.0
broadcast 192.168.15.255
up iptables -I INPUT 1 -s 192.168.15.1 -j ACCEPT
```

重启树莓派，输入 *ifconfig usb0* 检查网卡是否连接成功，连接成功会显示一个 usb0 网卡设备。
这时你可以 *ping 192.168.15.244*，检查网络是否通畅。一切 ok 的话就就可以启动 Kterm 连接树莓派了。
打开 *Kterm*

```bash
$ ssh  pi@192.168.15.1 -t "tmux attach"
```
接着输入账户密码就可以登录了。

![同屏](https://s1.ax1x.com/2020/05/24/tSeEa6.png)

最后，如果你想要横屏，那么你就在打开 Kterm 之前，随便打开一本书，切换成横屏即可。切换回竖屏同理。

## 参考资料
[https://www.shuyz.com/posts/phicomm_n1_with_kindle_as_screen/](https://www.shuyz.com/posts/phicomm_n1_with_kindle_as_screen/)

[https://www.fabiszewski.net/kindle-terminal/](https://www.fabiszewski.net/kindle-terminal/)

[https://bookfere.com/post/512.html](https://www.fabiszewski.net/kindle-terminal/)

[http://blog.yarm.is/kindleberry-pi-zero-w.html](https://www.fabiszewski.net/kindle-terminal/)
