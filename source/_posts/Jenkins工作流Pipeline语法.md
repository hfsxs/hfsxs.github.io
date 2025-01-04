---
title: Jenkins工作流Pipeline语法
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
date: 2023-06-24 10:10:03
---

Pipeline，即管道，是Jenkins用于集成持续交付与实施的一套插件，各种管道的综合运用完整定义了自动化持续交付流程，即将基于版本控制管理的软件代码经过持续的构建、测试、修复、部署直到最终交付到线上正式环境这一整套流程一站式完整的整合，这样就将原本独立运行于单个或者多个节点的任务连接起来，实现单个任务难以完成的复杂流程编排与可视化。可将这些管道组合而成的交付过程形象的理解为流水线模型，也由此展现了Jenkins自动化引擎的功能，其特性如下：

- 代码，流水线在代码中实现，通常会检查源代码控制，如代码编辑、审查和迭代的能力
- 可持续，Jenkins重启或者中断后都不会影响流水线的任务
- 可停顿，流水线可有选择的停止或等待人工输入或批准，然后才能继续运行流水线
- 多功能，流水线支持复杂的现实世界的CD需求，包括fork/join、循环以及并行执行工作的能力
- 可扩展，流水线插件支持扩展到它的DSL的惯例和与其他插件集成的多个选项

---------

Jenkins流水线存储于文本文件Jenkinsfile，分为声明式流水线与脚本化流水线两种，官方推荐声明式流水线，其语法类似于gradle，都是基于groovy的闭包语法

Jenkins官方建议将Jenkinsfile提交到项目的源代码托管仓库，体现了Jenkins流水线即代码的特性，即将交付流水线作为应用程序的一部分，像其他代码一样进行版本化和审查，以便于项目成员的查看、编辑、复查或迭代、跟踪审计，还能自动地为所有分支创建流水线构建过程并拉取

---------

# 1.基础结构

    pipeline {

      agent any

        stages {

          stage('Build') {
            steps {
              echo 'Building..'
            }
          }

          stage('Test') {
            steps {
              echo 'Testing..'
            }
          }

          stage('Deploy') {
            steps {
              echo 'Deploying....'
            }
          }

        }
    }

## 语法规范

- 1.声明式流水线的所有内容都被包含在一个Pipeline块中，标明其为声明式的pipeline脚本
- 2.语句无需分隔符但每条语句必须在一行内，且循环判断语句需被script{}包裹
- 3.顶层pipeline块由章节Sections、指令Directives、步骤Steps以及赋值语句assignment statements组成
- 4.属性引用语句将会被当做是无参数的方法调用，如input会被当做input()

# 2.Sections

Sections，即章节，是包含一个或多个Agent、Stages、post、Directives和Steps的代码区域块

## 2.1 agent

agent，即代理，用于指定任务或某个阶段的执行节点，也即是任务运行的slave或者master节点，位于pipeline块的顶层表示整个流水线的运行节点，位于stage则表示只在某个特定的阶段指定运行节点，可选参数为any、none、label、node、docker、dockerfile、kubernetes

### 2.1.1 any

表示任务可运行于任意的可用节点

    pipeline {

	    agent any

	    stages {

		    stage('Build') {
			    steps("Build"){ 
				    echo 'Project Build' 
			    }
		    }

		    stage('Deploy') {
			    steps { 
				    echo 'Project Deploy' 
			    }
		    }

	    }
    }

### 2.1.2 none

表示不声明全局agent，也即需要为每一个stage声明各自单独的agent

### 2.1.3 label

表示任务运行于指定标签的节点，可配合逻辑运算符

    agent {
      label 'test-project'
    }
    agent {
      label 'test' && 'devops'
    }
    agent {
      label 'project' || 'devops'
    }

### 2.1.4 node

表示任务运行于指定的节点，功能类似于label，但可附加选项参数，如指定工作目录customWorkspace

    agent {
      node {
        label 'test-node'
        customWorkspace '/home/jenkins'
      }
    }

### 2.1.5 docker

表示任务运行于预配置节点或指定label节点创建的docker容器，可接收docker run、docker registry等参数，也可指定工作目录customWorkspace参数

    agent {
      docker 'nginx:v1.20.0'
    }
    agent {
      docker {
        image 'nginx:v1.20.0'
        label 'nginx'
        args  '-v /tmp:/tmp'
        registryUrl 'https://myregistry.com/'
        registryCredentialsId 'myPredefinedCredentialsInJenkins'
      }
    }

### 2.1.6 dockerfile

表示任务运行于一个由Dockerfile创建docker容器，默认会从构建的根目录搜索Dockerfile文件，也可指定工作目录customWorkspace参数

    agent { 
      dockerfile true 
    }
    agent {
      dockerfile {
        filename 'my_dockerfile'
        dir 'build_dir'
        label 'my-defined-label'
        additionalBuildArgs  '--build-arg version=1.0.2'
        args '-v /tmp:/tmp'
        registryUrl 'https://myregistry.com/'
        registryCredentialsId 'myPredefinedCredentialsInJenkins'
      }
    }

### 2.1.7 kubernetes

表示任务运行于kubernetes集群的一个pod，pod模版被定义在kubernetes{}模块

    agent {
      kubernetes {
        label jenkins-slave
        yaml """
			    kind: Pod
			    metadata:
			      name: devops
			    spec:
			      containers:
			      - name: nginx
				    image: nginx
		    """
      }
    }

## 2.2 stages

stages，即阶段集合，项目交付所有的阶段，如拉取源代码、构建打包、测试、部署等各个阶段

## 2.3 stage

stage，即阶段，被stages包裹，一个stages可以有多个stage

## 2.4 steps

steps，即步骤，阶段的最小执行单元，被stage包裹

## 2.5 post

post，即发布，任务构建执行完成后根据构建结果所执行的对应操作，如发送任务构建通知邮件等，定义于整个流水线或某个stage，执行场景如下：

### 2.5.1 always

不考虑pipeline或stage的执行结果，总是会执行

### 2.5.2 changed

只有pipeline或stage的执行结果状态与前一次执行相比发生改变时执行

### 2.5.3 fixed

当前pipeline或stage执行成功且前一次执行结果是failure或unstable时执行

### 2.5.4 regression

当前pipeline或stage执行结果是failure、unstable或aborted且前一次执行成功时执行

### 2.5.5 aborted

当前pipeline或stage执行结果是aborted，即人工停止pipeline时执行

### 2.5.6 failure

当前pipeline或stage执行结果失败时执行

### 2.5.7 success

当前pipeline或stage执行结果成功时执行

### 2.5.8 unstable

当前pipeline或stage执行结果unstable时执行

### 2.5.9 unsuccessful

当前pipeline或stage执行结果不是成功时执行

### 2.5.10 cleanup

其余所有post场景脚本都处理完之后执行，无论当前pipeline或stage执行结果是什么

    pipeline {
      agent any
      stages {
        stage('Example1') {
          steps {
            echo 'Hello World1'
          }
        }
        stage('Example2') {
          steps {
            echo 'Hello World2'
          }
        }
      }
      post {
        always {
          echo 'I will always say Hello again!'
        }
      }
    }

    pipeline {
      agent any
      stages {
        stage('Example1') {
          steps {
            sh 'ip a'
          }
          post {
            failure {
              echo 'I will always say Hello again!'
            }
          }
        }
      }
    }

# 3.Directives

Directive，即指令，用于stage执行时的条件判断或数据的预处理，包含了environment、options、parameters、triggers、stage、tools、input、when等配置

## 3.1 environment

environment指令用于指定一个键/值对序列作为环境变量，其作用域取决于定义的位置，位于顶层pipeline时作为全局变量，位于stage时作为该stage的局部环境变量。此外，该指令的credentials()方法还可定义访问凭证，支持如下credential类型：

- Secret Text类型，该环境变量的值将会被设置为Secret Text的内容
- Secret File类型，该环境变量的值将会被设置为临时创建的文件路径
- Username and password类型，该环境变量的值将会被设置为username:password，并且还会自动创建两个环境变量MYVARNAME_USR和MYVARNAME_PSW
- SSH with Private Key类型，该环境变量的值将会被设置为临时创建的ssh key文件路径，并且还会自动创建两个环境变量
MYVARNAME_USR和MYVARNAME_PSW

### 3.1.1 环境变量

    pipeline {
      agent any
      environment {
        NAME= 'test'
      }
      stages {
        stage('env1') {
          environment {
            REGISTRY = 'https://registry.sword.org'
          }
          steps {
            sh "env"
          }
        }
        stage('env2') {
          steps {
            sh "env"
          }
        }
      }
    }

### 3.3.2 访问凭证

    pipeline {
      agent any
      environment {
        REGCRED = credentials('registry-auth')
        KUBECONFIG = credentials('kubernetes-auth')
      }
      stages {
        stage('env') {
          steps {
            sh "env"
          }
        }
      }
    }

## 3.2 options

options指令用于配置流水线特定的选项参数，以适用于特定的需求，一般定义于顶层Pipeline，某些指令也可用于stage

### 3.2.1 buildDiscarder

该指令用于指定构架历史与构建日志的保存数量

    options { 
      buildDiscarder(logRotator(numToKeepStr: '1')) 
    }

### 3.2.2 disableConcurrentBuilds

该指令用于禁止流水线并行执行，防止并行流水线同时访问共享资源导致流水线失败

    options { 
      disableConcurrentBuilds()
    }

### 3.2.3 disableResume

该指令用于禁止控制器重启后流水线自动开启

    options { 
      disableResume() 
    }

### 3.2.4 newContainerPerStage

该指令用于设定docker或dockerfile类型的agent每个阶段将在同一个节点的新容器中运行，而不是所有的阶段都在同一个容器中运行

    options {
      newContainerPerStage()
    }

### 3.2.5 quietPeriod

该指令用于设置流水线静默期，也即是触发流水线后任务启动的延迟时间，单位为秒

    options { 
      quietPeriod(30) 
    }

### 3.2.6 retry

该指令用于指定流水线失败重试次数，可用于stage

    options { 
      retry(3) 
    }

### 3.2.7 timeout

该指令用于设置流水线构建的超时时间，超时构建自动终止，不加unit参数默认为1分钟，可用于stage

    options {
      timeout(time: 1, unit: 'HOURS') 
    }

### 3.2.8 timestamps

该指令用于设置控制台构建日志输出的时间戳，可用于stage

    options { 
      timestamps() 
    }

### 3.2.9 checkoutToSubdirectory

该指令用于将源码拉取到工作空间指定的子目录

    options { 
      checkoutToSubdirectory('source') 
    }

## 3.3 parameters

parameters指令用于设置构建触发时用户所需的参数，steps指令通过params对象获取这些参数值，只可作用于顶层pipeline，且只能出现一次，支持的参数类型如下：

- string，字符串类型
- text，文本类型，一般用于定义多行文本内容的变量
- booleanParam，布尔类型
- choice，选择类型，一般用于给定几个可选的值，然后选择其中一个进行赋值
- password，密码类型，一般用于定义敏感型变量，在Jenkins控制台的输出为*
- imageTag，镜像tag，需安装Image Tag Parameter插件
- gitParameter，获取git仓库分支，需安装Git Parameter插件

### 3.3.1 string

    pipeline {
      agent any
      parameters {
        string(
          name: 'DEPLOY_ENV',
          defaultValue: 'staging',
          description: '1'
        )
      }
    }

### 3.3.2 text

    pipeline {
      agent any
      parameters {
        text(
          name: 'DEPLOY_TEXT', 
          defaultValue: 'One\nTwo\nThree\n', 
          description: '2'
        )
      }
    }

### 3.3.3 booleanParam

    pipeline {
      agent any
      parameters {
        booleanParam(
          name: 'DEBUG_BUILD',
          defaultValue: true,
          description: '3'
        )
      }
    }

### 3.3.4 choice

    pipeline {
      agent any
      parameters {
        choice(
          name: 'CHOICES',
          choices: ['one', 'two', 'three'],
          description: '4'
        )
      }
    }

### 3.3.5 password

    pipeline {
      agent any
      parameters {
        password(
          name: 'PASSWORD',
          defaultValue: 'SECRET',
          description: 'A  secret password'
        )
      }
    }

### 3.3.6 imageTag

    pipeline {
      agent any
      parameters {
        imageTag(
          name: 'DOCKER_IMAGE',
          description: '',
          image: 'hexo/nginx', filter: '.*',
          defaultTag: '',
          registry: 'https://registry.sword.org',
          credentialId: 'harbor-account',
          tagOrder: 'NATURAL'
        )
     }
    }

### 3.3.7 gitParameter

    pipeline {
      agent any
      parameters {
        gitParameter(
          branch: '',
          branchFilter: 'origin/(.*)',
          defaultValue: '',
          description: 'Branch for build and deploy',
          name: 'BRANCH',
          quickFilterEnabled: false,
          selectedValue: 'NONE',
          sortMode: 'NONE',
          tagFilter: '*',
          type: 'PT_BRANCH'
        )
      }
      stage('git') {
        steps {
          git branch: "$BRANCH",
          credentialsId: 'gitlab-key',
          url: 'git@git-server:root/env.git'
        }
      }
    }

## 3.4 triggers

triggers指令用于设置流水线任务的自动触发执行，支持Webhook、Cron、 pollSCM和upstream等方式，作用域为顶层pipeline

### 3.4.1 Cron

该指令用于流水线定时构建，适用于构建时间较长或需要定期在某个时间段执行构建的流水线，如周一到周五每隔四个小时执行一次

    pipeline {

      agent any

      triggers {
        cron('H */4 * * 1-5')
        cron('H/12 * * * *')
        cron('H * * * *')
      }

      stages {
        stage('Example') {
          steps {
            echo 'Hello World'
          }
        }
      }
    }

- 注:H意为Hash，而非HOURS，可解决多个流水线在同一时间同时运行所产生的系统负载

### 3.4.2 Upstream

该指令用于根据上游任务的执行结果决定是否触发该流水线，目前支持的状态有SUCCESS、UNSTABLE、FAILURE、NOT_BUILT、ABORTED等

    pipeline {
      agent any
        triggers {
          upstream(upstreamProjects: 'job01', threshold: hudson.model.Result.SUCCESS)
        }
      stages {
        stage('Example') {
          steps {
            echo 'Hello World'
          }
        }
      }
    }

### 3.4.3 pollSCM

该指令用于定时检查源码变更的触发，如果发生变更则触发构建

    triggers { 
      pollSCM('H */4 * * 1-5') 
    }

## 3.5 tools

该指令用于设置任务构建所需工具，并设置到PATH环境变量，但当agent none时tools声明将会被忽略，支持jdk、maven、gradle等工具，且需在Jenkins控制台全局工具配置处进行配置

## 3.6 input

该指令用于实现流水线交互式操作，如选择要部署的环境、是否继续执行某个阶段等，只能作用于stage，支持如下选项：

- message，必选，需要用户进行input的提示信息，如“是否发布到生产环境?”
- id，可选，input的标识符，默认为stage名称
- ok，可选，确认按钮的显示信息，如“确定”、“允许”等
- submitter，可选，允许提交input操作的用户或组，为空则表示任何登录用户均可提交
- parameters，提供一个参数列表供input使用

---------

    pipeline {
      agent any
        stages {
          stage('阶段1') {
            input {
              message "你好，请输入登录用户"
              ok "确认"
              submitter "alice,bob"
                parameters {
                  string(name: 'PERSON', defaultValue: '张三', description: '请输入公司账号')
                }
            }
            steps {
              echo "你好, ${PERSON}, 打卡成功"
            }
          }
        }
    }

## 3.7 when

该指令用于流水线根据给定的条件决定是否应该执行该stage，必须包含至少一个条件，若包含多个条件，则需所有子条件必须都返回True才能执行，还可结合not、allOf、anyOf语法达到更灵活的条件匹配。需要注意的是，正常情况下when判断是在agent、input、options命令之后才执行的，但也可通过将beforeAgent、beforeInput、beforeOptions参数设为true来设置提前执行。when指令只能作用于stage，常用的内置条件如下：

### 3.7.1 branch

当前构建分支与给定分支匹配时执行该stage，只适用于多分支流水线

    when { 
	    branch 'master' 
    }

    when { 
	    branch pattern: "release-\\d+", comparator: "REGEXP"
    }

### 3.7.2 changelog

匹配提交的变更日志决定是否构建

    when { 
	    changelog '.*^\\[DEPENDENCY\\] .+$' 
    }

### 3.7.3 environment

指定的环境变量和给定的变量匹配时执行该stage

    when { 
  	  environment name: 'DEPLOY_TO', value: 'production' 
    }

### 3.7.4 equals

期望值和实际值相同时执行该stage

    when { 
      equals expected: 2, actual: currentBuild.number
    }

### 3.7.5 expression

指定的Groovy表达式为True时执行该stage

    when { 
      expression { 
        return params.DEBUG_BUILD 
      } 
    }

### 3.7.6 tag

TAG_NAME的值和给定的条件匹配时执行该stage，匹配规则如下：

- not，嵌套条件出现错误时执行该stage，必须包含一个条件
- allOf，所有的嵌套条件都正确时执行该stage，必须包含至少一个条件
- anyOf，至少有一个嵌套条件为True时执行该stage

---------

    when { 
      tag "release-*" 
    }

    when { 
      tag pattern: "release-\\d+", comparator: "REGEXP"
    }

    when { 
      not { 
        branch 'master' 
      } 
    }

    when { 
      allOf { 
        branch 'master'; 
        environment name: 'DEPLOY_TO', value: 'production' 
      } 
    }

    when { 
      anyOf { 
        branch 'master'; branch 'staging' 
      } 
    }

# 4.parallel

Parallel，即并发，用于定义并行运行的stage，每个stage只能有一个steps或parallel，且并行的stage由于没有相关的steps就不能包含agent或tools，嵌套的stages也不能定义并行运行。此外，通过对并行stage设置failFast true，以达到其中一个并行stage执行失败时强制终止其他并行stage的目的

    pipeline {

      agent any

        stages {

          stage('非并行阶段') {
            steps {
              echo '非并行阶段'
            }
          }

          stage('并行阶段') {

            failFast true

              parallel {

                stage('并行阶段1') {
                  steps {
                    echo "并行阶段1"
                  }
                }

                stage('并行阶段2') {
                  steps {
                    echo "并行阶段2"
                  }
                }

              }
          }
        }
    }

---------

# 参考文档

- http://www.ioo.cool/posts/fa563716f116
- https://www.jenkins.io/zh/doc/book/pipeline/jenkinsfile
- https://blog.csdn.net/lazycheerup/article/details/130401651
- https://blog.csdn.net/zhou920786312/article/details/125955651
- https://blog.csdn.net/qq_34556414/article/details/120663772
- https://blog.csdn.net/u012060033/article/details/127907588