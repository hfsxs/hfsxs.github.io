---
title: Kubernetes集群网络模型详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 网络
  - 容器云
  - 云原生
  - 云计算
date: 2021-11-25 23:06:43
---

Kubernetes网络实现是集群的核心部分，宗旨就是在容器化的应用程序之间共享网络资源。集群中同一个节点上部署多个业务应用，而每个应用都需要自己的网络空间。为避免与其他业务网络冲突，需要Pod有自己独立的网络空间，而Pod中应用需要和其他应用进行通信，就需要Pod能够跟不同的应用互相访问。故此，网络系统的设计要解决如下几个问题：

- 同一节点上Pod之间的通信
- 不同节点上Pod之间的通信
- 外部网络和集群内Pod之间的通信

---------

容器常见的网络标准有两种，即Docker公司提出的CNM（Container Network Model）及CoreOS公司提出的CNI（Container Network Interface）。CNM和CNI并不是网络实现，而只是网络规范和网络体系，也即是一种网络设计模型，从研发的角度来看其实就是一组接口，底层还是由具体的网络插件来实现。CNI由于兼容其他容器技术（如rkt）及上层编排系统，受到了大力推广，目前已经成为Kubernetes所采用的主流网络标准

CNI网络插件目前主要有两种，即Flannel与Calico

---------

# 1.flannel

## 1.1 工作原理

flannel实质上是一种覆盖网络(overlaynetwork)，工作原理就是为集群中的所有node分配一个subnet（子网），容器从该subnet中分配到一个同属一个内网全集群唯一的虚拟IP，这些IP可以在主机间路由，容器间无需NAT和端口映射就可以跨主机通信。在此基础上将TCP数据包封装在另一种网络包里进行路由转发和通信。目前flannel已支持udp、vxlan、host-gw、aws-vpc、gce和alloc路由等数据转发方式，默认的节点间数据通信方式是UDP

## 1.2 网络架构

## 1.2.1 flanneld

flanneld进程连接etcd，负责维护集群可分配IP地址的资源池，同时监控etcd中每个Pod的实际地址，并在内存中建立一个Pod路由表

### 1.2.2 flannel0网桥

flanneld进程创建的虚拟网卡，连接docker0和节点物理网卡，根据内存中维护的Pod路由表将docker0发来的数据包封装，利用物理网卡投递到目标flanneld，目标flanneld将数据包解包后发送给本机docker0网卡，从而完成与另一个pod的通信

### 1.2.3 etcd

数据库存储，负责维护节点上划分的子网配置信息，如子网网段、外部IP等

## 1.3 工作模式

Flannel有三种网络实现模式，即UDP、VXLAN、host-gw

### 1.3.1 udp模式

使用设备flannel.0进行封包解包，不是内核原生支持，上下文切换较大，性能差，目前已被弃用

### 1.3.2 vxlan模式

使用flannel.1进行封包解包，内核原生支持，性能较强

### 1.3.3 host-gw模式

无需flannel.1这样的中间设备，直接宿主机当作子网的下一跳地址，性能最强，性能损失大约在10%左右，优于基于VXLAN“隧道”机制的性能损失在20%~30%左右的网络方案

# 2.calico

## 2.1 工作原理

calico是一个纯三层的虚拟网络，工作原理是用linux内核将宿主机节点虚拟为一个vRouter（虚拟路由器），这些vRouter组成了一个全连通的网络，集群中所有的容器都是连接这个网络的路由，每个路由节点通过BGP协议将自身的路由信息向整个Calico网络传播，从而将容器的地址信息维护成一张路由表，据此实现了跨主机容器的通信

## 2.2 网络架构

### 2.2.1 Felix

Calico Agent，运行在node上，负责为容器设置网络资源，如IP地址、路由规则配置、ACLS规则的配置及下发（ipvs、iptables）等，保证跨主机容器网络互通

### 2.2.2 BGP Client

负责把Felix在各Node上设置的路由信息通过BGP协议广播到Calico网络，确保网络的有效性

### 2.2.3 Route Reflector

大规模部署时使用，摒弃所有节点互联的mesh模，通过一个或多个BGP Reflector来完成集中式的分级路由分发

### 2.2.4 etcd

数据库存储，负责网络元数据一致性，确保Calico网络状态的一致性

### 2.2.5 CalicoCtl

Calico的命令行管理工具

## 2.3 工作模式

Calico有两种网络实现模式，即IPIP模式和BGP模式

### 2.3.1 IPIP模式

Calico官方默认的工作模式，启动后会在node上创建一个设备tunl0，容器的网络数据会经过该设备被封装一个ip头再转发

该模式是将IP数据包嵌套在另一个IP包里，即把IP层封装到IP层的一个tunnel（隧道），作用相当于一个基于IP层的网桥。一般来说，普通的网桥是基于mac层的，并不需要IP，而该模式下的网桥则是通过两端的路由做成tunnel，从而将两个本来不通的网络通过点对点连接起来，网络走向：

    pod1 cali0 ---> cali*** ---> tunl0 ---> node1 eth0 ---> node2 eth0 ---> tunl0 ---> cali*** ---> pod2 cali0

### 2.3.2 BGP模式

BGP，Border Gateway Protocol，即边界网关协议，是互联网上一个核心的去中心化自治路由协议，通过维护IP路由表或前缀表来实现自治系统（AS）之间的可达性，属于矢量路由协议。BGP不使用传统的内部网关协议（IGP）的指标，而使用基于路径、网络策略或规则集来决定路由，因此更适合称之为矢量性协议而不是路由协议。实质上就是直接使用物理机作为虚拟路由器（vRouter），不再创建额外的隧道

该模式启动后，将为容器生成veth pair，一端作为容器网卡加入到容器的网络命名空间，并设置IP和掩码，另一端直接暴露在宿主机上，并通过设置路由规则将容器IP暴露到宿主机的通信路由上。同时，calico为每个主机分配了一段子网作为容器可分配的IP范围，这样就可以根据子网的CIDR为每个主机生成比较固定的路由规则

当容器需要跨主机通信时，主要经过以下步骤

1.容器流量通过veth pair到达宿主机的网络命名空间上
2.根据容器要访问的IP所在的子网CIDR和主机上的路由规则，找到下一跳要到达的宿主机IP
3.流量到达下一跳的宿主机后，根据当前宿主机上的路由规则，直接到达对端容器的veth pair插在宿主机的一端，最终进入容器

此模式网络走向：

    pod1 cali0 ---> cali*** ---> node1 eth0 --->node2 eth0 ---> cali*** ---> pod2 cali0

---------

# 参考文档

- https://www.kubernetes.org.cn/2059.html
- https://www.cnblogs.com/v-fan/p/14452770.html
- https://cloud.tencent.com/developer/article/1804680
- https://blog.csdn.net/Thorne_lu/article/details/121391669
- https://www.jianshu.com/p/ecf874d74d61
- https://blog.51cto.com/u_10272167/2698291