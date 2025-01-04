---
title: Kubernetes集群Ingress详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2022-04-26 18:03:33
---

Ingress，即路由，是Kubernetes集群管理外部访问流量的路由规则，作为集群内部service对外暴露的访问接入点，几乎承载着集群内服务访问的所有流量。ingress为集群提供七层负载均衡、SSL安全连接和基于虚拟主机的反向代理功能，弥补了service的不足。通过配置不同的转发规则，将不同URL的外部访问请求转发到集群内部不同的Service，从而实现了HTTP层的业务路由机制，流量路由由Ingress资源上定义的规则控制

---------

# 功能组件

- Ingress Controller，即Ingress控制器，部署于集群内具体实现反向代理（即负载均衡）的程序，实现七层转发的Edge Router，通过调用apiserver组件动态感知集群中pod的变化而动态更新配置文件并重载。通常以DaemonSets或Deployments的形式部署，DaemonSets部署方式一般是以hostNetwork或者hostPort的形式暴露，Deployments部署形式以NodePort的方式暴露，控制器的多个节点则借助外部负载均衡ExternalLB以实现统一接入。常用的控制器有Nginx、HAProxy、Istio、Traefik ，当前Kubernetes官方维护的是Nginx Ingress Controller

- Ingress资源对象，即创建具体的转发到service的配置规则

---------

# 工作流程

## 1.创建ingress对象

集群用户向API Server提交ingress创建请求，定义域名与service的对应关系

## 2.解析负载均衡规则

ingress-controller通过和kubernetes APIServer交互，监测到到集群中ingress规则的变更，按照用户提交的规则生成负载均衡配置

## 3.加载负载均衡配置

ingress-controller运行的负载均衡器（nginx、haproxy）加载负载均衡配置到配置文件，并动态更新

## 4. 转发请求流量

外部流量访问域名，ingress-controller将请求直接转发到Service对应的后端Endpoint，不经过kube-proxy的转发， 此时控制器相当于是边缘路由器的功能

# 工作模式

## 1.LoadBalancer模式

用于公有云环境，Deployment部署ingress-controller，service type设为LoadBalancer，再为service自动创建绑定了公网IP的负载均衡器，只需将域名解析到负载均衡器的公网IP即可实现集群服务的对外暴露

## 2.NodePort模式

Deployment部署ingres-controller，service type设为NodePort，由于nodeport暴露的端口是随机分配，一般再搭建一套负载均衡器用于流量转发。此模式需为NodePort新增一层NAT，请求量级很大时性能会有一定影响

## 3.HostNetwork模式

DaemonSet部署ingress-controller，pod网络模式设为HostNetwork，与node节点的网络打通，直接使用宿主机的80/433端口访问，ingress-controller所在node节点类似于传统架构的边缘节点，如机房入口的nginx服务器。此模式整个请求链路最为简单，性能相对更好，适用于大并发量环境。由于直接绑定node节点的端口，故此每个node只能部署一个ingress-controller pod

---------

# 1.下载Nginx Ingress Controller资源配置文件

    wget -O ingress-nginx-deploy.yaml https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.2.1/deploy/static/provider/cloud/deploy.yaml

# 2.部署Nginx Ingress Controller

## 2.1 NodePort模式

### 2.1.1 配置service

    vi ingress-nginx-deploy.yaml

    
    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app.kubernetes.io/component: controller
        app.kubernetes.io/instance: ingress-nginx
        app.kubernetes.io/name: ingress-nginx
        app.kubernetes.io/part-of: ingress-nginx
        app.kubernetes.io/version: 1.2.1
      name: ingress-nginx-controller
      namespace: ingress-nginx
    spec:
      externalTrafficPolicy: Local
      ports:
      - appProtocol: http
        name: http
        port: 80
        # 设置绑定到节点的端口号
        # nodePort: 32080
        protocol: TCP
        targetPort: http
      - appProtocol: https
        name: https
        port: 443
        # 设置绑定到节点的端口号
        # nodePort: 32443
        protocol: TCP
        targetPort: https
      selector:
        app.kubernetes.io/component: controller
        app.kubernetes.io/instance: ingress-nginx
        app.kubernetes.io/name: ingress-nginx
      # 修改为NodePort类型
      type: NodePort

### 2.1.2 部署ingress-controller

    kubectl apply -f ingress-nginx-deploy.yaml

### 2.1.3 验证ingress-controller

    kubectl -n ingress-nginx get pod -o wide
    kubectl -n ingress-nginx get service
    kubectl -n ingress-nginx get ingressclasses

### 2.1.4 创建ingress

    vi nginx-ingress.yaml


    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: nginx-ingress
      namespace: default
    spec:
      # 设置Ingress控制器名称
      ingressClassName: nginx
      # 设置ingress主机规则列表，若未指定或无规则匹配，则所有流量都将发送到默认后端
      rules:
      # 设置虚拟主机域名
      - host: worker01
        # 设置网络协议http/https
        http:
          # 设置转发路径集合
          paths:
          - path: /
            # 设置路径匹配规则，Prefix表示基于URL路径前缀按/分割匹配且区分大小写，并按路径元素，即路径中由/分隔符分割的标签列表，逐个匹配；Exact表示精确匹配且区分大小写         
            pathType: Prefix
            # 设置流量转发的后端endpoint
            backend:
              service:
                # 设置后端关联的service
                name: nginx-service
                # 设置service的端口
                port: 
                  number: 80
          - path: /test
            # 设置路径匹配规则，Prefix表示基于URL路径前缀按/分割匹配且区分大小写，并按路径元素，即路径中由/分隔符分割的标签列表，逐个匹配；Exact表示精确匹配且区分大小写         
            pathType: Prefix
            # 设置流量转发的后端endpoint
            backend:
              service:
                # 设置后端关联的service
                name: nginx-service
                # 设置service的端口
                port: 
                  number: 80

### 2.1.5 部署ingress，访问ingress验证转发规则

    kubectl apply -f nginx-ingress.yaml

## 2.2 HostNetwork模式

### 2.2.1 配置网络模式

    vi ingress-nginx-deploy.yaml

    # 设置ingress-controller的service type为ClusterIP
    type: ClusterIP
    ---
    apiVersion: apps/v1
    # 设置ngress-controller部署为DaemonSet
    kind: DaemonSet
      # 设置ingress-controller dnsPolicy 
      dnsPolicy: ClusterFirstWithHostNet
      # 设置ngress-controller网络模式
      hostNetwork: true

### 2.2.2 部署ingress-controller

    kubectl apply -f ingress-nginx-deploy.yaml

### 2.2.3 验证ingress-controller

    kubectl -n ingress-nginx get pod -o wide
    kubectl -n ingress-nginx get service
    kubectl -n ingress-nginx get ingressclasses

### 2.2.4 创建ingress

    vi nginx-ingress.yaml


    apiVersion: networking.k8s.io/v1
    kind: Ingress
    metadata:
      name: nginx-ingress
      namespace: default
    spec:
      # 设置Ingress控制器名称
      ingressClassName: nginx
      # 设置ingress主机规则列表，若未指定或无规则匹配，则所有流量都将发送到默认后端
      rules:
      # 设置虚拟主机域名
      - host: worker01
        # 设置网络协议http/https
        http:
          # 设置转发路径集合
          paths:
          - path: /
            # 设置路径匹配规则，Prefix表示基于URL路径前缀按/分割匹配且区分大小写，并按路径元素，即路径中由/分隔符分割的标签列表，逐个匹配；Exact表示精确匹配且区分大小写         
            pathType: Prefix
            # 设置流量转发的后端endpoint
            backend:
              service:
                # 设置后端关联的service
                name: nginx-service
                # 设置service的端口
                port: 
                  number: 80   
      # 设置虚拟主机域名
      - host: worker02
        # 设置网络协议http/https
        http:
          # 设置转发路径集合
          paths:
          - path: /
            # 设置路径匹配规则，Prefix表示基于URL路径前缀按/分割匹配且区分大小写，并按路径元素，即路径中由/分隔符分割的标签列表，逐个匹配；Exact表示精确匹配且区分大小写         
            pathType: Prefix
            # 设置流量转发的后端endpoint
            backend:
              service:
                # 设置后端关联的service
                name: nginx-service
                # 设置service的端口
                port: 
                  number: 80

### 2.2.5 部署ingress，访问ingress验证转发规则

    kubectl apply -f nginx-ingress.yaml

---------

# 参考文档

- https://blog.csdn.net/MssGuo/article/details/123414161
- https://blog.csdn.net/supahero/article/details/121476304
- https://blog.csdn.net/qq_41582883/article/details/114003552
- https://blog.csdn.net/Yusheng9527/article/details/124140541