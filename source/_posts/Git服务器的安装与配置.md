---
title: Git服务器的安装与配置
categories:
  - 工作
tags:
  - Linux
  - Git
  - CICD
  - DevOps
  - 云计算
date: 2021-12-27 10:26:02
---

Gitea，由Go语言开发的轻量级开源DevOps平台系统，安装部署简易，高性能低资耗，旨在为个人、小型团队和企业提供简单、快速、安全的代码自托管解决方案。Gitea发源于Gogs，功能强大，从开发计划到产品成型的整个软件生命周期都能够高效而轻松地进行支持，如Git托管、代码审查、团队协作、软件包注册和CI/CD，此外还具有UI界面、权限管理、团队协作等功能，其开源社区也非常活跃

# 1.下载安装包

     curl -o gitea-1.20.6-linux-amd64.xz https://dl.gitea.com/gitea/1.20.6/gitea-1.20.6-linux-amd64.xz

# 2.安装Gitea

     xz -d gitea-1.20.6-linux-amd64.xz
     sudo mkdir -p /usr/local/gitea/{etc,data,logs}
     sudo mv gitea-1.20.6-linux-amd64 /usr/local/gitea/bin/gitea
     sudo chmod +x /usr/local/bin/gitea && sudo chown -R sword.sword /usr/local/gitea

# 3.创建数据库

    MariaDB [(none)]> CREATE DATABASE gitea CHARACTER SET 'utf8mb4' COLLATE 'utf8mb4_bin';
    MariaDB [(none)]> GRANT ALL PRIVILEGES ON gitea.* TO 'gitea'@'%';
    MariaDB [(none)]> FLUSH PRIVILEGES;

# 4.创建启动脚本

    sudo vi /lib/systemd/system/gitea.service


    [Unit]
    Description=Gitea (Git with a cup of tea)
    After=network.target

    [Service]
    RestartSec=2s
    Type=simple
    User=sword
    Group=sword
    WorkingDirectory=/var/lib/gitea/
    ExecStart=/usr/local/gitea/bin/gitea web --config /usr/local/gitea/etc/app.ini
    Restart=always

    [Install]
    WantedBy=multi-user.target

# 5.启动Gitea

    sudo systemctl daemon-reload
    sudo systemctl start gitea.service
    sudo systemctl enable gitea.service

# 6.访问Gitea

http://ip:3000

---------

# 参考文档

- https://hongzx.cn/home/blogShow/204
- https://docs.gitea.com/installation/install-from-binary