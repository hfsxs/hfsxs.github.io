---
title: Docsify搭建个人Wiki知识库
categories:
  - 极客
tags:
  - Linux
  - Docsify
  - Nodejs
  - Wiki
  - 极客
date: 2022-02-15 20:32:16
---

Docsify，动态生成文档网站的工具，可将.md文件以Wiki的形式展示，用于制作技术文档、用户手册、wiki等，部署于主机、VPS、Github、静态云存储，特别适于快速搭建小型的文档网站

---------

# 1.配置nodejs环境

    wget https://nodejs.org/dist/latest/node-v18.8.0-linux-x64.tar.gz
    tar -xzvf node-v18.8.0-linux-x64.tar.gz && mv node-v18.8.0 /usr/local/nodejs
    sudo ln -s /usr/local/nodejs/bin/node /usr/bin/node
    sudo ln -s /usr/local/nodejs/bin/npm /usr/bin/npm

# 2.设置npm网络代理

    sudo npm config set registry https://registry.npmmirror.com

# 3.安装docsify

    sudo npm install -g docsify-cli

# 4.初始化项目

    sudo /usr/local/nodejs/bin/docsify init /web/wiki

# 5.配置nginx代理

    sudo vi /etc/nginx/nginx.d/wiki.conf
        
        
    server {
    
      listen       80;
      server_name  localhost;
    
      charset	utf-8;
    
      location /wiki {
    
        root  /web;
        autoindex on;
        index index.html index.htm;
        try_files $uri $uri/ /index.html;
        # 设置资源不缓存,整个资源库完整后再缓存防止新配置不生效
        add_header Cache-Control "no-cache, no-store";
    
        access_log  /var/log/nginx/wiki_access.log  main;
        error_log  /var/log/nginx/wiki_error.log;
    
        }
    }
    
# 6.访问wiki

http://ip

---------

# 参考文档

- https://docsify.js.org/#/zh-cn
- https://blog.csdn.net/qq_62982856/article/details/129940209