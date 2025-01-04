---
title: Zabbix监控Linux系统SSH远程登录
categories:
  - 工作
tags:
  - Linux
  - Zabbix
  - SSH
  - 监控告警
  - 云计算
date: 2020-02-03 09:50:20
---

# 1.Linux模板创建系统登录监控项

- 名称：Login System
- 类型：Zabbix客户端（主动式）
- 键值：log[/var/log/secure,"(Accepted|Failed) password",,,skip,]
- 信息类型：日志
- 应用集：Security

# 2.创建系统登录触发器

## 2.1 创建系统登录成功触发器

- 名称：Login system has succeed
- 表达式：{Template OS Linux:log[/var/log/secure,"(Accepted|Failed) password",,,skip,].str(Accepted)}=1 
and {Template OS Linux:log[/var/log/secure,"(Accepted|Failed) password",,,skip,].nodata(60)}=0
- 严重性：信息

and之前，表示如果字符串中包含"Accepted"则表达式为真；and之后，表示60秒内有数据产生则表达式为真，即60秒内如果没有新数据了，则表达式为假。and之前匹配登录成功的信息，and之后保证触发器的恢复。即前者保证触发器的触发，后者保证触发器的恢复

## 2.2 创建系统登录失败触发器

- 名称：Login system has failed
- 表达式：{Template OS Linux:log[/var/log/secure,"(Accepted|Failed) password",,,skip,].str(Failed)}=1
and {Template OS Linux:log[/var/log/secure,"(Accepted|Failed) password",,,skip,].nodata(60)}=0
- 严重性：一般严重

and之前，表示如果字符串中包含"Failed"则表达式为真；and之后，表示60秒内有数据产生则表达式为真，即60秒内如果没有新数据了，则表达式为假。and之前匹配登录失败的信息，and之后保证触发器的恢复。前者保证触发器的触发，后者保证触发器的恢复

# 3.配置Linux系统登录日志文件权限

    sudo chmod 755 /var/log/secure

---------

# 参考文档

- https://blog.csdn.net/weixin_58400622/article/details/127792543