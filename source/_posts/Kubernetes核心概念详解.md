---
title: Kubernetes核心概念详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2021-05-18 12:15:38
---

Kubernetes集群资源分为三个级别，即命名空间级别、集群级别和元数据级别

# 资源分类

## 1.命名空间级别

该类资源从属于某个命名空间，创建、查询、修改及删除时需进行命名空间的指定，若不指定则从属于默认的命名空间为default

- WorkLoad，工作负载型资源，如Pod、ReplicaSet、Deployment、StatefulSet、DaemonSet、Job、CronJob

- ServiceDiscovery LoadBalance，服务发现及负载均衡型资，如Service、Ingress

- 配置与存储型资源，如Volume、CSI

- 特殊类型的存储卷，如ConfigMap、Secret、DownwardAPI

## 2.集群级别

该类资源不属于任何命名空间，所有命名空间下都可进行操作，无需进行指定，如Namespace、Node、Role、ClusterRole、RoleBinding、ClusterRoleBinding

## 3.元数据级别

介于上述两者之间，通过指标进行相应操作，如HPA（通过cpu利用率进行平滑扩展）、PodTemplate（pod模板）、LimitRange（资源限制）

# 1.Cluster

cluster，即集群，计算、存储和网络资源的集合，由一系列物理机、虚拟机和其他基础资源组成，由这些资源运行各种基于容器的应用

# 2.Master

master，即主节点，负责整个集群的管理、控制与调度，执行所有的控制命令，为实现高可用可运行多个master

# 3.Node

node，即工作节点，负责运行容器应用，由master管理，监控并汇报容器的状态，同时根据master的要求管理容器的生命周期，是真正用来承载业务的资源

# 4.Resource
  
resource，即资源，是Kubernetes API中的一个端点，其中存储的是某个类别的API对象的一个集合。实际上，Kubernetes中的所有内容都被抽象为资源，如Pod、Service、Node等都是资源。万物皆对象是Kubernetes的理念，资源即对象，对象就是资源的实例化，如名为nginx的pod、名为node03的node等

# 5.Objecte

objecte，即对象，又称为API对象，是Kubernetes集群中的持久化的实体和管理操作单元，用于表示整个集群的状态，这些状态包括节点上运行了什么样的应用（容器化的）、应用可以使用的资源、应用的管理策略。objecte由API服务器进行操作，如创建、修改、查询、删除等，是一种意图的记录，一旦被成功创建，就意味着将持续工作以确保对象存在。Pod、Deployment、RC、RS、Service、Volume、PV等，都属于kubernetes的对象

对象创建的过程也即是资源实例化的过程，实质上就是kubectl调用Master组件api-server的API接口对定义了对象属性的资源清单文件进行解析、执行的过程。资源清单文件通常为.yaml格式，kubectl发起API请求时，将文件包含的信息转换成JSON格式进行执行

API对象有三类属性：元数据metadata、规范spec和状态status
  
- metadata，元数据，用于标识API对象，每个对象都至少有3个元数据：namespace、name和uid，此外还有标签（label）用于标识和匹配不同的对象
- spec，规范，用于描述对象的期望状态，由用户在创建对象时指定，如用户RC用于设置Pod的期望副本数
- status，状态，用于标识对象当前的状态，由Master时刻监控与管理，以保障与期望状态相匹配

# 6.NameSpace

namespace，即命名空间，是对一组资源和对象的抽象集合，用于实现多租户的资源隔离。常见的pods，services, replication controllers和deployments等资源都属于某一个namespace，而node、persistentVolumes等则不属于任何namespace。namespace通过将集群内部的资源对象聚合到不同的Namespace中，形成逻辑上分组的不同项目、小组或者用户组，便于不同的分组在共享整个集群的资源的同时还能被分别管理
  
Kubernetes集群启动后，会创建一个名为default Namespace，若资源对象被创建时不特别指明，则都将被系统创建到名为default

namespace有两种状态，即Active和Terminating，后者表示正在被删除的过程中，删除完成后其所有的资源都将被删除，default和kube-system命名空间不可删除

# 7.Pod

pod，最小调度及资源单元，包含一个或者多个容器以及存储、网络等各个容器共享的资源，作为一个整体被master调度到一个node上运行，逻辑上表示某种应用的一个实例。每个Pod都有一个特殊的被称为根容器的Pause容器，其对应的镜像属于Kubernetes平台的一部分。根容器的状态代表整个容器组的状态，整个pod内部的多个容器共享pod IP及其挂载的Volume。pod可以被看作是一个豌豆荚，容器则是这个豆荚里的豆子

# 8.Label

label，即标签，是一个由用户自定义的key=value的键值对，被绑定到各种资源对象上，例如Node、Pod、Service、RC等，用于资源对象的分组标识与管理。一个资源对象可以定义任意数量的Label，同一个Label也可以被添加到任意数量的资源对象上去。通过这种方式，Controller与Pod之间就建立起一种对应关系，便于Controller对pod下达指令。Label通常在资源对象定义时确认，也可以在对象创建后动态添加或者删除label只对用户而言是有意义的，对内核系统没有直接意义

label Selector，即标签选择器，用于查询和筛选有某些Label的资源对象，类似于SQL的对象查询机制。label选择器可以由多个必须条件组成，由逗号分隔。在多个必须条件指定的情况下，所有的条件都必须满足，因而逗号起着AND逻辑运算符的作用。label表达式分为两类：

- Equality-based，基于等式

基于相等性或者不相等性的条件，允许用label的键或者值进行过滤。匹配的对象必须满足所有指定的label约束，尽管他们可能也有额外的label。基于等式的表达式有三种运算符，“=”，“==”和“!=”。前两种代表相等性，是同义运算符，后一种代表非相等性name = redis-slave:，匹配所有具有标签name=redis-slave的资源对象env != production，匹配所有不具有标签env=production的资源对象

- Set-based，基于集合

基于集合的label条件允许用一组值来过滤键，有三种操作符:in、notin和 exists(仅针对于key符号)，name in (redis-master,redis-slave)，匹配所有具有name=redis-master或者name=redis-slave的资源对象；name not in (php-fronted)，匹配所有不具有标签name=php-fronted的资源对象

# 9.Controller

controller，即控制器，用于创建、管理、扩容、复制、自愈、调度pod的资源。控制器定义了pod的部署特性，如副本数，可供调度的node等。controller通过API Server提供的接口实时监控整个集群每个资源对象的状态，当发生各种故障导致系统状态发生变化时，会尝试将系统状态修复到正常状态

## 9.1 Replication Controller

Replication Controller，即副本控制器，简称为RC，用于实现pod的扩容缩容，解决分布式应用的负载均衡及高可用问题，根据整体负载情况进行动态伸缩

## 9.2 Replica Set

Replica Set，即副本集，简称为RS，是RC的下一代，两者都能确保集群在任何时间运行指定数量的Pod副本，只在标签选择支持上有所不同，RS支持集合方式的选择，RC仅支持相等方式的选择

Kubernetes通常不直接使用副本控制器，而是由更高级的deployment来管理，包括协调pod创建、删除和更新，从而维持pod副本数

## 9.3 Deployment

deployment，即部署，用于管理pod和rc，最常用的controller。其主要应用场景为：创建、监测pod和rs、滚动升级和回滚应用、扩容与缩容以及暂停、恢复、更新Deployment

deployment实际上是对rs和pod的管理，先创建rs，由RS创建pod，即rs控制pod的数量，deployment管理、创建rs，同时控制pod应用的升级、回滚
  
## 9.4 StatefulSet

statefulset，即有状态服务集，用于解决有状态服务的问题，如复杂的中间件集群MySQL集群、MongoDB集群、Kafka集群、ZooKeeper集群等。statefuleset确保pod的每个副本在整个生命周期中名称保持不变，其他控制器都是无状态的，不提供这种功能

### 9.4.1 组成部分

Headless Service，用于定义网络标志（DNS domain），为pod进行编号volumeClaimTemplates，用于创建PersistentVolumes，挂载到Headless Service StatefulSet，用于定义具体的应用

StatefulSet每个Pod的DNS格式为statefulSetName-{0..N-1}.serviceName.namespace.svc.cluster.local，其
中，serviceName为Headless Service的名字，0..N-1为Pod所在的序号，从0开始到N-1，statefulSetName为StatefulSet
的名字，namespace为服务所在的namespace，Headless Servic和StatefulSet必须在相同的namespace，.cluster.local
为Cluster Domain

### 9.4.2 应用场景

- 稳定的持久化存储，即Pod重新调度后还是能访问到相同的持久化数据，基于PVC来实现
- 稳定的网络标志，即Pod重新调度后其PodName和HostName不变，基于Headless Service（没有Cluster IP的Service）来实现
- 有序部署，有序扩展，即Pod是有顺序的，在部署或者扩展的时候要依据定义的顺序依次依次进行，即从0到N-1，在下一个Pod运行之前所有之前的Pod必须都是Running和Ready状态），基于init containers来实现
- 有序收缩，有序删除（从N-1到0）
- 当某个pod发生故障需要删除并重新启动时，pod的名称会发生变化，同时statefulset会保证副本按照固定的顺序启动、更新或者删除
  
## 9.5 DaemonSet

daemonset，即后台守护服务集，能够让每个Node节点运行同一个pod，当节点从集群中被移除后，该节点上的Pod也会被移除，用于部署一些集群的日志采集、监控或者其他系统管理应用

### 9.5.1 调度策略
  
默认情况下，Pod被分配到具体哪一台Node节点运行是由Scheduler监听ApiServer，查询出还未分配的Node的Pod，再根据调度策略为这些Pod进行调度。但daemonset创建的pod却有些不同，其会忽略Node的unschedulable状态，且即使Scheduler还未启动，DaemonSet Controller仍然能够创建并运行Pod。为daemonset指定Node节点有三种方式；nodeSelector，只调度到匹配指定label的Node；nodeAffinity，功能更丰富的Node选择器，支持集合操作；podAffinity，调度到满足条件的Pod所在的Node

### 9.5.2 应用场景
 
- 日志收集守护程序，如fluentd或logstash，在每个节点运行容器
- 节点监视守护进程，如prometheus监控集群，可以在每个节点上运行一个node-exporter进程来收集监控节点的信息
- 系统程序与集群存储守护程序，如glusterd、ceph要部署在每个节点上提供持久性存储，集群程序kube-proxy, kube-dns等

## 9.6 Job
  
job，即任务，用于批量处理短暂的一次性任务，保障批处理任务的一个或多个Pod成功结束，由Job Controller负责根据Job Spec进行创建，并持续监控其状态，直至成功结束。其创建的pod任务执行完后就将自动退出，集群也不会再重新将其唤醒。只有job执行完毕后，STATUS状态才为Completed,没有执行完毕的状态为Running，其RestartPolicy (pod重启策略)仅支持Never和OnFailure两种，不支持Always

### 9.6.1 job分类

- 一次性job，通常创建一个Pod直至其成功结束，适用于数据库迁移场景，此时Spec设为：.spec.completions=1，.spec.Parallelism=1
- 固定结束次数的Job，依次创建一个Pod运行直至completions个成功结束，适用于处理工作队列的场景，此时Spec设为：.spec.completions=2+，.spec.Parallelism=1
- 并行Job，创建一个或多个Pod直至有一个成功结束，适用于多个Pod同时处理工作队列的场景，此时Spec设为：.spec.completions=1
- 固定结束次数的并行Job：依次创建多个Pod运行直至completions个成功结束，适用于多个Pod同时处理工作队列的场景，此时Spec设为：.spec.completions=2+，.spec.Parallelism=2+

## 9.7 CronJob

cronjob，即定时任务，类似于Linux系统的crontab，在指定的时间周期运行指定的任务

CronJob Spec格式：

.spec.schedule，指定任务运行周期，格式同Cron
.spec.jobTemplate，指定需要运行的任务，格式同Job
.spec.startingDeadlineSeconds，指定任务开始的截止期限
.spec.concurrencyPolicy，指定任务的并发策略，支持Allow、Forbid和Replace

# 10.Volume

volume，即数据卷，用于pod数据存储与共享存储，被挂载到Pod中一个或者多个容器的指定路径下，支持多种后端存储方式，如本地存储，分布式存储，云存储等，解决了容器文件系统临时性的问题

# 11.Persistent Volume

Persistent Volume，即持久化数据卷，简称PV，是对底层的共享存储的一种抽象，由管理员进行创建和配置，有多种类型，如Ceph、GlusterFS、NFS等，都是通过插件机制完成与共享存储的对接。PV是集群的存储资源，是一种静态的存在，其生命周期独立于使用PV的任何单个pod

Persisten Volume ClaimPVC，即持久化卷声明，简称PVC，是用户存储的一种声明，也就是对PV的引用。类似于pod，前者消耗节点资源，后者消耗PV资源。Pod请求CPU、内存（计算资源），PVC请求特定的存储空间和访问模式（存储资源）

PV是群集中的资源，PVC是对这些资源的请求，此外还充当对资源的检查。PV和PVC之间的相互作用遵循以下生命周期：Provisioning ——-> Binding ——–>Using——>Releasing——>Recycling

1.Provisioning，即供应准备，通过集群外的存储系统或者云平台来提供存储持久化支持，分为两类：

- Static，静态提供，集群管理员创建多个PV，且携带可供集群用户使用的真实详细的存储信息，存在于Kubernetes API中，可用于消费
- Dynamic，动态提供，当管理员创建的静态PV都不匹配用户的PVC时，集群会尝试为PVC动态配置卷。此配置基于StorageClasses：PVC必须请求一个类，并且管理员必须已创建并配置该类才能进行动态配置。此外，还要求该类的声明有效地为自己禁用动态配置

2.Binding，即绑定，用户创建pvc并指定需要的资源和访问模式，在此之前pvc会保持未绑定状态

3.Using，即使用，用户可在pod中像volume一样使用pvc

4.Releasing，即释放，用户删除pvc来回收存储资源，pv将变成released状态。由于还保留着之前的数据，这些数据需要根据不同的策略来处理，否则这些存储资源无法被其他pvc使用。

5.Recycling，即回收，pv可以设置三类回收策略：

- Retain，保留策略，允许人工处理保留的数据
- Delete，删除策略，将删除pv和外部关联的存储资源，需要插件支持
- Recycle，回收策略，将执行清除操作，之后可以被新的pvc使用，需要插件支持
  
# 12.ConfigMap 

configMap，即配置项，用于存储非机密性的配置数据，如注册中心地址、数据库地址、nginx地址等，解决了应用程序配置信息和容器镜像之间的依赖关系，分离了配置数据和应用程序代码，方便了应用程序配置信息的更新
configMap存储的是一个键值对，可以被pod引用，或者用于为contaroller一样的系统组件存储配置数据，类似于Linux系统中的/etc目录，用来存储配置文件的目录。具体作用有三种：设置环境变量；设置容器命令行参数；创建数据卷config文件

# 13.Secret

secret，即机密存储，用于存储敏感信息，如密码、OAuth令牌、SSH密钥等，可以被pod引用，方式有三种：作为挂载到一个或多个容器上的卷中的文件；作为容器的环境变量；kubelet在为Pod拉取镜像时使用
  
# 14.Service

service，即服务，定义了一组Pod访问策略的抽象。service创建成功后会分配到一个访问入口地址，前端pod通过入口地址将请求发给service，service通过Label Selector关联到后端pod，然后kube-proxy进程负责将请求转发到后端pod群，并在内部实现服务的负载均衡与会话保持机制。此过程中，RC用于保障service的能力与质量。Service不是共用一个负载均衡器的IP地址，而是每个Service分配了一个全局唯一的虚拟IP地址，这样service就成为了一个通信节点，避免了因pod的销毁或重建引发的IP地址变更的问题

# 15.Ingress

ingress，即外部入口，定义了一组外部请求进入集群的路由规则的集合，用于给service提供集群外部访问的URL、负载均衡、SSL终止、HTTP路由ingress由两部分组成，即Ingress controller和Ingress服务。Ingress controller监听Ingress和service的变化，根据规则配置负载均衡并提供访问入口与其他作为kube-controller-manager二进制文件的一部分随集群启动而启动运行的控制器不同，Ingress controller需要用户自定义创建，业内多种反向代理项目都有支持，如Nginx、HAProxy、Envoy、Traefik等。ingress反向代理service，作为service的负载均衡器，集群外部请求再由servi转发到后端的pod集群进行处理

---------

# 参考文档 

- https://kubernetes.io/zh
- https://www.kubernetes.org.cn
- https://www.cnblogs.com/fanqisoft/p/11533843.html
- https://www.cnblogs.com/life-of-coding/p/12156685.html