---
title: Ansible自动化运维工具的安装与配置
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2020-02-07 09:30:39
---

Ansible，由Python开发的开源的自动化运维配置管理工具，用于实现批量系统配置、批量程序部署、批量运行命令等自动化任务功能。Ansible基于ssh进行主机通信，远程主机无需安装客户端或代理，其本身并没有批量部署的能力，而是依赖所运行的各种模块

# 特点优势

- 部署简单，只需在控制设备上部署Ansible环境，而不需要在被控制设备上进行任何操作，主从集中化管理
- 使用安全协议SSH对设备进行管理
- 配置简单、功能强大、可扩展性强
- 支持API及自定义模块，可通过Python轻松扩展
- 通过playbooks定制强大的配置、状态管理
- 对云计算平台、大数据都有很好的支持

# 系统架构

Ansible主要由5部分组成

## Ansible

Ansible核心，主要用于处理请求

## Modules

Ansible模块，由Ansible自带的核心模块和自定义模块两部分组成

## 3.Plugins

Ansible模块功能的补充，如链接插件、邮件插件等等

## Playbooks

Ansible剧本，定义Ansible多任务配置文件，由Ansible自动执行

## Inventory

Ansible被控主机清单

# 集群架构

- master 172.16.100.100
- node01 172.16.100.120
- node02 172.16.100.200

---------

# 1.安装依赖包

    sudo yum -y install gcc gcc-c++ make cmake automake autoconf openssl openssl-devel zlib zlib-devel pcre pcre-devel libffi-devel unzip 

# 2.配置集群主机ssh免密钥登陆

# 3.安装python

    # yum install -y python
    tar -xzvf Python-2.7.8.tgz && cd Python-2.7.8
    sudo ./configure --prefix=/usr/local && make install

    sudo cp /usr/local/include/python2.7/* /usr/local/include -r
    sudo mv /usr/bin/python /usr/bin/python_bak
    sudo ln -s /usr/bin/python2.7 /usr/bin/python

# 4.安装Python模块

## 4.1 安装setuptools模块

    unzip setuptools-40.1.0.zip && cd setuptools-40.1.0
    sudo python setup.py install

## 4.2 安装pycrypto模块

    tar -xzvf pycrypto-2.6.1.tar.gz && cd pycrypto-2.6.1
    sudo python setup.py install

## 4.3 安装PyYAML模块

    tar -xzvf PyYAML-3.11.tar.gz && cd PyYAML-3.11
    sudo python setup.py install

## 4.4 安装Jinja2模块

    tar -xzvf MarkupSafe-0.9.3.tar.gz & cd MarkupSafe-0.9.3
    sudo python setup.py install

    tar -xzvf Jinja2-2.7.3.tar.gz && cd Jinja2-2.7.3
    sudo python setup.py install

## 4.5 安装cryptography模块

    tar -xzvf pycparser-2.20.tar.gz && cd pycparser-2.20
    sudo python setup.py install

    tar -xzvf cffi-1.12.3.tar.gz && cd cffi-1.12.3
    sudo python setup.py install

    tar -xzvf ipaddress-1.0.23.tar.gz && cd ipaddress-1.0.23
    sudo python setup.py install

    tar -xzvf enum34-1.1.10.tar.gz && cd enum34-1.1.10
    sudo python setup.py install

    tar -xzvf six-1.14.0.tar.gz && cd six-1.14.0
    sudo python setup.py install

    tar -xzvf cryptography-2.8.tar.gz && cd cryptography-2.8
    sudo python setup.py install

## 4.6 安装simplejson模块

    tar -xzvf simplejson-3.6.5.tar.gz && cd simplejson-3.6.5
    sudo python setup.py install

# 5.安装ansible

    tar -xzvf ansible-2.7.9.tar.gz && cd ansible-2.7.9
    sudo python setup.py install

    sudo mkdir /etc/ansible && sudo cp examples/ansible.cfg /etc/ansible

# 6.配置ansible主机组

    sudo vi /etc/ansible/hosts


    [master]
    master

    [worker]
    worker0[1:3]

    # 设置主机组cluster，master和worker这两个主机组都属于其内置组
    [cluster:children]
    master
    worker

    [data]
    data01    

# 7.ansible批量执行命令

    ansible cluster -m shell -a 'uptime'