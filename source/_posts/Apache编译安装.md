---
title: Apache编译安装
categories:
  - 工作
tags:
  - Linux
  - Apache
  - Http服务器
  - 云计算
date: 2020-02-01 09:20:02
---

Apache HTTP Server，是最流行的开源免费的HTTP服务器软件之一，功能强大，配置简单，速度快，应用广泛，性能稳定可靠，曾是世界使用排名第一的Web服务器软件，广泛应用于世界著名网站，如Amazon、Yahoo!、W3 Consortium、Financial Times等

Apache服务器的发轫颇具戏剧性。其最初发源于NCSA（伊利诺伊大学香槟分校的国家超级电脑应用中心）的httpd服务器，当时只用于小型或试验Internet性网络。该项目停顿之后，鉴于其强大的功能，一些爱好者与用户开始自发维护并不断改善其功能。为了更好进行沟通，Brian Behlendorf 自己建立了一个邮件列表，将其作为这个群体（或者社区）交流技术、维护软件的一个媒介，把代码重写与维护的工作有效组织起来。这些开发者们群体自称为“Apache 组织”，将这个经过不断修正并改善的服务器软件命名为 Apache 服务器（Apache Server）。该组织就是现今赫赫有名的Apache软件基金会的雏形

# 体系架构

Apache服务器基于模块化设计，大部分功能可被分割成相互独立的模块，通过增加和删除模块就可以扩展和修改功能。依据其功能模块，可将其架构划分为五层

## 1. 操作系统平台功能层

Apache服务器操作系统本身提供的底层功能，比如进程和线程、进程和线程的通信，网络套接字通信和文件操作等

## 2.可移植运行库

apr，即Apache portable runtime，操作系统适配层，实现了Apache服务器跨平台的功能。由于不同的操作系统提供的底层API不同，即实现同一个操作所用的函数方法不同，位于Apache和操作系统之间的APR根据不同的操作系统分别实现这一功能，直接用APR的统一API接口即可实现跨操作系统操作

## 3.核心功能层

由核心程序和核心模块组成，用于实现基本功能和核心功能

- 核心程序由核心组件构成，即配置文件组件(http_config)、进程并发组件(MPM)、连接处理组件(http_connection)、HTTP协议处理组件(http_protocol)、HTTP请求处理组件(http_request)、HTTP核心组件(http_core)、核心模块组件(mod_core) 、日志处理组件、虚拟主机处理组件、过滤模块组件，各个组件之间可相互调用，用于实现基本的功能，如启动和终止apache、处理配置文件(config.c)、接受和处理HTTP连接、读取和响应HTTP请求，处理HTTP协议。此外，还提供其余模块可调用的API，用于实现非核心模块的功能

- 核心模块有两个，即mod_core和mod_so，其中mod_core负责处理配置文件中的大部分配置指令，并根据这些指令运行apache；mod_so模块负责在需要的时候动态加载其余模块

## 4.可选功能层

即其余非核心的模块

## 5.第三方支持库

用于实现第三方的附加功能，如mod_perl、mod_ssl等

# 工作流程

## 1.启动流程

apache服务器的启动分为两个阶段，即高权限启动阶段和低权限运行阶段，通常称之为两阶段启动方式

apache服务器启动时首先初始化内存池资源，然后读取和解析apache的配置文件(httpd.conf) ，在启动的最后阶段将将控制权交给MPM，只有当MPM执行失败或结束后才把控制权交还给主程序，MPM在处理HTTP连接时使用普通用户权限，以避免root权限的攻击

## 2.链接处理流程

收到client端的HTTP请求并建立socket连接后，apache将读取请求信息，并调用HTTP_PROTOCOL模块将开始对该报文进行解析

## 3.请求处理流程

处理HTTP请求报文，分为三个阶段，即请求解析阶段、安全处理阶段、请求准备阶段

- 请求解析阶段，主要是包含URL的一些处理，如字符转义、名称转换、重定向等
- 安全处理，即访问控制、身份认证、用户授权
- 请求准备阶段，确定客户端请求资源类型(html txt gif ）及补丁修复，如优化操作等

## 4.响应生成流程

对于静态的HTML文件直接读取文件返回给客户端，对于动态文件，如脚本CGI、js、数据库文件等，将调用对应的处理器生成请求的内容，生成内容再进入过滤器进行内容过滤，通过最后一个过滤器(网络过滤器)后，将响应内容发送到网络，最后传输到客户端并在浏览器中显示

---------

# 1.安装依赖包

    yum install -y gcc make openssl-devel pcre-devel zlib-devel perl-devel expat-devel

# 2.编译安装apr

    tar -zxvf apr-1.5.2.tar.gz && cd apr-1.5.2
    ./configure --prefix=/usr/local/apr
    make &&  make install 

# 3.编译安装apr-util

    tar -zxvf apr-util-1.5.4.tar.gz && cd apr-util-1.5.4
    ./configure --prefix=/usr/local/apr-util --with-apr=/usr/local/apr
    make &&  make install

# 4.编译安装apache

    tar -zxvf httpd-2.4.25.tar.gz && cd httpd-2.4.25
    ./configure --prefix=/usr/local/httpd --sysconfdir=/etc/httpd/conf \
    --enable-cache --enable-disk-cache --enable-mem-cache --enable-file-cache \
    --enable-proxy --enable-proxy-http --enable-proxy-balancer --enable-proxy-ftp --enable-proxy-connect --enable-proxy-ajp \
    --enable-deflate=static --enable-headers=static --enable-rewrite=static --enable-expires=static --enable-ssl=static --enable-cgid=static \
    --with-zlib --with-pcre --enable-mods-shared=all --enable-mpms-shared=all --with-mpm=worker --with-apr=/usr/local/apr --with-apr-util=/usr/local/apr-util
    make &&  make install

# 5.修改配置文件

    sed -i 's@#ServerName www.example.com:80@ServerName localhost:80@g' /etc/httpd/conf/httpd.conf

# 6.配置Apache启动脚本

    cp /usr/local/httpd/bin/apachectl /etc/init.d/httpd

# 7.启动Apache服务器

    /etc/init.d/httpd start

# 8.访问Apache服务器

http://ip