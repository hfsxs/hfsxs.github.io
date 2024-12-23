title: Jenkins基于Kubernetes集群配置动态agent节点
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
date: 2023-04-18 18:45:50
---

# 1.配置代理节点持久化存储

## 1.1 创建PV、PVC

    vi jenkins-slave-data.yaml


    apiVersion: v1
    kind: PersistentVolume
    metadata:
      # 设置PV名称
      name: jenkins-slave-data
      # 设置PV标签，用于PVC的定向绑定
      labels:
        app: jenkins-slave-data
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
        path: /home/project/kubernetes/devops/jenkins-slave
        server: 192.168.100.200
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: jenkins-slave-data
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
      selector: 
        matchLabels:
          app: jenkins-slave-data

## 1.2 部署PV、PVC

    kubectl apply -f jenkins-slave-data.yaml

# 2.jenkins安装kubernetes插件

# 3.登录jenkins，创建kubernetes云

【系统管理】 -> 【节点管理】 -> 【Clouds】 -> 【新增一个云】

![jenkins-003-001](/img/wiki/jenkins/jenkins-003-001.jpg)

![jenkins-003-002](/img/wiki/jenkins/jenkins-003-002.jpg)

![jenkins-003-003](/img/wiki/jenkins/jenkins-003-003.jpg)

![jenkins-003-004](/img/wiki/jenkins/jenkins-003-004.jpg)

# 4.部署动态agent节点

## 4.1 Pod模版部署方式

### 4.1.1 配置POd模版

![jenkins-003-005](/img/wiki/jenkins/jenkins-003-005.jpg)

![jenkins-003-006](/img/wiki/jenkins/jenkins-003-006.jpg)

### 4.1.2 配置Pod容器

![jenkins-003-007](/img/wiki/jenkins/jenkins-003-007.jpg)

![jenkins-003-008](/img/wiki/jenkins/jenkins-003-008.jpg)

![jenkins-003-009](/img/wiki/jenkins/jenkins-003-009.jpg)

![jenkins-003-010](/img/wiki/jenkins/jenkins-003-010.jpg)

## 4.2 pipeline部署方式

    pipeline {
      agent {
        kubernetes {
          label "jenkins-slave"
          customWorkspace '/home/jenkins/workspace/hexo'
          yaml '''
            apiVersion: v1
            kind: Pod
            metadata:
              name: jenkins-slave
              namespace: devops
            spec:
              containers:
                - name: jnlp
                  image: registry.sword.org/jenkins-slave:4.13.3-1-jdk11
                  imagePullPolicy: IfNotPresent
                  env:
                    - name: "workDir"
                      value: "/home/jenkins"
                    - name: "TZ"
                      value: "Asia/Shanghai"
                  resources:
                    limits:
                      cpu: 500m
                      memory: 300Mi
                    requests:
                      cpu: 300m
                      memory: 200Mi
                  volumeMounts:
                    - name: docker-cmd
                      mountPath: /usr/bin/docker
                    - name: docker-sock
                      mountPath: /var/run/docker.sock
                    - name: jenkins-slave-data
                      mountPath: /home/jenkins
                    - name: localtime
                      mountPath: /etc/localtime
              volumes:
                - name: docker-cmd
                  hostPath:
                    path: /usr/bin/docker
                - name: docker-sock
                  hostPath:
                    path: /var/run/docker.sock
                - name: jenkins-slave-data
                  persistentVolumeClaim:
                    claimName: jenkins-slave-data
                - name: localtime
                  hostPath:
                    path: /etc/localtime
              securityContext:
                runAsGroup: 0
                runAsUser: 1000
              serviceAccountName: "jenkins"
          '''
        }
      }

      stages {
        stage('TestAgent') {
          steps {
            sh """
            hostname
            docker images
            """
          }
        }
      }
    }

# 5.构建任务，测试动态agent

---------

# 参考文档

- https://www.freesion.com/article/6009773987
- https://www.cnblogs.com/panwenbin-logs/p/17299430.html
- https://blog.csdn.net/weixin_44802620/article/details/125179310