---
title: Nginx配置身份认证
categories:
  - 工作
tags:
  - Linux
  - Nginx
  - Http服务器
  - 负载均衡
  - 云计算
date: 2020-02-01 15:02:01
---

nginx的ngx_http_auth_basic_module模块允许使用HTTP基本身份验证，即通过用户名及其密码限制资源的访问

# 1.安装htpasswd

    yum install -y httpd-tools

# 2.添加认证用户

    # 创建认证文件，新增认证用户admin，并设置密码
    htpasswd -c /etc/nginx/.auth_list admin 123456

    # 新增认证用户sword，并设置密码
    htpasswd /etc/nginx/.auth_list sword 123456

# 3.配置nginx服务器的用户认证

    vi /etc/nginx/nginx.conf


    server {
      listen       80;
      server_name  localhost;

      # 设置访问认证提示
      auth_basic "Server Auth";
      # 设置认证文件
      auth_basic_user_file /etc/nginx/.auth_list;

      location / {
        root   html;
        index  index.html;
      }
    }

# 4.启动nginx，验证用户认证

http://ip