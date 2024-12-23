---
title: LVS配置Nginx负载均衡集群
categories:
  - 工作
tags:
  - Linux
  - LVS
  - Nginx
  - 集群
  - 负载均衡
  - 云计算
date: 2020-02-05 09:09:44
---

LVS，即Linux Virtual Server，Linux虚拟服务器，是由章文嵩博士发起的实现负载均衡集群的开源项目，目前已是Linux内核标准的一部分。LVS架构从逻辑上可分为调度层、Server集群层和共享存储层，LVS工作在TCP/IP的第四层，即网络层，适用于1000-2000万PV或并发请求1万以上的Nginx不堪负载的大型网站

# LVS架构

- ipvs，即ip virtual server，工作在内核空间的代码，用于调度的实现
- ipvsadm，工作在用户空间，负责为ipvs内核框架编写规则、定义集群服务的组员及后端真实的服务器(Real Server)的组员

# LVS工作流程

- 1.客户端（Client）向负载均衡调度器（Director Server）发起请求，调度器将请求发往至内核空间
- 2.调度器的PREROUTING链接收到客户端请求，判断目标IP确定是本机IP，将数据包发往INPUT链
- 3.IPVS工作在INPUT链上，当客户端请求到达INPUT时，IPVS会将客户端请求和已经定义好的集群服务进行比对，若客户端请求的就是定义的集群服务，IPVS修改数据包的目标IP地址及端口，并将新数据包发往POSTROUTING链
- 4.POSTROUTING链接收数据包，将目标IP地址和已经定义好的后端服务器地址进行比对，通过选路后将数据包最终发送给后端的服务器

# LVS相关术语

- DS，Director Server，调度服务器，即前端负载均衡器节点
- RS，Real Server，即后端真实的工作服务器
- VIP，虚拟IP，即供外部用户请求IP地址
- DIP，Director Server IP，用于和内部主机通讯的IP地址
- RIP，Real Server IP，即后端服务器IP地址
- CIP，Client IP，即客户端IP地址

# LVS工作模式

## 1.NAT模式

即网络地址转换，支持端口映射，LVS通过转换请求报文和响应报文的目标IP实现负载均衡功能。由于其请求和响应的数据报文都需要通过DR进行IP转换，所以当集群规模达到一定程度时DR将成为整个集群的瓶颈

## 2.DR模式

即直接路由，通过为请求报文重新封装一个MAC首部进行转发以实现负载均衡功能。其只有请求报文经由LVS进行转发，而响应报文是由RS直接返回给客户端，所以LVS不会产生流量，只负责分发请求，故整个集群的吞吐量得以大大提高，应用最为广泛。但负载均衡器的网卡必须与物理网卡在一个物理段上，即不能跨地域物理网络调度，也不支持端口映射

## 3.TUN模式

即隧道模式，通过调度算法对请求报文封装一个新IP报头，这个新报头指定了后端服务器的IP，从而实现了负载均衡的功能。此模式负载均衡器只负责将请求包分发给后端服务器，而响应报文直接由后端服务器发送给客户端，故其能处理的请求量极为巨大，单台负载均衡能为超过100台的物理服务器服务。且由于DIP、VIP、 RIP都为公网地址，就具备了跨地域物理网络的调度功能。但需要后端服务器支持IP Tunneling，即IP Encapsulation协议，且通过隧道进行信息传输，增加了部分负载，也不支持端口映射，适用于跨地域或跨机房的场景

# LVS调度算法

# 1.RR 

轮询，调度器将外部请求按顺序轮流分配到集群中的真实服务器上，集群中的任意一台服务器都是均等的，不考虑服务器实际连接数和负载

## 2.WRR

加权轮询，调度器根据真实服务器的不同处理能力来调度访问请求，以保证处理能力强的服务器处理更多的访问流量，自动问询负载情况，并动态地调整其权值

## 3.DH
目标地址hash，根据请求的目标IP地址，通过一个散列（Hash）函数将一个目标IP地址映射到某一台服务器，是一种静态映射算法

## 4.SH

源地址hash，根据请求的源IP地址，作为散列键（Hash Key）从静态分配的散列表找出对应的服务器，若该服务器是可用的且未超载，将请求发送到该服务器，否则返回空。实际应用中SH和DH结合使用在防火墙集群，可以保证整个系统的唯一出
入口

## 5.LC

最少连接，调度器动态地将网络请求调度到已建立的链接数最少的服务器上，适用于真实服务器具有相近的性能的集群环境

# 6.WLC

加权最少连接，调度器可以自动问询真实服务器的负载情况，并动态地调整其权值，适用于真实服务器性能差异较大的情况，具有较高权值的服务器将承受较大比例的活动连接负载

## 7.SED
最少期望延迟，基于wlc算法，调度器根据权重和当前连接数进行运算决定负载机器

## 8.NQ
从不排队，无需列队，如果有台realserver的连接数=0就直接分配过去，不再进行运算

## 9.LBLC
基于本地的最少连接，适用于Cache集群系统。该算法根据请求的目标IP地址找出该目标IP地址最近使用的服务器，若该服务器可用且未超载，将请求发送到该服务器；若不存在或已超载，且有服务器处于一半的工作负载，则用最少链接的原则选出一个可用的服务器，将请求发送到该服务器

## 10.LBLCR
带复制的基于本地的最少连接，适用于Cache集群系统。该算法根据请求的目标IP地址找出该目标IP地址对应的服务器组，按最小连接原则从服务器组中选出一台服务器，若未超载，将请求发送到该服务器；若服务器超载，则按最小连接原则从这个集群中选出一台服务器，将该服务器加入到服务器组中，将请求发送到该服务器。同时，当该服务器组有一段时间没有被修改， 将最忙的服务器从服务器组中删除，以降低复制的程度

## 应用场景

LVS可实现负载均衡，但不能进行健康检查，若某个rs出现故障，LVS仍然会进行请求转发，这样就会导致请求的无效。所以经常会配合keepalived工作，实现后端服务器的健康检查及LVS的高可用功能
实际的生产环境中，lvs通常会和nginx配合使用。虽然nginx单独也可实现负载均衡的功能，但请求和响应流量都会经过nginx，当后端的服务器规模庞大时，网络带宽就成为了整个集群的瓶颈。所以，lvs和nginx配合使用，既保障了lvs四层工作的高效性，又避免了nginx流量集中以及lvs映射出错的弊端，且nginx还可以处理静态资源，以及承载业务切换、分流、前置缓存的任务，这样就会大大减轻后端服务器的压力，从而提高整个集群的性能

---------

# 参考文档

- https://www.jianshu.com/p/8a61de3f8be9
- https://blog.51cto.com/191226139/2089891
- https://www.cnblogs.com/lixigang/p/5371815.html

---------

# 集群架构

- 172.16.100.100 ds
- 172.16.100.150 rs1
- 172.16.100.200 rs2
- 172.16.100.120 vip

---------

# 1.DR模式

## 1.1 安装LVS

    yum install -y ipvsadm

## 1.2 调度服务器配置LVS脚本

    vi /usr/local/sbin/lvs_dr.sh


    #! /bin/bash


    ipv=/sbin/ipvsadm

    vip=172.16.100.120
    rs1=172.16.100.150
    rs2=172.16.100.200

    # 配置子网卡
    ifconfig ens33:0 down
    # 配置虚拟IP
    ifconfig ens33:0 $vip broadcast $vip netmask 255.255.255.255 up
    # 配置子网卡路由
    route add -host $vip dev ens33:0

    # 开启调度服务器路由转发功能
    echo 1 > /proc/sys/net/ipv4/ip_forward

    # 清除当前所有的lvs虚拟服务
    $ipv -C

    # 添加tcp协议虚拟服务集群，指定负载均衡算法
    $ipv -A -t $vip:8080 -s wrr
    # 配置lvs虚拟服务的后端服务器组
    # g，设置工作模式为dr；w，设置rs权重
    $ipv -a -t $vip:80 -r $rs1:80 -g -w 3
    $ipv -a -t $vip:80 -r $rs2:80 -g -w 1

## 1.3 创建LVS规则

    chmod +x /usr/local/sbin/lvs_dr.sh
    sh /usr/local/sbin/lvs_dr.sh

## 1.4 创建后端服务器配置脚本

     vi /usr/local/sbin/lvs_dr_rs.sh


    #! /bin/bash


    vip=172.16.100.120

    # RS绑定vip到回环网卡
    ifconfig lo:0 $vip broadcast $vip netmask 255.255.255.255 up

    # RS添加路由
    route add -host $vip lo:0

    # 配置ARP抑制，也可配置到/etc/sysctl.conf
    echo "1" >/proc/sys/net/ipv4/conf/lo/arp_ignore
    echo "2" >/proc/sys/net/ipv4/conf/lo/arp_announce
    echo "1" >/proc/sys/net/ipv4/conf/all/arp_ignore
    echo "2" >/proc/sys/net/ipv4/conf/all/arp_announce

## 1.5 创建LVS规则

    chmod +x /usr/local/sbin/lvs_dr_rs.sh
    sh /usr/local/sbin/lvs_dr_rs.sh

## 1.6 查看调度规则，验证集群功能

    ipvsadm -ln

# 2.NAT模式

# 3.TUN模式

---------

# 参考文档

- https://www.cnblogs.com/MacoLee/p/5856858.html
- https://blog.csdn.net/Ki8Qzvka6Gz4n450m/article/details/79119665