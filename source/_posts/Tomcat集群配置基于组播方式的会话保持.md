---
title: Tomcat集群配置基于组播方式的会话保持
categories:
  - 工作
tags:
  - Linux
  - Java
  - Tomcat
  - 负载均衡
  - 集群
  - 会话保持
  - 云计算
date: 2020-02-04 10:12:40
---

# 集群架构

- 172.16.100.100  node01  nginx tomcat
- 172.16.100.120  node02  tomcat
- 172.16.100.200  node03  tomcat

---------

# 1.部署nginx、tomcat，配置负载均衡集群

# 2.修改tomcat配置文件，启用session复制和Cluster功能

    vi  /usr/local/tomcat/conf/server.xml


    <Cluster className="org.apache.catalina.ha.tcp.SimpleTcpCluster"  channelSendOptions="8">

    <Manager className="org.apache.catalina.ha.session.DeltaManager"
                   expireSessionsOnShutdown="false"
                   notifyListenersOnReplication="true"/>

    <Channel className="org.apache.catalina.tribes.group.GroupChannel">

        <Membership className="org.apache.catalina.tribes.membership.McastService"

			# 设置集群组播地址
            address="228.0.0.4"
            port="45564"
            frequency="500"
            dropTime="3000"/>

        <Receiver className="org.apache.catalina.tribes.transport.nio.NioReceiver"

		    # 设置本机IP
            address="192.168.0.120"
            port="4000"
            autoBind="100"
            selectorTimeout="5000"
            maxThreads="6"/>

        <Sender className="org.apache.catalina.tribes.transport.ReplicationTransmitter">
        <Transport className="org.apache.catalina.tribes.transport.nio.PooledParallelSender"/>
        </Sender>
        <Interceptor className="org.apache.catalina.tribes.group.interceptors.TcpFailureDetector"/>
        <Interceptor className="org.apache.catalina.tribes.group.interceptors.MessageDispatch15Interceptor"/>
    </Channel>

    <Valve className="org.apache.catalina.ha.tcp.ReplicationValve" filter=""/>
    <Valve className="org.apache.catalina.ha.session.JvmRouteBinderValve"/>

    # <Deployer className="org.apache.catalina.ha.deploy.FarmWarDeployer"
        # tempDir="/tmp/war-temp/"
        # deployDir="/tmp/war-deploy/"
        # watchDir="/tmp/war-listen/"
        # watchEnabled="false"/>

    <ClusterListener className="org.apache.catalina.ha.session.ClusterSessionListener"/>
    </Cluster>

    # 设置路由信息，集群唯一
    <Engine name="Catalina" defaultHost="localhost" jvmRoute="tomcat1">

# 3.配置项目web.xml文件

    vi  /usr/local/tomcat/webapps/ROOT/WEB-INF/web.xml


    <web-app 

    <display-name>loadbalancer</display-name>
    <distributable/>

    </web-app>

# 4.创建测试页面

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
        out.println("000000");  
        %>  
      </body>  
    </html>

# 5.启动tomcat、nginx，验证集群会话保持功能

# 6.集群组播相关命令

    route add -host 228.0.0.4 dev eth0
    route add -net 224.0.0.0 netmask 240.0.0.0 dev eth0