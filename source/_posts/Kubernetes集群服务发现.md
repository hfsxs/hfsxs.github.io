---
title: Kubernetes集群服务发现
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - DNS
  - CoreDNS
  - 容器云
  - 云原生
  - 云计算
date: 2022-02-16 17:31:55
---

服务发现，即服务或应用之间相互调用时定位对方IP及端口的过程，通常是通过记录了系统所有服务的信息注册中心来实现，如传统的DNS协议方式、consul服务注册发现中心等。Kubernetes官方推荐使用DNS插件实现集群的服务发现，CoreDNS由于完全遵循官方提供的标准指南而得以广泛应用













---------

# 参考文档

- https://www.jianshu.com/p/33f4701f38b3
- https://www.cnblogs.com/wangguishe/p/16383394.html
- https://blog.csdn.net/qq_36885515/article/details/127833803