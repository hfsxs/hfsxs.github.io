---
title: CentOS配置静态IP
categories:
  - 工作
tags:
  - Linux
  - CentOS
  - 网络
  - 云计算
date: 2020-02-01 09:10:51
---

# 1.备份网卡配置文件

    cd /etc/sysconfig/network-scripts
    cp ifcfg-enp3s0 ifcfg-enp3s0.bak

# 2.修改网卡配置

    vi ifcfg-enp3s0


    TYPE="Ethernet"
    PROXY_METHOD="none"
    BROWSER_ONLY="no"
    BOOTPROTO="static"
    DEFROUTE="yes"
    IPV4_FAILURE_FATAL="no"
    IPV6INIT="yes"
    IPV6_AUTOCONF="yes"
    IPV6_DEFROUTE="yes"
    IPV6_FAILURE_FATAL="no"
    IPV6_ADDR_GEN_MODE="stable-privacy"
    NAME="enp3s0"
    UUID="fbc1994d-a800-4026-8188-765cb2747088"
    DEVICE="enp3s0"
    ONBOOT="yes"

    IPADDR=172.16.100.100
    NETMASK=255.255.255.0
    GATEWAY=172.16.100.1
    DNS1=172.16.100.1
    DNS2=8.8.8.8
  
# 3.重启网络服务

    systemctl restart network.service