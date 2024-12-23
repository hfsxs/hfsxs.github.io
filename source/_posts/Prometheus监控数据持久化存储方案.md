---
title: Prometheus监控数据持久化存储方案
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - 监控告警
  - 云原生
  - 云计算
date: 2024-04-09 10:20:12
---

Prometheus默认以tsdb时序数据库简单高效地将监控数据存储于本地，自2.0版本之后还将压缩数据的能力大大地提升（每个采样数据仅为3.5b左右），单节点即可满足大部分用户的监控需求。但本地存储也限制了其扩展性，带来了数据持久化等一系列问题。鉴于此，为解决单节点存储的限制，Prometheus提供了远程读写接口，用户可自行选择合适的时序数据库，如Influxdb、Thanos和VictoriaMetrics等等

# 时序数据

时序数据，即带有时间戳的数据，存储于时序数据库，目的是监测数据的前后差异，以便于做出相应的动作

## 数据特点

- 一旦被存储就不会被修改，即新增数据只会被添加到系统，不会在将来的某个时段被修改为其他的值
- 由于时序数据通常用于监测指标的变化趋势，所以最近产生的数据其重要性超过旧数据
- 数据量巨大，由于每隔一个时间段就会新增一批数据，数据增速非常快，如5000数据点每秒采集一次数据，一小时的数据量就将超过18,000,000条
- 往往是时间间隔越小差异性越小，如某地的温度，如秒级监控，差异将会很小

## 数据来源

### IOT

主要来源是传感器，如某点的温度、湿度、压力、电流、电压等

### 金融和科学数据

如交易时段的证券价格、地震监控数据等

### IT基础架构

即软硬件的监控数据

# 时序数据库

时序数据的数据量通常都非常巨大，由此也将带来许多问题

## 1.高速接收和存储数据

时序数据的数据点多，更新频率高，目前普遍使用LSM技术，而非B树来存储数据。LSM先在内存中积累数据然后再批量写入磁盘，而B树的优势在于读取而不是存储

## 2.压缩数据

目前大部分时序数据库采用Facebook提出的Gorilla算法，简单说就是存储数据的差异，因为时序数据有频率高差异小的特点。如果直接使用传统的关系数据库来存储时序数据会需要极高的存储成本，相比传统的关系数据库，时序数据库在存储时序数据上能做到只需要1/20甚至更低的存储空间需求

## 3.巨大数据量的快速查询

很多时序数据库是列数据库，列数据库具有更好的分析数据的性能

## 4.留存策略

时序数据库有相应的处理策略，如几年前和最近几个月的数据处理方式和留存策略需要做不同的处理

# 1.本地存储

Prometheus默认采用tsdb时序数据库，将监控数据存储在本地磁盘，默认存储时长为15天时间较短，且不支持跨集群的聚合

## 1.1 存储原理

Prometheus按每2小时一个Block进行存储，每个block由一个目录组成，该目录包含：一个或多个chunk文件，每个chunk默认大小为512M，用于保存两小时的时间序列数据，而最新写入的数据保存在内存block中，两小时后再写入chunk文件，且后台会将block压缩成更大的block，并合并成更高level的block文件后删除低level的block文件。通过这样时间窗口形式所保存的所有的样本数据明显提高了Prometheus的查询效率，即查询一段时间范围内的所有样本数据只需简单的从落在该范围内的块中查询数据即可；一个metadata文件；一个index文件，通过metric name和labels查找时间序列数据在chunk块文件的位置

为防止程序崩溃导致数据丢失，Prometheus采用WAL（write-ahead-log）机制，启动时以写入日志(WAL)的方式实现重播，从而恢复数据

删除数据时，删除条目会记录在独立的tombstone文件，而不是立即从chunk文件删除

## 1.2 磁盘大小计算

磁盘大小计算方式：磁盘大小 = 保留时间 * 每秒获取样本数 * 样本大小

保留时间(retention_time_seconds)和样本大小(bytes_per_sample)不变的情况下，如需减少本地磁盘的容量需求，只能通过减少每秒获取样本数(ingested_samples_per_second)的方式，因此有两种手段：即减少时间序列的数量，或是增加采集样本的时间间隔。由于Prometheus会对时间序列进行压缩，因此减少时间序列的数量效果更明显

## 1.3 内存占用

随着规模变大，Prometheus需要的CPU和内存都会升高，内存一般先达到瓶颈，这时要么加内存，要么集群分片减少单机指标。内存消耗主要由以下因素引起：

- Prometheus的内存消耗主要在于每2小时的Block数据落盘，落盘之前所有数据都在内存里面，因此和采集量有关
- 加载历史数据是从磁盘到内存，查询范围越大所占内存越大
- 一些不合理的查询条件也会加大内存，如Group或大范围Rate

## 1.4 数据存储方式

内存中的block数据未写入磁盘时，block目录下面主要保存wal文件:

    ./data/01BKGV7JBM69T2G1BGBGM6KB12
    ./data/01BKGV7JBM69T2G1BGBGM6KB12/meta.json
    ./data/01BKGV7JBM69T2G1BGBGM6KB12/wal/000002
    ./data/01BKGV7JBM69T2G1BGBGM6KB12/wal/000001

持久化的block目录下wal文件被删除，时序数据保存在chunk文件，index用于索引timeseries在wal文件里的位置：

    ./data/01BKGV7JC0RY8A6MACW02A2PJD
    ./data/01BKGV7JC0RY8A6MACW02A2PJD/meta.json
    ./data/01BKGV7JC0RY8A6MACW02A2PJD/index
    ./data/01BKGV7JC0RY8A6MACW02A2PJD/chunks
    ./data/01BKGV7JC0RY8A6MACW02A2PJD/chunks/000001
    ./data/01BKGV7JC0RY8A6MACW02A2PJD/tombstones

# 2.远程存储

2017年，Prometheus集成了Remote Read/Write API接口，支持将数据存储到远端和从远端读取数据的功能，也即是将数据通过接口保存到第三方存储服务。此后，社区涌现出大量长期存储的方案，如InfluxDB、Thanos、Grafana Cortex/Mimir、VictoriaMetrics、Wavefront、Splunk、Sysdig、SignalFx、Graphite等

## 2.1 工作机制

Prometheus将采集到的指标数据通过HTTP的形式发送给适配器(Adaptor)，再由适配器进行数据的存入；remote_read特性则会向适配器发起查询请求，适配器根据请求条件从第三方存储服务中获取响应的数据

### 2.1.1 Remote Write

Prometheus配置文件指定Remote Write(远程写)的URL地址，如指向influxdb，一旦设置了该配置项，Prometheus将样本数据通过HTTP的形式发送给适配器(Adaptor)，再由适配器对接任意的外部服务，如公有/私有云的存储服务，或消息队列等任意形式

### 2.1.2 Remote Read

Prometheus的查询请求由配置文件remote_read所指向的URL进行处理，Adaptor根据请求条件从第三方存储服务中获取响应的数据，同时将数据转换为Promethues的原始样本数据返回给Prometheus Server。之后，Promethues在本地使用PromQL对样本数据进行二次处理。即原始样本数据从远程存储获取，规则文件及Metadata API处理在本地完成

## 2.2 配置文件

    remote_write:
      - url: "http://localhost:9201/write"

    remote_read:
      - url: "http://localhost:9201/read"

## 2.3 方案选择

- InfluxDB，Go语言开发的开源时间序列数据库，行业标杆，最为流行，数据压缩能力极强
- VictoriaMetrics，最新技术，简单易用，但有些重要功能没开源，如Downsampling降采样功能，跨较长时间范围的聚合及查询耗时较久
- Thanos依赖对象存储，备份优势明显

# 3.InfluxDB

## 3.1 安装InfluxDB

    wget https://dl.influxdata.com/influxdb/releases/influxdb-1.8.10_linux_arm64.tar.gz
    tar -xzvf influxdb-1.8.10_linux_arm64.tar.gz && sudo mv influxdb-1.8.10-1 /usr/local/influxdb
    sudo mkdir -p /usr/local/influxdb/data/meta && sudo mkdir -p /usr/local/influxdb/data/wal

## 3.2 创建配置文件

    sudo vi /usr/local/influxdb/etc/influxdb.conf

    
    [meta]
      dir = "/usr/local/influxdb/data/meta"
    [data]
      dir = "/usr/local/influxdb/data"
      wal-dir = "/usr/local/influxdb/data/wal"

## 3.2 创建启动脚本

    sudo vi /lib/systemd/system/influxd.service


    [Unit]
    Description=influxd
    Documentation=https://docs.influxdata.com/influxdb/v1/install/?t=Linux
    After=network.target

    [Service]
    ExecStart=/usr/local/influxdb/usr/bin/influxd -config /usr/local/influxdb/etc/influxdb.conf
    Restart=on-failure
    RestartSec=20

    [Install]
    WantedBy=multi-user.target

## 3.3 启动InfluxDB

    sudo systemctl daemon-reload
    sudo systemctl start influxd.service
    sudo systemctl enable influxd.service

## 3.4 创建数据库

    /usr/local/influxdb/usr/bin/influx
    Connected to http://localhost:8086 version 1.8.10
    InfluxDB shell version: 1.8.10
    > create database prometheus;
    # 创建默认保留策略
    > CREATE RETENTION POLICY "prometheus" ON "prometheus" DURATION 1h REPLICATION 1 DEFAULT
    # 创建用户
    > CREATE USER prometheus WITH PASSWORD 'prometheus@2024'
    # 用户授权
    > GRANT ALL ON "prometheus" TO "prometheus"

## 3.5 配置Prometheus

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    remote_write:
      - url: "http://127.0.0.1:8086/api/v1/prom/write?db=prometheus&u=prometheus&p=prometheus@2024."
        remote_timeout: 30s
        queue_config:
          capacity: 100000
          max_shards: 1000
          max_samples_per_send: 1000
          batch_send_deadline: 5s
          min_backoff: 30ms
          max_backoff: 100ms
    remote_read:
      - url: "http://127.0.0.1:8086/api/v1/prom/read?db=prometheus&u=prometheus&p=prometheus@2024."
        remote_timeout: 10s
        read_recent: true

## 3.6 重启Prometheus

    sudo systemctl restart prometheus.service

## 3.7 验证InfluxDB数据

    /usr/local/influxdb/usr/bin/influx
    Connected to http://localhost:8086 version 1.8.10
    InfluxDB shell version: 1.8.10
    > use prometheus
    > show measurements
    > select * from go_info;

---------

# 参考文档

- https://www.cnblogs.com/liushiya/p/18009620
- https://www.cnblogs.com/yangjianbo/articles/17391415.html
- https://blog.csdn.net/m0_64417032/article/details/125450979
- https://blog.csdn.net/weixin_43202160/article/details/134418698