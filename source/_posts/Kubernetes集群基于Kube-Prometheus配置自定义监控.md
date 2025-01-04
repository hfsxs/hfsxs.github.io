---
title: Kubernetes集群基于Kube-Prometheus配置自定义监控
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - Prometheus
  - 监控告警
  - 云原生
  - 容器云
  - 云计算
date: 2023-10-31 10:41:20
---

Kube-Prometheus由自定义资源ServiceMonitor实现对资源的监控，该资源描述了Prometheus Server的Target列表，具体是通过Selector依据Labels选取到对应Service的endpoints，监控数据由Prometheus Server通过Service进行拉取，从而实现跨命名空间的动态服务发现。此外，ServiceMonito监听Kubernetes集群的资源变动，如服务的创建、删除或标签的变更，以及规则的更新，然后自动更新Prometheus的配置文件，以及配合PrometheusRule自动发现和生成相应的监控配置。通过这种简单的声明式配置实现了Prometheus监控系统的自动管理和扩展，从而使得监控系统的维护更加简单和可靠

# 工作流程

- 1.创建ServiceMonitor对象，用于Prometheus添加监控项
- 2.创建ServiceMonitor对象所关联的metrics数据接口的Service对象
- 3.验证并确保Service对象能正确获取到metrics数据，主要是关于MySQL用户和集群SA的权限

# 1.部署MySQL数据库

# 2.部署mysql-exporter

## 2.1 创建MySQL数据库用户并授权

    MariaDB [(none)]> create user 'exporter'@'%' identified with mysql_native_password by 'exporter@2020';
    MariaDB [(none)]> GRANT ALL PRIVILEGES ON *.* TO 'exporter'@'%' with grant option;
    MariaDB [(none)]> flush privileges;

## 2.2 创建MySQL数据库配置文件

    vi my.cnf


    [client]
    host=192.168.100.180
    user=exporter
    password=exporter@2020

## 2.3 部署MySQL数据库配置项


    kubectl create configmap mysql-exporter-conf --from-file=my.cnf

## 2.4 创建mysql-exporter资源文件

    vi mysql-exporter.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: mysql-exporter
      namespace: monitoring
    spec:
      replicas: 1
      selector:
        matchLabels:
          k8s-app: mysql-exporter
      template:
        metadata:
          labels:
            k8s-app: mysql-exporter
        spec:
          containers:
            - name: mysql-exporter
              image: registry.cn-hangzhou.aliyuncs.com/swords/mysqld-exporter
              env:
                - name: DATA_SOURCE_NAME
                  value: "exporter:123456@(192.168.100.180:3306)/"
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 9104
              volumeMounts:
                - name: mysql-exporter-conf
                  mountPath: /home/.my.cnf
                  subPath: my.cnf
          volumes:
            - name: mysql-exporter-conf
              configMap:
                name: mysql-exporter-conf
    ---
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        k8s-app: mysql-exporter
      name: mysql-exporter
      namespace: monitoring
    spec:
      type: ClusterIP
      ports:
        - name: api
          protocol: TCP
          port: 9104
      selector:
        k8s-app: mysql-exporter

## 2.5 部署mysql-exporter.yaml

    kubectl apply -f mysql-exporter.yaml

# 3.部署ServiceMonitor

## 3.1 创建ServiceMonitor资源文件

    vi servicemonitor.yaml


    apiVersion: monitoring.coreos.com/v1
    kind: ServiceMonitor
    metadata:
      name: mysql-exporter
      namespace: monitoring
      labels:
        k8s-app: mysql-exporter
        namespace: monitoring
    spec:
      jobLabel: k8s-app
      endpoints:
        - port: api
          interval: 30s
          scheme: http
      selector:
        matchLabels:
          k8s-app: mysql-exporter
      namespaceSelector:
        matchNames:
          - monitoring

## 3.2 部署ServiceMonitor

    kubectl apply -f servicemonitor.yaml

# 4.部署PrometheusRule监控规则

## 4.1 创建PrometheusRule监控规则文件

    vi mysql-exporter-PrometheusRule.yaml


    apiVersion: monitoring.coreos.com/v1
    kind: PrometheusRule
    metadata:
      labels:
        prometheus: k8s
        role: alert-rules
      name: mysql-exporter-rules
      namespace: monitoring
    spec:
      groups:
        - name: mysql-exporter
          rules:
            - alert: MysqlDown
              annotations:
                description: |-
                  MySQL instance is down on {{ $labels.instance }}
                    VALUE = {{ $value }}
                    LABELS = {{ $labels }}
                summary: 'MySQL down (instance {{ $labels.instance }})'
              expr: mysql_up == 0
              for: 0m
              labels:
                severity: critical
            - alert: MysqlSlaveIoThreadNotRunning
              annotations:
                description: |-
                  MySQL Slave IO thread not running on {{ $labels.instance }}
                    VALUE = {{ $value }}
                    LABELS = {{ $labels }}
                summary: >-
                  MySQL Slave IO thread not running (instance {{ $labels.instance
                  }})
              expr: >-
                mysql_slave_status_master_server_id > 0 and ON (instance)
                mysql_slave_status_slave_io_running == 0
              for: 0m
              labels:
                severity: critical
            - alert: MysqlSlaveSqlThreadNotRunning
              annotations:
                description: |-
                  MySQL Slave SQL thread not running on {{ $labels.instance }}
                    VALUE = {{ $value }}
                    LABELS = {{ $labels }}
                summary: >-
                  MySQL Slave SQL thread not running (instance {{ $labels.instance
                  }})
              expr: >-
                mysql_slave_status_master_server_id > 0 and ON (instance)
                mysql_slave_status_slave_sql_running == 0
              for: 0m
              labels:
                severity: critical

## 4.2 部署PrometheusRule监控规则

    kubectl apply -f mysql-exporter-PrometheusRule.yaml

# 5.导入grafana模版

Dashboards —> Manage —> Import —> 模版ID：7362

# 6.停止MySQL服务，测试监控告警

---------

# 参考文档

- https://blog.51cto.com/liubin0505star/5767918
- https://www.cnblogs.com/cndarren/p/16975566.html
- https://blog.csdn.net/knight_zhou/article/details/126241171
- https://blog.csdn.net/qq_43164571/article/details/127299185