---
title: ELK配置Filebeat收集日志
categories:
  - 工作
tags:
  - Linux
  - ELK 
  - Filebeat
  - 日志分析
  - 大数据
  - 云计算
date: 2020-02-10 15:15:53
---

Logstash可用于日志的收集，但资源消耗巨大，并不适合部署于应用服务器上收集日志，主要用于日志的过滤与格式化处理

Filebeat用于日志的收集更灵活，消耗资源较少，扩展性也较强。filebeat部署于应用服务器负责收集日志，logstash负责日志的解析、过滤及格式化，再发送给es集群进行日志的存储，大大节省了资源的开销，构建了经典的日志分析平台

# 1.部署ELK

# 2.配置logstash

## 2.1 创建配置文件

    sudo vi /usr/local/logstash/config/system.yml


    input{
    # 定义日志源为filebeat
    beats {
    port => 5044
        }
    }

    output{
    elasticsearch{
    hosts => ["172.16.100.200:9200"]
    index => "system-%{+YYYY.MM.dd}"
    document_type => "system"
    }

    stdout { codec => rubydebug }

    }
    
## 2.2 启动logstash
     
    nohup /usr/local/logstash/bin/logstash -f /usr/local/logstash/config/system.yml &

# 3.部署filebeat

    tar -xzvf filebeat-6.6.2-linux-x86_64.tar.gz
    sudo mv filebeat-6.6.2-linux-x86_64 /usr/local/filebeat

## 3.1 配置filebeat

    sudo vi /usr/local/filebeat/system.yml


    filebeat.prospectors:

    # 设置日志类型，log或stdin
    - input_type: log
    enabled: true
    # 设置日志路径
    paths:
    - /var/log/messages
    - /var/log/secure
    # 设置字符集编码
    encoding: utf-8
    # 设置文档类型，即es集群_type的值
    document_type: system
    # 设置日志标签，便于logstash的过滤
    tags: ["httpserver"]
    # 排除.gz结尾的文件
    exclude_files: [".gz$"]
    # 只发送的日志信息
    # include_lines:["^ERR","^WARN"]
    # 不发送的日志信息
    # exclude_lines:["^OK"]
    # 添加自定义字段
    # fields:
    # logIndex:httpserver
    # logsource:http-server
    # logtype:httpserver_system
    # projecta:zrlog

    - input_type: log
    enabled: true
    paths:
    - /usr/local/php-fpm/var/*.log
    tags: ["php"]

    output.logstash:
    hosts: ["172.16.100.150:5044"]
    # 设置filebeat的id，默认为beats
    client_id: httpserver

## 3.2 启动filebeat

    nohup /usr/local/filebeat/filebeat -e -c /usr/local/filebeat/filebeat.yml &

# 4.登陆kibana

---------

# 参考文档

- https://www.dgstack.cn/archives/2858.html
- https://blog.csdn.net/xuguokun1986/article/details/73560195/
- https://blog.51cto.com/michaelkang/1864225