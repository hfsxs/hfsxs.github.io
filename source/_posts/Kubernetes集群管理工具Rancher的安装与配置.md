---
title: Kubernetes集群管理工具Rancher的安装与配置
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2024-07-30 20:45:15
---

Rancher，开源的企业级一栈式多集群Kubernetes管理平台，专为依赖于容器技术的企业而打造，实现了Kubernetes集群在混合云和本地数据中心的集中部署与管理，简化了Kubernetes集群的运维与部署流程，从而加速企业数字化转型。Rancher基于集群的身份验证和角色访问控制（RBAC），将分散的多集群访问集中于一个平台，支持托管多个公有云服务服务商的集群、自动创建节点并安装的Kubernetes集群，或导入任何已经存在的Kubernetes集群。此外，Rancher还集成了几乎所有的云原生工具，如监控告警、日志分析、Helm应用、CI/CD、服务网格、安全扫描等等，是Kubernetes多集群管理的利器

# 1.安装Rancher

    sudo docker run -d -it \
    -p 80:80 -p 443:443 \
    --privileged --name=rancher \
    rancher/rancher

# 2.查看管理员密码

    sudo docker logs rancher | grep "Bootstrap Password:"

# 3.登录Rancher平台

    https://ip

# 4.导入集群

![导入集群](/img/wiki/kubernetes/rancher001.jpg)

![导入集群](/img/wiki/kubernetes/rancher002.jpg)

![注册集群](/img/wiki/kubernetes/rancher003.jpg)

# 5.验证集群状态

![集群状态验证](/img/wiki/kubernetes/rancher004.jpg)

---------

# 参考文档

- https://blog.csdn.net/MCB134/article/details/139611223
- https://blog.csdn.net/qq_35995514/article/details/130197353