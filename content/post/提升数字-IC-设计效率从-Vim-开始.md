---
title: 提升数字 IC 设计效率从 Vim 开始
tags:
  - Vim
  - IC Design
categories:
  - IC Design
  - 其他
abbrlink: 23797
date: 2018-11-12 16:10:29
---

## Vim

这篇文章主要分享给在 Windows 下进行数字 IC 开发的盆友们，如果早已 linux，请大神自行忽略，另外建议在 Windows 下的盆友早日脚踏两只船。
相信大家都有过为了追一个信号而不断地缩放 RTL 图的经历，有没有一种办法能一键式一条龙服务呢？有！用 Vim！

Vim，一种类似于 notepad 的文本编辑器，其拥有你喜欢的一切功能（护眼模式，关键词高亮 …… 废话没有这些还叫代码文本编辑器），其针对 Verilog 的项目维护是真的善良，黑暗中的阳光。

<!-- more -->

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/top_vim.jpg)

但这阳光大多数情况下照亮于 Linux 或者 Unix 系统下，那我们试试怎么让光照进 Windows。
![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/cmd_vim.jpg)

## 安装 Cygwin

> Cygwin 是一个在 Windows 平台上运行的 Unix 模拟环境，是 Cygnus solutions 公司开发的自由软件（该公司开发了很多好东西，著名的还有 eCos，不过现已被 Redhat 收购）。它对于学习 Unix/Linux 操作环境，或者从 Unix 到 Windows 的应用程序移植，或者进行某些特殊的开发工作，尤其是使用 gnu 工具集在 Windows 上进行嵌入式系统开发，非常有用。随着嵌入式系统开发在国内日渐流行，越来越多的开发者对 Cygwin 产生了兴趣。

下载好 Cygwin 后选择好安装路径，然后选择镜像网址，建议选择国内的镜像地址速度会快一些。可以使用网易的镜像地址：`http://mirrors.163.com` ,在 URL 栏自行输入镜像地址点击 `add` 添加后使用。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/cygwin_setup.jpg)

然后就进入选择安装包，初次进入建议都选择，高手可以有需要的时候可以再进来这个安装页面选择安装。
安装完成之后，把 Cygwin 添加到右键菜单，打开便是当前的路径下，这才是 Windows 该有的体验不是吗？而完成这一切只需简单地修改一下注册表。（以下步骤参考网络资源）：
> - 使用`Win + R`打开运行窗口, 输入 regedit, 回车, 启动注册表编辑程序，找到 HKEY_CLASSES_ROOT\Directory\Background\shell 表项;
> - 右键点击`shell`，选择`新建`->`项`，命名为`Cygwin`，或者其他，你右键时看到的就是`Cygwin`,或者是你自定义的名称;
> - 右键点击刚才创建的`Cygwin`，选择`新建`->`项`,命名为`command`，表示点击该菜单项时要执行的命令;
> - 双击`command`下`(默认)`数据项，在`数值数据(V)`下输入如下内容：
`"D:\Coding\Cygwin\bin\mintty.exe"-i/Cygwin-Terminal.ico /bin/env _T=%V /bin/bash -l"`
（你的 Cygwin 安装路径）

这样就可以直接在对应的文件夹通过右击菜单打开命令行窗口。
Cygwin 配置好后，接下来我们继续配置一下 Vim 。

## Vim 配置
1. 让`bash`命令行支持中文输入，打开 Cygwin 终端，在终端中输入如下命令 `vim ~/.inputrc`，打开inputrc 文件，将下面几行的注释去掉（去掉#），保存并退出。
```bash
set meta-flag on
set convert-meta off
set input-meta on
set output-meta on
```

2. 让 `ls` 命令支持中文显示，在终端中输入命令 `vim ~/.bashrc` ，打开 `bashrc` 文件修改：
```bash
alias ls='ls -hF –-show-control-chars –-color=tty'
```

3. 配置一个个人喜好的 Vim，打开 Cygwin 终端，输入`vim ~/.vimrc`，编辑如下设置
```vim
set fenc=utf-8 "设定默认解码 
set fencs=utf-8,usc-bom,gb18030,gbk,gb2312,cp936,euc-jp
set nocp "或者 set nocompatible 用于关闭 VI 的兼容模式 
set number "显示行号 
set ai "或者 set autoindent vim 使用自动对齐，也就是把当前行的对齐格式应用到下一行 
set si "或者 set smartindent 依据上面的对齐格式，智能的选择对齐方式
set tabstop=4 "设置 tab 键为4个空格
set sw=4 "或者 set shiftwidth 设置当行之间交错时使用4个空格
set ruler "设置在编辑过程中,于右下角显示光标位置的状态行 
set incsearch "设置增量搜索,这样的查询比较smart 
set showmatch "高亮显示匹配的括号 
set matchtime=5 "匹配括号高亮时间(单位为 1/10 s) 
set ignorecase "在搜索的时候忽略大小写 
syntax on "高亮语法
```

成功后界面如下图所示

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/vim_v.jpg)

## 使用 Vim 提升开发效率

首先，你需要进入项目工程的顶层目录，假设你整个项目最顶层的目录名叫 Vimtest，那么你就先进入这个目录，然后调用 ctags 工具生成整个工程目录的标签列表。

```bash
$ cd Vimtest  # youproject name
$ ctags -R *
```

顺利的话，你将会看到在 Vimtest 下新创建了一个叫 tags 的文件，在这个文件里将会以“`定义名称 文件位置：行数`”的格式将你所有项目中的模块，信号，参数定义全部列出，而此处参数`-R`的含义是递归执行，也就是从顶层目录向下自动遍历全部子目录进行文件检索和定义收录。在默认配置下，ctags 可以自动识别`.v`和`.vhdl`后缀文件的语法，如果你同时希望收录测试平台中的`.sv`文件的话，可能你需要额外增加一个 System Verilog 的语法说明文件。
有了这个标签列表之后应该如何使用呢？总不能每次都打开这个 tags 文件然后挨个查询吧？当然不是，接下来我们需要把这个 tags 文件和 Vim 结合起来。首先我们需要再次打开`.vimrc` 文件
打开 cygwin 终端，输入 `vim ~/.vimrc`， 打开文件后输入一下内容:

```vim
set tags=tags;
set autochdir
nnoremap t :tag
```

第一行命令的含义是指定标签列表名称为 tags，命令最末的`;`号不可省略，其含义是告知 Vim 首先在当前目录下寻找 tags 文件，如果找不到则自动向更上一级目录查找，现在你明白为什么我们一开始要把 tags 文件生成在项目的顶层目录了吧。第二行命令不是必须的，其含义是每次打开新的文件时，自动将终端切换到该文件的所在目录下。

下面就是见证奇迹的时刻了。你可以进入项目目录下的任何一个子目录，然后 vim top.v（我的工程顶层文件名，你可以叫别的名字）。如果你的`vimrc`配置跟我上文写的一模一样，那么你就按一下`t`，如果你的`vimrc`里没有`nnoremap t:tag`这一句的话，请手工输入`:tag `（此处有空格）。然后接着输入任何项目中存在的模块名称，信号名称或者参数名称。比如项目中有一个模块名叫`uart`，那么完整的命令应该是`:tag uart`。注意，如果你并不记得模块的完整名称也没关系，随时按下 tab 键都可以自动补全，即使你连开头都不记得了，还可以用`/keyword`的办法进行搜索。输入完毕后按下回车，如果 Vim 在标签列表中只找到唯一匹配定义的话，就会立刻跳转到对应文件的对应行；如果找到的匹配结果不止一个，就会把所有结果列出来让你用数字序号选择跳转目标。

![](https://mytu-1252671182.cos.ap-shanghai.myqcloud.com/hexo/vim_tag.jpg)

很多老手看到这里可能觉得不够过瘾，就只是这样而已，我也早就会了，只不过嫌太麻烦而已，还不是要不停输入模块名称吗，能快到哪里去？呵呵，最会偷懒的我怎么可能只是做到这样的程度而已呢？
大家觉得，平时在修改代码设计的时候，最需要进行频繁文件跳转的是什么时候？是不是当你找到了一个关键的寄存器，想顺着信号的传播路径一直跟踪下去的时候？当你跟着这个信号来到一个模块例化面前，是不是恨不能立刻跟着信号钻进这个模块的代码里去？其实，这非常简单。

根据我们前面的介绍，你肯定已经想到了，可以通过`:tag module_name`跳转到这个模块的设计文件，但是这样太麻烦了，万一模块名字老长还带有大小写，写一遍就得费老半天功夫。有一个相对简单的办法，把光标移动到模块名称上，按下`ctrl+]`，你会发现自己立刻飞到了该模块的设计文件中！但是！！等等！！我刚才要跟踪的信号是什么名字来着？忘记了对不对？这个方法还是不够方便。
有没有更简单的办法？这个办法最好能从我们决定要进入这个模块的那一刻起，只用一个按键操作就能立刻进入这个模块的设计文件，同时光标最好还能直接定位到我们要追踪的信号位置，这个信号的名字最好还能被高亮显示！当！然！没！问！题！

在 vimrc 文件中加入

```vim
nnoremap []
```

重新打开任何 Vim 文件，假装自己跟踪到了某个模块例化的某个信号上，类似`.clk`，通常你跟踪到这里的时候，光标应该是放在 clk上面，这时你在键盘上快速按下`[`和`]`这两个键，发生了什么？？！！！我是谁？？！我在哪里？！！！恭喜你！成功进入了该模块！！！并且光标飞到了之前 clk 所连接的 module 上！！好了我们可以和过去为了追信号而需要不断 zoom in zoom out 的 RTL 图说再见了~

**By Ricky**

参考源:
[https://www.jianshu.com/p/fac45920628d](https://www.jianshu.com/p/fac45920628d)
[https://blog.csdn.net/samxx8/article/details/38777189](https://blog.csdn.net/samxx8/article/details/38777189)
[https://blog.csdn.net/hao508506/article/details/52440220](https://blog.csdn.net/hao508506/article/details/52440220)
[http://kellen.wang/zh/useful-skills-of-vim-while-coding-verilog/](http://kellen.wang/zh/useful-skills-of-vim-while-coding-verilog/)
