---
title: ELK日志分析平台的搭建与配置
categories:
  - 工作
tags:
  - Linux
  - ELK
  - Elasticsearch
  - 日志分析
  - 大数据
  - 云计算
date: 2020-02-07 10:00:17
---

ELK，即由Elasticsearch、Logstash、Kibana这三个开源软件作为核心组件构建的分布式实时日志分析平台，用于实时分析系统日志、应用程序日志和安全日志，以便于掌握服务器负荷、性能及安全性，从而及时采取措施纠正错误

---------

- Elasticsearch，开源分布式搜索引擎，提供搜集、分析、存储数据三大功能，且所有节点数据都是均等的
- Logstash，用于日志的收集与过滤，支持大量的数据获取方式，负责从每台服务器抓取日志数据，对数据进行格式转换和处理后，输出到Elasticsearch中存储
- Kibana，为Logstash和ElasticSearch提供日志分析的web界面，用于汇总、分析和搜索重要日志数据

---------

# 工作流程

1.logstash分布于各个应用服务器节点，用于收集日志及数据，经过过滤与处理后发送es到集群

2.elasticsearch集群为日志数据创建索引，并将之以分片的形式进行分布式压缩存储

3.kibana从ES集群中查询数据生成图表，提供直观的web呈现方式，实现数据的可视化

---------

# 集群架构

- 172.16.100.100 node01 kibana
- 172.16.100.120 node02 es logstash
- 172.16.100.200 master es

---------

# 1.部署ES集群

## 1.1 创建elasticsearch用户

    sudo useradd elasticsearch

## 1.2 安装JDK，配置JAVA环境

    sudo yum install -y java-1.8.0-openjdk java-1.8.0-openjdk-devel
    sudo apt install -y default-jdk

## 1.3 安装ES

    tar -xzvf elasticsearch-6.6.2.tar.gz
    sudo mv elasticsearch-6.6.2 /usr/local/elasticsearch

## 1.4 创建ES集群配置文件

    sudo vi /usr/local/elasticsearch/config/elasticsearch.yml


    # 设置ES集群名称
    cluster.name: sword
    # 设置节点名称
    node.name: node-master
    # 设置elasticsearch数据存储路径        
    path.data: /usr/local/elasticsearch/data
    # 设置elasticsearch日志存储路径     
    path.logs: /usr/local/elasticsearch/logs
    # 设置elasticsearch监听地址，默认为localhost 
    network.host: 172.16.100.200
    # 设置elasticsearch监听端口
    http.port:9200
    # 设置集ES集群主机组，自动发现节点及选定主节点
    discovery.zen.ping.unicast.hosts: ["172.16.100.120", "172.16.100.200"]

    # centos6需要配置
    bootstrap.memory_lock: false
    bootstrap.system_call_filter: false

---------

- 注：其余ES节点只需改动节点名称即可

## 1.5 配置elasticsearch用户系统资源限制

### 1.5.1 配置打开文件最大数

    sudo vi /etc/security/limits.conf
	

    # elasticsearch    soft    nproc           16384
    # elasticsearch    hard    nproc           16384
    # soft表示告警值，hard表示阀值
    elasticsearch    soft    nofile          65536
    elasticsearch    hard    nofile          65536

### 1.5.2 配置进程最大数，默认为4096，会覆盖掉limits.conf配置
 
    sudo vi /etc/security/limits.d/20-nproc.conf
	

    elasticsearch    soft    nproc    4096
    elasticsearch    hard    nproc    4096

## 1.6 配置内核参数

### 1.6.1 设置进程占用VMA(虚拟内存区域)的数量

    sudo vi /etc/sysctl.conf
	
	
    # 默认为65536
    vm.max_map_count=262144
	
### 1.6.2 加载内核参数配置
	
    sudo sysctl -p

## 1.7 启动ES集群

    mkdir /usr/local/elasticsearch/data
    chown -R elasticsearch.elasticsearch /usr/local/elasticsearch

    su - elasticsearch
    cd /usr/local/elasticsearch/bin
    nohup ./elasticsearch &

## 1.8 查询ES集群状态

    curl -XGET 'http://172.16.100.200:9200/_cat/nodes?v'

# 2.部署kibana

    tar -xzvf kibana-6.6.2-linux-x86_64.tar.gz
    sudo mv kibana-6.6.2-linux-x86_64 /usr/local/kibana

## 2.1 创建kibana配置文件

    sudo vi /usr/local/kibana/config/kibana.yml
	
	
    # 设置kibana监听端口
    server.port: 5601
    # 设置kibana监听地址
    server.host: "172.16.100.150"
    # 设置elasticsearch地址
    elasticsearch.hosts: ["http://172.16.100.200:9200"]

## 2.2.启动kibana

    cd /usr/local/kibana/bin
    nohup ./kibana &

# 3.部署logstash

    tar -xzvf logstash-6.6.2.tar.gz
    sudo mv logstash-6.6.2 /usr/local/logstash

## 3.1 创建logstash解析配置文件

    vi /usr/local/logstash/config/syslog.yml
	
	
    # 定义日志源
    input {

      file {
        # 设置源日志文件路径
        path => ["/var/log/messages"]
        # 设置日志类型，相当于关系数据库中的table
        type => "system"
        # 设置从哪里开始收集日志
        start_position => "beginning"
        # 定义监听端口
        # port => 10514
      }

      file {
        path => ["/var/log/secure"]
        type => "secure"
        start_position => "beginning"
        }
      }

      # 定义日志过滤规则
      # filter {
      #	}

      # 定义日志输出
      output {

        if [type] == "system" {

          # 输出到es
          elasticsearch {
          # 设置es地址与端口，多个用逗号隔开
          hosts => ["172.16.100.200:9200"]
          # 设置日志的索引名称，相当于关系型数据库中的database
          index => "system-%{+YYYY.MM.dd}"
          }
        }

        if [type] == "secure" {

          elasticsearch {
            hosts => ["172.16.100.200:9200"]
            index => "secure-%{+YYYY.MM.dd}"
          }
        }
    
      # 输出到当前终端
      stdout { codec => rubydebug }
    }

## 3.2 启动logstash

    cd /usr/local/logstash/bin

    # 检测配置文件的语法
    ./logstash -f /etc/logstash/conf.d/syslog.conf -t

    # 后台启动logstash
    nohup ./logstash -f /usr/local/logstash/config/syslog.conf > nohup.log &

# 4.登陆kibana查看日志分析效果

http://172.16.100.200:5601

---------

# 参考文档

- http://www.cnblogs.com/yuhuLin/p/7018858.html
- https://blog.51cto.com/xiaorenwutest/2135897