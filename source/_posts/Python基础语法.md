---
title: Python基础语法
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-01-08 15:45:49
---

Python，开源免费的面向对象的解释型计算机高级程序设计语言，简单易用，应用广泛，功能强大。Python是一门推崇极简主义的编程语言，具有很强的可读性及更有特色语法结构

# 发展历史

Python最初是由就职于荷兰国家数学和计算机科学研究所的荷兰人Guido van Rossum（吉多·范罗苏姆）于1989年底发明，并于1991年发行第一个公开发行版。其诞生极具戏曲性，据Guido自述记载，Python语言是在圣诞节期间为了打发无聊的时间而开发，之所以会选择Python作为名字，是因为Guido是Monty Python戏剧团的忠实粉丝

Python是在ABC语言的基础上发展而来，设计初衷是成为ABC语言的替代品。ABC语言虽然是一款功能强大的高级语言，但由于不开放的原因，导致并没有得到普及。基于此，Guido在开发Python之初就决定将其开源。Python中不仅添加了许多ABC语言没有的功能，还为其设计了各种丰富而强大的库，利用这些Python库，程序员可以把使用其它语言制作的各类模块（尤其是C语言和 C++）很轻松地“黏连”在一起，因此Python又被称为胶水语言。现在，Python由一个核心开发团队在维护，Guido van Rossum仍然占据着至关重要的作用，指导其进展

Python因其简单易用、优雅干净、学习成本低及标准库与第三方库众多的特点，自面世之日起即发展迅猛，大受欢迎：

- 2004年，Python使用率呈线性增长，不断受到编程者的欢迎和喜爱
- 2010年，Python荣膺TIOBE『2010 年度最佳编程语言』桂冠
- 2017年，IEEE Spectrum发布的『2017 年度编程语言』排行榜中，Python 位居第1位
- 2018年，Python斩获TIOBE『2018 年度最佳编程语言』第1名
- 2020年和2021年，Python连续两年摘得TIOBE『年度最佳编程语言』桂冠，且市场份额仍在持续提升。由于人工智能、大数据等行业的发展，使得Python近几年增姿迅猛，甚至超越了C、C++和Java，成为编程语言排行榜冠军

# 功能特点

## 1.语法简单

关键字相对较少，结构简单，代码清晰和一个明确定义的语法，阅读、学习、维护更加简单。

## 2.封装较好

Python封装较深，屏蔽了很多底层细节，如Python自动管理内存，即需要时自动分配，不需要时自动释放，优点是使用方便，无需顾虑细枝末节；缺点是令人浅尝辄止，知其然不知其所以然

## 3.跨平台

Python是解释型语言，跨平台性好，易于移植，即可通过不同的解释器将相同的源代码解释成不同平台下的机器码

## 4.模块众多

Python的模块众多，基本实现了所有的常见的功能，从简单的字符串处理，到复杂的3D图形绘制，都可快速完成。且社区发展良好，除了 Python官方提供的核心模块，很多第三方机构也会参与到模块的开发中，其中就有 Google（谷歌）、Facebook（脸书）、Microsoft（微软） 等巨头

## 5.面向对象

面向对象，即Object Oriented，是大多数现代高级语言（即第三代编程语言）都具备的特性，否则在开发中大型程序时会捉襟见肘。但不同于Java这种典型的面向对象的编程语言，强制必须以类和对象的形式来组织代码，Python虽然支持面向对象，但非强制性

## 7.扩展性强

如需运行一段很快的关键代码，或是编写一些不便开放的算法，可用C或C++完成，之后从Python程序中调用，可在一定程度上弥补了运行效率慢的缺点

## 8.互动模式

互动模式的支持，可从终端输入执行代码并获得结果的语言，互动的测试和调试代码片断

## 9.GUI编程

Python支持GUI可以创建和移植到许多系统调用

---------

Python是解释型语言，需预先编译，而是由解释器逐行对源码进行解释，一边解释一边执行，效率较低，速度远远慢于C/C++、Java。因此，计算机的一些底层功能或关键算法，一般都使用C/C++实现，只有在应用层面，如网站开发、批处理、小工具等适于解释型语言。此外，编译型语言的源代码被编译成可执行程序的过程就相当于对源码完成了加密，而Python由于没有编译过程，则对源码加密就将相当困难

相对的，编译型语言开发完成之后则只需通过专门的编译器即可一次性将所有的源代码都转换成特定平台下包含机器码的可执行程序,如Windows下的.exe文件，只要拥有可执行程序即可随时运行，不再需要重新编译，也即是一次编译，无限次运行

# 应用领域

Python应用广发，几乎所有大中型互联网公司都有应用，如国外的Google、Youtube、Dropbox，国内的百度、新浪、搜狐、腾讯、阿里、网易、淘宝、知乎、豆瓣、汽车之家、美团等等，应用领域极为广泛

## 1.Web应用开发

尽管PHP、JS目前依然是Web开发的主流语言，但随着Python的Web开发框架逐渐成熟，如Django、Flask、Tornado、Web2py等，开发、管理复杂的Web程序将变得更加轻松。全球最大的搜索引擎Google在其网络搜索系统中就广泛地使用了Python语言，全球最大的视频网站 Youtube、网络文件同步工具Dropbox以及豆瓣网也是基于Python的

## 2.网络爬虫

Python提供有很多服务于编写网络爬虫的工具，如urllib、Selenium 和 BeautifulSoup等，还提供了一个网络爬虫框架Scrapy，Google等搜索引擎公司大量地使用Python语言编写网络爬虫

## 3.游戏开发

很多游戏使用Python或Lua编写游戏的逻辑，使用C++编写图形显示等高性能模块，如Sid Meier's Civilization（文明）和 EVE（星战前夜）

## 3.自动化运维

所谓自动化运维，实际上就是利用一些开源的自动化工具来管理服务器，如业界流行的基于Python开发的Ansible，用于运维工程师解决重复性的工作。且Python编写的系统管理脚本，无论是可读性、性能以及代码重度和扩展性等方面，都要优于shell编写的脚本

## 4.人工智能

人工智能的核心是机器学习，机器学习的研究可分为传统机器学习和深度学习，两者被广泛的应用于图像识别、智能驾驶、智能推荐、自然语言处理等应用方向

目前世界上优秀的人工智能学习框架，如Google的TransorFlow（神经网络框架）、FaceBook的PyTorch（神经网络框架）以及开源社区的 Karas神经网络库等，都是基于Python实现的；微软的 CNTK（认知工具包）完全支持Python；Python擅长科学计算和数据分析，支持各种数学运算，可绘制出更高质量的2D和3D图像

## 5.科学计算

Python在数据分析、可视化方面有相当完善和优秀的库，如NumPy、SciPy、Matplotlib、pandas等，可满足科学计算程序的需求，NASA在1997年以来就大量使用Python进行各种复杂的科学运算

---------

Python编码规范为PEP 8，Python Enhancement Proposal，即Python增强建议书，8代表的是Python代码的样式指南

# 1.头部注释

头部注释，又称声明编码格式，被系统或解释器调用而不是服务于代码，主要作用是标示Python解释器的位置与脚本的编码格式，几乎在所有主流的编程语言脚本中都是必需元素

    # /bin/python3
    # codeing: utf-8

# 2.注释规范

注释，即是对代码的解释，大大提高了程序代码的可读性与程序调试的效率，程序执行时将会忽略掉注释

Python单行注释以#开头，多行注释以三个单引号'''或三个双引号"""将注释内容包含进来

    #!/usr/bin/python3
    # coding:utf-8

    """
        @Author:songsong
        @Date:2022/12/13
        @Filename:3.py
        @Host:cloud-server
    """

    print("一定要坚持下去")
    print("Python学习")
    print("------------")


    '''
        Python注释分为单行注释与多行注释两种，单行注释以#开头，
        多行注释有两种写法，即6个单引号或6个双引号
    '''

    # 多行注释并没有强制的规范，保持统一即可

    print("人生苦短，我用Python")

# 3.缩进规范

Python的代码块不使用{}控制类、函数以及逻辑判断，而是使用缩进，且缩进量可自定但所有代码块的缩进量必须保持一致，否则将报错。建议以TAB键或4个空格作为缩进


正确缩进

    #!/bin/python3
    # coding: utf8

    a = 2

    if a > 1:
        print("当前a的值大于1")
    else:
        print("当前a的值小于1")

错误缩进

    #!/bin/python3
    # coding: utf8

    a = 2

    if a > 1:
    # 错误缩进
    print("当前a的值大于1")
    else:
        print("当前a的值小于1")

# 4.空格规范

- 运算符两侧各一个空格，数量可自定，但两侧要保持一致
- 逗号、分号、冒号之前不要加空格其后可以加空格
- 函数参数列表中

# 5.空行规范

- 函数之间和类的方法之间用空行分隔，表示一段新的代码的开始
- 类和函数入口之间用一行空行分隔，以突出函数入口的开始
- 空行的作用在于分隔两段不同功能或含义的代码，便于日后代码的维护或重构

# 6.变量命名规范

变量，Python程序用来保存计算结果的存储单元，变量名即是