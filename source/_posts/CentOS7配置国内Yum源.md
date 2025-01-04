---
title: CentOS7配置国内Yum源
categories:
  - 工作
tags:
  - Linux
  - CentOS
  - Yum
  - 云计算
date: 2020-02-01 09:16:29
---

Yum，“Yellow dog Updater, Modified”，RedHat系列发行版的RPM软件包管理器，即从指定的服务器自动下载、安装RPM包，并自动的、一次性的解决软件包的依赖关系，无需编译安装那样繁琐地一次次下载、编译及安装，节省了大量的查找、安装依赖包的时间。Yum由软件源仓库和客户端两部分组成，官方源由于防火墙的原因下载速度受限，一般都要更改为国内源，以提高下载速度

# 1.备份原yum源配置文件

    cd /etc/yum.repos.d
    mv CentOS-Base.repo CentOS-Base.repo.bak

# 2.创建yum源配置文件

    vi CentOS-Base.repo


    # CentOS-Base.repo
    #
    # The mirror system uses the connecting IP address of the client and the
    # update status of each mirror to pick mirrors that are updated to and
    # geographically close to the client.  You should use this for CentOS updates
    # unless you are manually picking other mirrors.
    #
    # If the mirrorlist= does not work for you, as a fall back you can try the
    # remarked out baseurl= line instead.
    #
    #
 
    [os]
    name=Qcloud centos os - $basearch
    baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/os/$basearch/
    enabled=1
    gpgcheck=1
    gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-7
 
    [updates]
    name=Qcloud centos updates - $basearch
    baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/updates/$basearch/
    enabled=1
    gpgcheck=1
    gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-7
 
    [centosplus]
    name=Qcloud centosplus - $basearch 
    baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/centosplus/$basearch/
    enabled=0
    gpgcheck=1
    gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-7
 
    [cr]
    name=Qcloud centos cr - $basearch
    baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/cr/$basearch/
    enabled=0
    gpgcheck=1
    gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-7
 
    [extras]
    name=Qcloud centos extras - $basearch
    baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/extras/$basearch/
    enabled=1
    gpgcheck=1
    gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-7
 
    [fasttrack]
    name=Qcloud centos fasttrack - $basearch
    baseurl=http://mirrors.cloud.tencent.com/centos/$releasever/fasttrack/$basearch/
    enabled=0
    gpgcheck=1
    gpgkey=http://mirrors.cloud.tencent.com/centos/RPM-GPG-KEY-CentOS-7

# 3.清理缓存

    yum clean all
    yum makecache

# 4.安装常用工具软件

    yum install -y bash-completion epel-release net-tools