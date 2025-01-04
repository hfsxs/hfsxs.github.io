---
title: Kubernetes集群部署
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2021-04-21 10:07:31
---

Kubernetes，意为舵手、飞行员，来源于希腊字母，是Google开源的工业级容器集群管理、编排平台，负责基于容器的应用部署、应用伸缩及应用管理，将后面8个字母缩写为K8s

# 逻辑架构

Kubernetes设计理念类似于Linux的分层架构，逻辑架构由内而外分为核心层、应用层、管理层、接口层及生态系统
  
- 核心层，Kubernetes最核心的功能，对外提供API构建高层的应用，对内提供插件式应用执行环境
- 应用层，部署（无状态应用、有状态应用、批处理任务、集群应用等）和路由（服务发现、DNS解析等）
- 管理层，系统度量（如基础设施、容器和网络的度量），自动化（如自动扩展、动态Provision等）以及策略管理（RBAC、Quota、PSP、NetworkPolicy等）
- 接口层，kubectl命令行工具、客户端SDK及集群组件
- 生态系统，在接口层之上的庞大容器集群管理调度的生态系统，可以划分为两类，即集群外部系统和集群内部系统，前者包含日志、监控、配置管理、CI/CD、Workflow、FaaS、OTS应用、ChatOps等，后者包含CRI、CNI、CVI、镜像仓库、Cloud Provider、集群自身的配置和管理等

# 功能组件

Kubernetes集群是典型的C/S二层架构，Master（主节点）作为中央控制节点，通过API从CLI（命令行界面）或UI（用户界面）接收输入操作，然后下发给相应的Node（工作节点）进行最终的执行

## 1.Master

主节点，控制集群工作，由四个核心组件组成，即API Server、Controller Manage、Scheduler及ETCD

### 1.1 API Server

集群内所有API资源对象的操作接口，用户与集群进行交互的入口，负责集群各个功能组件之间的通信，整个系统的数据总线和数据中心，具体实现方式是其余组件通过定时调用API Server的REST接口（get、list和watch）写入或读取集群所有对象所要维持的状态。此外，还提供认证、授权、访问控制、API注册和发现等功能

### 1.2 Controller Manage

控制管理器，是集群状态自动化维护的核心，管理集群各种控制器的运行，确保集群按预期目标工作，如故障检测、自动扩展、滚动更新等。集群的各类Controller通过API Server提供的接口实时监控集群中特定资源的状态变化，当发生故障导致某资源对象的状态发生变化时，将会尝试将其状态调整为期望的状态

### 1.3 Scheduler

调度器，用于资源的调度，接收来自API Server的请求，并将其分配给运行状况良好的节点。scheduler会对节点的质量进行排名，将Pod部署到最适合的节点。若没有合适的节点，则将Pod置于挂起状态，直到出现合适的节点

### 1.4 ETCD

键值存储系统，用于保存整个集群的状态，分布式存储所有集群数据的高可用数据库。存储整个集群的配置和状态，主节点从其读取节点和容器的状态参数，维护节点间的服务发现和配置共享

### 1.5  kubectl

客户端命令行工具，将接受的命令格式化后发送给API Server，作为整个系统的操作入口

## 2.Node

工作节点，运行业务负载，由三个核心组件组成，即kubelet、kube-proxy、container runtime

### 2.1 kubelet

内部代理，用于维护容器的生命周期，接收API Server发送来的任务并执行，如Pod、容器的创建与销毁，运行在每个工作节点，同时监视Pod状态，若不能正常运行，则向Master反馈，Master再基于该信息决定如何分配任务和资源以达到所需状态。此外，还负责Volume（CVI）和网络（CNI）的管理

### 2.2 kube-proxy

网络代理，用于为Service提供集群内部的服务发现和负载均衡，即为Service提供代理以供外部访问，运行在每个工作节点。Pod之间的访问请求会经过本机Proxy做转发，从而实现本地iptables和规则，以处理路由和流量负载均衡

### 2.3 Container runtime

即容器，用于镜像管理及Pod、容器的真正运行（CRI），如docker等，运行在每个工作节点

## 3.非核心组件
    
- kube-dns，用于整个集群的DNS服务
- Ingress Controller，用于为服务提供外网入口
- Heapster，用于提供资源监控
- Dashboard，用于提供GUI
- Federation，用于提供跨可用区的集群
- Fluentd-elasticsearch，用于提供集群日志采集、存储与查询

# 集群架构
  
- 172.16.100.100  master
- 172.16.100.180  node01
- 172.16.100.200  node02

---------

# 1.系统环境配置

## 1.1 配置hosts

    vi /etc/hosts


    172.16.100.100  master
    172.16.100.180  node01
    172.16.100.200  node02
 
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

# 2.Node节点部署docker

## 2.1 部署docker
 
## 2.2 部署镜像仓库

# 3.部署etcd集群

    sudo mkdir -p /opt/etcd/{bin,cfg,ssl}
    tar -xzvf etcd-v3.2.32-linux-amd64.tar.gz
    sudo cp etcd-v3.2.32-linux-amd64/etcd* /opt/etcd/bin

## 3.1 创建etcd集群认证证书
 
### 3.1.1 安装SSL证书签发工具cfssl

    sudo tar -xzvf cfssl.tar.gz -C /usr/local/bin
    mkdir -p ssl/etcd && cd ssl/etcd
    sudo chmod +x /usr/local/bin/cfssl*

### 3.1.2 创建CA配置文件，即证书生成策略，规定CA可以颁发哪种类型的证书

    vi ca-config.json


    {
      "signing": {
        "default": {
          "expiry": "87600h"
        },
        "profiles": {
          "www": {
             "expiry": "87600h",
             "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
          }
        }
      }
    }

### 3.1.3 创建CA证书签名请求配置文件
  
    vi ca-csr.json


    {
        "CN": "etcd CA",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
                "C": "CN",
                "L": "Beijing",
                "ST": "Beijing"
            }
        ]
    }

### 3.1.4 创建CA的私钥（ca-key.pem）、证书（ca.pem）及证书签名请求文件（ca.csr），用于交叉签名或重新签名

    cfssl gencert -initca ca-csr.json | cfssljson -bare ca

### 3.1.5 创建etcd集群证书签名请求配置文件

    vi server-csr.json


    {
        "CN": "etcd",
        "hosts": [
        "127.0.0.1",
        "172.16.100.100",
        "172.16.100.108",
        "172.16.100.120",
        "172.16.100.128",
        "172.16.100.150",
        "172.16.100.160",
        "172.16.100.180",
        "172.16.100.188",
        "172.16.100.200"
        ],
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
          {
            "C": "CN",
            "L": "BeiJing",
            "ST": "BeiJing"
          }
        ]
    }

### 3.1.6 创建etcd集群证书和私钥

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=www server-csr.json | cfssljson -bare server
    sudo cp *pem /opt/etcd/ssl

## 3.2 创建etcd配置文件

    sudo vi /opt/etcd/cfg/etcd.conf


    # 节点配置
    # 设置节点名称，集群中的唯一标识，不可重复
    ETCD_NAME="etcd01"
    # 设置数据存储目录
    ETCD_DATA_DIR="/var/lib/etcd/default.etcd"
    # 设置集群通信监听地址
    ETCD_LISTEN_PEER_URLS="https://172.16.100.100:2380"
    # 设置客户端访问监听地址
    ETCD_LISTEN_CLIENT_URLS="https://172.16.100.100:2379"

    # 集群配置
    # 设置集群通告地址
    ETCD_INITIAL_ADVERTISE_PEER_URLS="https://172.16.100.100:2380"
    # 设置客户端通告地址
    ETCD_ADVERTISE_CLIENT_URLS="https://172.16.100.100:2379"
    # 设置集群节点地址
    ETCD_INITIAL_CLUSTER="etcd01=https://172.16.100.100:2380,etcd02=https://172.16.100.180:2380,etcd03=https://172.16.100.200:2380"
    # 设置集群Token
    ETCD_INITIAL_CLUSTER_TOKEN="etcd-cluster"
    # 设置加入集群的当前状态，new为新集群，existing表示加入已有集群
    ETCD_INITIAL_CLUSTER_STATE="new"

---------

- 注：除集群节点地址外，其余节点的配置文件需修改成各自对应的信息

## 3.3 创建启动脚本

    sudo vi /lib/systemd/system/etcd.service


    [Unit]
    Description=Etcd Server
    After=network.target
    After=network-online.target
    Wants=network-online.target

    [Service]
    Type=notify
    EnvironmentFile=/opt/etcd/cfg/etcd.conf
    ExecStart=/opt/etcd/bin/etcd \
    --cert-file=/opt/etcd/ssl/server.pem \
    --key-file=/opt/etcd/ssl/server-key.pem \
    --peer-cert-file=/opt/etcd/ssl/server.pem \
    --peer-key-file=/opt/etcd/ssl/server-key.pem \
    --trusted-ca-file=/opt/etcd/ssl/ca.pem \
    --peer-trusted-ca-file=/opt/etcd/ssl/ca.pem 
    Restart=on-failure
    LimitNOFILE=65536

    [Install]
    WantedBy=multi-user.target

## 3.4 分发etcd的可执行文件、配置文件、认证证书和启动脚本到其余节点
  
    sudo scp -r /opt/etcd node01:/opt
    sudo scp -r /opt/etcd node02:/opt

    sudo scp /lib/systemd/system/etcd.service node01:/lib/systemd/system
    sudo scp /lib/systemd/system/etcd.service node02:/lib/systemd/system

## 3.5 启动etcd集群
  
    sudo systemctl daemon-reload
    sudo systemctl start etcd.service
    sudo systemctl enable etcd.service

## 3.6 查看etcd集群状态
  
    sudo /opt/etcd/bin/etcdctl --ca-file=/opt/etcd/ssl/ca.pem --cert-file=/opt/etcd/ssl/server.pem --key-file=/opt/etcd/ssl/server-key.pem \
    --endpoints="https://172.16.100.100:2379,https://172.16.100.180:2379,https://172.16.100.200:2379" cluster-health

# 4.部署CNI网络插件Flannel

    sudo mkdir -p /opt/flanneld/{bin,ssl}
    tar -xzvf flannel-v0.12.0-linux-amd64.tar.gz -C /opt/flanneld/bin
    cp /opt/etcd/ssl/*pem /opt/flanneld/ssl

## 4.1 etcd集群写入pod网段
  
    /opt/etcd/bin/etcdctl \
    --endpoints="https://172.16.100.100:2379,https://172.16.100.180:2379,https://172.16.100.200:2379" \
    --ca-file=/opt/flanneld/ssl/ca.pem --cert-file=/opt/flanneld/ssl/server.pem --key-file=/opt/flanneld/ssl/server-key.pem \
    set /kubernetes/network/config '{"Network":"172.30.0.0/16","SubnetLen": 24,"Backend": {"Type": "vxlan"}}'

---------

- 注：该步骤只需执行一次
  
## 4.2 创建flanneld启动脚本
  
    sudo vi /lib/systemd/system/flanneld.service


    [Unit]
    Description=Flanneld overlay address etcd agent
    After=network.target
    After=network-online.target
    Wants=network-online.target
    After=etcd.service
    Before=docker.service

    [Service]
    Type=notify
    ExecStart=/opt/flanneld/bin/flanneld \
      -etcd-cafile=/opt/flanneld/ssl/ca.pem \
      -etcd-certfile=/opt/flanneld/ssl/server.pem \
      -etcd-keyfile=/opt/flanneld/ssl/server-key.pem \
      -etcd-endpoints=https://172.16.100.100:2379,https://172.16.100.180:2379,https://172.16.100.200:2379 \
      -etcd-prefix=/kubernetes/network
    ExecStartPost=/opt/flanneld/bin/mk-docker-opts.sh -k DOCKER_NETWORK_OPTIONS -d /run/flannel/docker
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target
    RequiredBy=docker.service

## 4.3 启动flanneld
  
    sudo systemctl daemon-reload
    sudo systemctl start flanneld.service
    sudo systemctl enable flanneld.service

## 4.4 检查分配给各flanneld的Pod网段信息
  
    /opt/etcd/bin/etcdctl \
    --endpoints="https://172.16.100.100:2379,https://172.16.100.180:2379,https://172.16.100.200:2379" \
    --ca-file=/opt/flanneld/ssl/ca.pem --cert-file=/opt/flanneld/ssl/server.pem \
    --key-file=/opt/flanneld/ssl/server-key.pem ls /kubernetes/network/subnets
    /kubernetes/network/subnets/172.30.73.0-24

    /opt/etcd/bin/etcdctl \
    --endpoints="https://172.16.100.100:2379,https://172.16.100.180:2379,https://172.16.100.200:2379" \
    --ca-file=/opt/flanneld/ssl/ca.pem --cert-file=/opt/flanneld/ssl/server.pem \
    --key-file=/opt/flanneld/ssl/server-key.pem get /kubernetes/network/subnets/172.30.73.0-24
    {"PublicIP":"172.16.100.100","BackendType":"vxlan","BackendData":{"VtepMAC":"d6:b6:62:38:84:52"}}

## 4.5 配置docker启动，指定网络参数为flannel
 
    sed -i '/ExecStart/i EnvironmentFile=/run/flannel/docker' /lib/systemd/system/docker.service
    sed -i 's/dockerd/dockerd $DOCKER_NETWORK_OPTIONS/g' /lib/systemd/system/docker.service
    systemctl daemon-reload && systemctl restart docker.service 

## 4.6 验证flanneld配置是否生效
 
    ip addr | grep flannel | grep inet

    inet 172.30.71.0/32 scope global flannel.1

## 4.7 分发flanneld的可执行文件、认证证书、启动脚本到其余节点
 
    ssh node01 mkdir -p /opt/flanneld/{bin,ssl}
    ssh node02 mkdir -p /opt/flanneld/{bin,ssl}

    scp /opt/flanneld/bin/* node01:/opt/flanneld/bin
    scp /opt/flanneld/bin/* node02:/opt/flanneld/bin

    scp /opt/flanneld/ssl/* node01:/opt/flanneld/ssl
    scp /opt/flanneld/ssl/* node02:/opt/flanneld/ssl

    scp /lib/systemd/system/flanneld.service node01:/lib/systemd/system
    scp /lib/systemd/system/flanneld.service node02:/lib/systemd/system

# 5.部署Master

## 5.1 部署kube-apiserver

    wget https://dl.k8s.io/v1.20.15/kubernetes-server-linux-amd64.tar.gz
    tar -xzvf kubernetes-server-linux-amd64.tar.gz
    sudo mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs} 
    sudo cp kubernetes/server/bin/{kube-apiserver,kube-controller-manager,kube-scheduler} /opt/kubernetes/bin
    sudo cp kubernetes/server/bin/kubectl /usr/bin

### 5.1.1 创建apiserver证书
 
    mkdir -p ssl/k8s && cd ssl/k8s
 
#### 5.1.1.1 创建CA配置文件
  
    vi ca-config.json


    {
      "signing": {
        "default": {
          "expiry": "87600h"
        },
        "profiles": {
          "kubernetes": {
             "expiry": "87600h",
             "usages": [
                "signing",
                "key encipherment",
                "server auth",
                "client auth"
            ]
          }
        }
      }
    }

#### 5.1.1.2 创建CA证书签名请求配置文件
  
    vi ca-csr.json


    {
        "CN": "kubernetes",
        "key": {
            "algo": "rsa",
            "size": 2048
        },
        "names": [
            {
              "C": "CN",
              "L": "Beijing",
              "ST": "Beijing",
              "O": "k8s",
              "OU": "System"
            }
        ]
    }

#### 5.1.1.3 创建CA的私钥（ca-key.pem）、证书（ca.pem）及证书签名请求（ca.csr）

    cfssl gencert -initca ca-csr.json | cfssljson -bare ca -

#### 5.1.1.4 创建apiserver证书签名请求配置文件

    vi server-csr.json


    {
      "CN": "kubernetes",
      "hosts": [
      "127.0.0.1",
      "10.254.0.1",
      "172.16.100.100",
      "172.16.100.108",
      "172.16.100.120",
      "172.16.100.128",
      "172.16.100.150",
      "172.16.100.160",
      "172.16.100.180",
      "172.16.100.188",
      "172.16.100.200",
      "kubernetes",
      "kubernetes.default",
      "kubernetes.default.svc",
      "kubernetes.default.svc.cluster",
      "kubernetes.default.svc.cluster.local"
    ],
      "key": {
          "algo": "rsa",
          "size": 2048
        },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing",
          "ST": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }

---------

- 注：hosts字段IP为集群所有Master/Node/LB/VIP的IP，为方便后期扩容可将所有预留IP都包含进去

#### 5.1.1.5 创建apiserver认证证书
  
    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes server-csr.json | cfssljson -bare server
    sudo cp *.pem /opt/kubernetes/ssl

### 5.1.2 创建kube-apiserver配置文件
  
    sudo vi /opt/kubernetes/cfg/kube-apiserver.conf


    KUBE_APISERVER_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --etcd-servers=https://172.16.100.100:2379,https://172.16.100.180:2379,https://172.16.100.200:2379 \
    --bind-address=172.16.100.100 \
    --secure-port=6443 \
    --advertise-address=172.16.100.100 \
    --allow-privileged=true \
    --service-cluster-ip-range=10.254.0.0/24 \
    --enable-admission-plugins=NamespaceLifecycle,LimitRanger,ServiceAccount,ResourceQuota,NodeRestriction,DefaultStorageClass \
    --authorization-mode=RBAC,Node \
    --enable-bootstrap-token-auth=true \
    --token-auth-file=/opt/kubernetes/cfg/token.csv \
    --service-node-port-range=30000-32767 \
    --kubelet-client-certificate=/opt/kubernetes/ssl/server.pem \
    --kubelet-client-key=/opt/kubernetes/ssl/server-key.pem \
    --tls-cert-file=/opt/kubernetes/ssl/server.pem  \
    --tls-private-key-file=/opt/kubernetes/ssl/server-key.pem \
    --client-ca-file=/opt/kubernetes/ssl/ca.pem \
    --service-account-key-file=/opt/kubernetes/ssl/ca-key.pem \
    --service-account-signing-key-file=/opt/kubernetes/ssl/server-key.pem \
    --service-account-issuer=https://kubernetes.default.svc.cluster.local \
    --etcd-cafile=/opt/etcd/ssl/ca.pem \
    --etcd-certfile=/opt/etcd/ssl/server.pem \
    --etcd-keyfile=/opt/etcd/ssl/server-key.pem \
    --requestheader-client-ca-file=/opt/kubernetes/ssl/ca.pem \
    --proxy-client-cert-file=/opt/kubernetes/ssl/server.pem \
    --proxy-client-key-file=/opt/kubernetes/ssl/server-key.pem \
    --requestheader-allowed-names=kubernetes \
    --requestheader-extra-headers-prefix=X-Remote-Extra- \
    --requestheader-group-headers=X-Remote-Group \
    --requestheader-username-headers=X-Remote-User \
    --enable-aggregator-routing=true \
    --audit-log-maxage=30 \
    --audit-log-maxbackup=3 \
    --audit-log-maxsize=100 \
    --audit-log-path=/opt/kubernetes/logs/k8s-audit.log"

---------

- advertise-address，集群Apiserver通告地址，若未指定或为空则为bind-address地址
- service-cluster-ip-range，集群内部虚拟网络service的IP地址池，也即为pod的统一访问IP

### 5.1.3 创建token文件

    sudo vi /opt/kubernetes/cfg/token.csv


    5aad5e038ca05f6bcb256c3118e8366c,kubelet-bootstrap,10001,"system:node-bootstrapper"

---------

- 注：token文件用于启用TLS Bootstrapping机制，简化了Node节点kubelet和kube-proxy与kube-apiserver的通信认证流程，其格式为“token，用户名，UID，用户组”。token可用如下命令随机生成，head -c 16 /dev/urandom | od -An -t x | tr -d ' '

### 5.1.4 创建启动脚本

    sudo vi /lib/systemd/system/kube-apiserver.service


    [Unit]
    Description=Kubernetes API Server
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    EnvironmentFile=/opt/kubernetes/cfg/kube-apiserver.conf
    ExecStart=/opt/kubernetes/bin/kube-apiserver $KUBE_APISERVER_OPTS
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

### 5.1.5 启动kube-apiserver
  
    sudo systemctl daemon-reload
    sudo systemctl start kube-apiserver
    sudo systemctl enable kube-apiserver

## 5.2 部署kube-controller-manager
 
### 5.2.1 创建配置文件

    sudo vi /opt/kubernetes/cfg/kube-controller-manager.conf


    KUBE_CONTROLLER_MANAGER_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --leader-elect=true \
    --bind-address=127.0.0.1 \
    --allocate-node-cidrs=true \
    --cluster-cidr=172.30.0.0/16 \
    --service-cluster-ip-range=10.254.0.0/24 \
    --kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig \
    --cluster-signing-cert-file=/opt/kubernetes/ssl/ca.pem \
    --cluster-signing-key-file=/opt/kubernetes/ssl/ca-key.pem  \
    --root-ca-file=/opt/kubernetes/ssl/ca.pem \
    --service-account-private-key-file=/opt/kubernetes/ssl/ca-key.pem \
    --cluster-signing-duration=87600h0m0s"

---------

- cluster-cidr，pod IP地址池
- service-cluster-ip-range，与Apiserver保持一致
- experimental-cluster-signing-duratio，签名证书有效期，1.19版本之后用--cluster-signing-duration=87600h0m0s

### 5.2.2 创建kube-controller-manager集群认证令牌

#### 5.2.2.1 创建kube-controller-manager证书签名请求配置文件

    vi kube-controller-manager-csr.json


    {
      "CN": "system:kube-controller-manager",
      "hosts": [],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing", 
          "ST": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }

#### 5.2.2.2 创建kube-controller-manager证书

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-controller-manager-csr.json | cfssljson -bare kube-controller-manager

#### 5.2.2.3 设置环境变量

    KUBE_APISERVER="https://172.16.100.100:6443"

#### 5.2.2.4 设置集群参数

    kubectl config set-cluster kubernetes \
      --certificate-authority=/opt/kubernetes/ssl/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig

#### 5.2.2.5 设置客户端认证参数
  
    kubectl config set-credentials kube-controller-manager \
      --client-certificate=kube-controller-manager.pem \
      --client-key=kube-controller-manager-key.pem \
      --embed-certs=true \
      --kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig

#### 5.2.2.6 设置上下文参数
  
    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kube-controller-manager \
      --kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig

#### 5.2.2.7 切换上下文
  
    kubectl config use-context default --kubeconfig=/opt/kubernetes/cfg/kube-controller-manager.kubeconfig

### 5.2.3 创建启动脚本
  
    sudo vi /usr/lib/systemd/system/kube-controller-manager.service


    [Unit]
    Description=Kubernetes Controller Manager
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    EnvironmentFile=/opt/kubernetes/cfg/kube-controller-manager.conf
    ExecStart=/opt/kubernetes/bin/kube-controller-manager $KUBE_CONTROLLER_MANAGER_OPTS
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

### 5.2.4 启动kube-controller-manager
  
    sudo systemctl daemon-reload
    sudo systemctl start kube-controller-manager
    sudo systemctl enable kube-controller-manager

## 5.3 部署kube-scheduler

### 5.3.1 创建配置文件

    sudo vi /opt/kubernetes/cfg/kube-scheduler.conf


    KUBE_SCHEDULER_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --leader-elect \
    --kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig \
    --bind-address=127.0.0.1"

### 5.3.2 创建kube-scheduler集群认证令牌

#### 5.3.2.1 创建kube-scheduler证书签名请求配置文件

    vi kube-scheduler-csr.json


    {
      "CN": "system:kube-scheduler",
      "hosts": [],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing", 
          "ST": "BeiJing",
          "O": "system:masters",
          "OU": "System"
        }
      ]
     }

#### 5.3.2.2 创建kube-scheduler证书

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-scheduler-csr.json | cfssljson -bare kube-scheduler

#### 5.3.2.3 设置环境变量

    KUBE_APISERVER="https://172.16.100.100:6443"

#### 5.3.2.4 设置集群参数

    kubectl config set-cluster kubernetes \
      --certificate-authority=/opt/kubernetes/ssl/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig

#### 5.3.2.5 设置客户端认证参数

    kubectl config set-credentials kube-scheduler \
      --client-certificate=kube-scheduler.pem \
      --client-key=kube-scheduler-key.pem \
      --embed-certs=true \
      --kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig

#### 5.3.2.6 设置上下文参数

    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kube-scheduler \
      --kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig

#### 5.3.2.7 切换上下文

    kubectl config use-context default --kubeconfig=/opt/kubernetes/cfg/kube-scheduler.kubeconfig

### 5.3.3 创建启动脚本
  
    sudo vi /usr/lib/systemd/system/kube-scheduler.service


    [Unit]
    Description=Kubernetes Scheduler
    Documentation=https://github.com/kubernetes/kubernetes

    [Service]
    EnvironmentFile=/opt/kubernetes/cfg/kube-scheduler.conf
    ExecStart=/opt/kubernetes/bin/kube-scheduler $KUBE_SCHEDULER_OPTS
    Restart=on-failure

    [Install]
    WantedBy=multi-user.target

### 5.3.4 启动kube-scheduler
  
    sudo systemctl daemon-reload
    sudo systemctl start kube-scheduler
    sudo systemctl enable kube-scheduler

## 5.4 部署kubectl
 
### 5.4.1 创建kubectl集群认证证书

#### 5.4.1.1 创建证书签名请求配置文件
  
    vi admin-csr.json


    {
      "CN": "admin",
      "hosts": [],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing",
          "ST": "BeiJing",
          "O": "system:masters",
          "OU": "System"
        }
      ]
    }

#### 5.4.1.2 创建kubectl证书签名

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes admin-csr.json | cfssljson -bare admin
    sudo cp admin*pem /opt/kubernetes/ssl

#### 5.4.1.3 设置环境变量

    sudo mkdir -p /root/.kube

    KUBE_CONFIG="/root/.kube/config"
    KUBE_APISERVER="https://172.16.100.100:6443"

#### 5.4.1.4 设置集群参数

    sudo kubectl config set-cluster kubernetes \
      --certificate-authority=/opt/kubernetes/ssl/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=${KUBE_CONFIG}

#### 5.4.1.5 设置客户端认证参数
  
    sudo kubectl config set-credentials cluster-admin \
      --client-certificate=/opt/kubernetes/ssl/admin.pem \
      --client-key=/opt/kubernetes/ssl/admin-key.pem \
      --embed-certs=true \
      --kubeconfig=${KUBE_CONFIG}
  
#### 5.4.1.6 设置上下文参数
  
    sudo kubectl config set-context default \
      --cluster=kubernetes \
      --user=cluster-admin \
      --kubeconfig=${KUBE_CONFIG}

#### 5.4.1.7 设置默认上下文
  
    sudo kubectl config use-context default --kubeconfig=${KUBE_CONFIG}
  
### 5.4.2 配置kubectl命令补全功能
  
    echo "source <(kubectl completion bash)" >> /root/.bash_profile
    source /root/.bash_profile 

### 5.4.3 授权kubelet-bootstrap用户允许请求证书
  
    kubectl create clusterrolebinding kubelet-bootstrap \
    --clusterrole=system:node-bootstrapper \
    --user=kubelet-bootstrap

## 5.5 查看集群状态
 
    kubectl get cs

# 6.部署Node

    ssh node01 mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs}
    ssh node02 mkdir -p /opt/kubernetes/{bin,cfg,ssl,logs}

    sudo scp kubernetes/server/bin/{kubelet,kube-proxy} node01:/opt/kubernetes/bin
    sudo scp kubernetes/server/bin/{kubelet,kube-proxy} node02:/opt/kubernetes/bin

    sudo scp /opt/kubernetes/ssl/* node01:/opt/kubernetes/ssl
    sudo scp /opt/kubernetes/ssl/* node02:/opt/kubernetes/ssl

    sudo yum install -y ipvsadm ipset
    sudo apt install -y ipvsadm ipset

## 6.1 部署kubelet
 
### 6.1.1 创建配置文件

    sudo vi /opt/kubernetes/cfg/kubelet.conf


    KUBELET_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --hostname-override=node01 \
    --kubeconfig=/opt/kubernetes/cfg/kubelet.kubeconfig \
    --bootstrap-kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig \
    --config=/opt/kubernetes/cfg/kubelet-config.yml \
    --cert-dir=/opt/kubernetes/ssl \
    --pod-infra-container-image=hub.sword.com/library/pause"

---------

- hostname-override，node节点主机名或IP
- pod-infra-container-image，集群默认镜像拉取仓库

### 6.1.2 创建参数文件

    sudo vi /opt/kubernetes/cfg/kubelet-config.yml


    kind: KubeletConfiguration
    apiVersion: kubelet.config.k8s.io/v1beta1
    address: 0.0.0.0
    port: 10250
    readOnlyPort: 10255
    cgroupDriver: cgroupfs
    clusterDNS:
    - 10.254.0.2
    clusterDomain: cluster.local 
    failSwapOn: false
    authentication:
      anonymous:
        enabled: false
      webhook:
        cacheTTL: 2m0s
        enabled: true
      x509:
        clientCAFile: /opt/kubernetes/ssl/ca.pem 
    authorization:
      mode: Webhook
      webhook:
        cacheAuthorizedTTL: 5m0s
        cacheUnauthorizedTTL: 30s
    evictionHard:
      imagefs.available: 15%
      memory.available: 100Mi
      nodefs.available: 10%
      nodefs.inodesFree: 5%
    maxOpenFiles: 1000000
    maxPods: 110

### 6.1.3 创建kubelet集群认证令牌
  
#### 6.1.3.1 设置环境变量

    KUBE_APISERVER="https://172.16.100.100:6443"
    TOKEN="5aad5e038ca05f6bcb256c3118e8366c"

#### 6.1.3.2 设置集群参数
   
    kubectl config set-cluster kubernetes \
      --certificate-authority=/opt/kubernetes/ssl/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#### 6.1.3.3 设置客户端认证参数
   
    kubectl config set-credentials kubelet-bootstrap \
      --token=${TOKEN} \
      --kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#### 6.1.3.4 设置上下文参数
   
    kubectl config set-context default \
      --cluster=kubernetes \
      --user="kubelet-bootstrap" \
      --kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

#### 6.1.3.5 切换上下文

    kubectl config use-context default --kubeconfig=/opt/kubernetes/cfg/bootstrap.kubeconfig

    sudo scp /opt/kubernetes/cfg/bootstrap.kubeconfig node01:/opt/kubernetes/cfg
    sudo scp /opt/kubernetes/cfg/bootstrap.kubeconfig node02:/opt/kubernetes/cfg

### 6.1.4 创建启动脚本
  
    sudo vi /lib/systemd/system/kubelet.service


    [Unit]
    Description=Kubernetes Kubelet
    After=docker.service

    [Service]
    EnvironmentFile=/opt/kubernetes/cfg/kubelet.conf
    ExecStart=/opt/kubernetes/bin/kubelet $KUBELET_OPTS
    Restart=on-failure
    LimitNOFILE=65536

    [Install]
    WantedBy=multi-user.target

### 6.1.5 启动kubelet
  
    sudo systemctl daemon-reload
    sudo systemctl start kubelet.service
    sudo systemctl enable kubelet
   
## 6.2 审批请求节点加入集群

### 6.2.1 查看请求签名的Node
  
    kubectl get csr
    NAME                                                   AGE   SIGNERNAME                                    REQUESTOR           CONDITION
    node-csr-iWWLUr2rvtR2-8JoxHNUubpq0ui4v5aDl5hidlYbejc   9s    kubernetes.io/kube-apiserver-client-kubelet   kubelet-bootstrap   Pending
  
### 6.2.2 批准kubelet证书申请
  
    kubectl certificate approve node-csr-iWWLUr2rvtR2-8JoxHNUubpq0ui4v5aDl5hidlYbejc

    certificatesigningrequest.certificates.k8s.io/node-csr-iWWLUr2rvtR2-8JoxHNUubpq0ui4v5aDl5hidlYbejc approved

## 6.3 查看集群中的Node状态
 
    kubectl get node

    NAME     STATUS   ROLES    AGE   VERSION
    node01   Ready    <none>   8s    v1.19.3

### 6.3.2 Node节点设置标签
  
    kubectl label nodes node01 node-role.kubernetes.io/worker01=
    kubectl label nodes node01 node-role.kubernetes.io/etcd-1=
    # 删除标签etcd-1
    kubectl label nodes node01 node-role.kubernetes.io/etcd-1-

### 6.3.3 分发kubelet的配置文件、参数文件、认证证书、认证令牌、启动脚本到其余节点，并加入集群

## 6.4 部署kube-proxy

### 6.4.1 创建配置文件

    sudo vi /opt/kubernetes/cfg/kube-proxy.conf


    KUBE_PROXY_OPTS="--logtostderr=false \
    --v=2 \
    --log-dir=/opt/kubernetes/logs \
    --hostname-override=node01 \
    --proxy-mode=ipvs \
    --cluster-cidr=172.30.0.0/16 \
    --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig"

---------

- hostname-override，node主机名或IP
- proxy-mode，代理模式，默认为iptables
- cluster-cidr，pod地址池，与controller-manager保持一致

### 6.4.2 创建kube-proxy集群认证证书

#### 6.4.2.1 创建kube-proxy证书签名请求配置文件

    vi kube-proxy-csr.json


    {
      "CN": "system:kube-proxy",
      "hosts": [],
      "key": {
        "algo": "rsa",
        "size": 2048
      },
      "names": [
        {
          "C": "CN",
          "L": "BeiJing",
          "ST": "BeiJing",
          "O": "k8s",
          "OU": "System"
        }
      ]
    }

#### 6.4.2.2 创建kube-proxy证书

    cfssl gencert -ca=ca.pem -ca-key=ca-key.pem -config=ca-config.json -profile=kubernetes kube-proxy-csr.json | cfssljson -bare kube-proxy
    cp kube-proxy*pem /opt/kubernetes/ssl

#### 6.4.2.3 设置环境变量
   
    KUBE_APISERVER="https://172.16.100.100:6443"

#### 6.4.2.4 设置集群参数
   
    kubectl config set-cluster kubernetes \
      --certificate-authority=/opt/kubernetes/ssl/ca.pem \
      --embed-certs=true \
      --server=${KUBE_APISERVER} \
      --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

#### 6.4.2.5 设置客户端认证参数
   
    kubectl config set-credentials kube-proxy \
      --client-certificate=/opt/kubernetes/ssl/kube-proxy.pem \
      --client-key=/opt/kubernetes/ssl/kube-proxy-key.pem \
      --embed-certs=true \
      --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

#### 6.4.2.6 设置上下文参数
   
    kubectl config set-context default \
      --cluster=kubernetes \
      --user=kube-proxy \
      --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

#### 6.4.2.7 切换上下文
   
    kubectl config use-context default --kubeconfig=/opt/kubernetes/cfg/kube-proxy.kubeconfig

### 6.4.3 创建启动脚本

    sudo vi /lib/systemd/system/kube-proxy.service


    [Unit]
    Description=Kubernetes Proxy
    After=network.target

    [Service]
    EnvironmentFile=/opt/kubernetes/cfg/kube-proxy.conf
    ExecStart=/opt/kubernetes/bin/kube-proxy $KUBE_PROXY_OPTS
    Restart=on-failure
    LimitNOFILE=65536

    [Install]
    WantedBy=multi-user.target

### 6.4.4 启动kube-proxy
  
    sudo systemctl daemon-reload
    sudo systemctl start kube-proxy.service
    sudo systemctl enable kube-proxy.service

### 6.4.5 分发kube-proxy的配置文件、认证证书、认证令牌、启动脚本到其余节点

# 7.部署测试pod

## 7.1 创建资源配置清单

    vi test.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: sword618/nginx
        imagePullPolicy: IfNotPresent
      restartPolicy: Always
  
# 7.2 部署测试pod
 
     kubectl apply -f test.yaml
  
## 7.3 检查pod状态

    kubectl get pods -o wide

# 8.部署服务发现组件coredns

## 8.1 下载配置文件

    wget https://github.com/coredns/deployment/blob/master/kubernetes/coredns.yaml.sed -O coredns.yaml

## 8.2 修改配置文件DNS服务器地址

- clusterIP，对应kubelet的clusterDNS，这里改为10.254.0.2

## 8.3 部署coredns

    kubectl apply -f coredns.yaml

---------

# 参考文档

- https://blog.csdn.net/ljx1528/article/details/108465272
- https://blog.csdn.net/weixin_47748185/article/details/113651747
- https://blog.csdn.net/wtl1992/article/details/121187506
- https://www.cnblogs.com/bixiaoyu/p/11720864.html
- https://blog.csdn.net/jato333/article/details/123956783
- https://blog.csdn.net/guijianchouxyz/article/details/115585456