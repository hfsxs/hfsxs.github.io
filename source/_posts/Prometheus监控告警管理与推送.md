---
title: Prometheus监控告警管理与推送
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Alertmanager
  - 监控告警
  - 云计算
date: 2023-10-24 15:51:46
---

Prometheus监控系统的告警通知由Alertmanager组件负责管理，如告警信息的去重、分组、抑制与静默，最后通过路由推送给配置好的接收者，如电子邮箱、Slack、Webhook等

# 告警分组

分组，即是将具有相同性质的告警合并后作为单个通知进行发送，如两台主机的CPU/内存/磁盘使用率同时告警，则这些告警就可合并为一个告警通知，从而避免大量同类错误产生的告警风暴所导致关键告警信息的淹没。分组规则由group_by配置项按照告警标签指定，匹配到的告警合并为一个组

# 告警抑制

抑制，即是禁止触发相互依赖的级联告警，从而可以集中于真正的故障所在，如主机宕机的告警即可抑制该主机上所有运行的服务，Docker、MySQL等等

# 告警静默

静默，即某些预期内的告警不再进行发送，若从Prometheus推送过来的告警事件被静默规则匹配到，Alertmanager则将之设为静默状态，不再进行发送。告警静默通常用于系统维护升级，或上游服务器故障所导致的下游服务器告警，这些某个时间段内不希望触发告警通知的场景。直到维护结束，手动解除静默，恢复对应服务的告警通知功能。告警静默功能由Alertmanager UI通过定义标签的匹配规则(字符串或者正则表达式)启用

# 告警路由

路由，即基于告警匹配规则将告警事件推送给不同的接受者，以便于进行进一步的处理。告警路由分为两部分，即顶级根路由和子路由，其本质上就是一个基于标签匹配规则的树状结构，所有告警信息从顶级路由开始，根据标签匹配规则进入到不同的子路由，并且根据子路由设置的接收器发送告警，匹配不到子路由的告警则由默认接收者接收。子路由的告警匹配方式有两种，基于字符串验证，通过设置match规则判断告警是否存在标签label.name，且其值等于label.value；基于正则表达式，通过设置match_re验证告警标签的值是否满足正则表达式

# 1.配置解析

    # 设置全局参数，即作为默认值供子设置继承的公共设置，子参数中也可覆盖其设置
    global:
      # 设置处理超时时间，即为告警的解决的时间，直接影响到警报恢复的通知时间，默认为5分钟，建议依据实际生产场景进行设置
      resolve_timeout: 1m

      # 设置邮箱smtp服务器
      smtp_smarthost: 'smtp.qq.com:465'
      # 设置发件邮箱
      smtp_from: 'xxxxxxxxx@qq.com'
      # 设置发件账号
      smtp_auth_username: 'xxxxxxxxx@qq.com'
      # 设置发件人邮箱授权码，注意不是登录密码
      smtp_auth_password: 'xxxxxxxxx' 
      # 设置关闭邮箱的tls验证
      smtp_require_tls: false

    # 设置告警通知的模版
    templates:
    - '/etc/alertmanager/template/*.tmpl'

    # 设置告警根路由，即分发策略
    route:
      # 设置告警分组，即将具有相同标签的告警通知合并为告警组，作为单个通知发送
      group_by: ['alertname']
      # 设置组内告警发送的等待时间，即组内收到第一个告警后的发送等待时间，目标是等待组内新增的告警以便同时合并发送，默认为30s
      group_wait: 10s
      # 设置组内不同批次告警发送的时间间隔，默认为5m
      group_interval: 10s
      # 设置告警未解决时重复发送的时间间隔，且此期间组内无新增告警，默认4h，建议根据告警严重程度进行设置
      repeat_interval: 1h 
      # 设置默认告警接收者，即未被子路由的receivers.name选项匹配到的告警接收者
      receiver: 'webhook'

      # 设置告警信息子路由
      routes:
      # 设置告警接收器，即指定发送人以及发送渠道，支持多种类型，如邮箱、钉钉、企业微信等
      - receiver: 'email'
        group_wait: 10s
        match:
          team: node

    # 设置告警接收者
    receivers:
     - name: 'webhook'
       webhook_configs:
       - url: http://localhost:8060/dingtalk/ops_dingding/send
         # 设置当前收件人需要接收告警恢复通知
         send_resolved: true
     - name: 'email'
       email_configs:
       - to: 'xxxxxxxxxxxx@163.com'
       - to: 'xxxxxxxxxxxx@qq.com'
         send_resolved: true

    # 设置告警抑制规则，以减少垃圾告警的产生
    inhibit_rules:
      # 设置抑制规则源告警的匹配标签、名称或注释，可为标签列表或正则表达式，可选参数
      - source_match:
          severity: 'critical'
        # 设置抑制规则目标告警的匹配标签、名称或注释，可为标签列表或正则表达式，可选参数
        target_match:
          severity: 'warning'
        # 设置源告警与目标告警相同的标签值，可选参数，意为同instance、alertname的warning告警将被critical告警抑制
        equal: ['alertname', 'instance']

# 2.配置邮件通知

邮箱是目前企业最常用的告警通知方式，Alertmanager内置了对SMTP协议的支持，只需定义好SMTP相关的配置，并且在receiver中定义接收方的邮件地址即可

## 2.1 发送邮箱开启SMTP服务，获取登录授权码

![prometheus-010](/img/wiki/prometheus/prometheus-010.jpg)

- 注：不是邮箱登录密码，而是发送邮箱开启SMTP服务后登录第三方邮件客户端的授权码

## 2.2 修改AlertManager配置文件

    sudo vi /usr/local/prometheus/alertmanager.yml


    global:
      resolve_timeout: 1m

      # 设置邮箱smtp服务器
      smtp_smarthost: 'smtp.139.com:465'
      # 设置发件邮箱
      smtp_from: 'sxs0618@139.com'
      # 设置发件账号
      smtp_auth_username: 'sxs0618@q139.com'
      # 设置发件人邮箱授权码，注意不是登录密码
      smtp_auth_password: 'xxxxxxxxx' 
      # 设置关闭邮箱的tls验证
      smtp_require_tls: false

    # 设置告警通知的模版
    templates:
    - '/usr/local/prometheus/template/*.tmpl'

    route:
      # 设置告警分组，即将具有相同标签的告警通知合并为告警组，作为单个通知发送
      group_by: ['alertname']
      # 设置组内告警发送的等待时间，即组内收到第一个告警后的发送等待时间，目标是等待组内新增的告警以便同时合并发送，默认为30s
      group_wait: 10s
      # 设置组内不同批次告警发送的时间间隔，默认为5m
      group_interval: 10s
      # 设置告警未解决时重复发送的时间间隔，且此期间组内无新增告警，默认4h，建议根据告警严重程度进行设置
      repeat_interval: 1h 
      # 设置默认告警接收者，即未被子路由的receivers.name选项匹配到的告警接收者
      receiver: 'email'

    receivers:
     - name: 'email'
       email_configs:
       - to: '523343553@qq.com'
         send_resolved: true

    inhibit_rules:
      # 设置抑制规则源告警的匹配标签、名称或注释，可为标签列表或正则表达式，可选参数
      - source_match:
          severity: 'critical'
        # 设置抑制规则目标告警的匹配标签、名称或注释，可为标签列表或正则表达式，可选参数
        target_match:
          severity: 'warning'
        # 设置源告警与目标告警相同的标签值，可选参数，意为同instance、alertname的warning告警将被critical告警抑制
        equal: ['alertname', 'instance']

# 2.3 创建告警通知模版

    sudo mkdir -p /usr/local/prometheus/template
    vi /usr/local/prometheus/template/email.tmpl


    {{ define "email.html" }} 
    {{ range .Alerts }} 
    =========start==========<br> 
    告警程序: prometheus_alert <br> 
    告警级别: {{ .Labels.severity }} 级 <br>
    告警类型: {{ .Labels.alertname }} <br> 
    故障主机: {{ .Labels.instance }} <br> 
    告警主题: {{ .Annotations.summary }} <br>
    告警详情: {{ .Annotations.description }} <br>
    触发时间: {{ .StartsAt }} <br>
    =========end==========<br> 
    {{ end }} 
    {{ end }}

# 2.4 关闭服务器，验证告警推送信息

# 3.配置钉钉通知

## 3.1 钉钉群创建机器人

## 3.2 部署钉钉告警插件

### 3.2.1 安装Webhook-dingtalk

    sudo mkdir -p /usr/local/prometheus/dingtalk
    wget https://github.com/timonwong/prometheus-webhook-dingtalk/releases/download/v2.1.0/prometheus-webhook-dingtalk-2.1.0.linux-amd64.tar.gz
    tar -xzvf prometheus-webhook-dingtalk-2.1.0.linux-amd64.tar.gz 
    sudo mv prometheus-webhook-dingtalk-2.1.0.linux-amd64 /usr/local/prometheus/dingtalk/webhook-dingtalk
    sudo mv config.example.yml /usr/local/prometheus/dingtalk/config.yml

### 3.2.2 创建配置文件

    sudo vi /usr/local/prometheus/dingtalk/config.yml


    templates:
      - /usr/local/prometheus/template/dingtalk.tmpl
    targets:
      webhook:
        url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxx
        secret: xxxxxxxxx
        message:
          text: '{{ template "dingtalk.to.message" . }}'
        mention:
          all: true

### 3.2.3 创建告警通知模版

    sudo mkdir -p /usr/local/prometheus/template
    vi /usr/local/prometheus/template/dingtalk.tmpl


    {{ define "dingtalk.to.message" }}

    {{- if gt (len .Alerts.Firing) 0 -}}
    {{- range $index, $alert := .Alerts -}}

    =========  **监控告警** ========= </br>

    **告警集群:**    {{ $alert.Labels.clusters }} </br> 
    **告警类型:**    {{ $alert.Labels.alertname }} </br>
    **告警级别:**    {{ $alert.Labels.severity }}  
    **告警状态:**    {{ .Status }}   
    **故障主机:**    {{ $alert.Labels.hostname }} {{ $alert.Labels.device }}   
    **告警主题:**    {{ .Annotations.summary }}   
    **告警详情:**    {{ $alert.Annotations.message }}{{ $alert.Annotations.description}}   
    **主机标签:**    {{ range .Labels.SortedPairs  }}  </br> [{{ .Name }}: {{ .Value | markdown | html }} ] 
    {{- end }} </br>

    **故障时间:**    {{ ($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }}  
    ========= = **end** =  =========  </br>
    {{- end }}
    {{- end }}

    {{- if gt (len .Alerts.Resolved) 0 -}}
    {{- range $index, $alert := .Alerts -}}

    ========= **故障恢复** ========= </br> 
    **告警集群:**    {{ $alert.Labels.clusters }} </br>
    **告警主题:**    {{ $alert.Annotations.summary }}  
    **告警主机:**    {{ .Labels.hostname }}   
    **告警类型:**    {{ .Labels.alertname }}  
    **告警级别:**    {{ $alert.Labels.severity }}    
    **告警状态:**    {{ .Status }}  
    **告警详情:**    {{ $alert.Annotations.message }}{{ $alert.Annotations.description}}  
    **故障时间:**    {{ ($alert.StartsAt.Add 28800e9).Format "2006-01-02 15:04:05" }}  
    **恢复时间:**    {{ ($alert.EndsAt.Add 28800e9).Format "2006-01-02 15:04:05" }}  
    {{- end }}
    {{- end }}
    {{- end }}

### 3.2.4 创建启动脚本

    sudo vi /lib/systemd/system/dingtalk-webhook.service


    [Unit]
    Description=Prometheus Webhook Dingtalk
    Documentation=https://github.com/timonwong/prometheus-webhook-dingtalk
    After=network.target

    [Service]
    ExecStart=/usr/local/prometheus/dingtalk/prometheus-webhook-dingtalk --config.file=/usr/local/prometheus/dingtalk/config.yml

    [Install]
    WantedBy=multi-user.target

### 3.2.5 启动Webhook-dingtalk插件

    sudo systemctl daemon-reload
    sudo systemctl start dingtalk-webhook.service 
    sudo systemctl enable dingtalk-webhook.service 

## 3.3 修改Alertmanager配置文件

    # 设置全局参数，即作为默认值供子设置继承的公共设置，子参数中也可覆盖其设置
    global:
      # 设置处理超时时间，即为告警的解决的时间，直接影响到警报恢复的通知时间，默认为5分钟，建议依据实际生产场景进行设置
      resolve_timeout: 1m

      # 设置邮箱smtp服务器
      smtp_smarthost: 'smtp.139.com:465'
      # 设置发件邮箱
      smtp_from: 'sxs0618@139.com'
      # 设置发件账号
      smtp_auth_username: 'sxs0618@qq.com'
      # 设置发件人邮箱授权码，注意不是登录密码
      smtp_auth_password: 'xxxxxxxxx' 
      # 设置关闭邮箱的tls验证
      smtp_require_tls: false

    # 设置告警通知的模版
    templates:
    - '/etc/alertmanager/template/*.tmpl'

    # 设置告警根路由，即分发策略
    route:
      # 设置告警分组，即将具有相同标签的告警通知合并为告警组，作为单个通知发送
      group_by: ['alertname']
      # 设置组内告警发送的等待时间，即组内收到第一个告警后的发送等待时间，目标是等待组内新增的告警以便同时合并发送，默认为30s
      group_wait: 10s
      # 设置组内不同批次告警发送的时间间隔，默认为5m
      group_interval: 10s
      # 设置告警未解决时重复发送的时间间隔，且此期间组内无新增告警，默认4h，建议根据告警严重程度进行设置
      repeat_interval: 1h 
      # 设置默认告警接收者，即未被子路由的receivers.name选项匹配到的告警接收者
      receiver: 'webhook'

      # 设置告警信息子路由
      routes:
      # 设置告警接收器，即指定发送人以及发送渠道，支持多种类型，如邮箱、钉钉、企业微信等
      - receiver: 'email'
        group_wait: 10s
        match:
          team: node

    # 设置告警接收者
    receivers:
     - name: 'webhook'
       webhook_configs:
       - url: http://localhost:8060/dingtalk/ops_dingding/send
         # 设置当前收件人需要接收告警恢复通知
         send_resolved: true
     - name: 'email'
       email_configs:
       - to: 'xxxxxxxxxxxx@163.com'
       - to: 'xxxxxxxxxxxx@qq.com'
         send_resolved: true

    # 设置告警抑制规则，以减少垃圾告警的产生
    inhibit_rules:
      # 设置抑制规则源告警的匹配标签、名称或注释，可为标签列表或正则表达式，可选参数
      - source_match:
          severity: 'critical'
        # 设置抑制规则目标告警的匹配标签、名称或注释，可为标签列表或正则表达式，可选参数
        target_match:
          severity: 'warning'
        # 设置源告警与目标告警相同的标签值，可选参数，意为同instance、alertname的warning告警将被critical告警抑制
        equal: ['alertname', 'instance']

## 3.4 重启Alertmanager，验证告警推送信息

---------

# 参考文档

- https://andyoung.blog.csdn.net/article/details/126243110
- https://blog.csdn.net/qq_43164571/article/details/113104877
- https://blog.csdn.net/weixin_45310323/article/details/134103279
- https://blog.csdn.net/weixin_43883625/article/details/129759758