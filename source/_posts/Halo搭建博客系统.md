---
title: Halo搭建博客系统
categories:
  - 极客
tags:
  - Linux
  - Java
  - MySQL
  - 博客
  - 极客
date: 2020-02-18 22:54:27
---

Halo，由Java开发的现代的开源免费的轻量级博客系统，界面简洁美观，功能强大易用。Halo基于流行的Java框架Spring Boot进行后台开发，数据存储于关系数据库，如MySQL、PostgreSQL等，具备良好的稳定性和高性能。此外，Halo内置强大的Markdown编辑器让写作更为流畅，精美的主题与插件足以满足个性化需求，健全的权限管理和安全控制机制保障了数据的安全性，是专注于内容创作者的理想工具

# 1.配置Java环境

# 2.安装MySQL数据库

# 3.创建Halo数据库

    sudo mysql -uroot -p
    Enter password: 
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 206076
    Server version: 10.5.6-MariaDB-log MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> create database halo character set utf8 collate utf8_bin;
    Query OK, 1 row affected (0.002 sec)
    MariaDB [(none)]> GRANT ALL PRIVILEGES ON halo.* TO 'halo'@'%' IDENTIFIED BY 'halo';
    Query OK, 0 rows affected (0.156 sec)
    MariaDB [(none)]> flush privileges;
    Query OK, 0 rows affected (0.080 sec)

# 4.安装Halo

    wget https://dl.halo.run/release/halo-1.6.1.jar
    mv halo-1.6.1.jar /web/halo.jar

# 5.创建配置文件

    cd ~ && mkdir .halo
    vi .halo/application.yaml


    server:
      port: 8090
      # Response data gzip.
      compression:
        enabled: true
    
    spring:
      datasource:
        # MySQL database configuration.
        driver-class-name: com.mysql.cj.jdbc.Driver
        url: jdbc:mysql://127.0.0.1:3306/halo?characterEncoding=utf8&useSSL=false&serverTimezone=Asia/Shanghai&allowPublicKeyRetrieval=true
        username: halo
        password: halo
      redis:
        # Redis cache configuration.
        port: 6379
        database: 1
        host: 127.0.0.1
        # password: 123456

    halo:
      # Your admin client path is https://your-domain/{admin-path}
      admin-path: admin

      # memory or level or redis
      cache: redis

# 6.创建启动脚本

    sudo vi /lib/systemd/system/halo.service


    [Unit]
    Description=Halo Service
    Documentation=https://halo.run
    After=network-online.target
    Wants=network-online.target

    [Service]
    User=sword
    Type=simple
    ExecStart=/usr/bin/java -server -Xms256m -Xmx256m -jar /web/halo.jar 
    ExecStop=/bin/kill -s QUIT $MAINPID
    Restart=always
    StandOutput=syslog
    StandError=inherit

    [Install]
    WantedBy=multi-user.target

# 7.启动Halo

    sudo systemctl daemon-reload
    sudo systemctl start halo.service
    sudo systemctl enable halo.service

# 8.配置Nginx反向代理

    vi /etc/nginx/conf.d/halo.conf


    server {

        listen       80;
        server_name  localhost;

        charset utf-8;

        location / {

            access_log  /var/log/nginx/halo_access.log  main;
            error_log  /var/log/nginx/halo_error.log;

            proxy_pass http://127.0.0.1:8090;

        }
    }

# 9.访问Halo

---------

# 参考文档

- https://docs.halo.run