---
title: Ceph集群块存储的配置与管理
categories:
  - 工作
tags:
  - Linux
  - Ceph
  - 存储
  - 块存储
  - 分布式存储
  - 云存储
  - 云计算
date: 2023-07-10 12:01:49
---

Block，即块，一个固定大小的字节序列，如一个512字节的数据块，每个块都有自己的地址。块存储接口是最为常见的数据存储方式，基于旋转介质，如硬盘、CD、软盘，甚至传统的磁道磁带，应用极为广泛。RBD即是Ceph提供的块设备，是Ceph集群当前能提供的最稳定、应用最广泛的存储接口，数据条带化的存储到集群内的多个OSD，配置精简，大小可调，且具备RADOS的多种能力，如快照、复制和数据一致性，Linux系统可通过rbd命令将RBD块存储映射为本地的块设备文件，就像使用硬盘一样

# 1.创建存储池

## 1.1 查看存储池

    ceph osd lspools

## 1.2 创建存储池

    ceph osd pool create rbd 128 128

- 注：存储池创建的语法格式为ceph osd pool create <pool_name> pg_mun pgp_mun，若不指定pg_num、pgp_num数，则将集群配置文件作为默认值

## 1.3 设置存储池类型

    # rbd表示块设备存储类型，cephfs表示文件存储类型，rgw表示对象存储类型
    ceph osd pool application enable rbd rbd

## 1.4 初始化存储池

    rbd pool init rbd

# 2.创建磁盘镜像

    rbd create -p rbd --image kvm-centos7 --size 50G

- 注：块存储磁盘镜像的创建语法格式为：rbd create --size {megabytes} {pool-name}/{image-name}或rbd create -p pool-name --image image-name --size 100G，若不指定存储池，则默认为rbd

# 3.禁用镜像附加特性

    rbd feature disable --pool rbd --image kvm-centos7 exclusive-lock, object-map, fast-diff, deep-flatten

# 4.验证存储池镜像

    # 查看存储池的镜像
    rbd ls --pool rbd
    # 查看镜像信息
    rbd info rbd/kvm-centos7

# 5.创建ceph客户端用户并授权

## 5.1 创建ceph客户端用户

    ceph auth get-or-create client.rbd

- 注：ceph集群默认启用Cephx身份验证系统验证用户和守护进程，但只负责认证授权，没有数据传输加密功能。Ceph管理员将创建用户时生成的用户名和密钥环保存于monitor，客户端或应用连接集群任一monitor节点即可完成身份验证过程，有效的用户名语法为TYPE.ID，如client.admin、client.cinder

## 5.2 ceph用户授权

    ceph auth caps client.rbd mon 'allow r' osd 'allow rwx pool=rbd'

- 注：ceph集群用户授权语法格式为{daemon-type} ‘allow {capability}’，daemon-type表示集群组件，如mon、osd、mds等；capability即为具体的权限，如r、w、x，与Linux文件权限相一致

## 5.3 导出客户端用户密钥环

    sudo ceph auth get client.rbd -o /etc/ceph/ceph.client.rbd.keyring

## 5.4 验证客户端用户及其权限

    ceph auth list

# 6.ceph客户端配置

## 6.1 安装ceph客户端

    sudo apt install -y ceph-common

## 6.2 同步客户端用户密钥环

    scp worker01:/etc/ceph/ceph.client.rbd.keyring /etc/ceph

## 6.3 创建ceph配置文件

    scp worker01:/etc/ceph/ceph.conf /etc/ceph
    sudo vi /etc/ceph/ceph.conf


    [global]
    fsid = c649ba53-2f1a-431c-8fd4-eb4b423527d5
    mon initial members = node01,node02,node03
    mon host = 192.168.100.150,192.168.100.160,192.168.100.180
    public network = 192.168.100.0/24
    cluster network = 172.100.100.0/24
    auth cluster required = cephx
    auth service required = cephx
    auth client required = cephx

    [client.rbd]
    keyring=/etc/ceph/ceph.client.rbd.keyring

## 6.4 验证客户端连接集群服务器

    ceph -s --user rbd
    ceph osd lspools --user rbd

# 7.ceph客户端挂载块存储镜像

## 7.1 查看镜像

    rbd ls -l rbd --id rbd

## 7.2 将镜像映射到本地

    sudo rbd map rbd/kvm-centos7 --id rbd

## 7.3 验证镜像映射

    rbd showmapped

## 7.4 格式化存储池镜像映射的分区

    sudo mkfs.xfs /dev/rbd0

## 7.5 挂载分区

    sudo mount /dev/rbd0 /home/works

## 7.6 验证磁盘挂载

    df -h

# 8.镜像管理

## 8.1 镜像快照

## 8.2 镜像克隆

## 8.3 镜像扩容

---------

# 参考文档

- https://www.jianshu.com/p/ed9f022c2aa6
- https://www.r9it.com/20200215/ceph-rbd.html
- https://blog.csdn.net/NancyLCL/article/details/126917721