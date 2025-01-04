---
title: MySQL数据库服务器的安装与配置
categories:
  - 工作
tags:
  - Linux
  - MySQL
  - SQL
  - 数据库
  - 云计算
date: 2020-02-02 15:13:16
---

MySQL，是由瑞典MySQL AB公司开发的开源的关系型数据库管理系统，目前已被Oracle收购，全球范围内被广泛应用，其使用的SQL语言是用于访问数据库的最常用的标准化语言。MySQL分为社区版和商业版，由于其体积小、速度快、总体拥有成本低，尤其是开放源码这一特点，一般中小型和大型网站的开发都选择MySQL作为网站数据库。

# 发展历史

- 1979年，MySQL创始人Michael Widenius在开发一个报表工具时设计了一套API，并将mSQL代码集成到存储引擎以支持SQL语句
- 1996年，MySQL 1.0发布，Michael Widenius女儿的简称即为MY。当年10月，MySQL 3.11.1发布了Solaris版本。11月，发布linux版本。此后，MySQL逐渐进入大众视野
- 1999年，Michael Widenius创立MySQL AB公司，MySQL由个人开发转变为团队开发，社区版个人免费使用，商业版付费使用
- 2000年，MySQL遵守GPL协议，将之开源，此举使得MySQL AB收入遭受巨大打击，损失了将近80%的收入，但依然被坚持了下来
- 2001年，存储引擎InnoDB诞生，逐渐成为MySQL首选的存储引擎，MySQL用户基数已达到三分之一市场份额的规模
- 2005年，Oracle收购InnoDB，InnoDB只能作为第三方插件以供使用
- 2008年1月，MySQL AB公司被Sun公司以10亿美金收购，MySQL数据库进入Sun时代。当年11月，MySQL 5.1发布，MySQL成为了最受欢迎的小型数据库。随后，Widenius离开了Sun
- 2009年4月，Oracle公司以74亿美元收购Sun公司，MySQL也随之进入Oracle时代

---------

Oracle公司收购Sun公司的举动大大激怒了Monty Widenius，并极力反对，认为一家独大的Oracle将引起数据库市场的不良竞争，从而导致更高的价格。因此，他发起了著名的“Save MySQL”抗议活动，甚至还差点搅黄了Oracle收购Sun的交易。Oracle也不得不对MySQL许下若干承诺，才使得欧盟最终为收购案亮了绿灯。然而，Oracle的所作所为依然令他大为失望，虽然宣称MySQL依然遵守GPL协议，但却暗地里把开发人员全部换成内部人员，开源社区再也影响不了MySQL发展的脚步，而真正有心做贡献的人也被拒之门外，MySQL随时面临闭源的可能

有鉴于此，Monty Widenius当即以另外一个女儿Maria命名，创立了MariaDB。MariaDB是一个非商业化的永久免费的产品，用户如果愿意可以为它捐款，目前由MariaDB基金会来管理，发起者正是MySQL AB的三大创始人Monty Widenius、David Axmark和Allan Larsson。MariaDB完全兼容MySQL，包括API和命令行，此外扩展功能、存储引擎以及一些新的改进功能全面超越了MySQL，能够轻松成为MySQL的替代品。业界许多主流厂商也转而拥抱MariaDB，如Google、RedHat、SUSE、维基百科等，其光明的前景已是可以预见的一览无余

---------

# 体系架构

MySQL的逻辑架构分为四层，即连接层、SQL层、存储引擎层

## 1.连接层

由Connection pool组件构成，即连接池组件，主要负责连接处理、用户鉴权、安全管理等工作

### 1.1 连接处理

客户端应用程序通过接口，如ODBC、JDBC等，向MySQL发送连接请求，MySQL将按照客户端连接通信协议接收请求建立TCP连接，并从线程池中分配线程来和客户端进行连接，同时将该连接的用户名、密码、权限校验、线程处理等信息缓存到连接池，该客户端的请求都会被分配到该线程负责的连接通道，即连接复用功能。从而减少了创建线程和释放线程所花费的时间，大大提升了服务器性能

### 1.2 用户鉴权

主要负责客户端连接用户的认证鉴权工作，如用户名、客户端主机地址和用户密码

### 1.3 安全管理

依据客户端连接用户的权限来判断用户具体可执行哪些操作

## 2.SQL层

MySQL核心服务，实现了数据库管理系统的所有逻辑功能，由以下组件构成

### 2.1 MySQL Management Server & utilities

管理服务器与公用事业组件，具体功能如下：

- 数据库备份与还原
- 数据库安全管理，如用户及权限管理
- 数据库复制管理
- 数据库集群管理
- 数据库分区、分库、分表管理
- 数据库元数据管理

### 2.2 SQL Interface

SQL接口组件，用于接收SQL命令及返回查询结果，具体功能如下：

- Data Manipulation Language (DML)
- Data Definition Language (DDL)
- 存储过程
- 视图
- 触发器

### 2.3 SQL Parser

SQL解析器组件，用于解析查询语句并最终生成语法树，同时识别SQL语句语法错误，并返回相应的错误信息。若语法检查通过，解析器则优先查询缓存，缓存命中则直接返回结果，不用继续解析与执行

### 2.4 Optimizer

查询优化器组件，用于查询语句的优化，包括选择合适索引、数据读取方式等，查询策略为选取-投影-连接

### 2.5 Caches & buffers

缓存组件，由一系列小缓存组成，如表缓存、记录缓存、key缓存、权限缓存等，提高查询的效率

## 3.存储引擎层

### 3.1 存储引擎

存储引擎，即MySQL底层数据文件的组织、处理与存储机制，也就是数据的创建、查询、更新、存储方式，负责数据的存储和提取。存储引擎屏蔽了底层存储的细节，通过插件化的方式配置，可根据具体场景选择不同的存储引擎

## 3.1.1 InnoDB

MySQL数据库的首先存储引擎，如无其他特殊需求建议选择，也是MySQL 5.5及之后的版本默认的存储引擎，之前默认为MyISAM

### 3.2 文件系统

---------

# 1. 安装依赖包

    yum install -y bison gdb perl ncurses-devel libaio numactl
    apt install -y libaio1 libaio-dev libncurses5

# 2. 创建mysql用户

    groupadd mysql && useradd -g mysql -s /sbin/nologin mysql -M

# 3.安装mysql

    tar -zxvf mysql-5.7.22-linux-glibc2.12-x86_64.tar.gz
    mv mysql-5.7.22-linux-glibc2.12-x86_64 /usr/local/mysql

# 4.初始化数据库

    # mysql 5.6和mariadb初始化数据库
    # /usr/local/mysql/scripts/mysql_install_db --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql

    # mysql 5.7.6之后初始化数据库
    /usr/local/mysql/bin/mysqld --initialize-insecure --basedir=/usr/local/mysql --datadir=/usr/local/mysql/data --user=mysql

# 5.创建配置文件

    vi  /etc/my.cnf


    [client]
    port=3306
    socket=/var/lib/mysql/mysql.sock

    [mysqld]
    port=3306
    basedir=/usr/local/mysql
    datadir=/usr/local/mysql/data
    socket=/var/lib/mysql/mysql.sock
    pid-file=/var/lib/mysql/mysql.pid
    log-error =/usr/local/mysql/data/mysql-server.log
    # mariadb无需配置
    log_timestamps=system

    default-storage-engine=InnoDB
    innodb_file_per_table=1
    symbolic-links=0
    skip-external-locking
    wait_timeout=600
    interactive_timeout=600

# 6. 配置环境变量

    # echo 'PATH=/usr/local/mysql/bin/:$PATH' >>/etc/profile && source /etc/profile
    ln -s /usr/local/mysql/bin/mysql /usr/bin

# 7.配置mysql动态库

    echo "/usr/local/mysql/lib" >>/etc/ld.so.conf.d/mysql.conf
    ldconfig

# 8.配置mysql启动服务

    mkdir -p /var/lib/mysql
    cp /usr/local/mysql/support-files/mysql.server /etc/init.d/mysqld
    chown -R mysql.mysql /usr/local/mysql /var/lib/mysql
    chmod +x /etc/init.d/mysqld

    # 启动mysql数据库服务器
    /etc/init.d/mysqld start
    chkconfig mysqld on

# 9.设置mysql数据库root密码

    /usr/local/mysql/bin/mysqladmin -u root password '123456'