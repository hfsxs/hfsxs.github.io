---
title: Linux系统配置Cron定时任务
categories:
  - 工作
tags:
  - Linux
  - Cron
  - 定时任务
  - 云计算
date: 2020-04-06 10:54:43
---

Cron，Linux系统周期性执行程序的任务调度工具，守护进程为crond，默认安装且开机自启，管理命令为crontab。crond服务定期检查系统中是否有要执行的任务工作，默认每分钟检查一次，若检查到定时任务便会根据预先设定的规则自动执行该任务，类似于闹钟，从而实现计划任务的自动化执行，如日志轮询、数据备份、缓存清理、时钟同步及监控告警等

# 1.配置文件

- /etc/crontab，系统级任务调度列表，该文件所定义的调度任务都以用户名为文件名存储于/var/spool/cron/
- /etc/cron.d/，用于存储要执行的crontab文件或脚本的目录，便于以文件粒度对不同用户不同类别的任务进行管理，且所定义的任务调度文件需遵循Cron的命名规范才能被扫描到。系统预设四个目录但并未完全启用，即/etc/cron.hourly、/etc/cron.daily、/etc/cron.weekly、/etc/cron.monthly，用于定义每小时/天/周/月要执行的任务
- /etc/cron.allow、etc/cron.deny，默认情况下只有root用户可创建定时任务，建议两个文件保留一个，即白名单与黑名单，用于指定允许进行定时任务的普通用户

# 2.任务格式

    cat /etc/crontab


    # 设置命令解释器
    SHELL=/bin/bash
    # 设置环境变量，即定时任务所调用命令的目录，建议使用命令或脚本的绝对路径，避免环境变量引发的异常问题
    PATH=/sbin:/bin:/usr/sbin:/usr/bin
    # 设置任务调用输出信息的电子邮件接收用户
    MAILTO=root
 
    # For details see man 4 crontabs
 
    # Example of job definition:
    # .---------------- minute (0 - 59)
    # |  .------------- hour (0 - 23)
    # |  |  .---------- day of month (1 - 31)
    # |  |  |  .------- month (1 - 12) OR jan,feb,mar,apr ...
    # |  |  |  |  .---- day of week (0 - 6) (Sunday=0 or 7) OR sun,mon,tue,wed,thu,fri,sat
    # |  |  |  |  |
    # *  *  *  *  * user-name  command
    # 分 时 日  月 周 执行用户    要执行的程序或命令

## 2.1 基本格式

crontab文件包含多个任务，每个任务都被描述为一行，且遵循特定的时间格式，具体如下：

    *    *    *    *    *    user    command
    分钟 小时 日期  月份  星期   用户  要执行的程序或命令

- 前5个配置项用于表示任务执行的时间
- user，用于指定执行任务的用户
- command，要执行的程序或命令，需保证有执行权限

## 2.2 时间格式

Cron的任务由时间+动作构成，时间分为分、时、日、月、周五种，操作符如下：

- *，表示每，即取值范围内的所有数字都要执行调度，如30表示每小时的30分
- /，表示每过多少个数字，用于指定时间间隔与频率，如*/5表示每5分钟，
- -，表示时间区间，如10-15表示每小时的10-15分钟，0-29/2表示每个小时前半个小时每2分钟
- ,，表示散列数字，即不同时间区间的间隔，如7-11,13-15表示每天7-11点和13-15点

## 2.3 命令格式

- 单条命令，如* * * * * echo -e $(date '+\%Y\%m\%d') >> /root/tmp.log
- 脚本绝对路径，如* * * * * /root/scripts/test.sh
- 多条命令，以;分隔，如* * * * * . /etc/profile;/bin/sh /root/scripts/test.sh

# 3.执行日志

- /var/log/cron，定时任务日志
- /var/spool/mail/root，root用户邮件信息，每次任务都将写入，由此将产生大量的临时小文件，建议将定时任务的结果重定向为NULL或文件，且避免不必要的命令输出，以免小文件过多导致inode不足，影响磁盘写入

# 4.任务配置

Cron定时任务有两种配置方式，即系统定时任务配置文件crontab和crontab命令配置，两种方式并行，建议统一选择一种方式

## 4.1 查看任务列表

    # 查看当前用户的定时任务列表
    crontab -l
    # 查看root的定时任务列表
    sudo crontab -l

## 4.2 新增定时任务

    crontab -e


    # 测试定时任务，建议每条任务都做好注释
    10 * * * * echo 'cron test' > /home/sword/cron.log

## 4.3 验证任务列表

    crontab -l
    # 测试定时任务，建议每条任务都做好注释
    10 * * * * echo 'cron test' > /home/sword/cron.log

    sudo cat /var/spool/cron/sword
    # 测试定时任务，建议每条任务都做好注释
    10 * * * * echo 'cron test' > /home/sword/cron.log

## 4.4 删除定时任务

    crontab -r

- 注：该命令将会清空用户下所有定时任务，且不可恢复

## 4.5 备份定时任务

由于crontab -r命令将直接清空任务列表，所以不建议使用crontab -e直接编辑，而是将任务列表写入备份文件，再通过crontab file命令更新任务表，以防误操作而无法恢复

### 4.5.1 创建任务表文件

    vi cron_task.bak


    # 测试定时任务，建议每条任务都做好注释
    10 * * * * echo 'cron test' > /home/sword/cron.log
    # 测试定时任务备份，建议每条任务都做好注释
    45 * * * * echo 'cron bak' > /home/sword/cron.bak

### 4.5.2 创建定时任务表

    crontab cron_task.bak

### 4.5.3 验证定时任务

    sudo cat /var/spool/cron/sword

# 5.配置案例

---------

# 参考文档

- https://juejin.cn/post/7065972818965430286
- https://www.runoob.com/w3cnote/linux-crontab-tasks.html
- https://blog.csdn.net/qq_37510195/article/details/129530014