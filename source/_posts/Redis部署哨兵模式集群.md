---
title: Redis部署哨兵模式集群
categories:
  - 工作
tags:
  - Linux
  - Redis
  - NoSQL
  - 缓存
  - 集群
  - 主从复制
  - 高可用
  - 云计算
date: 2020-02-04 22:02:05
---

# 集群架构

- 172.16.100.100  master
- 172.16.100.120  node01
- 172.16.100.200  node02

---------

Redis主从复制集群解决了单点故障，但故障转移还是需要人工干预，手动进行主从切换，并不能第一时间恢复业务。有鉴于此，Redis引入了哨兵模式，即为集群的每个节点部署一个独立的监控服务，以监控主从复制的状态，并在主节点故障后通过投票机制自动进行主从切换

# 1.安装redis

# 2.配置主节点

## 2.1 修改redis配置文件

    vi /etc/redis/redis.conf


    # 设置从节点连接主节点的认证密码
    masterauth "redis"
    # 设置从节点权重，主节点失效后权重值最小者将被选为新主节点，为0则表示不参与选举
    slave-priority 100

## 2.2 配置sentinel节点

    vi /etc/redis/sentinel.conf


    # 设置监听IP
    bind 172.16.100.100
    # 设置监听端口
    port 6380
    # 设置sentinel服务为后台运行
    daemonize yes
    # 设置sentinel服务将数据保存到硬盘上的文件名
    dbfilename dump_sentinel.rdb
    # 设置sentinel服务硬盘数据文件存储路径
    dir /usr/local/redis/data
    # 设置sentinel服务pid文件路径
    pidfile  /usr/local/redis/data/sentinel.pid
    # 设置sentinel服务日志路径
    logfile "/usr/local/redis/logs/sentinel.log"
    # 设置sentinel所监听的主节点IP及主从切换策略，1表示判断主节点失效至少需要1个Sentinel节点同意
    sentinel monitor master 172.16.100.100 6379 1
    # 设置主节点连接密码
    sentinel auth-pass master redis
    # 设置监听超时时长，即以ping命令判断Redis数据节点和其余Sentinel节点是否可达，如果超过30000毫秒且没有回复，则判定不可达
    sentinel down-after-milliseconds master 30000
    # 当Sentinel节点集合对主节点故障判定达成一致时，Sentinel领导者节点做故障转移操作，选出新主节点，原来的从节点会向新的主节点发起复制操作，限制每次向新的主节点发起复制操作的从节点个数为1
    sentinel parallel-syncs master 1
    # 故障转移超时时间为180000毫秒
    sentinel failover-timeout master 180000

## 2.3 启动主节点sentinel

    /usr/local/redis/bin/redis-sentinel /etc/redis/sentinel.conf

# 3.配置从节点

## 3.1 修改redis配置文件

    vi /etc/redis/redis.conf


    # 配置主服务器
    slaveof 192.168.0.180 6379

    # 配置主服务器访问密码
    masterauth "redis"

## 3.2 配置sentinel节点

    vi /etc/redis/sentinel.conf


    bind 172.16.100.120
    port 6381
    daemonize yes
    dbfilename dump_sentinel.rdb
    dir /usr/local/redis/data
    pidfile  /usr/local/redis/data/sentinel.pid
    logfile "/usr/local/redis/logs/sentinel.log"
    sentinel monitor slaver001 192.168.0.100 6379 1
    sentinel auth-pass slaver001 redis
    sentinel down-after-milliseconds slaver001 30000
    sentinel parallel-syncs slaver001 1
    sentinel failover-timeout slaver001 180000

# 4.依次启动主从节点redis、sentinel

    # 启动redis节点
    service redis start

    # 启动sentinel节点
    /usr/local/redis/bin/redis-sentinel /usr/local/redis/conf/sentinel.conf

# 5.查看主服务器的主从信息

    redis-cli -a "redis" -h 172.16.100.180 -p 6379 info replication

    # 连接任意sentinel服务查看当前主redis服务信息
    redis-cli -a "redis" -h 192.168.0.150 -p 6380 info sentinel
    redis-cli -a "redis" -h 192.168.0.100 -p 6381 info sentinel
    redis-cli -a "redis" -h 192.168.0.200 -p 6382 info sentinel

# 6.测试集群故障切换

---------

# 参考文档

- https://www.51cto.com/article/651799.html
- https://blog.csdn.net/benxiaohai529/article/details/52848414