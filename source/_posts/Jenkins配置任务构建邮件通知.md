---
title: Jenkins配置任务构建邮件通知
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
date: 2023-05-24 10:51:11
---

DevOps聚合了开发、测试、运维这些前后端部门，其中任一环节出现问题，都将导致整个流程的失败。所以，将Jenkins任务的构建结果通知到相关责任人，收到信息后自行判断是否己相关，以便快速介入处理。这样，就将这些部门所有的相关责任人串联起来，也使得整个项目的各个环节的联结更加紧密

# 1.发送邮箱开启SMTP服务，获取认证码

# 2.jenkins安装邮箱插件Email Extension

# 3.jenkins配置邮件通知及系统管理员邮箱

![jenkins-005-001](/img/wiki/jenkins/jenkins-005-001.jpg)

![jenkins-005-002](/img/wiki/jenkins/jenkins-005-002.jpg)

![jenkins-005-003](/img/wiki/jenkins/jenkins-005-003.jpg)

# 4.jenkins配置邮件扩展

![jenkins-005-004](/img/wiki/jenkins/jenkins-005-004.jpg)

# 5.jenkins项目配置邮件通知

## 5.1 freestyle项目

![jenkins-005-005](/img/wiki/jenkins/jenkins-005-005.jpg)

![jenkins-005-006](/img/wiki/jenkins/jenkins-005-006.jpg)

![jenkins-005-007](/img/wiki/jenkins/jenkins-005-007.jpg)

### 5.1.1 邮件主题

    【Jenkins项目自动化构建通知】：$PROJECT_NAME - Build - $BUILD_NUMBER - $BUILD_STATUS!

### 5.1.2 邮件正文模版

    <!DOCTYPE html>    
    <html>    
    <head>    
    <meta charset="UTF-8">    
    <title>${ENV, var="JOB_NAME"}-${BUILD_NUMBER}</title>    
    </head>    
    <body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4"    
    offset="0"> 
        <table width="95%" cellpadding="0" cellspacing="0"  style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">    
        <tr>    
            本邮件由Jenkins系统自动发出，无需回复！<br/>            
            大家好，以下为${PROJECT_NAME }项目构建信息，请相关负责人关注：</br> 
            <td><font color="#CC0000">构建结果 - ${BUILD_STATUS}</font></td>   
        </tr>    
        <tr>    
            <td><br />    
            <b><font color="#0B610B">构建信息</font></b>    
            <hr size="2" width="100%" align="center" /></td>    
        </tr>    
        <tr>    
            <td>    
                <ul>    
                    <li>项目名称: ${PROJECT_NAME}</li>    
                    <li>项目描述: ${JOB_DESCRIPTION}</li>    
                    <li>构建编号: ${BUILD_NUMBER}</li>    
                    <li>触发原因: ${CAUSE}</li>    
                    <li>构建状态: ${BUILD_STATUS}</li>
                    <li>项目地址: <a href="${PROJECT_URL}">${PROJECT_URL}</a></li>
                    <li>工作目录: <a href="${PROJECT_URL}ws">${PROJECT_URL}ws</a></li>
                    <li>任务地址: <a href="${BUILD_URL}">${BUILD_URL}</a></li>
                    <li>构建日志: <a href="${BUILD_URL}console">${BUILD_URL}console</a></li>
                </ul>    
            </td>    
        </tr>
        <tr> 
            <td><b><font color="#0B610B">变更集</font></b>
            <hr size="2" width="100%" align="center" /></td>    
        </tr>
            <td>${JELLY_SCRIPT,template="html"}<br/>
                <hr size="2" width="100%" align="center" /></td>    
            </tr>
        </table>    
    </body>    
    </html>

## 5.2 pipeline项目

### 5.2.1 创建邮件通知模版文件

    vi email.html


    <!DOCTYPE html>    
    <html>    
    <head>    
    <meta charset="UTF-8">    
    <title>${ENV, var="JOB_NAME"}-${BUILD_NUMBER}</title>    
    </head>    
    <body leftmargin="8" marginwidth="0" topmargin="8" marginheight="4"    
    offset="0"> 
        <table width="95%" cellpadding="0" cellspacing="0"  style="font-size: 11pt; font-family: Tahoma, Arial, Helvetica, sans-serif">    
        <tr>    
            本邮件由Jenkins系统自动发出，无需回复！<br/>            
            大家好，以下为${PROJECT_NAME }项目构建信息，请相关负责人关注：</br> 
            <td><font color="#CC0000">构建结果 - ${BUILD_STATUS}</font></td>   
        </tr>    
        <tr>    
            <td><br />    
            <b><font color="#0B610B">构建信息</font></b>    
            <hr size="2" width="100%" align="center" /></td>    
        </tr>    
        <tr>    
            <td>    
                <ul>    
                    <li>项目名称: ${PROJECT_NAME}</li>    
                    <li>项目描述: ${JOB_DESCRIPTION}</li>    
                    <li>构建编号: ${BUILD_NUMBER}</li>    
                    <li>触发原因: ${CAUSE}</li>    
                    <li>构建状态: ${BUILD_STATUS}</li>
                    <li>项目地址: <a href="${PROJECT_URL}">${PROJECT_URL}</a></li>
                    <li>工作目录: <a href="${PROJECT_URL}ws">${PROJECT_URL}ws</a></li>
                    <li>任务地址: <a href="${BUILD_URL}">${BUILD_URL}</a></li>
                    <li>构建日志: <a href="${BUILD_URL}console">${BUILD_URL}console</a></li>
                </ul>
            </td> 
        </tr>
        <tr>
            <td><b><font color="#0B610B">变更集</font></b>
            <hr size="2" width="100%" align="center" /></td>    
        </tr>
            <td>${JELLY_SCRIPT,template="html"}<br/>
                <hr size="2" width="100%" align="center" /></td>    
            </tr>
        </table>    
    </body>    
    </html>  

### 5.2.2 创建pipeline文件

    def project = "hexo"
    def app_name = "poetry"
    def git_auth_id = "sword-cloud"
    def registry = "registry.sword.org"

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
          stage('Test') {
            steps {
              sh """
              pwd
              hostname
              date
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
        }
     }

# 6.构建任务，测试邮件通知

![jenkins-005-008](/img/wiki/jenkins/jenkins-005-008.jpg)

---------

# 参考文档

- https://www.cnblogs.com/qinziteng/p/16974541.html
- https://www.cnblogs.com/rb2010/p/16195448.html
- https://blog.csdn.net/fullbug/article/details/53024562