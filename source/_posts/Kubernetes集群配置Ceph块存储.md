---
title: Kubernetes集群配置Ceph块存储
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - Ceph
  - 存储
  - 块存储
  - 云存储
  - 分布式存储
  - 云原生
  - 容器云
  - 云计算
date: 2023-07-12 15:50:21
---

# 1.Ceph集群创建存储池及账户，并授予权限

    ceph osd pool create kubernetes 128 128
    ceph osd pool application enable kubernetes rbd
    rbd pool init kubernetes

    sudo ceph auth get-or-create client.kubernetes mon 'allow r' osd 'allow class-read object_prefix rbd_children, allow rwx pool=kubernetes' -o /etc/ceph/ceph.client.kubernetes.keyring

# 2.Kubernetes集群worker节点配置ceph

## 2.1 安装ceph客户端

    sudo apt install -y ceph-common

## 2.2 Ceph集群密钥环发送worker节点

    scp -r /etc/ceph worker01:/etc
    scp -r /etc/ceph worker02:/etc
    scp -r /etc/ceph worker03:/etc

# 3.Kubernetes集群创建rbd provisioner

## 3.1 创建资源配置文件

    vi ceph-rbd-provisioner.yaml


    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: rbd-provisioner
      namespace: kube-system
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: rbd-provisioner
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
      - apiGroups: [""]
        resources: ["endpoints"]
        verbs: ["get", "list", "watch", "create", "update", "patch"]
      - apiGroups: [""]
        resources: ["services"]
        resourceNames: ["kube-dns"]
        verbs: ["list", "get"]
    ---
    kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: rbd-provisioner
    subjects:
      - kind: ServiceAccount
        name: rbd-provisioner
        namespace: kube-system
    roleRef:
      kind: ClusterRole
      ame: rbd-provisioner
      apiGroup: rbac.authorization.k8s.io
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: Role
    metadata:
      name: rbd-provisioner
      namespace: kube-system
    rules:
    - apiGroups: [""]
      resources: ["secrets"]
      verbs: ["get"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: rbd-provisioner
      namespace: kube-system
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: rbd-provisioner
    subjects:
    - kind: ServiceAccount
      name: rbd-provisioner
      namespace: kube-system
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: rbd-provisioner
      namespace: kube-system
    spec:
      selector:
        matchLabels:
          app: rbd-provisioner
      replicas: 1
      strategy:
        type: Recreate
      template:
        metadata:
          labels:
            app: rbd-provisioner
        spec:
          containers:
          - name: rbd-provisioner
            image: quay.io/external_storage/rbd-provisioner
            env:
            - name: PROVISIONER_NAME
              value: ceph-rbd
            resources:
              limits:
                cpu: 50m
                memory: 100Mi
              requests:
                cpu: 20m
                memory: 50Mi
            volumeMounts:
              - name: ceph-config
                mountPath: /etc/ceph
              - name: localtime
                mountPath: /etc/localtime
          volumes:
            - name: ceph-config
              hostPath:
                path: /etc/ceph
            - name: localtime
              hostPath:
                path: /etc/localtime
          serviceAccount: rbd-provisioner

## 3.2 创建rbd provisioner

    kubectl apply -f ceph-rbd-provisioner.yaml

# 4.Ceph集群查看账户密钥环

    # 管理员账户密钥环
    ceph auth get-key client.admin
    # kubernetes账户密钥环
    ceph auth get-key client.kubernetes

# 5.Kubernetes集群Ceph Storageclass

## 5.1 创建管理员账户secret

    kubectl create secret generic ceph-secret --type="kubernetes.io/rbd" \
    --from-literal=key=AQDaWq5kcpcgGxAAJrrD4pgmOUvCH1TE9a6taQ== \
    --namespace=kube-system

## 5.2 创建kubernetes账户secret

    kubectl create secret generic ceph-user-secret --type="kubernetes.io/rbd" \
    --from-literal=key=AQDaWq5kcpcgGxAAJrrD4pgmOUvCH1TE9a6taQ== \

## 5.3 创建资源配置文件

    vi sc-ceph-rbd.yaml


    kind: StorageClass
    apiVersion: storage.k8s.io/v1
    metadata:
      name: sc-ceph-rbd
    provisioner: ceph-rbd
    parameters:
      monitors: 192.168.100.108:6789,192.168.100.118:6789,192.168.100.128:6789
      adminId: admin
      adminSecretName: ceph-secret
      adminSecretNamespace: kube-system
      pool: kubernetes
      userId: kubernetes
      userSecretName: ceph-user-secret
      fsType: ext4
      imageFormat: "2"
      imageFeatures: "layering"

## 5.4 创建StorageClass

    kubectl apply -f sc-ceph-rbd.yaml

# 6.创建POD，测试Ceph StorageClass

## 6.1 创建PVC

### 6.1.1 创建资源配置文件

    vi nginx-ceph-pvc.yaml


    kind: PersistentVolumeClaim
    apiVersion: v1
    metadata:
      name: nginx-ceph-rbd
    spec:
      accessModes:     
        - ReadWriteOnce
      storageClassName: sc-ceph-rbd
      resources:
        requests:
          storage: 1Gi

### 6.1.2 创建PVC

    kubectl apply -f nginx-ceph-pvc.yaml

### 6.1.3 查看PV/PVC

    kubectl get pv
    kubectl get pvc

## 6.2 创建测试POD

### 6.2.1 创建资源配置文件

    vi nginx.yaml


    apiVersion: v1
    kind: Pod
    metadata:
      name: nginx
      labels:
        name: nginx
    spec:
      containers:
      - name: nginx
        image: nginx
        ports:
        - name: web
          containerPort: 80
        volumeMounts:
        - name: nginx-html
          mountPath: /usr/share/nginx/html
      volumes:
      - name: nginx-html
        persistentVolumeClaim:
          claimName: nginx-ceph-rbd

---------

# 参考文档

- https://blog.51cto.com/u_13710166/5290959