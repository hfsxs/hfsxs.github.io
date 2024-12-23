---
title: Linux系统部署NFS文件存储服务器
categories:
  - 工作
tags:
  - Linux
  - NFS
  - 存储
  - 文件存储
  - 云计算
date: 2020-02-02 10:45:34
---

# 1. 部署NFS服务器

    yum install -y nfs-utils
    apt install -y nfs-kernel-server

## 1.2 创建共享目录

    mkdir -p /data && chmod 755 /data

## 1.3 创建配置文件

    vi /etc/exports


    /data 172.16.100.0/24(rw,no_root_squash,sync,insecure,no_subtree_check,no_root_squash)

## 1.4 配置文件生效

    exportfs -r

## 1.5 启动NFS服务器

    systemctl start nfs.service
    systemctl enable nfs.service

## 1.6 测试NFS服务连接

    showmount -e localhost 

# 2.部署NFS客户端

## 2.1 安装NFS客户端

    yum install -y nfs-utils
    apt install -y nfs-common

## 2.2 创建NFS的挂载目录

    mkdir -p /data

## 2.3 挂载共享目录

    # NFS默认用UDP协议，使用TCP协议挂载可以提高NFS的稳定性
    mount -t nfs -o proto=tcp -o nolock 172.16.100.100:/data /data 

# 3.NFS配置参数详解

- rw/ro，设置共享目录的权限，读写 (read-write) 或只读 (read-only)

- sync/async，设置数据同步方式，sync数据同步写入到内存与硬盘中，async则先暂存于内存而非直接写入硬盘

- no_root_squash/root_squash，设置客户端压缩所用账号，root_squash，root账号为root；nfsnobody，以保障NFS服务器的安全；no_root_squash，客户端使用 root 身份来操作服务器；all_squash，压缩所有NFS连接账户为匿名账户nobody(nfsnobody)

- anonuid，anongid，anon，指anonymous (匿名者) ，关于 *_squash 提到的匿名用户的 UID 设定值，通常为 nobody(nfsnobody)
anonuid，指的是 UID；anongid则是群组gid，UID 必需要存在于/etc/passw