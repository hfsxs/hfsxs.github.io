---
title: Docker镜像管理
categories:
  - 工作
tags:
  - Linux
  - Docker
  - 容器
  - 云计算
date: 2020-03-30 20:24:26
---

docker镜像，可理解为Linux的文件系统（Root FileSystem），这个文件系统包含可以运行在Linux内核的程序及相应的数据。镜像类似于虚拟机的模版，容器则类似于由镜像创建的虚拟机

---------

# 镜像分层

- Layer，即分层，镜像由一系列层（layers）组成，这些层都有独立的文件系统（包括文件和文件夹，称之为分支）。docker的UnionFS，即联合文件系统将这些层联合，从而形成一个单独连贯的文件系统，即为镜像。正是由于这个分层的特性，docker才会如此轻量。升级应用程序不用像虚拟机那样重新构建发布整个镜像，只需新增一层即可，这样就使得镜像的构建十分简单与快速。例如，centos镜像中安装nginx就构建了nginx镜像。此时，nginx镜像的底层是centos操作系统镜像，其上叠加一个ngnx层镜像，底层的centos镜像就被称为nginx镜像层的父镜像

- read-only，即只读，镜像在构建完成之后便不可以再修改，而上面所说的添加一层构建新的镜像，实际是通过创建一个临时的容器，并在容器上增加或删除一些文件而形成的新镜像，所以说容器支持动态改变。当运行容器时，若使用的镜像在本地中不存在，docker就会自动从docker镜像仓库中下载，默认是从Docker Hub公共镜像源下载镜像。当公共仓库的镜像不能满足需求时，可以本地自定义构建镜像

---------

# 1.镜像操作

## 1.1 查看本地镜像

    docker images

## 1.2 官方公共镜像仓库中搜索nginx镜像

    docker search nginx

## 1.3 官方公共镜像仓库拉取nginx镜像到本地

    docker pull nginx

## 1.4 更改镜像的tag，即标签

    docker tag nginx:latest nginx:v1.0.0

## 1.5 查看镜像元数据

    docker inspect nginx:v1.0.0

## 1.6 删除镜像

    docker rmi nginx

# 2.镜像构建

## 2.1 修改本地镜像构建新镜像

### 2.1.1 创建容器

    docker run --name nginx -p 80:80 -d nginx

### 2.1.2 容器配置Java环境

    docker exec -it nginx /bin/sh
    yum -y install java-1.8.0-openjdk java-1.8.0-openjdk-devel
    exit

### 2.1.3 提交容器的修改操作，将之打包为镜像，-m，描述信息；-a，镜像维护者

    docker commit -m="jdk1.8" -a="admin@sword.com" 2b4e18c57e01 nginx:java

### 2.1.4 查看镜像构建历史

    docker history nginx:java

### 2.1.5 导出镜像

    docker save -o docker_nginx.tar.gz nginx:java

### 2.1.6 镜像包发送到其他服务器导入镜像

    docker load -i docker_nginx.tar.gz

# 2.2 dockfile构建新镜像

Dockfile，由Docker程序解释的包含一系列指令和说明的脚本，其每一条指令都会在镜像上创建一个新层，逐层累积即构建起来完整的镜像

Dockerfile的指令忽略大小写，一般是大写，每行只支持一条指令，每条指令可以携带多个参数。指令分为两种，即构建指令和设置指令，前者用于构建镜像而不会在容器上执行，后者用于设置镜像的属性，将在容器中进行执行

Dockerfile分为四部分，即基础镜像信息、维护者信息、镜像操作指令和容器启动指令

### 2.2.1 创建Dockerfile文件

    vi Dockerfile


    # 底层镜像
    FROM alpine
    # 镜像维护者
    LABEL MAINTAINER admin@sword.com

    RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
    && apk update && apk add -U tzdata nginx && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
    && echo "Asia/shanghai" >> /etc/timezone && rm -rf  /tmp/* /var/cache/apk/* && apk del tzdata

    # 镜像操作指令
    ADD nginx.conf /etc/nginx

    # 容器对外暴露的端口
    EXPOSE 80 443
    # 环境变量
    ENV LANG C.UTF-8
    # 容器启动指令
    CMD ["/usr/sbin/nginx", "-g", "daemon off;"]

### 2.2.2 构建镜像；-t,指定镜像标签

    docker build -t nginx:v1.0.0 .

### 2.2.3 查看镜像

    docker images

---------

- 构建tomcat镜像

      FROM alpine
      LABEL MAINTAINER admin@sword.com

      ADD apache-tomcat-8.0.1.tar.gz /usr/local 

      RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
      && apk update && apk add -U tzdata openjdk8 && mv /usr/local/apache-tomcat-8.0.1 /usr/local/tomcat \
      && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime && echo "Asia/shanghai" >> /etc/timezone \
      && rm -rf /tmp/* /var/cache/apk/* && apk del tzdata

      EXPOSE 8080
      ENV LANG C.UTF-8
      CMD ["/usr/local/tomcat/bin/catalina.sh","run"]

- 构建redis镜像

      FROM alpine
      LABEL MAINTAINER admin@sword.com

      RUN sed -i 's/dl-cdn.alpinelinux.org/mirrors.tuna.tsinghua.edu.cn/g' /etc/apk/repositories \
      && apk update && apk add -U tzdata redis && cp /usr/share/zoneinfo/Asia/Shanghai /etc/localtime \
      && mkdir /etc/redis && mv /etc/redis.conf /etc/redis && echo "Asia/shanghai" >> /etc/timezone \
      && rm -rf /tmp/* /var/cache/apk/* && apk del tzdata

      EXPOSE 6379
      ENV LANG C.UTF-8
      ENTRYPOINT /usr/bin/redis-server /etc/redis/redis.conf