---
title: Kubernetes集群控制器详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2021-08-16 20:40:29
---

Controller，即控制器，用于驱动Kubernetes集群资源对象当前状态（status）逼近用户提交的期望状态，通过API Server提供的（List & Watch）接口实时地循环监控资源对象的状态，以便于发现故障并执行自动化修复流程。Controller由主节点的Controller Manager组件负责管理，不同的资源对象由各自的控制器进行管理，如Deployment Controller、Node Controller、Namespace Controller、Service Controller等

# 1.Node控制器

Node Controller，即节点控制器，用于管理和监控集群所有的节点资源，由kubelet组件通过API Server组件注册自身节点并周期性地将汇报节点的状态信息，最后将之更行到etcd数据库。节点信息包括节点健康状况、节点资源、节点名称、节点地址信息、操作系统版本、Dooker版本、kubelet版本等，节点健康状况包含就绪（True）、未就绪（False）、未知（Unknown）三种

# 2.ReplicaSet控制器

ReplicaSet，即副本集控制器，用于保障集群内od副本数量，目前已被Deployment代替，无需直接操作ReplicaSet

# 3.Deployment控制器

Deployment，即部署集控制器，集群内管理应用副本的API对象。Deployment并不直接控制Pod，而是通过ReplicaSet实现对Pod的管理，即是依据所定义的策略将ReplicaSet与Pod更新到预期状态，提供了运行Pod的能力，且为Pod提供滚动升级、伸缩、副本等功能，一般用于运行无状态的应用

# 4.StatefulSet控制器

StatefulSet，即有状态集管理器，用于管理一组具有唯一固定ID的Pod集的部署和扩缩容，并提供持久化存储和持久化标识符，如Kafka集群等

# 5.DaemonSet控制器

DaemonSet，即守护进程集控制器，用于确保所有节点运行一个Pod的副本，集群新增节点将会自动为其创建一个Pod，节点移除时相应的Pod也将被回收。DaemonSet的删除将会删除对应创建的所有Pod

# 6.Job控制器

Job，即任务管理器，用于批量处理短暂的一次性任务，也就是仅执行一次的任务，保证批处理任务的一个或多个Pod成功结束

# 7.CronJob控制器

CronJob，即定时任务处理器，用于周期性的处理任务，根据Cron表达式定时执行Job

# 8.ResourceQuota控制器

ResourceQuota，即资源配额控制器，用于限制集群资源对象所占用系统的物理资源，避免由于某些业务在设计或实现上的缺陷所导致整个系统运行紊乱甚至宕机，如容器CPU和Memory资源限制、Namespace所属Pod数量、Service数量、PV数量等的限制

# 9.Service/Endpoints控制器

Service/Endpoints Controller，即Service/控制器，用于监听Service及其服务端点的变化，并根据监测到的事件做出相应的动作，如Service的Endpoints对象的增加、删除或Endpoint列表的修改，以实现网络流量的路由转发，动态更新负载均衡的后端服务器