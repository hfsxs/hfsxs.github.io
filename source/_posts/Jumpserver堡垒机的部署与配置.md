---
title: Jumpserver堡垒机的部署与配置
categories:
  - 工作
tags:
  - Linux
  - 堡垒机
  - 云计算
date: 2024-08-18 15:05:32
---

JumpServer，由Python/Django开发的分布式开源堡垒机系统，是符合4A规范的专业运维安全审计系统，用于完成认证、授权、审计、自动化等运维工作，现已支持管理SSH、 Telnet、RDP、VNC等协议资产、MySQL/Redis/MongoDB等数据库资产及Kubernetes集群云资产等等。JumpServer配备了业界领先的Web Terminal，交互界面美观而简洁。此外，JumpServer还支持多机房跨区域部署，即中心节点提供API，各机房部署登录节点，可方便的横向扩展，无并发访问限制

# 1.下载离线安装包

    tar -xzvf jumpserver-offline-installer-v3.10.12-amd64.tar.gz
    mv jumpserver-offline-installer-v3.10.12-amd64 /opt/jumpserver

# 2.安装MySQL、Redis

# 3.创建数据库

    MariaDB [(none)]> CREATE DATABASE jumpserver CHARACTER SET 'utf8mb4';
    MariaDB [(none)]> GRANT ALL PRIVILEGES ON jumpserver.* TO 'jumpserver'@'%' IDENTIFIED BY 'jumpserver'; 
    MariaDB [(none)]> FLUSH PRIVILEGES;

# 4.安装Jumpserver

    















---------

# 参考文档

- https://docs.jumpserver.org/zh/v3