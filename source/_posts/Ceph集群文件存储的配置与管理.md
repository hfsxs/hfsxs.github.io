---
title: Ceph集群文件存储的配置与管理
categories:
  - 工作
tags:
  - Linux
  - Ceph
  - 存储
  - 文件存储
  - 分布式存储
  - 云存储
  - 云计算
date: 2023-07-15 09:24:20
---

CephFS，即Ceph文件系统，标准的POSIX文件系统，至少一个元数据服务器(Metadata Server，MDS)用于元数据管理，以实
现和数据的分离，从而降低了复杂度，也增加了系统可靠性。MDS提供了一个包含智能缓存层的共享一致的文件系统，基于动态子树分区算法设计，具备高效的元数据组织和索引方式的功能，极大地降低了读写频率

Ceph MDS以守护进程方式运行，不直接向客户端提供任何数据，所有的数据都由OSD管理。MDS服务可启用多个，主MDS节点活跃时，其余节点都将处于standby状态，待主MDS节点发生故障再手动指定一个standby节点跟踪活动节点，同时将会在内存维护一份和活跃节点一样的数据，以达到预加载缓存的目的

# 1.部署mds

## 1.1 安装ceph-mds

    sudo apt install -y ceph-mds

## 1.2 创建节点目录

    sudo -u ceph mkdir -p /var/lib/ceph/mds/ceph-node01

## 1.3 创建mds密钥环

    ceph auth get-or-create mds.node01 osd "allow rwx" mds "allow" mon "allow profile mds"

## 1.4 导出mds密钥环

    sudo ceph auth get mds.node01 -o /var/lib/ceph/mds/ceph-node01/keyring

## 1.5 集群配置文件添加mds

    sudo vi /etc/ceph/ceph.conf


    [mds.node01]
    host = node01

## 1.6 启动服务

    sudo systemctl start ceph-mds@node01
    sudo systemctl enable ceph-mds@node01

# 2.配置存储池

    # 
    ceph osd pool create cephfs_data 128
    ceph osd pool create cephfs_metadata 128

# 7. 

    ceph fs new cephfs cephfs_metadata cephfs_data

# 8.

    ceph fs ls
    ceph mds stat
    ceph -s

---------

# 参考文档

- https://cloud.tencent.com/developer/article/2015907
- https://blog.csdn.net/qq_63844528/article/details/130213273
- https://access.redhat.com/documentation/zh-cn/red_hat_ceph_storage