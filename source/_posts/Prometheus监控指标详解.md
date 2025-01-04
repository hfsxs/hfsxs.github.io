---
title: Prometheus监控指标详解
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - 监控告警
  - 云计算
date: 2023-08-04 15:12:36
---

Metric，即指标，是Prometheus系统所采集到的监控数据，以时间序列的方式保存于内存数据库，且定时写入到硬盘，即是以时间戳和值的序列顺序存储的连续的数据集合。可以将之形象的理解为向量vector，或是以时间为Y轴的数字矩阵，每条时间序列以指标名和一组标签集命名

    ^
    │   . . . . . . . . . . . . . . . . . . . .  node_cpu{cpu="cpu0",mode="idle"}
    │   . . . . . . . . . . . . . . . . . . . .  node_cpu{cpu="cpu0",mode="system"}
    │   . . . . . . . . . . . . . . . . . . . .  node_load1{}
    │   . . . . . . . . . . . . . . . . . . . .  node_load3{}
    |
    ------------------ 时间 ------------------->

# 1.指标组成

Metric每一个点称为一个样本sample，由三部分组成，即指标名及其标签集、时间戳、样本值

## 1.1 指标名及其标签集

- 指标名，metric name，表示指标的监控项，描述了指标的性质，格式包括ASCII字符、数字、下划线和冒号，命名应该具有语义化，以直观的表示度量指标，如http_request_total，即请求量

- 指标标签集，labelsets，表示指标的特征维度，用于对一个或一组样本数据进行不同维度的查询、过滤、聚合操作，是一组key/value键值对，如http_request_total指标，请求状态码标签集为code = 200/400/500，请求方式标签集为method = get/post。标签名由ASCII字符、数字及下划线组成，以__为前缀则表示为系统保留关键字，只在系统内部使用，标签值可以是任何Unicode字符，也支持中文，可来自被监控资源，也可由Prometheus在抓取期间和之后添加

## 1.2 时间戳

时间戳，即timestamp，描述了当前时间序列的时间，单位为毫秒

## 1.3 样本值

样本值，value，float64浮点型数据，表示当前监控指标的具体数值，如http_request_total的值就是请求数

# 2.指标格式

Prometheus监控指标的时间序列格式为：<metric name>{<label name>=<label value>, ...}，如node-exporter部分数据指标样本：

    # HELP node_network_receive_packets_total Network device statistic receive_packets.
    # TYPE node_network_receive_packets_total counter
    node_network_receive_packets_total{device="docker0"} 1.787294e+06
    node_network_receive_packets_total{device="eth0"} 2.22892757e+08
    node_network_receive_packets_total{device="lo"} 9.48425344e+08
    node_network_receive_packets_total{device="veth5cbe2df"} 1.006495e+06

- 注：第一行，#开头，指标的说明介绍；第二行，#开头，表示指标的类型，必须项且格式固定，即TYPE+指标名称+类型；第三行开始为指标名及其标签集和样本值，即node_network_receive_packets_total为指标名，{}为标签集，标明了指标样本的特征和维度，最后的数值则为样本值

# 3.指标类型

Prometheus指标类型分为四种，即Counter、Gauge、Histogram和Summary

# 3.1 Counter

counter，即计数器，其值只增不减，用于统计单调递增的数据，如Http请求量、请求错误数、接口调用次数等，命名时建议以_total作为后缀。此外，结合increase、rate等函数可用于统计指标的变化速率

# 3.2 Gauge

gauge，即仪表盘，一般数值，可增可减，用于统计系统当前的状态，且无需经过内置函数即可直观反映数据的动态变化情况，如当前内存占用量、CPU利用、Gc次数等动态数据

# 3.3 Histogram

Histogram，即直方图或柱状图，累计值，用于分析指标在不同区间范围的分布情况，如对象存储不同存储桶请求耗时的分布。此外，Histogram还可对指标进行分组，提供count和sum功能，通过histogram_quantile函数可用于统计百分位数

# 3.4 Summary

Summary，即摘要，类似于Histogram，也是用于统计分析，但其值是直接由客户端计算好的百分位数，而非像Histogram那样通过内置函数 histogram_quantile由Prometheus进行计算，如prometheus_tsdb_wal_fsync_duration_seconds 的指标，表示Prometheus wal_fsync处理时间的分布

# 4.指标查询

PromQL，即Prometheus Query Language，Prometheus内置的数据查询语言，提供对时间序列的查询、聚合运算及逻辑运算功能，广泛应用于Prometheus的日常运维，如数据查询、可视化、告警处理等

## 4.1 基础查询

基础查询，即是直接通过指标名及其标签进行数据查询，查询结果就是当前指标最新的时间序列，也称为瞬时向量，表达式格式为：<metric name>{label=value}，如Prometheus的监控指标请求次数的表达式为：

    prometheus_http_requests_total{handler="/metrics"}

### 4.1.1 标签匹配查询

PromQL标签匹配查询分为两种方式，即=和!=，前者通过label=value查询满足标签表达式的时间序列，后者通过label!=value则会排除满足条件的时间序列

    # 查询实例为localhost:9100且访问状态码不是200的时间序列
    promhttp_metric_handler_requests_total{instance="localhost:9100",code!="200"}

### 4.1.2 标签正则匹配查询

    # 查询访问状态码为503或500的时间序列
    promhttp_metric_handler_requests_total{code=~".*503|500"}

## 4.2 时间范围查询

时间范围查询，即是对基础查询的一个时间限定，查询结果集所返回的时间序列是某个时间范围内的一组数据，被称为范围向量或区间向量，通过[]指定时间范围

    # 以当前时间为基准，查询5分钟内访问状态码为503或500的时间序列
    promhttp_metric_handler_requests_total{code=~".*503|500"}[5m]
    # 时间位移操作，即以1小时前的时间点为基准，查询5分钟内的时间序列
    http_requests_total{}[5m] offset 1h

## 4.3 聚合查询

PromQL内置的聚合操作符对瞬时向量的样本进行聚合，从而形成新的时间序列，以供复杂的分析与汇总，类似于MySQL的聚合查询、分组统计等

    # sum，求和运算，查询所有接口请求量的总和
    sum(http_requests_total{})

# 5.指标计算

PromQL还支持对指标进行各种运算，如算术运算与逻辑运算，以便完成更加复杂的查询

    # 数学运算，内存占用百分比
    100 - (node_memory_Buffers_bytes + node_memory_Cached_bytes + node_memory_MemFree_bytes) / node_memory_MemTotal_bytes * 100
    # 逻辑运算，匹配出大于100小于1000区间的时间序列样本
    promhttp_metric_handler_requests_total{code="200"} < 1000 or promhttp_metric_handler_requests_total{code="200"}  >100

# 6.指标可视化

Prometheus提供了简洁的可视化Web UI以供操作，以便于监控系统的维护与查询，默认端口为9090，访问方式即为http://ip:9090

![prometheus-008](/img/wiki/prometheus/prometheus-008.jpg)


---------

# 参考文档

- https://mp.weixin.qq.com/s/wbteQZWXA-aDAusvBw0nOQ
- https://andyoung.blog.csdn.net/article/details/122056239
- https://blog.csdn.net/qq_48059971/article/details/125517243
- https://blog.csdn.net/weixin_43883625/article/details/129757109