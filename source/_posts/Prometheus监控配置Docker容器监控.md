---
title: Prometheus监控配置Docker容器监控
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Docker
  - 容器
  - 监控告警
  - 云原生
  - 云计算
date: 2023-11-09 10:31:42
---

cAdvisor，用于收集、聚合、处理和导出容器运行状态的信息，为每个容器保存资源隔离参数、历史资源使用情况、完整历史资源使用直方图和网络统计信息，对容器进行实时监控和性能数据采集，如CPU、内存、网络、文件系统等资源的使用情况

# 1.安装cAdvisor

## 1.1 下载cAdvisor

    wget https://github.com/google/cadvisor/releases/download/v0.49.1/cadvisor-v0.49.1-linux-amd64
    sudo mv cadvisor-v0.49.1-linux-amd64 /usr/local/bin/cadvisor && sudo chmod +x /usr/local/bin/cadvisor

## 1.2 创建启动脚本

    sudo vi /lib/systemd/system/cadvisor.service


    [Unit]
    Description=cadvisor_exporter
    Documentation=https://prometheus.io
    After=network.target

    [Service]
    Type=simple
    User=root
    ExecStart = /usr/local/bin/cadvisor -port 8080
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

## 1.3 启动cAdvisor

    sudo systemctl daemon-reload
    sudo systemctl start cadvisor.service
    sudo systemctl enable cadvisor.service

# 2.配置Prometheus

    sudo vi /usr/local/prometheus/prometheus.yml


    scrape_configs:
      - job_name: "docker"
        file_sd_configs:
        - files:
          - /usr/local/prometheus/config/docker.yml
        relabel_configs:
          - source_labels: [ '__address__' ]
            regex: "(.*):(.*)"
            replacement: $1
            target_label: 'hostname'

# 3.创建自动发现规则

    sudo vi /usr/local/prometheus/config/docker.yml


    - targets:
        - engine.sword.org:8080
      labels:
        clusters: KVM

# 4.创建告警规则

    sudo vi /usr/local/prometheus/rules/docker.yml


    groups:
    - name: docker
      rules:
      - alert: ContainerKilled
        expr: time() - container_last_seen{name!=""} > 60
        for: 1m
        labels:
          severity: Critical
        annotations:
          summary: "{{ $labels.name }}容器被Kill，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器被Kill"
      - alert: ContainerCpuUsage
        expr: (sum by(instance, name) (rate(container_cpu_usage_seconds_total{name!=""}[3m])) * 100) > 80
        for: 2m
        labels:
          severity: Warning
          clusters: 工控机
        annotations:
          summary: "{{ $labels.name }}容器CPU使用率过高，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器CPU使用率超过80%, 当前值为{{ $value }}"
      - alert: ContainerHighThrottleRate
        expr: rate(container_cpu_cfs_throttled_seconds_total[3m]) > 1
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.name }}容器CPU超限，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器持续2分钟CPU超限, 当前值为{{ $value }}"
      - alert: ContainerMemoryUsage
        expr: (sum by(instance, name) (container_memory_working_set_bytes{name!=""}) / sum by(instance, name) (container_spec_memory_limit_bytes{name!=""} > 0) * 100)  > 80
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.name }}容器内存使用率过高，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器内存使用率超过80%, 当前值为{{ $value }}"
      - alert: ContainerVolumeUsage
        expr: (1 - (sum(container_fs_inodes_free) BY (instance) / sum(container_fs_inodes_total) BY (instance))) * 100 > 80
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.name }}容器磁盘使用率过高，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器磁盘使用率超过80%, 当前值为{{ $value }}"
      - alert: ContainerLowCpuUtilization
        expr: (sum(rate(container_cpu_usage_seconds_total{name!=""}[3m])) BY (instance, name) * 100) < 20
        for: 7d
        labels:
          severity: Info
        annotations:
          summary: "{{ $labels.name }}容器CPU使用率过低，建议缩减CPU配额"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器持续7天CPU使用率低于20%, 当前值为{{ $value }}"
      - alert: ContainerLowMemoryUsage
        expr: (sum(container_memory_working_set_bytes{name!=""}) BY (instance, name) / sum(container_spec_memory_limit_bytes > 0) BY (instance, name) * 100) < 20
        for: 7d
        labels:
          severity: Info
        annotations:
          summary: "{{ $labels.name }}容器内存使用率过低，建议缩减内存配额"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器持续7天内存使用率低于20%, 当前值为{{ $value }}"
    
# 5.重载Prometheus

    curl -XPOST http://127.0.0.1:9090/-/reload

# 6.导入grafana模版

Dashboards ---> Manage ---> Import ---> 模版ID：14282

![prometheus-docker001](/img/wiki/prometheus/prometheus-docker001.jpg)

![prometheus-docker002](/img/wiki/prometheus/prometheus-docker002.jpg)

---------

# 参考文档

- https://zhuanlan.zhihu.com/p/618043088
- https://blog.csdn.net/m0_37749659/article/details/130716421
- https://docs.huihoo.com/apache/mesos/chrisrc.me/dcos-admin-monitoring-docker.html