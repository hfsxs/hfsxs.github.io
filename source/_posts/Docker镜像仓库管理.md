---
title: Docker镜像仓库管理
categories:
  - 工作
tags:
  - Linux
  - Docker
  - 容器
  - 云计算
date: 2020-04-03 23:15:31
---

docker Repository，即镜像仓库，用于镜像的集中存放与管理。一般的，仓库和仓库注册服务器（Registry）不做区分。实际上，仓库注册服务器是管理仓库的具体服务器，其中往往存放着多个仓库，每个仓库中又包含了多个镜像，每个镜像有不同的标签（tag）仓库可以被认为是一个具体的项目或目录，如仓库地址hub.docker/nginx，hub.docker是注册服务器地址，nginx是仓库名

---------

# 仓库分类

- 公共仓库，即Public Registry，最大的公共仓库是Docker Hub，由docker官方维护，存放了数量庞大的镜像供用户下载，通过docker login命令，输入用户名、密码和邮箱来完成注册和登录，本地用户目录的.dockercfg中将保存用户的认证信息

- 私有仓库，即Private Registry，是本地服务器所建的镜像仓库。私有仓库的创建有两种方式，即docker-registry和harbor，前者是官方提供的工具，安装了docker之后直接pull即可；后者是开源工具，Github可下载

# registry搭建私有仓库

## 1.拉取官方镜像

    docker pull registry

## 2.创建并启动registry容器

    docker run -p 5000:5000 -d --restart=always \
    -v /var/lib/docker/images:/var/lib/registry \
    --name sword-registry registry

## 3.http方式测试镜像仓库

### 3.1 配置docker镜像仓库拉取策略
 
    sudo vi /etc/docker/daemon.json


    {
     "insecure-registries":["172.16.100.100:5000"]
    }

    # 重启docker程序
    systemctl restart docker

### 3.2 镜像推送私有仓库

    # 更改nginx镜像标签
    docker tag nginx:latest 172.16.100.100:5000/nginx:v1.0.0
    # 推送到私有仓库
    docker push 172.16.100.100:5000/nginx:v1.0.0

### 3.3 查看私有仓库存放的镜像

    # 显示所有镜像
    curl http://172.16.100.100:5000/v2/_catalog
    # 显示nginx镜像的标签
    curl http://172.16.100.100:5000/v2/nginx/tags/list

### 3.4 从私有仓库拉取镜像

    # 删除本地nginx镜像
    docker rmi 172.16.100.100:5000/nginx:v1.0.0
    # 从私有仓库拉取nginx镜像
    docker pull 172.16.100.100:5000/nginx

---------

- 注：docker连接仓库默认通过安全的https协议连接，http连接用于测试场景

## 4.创建SSL自签名证书

### 4.1 创建RSA密钥

    openssl genrsa -des3 -out registry.key 2048

### 4.2 创建CSR，即证书签名请求文件

    openssl req -new -key registry.key \
    -subj "/C=CN/ST=HeNan/L=ShangQiu/O=Sword/OU=Opt/CN=registry.sword.org" \
    -out registry.csr

### 4.3 生成自签名证书

    openssl x509 -req -days 3650 -in registry.csr -signkey registry.key -out registry.crt

    # 退掉密码
    mv registry.key registry.bak.key
    openssl rsa -in registry.bak.key -out registry.key

## 5.配置nginx反向代理

    sudo vi /etc/nginx/conf.d/registry.conf


    server {

        listen       443 ssl;
        server_name  localhost;

        charset utf-8;

        ssl_certificate      /etc/nginx/ssl/registry.crt;
        ssl_certificate_key  /etc/nginx/ssl/registry.key;

        ssl_session_cache    shared:SSL:1m;
        ssl_session_timeout  5m;

        ssl_ciphers  ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
        ssl_prefer_server_ciphers  on;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2;

        location / {

            # auth_basic "Nginx Server Auth";
            # auth_basic_user_file /etc/nginx/conf.d/.auth_list;
            # limit_rate   1024k;

            access_log  /var/log/nginx/registry_access.log  main;
            error_log  /var/log/nginx/registry_error.log;

            proxy_pass http://127.0.0.1:5000;

            }
    }

## 6.操作系统信任SSL证书

    # Debian/Ubuntu
    sudo cp /etc/nginx/ssl/registry.crt /etc/ssl/certs
    # CentOS
    sudo cp /etc/nginx/ssl/registry.crt /etc/pki/tls/certs

## 7.启动nginx，重启docker

## 8.验证镜像仓库

    sudo docker tag nginx registry.sword.org/nginx
    sudo docker push registry.sword.org/nginx

## 9.nginx配置auth_basic，实现镜像仓库访问认证

---------

# harbor搭建私有仓库

## 1.配置仓库域名解析

    vi /etc/hosts


    172.16.100.100	hub.sword.com

## 2.部署docker-compose

    # 下载docker-compose
    curl -L https://github.com/docker/compose/releases/download/1.25.0/docker-compose-`uname -s`-`uname -m` -o /usr/local/bin/docker-compose

    chmod +x /usr/local/bin/docker-compose
    ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose

## 3.创建https证书

    mkdir -p /var/lib/docker/images/certs
    cd /var/lib/docker/images/certs

### 3.1 生成私钥，需设置密码
    
    openssl genrsa -des3 -out harbor.key 4096

### 3.2 生成CA证书，需输入密码

    openssl req -sha512 -new \
    -subj "/C=CN/ST=HeNan/L=ShangQiu/O=sword/OU=opt/CN=hub.sword.com" \
    -key harbor.key \
    -out harbor.csr

### 3.3 备份证书

    cp harbor.key harbor.key.org

### 3.4 退掉私钥密码以便docker访问，也可参考官方的双向认证

    openssl rsa -in harbor.key.org -out harbor.key

### 3.5 使用证书进行签名

    openssl x509 -req -days 365 -in harbor.csr -signkey harbor.key -out harbor.crt

## 4.将https证书发送给连接仓库的docker

    mkdir -p /etc/docker/certs.d/hub.sword.com
    cp /var/lib/docker/images/certs/harbor.crt /etc/docker/certs.d/hub.sword.com

## 5.安装harbor

    tar -xzvf harbor-offline-installer-v2.0.0.tgz
    cd harbor && cp harbor.yml.tmpl harbor.yml

### 5.1 创建配置文件

    vi harbor.yml



    # 设置仓库域名，与证书域名一致
    hostname: hub.sword.com
    # 设置证书路径
    certificate: /var/lib/docker/images/certs/harbor.crt
    private_key: /var/lib/docker/images/certs/harbor.key
    # 设置仓库登录密码，用户名默认为admin
    harbor_admin_password: Harbor12345
    # 设置镜像挂载目录
    data_volume: /var/lib/docker/images
    # 设置harbor仓库日志目录
    location: /var/log/harbor

### 5.2 安装harbor

    ./install.sh

## 6.镜像的推送与拉取

    # 登录仓库
    docker login hub.sword.com
    # 设置镜像标签，带上项目名称
    docker tag nginx hub.sword.com/library/nginx
    docker push hub.sword.com/library/nginx
    docker pull hub.sword.com/library/nginx

## 7.harbor的启动与停止

    # 启动harbor
    docker-compose up -d

    # 停止harbor
    docker-compose down

## 8.访问镜像仓库

https://hub.sword.com

---------

# 参考文档

- https://www.cnblogs.com/zhuzi91/p/12364200.html
- https://blog.csdn.net/zfw_666666/article/details/128918101
- https://blog.csdn.net/u013276277/article/details/102994771