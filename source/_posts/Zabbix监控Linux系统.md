---
title: Zabbix监控Linux系统
categories:
  - 工作
tags:
  - Linux
  - Zabbix
  - 监控告警
  - 云计算
date: 2020-02-02 18:10:12
---

# 集群架构

- 172.16.100.100 node01 Zabbix server
- 172.16.100.120 node02 Zabbix agent

---------

# 1.安装依赖包

    yum -y install gcc gcc-c++ make automake autoconf \
    curl curl-devel perl-DBI net-snmp-devel libcurl libxml2 libxml2-devel

# 2.创建zabbix用户

    groupadd zabbix && useradd -g zabbix -s /sbin/nologin zabbix

# 3.编译安装zabbix

    tar -zxvf zabbix-3.0.8.tar.gz && cd zabbix-3.0.8
    ./configure --prefix=/usr/local/zabbix --sysconfdir=/etc/zabbix --enable-agent \
    --with-net-snmp --with-libcurl --with-libxml2 --enable-ipv6
    make && make install

# 4.创建配置文件

    sed -i 's@BASEDIR=/usr/local@BASEDIR=/usr/local/zabbix@g' /etc/init.d/zabbix_agentd
    sed -i 's@LogFile=/tmp/zabbix_agentd.log@LogFile=/var/zabbix/zabbix_agentd.log@g' /etc/zabbix/zabbix_agentd.conf
    sed -i 's@# PidFile=/tmp/zabbix_agentd.pid@PidFile=/var/run/zabbix/zabbix_agentd.pid@g' /etc/zabbix/zabbix_agentd.conf

# 5.创建启动脚本

    cp /projects/zabbix-3.0.8/misc/init.d/fedora/core/zabbix_agentd /etc/init.d
    chmod +x /etc/init.d/zabbix_agentd
    mkdir /var/zabbix /var/run/zabbix
    chown zabbix:zabbix -R /usr/local/zabbix /etc/zabbix /var/zabbix /var/run/zabbix

# 6.启动Zabbix Agent

    systemctl daemon-reload
    systemctl start zabbix_agentd
    systemctl enable zabbix_agentd