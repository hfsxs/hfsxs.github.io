---
title: Kubernetes集群Service详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2022-02-12 23:00:19
---

Service，即服务，Kubernetes集群最核心的概念之一，定义了逻辑上一组Pod的访问策略，即通过标签选择器选择一组Pod，并为其分配一个访问入口地址，从而实现这个由Pod副本所组成的集群的访问。Service使Kubernetes集群具备了微服务平台的功能，即通过分析、识别并建模业务系统中所有服务为Service，将业务系统转换为由多个提供不同业务能力而又彼此独立的微服务单元，微服务之间通过TCP/IP进行通信，从而拥有了强大的分布式能力、弹性扩展能力和容错能力

---------

# 1.概念引入

Kubernetes集群中Pod是应用程序的载体，可以通过Pod的IP来访问应用程序，但Pod会随着集群规模、节点状态、用户缩放等因素动态变化，Pod的名称、运行节点、IP地址也会随之而变化。这样，就给业务系统的内部调用带来很大的不便。故此，引入Service这一概念

# 2.工作流程

## 2.1 分配虚拟IP

集群用户向API Server提交Service创建请求，运行在集群所有Node节点的Kube-Proxy组件通过API Serve监测到新增的Service之后为其分配集群虚拟IP，即ClusterIP，若定义时明确指定虚拟IP，则分配指定IP，如未指定则自动分配

## 2.2 选择pod副本组

根据标签选择器选取符合条件的Pod，Controller Manager组件的Endpoints Controller创建Endpoint，即包含这组Pod IP及访问端口的逻辑组合，并将Endpoint信息写入Etcd数据库

## 2.3 生成流量转发规则

Kube-Proxy组件监测到Service、Endpoint的变更，根据监测到的信息设置流量转发规则，即将一个集群虚拟IP及端口号与一个或多个Pod的IP、端口做映射，以作为后端Pod组的访问代理

## 2.4 配置服务发现

集群DNS服务器，如CoreDNS，监测到增的Service，根据Service名称、分配的集群虚拟IP、端口号创建DNS条目

## 2.5 Service访问及流量转发

通过服务名称访问Service时，首先由DNS将服务名称转换成集群虚拟IP与端口号，Kube-Proxy组件根据转发规则对Service的流量计算负载均衡，最后转发到位于后端的Pod

# 3.代理模式

Kube-Proxy组件负责将Service的请求转发到后端的某个Pod实例上，并配置内部实现服务的负载均衡与会话保持规则，实质上就是一个智能的软件负载均衡器。不同于常见的拥有一个独立IP负载均衡器，而是为每个Service分配了一个全局唯一的虚拟IP地址，即Cluster IP，实际上就是用于生成Iptables或IPVS转发规则时使用的IP地址，仅用于实现Kubernetes集群网络的内部通讯，仅能够将规则中定义的转发服务的请求作为目标地址予以响应，且在Service的整个生命周期内都不会改变

Kube-Proxy将请求代理至相关端点的方式有三种，即userspace、iptables和ipvs

## 3.1 userspace

userspace，即用户空间，指的是Linux操作系统的用户空间。此模式下，Kube-Proxy负责跟踪API Server上的Service和Endpoint对象的变动（创建或删除），并根据此调整Service资源的定义

此模式下，请求流量到达内核空间后经由套接字送往用户空间Kube-Proxy，而后再由它送回内核空间，并调度至后端Pod。由于请求在内核空间和用户空间来回转发必然会导致效率不高，Kubernetes1.1版本之后即被废弃

## 3.2 iptables

类似于userspace代理模式，iptables代理模式中，Kube-Proxy负责跟踪API Server上Service和Endpoint对象的变动（创建或删除），并据此做出Service资源定义的变动。同时，对于每个Service，都将会创建iptables规则直接捕获到达ClusterIP和Port的流量，并将其重定向至当前Service后端。对于每个Endpoint对象，Service资源会为其创建iptables规则并关联至挑选的后端Pod资源，默认算法是随即调度（random）。此模式自1.2版本开始成为默认的类型

在创建Service资源时，集群中每个节点上的Kube-Proxy都会收到通知并将其定义为当前节点上的iptables规则，用于转发工作接口接收到的与此Service资源的ClusterIP和端口的相关流量。客户端发来的请求被相关的iptables规则进行调度和目标地址转换（DNAT）后再转发至集群内的Pod对象上

相对于userspace模式，iptables模式无须将流量在用户空间和内核空间来回切换，因而更加高效和可靠。其缺点是iptables代理模型不会在被挑中的后端Pod资源无响应时自动进行重定向，而userspace模型则可以

## 3.3 ipvs

此模式下，Kube-Proxy跟踪API Server上Service和Endpoint对象的变动，据此来调用netlink接口创建ipvs规则，并确保与API Server中的变动保持同步。与iptables规则的不同之处仅在于其请求流量的调度功能由ipvs实现，其余功能仍由iptables完成。Kubernetes自1.9-alpha版本引入了ipvs代理模型，且自1.11版本起成为默认设置

类似于iptables模式，ipvs构建于netfilter的钩子函数之上，但使用hash作为底层数据结构并工作于内核空间，因此具有流量转发速度快、规则同步性能好的特性。此外，ipvs还支持众多的调度算法，例如rr、lc、dh、sh、sed和nq等

# 4.Service类型

## 4.1 ClusterIP

默认的Service类型，通过集群自动分配的内部IP地址暴露服务，该地址仅在集群内部可达，无法被集群外部的客户端访问


    apiVersion: v1
    kind: Service
    metadata:
      # 设置service名字
      name: redis-server
      namespace: default
    spec:
      selector: 
        # 设置标签选择器，关联指定的pod
        app: redis-servers
      # 设置service类型，默认为ClusterIP
      type: ClusterIP
      # 设置clusterIP，若不指定则自动分配
      clusterIP: 172.16.66.66
      ports:
      # 设置service访问端口
      - port: 6379
        # 设置pod端口
        targetPort: 6379

## 4.2 NodePort

基于ClusterIP而设计，依然会为Service分配集群IP地址，并将此作为NodePort的路由目标，工作原理就是将Service的端口映射到每个Node节点的同一个端口，用于将集群外部的用户请求转发至目标Service的ClusterIP和Port

- 集群内部Pod访问流量走向为：服务名 --- >> 集群虚拟IP:端口号 --- >> kube-proxy转发到pod
- 集群外部Pod访问流量走向为：节点IP:NodePort --- >> 集群虚拟IP:端口号 --- >> kube-Proxy转发到Pod

---------

    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-server
      namespace: default
    spec:
      type: NodePort
      selector:
        app: nginx-servers
      ports:
      - protocol: TCP
        port: 80
        targetPort: 80
        # 设置绑定到node节点的端口，若不指定则默认分配，取值范围为30000-32767
        nodePort: 30080

## 4.3 LoadBalancer

基于NodePort而设计，通过公有云服务商提供的负载均衡器将服务暴露到集群外部，也具有NodePort和ClusterIP。一个LoadBalancer类型的Service会指向关联Kubernetes集群外部的、切实存在的某个负载均衡设备，该设备通过工作节点之上的NodePort向集群内部发送请求流量。优势在于能够把来自集群外部客户端的请求调度至所有节点（或部分节点）的NodePort之上，而非依赖于客户端自行决定连接至哪个节点，从而避免了因客户端指定的节点故障而导致的服务不可用

目前已不再推荐使用，建议使用Ingress Controller

## 4.4 ExternalName

通过将Service映射至由externalName字段的内容所指定的主机名来暴露服务，此主机名需被DNS服务解析至CNAME类型的记录。实际之，该类型的Service并不是Kubernetes集群定义，而是把集群外部的某服务以DNS CNAME记录的方式映射到集群内，从而让集群内的Pod资源能够访问外部的Service。因此，该类型的Service没有ClusterIP和NodePort，也没有标签选择器用于选择Pod资源，也不会有Enpoints存在

## 4.5 HeadLess

基于ClusterIP而设计，但通过指定clusterIP属性为None而定义Service，即不为服务分配集群虚拟IP，自然也就不能在DNS插件中添加服务相关条目，Kube-Proxy组件不会为其添加转发规则，也就无法利用Kube-Proxy的转发、负载均衡功能

HeadLess Service依然会根据标签选择器创建Endpoint，并根据Endpoint向DNS插件中添加条目，DNS会将Headless Service的后端直接解析为Pod组的IP列表。这类Service主要供StatefulSet使用，因为StatefulSet能保证其管理的Pod有序，名称地址等特征保持不变


    apiVersion: v1
    kind: Service
    metadata:
      name: kafka-server
    spec:
      selector:
        app: kafka-servers
      # 设置cluserIP为空
      clusterIP: None
      ports:
      - port: 9092
        targetPort: 9092

---------

# 参考文档

- https://k.i4t.com/kubernetes_service.html
- https://cloud.tencent.com/developer/article/1981390
- https://www.modb.pro/db/388641
- https://blog.csdn.net/dkfajsldfsdfsd/article/details/81200411
- https://blog.csdn.net/bbj1030/article/details/124582208