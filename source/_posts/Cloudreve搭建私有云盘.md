---
title: Cloudreve搭建私有云盘
categories:
  - 极客
tags:
  - Linux
  - Cloudreve
  - 云存储
  - 极客
date: 2021-02-20 15:10:29
---

Cloudreve，由go语言开发的开源免费的网盘系统，用于快速搭建公私兼备的网盘，支持本地服务器、远程服务器、OneDrive、七牛云存储、阿里云OSS、又拍云、Amazon S3等作为存储后端，所存储的图片、视频、音频、Office文档支持在线预览，对于文本文件、Markdown文件支持在线编辑

Cloudreve是NAS方案的替代，本地服务器接上机械盘可用作家庭私有云存储，搭配aria2离线下载服务器直接可转换为在线视频网站。Cloudreve相比于Nextcloud的优点在于速度快，较为轻量，不像后者那么臃肿，但缺点是没有APP，没有文件自动同步的功能，上传大量文件不是很友好，因为设备锁屏后网络断掉会导致上传失败

---------

# 1.下载程序包

    mkdir /web/cloudreve && cd /web/cloudreve
    wget https://github.com/cloudreve/Cloudreve/releases/download/3.2.1/cloudreve_3.2.1_linux_amd64.tar.gz .

# 2.创建配置文件

    vi conf.ini


    [System]
    Mode = master
    Listen = :5212
	ProxyHeader = X-Forwarded-For

    [Database]
    Type = mysql
    Port = 3306
    User = cloudreve
    Password = cloudreve
    Host = 127.0.0.1
    Name = cloudreve
	Charset = utf8mb4
    TablePrefix = sword_

    [Redis]
    Server = 127.0.0.1:6379
    Password = redis
    DB = 1

# 3.创建数据库

	MariaDB [(none)]> create database cloudreve character set utf8mb4;  
	Query OK, 1 row affected (0.016 sec)

	MariaDB [(none)]> GRANT ALL PRIVILEGES ON cloudreve.* TO 'cloudreve'@'127.0.0.1' IDENTIFIED BY 'cloudreve'; 
	Query OK, 0 rows affected (0.023 sec)

	MariaDB [(none)]> flush privileges;
	Query OK, 0 rows affected (0.010 sec)

# 4.安装redis

# 5.启动cloudreve

	tar -xzvf cloudreve_3.2.1_linux_amd64.tar.gz
	chmod +x cloudreve
	/web/cloudreve/cloudreve -c /web/cloudreve/conf.ini

	\_ \_ \_ / \\ | \_ \_ \_ | |\_ \_ \_  
	/ / | |/ \_ | | | |/ \_ | ‘/ \_ \\ \\ / / \_ \\  
	/ /| | () | || | (| | | | /\\ V / /  
	_/||\_\_\_/ \_\_,|_,|| **\_| \_/ \_**|

	V3.3.1 Commit #a1252c8 Pro=false
	[Info] 2021-02-20 15:09:46 初始化数据库连接
	[Info] 2021-02-20 15:09:46 开始进行数据库初始化…
	[Info] 2021-02-20 15:09:47 初始管理员账号：admin@cloudreve.org
	[Info] 2021-02-20 15:09:47 初始管理员密码：yXoWFk7p
	[Info] 2021-02-20 15:09:50 数据库初始化结束
	[Info] 2021-02-20 15:09:50 初始化任务队列，WorkerNum = 10
	[Info] 2021-02-20 15:09:50 初始化定时任务…
	[Info] 2021-02-20 15:09:50 当前运行模式：Master
	[Info] 2021-02-20 15:09:50 开始监听 :5212

---------

- 注：首次启动cloudreve会随机生成管理密码，登录系统后再行修改

# 6.创建启动脚本

    sudo vi /lib/systemd/system/cloudreve.service


	[Unit]
	Description=Cloudreve
	Documentation=https://docs.cloudreve.org
	After=network.target
	Wants=network.target
	After=mysqld.service

	[Service]
	User=sword
	WorkingDirectory=/web/cloudreve
	ExecStart=/web/cloudreve/cloudreve -c /web/cloudreve/conf.ini
	Restart=on-abnormal
	RestartSec=5s
	KillMode=mixed
	StandardOutput=null
	StandardError=syslog

	[Install]
	WantedBy=multi-user.target

# 7.启动cloudreve

	sudo systemctl daemon-reload
	sudo systemctl enable cloudreve.service
	sudo systemctl start cloudreve.service

# 8.配置nginx反向代理

    sudo vi /etc/nginx/conf.d/cloudreve.conf


    server {

      listen       80;
      server_name  localhost;

      location / {

      access_log  /var/log/nginx/cloudreve_access.log  main;
      error_log  /var/log/nginx/cloudreve_error.log;

      }
    }

# 9.登录cloudreve，重置管理员密码

---------

# 参考文档

- https://docs.cloudreve.org