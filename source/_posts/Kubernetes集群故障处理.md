---
title: Kubernetes集群故障处理
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2023-01-30 12:25:53
---

# 1.worker节点重启后一直notready状态

## 故障背景

某个worker节点服务器重启，重启后处于notready状态

## 故障现象

集群master节点正常，docker运行正常，机器负载正常，kubelet反复启动

## 故障原因

刚接触kubernets不太熟悉，排查半天不得要领，直到查看kubelet日志发现有报错：”Failed to run kubelet” err=”failed to run Kubelet: misconfiguration: kubelet cgroup driver: "systemd" is different from docker cgroup driver:"cgroupfs"“，百度后是由docker默认的cgroup驱动cgroupfs与kubernets默认的驱动systemd不一致所导致，将docker驱动配置为systemd，两者保持一致即可

## 解决方案

### 1.配置docker的cgroup驱动为systemd

    
    
    sudo vi /etc/docker/daemon.json
    
    
    {
      "exec-opts": ["native.cgroupdriver=systemd"],
      "registry-mirrors": ["https://10.254.100.200"]
    }
    

### 2.重启docker
    
    sudo systemctl restart docker.service
    
---------

## 参考文档

- https://bbs.deepin.org/zh/post/198565
- https://blog.csdn.net/qq_45034687/article/details/129022342

# 2.POD启动失败

## 故障背景

客户要求集群新加一批机器，node节点添加正常，下午集中监控告警一批POD反复重启

## 故障现象

1.重启的POD状态为CrashLoopBackOff，退出码为139，且都是同一镜像拉起的容器  
2.只有调度到新加入的机器才会出现异常，且手动起容器也不行，容器也无日志。其他机器运行正常

## 故障原因

问题比较奇怪，镜像一直能正常拉起容器，证明镜像没问题，但在新机器就不行，推翻了这个结论。一开始感觉无从下手，有用的信息就只有退出码，程序也不复杂，其实就是一个java程序。百度139的退出码，可能是代码问题，或是基础镜像问题，在其他机器上能正常运行即可排除代码问题。接下来排查基础镜像，发现镜像基于centos6构建，尝试将基础镜像换成centos7构建后即正常运行

## 根因探究

根本原因其实是基础镜像低于2.14版本的glibc所采用的vsyscall内核调用机制由于风险过多，新的内核已经弃用，以可模拟兼容vsyscall的vDSO机制代替，由此产生报错

## 解决方案

将基础镜像换成centos7重新构建即可

---------

## 参考文档

- https://www.qedev.com/linux/340487.html
- https://blog.csdn.net/hakula007/article/details/125786395
- https://help.aliyun.com/document_detail/154067.html?spm=a2c6h.12873639.0.0.5b1224a46IyNve

# 3.文件上传失败报错

## 故障背景

转码业务的源数据来源于客户的媒资系统，通过FTP定时扫描获取，客户手动上传需求较少，前期规划与测试可满足平常的业务需求

## 故障现象

手动上传视频文件失败，测试发现报错信息为：413 Request Entity Too Large

## 故障原因

初步判断为前端代理nginx的client_max_body_size参数设置过小导致，更改为更大的值后还是报错。因为nginx的后端代理地址为ingress地址，原因即为nginx-ingress-controller配置文件client_max_body_size参数设置过小导致，调大即可

## 解决方案

    kubectl -n ingress-nginx edit configmaps ingress-nginx-controller
    
    
    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-custom-configuration
      namespace: kube-system
      labels:
        k8s-app: nginx-ingress-controller
    data:
      proxy-body-size: "4096m"

---------

## 参考文档

- https://zhuanlan.zhihu.com/p/28963911
- https://www.cnblogs.com/seablogs/articles/16054315.html

# 4.集群初始化失败报错

## 故障背景

客户业务集群构建于centos7，自己私有服务器上用Ubuntu18.04搭建1.20版集群

## 故障现象

kubeadm初始化失败报错，具体信息为：Failed to create pod sandbox: open /run/systemd/resolve/resolv.conf: no such file or directory

## 故障原因

debian系的DNS配置文件由systemd-resolved服务管理，该服务没有开机自启，导致/etc/resolv.conf未生成，连不上网络

## 解决方案

    sudo mkdir -p /run/systemd/resolve
    sudo ln -s /etc/resolv.conf /run/systemd/resolve/resolv.conf
    
---------

## 参考文档

- https://github.com/kubernetes/kubeadm/issues/1124

# 5.PVC不可用

## 故障背景

集群版本为V1.20.12，创建StorageClass正常未报错

## 故障现象

StorageClass创建的PVC一直处于Pending状态，具体信息为：waiting for a volume to be created,either by external provisioner “nfs-client” or manually created by system administrator，意思是SC的供应器未就绪，处于不可用状态。查看供应器日志，发现报错信息：Subsets:[]v1.EndpointSubset(nil)’ due to:‘selfLink was empty, can’t make reference’. Will not report event:‘Normal’ ‘LeaderElection’ ‘nfs-client-provisioner-5c4d67788-xwq2j_4cc3307a-bd8a-11ed-938e-5efc4b2ec335 became
leader’

## 故障原因

1.20版本的BUG导致，selfLink was empty在v1.20之前都存在，v1.20之后将会被删除

## 解决方案
    
    sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml
    
    
    # 每个master节点apiserver配置文件添加该参数，之后kubeadm部署的集群会自动加载部署pod
    - --feature-gates=RemoveSelfLink=false

---------

## 参考文档

- https://github.com/kubernetes-sigs/nfs-subdir-external-provisioner/issues/25

# 6.service创建失败

## 故障背景

创建service时失败报错

## 故障现象

创建service时报错，Invalid value: 38096: provided port is not in the valid range. The range of valid ports is 30000-32767

## 故障原因

kubernetes集群service默认端口是在30000-32767，给service指定的端口超出这个范围，导致报错

## 解决方案

    sudo vi /etc/kubernetes/manifests/kube-apiserver.yaml


    - --service-node-port-range=1-65535


- 注：高可用集群的每个apiserver都需要进行修改

---------

## 参考文档

- https://blog.csdn.net/weixin_45290734/article/details/120197991

# 7.服务器断电重启后docker启动失败报错

## 故障背景

上次新加的几台机器与其他机器不在同一机房，一次机房断电，随后重启服务器

## 故障现象

服务器重启后发现所有节点的docker都无法启动，报错信息为：cgroups: cgroup mountpoint does not exist: unknown

## 故障原因

从报错信息看，是由cgroup挂载点不存在所导致。百度上找到临时解决方案，即新建挂载点目录再重新挂载。原来以为是bug，随后找到一篇github上的帖子，说像是第三方打包或OS的问题，官方无能为力。目前只能以临时方案解决，个人猜测是docker版本问题，因为为了保持集群节点的一致性，docker统一为19版本，可能新版本操作系统有某些限制。测试环境试验最新版本没有这个问题

## 解决方案

    sudo mkdir /sys/fs/cgroup/systemd
    sudo mount -t cgroup -o none,name=systemd cgroup /sys/fs/cgroup/system

---------

## 参考文档

- https://github.com/moby/moby/issues/36016
- https://blog.csdn.net/weixin_41481443/article/details/130729906

# 8.docker监控容器启动失败

## 故障背景

Centos7维护周期将尽，考虑以RockyLinux9.2进行代替，配置Prometheus监控时docker容器启动失败

## 故障现象

docker运行cadvisor容器时报错：cadvisor.go:146 Failed to create a Container Manager: mountpoint for cpu not found

## 故障原因

cadvisor镜像版本太旧，需要升级为v0.46.0以上版本

## 解决方案

拉取v0.46.0以后版本的cadvisor镜像，重新启动

---------

## 参考文档

- https://github.com/google/cadvisor/issues/1943
- https://blog.csdn.net/wuxingge/article/details/133071181

# 9.集群不可访问

## 故障背景

Ubuntu18.04搭建本地kubernetes集群，服务器重启之后集群不可访问

## 故障现象

集群所有节点均不可用，etcd集群未启动，kubelet组件报错：Failed to create pod sandbox: open /run/systemd/resolve/resolv.conf: no such file or directory

## 故障原因

kubelet组件的报错报错信息很明显指向DNS解析，Ubuntu的/etc/resolv.conf是一个软连接，由系统服务器systemd-resolved生成。systemd-resolved是systemd附带的解析DNS的代理，将本地的DNS请求转发到外部的DNS服务器，也即是DNS解析的过程在本地又新增了一层，影响效率，也不利于管理，建议关闭，手动设置resolv.conf

## 解决方案

### 1.禁用systemd-resolved

    sudo systemctl stop systemd-resolved
    sudo systemctl disable systemd-resolved

### 2.创建resolv.conf文件

    sudo rm -rf /etc/resolv.conf
    sudo vi /etc/resolv.conf


    nameserver 8.8.8.8

### 3.锁定resolv.conf文件

    sudo chattr +i /etc/resolv.conf

---------

## 参考文档

- https://www.cnblogs.com/czlong/p/15802384.html
- https://www.cnblogs.com/xzlive/p/17139520.html