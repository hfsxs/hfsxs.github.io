---
title: Zabbix监控MySQL数据库性能
categories:
  - 工作
tags:
  - Linux
  - Zabbix
  - 监控告警
  - 云计算
date: 2020-02-03 09:48:52
---

# 1.创建监控脚本

    vi /usr/local/zabbix/share/zabbix/alertscripts/mysql_status.sh


    #!/bin/bash

    export MYSQL_PWD=checking
    MYSQL_CONN="/usr/local/mysql/bin/mysqladmin -hlocalhost -uchecker"

    if [ $# -ne "1" ];then
      echo "arg error!"
    fi

    case $1 in
      Uptime)
        result=`${MYSQL_CONN} status|cut -f2 -d":"|cut -f1 -d"T"`
        echo $result
        ;;
      Com_update)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_update"|cut -d"|" -f3`
        echo $result
        ;;
      Slow_queries)
        result=`${MYSQL_CONN} status |cut -f5 -d":"|cut -f1 -d"O"`
        echo $result
        ;;
      Com_select)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_select"|cut -d"|" -f3`
        echo $result
                ;;
      Com_rollback)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_rollback"|cut -d"|" -f3`
                echo $result
                ;;
      Questions)
        result=`${MYSQL_CONN} status|cut -f4 -d":"|cut -f1 -d"S"`
                echo $result
                ;;
      Com_insert)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_insert"|cut -d"|" -f3`
                echo $result
                ;;
      Com_delete)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_delete"|cut -d"|" -f3`
                echo $result
                ;;
      Com_commit)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_commit"|cut -d"|" -f3`
                echo $result
                ;;
      Bytes_sent)
        result=`${MYSQL_CONN} extended-status |grep -w "Bytes_sent" |cut -d"|" -f3`
                echo $result
                ;;
      Bytes_received)
        result=`${MYSQL_CONN} extended-status |grep -w "Bytes_received" |cut -d"|" -f3`
                echo $result
                ;;
      Com_begin)
        result=`${MYSQL_CONN} extended-status |grep -w "Com_begin"|cut -d"|" -f3`
                echo $result
                ;;

        *)
        echo "Usage:$0(Uptime|Com_update|Slow_queries|Com_select|Com_rollback|Questions|Com_insert|Com_delete|Com_commit|Bytes_sent|Bytes_received|Com_begin)"
        ;;
    esac

---------

    chmod +x mysql_status.sh
    chown zabbix.zabbix mysql_status.sh

# 2.编辑zabbix_agent配置文件

    vi /etc/zabbix/zabbix_agentd.conf


    UnsafeUserParameters=1
    UserParameter=mysql.version,/usr/local/mysql/bin/mysql -V
    UserParameter=mysql.status[*],/usr/local/zabbix/share/zabbix/alertscripts/mysql_status.sh $1 $2
    UserParameter=mysql.ping,/usr/local/mysql/bin/mysqladmin ping|grep -c "alive"

# 3.启动zabbix agent

    systemctl start zabbix_agentd

# 4.创建mysql监控账户

    MariaDB [(none)]> GRANT SELECT ON *.* TO 'checker'@'localhost' IDENTIFIED BY 'checking';
    MariaDB [(none)]> flush privileges;

# 5.Mysql主机配置监控模板

导入mysql模板 ---> 主机链接模板

# 6.验证nginx监控

    /usr/local/zabbix/bin/zabbix_get -s 192.168.100.188 -k "mysql.status[Bytes_received]"