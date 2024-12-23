---
title: ELK实时分析Nginx日志
categories:
  - 工作
tags:
  - Linux
  - ELK 
  - Nginx
  - Logstash
  - 日志分析
  - 大数据
  - 云计算
date: 2020-03-09 20:39:39
---

Nginx是云计算最基础最常用的组件，许多业务架构的入口流量都是由其进行转发，其日志对业务的动作分析有着重大意义

Logstash，日志收集工具，可以从本地磁盘、网络服务、消息队列中收集各种日志，自带的grok具有强大的日志解析、切割功能。其工作流程大致分为三个阶段:输入input --> 处理filter（非必须） --> 输出output

Logstash配置文件由三部分组成

- input{}：此模块负责收集日志，可从文件、消息队列（redis、kafka、MQ等）、tcp端口等产生日志的业务直接写入logstash
- filter{}：此模块负责过滤收集到的日志，并根据过滤后对日志定义显示字段
- output{}：此模块负责将过滤后的日志输出到elasticsearch或者文件、redis等

---------

# 1.部署ELK

# 2.配置nginx日志格式

    sudo vi /etc/nginx/nginx.conf


    log_format  main  '$remote_addr - $remote_user [$time_local] "$request" '
                  '$status $body_bytes_sent "$http_referer" '
                  '"$http_user_agent" "$http_x_forwarded_for" ' 
                  '"$request_time" "$upstream_response_time" "$upstream_addr" ';

# 3.配置logstash过滤nginx日志

    sudo vi /home/sword/logstash/config/nginx.yml


    input{

      file {
      path => ["/var/log/nginx/*access.log"]
      type => "nginx_access"
      start_position => "beginning"
      }

      file {
        path => ["/var/log/nginx/*error.log"]
        type => "nginx_error"
        start_position => "beginning"
        }
    }

    # 配置过滤器
    filter {

    if [type] == "nginx_access" {
  
      # 配置正则表达式结构化nginx日志
      grok {

    match => { "message" => "%{IPORHOST:remote_addr} - %{DATA:remote_user} \[%{HTTPDATE:access_time}\] \"%{WORD:http_method} %{DATA:url} HTTP/%{NUMBER:http_version}\" %{NUMBER:response_code} %{NUMBER:bytes_sent} %{NUMBER:body_bytes_sent} \"%{DATA:http_referer}\" \"%{DATA:http_user_agent}\" \"%{DATA:http_x_forwarded_for}\" \"%{DATA:request_time}\" \"%{DATA:upstream_response_time}\" \"%{DATA:upstream_status}\" \"%{HOSTPORT:upstream_addr}\""}
   
        }

      # 配置时间处理规则
      date {
        match => ["access_time", "dd/MMM/yyyy:HH:mm:ss Z"]
        remove_field => ["timestamp"]
        }

      if [remote_addr] != "-" {
   
       # 配置IP解析规则
       geoip {

         source => "remote_addr"
         database => "/home/sword/logstash/tools/geoip/GeoLite2-City.mmdb"

         add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
         add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]

         fields => ["ip","city_name","region_name","country_name","continent_code","longitude","latitude","location"]

        }
      }

      # 配置浏览器解析规则
      if [http_user_agent] != "-" {

        useragent {
          target => "http_user"
          source => "http_user_agent"
          }
      }

    # if [url] =~ "jpress/article" or [url] =~ "post" {

        #mutate {
             #add_field => {"url_tmp" => "%{[url]}"}
           #}
     #}

     #mutate {
       #split => ["url_tmp","/"]
       #add_field => {"article" => "%{[url_tmp][3]}"}
           #}

     #if [article] =~ "url_tmp" {
            #drop {}
     #}

      urldecode{
        all_fields=>true
      }

      # 配置类型转换规则
      mutate {

        convert => ["request_time", "float"]
        convert => ["upstream_response_time", "float"]
        convert => ["body_bytes_sent", "integer"]

        # 剔除掉多余字段
        remove_field => ["_id","_score","_type","message","http_user_agent","url_tmp"]
      }

    }

    if [type] == "nginx_error" {

      grok {

        match => [ "message" , "(?<timestamp>%{YEAR}[./-]%{MONTHNUM}[./-]%{MONTHDAY}[- ]%{TIME}) \[%{LOGLEVEL:severity}\] %{POSINT:pid}#%{NUMBER}: %{GREEDYDATA:errormessage}(?:, client: (?<clientip>%{IP}|%{HOSTNAME}))(?:, server: %{IPORHOST:server}?)(?:, request: %{QS:request})?(?:, upstream: (?<upstream>\"%{URI}\"|%{QS}))?(?:, host: %{QS:request_host})?(?:, referrer: \"%{URI:referrer}\")?"]
      }

      geoip {
        source => "clientip"
        database => "/home/sword/logstash/tools/geoip/GeoLite2-City.mmdb"

        add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ]
        add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}"  ]

        fields => ["ip","city_name","region_name","country_name","continent_code","longitude","latitude","location"]
     }
        mutate {
         convert => [ "[geoip][coordinates]", "float"]
         remove_field => ["timestamp","message","_id","_score","_type"]
        }
    }

      if "_geoip_lookup_failure" in [tags] { drop { } }

    }

    # 配置输出规则
    output{

    if [type] == "nginx_access" {

      elasticsearch{
      hosts => ["127.0.0.1:9200"]
      index => "logstash-nginx-access-%{+YYYY.MM.dd}"

      }
    }

    if [type] == "nginx_error" {

      elasticsearch{
      hosts => ["127.0.0.1:9200"]
      index => "logstash-nginx-error-%{+YYYY.MM.dd}"
      }

    }

    # 输出到屏幕
    # stdout { codec => rubydebug }

    }
    
# 4.重启logstash

---------   
    
# 参考文档

- https://www.cnblogs.com/liuning8023/p/5502460.html
- https://blog.51cto.com/aegis8/1900969?source=dra
- https://www.cnblogs.com/liuning8023/p/5502460.html