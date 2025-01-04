---
title: Kubernetes基于kubeadm工具构建高可用集群
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2021-11-12 15:26:56
---

kubeadm，用于快速构建kubernetes集群的工具，通过kubeadm init及kubeadm join两个命令迅速启动和运行一个可用的集群。kubeadm大大简化了二进制部署方式令人望而生畏的繁琐步骤，降低了部署门槛，对初学者十分友好。当然，二进制部署方式能详细了解集群的架构及工作原理，也利于后期的维护与排障，适用于对kubernetes有深入了解的情况

---------

# 高可用方案

Kubernetes集群的高可用是生产环境的业务系统必不可少的考量，其核心指标是集群内任意一台服务器的宕机都不能影响整个集群的正常工作，具体策略为给Kubernetes集群Master节点的关键组件都提供高可用的功能，从而消除整个集群的单点故障

- Etcd数据库，Kubernetes集群唯一带状态的服务，是整个集群的数据中心，分布式架构自带高可用功能，不存在单点故障，推荐的部署方案是3或5个奇数个节点组成冗余的etcd集群

- kube-apiserver，API Server是整个集群的访问入口，整个集群高可用的关键，通过启动多个实例并配合负载均衡器实现高可用，如Nginx/Haproxy、Keepalived等

- Kube-controller-manager，集群内部的管理控制中心，整个集群只有一个活跃的实例，可同时启动多个实例，然后开启领导者选举功能实现高可用，即--leader-elect=true

- kube-scheduler，集群节点调度中心，将POD调度到合适节点运行，一个集群只能有一个活跃的实例，可同时启动多个实例，然后开启领导者选举功能实现高可用，默认开启

- kube-dns，集群Service监控及发现中心，用于解析Service与ClusterIP的映射，通过Deployment方式部署，并用anti-affinity将之部署到不同的Node节点

# 集群架构
  
- 172.16.100.100  master01
- 172.16.100.120  master02
- 172.16.100.160  master03
- 172.16.100.180  worker01
- 172.16.100.200  worker02
- 172.16.100.150  VIP

# 1.系统环境配置

## 1.1 配置hosts

    sudo vi /etc/hosts


    172.16.100.100  master01
    172.16.100.120  master02
    172.16.100.160  master03
    172.16.100.180  worker01
    172.16.100.200  worker02
 
## 1.2 关闭防火墙
 
## 1.3 禁用selinux

## 1.4 关闭swap

    sudo swapoff -a && sudo sed -ri 's/.*swap.*/#&/' /etc/fstab

## 1.5 配置系统内核参数

### 1.5.1 开启路由转发

    sudo vi /etc/sysctl.d/k8s.conf


    net.ipv4.ip_forward=1
    net.bridge.bridge-nf-call-iptables=1
    net.bridge.bridge-nf-call-ip6tables=1

### 1.5.2 加载内核参数配置

    sudo sysctl -p

## 1.6 配置集群免密登录

# 2.集群部署docker

## 2.1 安装docker

    # 配置阿里云YUM源
    wget https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo \
    -O /etc/yum.repos.d/docker-ce.repo
    # 安装docker
    sudo yum install -y docker-ce

### 2.2 配置镜像加速及cgroup驱动

    sudo mkdir -p /etc/docker && sudo vi /etc/docker/daemon.json


    {
      "exec-opts": ["native.cgroupdriver=systemd"],
      "registry-mirrors": ["https://hub-mirror.c.163.com"]
    }

## 2.3 启动docker

    sudo systemctl start docker
    sudo systemctl enable docker

# 3.Master节点部署Haproxy、Keepalived

    sudo yum install -y haproxy keepalived

## 3.1 创建Haproxy配置文件

    sudo vi /etc/haproxy/haproxy.cfg
 

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
        server master01 172.16.100.100:6443 check port 6443 inter 2000 rise 2 fall 3
        server master02 172.16.100.120:6443 check port 6443 inter 2000 rise 2 fall 3
        server master03 172.16.100.160:6443 check port 6443 inter 2000 rise 2 fall 3

## 3.2 创建Keepalived配置文件

### 3.2.1 master01节点配置文件

    sudo vi /etc/keepalived/keepalived.conf


    global_defs {
      notification_email
      {
        admin@sword.com
      }
      notification_email_from
      smtp_server 127.0.0.1
      smtp_connect_timeout 30
      router_id master01
    }

    vrrp_script check_haproxy {
      script "/etc/keepalived/haproxy_check.sh"
      interval 2
      weight -10
    }

    vrrp_instance Haproxy {
      state BACKUP
      interface eth0
      virtual_router_id 51
      priority 100
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 123456
      }
      virtual_ipaddress {
        172.16.100.150/24
      }
      track_script {
        check_haproxy
      }
    }

### 3.2.2 master02节点配置文件

    sudo vi /etc/keepalived/keepalived.conf


    global_defs {
      notification_email
      {
        admin@sword.com
      }
      notification_email_from
      smtp_server 127.0.0.1
      smtp_connect_timeout 30
      router_id master02
    }

    vrrp_script check_haproxy {
      script "/etc/keepalived/haproxy_check.sh"
      interval 2
      weight -10
    }

    vrrp_instance Haproxy {
      state BACKUP
      interface eth0
      virtual_router_id 51
      priority 80
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 123456
      }
      virtual_ipaddress {
        172.16.100.150/24
      }
      track_script {
        check_haproxy
      }
    }

### 3.2.3 master03节点配置文件

    sudo vi /etc/keepalived/keepalived.conf


    global_defs {
      notification_email
      {
        admin@sword.com
      }
      notification_email_from
      smtp_server 127.0.0.1
      smtp_connect_timeout 30
      router_id master03
    }

    vrrp_script check_haproxy {
      script "/etc/keepalived/haproxy_check.sh"
      interval 2
      weight -10
    }

    vrrp_instance Haproxy {
      state BACKUP
      interface eth0
      virtual_router_id 51
      priority 60
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 123456
      }
      virtual_ipaddress {
        172.16.100.150/24
      }
      track_script {
        check_haproxy
      }
    }

## 3.3 创建Haproxy监控脚本

    sudo vi /etc/keepalived/haproxy_check.sh


    #!/bin/bash

    pid=`ps -ef|grep haproxy|grep -v grep|wc -l`
    port=`netstat -anp|grep :8443|grep LISTEN|wc -l`

    if [[ $pid -gt 1 && $port -gt 0 ]]
      then
        exit 0
      else
        pkill keepalived
    fi

## 3.4 启动Haproxy、Keepalived

    sudo systemctl start haproxy
    sudo systemctl enable haproxy
    sudo systemctl start keepalived
    sudo systemctl enable keepalived

# 4.Master节点部署kubeadm、kubelet、kubectl

## 4.1 配置阿里云YUM源

    sudo vi /etc/yum.repos.d/kubernetes.repo


    [kubernetes]

    name=Kubernetes
    baseurl=https://mirrors.aliyun.com/kubernetes/yum/repos/kubernetes-el7-x86_64
    enabled=1
    gpgcheck=0
    repo_gpgcheck=0
    gpgkey=https://mirrors.aliyun.com/kubernetes/yum/doc/yum-key.gpg https://mirrors.aliyun.com/kubernetes/yum/doc/rpm-package-key.gpg

## 4.2 安装kubeadm、kubelet、kubectl

    sudo yum install -y ipvsadm kubelet-1.20.12 kubeadm-1.20.12 kubectl-1.20.12
    sudo systemctl enable kubelet

# 5. Master节点部署Kubernetes

## 5.1 master01节点初始化集群

    kubeadm init \
    --kubernetes-version "1.20.12" \
    --control-plane-endpoint "172.16.100.100:8443" \
    --apiserver-cert-extra-sans "172.16.100.100,192.168.100.150,master" \
    --pod-network-cidr "172.30.0.0/16" \
    --service-cidr "10.254.0.0/16" \
    --token "dcwrhm.6wi8mn63s10gxrcf" \
    --token-ttl "0" \
    --image-repository registry.aliyuncs.com/google_containers \
    --upload-certs

- kubernetes-version，设置kubernetes版本
- control-plane-endpoint，设置控制节点IP地址
- apiserver-cert-extra-sans，设置API Server服务的附加认证证书，值为IP和DNS，可用于指定外网地址
- pod-network-cidr，设置Pod网段，与CNI网络组件定义的网段一致
- service-cidr，设置service网段
- image-repository，设置默认镜像拉取仓库
- token-tt，设置引导令牌有效期时长默认为24小时，为0表示永不过期，令牌保存于kube-system命名空间名为bootstrap-token-<token-id>的secret

---------

- 注：集群初始化成功将自动生成token及添加其余Master、Node节点的命令，按照给出的命令在其余节点执行即可将之加入集群

## 5.2 配置kubectl集群认证令牌

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

    echo "source <(kubectl completion bash)" >> /root/.bash_profile
    source /root/.bash_profile

## 5.3 其余Master节点初始化集群

### 5.3.1 Master节点初始化集群

    kubeadm join 172.16.100.100:8443 --token dcwrhm.6wi8mn63s10gxrcf \
    --discovery-token-ca-cert-hash sha256:231ea9ea085b6eccaac00cfb27b85748d2cc403cd2194434b163896d375126ea \
    --control-plane --certificate-key e9f4c8e66fd5b9629be14a92fac1230972f46427636be616cbae8573abc6bd5c

### 5.3.2  配置kubectl集群认证令牌

    mkdir -p $HOME/.kube
    sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
    sudo chown $(id -u):$(id -g) $HOME/.kube/config

# 6.部署Node

    kubeadm join 172.16.100.100:8443 --token dcwrhm.6wi8mn63s10gxrcf \
    --discovery-token-ca-cert-hash sha256:231ea9ea085b6eccaac00cfb27b85748d2cc403cd2194434b163896d375126ea 

- 注：token过期之后可重新创建，命令为：kubeadm token create --print-join-command

# 7.部署集群网络插件calico

## 7.1 下载calico资源文件

    curl https://docs.projectcalico.org/v3.20/manifests/calico.yaml -O

## 7.2 配置pod网络IP段

    vi calico.yaml


    - name: CALICO_IPV4POOL_CIDR
      value: "172.30.0.0/16"

- 注：CALICO_IPV4POOL_CIDR的值与初始化Master时--pod-network-cidr指定的值保持一致

## 7.3 部署集群网络插件calico

    kubectl apply -f calico.yaml

# 8.查看集群状态

## 8.1 查看集群组件状态

    kubectl get cs

## 8.2 查看集群网络组件

    kubectl -n kube-system get pods -o wide

## 8.3 查看集群节点状态

    kubectl get nodes -o wide

## 8.4 配置kube-proxy代理模式为ipvs

### 8.4.1 修改configmap

    kubectl edit cm kube-proxy -n kube-system


    mode: "ipvs"

### 8.4.2 重启kube-proxy

    kubectl -n kube-system get pod | grep kube-proxy | awk '{print $1}' | xargs kubectl -n kube-system delete pod

# 9.部署可视化管理UI

## 9.1 部署kuboard

    kubectl apply -f https://kuboard.cn/install-script/kuboard.yaml

## 9.2 获取登陆token

    echo $(kubectl -n kube-system get secret $(kubectl -n kube-system get secret | grep kuboard-user | awk '{print $1}') -o go-template='{{.data.token}}' | base64 -d)

## 9.3 访问Kuboard

http://worker节点IP:32567

---------

# 参考文档

- https://www.jianshu.com/p/64bb556a2006
- https://www.cnblogs.com/yx-book/p/14855450.html
- https://blog.csdn.net/weixin_44379843/article/details/125400358
- https://blog.csdn.net/mengshicheng1992/article/details/115659507
- https://blog.csdn.net/u014320421/article/details/118325544