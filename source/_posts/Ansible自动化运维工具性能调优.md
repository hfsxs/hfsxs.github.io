---
title: Ansible自动化运维工具性能调优
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2024-02-18 10:30:10
---

Ansible自动化运维工具基于SSH连接对被控主机进行控制，无需安装客户端软件，但随着着被控主机数量的增长，其执行效率将会越来越慢，因此对SSH进行调优能提高Ansible的工作效率。此外，Ansible执行Playbook时都会收集被控主机的信息，通常耗时较长，也是影响性能的重要因素，若是环境允许建议进行关闭

# 1.OpenSSH调优

默认情况下，OpenSSH服务基于安全考虑，服务器根据客户端的IP地址进行DNS反向解析以得到客户端的主机名，并将主机名经DNS查询解析为IP地址，最后验证IP地址的一致性。这个过程相当耗费时间，可以进行关闭以加速SSH连接速度

    vi /etc/ssh/sshd_config


    UseDNS no

# 2.Ansible SSH连接调优

## 2.1 关闭密钥检测

SSH登录远程主机时默认将检查远程主机的公钥，且将之记录于~/.ssh/known_hosts文件，以便于下次访问时OpenSSH进行核对，若如果公钥不同，则将发出警告，将Ansible配置文件的StrictHostKeyChecking参数设为False即可关闭该功能，以提高运行效率

## 2.2 SSH pipelining加速

Ansible基于兼容sudo配置的考虑，默认关闭SSH的pipelining功能，若不适用sudo可考虑开启该功能，以减少SSH在被控主机上执行任务的连接数，从而加快SSH连接的速度


    pipelining = True

## 2.3 SSH长连接

Openssh自5.6版本之后支持多路复用功能，即持久化的Socket，一次验证多次通信，以节省SSH连接每次验证和创建的时间，Ansible执行速度得以明显提高

    vi /etc/ansible/ansible.cfg

    
    # ControlPersist，表示
    ssh_args = -C -o ControlMaster=auto -o ControlPersist=10d

# 3.Ansible Facts缓存调优

## 3.1 关闭Facts收集

Palybook文件直接配置

    gather_facts: no

## 3.2 配置Redis缓存Facts

Ansible默认将Facts信息写入内存，若被控主机数量庞大，该过程将会耗费大量时间，可将之写入到Redis以便随时取用

### 3.2.1 安装Redis

### 3.2.2 安装Redis模块

    sudo pip install redis==3.4.1

### 3.2.3 配置Redis缓存


    vi /etc/ansible/ansible.cfg


    [defaults]

    
    gathering = smart
    fact_caching = redis
    # 设置缓存时长，单位为秒
    fact_caching_timeout = 86400
    # 设置Redis连接，格式为：IP:端口号:数据库:连接密码
    fact_caching_connection = localhost:6379:6


---------

# 参考文档

- https://www.cnblogs.com/fengyuanfei/p/13826469.html
- https://blog.csdn.net/kakaops_qing/article/details/109551250
- https://blog.csdn.net/weixin_40228200/article/details/123603649