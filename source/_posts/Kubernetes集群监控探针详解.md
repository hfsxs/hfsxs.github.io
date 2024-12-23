---
title: Kubernetes集群监控探针详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2023-02-10 08:51:20
---

Probe，即探针，Kubernetes集群监控容器运行状态的机制，是由kubelet组件对容器执行的定期检查，以监测容器是否正常运行、是否能够正常响应请求以及容器内部的应用程序是否正常运行，并根据探测到的状态做出相应的动作。默认情况下，集群只能检查容器主进程运行状况，而无法判断应用是否能正常提供服务，无法反映真实的健康状态。探针弥补了这一不足，实现了应用的健康检查，完善了集群自我修复能力，从而保障了业务的连续性与稳定性。Kubernetes集群提供了三种探针，即startupProbe、livenessProbe和readinessProbe

# 探测流程

容器启动时，三种探针依次执行，根据每次的探测结果来做相应的动作，探测结果有三种，即Success，表示通过检测；Failure，表示未通过检测；Unknown，表示检测没有正常进行

## 1.启动探针检测

startupProbe，启动探针，容器启动时首先执行，若探测失败则将重启容器，只会在容器启动时执行一次

## 2.存活探针定期检测

livenessProbe，存活探针，定期检测容器是否处于运行状态，若探测失败则由kubelet销毁该容器，并根据容器的重启策略restartPolicy做相应的处理。若未配置存活探针，则默认状态为Success，即探针返回的值永远为Success

## 3.就绪探针定期检测

readinessProbe，就绪探针，定期检测容器是否已准备好接收请求，用于判断应用是否健康，即能否正常提供服务，若探测失败则将从Service的EndPoints列表中剔除该Pod的IP:Port，直到探针再次成功

- 注：以上流程为三种探针都做配置的情况

# 探测方式

Kubernetes探针的探测机制支持三种健康检查方法，即命令行exec，httpGet和tcpSocket，其中exec通用性最强，适用与大部分场景，tcpSocket适用于TCP业务，httpGet适用于web业务

- exec，自定义健康检查，在容器中执行指定的命令，若执行成功，退出码为0，则表明容器健康
- httpGet，通过容器的IP地址、端口号及路径调用HTTP Get方法，若响应的状态码大于等于200且小于400，则表明容器健康
- tcpSocket，通过容器IP地址和端口号执行TCP检查，若能够建立TCP连接，则表明容器健康

# 配置参数

- initialDelaySeconds，启动liveness、readiness探针前的等待时长，单位为秒，默认为0
- periodSeconds，探针检测的频率，单位为秒，默认为1
- timeoutSeconds，探针检测的超时时长，单位为秒，默认为1
- successThreshold，探针需要通过的最小连续成功检查次数，通过即为探测成功，默认为1
- failureThreshold，将探针标记为失败的重试次数，liveness探针失败将导致Pod重启，readiness探针失败则将标记Pod为未就绪（unready）状态，默认为1

# 1.startupProbe

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

# 2.livenessProbe

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
              livenessProbe:
                httpGet:
                  path: /
                  port: 80
                initialDelaySeconds: 10
                periodSeconds: 5
          imagePullSecrets:
            - name: regcred

# 3.readinessProbe

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
              livenessProbe:
                httpGet:
                  path: /
                  port: 80
                initialDelaySeconds: 10
                periodSeconds: 5
              readinessProbe:
                tcpSocket:
                  port: 80
                initialDelaySeconds: 5
                periodSeconds: 5
          imagePullSecrets:
            - name: regcred
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: test-nginx
    spec:
      selector:
        app: test
      ports:
      - protocol: TCP
        port: 80
        targetPort: 80
        
---------

# 参考文档

- https://blog.csdn.net/m0_71518373/article/details/127781889
- https://blog.csdn.net/ApexPredator/article/details/131170506
- https://blog.csdn.net/weixin_40579389/article/details/129930165