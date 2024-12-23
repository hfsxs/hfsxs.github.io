---
title: Debian配置国内Apt源
categories:
  - 工作
tags:
  - Linux
  - Debian
  - Apt
  - 云计算
date: 2020-09-30 11:18:23
---

# 1.备份apt源配置文件

    sudo mv /etc/apt/sources.list /etc/apt/sources.list.bak

# 2.创建apt源配置文件

    sudo vi /etc/apt/sources.list


    # ustc mirrors
    deb http://mirrors.ustc.edu.cn/debian/ buster main
    deb http://mirrors.ustc.edu.cn/debian/ buster-updates main
    deb-src http://mirrors.ustc.edu.cn/debian/ buster main
    deb-src http://mirrors.ustc.edu.cn/debian/ buster-updates main
    deb-src http://mirrors.ustc.edu.cn/debian/ buster-backports main non-free contrib

    deb https://mirrors.ustc.edu.cn/debian/ buster-backports main contrib non-free
    deb https://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib non-free
    deb-src https://mirrors.ustc.edu.cn/debian-security/ buster/updates main contrib non-free

# 3.更新软件包

    # 刷新存储库索引
    sudo apt update -y
    # 升级所有可更新的包
    sudo apt upgrade -y

# 4.设置时区及时间格式

    ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
    localectl set-locale LC_TIME=en_GB.UTF-8

# 5.安装常用工具软件

    sudo apt install -y sudo bash-completion