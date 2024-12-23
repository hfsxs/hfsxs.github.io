---
title: Ansible自动化运维工具Playbook
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2022-10-12 12:24:45
---

Playbook，剧本，Ansible用于配置、部署及管理被控节点的任务编排脚本，描述了一系列tasks的执行，类似于shell脚本执行批量任务，由用于编写配置文件的YAML语言编写

---------

# 1.语法格式

- 文件第一行以“—--”开始，表明YAML文件的开始

- #表示注释，类似于Shell、python和Ruby

- YAML文件的列表元素以“-”开头且跟着一个空格，其后为元素内容

- 同一个列表之中的元素应保持相同缩进，否则将被当做错误处理

- playbook中hosts、variables、roles、tasks等对象的表示方法是以键值中间“:”为分隔表示，且“:”之后要有一个空格

# 2.核心元素

- Hosts，远程主机组
- Variables，变量，可传递给Tasks、Templates
- Tasks，任务集，由模块调用所定义的操作任务的列表，以“-”开头
- Templates，模版，包含了模块语法的文本文件  
- Handlers，处理器，由特定条件触发的任务集，即某个Task成功执行状态为changed时，触发执行由Notify所指定的Handler，通常用于配置文件创建或更改时service的重启

# 3.基础组件

    ---
    # 设置playbook或task的名称
    name: test
    # 设置所要运行任务的目标主机
    hosts：nodes
    # 设置远程主机执行任务的用户，默认为root
    remoute_user: user001 
    # 设置sudo用户
    sudo_user: user001
    # 设置任务列表
    tasks:
      # 设置任务名称 
      - name: task01
        # 设置执行任务模块 
        module: arguments
        # 设置该任务执行成功所触发的处理器
        notify: handlers001 
      - name: task02
        module: arguments
        # 设置模版文件
        template：
        # 设置条件判断，即满足条件才能执行任务 
        when: Expression

      # 设置处理器
      handlers: 
          # 设置处理器名称
          - name: handlers001
            # 设置执行任务模块 
            module: arguments

# 4.创建Playbook

    vi nginx.yaml


    ---
    - name: Nginx安装部署
      hosts: nodes
      remote_user: sword
      become: yes
      become_user: root
      tasks:
        - name: 安装Nginx
          apt:
            name:  
              - curl
              - wget
              - nginx
            state: latest
        - name: 启动nginx
          service: name=nginx state=started

# 5.语法检查

    # 语法错误检查
    ansible-playbook --syntax-check nginx.yaml
    # 模拟执行，并不会在主机上真正执行任务
    ansible-playbook -C

# 6.执行Playbook

    ansible-playbook nginx.yaml

# 7.验证执行结果

    ansible nodes -m shell -a 'ps -ef|grep nginx|grep -v nginx'

# 8.实战：kubernetes高可用集群部署

    vi kubernetes.yaml


    ---
    - name: kubernetes高可用集群部署
      hosts: k8s
      remote_user: sword
      become: yes
      become_user: root
      tasks:
        - name: 安装依赖包
          apt:
            name:  
              - curl
              - gnupg2
              - ca-certificates
              - apt-transport-https
            state: latest
        - name: 导入阿里云apt源密钥
          shell: curl https://mirrors.aliyun.com/kubernetes/apt/doc/apt-key.gpg | apt-key add -
        - name: 禁用swap
          shell: sed -ri 's/.*swap.*/#&/' /etc/fstab && swapoff -a
        - name: 开启路由转发
          copy: src=k8s.conf dest=/etc/sysctl.d
        - name: 生效配置文件
          shell: sysctl -p
        - name: 解压docker安装包
          unarchive: src=/home/works/Linux/software/docker-19.03.12.tgz dest=/home/sword
        - name: 安装docker
          shell: mv docker/* /usr/bin && mkdir -p /etc/docker && mkdir -p /root/.docker
        - name: 配置docker仓库加速器
          copy: src=docker/daemon.json dest=/etc/docker
        - name: 配置docker仓库认证文件
          copy: src=docker/config.json dest=/root/.docker   
        - name: 创建创建docker服务启动脚本
          copy: src=docker/docker.service dest=/lib/systemd/system
        - name: 启动docker
          service: name=docker state=started enabled=yes
        - name: 配置kubernetes阿里云apt源
          copy: src=kubernetes.list dest=/etc/apt/sources.list.d
        - name: 安装kubeadm、kubelet、kubectl
          shell: apt update && apt install -y kubelet=1.20.12-00 kubeadm=1.20.12-00 && systemctl enable kubelet
        - name: master节点安装haroxy、keepalived
          apt: 
            name:
              - haproxy
              - keepalived
            state: latest
          when: ansible_hostname in groups ['master'] 
        - name: master节点创建haproxy配置文件
          copy: src=haproxy.cfg dest=/etc/haproxy
          when: ansible_hostname in groups ['master'] 
        - name: master节点启动haproxy
          service: name=haproxy state=started enabled=yes
          when: ansible_hostname in groups ['master']
        - name: master节点创建keepalived配置文件
          copy: src=keepalived.conf dest=/etc/keepalived
          when: ansible_hostname in groups ['master']
        - name: master节点创建haproxy服务状态监控脚本
          copy: src=haproxy_check.sh dest=/etc/keepalived
          when: ansible_hostname in groups ['master']
        - name: master02节点修改keepalived配置文件
          shell: sed -i 's/master01/master02/g' /etc/keepalived/keepalived.conf && sed -i 's/priority 100/priority 80/g' /etc/keepalived/keepalived.conf
          when: ansible_hostname=="master02"
        - name: master03节点修改keepalived配置文件
          shell: sed -i 's/master01/master03/g' /etc/keepalived/keepalived.conf && sed -i 's/priority 100/priority 60/g' /etc/keepalived/keepalived.conf
          when: ansible_hostname=="master03"
        - name: master节点启动keepalived
          service: name=keepalived state=started enabled=yes

---------

# 参考文档

- https://zhuanlan.zhihu.com/p/149499486
- https://blog.csdn.net/qq_42761527/article/details/105984961
- https://blog.csdn.net/weixin_34162695/article/details/89784000