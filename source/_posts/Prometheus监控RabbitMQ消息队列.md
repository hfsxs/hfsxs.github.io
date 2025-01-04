---
title: Prometheus监控RabbitMQ消息队列
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - RabbitMQ
  - 监控告警
  - 云原生
  - 云计算
date: 2024-04-15 15:55:57
---

# 1.RabbitMQ启用管理插件

    sudo rabbitmq-plugins enable rabbitmq_management

# 2.RabbitMQ创建监控账号

    sudo rabbitmqctl add_user prometheus prometheus_2024
    # 需要将用户赋予管理员权限: 
    sudo rabbitmqctl set_user_tags prometheus administrator
    # 需要将用户赋予vhost权限: 
    sudo rabbitmqctl set_permissions -p / prometheus ".*" ".*" ".*"

# 3.安装rabbitmq_exporter

    wget https://github.com/kbudde/rabbitmq_exporter/releases/download/v1.0.0/rabbitmq_exporter_1.0.0_linux_amd64.tar.gz
    tar -xzvf rabbitmq_exporter_1.0.0_linux_amd64.tar.gz && sudo mkdir -p /usr/local/rabbitmq_exporter
    sudo mv rabbitmq_exporter /usr/local/rabbitmq_exporter

# 4.创建配置文件

     sudo vi /usr/local/rabbitmq_exporter/config.json


    {
      "rabbit_url": "http://127.0.0.1:15672",
       "rabbit_user": "prometheus",
       "rabbit_pass": "prometheus_2024",
       "publish_port": "9419",
       "publish_addr": "",
       "output_format": "TTY",
       "ca_file": "ca.pem",
       "cert_file": "client-cert.pem",
       "key_file": "client-key.pem",
       "insecure_skip_verify": false,
       "exlude_metrics": [],
       "include_exchanges": ".*",
       "skip_exchanges": "^$",
       "include_queues": ".*",
       "skip_queues": "^$",
       "skip_vhost": "^$",
       "include_vhost": ".*",
       "rabbit_capabilities": "no_sort,bert",
       "aliveness_vhost": "/",
       "enabled_exporters": [
         "exchange",
         "node",
         "overview",
         "queue",
         "aliveness"
       ],
       "timeout": 30,
       "max_queues": 0
  }


# 5.创建启动脚本

    sudo vi /lib/systemd/system/rabbitmq_exporter.service


    [Unit]
    Description=https://www.rabbitmq.com/prometheus.html
    After=network-online.target
 
    [Service]
    Restart=on-failure
    ExecStart=/usr/local/bin/rabbitmq_exporter -config-file /usr/local/rabbitmq_exporter/config.json
 
    [Install]
    WantedBy=multi-user.target

# 6.启动rabbitmq_exporter

    sudo systemctl daemon-reload
    sudo systemctl start rabbitmq_exporter.service
    sudo systemctl enable rabbitmq_exporter.service

# 7.配置Prometheus

## 7.1 配置监控实例

    sudo vi /usr/local/prometheus/prometheus.yml


    global:
      scrape_interval: 15s 
      evaluation_interval: 15s 
      scrape_timeout: 10s 

    scrape_configs:
      - job_name: "prometheus"
        static_configs:
          - targets: ["localhost:9090"]

      - job_name: "rabbitmq"
        static_configs:
          - targets: ["192.168.100.120:9414"]

## 7.2 配置告警规则

    sudo vi /usr/local/prometheus/rules/rabbitmq.yml


    groups:
    - name: RabbitMQ
      rules:
      - alert: RabbitmqDown
        expr: sum(rabbitmq_build_info) < 1
        for: 1m
        labels:
          severity: Critical
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例宕机，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例宕机超过1分钟，当前状态为{{ $value }}"       
      - alert: RabbitmqNodeNotDistributed
        expr: erlang_vm_dist_node_state < 3
        for: 0m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例未启用分布式功能，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例未启用分布式功能，当前状态为{{ $value }}"               
      - alert: RabbitmqMemoryHigh
        expr: rabbitmq_process_resident_memory_bytes / rabbitmq_resident_memory_limit_bytes * 100 > 90
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例内存超限，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例内存超限90%，当前内存占用为{{ $value }}"
      - alert: RabbitmqFileDescriptorsUsage
        expr: rabbitmq_process_open_fds / rabbitmq_process_max_fds * 100 > 90
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例文件描述符占用超限，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例文件描述符占用超限90%，当前占用量为VALUE = {{ $value }}" 
      - alert: RabbitmqTooManyUnackMessages
        expr: sum(rabbitmq_queue_messages_unacked) BY (queue) > 1000
        for: 1m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例消息队列未确认消息量超限，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例消息队列未确认消息量已超过1000，当前量为{{ $value }}" 
      - alert: RabbitmqUnroutableMessages
        expr: increase(rabbitmq_channel_messages_unroutable_returned_total[5m]) > 0 or increase(rabbitmq_channel_messages_unroutable_dropped_total[5m]) > 0
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例消息队存在不可路由消息，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例消息队存在不可路由消息，当前不可路由消息数量为{{ $value }}"
      - alert: RabbitmqTooManyConnections
        expr: rabbitmq_connections > 1000
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例连接数超限，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例连接数超过1000，当前连接数为{{ $value }}"                 
      - alert: RabbitmqNoQueueConsumer
        expr: rabbitmq_queue_consumers < 1
        for: 1m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例消息队列无消费者，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例消息队列无消费者，当前消费者数为{{ $value }}"
      - alert: RabbitmqInstancesDifferentVersions
        expr: count(count(rabbitmq_build_info) by (rabbitmq_version)) > 1
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例存在不同版本，请尽快处理!"
          description: "{{ $labels.instance }}RabbitMQ集群实例消息队列无消费者，当前状态为{{ $value }}"
      - alert: RabbitmqClusterPartition
        expr: rabbitmq_partitions > 0
        for: 5m
        labels:
          severity: Critical
        annotations:
          summary: "{{ $labels.instance }}RabbitMQ集群实例存在网络分区，请尽快处理!"
          description:"{{ $labels.instance }}RabbitMQ集群实例存在网络分区，当前状态为{{ $value }}"

## 7.3 重载Prometheus

    curl -XPOST http://127.0.0.1:9090/-/reload

# 8.导入grafana模版

Dashboards ---> Manage ---> Import ---> 模版ID：10120

![prometheus-011](/img/wiki/prometheus/prometheus-011.jpg)

---------

# 参考文档

- https://blog.51cto.com/u_16213630/10089792
- https://github.com/kbudde/rabbitmq_exporter
- https://blog.csdn.net/manba_24/article/details/134441710
- https://blog.csdn.net/wybaaaaaaaa/article/details/130887890
- https://blog.csdn.net/weixin_43845924/article/details/136167093