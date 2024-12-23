---
title: Prometheus监控Redis数据库
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Redis
  - 监控告警
  - 云原生
  - 云计算
date: 2024-06-30 22:06:17
---

# 1.下载redis_exporter

    wget https://github.com/oliver006/redis_exporter/releases/download/v1.61.0/redis_exporter-v1.61.0.linux-amd64.tar.gz

# 2.安装redis_exporter

    tar -xzvf redis_exporter-v1.61.0.linux-amd64.tar.gz
    sudo mv redis_exporter-v1.61.0.linux-amd64/redis_exporter /usr/local/bin

# 3.创建启动脚本

    sudo vi /lib/systemd/system/redis_exporter.service


    [Unit]
    Description=redis_exporter
    Documentation=https://github.com/oliver006/redis_exporter
    After=network.target
    BindsTo=redis.service

    [Service]
    Type=simple
    User=root
    ExecStart=/usr/local/bin/redis_exporter -redis.password redis -exclude-latency-histogram-metrics
    KillMode=mixed
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

# 4.启动redis_exporter


    sudo systemctl daemon-reload
    sudo systemctl start redis_exporter.service
    sudo systemctl enable redis_exporter.service

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

      - job_name: "redis"
        static_configs:
          - targets:
            - ovirt.sword.org:9121
            labels:
              clusters: Ovirt
        relabel_configs:
          - source_labels: [ '__address__' ]
            regex: "(.*):(.*)"
            replacement: $1
            target_label:  'hostname'

## 5.2 重载Prometheus，验证集群监控状态

    curl -XPOST http://127.0.0.1:9090/-/reload

# 6.导入grafana模版

Dashboards ---> Manage ---> Import ---> 模版ID：14091

![redis](/img/wiki/prometheus/redis.jpg)

---------

# 参考文档

- https://github.com/oliver006/redis_exporter
- https://www.cnblogs.com/miaocbin/p/12028105.html