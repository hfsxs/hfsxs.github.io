---
title: Prometheus监控高可用集群方案
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - 监控告警
  - 云原生
  - 云计算
date: 2023-12-22 15:51:48
---

Prometheus创作者及社区核心开发者始终秉承一个理念，即只聚焦核心的功能，扩展性的功能留给社区解决。所以，自诞生至今，Prometheus都是单实例架构，且不可扩展。这对于云计算与大数据领域而言十分罕见，而Prometheus的核心开发者这样解释：Prometheus基于Go语言的特性和优势，能够以更小的代价抓取并存储更多数据，而Elasticsearch或Cassandra等Java实现的大数据项目处理同样的数据量会消耗更多的资源。也即是说，单实例、不可扩展的Prometheus已强大到可以满足大部分用户的需求

但是，随着基础架构的不断扩展，监控数据终将会增长到单个Prometheus Server无法处理的量级。鉴于此，Prometheus提供了联邦集群的解决方案

# 集群方案

## 1.基本HA

部署多个Prometheus Server实例，前段部署反向代理，各实例采集相同的Exporter目标，也就是将监控数据保留同样的几份。该方案只能确保Promthues服务的可用性问题，但数据一致性问题及持久化问题无法解决，也无法进行动态的扩展。因此，只适用于监控规模不大，Promthues Server也不会频繁发生迁移，且只需保存短周期监控数据的场景

## 2.基本HA+远程存储

基本HA模式的基础上通过添加Remote Storage存储支持，将监控数据保存在第三方存储服务。该方案在保证Promthues服务可用性的基础上，同时确保了数据的持久化，Promthues Server宕机或数据丢失也可以快速恢复，也可以很好的进行迁移，适用于用户监控规模不大，监控数据有持久化需求，且需要确保Promthues Server迁移性的场景

## 3.联邦集群+远程存储

联邦集群，即Prometheus中心实例负责数据聚合，分区实例负责监控数据采集所构成的监控系统。联邦集群将大量采集任务所形成的压力分散于不同的实例，在任务级别进行功能分区，即每个实例只负责采集一部分监控任务(Job)，如将应用监控和主机监控分离到不同的实例，监控规模持续扩大就将分区方式进一步细化，大大地提高了整个监控系统的吞吐量。联邦集群适用于如下场景：

- 巨量采集任务的单数据中心

该场景下，Promethues的性能瓶颈主要在于大量的采集任务，Prometheus联邦集群能将不同类型的采集任务划分到不同的Promethues实例，从而分散了任务采集的压力

- 垮机房的多数据中心

跨机房与数据中心的场景，由于不同内网之间的通信问题，单独部署的监控体系之间很难进行集中管理与聚合。因此，每个机房或数据中部署单独的实例负责当前数据中心的采集任务，并通过中心实例进行数据聚合，也就无需进行额外的网络配置即可构建起完整的监控体系

# 集群架构

- 172.100.100.200 Master
- 172.100.100.150 Node01 KVM虚拟机监控
- 172.100.100.180 Node02 应用程序监控

# 1.部署Prometheus

# 2.配置分区节点

## 2.1 配置分区Node01

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
                - 172.100.100.200:9093

    - job_name: node
      relabel_configs:
        - source_labels: [ '__address__' ]
          target_label: 'hostname'
      static_configs:
        - targets: ["172.100.100.180:9100"]
          labels:
            clusters: 'Openstack'
        - targets: ["172.100.100.181:9100"]
          labels:
            clusters: 'Openstack'
        - targets: ["172.100.100.182:9100"]
          labels:
            clusters: 'Openstack'
        - targets: ["172.16.100.100:9100"]
          labels:
            clusters: 'Kubernetes'
        - targets: ["172.16.100.101:9100"]
          labels:
            clusters: 'Kubernetes'
        - targets: ["172.16.100.102:9100"]
          labels:
            clusters: 'Kubernetes'

## 2.2 配置分区Node02

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
                - 172.100.100.200:9093

    scrape_configs:

      - job_name: prometheus
        relabel_configs:
          - source_labels: [ '__address__' ]
            target_label: 'hostname'
        static_configs:
          - targets: ["172.100.100.150:9090"]
            labels:
              clusters: 'Kubernetes'
          - targets: ["172.100.100.180:9090"]
            labels:
              clusters: 'Openstack'

      - job_name: memcached
        relabel_configs:
          - source_labels: [ '__address__' ]
            target_label: 'hostname'
        static_configs:
          - targets: ["172.100.100.180:9150"]
            labels:
              clusters: 'Openstack'

      - job_name: mysql
        relabel_configs:
          - source_labels: [ '__address__' ]
            target_label: 'hostname'
        static_configs:
          - targets: ["172.100.100.180:9104"]
            labels:
              clusters: 'Openstack'

      - job_name: rabbitmq
        relabel_configs:
          - source_labels: [ '__address__' ]
            target_label: 'hostname'
        static_configs:
          - targets: ["172.100.100.180:9419"]
            labels:
              clusters: 'Openstack'

# 3.配置联邦节点

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["172.100.100.200:9090"]
            labels:
              clusters: 'CloudServer'

      - job_name: "node"
        static_configs:
          - targets: ["172.100.100.200:9100"]
            labels:
              clusters: 'CloudServer'

      - job_name: 'prometheus150'
        scrape_interval: 10s
        metrics_path: /federate
        honor_labels: true
        params:
          # 设置查询条件，即只从其他Prometheus抓取符合条件的数据
          'match[]':
          # 设置匹配任务名称的表达式，该表达式表示job名称以node开头的指标数据
          - '{job=~"node.*"}'

        static_configs:
          # 设置指定的Prometheus实例
          - targets: ["192.168.100.150:9090"]

      - job_name: 'prometheus180'
        scrape_interval: 10s
        metrics_path: /federate
        honor_labels: true
        params:
          # 设置查询条件，即只从其他Prometheus抓取符合条件的数据
          'match[]':
          # 设置匹配任务名称的表达式，该表达式表示job名称为prometheus的指标数据
          # - '{job="prometheus"}' 
          # 设置匹配指标名称的表达式，__name__表示匹配指定名称的指标数据，该表达式表示指标名称以job开头的指标数据
          # - '{__name__=~"job:.*"}'

          # 设置匹配任务名称的表达式，该表达式表示job名称以node开头的指标数据
          - '{job=~"prometheus.*"}' 
          - '{job=~"mysql.*"}' 
          - '{job=~"rabbitmq.*"}' 
          - '{job=~"memcached.*"}' 

        static_configs:
          # 设置指定的Prometheus实例
          - targets: ["172.100.100.180:9090"]
           
---------

# 参考文档

- https://blog.csdn.net/hanjinjuan/article/details/121363870
- https://blog.csdn.net/m0_37749659/article/details/130794785
- https://blog.csdn.net/agonie201218/article/details/126249715