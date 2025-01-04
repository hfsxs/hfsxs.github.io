---
title: Redis编译安装
categories:
  - 工作
tags:
  - Linux
  - Redis
  - NoSQL
  - 缓存
  - 云计算
date: 2020-02-04 21:31:17
---

Redis，Remote Dictionary Server，即远程字典服务，由ANSI C语言编写的基于内存的高性能键值对NoSQL数据库，可用作数据库、缓存服务器或消息服务器，支持多种数据结构，如字符串、哈希表、链表、集合、有序集合、位图、Hyperloglogs等，所以又被称为数据结构服务器。Redis特别适用于涉及大数据量的场景，如商品抢购或瞬时访量过高的网站，以缓解成千上万的瞬时请求引发大量磁盘读写操作而导致的数据库压力

Redis以其超高的性能、完美的文档、简洁易懂的源码和丰富的客户端库支持在开源中间件领域广受好评，国内外很多大型互联网公司都在使用，如Twitter、Github、StackOverflow、腾讯、阿里、京东、华为、新浪微博、暴雪娱乐等等

# 1.体系架构

Redis系统架构分为事件处理模块、数据存储及管理模块、集群管理模块及System扩展模块

## 1.1 事件处理模块

Redis基于事件驱动设计，即是将客户端的连接、读、写和关闭操作转换为各种事件由自研的ae事件驱动模型高效地处理。Redis事件处理模块由文件事件处理器和时间事件处理器两部分组成

### 1.1.1 文件事件处理器

Redis的核心部件，用于处理核心任务，如网络IO读写、命令执行等，原理是基于IO多路复用程序监听多个套接字（socket），并根据套接字执行的任务为其关联不同的事件处理器。Redis单线程模型实质上指的就是因为文件事件处理器被设计为单线程运行，即不需要额外创建监听客户端连接的线程而实现了高并发高性能的网络通信，保持了单线程设计的简洁性，降低了资源消耗。这就是Redis单线程高性能的关键

文件事件处理器由四部分组成，即套接字、I/O多路复用处理程序、文件事件分派器和事件处理器

- 多个socket，用于客户端的连接
- IO多路复用程序，用于将多种不同事件类型的客户端sockert置入队列，通过这个队列有序、同步地传送给文件事件分派器
- 文件事件分派器，用于将socket关联到相应的事件处理器
- 事件处理器，用于执行具体的事件，如连接应答处理器、命令请求处理器、命令回复处理器

### 1.1.2 时间事件

时间事件处理器比较简单，主要由serverCron函数执行做一些统计更新、过期key清理、AOF及RDB持久化等辅助操作

## 1.2 数据存储模块

Redis内存数据存储于redisDB，数据及其相关的辅助信息都以key/value格式存储在各个数据库的字典中。此外，数据的写指令还会及时追加到AOF，追加的方式是先实时写入AOF缓冲，再按策略刷缓冲数据到文件。由于AOF记录每个写操作，所以一个key的大量中间状态也会呈现于AOF，从而导致AOF冗余信息过多。因此Redis设计了RDB快照操作，可以通过定期将内存里所有的数据快照落盘到RDB文件，依此记录Redis的所有内存数据。也即是数据持久化

## 1.3 集群管理模块

Redis虽然以高性能著称，但单机模式总还是会达到性能瓶颈，因此主从复制的集群扩展能力也是必不可少。此外，主从复制虽然可以较好的解决单机读写问题，但所有的写操作都集中在Master服务器还是很容易达到写上限，同时主从节点都保存了业务的所有数据，随着业务发展也很容易出现内存不足问题。为此，Redis分区无从避免。虽然业界大多采用在client和proxy端分区，但Redis本身也早早地推出了集群功能，并不断进行优化。Redis cluster预先设定了16384个slot槽，集群启动时通过手动或自动将这些slot分配到不同服务节点上，进行key读写定位时首先对key做hash，并将hash值对16383做按位与运算，确认slot，从而确认服务节点，再对对应的Redis节点进行常规读写。若client发送到错误的Redis分片，则会发送重定向回复。若业务数据大量增加，Redis 集群可以通过数据迁移，来进行在线扩容

## 1.4 系统扩展模块

Redis在4.0版本引入了Module System模块，可以方便地在不修改核心功能的同时进行插件化功能开发，如将新feature封装成动态链接库以便于启动时加载，也可在运行过程中随时按需加载和启用，即以可插拔的方式引入新的数据结构和访问命令

# 2.启动流程

## 2.1 加载配置

加载配置文件，接收命令行中传入的参数，替换服务端设置的默认值，如端口号、密码、持久化设置等

## 2.2 初始化

根据配置信息初始化数据结构，如客户端连接、共享对象、事件处理、持久化模块等

## 2.3 加载持久化数据

加载持久化存储于磁盘的RDB或AOF数据文件

## 2.4 处理事件

启动事件监听服务，等待客户端连接请求，接收到连接请求将其放入事件队列，并通过事件处理器进行处理

# 3.性能优势

- 1.Redis基于内存实现数据存储，没有磁盘IO的损耗，性能极高
- 2.Redis内置的数据结构非常高效，大部分操作的时间复杂度为O(1)
- 3.Redis的网络IO及数据读写这些核心操作由一个线程完成，也即单线程模型，避免了CPU上下文切换及竞争锁的消耗，但其他功能由额外线程执行，如持久化、异步删除和集群数据同步等

# 4.应用场景

大型电商网站、视频直播和游戏应用等存在大规模数据访问，对数据查询效率要求很高，且数据结构简单，不涉及太多关联查询。此时Redis速度上对传统磁盘数据库就有很大优势，可有效减少数据库磁盘IO，提高数据查询效率，减轻管理维护工作量，降低数据库存储成本。Redis对传统磁盘数据库是一个重要的补充，成为了互联网应用，尤其是支持高并发访问的互联网应用必不可少的基础服务之一

- 电商网站秒杀抢购，即电商网站的商品类目、推荐系统以及秒杀抢购活动，适宜使用Redis缓存数据库。如秒杀抢购活动，并发高，对于传统关系型数据库来说访问压力大，需要较高的硬件配置（如磁盘IO）支撑。Redis数据库，单节点QPS支撑能达到10万，轻松应对秒杀并发。实现秒杀和数据加锁的命令简单，使用SET、GET、DEL、RPUSH等命令即可

- 视频直播消息弹幕，即直播间的在线用户列表，礼物排行榜，弹幕消息等信息，都适合使用Redis中的SortedSet结构进行存储。如弹幕消息，可使用ZREVRANGEBYSCORE排序返回

- 游戏排行榜，即在线游戏一般涉及排行榜实时展现，如列出当前得分最高的10个用户。使用Redis的有序集合存储用户排行榜非常合适，有序集合使用非常简单，提供多达20个操作集合的命令

- 社交类应用的最新评论/回复，即web类应用的“最新评论”之类的查询，如果使用关系型数据库，往往涉及到按评论时间逆排序，随着评论越来越多，排序效率越来越低，且并发频繁。使用Redis的List（链表），例如存储最新1000条评论，当请求的评论数在这个范围，就不需要访问磁盘数据库，直接从缓存中返回，减少数据库压力的同时，提升APP的响应速度

---------

# 1.安装依赖包

    yum install -y gcc gcc-c++ make openssl-devel pcre-devel zlib-devel
    apt install -y gcc make pkg-config libssl-dev libpcre3-dev zlib1g-dev

# 2.编译安装redis

    tar -xzvf redis-4.0.8.tar.gz && cd redis-4.0.8
    make && make PREFIX=/usr/local/redis install

# 3.创建redis配置文件

    mkdir -p /etc/redis /usr/local/redis/data /usr/local/redis/logs
    cp redis.conf /etc/redis
    vi /etc/redis/redis.conf


    # 设置IP
    bind 127.0.0.1
    # 设置redis服务为后台启动
    daemonize yes
    # 设置进程文件路径
    pidfile /usr/local/redis/redis-server.pid
    # 设置redis持久化到硬盘数据的文件名
    dbfilename dump.rdb
    # 设置硬盘数据存储路径，防止redis意外重启数据丢失，启动时搜索该文件，将其数据导入，若无法找到则重新建立，为空表示数据已丢失
    dir /usr/local/redis/data
    # 设置访问密码
    # requirepass redis
    # 设置日志存储路径
    logfile "/usr/local/redis/logs/redis.log"

# 5.配置内核参数

    echo "vm.overcommit_memory = 1" >> /etc/sysctl.conf
    sysctl vm.overcommit_memory=1
    echo 511 > /proc/sys/net/core/somaxconn

# 6.创建redis启动脚本

    vi /lib/systemd/system/redis.service


    [Unit]
    Description=Redis
    After=network.target

    [Service]
    Type=forking
    ExecStart=/usr/local/redis/bin/redis-server /etc/redis/redis.conf
    ExecReload=/usr/local/redis/bin/redis-server -s reload
    ExecStop=/usr/local/redis/bin/redis-server -s stop
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target

# 7.启动redis

    systemctl daemon-reload
    systemctl start redis.service
    systemctl enable redis.service

---------

# 参考文档

- http://blog.51cto.com/oceanszf/1752641
- http://lyl-zsu.iteye.com/blog/2408292
- https://blog.csdn.net/junbaozi/article/details/130632437