---
title: Ceph分布式存储集群部署
categories:
  - 工作
tags:
  - Linux
  - Ceph
  - 存储
  - 分布式存储
  - 云存储
  - 云计算
date: 2023-07-05 10:50:31
---

Ceph，由C++开发的高性能、高可靠性、可扩展的开源分布式存储系统，提供块存储、文件存储和对象存储服务，以满足不同场景的应用需求，是架设于廉价通用的商用硬件之上的统一企业级存储方案，其规模可轻易地扩展至PB级乃至于EB级，其核心数据分布算法CRUSH摒弃了传统的集中式存储元数据寻址方式，规避了数据库查找这种中心化架构存在的单点故障、性能瓶颈以及不易扩展的缺陷

# 发展历程

- 2004年，Ceph项目起源于加州大学Sage Weil博士的研究课题，设计初衷是致力于避免单节点故障的分布式文件系统
- 2006年，Sage在OSDI学术会议上发表了关于Ceph的论文，并提供了项目的下载链接，随后贡献给了开源社区
- 2008年，Ceph发布第一个版本，版本号为0.1
- 2010年，Ceph被正式集成于Linux内核
- 2011年，Sage Weil创建Inktank公司，主导Ceph的开发和社区维护
- 2014年，Inktank公司被ReaHat收购，Ceph从此进入商用领域

此后，乘着Openstack与云原生的东风，Ceph作为底层存储的基石得以迅速发展，目前已得到众多云计算厂商的广泛支持与应用，如RedHat、OpenStack都将其作为虚拟机镜像及云盘的后端存储

# 逻辑架构

Ceph存储系统自下而上分为三层，即基础存储系统层RADOS、基础库层Librados和应用接口层

## 1.RADOS

RADOS，Reliable,Autonomic,Distributed,Object Store，即可靠、自动化、分布式的对象存储，实质上就是一套完整的对象存储系统，是真实数据存放的最底层

## 2.Librados

底层RADOS存储集群的抽象和封装，提供访问接口，也即是屏蔽底层逻辑，便于用户基于RADOS进行应用开发及深度定制，支持C/C++/JAVA/python/ruby/php/go等编程语言客户端

## 3.应用接口

负责基于Librados库提供抽象层次更高的、更便于应用或客户端使用的、即插即用的应用接口，由三部分构成，即RADOS GWRADOS Gateway 、RBD Reliable Block Device和Ceph FS Ceph File System

- RADOS GW，Amazon S3和Swift兼容的RESTful API的网关接口，以供相应的对象存储应用开发使用，提供对象存储服务，功能不如Librados强大，不能深入到最底层的RADOS

- RBD，提供标准的块设备接口，具备自动精简配置、数据快照、数据克隆及动态调整空间的功能，数据分散存储于OSD节点，常用于在虚拟化的场景下为虚拟机创建数据卷，目前已被Red Hat集成到KVM/QEMU

- Ceph FS，POSIX兼容的分布式文件系统，用户可直接通过客户端挂载使用，内核态程序，通过内核net模块与Rados交互，无需调用用户空间的Librados库

# 功能组件

## 1.Monitors

Ceph Monitors，ceph-mon，即Ceph监视器进程，核心组件，用于维护集群状态的映射、客户端的连接验证及日志的维护，包括监视器映射、管理器映射、OSD映射、MDS映射和CRUSH映射，这些映射是Ceph守护进程相互协调所需的关键集群状态，描述了对象、块存储的物理位置，以及⼀个将设备聚合到物理位置的桶列表，保障了集群数据的一致性，至少三个监视器才可保障集群的高可用性

## 2.Managers

Ceph Managers，ceph-mgr，即Ceph管理器进程，核心组件，用于跟踪、收集集群状态和运行指标，如存储利用率、当前性能指标和系统负载，至少两个管理器才可保障集群的高可用性

## 3.OSD

Ceph OSD，Object Storage Daemon，ceph-osd，即对象存储守护进程，核心组件，以对象的方式管理物理硬盘的数据，如数据的存储、复制、恢复、再平衡等，且各个进程之间通过心跳检测的方式向监视器和管理器提供监视信息，至少三个OSD才可保障集群的高可用性。OSD的构建建议采用SSD磁盘，且以xfs文件系统格式化分区

## 4.MDS

Ceph MDS，Metadata server，ceph-mds，即元数据服务器，负责为存储于OSD节点的Ceph文件存储服务的元数据提供计算、缓存与同步服务，类似于元数据的代理缓存服务器

- 注：Ceph块存储和Ceph对象存储服务不需要MDS

# 工作原理

Ceph集群将多台存储服务器的磁盘合并为一个整体，形成一个大容量的虚拟磁盘设备。文件写入这个分区中时，Ceph将文件切分为多个固定大小（默认为4M）的Objects，并以其为最小单元将之随机均匀地存储到集群各节点的物理磁盘。Object的分布CRUSH经过运算所得，存取操作由每个物理磁盘的对应OSD来完成

Ceph集群为了保障数据的安全，设计了两种数据备份机制，即多副本和纠删码（1）多副本方法，让每个object保存到多个不同节点的OSDs中。ceph默认使用了3副本方法，则表示object保存到了3个不同的OSDs，从而实现数据安全，但是这样会让有效的存储空间降到三分之一。即使使用2副本的方法，也只有50%的空间利用率。但是Ceph的多副本的方法能获得最好的性能。（2）纠删码方法，则是将数据分割成k份，再根据这k份数据计算出m份同样大小的纠删码数据，将数据保存到k+m个不同的OSDs上。若某一份数据丢失，则可以根据仍然存在的>=k份数据计算出丢失的数据，从而获得完整的数据。只要不超过m份数据丢失，则数据依然可以根据通过解码方法计算出完整的数据。对于纠删码的简单理解：1+2+3+4=10，根据前面4份数据，算出了第5份数据的值；当某一份数据丢失时，1+x+3+4=10，则可以根据纠删码的数据算出丢失的数据x=2，从而获得完整的数据。纠删码方式存储数据的好处是能获得更高的空间利用率。例如，k=4，m=1的空间利用率为80%，k=8，m=2的空间利用率也为80%。但是前者是解一元方程，后者是解二元方程，其计算量更大，但是允许故障的OSDs更多。因此，纠删码方法存储数据会消耗较大的计算量，建议给服务器配置更多的CPU线程。特别是当某个OSDs出故障情况下，对整个OSD的数据重建会消耗极大的计算资源和网络负荷。因为该OSD中数据可能和其他所有的OSDs都有联系，对该OSD数据进行重建，需要读取其他OSDs的数据并进行计算恢复。而多副本的方法，则只需要复制相应的数据即可。此外，将一个object存储到多个OSDs，描述其存放位置的术语为放置组（PG / Placement Group），即一个object数据是保存到一个PG中的。而PG如何映射到不同节点上的多个OSDs中，保证数据可靠性，则是 使用CRUSH算法进行。

# 工作流程


文件上传，先将文件切片成N个object（如果开启了cephFS，可以使用MDS缓存）
2:切片后的文件object会存入到Ceph中
3:文件存储前，会经过CRUSH算法，计算当前文件存储归结于哪个PG
4:PG是逻辑概念上对文件存储范围划分的索引
5:根据PG索引将文件存储到指定服务器的OSD中


---------

# 集群架构

- 172.100.100.150/192.168.100.150 node01
- 172.100.100.160/192.168.100.160 node02
- 172.100.100.180/192.168.100.180 node03

---------

# 1.系统环境配置

## 1.1 配置hosts

    sudo vi /etc/hosts


    172.100.100.150/192.168.100.150 node01
    172.100.100.160/192.168.100.160 node02
    172.100.100.180/192.168.100.180 node03
 
## 1.2 关闭防火墙
 
## 1.3 禁用selinux

## 1.4 配置系统内核参数

    sudo vi /etc/sysctl.conf


    fs.file-max = 10000000000
    fs.nr_open = 1000000000

## 1.5 配置用户进程数限制

    sudo vi /etc/security/limits.conf


    * soft nproc 102400
    * hard nproc 104800
    * soft nofile 102400
    * hard nofile 104800

## 1.6 配置集群免密登录

# 2.配置网络

## 2.1 新增集群通信网卡

    # 新增网卡
    sudo virsh attach-interface node01 --type network --source default --model virtio
    # 加载到虚拟机配置文件
    sudo virsh attach-interface node01 --type network --source default --model virtio  --config

    sudo virsh attach-interface node02 --type network --source default --model virtio
    sudo virsh attach-interface node02 --type network --source default --model virtio  --config

    sudo virsh attach-interface node03 --type network --source default --model virtio
    sudo virsh attach-interface node03 --type network --source default --model virtio  --config

## 2.2 配置集群通信网卡IP

    sudo vi /etc/netplan/01-netcfg.yaml


    network:
      version: 2
      renderer: networkd
      ethernets:
        ens2:
          dhcp4: no
          addresses:
            - 192.168.100.150/24
          gateway4: 192.168.100.1
          nameservers:
              addresses: [192.168.100.1,8.8.8.8]
        ens6:
          dhcp4: no
          addresses:
            - 172.100.100.150/24
          gateway4: 172.100.100.1
          nameservers:
              addresses: [172.100.100.1,8.8.8.8]

## 2.3 应用网卡配置

    sudo netplan apply

# 3.配置集群磁盘

## 3.1 新增磁盘

    sudo qemu-img create -f qcow2 /home/kvm/ceph/node01-ceph-01.qcow2 30G
    sudo virsh attach-disk node01 /home/kvm/ceph/node01-ceph-01.qcow2 vdb --live --cache=none --subdriver=qcow2 --config

    sudo qemu-img create -f qcow2 /home/kvm/ceph/node02-ceph-01.qcow2 30G
    sudo virsh attach-disk node02 /home/kvm/ceph/node02-ceph-01.qcow2 vdb --live --cache=none --subdriver=qcow2 --config

    sudo qemu-img create -f qcow2 /home/kvm/ceph/node01-ceph-03.qcow2 30G
    sudo virsh attach-disk node03 /home/kvm/ceph/node01-ceph-03.qcow2 vdb --live --cache=none --subdriver=qcow2 --config

## 3.2 验证磁盘

    sudo lsblk

# 4.安装ceph

    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common wget
    wget -q -O- 'https://mirrors.tuna.tsinghua.edu.cn/ceph/keys/release.asc' | sudo apt-key add -
    echo deb https://mirrors.tuna.tsinghua.edu.cn/ceph/debian-pacific/ $(lsb_release -sc) main | sudo tee /etc/apt/sources.list.d/ceph.list
    sudo apt install -y ceph

# 5.部署mon
    
## 5.1 创建集群配置文件

    sudo vi /etc/ceph/ceph.conf


    [global]
    # 设置集群ID，可用uuidgen命令生成
    fsid = c649ba53-2f1a-431c-8fd4-eb4b423527d5
    mon initial members = node01
    mon host = 192.168.100.150
    # 设置集群管理网络的网段
    public network = 192.168.100.0/24
    # 设置集群通信网络的网段
    cluster network = 172.100.100.0/24
    auth cluster required = cephx
    auth service required = cephx
    auth client required = cephx
    osd journal size = 1024
    # 设置osd副本数，默认为3
    osd pool default size = 3
    # 设置osd最小副本数                    
    osd pool default min size = 2                 
    osd pool default pg num = 16               
    osd pool default pgp num = 16
    osd crush chooseleaf type = 1

## 5.2 创建集群mon密钥环

    sudo ceph-authtool --create-keyring /tmp/ceph.mon.keyring --gen-key -n mon. --cap mon 'allow *'

## 5.3 创建集群管理密钥环

    sudo ceph-authtool --create-keyring /etc/ceph/ceph.client.admin.keyring --gen-key -n client.admin --cap mon 'allow *' --cap osd 'allow *' --cap mds 'allow *' --cap mgr 'allow *'
    sudo chmod +r /etc/ceph/ceph.client.admin.keyring

## 5.4 创建osd引导密钥环

    sudo ceph-authtool --create-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring --gen-key -n client.bootstrap-osd --cap mon 'profile bootstrap-osd' --cap mgr 'allow r'

## 5.5 mon密钥环导入到管理密钥环、osd引导密钥环

    sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /etc/ceph/ceph.client.admin.keyring
    sudo ceph-authtool /tmp/ceph.mon.keyring --import-keyring /var/lib/ceph/bootstrap-osd/ceph.keyring
    sudo chown ceph:ceph /tmp/ceph.mon.keyring

## 5.6 创建ceph监视图

    monmaptool --create --add node01 192.168.100.150 --fsid c649ba53-2f1a-431c-8fd4-eb4b423527d5 /tmp/monmap

## 5.7 初始化mon

    # 创建mon目录，默认命名格式为ceph-hostname
    sudo -u ceph mkdir /var/lib/ceph/mon/ceph-node01
    sudo -u ceph ceph-mon --mkfs -i node01 --monmap /tmp/monmap --keyring /tmp/ceph.mon.keyring
    # 防止重新安装，创建空的done文件
    sudo -u ceph touch /var/lib/ceph/mon/ceph-node01/done

## 5.8 启动监视器服务，查看状态

    sudo systemctl start ceph-mon@node01
    sudo systemctl enable ceph-mon@node01

## 5.9 其余节点部署监视器

### 5.9.1 将配置文件发往其余节点

    scp -r /etc/ceph node02:/etc
    scp -r /etc/ceph node02:/etc

### 5.9.2 node02部署mon

    ssh node02 sudo -u ceph mkdir /var/lib/ceph/mon/ceph-node02
    # 获取监视器密钥环
    ssh node02 ceph auth get mon. -o /tmp/ceph.mon.keyring
    # 获取监视器运行图
    ssh node02 ceph mon getmap -o /tmp/ceph.mon.map
    ssh node02 sudo chown ceph.ceph /tmp/ceph.mon.keyring
    ssh node02 sudo -u ceph ceph-mon --mkfs -i node02 --monmap /tmp/ceph.mon.map --keyring /tmp/ceph.mon.keyring
    ssh node02 sudo -u ceph touch /var/lib/ceph/mon/ceph-node02/done
    ssh node02 sudo systemctl start ceph-mon@node02
    ssh node02 sudo systemctl enable ceph-mon@node02

### 5.9.3 node03部署mon

    ssh node03 sudo -u ceph mkdir /var/lib/ceph/mon/ceph-node03
    ssh node03 ceph auth get mon. -o /tmp/ceph.mon.keyring
    ssh node03 ceph mon getmap -o /tmp/ceph.mon.map
    ssh node03 sudo chown ceph.ceph /tmp/ceph.mon.keyring
    ssh node03 sudo -u ceph ceph-mon --mkfs -i node03 --monmap /tmp/ceph.mon.map --keyring /tmp/ceph.mon.keyring
    ssh node03 sudo -u ceph touch /var/lib/ceph/mon/ceph-node03/done
    ssh node03 sudo systemctl start ceph-mon@node03
    ssh node03 sudo systemctl enable ceph-mon@node03

### 5.9.4 验证服务状态

    ceph mon stat

# 6.部署osd

## 6.1 导出集群osd引导密钥环

    sudo ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring

## 6.2 初始化osd

    sudo ceph-volume lvm create --data /dev/vdb
    sudo ceph-volume lvm create --data /dev/vdc
    sudo ceph-volume lvm create --data /dev/vdd

## 6.3 启动osd

    sudo systemctl start ceph-osd@0
    sudo systemctl enable ceph-osd@0
    sudo systemctl start ceph-osd@1
    sudo systemctl enable ceph-osd@1
    sudo systemctl start ceph-osd@2
    sudo systemctl enable ceph-osd@2

- 注：osd编号从0开始自动增加，可逐个节点逐个盘的创建，守护进程也是用该ID作为标识

## 6.4 集群其余节点部署osd

### 6.4.1 node02部署osd

    ssh node02 sudo ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring
    ssh node02 sudo ceph-volume lvm create --data /dev/vdb
    ssh node02 sudo ceph-volume lvm create --data /dev/vdc
    ssh node02 sudo ceph-volume lvm create --data /dev/vdd
    ssh node02 sudo systemctl start ceph-osd@3
    ssh node02 sudo systemctl enable ceph-osd@3
    ssh node02 sudo systemctl start ceph-osd@4
    ssh node02 sudo systemctl enable ceph-osd@4
    ssh node02 sudo systemctl start ceph-osd@5
    ssh node02 sudo systemctl enable ceph-osd@5

### 6.4.2 node03部署osd

    ssh node03 sudo ceph auth get client.bootstrap-osd -o /var/lib/ceph/bootstrap-osd/ceph.keyring
    ssh node03 sudo ceph-volume lvm create --data /dev/vdb
    ssh node03 sudo ceph-volume lvm create --data /dev/vdc
    ssh node03 sudo ceph-volume lvm create --data /dev/vdd
    ssh node03 sudo systemctl start ceph-osd@6
    ssh node03 sudo systemctl enable ceph-osd@6
    ssh node03 sudo systemctl start ceph-osd@7
    ssh node03 sudo systemctl enable ceph-osd@7
    ssh node03 sudo systemctl start ceph-osd@8
    ssh node03 sudo systemctl enable ceph-osd@8

## 6.5 验证服务状态

    ceph osd stat
    # 查看osd目录树及osd所属服务器与状态
    ceph osd tree

# 7.部署mgr

## 7.1 创建mgr密钥环

    ceph auth get-or-create mgr.node01 mon 'allow profile mgr' osd 'allow *' mds 'allow *'

## 7.2 创建mgr节点目录

    # 节点目录默认名称为集群名称+节点名称
    sudo -u ceph mkdir /var/lib/ceph/mgr/ceph-node01

## 7.3 获取mgr密钥环，导出到节点目录下，默认为keyring

    sudo -u ceph ceph auth get mgr.node01 -o /var/lib/ceph/mgr/ceph-node01/keyring

## 7.4 启动mgr

    sudo systemctl start ceph-mgr@node01
    sudo systemctl enable ceph-mgr@node01

## 7.5 部署热备mgr

    ssh node02 ceph auth get-or-create mgr.node02 mon 'allow profile mgr' osd 'allow *' mds 'allow *'
    ssh node02 sudo -u ceph mkdir /var/lib/ceph/mgr/ceph-node02
    ssh node02 sudo -u ceph ceph auth get mgr.node02 -o /var/lib/ceph/mgr/ceph-node02/keyring
    ssh node02 sudo systemctl start ceph-mgr@node02
    ssh node02 sudo systemctl enable ceph-mgr@node02

# 8.部署dashboard

## 8.1 启用dashboard

    ceph mgr module enable dashboard

## 8.2 启用自签名证书

    ceph dashboard create-self-signed-cert

## 8.3 创建自签名SSL证书

    openssl req -new -nodes -x509 \
    -subj "/O=OPS/CN=ceph-mgr-dashboard" -days 3650 \
    -keyout dashboard.key -out dashboard.crt -extensions v3_ca

## 8.4 导入证书文件和私钥文件

    ceph dashboard set-ssl-certificate -i dashboard.crt

## 8.5 设置访问地址及端口

    ceph config set mgr mgr/dashboard/server_addr 192.168.100.150
    ceph config set mgr mgr/dashboard/server_port 8080
    ceph config set mgr mgr/dashboard/ssl_server_port 8443

## 8.6 设置用户及密码

    echo "admin@ceph" > dashboard_passwd.txt
    ceph dashboard ac-user-create admin administrator -i dashboard_passwd.txt

## 8.7 禁用SSL认证

    # 也可禁用SSL认证，使用8080端口进行http访问
    # ceph config set mgr mgr/dashboard/ssl false
    # 重启mgr
    # sudo systemctl restart ceph-mgr@node01

## 8.8 登录web页面，验证dashboard

# 9.验证集群状态

    # 集群禁止非安全模式
    ceph config set mon auth_allow_insecure_global_id_reclaim false
    # 开启mon组件msgr2消息传递协议
    ceph mon enable-msgr2

    # 查看ceph集群整体状态
    ceph -s
    # 查看ceph集群健康状态
    ceph health detail
    # 查看ceph集群的存储空间
    ceph df
    # 查看ceph的实时运行状态
    ceph -w

---------

# 参考文档

- https://www.cnblogs.com/punchlinux/p/17053624.html
- https://blog.csdn.net/jkjgj/article/details/128785139
- https://blog.csdn.net/weixin_43860781/article/details/109053152