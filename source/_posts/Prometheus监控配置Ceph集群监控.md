---
title: Prometheus监控配置Ceph集群监控
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Ceph
  - 监控告警
  - 存储
  - 分布式存储
  - 云存储
  - 云计算
date: 2024-04-27 18:18:33
---

Ceph集群Manager组件内部集成了Prometheus监控模块，并监听在每个Manager节点的9283端口，用于将采集到的信息通过http接口传送到Prometheus。当然，也可以通过ceph_exporter完成监控信息的采集

# 1.启用Prometheus监控模块

    ceph mgr module enable prometheus

    # 验证监控模块
    ceph mgr module ls

# 2.查看prometheus指标节点信息

    ceph mgr services

    {
    "dashboard": "http://192.168.100.183:8080/",
    "prometheus": "http://192.168.100.183:9283/"
    }

# 3.Prometheus配置监控实例

    sudo vi /usr/local/prometheus/prometheus.yml


    - job_name: "ceph"
    static_configs:
    - targets: ["172.100.100.183:9283"]
      labels:
        clusters: 'Ceph'

# 4.重启Prometheus Server

    sudo systemctl resetart prometheus.service

# 5.创建告警规则

    sudo vi /usr/local/prometheus/rules/ceph.yml


    groups:
      - name: ceph
        rules:
        - alert: CephCluster
          expr: ceph_health_status > 0
          for: 3m
          labels:
            severity: Critical
          annotations:
            summary: "{{$labels.instance}}: Ceph集群状态异常"
            description: "{{$labels.instance}}:Ceph集群状态异常，当前状态为{{ $value }}"
        - alert: CephOSDDown
          expr: count(ceph_osd_up{} == 0.0) > 0
          for: 3m
          labels:
            severity: Critical
          annotations:
            summary: "{{$labels.instance}}: 有{{ $value }}个OSD挂掉了"
            description: "{{$labels.instance}}:{{ $labels.osd }}当前状态为{{ $labels.status }}"
        - alert: CephOSDOut
          expr: count(ceph_osd_up{}) - count(ceph_osd_in{}) > 0
          for: 3m
          labels:
            severity: Critical
          annotations:
            summary: "{{$labels.instance}}: 有{{ $value }}个OSD Out"
            description: "{{$labels.instance}}:{{ $labels.osd }}当前状态为{{ $labels.status }}"
        - alert: CephOverSpace
          expr: ceph_cluster_total_used_bytes / ceph_cluster_total_bytes * 100 > 80
          for: 3m
          labels:
            severity: Critical
          annotations:
            summary: "{{$labels.instance}}:集群空间不足"
            description: "{{$labels.instance}}:当前空间使用率为{{ $value }}"
        - alert: CephMonDown
          expr: count(ceph_mon_quorum_status{}) < 3
          for: 3m
          labels:
            severity: Critical
          annotations:
            summary: "{{$labels.instance}}:Mon进程异常"
            description: "{{$labels.instance}}: Mon进程Down"
        - alert: CephMgrDown
          expr: sum(ceph_mgr_status{}) < 1.0
          for: 3m
          labels:
            severity: Critical
          annotations:
            summary: "{{$labels.instance}}:Mgr进程异常"
            description: "{{$labels.instance}}: Mgr进程Down"
        - alert: CephMdsDown
          expr: sum(ceph_mds_metadata{}) < 3.0
          for: 3m
          labels:
            severity: Warning
          annotations:
            summary: "{{$labels.instance}}:Mds进程异常"
            description: "{{$labels.instance}}: Mds进程Down"
        - alert: CephRgwDown
          expr: sum(ceph_rgw_metadata{}) < 2.0
          for: 3m
          labels:
            severity: Warning
          annotations:
            summary: "{{$labels.instance}}:Rgw进程异常"
            description: "{{$labels.instance}}: Rgw进程Down"
        - alert: CephOsdOver
          expr: sum(ceph_osd_stat_bytes_used / ceph_osd_stat_bytes > 0.8) by (ceph_daemon) > 0
          for: 3m
          labels:
            severity: Warning
          annotations:
            summary: "{{$labels.instance}}:High OSD Usage Alert"
            description: "{{$labels.instance}}: Some OSDs have usage above 80%"
  
# 6.导入grafana模版

Dashboards —> Manage —> Import —> 模版ID：9966  

![prometheus-012](/img/wiki/prometheus/prometheus-012.jpg)

---------

# 参考文档

- https://blog.csdn.net/xu710263124/article/details/135849819
- https://blog.csdn.net/yangkang1122/article/details/88687944
- https://blog.csdn.net/zuoyang1990/article/details/132147203