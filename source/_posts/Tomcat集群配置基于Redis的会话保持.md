---
title: Tomcat集群配置基于Redis的会话保持
categories:
  - 工作
tags:
  - Linux
  - Java
  - Tomcat
  - Redis
  - 负载均衡
  - 集群
  - 会话保持
  - 云计算
date: 2020-02-04 22:21:53
---

# 集群架构

- 172.16.100.100  node01  nginx tomcat redis
- 172.16.100.120  node02  tomcat
- 172.16.100.200  node03  tomcat

---------

# 1.部署tomcat负载均衡集群

# 2.部署redis

    vi /etc/redis/redis.conf


    # 设置绑定IP
    bind 0.0.0.0

# 3.tomcat节点添加redis jar包

    cp *.jar /usr/local/tomcat/lib

# 4.tomcat配置文件添加redis节点

    vi /usr/local/tomcat/conf/context.xml


    <Context>

      <!-- redis node -->
      <Valve className="com.orangefunction.tomcat.redissessions.RedisSessionHandlerValve" />
      <Manager className="com.orangefunction.tomcat.redissessions.RedisSessionManager" 
      host="172.16.100.100" 
      port="6379"
      password="redis"
      database="2" 
      maxInactiveInterval="60"/>

    </Context>

5.tomcat节点创建测试文件

    vi /usr/local/tomcat/webapps/ROOT/test.jsp


    <%@ page language="java" import="java.util.*" pageEncoding="UTF-8"%>  
    <%  
    String path = request.getContextPath();  
    String basePath = request.getScheme()+"://"+request.getServerName()+":"+request.getServerPort()+path+"/";  
    %>  

    <!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01 Transitional//EN">  
    <html>  
      <head>  
        <base href="<%=basePath%>">  
        <title>My JSP 'index.jsp' starting page</title>  
        <meta http-equiv="pragma" content="no-cache">  
        <meta http-equiv="cache-control" content="no-cache">  
        <meta http-equiv="expires" content="0">      
        <meta http-equiv="keywords" content="keyword1,keyword2,keyword3">  
        <meta http-equiv="description" content="This is my page">  
        <!-- 
        <link rel="stylesheet" type="text/css" href="styles.css"> 
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

# 6.启动redis、tomcat、nginx，验证集群会话保持功能

    http://172.16.100.100/test.jsp

# 7.停止tomcat节点，模拟集群故障

---------

# 参考文档

- http://blog.51cto.com/oceanszf/1752641
- http://lyl-zsu.iteye.com/blog/2408292