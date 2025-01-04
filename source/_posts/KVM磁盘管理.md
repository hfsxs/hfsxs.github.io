---
title: KVM磁盘管理
categories:
  - 工作
tags:
  - Linux
  - KVM
  - 虚拟化
  - 云计算
date: 2022-03-16 22:45:52
---

KVM虚拟机由两部分组成，即配置文件和磁盘文件，配置文件描述了虚拟机的详细参数，路径默认为/etc/libvirt/qemu；磁盘文件即为虚拟机的镜像，支持多种格式，raw和qcow2这两种格式最为常见

- raw，意为未被加工的，又被称为原始镜像或裸设备镜像，KVM默认格式，指定多大就创建多大，直接占用指定大小的空间，镜像文件由宿主机的文件系统来管理，可直接挂载，性能优于qcow2，且通用性好，可随意进行格式转换，所以常作为其他格式转换时的中间格式。缺点是不支持内部快照与加密，远程传输网络IO消耗较大，建议转换格式再传输

- qcow2，主流虚拟机磁盘镜像格式，也是openstack默认格式，空间动态增长，文件及快照较小，性能接近raw，且支持zlib磁盘压缩及AES加密。缺点是性能略低于raw，且镜像文件一旦损坏则文件系统全部不可用
  
---------

# 1.虚拟机磁盘扩容

## 1.1 虚拟机添加新磁盘

### 1.1.1 创建虚拟磁盘

    qemu-img create -f qcow2 /home/kvm/servers/node01-001.qcow2 10G

### 1.1.2 验证新增磁盘信息

    qemu-img info /home/kvm/servers/node01-001.qcow2

### 1.1.3 虚拟机node01添加新磁盘

    # 临时生效，--live，热添加；vdb，第二块硬盘；--cache，宿主机对虚拟机镜像的读写缓存；--subdriver，硬盘驱动类型
    # virsh attach-disk node01 /home/kvm/servers/node01-001.qcow2 vdb --live --cache=none --subdriver=qcow2

    virsh attach-disk node01 /home/kvm/servers/node01-001.qcow2 vdb --live --cache=none --subdriver=qcow2 --config

### 1.1.4 登录虚拟机验证新增的硬盘

    lsblk

### 1.1.5 卸载硬盘

    virsh detach-disk node01 vdb

## 1.2 虚拟机扩容磁盘

### 1.2.1 调整虚拟磁盘容量，只能增大不能减小

    qemu-img resize /home/kvm/servers/node01-001.qcow2 +10G

### 1.2.2 验证磁盘容量

    qemu-img info /home/kvm/servers/node01-001.qcow2

### 1.2.3 虚拟机node01在线添加新磁盘

    virsh attach-disk node01 /home/kvm/servers/node01-001.qcow2 vdb --live --cache=none --subdriver=qcow2 --config

### 1.2.4 登录虚拟机验证新增的硬盘

    lsblk

### 1.2.5 新硬盘分区后挂载 

## 1.3 虚拟机扩容非根分区

### 1.3.1 登录虚拟机，卸载文件系统

    umount /opt

### 1.3.2 在线扩容虚拟磁盘

    qemu-img resize /home/kvm/servers/node01-001.qcow2 5G

### 1.3.3 登录虚拟机重新挂载文件系统

    mount  /dev/vdb  /opt/

### 1.3.4 更新文件系统，调整元数据

     xfs_growfs  /opt

### 1.3.5 验证磁盘扩容

    dh -h

## 1.4 虚拟机扩容根分区

### 1.4.1 关闭虚拟机

### 1.4.2 在线扩容虚拟机磁盘

    qemu-img  resize  /home/kvm/servers/node01.qcow2 +10G

### 1.4.3 登录虚拟机重新分区

    fdisk /dev/vda

    # 删除原有分区，重新创建分区，然后通知内核系统分区已变化
    partprobe

### 1.4.4 重启虚拟机

### 1.4.5 登录虚拟机更新文件系统

    xfs_growfs /dev/centos/root

### 1.4.6 验证磁盘扩容

    df -h

# 2.虚拟机快照管理

KVM虚拟机快照用于保存虚拟机在某个时间点内存、磁盘或设备的状态，若有需要可再回滚到这个时间点。快照分为磁盘快照和内存快照两类，两者组合构成了一个系统还原点，记录了虚拟机在某个时间点的全部状态

磁盘快照根据存储方式的不同，分为内部快照和外部快照

- 内部快照，只支持qcow2格式的虚拟机镜像，快照及后续变动都保存在原来的qcow2文件内，平常所说的快照通常即为这种

- 外部快照，被保存于另一个单独文件，创建快照时间点之后的数据被记录到一个新的qcow2文件，原镜像文件即成为新镜像文件的backing file（只读），在创建多个快照后，这些文件将形成一个备份链。外部快照同时支持raw和qcow2格式的虚拟机镜像，需要安装qemu-kvm-rhev

---------

## 2.1 创建虚拟机快照

    sudo virsh snapshot-create-as centos7 centos7 --description "centos7"

## 2.2 查看快照

    sudo virsh snapshot-list centos7

## 2.3 查看快照信息

    sudo virsh snapshot-info centos7 --snapshotname centos7

## 2.4 快照回滚

    sudo virsh snapshot-revert centos7 centos7

## 2.5 快照删除

    sudo virsh snapshot-delete centos7 centos7

---------

# 参考文档

- https://www.shuzhiduo.com/A/D854PDBQ5E
- https://blog.51cto.com/u_3646344/2096347
- http://koumm.blog.51cto.com/703525/1304196
- https://blog.csdn.net/weixin_30875157/article/details/97096593