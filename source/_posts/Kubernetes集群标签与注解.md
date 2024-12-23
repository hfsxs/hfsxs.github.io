---
title: Kubernetes集群标签与注解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2021-09-11 21:56:28
---

标签和注解，Kubernetes集群基本概念，即是以键值对形式附加到集群资源对象（Node、Pod、Service）的元数据，应急集群应用的组织、标记及分组，以便于灵活、方便地进行资源分配、调度、配置、部署等管理工作

# 1.标签

Labels，标签，配合标签选择器用于查询和选择特定的资源对象，可在创建时附加，也可以通过更新操作进行修改，应用场景如下：

- 环境区分，关联不同的环境或特征，如开发、测试和生产环境或服务层次（前端、后端、数据库），以便针对不同环境进行部署和管理
- 版本管理，标记不同版本的应用，方便进行版本控制和回滚操作
- 负载均衡，选择特定的资源对象集合，选择性地将应用暴露给特定的服务或进行负载均衡
- 故障排查，筛选特定的应用实例，方便进行故障排查和日志分析
- 策略管理，定义发布策略，如灰度发布、AB测试等

## 1.1 创建标签

    kubectl label service nginx version = 1.0

## 1.2 查询标签

    kubectl get service nginx --show-labels

## 1.3 修改标签

    kubectl label service nginx "version = 2.0"

## 1.4 删除标签

    kubectl label service nginx version-

- 注：-，连字符，表示删除标签，若需删除多个标签则只需在每个之后附加连字符即可

# 2.注解

Annotations，注解，用于存储集群资源对象额外的非标识性信息，通常作为上下文信息被集成工具、监控系统和自动化流程调用，以更加灵活的方式传递配置信息，应用场景如下：

- 文档配置，将特定资源的目的、使用方法或历史见解以文档的形式作详细记录与描述，如资源对象更新的原因及滚动发布的副本集
- 工具集成，Kubernetes生态系统各种工具和控制器的提示或指令，如Prometheus监控集成配置等
- 参数配置，定义应用程序的配置参数，如数据库连接字符串、环境变量及Git哈希、时间戳、pull请求单号等

## 2.1 文档配置

    apiVersion: v1
    kind: Pod
    metadata:
      name: data-processing-pod
      annotations:
        purpose: "This pod is responsible for processing large datasets and generating reports."
    spec:
      containers:
        - name: data-processor
          image: data-processor-image

## 2.2 工具集成

    apiVersion: v1
    kind: Pod
    metadata:
      name: monitored-pod
      annotations:
        prometheus.io/scrape: "true"
        prometheus.io/port: "8080"
    spec:
      containers:
        - name: web-app
          image: web-app-image
          ports:
            - containerPort: 8080

## 2.3 参数配置

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: app-deployment
    spec:
      replicas: 3
      selector:
        matchLabels:
          app: my-app
      template:
        metadata:
          labels:
            app: my-app
          annotations:
            app-config/database-url: "jdbc:mysql://db-server:3306/mydatabase"
            app-config/max-connections: "100"
        spec:
          containers:
            - name: my-app-container
              image: my-app-image

---------

# 参考文档

- https://www.jianshu.com/p/1815a4281948
- https://blog.csdn.net/zhaopeng_yu/article/details/134920491
- https://blog.csdn.net/weixin_45310323/article/details/130718456