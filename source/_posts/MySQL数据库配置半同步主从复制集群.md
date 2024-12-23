---
title: MySQL数据库配置半同步主从复制集群
categories:
  - 工作
tags:
  - Linux
  - MySQL
  - SQL
  - 数据库
  - 主从复制
  - 云计算
date: 2020-02-02 15:54:48
---

MySQL数据复制有两种方式，即异步复制、半同步复制、全同步复制，默认为异步方式

# 异步方式

从节点通过IO线程拉取主节点的binlog，这个过程中主节点并不关注从节点是否已经接收、处理数据和数据处理的进度，而是继续处理客户端提出的事务已生成binlog文件工从节点拉取。若主节点此时发生故障，则已经提交的事务就存在并没被从节点拉取的数据，或者从节点拉取到的binlog日志文件不完整，就会造成主从节点的数据不一致，甚至在恢复时造成数据的丢失。但复制速度快，扩展性好，资源占用少

# 全同步方式

主节点等待所有的从节点完成数据同步后再提交事务，再将执行信息返回给客户端，从而保障主从节点数据完整性，但处理速度会大大降低

# 半同步方式

主数据库等待至少一个从节点完成数据同步后再提交事务，既保障了处理速度，又至少保障了一个从节点的数据完整性

半同步复制模式工作机制：从节点IO线程将binlog日志接收完毕之后，反馈给主节点一个确认消息，通知主节点binlog日志已经接收完毕。然后，主节点再提交下一个事务。若主节点等待反馈超时，则自动切换为异步复制模式，直到接收到至少一个从节点的反馈信息为止。由于增加了这个反馈机制，相对于异步复制就会有一个延迟，性能稍微降低，但至少保障了一个从节点的数据完整性

---------

# 集群架构

- 172.16.100.200 master
- 172.16.100.100 slaver1
- 172.16.100.120 slaver2

---------

# 1.安装MySQL数据库服务器

# 2.安装MySQL数据库半同步复制插件

## 2.1 配置主节点

    # 安装半同步复制插件
    mysql> install plugin rpl_semi_sync_master soname 'semisync_master.so';
    # 查看半同步复制插件状态
    mysql> show global variables like 'rpl%';

## 2.2 配置从节点

    # 安装半同步复制插件
    mysql> install plugin rpl_semi_sync_slave soname 'semisync_slave.so'; 
    # 查看半同步复制插件状态
    mysql> show global variables like 'rpl%';

# 3.主从节点启用半同步复制

## 3.1 配置主节点

    sudo vi /etc/my.cnf


    [mysqld]

    # 启用半同步复制插件
    rpl_semi_sync_master_enabled=1
    # 设置半同步复制超时时长
    rpl_semi_sync_master_timeout=1000

## 3.2 配置从节点

    sudo vi /etc/my.cnf


    [mysqld]

    # 启用半同步复制插件
    rpl_semi_sync_slave_enabled=1

# 5.重启主从节点MySQL数据库服务

# 6.测试主从复制功能

---------

# 参考文档

- https://blog.csdn.net/xlgen157387/article/details/69400410