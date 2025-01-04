---
title: oVirt虚拟化管理平台的部署与配置
categories:
  - 极客
tags:
  - Linux
  - oVirt
  - KVM
  - 虚拟化
  - 极客
date: 2022-08-15 12:08:28
---

oVirt，基于kvm的企业级开源虚拟化解决方案，是RedHat商业版RHEV的开源版，整合了libvirt、gluster、patternfly、ansible等一系列优秀的开源软件，定位是替代vmware、vsphere，相比OpenStack的庞大和复杂，其简洁的部署与维护更具优势

---------

# 体系架构

oVirt集群架构由三个部分构成，即管理节点Engine、主机节点Node以及存储节点

## 1.engine

用于运行UI、认证及虚拟机管理服务，主要负责集群用户和管理员的认证、虚拟机的创建、开关机、网络与存储用户和管理员的认证等。主要包含以下功能组件：

- ovirt-engine，集群管理组件，管理主机节点、虚拟机、存储、网络等
- Postgresql数据库，用于持久化数据
- SPICE客户端，用于访问虚拟机的工具

---------

## 2.node

主机节点，安装有vdsm和libvirt组件的linux发行版，以及一些用来实现网络虚拟化和其它系统服务的组件，用于运行虚拟机。主要包含以下功能组件：

- VDSM，主机代理，用于与engine通信，接收engine的命令并执行虚拟机与存储的相关操作。此外，还监视主机资源，如内存、存储和网络，以及管理虚拟机创建、统计信息积累和日志收集等任务
- libvirt，被vdsm调用，执行虚拟机的各种管理命令 
- Guest Agent，虚拟机代理，运行于虚拟机内部，通过一个虚拟串口与外部通信，向engine提供所需信息

---------

## 3.存储节点

存储节点，用于存储虚机镜像和iso镜像，支持块存储与文件存储，也可以是主机节点本地存储，还支持外部存储，如NFS。此外，通过gluster将主机节点自身的磁盘组成存储池，即为超融合架构，从而实现虚拟机的高可用和冗余

---------

# 集群架构

- 192.168.100.100 engine.ovirt
- 192.168.100.180 node01.ovirt
- 192.168.100.200 node02.ovirt

---------

# 1.安装ovirt仓库包
    
    sudo yum install -y http://resources.ovirt.org/pub/yum-repo/ovirt-release43.rpm  

# 2.安装engine

    sudo yum install -y ovirt-engine
    sudo yum update -y

# 3.配置engine，设置admin登录密码

    sudo engine-setup

- 注：设置密码之外的步骤直接回车即可
        
# 4.设置engine通过ip访问
    
    sudo vi /etc/ovirt-engine/engine.conf.d/99-custom-sso-setup.conf
        

    SSO_ALTERNATE_ENGINE_FQDNS="192.168.100.100"
    SSO_CALLBACK_PREFIX_CHECK=false
    
## 重启ovirt-engine服务
    
    sudo systemctl restart ovirt-engine.service

# 5.修改数据中心存储类型为本地

![001](/img/wiki/ovirt/datacenter-local.jpg)

---------

# 6.新建Node节点

![002](/img/wiki/ovirt/host-add.jpg)

---------

# 7.新建本地存储域
    
    # 创建虚拟机镜像存储目录并授予权限
    mkdir -p /home/ovirt/images && chown -R vdsm.root /home/ovirt/images

---------

![003](/img/wiki/ovirt/storage-local-add.jpg)

---------

# 8.新建本地ISO存储域

    # 创建ISO光盘存储目录并授予权限
    mkdir -p /home/ovirt/iso && chown -R vdsm.root /home/ovirt/iso

---------

![004](/img/wiki/ovirt/storage-iso-add.jpg)

---------

# 9.上传ISO光盘文件

# 10.安装虚拟机

## 10.1 Windows安装

## 10.2 创建虚拟机

## 10.3 虚拟机安装guest客户端

    sudo yum -y install epel-release ovirt-guest-agent-common
    sudo apt install -y ovirt-guest-agent

## 10.4 导入KVM虚拟机

### 10.4.1

    # 配置nat网络
    sudo yum install -y vdsm-hook-extnet
    engine-config -s CustomDeviceProperties='{type=interface;prop={extnet=^[a-zA-Z0-9_ ---]+$}}'

---------

# 参考文档

- https://www.cnovirt.com/archives/6
- https://www.freesion.com/article/7685172883
- https://blog.csdn.net/weixin_34345753/article/details/92266128
- http://t.zoukankan.com/bnsdmmL-p-13601026.html
- https://blog.csdn.net/weixin_34281537/article/details/91574467