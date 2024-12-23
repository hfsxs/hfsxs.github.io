---
title: PHP工作模式详解
categories:
  - 工作
tags:
  - Linux
  - PHP
  - 云计算
date: 2020-02-02 10:02:35
---

PHP有三种工作模式，即CLI模式、Module模式和PHP-FPM模式

---------

# 1.CLI模式

CLI，Command Line Interface，即命令行接口，默认安装，通过此接口可在shell环境与PHP交互，就像使用shell、Python一样，不依赖于WEB服务器。如Laravel框架的Artisan命令行工具，其实就是一个PHP脚本，用于快速构建Laravel应用

# 2.Module模式

此模式即是将PHP以模块的形式集成到Apace服务器供Apache加载调用，模块名为php5_module，接收PHP请求并进行处理，然后将处理结果返回给Apache。LAMP组合的PHP即是工作于此模式，但随着Nginx的异军突起，已不再是PHP开发者的第一选择，逐渐被LNMP组合所代替

## 2.1 编译安装PHP

    ./configure --prefix=/usr/local/php --with-config-file-path=/etc --with-apxs2=/usr/local/httpd/bin/apxs \
    --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --with-openssl --with-pcre --enable-inline-optimization 
    make && make install

## 2.2 配置Apache加载PHP模块

    vi /etc/httpd/conf/httpd.conf


    # 设置启用mod_php5模块
    LoadModule php5_module modules/libphp5.so

    # 设置服务器解析PHP文件
    <FilesMatch \.php$>
      SetHandler application/x-httpd-php
    </FilesMatch>

# 3. PHP-FPM模式

PHP-FPM，PHP FastCGI Process Manager，即PHP FastCGI进程管理器，是PHP对FastCGI（Fast Common Gateway Interface，快速通用网关接口）通信协议的具体实现，用于PHP脚本与WEB服务器之间的通信，致力于减少网页服务器与CGI程序之间交互的开销，从而使WEB服务器得以支持高更的并发量

PHP-FPM负责管理维护一个进程池，用来处理来自WEB服务器的HTTP动态请求。其中，master主进程负责与web服务器进行通信，接收HTTP请求，再将请求转发给worker进程进行处理；worker进程主要负责动态执行PHP代码，处理完成后，将处理结果返回给web服务器，再由web服务器将结果发送给客户端

PHP-FPM监听方式有两种，即TCP socket(IP和port)，监听端口为9000；Unix Domain Socket（UDS)，需指明socket位置

## 3.1 编译安装PHP

    ./configure --prefix=/usr/local/php --with-config-file-path=/etc --enable-fpm --with-fpm-user=fpm --with-fpm-group=fpm \
    --with-mysqli=mysqlnd --with-pdo-mysql=mysqlnd --enable-opcache --with-openssl --with-pcre --enable-inline-optimization 
    make && make install

## 3.2 配置php-fpm服务

    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
    cp php.ini-production /etc/php.ini
    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm

## 3.1 配置Apache对PHP-FPM的支持

    vi /etc/httpd/conf/httpd.conf


    # 设置启用代理模块
    LoadModule proxy_module modules/mod_proxy.so
    # 设置启用fcgi代理模块
    LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so

    # 设置启用tcp socket监听方式
    <FilesMatch \.php$>
      SetHandler "proxy:fcgi://127.0.0.1:9000"
    </FilesMatch>

    # 设置启用Unix Domain Socket监听方式
    # <Proxy "unix:/dev/shm/php-fpm.sock|fcgi://php-fpm">
      # ProxySet disablereuse=off
    # </Proxy>

## 3.2 配置Nginx对PHP-FPM的支持

    vi /etc/nginx/nginx.conf


    server {

        listen       80;
        server_name  localhost;

        #charset koi8-r;

        #access_log  logs/host.access.log  main;

        location / {
            root   html;
            index  index.html index.htm;
        }

        #error_page  404              /404.html;

        # redirect server error pages to the static page /50x.html
        #
        error_page   500 502 503 504  /50x.html;
        location = /50x.html {
            root   html;
        }

        # proxy the PHP scripts to Apache listening on 127.0.0.1:80
      
        #location ~ \.php$ {
        #    proxy_pass   http://127.0.0.1;
        #}

        # pass the PHP scripts to FastCGI server listening on 127.0.0.1:9000
        
        location ~ \.php$ {
            root           html;
            fastcgi_pass   127.0.0.1:9000;
            fastcgi_index  index.php;
            fastcgi_param  SCRIPT_FILENAME  /scripts$fastcgi_script_name;
            include        fastcgi_params;
        }
    }