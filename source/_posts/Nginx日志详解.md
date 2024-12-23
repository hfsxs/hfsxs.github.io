---
title: Nginx日志详解
categories:
  - 工作
tags:
  - Linux
  - Nginx
  - Http服务器
  - 日志分析
  - 负载均衡
  - 云计算
date: 2020-02-01 15:24:41
---

nginx日志分为两种，即访问日志和错误日志

# 1.访问日志

访问日志，access_log，用于记录客户端的请求，如客户端IP地址、浏览器信息、请求信息等等，对于统计分析作用巨大

## 1.1 格式设置

访问日志由log_format指令定义，用于自定义日志格式，如存放路径、类型、缓存大小等，默认参数格式为：

    ‘$remote_addr – $remote_user [$time_local] “$request” ‘
    ‘$status $body_bytes_sent “$http_referer” ‘
    ‘”$http_user_agent” “$http_x_forwarded_for”‘;

---------

设置参数：

- $remote_addr，http客户端的IP地址，如 112.10.24.36
- $remote_user，http客户端用户名称，一般为空
- $time_local，http客户端访问时间和时区，如 03/Jan/2020:17:15:35 +0800
- $request，http请求的URI和HTTP协议，如 "GET /jpress/static/components/layer/theme/jpress/style.css HTTP/1.1"
- $status，http请求的响应状态码，如200、404
- $bytes_sent，nginx返回给客户端数据的字节数，即响应报文，包括响应头和响应体
- $body_bytes_sent，nginx返回给客户端数据的响应体的字节数，不包含响应头
- $http_referer，url跳转来源，如 https://49.232.97.179/jpress/admin
- $http_user_agent，客户端浏览器等信息，如"Mozilla/5.0 (Macintosh; Intel Mac OS X 10_13_6) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/79.0.3945.88 Safari/537.36"
- $http_x_forwarded_for，web服务器记录的客户端地址，适用于前端有代理服务器，且代理服务器http_x_forwarded_for也需配置
- $ssl_protocol，nginx SSL协议版本，如TLSv1
- $ssl_cipher，nginx SSL交换数据中的算法，如RC4-SHA
- $upstream_addr，后端web服务器地址，即真正提供服务的主机地址，如 172.21.0.7:8088
- $upstream_status，后端web服务器的响应状态码，如200、500
- $request_time，nginx完成本次请求的时长，包括接收http请求时间、后端web服务器响应时间、将响应数据传给客户端的时间
- $upstream_response_time，后端服务器的响应时长，包括nginx与后端web服务器建立连接的时间、nginx接收响应数据的时间、关闭连接的时间
- $request_length，http客户端请求报文的字节数，包括请求行、请求头和请求体。其值在请求解析过程中不断累加，若解析请求时出现异常或提前完成，则$request_length只是已经累加部分的长度，而不是nginx从客户端收到的完整请求的总字节数
- $http_host，http客户端的请求地址，即浏览器输入的地址（IP或域名），如 49.232.97.179
- $connection              TCP连接的序列号
- $connection_requests     TCP连接当前的请求数量
- $content_length          "Content-Length" 请求头字段
- $content_type            "Content-Type" 请求头字段
- $cookie_name             cookie名称
- $nginx_version           nginx版本
- $proxy_protocol_addr     获取代理访问服务器的客户端地址，如果是直接访问，该值为空字符串
- $remote_port             客户端端口
- $scheme                  请求使用的Web协议，"http" 或 "https"
- $server_addr             服务器端地址，需要注意的是：为了避免访问linux系统内核，应将ip地址提前设置在配置文件中
- $server_name             服务器名
- $server_port             服务器端口
- $server_protocol         服务器的HTTP版本，通常为 "HTTP/1.0" 或 "HTTP/1.1"
- $cookie_NAME             客户端请求Header头中的cookie变量，前缀"$cookie_"加上cookie名称的变量，该变量的值即为cookie名称的值
- $http_NAME               匹配任意请求头字段；变量名中的后半部分NAME可以替换成任意请求头字段，如在配置文件中需要获取http请求头："Accept-Language",使用$http_accept_language即可
- $sent_http_NAME          可以设置任意http响应头字段；变量名中的后半部分NAME可以替换成任意响应头字段，如需要设置响应头Content-length，$sent_http_content_length即可
- $sent_http_cache_control
- $sent_http_connection
- $sent_http_content_type
- $sent_http_keep_alive
- $sent_http_last_modified
- $sent_http_location
- $sent_http_transfer_encoding


    log_format  main '$remote_addr - $remote_user [$time_local] "$request" '
                     '$status $bytes_sent $body_bytes_sent "$http_referer" '
                     '"$http_user_agent" "$http_x_forwarded_for" '
                     '"$request_time" "$upstream_response_time" "$upstream_status" "$upstream_addr" $http_host';


## 1.2 nginx访问日志分析

分析、统计网站的流量数据是非常重要的工作，可以了解网站当前的访问效果和访问用户行为并发现当前网络营销活动中存在的问题，并为进一步修正或重新制定网络营销策略提供依据。nginx通常作为业务系统的前端入口，其访问日志就包含了大量的值得分析的数据指标

### 1.2.1 常用网站流量指标

#### 网站并发连接数

网站服务器单位时间内能够处理的最大连接数，如某网站的并发为5000，则意味着单位时间内（1秒或数秒）正在
处理的连接数与正在建立的连接数之和

#### IP

即客户端IP地址，一般指独立IP数，即不同IP地址的计算机访问网站的总次数，一般24小时内（00:00-24:00）相同IP地址只被计入一次

#### PV

Page View，即页面浏览量或点击量，无论IP、浏览器、网站页面是否相同，只要访问一次网站页面就会被计入一次PV

#### UV

Unique Visitor，同一客户端（PC或移动端）访问网站被计为一个访客，24小时内（00:00-24:00）相同的客户端访问同一个网站只统计一次UV。UV一般是以客户端Cookie等技术作为统计依据，实际统计会有误差

### 1.2.2 常用分析命令

#### 总请求数

    wc -l  access.log |awk '{print $1}'

#### 独立IP数

    awk '{print $1}' access.log|sort |uniq |wc -l

#### 每秒客户端请求数 TOP5

    awk '{print $6}' access.log|sort|uniq -c|sort -rn|head -5

#### 访问最频繁IP Top5

    awk '{print $1}' access.log|sort |uniq -c |sort -nr |head -5

#### 访问最频繁的URL TOP5

    awk '{print $7}' access.log|sort |uniq -c |sort -nr |head -5

#### 响应大于5秒的URL TOP5

    awk '{if ($7 > 5){print $6}}' access.log|sort|uniq -c|sort -rn |head -5

#### HTTP状态码(非200)统计 Top5

    awk '{if ($11 != 200){print $11}}' access.log|sort|uniq -c|sort -rn|head -5

#### 请求数大于50000的源IP

    cat access.log|awk '{print $NF}'|sort |uniq -c |sort -nr|awk '{if ($1 >50000){print $2}}'

# 2.错误日志

错误日志，error_log，用于记录服务器和请求处理过程中的错误信息，对于错误原因定位意义重大。错误日志格式由error_log指令定义，不支持自定义，只能定义错误日志记录的等级及其存储路径，等级分为debug、info、notice、warn、error、crit几种，日志详细程度逐级递减，默认级别为error