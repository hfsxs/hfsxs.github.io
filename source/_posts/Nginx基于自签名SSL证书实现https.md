---
title: Nginx基于自签名SSL证书实现https
categories:
  - 工作
tags:
  - Linux
  - Nginx
  - Http服务器
  - SSL
  - Https
  - 负载均衡
  - 云计算
date: 2020-02-01 15:10:10
---

HTTP，HyperText Transfer Protocol，即超文本传输协议，是一种用于分布式、协作式和超媒体信息系统的应用层协议。简单来说就是一种发布和接收HTML页面的方法，被用于在Web浏览器和网站服务器之间传递信息。HTTP默认工作在TCP协议80端口，通过http://打头访问的都是标准HTTP服务。HTTP协议缺陷在于以明文方式发送内容，没有提供任何方式的数据加密，若攻击者截取了Web浏览器和网站服务器之间的传输报文，就可以直接截取其中的信息。所以，HTTP协议不适合传输一些敏感信息，如信用卡号、密码、支付信息等

HTTPS，Hypertext Transfer Protocol Secure，即超文本传输安全协议，是HTTP的安全版，实质上就是在HTTP通信的基础上集成SSL/TLS以加密数据包，即HTTPS=HTTP+SSL，主要目的是提供对网站服务器的身份认证，以保护交换数据的隐私与完整性。HTTPS默认工作在TCP协议443端口，https://打头的网站都是HTTPS服务

# SSL原理

SSL/TLS协议采用公钥加密法（最著名的是RSA加密算法），具体流程为：客户端向服务器索要公钥，然后用公钥加密信息，服务器收到密文，用自己的私钥解密即可

SSL证书，即遵守SSL协议的数字证书，因部署在服务器上也称服务器SSL证书，服务器通过证书管理公钥与私钥，一般由全球信任的证书颁发机构(CA)验证服务器身份后颁发，通过证书启动SSL安全通道以实现加密传输。向权威机构申请证书需要额外的费用，也可自己制作，即自签名证书，但不受信任，客户端访问的时候会弹出告警信息，需要客户端验证通过才能继续访问

# HTTPS工作流程

## 1.客户端发起HTTPS请求

用户在浏览器里输入一个https网址，经过TCP三次同步握手后，与服务器的443端口建立TCP连接

## 2.服务端传送证书

服务端将证书发送给客户端，实质上就是公钥，包含证书颁发机构、过期时间等信息

## 3.客户端验证证书
	
客户端的TLS验证公钥是否有效，如颁发机构是否可信、是否过期等，若发现异常，则会发出证书异常的警告；若证书没有问题，将生成随机值，再用证书对其加密，形成私钥，完成双方通信的加密算法与密钥的协商

## 4.客户端传送私钥

客户端将私钥发送到服务端，此后客户端和服务端双方通信就基于此进行加密与解密

## 5.服务端加密响应数据并发送给客户端

服务端通过客户端发送的密钥与加密算法，将响应数据进行运算完成加密，以保障数据的安全性和隐私性，最后发送给客户端

## 6.客户端解密信息

客户端依据之前的加密算法与密钥解密响应数据，渲染成网页呈现给用户

---------

# 1.编译安装http_ssl_module模块

--with-http_ssl_module

# 2.创建证书

    mkdir /etc/nginx/ssl
    cd /etc/pki/tls/certs

## 2.1 创建RSA密钥

    openssl genrsa -des3 -out nginx.key 2048

## 2.2 创建CSR，即证书签名请求文件

    openssl req -new -key nginx.key \
    -subj "/C=CN/ST=HeNan/L=ShangQiu/O=Sword/OU=Opt/CN=registry.sword.org" \
    -out nginx.csr

## 2.3 生成自签名证书

    openssl x509 -req -days 3650 -in nginx.csr -signkey nginx.key -out nginx.crt

## 2.4 退掉密码

    mv nginx.key nginx.bak.key
    openssl rsa -in nginx.bak.key -out nginx.key

# 3.配置SSL证书

    vi /etc/nginx/nginx.conf


    server {

      listen       80;
      server_name  localhost;

      location / {
        root   html;
        index  index.html index.htm;
      }

      # 配置http自动跳转https，实现全站加密
      # rewrite ^(.*) https://$host$1 permanent;
    }

    server {

      listen       443 ssl;
      server_name  localhost;
      root         /web;

      ssl on;
      ssl_certificate      /etc/nginx/ssl/nginx.crt;
      ssl_certificate_key  /etc/nginx/ssl/nginx.key;

      ssl_session_cache    shared:SSL:1m;
      ssl_session_timeout  5m;

      ssl_ciphers  ECDHE-RSA-AES128-GCM-SHA256:HIGH:!aNULL:!MD5:!RC4:!DHE;
      ssl_prefer_server_ciphers  on;
      ssl_protocols TLSv1 TLSv1.1 TLSv1.2;
}

# 4.测试https访问

https://ip

---------

# 参考文档

- https://www.cnblogs.com/lan1x/p/5872915.html