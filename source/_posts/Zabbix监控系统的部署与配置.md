---
title: Zabbix监控系统的部署与配置
categories:
  - 工作
tags:
  - Linux
  - Zabbix
  - 监控告警
  - 云计算
date: 2020-02-02 18:09:31
---

Zabbix，由C语言开发的开源分布式企业级监控系统，通过Agent方式采集服务器、应用程序、网络服务、数据库、网站及其他网络硬件的工作状态，最终将监控数据写入数据库。Zabbix具备分布式监控功能，支持复杂架构下的监控解决方案，还提供直观的web页面展现。Zabbix告警通知机制也比较灵活，如邮件、短信和其他报警方式，以便于快速定位、解决各种故障，从而保障业务统的安全与稳定

# 体系架构

Zabbix是典型的C/S架构，Zabbix Server作为服务端通过Zabbix Agent或SNMP协议等方式，定期收集被监控端的监控数据并其存储到数据库，最后通过前端UI做展示

## 1.Zabbix Server

Zabbix Server，Zabbix监控服务端，核心部分，负责监控数据的采集、计算及存储，并依据监控指标所设置的触发器阈值生成告警信息，进而完成告警动作，如发送告警信息（邮件、微信、短信及钉钉等）、运行命令（如shell命令、reboot、restart、install等），以进行故障处理或通知

## 2.Zabbix Agent

Zabbix Agent，部署于被监控端，收集本地资源和应用程序的状态，并将收集到的数据发送给Zabbix Server

## 3.Zabbix Proxy

Zabbix Proxy，可选组件，用于分流Zabbix Server的负载，类似于中转站，将收集到的数据转发给Zabbix Server，实现整个监控系统分布式的架构

## 4.数据库

Zabbix配置信息及监控数据的后端存储，支持MySQL、Oracle等主流数据库，官方推荐MySQL

## 5.UI

前端Web界面，根据收集到的数据进行展示和绘图，属于Zabbix Server，可部署于同一服务器

# 功能组件

## 1.zabbix_server

Zabbix服务端守护进程，接收其余组件采集到的监控数据，如zabbix_agent、zabbix_get、zabbix_sender、zabbix_proxy、Zabbix_ java_ gateway等

## 2.zabbix_agentd

Zabbix客户端守护进程，负责收集客户端数据，如CPU 负载、内存、硬盘使用情况等

## 3.zabbix_proxy

Zabbix分布式架构代理守护进程，通常监控设备大于500时需要进行分布式监控架构部署

## 4.zabbix_get

Zabbix数据接收工具，单独使用的命令，通常在server或proxy端执行获取远程客户端信息的命令

## 5.zabbix_sender

Zabbix数据发送工具，发送数据给server或proxy端，通常用于耗时比较长的检查

## 6.zabbix_java_gataway

java网关，专用于java的agentd，只能主动取获取数据，而不能被动获取

# 监控指标

## 1.操作系统状态

例如CPU使用率、内存使用率、磁盘空间等。Zabbix agent还可以执行命令并返回结果，用于更复杂的监控需求。使用Zabbix agent进行监控的好处是它可以提供更详细和精确的数据，并且对于网络环境有更好的适应性

## 2.服务器硬件状态

IPMI:智能平台管理接口（Intelligent Platform Management Interface）IPMI 能够横跨不同的操作系统、固件和硬件平台，用于监控服务器硬件的状态和性能。Zabbix可以通过IPMI协议直接与服务器进行通信，获取硬件相关的信息，例如温度、风扇转速、电源状态等

## 3.应用程序状态

## 4.Web网站状态

## 5.网络硬件设备状态


SNMP：网络管理协议（Simple Network Management Protocol）是专门设计用于在 IP 网络管理网络节点（服务器、工作站、路由器、交换机等）的一种标准协议，它是一种应用层协议。通过SNMP协议，Zabbix可以获取网络设备的各种信息，例如接口流量、端口状态等

## 6.Java程序状态

JMX（Java Management Extensions）：JMX是一种Java平台的管理和监控标准。Zabbix可以通过JMX协议与Java应用程序进行通信，获取应用程序运行状态的信息，例如堆内存使用情况、线程数、GC时间等。JMX适用于监控Java应用程序的性能和健康状态，对于Java开发人员和运维人员非常有用


# 核心概念

## 1.主机 

host，主机，被监控的网络设备，以IP或域名表示

## 2.主机组
host group，主机组，逻辑概念，包含主机和模板，一个主机组的主机和模板之间并没有任何直接的关联。通常在给不同用户组的主机分配权限时候使用主机组

## 3.监控项

item，监控项，即监控指标，通常是度量数据

## 4.触发器

trigger，触发器，用于定义监控指标阈值和评估监控项接收到的数据的逻辑表达式 当接收到的数据高于阈值时，触发器从“OK”变成“Problem”状态。当接收到的数据低于阈值时，触发器保留/返回一个“OK”的状态。

5、动作 (action)
一个对事件做出反应的预定义的操作。 一个动作由操作(例如发出通知)和条件(当时操作正在发生)组成

6、媒介 (media)
发送告警通知的手段；告警通知的途径

7、远程命令 (remote command)
一个预定义好的，满足一些条件的情况下，可以在被监控主机上自动执行的命令

8、模版 (template)
一组可以被应用到一个或多个主机上的实体（监控项，触发器，图形，应用，Web场景等）的集合 模版的任务就是加快对主机监控任务的实施；也可以使监控任务的批量修改更简单。模版是直接关联到每台单独的主机上。

9、web 场景 (web scenario)
利用一个或多个HTTP请求来检查网站的可用性

---------

# 1.安装依赖包

    apt install -y gcc libsnmp-dev libevent-dev libxml2-dev libghc-curl-dev
    yum instal -y gcc make curl-devel net-snmp-devel libcurl libxml2-devel

# 2.安装Nginx、PHP、MySQL

## 2.1 配置数据库

### 2.1.1 创建zabbix数据库，并授予权限

    MariaDB [(none)]> create database zabbix charset utf8 collate utf8_bin;"
    MariaDB [(none)]> GRANT ALL PRIVILEGES ON zabbix.* TO 'zabbix'@'localhost' IDENTIFIED BY 'zabbix';
    MariaDB [(none)]> flush privileges;"

### 2.1.2 导入zabbix表结构

    MariaDB [(none)]> source database/mysql/schema.sql;
    MariaDB [(none)]> source database/mysql/images.sql;
    MariaDB [(none)]> source database/mysql/data.sql;

# 3.创建zabbix用户与组

    groupadd zabbix && useradd -g zabbix -s /sbin/nologin zabbix
    mkdir -p /var/log/zabbix && chown -R zabbix:zabbix /var/log/zabbix

# 4.编译安装zabbix server

    tar -zxvf zabbix-6.0.18.tar.gz && cd zabbix-6.0.18
    ./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix \
    --enable-server --enable-agent --enable-proxy --with-net-snmp --enable-ipv6 \
    --with-libcurl --with-libxml2 --with-mysql=/usr/local/mysql/bin/mysql_config
    make && make install

# 5.创建配置文件

    vi /etc/zabbix/zabbix_server.conf


    LogFile=/var/log/zabbix/zabbix_server.log
    PidFile=/var/log/zabbix/zabbix_server.pid
    DBHost=127.0.0.1
    DBName=zabbix
    DBUser=zabbix
    DBPassword=zabbix

### 1.5.2 创建zabbix agent配置文件

    vi /etc/zabbix/zabbix_agentd.conf


    PidFile=/var/log/zabbix/zabbix_agentd.pid
    LogFile=/var/log/zabbix/zabbix_agentd.log
    Server=127.0.0.1
    ServerActive=127.0.0.1
    Hostname=Zabbix server

# 6.创建启动脚本

# 7.配置监控web可视化

## 7.1 创建nginx配置文件

    vi /etc/nginx/conf.d/zabbix.conf


    server {

        listen       80;
        server_name  localhost;    
        location /zabbix {

            root   /web;
            index  index.html index.htm index.php;
            charset utf-8;

            access_log  /var/log/nginx/zabbix_access.log main;
            error_log  /var/log/nginx/zabbix_error.log;

            location ~* \.php$ {

            root           /web;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME $document_root$fastcgi_script_name;
            include        /etc/nginx/fastcgi_params;
            }
        }
    }

## 7.2 创建UI

    cp -r ui /web/zabbix

# 8.启动Zabbix server、Zabbix agent、nginx、php

# 9.验证

# 2.部署Zabbix agent

## 2.1 安装依赖包

    apt install -y gcc libsnmp-dev libevent-dev libxml2-dev libghc-curl-dev
    yum instal -y gcc make curl-devel net-snmp-devel libcurl libxml2-devel

## 2.2 创建zabbix用户与组

    groupadd zabbix && useradd -g zabbix -s /sbin/nologin zabbix

## 2.3 编译安装zabbix server

    tar -zxvf zabbix-6.0.18.tar.gz && cd zabbix-6.0.18
    ./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix \
    --enable-agent --with-net-snmp --enable-ipv6 \
    --with-libcurl --with-libxml2
    make && make install

## 2.4 修改zabbix_server配置文件

    vi /etc/zabbix/zabbix_agentd.conf


    PidFile=/var/log/zabbix/zabbix_agentd.pid
    LogFile=/var/log/zabbix/zabbix_agentd.log
    Server=172.16.100.100
    ServerActive=172.16.100.100
    Hostname=node02

---------

# 参考文档

- https://blog.csdn.net/m0_54563444/article/details/141207533