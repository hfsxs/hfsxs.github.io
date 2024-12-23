---
title: Python模块与包
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-02-27 12:50:23
---

Python为提高代码的维护性与复用性，引入了模块与包的概念，即通过模块将相关的代码拆分到不同的代码文件以提高代码的可维护性与逻辑性，通过包目录化的组织模块以提高代码的可维护性与层次感，通过互相调用以提高代码的复用性。Python这种内置电池的哲学思维，使得代码的编写不必要从零开始，直接导入模块或包即可完成调用，大大编程的繁复性，降低了学习门槛，促成了Python的广泛应用

# 模块

模块，Module，是一组包含Python定义和语句的文件，后缀名为.py，可被相互调用以实现其功能。模块分为内置模块、自定义模块和第三方模块：自定义模块即为自己编写的模块，可以通过申请成为Python内置的标准模块，发布到网络供他人使用即为第三方模块。

# 包

包，Package，模块的集合，是Python用于按目录分层次组织模块的方法，定义了由模块及子包，以及子包下的子包所组成的Python应用环境，是比模块又高一级的封装，采用“包名.子包名.....模块名”的调用形式，解决了模块重名的问题。包类似于文件系统的文件目录，其文件夹下必须存在__init__.py文件, 用于标识当前文件夹是一个Python包，内容可为空

---------

# 1.创建模块

创建模块，即为编写自定义模块，实际上就是编写一个后缀名为.py的Pyhton脚本，模块名应符合标识符命名规范


    vi power.py


    #!/usr/bin/python3

    # -*- coding: utf-8 -*-

    def pow(a,b):
        return a ** b

# 2.导入模块

导入模块，即是将模块代码加载到内存以供调用，使用import关键，调用模块所定义函数的方式为：模块名.函数名

## 2.1 导入自定义模块

    >>> import power
    >>> power.pow(2,3)
    8

## 2.2 导入内置模块

    >>> import math
    >>> math.pow(2,3)
    8.0

## 2.3 导入第三方模块

Python第三方模块存储于网络上，所以要使用第三方模块首先要将其下载到本地，然后才能进行导入、调用

### 2.3.1 导入国内python镜像源

    vi ~/.pip/pip.conf
    
    
    [global]
    index-url = http://mirrors.aliyun.com/pypi/simple/
    [install]
    trusted-host=mirrors.aliyun.com

### 2.3.2 安装第三方模块

    sudo pip install requests

## 2.4 导入部分模块

Python语言from关键字用于从某个对象导入指定的部分到当前命名空间，而不会将整个对象导入，但需注意名字冲突

    # 导入datetime库的date与datetime类
    >>> from datetime import date,datetime
    # 导入datetime库的date类，并重命名为cdate，注意名字冲突
    >>> from datetime import date as cdate

    >>> date.today()
    datetime.date(2024, 1, 25)
    >>> now = date.today()
    >>> print(now)
    2024-01-25

    >>> from datetime import date as cdate
    >>> now = cdate.today()
    >>> print(now)
    2024-01-25

# 3.搜索路径

Python语言import关键字用于导入的模块，一个模块只会被导入一次，不会重复导入，以节省资源。Python解释器根据内置函数sys.path的设置Python环境变量PYTHONPATH按顺序搜索模块文件，若找不到模块文件则会报错，默认的搜索顺一般为：当前执行脚本目录（自定义） --->> Python安装目录（内置） --->> Python安装目录site-packages目录（第三方）。也可自定义Python环境变量：

    set PYTHONPATH=/usr/local/lib/python

# 4.模块内置函数

## 4.1 dir()

dir() 函数，返回值为排好序的字符串列表，其内容是模块里定义过的名字，包括模块、变量和函数

    >>> import a
    >>> import math
    >>> dir(a)
    >>> dir()

## 4.2 reload()

reload() 函数，用于重新执行模块顶层部分的代码，也即重新导入之前导入过的模块，语法为：reload(module_name)

    >>> reload(a)

# 5.包

包，package，由若干Python模块或子包构成的层级目录结构，功能完备的包或模块的集合也称为库。包实质上是Python语言管理与组织模块和库的手段，是Python库的组织形式与表现形式，以便增强模块调用的层次感与逻辑性。事实上，Python语言并没有库这个概念，是种通俗的说法，通常所说的库即可以是模块也可以是包

## 5.1 创建包

    # 创建包目录
    mkdir -p package_test && cd package_test

### 5.1.1 创建模块

    # 创建模块m1
    vi m1.py


    #!/usr/bin/python3
    # -*- coding: utf-8 -*-

    print("Hello")

---------

    # 创建模块m2
    vi m2.py


    #!/usr/bin/python3
    # -*- coding: utf-8 -*-

    print("World")

### 5.1.2 创建初始化模块

    vi __init__.py


    #!/usr/bin/python3
    # -*- coding: utf-8 -*-

    if __name__ == '__main__':
        print("作为主程序运行")
    else:
        print("package_test包初始化")

### 5.1.3 创建调用包的脚本

    cd ..
    vi test.py


    #!/usr/bin/python3
    # -*- coding: utf-8 -*-

    # 导入包
    import package_test

    # 调用包的模块
    package_test.m1()
    package_test.m2()

### 5.1.3 调用包

    ./test
    package_test包初始化
    Hello
    World

# 6.内置库

Python能大行其道的原因之一就是数量庞大且功能丰富的内置库，无需额外安装与配置，直接调用即可，是Python学习的必修课

## 6.1 datetime

datetime，Python语言日期和时间处理的标准库

### 6.1.1 当前日期与时间

    >>> import datetime
    >>> now = datetime.datetime.now()
    >>> print(now)
    2024-01-24 14:25:41.623668

- 注：datetime.datetime.now()表示调用datetime库的datetime模块的now()方法，该方法（函数），返回值类行为datetime，用于获取当前日期与时间

### 6.1.2 格式化日期与时间

strftime()方法用于将datetime类型转换为字符串类型，已实现日期时间的格式化操作

    >>> now = datetime.datetime.now()
    >>> date = now.strftime("%Y-%m-%d")
    >>> print(date)
    2024-01-24
    >>> time = now.strftime("%H:%M:%S")
    >>> print(time)
    14:30:32

- 注：strftime()方法%Y表示4位数的年份，%m表示两位数的月份，%d表示两位数的日期，%H表示24小时制的小时，%M表示分钟，%S表示秒

### 6.1.3 字符串转换为日期时间

strftime()方法用于将字符串类型的数据转换为日期时间类型

    >>> datetime = datetime.datetime.strptime(date,"%Y-%m-%d")
    >>> print(datetime)
    2024-01-24 00:00:00

### 6.1.4 日期时间运算

## 6.2 os模块

os模块，跨平台的操作系统接口模块，具备大量的操作系统相关功能的函数，主要包括系统相关、目录及文件操作、路径操作、命令执行和进程管理等

### 6.2.1 系统相关

os模块系统相关的功能主要体现在获取操作系统环境变量

    import os

    # 获取当前操作系统名称，Windows平台返回"nt"，Linux返回"posix"
    print(os.name)
    # 获取当前操作系统路径的分隔符，Windows平台为"\"，Linux为"/"
    print(os.sep)
    # 获取当前操作系统环境变量的分隔符，Windows平台为";"，Linux为":"
    print(os.pathsep)
    # 获取登陆系统的用户名
    print(os.getlogin)

### 6.2.2 文件及目录操作

## 6.3 tarfile模块

tarfile模块，Python内置模块之一，用于tar归档文件的压缩、解压处理，类似于文件操作。Linux系统常见压缩文件格式如下：

- tar，Linux系统打包归档工具，没有压缩功能，打包为tar包之后才可以其他压缩程序进行压缩，最常用的压缩方式为gzip，压缩率最高的方式为bzip2
- gz，即gzip压缩方式，通常只能压缩一个文件
- tgz，即tar.gz，先以tar打包，再用gz压缩得到的文件
- zip，不同于gzip，可分别打包压缩多个文件，压缩率低于tar
- rar，打包压缩文件，最初用于DOS，基于window操作系统。压缩率比zip高，但速度慢，随机访问的速度也慢

### 6.3.1 语法格式

#### 6.3.1.1 打开/创建压缩包

    tarfile.open(name=None, mode='r', fileobj=None, bufsize=10240, **kwargs)

参数详解：

1.name，打开的文件名或路径
2.bufsize：用于指定数据块的大小，默认为20*512字节
3.mode，文件打开方式，默认为'r'，具体如下：

- 'r'或'r:*'，自动解压并打开文件

- 'r:'，只打开文件不解压

- 'r:gz'，gzip格式解压并打开文件

- 'r:bz2'，bz2格式解压并打开文件

- 'r:xz'，lzma格式解压并打开文件

- 'x'or 'x:'，仅创建打包文件，不压缩

- 'x:gz'，gzip方式压缩并打包文件

- 'x:bz2'，bzip2方式压缩并打包文件

- 'x:xz'，lzma方式压缩并打包文件

- 'a' or 'a:'，打开文件，并以不压缩的方式追加内容。如果文件不存在，则新建

- 'w' or 'w:'，以不压缩的方式写入，即只归档不压缩

- 'w:gz'，gzip的方式压缩并写入

- 'w:bz2'，以bzip2的方式压缩并写入

- 'w:xz'，lzma的方式压缩并写入

#### 6.3.1.2 压缩包添加文件

压缩文件的方式主要是将模式改变，在rwx的基础上加上各个压缩的方式，如r:gz、w:bz2、x:xz等样式

add(name, arcname)

参数详解：

- 1.name，压缩文件的文件名或文件路径
- 2.arcname，压缩文件文件名的别名，非必要参数，压缩别名一定不要以路径分隔符为结尾，否则只会创建一个文件夹