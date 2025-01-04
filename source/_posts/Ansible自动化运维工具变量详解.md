---
title: Ansible自动化运维工具变量详解
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2023-12-28 09:36:59
---

Variables，即变量，用于管理Playbook中Tasks、Templates的动态值或多次引用值，如要创建的用户、安装的软件包、重启的服务、删除的文件以及要下载的文档等等，都可以通过定义的变量来继承，极大地简化项目的创建与维护

# 1.命令行定义变量

Ansible执行Playbook时可直接定义变量，并直接将变量值传入Playbook以供调用，适用于变量较少的场景

## 1.1 创建Playbook

    vi test.yaml


    ---
    - hosts: cluster
      tasks:
      - name: 安装Docker
        # 调用yum模块，service为变量
        yum: name={{ service }} state=installed
      - name: 启动Docker
        service: name={{ service }} state=started

## 1.2 执行Playbook

    # 执行剧本，并定义变量service，其值为nginx
    ansible-playbook test.yml -e "service = docker"

# 2.主机清单定义变量

Ansible主机清单文件支持变量的定义，inventory变量，用于定义主机或主机组的变量

## 2.1 定义主机清单变量

    sudo vi /etc/ansible/hosts


    [master]
    # 定义主机master的变量data，其值为etcd
    master data = etcd

    [worker]
    worker0[1:3]

    # 定义主机组变量，:vars为固定格式
    [worker:vars]
    # 定义主机组worker的变量port，其值为8443
    port = 8443

    # 设置主机组cluster，master和worker这两个主机组都属于其内置组
    [cluster:children]
    master
    worker

## 2.2 创建Playbook

    vi test.yaml


    ---
    - hosts: master
      tasks:
      - name: 安装etcd
        # 调用yum模块，data为变量
        yum: name={{ data }} state=installed
      - name: 启动etcd
        service: name={{ data }} state=started 

# 3.Playbook定义变量

Ansible最常用的变量声明方式之一是通过Playbook定义变量，并可直接进行调用

    vi test.yaml


    ---
    - hosts: 
      # 定义全局变量，所有模块均可引用 
      vars:
        packages：
          - docker
          - ipvsadm
      tasks:
      - name: 
        # 定义任务变量，仅限当前任务引用
        vars： 
          port:
            - 80
            - 443
            - 8443
        # 调用全局变量packages
        yum: name={{ packages }} state=installed

# 4.变量文件定义变量

Ansible支持将变量存储为单独的变量文件，可供所有的Playbook调用，推荐使用

## 4.1 变量文件

    mkdir -p /etc/ansible/vars

### 4.1.1 创建变量文件

    vi /etc/ansible/vars/vars.yml


    packages：
      - ipvsadm
      - docker

### 4.1.2 创建Playbook

    vi test.yaml


    ---
    - hosts: master
      # 定义变量文件所定义的变量 
      vars_files: /etc/ansible/vars/vars.yml
      tasks:
      - name: 安装依赖包
        # 调用全局变量packages
        yum: name={{ packages }} state=installed

## 4.2 主机组变量文件

    mkdir -p /etc/ansible/grous_vars

### 4.2.1 创建所有主机组变量文件

    vi /etc/ansible/grous_vars/all.yml


    

# 5.内置变量

facts是ansible自带的预定义变量，用于描述被控端软硬件信息，通过setup模块获得




# 参考文档

---------

- https://www.cnblogs.com/wuqiuyin/p/15214880.html
- https://blog.csdn.net/weixin_40228200/article/details/123504990