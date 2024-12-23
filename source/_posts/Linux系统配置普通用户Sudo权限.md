---
title: Linux系统配置普通用户Sudo权限
categories:
  - 工作
tags:
  - Linux
  - Sudo
  - 云计算
date: 2020-02-07 09:15:13
---

Root，Linux系统的超级管理员用户，可访问Linux系统任何文件和运行任何命令，拥有系统完全控制的能力。一个错误的命令可能会破坏系统文件和配置，日常的管理操作应谨慎使用root用户。为安全考虑，普通用户的权限有所限制，这就给日常运维工作带来了极大的不便。基于此，Linux系统引入了sudo的概念，通过配置sudo使得普通用户拥有root命令的某些权限，既保障了运维工作的便捷性，又将风险固定了一定的可控范围内

# 1.安装sudo

    yum install -y sudo
    apt install -y sudo

# 2.配置sudo审计日志

    echo "Defaults logfile=/var/log/sudo.log"  >> /etc/sudoers

# 3.配置普通用户sword sudo权限

    vi /etc/sudoers


    # 配置sword拥有root用户所有权限，且免密码输入
    sword    ALL=(ALL)       NOPASSWD:ALL
    # 配置sword拥有virsh及systemctl命令执行的权限，且免密码输入
    # sword   ALL=(ALL)       NOPASSWD: /usr/bin/virsh,/bin/systemctl

# 4.检查配置文件

    visudo -c

# 5.测试sudo及其审计功能

    su - sword
    sudo systemctl restart sshd