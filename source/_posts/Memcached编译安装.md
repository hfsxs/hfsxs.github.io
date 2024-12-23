---
title: Memcached编译安装
categories:
  - 工作
tags:
  - Linux
  - Memcached
  - NoSQL
  - 缓存
  - 云计算
date: 2020-02-04 21:07:25
---


# 1.安装依赖包

    yum -y install gcc gcc-c++ make cmake automake autoconf pcre pcre-devel zlib zlib-devel \
    openssl openssl-devel libjpeg-devel libpng-devel libxml2-devel bzip2 bzip2-devel libcurl-devel

# 2.创建memcached用户

    groupadd memcached && useradd -g memcached -s /sbin/nologin memcached -M
    mkdir -p /usr/local/memcached/logs
    chown -R memcached.memcached /usr/local/memcached

# 3.编译安装libevent

    tar -xzvf libevent-2.1.8-stable.tar.gz
    cd libevent-2.1.8-stable
    ./configure --prefix=/usr/local/libevent -with-libevent=/usr/local/libevent
    make && make install

# 4.编译安装memcached

    tar -xzvf memcached-1.5.6.tar.gz
    cd memcached-1.5.6
    ./configure --prefix=/usr/local/memcached --enable-threads --with-libevent=/usr/local/libevent
    make && make install


# 5.启动memcached

    /usr/local/memcached/bin/memcached -d -u memcached -l 192.168.0.150 -p 11211 -P /usr/local/memcached/memcached.pid

---------

## memcached启动参数

- -d，启动一个守护进程
- -m，设置分配给memcached使用的内存量，单位是MB，设为10MB
- -u，设置memcached运行用户，设为memcached
- -l，设置监听的服务器IP地址，设为192.168.0.150
- -p，设置memcached监听的端口，设为11211，最好是1024以上的端口
- -c，设置最大运行的并发连接数，默认是1024，设为256，按照服务器的负载量设定
- -P，设置memcached的pid文件存储路径，设为/usr/local/memcached/memcached.pid
- -v，设置memcached普通的错误或者警告类型的日志信息 
- -vv，设置memcached详细日志信息，包含客户端命令和server端的响应信息 
- -vvv，设置memcached详细日志信息，包含内部的状态信息
- /usr/local/memcached/bin/memcached -d -vv -m 10 -u memcached -l 192.168.0.150 -p 11211 -c 256 -P /usr/local/memcached/logs/memcached.pid >> /usr/local/memcached/logs/memcached.log 2>&1