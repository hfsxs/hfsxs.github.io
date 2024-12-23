---
title: Linux系统配置网卡bond
categories:
  - 工作
tags:
  - Linux
  - 网络
  - 云计算
date: 2024-05-16 21:56:46
---

Bond，网络绑定或链路聚合，即将多个网络接口绑定为一个逻辑网卡对外提供服务，从而实现网络流量的负载均衡，以及网卡级的冗余与扩容，提高网络总体可用性。Linux系统网卡绑定分为7种工作模式，其中mode0/1/6这三种模式最为常用

# 1.mode=0

balance-rr，Round-Robin Policy，即平衡轮训策略，工作机制是将网络数据包按照轮询方式依次地平均分配到所有被绑定的网络接口，链路故障自动切换。优点是具备负载均衡和容错能力，增加网络吞吐量，较为常用。但需要交换机配置端口静态聚合，且网络接口轮训的链路可能出现数据包无序到达而需要重新发送，从而影响网络吞吐量

## 1.1 虚拟机新增网卡

## 1.2 配置网卡

### 1.2.1 配置网卡ens2

    sudo cp /etc/sysconfig/network-scripts/ifcfg-ens2 /etc/sysconfig/network-scripts/ifcfg-ens2.bak
    sudo vi /etc/sysconfig/network-scripts/ifcfg-ens2 

    
    TYPE=Ethernet
    PROXY_METHOD=none
    BROWSER_ONLY=no
    DEFROUTE=yes
    NAME=ens2
    UUID=2a8c33e3-34e6-4c1b-aaef-258efba38bf6
    DEVICE=ens2
    ONBOOT=yes

    BOOTPROTO=none
    MASTER=bond0
    SLAVE=yes
    USERCTL=no

### 1.2.2 配置网卡ens6

    sudo vi /etc/sysconfig/network-scripts/ifcfg-ens6

    
    TYPE=Ethernet
    PROXY_METHOD=none
    BROWSER_ONLY=no
    DEFROUTE=yes
    NAME=ens6
    UUID=2a8c33e3-34e6-4c1b-aaef-258efba38bf9
    DEVICE=ens6
    ONBOOT=yes

    BOOTPROTO=none
    MASTER=bond0
    SLAVE=yes
    USERCTL=no

## 1.3 配置网卡Bond

    sudo vi /etc/sysconfig/network-scripts/ifcfg-bond0


    TYPE=Ethernet
    DEVICE=bond0
    ONBOOT=yes
    BOOTPROTO=static

    IPADDR=192.168.100.120
    NETMASK=255.255.255.0
    GATEWAY=192.168.100.1
    DNS1=192.168.100.1
    DNS2=8.8.8.8
    BONDING_OPTS="miimon=100 mode=0 fail_over_mac=1"

## 1.4 重启网卡以生效配置

# 2.mode=1

active-backup，Active-Backup Policy，即主备策略，也就是主设备处于活动状态，备用设备只有在主设备故障才转换为主设备接管服务。优点是具备容错和冗余功能，保障了网络稳定性，较为常用。但资源利用率低，因为只有一个设备处于工作状态

## 2.1 虚拟机新增网卡

## 2.2 配置网卡

    sudo cp /etc/netplan/01-netcfg.yaml /etc/netplan/01-netcfg.yaml.bak
    sudo vi /etc/netplan/01-netcfg.yaml


    # This file describes the network interfaces available on your system
    # For more information, see netplan(5).
    network:
      version: 2
      renderer: networkd
      ethernets:
        eth0:
          dhcp4: no
          dhcp6: no
        eth1:
          dhcp4: no
          dhcp6: no

      bonds:
        bond1:
          interfaces:
            - eth0
            - eth1
          addresses: [192.168.100.120/24]
          gateway4: 192.168.100.1
          nameservers:
            addresses: [192.168.100.1,8.8.8.8]
          parameters:
            mode: active-backup
            mii-monitor-interval: 100

## 2.3 应用网卡配置

    sudo netplan apply

# 3.mode=2

balance-xor，XOR Policy，即平衡哈希策略，工作机制是将网络数据包基于HASH运算的方式平均分配到所有被绑定的网络接口，默认算法为：(源MAC地址 XOR 目标MAC地址) % slave数量。优点是具备负载均衡和容错能力，但需要交换机配置端口静态聚合，且交换机需要支持哈希分配，不常用

# 4.mode=3

broadcast，广播策略，即是将所有数据包发送到所有接口以实现广播传输，不提供负载均衡，只有冗余功能，资源浪费，且需要交换机配置端口静态聚合，不常用。但适用于高可靠性环境，如金融行业

# 5.mode=4

Dynamic Link aggregation Policy，即动态链接聚合策略，工作机制是基于IEEE 802.3ad规范创建共享速率和双工设定的网卡聚合组，外出网络流量的链路基于传输hash进行选举。优点是具备容错和冗余功能，但需要交换机支持动态链接聚合，且需配置LACP（Link Aggregation Control Protocol），不常用

# 6.mode=5

balance-tlb，Adaptive Transmit Load Balancing，即适配器传输负载均衡策略，工作机制是基于TLB算法分配外出网络流量，入口流量只有一个。优点是具备容错和冗余功能，但需要网络设备支持获取每个slave的速率，不常用

# 7.mode=6

balance-alb，Adaptive load balancing，即适配器适应性负载均衡策略，工作机制是基于ALB算法在传输端和接收端都进行负载均衡，也就是mode5方式的升级版，接收端负载均衡通过ARP协商实现，并使得不同的对端使用不同的硬件地址进行通信。该模式不需要特殊的交换机支持，网卡自动聚合。但不同于mode0的所有接口流量均衡，而是先占满第一个接口，再依次分配，所以会出现第一个接口流量非常高而其余接口只有小部分流量的情况，不均衡

---------

# 参考文档

- https://blog.csdn.net/wangzongyu/article/details/127097986
- https://blog.csdn.net/weixin_44265455/article/details/139479821
- https://blog.csdn.net/weixin_45548465/article/details/122625777
- https://blog.csdn.net/hezuijiudexiaobai/article/details/131216840