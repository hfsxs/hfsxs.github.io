---
title: Leanote搭建私有云笔记服务器
categories:
  - 极客
tags:
  - Linux
  - Leanote
  - Mongodb
  - 私有云
  - 云笔记 
  - 极客
date: 2021-02-01 18:50:31
---

Leanote，即蚂蚁笔记，由Go语言的web框架revel开发的开源云笔记软件，集知识管理、笔记、分享、博客功能于一身，支持多笔记本、标签分类、笔记共享、添加与保存附件、代码高亮等功能。此外，还支持平台自建和办公协作，适用于规模较小的团队，团队成员共用一个用户组，将笔记共享到这个组里，所有组员都可以浏览、编辑笔记，可以非常方便地进行协作与知识共享

---------

# 1.安装mongodb

## 1.1 下载mongodb

## 1.2 安装mongodb

    tar -xzvf mongodb-*.tgz
    sudo mv mongodb-* /usr/local/mongodb
    sudo mkdir -p /usr/local/mongodb /var/log/mongodb 

## 1.3 创建启动脚本

    sudo vi /lib/systemd/systemd/mongodb.service
    
    
    [Unit] 
    Description=mongodb
    After=network.target remote-fs.target nss-lookup.target
    
    [Service]
    Type=forking
    ExecStart=/usr/local/mongodb/bin/mongod --dbpath /usr/local/mongodb/data \
    --logpath /var/log/mongodb/mongod.log --fork 
    ExecReload=/bin/kill -s HUP $MAINPID
    ExecStop=/bin/kill -s QUIT $MAINPID 
    PrivateTmp=true
    
    [Install] WantedBy=multi-user.target
    

## 1.4 启动mongodb

    sudo systemctl daemon-reload
    sudo systemctl start mongodb.service
    sudo systemctl enable mongodb.service

# 2.安装leanote

## 2.1 下载leanote二进制安装包

http://leanote.org/#download

## 2.2 安装leanote

    tar -xzvf leanote-linux-amd64-v2.6.1.bin.tar.gz
    sudo mv leanote-linux-amd64-v2.6.1 /web/leanote
    
## 2.3 修改配置文件

    sudo vi /web/leanote/conf/app.conf
    
    
    http.addr=0.0.0.0
    http.port=8888
    site.url=http://localhost:8888
    adminUsername=admin
    db.host=127.0.0.1 db.port=27017
    app.secret=V85ZzBfTnzpsHyjQX4zukbQ8qBtju9y2aDM55VWxAH8Qop21poekx3xkcDVvrD0Y
    
## 2.4 导入leanote初始数据

    sudo /usr/local/mongodb/bin/mongorestore -h 127.0.0.1 \
    -d leanote --dir /web/leanote/mongodb_backup/leanote_install_data
    
## 2.5 创建启动脚本

    sudo vi /lib/systemd/system/leanote.service
    
    
    [Unit]
    Description=Leanote Service
    After=syslog.target network.target
    
    [Service]
    User=sword
    ExecStart=/web/leanote/bin/run.sh
    ExecReload=/bin/kill -s HUP $MAINPID
    ExecStop=/bin/kill -s QUIT $MAINPID
    
    [Install]
    WantedBy=multi-user.target

## 2.5 启动leanoe

    sudo systemctl daemon-reload
    sudo systemctl start leanote.service
    sudo systemctl enable leanote.service 

# 3.登录leanote

http://ip:8888

管理员账号：admin@leanote.com
初始密码：abc123