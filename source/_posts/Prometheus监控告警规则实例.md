---
title: Prometheus监控告警规则实例
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - 监控告警
  - 云计算
date: 2023-08-17 08:57:51
---

# 1.Prometheus监控规则

    vi /usr/local/prometheus/rules/prometheus.yaml


    groups:
    - name: prometheus
      rules:
      - alert: PrometheusAllTargetsMissing
        expr: count by (job) (up) == 0
        for: 2m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统所有监控指标丢失,请尽快处理!'
          description: "Prometheus系统所有监控指标丢失"
      - alert: PrometheusConfigurationReloadFailure
        expr: prometheus_config_last_reload_successful != 1
        for: 0m
        labels:
          severity: Warning
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统配置重载失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统配置重载失败"
      - alert: PrometheusTooManyRestarts
        expr: changes(process_start_time_seconds{job=~"prometheus|pushgateway|alertmanager"}[15m]) > 2
        for: 0m
        labels:
          severity: Warning
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统多次重启,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统15分钟内重启两次"
      - alert: PrometheusAlertmanagerConfigurationReloadFailure
        expr: alertmanager_config_last_reload_successful != 1
        for: 0m
        labels:
          severity: Warning
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统AlertManager告警组件配置重载失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统AlertManager告警组件配置重载失败"
      - alert: PrometheusNotificationsBacklog
        expr: min_over_time(prometheus_notifications_queue_length[10m]) > 0
        for: 1m
        labels:
          severity: Warning
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统告警消息堆积,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统告警消息堆积超过10分钟"
      - alert: PrometheusAlertmanagerNotificationFailing
        expr: rate(alertmanager_notifications_failed_total[1m]) > 0
        for: 1m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统AlertManager告警组件告警信息发送失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统AlertManager告警组件告警信息发送失败"
      - alert: PrometheusTsdbCheckpointCreationFailures
        expr: increase(prometheus_tsdb_checkpoint_creations_failed_total[1m]) > 0
        for: 0m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统TSDB数据库checkpoint创建失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统TSDB数据库checkpoint创建失败,当前状态为{{ $value }}"
      - alert: PrometheusTsdbCheckpointDeletionFailures
        expr: increase(prometheus_tsdb_checkpoint_deletions_failed_total[1m]) > 0
        for: 1m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统TSDB数据库checkpoint删除失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统TSDB数据库checkpoint删除失败,当前状态为{{ $value }}"
      - alert: PrometheusTsdbCompactionsFailed
        expr: increase(prometheus_tsdb_compactions_failed_total[1m]) > 0
        for: 1m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统TSDB数据库数据压缩失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统TSDB数据库数据压缩失败,当前频次为{{ $value }}"
      - alert: PrometheusTsdbHeadTruncationsFailed
        expr: increase(prometheus_tsdb_head_truncations_failed_total[1m]) > 0
        for: 1m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统TSDB数据库内存数据压缩失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统TSDB数据库内存数据压缩失败,当前频次为{{ $value }}"
      - alert: PrometheusTsdbReloadFailures
        expr: increase(prometheus_tsdb_reloads_failures_total[1m]) > 0
        for: 1m
        labels:
          severity: Critical
          clusters: Prometheus
        annotations:
          summary: 'Prometheus系统TSDB数据库配置重载失败,请尽快处理!'
          description: "{{ $labels.instance }}Prometheus系统TSDB数据库配置重载失败,当前状态为{{ $value }}"

# 2.Alertmanager监控规则

    vi /usr/local/prometheus/rules/alertmanager.yaml


    groups:
    - name: alertmanager.rules
      rules:
      - alert: AlertmanagerFailedReload
        annotations:
          description: Configuration has failed to load for {{ $labels.namespace }}/{{ $labels.pod}}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerfailedreload
          summary: Reloading an Alertmanager configuration has failed.
        expr: max_over_time(alertmanager_config_last_reload_successful{job="alertmanager-main",namespace="monitoring"}[5m]) == 0
        for: 10m
        labels:
          severity: Critical
      - alert: AlertmanagerMembersInconsistent
        annotations:
          description: Alertmanager {{ $labels.namespace }}/{{ $labels.pod}} has only found {{ $value }} members of the {{$labels.job}} cluster.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagermembersinconsistent
          summary: A member of an Alertmanager cluster has not found all other cluster members.
        expr: max_over_time(alertmanager_cluster_members{job="alertmanager-main",namespace="monitoring"}[5m]) < on (namespace,service) group_left count by (namespace,service) (max_over_time(alertmanager_cluster_members{job="alertmanager-main",namespace="monitoring"}[5m]))
        for: 10m
        labels:
          severity: Critical
      - alert: AlertmanagerFailedToSendAlerts
        annotations:
          description: Alertmanager {{ $labels.namespace }}/{{ $labels.pod}} failed to send {{ $value | humanizePercentage }} of notifications to {{ $labels.integration }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerfailedtosendalerts
          summary: An Alertmanager instance failed to send notifications.
        expr: (rate(alertmanager_notifications_failed_total{job="alertmanager-main",namespace="monitoring"}[5m]) /
              rate(alertmanager_notifications_total{job="alertmanager-main",namespace="monitoring"}[5m])) > 0.01
        for: 5m
        labels:
          severity: Warning
      - alert: AlertmanagerClusterFailedToSendAlerts
        annotations:
          description: The minimum notification failure rate to {{ $labels.integration }} sent from any instance in the {{$labels.job}} cluster is {{ $value | humanizePercentage }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerclusterfailedtosendalerts
          summary: All Alertmanager instances in a cluster failed to send notifications to a critical integration.
        expr: min by (namespace,service, integration) (rate(alertmanager_notifications_failed_total{job="alertmanager-main",namespace="monitoring", integration=~`.*`}[5m]) / rate(alertmanager_notifications_total{job="alertmanager-main",namespace="monitoring", integration=~`.*`}[5m])) > 0.01
        for: 5m
        labels:
          severity: Critical
      - alert: AlertmanagerClusterFailedToSendAlerts
        annotations:
          description: The minimum notification failure rate to {{ $labels.integration }} sent from any instance in the {{$labels.job}} cluster is {{ $value | humanizePercentage }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerclusterfailedtosendalerts
          summary: All Alertmanager instances in a cluster failed to send notifications to a non-critical integration.
        expr: |
          min by (namespace,service, integration) (
            rate(alertmanager_notifications_failed_total{job="alertmanager-main",namespace="monitoring", integration!~`.*`}[5m])
          /
            rate(alertmanager_notifications_total{job="alertmanager-main",namespace="monitoring", integration!~`.*`}[5m])
          )
          > 0.01
        for: 5m
        labels:
          severity: Warning
      - alert: AlertmanagerConfigInconsistent
        annotations:
          description: Alertmanager instances within the {{$labels.job}} cluster have different configurations.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerconfiginconsistent
          summary: Alertmanager instances within the same cluster have different configurations.
        expr: count by (namespace,service) (count_values by (namespace,service) ("config_hash", alertmanager_config_hash{job="alertmanager-main",namespace="monitoring"})) != 1
        for: 20m
        labels:
          severity: Critical
      - alert: AlertmanagerClusterDown
        annotations:
          description: '{{ $value | humanizePercentage }} of Alertmanager instances within the {{$labels.job}} cluster have been up for less than half of the last 5m.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerclusterdown
          summary: Half or more of the Alertmanager instances within the same cluster are down.
        expr: |
          ( count by (namespace,service) ( avg_over_time(up{job="alertmanager-main",namespace="monitoring"}[5m]) < 0.5 )
          /
          count by (namespace,service) ( up{job="alertmanager-main",namespace="monitoring"} )
          )
          >= 0.5
        for: 5m
        labels:
          severity: Critical
      - alert: AlertmanagerClusterCrashlooping
        annotations:
          description: '{{ $value | humanizePercentage }} of Alertmanager instances within the {{$labels.job}} cluster have restarted at least 5 times in the last 10m.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/alertmanagerclustercrashlooping
          summary: Half or more of the Alertmanager instances within the same cluster are crashlooping.
        expr: |
          (
            count by (namespace,service) (
              changes(process_start_time_seconds{job="alertmanager-main",namespace="monitoring"}[10m]) > 4
            )
          /
            count by (namespace,service) ( up{job="alertmanager-main",namespace="monitoring"} )
          )
          >= 0.5
        for: 5m
        labels:
          severity: Critical

# 3.主机监控规则

    vi /usr/local/prometheus/rules/nodes.yaml


    groups:
    - name: nodes
      rules:
      - alert: InstanceDown
        expr: up == 0
        for: 2m
        labels:
          severity: Critical
        annotations:
          summary: "{{ $labels.instance }}实例宕机，请尽快处理！"
          description: "{{ $labels.instance }}实例宕机超过2分钟，当前状态为{{ $value }}"
      - alert: HostCpuLoadAvage
        expr: sum(node_load5) by (instance) > 10
        for: 1m
        annotations:
          summary: "{{ $labels.instance }}实例CPU负载过高，请尽快处理！"
          description: "{{ $labels.instance }}实例CPU负载过高，当前值为{{ $value }}"
        labels:
          severity: Warning
      - alert: HostCpuUsage
        expr: (1-((sum(increase(node_cpu_seconds_total{mode="idle"}[5m])) by (instance))/ (sum(increase(node_cpu_seconds_total[5m])) by (instance))))*100 > 80
        for: 1m
        annotations:
          summary: "{{ $labels.instance }}实例CPU使用率过高，请尽快处理！"
          description: "{{ $labels.instance }}实例CPU使用率超过80%，当前值为{{ $value }}"
        labels:
          severity: Warning
      - alert: HostMemoryUsage
        expr: (1-((node_memory_Buffers_bytes + node_memory_Cached_bytes + node_memory_MemFree_bytes)/node_memory_MemTotal_bytes))*100 > 80
        for: 1m
        annotations:
          summary: "{{ $labels.instance }}实例内存使用率过高，请尽快处理！"
          description: "{{ $labels.instance }}实例内存使用率超过80%，当前使用率为{{ $value }}%"
        labels:
          severity: Warning
          clusters: CloudServer
      - alert: HostIOWait
        expr: ((sum(increase(node_cpu_seconds_total{mode="iowait"}[5m])) by (instance))/(sum(increase(node_cpu_seconds_total[5m])) by (instance)))*100 > 10
        for: 1m
        annotations:
          summary: "{{ $labels.instance }}实例磁盘IO过高，请尽快处理！"
          description: "{{ $labels.instance }}实例磁盘IO过高，当前负载值为{{ $value }}"
        labels:
          severity: Warning
      - alert: HostFileSystemUsage
        expr: (1-(node_filesystem_free_bytes{fstype=~"ext4|xfs",mountpoint!~".*tmp|.*boot" }/node_filesystem_size_bytes{fstype=~"ext4|xfs",mountpoint!~".*tmp|.*boot" }))*100 > 80
        for: 1m
        annotations:
          summary: "{{ $labels.mountpoint }}磁盘分区容量不足，请尽快处理！"
          description: "{{ $labels.instance }}实例{{ $labels.mountpoint }}磁盘分区使用率超过80%, 当前值使用率为{{ $value }}%"
        labels:
          severity: Warning
      - alert: HostSwapIsFillingUp
        expr: (1 - (node_memory_SwapFree_bytes / node_memory_SwapTotal_bytes)) * 100 > 80
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}实例Swap分区不足，请尽快处理！"
          description: "{{ $labels.instance }}实例Swap分区使用超过80%，当前值使用率为{{ $value }}%"
      - alert: HostNetworkConnection-ESTABLISHED
        expr:  sum(node_netstat_Tcp_CurrEstab) by (instance) > 1000
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}实例TCP ESTABLISHED连接数过高，请尽快处理！"
          description: "{{ $labels.instance }}实例TCP ESTABLISHED连接数超过1000，当前连接数为{{ $value }}"
      - alert: HostNetworkConnection-TIME_WAIT
        expr:  sum(node_sockstat_TCP_tw) by (instance) > 1000
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}实例TCP TIME_WAIT连接数过高，请尽快处理！"
          description: "{{ $labels.instance }}实例TCP TIME_WAIT连接数超过1000，当前连接数为{{ $value }}"
      - alert: HostUnusualNetworkThroughputIn
        expr:  sum by (instance, device) (rate(node_network_receive_bytes_total{device=~"ens.*"}[2m])) / 1024 / 1024 > 100
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}实例网卡入流量过高，请尽快处理！"
          description: "{{ $labels.instance }}实例网卡{{ $labels.device }}持续5分钟入流量带宽超过100MB/s, 当前值为{{ $value }}"
      - alert: HostUnusualNetworkThroughputOut
        expr: sum by (instance, device) (rate(node_network_transmit_bytes_total{device=~"ens.*"}[2m])) / 1024 / 1024 > 100
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}实例网卡出流量过高，请尽快处理！"
          description: "{{ $labels.instance }}实例网卡{{ $labels.device }}持续5分钟出流量带宽超过100MB/s, 当前值为{{ $value }}"
      - alert: HostUnusualDiskReadRate
        expr: sum by (instance, device) (rate(node_disk_read_bytes_total{device=~"sd.*"}[2m])) / 1024 / 1024 > 50
        for: 5m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.device }}磁盘分区读取速率过高，请尽快处理！"
          description: "{{ $labels.instance }}实例磁盘分区{{ $labels.device }}持续5分钟读取速度超过50MB/s, 当前值为{{ $value }}"     
      - alert: HostUnusualDiskWriteRate
        expr: sum by (instance, device) (rate(node_disk_written_bytes_total{device=~"sd.*"}[2m])) / 1024 / 1024 > 50
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.device }}磁盘分区写入速率过高，请尽快处理！"
          description: "{{ $labels.instance }}实例磁盘分区{{ $labels.device }}写入速度超过50 MB/s, 当前值为{{ $value }}"    
      - alert: HostOutOfInodes
        expr: node_filesystem_files_free{fstype=~"ext4|xfs",mountpoint!~".*tmp|.*boot" } / node_filesystem_files{fstype=~"ext4|xfs",mountpoint!~".*tmp|.*boot" } * 100 < 10
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.device }}磁盘分区Inode节点不足，请尽快处理！"
          description: "{{ $labels.instance }}实例{{ $labels.mountpoint }}磁盘分区Inode节点不足，当前值为{{ $value }}%"    
      - alert: HostUnusualDiskReadLatency
        expr: rate(node_disk_read_time_seconds_total{device=~"sd.*"}[1m]) / rate(node_disk_reads_completed_total{device=~"sd.*"}[1m]) > 0.1 and rate(node_disk_reads_completed_total{device=~"sd.*"}[1m]) > 0
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.device }}磁盘分区读延迟过高，请尽快处理！"
          description: "{{ $labels.instance }}实例磁盘分区{{ $labels.device }}读延迟过高超过100ms, 当前值为{{ $value }}"
      - alert: HostUnusualDiskWriteLatency
        expr: rate(node_disk_write_time_seconds_total{device=~"sd.*"}[1m]) / rate(node_disk_writes_completed_total{device=~"sd.*"}[1m]) > 0.1 and rate(node_disk_writes_completed_total{device=~"sd.*"}[1m]) > 0
        for: 2m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.device }}磁盘分区写延迟过高，请尽快处理！"
          description: "{{ $labels.instance }}实例磁盘分区{{ $labels.device }}写延迟超过100ms, 当前值为{{ $value }}"

# 4.MySQL监控规则

    vi /usr/local/prometheus/rules/mysql.yaml


    groups:
    - name: Mysql
      rules:
      - alert: MysqlDown
        expr: mysql_up == 0
        for: 1m
        labels:
          severity: Critical
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例宕机，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例宕机超过1分钟，当前状态为{{ $value }}"
      - alert: MysqlRestarted
        expr: mysql_global_status_uptime < 60
        for: 0m
        labels:
          severity: Info
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例已重启!'
          description: "{{ $labels.instance }}Mysql数据库实例1分钟前已重启，当前状态为{{ $value }}"
      - alert: MysqlConnectionError
        expr: rate(mysql_global_status_connection_errors_total[5m]) > 0
        for: 5m
        labels:
          severity: Warning
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例存在错误连接!'
          description: "{{ $labels.instance }}Mysql数据库实例5分钟内存在错误连接，连接数为{{ $value }}"
      - alert: MysqlTooManyConnections
        expr: max_over_time(mysql_global_status_threads_connected[1m]) / mysql_global_variables_max_connections * 100 > 80
        for: 2m
        labels:
          severity: Warning
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例当前连接数过高，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例当前连接数超过最大连接数的80%，当前连接数为{{ $value }}"
      - alert: MysqlHighThreadsRunning
        expr: max_over_time(mysql_global_status_threads_running[1m]) / mysql_global_variables_max_connections * 100 > 60
        for: 2m
        labels:
          severity: Warning
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例当前并发连接数过高，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例并发连接数超过最大连接数的60%，当前并发连接数为{{ $value }}"
      - alert: MysqlSlaveIoThreadNotRunning
        expr: ( mysql_slave_status_slave_io_running and ON (instance) mysql_slave_status_master_server_id > 0 ) == 0
        for: 0m
        labels:
          severity: Critical
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例从库IO线程未启动，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例从库IO线程未启动，当前状态为{{ $value }}"
      - alert: MysqlSlaveSqlThreadNotRunning
        expr: ( mysql_slave_status_slave_sql_running and ON (instance) mysql_slave_status_master_server_id > 0) == 0
        for: 0m
        labels:
          severity: Critical
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例从库SQL线程未启动，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例从库SQL线程未启动，当前状态为{{ $value }}"
      - alert: MysqlSlaveReplicationLag
        expr: ( (mysql_slave_status_seconds_behind_master - mysql_slave_status_sql_delay) and ON (instance) mysql_slave_status_master_server_id > 0 ) > 30
        for: 1m
        labels:
          severity: Critical
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例从库滞后于主库，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例从库滞后于主库，当前延迟时长为{{ $value }}"
      - alert: MysqlSlowQueries
        expr: rate(mysql_global_status_slow_queries[5m]) > 0
        for: 2m
        labels:
          severity: Warning
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例存在慢查询，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例存在慢查询，当前状态为{{ $value }}"
      - alert: MysqlInnodbLogWaits
        expr: rate(mysql_global_status_innodb_log_waits[15m]) > 10
        for: 0m
        labels:
          severity: Warning
          clusters: MysqlServer
        annotations:
          summary: '{{ $labels.instance }}Mysql数据库实例存在事务日志写入等待，请尽快处理!'
          description: "{{ $labels.instance }}Mysql数据库实例存在事务日志写入等待，当前等待写入的日志数为{{ $value }}"

# 5.Redis监控规则

    vi /usr/local/prometheus/rules/redis.yaml


    groups:
    - name: Redis
      rules:
      - alert: RedisDown
        expr: redis_up == 0
        for: 1m
        labels:
          severity: Critical
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis实例宕机，请尽快处理!'
          description: "{{ $labels.instance }}Redis实例宕机超过1分钟,当前状态为{{ $value }}"
      - alert: RedisMissingMaster
        expr: count(redis_instance_info{role="master"}) < 1
        for: 2m
        labels:
          severity: Critical
        annotations:
          summary: 'Redis集群主节点缺失!'
          description: "Redis集群主节点缺失"
      - alert: RedisTooManyMasters
        expr: count(redis_instance_info{role="master"}) > 1
        for: 2m
        labels:
          severity: Critical
        annotations:
          summary: 'Redis集群主节点过多!'
          description: "Redis集群主节点过多"
      - alert: RedisReplicationBroken
        expr: delta(redis_connected_slaves[1m]) < 0
        for: 0m
        labels:
          severity: Critical
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis集群复制中断，请尽快处理!'
          description: "{{ $labels.instance }}Redis实例失联,从节点丢失"
      - alert: RedisClusterFlapping
        expr: changes(redis_connected_slaves[1m]) > 1
        for: 2m
        labels:
          severity: Critical
          clusters: RedisServer
        annotations:
          summary: 'Redis集群发生扰动!'
          description: "{{ $labels.instance }}Redis实例从节点与主节点失联并建立重新连接,集群扰动"
      - alert: RedisMissingBackup
        expr: time() - redis_rdb_last_save_timestamp_seconds > 60 * 60 * 24
        for: 0m
        labels:
          severity: Critical
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis实例备份缺失,请尽快处理!'
          description: "{{ $labels.instance }}Redis实例超过24小时备份缺失"
      - alert: RedisOutOfConfiguredMaxmemory
        expr: redis_memory_used_bytes / redis_memory_max_bytes * 100 > 80
        for: 2m
        labels:
          severity: Warning
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis实例内存超限，请尽快处理!'
          description: "{{ $labels.instance }}Redis实例内存占用超过最大限制量80%, 当前值为{{ $value }}"
      - alert: RedisTooManyConnections
        expr: redis_connected_clients / redis_config_maxclients * 100 > 80
        for: 2m
        labels:
          severity: Warning
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis实例连接数过高，请尽快处理!'
          description: "{{ $labels.instance }}Redis实例连接数超过最大连接数的80%, 当前连接数为{{ $value }}"
      - alert: RedisNotEnoughConnections
        expr: redis_connected_clients < 5
        for: 2m
        labels:
          severity: Warning
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis实例连接数过少!'
          description: "{{ $labels.instance }}Redis实例连接数过少,当前连接数为{{ $value }}"
      - alert: RedisRejectedConnections
        expr: increase(redis_rejected_connections_total[1m]) > 0
        for: 0m
        labels:
          severity: Critical
          clusters: RedisServer
        annotations:
          summary: '{{ $labels.instance }}Redis实例1分钟内存在被拒绝的连接!'
          description: "{{ $labels.instance }}Redis实例被拒绝的连接数为{{ $value }}"

# 6.Elasticsearch监控规则

    vi /usr/local/prometheus/rules/elasticsearch.yaml


    groups:
    - name: Elasticsearch
      rules:
      - alert: ElasticsearchDown
        expr: elasticsearch_up == 0
        for: 1m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例宕机，请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例宕机超过1分钟,当前状态为{{ $value }}"
      rules:
      - alert: ElasticsearchHeapUsageTooHigh
        expr: (elasticsearch_jvm_memory_used_bytes{area="heap"} / elasticsearch_jvm_memory_max_bytes{area="heap"}) * 100 > 90
        for: 2m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: "Elasticsearch实例jvm内存超限，请尽快处理!"
          description: "{{ $labels.instance }}Elasticsearch实例jvm内存超过最大限制的90%,当前值为{{ $value }}"
      - alert: ElasticsearchDiskOutOfSpace
        expr: elasticsearch_filesystem_data_available_bytes / elasticsearch_filesystem_data_size_bytes * 100 < 10
        for: 0m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例磁盘空间不足，请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例磁盘空间占用超过90%, 当前值为{{ $value }}"
      - alert: ElasticsearchClusterRed
        expr: elasticsearch_cluster_health_status{color="red"} == 1
        for: 0m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch集群状态为Red,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例全部副本分片均不可用，集群状态为Red"
      - alert: ElasticsearchClusterYellow
        expr: elasticsearch_cluster_health_status{color="yellow"} == 1
        for: 0m
        labels:
          severity: Warning
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch集群状态为Yellow,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例存在不可用的副本分片，集群状态为Yellow"
      - alert: ElasticsearchHealthyNodes
        expr: elasticsearch_cluster_health_number_of_nodes < 3
        for: 0m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch集群健康节点数不足,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch集群健康节点数不足3,当前状态为{{ $value }}"
      - alert: ElasticsearchHealthyDataNodes
        expr: elasticsearch_cluster_health_number_of_data_nodes < 3
        for: 0m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch集群健康数据节点数不足,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch集群健康数据节点数不足3,当前状态为{{ $value }}"
      - alert: ElasticsearchRelocatingShards
        expr: elasticsearch_cluster_health_relocating_shards > 0
        for: 0m
        labels:
          severity: Info
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例正在重新定位分片'
          description: "{{ $labels.instance }}Elasticsearch实例正在重新定位分片"
      - alert: ElasticsearchRelocatingShardsTooLong
        expr: elasticsearch_cluster_health_relocating_shards > 0
        for: 15m
        labels:
          severity: Warning
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例重新定位分片时间过长,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例重新定位分片时间已超过15分钟!"
      - alert: ElasticsearchInitializingShards
        expr: elasticsearch_cluster_health_initializing_shards > 0
        for: 0m
        labels:
          severity: Info
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例正在初始化分片'
          description: "{{ $labels.instance }}Elasticsearch实例正在初始化分片"
      - alert: ElasticsearchInitializingShardsTooLong
        expr: elasticsearch_cluster_health_initializing_shards > 0
        for: 15m
        labels:
          severity: Warning
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例初始化分片时间过长,请尽快处理!'
          description: "{{ $labels.instance }}】Elasticsearch实例初始化分片时间已超过15分钟!"
      - alert: ElasticsearchUnassignedShards
        expr: elasticsearch_cluster_health_unassigned_shards > 0
        for: 0m
        labels:
          severity: Critical
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例存在未分配的分片,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例存在未分配的分片!"
      - alert: ElasticsearchPendingTasks
        expr: elasticsearch_cluster_health_number_of_pending_tasks > 0
        for: 15m
        labels:
          severity: Warning
          clusters: ElasticsearchServer
        annotations:
          summary: 'Elasticsearch实例存在待处理的任务,请尽快处理!'
          description: "{{ $labels.instance }}Elasticsearch实例存在待处理的任务,集群运行存在延迟, 当前状态为{{ $value }}"
      - alert: ElasticsearchNoNewDocuments
        expr: increase(elasticsearch_indices_docs{es_data_node="true"}[10m]) < 1
        for: 0m
        labels:
          severity: Info
          clusters: ElasticsearchServer
        annotations:
          summary: '{{ $labels.instance }}Elasticsearch实例持续10分钟没有文档写入'
          description: "{{ $labels.instance }}Elasticsearch实例持续10分钟没有文档写入"

# 7.Zookeeper告警规则

    vi /usr/local/prometheus/rules/Zookeeper.yaml


    groups:
    - name: Zookeeper
      rules:
      - alert: ZookeeperDown
        expr: zk_up == 0
        for: 1m
        labels:
          severity: Critical
          clusters: ZookeeperServer
        annotations:
          summary: "{{ $labels.instance }}Zookeeper实例宕机,请尽快处理!"
          description: '{{ $labels.instance }}Zookeeper实例宕机超过1分钟,当前状态为{{ $value }}'
      - alert: ZookeeperMissLeader
        expr: absent(zk_server_state{state="leader"})  != 1
        for: 1m
        labels:
          severity: Critical
          clusters: ZookeeperServer
        annotations:
          summary: "{{ $labels.instance }}Zookeeper集群Leader丢失,请尽快处理!"
          description: '{{ $labels.instance }}Zookeeper集群Leader丢失,当前状态为{{ $value }}'
      - alert: RequestsHeapTooHigh
        expr: avg(zk_outstanding_requests) by (instance) > 10    
        for: 1m
        labels:      
          severity: Critical
          clusters: ZookeeperServer
        annotations:
          summary: "{{ $labels.instance }}Zookeeper集群堆积请求量过高,请尽快处理!"
          description: "{{ $labels.instance }}Zookeeper集群堆积请求量大于10,当前状态为{{ $value }}"
      - alert: PendingSyncHeapTooHigh
        expr: avg(zk_pending_syncs) by (instance) > 10
        for: 1m
        labels:
          severity: Critical
          clusters: ZookeeperServer
        annotations:
          summary: "{{ $labels.instance }}Zookeeper集群Leader节点Sync阻塞量过高,请尽快处理! "
          description: "{{ $labels.instance }}Zookeeper集群Leader节点Sync阻塞量大于10,当前状态为{{ $value }}"
      - alert: AvgResponseLatencyTooHigh
        expr: avg(zk_avg_latency) by (instance) > 10
        for: 1m
        labels:
          severity: Critical
          clusters: ZookeeperServer
        annotations:
          summary: "Zookeeper集群平均响应延迟过高,请尽快处理!"
          description: '{{ $labels.instance }}Zookeeper集群平均响应延迟大于10,当前状态为{{ $value }}'
      - alert: OpenFileTooMany
        expr: zk_open_file_descriptor_count > zk_max_file_descriptor_count * 0.85
        for: 1m
        labels:
          severity: Critical
          clusters: ZookeeperServer
        annotations:
          summary: "Zookeeper集群文件打开量超限,请尽快处理! "
          description: '{{ $labels.instance }}Zookeeper集群打开文件描述符数量超过最大限量的85%,当前状态为{{ $value }}'

# 8.Kafka监控规则

    vi /usr/local/prometheus/rules/kafka.yaml


    groups:
    - name: Kafka
      rules:
      - alert: KafkaDown
        expr: kafka_up == 0
        for: 1m
        labels:
          severity: Critical
          clusters: KafkaServer
        annotations:
          summary: '{{ $labels.instance }}Kafka实例宕机，请尽快处理!'
          description: "{{ $labels.instance }}Kafka实例宕机超过1分钟,当前状态为{{ $value }}"
      - alert: KafkaTopicsReplicas
        expr: sum(kafka_topic_partition_in_sync_replica) by (topic) < 3
        for: 0m
        labels:
          severity: Critical
          clusters: KafkaServer
        annotations:
          summary: '{{ $labels.instance }}Kafka实例{{ $labels.topic }}Topic分区副本数不足,请尽快处理!'
          description: "{{ $labels.instance }}Kafka实例{{ $labels.topic }}Topic分区副本数少于3,当前值为{{ $value }}"
      - alert: KafkaConsumersGroupLag
        expr: sum(kafka_consumergroup_lag) by (consumergroup) > 50
        for: 1m
        labels:
          severity: Critical
          clusters: KafkaServer
        annotations:
          summary: '{{ $labels.instance }}Kafka实例消费组消息堆积,请尽快处理!'
          description: "{{ $labels.instance }}Kafka实例消费组消费堆积量超过50, 当前Lag值为{{ $value }}"
      - alert: KafkaConsumersTopicLag
        expr: sum(kafka_consumergroup_lag) by (topic) > 50
        for: 1m
        labels:
          severity: Critical
          clusters: KafkaServer
        annotations:
          summary: '{{ $labels.instance }}Kafka实例Topic消息堆积,请尽快处理!'
          description: "{{ $labels.instance }}Kafka实例Topic消息堆积量已超过50, 当前Lag值为{{ $value }}"

# 9.Docker监控规则

    vi /usr/local/prometheus/rules/docker.yaml


    groups:
    - name: docker
      rules:
      - alert: ContainerKilled
        expr: time() - container_last_seen{name!=""} > 60
        for: 1m
        labels:
          severity: Critical
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器被Kill，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器被Kill"
      - alert: ContainerCpuUsage
        expr: (sum by(instance, name) (rate(container_cpu_usage_seconds_total{name!=""}[3m])) * 100) > 80
        for: 2m
        labels:
          severity: Warning
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器CPU使用率过高，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器CPU使用率超过80%, 当前值为{{ $value }}"
      - alert: ContainerHighThrottleRate
        expr: rate(container_cpu_cfs_throttled_seconds_total[3m]) > 1
        for: 2m
        labels:
          severity: Warning
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器CPU超限，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器持续2分钟CPU超限, 当前值为{{ $value }}"
      - alert: ContainerMemoryUsage
        expr: (sum by(instance, name) (container_memory_working_set_bytes{name!=""}) / sum by(instance, name) (container_spec_memory_limit_bytes{name!=""} > 0) * 100)  > 80
        for: 2m
        labels:
          severity: Warning
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器内存使用率过高，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器内存使用率超过80%, 当前值为{{ $value }}"
      - alert: ContainerVolumeUsage
        expr: (1 - (sum(container_fs_inodes_free) BY (instance) / sum(container_fs_inodes_total) BY (instance))) * 100 > 80
        for: 5m
        labels:
          severity: Warning
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器磁盘使用率过高，请尽快处理!"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器磁盘使用率超过80%, 当前值为{{ $value }}"
      - alert: ContainerLowCpuUtilization
        expr: (sum(rate(container_cpu_usage_seconds_total{name!=""}[3m])) BY (instance, name) * 100) < 20
        for: 7d
        labels:
          severity: Info
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器CPU使用率过低，建议缩减CPU配额"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器持续7天CPU使用率低于20%, 当前值为{{ $value }}"
      - alert: ContainerLowMemoryUsage
        expr: (sum(container_memory_working_set_bytes{name!=""}) BY (instance, name) / sum(container_spec_memory_limit_bytes > 0) BY (instance, name) * 100) < 20
        for: 7d
        labels:
          severity: Info
          clusters: CloudServer
        annotations:
          summary: "{{ $labels.name }}容器内存使用率过低，建议缩减内存配额"
          description: "{{ $labels.instance }}实例{{ $labels.name }}容器持续7天内存使用率低于20%, 当前值为{{ $value }}"

# 10.SSL证书监控规则

    vi /usr/local/prometheus/rules/ssl.yaml


    groups:
    - name: ssl
      rules:
      - alert: SslCertificateProbeFailed
        expr: ssl_probe_success == 0
        for: 0m
        labels:
          severity: Critical
        annotations:
          summary: "{{ $labels.instance }}实例SSL证书请求探测失败,请及时处理!"
          description: "{{ $labels.instance }}实例SSL证书信息获取失败,当前状态为{{ $value }}"
      - alert: SslCertificateExpiry
        expr: ssl_verified_cert_not_after{chain_no="0"} - time() < 86400 * 7
        for: 0m
        labels:
          severity: Warning
        annotations:
          summary: "{{ $labels.instance }}实例SSL证书即将过期,请尽快处理!"
          description: "{{ $labels.instance }}实例SSL证书有效期不足7,天当前状态为{{ $value }}"

---------

# 参考文档

- https://blog.51cto.com/u_64214/6080565
- https://codeleading.com/article/55986015391
- https://codeleading.com/article/61863346404
- https://samber.github.io/awesome-prometheus-alerts/rules
- https://blog.csdn.net/yeqinghanwu/article/details/126367493