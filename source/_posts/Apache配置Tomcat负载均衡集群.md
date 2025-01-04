---
title: Apache配置Tomcat负载均衡集群
categories:
  - 工作
tags:
  - Linux
  - Apache
  - Http服务器
  - 负载均衡
  - 云计算
date: 2020-02-01 09:24:41
---

# 集群架构

- 172.16.100.100  node01  apache
- 172.16.100.120  node02  tomcat
- 172.16.100.200  node03  tomcat

---------

Apache配置Tomcat的负载均衡集群有三种方式，即mod_jk、http_proxy及ajp_proxy

---------

# 1.mod_jk方式

mod_jk通过AJP协议与Tomcat通信，Tomcat默认的AJP Connector端口为8009，此外还提供了一个监控器jkstatus，用于监控JK的工作状态

## 1.1 编译安装mod_jk

    tar -xzvf tomcat-connectors-1.2.42-src.tar.gz && cd tomcat-connectors-1.2.42-src/native
    ./configure --with-apxs=/usr/local/httpd/bin/apxs
    make && make install

## 1.2 Apache配置文件加载mod_jk模块

    vi /etc/httpd/conf/httpd.conf


    # 设置加载mod_jk模块配置文件
    Include /etc/httpd/conf/extra/mod_jk.conf

## 1.3 创建mod_jk模块配置文件

    vi /etc/httpd/conf/extra/mod_jk.conf


    # 设置加载mod_jk模块 
    LoadModule jk_module /usr/local/httpd/modules/mod_jk.so

    # 设置加载负载均衡控制器配置文件，用于定义转发主机和监听端口
    JkWorkersFile /etc/httpd/conf/extra/workers.properties

    # 设置日志文件存储路径
    JkLogFile /usr/local/httpd/logs/mod_jk.log

    # 设置日志级别[debug/error/info]
    JkLogLevel info

    # 设置日志格式
    JkLogStampFormat "[%a %b %d %H:%M:%S %Y] "
    JkOptions +ForwardKeySize +ForwardURICompat -ForwardDirectories
    JkRequestLogFormat "%w %V %T"

    # 设置URL规则，实现动静分离
    JkMount /*.do loadbalancer
    JkMount /*.jsp loadbalancer
    JkMount /servlet/* loadbalancer
    # 设置监控器访问地址
    JkMount /jk_status status

## 1.4 设置负载均衡控制器配置文件

    vi /etc/httpd/conf/extra/workers.properties


    # 设置Tomcat服务器工作组，对应于mod_jk.conf文件
    worker.list=loadbalancer,status,tomcat1,tomcat2

    # 设置Tomcat服务器JK端口
    worker.tomcat1.port=8009 
    # 设置Tomcat服务器IP
    worker.tomcat1.host=172.16.100.100.120
    # 设置通信协议，与Tomcat配置文件server.xml protocol保持一致
    worker.tomcat1.type=ajp13
    # 设置Tomcat服务器负载权重
    worker.tomcat1.lbfactor=1

    worker.tomcat2.port=8009
    worker.tomcat2.host=172.16.100.200
    worker.tomcat2.type=ajp13
    worker.tomcat2.lbfactor=1

    # 设置loadbalancer负载均衡控制器
    worker.loadbalancer.type=lb

    # 设置负载列表
    worker.loadbalancer.balance_workers=tomcat1,tomcat2

    # 设置启用会话保持
    worker.loadbalancer.sticky_session=ture

    # 设置启用JK模块监控器
    worker.status.type=status

## 1.5 启动Apache、Tomcat服务验证负载均衡

# 2.http_proxy方式

mod_proxy模块自Apache 2.2开始正式启用，是基于HTTP协议的代理，Tomcat默认的HTTP Connector端口为8080

## 2.1 安装Apache、Tomcat

## 2.2 修改Apache配置文件

    vi /etc/httpd/conf/httpd.conf


    # 启用反向代理模块
    LoadModule proxy_module modules/mod_proxy.so

    # 启用代理http协议模块
    LoadModule proxy_http_module modules/mod_proxy_http.so

    # 启用代理ajp协议模块
    LoadModule proxy_ajp_module modules/mod_proxy_ajp.so

    LoadModule proxy_connect_module modules/mod_proxy_connect.so

    # 启用负载均衡模块
    LoadModule proxy_balancer_module modules/mod_proxy_balancer.so

    # 启用负载均衡管理器模块
    LoadModule status_module modules/mod_status.so 

    # 启用负载均衡算法模块
    LoadModule lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so
    LoadModule lbmethod_bytraffic_module modules/mod_lbmethod_bytraffic.so
    LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so 
    LoadModule slotmem_shm_module modules/mod_slotmem_shm.so

    # 反向代理负载均衡配置

    # 关闭正向代理
    ProxyRequests Off

    # 反向代理支持虚拟主机
    ProxyPreserveHost On

    # session粘性，为JSESSIONID是浏览器cookie方式session处理，为jsessionid则是客户端采用URL
    # ProxyPass / balancer://tomcat-cluster/ stickysession=JSESSIONID nofailover=On

    # session非粘性，需后端Tomcat服务器配置session复制功能，
    ProxyPass / balancer://app-slb-tomcat/ nofailover=On

    # 负载均衡管理器，仅调试用，生产环境禁用，访问路径为 http://localhost/balancer-manager

    # <Location /balancer-manager> 
      # SetHandler balancer-manager 
      # Order Deny,Allow 
      # Allow from all 
      # Allow from localhost 
    # </Location> 

    # 配置动静分离
    ProxyPassMatch /*.gif$ ! 
    ProxyPassMatch /*.jpg$ !
    ProxyPassMatch /*.png$ ! 
    ProxyPassMatch /*.css$ ! 
    ProxyPassMatch /*.js$ ! 
    ProxyPassMatch /*.htm$ ! 
    ProxyPassMatch /*.html$ !

    # 配置负载均衡器日志路径
    ErrorLog "/usr/local/httpd/logs/app-slb-tomcat-error.log"
    CustomLog "/usr/local/httpd/logs/app-slb-tomcat-access.log" common

    <Proxy balancer://app-slb-tomcat>      
      BalancerMember http://172.16.100.100.100:8080  loadfactor=1 route=tomcat1
      BalancerMember http://172.16.100.100.200:8080  loadfactor=1 route=tomcat2
      # 热备服务器
      # BalancerMember http://172.16.100.100.120:8080 status=+H

      # 设置负载均衡算法

      # 按照请求次数均衡(默认)
      # ProxySet lbmethod=byrequests
      # 按照流量均衡
      # ProxySetlbmethod=bytraffic
      # 最少请求数
      # ProxySet lbmethod=bybusyness
    </Proxy> 

    # 配置双机热备高可用集群

    # ProxyRequests Off 
    # ProxyPass / balancer://app-ha-tomcat/ 
    # <Proxy balancer://app-ha-tomcat> 
      # BalancerMember http://172.16.100.100.120:8080 
      # BalancerMember http://172.16.100.100.200:8080 status=+H 
    # </Proxy> 

## 2.3 启动Apache与Tomcat服务

# 3.ajp_proxy方式

类似于http_proxy，由mod_proxy模块提供代理功能，只需将http://换成ajp://，也是连接Tomcat的AJP Connector端口，默认为8009


    <Proxy balancer://app-slb-tomcat>      
      BalancerMember ajp://172.16.100.100.120:8009  loadfactor=1 route=tomcat1
      BalancerMember ajp://172.16.100.100.200:8009  loadfactor=1 route=tomcat2
    </Proxy> 