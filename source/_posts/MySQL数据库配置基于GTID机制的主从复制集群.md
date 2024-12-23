---
title: MySQL数据库配置基于GTID机制的主从复制集群
categories:
  - 工作
tags:
  - Linux
  - MySQL
  - SQL
  - 数据库
  - 主从复制
  - 云计算
date: 2020-02-02 15:45:07
---

GTID，即全局事务标识，是MySQL 5.6新增功能，用于替代通过binlog文件偏移量定位复制位置的传统方式。GTID信息存储于binlog文件，且新增2个binlog事件：Previous_gtids_log_event，位于每个binlog文件的开头且记录了在该binlog文件之前已执行的GTID集合；Gtid_log_event，位于每个事务之前，标明下一事务的GTID
    
MySQL服务器启动时，读取binlog文件，初始化gtid_executed和gtid_purged，使之与上次MySQL运行时一致gtid_executed被设置为新binlog文件中Previous_gtids_log_event和所有Gtid_log_event的合集；gtid_purged为最旧的binlog文件中Previous_gtids_log_event

由于两个重要的变量记录在binlog，所以MySQL 5.6开启gtid_mode须在备库上开启log_slave_updates。MySQL5.7新增了一个系统表mysql.gtid_executed，用于持久化已执行的GTID集合。当主库上没有开启log_bin或在备库上没有开启log_slave_updates时，mysql.gtid_executed跟每次用户事务一起更新，否则只在binlog日志发生rotation时更新mysql.gtid_executed

---------

# 集群架构

- 172.16.100.200 master
- 172.16.100.100 slaver

---------

# 1.安装mysql数据库服务器

# 2.配置主节点

## 2.1 创建配置文件

    sudo vi /etc/my.cnf


    [mysqld]

    server-id=100
    log_bin=mysql-bin
    log-bin-index=mysql-bin.index
    binlog_format=row
    sync_binlog=100
    expire_logs_days=90
    # 启用DTID,MariaDB默认启用，不需配置
    gtid-mode=on
    # 强制执行GTID一致性,MariaDB默认启用，不需配置
    enforce-gtid-consistency=on

    # MariaDB默认启用，不需配置
    master_info_repository=TABLE
    # MariaDB默认启用，不需配置
    relay_log_info_repository=TABLE

    # 设置开启基于组提交的并行复制，默认为DATABASE，即基于数据库的并行复制
    slave-parallel-type=LOGICAL_CLOCK
    # 设置并行复制的SQL线程数，MariaDB为slave-parallel-threads
    slave-parallel-workers =8

    # 设置基于行的复制将SQL语句记录到二进制日志，默认为off
    binlog-rows-query-log_events=on
    # 设置从库是否将主库事务更新到本地二进制文件，用于级联复制架构，默认关闭
    # log_slave_updates=on
    # slave-skip-errors=all

## 2.2 主节点创建复制账户并授予从节点权限

    mysql> GRANT REPLICATION SLAVE ON *.* to 'syncer'@'172.16.100.100' identified by 'syncer';
    mysql> FLUSH PRIVILEGES;

# 3.配置从节点

## 3.1 创建配置文件

    sudo vi /etc/my.cnf


    [mysqld]

    server-id=200
    # 设置中继日志名称和存储位置
    relay_log=relay-bin
    # 设置中继日志索引名称和存储位置，用于存储最后一个中继日志的列表
    relay-log-index=relay-log-bin.index
    # 设置中继日志写入到磁盘文件的频率
    sync_relay_log=100
    # 设置启用中继日志修复功能，即中继日志损坏后重新从主服务器获取，防止其意外损坏造成位点信息读取错误，默认为0
    relay_log_recovery=1
    # 设置启用中继日志自动清理功能，配合relay_log_recovery参数防止从库意外崩溃后读取不准确的中继日志
    relay_log_purge=1

    # MariaDB默认启用，不需配置
    slaver_info_repository=TABLE
    # MariaDB默认启用，不需配置
    relay_log_info_repository=TABLE

    # 设置开启基于组提交的并行复制，默认为DATABASE，即基于数据库的并行复制
    slave-parallel-type=LOGICAL_CLOCK
    # 设置并行复制的SQL线程数，MariaDB为slave-parallel-workers
    slave-parallel-threads=4

    # 设置基于行复制是否启用二进制日志中的信息日志事件，MariaDB不需配置
    binlog-rows-query-log_events=on
    # 设置从库是否将主库事务更新到本地二进制文件，用于级联复制架构，默认关闭
    # log_slave_updates=on
    # slave-skip-errors=all

    replicate_ignore_db=mysql
    replicate_ignore_db=performance_schema
    replicate_ignore_db=information_schema

## 3.2 配置主从复制

    # MySQL数据库
    mysql>  change master to 
        master_host='172.16.100.200',
        master_port=3306,
        master_user='syncer',
        master_password='syncer',
        master_auto_position=1;

    # MariaDB数据库
    mysql>  change master to 
        master_host='172.16.100.100',
        master_port=3306,
        master_user='syncer',
        master_password='syncer',
        master_use_gtid=slave_pos;

## 3.3 开启主从复制功能

    mysql> start slave;

## 3.4 查看从节点复制功能状态，测试主从同步功能

    mysql> show slave status\G ; show processlist;
    *************************** 1. row ***************************
               Slave_IO_State: Waiting for node to send event
                  node_Host: 192.168.0.200
                  node_User: syncer
                  node_Port: 3306
                Connect_Retry: 60
              node_Log_File: node-bin.000001
          Read_node_Log_Pos: 859
               Relay_Log_File: relay-bin.000002
                Relay_Log_Pos: 321
        Relay_node_Log_File: node-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: data
          Replicate_Ignore_DB: test
           Replicate_Do_Table: data.test
       Replicate_Ignore_Table: test.test
      Replicate_Wild_Do_Table:
    Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_node_Log_Pos: 859
              Relay_Log_Space: 522
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           node_SSL_Allowed: No
           node_SSL_CA_File:
           node_SSL_CA_Path:
              node_SSL_Cert:
            node_SSL_Cipher:
               node_SSL_Key:
        Seconds_Behind_node: 0
    node_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
    Replicate_Ignore_Server_Ids:
             node_Server_Id: 200
                  node_UUID: 7b1bbc09-7009-11e8-8487-000c29a5e01f
             node_Info_File: mysql.slave_node_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           node_Retry_Count: 86400
                  node_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               node_SSL_Crl:
           node_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           node_TLS_Version:
    1 row in set (0.00 sec)

- 注：Slave_IO及Slave_SQL进程必须正常运行，即YES状态，否则表示复制状态不正常

---------

# 参考文档

- https://www.cnblogs.com/liangshaoye/p/5459421.html
- https://www.cnblogs.com/zhoujinyi/p/4717951.html
- https://blog.csdn.net/anzhen0429/article/details/77658663