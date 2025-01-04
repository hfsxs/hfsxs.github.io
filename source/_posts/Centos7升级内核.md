---
title: Centos7升级内核
categories:
  - 工作
tags:
  - Linux
  - CentOS
  - 云计算
date: 2023-09-04 09:36:33
---

Linux内核，即kernel，是由林纳斯·托瓦兹编写的开源操作系统核心程序，负责管理硬件、文件系统和网络等资源，目前由Linux开源社区维护、更新与修复。Linux内核版本是指其版本号，是其独特的标识，包括主版本号、次版本号和修订号，通常主版本号表示基本的架构和功能的重大改变，次版本号表示较小的变化（偶数为稳定版，奇数为开发版），修订号表示修复次数，如4.18.10。Linux内核版本大致分为两类，即ml和lt，也就是mainline stable（稳定主线版）和long term support（长期支持版），两者可以共存，但每种类型内核只能存在一个版本。为了获得更好的使用体验和漏洞的修复，及时的更新内核版本非常有必要

# 1.查看当前版本号

    uname -r

# 2.导入仓库源

    sudo rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
    sudo rpm -Uvh http://www.elrepo.org/elrepo-release-7.0-2.el7.elrepo.noarch.rpm

# 3.查看可安装的软件包

    sudo yum --enablerepo="elrepo-kernel" list --showduplicates | sort -r | grep kernel-ml.x86_64

# 4.安装内核版本

    # 安装ML版本
    yum --enablerepo=elrepo-kernel install  kernel-ml-devel kernel-ml -y   
    # 安装LT版本
    yum --enablerepo=elrepo-kernel install kernel-lt-devel kernel-lt -y

# 5.配置内核启动顺序

## 5.1 查看当前内核启动顺序

    sudo awk -F\' '$1=="menuentry " {print $2}' /etc/grub2.cfg

## 5.2 配置内核启动顺序

    # 设置启动项的版本的序号，从0开始计数
    grub2-set-default 0

# 6.重启服务器，验证内核版本

---------

# 参考文档

- https://blog.csdn.net/weixin_39094034/article/details/127523196