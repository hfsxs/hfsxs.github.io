---
title: RockyLinux9配置静态IP
categories:
  - 工作
tags:
  - Linux
  - Rocky9
  - 网络
  - 云计算
date: 2023-12-10 11:07:05
---

Rocky Linux，Centos的创始人Gregory Kurtzer所引领的社区企业级操作系统，是CentOS官方宣布停止Centos的维护之后的替换项目，其命名是为了纪念CentOS早期的联合创始人Rocky McGaugh

# 1.查看系统网卡名称

    ip addr

# 2.修改网卡配置

    sudo cp /etc/NetworkManager/system-connections/ens32.nmconnection /etc/NetworkManager/system-connections/ens32.nmconnection.bak
    sudo vi /etc/NetworkManager/system-connections/ens32.nmconnection

    
    [connection]
    id=ens32
    uuid=887ca84f-46c5-38ad-a5c4-757b56999fbd
    type=ethernet
    autoconnect-priority=-999
    interface-name=ens32
    timestamp=1686652135

    [ethernet]

    [ipv4]
    method=manual
    address1=192.168.100.120/24,192.168.100.1
    dns=8.8.8.8

    [ipv6]
    addr-gen-mode=eui64
    method=auto

    [proxy]

# 3.重新加载网络配置

    nmcli c reload
    nmcli c up ens32
    ip a

# 4.配置国内Yum源



---------

# 参考文档

- https://www.cnblogs.com/tigerisnotcat/p/17479898.html
- https://blog.csdn.net/qq_41195336/article/details/134255595