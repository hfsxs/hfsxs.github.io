---
title: Haproxy搭建负载均衡集群
categories:
  - 工作
tags:
  - Linux
  - Haproxy
  - 集群
  - 负载均衡
  - 云计算
date: 2020-02-05 12:07:54
---

HAProxy，是由C语言编写的提供高可用、负载均衡及基于TCP(第四层)和HTTP(第七层)应用的代理软件，适用于负载特大且需要会话保持或七层处理的web站点，支持虚拟主机、Session保持和后端服务器的url健康检测，其全透明代理的特性已初步具备硬件防火墙的典型特点，特有的连接拒绝功能更是可以抵御小型的DDoS攻击。HAProxy的单进程、事件驱动模型显著降低了上下文切换的开销及内存占用，不受内存、系统调度器及各种锁的限制，从而能支持非常大的并发连接数

HAProxy的弊端在于多核系统程序的扩展性较差，需要进行优化以使每个CPU时间片(Cycle)能做更多负载，也不支持web缓存功能

# 连接模式

- keepalive，默认模式，处理请求和响应连接保持打开，但在响应和新请求之间保持空闲
- tunnel，只有第一个请求和响应被处理，其他都被转发，不建议使用
- passive close，即被动关闭，与隧道模式完全相同，但在两个个方向上添加Connection: close以尝试在第一次交换之后立即关闭连接
- server close，即服务器关闭，服务器连接在收到响应结束后即关闭，但客户端连接保持打开
- forced close，即强制关闭，连接被主动关闭，响应结束

---------

# 1.安装依赖包

    apt install -y gcc make libssl-dev libsystemd-dev 
    yum install -y gcc make openssl-devel systemd-devel 

# 2.编译安装haproxy

    tar -xzvf haproxy-1.7.9.tar.gz && cd haproxy-1.7.9
    make ARCH=x86_64 TARGET=linux-glibc USE_SYSTEMD=1 PREFIX=/usr/local/haproxy
    make install PREFIX=/usr/local/haproxy SBINDIR=/usr/local/haproxy/sbin

# 3.创建haproxy配置文件

    mkdir -p /etc/haproxy /var/lib/haproxy
    vi /etc/haproxy/haproxy.cfg


    global
      log         127.0.0.1 local2
      chroot      /var/lib/haproxy
      pidfile     /var/run/haproxy.pid
      maxconn     4096
      user        sword
      group       sword
      daemon
      stats socket /var/lib/haproxy/stats

    defaults
      mode             tcp
      log              global
      option           tcplog
      option           dontlognull
      option           redispatch
      retries          3
      timeout queue    1m
      timeout connect  10s
      timeout client   1m
      timeout server   1m
      timeout check    10s
      maxconn          3000

    frontend  nginx
    bind    0.0.0.0:80
    mode               tcp
    maxconn            2048
    default_backend    nginx-servers
    
    backend nginx-servers
      balance    roundrobin
      server master01 172.16.100.100:80  check inter 10000 fall 2 rise 2 weight 1
      server master02 172.16.100.120:80  check inter 10000 fall 2 rise 2 weight 1
      server master03 172.16.100.160:80  check inter 10000 fall 2 rise 2 weight 1

# 4.配置启动脚本

    cp contrib/systemd/haproxy.service.in /usr/lib/systemd/system/haproxy.service
    sed -i 's#@SBINDIR@#/usr/local/haproxy/sbin#g' /usr/lib/systemd/system/haproxy.service

# 5.创建选项配置文件

    vi /etc/default/haproxy


    EXTRAOPTS="-S /run/haproxy-master.sock"

# 6.配置haproxy日志

## 6.1 配置系统日志服务rsyslog

    vi /etc/rsyslog.conf 


    # 启用UDP端口接收其他设备的日志消息          
    $ModLoad imudp
    $UDPServerRun 514

    # 设置local2级别设备的日志存储路径
    local2.*    /var/log/haproxy.log

#### 6.2 重启rsyslog

    systemctl restart rsyslog.service

# 7.启动haproxy服务

    systemctl daemon-reload
    systemctl start haproxy.service
    systemctl enable haproxy.service

---------

# 参考文档

- https://www.cmdschool.org/archives/9619
- http://www.cnblogs.com/xibei666/p/5877548.html
- https://blog.csdn.net/tantexian/article/details/50056199