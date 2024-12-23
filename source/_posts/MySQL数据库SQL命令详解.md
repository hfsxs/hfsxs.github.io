---
title: MySQL数据库SQL命令详解
categories:
  - 工作
tags:
  - Linux
  - MySQL
  - SQL
  - 数据库
  - 云计算
date: 2020-02-02 15:22:29
---

# 1.设置root账户密码

    /usr/local/mysql/bin/mysqladmin -u root password '123456'

# 2.登陆数据库

    # 格式为：mysql -h 主机地址 -P 端口号 -u 用户名 -p用户密码
    mysql -u root -p 123456
    mysql -h127.0.0.1 -P3301 -uroot -p123456

# 3.查看所有数据库

    MariaDB [(none)]>  show databases;

# 4.创建数据库

    MariaDB [(none)]>  create database testdb character set utf8mb4 collate utf8mb4_unicode_ci;

# 5.切换数据库

    MariaDB [(none)]>  use mysql;

# 6.创建数据库用户并授予权限

    # 格式为：grant 权限 on 数据库.* to 用户名@登录主机 identified by "密码";
    MariaDB [(none)]>  GRANT ALL PRIVILEGES ON user01.* TO 'testdb'@'172.16.100.200' IDENTIFIED BY 'sword';
    MariaDB [(none)]>  grant SELECT privileges on user01.* to 'testdb'@'172.16.100.200' identified by '123456';

---------

权限可取值：

- ALTER，修改表和索引
- CREATE，创建数据库和表
- DELETE，删除表中已有的记录
- DROP，删除数据库和表
- INDEX，创建或删除索引
- INSERT，向表中插入新行
- SELECT，检索表中的记录
- UPDATE，修改现存表记录
- FILE，读或写服务器上的文件
- PROCESS，查看服务器中执行的线程信息或杀死线程
- RELOAD，重载授权表或清空日志、主机缓存或表缓存
- SHUTDOWN，关闭服务器
- ALL，所有权限，同义词ALL PRIVILEGES

---------

# 7.刷新权限表

    MariaDB [(none)]>  flush privileges;

# 8.创建数据表

    MariaDB [(none)]>  use testdb;
    # MariaDB [(none)]>  select DATE_FORMAT(current_timestamp(3),'%Y%m%d%H%i%s%f');
    MariaDB [(none)]>  create table test (id varchar(50) not null primary key,name varchar(50),create_time timestamp(3));

# 9.显示当前数据库所有数据表

    MariaDB [(none)]>  show tables;

# 10.显示表结构

    MariaDB [(none)]>  desc test;

# 11.数据表插入数据

    MariaDB [(none)]>  insert into test values ('001','test001');

# 12.修改账户密码

    MariaDB [(none)]>  use mysql;
    MariaDB [(none)]>  update mysql.user set password=password('111111') where User="root" and Host="localhost";
    # MariaDB [(none)]>  update user set password=password("111111") where user="root" flush privileges;
    # MariaDB [(none)]>  alter  user 'root'@'localhost' identified by '111111';

# 13.数据库热备份

    /usr/local/mysql/bin/mysqldump -uroot -p111111 testdb >/opt/buckups/data/testdb $(date +%Y%m%d_%H%M%S).sql
    /usr/local/mysql/bin/mysqldump -uroot -p111111--events --all-databases | gzip > /opt/buckups/data/mysql.$(date +%Y%m%d).sql
    /usr/local/mysql/bin/mysqldump --host=127.0.0.1 --port=3306 --user=root -p111111 --all-databases --events --routines --compress --log-error=/tmp/mysqldump_error.log >  /opt/buckups/data/mysql.sql

# 14.数据库导入

    /usr/local/mysql/bin/mysql -uroot -p111111 testdb < /opt/buckups/data/mysql.sql

# 15.查询数据库中数据量最大的前10个表

     MariaDB [(none)]>  use information_schema;
     MariaDB [(none)]>  select table_name,table_rows from  tables order by table_rows desc limit 10;

# 16.批量插入10000条数据脚本

    #!/bin/bash


    i=1;
    while [ $i -le 10000 ]
      do
    mysql -usword -p111111 testdb -e "insert into test (id,name) values (DATE_FORMAT(current_timestamp(3),'%Y%m%d%H%i%s%f'),substring(MD5(RAND()),1,20));"
      let    i=i+1
      sleep 0.01
    done
    exit 0