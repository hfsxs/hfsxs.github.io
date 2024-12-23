---
title: Ansible自动化运维工具流程控制与错误处理
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2024-01-06 10:13:23
---

# 1.条件判断

when语句表示只执行满足条件的Task，其后是python表达式，支持变量与facts

    - name: 配置高可用
      apt: 
        name:
          - haproxy
          - keepalived
        state: latest
      when: ansible_hostname in groups ['master'] 

# 2.循环遍历

Ansible关键字loop和with_items用于创建循环，格式为：Playbook的task使用关键字with_items或loop设置要循环遍历的元素列表；固定变量名item的变量引用迭代项作为变量值以供调用

## 2.1 列表循环

    - hosts: hosts
      tasks:
        - name: 启动服务
          systemd:
            name: "{{ item }}"
            state: started
          with_items:
            - nginx
            - php-fpm
            - mariadb

## 2.2 变量循环

    - hosts: hosts
      vars:
        services:
          - nginx
          - php-fpm
          - mariadb
      tasks:
        - name: 启动服务
          systemd:
            name: "{{ services }}"
            state: started
        # 设置循环关键字为loop，逻辑上更为直观
        - name: 启动服务
          systemd:
            name: "{{ item }}"
            state: started
          loop: "{{ services }}"

## 2.3 字典循环

    - hosts: web_group
      tasks:
        - name: copy conf and code
          copy:
            src: "{{ item.src }}"
            dest: "{{ item.dest }}"
            mode: "{{ item.mode }}"
          with_items:
            - { src: "./httpd.conf", dest: "/etc/httpd/conf/", mode: "0644" }
            - { src: "./upload_file.php", dest: "/var/www/html/", mode: "0600" }

## 2.4 重试循环

    - action: shell /usr/bin/foo
      register: result
      until: result.stdout.find("all systems go") != -1
      # 设置重试次数，默认为3
      retries: 5
      # 设置每次重试的超时时长，默认为10s
      delay: 10

# 3.任务打标

Ansible支持给Playbook的task定义一个或多个Tag标签，执行时使用-t参数来调用标签所指定的任务，以执行其中的某些Task

## 3.1 定义标签

    - name: 配置高可用
      apt: 
        name:
          - haproxy
          - keepalived
        state: latest
      tags:
      - haproxy
      - keepalived
    - name: 启动haproxy
      service: name=haproxy state=started enabled=yes

## 3.2 调用标签

    ansible-playbook test.yml -t haproxy

# 4.错误处理

## 4.1 忽略错误

Ansible执行Playbook时会检测任务执行的返回状态，遇到错误就会终止任务的执行，后续所有的任务都将不再执行，若是执行时遇到错误仍然要求继续执行，只需调用参数ignore_errors，设为yes，即可忽略错误继续执行

    - hosts: hosts
      tasks:
        - name: 
          command: /bin/false
          ignore_errors: yes

## 4.2 强制执行Handler

force_handlers，强制执行Handler，即只有Palybook所有Task都运行正确，执行完成时才会通知执行Handlers，若执行时遇到错误就不会执行Handlers
，建议生产环境设为yes


---------

# 参考文档

- https://www.jianshu.com/p/9255d4e07e8d
- https://www.cnblogs.com/dgp-zjz/p/15683467.html
- https://blog.csdn.net/qq_37510195/article/details/130250414