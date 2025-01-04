---
title: Zabbix配置邮件告警
categories:
  - 工作
tags:
  - Linux
  - Zabbix
  - 监控告警
  - 云计算
date: 2020-02-03 09:59:38
---

# 1.zabbix服务器安装邮件发送程序mailx

    sudo yum install -y mailx dos2unix

# 2.修改mailx配置文件

    sudo vi /etc/mail.rc


    # for zabbix
    set from=sxs0618@139.com
    smtp=smtp.139.com
    set smtp-auth-user=sxs0618@139.com
    smtp-auth-password=123456
    set smtp-auth=login

# 3.创建邮箱发送脚本文件

    sudo vi /usr/local/zabbix/share/zabbix/alertscripts/sendmail.sh


    #!/bin/bash


    messages=`echo $3 | tr '\r\n' '\n'`
    subject=`echo $2 | tr '\r\n' '\n'`
    echo "${messages}" | mail -s "${subject}" $1 >>/tmp/sendmail.log 2>&1

    sudo chown zabbix.zabbix /usr/local/zabbix/share/zabbix/alertscripts/sendmail.sh
    sudo chmod +x /usr/local/zabbix/share/zabbix/alertscripts/sendmail.sh

# 4.zabbix前端页面创建媒体类型

## 管理 -> 报警媒介类型 -> 创建媒体类型

- 名称：sendmail

- 类型：脚本

- 脚本参数：

{ALERT.SENDTO}
{ALERT.SUBJECT}
{ALERT.MESSAGE}

# 5.添加邮箱收件人

## Admin -> 报警媒介 -> 添加 

- 类型：sendmail
- 收件人：sxs3013@outlook.com

# 6.添加邮件发送动作

## 配置 -> 动作 -> 创建动作 -> 操作

    默认接收人：{TRIGGER.SEVERITY}:{TRIGGER.NAME}

    默认信息：

    告警IP:{HOST.CONN}

    告警主机:{HOSTNAME1}

    告警时间:{EVENT.DATE} {EVENT.TIME}

    告警等级:{TRIGGER.SEVERITY}

    告警信息: {TRIGGER.NAME}

    告警项目:{TRIGGER.KEY1}

    问题详情:{ITEM.NAME}:{ITEM.VALUE}

    当前状态:{TRIGGER.STATUS}:{ITEM.VALUE1}

    事件ID:{EVENT.ID}


## 操作

- 步骤					1-1
- 发送到用户群组		添加-> Zabbix administrators
- 发送到用户	     添加-> Admin
- 仅送到		    sendmail

---------

# 参考文档

- http://www.cnblogs.com/rysinal/p/5834421.html
- http://blog.csdn.net/slovyz/article/details/53100780
- http://www.tuicool.com/articles/7jqm2aE