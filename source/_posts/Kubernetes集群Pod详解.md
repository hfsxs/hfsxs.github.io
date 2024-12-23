---
title: Kubernetes集群Pod详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云计算
date: 2021-06-03 22:07:21
---

Pod，Kubernetes集群所管理的最小单元，由一个或者多个紧密相连的容器组成，作为容器环境下的逻辑主机被部署于同一节点，用于承载具体的应用实例。Pod内的容器总是并置的且共同调度，共享一组上下文配置，如PID命名空间（同一个Pod中应用可以看到其它进程）、网络命名空间（同一个Pod的中的应用对相同的IP地址和端口有权限）、IPC命名空间（同一个Pod中的应用可以通过VPC或者POSIX进行通信）、UTS命名空间（同一个Pod中的应用共享一个主机名称），还共享存储、网络、以及容器运行规约等资源

---------

# 1.设计理念

Pod为什么要被引入，直接用容器管理应用程序不行吗？容器管理单个进程的应用程序时是有效的，而对于多个进程组合而成的应用程序则难于管理，如以下两种处理方式

## 1.1 应用程序进程封装到一个容器

Docker管理的进程是pid为1的主进程，由于应用进程代替init直接占用了1的进程号，将导致孤儿进程和僵尸进程不能被正常回收。最终，容器的资源将被完全占用。所以，容器的运行方式才会推荐一个容器只干一件事情

## 1.2 应用程序进程拆分到单个容器

此时，应用程序的进程将会被调度到各个不同的节点上，这样往往会造成进程间不能正常通信的问题，从而使应用程序运行异常

---------

综上，kubernetes需要一个将容器绑定在一起作为一个基本的调度单元进行管理的结构，保证这些容器始终能被调度到同一个节点上，即为Pod设计的初衷

# 2.Pod优点

## 2.1 透明

pod中的容器对基础设施可见，使得基础设施可以给容器提供服务，例如线程管理和资源监控，这为用户提供很多便利

## 2.2 解耦

解耦软件依赖关系,独立的容器可以独立的进行重建和重新发布，Kubernetes甚至会在将来支持独立容器的实时更新

## 2.3 易用

用户不需要运行自己的线程管理器，也不需要关心程序的信号以及异常结束码等，只需直接操作pod即可

## 2.4 共享

Pod的中的应用均使用相同的网络命名空间及端口，并且可以通过localhost发现并沟通其他应用，每个Pod都有一个扁平化的网络命名空间下IP地址，使其可以和其他的物理机及其他的容器进行无障碍通信

Pod还定义了一系列的共享磁盘，让数据在容器重启的时候不会丢失，且可以将这些数据在Pod中的应用进行共享

# 3.创建流程

## 3.1 集群用户提交请求

集群用户通过客户端管理命令kubectl或UI向API Server提交pod创建请求

## 3.2 master处理请求

主节点的API Server组件处理用户请求，生成一个包含创建信息的yaml，并将pod信息写入到etcd数据库

## 3.3 master协调Pod数

kube-controller-manager的通过Watch监听机制感知到新建Pod请求事件，创建ReplicaSet控制器，进入一致性协调逻辑，确保实际运行Pod数与期望一致

## 3.4 master调度资源

kube-scheduler通过API Server的watch监听机制感知到了etcd数据库存储的新写入的Pod信息，尝试为Pod分配Node

### 3.4.1 即调度预选

kube-scheduler用一组规则过滤掉不符合要求的主机，如资源不足、标签选择不符、亲和性不符等

### 3.4.2 即调度优选

kube-scheduler为主机打分，对上一步筛选出的符合要求的主机进行打分，制定出一些整体优化策略，如把同一个Replication Controller的副本分布到不同的主机上以平衡主机负载，使用最低负载的主机等

### 3.4.3 选择主机

kube-scheduler选择出打分最高的主机，根据一组相关规则进行binding操作，并将结果存储到etcd中以记录pod分配情况

## 3.5 node执行创建操作

被选中的node上的kubelet定期通过watch监听到etcd数据库的boundpod对象（由master的scheduler组件调用APIServer的API在etcd中创建，描述node上绑定运行的所有pod信息），发现分配给该工作节点上运行的boundpod对象没有更新，则调用Docker API创建并启动pod内的容器

# 4.运行状态

Pod在整个生命周期过程中被系统定义为各种状态，该状态值标识了pod的运行情况

## 4.1 重启策略

Pod中所有容器的重启策略由restartPolicy字段来设置 ，其可能值为Always，OnFailure 和 Never，默认值为Always。restartPolicy仅指通过kubelet在同一节点上重新启动容器，通过kubelet重新启动的退出容器将以指数增加延迟（10s，20s，40s…）重新启动，上限为 5 分钟，并在成功执行 10 分钟后重置

不同类型的的控制器可以控制 Pod的重启策略

- Job，适用于一次性任务如批量计算，任务结束后Pod会被此类控制器清除，重启策略只能是OnFailure或Never

- Replication Controller,ReplicaSet或Deployment，希望Pod一直运行，重启策略是Always

- DaemonSet，每个节点上启动一个Pod，重启策略应该是Always

## 4.2 状态解析

### 4.2.1 Pending，挂起状态

API Server已经创建该Pod但还没有被调度器调度到合适的节点，或者Pod内还有一个或多个容器没有创建成功，包括正在下载的镜像的过程

### 4.2.2 Running，运行中状态

Pod已经绑定到一个节点上，所有容器均已创建，且至少有一个容器处于运行状态、正在启动或正在重启状态

### 4.2.3 Succeeded，成功状态

Pod内所有容器均已成功执行退出，且不会再重启

### 4.2.4 Failed，失败状态

Pod内所有容器均已退出，但至少有一个容器退出为失败状态，即容器以非0状态退出或者被系统终止

### 4.2.5 Unknown，未知状态

由于某种原因无法获取该Pod的状态，可能由于网络通信不畅导致

# 5.生命周期

Pod完整的生命周期由三部分组成，即Init Container、Pod Hook、健康检查

## 5.1 Init Container

Init Container，即初始化容器，用于做初始化工作的容器，可以是一个或者多个，若有多个则按定义的顺序依次执行。由于Pod所有容器共享数据卷和Network Namespace，所以Init Container里面产生的数据可以被主容器使用到初始化容器独立于主容器之外，只有所有的初始化容器执行成功后主容器才会被启动，应用场景如下：

- 服务依赖，等待其他模块Ready，如一个Web服务依赖于另外一个数据库服务，但启动这个Web服务的时候并不能保证依赖的这个数据库服务就已经成功启动，所以可能会出现一段时间内Web服务连接数据库异常问题。此时，可在Web服务Pod中定义一个InitContainer，在这个初始化容器中去检查数据库是否已经准备好了，准备好了过后初始化容器就结束退出，然后再将主容器Web服务启动起来，再去连接数据库就不会有问题

- 初始化配置，如集群里检测所有已经存在的成员节点，为主容器准备好集群的配置信息，这样主容器起来后就能用这个配置信息加入集群

- 其它场景，如将Pod注册到一个中央数据库、配置中心等

## 5.2 Pod Hook

Pod Hook，即容器生命周期钩子，监听容器生命周期的特定事件，并在事件发生时执行已注册的回调函数，由kubelet发起，运行于容器中的进程启动前或者容器中的进程终止前，包含在容器的生命周期之中

### 5.2.1 钩子分类

- postStart，容器启动后立即执行，由于是异步执行而没有参数传递给处理程序，无法保证一定在ENTRYPOINT之后运行。若失败则容器会被杀死，并根据RestartPolicy决定是否重启。主要用于资源部署、环境准备等，不过需要注意的是如果钩子花费太长时间以至于不能运行或挂起，容器将不能达到running状态

- preStop，容器停止前执行，常用于资源清理、优雅关闭应用程序、通知其他系统等，若失败则容器被杀死。若在执行期间挂起，则Pod将停留在running状态并且永远不会达到failed状态

### 5.2.2 回调函数

- exec，在容器内执行特定的命令，将消耗容器的计算资源

- httpGet，向指定URL发起GET请求用户请求删除含有Pod的资源对象时（如Deployment等），为了让应用程序优雅关闭（完成正在处理的请求再关闭），提供了两种信息通知：默认，通知node执行docker stop命令，docker先向容器中PID为1的进程发送系统信号SIGTERM，然后等待容器中的应用程序终止执行，若等待时间达到设定的超时时间，或者默认超时时间（30s），则继续发送SIGKILL的系统信号强行kill 掉进程；使用Pod生命周期（利用PreStop回调函数），在发送终止信号之前执行默认所有的优雅退出时间都在30秒内，kubectl delete 命令支持--grace-period=<seconds>选项，允许用户自定义以覆盖默认值，为0代表强制删除 pod。强制删除pod是从集群状态还有etcd里立刻删除这个pod，APIServer不会等待来自Pod所在节点上kubelet的确认信息：pod已经被终止。在API里pod会被立刻删除，在节点上pods被设置成立刻终止后，在强行杀掉前还会有一个很小的宽限期

## 5.3 健康检查

Kubernetes提供了两种探针（Probe，支持exec、tcp和httpGet方式）来探测容器的状态，以保障容器在部署后确实处在正常运行状态

- LivenessProbe，即存活探针，探测应用是否处于存活状态，否则kubelet将杀掉该容器，并根据容器的重启策略做相应的处理。若容器不包含LivenessProbe探针，则kubelet认为该容器的LivenessProbe探针返回的值永远都是success

- ReadinessProbe，即可读性探针，探测容器是否处于可以接收请求的完成(Ready状态)，否则Pod的状态将被修改，Endpoint Controller将从Service的Endpoint中删除包含该容器所在的Pod的Endpoint

---------

# 1.创建pod

# 1.1 创建资源文件

    vi nginx.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      labels:
        app: nginx
    spec:
      containers:
      - name: nginx
        image: nginx

## 1.2 部署Pod

    kubectl create -f nginx.yaml

# 3.查看Pod

    kubectl get pods -o wide

# 4.查看pod详情

    kubectl describe pod nginx

# 5.查看pod日志

    kubectl logs nginx



---------

# 参考文档

- 