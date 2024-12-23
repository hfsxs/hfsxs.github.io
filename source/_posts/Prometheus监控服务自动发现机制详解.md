---
title: Prometheus监控服务自动发现机制详解
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Alertmanager
  - 监控告警
  - 云计算
date: 2023-10-20 15:18:33
---

服务发现，即Prometheus自动检测、分类和识别新增及变更的监控目标的机制，分为基于DNS、文件、Consul和Kubernetes集群这几种类型

# 监控指标抓取流程

Prometheus监控标签，附加到指标名称或指标值的标识监控数据元数据的键值对，以便于监控数据的过滤、聚合和查询，用于标识应用程序实例与环境，如生产、测试、开发环境或分散的数据中心等

## 1.指标发现

Prometheus在每个scrape_interval期间都会检查执行的任务（Job），这些Job将根据指定的发现配置生成Target列表，完成服务发现过程

## 2.配置标签

服务发现将会返回一个Target列表，并为之配置内置标签和自定义标签，以"__"前缀为前缀均为内置标签，如以"__meta_"为前缀的元数据标签，只供Prometheus使用而不写入时序数据库，也无法在promql查到；“__scheme__”表示target支持使用协议（http或https，默认为http），“__address__”表示target的地址，“__metrics_path__”表示指标的URI路径（默认为/metrics），若URI路径中存在请求参数，则前缀将设置为“__param_；被重复利用以生成其他标签，如instance标签的默认值就来自于__address__标签。自然，也包括用户为方便多维度查询的自定义标签

## 3.relabel_configs

抓取指标之前通过relabel_configs对Target实例的标签进行重写，较为常用，如过滤不需要被抓取的target、删除不需要或者敏感标签、根据已有的标签生成新标签等，重写标签之后以__开头的标签将被从标签集中删除，可确定需要抓取的目标及其标签

## 4.指标抓取

Prometheus按照指标名称及标签抓取监控数据，完成样本数据采集

## 5.metric_relabel_configs

为了更好的标识监控指标，Prometheus允许对原始数据进行编辑，类似于relabel_configs也是对标签进行重写，如添加、修改、删除标签及其格式。不同于relabel_configs操作target，metric_relabel_configs的操作对象Metric，也即时间序列

## 6.指标保存

Prometheus最后将指标、值及其标签写入时序数据库，以供后续的聚合、查询与分析

# 1.基于文件自动发现

该类型是实现最为简单的服务发现方式，不依赖于其他任何平台或第三方服务，略由于静态配置，主要是通过Prometheus Server周期性地读取与重载文件所定义的target的信息，包括target列表及可选的标签，文件格式支持json或yaml

## 1.1 创建配置文件

    sudo mkdir -p /usr/local/prometheus/configs
    sudo vi /usr/local/prometheus/configs/node.yaml


    - targets:
      - node01:9100
      - node02:9100
      - node03:9100
      labels:
        app: node-exporter

## 1.2 Prometheus加载配置

    sudo vi /usr/local/prometheus/prometheus.yml


      - job_name: "node"
        file_sd_configs:
        - files:
          - /usr/local/prometheus/configs/*.yaml
          refresh_interval: 2m

## 1.3 验证自动发现机制








---------

# 参考文档

- https://blog.csdn.net/q2524607033/article/details/134574252
- https://blog.csdn.net/qq_30614345/article/details/131776198
- https://blog.csdn.net/m0_59430185/article/details/121853136