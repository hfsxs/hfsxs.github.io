---
title: Nginx配置Tomcat动静分离负载均衡集群
categories:
  - 工作
tags:
  - Linux
  - Nginx
  - Http服务器
  - Tomcat
  - 负载均衡
  - 云计算
date: 2020-02-01 14:20:48
---

# 集群架构

- 172.16.100.100  node01  nginx tomcat
- 172.16.100.120  node02  tomcat
- 172.16.100.200  node03  tomcat

---------

# 1.安装nginx、tomcat

# 2.创建nginx配置文件

    vi /etc/nginx/conf.d/tomcat.conf


    # 配置负载均衡集群
    upstream tomcat-servers {

      # 设置后端服务器组
      server 172.16.100.120:8080 weight=2 max_fails=2 fail_timeout=30s;
      server 172.16.100.200:8080 weight=2 max_fails=2 fail_timeout=30s;
      # 设置备用服务器，即所有非备用服务器down或忙时再承担负载
      server 172.16.100.100:8080 weight=2 max_fails=2 fail_timeout=30s;
      # 设置不承担负载的服务器
      # server 172.16.100.100:8080 weight=2 max_fails=2 fail_timeout=30s;
    }

    server {

      listen       80;
      server_name  localhost;
      charset utf-8;

      location / {

        proxy_pass http://tomcat-servers;

        access_log  /var/log/nginx/tomcat_access.log  main;
        error_log  /var/log/nginx/tomcat_error.log;
      }

      # 配置动静分离
      location ~ \.(jsp|jspx|do)$ {
      proxy_pass http://tomcat-servers;
      }

    }

# 3.tomcat节点配置测试页面

    vi /usr/local/tomcat/webapps/ROOT/test.jsp


    node01

---------

- 注：其余两个节点的测试页面名称相同，内容分别为node02、node03

# 4.启动tomcat、nginx，验证集群功能

http://172.16.100.100/test.jsp