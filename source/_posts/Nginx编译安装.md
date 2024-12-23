---
title: Nginx编译安装
categories:
  - 工作
tags:
  - Linux
  - Nginx
  - Http服务器
  - 负载均衡
  - 云计算
date: 2020-02-01 14:08:29
---

Nginx，由俄罗斯工程师Igor Sysoev（戈尔·西索耶夫）于2004年所开发的高性能轻量级HTTP、反向代理、负载均衡及电子邮件（IMAP/POP3）服务器，以资源消耗少、并发能力强、配置简单、模块库丰富、性能稳定等特点闻名于业界，目前在web服务器市场份额已超越Apache成为全球第一

### 体系架构

nginx服务器由一个master进程和多个worker进程所构成，整体上表现为依赖事件驱动、异步、非阻塞的模式

#### 1.master进程

master进程负责创建、管理、调度和监控worker进程的工作，具体如下：

- 加载、解析配置文件，并验证其有效性和正确性
- 建立、绑定和关闭socket连接
- 启动、管理worker进程，并持续监控，如woker进程异常退出则自动重新启动新woker进程
- 接收外部信号，如QUIT信号表示关闭服务
- 开启日志文件，获取文件描述符
- 程序及配置文件的热更新，保持业务运行中的平滑更新

#### 2.worker进程

worker进程主要负责处理网络请求及响应，多个worker进程相互独立处理客户端请求，每个worker进程以异步非阻塞方式处理客户端请求，接收到客户端的请求之后调用IO，若不能立即得到响应，则非阻塞地处理其他请求，而客户端在此期间也无需等待响应，可异步处理其他事情。而当IO返回数据时，则将通知此worker进程，之后将暂时挂起当前处理的事务而去响应客户端请求。此外，worker进程构建于Linux基于事件驱动机制的epoll模型，监控多个事件是否准备完毕，如果OK，那么放入epoll队列中，这个过程是异步的。worker只需要从epoll队列循环处理即可。


worker进程具体功能如下：

- 接受客户端请求，并将其依次送入各个功能模块进行处理
- I/O调用，获取响应数据
- 与后端服务器通信，接收后端服务器的处理结果
- 缓存数据，访问缓存索引，查询和调用缓存数据
- 发送请求结果，响应客户的请求
- 接收主程序指令，如重启、升级和退出




worker进程依靠epoll模型管理并发连接

### 功能模块

Nginx服务器由内核与功能模块组成，内核负责底层通讯协议的实现、运行环境的创建及功能模块的调用与协调，其余功能均由各种功能模块完成，模块之间严格遵循高内聚、低耦合的原则，这就是Nginx高度模块化的设计

Nginx将各功能模块组织成链，客户端请求依次经过这条链上的部分或者全部模块进行处理，每个模块只负责实现各自的功能

## 1.核心模块

提供错误日志记录、配置文件解析、事件驱动机制、进程管理等核心功能

## 2.标准HTTP模块

提供HTTP协议解析相关功能，如端口配置、网页编码设置、HTTP响应头设置等

## 3.扩展HTTP模块

用于扩展标准的HTTP功能，可处理一些特殊的服务，如Flash多媒体传输、解析GeoIP请求、 网络传输压缩、安全协议SSL支持等

## 4.邮件服务模块

用于支持邮件服务，包括对POP3协议、IMAP协议和SMTP协议的支持

## 5.第三方模块

用于扩展Nginx服务器应用，完成开发者自定义功能，如Json支持、Lua支持等

---------

# 1.安装依赖包

    # apt install -y nginx
    yum install -y gcc make pcre-devel openssl-devel zlib-devel
    apt install -y gcc make libssl-dev libpcre3-dev zlib1g-dev

# 2.编译安装nginx

    tar -zxvf nginx-1.20.2.tar.gz && cd nginx-1.20.2
    ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf \
    --with-http_ssl_module --with-http_stub_status_module --with-http_gunzip_module \
    --with-http_realip_module --with-http_sub_module --with-pcre --with-stream --with-threads \
    --http-log-path=/var/log/nginx/access.log --error-log-path=/var/log/nginx/error.log
    make &&  make install

# 3.修改配置文件

    sed -i '/nobody/a user sword sword;' /etc/nginx/nginx.conf
    sed -i '/SCRIPT_FILENAME/a fastcgi_param SCRIPT_FILENAME $document_root$fastcgi_script_name;' /etc/nginx/nginx.conf
    sed -i '/default_type/a client_max_body_size 20m;' /etc/nginx/nginx.conf

# 4.创建启动脚本

    vi /lib/systemd/system/nginx.service


    [Unit]
    Description=Nginx Server
    After=network.target

    [Service]
    Type=forking
    ExecStart=/usr/local/nginx/sbin/nginx
    ExecReload=/usr/local/nginx/sbin/nginx -s reload
    ExecStop=/usr/local/nginx/sbin/nginx -s quit
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target

# 5.启动nginx

    systemctl daemon-reload
    systemctl start nginx.service
    systemctl enable nginx.service

# 6.访问nginx

    # curl 127.0.0.1
    http://IP