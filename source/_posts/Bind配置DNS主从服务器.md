---
title: Bind配置DNS主从服务器
categories:
  - 工作
tags:
  - Linux
  - Bind
  - DNS
  - 域名解析
  - 云计算
date: 2020-03-03 21:07:33
---

# 集群架构

- Master 172.16.100.100
- Slaver 172.16.100.150

# 1.主从服务器安装Bind

# 2.主服务器配置解析文件

# 3.配置主服务器区域文件允许转发到从服务器

    vi /etc/named.rfc1912.zones


    # 配置正向解析区域
    zone "sxs0618.com." IN {
      type master;
      file "sxs0618.com.zone";
      allow-update { none; };
      # 配置允许转发的从服务器
      allow-transfer { 172.16.100.150;};
    };

    zone"100.16.172.in-addr.arpa." IN {
      type master;
      file"100.16.172.in-addr.zone";
      allow-update { none; };
		  # 配置允许转发的从服务器
      allow-transfer{ 172.16.100.150; }; 
    };

# 4.主服务器配置解析文件

## 4.1 配置正向解析文件

    vi /var/named/sxs0618.com.zone


    $TTL    86400
    $ORIGIN sxs0618.com.
    @       IN  SOA     dns1.sxs0618.com. admin.sxs0618.com. (
                                        20190518; serial
                                        1H      ; refresh
                                        5M      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
             IN         NS          dns1
             IN         NS          dns2
    dns1     IN         A           172.16.100.100
    dns2     IN         A           172.16.100.150
             IN         MX          10  mail.sxs0618.com.
    www      IN         A           172.16.100.100
    mail     IN         A           172.16.100.200
    bbs      IN         A           172.16.100.150
    ftp      IN         A           172.16.100.100

## 4.2 配置反向解析文件

    vi /var/named/sxs0618.com.local


    $TTL    604800
    $ORIGIN 100.16.172.in-addr.arpa.
    @       IN SOA  dns1.sxs0618.com. admin.sxs0618.com. (
                                        20190518; serial
                                        1H      ; refresh
                                        5M      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
            IN        NS            dns1.sxs0618.com.
            IN        NS            dns2.sxs0618.com.
    100     IN        PTR           www.sxs0618.com.
    200     IN        PTR           mail.sxs0618.com.
    150     IN        PTR           bbs.sxs0618.com.
    100     IN        PTR           ftp.sxs0618.com.

# 5.配置从服务器区域文件

    vi /etc/named.rfc1912.zones


    # 配置正向解析区域
    zone "sxs0618.com." IN {
      type slave;
      masters { 172.16.100.100; };
      file "slaves/sxs0618.com.zone";
      allow-transfer { none;};
    };

    zone"100.16.172.in-addr.arpa." IN {
      type slave;
      masters { 172.16.100.100; };
      file"slaves/100.16.172.in-addr.zone";
      allow-transfer{ none; }; 
    };

# 6.启动从服务器，开始区域文件同步

---------

# 参考文档

- https://www.cnblogs.com/fyy-hhzzj/p/9066477.html
- https://cloud.tencent.com/developer/article/1363063