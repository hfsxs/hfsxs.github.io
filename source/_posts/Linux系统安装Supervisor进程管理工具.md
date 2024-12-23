---
title: Linux系统安装Supervisor进程管理工具
categories:
  - 工作
tags:
  - Linux
  - Supervisor
  - 云计算
date: 2020-02-07 09:30:10
---

Supervisor，Python开发的通用的C/S架构的进程管理系统，用于启动、停止、重启、监听一个或多个进程，异常退出时自动重启，实现集中式精确管理Linux服务器运行的的大量进程

# 1.安装python

    sudo yum install -y python

# 2.安装supervisor

    # sudo yum install -y python-setuptools && easy_install supervisor
    tar -xzvf supervisor-3.3.5.tar.gz
    cd supervisor-3.3.5

    sudo python setup.py install

# 3.创建supervisor主配置文件

    sudo mkdir -p /etc/supervisor/conf.d /var/log/supervisor /var/run/supervisor
    sudo echo_supervisord_conf > /etc/supervisor/supervisord.conf

# 4.supervisor主配置文件的修改

    sudo vi /etc/supervisor/supervisord.conf


    [unix_http_server]
    file=/var/run/supervisor/supervisor.sock ;

    [supervisord]
    logfile=/var/log/supervisor/supervisord.log ;
    pidfile=/var/run/supervisor/supervisord.pid ;

    [supervisorctl]
    serverurl=unix:///var/run/supervisor/supervisor.sock ;

    [include]
    files=/etc/supervisor/conf.d/*.conf

# 5.创建elasticsearch的supervisor管理配置文件

    sudo vi /etc/supervisor/conf.d/nginx.conf


    [program:elasticsearch]
    # 设置进程运行用户
    user=sword
    # 设置进程启动路径
    command=/home/sword/elasticsearch/bin/elasticsearch
    # 设置进程数
    numprocs=1
    # 设置进程是否随supervisord的启动而启动
    autostart=false
    # 设置进程是否随supervisord的重启而重启
    autorestart=false
    # 设置进程启动失败后最大重试次数
    startretries=3
    # 设置进程权重，即启动优先级，默认999，数值越小优先级越高
    priority=1
    # 设置进程启动后确认其为启动正常的时间
    startsecs=3

    # 设置进程启动日志文件路径
    stdout_logfile = /var/log/supervisor/elasticsearch.log
    # 设置进程启动错误日志文件路径
    stderr_logfile = /var/log/supervisor/elasticsearch-error.log

# 6.创建supervisor启动脚本

    sudo vi /lib/systemd/system/supervisord.service


    [Unit]
    Description=Process Monitoring and Control Daemon
    After=rc-local.service nss-user-lookup.target

    [Service]
    Type=forking
    ExecStart=/usr/bin/supervisord -c   /etc/supervisor/supervisord.conf
    ExecStop=/usr/bin/supervisord shutdown
    ExecReload=/usr/bin/supervisord reload
    killMode=process
    Restart=on-failure
    RestartSec=42s

    [Install]
    WantedBy=multi-user.target

# 7.启动supervisor，测试supervisor的监控及管理功能

    sudo systemctl daemon-reload
    sudo systemctl start supervisord.servic
    sudo systemctl enable supervisord.servic

# 8.启动elasticsearch，测试supervisor的监控及管理功能

    sudo supervisorctl status
    sudo supervisorctl start elasticsearch

---------

# 参考文档

- https://www.cnblogs.com/binglansky/p/9246780.html
- https://www.cnblogs.com/toutou/p/supervisor.html#_label1