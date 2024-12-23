---
title: ELK实时分析Linux系统SSH远程登录
categories:
  - 工作
tags:
  - Linux
  - ELK 
  - SSH
  - Logstash
  - 日志分析
  - 大数据
  - 云计算
date: 2020-02-27 21:57:00
---

Linux系统的安全日志为/var/log/secure，记录了系统验证和授权的信息，只要涉及账号和密码的程序都会被记录，如SSH登录。对安全日志的监控有助于了解服务器的安全漏洞，从而采取相应的措施以提高安全性

---------

# SSH远程登录日志分析

## SSH登录成功的日志

    Nov  7 00:57:50 localhost sshd[22514]: Accepted password for root from 192.168.28.1 port 18415 ssh2
    Nov  7 00:57:50 localhost sshd[22514]: pam_unix(sshd:session): session opened for user root by (uid=0)

## SSH登录失败的日志

    Nov  7 00:59:12 localhost sshd[22602]: Failed password for root from 192.168.28.1 port 18443 ssh2
    Nov  7 00:59:14 localhost sshd[22602]: error: Received disconnect from 192.168.28.1 port 18443:0:  [preauth]

---------

- 综上，只需匹配出Accepted、Failed这两个字段即可判定远程登录的性质

---------

# 1.部署ELK

# 2.创建logstash配置文件

    sudo vi /usr/local/logstash/config/sshd.conf


    input{

      file { 
      path => ["/var/log/secure"] 
      type => "ssh_login" 
      start_position => "beginning" 
      }
    }

    filter {

      if [type] == "ssh_login" {

        grok { 
          match => {"message" => ".*sshd\[\d+\]: %{WORD:status} .* %{USER:username} from.*%{IP:clientip}.*"}
        }

        if [message] !~ "Accepted | Failed" { 
          drop {} 
        }

        geoip { 
          source => "clientip" 
          database => "/home/sword/logstash/tools/geoip/GeoLite2-City.mmdb" 
          add_field => [ "[geoip][coordinates]", "%{[geoip][longitude]}" ] 
          add_field => [ "[geoip][coordinates]", "%{[geoip][latitude]}" ]

          fields => ["ip","city_name","region_name","country_name","continent_code","longitude","latitude","location"]
        }

        mutate { 
          convert => [ "[geoip][coordinates]", "float"] 
          remove_field => ["timestamp","message","_id","_score","_type"] 
        } 

        if "_geoip_lookup_failure" in [tags] { drop { } }
        }
    }

    output{

      if [type] == "ssh_login" {

        elasticsearch{ 
          hosts => ["127.0.0.1:9200"] 
          index => "logstash-ssh-login-%{+YYYY.MM.dd}"
        }
      }

        stdout { codec => rubydebug }
    }

# 3.重启logstash