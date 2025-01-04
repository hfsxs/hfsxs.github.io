---
title: Tomcat集群配置基于Memcached的会话保持
categories:
  - 工作
tags:
  - Linux
  - Java
  - Tomcat
  - Memcached
  - 负载均衡
  - 集群
  - 会话保持
  - 云计算
date: 2020-02-04 10:27:05
---

# 集群架构

- 192.168.0.180 tomcat nginx 
- 192.168.0.100 tomcat memcached
- 192.168.0.200 tomcat

---------

# 1.安装nginx、tomcat、memcached

# 2.tomcat节点添加memcached jar包

    cp *.jar /usr/local/tomcat/lib

    memcached-session-manager-2.1.1.jar
    spymemcached-2.11.1.jar
    tomcat-memcached-session-manage-tomcat8.jar

# 3.tomcat配置文件添加memcached节点

    vi /usr/local/tomcat/conf/context.xml


    <Context>

      # memcached node
      <Manager className="de.javakaffee.web.msm.MemcachedBackupSessionManager
      "memcachedNodes="n:192.168.0.150:11211"
      lockingMode="auto"
      sticky="false"
      requestUriIgnorePattern= ".*\.(png|gif|jpg|css|js|html)$"
      sessionBackupAsync= "false"
      sessionBackupTimeout= "100"
      transcoderFactoryClass="de.javakaffee.web.msm.JavaSerializationTranscoderFactory"/>

    </Context>

# 4.nginx反向代理负载均衡的配置

# 5.tomcat节点配置测试文件

    vi /usr/local/tomcat/webapps/ROOT/test.jsp


    <%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>  
    <%  
    String path = request.getContextPath();  
    String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";  
    %>  

    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
    <html>  
      <head>  
        <base href="<%=basePath%>">  

        <title>My JSP 'index.jsp' starting page</title>  
        <meta http-equiv="pragma" content="no-cache">  
        <meta http-equiv="cache-control" content="no-cache">  
        <meta http-equiv="expires" content="0">      
        <meta http-equiv="keywords" content="keyword1,keyword2,keyword3">  
        <meta http-equiv="description" content="This is my page">  
        <!-- 
        <link rel="stylesheet" type="text/css" href="styles.css"> 
        -->  
      </head>  

      <body>  

        SessionID:<%=session.getId()%>  
        <BR>  
        SessionIP:<%=request.getServerName()%>  
        <BR>  
        SessionPort:<%=request.getServerPort()%> 
        <%  
        out.println("tomcat-node-001");  
        %>  
      </body>  
    </html>

# 6.启动memcached、tomcat、nginx，验证集群功能

http://192.168.0.180/test.jsp

---------

# 参考文档

- https://www.cnblogs.com/jsonhc/p/7344902.html