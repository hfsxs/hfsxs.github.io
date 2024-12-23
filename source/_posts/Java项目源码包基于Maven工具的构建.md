---
title: Java项目源码包基于Maven工具的构建
categories:
  - 工作
tags:
  - Linux
  - Java
  - Tomcat
  - 云计算
date: 2024-01-18 18:05:17
---

Maven，Apache旗下由Java开发的开源项目管理和构建工具，基于项目对象模型(POM)的概念，通过描述信息管理项目的构建、报告和文档，特别适用于Java项目的构建与依赖管理，也可用于其他项目，如C#、Ruby和Scala等等

# 1.配置Java环境

# 2.下载Maven安装包

    wget https://dlcdn.apache.org/maven/maven-3/3.9.6/binaries/apache-maven-3.9.6-bin.tar.gz

# 3.安装Maven

        tar -xzvf apache-maven-3.9.6-bin.tar.gz
        sudo mv  apache-maven-3.9.6-bin /usr/local/maven
        sudo ln -s /usr/local/maven/bin/mvn /usr/local/bin/mvn

# 4.配置仓库

## 4.1 配置本地仓库

    sudo mkdir -p /usr/local/maven/repository
    sudo vi /usr/local/maven/conf/settings.xml


    <localRepository>/usr/local/maven/repository</localRepository>

## 4.2 配置远程仓库

    sudo vi /usr/local/maven/conf/settings.xml


    <mirror>
        <id>alimaven</id>
        <mirrorOf>central</mirrorOf>
        <name>aliyun maven</name>
        <url>http://maven.aliyun.com/nexus/content/groups/public</url>
    </mirror>

# 5.下载开源项目Jpress的Java源码包

# 6.编译Jpress项目

    unzip jpress-v5.x.zip
    cd jpress
    # 源码包打包
    sudo mvn clean package
    # 将源代码打包为jar包，并下载到本地仓库
    # sudo mvn install

# 7.验证编译文件

    ls -l starter-tomcat/target

# 8.Tomcat部署Jpress，验证编译结果

    sudo cp starter-tomcat/target/starter-tomcat-5.0.war /usr/local/tomcat/webapps/jpress.war

---------

# 参考文档

- http://doc.jpress.cn/manual/maven_config.html
- https://www.runoob.com/maven/maven-setup.html
- https://blog.csdn.net/m0_63684495/article/details/129046405