---
title: ELK日志分析平台集成Kafka作为缓存服务
categories:
  - 工作
tags:
  - Linux
  - ELK 
  - Kafka
  - Filebeat
  - 日志分析
  - 大数据
  - 云计算
date: 2020-02-16 14:03:00
---

Redis的消息推送功能多用于实时性较高而持久性较低的场景，且redis本身并没有消息队列的容错机制。由于Redis的数据存储于内存，生产的消息只能一次性全部处消费掉，且没有留下任何痕迹，若消息在未到达消费者前因网络中断或其它缘由就发生丢失，而接受者并不知道有此消息，最终就会导致分布式事务的不一致，排查问题也无从着手

kafka的数据是consumer端的，所以对于消费而言consumer被赋予极大的自由度。consumer可以顺序地消费消息，也可以重新消费之前处理过的消息
    
# 工作流程

- 1.filebeat收集应用服务器的日志数据，发送到Kafka消息系统
- 2.logstash从Kafka消息队列取到日志数据，过滤、结构化后发送到elasticsearch集群存储
- 3.kibana连接elasticsearch集群提供数据的可视化分析与展示

# 1.安装es、logstash、filebeat、kafka

# 2.配置filebeat

    sudo vi /usr/local/filebeat/filebeat.yml


    filebeat.prospectors:

    input {
      kafka {
        bootstrap_servers => ["172.16.100.100:9092,172.16.100.150:9092,172.16.100.200:9092"]
    topics => ["nginx_access"]
    codec => "json"
    auto_offset_reset => "latest"
    consumer_threads => 1
    decorate_events => true
    type => "nginx_access"
      }
    }

    output.kafka:

    hosts: ["172.16.100.100:9092","172.16.100.150:9092","172.16.100.200:9092"]
    topic: 'nginx_access'
    partition.round_robin:
        reachable_only: false
    required_acks: 1
    compression: gzip
    max_message_bytes: 1000000

# 3.配置logstash



# 参考文档

- https://www.cnblogs.com/wangmo/p/9505883.html
- https://www.jianshu.com/p/87e737c081d4
- https://doc.yonyoucloud.com/doc/logstash-best-practice-cn/input/redis.html