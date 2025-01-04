---
title: Prometheus监控配置Alertmanager告警组件
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Alertmanager
  - 监控告警
  - 云计算
date: 2023-08-08 22:54:17
---

Alertmanager组件负责接收并处理来自Prometheus Server的告警信息，如消除大量重复告警信息、对告警信息分组以及将之路由到通知方，如邮箱、钉钉、微信等。此外，还提供了静默和告警抑制机制来对告警通知行为进行优化

# 1.部署Alertmanager

## 1.1 下载安装包

    wget https://github.com/prometheus/alertmanager/releases/download/v0.25.0/alertmanager-0.25.0.linux-amd64.tar.gz

## 1.2 安装Alertmanager

    tar -xzvf alertmanager-0.25.0.linux-amd64.tar.gz
    sudo mv alertmanager-0.25.0.linux-amd64/alertmanager* /usr/local/prometheus
    sudo mkdir -p /usr/local/prometheus/data/alertmanager

## 1.3 创建启动脚本

    sudo vi /lib/systemd/system/alertmanager.service


    [Unit]
    Description=Alertmanager Server
    Documentation=https://github.com/prometheus/alertmanager
    After=network.target

    [Service]
    Type=simple
    User=root
    Group=root
    WorkingDirectory=/usr/local/prometheus
    ExecStart=/usr/local/prometheus/alertmanager --config.file=/usr/local/prometheus/alertmanager.yml --storage.path=/usr/local/prometheus/data/alertmanager
    ExecReload=/bin/kill -s HUP $MAINPID
    ExecStop=/bin/kill -s QUIT $MAINPID
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

## 1.4 配置文件语法检查

    /usr/local/prometheus/promtool check config /usr/local/prometheus/alertmanager.yml 

## 1.5 启动Alertmanager

    sudo systemctl daemon-reload
    sudo systemctl start alertmanager.service
    sudo systemctl enable alertmanager.service

# 2.配置Prometheus关联Alertmanager

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s

    alerting:
      alertmanagers:
        - static_configs:
            - targets:
                - localhost:9093
 
    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]
 
        - job_name: "node"
        static_configs:
          - targets: ["192.168.100.120:9090"]
          - targets: ["192.168.100.121:9090"]  

# 3.配置告警规则

Prometheus告警规则基于PromQL语句定义了监控指标的告警阈值及计算方式，并定期按照规则进行计算，若计算结果超过了所定义的阈值则会触发告警，再将产生的告警信息发送给Alertmanager进行处理

## 3.1 规则组成

告警规则由五部分组成，即规则名称、规则条件、等待时间、标签和附加信息，如下所示：

    # 设置告警规则分组，告警组由若干告警规则组成，便于规则管理
    groups:
    - name: nodes
      rules:
      # 设置告警规则名称
      - alert: HostCpuUsage
        # 设置基于PromQL语句的计算规则
        expr: (1-((sum(increase(node_cpu_seconds_total{mode="idle"}[5m])) by (instance))/ (sum(increase(node_cpu_seconds_total[5m])) by (instance))))*100 > 80
        # 设置告警评估时间，即触发条件持续一段时间后才发送告警
        for: 1m
        # 设置告警规则标签
        labels:
          severity: Warning
          clusters: CloudServer
        annotations:
          # 设置告警内容摘要，可用表达式获取变量的值
          summary: "{{ $labels.instance }}实例CPU使用率过高，请尽快处理！"
          # 设置告警内容详情，可用表达式获取变量的值
          description: "{{ $labels.instance }}实例CPU使用率超过80%，当前值为{{ $value }}"

### 3.1.1 alert

告警规则名称，规则组内规则名称必须唯一

### 3.1.2 expr

基于PromQL表达式配置的规则条件，用于计算时间序列指标是否满足规则

### 3.1.3 for

评估等待时间，可选参数，告警规则初始状态为inactive，当监控指标触发规则后，在for定义的时间区间内该规则会处于Pending状态，超过该时间后规则状态转换为Firing，并发送告警信息到Alertmanager

### 3.1.4 labels

自定义标签，允许用户指定要添加到告警信息上的一组附加标签，如告警等级等，告警等级一般分为三种，即warning、critical和emergency，严重等级依次递增

### 3.1.5 annotations

用于指定一组附加信息，如描述告警的信息文字等，summary用于描述主要信息，description用于描述详细的告警内容，支持两种类型的模版变量，$labels.<labelname>类型变量支持告警实例指定标签的值，$value则是获取当前PromQL计算的变量(expr里表达式的值)

## 3.2 告警流程

- 1.Prometheus加载告警规则文件，持续采集指标数据，并定期计算监控指标是否满足告警规则，计算周期由配置参数evaluation_interval指定，默认为1分钟
- 2.监控指标触发告警规则，指标告警状态转为Pending，若持续时间超过for所指定的时间，则转换为Firing，并将告警信息发送到Alertmanager
- 3.Alertmanager收到告警后，等待所定义的分组时间后，通过配置的告警介质发送到告警通知；若在此期间该分组又持续收到了告警，则会等待一个分组告警间隔时间，再次为该分组发送告警
- 4.若该告警一直存在，Alertmanager则会按照重发时间间隔重复发送告警通知，直到告警恢复

## 3.3 告警状态

Prometheus告警状态分为三种，即Inactive、Pending、Firing

- Inactive，非活动状态，表示正在监控，但还未有任何告警触发
- Pending，表示告警已被触发，等待分组、抑制或静默验证，验证通过则将转到Firing状态
- Firing，告警信息已发送到AlertManager，之后按照配置发送给接收者，告警解除后则将状态转为Inactive

## 3.4 创建告警规则文件

    sudo mkdir -p /usr/local/prometheus/rules
    sudo vi /usr/local/prometheus/rules/nodes.yml


    groups:
    - name: nodes
      rules:
      - alert: InstanceDown
        expr: up == 0
        for: 1m
        labels:
          severity: Critical
        annotations:
          summary: "{{$labels.instance}}实例宕机，请尽快处理!"
          description: "{{$labels.instance}}实例宕机超过1分钟，当前状态为{{$value}}"

# 4.告警规则文件语法检查

    /usr/local/prometheus/promtool check rules /usr/local/prometheus/rules/nodes.yml

# 5.重载Prometheus，加载告警规则

    curl -XPOST http://127.0.0.1:9090/-/reload 

# 6.关机被监控主机，测试告警状态

![prometheus-009](/img/wiki/prometheus/prometheus-009.jpg)

---------

# 参考文档

- https://blog.csdn.net/qq_30614345/article/details/131616940
- https://blog.csdn.net/weixin_46902396/article/details/125570792
- https://blog.csdn.net/weixin_56752399/article/details/121596299