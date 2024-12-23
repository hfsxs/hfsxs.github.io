---
title: Kubernetes集群水平自动伸缩HPA详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2022-12-01 12:28:24
---

HPA，Horizontal Pod Autoscaling，即Pod水平自动伸缩，是通过监控分析RC或Deployment控制器Pod的负载变化动态调整Pod的副本数量的Kubernetes集群资源对象，目的是根据业务整体压力调整集群规模，以应对流量的场景。HPA Controller通过kube-controller-manager组件的启动参数--horizontal-pod-autoscaler-sync-period定义的轮询时间间隔周期性查询指定资源所含Pod的负载，再根据创建时设定的策略判断是否达到阈值，若达到阈值则根据扩缩容策略扩容副本分担压力，直到Pod稳定空闲一段时间后再缩减副本数量，完成自动伸缩流程

# 1.安装metrics

    wget -O metrics-server.yml https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.5.0/components.yaml
    kubectl apply -f metrics-server.yaml

# 2.创建HPA

    kubectl autoscale deployment nginx-deployment --cpu-percent=90 --min=1 --max=6

# 3.应用压测，验证HPA

    kubectl exec -it nginx -- while true;do curl -I nginx-service;done

---------

# 参考文档

- https://www.cnblogs.com/maxzhang1985/p/15989762.html
- https://blog.csdn.net/fly910905/article/details/105375822
- https://blog.csdn.net/zenglingmin8/article/details/116837006