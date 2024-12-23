---
title: MySQL数据库配置主从复制集群
categories:
  - 工作
tags:
  - Linux
  - MySQL
  - SQL
  - 数据库
  - 主从复制
  - 云计算
date: 2020-02-02 15:27:27
---

MySQL的复制功能是构建大规模、高性能数据库应用的基础，就是将一台数据库服务器的数据和其它服务器保持同步，主库可同步到多台备库，备库也可作为其他服务器的主库，主备之间可以有多种不同的组合方式。复制的基本原理即主库记录DDL和DML操作写入二进制日志，从库连接主库并将获取到的二进制日志重新执行，从而保持主备数据的一致性

# 工作流程

## 1.主库记录binlog

主节点启动binlog dump线程，事务处理完成后将该次更新写入binlog，然后通知存储引擎提交事务，完成该次更新

## 2.从库请求读取主库binlog

从库启动IO线程，连接到主库，请求读取主库的binlog

## 3.主库发送binlog到从库

主库根据从库的请求信息，将本地binlog文件与从库请求的位点信息对比，将binlog文件传送给从库的IO线程。若无请求位点信息，则从第一个日志文件中的第一个事件一个一个传送给从库

## 4.从库将binlog写入中继日志Relay Log

从库IO线程将获取到的主库的日志、位点信息写入本地中继日志Relay Log的最末端，并将新的binlog文件名和位点记录到master-info文件，以记录已读取得主库的最新位置信息。若主从节点同步一致，则从库IO线程进入睡眠状态，直到主库有新事件产生后被唤醒，再将新事件更新到中继日志

## 5.从库更新数据

从库SQL线程实时监测到本地Relay Log文件，将其最新更新的日志解析为SQL并执行，重复主库的事务，完成本次复制，最后将从库的中继日志及位点信息写入relay_log.info，以记录下次数据复制的初始位点

---------

# 集群架构

- 172.16.100.200 master
- 172.16.100.100 slaver

---------

# 1.安装Mysql数据库服务器

# 2.配置主节点

## 2.1 创建配置文件

    sudo vi /etc/my.cnf


    [mysqld]
    # 设置服务器ID，具有唯一性
    server-id=100
    # 设置二进制日志名称和存储位置
    log-bin=mysql-bin
    # 设置二进制日志索引名称和存储位置，用于存储最后一个binlog文件的名称
    log-bin-index=mysql-bin.index
    # 二进制日志格式，默认为statement，基于SQL语句复制，可能会造成ID重复；row，基于数据行复制，日志量大；mix，混合复制
    binlog_format=mixed
    # 设置二进制日志写入到磁盘文件的频率，二进制日志先写入binlog_cache，再根据此参数写入到磁盘文件，复制的关键参数，影响性能与完整性，从库可不启用，默认为0，由操作系统调配，性能最高，安全性低；1，安全性最好，性能最低；n，n次事件提交后执行fsync磁盘同步指令，文件系统再将缓存到内存的binlog数据更新到磁盘
    sync_binlog=100
    # 设置每个连接会话所占用缓存量，默认32k
    # binlog_cache_size=64k
    # 设置binlog最大缓存内存量，默认1M，可通过binlog_cache_use、binlog_cache_size及binlog_cache_disk_use参数判断设置是否合理，若binlog_cache_disk_use大于1或者binlog_cache_use* binlog_cache_size大于max_binlog_cache_size，则需要调大该值
    # max_binlog_cache_size=2M
    # 设置二进制日志文件保存时长，默认为0，即永久保存
    # expire_logs_days=30

## 2.2 创建复制账户并授予权限

    mysql>  GRANT REPLICATION SLAVE ON *.* to 'syncer'@'172.16.100.100' identified by 'syncer';
    mysql>  FLUSH PRIVILEGES;

## 2.3 查看主节点二进制位置

    mysql> show master status;
    +-------------------+----------+--------------+------------------+-------------------+
    | File              | Position | Binlog_Do_DB | Binlog_Ignore_DB | Executed_Gtid_Set |
    +-------------------+----------+--------------+------------------+-------------------+
    | log-bin.000001    |    120 |              |                  |                   |
    +-------------------+----------+--------------+------------------+-------------------+
    1 row in set (0.00 sec)

- 执行完此步骤后不要再操作主数据库，防止主节点二进制日志位置更新

---------

# 3.配置从节点

## 3.1 创建配置文件

    sudo vi /etc/my.cnf


    [mysqld]

    # 设置服务器ID，具有唯一性
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

    # 设置从库的主节点位点信息写入磁盘的频率
    # sync_master_info=100
    # 设置从库的主节点位置信息存储方式，TABLE|FILE
    master_info_repository=TABLE
    # 设置从库位点信息写入磁盘的频率
    # sync_relay_log_info=100
    # 设置从库位点信息存储方式，TABLE|FILE
    relay_log_info_repository=TABLE

    # 设置启用基于组提交的并行复制，DATABASE｜LOGICAL_CLOCK，
    slave-parallel-type=LOGICAL_CLOCK
    # 设置并行复制的SQL线程数
    slave-parallel-workers=8

    # 设置启用链式级联服务，既可为主库又可为从库
    # log_slave_updates=1
    # 设置从库故障排除重新启动后不自动复制
    # skip_slave_start
    # 设置错误事务的忽略
    # slave-skip-errors=all
    # 设置服务器属性为只读，即具有超级用户权限的用户可修改数据，其他用户均不能
    # read_only=1

    # 设置binlog日志事件校验，即配置事件校验，保障复制事件完整性，默认none，即不记录checksum
    binlog-checksum=CRC32
    # 设置主库写binlog事件校验，默认为0，不启用
    master-verify-checksum=1
    # 设置从库读binlog事件校验，默认为1，启用
    slave-sql-verify-checksum=1

    # 设置不参与同步的数据库，默认全部参与
    replicate_ignore_db=mysql
    replicate_ignore_db=performance_schema
    replicate_ignore_db=information_schema
    # 设置参与同步的数据库，默认全部参与 
    # replicate_do_db=test

    # data001库只同步logs表
    # replicate_do_table=data001.user
    # data001库不同步以“log”字符串结尾的表
    # replicate_wild_ignore_table=data001.%log
    # data002库之同步包含“user”字符串的表
    # replicate_wild_do_table=data002.%user%
    # data002库不同步log表
    # replicate_ignore_table=data002.log

## 3.2 配置主从复制

    mysql> change master to 
            master_host='172.16.100.200',
            master_port=3306,
            master_user='syncer',
            master_password='syncer',
            master_log_file='log-bin.000001',
            master_log_pos=120;

## 3.3 启动主从复制功能

    mysql>  start slave;

# 3.4 查看从节点复制功能状态，测试主从同步功能

    mysql> show slave status\G
    *************************** 1. row ***************************
               Slave_IO_State: Waiting for master to send event
                  Master_Host: 172.16.100.200
                  Master_User: syncer
                  Master_Port: 3306
                Connect_Retry: 60
              Master_Log_File: master-bin.000001
          Read_Master_Log_Pos: 859
               Relay_Log_File: relay-bin.000002
                Relay_Log_Pos: 321
        Relay_Master_Log_File: master-bin.000001
             Slave_IO_Running: Yes
            Slave_SQL_Running: Yes
              Replicate_Do_DB: data002
          Replicate_Ignore_DB: test
           Replicate_Do_Table: data002.test
       Replicate_Ignore_Table: test.test
       Replicate_Wild_Do_Table:
    Replicate_Wild_Ignore_Table:
                   Last_Errno: 0
                   Last_Error:
                 Skip_Counter: 0
          Exec_Master_Log_Pos: 859
              Relay_Log_Space: 522
              Until_Condition: None
               Until_Log_File:
                Until_Log_Pos: 0
           Master_SSL_Allowed: No
           Master_SSL_CA_File:
           Master_SSL_CA_Path:
              Master_SSL_Cert:
            Master_SSL_Cipher:
               Master_SSL_Key:
        Seconds_Behind_Master: 0
    Master_SSL_Verify_Server_Cert: No
                Last_IO_Errno: 0
                Last_IO_Error:
               Last_SQL_Errno: 0
               Last_SQL_Error:
    Replicate_Ignore_Server_Ids:
             Master_Server_Id: 200
                  Master_UUID: 7b1bbc09-7009-11e8-8487-000c29a5e01f
             Master_Info_File: mysql.slave_master_info
                    SQL_Delay: 0
          SQL_Remaining_Delay: NULL
      Slave_SQL_Running_State: Slave has read all relay log; waiting for more updates
           Master_Retry_Count: 86400
                  Master_Bind:
      Last_IO_Error_Timestamp:
     Last_SQL_Error_Timestamp:
               Master_SSL_Crl:
           Master_SSL_Crlpath:
           Retrieved_Gtid_Set:
            Executed_Gtid_Set:
                Auto_Position: 0
         Replicate_Rewrite_DB:
                 Channel_Name:
           Master_TLS_Version:
    1 row in set (0.00 sec)

- Slave_IO及Slave_SQL进程必须正常运行，即YES状态，否则都是错误的状态

---------

# 参考文档

- https://blog.51cto.com/amyhehe/1699168