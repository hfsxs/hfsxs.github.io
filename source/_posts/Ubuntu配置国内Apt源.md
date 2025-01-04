---
title: Ubuntu配置国内Apt源
categories:
  - - 工作
  - - 极客
tags:
  - Linux
  - Ubuntu
  - Apt
  - 云计算
  - 极客
date: 2020-12-10 15:22:38
---

### 1.备份apt源配置文件

    sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak

### 2.创建apt源配置文件

    sudo vi /etc/apt/sources.list


    # ustc mirrors
    deb https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
    deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic main restricted universe multiverse
    deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
    deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-updates main restricted universe multiverse
    deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
    deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-backports main restricted universe multiverse
    deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
    deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-security main restricted universe multiverse
    deb https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse
    deb-src https://mirrors.ustc.edu.cn/ubuntu/ bionic-proposed main restricted universe multiverse

### 3.更新软件包

    # 更新存储库索引
    sudo apt update
    # 升级所有可更新的包
    sudo apt upgrade -y
    # 删除不需要的依赖包
    sudo apt autoremove
