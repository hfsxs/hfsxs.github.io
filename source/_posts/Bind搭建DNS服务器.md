---
title: Bind搭建DNS服务器
categories:
  - 工作
tags:
  - Linux
  - Bind
  - DNS
  - 域名解析
  - 云计算
date: 2020-02-03 11:10:09
---

bind，安全高效的开源域名解析服务程序，发源于1980年代加州大学伯克利分校的由美国国防高级研究项目管理局 (DARPA)资助的研究生项目，故取名为Berkeley Internet Name Domain，以其稳定性、可靠性和灵活性广泛应用于各类操作系统与网络环境，是当今互联网最为流行的域名解析方案

# DNS

DNS，Domain Name System，即域名系统，是互联网基础设施类的服务，以层次结构的命名系统将域名和IP地址相互映射，从而形成一个分布式数据库系统，最终完成域名与IP地址的相互转换。DNS将网站的域名解析为IP地址，这样通过简单易记的域名即可访问网站，而不必使用复杂的IP地址，通过互联网进行信息检索更加便捷

# 1.安装bind

    # sudo yum -y install bind bind-utils
    # sudo mkdir -p /var/named/log

    sudo useradd named -s /sbin/nologin -M
    sudo mkdir /var/named && sudo chown -R named.named /var/named
    sudo yum install -y gcc gcc-c++ openssl openssl-dev

    tar -xzvf bind-9.18.26.tar.xz
    sudo ./configure --prefix=/usr/local/bind --sysconfdir=/etc/bind --enable-threads --enable-largefile --disable-ipv6
    sudo mkae && sudo make install  

# 2.修改主配置文件

    vi /etc/named.conf


    options {

      # 设置DNS服务器监听端口与IP
      listen-on port 53 { 192.168.0.150; }; 
      # 设置DNS服务器IPv6监听IP
      listen-on-v6 port 53 { ::1; };

      # 设置DNS服务器全局配置目录
      directory "/var/named";

      # 设置DNS服务器缓存数据文件
      dump-file "/var/named/data/cache_dump.db";

      # 设置DNS服务器统计数据文件
      statistics-file "/var/named/data/named_stats.txt";

      # 设置DNS服务器内存使用的统计数据文件
      memstatistics-file "/var/named/data/named_mem_stats.txt";

      # 设置允许查询的IP地址
      allow-query { 192.168.0.0/24; };

      # DNS服务器日志配置
      logging {
        channel default_debug {
        file "/var/named/log/named.log";
        severity dynamic;
        };
      };

      # 根区域解析文件配置
      zone "." IN {
        type hint;
        file "named.ca";
      };

      # 设置区域文件
      include "/etc/named.rfc1912.zones";
      include "/etc/named.root.key";

    }

# 3.配置区域文件

    sudo vi /etc/named.rfc1912.zones


    # 正向解析区域配置
    # 设置正向解析库名称
    zone "sxs0618.com" IN {
      # 设置为主dns解析库
      type master;
      # 设置正向解析库文件名
      file "sxs0618.com.zone";
      # 设置自动更新解析文件的客户端
      allow-update { none; };
    };

    # 配置反向解析区域
      zone "0.168.192.in-addr.arpa" IN {
      type master;
      file "sxs0618.com.local";
      allow-update { none; };
    };

# 4.创建正向区域解析文件

    sudo vi /var/named/sxs0618.com.zone


    $TTL    86400
    $ORIGIN sxs0618.com.
    @       IN  SOA     dns.sxs0618.com. admin.sxs0618.com. (
      20190518; serial
      1H      ; refresh
      5M      ; retry
      1W      ; expire
      3H )    ; minimum
             IN         NS          dns
      dns      IN         A           192.168.0.150
               IN         MX          10  mail. sxs0618.com.
      www      IN         A           192.168.0.150
      mail     IN         A           192.168.0.120
      bbs      IN         A           192.168.0.160
      ftp      IN         A           192.168.0.180

# 5.创建反向区域解析文件

    sudo vi /var/named/sxs0618.com.local


    $TTL    604800
    $ORIGIN 0.168.192.in-addr.arpa.
    @       IN SOA  dns.sxs0618.com. admin.sxs0618.com. (
                                        20190518; serial
                                        1H      ; refresh
                                        5M      ; retry
                                        1W      ; expire
                                        3H )    ; minimum
        IN        NS            dns.sxs0618.com.
    150     IN        PTR           www.sxs0618.com.
    120     IN        PTR           mail.sxs0618.com.
    160     IN        PTR           bbs.sxs0618.com.
    180     IN        PTR           ftp.sxs0618.com.

# 6.启动DNS服务

    sudo systemctl start named.service
    sudo systemctl enable named.service

# 7.配置主机DNS服务器

    sudo vi /etc/resolv.conf 


    nameserver 192.168.0.150
    #nameserver 8.8.8.8

# 8.验证DNS服务器解析

    nslookup www.sxs0618.com
    nslookup 192.168.0.150

---------

# 参考文档

- http://www.cnblogs.com/st-jun/p/8022137.html
- https://blog.51cto.com/5165807/2313377?source=dra
- https://www.cnblogs.com/heqiuyu/articles/6600326.html
- https://blog.csdn.net/feng271374203/article/details/89920817