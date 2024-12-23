---
title: Linux系统部署Spug自动化运维平台
categories:
  - 工作
tags:
  - Linux
  - 自动化运维
  - 云计算
date: 2024-06-21 10:21:54
---

Spug，基于Python和JavaScript开发的轻量级无Agent的开源自动化运维管理平台，适用于中小型企业，UI基于Ant Design设计，整合了主机管理、主机批量执行、主机在线终端、应用发布部署、在线任务计划、配置中心及监控告警等一系列功能，且二次开发很方便，是一套十分全面的运维解决方案

# 1.安装MySQL、Redis

# 2.安装Spug

    sudo docker pull registry.aliyuncs.com/openspug/spug
    sudo docker tag registry.aliyuncs.com/openspug/spug spug

# 3.启动Spug

    sudo sudo docker run -d -it --name=spug -p 80:80 -v /web:/data spug

# 4.创建数据库

    sudo mysql -uroot -p
    Enter password: 
    Welcome to the MariaDB monitor.  Commands end with ; or \g.
    Your MariaDB connection id is 376
    Server version: 10.5.6-MariaDB MariaDB Server

    Copyright (c) 2000, 2018, Oracle, MariaDB Corporation Ab and others.

    Type 'help;' or '\h' for help. Type '\c' to clear the current input statement.

    MariaDB [(none)]> create database spug character set utf8mb4;
    MariaDB [(none)]> GRANT ALL PRIVILEGES ON spug.* TO 'spug'@'%' IDENTIFIED BY 'spug';
    MariaDB [(none)]> flush privileges;

# 5.创建配置文件

    sudo vi /web/spug/spug_api/spug/overrides.py


    DEBUG = False
    ALLOWED_HOSTS = ['127.0.0.1']
    SECRET_KEY = 'gyseWUT@ib45%PAbfE6ZZ@sX%2i.8z!pcNh5KpI7.Uu98ed84G'

    DATABASES = {
        'default': {
            'ATOMIC_REQUESTS': True,
            'ENGINE': 'django.db.backends.mysql',
            'NAME': 'spug',
            'USER': 'spug',
            'PASSWORD': 'spug',
            'HOST': '192.168.100.100',
            'OPTIONS': {
                'charset': 'utf8mb4',
                'sql_mode': 'STRICT_TRANS_TABLES',
            }
        }
    }

    CACHES = {
        "default": {
            "BACKEND": "django_redis.cache.RedisCache",
            "LOCATION": "redis://:redis@192.168.100.100:6379/3",
            "OPTIONS": {
                "CLIENT_CLASS": "django_redis.client.DefaultClient",
            }
        }
    }

    CHANNEL_LAYERS = {
        "default": {
            "BACKEND": "channels_redis.core.RedisChannelLayer",
            "CONFIG": {
                "hosts": ["redis://:redis@192.168.100.100:6379/3"],
            },
        },
    }

# 6.配置容器启动参数

    sudo docker exec -it spug /bin/bash
    [root@64c97dea4c11 /]# cp /etc/supervisord.d/spug.ini /etc/supervisord.d/.spug.ini
    [root@64c97dea4c11 /]# vi /etc/supervisord.d/spug.ini


    # 删除如下内容
    [program:mariadb]
    command = /usr/libexec/mysqld --user=mysql
    autostart = true
    [program:redis]
    command = /usr/bin/redis-server
    autostart = true

# 7.重启spug

    sudo docker restart spug

# 8.创建管理员账户

    sudo docker exec spug init_spug admin spug.cc

- 注：管理员账户为admin，密码为spug.cc

# 9.验证spug

http://ip

---------

# 参考文档

- https://spug.dev/docs/install-docker
- https://blog.csdn.net/ximenjianxue/article/details/122092843