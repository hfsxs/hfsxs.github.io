---
title: Kubernetes集群服务发布方式详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 蓝绿发布
  - 滚动发布
  - 灰度发布
  - 容器云
  - 云原生
  - 云计算
date: 2023-07-21 10:22:55
---

应用程序升级面临的最大挑战是新旧业务切换，也即是将软件从测试最后阶段发布到生产环境时保证系统不间断提供服务。为了减小或避免应用更新时对客户使用的影响，以及因发布导致的流量丢失或服务不可用问题，针对不同的业务场景和技术需求，最为常见的发布方式分为三种，即蓝绿发布、灰度发布和滚动发布

# 1.蓝绿发布

蓝绿发布，即将应用服务集群分为逻辑上的蓝绿两组，先将绿组集群从负载均衡中移除进行升级，蓝组则继续对用户提供服务，直到顺利升级完毕再从新接入负载均衡。此后，蓝组重复绿组的流程，移除负载均衡、服务升级、升级完毕接入负载均衡。最后，整个项目集群升级完毕

蓝绿发布策略简单、易操作，升级与回滚速度快，全量迭代也更易测试各种场景，且无需顾虑瞬时流量的高压问题，但为了防范单组无法承载业务突发的情况，升级期间需要两倍的正常业务运行时所需资源，所需成本较高，特别是集群比较大的场景，如上千个节点的集群几乎不可实现

## 1.1 部署蓝组应用

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hexo
      namespace: devops
    spec:
      selector:
        matchLabels:
          app: hexo-server
          version: "v1.0"
      replicas: 6
      template:
        metadata:
          labels:
            app: hexo-server
            version: "v1.0"
        spec:
          containers:
            - name: hexo
              image: registry.sword.org/nginx:v1.0
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: hexo-nginx
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 100m
                  memory: 64M
              volumeMounts:
                - name: nginx-conf
                  mountPath: /etc/nginx/nginx.conf
                  subPath: nginx.conf
          volumes:
            - name: nginx-conf
              configMap:
                name: nginx.conf
          imagePullSecrets:
            - name: regcred

## 1.2 部署绿组应用

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hexo-v2.0
      namespace: devops
    spec:
      selector:
        matchLabels:
          app: hexo-server
          version: "v2.0"
      replicas: 6
      template:
        metadata:
          labels:
            app: hexo-server
            version: "v2.0"
        spec:
          containers:
            - name: hexo
              image: registry.sword.org/nginx:v2.0
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: hexo-nginx
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 100m
                  memory: 64M
              volumeMounts:
                - name: nginx-conf
                  mountPath: /etc/nginx/nginx.conf
                  subPath: nginx.conf
          volumes:
            - name: nginx-conf
              configMap:
                name: nginx.conf
          imagePullSecrets:
            - name: regcred

## 1.3 部署service

    apiVersion: v1
    kind: Service
    metadata:
      name: hexo-service
      namespace: devops
    spec:
      type: NodePort
      sessionAffinity: ClientIP
      selector:
        app: hexo-server
        version: "v1.0"
      ports:
        - port: 80
          targetPort: 80
          nodePort: 32080

## 1.4 切换流量入口，完成蓝绿发布

    apiVersion: v1
    kind: Service
    metadata:
      name: hexo-service
      namespace: devops
    spec:
      type: NodePort
      sessionAffinity: ClientIP
      selector:
        app: hexo-server
        version: "v2.0"
      ports:
        - port: 80
          targetPort: 80
          nodePort: 32080

# 2.滚动发布

滚动发布，即每次只升级一个或多个服务，升级完成后加入生产环境，不断执行这个过程，直到集群中的全部旧版本升级新版本

滚动发布需要配置自动更新策略和流量控制能力，以缩减部署时长与复杂度，且发布期间的新旧版本共存将会加大故障排查的难度，若是新版本出现的问题则切换过来的流量将全部受到影响，老版本的问题则会增加故障排查的迷惑性，系统将处于不稳定状态

---------

Kubernetes集群Deployment控制器通过rollingUpdate属性集成了滚动更新策略：


- maxSurge，最大可超期望节点数，百分比或绝对数值，默认为25%，建议配置为1
- maxUnavailable，最大不可用节点数，百分比或者绝对数值，默认为25%，建议配置为0

---------

## 2.1 设置滚动发布策略

    kubectl -n devops patch deployments.apps hexo -p '"spec":"strategy":"rollingUpdate":"maxSurge":1,"maxUnavailable":0'

## 2.2 执行滚动发布

    kubectl -n devops set image deployment hexo *=registry.sword.org/hexo:v0.48

## 2.3 应用回滚，滚动发布失败

    # 查看历史版本
    kubectl -n devops rollout history deployment hexo
    # 查看版本2的详细内容
    kubectl -n devops rollout history deployment hexo --revision 3
    # 回滚到版本2
    kubectl -n devops rollout undo deployment hexo --to-revision=3

# 3.灰度发布

灰度发布，即金丝雀发布，来源于矿工下矿前以金丝雀是否能存活来判断矿洞是否有毒气的探测方式，类似于游戏体验服，即部分用户进行升级测试，如新版本业务正常则逐步推广，直到所有用户完成迁移

灰度发布保障了系统整体稳定性，以小步快跑的快速完成迭代，初始阶段就能发现、调整问题，新功能的性能、稳定性和健康状况将经过逐步部署、验证、评估，若出现问题由于体验用户不多，影响范围相对可控，但只适用于兼容迭代的方式，大版本不兼容的场景不适用，且对业务有自动化要求

## 3.1 内置命令方式

### 3.1.1 执行金丝雀发布

    kubectl -n devops set image deployment hexo *=registry.sword.org/hexo:v0.50 && kubectl -n devops rollout pause deployment hexo

- 注：将命名空间devops的hexo deployment的镜像更新到hexo:v0.50版本，创建一个新pod就立即暂停更新，之后经过一段时间的验证再决定取消暂停继续更新还是回滚

### 3.1.2 继续更新，完成金丝雀发布

    kubectl -n devops rollout resume deployment hexo

### 3.1.3 应用回滚，金丝雀发布失败

    # 查看历史版本
    kubectl -n devops rollout history deployment hexo
    kubectl -n devops rollout history deployment hexo --revision 3
    kubectl -n devops rollout undo deployment hexo --to-revision=3

---------

# 参考文档

- https://developer.aliyun.com/article/895549
- https://www.freesion.com/article/41971508841
- https://blog.csdn.net/ll945608651/article/details/131507220