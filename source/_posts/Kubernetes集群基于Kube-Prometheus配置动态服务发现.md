---
title: Kubernetes集群基于Kube-Prometheus配置动态服务发现
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
date: 2023-11-22 10:06:39
---

Prometheus基于Kubernetes集群服务发现的原理是通过Kubernetes的REST API检索抓取监控目标，并始终与集群状态保持同步，支持Node、Service、Pod、Endpoints、Ingress这几种模式，也称为角色Role，以适用不同的场景

# 角色类型

## Node

Node角色用于发现集群节点服务器的地址端口，默认为Kubelet的HTTP端口，Target地址默认为Kubernetes节点对象的第一个现有地址，地址类型顺序为NodeInternalIP、NodeExternalIP、NodeLegacyHostIP和NodeHostName

## Service

Service角色用于发现集群Service的IP和Port，将其作为Target，适用于黑盒监控(blackbox)场景

## Pod

Pod角色用于发现集群所有Pod并将其IP作为Target，若存在有多个端口或容器，则将生成多个Target；若容器没有指定的端口，则会为每个容器创建一个无端口Target，以便通过Relabel手动添加端口

## Endpoints

Endpoints角色用于发现集群Endpoints并将其作为Targets，若Tndpoint属于Service则会附加Service角色的所有标签，后端节点是Pod则会附加Pod角色的所有标签

## Ingress

Ingress角色用于发现集群Ingress每个路径的Target，其地址将设为Ingress中指定的host，通常用于黑盒监控

# 1.创建额外监控配置文件

    vi prometheus-additional.yaml


    - job_name: 'kubernetes-endpoints'
      kubernetes_sd_configs:
      - role: endpoints
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_scheme]
        action: replace
        target_label: __scheme__
        regex: (https?)
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_service_annotation_prometheus_io_port]
        action: replace
        target_label: __address__
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: kubernetes_name
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

# 2.创建额外监控配置项的Secret

    kubectl -n monitoring create secret generic additional-configs --from-file=prometheus-additional.yaml

# 3.Prometheus配置加载额外监控项



      version: 2.29.1
      additionalScrapeConfigs:
        name: additional-configs
        key: prometheus-additional.yaml

# 4.创建RBAC

    vi prometheus-clusterRole.yaml


    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      labels:
        app.kubernetes.io/component: prometheus
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 2.29.1
      name: prometheus-k8s
    rules:
    - apiGroups:
      - ""
      resources:
      - nodes
      - services
      - endpoints
      - pods
      - nodes/proxy
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - ""
      resources:
      - nodes/metrics
      verbs:
      - get
    - nonResourceURLs:
      - /metrics
      - /actuator/prometheus
      verbs:
      - get

# 5.验证监控项

# 参考文档

---------

- https://blog.z0ukun.com/?p=2605
- https://www.cnblogs.com/deny/p/14328900.html
- https://blog.csdn.net/ss810540895/article/details/130870986