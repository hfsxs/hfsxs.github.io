---
title: Kubernetes集群性能优化策略
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2024-02-20 17:05:51
---

kubernetes集群默认配置已足够满足常见的中小规模的业务场景，但仍然建议将生产环境集群各组件的参数及系统内核参数进行适当的调整与优化，以应对高并发高负载的场景，提高集群运行的稳定性和故障切换能力，保障业务的连续性与稳定性

# 1.系统参数配置

    sudo vi /etc/sysctl.conf

  
    # 设置系统级别文件句柄打开的最大数量，用于解决Too many open files和Socket/File: Can’t open so many files报错
    fs.file-max = 1000000
    # 设置单个用户ID可创建的inotify instatnces最大量，默认为128
    fs.inotify.max_user_instances = 524288
    # 设置每个inotify instance相关联的watches，默认为8192
    fs.inotify.max_user_watches = 524288

    # 设置内核允许的最大跟踪连接条目，即netfilter同时处理的任务数
    net.netfilter.nf_conntrack_max = 10485760
    # 设置内核netfilter处理tcp会话的超时时间，默认为432000，即5天
    net.netfilter.nf_conntrack_tcp_timeout_established = 300
    # 设置内核netfilter哈希表的大小，64位CPU8G内存默认为65536，以此类推
    net.netfilter.nf_conntrack_buckets = 655360
    # 设置每个网卡缓存报文的最大量，默认为1000，适用于网卡负载高于内核处理速度的场景，防止网络丢包
    net.core.netdev_max_backlog = 10000

    # 设置ARP高速缓存垃圾收集器的运行阈值，即层数超过该值则运行，默认为128，适用于内核维护的arp表过于庞大的场景
    # net.ipv4.neigh.default.gc_thresh1 = 1024
    # 设置ARP高速缓存垃圾收集器的软限制，即超过此阈值等待5秒开始运行垃圾收集器，默认为512，适用于内核维护的arp表过于庞大的场景
    # net.ipv4.neigh.default.gc_thresh2 = 4096
    # 设置ARP高速缓存垃圾收集器的硬限制，即超过此阈值立即开始运行垃圾收集器，默认为1024，适用于内核维护的arp表过于庞大的场景
    # net.ipv4.neigh.default.gc_thresh3 = 8192

# 2.Etcd参数配置

## 2.1 存储配额

Etcd数据库默认磁盘空间配额大小为2G，超过将不会再写入数据，--quota-backend-bytes配置项用于设置配额，最大支持8G

    --quota-backend-bytes 8589934592 
  
## 2.2 进程优先级

Etcd数据库写入数据时，为规避其他进程磁盘IO的影响，防止请求超时和临时Leader的丢失，建议设置etcd进程的IO调度优先级，以保集群的障稳定性

    sudo ionice -c2 -n0 -p $(pgrep etcd) 

## 2.3 请求数据

Etcd数据库被设计用于元数据的小键值对的处理，数据量较大的请求可能会引发请求延迟，请求的数据量默认被限制为1.5MiB，可通过配置项–max-request-bytesetcd进行设置

## 2.4 历史记录压缩

ETCD数据库中存储有多个版本数据，随着写入的主键增加，历史版本将会越来越多，且不会自动清理，可通过压缩与清理历史数据进行优化

    --auto-compaction-mode
    --auto-compaction-retention

## 2.5 operator etcd集群 

operator是CoreOS推出的旨在简化复杂有状态应用管理的框架，动态地感知应用状态的控制器，可以更加自动化智能化地管理与维护Etcd集群

# 3.kubelet组件配置

## 3.1 设置并发度

kubelet默认情况下以串行方式拉取镜像，可将配置项--serialize-image-pulls设为false，改成并行方式，以提高镜像镜像速度，适用于docker daemon版本高于1.9，且未配置aufs存储的场景

    --serialize-image-pulls=false

## 3.2 限制镜像拉取时长

image-pull-progress-deadline配置项用于设置镜像拉取的超时时长，默认为1分钟，可进行调整以优化镜像拉取速度

    --image-pull-progress-deadline=30

## 3.3 限制单节点运行的Pod量

kubelet单节点允许运行的最大Pod数默认为110，可根据实际需要进行调整

    --max-pods=110

# 4.ApiServer组件配置

## 4.1 参数配置

    # 设置单位时间内最大非修改型请求数，即读操作数，默认为400
    --max-requests-inflight
    # 设置单位时间内最大修改型请求数，即写操作数，默认为200
    --max-mutating-requests-inflight
    # 设置集群资源的watch缓存，默认为100，资源数量较多时可相应增加
    --watch-cache-sizes

- 注：读/写最大请求量的设置建议按照集群Node节点的数量进行配置，节点数大于3000，则配置为3000/1000；节点数大于1000小于3000，则配置为1500/500

## 4.2 内存配额

    # 设置ApiServer程序所占内存，建议按照公式进行配置
    --target-ram-mb=node_nums * 60

# 5.ControllerManager组件配置

## 5.1 参数配置

    # 设置Node节点健康检查时间间隔，默认为5s
    --node-monitor-period
    # 设置Node节点健康检查超时时长，超过即将进入ConditionUnknown状态，默认为40s
    --node-monitor-grace-period
    # 设置Node节点处于NotReady状态后开始驱逐Pod的超时时长，默认为5m
    --pod-eviction-timeout
    # 设置集群规模判断依据，默认为50，即50个节点以上的集群为大集群
    --large-cluster-size-threshold 
    # 设置集群故障节点数超限率，默认为55%
    --unhealthy-zone-threshold
    # 设置Node节点Pod驱逐操作的频率，默认0.1个/s，即每10s最多驱逐某一个节点的Pod，以减缓Master节点故障导致大批量的Node节点异常驱逐
    --node-eviction-rate
    # 设置集群节点故障率超限后的Pod驱逐操作的频率，大集群超限后将会降为0.001，小集群则直接停止驱逐
    --secondary-node-eviction-rate

## 5.2 ApiServer通信限制

    # 设置ApiServer组件会话QPS，默认为20
    --kube-api-qps=100
    # 设置ApiServer组件会话并发数，默认为30
    --kube-api-burst=150

# 6.Scheduler组件配置

## 6.1 设置调度策略文件

    # 设置调度策略json文件，不指定则表示默认的调度策略
    --policy-config-file 

## 6.2 ApiServer通信限制

    --kube-api-qps=100
    --kube-api-burst=150

---------

# 参考文档

- https://blog.csdn.net/ywq935/article/details/103124541
- https://blog.csdn.net/tgzh123/article/details/134857593
- https://blog.csdn.net/ver_mouth__/article/details/126120802