---
title: Kubernetes实战之部署Cloudreve云存储系统
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - Cloudreve
  - 存储
  - 云存储
  - 分布式存储
  - 云原生
  - 容器云
  - 云计算
date: 2022-12-20 12:18:11
---

# 1.部署Mysql数据库

# 2.部署nfs

# 3.部署StorageClass

# 4.配置镜像仓库免密拉取

# 4.1 创建镜像仓库认证文件

    sudo docker login
    sudo docker login registry.sword.org
    sudo docker login ccr.ccs.tencentyun.com
    sudo docker login registry.cn-hangzhou.aliyuncs.com

### 4.2 创建镜像拉取密钥

    kubectl create secret generic regcred \
      --from-file=.dockerconfigjson=/root/.docker/config.json \
      --type=kubernetes.io/dockerconfigjson

# 5.部署Redis缓存服务

## 5.1 创建配置文件

    vi redis-conf.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: redis-conf
    data:
      maxclients: "1024"
      dir: "/var/lib/redis"
      dbfilename: "dump.rdb"

## 5.2 创建redis持久化存储资源部署文件

    vi redis-data.yaml


    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: redis-data
      namespace: default
    spec:
      # 设置PVC StorageClassName
      storageClassName: sc-nfs
      accessModes:
      - ReadWriteMany
      resources:
        requests:
          storage: 10Gi

## 5.3 创建redis应用资源部署文件

    vi redis-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: redis-deployment  
    spec:
      selector:
        matchLabels:
          app: redis-servers
      replicas: 1
      template:
        metadata:
          labels:
            app: redis-servers
        spec:
          containers:
            - name: redis
              image: registry.cn-hangzhou.aliyuncs.com/swords/redis
              imagePullPolicy: IfNotPresent
              command: [ "/usr/bin/redis-server" ]
              args: ["--requirepass","$(requirepass)","--dir","$(dir)"]
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
                  name: tcp-redis
                  protocol: TCP
              resources:
                  limits:
                    cpu: 500m
                  requests:
                    cpu: 200m
              volumeMounts:
                - name: redis-data
                  mountPath: /var/lib/redis
          volumes:
            - name: redis-data
              persistentVolumeClaim:
                claimName: redis-data
          # 设置镜像拉取认证密钥
          imagePullSecrets:
            - name: regcred
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: redis-service
    spec:
      selector:
        app: redis-servers
      ports:
      - port: 6379
        targetPort: 6379

## 5.4 部署redis服务

    # 部署redis认证密钥
    kubectl create secret generic redis-auth --from-literal=requirepass='redis'
    # 部署配置文件
    kubectl apply -f redis-conf.yaml
    # 部署数据持久化存储
    kubectl apply -f redis-data.yaml
    # 部署redis
    kubectl apply -f redis-deployment.yaml

# 6.部署Cloudreve

## 6.1 创建配置文件

    vi conf.ini


    [System]
    Debug = false
    Mode = master
    Listen = :5212
    SessionSecret = fVVTsAm06i7YQjE0uX6dEhgNarFd6Bfg0BNceMT6n3jI0l7TGHMlqobQ235NksNu
    HashIDSalt = l5j19NsR47owEy0qQcL0IUKSgsy1Zc4tMophQ6Rane72he0AIySBWXsYAlRsYomN

    [Database]
    Type = mysql
    Port = 3306
    User = cloudreve
    Password = cloudreve
    Host = 192.168.100.120
    Name = cloudreve
    TablePrefix = sword_

    [Redis]
    Server = redis-service:6379
    Password = redis
    DB = 3

## 6.2 创建持久化存储资源部署文件

    vi cloudreve-data.yaml


    apiVersion: v1
    kind: PersistentVolume
    metadata:
      # 设置PV名称
      name: cloudreve-data
      # 设置PV标签，用于PVC的定向绑定
      labels:
        app: cloudreve-data
    spec:
      # 设置存储类别
      storageClassName: nfs
      # 设置访问模式
      accessModes:
        - ReadWriteMany
      # 设置PV的存储空间
      capacity:
        storage: 500Gi
      # 设置PV的回收策略
      persistentVolumeReclaimPolicy: Retain
      nfs:
        path: /web/cloudreve/data
        server: 192.168.100.200
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: cloudreve-data
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
          storage: 500Gi
      selector: 
        matchLabels:
          app: cloudreve-data

## 6.3 创建cloudreve应用资源部署文件

    vi cloudreve-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: cloudreve-deployment  
    spec:
      selector:
        matchLabels:
          app: cloudreve-servers
      replicas: 1
      template:
        metadata:
          labels:
            app: cloudreve-servers
        spec:
          containers:
            - name: cloudreve
              image: cloudreve/cloudreve
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 5212
                  name: tcp-cloudreve
                  protocol: TCP
              resources:
                  limits:
                    cpu: 500m
                  requests:
                    cpu: 200m
              volumeMounts:
                - name: cloudreve-conf
                  mountPath: /cloudreve/conf.ini
                  subPath: conf.ini
                - name: data
                  mountPath: /data
          volumes:
            - name: cloudreve-conf
              configMap:
                name: cloudreve-conf
            - name: data
              persistentVolumeClaim:
                claimName: cloudreve-data
          # 设置镜像拉取认证密钥
          imagePullSecrets:
            - name: regcred
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: cloudreve-service
    spec:
      type: NodePort
      sessionAffinity: ClientIP
      selector:
        app: cloudreve-servers
      ports:
      - port: 5212
        targetPort: 5212
        nodePort: 32512

## 6.4 部署

    # 部署配置文件cloudreve
    kubectl create configmap cloudreve-conf --from-file=conf.ini
    # 部署数据持久化存储
    kubectl apply -f cloudreve-data.yaml
    # 部署cloudreve
    kubectl apply -f cloudreve-deployment.yaml

## 6.5 部署HPA

    kubectl autoscale deployment cloudreve-deployment --cpu-percent=90 --min=1 --max=3

# 7.部署Nginx

## 7.1 创建配置文件

    vi nginx-conf.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: nginx-conf
    data:
      cloudreve.conf: |
        server {
          listen       80;
          server_name  localhost;

          location / {
                                                       
          access_log  /var/log/nginx/cloudreve_access.log  main;
          error_log  /var/log/nginx/cloudreve_error.log;

          proxy_pass http://cloudreve-service:5212;

          }

          location /wiki {

            root  /web;
            autoindex on;
            charset utf-8;
            autoindex_exact_size off;
            autoindex_localtime on;

            access_log  /var/log/nginx/wiki_access.log  main;
            error_log  /var/log/nginx/wiki_error.log;

          }
        }

## 7.2 创建nginx应用资源部署文件

    vi nginx-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nginx-deployment  
    spec:
      selector:
        matchLabels:
          app: nginx-servers
      replicas: 1
      template:
        metadata:
          labels:
            app: nginx-servers
        spec:
          containers:
            - name: nginx
              image: registry.cn-hangzhou.aliyuncs.com/swords/nginx
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: tcp-nginx
                  protocol: TCP
              resources:
                  limits:
                    cpu: 500m
                  requests:
                    cpu: 200m
              volumeMounts:
                - name: nginx-conf
                  mountPath: /etc/nginx/nginx.conf
                  subPath: nginx.conf
                - name: nginx-logs
                  mountPath: /var/log/nginx
          volumes:
            - name: nginx-conf
              configMap:
                name: nginx-conf
            - name: nginx-logs
              hostPath:
                path: /var/log/nginx
          # 设置镜像拉取认证密钥
          imagePullSecrets:
            - name: regcred
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: nginx-service
    spec:
      type: NodePort
      selector:
        app: nginx-servers
      ports:
      - port: 80
        targetPort: 80
        nodePort: 30080

## 7.3 部署nginx

    # 部署主配置文件
    kubectl create configmap nginx-conf --from-file=nginx.conf
    # 部署配置文件
    kubectl apply -f nginx-confs.yaml
    # 部署nginx应用
    kubectl apply -f nginx-deployment.yaml

## 7.4 部署HPA

    kubectl autoscale deployment nginx-deployment --cpu-percent=90 --min=1 --max=3

# 8.验证cloudreve存储系统

    kubectl get pvc
    kubectl get svc
    kubectl get pod -o wide