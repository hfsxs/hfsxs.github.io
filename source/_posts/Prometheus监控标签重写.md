---
title: Prometheus监控标签重写
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Alertmanager
  - 监控告警
  - 云计算
date: 2023-11-27 15:07:02
---

relabel，即标签重写，是Prometheus监控在数据抓取之前对其标签动态改写的功能，由配置项relabel_configs完成对标签的添加、删除、重命名、合并及提取替换等操作，以满足不同场景下的需求，更好地分析和查询数据

# 1.内置标签

targets以"__"为前置的标签一般是系统内置标签，不会写入到指标数据，但可通过标签重新操作将之写入指标数据，如instance标签就是通过对target实例的内置标签__address__所做的重写操作。常见内置标签如下：

- __address__，当前Target实例的访问地址<host>:<port>
- __scheme__，采集目标服务访问地址的HTTP Scheme，HTTP或者HTTPS
- __metrics_path__，采集目标服务访问地址的访问路径
- __param_<name>，采集任务目标服务的中包含的请求参数

# 2.自定义标签

## 2.1 修改Prometheus配置文件

    sudo vi /usr/local/prometheus/prometheus.yml


    - job_name: "node"
        static_configs:
          - targets: ["worker01:9100"]
            labels:
              env: formal
              __hostname__: worker01

## 2.2 重启Prometheus

    sudo systemctl restart prometheus.service

## 2.3 验证自定义标签

# 3.标签重写

## 3.1 配置解析

    relabel_configs:
      # 设置源标签，支持正则表达式
      - source_labels: [ 'labelname' ]
        # 设置多个源标签的分隔符，默认为分号;
        separator: _
        # 设置重写操作的目标标签
        target_label: [ 'labelname' ]
        # 设置匹配源标签所用的正则表达式，默认为(.*)，即全部匹配
        regex: "正则表达式"
        # 设置正则表达式匹配用于替换的值，默认为$1，以代替正则匹配到的值
        replacement: $1-$2

        # 设置基于正则表达式匹配要执行的动作，如keep、drop等，默认为replace
        action: relabel_action
 
        # 设置哈希模式下源标签值哈希值的模数，作为系数计算源标签的哈希值
        modulus: int
 
action类型

- replace，缺省类型，正则匹配源标签的值用于替换目标标签
- keep，如果正则没有匹配到源标签的值，则删除该targets，不进行采集
- drop，与keep相反，正则匹配到源标签则删除该targets
- labelmap，正则匹配所有标签名，将匹配的标签值部分做为新标签名，原标签值做为新标签的值
- labeldrop，正则匹配所有标签名，匹配则移除标签
- labelkeep，正则匹配所有标签名，不匹配的标签会被移除
- hashmod，将一个或多个源标签的值经过哈希运算后作为目标标签的值，用于Prometheus集群的负载均衡

## 3.2 指标新增重写

    relabel_configs:
      - source_labels: [ '__address__' ]
        # 将内置标签__address__重写为addr，并继承其标签的值
        target_label:  'addr'

## 3.3 指标覆盖重写

    relabel_configs:
      - source_labels: [ '__address__' ]
        target_label:  'addr'
        # 将内置标签__address__重写为addr，并将标签值设为自定义的localhost
        replacement: 'localhost'

## 3.4 指标拼接重写

    relabel_configs:
      - source_labels: ['__address__','job']
        separator: _
        # 将两个内置标签以“_”为分隔符作连接，标签值继承源标签，重写结果为：192.168.100.100:9100_node    
        target_label: addr

## 3.5 正则重写

    relabel_configs:
      - source_labels: [ '__address__' ]
        target_label:  'addr'
        # 将获取到的源标签的值做正则匹配，匹配结果为：192.168.100.100 9100
        regex: "(.*):(.*)"
        # 将内置标签__address__经过正则匹配的值进行重写，$1/$2表示位置变量，重写结果为：192.168.100.100_9100
        replacement: $1_$2

## 3.6 指标丢弃重写

### 3.6.1 drop

    relabel_configs:
      - source_labels: ['addr']
        regex: "192.168.100.100_9100"
        # 将正则表达式匹配到源标签值的target采集到的数据丢弃
        action: drop

### 3.6.2 keep

    relabel_configs:
      - source_labels: ['addr']
        regex: "192.168.100.100_9100"
        # 将正则表达式匹配到源标签值的target采集到的数据保留，未匹配到的则全部丢弃，与drop相反
        action: keep

## 3.7 标签删除重写

### 3.7.1 labeldrop

    relabel_configs:
      - regex: '(job)'
        #  将所有正则匹配到的标签删除
        action: labeldrop

### 3.7.2 labelkeep

    relabel_configs:
      - regex: '(job)'
        # 将所有未被正则匹配到的标签删除，与labeldrop相反
        action: labelkeep    

## 3.8 标签重命名重写

     relabel_configs:
       - regex: monitor_(.*)
         replacement: '${1}'
         # 将所有以monitor_开头的标签名重写替换为去掉monitor_前缀的新标签名字，类似于覆盖重写，如monitor_mysql="01"--> mysql="01"
         action: labelmap

## 3.9 哈希重写

哈希重写是将一个或多个源标签的值进行hash运算，所得到的值作为目标标签的值，这样只要hash值一致则表示源标签一致，再对Prometheus根据该hash值标签设置不同的取舍action，如某个Prometheus只采集hash值为1的指标。这样完成了同个指标的分片拆分操作，从而实现多个Prometheus横向扩展副本的负载均衡，缓解了指标采集压力

    - job_name: "mysqld"
      file_sd_configs:
      - files:
        - /usr/local/prometheus/config/*.yaml
        refresh_interval: 2m
      relabel_configs:
        - source_labels: [ 'instance','__address__']
          action: hashmod
          modulus: 2
          target_label: hash_id

---------

# 参考文档

- https://andyoung.blog.csdn.net/article/details/126263009
- https://blog.csdn.net/qq_21127151/article/details/130098062
- https://blog.csdn.net/qq_42883074/article/details/115894190
- https://blog.csdn.net/weixin_40046357/article/details/120540581