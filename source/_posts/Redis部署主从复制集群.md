---
title: Redis部署主从复制集群
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
date: 2020-02-04 21:36:26
---

Redis主从复制是指将一台Redis服务器（主节点）的数据复制到其他的Redis服务器（从节点），该过程是单向进行，即只能从主节点复制到从节点。主节点宕机后即可将业务切换到从节点，尽可能的消弱影响

---------

# 集群架构

- 172.16.100.100  master
- 172.16.100.200  slaver

---------

# 1.部署redis

# 2.配置主节点

    sudo vi /etc/redis/redis.conf


    # 设置监听IP
    bind 0.0.0.0

# 3.配置从节点

    sudo vi /etc/redis/redis.conf


    # 设置主节点IP及端口
    replicaof 172.16.100.100 6379

    # 设置主节点访问密码
    # masterauth "redis"

    # 设置权重值，为0则表示不参与master选举
    # replica-priority 100

# 3.启动主、从redis节点，验证主从功能

    redis-cli -a "redis" -h 172.16.100.200 -p 6379 info replication

---------

# 参考文档

- https://blog.csdn.net/shianla/article/details/137613665
- https://blog.csdn.net/qq_36838700/article/details/140637913
- https://blog.csdn.net/weixin_43412762/article/details/134946683