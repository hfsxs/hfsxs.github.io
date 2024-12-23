---
title: CoreDNS搭建DNS服务器
categories:
  - - 工作
  - - 极客
tags:
  - Linux
  - DNS
  - CoreDNS
  - 域名解析
  - 云计算
  - 极客
date: 2022-11-06 19:19:27
---

# 1.下载coredns二进制安装包

    wget https://github.com/coredns/coredns/releases/download/v1.10.1/coredns_1.10.1_linux_amd64.tgz
    
# 2.安装coredns

    tar -xzvf coredns_1.10.1_linux_amd64.tgz
    sudo mv coredns /usr/local/bin
    sudo chmod +x /usr/local/bin/coredns

# 3.创建配置文件

    sudo mkdir -p /etc/coredns/zones
    
## 3.1 创建主配置文件

    sudo vi /etc/coredns/corefile
    
    
    .:53 {
    
        loadbalance
        forward . 8.8.8.8 8.8.4.4
        cache 120
        reload 6s
        log
        errors

        # 配置hosts插件，适用于解析的域名较少的场景
        hosts {

          192.168.0.41 web.local.com
          ttl 60
          reload 1m
          fallthrough
        }
    
        auto sword.org {
            directory /etc/coredns/zones
            reload 10s
        }
    
    }
    
    org:53 {
    
        hosts /etc/coredns/hostsfile
        log
    }

## 3.2 创建配置文件
    
    sudo vi /etc/coredns/hostsfile
    
    
    192.168.100.120 test.sword.org
    

# 4.创建启动脚本
    
    sudo vi /lib/systemd/system/coredns.service
    
    
    [Unit]
    Description=https://github.com/coredns/deployment
    After=network.target
    
    [Service]
    WorkingDirectory=/usr/local/bin
    Restart=on-failure
    ExecStart=/usr/local/bin/coredns -conf=/etc/coredns/corefile
    #ExecReload=/bin/kill -HUP $MAINPID
    Type=simple
    KillMode=control-group
    RestartSec=3
    
    [Install]
    WantedBy=multi-user.target

# 5.启动coredns服务
 
    sudo systemctl daemon-reload  
    sudo systemctl start coredns  
    sudo systemctl enable coredns

# 6.配置客户端DNS服务器，测试域名解析

## 6.1 Windows客户端

## 6.2 MacOS或Linux客户端

    sudo vi /etc/resolv.conf
    
    
    nameserver 192.168.100.120
    nameserver 8.8.8.8

## 6.3 测试域名解析

    ping test.sword.org

---------

# 参考文档

- https://www.cnblogs.com/XY-Heruo/p/16783123.html
- https://www.cnblogs.com/menglingqian/p/15872362.html
- https://www.pudn.com/news/623c277fe28b415bafe2cf2a.html