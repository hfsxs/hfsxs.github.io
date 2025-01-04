---
title: kubernetes存储持久化详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 存储
  - 云存储
  - 分布式存储
  - 云原生
  - 容器云
  - 云计算
date: 2021-11-06 15:30:35
---

存储持久化，是容器化技术中绕不开的话题。因为容器中的文件在磁盘上是临时存储的，也即是说容器中的文件随着容器的重启或销毁也会随之丢失，这就给应用程序的容器化带来了一项巨大的挑战。Kubernetes集群提供了多种不同的方案来解决这些问题，管理员可以根据需求来进行选择

---------

# 1.Volume

volume，即卷，核心是一个目录，其中可能存有数据，Pod中的容器可以访问该目录中的数据，所采用的特定的卷类型将决定该目录如何形成的、使用何种介质保存数据以及目录中存放的内容

pod资源定义文件声明及引用卷时，.spec.volumes表示Pod所使用的卷，.spec.containers[*].volumeMounts字段表示卷在容器中的挂载位置。容器中的进程看到的是由它们的Docker镜像和卷组成的文件系统视图，镜像位于文件系统层次结构的根部，各个卷则挂载在镜像内的指定路径上。卷不能挂载到其他卷之上，也不能与其他卷有硬链接，Pod配置中的每个容器必须独立指定各个卷的挂载位置

卷的缺点很明显，就是无论使用哪种类型的存储都需要手动定义，指明存储类型以及相关配置，也即是说卷的使用者还需要理解存储的底层实现，这就给卷的使用带来了极大的不便

kubernetes支持多种类型的卷，如下：

- emptyDir
- hostPath
- gcePersistentDisk
- awsElasticBlockStore
- nfs
- iscsi
- fc (fibre channel)
- flocker
- glusterfs
- rbd
- cephfs
- gitRepo
- secret
- persistentVolumeClaim
- downwardAPI
- projected
- azureFileVolume
- azureDisk
- vsphereVolume
- Quobyte
- PortworxVolume
- ScaleIO
- StorageOS
- local

---------

## 1.1 本地存储类卷，emptyDir、hostPath、local

### 1.1.1 EmptyDir

EmptyDir，一个空目录，生命周期和所属Pod完全一致，即存储的数据随之pod的销毁而被删除，主要用于存储同一Pod内不同容器间共享工作过程中产生的文件，如缓存数据、检查点数据等

    vi nginx.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
    spec:
      containers:
      - image: sword618/nginx
        name: nginx
        # 设置容器所要挂载的卷
        volumeMounts:
        # 设置卷挂载到容器的路径
        - mountPath: /tmp/nginx
          # 设置所要挂载的卷的名称
          name: nginx-cache
      # 设置卷的信息
      volumes:
      # 设置卷名称
      - name: nginx-cache
        # 设置卷的类型
        emptyDir: {}

### 1.1.2 Hostpath

Hostpath，将node上文件系统挂载到pod，若Pod跨主机重建，其内容则无法保证，所以可搭配DaemonSet使用，可用于存储日志、cADvisor监控数据等

    vi nginx.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      namespace: sword
    spec:
      containers:
      - image: sword618/nginx
        name: nginx
        volumeMounts:
        - mountPath: /var/log/nginx
          name: nginx-logs
      volumes:
      - name: nginx-logs
        hostPath:
          # 设置node节点目录
          path: /var/log/nginx

## 1.2 分布式存储类卷，如NFS、GlusterFS、CephFS等

适用于不同node上的pod数据共享，如静态html、图片资源、web资源等

    vi nginx-deployment.yaml



    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
      namespace: sword
    spec:
      selector:
        matchLabels:
          app: nginx-servers
      replicas: 2
      template:
        metadata:
          labels:
            app: nginx-servers
        spec:
          containers:
            - name: nginx
              image: sword618/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
              name: port
              protocol: TCP
          volumeMounts:
            - mountPath: /var/nginx/html
            name: web
          volumes:
          - name: web
            nfs:
            # 设置nfs服务器
            server: 172.16.100.200
            # 设置nfs服务器目录
            path: /data/web/html
                  
## 1.3 公有云存储，如AWS、GCE、Auzre等

# 2.PV/PVC

PV，PersistentVolume，即持久卷，由管理员预先创建或由StorageClass动态供应，是一段网络存储。PV与普通Volume一样使用卷插件实现，所不同的是拥有独立于任何使用PV的Pod的生命周期。PV属于集群资源，类似于node，不属于任何pod。PV将存储实现的底层逻辑抽象出来，kubernetes用户无需关注存储的实现细节，无论其背后是NFS、iSCSI还是特定于云平台的存储系统，直接申领使用即可

PVC，PersistentVolumeClaim，即持久卷申领，是用户对存储的引用，属于命名空间资源，消耗PV，类似于pod消耗node资源。PVC根据accessModes和capacity字段，自动搜索到符合这两个字段配置的PV并进行绑定，或者也可以通过标签选择器来定向进行匹配，一个PV只能被一个PVC绑定

## 2.1 PV支持的类型

PersistentVolume是由存储插件来进行实现，目前支持的插件如下：

- awsElasticBlockStore：AWS弹性块存储（EBS）
- azureDisk：Azure Disk
- azureFile：Azure File
- cephfs：CephFS volume
- csi：容器存储接口 (CSI)
- fc：Fibre Channel (FC) 存储
- flexVolume：FlexVolume
- gcePersistentDisk：GCE持久化盘
- glusterfs：Glusterfs卷
- hostPath：HostPath卷，仅供单节点测试环境而不适用于多节点集群，建议使用local卷作为替代
- iscsi，iSCSI (SCSI over IP) 存储
- local，节点上挂载的本地存储设备
- nfs，网络文件系统 (NFS) 存储
- portworxVolume，Portworx卷
- rbd，Rados块设备(RBD)卷
- vsphereVolume，vSphere VMDK卷
- cinder，Cinder OpenStack 块存储，v1.18弃用
- flocker，Flocker存储，v1.22弃用
- quobyte，Quobyte卷，v1.22弃用
- storageos，StorageOS卷，v1.22弃用

---------

## 2.2 PV生命周期

### 2.2.1 资源供应，Provisioning

Kubernetes支持两种资源的供应模式，即静态模式(Staic)和动态模式(Dynamic)，其结果就是创建完成的PV

- 静态模式，集群管理员手工创建多个PV，在定义PV时需要将后端存储的特性进行设置

- 动态模式，集群管理员无须手工创建PV，而是通过StorageClass的设置对后端存储进行描述，标记为某种类型，即Class。PVC对存储类型进行声明，集群将自动完成PV的创建及PVC的绑定

---------

### 2.2.2 资源绑定，Binding

PVC定义完成后，Kubernetes集群根据PVC对存储资源的请求，如存储空间和访问模式，在已存在的PV中选择一个满足PVC要求的PV，若能匹配就将该PV与用户定义的PVC进行绑定，从而实现pod存储卷的挂载

若没有满足PVC要求的PV，PVC则会无限期处于Pending状态，直到系统管理员创建了一个符合要求的PV。也可将两者定向绑定，如使用label等

PV一旦绑定在某个PVC上就会被其独占，不能再与其他PVC进行绑定。当PVC申请的存储空间比PV的少时，整个PV的空间都能够为PVC所用，但会造成资源的浪费。若资源供应使用的是动态模式，则集群在PVC找到合适的StorageClass后，将会自动创建PV并完成PVC的绑定

### 2.2.3 资源使用，Using

pod读取定义的卷，将PVC挂载到容器内的某个路径以实现存储的持久化。卷的类型为persistentVoulumeClaim，在容器挂载了PVC后就会被持续独占使用。多个Pod可以挂载同一个PVC，应用程序需考虑多个实例共同访问一块存储空间的问题

### 2.2.4 资源释放，Releasing

当用户对存储资源使用完毕后可以删除PVC，与该PVC绑定的PV将会被标记为已释放，此时该PV还不能绑定其他PVC，因为之前绑定的PVC写入的数据可能还留在存储设备上，只有在清除之后该PV才能继续使用

### 2.2.5 资源回收，Reclaiming

PV回收策略，即Reclaim Policy，由集群管理员设置，用于定义与之绑定的PVC释放资源之后对于遗留数据的处理方式。只有PV的存储空间完成回收，才能用于新的PVC的绑定和使用

 2.3 PV状态

- Available，空闲状态，未被PVC绑定
- Bound，绑定状态，已被PVC绑定
- Released，释放状态，已被PVC解绑，但还未被集群重新声明
- Failed，自动回收失败

---------

## 2.4 PV配置参数

### 2.4.1 Capacity，存储容量

描述存储设备具备的能力，定义存储空间，描述字段storage，如storage=10G

### 2.4.2 Volume Mode，存储卷模式

描述字段volumeMode，可选项Filesystem（文件系统）和Block（块设备），默认值FileSystem

### 2.4.3 Access Modes，访问模式

描述应用对存储资源的访问权限，一个PV支持多种访问模式，但挂载时只支持一种模式，可选项：

- ReadWriteOnce（RWO），读写权限，且只能被单个Node挂载
- ReadOnlyMany（ROX），只读权限，允许被多个Node挂载
- ReadWriteMany（RWX），读写权限，允许被多个Node挂载

---------

### 2.4.4 Class，存储类别

设定存储的类别，通过storageClassName参数指定给一个StorageClass资源对象的名称，具有特定类别的PV只能与请求了该类别的PVC进行绑定，未绑定类别的PV则只能与不请求任何类别的PVC进行绑定

### 2.4.5 Reclaim Policy，回收策略

描述字段persistentVolumeReclaimPolicy

- Retain，保留，保留数据，需手工处理
- Recycle，回收空间，简单清除文件的操作，如执行rm -rf /thevolume/*命令
- Delete，删除，与PV相连的后端存储完成Volume的删除操作。目前只有NFS和HostPath支持回收，其余只支持删除

---------

### 2.4.6 Mount Options，挂载选项

描述字段mountOptions，在将PV挂载到Node上时，根据后端存储的特点，可能需要设置额外的挂载参数，可根据PV定义中的mountOptions字段进行设置

### 2.4.7 Node Affinity，节点亲和性，仅用于Local存储卷

限制只能通过某些Node来访问Volume，描述字段nodeAffinity，使用这些Volume的Pod将被调度到满足条件的Node上

    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv001
    spec:
      accessModes:
        - ReadOnlyMany
      capacity:
        storage: 100Mi
      nfs:
        path: /data/web/html
        server: 192.168.100.100
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv002
    spec:
      accessModes:
        - ReadWriteMany
      capacity:
        storage: 1Gi
      persistentVolumeReclaimPolicy: Delete
      nfs:
        path: /data/log
        server: 192.168.100.100
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv003
    spec:
      accessModes:
        - ReadWriteOnce
      capacity:
        storage: 100Mi
      nfs:
        path: /data/log
        server: 192.168.100.100
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv004
      labels:
        app: nginx
    spec:
      accessModes:
        - ReadWriteMany
      capacity:
        storage: 1GMi
      persistentVolumeReclaimPolicy: Recycle
      nfs:
        path: /data/log/nginx
        server: 192.168.100.100
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      name: pv005
    spec:
      storageClassName: nfs
      accessModes:
        - ReadWriteMany
      capacity:
        storage: 500Mi
      nfs:
        path: /data/web
        server: 192.168.100.100
    ---
    apiVersion: v1
    kind: PersistentVolume
    metadata:
      # 设置PV名称
      name: pv006
      # 设置PV标签，用于PVC的定向绑定
      labels:
        app: tomcat
    spec:
      # 设置存储类别
      storageClassName: nfs
      # 设置访问模式
      accessModes:
        - ReadWriteMany
      # 设置PV的存储空间
      capacity:
        storage: 500Mi
      # 设置PV的回收策略
      persistentVolumeReclaimPolicy: Retain
      nfs:
        path: /data/web
        server: 192.168.100.100

## 2.5 PVC配置参数
 
### 2.5.1 Resources，资源请求

描述对存储资源的请求，目前仅支持request.storage的设置，即是存储空间的大小，PV的存储容量高于此值才能进行绑定，可用于PV的筛选

### 2.5.2 访问模式，AccessModes

用于描述对存储资源的访问权限，与绑定的PV一致，可用于PV的筛选

### 2.5.3 存储卷模式，Volume Modes

用于描述希望使用的PV存储卷模式，支持两种模式，即Filesystem（文件系统，默认值）模式和Block（块）模式

### 2.5.4 存储类，Class

PVC定义时可指定后端存储的类别，即storageClassName字段，从而减少对后端存储特性的详细信息的依赖。此时，只有设置了该Class的PV才能被系统选出，并与该PVC进行绑定

PVC也可不设置Class，若storageClassName字段的值被设置为空，即storageClassName=""，则表示该PVC不要求特定的存储，kubernetes集群将只选择未设定Class的PV与之匹配和绑定。若完全不设置storageClassName字段，将根据kubernetes集群是否启用了名为DefaultStorageClass的admission controller进行相应的操作

### 2.5.5 选择条件，Selector

用对PVC对PV的定向绑定，由matchLabels和matchExpressions字段这两个进行设置，若设置两个字段，则Selector的逻辑是所有条件同时满足才能完成匹配，包括Class

---------

- matchLabels，标签匹配

- matchExpressions，表达式匹配，通过键值对和运算符组合的表达式进行匹配，支持的运算符包括In、NotIn、Exists、DoesNotExist 

---------

    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: nginx-web
      namespace: default
    spec:
      accessModes:
      - ReadOnlyMany
      resources:
        requests:
          storage: 50Mi
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: nginx-log
      namespace: default
    spec:
      accessModes:
      - ReadWriteMany
      resources:
        requests:
          storage: 1Gi
      selector: 
        matchLabels:
          app: nginx
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: tomcat-log
      namespace: default
    spec:
      accessModes:
      - ReadWriteMany
      resources:
        requests:
          storage: 500Mi
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: tomcat-web
      namespace: default
    spec:
      # 设置PVC存储类别，用于指定存储类型
      storageClassName: nfs
      # 设置访问模式，匹配相同模式的PV
      accessModes:
      - ReadWriteMany
      # 设置PVC所申请存储空间的大小
      resources:
        requests:
          storage: 500Mi

# 3.StorageClass

StorageClass，即存储类，用于实现集群存储资源的动态供应，允许按需创建PV，在用户请求时自动供应，由集群自动完成PV的创建和绑定

集群管理员根据存储底层机制不同的特性和性能定义各种不同StorageClass对象，每个对象指定一个相应的供应器，即provisioner，供应器向卷供应商提供在创建卷时需要的数据卷信息及相关参数，并映射到不同的服务质量等级或备份策略，或是由集群管理员制定的任意策略。定义了storageClassName的PVC被创建申请资源时，相应的StorageClass对象被调用，根据定义好的传递给该驱动的参数将驱动启动，StorageClass的后端存储从而制备一个PV并进行绑定，最终实现了存储资源的动态创建

若PVC没有指定storageClassName，则会被绑定到由集群管理员设置的默认StorageClass。若集群准入控制器插件，即DefaultStorageClass未启用或未设置默认StorageClass，等效于PVC设置storageClassName的值为空，则只能绑定未设置Class的PV

## 3.1 配置参数

### 3.1.1 Provisioner，供应器

描述存储资源的提供者，可视为后端存储驱动，决定了动态创建PV时所用的卷插件，必选参数

### 3.1.2 Parameters，参数

描述存储类的卷，取决于后端存储供应器

### 3.1.3 Reclaim Policy，回收策略

由StorageClass动态供应的PV将继承该值，默认为Delete，删除PVC与之绑定的PV也将根据其默认的回收策略被删除，若需保留PV数据，则在动态绑定成功后手动将自动生成PV的回收策略改为Retain。通过StorageClass手动创建并管理的PV将会继承创建时指定的回收策略

### 3.1.4 Mount Options，挂载选项

由StorageClass动态供应的PV将继承该值，若卷插件不支持挂载选项却指定了挂载选项，则PV的制备操作就会失败

### 3.1.5 VolumeBindingMode，卷绑定模式

描述存储类制备PV及与PVC绑定的时间点，默认为Immediate，即创建PVC成功立即制备PV并完成两者的绑定。将该字段的值设置为WaitForFirstConsumer表示延迟PV的制备与绑定直到申请PVC的pod被成功创建，此时会根据pod调度指定的约束条件选择制备PV的时机，选择依据包括资源需求、节点筛选器、pod亲和性和互斥性以及污点和容忍度，适用于跨集群的业务场景

目前支持动态供应延迟绑定的插件有AWSElasticBlockStore、GCEPersistentDisk和AzureDisk，其余插件只支持预创建绑定PV的延迟绑定

## 3.2 设置默认StorageClass

### 3.2.1 启用DefaultStorageClass

    sudo vi /opt/kubernetes/cfg/kube-apiserver.conf


    --enable-admission-plugins=DefaultStorageClass

### 3.2.2 创建provisioner

    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: nfs-client-provisioner
      namespace: default
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: nfs-client-provisioner-runner
    rules:
      - apiGroups: [""]
        resources: ["persistentvolumes"]
        verbs: ["get", "list", "watch", "create", "delete"]
      - apiGroups: [""]
        resources: ["persistentvolumeclaims"]
        verbs: ["get", "list", "watch", "update"]
      - apiGroups: ["storage.k8s.io"]
        resources: ["storageclasses"]
        verbs: ["get", "list", "watch"]
      - apiGroups: [""]
        resources: ["events"]
        verbs: ["create", "update", "patch"]
    ---
    kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: run-nfs-client-provisioner
    subjects:
      - kind: ServiceAccount
        name: nfs-client-provisioner
        namespace: default
    roleRef:
      kind: ClusterRole
      name: nfs-client-provisioner-runner
      apiGroup: rbac.authorization.k8s.io
    ---
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: leader-locking-nfs-client-provisioner
      namespace: default
    rules:
      - apiGroups: [""]
        resources: ["endpoints"]
        verbs: ["get", "list", "watch", "create", "update", "patch"]
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: leader-locking-nfs-client-provisioner
      namespace: default
    subjects:
      - kind: ServiceAccount
        name: nfs-client-provisioner
        namespace: default
    roleRef:
      kind: Role
      name: leader-locking-nfs-client-provisioner
      apiGroup: rbac.authorization.k8s.io
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nfs-client-provisioner
      labels:
        app: nfs-client-provisioner
      namespace: default
    spec:
      replicas: 1
      strategy:
        type: Recreate
      selector:
        matchLabels:
          app: nfs-client-provisioner
      template:
        metadata:
          labels:
            app: nfs-client-provisioner
        spec:
          serviceAccountName: nfs-client-provisioner
          containers:
            - name: nfs-client-provisioner
              image: quay.io/external_storage/nfs-client-provisioner:latest
              volumeMounts:
                - name: nfs-client-root
                  mountPath: /persistentvolumes
              env:
                - name: PROVISIONER_NAME
                  # 设置nfs provisioner名称，storageclass需保持一致
                  value: nfs-client
                - name: NFS_SERVER
                  # 设置nfs服务器IP
                  value: 192.168.100.100
                - name: NFS_PATH
                  # 设置nfs路径
                  value: /data
          volumes:
            - name: nfs-client-root
              nfs:
                server: 192.168.100.100
                path: /data

### 3.2.3 创建默认StorageClass      

    vi sc.yaml


    apiVersion: storage.k8s.io/v1
	  kind: StorageClass
	  metadata:
      name: sc-nfs
      annotations:
        # 设置为集群默认storageclass
        storageclass.kubernetes.io/is-default-class: "true"
    # 设置动态卷供应器名称，对应供应器PROVISIONER_NAME
    provisioner: nfs-client
    parameters:
      # 设置PVC删除时保留PV数据
      archiveOnDelete: "true" 

- 注：集群中只能有一个默认StorageClass，否则将无法为PVC创建相应的PV

---------

    vi nginx-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment  
    spec:
      selector:
        matchLabels:
          app: nginx-servers
      replicas: 2
      template:
        metadata:
          labels:
            app: nginx-servers
        spec:
          containers:
            - name: nginx
              image: sword618/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: http-nginx
                  protocol: TCP
              ports:
              volumeMounts:
                - name: web
                  mountPath: /usr/share/nginx/html
                - name: logs
                  mountPath: /var/log/nginx
          volumes:
            - name: web
              persistentVolumeClaim:
                claimName: nginx-web
            - name: logs
              persistentVolumeClaim:
                claimName: nginx-log
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-service
    spec:
      type: NodePort
      sessionAffinity: ClientIP
      selector:
        app: nginx-servers
      ports:
      - port: 80
        targetPort: 80
        nodePort: 32000



vi tomcat-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: tomcat-deployment  
    spec:
      selector:
        matchLabels:
          app: tomcat-servers
      replicas: 2
      template:
        metadata:
          labels:
            app: tomcat-servers
        spec:
          containers:
            - name: tomcat
              image: sword618/tomcat
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 8080
                  name: http-tomcat
                  protocol: TCP
              ports:
              volumeMounts:
                - name: web
                  mountPath: /usr/local/tomcat/webapps
                - name: logs
                  mountPath: /usr/local/tomcat/logs
          volumes:
            - name: web
              persistentVolumeClaim:
                claimName: tomcat-web
            - name: logs
              persistentVolumeClaim:
                claimName: tomcat-log
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: tomcat-service
    spec:
      type: NodePort
      selector:
        app: tomcat-servers
      ports:
      - port: 8080
        targetPort: 8080
        nodePort: 32080

# 4.ConfigMap

ConfigMap，即配置项，用于将非机密性的配置数据存储于键值对,实现了环境配置信息和容器镜像的解耦，将容器化的应用与其配置信息分离，避免因应用的配置修改而重新构建镜像的操作。ConfigMap文件大小被限制为1M，且只能被相同namespace的pod引用，若pod引用了不存在的configmap则pod的创建将会失败

## 4.1 创建configmap

### 4.1.1 键值对创建方式

    kubectl create configmap redis-conf-001 --from-literal=maxclients=1024 --from-literal=requirepass=redis

### 4.1.2 yaml资源文件创建方式

    # 类属性键值对
    vi configmap-redis002.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: redis-conf-002
    data:
      maxclients: "1024"
      requirepass: "redis"

---------

    # 类文件键值对
    vi configmap-redis003.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: redis-conf-003
    data:
      redis.conf: |
        maxclients  1024
        requirepass redis

### 4.1.3 配置文件创建方式

    # 单个文件方式
    kubectl create configmap nginx-conf-001 --from-file=nginx.conf
    # 整个目录方式，但不含子目录
    kubectl create configmap nginx-conf-002 --from-file=/etc/nginx/conf.d

## 4.2 pod引用configmap

configmap有三种引用方式，即环境变量、容器启动命令行参数和数据卷文件

### 4.2.1 环境变量方式

    # 引用单个configmap
    vi redis001.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: redis001
    spec:
      containers:
        - name: redis-server
          image: sword618/redis
          imagePullPolicy: IfNotPresent
          env:
            - name: passwd
              valueFrom:
                configMapKeyRef:
                  name: redis-conf-001
                  key: requirepass

    # 引用多个configmap
    vi redis002.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: redis002
    spec:
      containers:
        - name: redis-server
          image: sword618/redis
          imagePullPolicy: IfNotPresent
           env:
            - name: passwd
              valueFrom:
                configMapKeyRef:
                  name: redis-conf-001
                  key: requirepass
            - name: maxclients
              valueFrom:
                configMapKeyRef:
                  name: redis-conf-002
                  key: maxclients

    # 引用所有键值对
    vi redis003.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: redis003
    spec:
      containers:
        - name: redis-server
          image: sword618/redis
          imagePullPolicy: IfNotPresent
          envFrom:
          - configMapRef:
              name: redis-conf-002

### 4.2.2 容器启动命令参数方式

    vi redis004.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: redis004
    spec:
      containers:
        - name: redis-server
          image: sword618/redis
          imagePullPolicy: IfNotPresent
          command: [ "/usr/bin/redis-server" ]
          args: ["--requirepass","$(requirepass)","--maxclients","$(maxclients)"]
          envFrom:
          - configMapRef:
              name: redis-conf-001

### 4.2.3 数据卷文件方式

    vi redis005.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: redis005
    spec:
      containers:
      - name: redis-server
        image: sword618/redis
        volumeMounts:
        - name: redis-conf
          mountPath: /etc/redis
          readOnly: true
      volumes:                                       
      - name: redis-conf
        configMap:
          name: redis-conf-003

---------

    vi nginx001.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx001
    spec:
      containers:
      - name: nginx-server
        image: sword618/nginx
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx
          readOnly: true
      volumes:                                       
      - name: nginx-conf
        configMap:
          name: nginx-conf-001

---------

    vi nginx002.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx002
    spec:
      containers:
      - name: nginx-server
        image: sword618/nginx
        volumeMounts:
        - name: nginx-conf
          mountPath: /etc/nginx
          readOnly: true
      volumes:                                       
      - name: nginx-conf
        configMap:
          name: nginx-conf-001

# 5.Secret

Secret，包含少量敏感信息如密码、令牌或密钥的对象。这类信息当然可被放在Pod规约或者镜像中，但存储于Secret由于有加密措施就大大减少了机密暴露的风险

Secret类型由type字段设置，默认为Opaque

- Opaque，集群用户创建的base64编码格式的数据，用于存储密码、密钥等，但数据可通过base64–decode解码得到原始数据，加密性不强
- Service Account，集群内置的服务账户，用于访问API对象的权限分配，由Kubernetes集群自动创建和挂载
- kubernetes.io/dockerconfigjson，用于存储私有镜像库的认证信息
- kubernetes.io/basic-auth，基本身份认证数据，用于存储基本身份认证所需的凭据信息
- kubernetes.io/ssh-auth，SSH身份认证数据，用于存储SSH身份认证所需的凭据
- kubernetes.io/tls，SSL证书数据，用于存储证书及相关密钥，提供给Ingress用以终结TLS链接，也可以用于其他资源或者负载

---------

## 5.1 启用静态Secret数据加密

    sudo vi /opt/kubernetes/cfg/kube-apiserver.conf


    --experimental-encryption-provider-config

## 5.2 创建secret

### 5.2.1 键值对方式

    kubectl create secret generic redis-auth --from-literal=requirepass='redis'

## 5.2.2 文件方式

    kubectl create secret tls nginx-ssl --key=nginx.key --cert=nginx.crt
    kubectl create secret generic ssh-key --from-file=ssh-privatekey=id_rsa --from-file=ssh-publickey=id_rsa.pub
    kubectl create secret generic regcred --from-file=.dockerconfigjson=config.json --type=kubernetes.io/dockerconfigjson

## 5.2.3 yaml资源文件方式

    # 将认证信息转换为base64编码格式，以密文存储
    echo -n 'admin' | base64
    YWRtaW4=
    echo -n 'nginx' | base64
    bmdpbng=

    vi nginx-auth.yaml


    apiVersion: v1
    kind: Secret
    metadata:
      name: nginx-auth
    type: kubernetes.io/basic-auth
    stringData:
      username: YWRtaW4=
      password: bmdpbng=

## 5.3 pod引用Secret

### 5.3.1 环境变量方式

    vi redis.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: redis
    spec:
      containers:
      - name: redis-server
        image: sword618/redis
        command: [ "/usr/bin/redis-server" ]
        args: ["--requirepass","$(requirepass)"]
        env:
          - name: requirepass
            valueFrom:
              secretKeyRef:
                name: redis-auth
                key: requirepass

### 5.3.1 数据卷文件方式

    vi nginx.yaml


    apiVersion: v1
    kind: Pod
    metadata: 
      name: nginx
    spec:
      containers:
      - name: nginx-server
        image: sword618/nginx
        imagePullPolicy: IfNotPresent
        volumeMounts:
        - name: nginx-cert
          mountPath: /etc/nginx/ssl
          readOnly: true
        - name: nginx-auth
          mountPath: /etc/nginx/auth
          readOnly: true
      volumes:
      - name: nginx-cert
        secret:
          secretName: nginx-ssl
      - name: nginx-auth
        secret:
          secretName: nginx-auth

---------

### 参考文档

- https://blog.51cto.com/ylw6006/2068953
- https://zhuanlan.zhihu.com/p/347526819
- https://www.cnblogs.com/xull0651/p/15457326.html
- https://blog.csdn.net/ljx1528/article/details/119382467
- https://blog.csdn.net/Micky_Yang/article/details/108308772
- https://blog.csdn.net/star1210644725/article/details/112416760
- https://blog.csdn.net/weixin_43114954/article/details/120296-687
- https://kubernetes.io/zh/docs/concepts/storage/persistent-volumes