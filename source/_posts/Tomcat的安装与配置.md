---
title: Tomcat的安装与配置
categories:
  - 工作
tags:
  - Linux
  - Java
  - Tomcat
  - 云计算
date: 2020-02-04 09:58:55
---

Tomcat，用于运行JSP (Java Server Pages，Java服务器网页)和Servlet的基于Java的开源轻量级Web应用服务器。Tomcat是装载Java Web程序的Web容器，主要功能是按照J2EE中的Servlet规范编写好的Java程序解析为动态网页，并处理客户端的请求与响应，从而运行Java网站。Tomcat最初由Sun公司软件架构师詹姆斯·邓肯·戴维森开发，开源后由Sun公司贡献给Apache软件基金会，技术先进，性能稳定、配置简单，特别适用于中小型系统和并发数不是很多的场景，是开发和调试JSP程序的首选

---------

# 体系架构

tomcat由两个核心组件构成，即Connector、Container，两者组合为对外提供WEB服务的Service

## Connector

即连接器，负责对外接收和响应请求，是Tomcat服务器与外界的交通枢纽，监听端口接收外界请求，并将请求处理后传递给容器做业务处理，最后将容器处理后的结果响应给外部

## Container

即容器，负责对内处理业务逻辑，内部由Engine、Host、Context和Wrapper四个容器组成，用于管理和调用Servlet相关逻辑

Container内部包含父子关系的4个子容器，即容器由一个引擎管理多个虚拟主机，每个虚拟主机可以管理多个Web应用，每个Web应用又会有多个Servlet封装器

- Engine，引擎，用于管理多个虚拟主机，一个Service最多只能有一个 Engine
- Host，虚拟主机，又称为站点，通过配置Host可以添加站点
- Context，代表一个Web应用，包含多个 Servlet 封装器
- Wrapper，封装器，容器的最底层，每一Wrapper封装着一个Servlet，负责对象实例的创建、执行和销毁功能

## Service

即对外提供的Web服务，由Connector和Container两个核心组件及其他功能组件构成，一个Tomcat实例可以管理多个Service，且各个Service之间相互独立

# 工作流程

- connector接收请求，转发给servlet容器里的container，由container里的Engine进行响应
- Engine收到请求，分发给不同的站点，即host，由其调用Context确定相对应的路径，最后到达servlet容器，servlet会通过catalina将其中的Java代码翻译成能识别的servlet代码，最后执行的结果会返回给context
- 执行结果重新经过Context，Host，Engine一层一层的返还回去，到达Container，然后再到Connector，最后返回给客户端

---------

# 1.配置Java环境

## 1.1 安装jdk

    # yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
    # apt install -y 
    tar -zxvf jdk-8u131-linux-i586.tar.gz

## 1.2 配置环境变量

    vi /etc/profile 


    JAVA_HOME=/usr/local/jdk
    JAVA_BIN=/usr/local/jdk/bin
    JRE_HOME=/usr/local/jdk/jre 
    PATH=$PATH:/usr/local/jdk/bin:/usr/local/jdk/jre/bin
    CLASSPATH=/usr/local/jdk/jre/lib:/usr/local/jdk/lib:/usr/local/jdk/jre/lib/charsets.jar



## 1.3 生效环境变量

      source /etc/profile

## 1.4 验证java环境

    java --version

# 2.安装Tomcat

## 2.1 下载Tomcat安装包

## 2.2 安装tomcat

    tar -zxvf apache-tomcat-8.0.1.tar.gz
    mv apache-tomcat-8.0.1 /usr/local/tomcat

# 3.启动tomcat服务器

    /usr/local/tomcat/bin/startup.sh

# 4.访问tomcat

http://ip:8080