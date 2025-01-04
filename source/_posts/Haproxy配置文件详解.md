---
title: Haproxy配置文件详解
categories:
  - 工作
tags:
  - Linux
  - Haproxy
  - 集群
  - 负载均衡
  - 云计算
date: 2020-02-05 12:12:16
---

    # 进程级全局配置，系统相关
    global
      # 设置全局日志的设备级别
      log    127.0.0.1 local2
      # 设置haproxy运行路径
      chroot    /usr/local/haproxy
      # 设置pid文件路径
      pidfile    /var/run/haproxy.pid
      # 设置进程运行用户
      user    sword
      # 设置运行进程用户所属组
      group    sword
      # 设置haproxy服务为后台运行
      daemon
      # 设置haproxy进程数，默认为1，建议设为CPU核心数
      nbproc    2
      # 设置每个进程最大连接数，决定了前端frontend总的连接数
      maxconn    1024
      # 设置当前节点名称，用于HA集群中多个haproxy节点共享同一IP
      node    haproxy001
      # 设置统计数据接口    
      stats socket    /var/lib/haproxy/stats

    # 默认全局设置，可被frontend，backend，listen等组件引用
    defaults

      # 设置全局日志配置的引用
      log    global
      # 设置实运行模式，tcp为4层，用于SSL、SSH、SMTP等应用；http为7层，默认模式；health，已废弃
      mode    http
      # 设置日志类别，记录http请求、session信息
      option    httplog
      # 设置每次请求完毕后自动关闭http通道
      option    httpclose
      # 设置获取客户端真实IP，即后端服务器从Http Header中获得客户端IP 
      option    forwardfor except 127.0.0.0/8              
      # 设置日志不记录空连接，可剔除健康检查日志，用于上游服务器存在负载均衡器场景
      #option    dontlognull
      # 设置后端服务器挂掉强制转向其他健康的服务器
      option    redispatch
      # 设置服务器负载高时自动结束当前队列处理较久的连接
      option    abortonclose
      # 设置连接重用策略，默认为never，表示禁用
      http-reuse    safe
      # 设置后端服务器最大重试次数
      retries    3

      # 设置客户端保持连接的超时时长，高并发场景建议设置为较小值以尽快释放
      timeout client    10s
      # 设置客户端发送完整请求的最大时长，由于haproxy机制是每次请求或响应全部发送完成再进行转发，为防止洪水攻击建议设为较小值
      timeout http-request    2s
      # 设置客户端保持长连接的时长，优先级> timeout http-request > timeout client，适用于后端为静态web或静态缓存服务器
      # timeout http-keep-alive 10s
      # 设置客户请求在等待队列的超时时长
      timeout queue    10s
      # 设置后端服务器连接超时时长
      timeout connect    1s
      # 设置后端服务器健康检测超时时长
      timeout check    2s
      # 设置后端服务器连接的保持时长，高并发场景建议设置为较小值
      timeout server    3s

      # 设置负载均衡算法，roundrobin，动态权重轮询，默认算法，权重运行时可调整，每个后端服务器最大连接数4128；static-rr，静态权重轮询，权重值运行时调整不生效，后端服务器连接数不限；leastconn，最少连接数，适用于长连接的会话，LDAP、SQL、FTP等，不适合HTTP协议；source，根据请求源IP进行hash运算，将同一IP请求送往同一服务器,实现会话保持功能；first，根据服务器在列表中的位置自上而下进行调度，即前面服务器的连接数达到上限或不可用，新请求才会分配给下一服务；uri，根据请求的URI进行hash运算，用于代理缓存以提高命中率，适用于HTTP后端缓存服务器；url_param，根据请求的URl参数进行hash运算，可将同一个用户ID的请求送往同一特定服务器；hdr(name)，根据HTTP请求头匹配HTTP请求；rdp-cookie(name)，根据据cookie(name)锁定并哈希每一次TCP请求
      # balance            roundrobin                           

    # 监控、统计页面配置，用于监控后端服务器状态
    # 设置监控组名称，与frontend、backend共同组成完整代理，作用于TCP流量
    listen monitor

      # 设置监控组工作模式
      mode    http
      # 设置监控组端口
      bind    :18088
      # 设置启用默认统计报告
      stats    enable
      # 设置隐藏版本号
      stats    hide-version
      # 设置统计页面自动刷新时间间隔 
      stats    refresh 10       　　　　
      # 设置监控页面url，即监控访问网址
      stats uri    /status
      # 设置监控页面密码框提示文本
      stats realm    Haproxy Manager
      # 设置监控页面用户和密码  
      stats auth    admin:admin
      # 设置监控组是否启用后端服务器管理功能，用于手工启用/禁用后端服务器
      stats admin if    TRUE 

    # 设置接收客户端请求的前端虚拟节点，即对外提供服务的接口
    frontend    http-server

      # 设置前端节点模式
      mode    http
      # 设置前端节点监听端口
      bind    0.0.0.0:8088

      # acl请求策略配置，用于基于请求报文的首部、响应报文的内容或其它的环境状态信息制定转发决策，从而实现动静分离功能，区分大小写

      # 配置静态资源组请求策略，即匹配以/static /images等开头的访问路径，-i表示忽略大小写  
      # acl url_static path_beg  -i /static /images /img /javascript /stylesheets
      # 配置静态资源请求策略，即匹配以.jpg .gif等结尾的访问路径，-i即忽略大小写
      # acl url_static path_end  -i .jpg .gif .png .css .js .html
      # 配置主机类型静态资源策略，即匹配以.img .ftp等开头的主机访问信息，-i即忽略大小写
      # acl host_static hdr_beg(host)  -i img. video. download. ftp. imags. videos.

      # 配置php动态资源请求策略
      # acl url_php path_end -i .php

      # 配置java动态资源请求策略
      # acl url_jsp path_end -i .jsp .do

      # acl策略请求的匹配规则配置，即分配后端服务器的策略

      # url_static或host_static策略匹配
      # use_backend web-servers if url_static or host_static

      # php请求策略匹配
      use_backend php-servers if url_php

      # 匹配java请求策略转发匹配
      use_backend tomcat-servers if url_jsp


      # 后端服务器组配置

      # 设置默认后端服务器，即处理所有没有被规则匹配到的请求
      default_backend    web-servers
      
      # 设置后端服务器组web-servers
      backend web-servers
         
        # 设置负载均衡算法
        balance    first
        # 设置启用http-keep-alive事务类型，适用于静态后端服务器
        option    http-keep-alive
        # 设置后端服务器组的实例，check，健康检查；inter，健康检查时间间隔；maxconn，后端服务器最大连接数；rise，2次健康检查正常则判定次数；fall，健康检查失败判定次数；weight，权重；maxqueue，后端服务器请求最大等待队列数
        server nginx-server 192.168.0.100:80 check port 80 inter 2000 rise 2 fall 3
        server httpd-server 192.168.0.200:80 check port 80 inter 2000 rise 2 fall 3
        server tomcat-backup 192.168.0.180:8080 check port 8080 inter 2000 rise 2 fall 3 backup

      backend tomcat-servers

        # 设置工作方式
        mode    http
        # 设置启用http-server-close，适用于动态后端服务器
        option    http-server-close
        # 设置健康检查访问路径
        option    httpchk /index.html             　　　　 


        server tomcat-master 192.168.0.100:8080 check port 8080 inter 2000 rise 2 fall 3 weight 3 maxconn 300 maxqueue 10
        server tomcat-slaver 192.168.0.200:8080 check port 8080 inter 2000 rise 2 fall 3 weight 1 maxconn 300 maxqueue 10
        # 设置不参与负载的服务器
        # server tomcat-servers 127.0.0.1:8080 weight 0
        # 设置容灾服务器，即其他所有负载宕机之后再提供服务
        # server tomcat-backup 192.168.0.180:8080 check port 8080 inter 2000 rise 2 fall 1 backup

      backend php-servers

        # 设置会话保持，不建议haproxy配置session共享，可于后端服务器配置

        # source方式，将同一IP请求送往同一服务器，若服务不可用，则session消失，不适于小型网络和代理服务器
        # balance    source
        # server httpd-master 192.168.0.200:80 check port 80 inter 2000 rise 2 fall 3
        # server httpd-slaver 192.168.0.100:80 check port 80 inter 2000 rise 2 fall 3
        # server nginx-server 192.168.0.180:80 check port 80 inter 2000 rise 2 fall 3 backup

        # cookie方式，将服务器端返回给客户端的cookie中插入后端服务器的cookie id，若客户端禁用则无法实现
        # cookie SERVERID insert indirect nocache

        # server httpd-master 192.168.0.200:80 check port 80 cookie httpd-server inter 2000 rise 2 fall 3
        # server httpd-slaver 192.168.0.100:80 check port 80 cookie httpd-server inter 2000 rise 2 fall 3
        # server nginx-server 192.168.0.180:80 check port 80 cookie nginx-server inter 2000 rise 2 fall 3 backup

---------

# 参考文档

- http://www.cnblogs.com/moss_tan_jun/p/6616472.html
- http://blog.51cto.com/jinyudong/1910320
- https://blog.csdn.net/li123128/article/details/79510249
- http://www.ttlsa.com/linux/haproxy-study-tutorial