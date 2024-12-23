---
title: Jellyfin搭建私人家庭影音娱乐中心
categories:
  - 极客
tags:
  - Linux
  - Jellyfin
  - 影音娱乐
  - 极客
date: 2022-10-15 10:31:56
---

Jellyfin，跨平台的开源免费的媒体管理系统，用于控制和管理媒体、流媒体文件，通过多个应用程序从专用服务器向终端用户设备提供媒体，配合TTM刮削器可实现华丽的家庭私人影院。Jellyfin分为服务端和客户端应用程序，服务端安装运行于Microsoft Windows、MacOS、Linux、NAS等系统的服务器，客户端可安装在智能手机、平板电脑、智能电视、网络机顶盒、电子游戏机或网页浏览器

---------

![jellyfin](/img/wiki/jellyfin/jellyfin.jpg)

---------

# 1.容器化部署

## 1.1 安装Docker，拉取镜像

    sudo docker pull nyanmisaka/jellyfin

## 1.2 创建Jellyfin容器

    sudo docker run -d -it -p 8096:8096 --restart=always \
    -v /web/jellyfin/config:/config -v /web/jellyfin/cache:/cache \
    -v /home:/media --name jellyfin jellyfin

# 2.服务器部署

## 2.1 安装Jellyfin

    curl -s https://repo.jellyfin.org/install-debuntu.sh | sudo bash

## 2.2 启动Jellyfin

    sudo systemctl start jellyfin.service
    sudo systemctl enable jellyfin.service  

# 3.配置Nginx反向代理

    server {

      listen       80;
      server_name  localhost;

      location / {

      access_log  /var/log/nginx/jellyfin_access.log  main;
      error_log  /var/log/nginx/jellyfin_error.log;

      }
    }

# 4.登陆Jellyfin

http://ip

# 5.添加媒体库

---------

# 参考文档

- https://jellyfin.org/docs/
- https://post.smzdm.com/p/ao97n5wn
- https://post.smzdm.com/p/a4x2nenw