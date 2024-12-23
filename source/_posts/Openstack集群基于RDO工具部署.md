---
title: Openstack集群基于RDO工具部署
categories:
  - 工作
tags:
  - Linux
  - Openstack
  - 云计算
date: 2023-06-18 22:55:12
---

# 集群架构

- 172.100.100.180 controler
- 172.100.100.181 compute01
- 172.100.100.182 compute02

---------

# 1.配置系统环境

## 1.1 配置hosts

    sudo vi /etc/hosts


    172.100.100.180 controler
    172.100.100.181 compute01
    172.100.100.182 compute02

## 1.2 配置字符集

    sudo vi /etc/environment


    LANG=en_US.utf-8
    LC_ALL=en_US.utf-8

## 1.3 关闭防火墙

## 1.4 禁用selinux

## 1.5 禁用NetworkManager

    sudo systemctl stop NetworkManager
    sudo systemctl disable NetworkManager

## 1.6 控制节点配置外网网卡

# 2.配置集群免密登录

# 3.配置集群时间同步

    sudo yum install -y ntp ntpdate

# 4.安装OpenStack库

    sudo yum update -y
    sudo yum install -y centos-release-openstack-train
    sudo yum update -y

# 5.控制节点安装RDO

    sudo yum install -y openstack-packstack

# 6.控制节点初始化集群

## 6.1 生成应答文件

    packstack --gen-answer-file=openstack.txt

## 6.2 Allinone部署

    sudo packstack --allinone --default-password=Openstack_2023 \
    --os-neutron-l2-agent=openvswitch --ntp-servers=ntp.ntsc.ac.cn \
    --os-neutron-ovs-bridge-interfaces=br-ex:eth0 --provision-demo=n \
    --os-neutron-ovs-bridge-mappings=extnet:br-ex --os-aodh-install=n \
    --os-neutron-ml2-type-drivers=vxlan,vlan,gre,flat,geneve,local \
    --os-neutron-ml2-tenant-network-types=vxlan,vlan,gre,geneve,local \
    --os-neutron-ml2-mechanism-drivers=openvswitch,l2population \
    --os-ceilometer-install=n --os-swift-install=n

## 6.3 多节点部署

### 6.3.1 生成应答文件

    packstack --default-password=Openstack_2023 --gen-answer-file=openstack.txt

### 6.3.2 配置应答文件

    vi openstack.txt


    # 设置是否安装OpenStack对象存储组件swift，默认为y，生产环境设为n，不安装
    CONFIG_SWIFT_INSTALL=n
    # 设置是否安装Openstack计量组件，可不安装
    CONFIG_CEILOMETER_INSTALL=n
    # 设置是否安装OpenStack遥测告警组件aodh，默认为y，生产环境设为n，不安装
    CONFIG_AODH_INSTALL=n
    # 设置NTP时间同步服务器
    CONFIG_NTP_SERVERS=ntp.ntsc.ac.cn
    # 设置控制节点IP
    CONFIG_CONTROLLER_HOST=172.100.100.180
    # 设置计算节点IP
    CONFIG_COMPUTE_HOSTS=172.100.100.181,172.100.100.182
    # 设置网络节点IP
    CONFIG_NETWORK_HOSTS=172.100.100.180
    # 设置块存储节点IP
    CONFIG_STORAGE_HOST=172.100.100.180
    # 设置块存储大小，默认为20G，存储路径为/var/lib/cinder
    CONFIG_CINDER_VOLUMES_SIZE=180G
    # 设置是否安装OpenStack主防火墙，用于控制进出网络的网络包
    CONFIG_NEUTRON_FWAAS=y
    # 设置是否安装OpenStack VPN
    CONFIG_NEUTRON_VPNAAS=y
    # 设置二层网络模块网络类型驱动
    CONFIG_NEUTRON_ML2_TYPE_DRIVERS=vxlan,gre,flat,vlan,geneve,local
    # 设置二层网络模块租户网络类型
    CONFIG_NEUTRON_ML2_TENANT_NETWORK_TYPES=vxlan,gre,vlan,geneve,local
    # 设置二层网络模块网络机制驱动，即设备实现机制
    CONFIG_NEUTRON_ML2_MECHANISM_DRIVER=openvswitch,l2population
    # 设置设置flat二层网络
    CONFIG_NEUTRON_ML2_FLAT_NETWORKS=extnet
    # 设置二层网络代理架构，OVN不支持LBaaS、VPNaaS和FWaaS
    CONFIG_NEUTRON_L2_AGENT=openvswitch
    # 设置flat二层网络关联的网桥
    CONFIG_NEUTRON_OVS_BRIDGE_MAPPINGS=extnet:br-ex
    # 设置桥接网卡，即将br-ex网卡桥接到eth0网卡用于外网连接
    CONFIG_NEUTRON_OVS_BRIDGE_IFACES=br-ex:eth0
    # 设置是否部署演示环境，设为否
    CONFIG_PROVISION_DEMO=n

### 6.3.3 备份应答文件

    grep -vE "^#|^$" openstack.txt > openstack.txt.bak

## 6.4 控制节点初始化集群

    packstack --answer-file=openstack.txt

# 7.配置Dashboard

## 7.1 配置Dashboard访问地址

    sudo cp /etc/httpd/conf.d/15-horizon_vhost.conf /etc/httpd/conf.d/15-horizon_vhost.conf.bak
    sudo sed -i 's/ServerAlias 172.100.100.180/192.168.100.180/g' /etc/httpd/conf.d/15-horizon_vhost.conf

## 7.2 配置控制台访问地址

    sudo cp /etc/nova/nova.conf /etc/nova/nova.conf.bak
    sudo sed -i 's/172.100.100.180:6080/192.168.100.180:6080/g' /etc/nova/nova.conf
    server_proxyclient_address

## 7.3 重启httpd、nova服务

    sudo systemctl restart httpd.service
    sudo systemctl restart openstack-nova-novncproxy.service 

# 8.验证Openstack

---------

# 参考文档

- https://www.cnblogs.com/fengdejiyixx/p/14776814.html
- https://blog.csdn.net/CN_TangZheng/article/details/104543185
- https://m.dandelioncloud.cn/article/details/1613550192089595906