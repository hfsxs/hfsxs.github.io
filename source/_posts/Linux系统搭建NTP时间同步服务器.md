---
title: Linux系统搭建NTP时间同步服务器
categories:
  - 工作
tags:
  - Linux
  - NTP
  - 时间同步
  - 云计算
date: 2020-02-06 10:42:22
---

NTP，Network Time Protocol，即网络时间协议，用于精确同步网络节点的机器时间。NTP提供了高精准度的时间校正，其精度在局域网内可达0.1ms，Internet上精度可达几十ms，且能以加密确认的方式防止网络攻击

---------

# 1.安装ntp

    yum install -y ntp
    apt install -y ntp

# 2.修改配置文件

    vi /etc/ntp.conf


    # 设置ntp服务器
    server 172.16.100.100 prefer
    # server 0.centos.pool.ntp.org iburst
    # server 1.centos.pool.ntp.org iburst
    # server 2.centos.pool.ntp.org iburst
    # server 3.centos.pool.ntp.org iburst
  
# 3.启动ntp服务

    systemctl restart ntpd.service
    systemctl enable ntpd.service

# 4.配置客户端ntp服务

    vi /etc/ntp.conf


    # 设置ntp服务器
    server 172.16.100.100

# 5.启动ntp服务

    systemctl restart ntpd.service
    systemctl enable ntpd.service

# 6.验证时间同步

    # 查看是否与时间服务器连接成功
    ntpstat
    # 查看当前服务器与上层ntp服务器的状态
    ntpq -p