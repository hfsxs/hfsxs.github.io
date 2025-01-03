---
title: Linux系统启动过程详解
categories:
  - 工作
tags:
  - Linux
  - 操作系统
  - 云计算
date: 2023-05-27 23:24:22
---

Linux系统的启动是指计算机加电到显示用户登陆提示的整个过程，最终将计算机带入工作状态，是一个复杂而有序的多阶段系统事件，对操作系统管理计算机资源的理解、系统性能的优化以及系统启动故障的排查非常有帮助

![boot](/img/wiki/linux/boot.png)

# 1.硬件引导

计算机打开电源后，首先是BIOS开机自检，按照BIOS中设置的启动设备启动系统，通常为硬盘，然后由启动设备的主引导扇区所存储的引导加载程序（BootLoader）读取引导程序GRUB和硬盘分区表

# 2.加载内核

GRUB引导程序加载内核和镜像文件到内存，进行操作系统内核的运行。之后，由Linux操作系统全面接管硬件

# 3.运行init

内核加载完毕后，Linux操作系统将会启动第一个守护进程init，进程PID为1，所有的进程都是其子进程，之后再读取进程运行等级文件/etc/inittab，以确定所需要启动的程序与服务。Linux系统运行级别，runlevel，代表了Linux的运行状态，分为7个级别，具体如下：

- 级别0，系统停机状态，默认运行级别不能设为0，否则不能正常启动
- 级别1，单用户工作状态，root权限，用于系统维护，禁止远程登录
- 级别2，多用户状态，没有NFS
- 级别3，完全的多用户状态，有NFS，登录后进入控制台命令行模式，最为常用
- 级别4，系统未使用，保留级别
- 级别5，X11控制台，登录后进入图形GUI模式
- 级别6，系统正常关闭并重启，默认运行级别不能设为6，否则不能正常启动

# 4.系统初始化

init进程通过调用/etc/rc.d/rc.sysinit这个bash shell脚本来完成系统的初始化工作，如激活交换分区、加载硬件模块、设置系统时间、挂载文件系统、启动磁盘检查等。此外，还会加载并启动一些必要的守护进程和服务，以便在系统启动的后续阶段能够正常运行

# 5.建立终端

rc.sysinit执行完毕后，返回init，此时基本系统环境已完成设置，各种守护进程也已启动。init接着将会打开6个终端，分别为tty1、tty2、tty3、tty4、tty5和tty6，用户可以通过这些终端进行命令行登录或远程登录

# 6.用户登录

用户登录方式分为三种，即命令行登陆、SSH登陆和图形界面登陆，Linux系统通过账号验证程序login对登录用户进行验证

---------

# 参考文档

- https://www.runoob.com/linux/linux-system-boot.html
- https://servu.nwafu.edu.cn/servers_mgr/booting.html
- https://blog.csdn.net/zhangkunls/article/details/132769955