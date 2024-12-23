---
title: Kafka集群Kraft模式部署
categories:
  - 工作
tags:
  - Linux
  - Kafka
  - 消息队列
  - 中间件
  - 云计算
date: 2024-08-07 10:55:47
---

Kafka基于Zookeeper服务管理集群的元数据信息以及集群的协调工作，性能必然受其制约与影响，也增加了运维难度。于是，2.8版本开始，Kafka引入KRaft集群架构模式，力图去除Zookeeper依赖。当然，KRaft集群模式最初并不如Zookeeper模式稳定，所以依然保持了兼容的状态。直到3.3.1版本，Kafka官方开始将KRaft标注为生产环境适用。之后，经过长期的多个版本的持续迭代，基本已经可以完全弃用Zookeeper

# 工作原理

KRaft模式集群基于分布式共识算法Raft管理集群，集群每个Broker节点都可参与，如分区分配、副本分配、元数据快照等

# 1.配置Java环境

# 2.下载安装包

    wget https://downloads.apache.org/kafka/3.6.2/kafka_2.12-3.6.2.tgz
    tar -xzvf kafka_2.12-3.6.2.tgz && sudo mv kafka_2.12-3.6.2 /usr/local/kafka
    sudo mkdir -p /usr/local/kafka

# 3.配置Kafka集群

    sudo vi /usr/local/kafka/config/kraft/server.properties


    # 设置节点ID，唯一性
    node.id = 1
    # 设置Broker节点角色，broker表示数据节点；controller表示控制器节点；broker,controller表示混合节点；为空则表示ZooKeeper模式
    process.roles = broker,controller
    # 设置数据存储目录
    log.dirs = /usr/local/kafka

    # 设置Controller选举节点，用于管理集群状态，建议配置所有节点
    controller.quorum.voters = 1@172.100.100.101:9093,2@172.100.100.102:9093,3@172.100.100.103:9093

    # 设置Broker服务协议别名
    inter.broker.listener.name = PLAINTEXT
    # 设置controller服务协议别名
    controller.listener.names = CONTROLLER
    # 设置Broker角色绑定的端口，数据节点端口为9092，控制节点端口为9093
    listeners = PLAINTEXT://:9092,CONTROLLER://:9093
    # 设置Broker节点外网访问地址，支持域名和IP
    advertised.Listeners = PLAINTEXT://:9092

- 注：三个节点node.id参数务必要保持其唯一性，且建议Broker节点角色单独部署，以免混合部署的服务器资源不足引发OOM等问题

# 4.格式化数据目录

## 4.1 创建集群UUID

    sudo /usr/local/kafka/bin/kafka-storage.sh random-uuid

## 4.2 格式化数据存储目录

    sudo /usr/local/kafka/bin/kafka-storage.sh format -t 7NSm-xjRRGu3hj-4bA0qMw -c /usr/local/kafka/config/kraft/server.properties

- 注：三个节点都需要执行

# 5.创建启动脚本

    sudo vi /lib/systemd/system/kafka.service


    Description = Apache Kafka
    Documentation = https://kafka.apache.org
    After = network.target

    [Service]
    Type = simple
    User = root
    Group = root
    ExecStart = /usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/kraft/server.properties
    ExecStop = /usr/local/kafka/bin/kafka-server-stop.sh
    Restart = on-failure

    [Install]
    WantedBy = multi-user.target

## 6.启动Kafka集群

    sudo systemctl daemon-reload
    sudo systemctl start kafka.service
    sudo systemctl enable kafka.service

---------

# 参考文档

- https://blog.csdn.net/qq_27740127/article/details/134725178
- https://blog.csdn.net/cold___play/article/details/132267259
- https://blog.csdn.net/ximenjianxue/article/details/132545093

https://blog.csdn.net/2201_75529678/article/details/128181202