---
title: 使用 Docker + GitLab 构建自用的代码管理服务
tags:
  - Docker
  - GitLab
  - frp
categories:
  - 学习
abbrlink: 28215
date: 2018-11-13 15:16:45
---

## 准备工作
### 系统要求
- 一台 Ubuntu 系统的电脑作为服务器（我这里是一台 Ubuntu Xenial 16.04 的电脑），其他版本和系统也可以，只要 Docker CE 支持即可，详情请访问 [Docker 官网](https://www.docker.com)。
- GitLab CE 要求内存 2G 以上

## Docker 安装及配置
### Docker 是什么
Docker 使用 Google 公司推出的 Go 语言进行开发实现，基于 Linux 内核的 cgroup，namespace，以及 AUFS 类的 Union FS 等技术，对进程进行封装隔离，属于 [操作系统层面的虚拟化技术](https://en.wikipedia.org/wiki/Operating-system-level_virtualization)。由于隔离的进程独立于宿主和其它的隔离的进程，因此也称其为容器。

<!-- more  -->

Docker 在容器的基础上，进行了进一步的封装，从文件系统、网络互联到进程隔离等等，极大的简化了容器的创建和维护。使得 Docker 技术比虚拟机技术更为轻便、快捷。

传统虚拟机技术是虚拟出一套硬件后，在其上运行一个完整操作系统，在该系统上再运行所需应用进程；而容器内的应用进程直接运行于宿主的内核，容器内没有自己的内核，而且也没有进行硬件虚拟。因此容器要比传统虚拟机更为轻便。

它是目前最流行的 Linux 容器解决方案！

### 卸载旧版本
旧版本的 Docker 称为 `docker` 或者 `docker-engine`，使用以下命令卸载旧版本：
```bash
$ sudo apt-get remove docker \
               docker-engine \
               docker.io
```

### 使用 APT 安装
由于 `apt` 源使用 HTTPS 以确保软件下载过程中不被篡改。因此，我们首先需要添加使用 HTTPS 传输的软件包以及 CA 证书。

```bash
$ sudo apt-get update
$ sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
```

鉴于国内网络的问题，建议使用国内源，官方源在注释中查看。
为了确认所下载软件包的合法性，需要添加软件源的 `GPG` 密钥。
```bash
$ curl -fsSL https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu/gpg | sudo apt-key add -


# 官方源
# $ curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
```

然后，向 `source.list` 中添加 Docker 软件源

```bash
$ sudo add-apt-repository \
    "deb [arch=amd64] https://mirrors.ustc.edu.cn/docker-ce/linux/ubuntu \
    $(lsb_release -cs) \
    stable"


# 官方源
# $ sudo add-apt-repository \
#    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
#    $(lsb_release -cs) \
#    stable"
```

### 安装 Docker CE
更新 apt 软件包缓存，并安装 `docker-ce`：
```bash
$ sudo apt-get update

$ sudo apt-get install docker-ce
```

### 启动 Docker CE
```bash
$ sudo systemctl enable docker

$ sudo systemctl start docker
```

### 建立 Docker 用户组
默认情况下，`docker` 命令会使用 Unix socket 与 Docker 引擎通讯。而只有 `root` 用户和 `docker` 组的用户才可以访问 Docker 引擎的 Unix socket。出于安全考虑，一般 Linux 系统上不会直接使用 `root` 用户。因此，更好地做法是将需要使用 `docker` 的用户加入 `docker` 用户组。

建立 `docker` 用户组：
```bash
$ sudo groupadd docker      #新建 docker 用户组

$ sudo usermod -aG docker $USER     #将当前用户加入 docker 组
```

退出当前终端并重新登录，进行如下测试。

### 测试 Docker 是否正确安装
```bash
$ docker run hello-world

Unable to find image 'hello-world:latest' locally
latest: Pulling from library/hello-world
d1725b59e92d: Pull complete
Digest: sha256:0add3ace90ecb4adbf7777e9aacf18357296e799f81cabc9fde470971e499788
Status: Downloaded newer image for hello-world:latest

Hello from Docker!
This message shows that your installation appears to be working correctly.

To generate this message, Docker took the following steps:
 1. The Docker client contacted the Docker daemon.
 2. The Docker daemon pulled the "hello-world" image from the Docker Hub.
    (amd64)
 3. The Docker daemon created a new container from that image which runs the
    executable that produces the output you are currently reading.
 4. The Docker daemon streamed that output to the Docker client, which sent it
    to your terminal.

To try something more ambitious, you can run an Ubuntu container with:
 $ docker run -it ubuntu bash

Share images, automate workflows, and more with a free Docker ID:
 https://hub.docker.com/

For more examples and ideas, visit:
 https://docs.docker.com/get-started/
```
若能正常输出以上信息，则说明安装成功。

### 配置镜像加速
因为国内网络的原因，后续拉取 Docker 镜像会十分缓慢，建议安装好 Docker 后配置一下国内镜像加速。
Ubuntu 16.04 的配置方法如下（参考：[Docker 中国](https://www.docker-cn.com)）：
修改 `/etc/docker/daemon.json` 文件并写入如下内容（如果文件不存在请新建该文件）：
```json
{
    "registry-mirrors": [
      "https://registry.docker-cn.com"
    ]
}
```
> 注意，一定要保证该文件符合 json 规范，否则 Docker 将不能启动。

之后重新启动服务
```bash
$ sudo systemctl daemon-reload

$ sudo systemctl restart docker
```
到此为止，Docker 就配置好了，接下来安装 GitLab CE 就十分简单了。

## GitLab 安装及配置
### GitLab 是什么
GitLab 是一个类似与 GitHub 的开源源码托管服务，它提供了一个基于 Git 的全功能软件开发平台，可以通过 Web 界面访问公有或私有的项目，还具备很多与软件开发协作相关的其他功能。利用 GitLab 提供的这些功能，可以实践一些项目管理和协作流程。这套流程借鉴于很多成功的开源项目，非常适合在小型团队里使用。

### 拉取 GitLab 镜像
安装最新版 GitLab 镜像
```bash
sudo docker pull gitlab/gitlab-ce:latest
```

### 启动 GitLab
使用 Docker 命令运行容器，命令如下：
```bash
sudo docker run -d \
    --hostname gitlab.asicfans.com \
    -p 8443:443 -p 8080:80 -p 2222:22 \
    --name gitlab \
    --restart always \
    -v /srv/gitlab/config:/etc/gitlab \
    -v /srv/gitlab/logs:/var/log/gitlab \
    -v /srv/gitlab/data:/var/opt/gitlab \
    gitlab/gitlab-ce:latest
```
> 注意修改 hostname 为自己的域名或者 ip 地址。
> `-v` 命令表示将原有的挂载目录重新映射到自己的目录，这三个参数将 GitLab 的配置、数据和日志持久化到文件系统上，这样就可以保证后面升级 GitLab 时数据不会丢失。
> `-p` 命令表示将原有的端口映射一下，避免常用端口被占用。我这里使用的都是安全端口。如果大家的环境没有限制或不冲突可以使用与容器同端口，如：-p 443:443 -p 80:80 -p 22:22
> 上面的命令太长，也可以写成 shell 脚本
```bash
$ cat <<EOF > start.sh
#!/bin/bash
HOST_NAME=gitlab.asicfans.com
docker stop gitlab
docker rm gitlab
sudo docker run -d \\
    --hostname \${HOST_NAME} \\
    -p 8443:443 -p 8080:80 -p 2222:22 \\
    --name gitlab \\
    --restart always \\
    -v /srv/gitlab/config:/etc/gitlab \\
    -v /srv/gitlab/logs:/var/log/gitlab \\
    -v /srv/gitlab/data:/var/opt/gitlab \\
    gitlab/gitlab-ce:latest
EOF
```
> 脚本编辑好之后运行脚本就可以了，就再也不用输入这么长的命令了！
```bash
 $ sh start.sh
```

### 配置环境
修改 /etc/hosts 文件，使在本地端可以使用域名访问
```bash
127.0.0.1 gitlab.asicfans.com
```
这样就可以使用 `http://gitlab.asicfans.com:8080` 域名在本地从浏览器访问 GitLab 了（GitLab 初次启动会比较慢，等待大约一分钟）。

### 试用 GitLab
首先根据提示输入管理员密码，这个密码是管理员用户的密码。对应的用户名是 root，用于以管理员身份登录 GitLab。

![](https://img.mukewang.com/5a73280a0001efc904500304.png)

设置好密码后去注册一个普通账号

![](https://img.mukewang.com/5a7327360001cdff03400477.png)

注册成功后会跳到首页，这样就可以创建一个项目了

![](https://img.mukewang.com/5a7327620001bc7f05460400.png)

项目建好了，我们加一个 ssh key，以后本地 pull/push 就简单啦!

![](https://img.mukewang.com/5a73277b0001982f07080200.png)

首先去到添加 ssh key 的页面

![](https://img.mukewang.com/5a73278e0001303620200994.png)

然后拿到我们的 ssh key 贴到框框里就行了
获取 ssh key：
```bash
# 先看看是不是已经有了，如果有内容就直接 copy 贴过去就行啦
$ cat ~/.ssh/id_rsa.pub

# 如果上一步没有这个文件 我们就创建一个，运行下面命令（邮箱改成自己的），一路回车就好了
$ ssh-keygen -t rsa -C "youremail@example.com"
$ cat ~/.ssh/id_rsa.pub
```

点开我们刚创建的项目，复制项目 ssh 的地址。
添加个文件，测试一下（我的项目叫 test）
```bash
$ git clone ssh://git@gitlab.asicfans.com:2222/wangqq/test.git

$ cd test && echo test > README.md  # 添加文件

#push 上去
$ git add .
$ git commit -m "test"
$ git push origin master
```

这样我们就可以在 GitLab 上看到我们刚才提交的结果了。到这 GitLab 的本地端使用就已经没问题了，但是要想不在家，或者在其他地方也可以访问，那我们就需要进行一下，内网穿透！

## frp 配置
配置 frp 你需要有一个有公网 ip 的云服务器和自己的域名，然后在云服务器和本地端分别下载安装 frp 并进行配置。

下载与系统对应的 frp 文件，frp 支持多种系统架构，详情请访问 [**frp**](https://github.com/fatedier/frp/) 查看

```bash
$ uname -a      # 首先使用 uname 命令查看一下你的系统

# 我这里是 Ubuntu x86_x64 所以下载 Linux_amd64 的软件包
$ wget https://github.com/fatedier/frp/releases/download/v0.21.0/frp_0.21.0_linux_amd64.tar.gz

# 解压安装包
$ tar -zxvf frp_0.21.0_linux_amd64.tar.gz

$ cd frp_0.21.0_linux_amd64

```

然后分别配置服务器端的 `frps.ini` 文件和本地端的 `frpc.ini` 文件。

- 1.修改 frps.ini 文件
```bash
# frps.ini
[common]    
bind_port = 7000        # 穿透使用的端口
vhost_http_post = 80    # 从外网访问的端口
subdomain_host = asicfans.com   # 主域名
token = xxxx            # 服务器与本地的校验信息，校验信息错误无法穿透，自行设置
```
- 2.启动 frps
```bash
$ ./frps -c ./frps.ini
```
- 3.修改 frpc.ini 文件
```bash
# frpc.ini
[common]
server_addr = x.x.x.x   # 你的服务器 ip 地址
server_port = 7000      # 开放的穿透端口
token = xxxx            # 需要与服务器端一致

[gitlab]
type = http
local_port = 8080
subdomain = gitlab
```
- 4.启动 frpc
```bash
$ ./frpc -c ./frpc.ini
```

- 5.将 gitlab.asicfans.com 的域名 A 记录解析到 ip `x.x.x.x`， 如果服务器已经有了对应的域名，也可以将 CNAME 记录解析到服务器原先的域名。
- 6.通过浏览器访问 http://gitlab.asicfans.com 即可访问到处于内网的 gitlab 服务了。
这样就不用使用 ssh key 的方式 clone/pull/push 代码仓库了，就可以直接使用 http 的方式进行操作了！ 十分方便！

自此，我们就可以让自己和小伙伴们一起愉快的在 GitLab 上玩耍啦！！
