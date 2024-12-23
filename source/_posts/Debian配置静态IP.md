---
title: Debian配置静态IP
categories:
  - 工作
tags:
  - Linux
  - Debian
  - 网络
  - 云计算
date: 2020-09-30 11:15:54
---

# 1.查看系统网卡名称

    ip addr

# 2.修改网卡配置

    sudo cp /etc/network/interfaces /etc/network/interfaces.bak
    sudo vi /etc/network/interfaces 

 
    # This file describes the network interfaces available on your system
    # and how to activate them. For more information, see interfaces(5).
    source /etc/network/interfaces.d/*
    # The loopback network interface
    auto lo
    iface lo inet loopback

    # The primary network interface
    allow-hotplug enp3s0
    auto enp3s0
    iface enp3s0 inet static
      address 192.168.100.100/24
      broadcast 192.168.100.255
      network 192.168.100.1
      gateway 192.168.100.1
  
# 3.重启网络服务

    sudo systemctl restart networking.service

# 4.配置vim环境

    sudo vi /etc/vim/vimrc.tiny


    set nocompatible
    set backspace=2 