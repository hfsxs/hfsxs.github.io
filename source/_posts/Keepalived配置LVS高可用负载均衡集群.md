---
title: Keepalived配置LVS高可用负载均衡集群
categories:
  - 工作
tags:
  - Linux
  - Keepalived
  - LVS
  - 集群
  - 高可用
  - 负载均衡
  - 云计算
date: 2020-02-05 15:45:50
---

# 集群架构

- 172.16.100.100 lvs-server01
- 172.16.100.120 lvs-server02
- 172.16.100.150 nginx-server01
- 172.16.100.160 nginx-server02
- 172.16.100.200 vip

---------

# 1.安装lvs、keepalived、nginx

# 2.创建keepalived配置文件

    ! Configuration File for keepalived

    global_defs {
      notification_email {
      example@example.cn
      }

    notification_email_from example@example.cn
    smtp_server 127.0.0.1
    smtp_connect_timeout 30
    router_id lvs-ha-001
    }

    vrrp_instance lvs-ha {

      # 设置为主节点
      state MASTER
      interface eth1
      virtual_router_id 80
      # 设置优先级,高于备机
      priority 100
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 1111
      }

      virtual_ipaddress {
        172.16.100.200/24
      }
    }

    virtual_server 172.16.100.120 80 {
      delay_loop 6
      # 配置lvs调度算法
      lb_algo wrr
      # 配置lvs调度类型
      lb_kind DR
      protocol TCP
      nat_mask 255.255.255.0

      real_server 172.16.100.240 80 {
        weight 1

        TCP_CHECK {
            connect_timeout 8
            nb_get_retry 3
            delay_before_retry 3
            connect_port 80
                }
    }

      real_server 172.16.100.248 80 {
        weight 1

      TCP_CHECK {
        connect_timeout 8
        nb_get_retry 3
        delay_before_retry 3
        connect_port 80
        }
      }
    }

---------

- 注：lvs备机的配置文件基本相同，只需更改router_id、state、priority这三处即可

# 3.Nginx后端服务器创建lvs脚本

    vi /usr/local/sbin/lvs_dr.sh


    #! /bin/bash


    vip=172.16.100.200

    # RS绑定vip到回环网卡
    ifconfig lo:0 $vip broadcast $vip netmask 255.255.255.255 up

    # RS添加路由
    route add -host $vip lo:0

    # 配置ARP抑制，也可配置到/etc/sysctl.conf
    echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
    echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
    echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
    echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce

# 4.创建LVS规则

    chmod +x /usr/local/sbin/lvs_dr.sh
    sh /usr/local/sbin/lvs_dr.sh

# 5.启动keepalived、nginx

# 6.模拟故障，测试集群高可用