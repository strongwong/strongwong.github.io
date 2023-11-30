---
title: 使用 Hexo+Github Pages 搭建个人博客
tags:
  - blog
  - 教程
categories:
  - 学习
abbrlink: 3377
date: 2018-08-02 21:22:50
---

## 使用 Hexo+Github Pages 搭建个人博客记录

最近在学习的时候发现很多人都推荐说，要学会写作。很多大牛都会有自己的博客，或者微信公众号。不仅要学会学习，更要学会表达，而写作就是一个很好的方式。通过把自己学到的东西再次输出出来，才有价值，写作是一个人吸收知识，并增强记忆转化成自己东西的过程。很多人认为学校里出来了之后应该会很少写文字了，其实不然，在工作中经常会有各种各样的汇报和报告需要你去写。
如果你不经常去写一些文字，慢慢的也就生疏了，也就忘了该怎么通过书面方式更好的表达信息。比如我们领导让大家每周写一份周报，每到周五的时候大家总是在纠结，这周报该怎么写。还有做测试的时候要有测试方案，测试结果，测试报告（分析）都是要写文档的。跟文字打交道的时候还是很多的啊！所以啊，平时还得多写写！

<!-- more -->

我在看一些大牛的博客的时候，发现他们的博客，好像都很好看。我很羡慕，于是我也想搭建一个自己的个人博客，所以就有了本站！
我了解到建站的方法有很多，比如:

- Hexo + GitHub Pages
- Jekyll + GitHub Pages 
- WordPress + 服务器 + 域名
- DeDeCMS + 服务器 + 域名
- ......

我选择了使用 Hexo + GitHub Pages + 域名 的方法来建站。
首先 Hexo 简约风格我很喜欢，其次利用 GitHub Pages 的免费存储空间不需要自己购买服务器，
有一个 GitHub 账号就 ok 了，然后域名其实是一个可选项，GitHub 会提供一个 http://xxxx.github.io/ 这种形式的域名进行访问。

## 下面来简单记录一下，本站的搭建过程


安装 Hexo 很简单，但是在安装前需要配置一些环境，需要安装 Node.js 和 Git 。因为 Hexo 博客系统是基于 Node.js 写的，需要 Node.js 的环境才能运行。 Hexo 运行之后会在本地生成网页，所以我们需要使用 Git 把本地网页文件上传到 GitHub 上的远程仓库里。（当然使用 GitHub 桌面版也可以上传。）

## 安装 Node.js
在 Node.js 官网：https://nodejs.org/en/ 下载最新的稳定版，安装时保持默认设置，一路 next 就好，等待安装完成。
安装好之后，按`Win+R`,输入 `cmd`，运行命令提示符，输入` node -v `和 `nmp -v`，如果出现版本号，那么就安装成功了。
![node -v npm -v](https://photo.ishield.cn/pic/5b8ca1e59dc6d611b60ee2bd)

## 安装 Git
去 Git 官网：https://git-scm.com/ 下载最新的稳定版的 git 安装包，直接默认配置安装就好了，一路 next 就好。
![git](https://photo.ishield.cn/pic/5b8ca4519dc6d611b60ee2d1)
安装完成后，在桌面右键，点击`Git Bush Here`，输入 `git --version`，如果成功出现 Git 的版本号，到这里 Git 的环境配置就完成了！（如果你对 Git 不太熟悉，不太会用 Git 来上传你的博客，你也可以考虑使用 GitHub 的桌面版。）
![](https://ww3.sinaimg.cn/large/005YhI8igy1fuw5x63irrj30630a0gln)

## 注册 GitHub 和配置
身为一个程序员，怎么能不知道 GitHub！每个程序员都应该有一个 GitHub 账号！GitHub是一个大型的代码托管平台，上面有很多技术大牛，也有很多有趣的开源项目，像Google、FaceBook、Macrosoft 等大公司也都在使用 GitHub。我们的博客就是托管在 GitHub 上的。

GitHub Pages 是面向用户、组织和项目开放的公共静态页面搭建托管服务，站点可以被免费托管在 Github 上，你可以选择使用 Github Pages 默认提供的域名 github.io 或者使用自定义域名来发布站点。

如果你还没有 Github 账号的话，需要先到 GitHub 官网进行注册： https://github.com/ 

注册完成之后，我们需要创建一个仓库来存放我们的博客。新建一个项目，如下图所示：
![](https://photo.ishield.cn/pic/5b8ca25b9dc6d611b60ee2c3)
仓库名称一般使用用户名加 `.github.io`后缀，如下图所示：
![](https://photo.ishield.cn/pic/5b8ca2889dc6d611b60ee2c5)
最后，创建完成后，就可以直接访问 https://yourname.github.io/ ,如果可以正常访问，那么 GitHub 的配置就搞完了。
到这里环境就基本上搭好了，下面就开始安装 Hexo 正式搭建个人博客。

## 安装Hexo
Hexo 是什么？
Hexo 是一个快速、简洁且高效的博客框架。Hexo 使用 Markdown (或者其他渲染引擎)解析文章，在几秒内，即可利用靓丽的主题生成静态网页。并且一条指令即可部署到 GitHub Pages 或者其他网站。想更多了解 Hexo 请阅读 Hexo 官方文档: https://hexo.io/zh-cn/

首先，在你的电脑里，新建一个文件夹专门用来存放你的博客文件。比如我的都放在 D:\study\hexo 目录下。

然后在该目录下，右键点击 ` Git Bush Here `，打开 Git 控制台窗口，接下来的操作都在 Git 控制台进行，反正我是挺喜欢敲命令行的感觉。

接下来，在该目录下，输入 `npm install -g hexo-cli `，安装 Hexo ，这里会有一个 ` WARN `，不用担心这不会影响正常使用。然后在安装 Hexo 部署到 Github Pages 的 deployer。
```bash
$ npm install -g hexo-cli 
$ npm install hexo-deployer-git --save
```

![](https://photo.ishield.cn/pic/5b8ca2ae9dc6d611b60ee2c6)

查看 Hexo 的版本，输入 `hexo -v`，正确输入如下信息就表示 Hexo 安装成功了。
![](https://ww3.sinaimg.cn/large/005YhI8igy1fuw600gjbcj30gz0de74s)

## Hexo基础配置
Hexo 安装完成后，执行下面的命令来初始化 Hexo ，对应的用户名(文件夹名称)改成自己的。Hexo 会在指定的文件夹中新建博客系统，和安装必备组件。

```bash
$ hexo init strongwong.github.io
$ cd strongwong.github.io
$ npm install
```
![](https://photo.ishield.cn/pic/5b8ca2f39dc6d611b60ee2c8)

新建完成后，在本地运行 Hexo 查看效果:

```bash
$ hexo generate	#或者运行 hexo g 根据配置生成博客
$ hexo server	#或者运行 hexo s 在本地运行 Hexo 登录 localhost:4000 查看
			#按 ctrl + c 即可关闭本地服务器
```

这时我们到浏览器中输入 `localhost:4000` 就可以在本地端正常访问了(如下图)，这样的话就说明博客已经打起来了，但是现在只是在本地，别人还不能访问，接下来我们就要把本地博客部署到 GitHub 上，让别人也可以看到你的博客。
![](https://photo.ishield.cn/pic/5b8ca3139dc6d611b60ee2cc)

## 本地 Hexo 仓库与 GitHub 关联
配置 GitHub 的 SSH 密钥，让本地项目通过 git 命令与远程 GitHub 仓库建立联系，我们在本地做了修改之后直接通过 git 命令就可以把博客同步到 GitHub 上。

1.首先，在 git 控制台中，输入如下命令，配置个人参数(你的名字，你的邮箱)。
```bash
$ git config --global user.name "yourname"
$ git config --global user.email "your_email@example.com"
```

2.接下来生成 SSH key 根据提示进行操作(其实一路回车就好了。)
```bash
$ ssh-keygen -t rsa -C "your_email@example.com"
```

3.执行完之后就会在默认路径下生成 `id_rsa.pub`文件。默认路径是：`C:\Users\Administrator\.ssh\id_rsa.pub` 需要注意的是 .ssh 是隐藏文件夹。
使用记事本打开这个文件，复制文件内容，然后粘贴到 https://github.com/settings/ssh/ 的 "new SSH key" 中。

4.输入下面的命令，查看 SSH 是否配置成功。
```bash
$ ssh -T git@github.com
```
如果是下面的反馈
```
The authenticity of host 'github.com (207.97.227.239)' can't be established.
RSA key fingerprint is 16:27:ac:a5:76:28:2d:36:63:1b:56:4d:eb:df:a6:48.
Are you sure you want to continue connecting (yes/no)?
```
直接输入 yes 就好了，然后就会看到：
```
Hi strongwong! You've successfully authenticated, but GitHub does not provide shell access.
```
这样的话，我们 SSH key 就配置成功了。

5.配置 deploy 参数
在博客根目录下，找到 `__config.yml` 文件，找到 deploy 关键字，进行如下配置。
```$
deploy: 
  type: git
  repo: git@github.com:strongwong/strongwong.github.io.git
  branch: master
```

6.将本地博客提交到 GitHub Pages
```bash
$ hexo g			#根据你的改动生成新的静态文件(即 public 文件夹)
$ hexo s			#启动本地预览 ctrl + c 关闭
$ hexo d			#部署到远程站点
$ hexo clean		#清除旧的静态文件(即 public 文件夹)
```

7.这时在浏览器输入 https://strongwong.github.io/ ，可以正常访问就说明 hexo 搭建的博客已经成功部署到 GitHub 了，小伙伴们都可以通过这个地址访问自己的博客了。

## 将个人域名解析到 GitHub
看着这个 GitHub 下面的二级域名，总觉得让人不太爽，所以有很多小伙伴都买了自己的域名，然后将自己域名绑定到 GitHub Pages 的博客上。
于是我也就到阿里云上购买了一个万网域名，也不是很贵。
进入阿里云网站，打开阿里云域名控制台，点击管理，然后点击域名解析。
![](https://photo.ishield.cn/pic/5b8ca34f9dc6d611b60ee2cf)
![](https://photo.ishield.cn/pic/5b8ca3669dc6d611b60ee2d0)

在下图中点击添加记录，添加解析：
> 记录类型选择`CNAME`
> 主机记录填 `www`
> 解析线路选择 `默认`
> 记录值填 `yourname.github.io`
> TTL 值为 `10` 分钟
> 再添加一个解析，记录类型 `A`
> 主机记录填 `@`
> 解析线路选择 `默认`
> 记录值填你 GitHub 的 IP 地址 (在 cmd 中 ping：`ping yourname.github.io`)
![](https://ww3.sinaimg.cn/large/005YhI8igy1fuw67ojfrmj31ba05pgm6)

在本地博客的 source 目录下新建一个 CNAME 文件(没有扩展名)，用记事本打开填入购买的域名地址:
```
www.strongwong.top
```
将博客重新发布一次：
```bash
$ hexo g -d	#generate 和 deploy 的组合命令
```
此时，在浏览器中输入你的个人域名([www.strongwong.top](https://www.strongwong.top/))，如果正常访问你的博客就说明，域名绑定成功，域名解析成功啦！！在这伟大的互联网时代，终于拥有了自己的网站啦！

### 发表一篇文章
运行下面的命令，就会创建一个文章文件，在本地博客的 source\_posts 文件夹下就会有一个新建的 markdown 文件。
```bash
$ hexo new "文章标题"   # hexo n "文章标题" 这种简写也可以
```
文章编辑好之后，推送到 GitHub 上我们在站点上就可以看到新的文章了。
```bash
$ hexo g  #生成 
$ hexo d  #部署
```

## 安装 Next 主题及个性化
Hexo 有非常多的主题可以选择，可以到官方主题库进行选择： https://hexo.io/themes/
我这里选择了资料相对详细、丰富的 Next 主题，前往 Next 主题发布页面下载：https://github.com/iisnan/hexo-theme-next/releases/ 
下载最新版本的 Next 主题包，解压缩，将文件名称改为 next，放置到博客根目录的 themes 目录下。
打开站点配置文件 `_config.yml`，找到 themes 字段，修改为 next。
到此，next 主题安装完成。

关于 next 主题的一些配置请查阅 next 主题官方文档：https://theme-next.iissnan.com/

## 结束语
花了两天时间把博客搭起来，还是挺开心的。博客使用 Hexo 搭建，主题使用 Next，评论系统使用 Valine ，文章浏览统计使用 LeanCloud ，网站访客数量使用不蒜子，另外还使用了 Google 统计，方便自己查看数据。
我会坚持在工作之余，写点技术分享，记录一下我的学习历程。我也不知道我会分享哪些东西，但是我想可能还是嵌入式软件方面可能会比较多一些吧，其他方面也可能会分享一些学习、工作、生活中的经历和经验吧！祝我未来，越来越好！


strongwong

2018.8.2


