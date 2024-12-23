---
title: Ansible自动化运维工具常用模块
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2022-09-14 16:02:54
---

# 1.command

默认模块，远程主机执行命令时不经过其shell处理，不支持管道符、重定向和变量  
    
    ansible hosts -m command -a 'uptime'
    # chdir，执行命令前先切换到指定目录
    ansible hosts -m command -a 'chdir=/root ls -l' 

# 2.shell

基础模块，远程主机执行命令时经过其/bin/sh程序处理

    ansible master -m shell -a 'chdir=/root ps -ef|grep keepalived|grep -v grep'
    

# 3.yum/apt

用于管理远程主机的RPM/DEB包，执行安装、升级及卸载操作

参数详解：  
name，包名字  
state，对包进行的操作，latest/installd/present表示安装，removed/absent表示卸载 
    
    # 安装最新版本docker
    ansible hosts -m yum -a 'name=docker state=latest'
    # 安装指定版本软件包
    ansible hosts -m apt -a 'name=docker-20. state=present'
    # 将所有软件包升级到最新版本
    ansible hosts -m apt -a 'name=* state=latest'
    
    # 卸载软件包
    ansible hosts -m yum -a 'name=docker state=absent'

# 4.copy

用于将控制主机的文件复制到受控主机的制定目录，类似于scp命令，但不支持文件夹和变量

参数详解：  
src，本地文件路径  
dest，远程主机路径  
backup，备份，默认为no，远程主机的同名文件将被覆盖  
owner，设置受控主机文件属主，默认与控制主机的权限一致  
group，设置受控主机文件属组，默认与控制主机的权限一致  
mode，远程主机的文件权限，默认与控制主机的权限一致
    
    ansible hosts -m copy -a 'src=/root/docker- dest=/root'
    # 将本地文件复制到受控主机，若内容不同则执行备份操作
    ansible hosts -m copy -a 'src=/etc/hosts dest=/etc backup=yes'
    # 将本地文件复制到受控主机，并修改文件权限
    ansible host -m copy -a 'src=/root/docker- dest=/home/sword owner=sword group=sword mode=755'
    

# 5.unarchive

用于解压缩远程主机的压缩包

参数详解：  
src，控制主机的压缩包文件路径，默认上传到远程主机  
dest，远程主机压缩包解压的路径  
copy，是否拷贝压缩包文件到远程主机，默认为yes，no则表示在远程主机搜索压缩包文件  
exec，排除的文件或目录  
owner，设置受控主机文件属主，默认与控制主机的权限一致  
group，设置受控主机文件属组，默认与控制主机的权限一致  
mode，远程主机的文件权限，默认与控制主机的权限一致

    ansible hosts -m unarchive -a 'src=docker-20.10.16.tgz dest=/root'
    ansible hosts -m unarchive -a 'src=/root/apache-tomcat-10.0.20.tar.gz dest=/usr/local mode=755'

# 5.service

用于管理远程主机上的服务，且远程主机的服务须通过BSD init,、OpenRC、SysV、Solaris SMF、systemd、
upstart中的任意一种所管理

参数详解：  
name，服务名称  
state，对服务进行的操作，started表示启动，stopped表示停止，restarted表示重启，reloaded表示重载  
enabled，yes表示服务设为开机启动，no则相反
    
    ansible hosts -m service -a 'name=docker state=started enabled=yes'

---------

# 参考文档

- https://blog.csdn.net/xcndafad/article/details/122138782?spm=1001.2014.3001.5502