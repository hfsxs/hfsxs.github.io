---
title: Frp内网穿透工具的安装与配置
categories:
  - 极客
tags:
  - Linux
  - Frp
  - 内网穿透 
  - 极客
date: 2021-03-24 17:15:36
---

Frp，是一款跨平台的开源免费的内网穿透工具，实质上就是一个反向代理服务器，将访问公网IP的请求通过端口转发到内网，再将内网服务器的响应信息通过公网IP发送给客户端，从而使处于内网或防火墙后的设备具备了对外提供服务的功能。frp支持TCP、UDP、HTTP及HTTPS等众多协议，速度只受公网IP的带宽限制，功能强大而易用

---------

# 1.下载frp软件包

    # https://github.com/fatedier/frp/releases  
    wget https://github.com/fatedier/frp/releases/download/v0.36.2/frp_0.36.2_linux_amd64.tar.gz
    
# 2.配置公网服务器端

    tar -xzvf frp_0.36.2_linux_amd64.tar.gz
    sudo mv frp_0.36.2_linux_amd64 /usr/local/frp  
    
## 2.1 创建配置文件

    sudo vi /usr/local/frp/frps.ini 
    
    
    [common]
    # 设置服务端监听端口，用于和内网设备通信
    bind_port = 8000
    # 设置服务端可视化仪表板访问端口
    # dashboard_port = 8001
    # 设置服务端可视化仪表板用户名
    # dashboard_user = admin
    # 设置服务端可视化仪表板登录密码
    # dashboard_pwd = admin@2020
    # 设置服务端连接的身份认证令牌密码
    token = FrpServer@2020
    
## 2.2 创建启动脚本

    sudo vi /lib/systemd/system/frps.service 
    
    
    [Unit]
    Description=Frp Server Service
    After=network.target
    
    [Service]
    Type=simple
    User=nobody
    Restart=on-failure
    RestartSec=5s
    ExecStart=/usr/local/frp/frps -c /usr/local/frp/frps.ini
    
    [Install]
    WantedBy=multi-user.target
    
## 2.3 启动frp服务

    sudo systemctl daemon-reload
    sudo systemctl enable frps
    sudo systemctl start frps
    
# 3.配置内网客户端

    tar -xzvf frp_0.36.2_linux_amd64.tar.gz
    sudo mv frp_0.36.2_linux_amd64 /usr/local/frp
    
## 3.1 创建配置文件

    sudo vi /usr/local/frp/frpc.ini 
    
    
    [common]
    # 设置服务端公网IP
    server_addr = 42.192.96.124
    # 设置服务端通信端口
    server_port = 8000
    # 设置服务端身份认证的令牌密码
    token = FrpServer@2020 
    
    [ssh]
    # 设置转发协议，tcp、udp、http
    type = tcp
    # 设置内网IP
    local_ip = 127.0.0.1
    # 设置内网端口
    local_port = 22
    # 设置服务端转发端口，用于内网流量的转发及外部访
    remote_port = 221
    
    [http]
    # 设置转发协议，tcp、udp、http
    type = tcp
    # 设置内网IP
    local_ip = 127.0.0.1
    # 设置内网端口
    local_port = 80
    # 设置服务端转发端口，用于内网流量的转发及外部访问
    remote_port = 880
    
## 3.2 创建启动脚本

    sudo vi /lib/systemd/system/frpc.service 
    
    
    [Unit]
    Description=Frp Server Service
    After=network.target
    
    [Service]
    Type=simple
    User=nobody
    Restart=on-failure
    RestartSec=5s
    ExecStart=/usr/local/frp/frpc -c /usr/local/frp/frpc.ini
    
    [Install]
    WantedBy=multi-user.target

## 3.3 启动frp服务

    sudo systemctl daemon-reload
    sudo systemctl enable frpc
    sudo systemctl start frpc
    
# 4.测试连接

    ssh -p221 42.192.96.124