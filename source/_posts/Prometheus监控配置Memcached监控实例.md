---
title: Prometheus监控配置Memcached监控实例
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Memcached
  - 监控告警
  - 云原生
  - 云计算
date: 2024-04-30 16:23:58
---

# 1.安装memcached_exporter

    wget https://github.com/prometheus/memcached_exporter/releases/download/v0.14.3/memcached_exporter-0.14.3.linux-amd64.tar.gz
    tar -xzvf memcached_exporter-0.14.3.linux-amd64.tar.gz && sudo mv memcached_exporter /usr/local/bin

# 2.创建启动脚本

    sudo vi /lib/systemd/system/memcached_exporter.service


    [Unit]
    Description = memcached_exporter
    Documentation = https://github.com/prometheus/memcached_exporter
    After = network.target

    [Service]
    Type = simple
    User = root
    ExecStart = /usr/local/bin/memcached_exporter
    Restart = on-failure

    [Install]
    WantedBy = multi-user.target

# 3.启动memcached_exporter

    sudo systemctl daemon-reload
    sudo systemctl start memcached_exporter.service
    sudo systemctl enable memcached_exporter.service

# 4.配置Prometheus

## 4.1 配置监控实例

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]

      - job_name: "memcached"
        static_configs:
          - targets: ["192.168.100.180:9150"]

## 4.2 创建告警规则

    sudo vi /usr/local/prometheus/rules/memcached.yml

# 5.重载Prometheus

    curl -XPOST http://127.0.0.1:9090/-/reload

# 6.导入grafana模版

Dashboards ---> Manage ---> Import ---> 模版ID：37

![prometheus-memcached](/img/wiki/prometheus/prometheus-memcached.jpg)

---------

# 参考文档

- https://www.cnblogs.com/you-men/p/13206737.html
- https://github.com/prometheus/memcached_exporter