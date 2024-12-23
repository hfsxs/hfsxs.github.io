---
title: Prometheus监控Linux系统
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - 监控告警
  - 云计算
date: 2023-08-01 12:16:28
---

实例，即Instance，Exporters暴露的HTTP方式的API，用于Prometheus周期性地采集监控样本数据，分布于不同节点的实例组构成任务，即Job，如node_exporter系统监控实例所组成的服务器资源监控任务、mysql_exporter监控实例所组成的数据库资源监控任务等

# 集群架构

- 192.168.100.100 Prometheus node_exporter
- 192.168.100.120 node_exporter
- 192.168.100.121 node_exporter

# 1.下载安装包

    wget https://github.com/prometheus/node_exporter/releases/download/v1.6.1/node_exporter-1.6.1.linux-amd64.tar.gz

# 2.安装node-exporter

    tar -xzvf node_exporter-1.6.1.linux-amd64.tar.gz
    sudo mv node_exporter-1.6.1.linux-amd64 /usr/local/bin/node_exporter

# 3.创建启动脚本

    sudo vi /lib/systemd/system/node_exporter.service


    [Unit]
    Description=node_exporter
    Documentation=https://prometheus.io
    After=network.target

    [Service]
    Type=simple
    User=root
    ExecStart=/usr/local/bin/node_exporter
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

# 4.启动node-exporter

    sudo systemctl daemon-reload
    sudo systemctl start node_exporter.service
    sudo systemctl enable node_exporter.service

# 5.配置Prometheus

## 5.1 配置监控实例

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]

      - job_name: "node"
        static_configs:
          - targets: ["192.168.100.120:9090"]
          - targets: ["192.168.100.121:9090"]  

## 5.2 重载Prometheus

    curl -XPOST http://127.0.0.1:9090/-/reload

# 6.导入grafana模版

Dashboards ---> Manage ---> Import ---> 模版ID：11074

![prometheus-005](/img/wiki/prometheus/prometheus-005.jpg)

![prometheus-006](/img/wiki/prometheus/prometheus-006.jpg)

# 7.验证Linux系统监控

![prometheus-007](/img/wiki/prometheus/prometheus-007.jpg)

---------

# 参考文档

- https://blog.csdn.net/weixin_43883625/article/details/129757960