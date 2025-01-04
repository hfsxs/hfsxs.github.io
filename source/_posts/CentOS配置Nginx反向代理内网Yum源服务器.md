---
title: CentOS配置Nginx反向代理内网Yum源服务器
categories:
  - 工作
tags:
  - Linux
  - CentOS
  - Yum
  - 云计算
date: 2021-03-01 19:39:06
---

# 1.yum源服务器配置本地源

## 1.1 挂载ISO镜像文件

    sudo mkdir -p /mnt/cdrom
    sudo mount -o loop -t iso9660 /home/kvm/images/CentOS-7-x86_64-Minimal-2009.iso /mnt/cdrom

## 1.2 创建yum源配置文件

    sudo mkdir -p /etc/yum.repos.d/bak
    sudo mv /etc/yum.repos.d/*.repo /etc/yum.repos.d/bak
    sudo vi /etc/yum.repos.d/CentOS-Media.repo


    [c7-media]
    name=CentOS-$releasever - Media
    baseurl=file:///mnt/cdrom
    gpgcheck=1
    enabled=1
    gpgkey=file:///etc/pki/rpm-gpg/RPM-GPG-KEY-CentOS-7

## 1.3 清除缓存及旧包

    sudo yum clean all && sudo yum makecache

## 1.4 测试本地yum源

    sudo yum list

# 2.yum源服务器安装nginx

    sudo vi /etc/nginx/conf.d/yum.conf


    server {

      listen       80;
      server_name  172.16.100.100;
      
      access_log  /var/log/nginx/yum_access.log  main;
      error_log  /var/log/nginx/yum_error.log;

      location / {

        root		/mnt/cdrom;
        autoindex	on;
        index		index.html index.htm;

      }
}

# 3.集群其余服务器配置yum源

## 3.1 创建yum源配置文件

    sudo mkdir /etc/yum.repos.d/bak && sudo mv *.repo bak
    sudo vi /etc/yum.repos.d/CentOS-Nginx.repo


    [c7-media]
    name=CentOS-$releasever - Media
    baseurl=http://172.16.100.100
    gpgcheck=1
    enabled=1
    gpgkey=fhttp://172.16.100.100/RPM-GPG-KEY-CentOS-7

## 3.2 清除缓存及旧包

    sudo yum clean all
    sudo yum makecache

## 3.3 测试yum源服务器

    sudo yum list