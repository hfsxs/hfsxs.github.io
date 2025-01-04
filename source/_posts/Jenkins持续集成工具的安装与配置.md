---
title: Jenkins持续集成工具的安装与配置
categories:
  - 工作
tags:
  - Linux
  - Jenkins
  - DevOps
  - CICD
  - Kubernetes
  - 容器云
  - 云原生
  - 云计算
date: 2023-01-03 10:04:48
---

DevOps，由Development和Operations组合而成，即开发 && 运维，是一组用于促进开发、运营和质量保障部门之间沟通、协作与整合的过程、方法与系统的统称

### 软件工程模型

软件系统的工程化贯穿了软件完整的生命周期，实质上就是将各项任务按照预定的框架与规程进行划分与整合，以便于清晰、直观地表达软件开发全过程，明确规定了要完成的主要活动和任务，即是软件工程模型

软件系统从零开始到最终交付大致包括如下阶段：规划、编码、构建、测试、发布、部署和维护，软件工程模型即是基于这些阶段不断进行改进与规范逐渐发展而来

##### 1.瀑布式流程

传统的软件工程开发方式，前期需求确立之后，软件开发人员花费数周和数月编写代码，把所有需求一次性开发完，然后将代码交给QA（质量保障）团队进行测试，最后将最终的发布版交给运维团队去部署。简单来说，就是等一个阶段所有工作完成之后再进入下一个阶段，由各个团队相互衔接完成整个项目的生命周期。该模式下整个软件开发流程其实是线性的孤岛式作业，产品迭代周期长，沟通成本高，灵活性差，周期动辄几周几个月，无法适应当下产品需求快速迭代的场景

##### 2.敏捷开发

将开发任务由大拆小，开发、测试协同工作，注重开发敏捷，不重视交付敏捷

##### 3.DevOps

开发、测试、运维协同工作，即持续开发 && 持续交付

---------

# 1.jar包部署方式

## 1.1 安装jdk，配置java环境

## 1.2 下载war包

    mkdir -p /usr/share/java /var/lib/jenkins 
    cd /usr/share/java && wget https://mirrors.tuna.tsinghua.edu.cn/jenkins/war/2.399/jenkins.war

## 1.3 创建启动脚本

    vi /lib/systemd/system/jenkins.service 


    [Unit]
    Requires=network.target
    After=network.target
    Description=Jenkins Continuous Integration Server

    [Service]
    User=www
    Group=www
    Type=notify
    NotifyAccess=main
    Restart=on-failure
    SuccessExitStatus=143
    WorkingDirectory=/var/lib/jenkins
    Environment="JENKINS_HOME=/var/lib/jenkins"
    Environment="JAVA_OPTS=-Djava.awt.headless=true"
    ExecStart=/usr/bin/java -jar /usr/share/java/jenkins.war --webroot=/var/lib/jenkins

    [Install]
    WantedBy=multi-user.target

## 1.4 启动Jenkins

    sudo systemctl daemon-reload
    sudo systemctl start jenkins.service
    sudo systemctl enable jenkins.service

## 1.5 获取初始密码，解锁jenkins

![jenkins-001-001](/img/wiki/jenkins/jenkins-001-001.jpg)

---------
## 1.6 安装推荐插件

![jenkins-001-002](/img/wiki/jenkins/jenkins-001-002.jpg)

---------

# 2.docker部署方式

    sudo mkdir /web/jenkins
    sudo chmod -R 777 /web/jenkins

    sudo docker run -d -it -p 8080:8080 -p 50000:50000 \
    --privileged=true -v /web/jenkins:/var/jenkins_home \
    --name jenkins jenkins

# 3.kubernetes部署方式

## 3.1 安装nfs

    sudo mkdir /home/project/kubernetes/jenkins
    sudo chmod -R 777 /home/project/kubernetes/jenkins

## 3.2 配置持久化存储

### 3.2.1 创建PV、PVC

    vi jenkins-data.yaml


    apiVersion: v1
    kind: PersistentVolume
    metadata:
      # 设置PV名称
      name: jenkins-data
      # 设置PV标签，用于PVC的定向绑定
      labels:
        app: jenkins-data
    spec:
      # 设置存储类别
      storageClassName: nfs
      # 设置访问模式
      accessModes:
        - ReadWriteMany
      # 设置PV的存储空间
      capacity:
        storage: 10Gi
      # 设置PV的回收策略
      persistentVolumeReclaimPolicy: Retain
      nfs:
        path: /home/project/kubernetes/jenkins
        server: 192.168.100.200
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: jenkins-data
      namespace: devops
    spec:
      # 设置PVC存储类别，用于指定存储类型
      storageClassName: nfs
      # 设置访问模式，匹配相同模式的PV
      accessModes:
      - ReadWriteMany
      # 设置PVC所申请存储空间的大小
      resources:
        requests:
          storage: 10Gi

### 3.2.2 部署jenkins存储

    kubectl apply -f jenkins-data.yaml

## 3.3 部署jenkins

### 3.3.1 创建部署文件

    vi jenkins.yaml


    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: jenkins
      namespace: devops
      labels:
        name: jenkins
    ---
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: jenkins
      namespace: devops
    rules:
    - apiGroups: [""]
      resources: ["pods","events"]
      verbs: ["create","delete","get","list","patch","update","watch"]
    - apiGroups: [""]
      resources: ["pods/exec"]
      verbs: ["create","delete","get","list","patch","update","watch"]
    - apiGroups: [""]
      resources: ["pods/log"]
      verbs: ["get","list","watch"]
    - apiGroups: [""]
      resources: ["secrets","events"]
      verbs: ["get"]
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: RoleBinding
    metadata:
      name: jenkins
      namespace: devops
    subjects:
    - kind: ServiceAccount
      name: jenkins
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: Role
      name: jenkins
    ---
    kind: Deployment
    apiVersion: apps/v1
    metadata:
      name: jenkins
      namespace: devops
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: jenkins
      template:
        metadata:
          labels:
            app: jenkins
        spec:
          serviceAccountName: jenkins
          containers:
          - name: jenkins
            image: registry.cn-hangzhou.aliyuncs.com/swords/jenkins:v2.400-jdk11
            imagePullPolicy: IfNotPresent
            securityContext:                     
              runAsUser:
              privileged: true
            env:
            - name: "JAVA_OPTS"
              value: -Dhudson.security.csrf.GlobalCrumbIssuerConfiguration.DISABLE_CSRF_PROTECTION=true
            ports:
            - containerPort: 8080
              name: web
              protocol: TCP
            - containerPort: 50000
              name: agent
              protocol: TCP
            resources:
              limits:
                cpu: 2000m
                memory: 1Gi
              requests:
                cpu: 50m
                memory: 512Mi
            livenessProbe:
              httpGet:
                path: /login
                port: 8080
              initialDelaySeconds: 60
              timeoutSeconds: 5
              failureThreshold: 3
            readinessProbe:
              httpGet:
                path: /login
                port: 8080
              initialDelaySeconds: 60
              timeoutSeconds: 5
              failureThreshold: 3
            volumeMounts:
            - name: jenkins-data
              mountPath: /var/jenkins_home
            - name: localtime
              mountPath: /etc/localtime
          volumes:
          - name: jenkins-data
            persistentVolumeClaim:
              claimName: jenkins-data
          - name: localtime
            hostPath:
              path: /etc/localtime
          imagePullSecrets:
            - name: regcred
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: jenkins
      namespace: devops
      labels:
        app: jenkins
    spec:
      type: NodePort
      ports:
      - name: web
        port: 8080
        targetPort: 8080
        nodePort: 38080
      - name: agent
        port: 50000
        targetPort: 50000
        nodePort: 50000
      selector:
        app: jenkins

### 3.3.2 部署jenkins

    kubectl apply -f jenkins.yaml

## 3.4 获取随机密码，解锁jenkins

    kubectl -n devops logs jenkins-655564d6f5-ld5tl

# 4.创建项目，测试任务构建

![jenkins-001-003](/img/wiki/jenkins/jenkins-001-003.jpg)

![jenkins-001-004](/img/wiki/jenkins/jenkins-001-004.jpg)

![jenkins-001-005](/img/wiki/jenkins/jenkins-001-005.jpg)

![jenkins-001-006](/img/wiki/jenkins/jenkins-001-006.jpg)

![jenkins-001-007](/img/wiki/jenkins/jenkins-001-007.jpg)

![jenkins-001-008](/img/wiki/jenkins/jenkins-001-008.jpg)

![jenkins-001-009](/img/wiki/jenkins/jenkins-001-009.jpg)

---------

# 参考文档

- https://cloud.tencent.com/developer/article/1559679
- https://blog.csdn.net/qq_42883074/article/details/126009573
- https://blog.csdn.net/weixin_38299857/article/details/115384071