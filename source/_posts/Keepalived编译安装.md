---
title: Keepalived编译安装
categories:
  - 工作
tags:
  - Linux
  - Keepalived
  - 集群
  - 高可用
  - 云计算
date: 2020-02-05 14:30:40
---

Keepalived，由C语言编写的基于VRRP（Vritrual Router Redundancy Protocol，虚拟路由冗余协议)的开源路由软件，用于为基于Linux的基础设施提供简单而稳定的负载均衡和高可用方案。最初是为LVS设计，用于管理与监控LVS集群各个服务节点的状态，根据其健康状况动态地、自适应地维护和管理负载均衡的服务器池，自动检测集群故障并完成转移，避免IP单点故障。Keepalived后来融入了可实现高可用的VRRP功能，也可作为其他服务的高可用解决方案，如Nginx、Haproxy、MySQL等

# 1.体系架构

## 1.1 core components

keepalived的核心组件，负责主进程的启动及维护，由一系列功能模块组成

- Checkers，基于网络层（IP）、传输层（TCP）、应用层（HTTP、SSL等）对服务器池内真实服务器的健康检查模块
- WatchDog，监控checkers和VRRP进程的状况
- VRRP Stack，VRRP协议的实现，负责负载均衡器之间的切换，从而实现高可用性
- IPVS wrapper，负责设定规则到内核ipvs的接口，即根据配置文件生成IPVS规则并送往内核空间的IPVS使之生效
- Netlink Reflector，负责设定vrrp的vip地址等路由相关的功能

## 1.2 Control Plane

keepalived的控制面板，负责配置文件的编译和解析

## 1.3 Scheduler I/O Multiplexer

I/O复用分发调度器，负责keepalived所有内部任务请求的调度

## 1.4 Memory Management

内存管理机制，提供内存访问的一些通用方法

## 1.5 SMTP

即SMTP接口，用于VRRP Stack发生地址流动或Checkers发现服务上下线并增删服务节点时，以邮件方式通知管理员

# 2.工作原理

## 2.1 VRRP工作原理

VRRP，Virtual Router Redundancy Protocol，即虚拟路由冗余协议，是实现路由器高可用的容错协议，最初是由IETF提出的用于解决局域网静态网关单点故障的路由协议，应用于交换机、路由器等设备。VRRP基本原理是将多台提供相同功能的路由器虚拟成为一个路由设备，虚拟MAC地址为00-00-5e-00-01-xx（xx为唯一VRID，即Virtual Router Identifier），对外提供虚拟IP，内部则由竞选机制根据优先级高低来决定路由器的角色，其中一台被选举为Master的拥有外部虚拟IP的路由器负责路由任务，如ARP请求的解析与响应、转发IP数据包等，其余路由器均为Backup角色。Master角色的路由器将会以IP组播（默认组播地址为224.0.0.18）的方式发送心跳消息给组内的Backup路由器，通知自己的存活状态及优先级。Master路由器若发生故障则会停止发送心跳消息，Backup路由器组检测不到Master的心跳消息将再通过同样的竞选机制选举出优先级最高的一台作为新的Master路由器，并接管路由任务

VRRP使得外部认为只有一个网关在工作，所有的网络功能都是通过Master处理，突发故障时由Backup立即接替而不影响内外数据通信，且无需手动修改网络配置，实现了路由故障的无缝切换，达到了整个过程对外部而言完全透明无感知的效果

## 2.2 Keepalived工作流程

1.Keepalived高可用节点通过VRRP报文的交互获知各自的优先级即route_id，并通过VRRP的竞选机制确定主、备节点，主节点优先级高于备节点，若优先级相同则通过IP值较大者成为主节点

2.主节点接管IP资源和服务资源对外提供服务，并不断以组播方式向备节点发送心跳消息用以告知备节点自己的优先级及存活状态

3.备节点接收到心跳消息，得知自己的优先级低于主节点，处于待机状态

4.主节点突发故障，不能再发送心跳消息，或人为降低了优先级

5.备节点接收不到主节点的心跳消息或获知了主节点优先级的变动，则将各自的优先级通告给其余备节点进行协商，即再次进行竞选，最后优先级高的备节点则为新的主节点，由其调用自身的接管程序接管之前主节点的IP资源和服务资源继续对外提供服务。从而，完成了主备切换，保障了业务的连续性

6.若之前故障的主节点由人工介入完成修复，若工作于抢占模式，则会再次成为主节点，否则将加入备节点

# 3.网络场景

## 3.1 网络层场景

工作方式是通过ICMP协议向服务器集群发送ICMP数据包，类似于ping实现的功能，若某节点没有返回响应数据包，则判定为节点故障，Keepalived将报告此节点失效，并从服务器集群中剔除该节点

## 3.2 传输层场景

Keepalived在传输层利用TCP协议的端口连接和扫描技术来判断集群点是否正常。如常见的WEB服务默认的80端口、SSH服务默认的22端口等，若探测到某端口没有响应数据返回，则判定为该端口异常，然后强制将此端口对应的节点从服务器集群组中剔除

## 3.3 应用层场景

Keepalived在应用层的运行方式更加全面化和复杂化，如根据业务场景编写监测程序来判定程序或服务是否运行正常，若Keepalived的检测结果与用户设定不一致，则将对应的服务从服务器剔除

# 4.高可用架构

## 4.1 主从高可用架构

一个Master节点和一个Backup节点，其中Master节点对外提供服务，两节点间保持心跳，直到Master节点因宕机服务不可用时，系统会切换到Backup继续提供服务，宕机的Master节点恢复后将作为Backup加入集群

## 4.2 双主高可用架构

两节点均为Master节点，同时对外提供服务，同时保持心跳，某一节点宕机服务不可用时，流量将会全部导向另一节点继续提供服务，宕机节点恢复后重新加入集群提供服务。两节点对外服务的虚拟IP地址不同，可根据业务特点自行衡量

# 5.脑裂现象

高可用（HA）系统中，当联系两个节点的“心跳线”断开时，由于相互失去了联系，双方都会判定对方出现故障。两个节点上的HA软件像“裂脑人”一样争抢共享资源与应用服务，本为一个整体、动作协调的HA系统，分裂成为两个独立的个体。此时，共享资源被瓜分，两边服务都不能运行或都各自独立运行，将会造成业务中断或同时读写共享存储导致数据损坏的严重后果，即为脑裂现象

## 5.1 常见原因

- 高可用服务器之间心跳线链路故障，导致无法正常通信，如因心跳线断开、老化或连接设备故障（网卡及交换机）等、网卡及驱动故障或心跳网卡地址等信息配置不正确导致的心跳发送失败、IP冲突
- 采用仲裁机制的仲裁机器故障
- 高可用服务器开启了iptables防火墙阻挡了心跳消息传输
- 其他服务配置不当，如心跳方式不同，心跳广插冲突、软件Bug等

## 5.2 解决方案

- 若开启防火墙，则一定要保障心跳消息的通过，一般以允许IP段的形式解决
- 同时使用串行电缆和以太网电缆或同时使用两条心跳线路作为灾备冗余
- 开发检测报警程序，通过监控软件检测脑裂

---------

# 1.安装依赖包

    apt install -y gcc make libssl-dev libnl-3-dev
    yum install -y gcc make openssl-devel libnl-devel

# 2.编译安装keepalived

    tar -xzvf keepalived-2.2.1.tar.gz && cd keepalived-2.2.1
    ./configure --prefix=/usr/local/keepalived --sysconfdir=/etc --with-init=systemd
    make && make install

# 3.创建keepalived配置文件

    mv /etc/keepalived/keepalived.conf /etc/keepalived/keepalived.conf.bak
    vi /etc/keepalived/keepalived.conf


    global_defs {

      notification_email

      {
        admin@sword.com
      }
      notification_email_from
      smtp_server 127.0.0.1
      smtp_connect_timeout 30
      router_id master

    }

    vrrp_script check_nginx {

      script "/etc/keepalived/nginx_check.sh"
      interval 2
      weight -20

    }

    vrrp_instance NGINX {

      state MASTER
      interface eth0
      virtual_router_id 51
      priority 100
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 123456
      }
      virtual_ipaddress {
        172.16.100.150/24
      }
      track_script {
        check_nginx
      }
    
    }

# 4.配置keepalived启动参数

    vi /etc/sysconfig/keepalived


    KEEPALIVED_OPTIONS="-D -d -S 0"

# 5.创建启动脚本

    vi /lib/systemd/system/keepalived.service


    [Unit]
    Description=LVS and VRRP High Availability Monitor
    After=network-online.target syslog.target
    Wants=network-online.target

    [Service]
    Type=forking
    PIDFile=/run/keepalived.pid
    KillMode=control-group
    EnvironmentFile=-/etc/sysconfig/keepalived
    ExecStart=/usr/local/keepalived/sbin/keepalived $KEEPALIVED_OPTIONS
    ExecReload=/bin/kill -HUP $MAINPID
    ExecStop=/bin/kill -TERM $MAINPID

    [Install]
    WantedBy=multi-user.target

# 6.配置keepalived日志

## 6.1 配置系统日志服务rsyslog

    vi /etc/rsyslog.conf


    # 启用UDP端口接收其他设备的日志消息          
    $ModLoad imudp
    $UDPServerRun 514

    # 设置local0级别设备的日志存储路径
    local0.*    var/log/keepalived.log

## 6.2 重启rsyslog

    systemctl restart rsyslog.service

# 7.启动keepalived服务

    systemctl daemon-reload
    systemctl start keepalived.service
    systemctl enable keepalived.service

# 8.模拟集群故障，测试VIP漂移

---------

# 参考文档

- https://blog.51cto.com/qiuyue/2364190
- https://blog.csdn.net/fduffyyg/article/details/84195323
- https://blog.csdn.net/qq_22648091/article/details/108519773
- https://blog.csdn.net/weixin_43740223/article/details/109475495