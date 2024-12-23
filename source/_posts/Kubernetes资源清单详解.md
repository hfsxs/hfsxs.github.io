---
title: Kubernetes资源清单详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云计算
date: 2021-05-27 16:32:59
---

Kubernetes对象通常通过定义资源清单进行创建，资源清单描述了该对象的属性，决定了用户对其在生命内的期望状态。资源清单有许多可供选择的表示对象属性的字段，必须进行配置的字段的三个，即apiVersion，创建对象所用Kubernetes API版本；kind，创建对象所属类别；metadata，唯一标识对象的元数据，包括一个name、UID和namespace

---------

# 1.属性字段

    apiVersion，字符串型字段，Kubernetes API版本，基本为V1，查询命令为：       kubectl api-versions
    kind，定义对象的资源类型与角色，比如Pod
    metadata，对象型字段，元数据对象，唯一标识对象的元数据
      name，字符串型字段，元数据对象的名字，如定义Pod的名字
      namespace，字符串型字段，元数据对象的命名空间，默认为

    spec，对象型字段，对象的详细描述
      containers，列表型字段，定义对象的容器列表
      name，字符串型字段，定义容器的名字
      image，字符串型字段，定义容器所属镜像的名称
      imagePullPolicy，字符串型字段，定义镜像拉取策略，可选值有三个：Always，每次都尝试重新拉取镜像；Never；仅使用本地镜像；IfNotPresent，如果本地有镜像就使用本地镜像，没有则拉取镜像，默认为Always

        command，列表型字段，指定容器启动命令，可指定多个，若不指定则使用镜像打包时的启动命令
        args，列表型字段，指定容器启动命令参数，可指定多个
        workingDir，字符串型字段，指定容器的工作目录
        volumeMounts，列表型字段，指定容器内部的存储卷配置

          name，字符串型字段，指定被容器挂载的存储卷的名称
          mountPath，字符串型字段，指定被容器挂载的存储卷的路径
          readOnly，布尔型字段，指定存储卷路径的读写模式，true或false，默认为读写模式

        ports，列表型字段，指定容器需要用到的端口列表

          name，字符串型字段，指定端口名称
          containerPort，字符串型字段，指定容器需要监听的端口号
          hostPort，字符串型字段，指定容器所在主机需要监听的端口号，默认同containerPort，若定义了该字段，则同台主机无法启动该容器的相同副本，会造成端口号冲突

          protocol，字符串型字段，指定端口协议，支持TCP和UDP,默认值为TCP

        env，列表型字段，指定容器运行前需要设置的环境变量列表

          name，字符串型字段，指定环境变量名称
          value，字符串型字段，指定环境变量值

        resources，对象型字段，指定资源限制和资源请求

          limits，对象型字段，指定设置容器运行时资源的运行上限
            cpu，字符串型字段，指定cpu的限制，单位为core数，用于docker run --cpu-shares参数
            memory，字符串型字段，指定mem内存的限制
          requests，对象型字段，指定容器启动和调度时的限制设置
            cpu，字符串型字段，cpu请求，单位为core数，容器启动时初始化可用数量
            memory，字符串型字段，内存请求，容器启动的初始化可用数量

      restartPolicy，字符串型字段，定义Pod的重启策略，可选值有三个：Always，Pod一旦终止运行则无论任何原因kubelet服务都将尝试重启；OnFailure，Pod以非零码（异常）终止时kubelet才会尝试重启，若是正常结束（退出码为0）则kubelet将不会重启；Never，kubelet只将退出码报告给master，不会进行重启

      nodeSelector，对象型字段，定义Node的Label过滤标签，以key:value格式指定
      imagePullSecrets，对象型字段，定义拉取镜像时使用的secret，以name:secretkey格式指定
      hostNetwork，布尔型字段，定义是否使用主机网络模式，默认值为false，设   置true表示使用宿主机网络， 不使用docker网桥，将无法在同一台宿主机上启动第二个副本

# 2.yaml基本语法

- 缩进时不允许使用tab，只能用空格
- 缩进的数目不固定，可任意选择，但全局缩进数目要保持统一，即相同层级的元素左对齐
- 注释使用 #

---------

# 3.资源清单基本格式

    apiVersion: apps/v1
    # 声明一个Deployment资源对象
    kind: Deployment
    metadata:
      name: nginx-deployment  
    spec:
      # 通过标签选择被控制的pod
      selector:
        matchLabels:
          app: nginx-servers
      # 声明pod副本数
      replicas: 2
      # 定义pod
      template:
    metadata:
      # 给pod打上标签
      labels:
        app: nginx-servers
    spec:
      containers:
        # 声明容器名称、镜像及镜像拉取策略
        - name: nginx
          image: sword618/nginx
          imagePullPolicy: IfNotPresent
          ports:
            - containerPort: 80
              name: http-nginx
              protocol: TCP
          # 声明容器资源限制
          resources:
              limits:
                cpu: 500m
                memory: 200Mi
              requests:
                cpu: 200m
                memory: 100Mi
    # 声明资源对象分割符          
    ---
    apiVersion: v1
    # 声明一个Service资源对象
    kind: Service
    metadata:
      name: nginx-service
    spec:
      # 声明service的类型为NodePort
      type: NodePort
      # 声明service的会话保持机制，None为默认值，表示随机调度；ClientIP表示来自于同一个客户端的请求调度到同一pod
      sessionAffinity: ClientIP
      # 通过标签选择被控制的pod
      selector:
        app: nginx-servers
      ports:
      # 声明service集群内部访问端口
      - port: 80
        # 声明pod容器端口
        targetPort: 80
        # 声明绑定到node的端口，如不指定则随机分配，范围为30000-32767
        nodePort: 32000