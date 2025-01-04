---
title: Keepalived配置文件详解
categories:
  - 工作
tags:
  - Linux
  - Keepalived
  - 集群
  - 高可用
  - 云计算
date: 2020-02-05 14:36:11
---

    ! Configuration File for keepalived
    # global_defs，全局定义块 
    global_defs {
   
      notification_email {
      # 设置故障切换告警邮箱，多个分行即可
      example@example.cn
      }

    # 设置发件人邮箱地址
    notification_email_from example@example.cn
    # 设置smtp服务器地址
    smtp_server 127.0.0.1
    # 设置smtp连接超时时间
    smtp_connect_timeout 30
    # 该节点的标识符
    router_id web-ha-001
    }

    # vrrp_sync_group，实例组配置，可不设置，用于确定失败切换（FailOver）包含的路由实例个数，即在有2个负载均衡器的场景，一旦某个负载均衡器失效，需要自动切换到另外一个负载均衡器的实例是哪些，至少包含一个vrrp实例
    # vrrp_sync_group VG_1 { 
        #group {
          # VI_1
          # VI_2
    # }

    # 设置切换master执行的脚本
    notify_master /path/*.sh
    # 设置换backup执行的脚本
    netify_backup /path/*.sh
    # 设置故障发生执行的脚本
    notify_fault "/path/*.sh VG_1" 
    notify /path/xx.sh
    # 使用global_defs中提供的邮件地址和smtp服务器发送邮件通知
    smtp_alert

    }

    # vrrp_instance，vrrp实例定义，实例名出自vrrp_sync_group
    vrrp_instance VI_1 {

      # 设置主备服务器，若设置nopreempt，则主备由priority决定
      state MASTER
      # 设置VIP绑定的网卡
      interface eth0
      # 忽略vrrp的interface错误，默认不设置
      dont_track_primary 

      # 设置额外的监控，其中任一网卡故障都会进行切换
      track_interface{
        eth0
        eth1
      }

      # 发送多播包的地址，默认使用绑定网卡的primary ip
      mcast_src_ip
      # 切换master状态后，延迟进行gratuitous ARP请求
      garp_master_delay
      # VRRP组名，两节点一致，表明节点属同一VRRP组
      virtual_router_id 50
      # 优先级定义，取值1~254，高优先级竞选为master
      priority 100
      # 组播信息发送间隔，两节点一致
      advert_int 1
      # 非抢占模式，设置在备机上，或者优先级低于备机的主机上
      # 表示主机或优先级高于主机的备机在故障恢复后不提供服务，即不抢占VIP
      nopreempt
      # 抢占延时，默认5分钟
      preempt_delay
      #debug级别
      debug

      # 设置认证
      authentication {
        # 认证方式
        auth_type PASS
        # 认证密码
        auth_pass 1234
      }

      # 设置vip
      virtual_ipaddress {
        192.168.0.200/24
      }
    }


    # virtual_server，虚拟服务器定义块
    # 用于管理LVS，实现与LVS的结合。ipvsadm命令可以实现的管理可以通过参数配置实现，real_server是其子模块

    # VIP定义，要和vrrp_instance模块中的virtual_ipaddress地址一致
    virtual_server 192.168.0.200 80 {

      # 健康检查时间间隔
      delay_loop 6
      # lvs调度算法，rr|wrr|lc|wlc|lblc|sh|dh
      lb_algo rr
      # 负载均衡转发规则,NAT|DR|RUN 
      lb_kind DR
      nat_mask 255.255.255.0
      # 会话保持时间
      persistence_timeout 5
      # 使用的协议,TCP|UDP
      protocol TCP
      # lvs会话保持粒度
      persistence_granularity <NETMASK>
      # 检查的web服务器的虚拟主机
      virtualhost <string>
      # 备用机，所有realserver失效后启用
      sorry_server<IPADDR> <port>

      # real server，真实服务器定义块
      real_server 192.168.0.150 80 {
        # 默认为1,0为失效
        weight 1
        # 服务器健康检查失效时，将其设为0，而不是直接从ipvs中删除 
        inhibit_on_failure
        # 检测到server up后执行的脚本
        notify_up <string> | <quoted-string>
        # 检测到server down后执行脚本
        notify_down <string> | <quoted-string>

        # TCP健康检测            
        TCP_CHECK {
          # 连接超时时间
          connect_timeout 3
          # 重连次数
          nb_get_retry 3
          # 重连间隔时间
          delay_before_retry 3
          # 健康检测的端口的端口
          connect_port 80
        }

        # 脚本健康检测
        MISC_CHECK{
          # 外部脚本路径
          misc_path <string> | <quoted-string>
          # 脚本执行超时时间
          misc_timeout
          # 若设置该项，则退出状态码会用来动态调整服务器的权重，返回0 正常，不修改；返回1，检查失败，权重改为0；返回2-255，正常，权重设置为：返回状态码-2
          misc_dynamic
        }

        # HTTP_GET、SSL_GET健康检测
        HTTP_GET | SSL_GET {
        # 检查url，可以指定多个
        url{
          path /
          # 检查后的摘要信息
          digest <string>
          # 检查的返回状态码
          status_code 200
        }

        connect_port <port> 
        bindto <IPADD>
        connect_timeout 5
        nb_get_retry 3
        delay_before_retry 2
        }

        # SMTP健康检测
        SMTP_CHECK{
          host{
            connect_ip <IP ADDRESS>
            # 默认检查25端口
            connect_port <port>
            bindto <IP ADDRESS>
          }

          connect_timeout 5
          retry 3
          delay_before_retry 2
          # smtp helo请求命令参数，可选
          helo_name <string> | <quoted-string>
        }
      }
    }