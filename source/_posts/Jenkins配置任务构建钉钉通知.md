---
title: Jenkins配置任务构建钉钉通知
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
date: 2023-05-31 16:44:29
---

# 1.钉钉群创建机器人

【群设置】 ---> 【机器人】 ---> 【添加机器人】 ---> 【自定义】

---------

![jenkins-006-001](/img/wiki/jenkins/jenkins-006-001.jpg)

![jenkins-006-002](/img/wiki/jenkins/jenkins-006-002.jpg)

# 2.jenkins安装Ding Talk插件

# 3.jenkins配置钉钉机器人

- 【系统管理】 ---> 【钉钉】

![jenkins-006-003](/img/wiki/jenkins/jenkins-006-003.jpg)

![jenkins-006-004](/img/wiki/jenkins/jenkins-006-004.jpg)

# 4.项目配置钉钉机器人通知

## 4.1 freestyle项目

![jenkins-006-005](/img/wiki/jenkins/jenkins-006-005.jpg)

### 自定义消息格式

    ### ${PROJECT_NAME}项目构建构建${JOB_STATUS}!
    ---------
    - 项目: ${PROJECT_NAME}
    - 构建号: ${BUILD_ID}
    - 构建人: ${EXECUTOR_NAME}
    - 项目地址: ${PROJECT_URL}
    - 工作目录: ${PROJECT_URL}ws
    - 任务地址: ${BUILD_URL}
    - 构建日志: ${BUILD_URL}console
    - 持续时间: ${JOB_DURATION}

## 4.2 pipeline项目

    def project = "hexo"
    def app_name = "poetry"

    pipeline {
    
      agent any

      stages {
      
        stage('TestAgent') {
          steps {
            sh """
            date
            pwd
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
                     "- 任务地址: ${BUILD_URL}",
                     "- 构建日志: ${BUILD_URL}console",
                     "- 持续时间: ${currentBuild.durationString}"
                    ]
              )
          }
        }
    }

# 5.构建任务，测试钉钉通知

![jenkins-006-006](/img/wiki/jenkins/jenkins-006-006.jpg)

---------

# 参考文档

- https://jenkinsci.github.io/dingtalk-plugin
- https://blog.csdn.net/IT_ZRS/article/details/125674756
- https://blog.csdn.net/heian_99/article/details/124816190
- https://blog.csdn.net/qq_42157883/article/details/124215072