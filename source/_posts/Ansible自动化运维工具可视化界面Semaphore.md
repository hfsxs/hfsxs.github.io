---
title: Ansible自动化运维工具可视化界面Semaphore
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2024-06-15 10:20:45
---

Semaphore，Ansible用于运行Playbook的响应式Web可视化工具，是由Go语言编写的开源项目，旨在为用户提供剧本管理和运行的直观的界面，简化其执行过程，并将之打造为简洁而高质量的代码库。此外，Semaphore还允许用户根据需求进行定制与扩展，以适应特定的环境和工作流程，文档与社区支持十分丰富

# 1.下载安装包

    sudo mkdir -p /usr/local/semaphore && cd /usr/local/semaphore
    wget https://github.com/semaphoreui/semaphore/releases/download/v2.9.112/semaphore_2.9.112_linux_amd64.tar.gz
    tar -xzvf semaphore_2.9.112_linux_amd64.tar.gz

# 2.安装MySQL数据库

# 3.安装Semaphore

    ./semaphore setup

    Hello! You will now be guided through a setup to:

    1. Set up configuration for a MySQL/MariaDB database
    2. Set up a path for your playbooks (auto-created)
    3. Run database Migrations
    4. Set up initial semaphore user & password

    What database to use:
       1 - MySQL
       2 - BoltDB
       3 - PostgreSQL
    (default 1): 1

    db Hostname (default 127.0.0.1:3306): 

    db User (default root): 

    db Password: 123456

    db Name (default semaphore): 

    Playbook path (default /tmp/semaphore): /usr/local/semaphore/playbooks 

    Public URL (optional, example: https://example.com/semaphore): 

    Enable email alerts? (yes/no) (default no): 

    Enable telegram alerts? (yes/no) (default no): 

    Enable slack alerts? (yes/no) (default no): 

    Enable Rocket.Chat alerts? (yes/no) (default no): 

    Enable Microsoft Team Channel alerts? (yes/no) (default no): 

    Enable LDAP authentication? (yes/no) (default no): 

    Config output directory (default /usr/local/semaphore): 

    Running: mkdir -p /usr/local/semaphore..
    Configuration written to /usr/local/semaphore/config.json..
    Loading config
    Validating config

# 4.创建启动脚本

    sudo vi /lib/systemd/system/semaphore.service


    [Unit]
    Description=Semaphore Ansible
    Documentation=https://github.com/semaphoreui/semaphore
    Wants=network-online.target
    After=network-online.target

    [Service]
    Type=simple
    ExecReload=/bin/kill -HUP $MAINPID
    ExecStart=/usr/local/semaphore/semaphore server --config=/usr/local/semaphore/config.json
    SyslogIdentifier=semaphore
    Restart=always
    RestartSec=10s

    [Install]
    WantedBy=multi-user.target

# 5.启动Semaphore

    sudo systemctl daemon-reload
    sudo systemctl start semaphore.service
    sudo systemctl enable semaphore.service

# 6.访问Semaphore

http://ip:3000


---------

# 参考文档

- https://docs.semui.co/administration-guide/installation
- https://blog.csdn.net/weixin_73545275/article/details/134948388