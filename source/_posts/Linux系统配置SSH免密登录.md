---
title: Linux系统配置SSH免密登录
categories:
  - 工作
tags:
  - Linux
  - SSH
  - 云计算
date: 2020-02-07 09:11:15
---

# 集群架构

- 172.16.100.100  master
- 172.16.100.120  node01
- 172.16.100.200  node02

---------

# 1.安装依赖包

    yum install -y openssh-clients

# 2.生成公钥私钥对

    ssh-keygen -t rsa

# 3.分发公钥到集群其余节点

    ssh-copy-id -i /root/.ssh/id_rsa.pub 172.16.100.100
    ssh-copy-id -i /root/.ssh/id_rsa.pub 172.16.100.120
    ssh-copy-id -i /root/.ssh/id_rsa.pub 172.16.100.200

# 4.测试免密登录

    ssh node01