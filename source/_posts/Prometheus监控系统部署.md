---
title: Prometheus监控系统部署
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - 监控告警
  - 云计算
date: 2023-02-01 09:42:31
---

Prometheus是基于Go语言构建的由SoundCloud开发的开源监控告警系统，基本原理是通过HTTP协议周期性拉取被监控组件的状态，任意组件只要提供对应的HTTP接口即可接入，而不再需要任何SDK或其他集成过程

# 系统架构

## 1.Prometheus

prometheus server，Prometheus监控系统的核心部分，负责实现监控数据的收集、存储及数据查询

## 2.Exporters

exporter，即监控数据采集端，通过http服务的形式保留一个url地址，prometheus server周期性地访问exporter提供的endpoint端点，以获取需要采集的监控数据，可分为两大类：

- 直接采集，直接内置了对Prometheus监控的支持，如cAdvisor,Kubernetes等
- 间接采集，原有监控目标不支持prometheus，需要通过prometheus提供的客户端库编写监控采集程序，如Mysql Exporter、JMX Exporter等

## 3.AlertManager

告警管理，处理prometheus基于PromQL创建的告警规则所生成的告警信息，可集成邮件、Slack或webhook自定义报警

## 4.PushGateway

推送服务，用于被监控端无法直接提供http形式的exporter，将内部网络数据主动push到gateway，prometheus再从中将监控数据以pull方式拉取过来

## 5.Web UI

Prometheus系统内置的简单Web控制台，用于查询指标、查看配置信息或Service Discovery等，比较简陋，通常是配合Grafana展示监控指标

# 工作流程

## 1.拉取监控数据

Prometheus server定期从配置好的jobs或者exporters中拉取metrics，或从push gateway拉取metrics，当然也可从其他Prometheus server拉取metrics

## 2.存储监控数据

Prometheus server在本地存储收集到的metrics，并运行定义好的alert.rules，通过一定规则进行清理和整理数据，并把得到的结果存储到新的时间序列中，同时向Alertmanager推送警报

## 3.可视化监控数据

Prometheus通过PromQL和其他可视化的展现收集的数据，支持很多方式的图表可视化，如Grafana、自带的Promdash以及自身提供的模板引擎等。Promenade还提供HTTP API的查询方式，自定义所需要的输出

# 监控指标

## 1.服务器监控

### 1.1 CPU

CPU整体使用量、用户态百分比、内核态百分比，以及单个CPU的使用量、等待队列长度、I/O等待百分比、CPU消耗最多的进程、上下文切换次数、缓存命中率等

### 1.2 内存

内存整体使用量、剩余量、内存占用最高的进程、交换分区大小、缺页异常等

### 1.3 网络I/O

单个网卡的上行流量、下行流量、网络延迟、丢包率等

### 1.4 磁盘 I/O

硬盘读写速率、IOPS、磁盘用量、读写延迟等

## 2.网络监控

### 2.1 网络性能监控

网络监测、网络实时流量监控（网络延迟、访问量、成功率）、历史数据统计、汇总和历史数据分析等指标

### 2.2 网络检测

网络攻击，如DDoS攻击，通过分析异常流量来确定网络攻击行为

### 2.3 设备监控

数据中心内的多种网络设备监控，如路由器、防火墙和交换机等硬件设备，通过snmp协议收集监控数据

##  3.存储监控

### 3.1 块存储

存储块的读写速率、IOPS、读写延迟，磁盘用量等

### 3.2 文件存储

文件存储的文件系统inode、读写速度、目录权限等

### 3.3 分布式存储

分布式系统监控，不同的存储系统有不同的指标，如ceph的OSD、MON运行状态，各种状态pg的数量及集群IOPS信息等

### 3.4 存储设备

对于构建在x86服务器上的存储设备，设备监控通过每个存储节点上的采集器统一收集磁盘、SSD、网卡等设备信息。存储厂商通常以黑盒方式提供商业存储设备，自带监控功能，可监控设备的运行状态，性能和容量

## 4.中间件监控

### 4.1 消息中间件

RabbitMQ、Kafka等

### 4.2 Web服务中间件

Tomcat、Jetty等

### 4.3 缓存中间件

Redis、Memcached等

### 4.4 数据库中间件

MySQL、PostgreSQL等

## 5.应用程序监控

APM主要是针对应用程序的监控，包括应用程序的运行状态监控，性能监控，日志监控及调用链跟踪等。调用链跟踪是指追踪整个请求过程（从用户发送请求，通常指浏览器或者应用客户端）到后端API服务以及API服务和关联的中间件，或者其他组件之间的调用，构建出一个完整的调用拓扑结构，不仅如此，APM 还可以监控组件内部方法的调用层次（Controller–>service–>Dao）获取每个函数的执行耗时，从而为性能调优提供数据支撑

---------

# 1.下载安装包

    wget https://github.com/prometheus/prometheus/releases/download/v2.45.0/prometheus-2.45.0.linux-amd64.tar.gz
    wget https://github.com/prometheus/mysqld_exporter/releases/download/v0.15.0/mysqld_exporter-0.15.0.linux-amd64.tar.gz

# 2.安装Prometheus

    tar -xzvf prometheus-2.45.0.linux-amd64.tar.gz
    sudo mv prometheus-2.45.0.linux-amd64 /usr/local/prometheus
    sudo mkdir -p /usr/local/prometheus/data

# 3.创建启动脚本

    sudo vi /lib/systemd/system/prometheus.service 


    [Unit]
    Description=Prometheus Server
    Documentation=https://prometheus.io/
    After=network.target

    [Service]
    Type=simple
    User=root
    Group=root
    WorkingDirectory=/usr/local/prometheus
    ExecStart=/usr/local/prometheus/prometheus --web.listen-address=0.0.0.0:9090 --config.file=/usr/local/prometheus/prometheus.yml --web.enable-lifecycle
    ExecReload=/bin/kill -s HUP $MAINPID
    ExecStop=/bin/kill -s QUIT $MAINPID
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

# 4.启动Prometheus

    sudo systemctl daemon-reload
    sudo systemctl start prometheus.service
    sudo systemctl enable prometheus.service

# 5.验证Prometheus

    curl http://127.0.0.1:9090/metrics

# 6.部署grafana

## 6.1 安装grafana

    sudo docker run -it -d -p 3000:3000 --name grafana grafana

## 6.2 登录grafana，更改默认密码

- 登录网址：http://ip:3000
- 账户密码：admin/admin

![prometheus-001](/img/wiki/prometheus/prometheus-001.jpg)

## 6.3 配置Prometheus数据源

Configuration --- > Data Sources ---> Add data source ---> Prometheus

![prometheus-002](/img/wiki/prometheus/prometheus-002.jpg)

## 6.3 导入Prometheus监控大盘

![prometheus-003](/img/wiki/prometheus/prometheus-003.jpg)

## 6.4 验证grafana

![prometheus-004](/img/wiki/prometheus/prometheus-004.jpg)

---------

# 参考文档

- https://andyoung.blog.csdn.net/article/details/122040410
- https://blog.csdn.net/qq_43164571/article/details/112655017
- https://blog.csdn.net/weixin_43883625/article/details/129756413