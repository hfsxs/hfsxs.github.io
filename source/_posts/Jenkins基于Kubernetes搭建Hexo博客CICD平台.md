---
title: Jenkins基于Kubernetes搭建Hexo博客CICD平台
categories:
  - 工作
tags:
  - Linux
  - Jenkins
  - Git
  - DevOps
  - CICD
  - Kubernetes
  - Hexo
  - 容器云
  - 云原生
  - 云计算
date: 2023-05-18 09:26:54
---

# 发布流程

- 1.本地VSCode编写hexo博客
- 2.运行hexo -g -d发布博客，将静态博客文件提交到Kubernetes集群的Git私有仓库
- 3.Gitweb钩子触发Kubernetes集群部署的Jenkins的构建触发器，拉取托管在Git私有仓库的Jenkinsfile作为构建依据
- 4.Jenkins开始任务构建，连接kubernetes集群拉起代理Pod，执行任务构建
- 5.Jenkins代理Pod拉取Git私有仓库代码，通过Dockerfile文件将静态博客文件构建为镜像，再将镜像push到Docker私有镜像仓库
- 6.执行kubelet set命令，将博客的deployment镜像更新为新构建的镜像，完成整个发布流程

---------

# 1.部署Jenkins

## 1.1 创建存储资源文件

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
        path: /home/project/kubernetes/devops/jenkins
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
      selector: 
        matchLabels:
          app: jenkins-data

## 1.2 创建应用资源文件

    vi jenkins-deployment.yaml


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

## 1.3 部署Jenkins

    kubectl apply -f jenkins-data.yaml
    kubectl apply -f jenkins-deployment.yaml

# 2.部署Git服务器

## 2.1 创建存储资源文件

    vi gitea-data.yaml


    apiVersion: v1
    kind: PersistentVolume
    metadata:
      # 设置PV名称
      name: gitea-data
      # 设置PV标签，用于PVC的定向绑定
      labels:
        app: gitea-data
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
        path: /home/project/kubernetes/devops/gitea
        server: 192.168.100.200
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: gitea-data
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
          app: gitea-data

## 2.2 创建应用资源文件

    vi gitea-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: gitea-deployment
      namespace: devops
      labels:
        app: gitea
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: gitea
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
                cpu: 500m
                memory: 200Mi
              requests:
                cpu: 200m
                memory: 100Mi
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
    ---
    kind: Service
    apiVersion: v1
    metadata:
      name: gitea-service
      namespace: devops
    spec:
      selector:
        app: gitea
      type: NodePort
      ports:
      - name: gitea-http
        port: 3000
        targetPort: gitea-http
        nodePort: 30000
      - name: gitea-ssh
        port: 22
        targetPort: gitea-ssh
        nodePort: 30022

## 2.3 部署Gitea

    kubectl apply -f gitea-data.yaml
    kubectl apply -f gitea-deployment.yaml

# 3.配置Jenkins

    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: hexo
      namespace: devops
    spec:
      selector:
        matchLabels:
          app: hexo
      replicas: 1
      template:
        metadata:
          labels:
            app: hexo
        spec:
          containers:
            - name: hexo
              image: registry.cn-hangzhou.aliyuncs.com/swords/nginx:ubuntu18
              imagePullPolicy: IfNotPresent
              ports:
                - containerPort: 80
                  name: hexo
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
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: hexo-service
      namespace: devops
    spec:
      type: NodePort
      sessionAffinity: ClientIP
      selector:
        app: hexo
      ports:
        - port: 80
          targetPort: 80

## 3.1 创建任务

    def project = "hexo"
 
    pipeline {
     
      agent {
         kubernetes {
           label "jenkins-slave"
           cloud "Kubernetes"
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
                   image: registry.cn-hangzhou.aliyuncs.com/swords/jenkins-inbound-agent:latest-jdk17
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
              date
              pwd
              whoami
            """
          }
        }
   
        stage('CleanWorkspace') {
          steps {
            sh """
            rm -rf *
            """
          }
        }

        stage('CheckoutGitea') {
          steps {
            checkout scmGit(
              branches: [[name: '*/master']], 
              extensions: [],
              userRemoteConfigs: [
                [credentialsId: 'gitea-cloud', url: 'http://192.168.100.200:3200/sword/hexo.git']
              ]
            )
          }
        }

        stage('DockerImage') {

          steps {

            sh """
              docker build -t registry.cn-hangzhou.aliyuncs.com/geekers/hexo:v${BUILD_NUMBER} .
              docker push registry.cn-hangzhou.aliyuncs.com/geekers/hexo:v${BUILD_NUMBER}
              docker rmi registry.cn-hangzhou.aliyuncs.com/geekers/hexo:v${BUILD_NUMBER}
            """
          }
        }

        stage('Deploy') {
          steps {
            sh """
              /home/jenkins/kubectl -n devops set image deployments/hexo *="registry.cn-hangzhou.aliyuncs.com/geekers/${project}:v${BUILD_NUMBER}"
            """
          }
        }
      }
   
      post {
     
        always {
          emailext ( 
            subject: '【Jenkins项目自动化构建通知】：$PROJECT_NAME - $BUILD_NUMBER - $BUILD_STATUS!',
            body: '${FILE,path="/home/jenkins/email.html"}',
            to: '523343553@qq.com'
            )
        }        
 
        failure {
          dingtalk (
            robot: 'dingtalk-jenkins',
            type:'MARKDOWN',
            atAll: true,
            text: ["### ${currentBuild.projectName}项目构建${currentBuild.currentResult}!",
                   "---------",
                   "- 项目: ${JOB_NAME}",
                   "- 构建号: ${BUILD_ID}",
                   "- 构建人: ${env.BUILD_USER}",
                   "- 项目地址: ${JOB_URL}",
                   "- 工作目录: ${BUILD_URL}ws",
                   "-任务地址: ${BUILD_URL}",
                   "- 构建日志: ${BUILD_URL}console",
                   "- 持续时间: ${currentBuild.durationString}"
                  ]
          )
        }
      }
    }

## 3.2 配置Cloud

## 3.2.1 配置镜像仓库

## 3.3 配置CSF安全认证

# 4.配置Git仓库

## 4.1 创建Hexo仓库

## 4.2 创建Web钩子

## 4.3 测试Git仓库





---------

# 参考文档

- https://blog.lanweihong.com/posts/45278
- http://www.liuhaihua.cn/archives/516810.html
- https://blog.csdn.net/sanhewuyang/article/details/121189389
- https://blog.csdn.net/weixin_43458965/article/details/129121351