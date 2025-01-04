---
title: Kubernetes集群Etcd数据库详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - Etcd
  - 云原生
  - 容器云
  - 云计算
date: 2022-11-10 23:20:36
---

Etcd，由CoreOS团队于2013年用Go言编写的分布式、高可用的开源一致性key-value存储系统，现由Cloud Native Computing Foundation负责管理，用于提供可靠的分布式键值存储、配置共享和服务发现、一致性保障等功能，如数据库选主、分布式锁等。Etcd提供的数据TTL失效、数据改变监视、多值、目录监听、分布式锁原子操作等功能可以方便的跟踪并管理集群节点的状态，从而实现了集群环境的服务发现和注册，解决了分布式系统如何管理节点间的状态这一难题，为跨服务器集群的数据存储提供了可靠的方式

Etcd具有以下特点：

- 简单易使用，基于HTTP+JSON的API，curl即可轻松使用
- 易部署，由Go语言编写，跨平台，部署和维护简单
- 可靠强一致性，使用Raft算法充分保证了分布式系统数据的强一致性，集群中的每个节点都存储有完整的数据
- 高可用，具有容错能力，若集群有n个节点，当有(n-1)/2节点发生故障时依然能提供服务
- 持久化，将数据存储在分层组织的目录中，如同在标准文件系统中，数据更新后将通过WAL格式数据持久化到磁盘，并支持Snapshot快照
- 快速，单实例每秒支持1000次写操作，2000+次读操作，极限写性能可达10K QPS
- 安全，可选SSL客户认证机制

---------

# 体系架构

用户的请求数据经由HTTP Server转发给Store进行具体的事务处理，如涉及节点的修改，则交由Raft模块进行状态的变更、日志的记录，然后再同步给其余的Etcd节点以确认数据提交，最后进行数据的提交，再次同步

## 1.HTTP Server

用于处理用户发送的API请求以及其它Etcd节点的同步与心跳信息请求

## 2.Store

用于处理Etcd支持的各类功能的事务，包括数据索引、节点状态变更、监控与反馈、事件处理与执行等等，是Etcd对用户提供的大多数API功能的具体实现

## 3.Raft

强一致性算法的具体实现，是Etcd的核心，使得Etcd天然地成为一个强一致性、高可用的服务存储目录

## 4.WAL

WAL，Write Ahead Log，即预写式日志，是Etcd的持久化数据存储方式，记录了整个数据库变化的全部历程，即所有内存数据及其状态数据、节点索引数据提交前事先记录日志。这个机制极大的保障了整个集群的数据完整性，可快速从故障中恢复数据、数据回滚及重做。其中，Snapshot是为了防止数据过多而进行的状态快照，Entry表示存储的具体日志内容

# 应用场景

## 1.服务注册与发现

服务注册及健康状况的机制，即在同一个分布式集群中的进程或服务如何才能找到对方并建立连接。用户可在Etcd注册服务，并且对注册的服务配置key TTL，定时保持服务的心跳，从而达到监控健康状态的效果

## 2.消息发布与订阅

分布式系统组件间通信方式最适用的即为消息发布与订阅机制，即构建一个共享配置中心，数据提供者在配置中心发布消息，而消息使用者则从配置中心订阅所需主题，一旦主题有消息发布就会实时通知订阅者，从而实现分布式系统配置的集中式管理与动态更新功能

具体地说，业务系统将配置信息写入Etcd进行集中管理，启动的时候主动获取一次配置信息，同时在Etcd节点上注册一个Watcher并等待，之后每次配置有更新的时候，Etcd都会实时通知订阅者，以此达到获取最新配置信息的目的

Kubernetes集群的API Server将群集状态持久化到Etcd，并通过watch API监视集群，从而发布关键的配置更改，如Pod的创建与删除等操作

## 3.分布式通知与协调

分布式系统中，有一种典型的设计模式就是Master+Slave，即主从模式，具体表现为：Slave提供CPU、内存、磁盘以及网络等各种资源，Master用来协调这些节点以使其对外提供一个服务，如分布式存储（HDFS）、分布式计算（Hadoop）等。主从模式为保障业务的可用性通常会启动多个Master节点作为冗余，通过选主的方式将其中一个节点作为主节点提供服务，其余节点处于等待状态。Etcd的机制即可很容易的实现分布式进程的选主功能

## 4.分布式锁

Etcd的Raft算法保持了数据的强一致性，某次操作存储到集群中的值必然是全局一致的，这样的机制很容易实现分布式锁，分为两种方式，即保持独占和控制时序

- 保持独占，即所有获取锁的用户最终只有一个用户可以得到。Etcd提供了实现分布式锁原子操作CAS（CompareAndSwap）的API，通过设置prevExist值，可保证在多个节点同时去创建某个目录时，只有一个能成功，创建成功的用户即为获得了锁
- 控制时序，即所有想要获得锁的用户都会被安排执行，但是获得锁的顺序是全局唯一的，且决定了执行顺序。Etcd提供了自动创建有序键的API，对一个目录建值时指定为POST动作，同时会自动在目录下生成一个当前最大的值为键以存储这个新的值，即客户端编号，且还可以按顺序列出所有当前目录下的键值。此时这些键的值就是客户端的时序，而这些键中存储的值可代表客户端的编号

---------

# 常用命令

## 1.查看集群成员列表

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem member list --write-out=table

## 2.查看集群成员健康状态

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem endpoint health

## 3.查看集群成员读写状态

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem endpoint status --write-out=table

## 4.写入数据

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem --endpoints=localhost:2379 put /kubesre 123

## 5.查询数据

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem --endpoints=localhost:2379 get  /kubesre

## 6.按key的前缀查询数据

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem --endpoints=localhost:2379 get --prefix / 

## 7.只显示键值

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem --endpoints=localhost:2379 get --prefix / --keys-only --debug 

## 8.清空集群数据

    /opt/etcd/bin/etcdctl --endpoints=https://192.168.100.180:2379,https://192.168.100.181:2379,https://192.168.100.182:2379 --cacert=/opt/etcd/ssl/ca.pem --cert=/opt/etcd/ssl/server.pem --key=/opt/etcd/ssl/server-key.pem del --prefix /

---------

Kubernetes集群是一个典型的声明式系统，即是通过API将用户的期望状态持久化到Etcd数据库，再由系统各个组件通过不断地读取数据库，最后以异步方式执行该状态。这种面向最终状态的方式很好的降低了运维和排查错误的成本，只需给出每个Pod的最终状态即可让各个组件自动执行，相比每执行一条命令就执行相关操作的面向过程的运维模式，大大的提高了系统整体的可靠性。但这样密集的I/O操作，Etcd数据库的性能必然大受影响，甚至成为整个集群的性能瓶颈。所以，Etcd数据库的高性能运行对Kubernetes集群的稳定性至关重要

---------

# 1.Etcd数据库备份

Kubernetes集群所有的对象都存储在Etcd上，定期备份数据对于灾难场景下的快速恢复非常重要。Etcd可通过快照的机制进行数据备份，快照文件包含所有Kubernetes状态和关键信息

## 1.1 备份kubernetes相关目录

    sudo cp -r /etc/kubernetes /etc/kubernetes_bak
    sudo cp -r /var/lib/etcd /var/lib/etcd_bak
    # 二进制安装的集群
    sudo cp -r /var/lib/etcd/default.etcd /var/lib/etcd/default.etcd.bak
    sudo cp -r /var/lib/kubet /var/lib/kubet_bak

## 1.2 备份数据库

    sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt snapshot save /home/sword/etcd_bak/etcd-snap-$(date +%Y%m%d%H%M).db

## 1.3 恢复数据库

### 1.3.1 停止Api Server与Etcd服务

    # 二进制安装的集群用systemctl管理即可
    sudo mv /etc/kubernetes/manifests /etc/kubernetes/manifests_bak
    # 二进制安装的集群为sudo rm -rf /var/lib/etcd/default.etcd
    sudo rm -rf /var/lib/etcd

### 1.3.2 恢复数据

    sudo ETCDCTL_API=3 etcdctl --endpoints=https://127.0.0.1:2379 --cert=/etc/kubernetes/pki/etcd/server.crt --key=/etc/kubernetes/pki/etcd/server.key --cacert=/etc/kubernetes/pki/etcd/ca.crt snapshot restore /home/sword/etcd_bak/etcd-snap-202303061755.db --data-dir=/var/lib/etcd

## 1.4 启动kube-apiserver和Etcd，验证集群状态

    # 二进制安装的集群用systemctl管理即可
    sudo mv /etc/kubernetes/manifests_bak /etc/kubernetes/manifests

- 注：高可用master节点的kubernetes集群恢复数据库的时候要在所有master节点执行恢复的命令

---------

# 2.Etcd隔离环境

Etcd集群的性能和稳定性对网络和磁盘IO非常敏感，任何资源匮乏都会导致心跳超时，使得Kubernetes集群不能调度新的Pod，从而引发故障。故此，在单独的专用的隔离环境上运行Etcd集群十分必要，且磁盘也建议使用更为快速的本地SSD硬盘

## 2.1 部署Etcd集群

## 2.2 分发Etcd证书

    scp /opt/etcd/ssl/*.pem master01:/etc/kubernetes/pki/etcd
    mv /etc/kubernetes/pki/etcd/server.pem /etc/kubernetes/pki/etcd/etcd-server.pem
    mv /etc/kubernetes/pki/etcd/server-key.pem /etc/kubernetes/pki/etcd/etcd-server-key.pem

## 2.3 创建初始化配置文件

    vi kubeadm-config.yaml


    apiVersion: kubeadm.k8s.io/v1beta2
    kind: ClusterConfiguration
    kubernetesVersion: v1.20.12
    clusterName: kubernetes
    imageRepository: registry.aliyuncs.com/google_containers
    etcd: 
      external:
        endpoints:
        - https://192.168.100.100:2379
        - https://192.168.100.120:2379
        - https://192.168.100.200:2379
        caFile: /etc/kubernetes/pki/etcd/ca.pem
        certFile: /etc/kubernetes/pki/etcd/etcd-server.pem
        keyFile: /etc/kubernetes/pki/etcd/etcd-server-key.pem
    apiServer:
      certSANs:
      - 192.168.100.100
      - 192.168.100.120
      - 192.168.100.200
      - 192.168.100.150
    controlPlaneEndpoint: "192.168.100.150:8443"
    networking:
      podSubnet: "172.30.0.0/16"
      serviceSubnet: "10.254.0.0/16"
    ---
    apiVersion: kubeproxy.config.k8s.io/v1alpha1
    kind: KubeProxyConfiguration
    mode: ipvs

## 2.4 初始化集群

    kubeadm init --config=kubeadm-config.yaml

---------

# 参考文档

- https://blog.csdn.net/lihongbao80/article/details/126508726
- https://blog.csdn.net/Jerry00713/article/details/126581563
- https://blog.csdn.net/fengge55/article/details/121797974
- https://blog.csdn.net/alwaysbefine/article/details/127500573
- https://blog.csdn.net/yujia_666/article/details/120667639