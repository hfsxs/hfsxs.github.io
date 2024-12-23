---
title: Kubernetes集群网络策略详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 网络
  - 容器云
  - 云原生
  - 云计算
date: 2023-09-01 10:58:27
---

NetworkPolicy，即网络策略，是Kubernetes集群控制Pod通信规则的命名空间级别的资源对象，通过标签筛选Pod组并定义规则管控组内流量，从而为集群提供更精细的流量控制和租户隔离机制，最终削减应用网络攻击的影响范围。网络策略实现依靠CNI网络插件完成，如Calico、Weave和Antrea等，flannel则不支持

# 工作原理

- 1.集群管理员通过API或Web页面的方式创建NetworkPolicy资源对象
- 2.CNI插件的NetworkPolicyController监听到新增的NetworkPolicy资源，读取到具体信息后写入etcd数据库
- 3.节点运行的CNI Agent（calico-felix）组件从etcd数据库中获取NetworkPolicy资源，调用iptables做相应配置

# 1.配置默认网络策略

Kubernetes集群默认不对Pod流量做任何限制，既能够与集群上其他任何Pod通信，也能够与集群外部的网络端点通信，也即不具备网络隔离功能。NetworkPolicy通过附加到命名空间所属Pod的方式管控Pod的入站（Ingress）和出站（Egress）流量，被附加的Pod只放行网络策略明确允许的流量，未被标签选择器选中的Pod流量则不受影响，且网络策略是叠加的关系，不会产生冲突，其顺序也不影响策略的结果

    kubectl create namespace test
    kubectl -n test run nginx001 --image nginx --image-pull-policy=IfNotPresent --labels app=nginx
    kubectl -n test run nginx002 --image nginx --image-pull-policy=IfNotPresent --port 80 --expose --labels app=nginx
    # 查看命名空间下所有网络策略，默认为空
    kubectl -n test get networkpolicy

## 1.1 配置默认入站流量策略

### 1.1.1 默认拒绝所有入口流量

命名空间所有容器都不允许任何进入

    apiVersion: networking.k8s.io/v1 
    kind: NetworkPolicy 
    metadata: 
      name: default-deny-ingress 
    spec: 
      podSelector: {} 
      policyTypes: 
        - Ingress

### 1.1.2 默认允许所有入口流量

命名空间所有容器都允许任何流量进入

    apiVersion: networking.k8s.io/v1 
    kind: NetworkPolicy 
    metadata: 
      name: allow-all-ingress 
    spec: 
      podSelector: {} 
      ingress: 
        - {} 
      policyTypes: 
        - Ingress

## 1.2 配置默认出站流量策略

### 1.2.1 默认拒绝所有出口流量

    apiVersion: networking.k8s.io/v1 
    kind: NetworkPolicy 
    metadata: 
      name: default-deny-egress 
    spec: 
      podSelector: {} 
      policyTypes: 
        - Egress

### 1.2.2 默认允许所有出口流量

    apiVersion: networking.k8s.io/v1 
    kind: NetworkPolicy 
    metadata: 
      name: allow-all-egress 
    spec: 
      podSelector: {} 
      egress: 
        - {} 
      policyTypes: 
        - Egress

## 1.3 默认拒绝所有入口和所有出口流量

    apiVersion: networking.k8s.io/v1 
    kind: NetworkPolicy 
    metadata: 
      name: default-deny-all 
    spec: 
      podSelector: {} 
      policyTypes: 
        - Ingress 
        - Egress

# 2.配置Pod标签选择器方式网络策略

## 2.1 入站网络策略

    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: my-network-policy
      namaspace: test
    spec:
      podSelector:
        matchLabels:
          # 设置网络策略所匹配Pod的标签，若标签为空则匹配命名空间所属全部Pod
          app: nginx
      policyTypes:
      - Ingress
      ingress:
      # 设置允许访问的Pod
      - from:
        - podSelector:
            matchLabels:
              role: podclient
        ports:
        - protocol: TCP
          port: 80

## 2.2 出站网络策略

    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: my-network-policy
      namaspace: test
    spec:
      podSelector:
        matchLabels:
          # 设置网络策略所匹配Pod的标签，若标签为空则匹配命名空间所属全部Pod
          app: nginx
      policyTypes:
      - Egress
      egress:
      # 设置允许访问的Pod
      - to:
        - podSelector:
            matchLabels:
              role: podclient
        ports:
        - protocol: TCP
          port: 80

# 3.配置命名空间选择器方式网络策略

## 3.1 配置入站网络策略

    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: my-network-policy
      namaspace: test
    spec:
      podSelector:
        matchLabels:
          # 设置网络策略所匹配Pod的标签，若标签为空则匹配命名空间所属全部Pod
          app: nginx
      policyTypes:
      - Ingress
      ingress:
      # 设置允许访问的命名空间，即命名空间所属的Pod均可访问
      - from:
        - namespaceSelector:
            matchLabels:
              name: default
        - podSelector:
            matchLabels:
              app: nginx 
        ports:
        - protocol: TCP
          port: 80

## 3.2 配置出站网络策略

    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: my-network-policy
      namaspace: test
    spec:
      podSelector:
        matchLabels:
          # 设置网络策略所匹配Pod的标签，若标签为空则匹配命名空间所属全部Pod
          app: nginx
      policyTypes:
      - Egress
      egress:
      # 设置允许访问的命名空间，即命名空间所属的Pod均可访问
      - to:
        - namespaceSelector:
            matchLabels:
              name: default
        ports:
        - protocol: TCP
          port: 80

# 4.配置IP地址范围方式网络策略

## 4.1 配置入站策略

    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: my-network-policy
      namaspace: test
    spec:
      podSelector:
        matchLabels:
          # 设置网络策略所匹配Pod的标签，若标签为空则匹配命名空间所属全部Pod
          app: nginx
      policyTypes:
      - Ingress
      ingress:
      # 设置允许访问Pod网段
      - from:
        - ipBlock:
            cidr: 172.30.100.0/24
        ports:
        - protocol: TCP
          port: 80

# 5.配置端口范围方式网络策略

## 5.1 配置出站网络策略

    apiVersion: networking.k8s.io/v1
    kind: NetworkPolicy
    metadata:
      name: multi-port-egress
      namespace: test
    spec:
      podSelector:
        matchLabels:
          app: nginx
      policyTypes:
      - Egress
      egress:
      - to:
        - ipBlock:
            cidr: 172.30.0.0/24
        ports:
        - protocol: TCP
          port: 32000
          endPort: 32768

---------

# 参考文档

- https://www.cnblogs.com/renshengdezheli/p/17479289.html
- https://blog.csdn.net/junbaozi/article/details/127893277
- https://blog.csdn.net/lingshengxiyou/article/details/129998725