---
title: Ubuntu配置静态IP
categories:
  - - 工作
  - - 极客
tags:
  - Linux
  - Ubuntu
  - 网络
  - 云计算
  - 极客
date: 2020-12-09 14:20:11
---

### 1.查看网卡名称

    ip a

### 2.创建网卡配置文件

    sudo mv /etc/netplan/01-network-manager-all.yaml /etc/netplan/01-network-manager-all.yaml.bak
    sudo vi /etc/netplan/01-network-manager-all.yaml



    # This file describes the network interfaces available on your system
    # For more information, see netplan(5).
    
    network:
      version: 2
      renderer: networkd
      ethernets:
        enp3s0:
          addresses:
            - 172.16.100.120/24
          gateway4: 172.16.100.1
          nameservers:
              addresses: [172.16.100.1, 8.8.8.8]
            
### 3.应用网卡配置

    sudo netplan apply

### 4.配置vi环境

    sudo vi /etc/vim/vimrc.tiny


    set nocompatible
    set backspace=2