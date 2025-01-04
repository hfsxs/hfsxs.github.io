---
title: KVM网络模式详解
categories:
  - 工作
tags:
  - Linux
  - KVM
  - 虚拟化
  - 云计算
date: 2022-03-07 14:27:35
---

kvm虚拟机的网络连接模式有两种，即NAT和Bridge模式

---------

# 1.NAT

NAT是KVM默认的网络连接方式，此模式下宿主机配置有虚拟网桥virbr0作为虚拟交换机，并绑定到虚拟网卡virbr0-nic。虚拟机的虚拟网卡vnet0连接virbr0交换机，通过virbr0-nic网卡将数据包转发到宿主机。此时的宿主机已经配置了iptables，成为配置了SNAT规则具备路由功能的路由器，从而将数据包发送到外网进行数据交换

## 1.1 查看所有虚拟网络配置

    sudo virsh net-list --all

## 1.2  修改虚拟网络default

### 1.2.1 备份default配置

    sudo virsh net-dumpxml default > default.xml

### 1.2.2 修改虚拟网络default  

    sudo virsh net-edit default

### 1.2.3 重新定义虚拟网络default

    sudo virsh net-define --file /etc/libvirt/qemu/networks/default.xml

### 1.2.4 设置虚拟网络default自动启动

    sudo virsh net-autostart default

## 1.3 创建虚拟机

    sudo virt-install --name=centos7 --memory=1024,maxmemory=2048 --vcpus=1,maxvcpus=2 --os-variant=centos7.0 \
    --location=/home/kvm/images/CentOS-7-x86_64-Minimal-2009.iso --disk /home/kvm/templates/centos7.img,size=30 --network network=default \
    --graphics=none --console=pty,target_type=serial --extra-args='console=ttyS0'

## 1.4 查看虚拟交换机的连接

    sudo brctl show

## 1.5 查看虚拟机网络接口类型

    sudo sudo virsh domiflist centos7

## 1.6 查看虚拟机网卡IP地址

    sudo sudo virsh domifaddr centos7
    
# 2.Bridge

Bridge模式是将宿主机的物理网卡eth0桥接到虚拟交换机virbr1，虚拟机的虚拟网卡vnet0连接virbr1交换机，从而直接将数据包通过宿主机的物理网卡发送到外网进行数据交换

## 2.1 centos配置桥接网络

### 2.1.1 创建虚拟网桥配置文件

    sudo vi /etc/sysconfig/network-scripts/ifcfg-virbr1


    # 设置设备类型为网桥
    TYPE=Bridge
    BOOTPROTO=static
    # 设置网桥名称
    NAME=virbr1
    DEVICE=virbr1
    ONBOOT=yes
    IPADDR=192.168.100.100
    GATEWAY=192.168.100.1
    DNS1=192.168.100.1
    DNS2=8.8.8.8

### 2.1.2 宿主机物理网卡连接虚拟网桥

    sudo cp /etc/sysconfig/network-scripts/ifcfg-enp1s0 /etc/sysconfig/network-scripts/ifcfg-enp1s0.bak
    sudo vi /etc/sysconfig/network-scripts/ifcfg-enp1s0


    TYPE=Ethernet
    PROXY_METHOD=none
    BROWSER_ONLY=no
    BOOTPROTO=static
    DEFROUTE=yes
    IPV4_FAILURE_FATAL=no
    IPV6INIT=yes
    IPV6_AUTOCONF=yes
    IPV6_DEFROUTE=yes
    IPV6_FAILURE_FATAL=no
    IPV6_ADDR_GEN_MODE=stable-privacy
    NAME=enp1s0
    UUID=77096720-9699-44b0-83d7-582538c24bec
    DEVICE=enp1s0
    ONBOOT=yes

    BRIDGE=virbr1

    # IPADDR=192.168.100.100
    # NETMASK=255.255.255.0
    # GATEWAY=192.168.100.1
    # DNS1=192.168.100.1
    # DNS2=8.8.8.8

### 2.1.3 重启网络服务以生效网络配置

    sudo systemctl restart network
    
### 2.1.4 创建虚拟机

    sudo virt-install \
    --name=debian10 --memory=1024,maxmemory=2048 --vcpus=1,maxvcpus=2 --os-variant=debian10 \
    --location=/home/kvm/images/debian-10.9.0-amd64-netinst.iso --disk /home/kvm/templates/debian10.qcow2,size=30 --network bridge=virbr1 \
    --graphics=none --console=pty,target_type=serial --extra-args='console=ttyS0'
    
### 2.1.5 查看虚拟交换机的连接

    sudo brctl show

### 2.1.6 查看虚拟机网络接口类型

    sudo sudo virsh domiflist debian10

### 2.1.7 查看虚拟机网卡IP地址

    sudo sudo virsh domifaddr debian10

## 2.2 debian配置桥接网络

    sudo apt install -y bridge-utils

### 2.2.1 创建虚拟网桥配置文件

    sudo vi /etc/network/interfaces.d/virbr1


    auto virbr1
    iface virbr1 inet static
      address 192.168.100.100
      broadcast 192.168.100.255
      netmask 255.255.255.0
      gateway 192.168.100.1
      # dns-nameservers 192.168.2.254
      # If you have muliple interfaces such as eth0 and eth1
      # bridge_ports eth0 eth1
      bridge_ports enp3s0
      bridge_stp off
      bridge_waitport 0
      bridge_fd 0

## 2.3 ubuntu配置桥接网络

### 2.3.1 创建虚拟网桥配置文件

    sudo cp /etc/netplan/01-network-manager-all.yaml  /etc/netplan/01-network-manager-all.yaml.bak
    sudo vi /etc/netplan/01-network-manager-all.yaml


    network:
      version: 2
      renderer: networkd
      ethernets:
        enp3s0:
          dhcp4: no
      bridges:
        virbr1:
          interfaces:
            - enp3s0
          addresses:
            - 192.168.100.240/24
          gateway4: 192.168.100.1
          nameservers:
              addresses: [192.16.100.1, 8.8.8.8]

### 2.3.2 应用网卡配置

    sudo netplan apply
    
# 3.NAT模式转换为Bridge模式

NAT网络模式下虚拟机可以访问外网，但外网不可访问虚拟机资源，而Bridge模式支持外网访问，由此需求的情况可将虚拟机的网络从NAT模式转换为Bridge模式

## 3.1 关闭虚拟机

    sudo virsh shutdown node01

## 3.2 修改虚拟机配置文件的网络模式

    sudo virsh edit node01


    # 设置网络类型为bridge
    <interface type='bridge'>
      <mac address='52:54:00:4f:2f:3e'/>
      # 设置网络名称
      <source bridge='virbr1'/>
      <model type='virtio'/>
      <address type='pci' domain='0x0000' bus='0x00' slot='0x03' function='0x0'/>
    </interface>

## 3.3 开启虚拟机，配置网卡

---------

# 参考文档

- https://blog.51cto.com/yangshufan/2130263
- https://blog.csdn.net/hzhsan/article/details/44098537
- https://www.cnblogs.com/zhangjianchao/p/15329593.html