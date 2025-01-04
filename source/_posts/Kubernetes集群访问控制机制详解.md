---
title: Kubernetes集群访问控制机制详解
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2022-03-31 22:51:26
---

Kubernetes集群一切皆API对象，所有操作和组件之间的通信及外部用户命令都是通过调用API Server进行处理。因此，API Server对集群的访问请求进行身份认证与鉴权即可实现整个集群的权限管理，也即是Kubernetes API访问控制

---------

# 访问控制流程

- Authentication，即认证，客户端与API Server建立TLS后，API Server身份认证组件将判断该请求的用户是否为能够访问集群的合法用户，若为非
法用户，则返回401状态码，并终止该请求
- Authorization，即鉴权，API Server将判断该请求的用户是否有权限进行请求中的操作，若无权限，则返回403的状态码，并终止该请求
- AdmissionControl，即准入控制，API Server的admission控制器将判断该请求是否是一个安全合规的请求，若验证通过，则访问控制流程结束，并
将该请求转换为Kubernetes objects相应的变更请求，最终写入到ETCD

# 1.Authentication

Kubernetes集群用户分为两类，即由集群管理的服务账号和普通账户，认证策略即是对这两类用户进行相关认证。普通账户对应于集群用户，由集群管理员分配私钥，私钥保存于~.kube/config，执行kubectl命令时自动读取以供API Server认证；服务账户对应于pod，由Kubernetes API自动创建及管理，且与secret资源关联挂载到pod，作为访问API Server的凭证

认证策略有8种，可以启动一种或多种认证方式，只要有一种认证方式通过即为认证通过，不再对其它方式认证

## 1.1 X509客户端证书

客户端向API Server传递SSL证书即启用客户端证书身份认证，若证书验证通过，则subject中的公共名称，即Common Name，就被作为请求的用户名，
该用户即为普通用户

    # 使用用户名test00生成一个证书签名请求（CSR），且该用户属于test和dev两个用户组
    openssl req -new -key test00.pem -out test00-csr.pem -subj "/CN=test/O=test/O=dev"

## 1.2 Service Account，服务账户令牌

通常由API Server自动创建并通过ServiceAccount准入控制器挂载到集群中运行的Pod上，允许集群内进程与API Server通信

## 1.3 Static Token，静态令牌

token文件是至少包含3列的csv格式文件，即token, user name, user uid，group（可选）,具体格式为：token,user,uid,"group1,group2,group3"

## 1.4 Bootstrap Tokens，引导令牌

主要用于新建集群或在现有集群中添加新节点，支持kubeadm，被定义为bootstrap.kubernetes.io/token类型的Secret，存储于 kube-system命名空间中，被API Server上的启动引导认证组件（Bootstrap Authenticator）读取

## 1.5 OpenID Connect（OIDC）令牌

主要用于OAuth2认证机制，如Azure Active Directory

## 1.6 Webhook令牌

即具有回调机制的认证策略

## 1.7 Authenticating Proxy

即认证代理，从请求的头部字段值如X-Remote-User辩识用户，身份认证代理负责设置请求的头部字段值

## 1.8 Basic Authentication

即基本身份认证，API Server将于请求头加入Basic BASE64ENCODED(USER:PASSWORD)

# 2.Authorization

客户端请求通过认证之后，API Server将根据所有授权策略匹配该请求的属性，所有部分都必须被某些策略允许才能决定允许或拒绝。客户端请求属性包含请求者用户名、请求对象及请求操作等。授权策略由授权模块定义，若集群配置了多个鉴权模块，则将按顺序进行匹配

## 2.1 客户端请求属性

### 2.1.1 请求用户及其所属组

- 用户，身份验证环节提供并通过的user
- 组，通过身份验证的用户所属组列表
- 额外信息，由身份验证环节提供的任意字符串键到字符串值的映射

### 2.1.2 请求对象

请求对象即是该次请求所申请的集群资源对象，分为API资源和非资源端点两类

#### API资源对象

- API，请求所对应的API资源
- API组，请求API资源的所属组，空字符串表示核心API组
- 命名空间，即namespace，请求所对应的API对象所属命名空间
- resource，即该次请求的集群对象的ID或名称，如pod、service等，对于get、update、patch和delete的资源请求，须提供资源名称的子资源

#### 非资源端点

- 请求路径，非资源端点的路径，如/api或/healthz

### 2.1.3 请求操作

#### API请求操作，用于API资源对象的请求，即是对所请求的集群资源对象的操作

- POST请求，对应于API资源对象的create
- GET、HEAD请求，对应于单个API资源对象的get或集合资源的ist
- PUT请求，对应于API资源对象的update
- PATCH请求，对应于API资源对象的patch
- DELETE请求，对应于单个API资源对象的delete或集合资源的deletecollection

#### HTTP请求操作，用于非资源端点的请求，类似于HTTP请求的方法，如get、post、put、delete等

## 2.2 RABC授权策略

集群的授权策略由授权模块定义，可用的授权模块有6个，其中RBAC模块为集群默认强制开启且最为完善。RBAC，即Role Based Access Control，基于角色的访问控制，由rbac.authorization.k8s.io API资源组驱动鉴权，通过API动态配置策略

### 鉴权流程

- 定义角色资源对象，角色是集群内某些资源（apiGroups、resources）的操作（verbs）权限的集合，即为对象及对其的操作动作。角色分为Role
和ClusterRole两类，前者属于命名空间级别，后者属于集群级别

- 定义角色绑定资源对象，即是将角色绑定到某个主体（subject），从而继承了角色的操作权限。主体为某个用户（User）、用户组（Group）、服务账号（ServiceAccount），角色绑定对应于角色，也分为两类，即RoleBinding，将Role绑定到主体；ClusterRoleBinding，将Role和ClusterRole绑定到主体

### 优势特点

对集群中的资源和非资源权限均有完整的覆盖，能够做到精细控制整个授权流程完全由几个API对象完成，同其他API对象一样，可用kubectl或API进行操作支持在运行时进行调整，无须重新启动API Server

## 2.1 创建用户

### 2.1.1 创建普通用户

    # 普通用户user001创建私钥
    openssl genrsa -out user001.key 2048
 
    # 根据私钥创建csr(证书签名请求)文件
    openssl req -new -key user001.key -subj "/CN=user001/O=user00" -out user001.csr

    # 根据私钥和csr文件生成证书
    openssl x509 -req -in user001.csr -CA /opt/kubernetes/ssl/ca.pem -CAkey /opt/kubernetes/ssl/ca-key.pem -CAcreateserial -out user001.crt -days 365

    # 创建集群普通用户user001，将其认证信息写入kubeconfig
    kubectl config set-credentials user001 --client-certificate=./user001.crt --client-key=./user001.key --embed-certs=true

    # 设置上下文， 默认会保存在$HOME/.kube/config
    kubectl config set-context user001@kubernetes --cluster=kubernetes --user=user001

    # 查看当前上下文
    kubectl config get-contexts

    # 切换上下文，即切换user001为当前用户
    kubectl config use-context user001@kubernetes

    # 查看当前上下文
    kubectl config get-contexts

    # 执行测试命令
    kubectl get nodes

### 2.1.2 创建服务账户

    kubectl create serviceaccount sa001
    # serviceaccount新增secret
    kubectl patch serviceaccount sa001 -p '{"imagePullSecrets": [{"name": "myregistrykey"}]}'
    # 创建绑定sa的pod，使其认证私有仓库
    vi nginx-sa001.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx-sa001
    spec:
      containers:
      - name: nginx
        image: sword618/nginx
        imagePullPolicy: IfNotPresent
    serviceAccountName: sa001

## 2.2 创建角色

### 2.2.1 角色配置参数

- APIGroup，即角色所作用的API资源组，可选项：“”,“apps”, “autoscaling”, “batch”

- Resource，即角色所作用的资源对象，可选项：“services”, “endpoints”, “pods”,“secrets”,“configmaps”,“crontabs”,“deployments”,“jobs”,“nodes”,“rolebindings”,“clusterroles”,“daemonsets”,“replicasets”,“statefulsets”,“horizontalpodautoscalers”,“replicationcontrollers”,“cronjobs”

- Verbs，即角色的动作权限，可选项：“get”, “list”, “watch”, “create”, “update”, “patch”, “delete”, “exec”

### 2.2.2 创建Role

    vi role.yaml


    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      namespace: test
      name: role-default-all
    rules:
      - apiGroups:
        - "*"
        resources:
        - pods
        - deployments
        - services
        verbs:
        - get
        - watch
        - list
        - create
        - delete
        - update
        - patch
        - exec
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      namespace: default
      name: role-default-log
    rules:
    - apiGroups: [""]
      # 设置角色所作用集群对象为子资源
      resources: ["pods", "pods/log","pods/status"]
      verbs: ["get", "list"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      namespace: default
      name: role-default-redis-conf-update
    rules:
    - apiGroups: [""]
      # 设置角色所作用集群对象为某个指定的对象实例
      resources: ["configmaps"]
      resourceNames: ["redis-conf"]
      verbs: ["update", "get"]

### 2.2.3 创建ClusterRole

    vi clusterrole.yaml


    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: clusterrole-read
    rules:
      - apiGroups: [""]
        # 设置角色所作用集群对象为集群所有资源
        resources: ["*"]
        verbs: ["get", "watch", "list"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: clusterrole-nodes-read
    rules:
      - apiGroups: [""]
      # 设置角色所作用集群对象为node
      resources: ["nodes"]
      verbs: ["get", "list", "watch"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: clusterrole-nonresource
    rules:
      # 设置角色所作用集群对象为非资源端点，支持通配符
      - nonResourceURLs: ["/healthz", "/healthz/*"]
        verbs: ["get", "post"]

## 2.3 创建角色绑定

### 2.3.1 创建RoleBinding

    vi user-role.yaml

    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: user001-role
      namespace: default
    # 设置角色绑定的主体，可指定多个
    subjects:
    - kind: User
      # 设置角色绑定所作用的用户
      name: user001
      apiGroup: rbac.authorization.k8s.io
    - kind: ServiceAccount
      name: kube-system-sa-default
      # 设置角色绑定所作用的服务账户，即kube-system命名空间的默认服务账户
      namespace: kube-system
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      kind: Role
      # 设置绑定的角色为Role，引用Role名称
      name: role-default-all
      apiGroup: rbac.authorization.k8s.io
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: user002-role
    subjects:
    - kind: Group
      name: user002
      apiGroup: rbac.authorization.k8s.io
    - kind: Group
      # 设置角色绑定所作用的服务账户，即所有命名空间的服务账户
      name: system:serviceaccounts
      apiGroup: rbac.authorization.k8s.io
    roleRef:
      # 设置绑定的角色为ClusterRole，用于跨命名空间的整个集群的授权
      kind: ClusterRole
      name: clusterrole-read
      apiGroup: rbac.authorization.k8s.io

### 2.3.2 创建ClusterRoleBinding

    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: user003-role
    subjects:
    - kind: Group
      # 设置角色绑定所作用的用户，即所有已通过认证的用户
      name: system:authenticated
      apiGroup: rbac.authorization.k8s.io
    - kind: Group
      # 设置角色绑定所作用的服务账户，即default命名空间中属于dev组的所有服务账户
      name: system:serviceaccounts:dev
      apiGroup: rbac.authorization.k8s.io
      namespace: default
    roleRef:
       kind: ClusterRole
      name: clusterrole-nonresource
      apiGroup: rbac.authorization.k8s.io

# 3.AdmissionControl

客户端请求通过认证和鉴权之后，就将进入准入控制流程，作用是拦截掉某些不合规的请求。拦截规则由准入控制器决定，准入控制器由一系列插件
构成，由集群管理员配置，若请求被任一控制器拒绝，则整个请求将立即被拒绝，并向客户端返回错误码。此外，准入控制器还能够修改请求参数以完
成一些自动化的任务，比如Service Account这个控制器
准入控制器插件通过apiserver组件配置，具体配置项是admission_control，其值为一串逗号连接的插件名称，集群默认启用的准入控制器插件查询命令为：kube-apiserver -h | grep enable-admission-plugins

## 常用准入控制器

- AlwaysPullImages，修改新创建pod的镜像拉取策略为Always，用于多租户集群，表明私有镜像只能被有凭证的人使用，否则任何用户的pod都可通过已拉取到节点上的镜像
- DefaultStorageClass，用于设定默认存储类
- DefaultIngressClass，用于设定默认Ingress类
- EventRateLimit，用于设定事件速率限制，缓解API Server的压力，即根据命名空间、用户等条件设置相应的API Server的QPS等
- NamespaceAutoProvision，用于自动创建命名空间的集群，即请求的命名空间不存在时自动创建
- NamespaceExists，用于剔除访问集群不存在的命名空间的请求
- NamespaceLifecycle，用于确保处于Termination状态的命令空间不再接收新对象创建请求，并拒绝请求不存在的命名空间，还可以防止删除系统保留的命名空间，如default、kube-system、kube-public等，建议开启
- NodeRestriction，用于设定kubelet修改node与pod的限制条件，即只可修改绑定到node本身的Pod
- PersistentVolumeClaimResize，用于额外验证PVC容量调整的请求，与ExpandPersistentVolumes配合使用
- ServiceAccount，用于实现ServiceAccount的自动化，使用服务账户的集群建议开启
- TaintNodesByCondition，用于给新建节点添加NotReady和NoSchedule污点，防止静态条件的发生，避免Pod在更新节点污点以准确反映其所报告状况之前就被调度到新节点上

---------

# 参考文档

- https://www.orchome.com/1308
- http://docs.kubernetes.org.cn/51.html
- https://blog.csdn.net/qq_35745940/article/details/120693490
- https://blog.csdn.net/weixin_43936969/article/details/106318259
- https://kubernetes.io/zh/docs/concepts/security/controlling-access