---
title: Kubernetes集群Helm工具详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - Helm
  - 云原生
  - 容器云
  - 云计算
date: 2023-04-20 19:15:50
---

Helm，意为舵轮，是Kubernetes集群的包管理器，用于yaml文件的统一管理及高效复用，实现了应用级别的版本管理，即是将部署应用的yaml文件像Linux的包管理器一样进行封装，从仓库里快速查找、下载和安装，快速的发布中间件、数据库、公共组件等应用，类似于RedHat的yum、Python的pip。helm大大简化了Kubernetes应用的部署方式，将yaml文件存入chart包一键执行即可，不再需要kubectl一个个地执行，是查找、共享、打包、升级、回滚和使用Kubernetes构建软件的最佳方式

---------

# 相关概念

## 1.Chart

chart，应用描述，即一系列用于描述Kubernetes资源文件的集合，包含镜像、服务、依赖以及资源定义等，类似于apt的dpkg包或yum的rpm包

## 2.Release

release，基于Chart的部署实体，执行后将会在Kubernetes集群创建真实运行的资源对象，如Tomcat Chart

## 3.Repository

Repository，用于发布和存储Chart的存储库

## 4.helm

helm，命令行客户端工具，用于Kubernetes集群应用chart的创建、打包、发布和管理

---------

# 1.helm的安装与配置

## 1.1 下载helm

    wget -O helm.tar.gz https://get.helm.sh/helm-v3.6.3-linux-amd64.tar.gz

## 1.2 安装helm

    tar -xzvf helm.tar.gz
    cd linux-amd64
    sudo mv helm /usr/local/bin

## 1.3 配置helm仓库

### 1.3.1 查看仓库

    helm repo list

### 1.3.2 添加仓库

    helm repo add stable http://mirror.azure.cn/kubernetes/charts

### 1.3.3 更新仓库

    helm repo update

### 1.3.4 删除仓库

    helm repo remove stable

## 1.4 安装chart

### 1.4.1 下载

# 2.搭建私有仓库

## 2.1 安装nginx

    sudo mkdir -p /web/helm/charts
    sudo vi /etc/nginx/conf.d/helm.conf


    server {

      listen       80;
      server_name  localhost;

      location /charts {

        root  /web/helm;
        autoindex on;
        charset utf-8;
        autoindex_exact_size off;
        autoindex_localtime on;

        access_log  /var/log/nginx/helm_access.log  main;
        error_log  /var/log/nginx/helm_error.log;

      }
    }

## 2.2 创建helm应用并打包

    helm create nginx
    helm package nginx

## 2.3 生成charts库index文件

    mkdir swordhub
    mv nginx-0.1.0.tgz swordhub/
    helm repo index swordhub/ --url http://engine.sword.org/charts

## 2.4 charts库文件上传

    sudo cp swordhub/* /web/helm/charts

## 2.5 helm添加私有仓库swordhub

    helm repo add swordhub http://engine.sword.org/charts

## 2.6 验证私有库中swordhub

    helm install test swordhub/nginx --namespace test

# 3.chart应用编排


---------

# 参考文档

- https://blog.51cto.com/u_13760351/2898442
- https://www.cnblogs.com/lvzhenjiang/p/14878279.html
- https://blog.csdn.net/u011127242/article/details/118197361
- https://blog.csdn.net/qq_35745940/article/details/120693245