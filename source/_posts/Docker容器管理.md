---
title: Docker容器管理
categories:
  - 工作
tags:
  - Linux
  - Docker
  - 容器
  - 云计算
date: 2020-03-21 15:00:50
---

docker容器，是独立运行的一个或一组应用及其环境，是docker镜像的一个实例，核心就是该容器所执行的应用程序。可将容器当作是简易版的Linux环境，这个环境只涵盖了应用程序及其基础运行环境，如root用户权限、进程空间、用户空间和网络空间等
容器只用来运行单进程，而不是像虚拟机那样模拟一个完整的操作系统环境。实质上，容器的是设计初衷就是运行一个应用而非一台机器

docker容器运行方式分为两类，即交互式和守护式，一般都为守护式

---------

# 生命周期
  
- 检查本地是否存在指定镜像，若不存在就从公有仓库下载到本地
- 加载镜像以创建并启动容器
- 分配文件系统给容器，并在只读的镜像层外面挂载一层可读写层
- 从宿主机配置的网桥接口中桥接一个虚拟接口到容器，并从地址池分配一个地址
- 执行用户指定的应用程序
- 应用程序执行完毕后终止容器

---------

# 1.查看本地所有容器

    docker ps -a

# 2.创建容器

    # 创建交互式容器，执行完毕即被终止
    docker run -it ubuntu /bin/bash

    # 创建守护式容器，后台运行，持续提供服务
    docker run -p 80:80 -d --name nginx nginx

# 3.启停容器

    # 启动容器
    docker start nginx
    # 查看容器的端口映射
    docker port nginx
    # 重启容器
    docker restart nginx
    ## 停止容器
    docker stop nginx

# 4.进入容器后台并分配一个伪终端

    docker exec -it nginx /bin/bash

# 5.容器与宿主机之间的文件传输

## 5.1 将容器内文件复制到宿主机指定目录

    docker cp nginx:/etc/nginx/nginx.conf /root

## 5.2 将宿主机文件复制到容器指定目录

    docker cp /root/nginx.conf nginx:/etc/nginx

# 6.检查容器文件结构的更改

    docker diff nginx

# 7.查看容器中的所有进程信息，支持管道

    docker top nginx

# 8.暂停容器

## 8.1 暂停nginx容器中所有进程

    docker pause nginx

## 8.2 恢复nginx容器中所有进程

    docker upause nginx

# 9.查看docker容器事件

## 9.1 查看2020年8月1日后的所有事件

    docker events  --since="2020-08-01"

## 9.2 持续输出docker镜像为nginx:latest的相关事件，直到2020年9月1日

    docker events -f "image"="nginx:latest" --until="2020-09-01"

# 10.查看容器元数据

    docker inspect 92e5e5f86102

# 11.导出导入容器

## 11.1 将nginx容器的文件系统导出到tar归档文件

    docker export -o nginx-`date +%Y%m%d`.tar nginx

## 11.2 将nginx容器的文件系统的归档文件导入为镜像

    cat nginx-20200801.tar | docker import - nginx:v1.0.0

# 12.删除容器

    docker rm nginx