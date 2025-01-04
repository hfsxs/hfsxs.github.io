---
title: Docker的安装与配置
categories:
  - 工作
tags:
  - Linux
  - Docker
  - 容器
  - 云计算
date: 2020-03-18 15:55:57
---

Docker，由go语言基于是Linux容器（LXC）等技术开发的开源应用容器引擎，致力于实现轻量级的操作系统虚拟化解决方案，是当前最热门的容器化技术之一。相比于传统的虚拟化技术，容器是在操作系统层面上实现的虚拟化，直接复用本地主机的操作系统，而传统的虚拟化方式则是在硬件层面实现

---------
  
### docker与虚拟机  
  
- 两者都是虚拟化资源管理技术，是将计算机的各种实体资源，如服务器、网络、内存等抽象转化后呈现出来，使用户以更好的方式来应用这些资源。虚拟化目标往往是为了在同一个主机上运行多个系统或者应用，从而提高资源的利用率，降低成本，方便管理及容错容
  
- 虚拟机是在硬件层面实现虚拟化，需要有额外的虚拟机管理应用和虚拟机操作系统，运行的是完整的操作系统。虚拟机擅长于彻底隔离整个运行环境，如云服务提供商通常采用虚拟机技术隔离不同的用户

- docker容器技术是在操作系统层面上实现虚拟化，运行的是不完整的操作系统当然也能运行完整的操作系统，通常用于隔离不同的应用，如前端、后端及数据库

---------

简单来说，虚拟机是虚拟出一台服务器来运行应用程序，docker只是虚拟出了保障应用程序的运行所需的环境
  
### 体系架构
  
docker是典型的C/S架构，其中docker daemon作为server端接受client的请求，然后进行处理，如容器的创建、运行、分发。两者可以运行在一个机器上，也可通过socket或者RESTful API通信

- docker daemon，即docker守护进程，一般在宿主主机后台运行，用户并不直接和守护进程进行交互，而是通过 Docker client间接和其通信

- Docker client，即docker客户端，实际是docker的二进制程序，是用户与 Docker 交互方式，接收用户指令并且与后台的docker守护进程通信

---------
  
### 底层实现
  
docker底层的两个核心技术是Namespaces和Control groups
  
##### 1.Namespaces，即命名空间，用于容器资源的隔离  
  
- pid namespace，进程隔离，不同namespace中可以有相同pid。所有LXC进程在docker中的父进程为docker进程，每个lxc进程具有不同的namespace

- net namespace，网络隔离，虽然pid namespace实现了进程的隔离，但网络端口还是共享宿主机端口，每个net namespace有独立的network、devices、IP addresses、IP routing tables、/proc/net等目录，从而实现了容器的网络隔离。docker默认采用veth的方式将容器中的虚拟网卡同宿主机上的docker bridge:docker0相连接

- ipc namespace，进程通信隔离，容器间进程交互还是采用linux常见的进程间交互方法 (interprocess communication，即IPC)，包括常见的信号量、消息队列和共享内存，容器进程间的交互实际上还是宿主机上具有相同pid namespace中的进程间交互

- mnt namespace，文件系统隔离，类似chroot，将一个进程放到一个特定的目录执行。mnt namespace允许不同namespace的进程看到不同的文件结构，这样每个namespace中的进程所看到的文件目录就被隔离开了。在容器里看到的文件系统就是一个完整的linux系统，有/etc、/lib等，通过chroot来实现

- uts namespace，UNIX分时隔离，即UNIX Time-sharing System，允许每个容器拥有独立的hostname和domain name，使其在网络上可以被视作一个独立的节点而非宿主机上的一个进程

- user namespace，用户隔离，允许每个容器可以有不同的user和group id，容器内部的用户是独立的存在，可以用于在容器内部执行程序而不是一定要用宿主机上的用户

---------

#### 2.cgroups，Control groups，即控制组，用于资源的配额与度量  
  
Namespaces实现了容器操作系统层的隔离，对外展现出一种独立计算机的能力，但不同的namespace之间资源还是会相互竞争，这就需要类似ulimit来管理每个容器所能使用的资源，控制组就是用于实现这个功能  

### 核心概念  

- 镜像，images，只读的模版，类似于虚拟机的镜像，用于创建容器  
- 容器，container，由镜像创建的可运行实例，类似于linux系统环境，用于运行和隔离应用程序  
- 仓库，repository，镜像的集中存放地，分为公共仓库和私有仓库，多个仓库组成仓库注册服务器

---------

# 1.安装docker  
  
    # sudo apt-get update && sudo apt-get install -y docker.io  
    # curl -fsSL https://get.docker.com -o get-docker.sh && sh get-docker.sh  
  
    tar -xvf docker-19.03.1.tgz  
    sudo cp docker/* /usr/bin 
  
# 2.配置docker仓库加速器
  
    sudo mkdir -p /etc/docker
    sudo vi /etc/docker/daemon.json  
  

    {  
      "registry-mirrors": [  
      "https://registry.docker-cn.com",  
      "https://docker.mirrors.ustc.edu.cn"  
      ]  
    }  
  
# 3.创建docker服务启动脚本  
  
    sudo vi /lib/systemd/system/docker.service  
  
  
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
  
# 4.启动docker  
  
    sudo systemctl daemon-reload  
    sudo systemctl start docker  
    sudo systemctl enable docker  
  
# 5.拉取镜像  
  
    # 官方公共镜像仓库中搜索nginx镜像  
    sudo docker search nginx  
  
    # 拉取nginx镜像到本地  
    sudo docker pull nginx  
  
    # 查看本地镜像  
    sudo docker images
  
# 6.创建容器  
  
    # 创建nginx容器实例，使之后台运行，暴露80端口  
    sudo docker run --name nginx -p 80:80 -d nginx  
  
    # 查看所有容器实例  
    sudo docker ps -a  
  
    # 查看nginx实例日志  
    sudo docker logs nginx