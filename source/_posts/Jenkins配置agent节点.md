---
title: Jenkins配置agent节点
categories:
  - 工作
tags:
  - Linux
  - Jenkins
  - DevOps
  - CICD
  - 容器云
  - 云原生
  - 云计算
date: 2023-04-16 09:06:09
---

Jenkins主节点负责任务调度，也具备运行构建任务的功能，但为保障构整个建流程的可用性一般不进行任务构建，而是配置以专用于任务执行的代理节点。代理节点分为静态节点和动态节点，静态节点是固定的虚机或容器，动态节点则是随着任务的构建自动创建以及任务的完成自动销毁的节点

---------

# 1.配置代理节点服务器

# 1.1 安装jdk，配置java环境

# 1.2 创建jenkins用户并设置密码

    sudo adduser

# 1.3 配置jenkins sudo权限

# 2.登录jenkins，创建代理节点

# 2.1 创建代理节点登录凭据

【系统管理】 -> 【凭据】 -> 【全局凭据】 -> 【新增凭据】

![jenkins-002-001](/img/wiki/jenkins/jenkins-002-001.jpg)

# 2.2 创建代理节点

【系统管理】 -> 【节点管理】 -> 【新增节点】

![jenkins-002-002](/img/wiki/jenkins/jenkins-002-002.jpg)

![jenkins-002-003](/img/wiki/jenkins/jenkins-002-003.jpg)

![jenkins-002-004](/img/wiki/jenkins/jenkins-002-004.jpg)

![jenkins-002-005](/img/wiki/jenkins/jenkins-002-005.jpg)

# 3.测试agent节点任务构建

## 3.1 配置任务运行节点

![jenkins-002-006](/img/wiki/jenkins/jenkins-002-006.jpg)

## 3.2 配置测试任务

![jenkins-002-007](/img/wiki/jenkins/jenkins-002-007.jpg)

![jenkins-002-008](/img/wiki/jenkins/jenkins-002-008.jpg)

## 3.3 构建任务，测试代理服务器

![jenkins-002-009](/img/wiki/jenkins/jenkins-002-009.jpg)

---------

# 参考文档

- https://www.freesion.com/article/85671159445