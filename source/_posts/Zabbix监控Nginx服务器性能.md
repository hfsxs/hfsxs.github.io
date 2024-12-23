---
title: Zabbix监控Nginx服务器性能
categories:
  - 工作
tags:
  - Linux
  - Zabbix
  - Nginx
  - 监控告警
  - 云计算
date: 2020-02-03 09:45:09
---

# 1.Nginx编译安装http_stub_status_module模块

    ./configure --prefix=/usr/local/nginx --conf-path=/etc/nginx/nginx.conf \
    --with-http_stub_status_module
    make && make installs

# 2.配置nginx status

    vi /etc/nginx/nginx.conf

    server {

      listen       80;
      #access_log  logs/host.access.log  main;

      location / {
        root   html;
        index  index.php index.html index.htm;
      }

      location = /nginx-status {
        stub_status on;
        access_log  off;
        allow 127.0.0.1;
        allow 192.168.100.188;
				deny all;
      }
    }

# 3.测试nginx-status

    curl 127.0.0.1/nginx-status

# 4.编写zabbix监控脚本

    vi /usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh


    #!/bin/bash 


    HOST="127.0.0.1" 
    PORT="80" 
    # Functions to return nginx stats 
    function active { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| grep 'Active' | awk '{print $NF}' 
    } 
    function reading { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| grep 'Reading' | awk '{print $2}' 
    } 
    function writing { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| grep 'Writing' | awk '{print $4}' 
    } 
    function waiting { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| grep 'Waiting' | awk '{print $6}' 
    } 
    function accepts { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| awk NR==3 | awk '{print $1}' 
    } 
    function handled { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| awk NR==3 | awk '{print $2}' 
    } 
    function requests { 
      /usr/bin/curl "http://$HOST:$PORT/nginx-status" 2>/dev/null| awk NR==3 | awk '{print $3}' 
    } 
    $1

---------

    chmod +x nginx_status.sh
    chown zabbix.zabbix nginx_status.sh

# 5.配置zabbix客户端配置文件

    vi /etc/zabbix/zabbix_agentd.conf


    UnsafeUserParameters=1
    UserParameter=nginx.accepts,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh accepts 
    UserParameter=nginx.handled,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh handled 
    UserParameter=nginx.requests,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh requests 
    UserParameter=nginx.connections.active,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh active 
    UserParameter=nginx.connections.reading,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh reading 
    UserParameter=nginx.connections.writing,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh writing 
    UserParameter=nginx.connections.waiting,/usr/local/zabbix/share/zabbix/alertscripts/nginx_status.sh waiting

# 6.启动zabbix agent

    systemctl start zabbix_agentd

# 7.Nginx主机配置监控模版

导入nginx模板 ---> 主机链接模板

# 8.验证nginx监控

    