---
title: Linux系统安装Web虚拟化管理平台Cockpit
categories:
  - 极客
tags:
  - Linux
  - Cockpit
  - KVM
  - 虚拟化
  - 极客
date: 2022-09-23 19:57:27
---

Cockpit，ReaHat开发的网页版图形化服务器管理工具，简单易用，支持Debian、Redhat、CentOS、Fedora、Atomic、Arch Linux和Ubuntu多种操作系统，具备存储管理、网络配置、检查日志、管理容器等功能，是管理小规模服务器集群的利器

---------

![001](/img/wiki/cockpit/001.jpg)

---------

# 1.安装cockpit

    # CentOS
    sudo yum install -y cockpit cockpit-machines cockpit-docker
    # Ubuntu
    . /etc/os-release && sudo apt install -t ${VERSION_CODENAME}-backports cockpit cockpit-machines cockpit-docker

# 2.启动cockpit

    sudo systemctl start cockpit.service
    sudo systemctl enable cockpit.service

# 3.访问cockpit

https://ip:9090

# 4.配置KVM桥接网络

# 5.安装虚拟机

![002](/img/wiki/cockpit/001.jpg)

---------

# 参考文档

- https://blog.whsir.com/post-6289.html
- https://zhuanlan.zhihu.com/p/113187354
- https://cockpit-project.org/running.html