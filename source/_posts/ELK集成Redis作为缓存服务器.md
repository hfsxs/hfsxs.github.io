---
title: ELK集成Redis作为缓存服务器
categories:
  - 工作
tags:
  - Linux
  - ELK 
  - Redis
  - Filebeat
  - 日志分析
  - 大数据
  - 云计算
date: 2020-02-15 18:20:14
---

Filebeat、Logstash、Elasticsearch、Kibana构成了经典的ELK架构，适用于数据量较小的环境。大型生产环境中，业务流量的突发峰值将对Elasticsearch造成巨大的冲击，存在安全隐患。鉴于此，引入消息队列（Redis、Kafka或RabbitMQ）作为缓冲，用以削平峰值及异步容错，缓解了后端Elasticsearch集群的压力

---------
    
# 工作流程

- Filebeat收集应用服务器的日志数据，发送到Redis消息队列
- Logstash从Redis消息队列取到日志数据，过滤、结构化后发送到Elasticsearch集群存储
- kibana连接Elasticsearch集群提供数据的可视化分析与展示

---------

# 1.安装elk、filebeat、redis

# 2.配置filebeat

    sudo vi /usr/local/filebeat/filebeat.yml


    filebeat.prospectors:

    - type: log
      enabled: true
      paths:
        - /var/log/nginx/access.log
      tags: ["nginx"]

    # 输出到redis
    output.redis:

      # 设置redis地址与端口
      hosts: ["172.16.100.200:6379"]
      # 设置存储在redis队列的key
      key: "nginx_zabbix"
      # 设置redis连接密码
      password: "redis"
      # 设置redis存储数据库
      db: 0
      # 设置redis连接超时时长
      timeout: 5

# 3.配置logstash

    input{

    redis {
      host => "172.16.100.200"
      port => "6379"
      password => "redis"
      key => "nginx_zabbix"
      type => "nginx"
      # 设置数据类型为队列
      data_type => "list"
      db => 0
      timeout => 5
      }

    }

    output{

      elasticsearch{
        hosts => ["172.16.100.150:9200","172.16.100.200:9200"]
        index => "nginx-%{+YYYY.MM.dd}"
        document_type => "nginx"
        }

    stdout { codec => rubydebug }

    }

---------

# 参考文档

- https://www.cnblogs.com/wangmo/p/9505883.html
- https://www.jianshu.com/p/87e737c081d4
- https://doc.yonyoucloud.com/doc/logstash-best-practice-cn/input/redis.html