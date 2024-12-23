---
title: Kubernetes集群节点维护策略
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2023-09-20 10:45:22
---

Kubernetes集群节点的维护操作将导致业务的连续性不能得到保障，如操作系统升级、硬件维修与更换等，甚至需要下线停机，因此需要规划Pod平滑迁移的策略或方案

# 1.创建PodDisruptionBudget

PodDisruptionBudget，即Pod干扰预算或主动驱逐保护，是Kubernetes集群控制可以中断的Pod数量资源对象，用于确保系统维护、升级或其他操作时应用Pod不会被意外中断或终止，从而保障系统的可用性和可靠性

## 1.1 创建PDB资源文件

    vi pdb-nginx-test.yaml


    apiVersion: policy/v1
    kind: PodDisruptionBudget
    metadata:
      name: nginx-test
    spec:
      # 设置可用Pod的最小值，或者设置不可用最大值maxUnavailable，二者不可共存
      minAvailable: 1
      # 设置标签选择器，即所要匹配的Pod组
      selector:
        matchLabels:
          app: nginx-test

## 1.2 部署PDB

    kubectl apply -f pdb-nginx-test.yaml

# 2.设置节点不可调度

    kubectl cordon worker01

# 3.驱逐节点运行的Pod

    kubectl drain worker01 --delete-local-data --ignore-daemonsets --force

# 4.维护结束，设置节点可调度

    kubectl uncordon worker01

# 5.节点删除

    kubectl delete node worker01

# 6.节点重新加入集群

## 6.1 主节点获取加入节点的命令
    
    kubeadm token create --print-join-command

## 6.2 Worker节点重新加入集群

    kubeadm join 192.168.100.189:8443 --token dcwrhm.6wi8mn63s10gxrcf --discovery-token-ca-cert-hash sha256:af6e4d737cbd7e294036d7391a5931fba589942e777811bb6f74b77ccbda3cfc

## 6.3 验证节点状态

    kubectl get nodes -o wide 

---------

# 参考文档

- https://www.ngui.cc/zz/2318348.html
- https://bertram.blog.csdn.net/article/details/129385498
- https://blog.csdn.net/weixin_43616190/article/details/126433485