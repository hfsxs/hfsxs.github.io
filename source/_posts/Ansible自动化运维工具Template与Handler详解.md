---
title: Ansible自动化运维工具Template与Handler详解
categories:
  - 工作
tags:
  - Linux
  - Ansible
  - 自动化运维
  - 云计算
date: 2024-01-09 09:06:54
---

Template，即模版，Playbook生成目标文件的模版，即由jinjia2语言编写的后缀名为.j2的模板文件可调用变量替换其中的内容动态生成被控主机的配置文件，配合Handler处理器触发服务重启，从而生效配置

# 1.创建模版文件

    # 模版文件存储目录为templates，与Playbook文件平级
    mkdir -p test/templates
    vi test/templates/keepalived.conf.j2


    global_defs {
      notification_email
      {
        admin@sword.com
      }
      notification_email_from
      smtp_server 127.0.0.1
      smtp_connect_timeout 30
      router_id {{ ansible_hostname }}
    }

    vrrp_script check_haproxy {
      script "/etc/keepalived/haproxy_check.sh"
      interval 2
      weight -10
    }

    vrrp_instance Haproxy {
      state {{  }}
      interface eth0
      virtual_router_id 51
      priority {{  }}
      advert_int 1
      authentication {
        auth_type PASS
        auth_pass 123456
      }
      virtual_ipaddress {
        172.16.100.150/24
      }
      track_script {
        check_haproxy
      }
    }

# 2.定义变量

    vi test/group_vars/master.yml


    master01: 100
    master02: 80
    master03: 60

# 3.生成keepalived配置文件

    - name: Keepalived安装
      hosts: master
      remote_user: sword
      become: yes
      become_user: root
      tasks:
        - name: 安装keepalived
          apt: 
            name:
              - keepalived
            state: latest
        - name: 创建Keepalived配置文件
          template: src=keepalived.conf.j2 dest=/etc/keepalived/keepalived.conf

# 4.配置Handler

     - name: Keepalived安装
      hosts: master
      remote_user: sword
      become: yes
      become_user: root
      tasks:
        - name: 安装keepalived
          apt: 
            name:
              - keepalived
            state: latest
        - name: 创建Keepalived配置文件
          template: src=keepalived.conf.j2 dest=/etc/keepalived/keepalived.conf
          notify: 重启keepalived

      handlers:
      - name: 重启keepalived
        service: name=keepalived state=restarted

# 5.循环调用变量

    {% for vhost in nginx_vhosts %}
    server{
        listen {{ vhost.port }};
        server_name {{ vhost.server_name }};
        root {{ vhost.root }};
    }
    {% endfor %}

    
# 6.实战项目：Kubernetes集群巡检

    - name: Kubernetes集群巡检
      hosts: k8s
      tasks:
        - name: 磁盘空间巡检
          shell: df -h
          register: disk_usage
        - name: 检查处理器使用率
          shell: top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4}'
          register: cpu_usage
        - name: 内存占用巡检
          shell: free | grep Mem | awk '{print $3/$2 * 100.0}'
          register: memory_usage
        - name: 运行进程巡检
          shell: ps -ef | grep "{{ process_name }}" | grep -v grep
          register: process_status
          ignore_errors: yes
        - name: 端口监听巡检
          wait_for:
            host: 127.0.0.1
            port: "{{ item }}"
            state: started
            timeout: 5
          loop: "{{ ports_to_check }}"
          register: port_status
          ignore_errors: yes
        - name: 巡检报告
          template:
            src: report_template.j2
            dest: "{{ report_file }}"
          vars:
            disk_usage: "{{ disk_usage.stdout }}"
            cpu_usage: "{{ cpu_usage.stdout }}"
            memory_usage: "{{ memory_usage.stdout }}"
            process_status: "{{ process_status.stdout }}"
            port_status: "{{ port_status.results }}"
        - name: 巡检报告邮箱发送
          mail:
            host: smtp.example.com
            port: 587
            username: your_username
            password: your_password
            to: your_email@example.com
            subject: "巡检报告"
            body: "{{ lookup('file', report_file) }}"

---------

# 参考文档

- https://blog.csdn.net/weixin_40228200/article/details/123513678