---
title: Ansible自动化运维工具Role详解
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2024-01-16 10:20:55
---

Role，即角色，用于Ansible自动化运维工具Playbook的层次化、结构化地组织与编排，并根据层次型结构自动装载变量、tasks及handlers等。实际上，Role是通过分别将变量、文件、任务、模板及处理器存放于单独的目录，再通过include指令完成调用，最终将这些元素组合为一个整体。Role特别适用于复杂的大型场景，避免了出现不利于管理与维护的几百上千行的Playbook文件，提高了代码的复用度

# 目录结构

Ansible的Roles配置存放于/etc/ansible/roles，其下每个子文件夹即为一个Role，每个Role目录结构通常如下：

## 1.tasks/

用于存放任务文件，其下必须存在一个main.yml文件，用于通过include指令调用其他文件

## 2.vars/

用于存放变量文件，其下必须存在一个main.yml文件，用于通过include指令调用其他文件。若整个roles配置变量使用较少，只使用一个main.yml文件即可，否则就应将变量进行分类后存放于不同的目录，再通过main.yml进行调用

## 3.files/

用于存放copy或script模块的脚本文件

## 4.templates/

用于存放此Role需要使用的jinjia2模板文件

## 5.handlers/

用于存放Role中触发条件后执行的动作，也必须存在一个main.yml文件

## 6.meta/

用于存放此Role的特殊设定及其依赖关系，也必须存在一个main.yml文件

## 7.default/

用于存放此Role的设定默认变量，也必须存在一个main.yml文件

---------

# 1.创建项目

    mkdir -p /home/project/ansible/kubernetes/roles
    cd /home/project/ansible/kubernetes/roles

# 2.系统初始化配置

    ansible-galaxy init system 

## 2.1 创建Playbook

    vi system/tasks/main.yml

    - name: 更新
    - name: 安装依赖包
      apt: name="{{ item }}" state: latest
      loop:
        - curl
        - gnupg2
        - ipvsadm
        - ca-certificates
        - apt-transport-https
    - name: 导入阿里云apt源密钥
      shell: curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
    - name: 禁用swap
      shell: sed -ri 's/.*swap.*/#&/' /etc/fstab && swapoff -a
    - name: 开启路由转发
      copy: src=k8s.conf dest=/etc/sysctl.d
    - name: 生效配置文件
      shell: sysctl -p

## 2.2 创建配置文件

    vi files/k8s.conf


    net.ipv4.ip_forward=1
    net.bridge.bridge-nf-call-iptables=1
    net.bridge.bridge-nf-call-ip6tables=1

# 3.Docker配置

    ansible-galaxy init docker

## 3.1 创建Playbook

    vi docker/tasks/main.yaml


    - name: 解压docker安装包
      unarchive: src=docker-19.03.12.tgz dest=/home/sword
    - name: 安装docker
      shell: mv docker/* /usr/bin && mkdir -p /etc/docker && mkdir -p /root/.docker
    - name: 配置docker仓库加速器
      copy: src=daemon.json dest=/etc/docker  
    - name: 创建创建docker服务启动脚本
      copy: src=docker.service dest=/lib/systemd/system
    - name: 启动docker
      service: name=docker state=started enabled=yes

## 3.2 创建配置文件

    cp /home/works/Linux/software/docker-19.03.12.tgz docker/files/
    vi docker/files/daemon.json


    {  
      "exec-opts": ["native.cgroupdriver=systemd"],
      "registry-mirrors": [  
        "https://registry.docker-cn.com",  
        "https://docker.mirrors.ustc.edu.cn"  
      ]  
    }

---------

    vi docker/files/docker.service


    [Unit]
    Description=Docker Application Container Engine  
    Documentation=https://docs.docker.com  
    After=network-online.target firewalld.service  
    Wants=network-online.target  
  
    [Service]  
    Type=notify  
    ExecStart=/usr/bin/dockerd  
    ExecReload=/bin/kill -s HUP $MAINPID  
    LimitNOFILE=infinity  
    LimitNPROC=infinity  
    LimitCORE=infinity  
    TimeoutStartSec=0  
    Delegate=yes  
    KillMode=process  
    Restart=on-failure  
    StartLimitBurst=3  
    StartLimitInterval=60s  
  
    [Install]  
    WantedBy=multi-user.target 

# 4.kubernetes集群组件配置

    ansible-galaxy init kubeadm

## 4.1 创建Playbook

    vi kubeadm/tasks/main.yml


    - name: 配置kubernetes阿里云apt源
      copy: src=kubernetes.list dest=/etc/apt/sources.list.d
    - name: 安装kubeadm、kubelet、kubectl
      shell: apt update && apt install -y kubelet=1.20.12-00 kubeadm=1.20.12-00 && systemctl enable kubelet

## 4.2 创建配置文件

    vi kubeadm/files/kubernetes.list


    deb https://mirrors.aliyun.com/kubernetes/apt kubernetes-xenial main

# 5.高可用配置

    ansible-galaxy init ha

## 5.1 创建Playbook

    vi ha/tasks/main.yml


    - name: master节点安装haroxy、keepalived
      apt: 
        name:
          - haproxy
          - keepalived
        state: latest
    - name: master节点创建haproxy配置文件
      copy: src=haproxy.cfg dest=/etc/haproxy
    - name: master节点启动haproxy
      service: name=haproxy state=started enabled=yes
    - name: master节点创建keepalived配置文件
      template: src=keepalived.conf.j2 dest=/etc/keepalived/keepalived.conf
      notify: 重启keepalived
    - name: master节点创建haproxy服务状态监控脚本
      copy: src=haproxy_check.sh dest=/etc/keepalived

## 5.2 创建配置文件

    vi ha/files/haproxy.cfg


    global
    log    127.0.0.1 local2
    # chroot    /usr/local/haproxy
    pidfile    /var/run/haproxy.pid
    user    sword
    group    sword
    daemon
    nbproc    1
    maxconn   1024
    # node    haproxy-001
    stats socket    /var/lib/haproxy/stats

    defaults
      log    global
      mode    http
      option    httplog
      option    httpclose
      option    forwardfor except 127.0.0.0/8              
      option    dontlognull
      option    redispatch
      option    abortonclose
      http-reuse    safe
      retries    3

      timeout client    10s
      timeout http-request    2s
      timeout http-keep-alive 10s
      timeout queue    10s
      timeout connect    1s
      timeout check    2s
      timeout server    3s

    listen monitor
      mode    http
      bind    :1443
      stats    enable
      stats    hide-version
      stats    refresh 10       　　　　
      stats uri    /status
      stats realm    Haproxy Manager
      stats auth    admin:admin
      stats admin if    TRUE 

    frontend    master
      mode    tcp
      option   tcplog
      bind    0.0.0.0:8443
      default_backend    api-servers 

      backend api-servers

        mode    tcp
        balance    roundrobin
        stick-table type ip size 200k expire 30m
        stick on src
        server master01 172.100.100.201:6443 check port 6443 inter 2000 rise 2 fall 3
        server master02 172.100.100.202:6443 check port 6443 inter 2000 rise 2 fall 3
        server master03 172.100.100.203:6443 check port 6443 inter 2000 rise 2 fall 3

---------

    vi ha/files/haproxy_check.sh


    #!/bin/bash

    pid=`ps -ef|grep haproxy|grep -v grep|wc -l`
    port=`netstat -anp|grep :8443|grep LISTEN|wc -l`

    if [[ $pid -gt 1 && $port -gt 0 ]]
      then
        exit 0
      else
        pkill keepalived
    fi

## 5.3 创建模版文件

    vi ha/templates/keepalived.conf.j2


    global_defs {
      notification_email
      {
        admin@sword.com
      }
      notification_email_from
      smtp_server 127.0.0.1
      smtp_connect_timeout 30
      router_id {{ ansible_hostname }}
    }

    vrrp_script check_haproxy {
      script "/etc/keepalived/haproxy_check.sh"
      interval 2
      weight -10
    }

    vrrp_instance Haproxy {
      state {{ keepalived_role }}
      interface eth0
      virtual_router_id 51
      priority {{ keepalived_rank }}
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 123456
      }
      virtual_ipaddress {
        172.100.100.210/24
      }
      track_script {
        check_haproxy
      }
    }

## 5.4 创建变量

    vi /etc/ansible/hosts 

    
    [master]
    master01 keepalived_role=MASTER keepalived_rank=100
    master02 keepalived_role=BACKUP keepalived_rank=80
    master03 keepalived_role=BACKUP keepalived_rank=60

## 5.5 创建处理器

    vi ha/handlers/main.yml


    - name: 重启keepalived
      systemd:
        name: keepalived
        state: restarted

# 6.创建项目调度入口脚本

    vi /home/project/ansible/kubernetes/site.yml


    - hosts: k8s
      become: yes
      roles:
        - role: system
        - role: docker
        - role: kubeadm
        - role: ha
          when: ansible_hostname in groups ['master']

---------

# 参考文档

- https://www.cnblogs.com/FGdeHB/p/16685985.html
- https://www.cnblogs.com/caodan01/p/14859879.html
- https://blog.csdn.net/Promise_410/article/details/118520364