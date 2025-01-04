---
title: Redis部署分片式集群
categories:
  - 工作
tags:
  - Linux
  - Redis
  - NoSQL
  - 缓存
  - 集群
  - 主从复制
  - 云计算
date: 2024-07-12 09:46:07
---

Redis Cluster是Redis官方推出的无中心架构的分布式集群解决方案，集群所有节点都用于存储数据和集群状态，其具体机制为：基于主从复制模式将数据均匀分片到集群节点用于管理集群数据和集群状态的哈希槽，每个节点负责一部分数据，其中主节点负责读写操作和集群状态维护，从节点复制主节点的数据与状态信息，并承担读操作。节点之间通过gossip协议交换状态信息，失去连接或不可达将被标记为不可用，并从可用节点选举出新的主节点

# 工作原理

Redis Cluster基于虚拟哈希槽分区技术将数据划分为16384个Slots（槽），并将所有的Key依据哈希函数映射到这些槽位进行存储，即由集群每个节点负责维护一部分槽位信息及其所映射的K/V数据，客户端请求到达后根据槽位配置信息直接定位到目标节点进行读写操作。Slots是Redis Cluster管理数据的基本单位，集群伸缩就是槽和数据在节点之间的移动，即扩容或缩容槽需要重新分配，数据也需要重新迁移，但服务不需要下线。由此，集群的扩展性大大增强，支持节点动态增删和数据分布动态调整，高可用性也有保障，且故障自动failover。但数据异步复制的特性决定了数据强一致性无法得到保证

# 集群架构

- 172.100.100.180 master01/slave01
- 172.100.100.181 master02/slave02
- 172.100.100.183 master03/slave03

# 1.安装redis

# 2.部署主节点

## 2.1 创建配置文件

    sudo vi /etc/redis/master.conf


    port 6379
    bind 0.0.0.0
    daemonize yes
    requirepass redis
    masterauth redis
    protected-mode yes

    maxmemory 1024M

    dbfilename master.rdb
    dir /usr/local/redis/data
    pidfile /var/run/redis-master.pid
    logfile "/usr/local/redis/logs/master.log"

    # 设置启用集群功能
    cluster-enabled yes
    # 设置集群配置文件，由节点自动维护，用于存储集群节点信息及其状态信息
    cluster-config-file node-master.conf
    # 设置节点失联时间，即超时之后节点即从集群移除，若为主节点则触发主从切换
    cluster-node-timeout 15000

- 注：三个主节点配置文件相同

## 2.2 创建启动脚本

    sudo vi /lib/systemd/system/redis_master.service


    [Unit]
    Description=Redis
    After=network.target

    [Service]
    Type=forking
    ExecStart=/usr/local/redis/bin/redis-server /etc/redis/master.conf
    ExecReload=/usr/local/redis/bin/redis-server -s reload
    ExecStop=/usr/local/redis/bin/redis-server -s stop
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target

## 2.3 启动主节点

    sudo systemctl daemon-reload
    sudo systemctl start redis_master.service
    sudo systemctl enable redis_master.service

# 3.配置从节点

## 3.1 创建配置文件

    sudo vi /etc/redis/slave.conf


    port 6380
    bind 0.0.0.0
    daemonize yes
    requirepass redis
    masterauth redis
    protected-mode yes

    maxmemory 1024M

    dir /usr/local/redis/data
    pidfile /var/run/redis-slave.pid
    logfile "/usr/local/redis/logs/slave.log"

    # 设置启用集群功能
    cluster-enabled yes
    # 设置集群配置文件，由节点自动维护，用于存储集群节点信息及其状态信息
    cluster-config-file node-slave.conf
    # 设置节点失联时间，即超时之后节点即从集群移除
    cluster-node-timeout 15000

- 注：三个从节点配置文件相同

## 2.2 创建启动脚本

    sudo vi /lib/systemd/system/redis_slave.service


    [Unit]
    Description=Redis
    After=network.target

    [Service]
    Type=forking
    ExecStart=/usr/local/redis/bin/redis-server /etc/redis/slave.conf
    ExecReload=/usr/local/redis/bin/redis-server -s reload
    ExecStop=/usr/local/redis/bin/redis-server -s stop
    PrivateTmp=true

    [Install]
    WantedBy=multi-user.target

## 3.3 启动从节点

## 2.3 启动主节点

    sudo systemctl daemon-reload
    sudo systemctl start redis_slave.service
    sudo systemctl enable redis_slave.service

# 3.Redis集群初始化

    sudo /usr/local/redis/bin/redis-cli -a redis --cluster create --cluster-replicas 1 172.100.100.180:6379 172.100.100.180:6380 172.100.100.181:6379 172.100.100.181:6380 172.100.100.182:6379 172.100.100.182:6380

# 4.验证集群状态

    sudo /usr/local/redis/bin/redis-cli

    127.0.0.1:6379> auth redis
    OK

## 4.1 集群信息

    127.0.0.1:6379> cluster info
    cluster_state:ok
    cluster_slots_assigned:16384
    cluster_slots_ok:16384
    cluster_slots_pfail:0
    cluster_slots_fail:0
    cluster_known_nodes:6
    cluster_size:3
    cluster_current_epoch:6
    cluster_my_epoch:5
    cluster_stats_messages_ping_sent:303
    cluster_stats_messages_pong_sent:304
    cluster_stats_messages_meet_sent:5
    cluster_stats_messages_sent:612
    cluster_stats_messages_ping_received:304
    cluster_stats_messages_pong_received:308
    cluster_stats_messages_received:612

## 4.2 节点主从关系

    127.0.0.1:6379> info replication
    # Replication
    role:master
    connected_slaves:1
    slave0:ip=172.100.100.180,port=6380,state=online,offset=2842,lag=0
    master_replid:4593f8fefee93563e77de327cb17203c2ada6167
    master_replid2:0000000000000000000000000000000000000000
    master_repl_offset:2842
    master_repl_meaningful_offset:0
    second_repl_offset:-1
    repl_backlog_active:1
    repl_backlog_size:1048576
    repl_backlog_first_byte_offset:1
    repl_backlog_histlen:2842

## 4.3 集群节点关系
    
    127.0.0.1:6379> cluster nodes
    9b3455aa02690fddb7fd04684f441a0cdb8a7e01 172.100.100.180:6379@16379 master - 0 1721630183744 1 connected 0-5460
    99475e8b376d71fe51d7a52e413aab8b58ee6d82 172.100.100.181:6379@16379 master - 0 1721630186752 3 connected 5461-10922
    5264f9b7db6512765c6c3406a14c03c9bd4979ed 172.100.100.182:6380@16380 slave 99475e8b376d71fe51d7a52e413aab8b58ee6d82 0 1721630185000 6 connected
    cefbed9e3ece2a326bc8d88d2f1bddee526d8fe7 172.100.100.180:6380@16380 slave c1cf0836ef86f29c6786e523bc1b7f9e4cfef1c1 0 1721630186000 5 connected
    216177fbb99467606b945be756c35ca9dc4aaed8 172.100.100.181:6380@16380 slave 9b3455aa02690fddb7fd04684f441a0cdb8a7e01 0 1721630186000 4 connected
    c1cf0836ef86f29c6786e523bc1b7f9e4cfef1c1 172.100.100.182:6379@16379 myself,master - 0 1721630184000 5 connected 10923-16383

---------

# 参考文档

- https://blog.csdn.net/m0_56754510/article/details/131942652
- https://blog.csdn.net/weixin_43888891/article/details/131208398
- https://blog.csdn.net/suixinfeixiangfei/article/details/129356704