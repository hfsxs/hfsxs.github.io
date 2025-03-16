def project = "hexo"
 
 pipeline {
     
  agent {
     kubernetes {
       label "jenkins-slave"
       cloud "Kubernetes01"
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
          docker build -t registry.cn-hangzhou.aliyuncs.com/geekers/hexo:{BUILD_NUMBER} .
          docker push registry.cn-hangzhou.aliyuncs.com/geekers/hexo:{BUILD_NUMBER}
          docker rmi registry.cn-hangzhou.aliyuncs.com/geekers/hexo:{BUILD_NUMBER}
          """
      }
    }

    stage('Deploy') {
      steps {
        sh """
          /home/jenkins/kubectl -n devops set image deployments/hexo *="registry.cn-hangzhou.aliyuncs.com/geekers/${project}:${BUILD_NUMBER}"
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
