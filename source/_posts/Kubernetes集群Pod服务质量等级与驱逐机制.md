---
title: Kubernetes集群Pod服务质量等级与驱逐机制
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2023-08-11 10:48:15
---

Qos，Quality of Service，即服务质量等级，是kubernetes集群通过对容器资源限制的方式以保障容器生命周期内有足够运行资源的机制，标记了集群对每个Pod服务质量的预期，决定了节点资源紧张时Pod被驱逐的级别

# 1.资源限制

kubernetes集群以公平、合理的方式整体统筹集群资源的分配，但由于CPU、内存等资源的独占性，即资源已经分配给了某容器，同样的资源不会在分配给其他容器，就不可避免的存在着资源利用率相对较低的容器所造成的资源浪费或资源竞争。因此，通常会对Pod的资源使用量进行限制，以保障系统能够稳定的运行

kubernetes集群通过设置requests和limits这两个属性对资源进行分配与限制，作用的指标即为CPU与内存，若不设置则表示容器可占用全部的节点资源。建议资源限制定义在容器而非Pod上，因为不同容器的资源需求可能不一致

## 1.1 Requests

Pod启动时申请分配的资源大小，即容器运行可能用不到这些额度的资源，但用到时必须确保有这么多的资源使用，主要体现在Pod调度时，申请范围为0到节点的最大配置，即0 <= Requests <=Node Allocatable

## 1.2 Limits

Pod运行时最大可用的资源大小，即硬限制，主要体现在Pod运行时，申请范围为requests到无限，即Requests <= Limits <= Infinity

# 2.Qos等级

Qos基于资源限制对Pod服务质量的预期进行管理，提供了节点OOM控制的级别，即对于内存这种不可压缩型资源，若发生超载触发节点OOM机制就将销毁或驱逐Pod，其优先级就取决于QOS。QoS级别分为三类，即Guaranteed、Burstable和BestEffort

    # 查看Pod的Qos等级
    kubectl get pod nginx -o yaml | grep qos

## 2.1 Guaranteed

Pod所有容器CPU和Memory同时设置相同的limits即为该级别，优先级最高，最不易被销毁或驱逐，除非内存需求超限或OMM时没有其他更低优先级的存在

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.cn-hangzhou.aliyuncs.com/swords/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 200m
                  memory: 200Mi
                requests:
                  cpu: 200m
                  memory: 200Mi
              startupProbe:
                httpGet:
                  path: /
                  port: 80
                initialDelaySeconds: 10
                periodSeconds: 5
          imagePullSecrets:
            - name: regcred

- 注：若容器只指明limit而未设定request，则request等于limit

## 2.2 Burstable

Pod任一容器的requests和limits设置不同即为该级别，优先级中等，同级别类容器资源占用多的先被销毁或驱逐

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.cn-hangzhou.aliyuncs.com/swords/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 200m
                  memory: 200Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
              startupProbe:
                httpGet:
                  path: /
                  port: 80
                initialDelaySeconds: 10
                periodSeconds: 5
          imagePullSecrets:
            - name: regcred

## 2.3 BestEffort

Pod所有容器的requests与limits均未设置即为该级别，优先级最低，最先被销毁或驱逐

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.cn-hangzhou.aliyuncs.com/swords/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              startupProbe:
                httpGet:
                  path: /
                  port: 80
                initialDelaySeconds: 10
                periodSeconds: 5
          imagePullSecrets:
            - name: regcred

Qos虽然能规避Pod耗尽节点全部资源，导致sshd、docker、kubelet等关键进程OOM，最终引发集群雪崩的重大故障，但也可能会导致资源占用远远大于Pod正常运行所需量，加大业务成本。建议详细分析历史资源的请求、使用情况和利用率，并优化Pod的资源占用，再设置合理的Qos策略

# 3.驱逐机制

Eviction，即驱逐，即kubernetes集群节点出现异常时为保障工作负载的可用性而由kubelet将该节点上运行的Pod销毁再调度的机制。kubernetes集群Pod驱逐分为三类，即手工驱逐、污点驱逐和抢占与节点压力驱逐

## 3.1 手工驱逐

手动驱逐，使用drain命令直接删除节点上所有Pod，建议先禁止节点调度，然后再执行排空节点的命令

## 3.2 污点驱逐

污点驱逐，将节点打上不可调度的污点而将Pod驱逐出去

## 3.3 抢占驱逐

抢占驱逐，Pod调度时所有节点的可用资源都不足以承载而将其挂起，即触发抢占逻辑，然后由scheduler组件基于PriorityClass所定义的优先级进行轮询，若某个节点存在优先级低于所要调度Pod的优先级，则将其驱逐以回收部分资源，从而完成调度

## 3.4 节点压力驱逐

节点压力驱逐，即基于Qos策略的驱逐机制，由kubelet组件执行

---------

# 参考文档

- http://docs.kubernetes.org.cn/769.html
- https://blog.51cto.com/liruilong/5929798
- https://blog.51cto.com/u_15715098/5733127
- https://developer.aliyun.com/article/1237138
- https://www.cnblogs.com/xunweidezui/p/16531596.html