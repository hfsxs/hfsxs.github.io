---
title: PHP编译安装
categories:
  - 工作
tags:
  - Linux
  - PHP
  - 云计算
date: 2020-02-02 09:56:07
---

PHP，Hypertext Preprocessor，即超文本预处理器，广泛应用于服务端的开源脚本程序语言，尤其适用于Web开发并可嵌入到HTM。PHP于1994年由Rasmus Lerdorf开发 ，最初只是一个简单的用Perl语言编写的统计自己网站访问量的程序。其后重用C语言编写，1995年发布的PHP2加入了对MySQL数据库的支持。此后，越来越多的网站开始使用PHP，不断有其他开发者对其进行重构，使得PHP性能不断提高，已经可以应用在TCP/UDP服务、高性能Web、WebSocket服务、物联网、实时通讯、游戏、微服务等非Web领域的系统研发

目前，业界主流网站服务器架构为LAMP或LNMP，即linux操作系统、Apache/Nginx web服务器、MySQL数据服务器、PHP网页编程语言。这些软件全部是开源免费的，大大的节省了企业成本，所以得到了广泛的应用。根据W3Techs2019年12月6号发布的统计数据，PHP在WEB网站服务器端使用的编程语言所占份额高达78.9%，在内容管理系统的网站中，有58.7%的网站使用WordPress（PHP开发的CMS系统），在所有网站的占比为25.0%

---------

# 体系架构

PHP主要由四层体系构成，从下到上依次是Zend引擎、Extensions、SAPI、Application

## Zend引擎

php的内核，由C语言实现，将php代码翻译（词法、语法解析等一系列编译过程）为可执行的中间语言opcode，从而实现PHP代码所表达的功能。此外，还实现了基本的数据结构（如hashtable、oo）、内存分配及管理，提供了相应的api方法供外部调用，所有的外围功能均围绕其实现

## Extensions

围绕zend引擎，通过组件方式提供各种基础服务，如各种内置函数（array系列）、标准库等都通过其实现，用户也可以根据需要实现自己的extension以达到功能扩展、性能优化等目的，如贴吧正在使用的php中间层、富文本解析就是extension典型应用

## Sapi

Server Application Programming Interface，即服务端应用编程接口，通过一系列钩子函数使得php可以和外围交互数据，可以看作是PHP和外部环境的代理器，是非常优雅和成功的一个设计。Sapi把外部环境抽象后，为内部的PHP提供一套固定的，统一的接口，使得 PHP 自身实现能够不受错综复杂的外部环境影响，保持一定的独立性。通过将php本身和上层应用解耦隔离，可以不再考虑如何针对不同应用进行兼容，而应用本身也可以针对自己的特点实现不同的处理方式

## Application

即所编写的php程序，通过不同的sapi方式得到各种各样的应用模式，如通过webserver实现web应用、在命令行下以脚本方式运行等

---------

# 1.安装依赖包

    yum install -y gcc gcc-c++ make cmake pcre-devel openssl-devel libzip-devel \
    bzip2-devel sqlite-devel perl-devel libxml2-devel libcurl-devel libicu-devel libxslt-devel \
    libjpeg-devel libpng-devel freetype-devel oniguruma-devel

    apt install -y gcc g++ make libssl-dev libpcre3-dev libsqlite3-dev libzip-dev \
    libbz2-dev zlib1g-dev libxml2-dev libcurl4-openssl-dev libonig-dev libxslt1-dev libpng-dev \
    libjpeg-dev libfreetype6-dev 

# 2.编译安装php

    tar -zxvf php-8.1.8.tar.gz && cd php-8.1.8

    ./configure --prefix=/usr/local/php --with-apxs2=/usr/bin/apxs --with-config-file-path=/etc \
    --with-mysqli --with-pdo-mysql --with-bz2 --with-zip --enable-xml --with-curl --with-zlib --with-openssl \
    --enable-mbstring --with-gettext --enable-bcmath --enable-sockets --enable-opcache --with-libxml --enable-intl \
    --enable-dom --enable-calendar --enable-gd --with-jpeg --with-freetype --with-xsl --with-libdir=lib64 --disable-debug \
    --without-pear --disable-rpath --disable-ipv6
    make && make install

# 3.创建配置文件

    cp php.ini-production /etc/php.ini -r

# 4.修改配置文件

    sed -i 's@;date.timezone =@date.timezone = Asia/Shanghai@g' /etc/php.ini
    sed -i 's@max_execution_time = 30@max_execution_time = 300@g' /etc/php.ini
    sed -i 's@post_max_size = 8M@post_max_size = 32M@g' /etc/php.ini
    sed -i 's@max_input_time = 60@max_input_time = 300@g' /etc/php.ini
    sed -i 's@memory_limit = 128M@memory_limit = 128M@g' /etc/php.ini
    sed -i 's@;always_populate_raw_post_data = -1@always_populate_raw_post_data = -1@g' /etc/php.ini

# 5.配置opcache缓存

    opcahce=`find /usr/local/php -name 'opcache.so'`
    echo zend_extension=$opcahce >> /etc/php.ini