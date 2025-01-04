---
title: Kubernetes集群调度策略详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 云原生
  - 容器云
  - 云计算
date: 2023-03-14 09:16:23
---


Sheduler，即调度器，负责整个集群的资源调度。默认情况下，Pod被调度到哪个节点运行是由Scheduler组件经过相应的算法计算所得，这个过程不受人工控制，由集群自动完成。但业务实际运行时，自动调度的结果可能并不能满足需求，如需要控制某些Pod到达某些特定的节点上。当然，这样人为控制调度策略将会额外增加资源分配时的计算开销，且复杂的调度规则也将加大管理及维护的成本，具体的配置还是要根据实际情况进行详尽的规划

kubernetes集群调度方式分为四种：

- 自动调度，运行在哪个节点上完全由Scheduler经过一系列的算法自动计算得出
- 定向调度，NodeName、NodeSelector
- 亲和性/反亲和性调度，NodeAffinity、PodAffinity、PodAntiAffinity
- 污点/容忍调度，Taints/Toleration

---------

# 1.自动调度

自动调度是Scheduler默认调度方式，经由一些列算法确定将Pod调度到哪些节点

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 200m
                  memory: 200Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
          imagePullSecrets:
            - name: regcred

# 2.定向调度

定向调度，即将Pod调度到指定的节点，带有强制性，也就是说即使所要调度的目标节点不存在或不可调度也要进行调度，调度的结果自然是失败的。定向调度有两种实现方式，即NodeName和NodeSelector

## 2.1 NodeName

NodeName，用于强制约束将Pod调度到指定Name的节点，即跳过Scheduler的调度逻辑直接将Pod调度到指定名称的节点。如匹配的节点不存在，则Pod运行失败

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 200m
                  memory: 200Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
          imagePullSecrets:
            - name: regcred
          nodeName: worker03

## 2.2 NodeSelector

NodeSelector，用于通过kubernetes的label-selector机制将Pod调度到添加了指定标签的节点，即由scheduler使用MatchNodeSelector调度策略匹配指定label的节点进行Pod调度，匹配规则具有强制性。如匹配的节点不存在，则Pod运行失败

### 2.2.1 节点新增标签

    kubectl label nodes worker01 worker=01
    kubectl label nodes worker02 worker=02
    kubectl label nodes worker03 worker=03
    kubectl label nodes worker02 app=jellyfin
    kubectl label nodes worker03 app=database

### 2.2.2 验证NodeSelector调度算法

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: jellyfin-deployment
    spec:
      selector:
        matchLabels:
          app: jellyfin-server
      replicas: 1
      template:
        metadata:
          labels:
            app: jellyfin-server
        spec:
          containers:
            - name: jellyfin
              image: registry.cn-hangzhou.aliyuncs.com/geekers/jellyfin:v10.8.5
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: tcp-jellyfin
                  protocol: TCP
              resources:
                limits:
                  cpu: 500m
                  memory: 512M
                requests:
                  cpu: 300m
                  memory: 500M
              volumeMounts:
              - mountPath: /etc/localtime
                name: localtime
              - mountPath: /media/cloud
                name: nfs-sword
              - mountPath: /config
                name: jellyfin-config
              - mountPath: /cache
                name: jellyfin-cache
          volumes:
          - hostPath:
              path: /etc/localtime
            name: localtime
          - name: nfs-sword
            persistentVolumeClaim:
              claimName: nfs-sword
          - name: jellyfin-config
            persistentVolumeClaim:
              claimName: jellyfin-ceph-config
          - name: jellyfin-cache
            persistentVolumeClaim:
              claimName: jellyfin-ceph-cache
          imagePullSecrets:
            - name: regcred 
          nodeSelector:
            app: jellyfin

### 2.2.3 删除节点标签，验证NodeSelector调度算法

    # 查看节点标签
    kubectl get nodes worker02 --show-labels
    # 删除节点的app标签
    kubectl label nodes worker02 app-
    # 删除任一pod，重新调度
    kubectl delete pod jellyfin-deployment-545d877bbc-c65pz

# 3.亲和性调度

亲和性调度，即Affinity，是基于NodeSelector调度策略的扩展，通过配置节点标签的匹配规则优先选择满足条件的Node进行调度，若匹配失败，则再调度到不满足条件的节点上，从而使得调度更加灵活。Affinity分为三类，即nodeAffinity、podAffinity、podAntiAffinity：

- nodeAffinity，node亲和性，即以node为目标决定pod可以调度到哪些Node上
- podAffinity，pod亲和性，即以正在运行的pod为参照目标，实现新创建的pod跟参照pod部署在同一区域
- podAntiAffinity，pod反亲和性，即以正在运行的pod为参照目标，实现新创建的pod不跟参照pod部署在同一区域

## 3.1 使用场景

- 亲和性，若两个应用频繁交互，则有必要利用亲和性调度策略将两者尽可能调度到同一节点，以减少因网络通信带来的性能损耗
- 反亲和性，若应用涉及多副本部署，则有必要采用反亲和性调度策略将各个应用实例打散分布到各个不同的节点，以提高服务的高可用性

## 3.2 标签匹配表达式

亲和性调度算法依据标签匹配表达式列出符合要求的节点列表，从而更灵活地完成调度，表达式可用的关系运算符有In、NotIn、Exists、 DoesNotExist、Gt、Lt，用法如下：

### 3.2.1 Exists

    - matchExpressions:
      # 匹配存在标签key为test的节点 
      - key: test
        operator: Exists

### 3.2.2 In

    - matchExpressions:
      # 匹配标签key为test，且value是"01"或"02"的节点 
      - key: test
        operator: In
        values: 
        - ["01","02"]

### 3.2.3 Gt
 
    - matchExpressions:
      # 匹配标签key为test，且value大于"01"的节点 
      - key: test
        operator: Gt
        values: 
        - "01"

---------

- 注：其余运算符的运算逻辑基本为上面三个的反例

## 3.3 nodeAffinity

### 3.3.1 硬亲和性策略

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis-deployment
    spec:
      selector:
        matchLabels:
          app: redis-server
      replicas: 1
      template:
        metadata:
          labels:
            app: redis-server
        spec:
          containers:
            - name: redis
              image: registry.sword.org/redis
              imagePullPolicy: IfNotPresent
              command: [ "/usr/bin/redis-server" ]
              args: ["--requirepass","$(requirepass)"]
              envFrom:
              - configMapRef:
                  name: redis-conf
              env:
                - name: requirepass
                  valueFrom:
                    secretKeyRef:
                      name: redis-auth
                      key: requirepass
              ports:
                - containerPort: 6379
                  name: redis-tcp
                  protocol: TCP
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 50m
                  memory: 64M
          imagePullSecrets:
            - name: regcred
          # 设置亲和性 
          affinity:
            # 设置node亲和性
            nodeAffinity:
              # 设置硬亲和性策略，即必须满足的匹配规则
              requiredDuringSchedulingIgnoredDuringExecution:
                # 设置节点选择列表
                nodeSelectorTerms:
                # 设置标签匹配表达式
                - matchExpressions:
                  - key: app
                    # 设置标签匹配规则，即匹配标签key为app且value值不为jellyfin的节点
                    operator: NotIn
                    values: 
                    - jellyfin

 ### 3.3.2 软亲和性策略

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gitea-deployment
      namespace: devops
    spec:
      selector:
        matchLabels:
          app: gitea
      replicas: 1
      template:
        metadata:
          labels:
            app: gitea
        spec:
          containers:
            - name: gitea
              image: gitea/gitea
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 3000
                  name: gitea-http
                - containerPort: 22
                  name: gitea-ssh  
              resources:
                limits:
                  cpu: 300m
                  memory: 256M
                requests:
                  cpu: 200m
                  memory: 200M
              volumeMounts:
              - mountPath: /data
                name: gitea-data
              - name: localtime
                mountPath: /etc/localtime
          volumes:
          - name: gitea-data
            persistentVolumeClaim:
              claimName: gitea-data
          - name: localtime
            hostPath:
              path: /etc/localtime
          imagePullSecrets:
            - name: regcred
          # 设置亲和性 
          affinity:
            # 设置node亲和性
            nodeAffinity:
              # 设置软亲和性策略，即优先调度到满足指定规则的节点，若无满足规则的节点再调度到其他节点
              preferredDuringSchedulingIgnoredDuringExecution:
              # 设置策略权重，取值范围为1-100
              - weight: 1
                # 设置节点选择器
                preference: 
                  # 设置标签匹配表达式
                  matchExpressions:
                  - key: worker
                    # 设置标签匹配规则，即匹配标签key为worker且value值大于01的节点
                    operator: Gt
                    values: 
                    - "01"

### 3.3.3 注意事项

- 若同时定义了nodeSelector和nodeAffinity，则须两个条件都得到满足才能调度到指定的Node
- 若nodeAffinity指定了多个nodeSelectorTerms，则只需其中一个能够匹配成功即可
- 若nodeSelectorTerms有多个matchExpressions，则节点须全部满足才能匹配成功
- 若Pod所在的节点在Pod运行期间标签发生了改变，不再符合该Pod节点的亲和性需求，则将忽略此变化，不再重新调度

## 3.4 podAffinity

    # 查看Pod标签
    kubectl get pod redis --show-labels

### 3.4.1 硬亲和性策略

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: cloudreve-deployment
    spec:
      selector:
        matchLabels:
          app: cloudreve-server
      replicas: 1
      template:
        metadata:
          labels:
            app: cloudreve-server
        spec:
          containers:
            - name: cloudreve
              image: registry.sword.org/cloudreve
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 5212
                  name: cloudreve-tcp
                  protocol: TCP
              resources:
                limits:
                  cpu: 200m
                  memory: 512M
                requests:
                  cpu: 100m
                  memory: 300M
              volumeMounts:
              - mountPath: /cloudreve/conf.ini
                name: cloudreve-conf
                subPath: conf.ini
              - mountPath: /home/sword
                name: nfs-sword
          volumes:
          - configMap:
              name: cloudreve-conf
            name: cloudreve-conf
          - name: nfs-sword
            persistentVolumeClaim:
              claimName: nfs-sword
          imagePullSecrets:
            - name: regcred
          # 设置亲和性 
          affinity:
            # 设置pod亲和性
            podAffinity:
              # 设置硬亲和性策略，即必须满足的匹配规则
              requiredDuringSchedulingIgnoredDuringExecution:
                # 设置Pod标签选择器
              - labelSelector:
                # 设置Pod标签匹配表达式
                  matchExpressions:
                  - key: app
                    # 设置Pod标签匹配规则，即匹配标签key为app且value值为redis-server的Pod作为调度目标
                    operator: In
                    values: 
                    - "redis-server"
                  - key: app
                    # 设置Pod标签匹配规则，即匹配标签key为app且value值不为jellyfin的Pod作为调度目标
                    operator: NotIn
                    values: 
                    - "jellyfin-server"
                # 设置调度作用域
                topologyKey: kubernetes.io/hostname
            # 设置node亲和性
            nodeAffinity:
              # 设置软亲和性策略，即优先调度到满足指定规则的节点，若无满足规则的节点再调度到其他节点
              preferredDuringSchedulingIgnoredDuringExecution:
              # 设置策略权重，取值范围为1-100
              - weight: 1
                # 设置节点选择器
                preference: 
                  # 设置标签匹配表达式
                  matchExpressions:
                  - key: app
                    # 设置标签匹配规则，即匹配标签key为app且value值为database的节点
                    operator: In
                    values: 
                    - "database"

### 3.4.2 软亲和性策略

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hexo-deployment
      namespace: devops
    spec:
      selector:
        matchLabels:
          app: hexo-server
      replicas: 1
      template:
        metadata:
          labels:
            app: hexo-server
        spec:
          containers:
            - name: hexo
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: hexo-nginx
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 100m
                  memory: 64M
              volumeMounts:
                - name: nginx-conf
                  mountPath: /etc/nginx/nginx.conf
                  subPath: nginx.conf
          volumes:
            - name: nginx-conf
              configMap:
                name: nginx.conf
          imagePullSecrets:
            - name: regcred
          # 设置亲和性 
          affinity:
            # 设置Pod亲和性
            podAffinity:
              # 设置软亲和性策略，即优以满足指定规则的Pod为目标进行调度，若无满足规则的Pod则按照集群自动调度
              preferredDuringSchedulingIgnoredDuringExecution:
                # 设置策略权重值，范围为1-100
                - weight: 1
                  # 设置标签列表
                  podAffinityTerm:
                    # 设置Pod标签选择器
                    labelSelector:
                      # 设置Pod标签匹配表达式
                      matchExpressions:
                        - key: app
                          # 设置Pod标签匹配规则，即匹配标签key为app且value值为jenkins的Pod作为调度目标
                          operator: In
                          values: 
                          - jenkins
                    # 设置调度作用域，以节点区分区域
                    topologyKey: kubernetes.io/hostname
            # 设置node亲和性
            nodeAffinity:
              # 设置硬亲和性策略，即必须满足的匹配规则
              requiredDuringSchedulingIgnoredDuringExecution:
                # 设置节点选择列表
                nodeSelectorTerms:
                # 设置标签匹配表达式
                - matchExpressions:
                  - key: app
                    # 设置标签匹配规则，即匹配没有标签key为app的节点
                    operator: DoesNotExist

## 3.5 PodAntiAffinity

### 3.5.1 硬反亲和性策略

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment
    spec:
      selector:
        matchLabels:
          app: nginx-server
      replicas: 3
      template:
        metadata:
          labels:
            app: nginx-server
        spec:
          containers:
            - name: nginx
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 200m
                  memory: 200Mi
                requests:
                  cpu: 100m
                  memory: 100Mi
              volumeMounts:
                - name: nginx-conf
                  mountPath: /etc/nginx/nginx.conf
                  subPath: nginx.conf
                - name: nginx-logs
                  mountPath: /var/log/nginx
                - name: nfs-sword
                  mountPath: /home/sword
          volumes:
            - name: nginx-conf
              configMap:
                name: nginx-conf
            - name: nginx-logs
              hostPath:
                path: /var/log/nginx
            - name: nfs-sword
              persistentVolumeClaim:
                claimName: nfs-sword
          imagePullSecrets:
            - name: regcred
          # 设置亲和性 
          affinity:
            # 设置pod反亲和性
            podAntiAffinity:
              # 设置硬反亲和策略，即必须满足的匹配规则
              requiredDuringSchedulingIgnoredDuringExecution:
                # 设置Pod标签选择器
              - labelSelector:
                # 设置Pod标签匹配表达式
                  matchExpressions:
                  - key: app
                    # 设置Pod标签匹配规则，即匹配标签key为app且value值为nginx-servers的Pod作为反向
                    # 调度目标，也即是使得副本Pod之间互斥，相互之间不在同一节点上，将之打散以保障其可用性
                    operator: In
                    values: 
                    - nginx-server
                # 设置调度作用域
                topologyKey: kubernetes.io/hostname
            # 设置Pod亲和性
            podAffinity:
              # 设置软亲和性策略，即优以满足指定规则的Pod为目标进行调度，若无满足规则的Pod则按照集群自动调度
              preferredDuringSchedulingIgnoredDuringExecution:
                # 设置策略权重值，范围为1-100
                - weight: 1
                  # 设置标签列表
                  podAffinityTerm:
                    # 设置Pod标签选择器
                    labelSelector:
                      # 设置Pod标签匹配表达式
                      matchExpressions:
                        - key: app
                          # 设置Pod标签匹配规则，即匹配标签key为test且value值为00的pod作为调度目标
                          operator: NotIn
                          values: 
                          - ["jellyfin","cloudreve"]
                        - key: app
                          # 设置Pod标签匹配规则，即匹配标签key为test且value值为00的pod作为调度目标
                          operator: In
                          values: 
                          - redis 
                    # 设置调度作用域，以节点区分区域
                    topologyKey: kubernetes.io/hostname

### 3.5.2 软亲和性策略

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: webos-deployment  
    spec:
      selector:
        matchLabels:
          app: webos-server
      replicas: 1
      template:
        metadata:
          labels:
            app: webos-server
        spec:
          containers:
            - name: webos
              image: registry.cn-hangzhou.aliyuncs.com/geekers/webos
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 8088
                  protocol: TCP
              resources:
                  limits:
                    cpu: 500m
                    memory: 300Mi
                  requests:
                    cpu: 300m
                    memory: 200Mi
              volumeMounts:
                - name: webos-root
                  mountPath: /webos/api/rootPath
                - name: webos-apps
                  mountPath: /webos/web/apps
                - name: webos-data
                  mountPath: /home/webos
          volumes:
            - name: webos-root
              persistentVolumeClaim:
                claimName: webos-root
            - name: webos-apps
              persistentVolumeClaim:
                claimName: webos-apps
            - name: webos-data
              persistentVolumeClaim:
                claimName: webos-data
          imagePullSecrets:
            - name: regcred
          # 设置亲和性 
          affinity:
            # 设置Pod反亲和性
            podAntiAffinity:
              # 设置软亲和性策略，即优以满足指定规则的Pod为目标进行反向调度
              preferredDuringSchedulingIgnoredDuringExecution:
                # 设置策略权重值，范围为1-100
                - weight: 1
                  # 设置标签列表
                  podAffinityTerm:
                    # 设置Pod标签选择器
                    labelSelector:
                      # 设置Pod标签匹配表达式
                      matchExpressions:
                        - key: app
                          # 设置Pod标签匹配规则，即匹配标签key为app且value值为jellyfin的pod作为调度目标
                          operator: In
                          values: 
                          - "jellyfin-server"
                    # 设置调度作用域
                    topologyKey: kubernetes.io/hostname
            podAffinity:
              # 设置软亲和性策略，即优以满足指定规则的Pod为目标进行调度，若无满足规则的Pod则按照集群自动调度
              preferredDuringSchedulingIgnoredDuringExecution:
                # 设置策略权重值，范围为1-100
                - weight: 1
                  # 设置标签列表
                  podAffinityTerm:
                    # 设置Pod标签选择器
                    labelSelector:
                      # 设置Pod标签匹配表达式
                      matchExpressions:
                        - key: app
                          # 设置Pod标签匹配规则，即匹配标签key为test且value值为00的pod作为调度目标
                          operator: In
                          values: 
                          - "cloud-server"
                    # 设置调度作用域，以节点区分区域
                    topologyKey: kubernetes.io/hostname
            # 设置node亲和性
            nodeAffinity:
              # 设置软亲和性策略，即优先调度到满足指定规则的节点，若无满足规则的节点再调度到其他节点
              preferredDuringSchedulingIgnoredDuringExecution:
              # 设置策略权重，取值范围为1-100
              - weight: 1
                # 设置节点选择器
                preference: 
                  # 设置标签匹配表达式
                  matchExpressions:
                  - key: app
                    # 设置标签匹配规则，即匹配具有标签key为app的节点
                    operator: Exists

# 4.污点和容忍调度

Kubernetes作为容器化云平台已经实现了资源的容器隔离，但目前容器隔离还不能做到宿主机资源100%的隔离，且平台层面对业务线占用资源的限制和隔离也大大增加了跨部门协同合作的沟通成本。污点和容忍配合的调度策略可妥善的解决此问题，即是通过对节点配置Taints和Tolerations，将资源需求不同的业务线Pod调度到各自独立的节点组，从而避免同一业务线的Pod被分配到不合适的节点，从而实现了不同业务线的物理隔离

- 污点，即Taints，节点避免被调度的属性，即不允许将Pod调度到配置了污点的节点，甚至还能将已经存在的Pod驱逐出去
- 容忍，即Tolerations，Pod对污点忽略的属性，即允许Pod被调度到有污点的节点
  
## 4.1 污点配置

污点的格式为:key=value:effect, 其中，key和value是污点的标签；effect描述污点的作用，支持三种选项：

- NoSchedule，不会将Pod调度到具有该污点的Node上，但不影响当前Node上已存在的Pod
- PreferNoSchedule，尽量避免将Pod调度到具有该污点的Node上，除非没有其他节点可调度
- NoExecute，不会将Pod调度到具有该污点的Node上，且还会将Node上已存在的Pod驱离

### 4.1.1 设置污点

    kubectl taint nodes master01 master=master01:NoExecute
    kubectl taint nodes worker01 worker=worker01:PreferNoSchedule

- 注：kubeadm引导的集群master节点已经被打上key为node-role.kubernetes.io/master且effect为NoSchedule的污点

### 4.1.2 删除污点

    kubectl taint nodes node01 key1=value1:NoSchedule-

## 4.2 容忍配置

Pod容忍属性匹配污点的原则是key、effect相同，且满足运算符为Exists或Equal时value相等，此外还存在两种特例：

- 若容忍的key为空且运算符为Exists，将会匹配所有的key、value和effect，即容忍所有污点
- 若一个key和一个空的effect匹配此key的所有effect

### 4.2.1 容忍所有污点

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 50m
                  memory: 50M
          imagePullSecrets:
            - name: regcred
          tolerations:
          - operator: "Exists"

### 4.2.2 容忍标签所有的污点

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 50m
                  memory: 50M
          imagePullSecrets:
            - name: regcred
          tolerations:
          - key: "worker"
            operator: "Exists" 

### 4.2.3 精确匹配容忍的污点

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: test-nginx
    spec:
      selector:
        matchLabels:
          app: test
      replicas: 3
      template:
        metadata:
          labels:
            app: test
        spec:
          containers:
            - name: nginx
              image: registry.sword.org/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: nginx
                  protocol: TCP
              resources:
                limits:
                  cpu: 100m
                  memory: 100M
                requests:
                  cpu: 50m
                  memory: 50M
          imagePullSecrets:
            - name: regcred
          tolerations:
          - key: "master"
            operator: "Equal" 
            value: "master01"
            effect: "NoExecute"

---------

# 参考文档

- https://www.jianshu.com/p/4e9c81607f95
- https://blog.csdn.net/qq_52397471/article/details/129093055
- https://cloud.tencent.com/developer/article/1815807?from=15425