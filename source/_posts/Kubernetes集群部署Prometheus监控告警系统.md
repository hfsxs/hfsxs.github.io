---
title: Kubernetes集群基于Kube-Prometheus部署监控告警系统
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - Prometheus
  - 监控告警
  - 云原生
  - 容器云
  - 云计算
date: 2021-12-02 15:21:47
---

Kube-Prometheus，Coreos基于Prometheus Operator开发的专为Kubernetes集群设计的一站式开箱即用监控方案，以定制资源管理应用和组件的方式简便快捷地实现Prometheus实例的部署、管理及监控规则的定义，从而大大降低了Kubernetes集群接入Prometheus监控系统的难度，无需手动编写繁杂的YAML文件进行部署与管理

# Prometheus Operator

Prometheus Operator基于Kubernetes集群的operator操作模式而设计，在不修改Kubernetes自身代码的情况下通过封装业务逻辑和任务自动化代码定制资源管理应用及其组件，从而获得集群内置的自动化功能与扩展功能，达成Prometheus监控系统配置的精简化与自动化

## 系统架构

### Operator

Operator根据自定义资源（Custom Resource Definition即CRDs）部署和管理Prometheus Server，并监控这些自定义资源事件的变化做相应的处理，是整个系统的控制中心

### Prometheus

Prometheus声明性地描述Prometheus部署的期望状态

### Prometheus Server

Operator根据自定义资源Prometheus类型中定义的内容而部署Prometheus Server集群，这些自定义资源是用来管理Prometheus Server集群的StatefulSets

## ServiceMonitor

ServiceMonitor也是自定义资源，描述了一组被Prometheus监控的targets列表，通过Labels选取对应的Service Endpoint，从而使得Prometheus Server通过选取的Service获取Metrics信息

### Service

Service用于对应Kubernetes集群中的Metrics Server Pod，也即是Prometheus监控的对象，提供给ServiceMonitor选取让Prometheus Server来获取信息，如Node Exporter Service、Mysql Exporter Service等

### Alertmanager

Alertmanager也是自定义资源类型，由Operator根据资源描述的内容部署Alertmanager集群

---------

# 1.部署nfs

# 2.下载Prometheus Operator

    wget -O kube-prometheus-0.8.0.tar.gz https://github.com/prometheus-operator/kube-prometheus/archive/refs/tags/v0.8.0.tar.gz

# 3.部署CRD

    tar -xzvf kube-prometheus-0.8.0.tar.gz && cd kube-prometheus-0.8.0/manifests
    kubectl apply -f setup/

# 4.部署StorageClass

## 4.1 创建provisioner

    vi nfs-client-provisioner.yaml


    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: nfs-client-provisioner
      namespace: kube-system
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: nfs-client-provisioner-runner
    rules:
      - apiGroups: [""]
        resources: ["persistentvolumes"]
        verbs: ["get", "list", "watch", "create", "delete"]
      - apiGroups: [""]
        resources: ["persistentvolumeclaims"]
        verbs: ["get", "list", "watch", "update"]
      - apiGroups: ["storage.k8s.io"]
        resources: ["storageclasses"]
        verbs: ["get", "list", "watch"]
      - apiGroups: [""]
        resources: ["events"]
        verbs: ["create", "update", "patch"]
    ---
    kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: run-nfs-client-provisioner
    subjects:
      - kind: ServiceAccount
        name: nfs-client-provisioner
        namespace: monitoring
    roleRef: 
      kind: ClusterRole
      name: nfs-client-provisioner-runner
      apiGroup: rbac.authorization.k8s.io
    ---
    kind: Role
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: leader-locking-nfs-client-provisioner
      namespace: kube-system
    rules:
      - apiGroups: [""]
        resources: ["endpoints"]
        verbs: ["get", "list", "watch", "create", "update", "patch"]
    ---
    kind: RoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: leader-locking-nfs-client-provisioner
      namespace: kube-system
    subjects:
      - kind: ServiceAccount
        name: nfs-client-provisioner
        namespace: monitoring
    roleRef:
      kind: Role
      name: leader-locking-nfs-client-provisioner
      apiGroup: rbac.authorization.k8s.io
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: nfs-client-provisioner
      labels:
        app: nfs-client-provisioner
      namespace: kube-system
    spec:
      replicas: 1
      strategy:
        type: Recreate
      selector:
        matchLabels:
          app: nfs-client-provisioner
      template:
        metadata:
          labels:
            app: nfs-client-provisioner
        spec:
          serviceAccountName: nfs-client-provisioner
          containers:
            - name: nfs-client-provisioner
              image: quay.io/external_storage/nfs-client-provisioner:latest
              volumeMounts:
                - name: nfs-client-root
                  mountPath: /persistentvolumes
              env:
                - name: PROVISIONER_NAME
                  # 设置nfs provisioner名称，storageclass需保持一致
                  value: nfs-client
                - name: NFS_SERVER
                  # 设置nfs服务器IP
                  value: 192.168.100.200
                - name: NFS_PATH
                  # 设置nfs路径
                  value: /home/project/kubernetes
          volumes:
            - name: nfs-client-root
              nfs:
                server: 192.168.100.200
                path: /home/project/kubernetes

## 4.2 创建默认StorageClass

    vi sc-default.yaml


    apiVersion: storage.k8s.io/v1
    kind: StorageClass
    metadata:
      name: sc-nfs
      annotations:
        # 设置为集群默认storageclass
        storageclass.kubernetes.io/is-default-class: "true"
    # 设置动态卷供应器名称，对应供应器PROVISIONER_NAME
    provisioner: nfs-client
    parameters:
      # 设置PVC删除时保留PV数据
      archiveOnDelete: "true"

# 5.配置持久化存储

## 5.1 配置prometheus持久化存储

    vi prometheus-prometheus.yaml


    apiVersion: monitoring.coreos.com/v1
    kind: Prometheus
    metadata:
      labels:
        app.kubernetes.io/component: prometheus
        app.kubernetes.io/name: prometheus
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 2.26.0
        prometheus: k8s
      name: k8s
      namespace: monitoring
    spec:
      alerting:
        alertmanagers:
        - apiVersion: v2
          name: alertmanager-main
          namespace: monitoring
          port: web
      externalLabels: {}
      image: quay.io/prometheus/prometheus:v2.26.0
      nodeSelector:
        kubernetes.io/os: linux
      podMetadata:
        labels:
          app.kubernetes.io/component: prometheus
          app.kubernetes.io/name: prometheus
          app.kubernetes.io/part-of: kube-prometheus
          app.kubernetes.io/version: 2.26.0
      podMonitorNamespaceSelector: {}
      podMonitorSelector: {}
      probeNamespaceSelector: {}
      probeSelector: {}
      replicas: 2
      resources:
        requests:
          memory: 400Mi
      ruleSelector:
        matchLabels:
          prometheus: k8s
          role: alert-rules
      securityContext:
        fsGroup: 2000
        runAsNonRoot: true
        runAsUser: 1000
      serviceAccountName: prometheus-k8s
      serviceMonitorNamespaceSelector: {}
      serviceMonitorSelector: {}
      version: 2.26.0
      # 新增存储配置
      storage:
        volumeClaimTemplate:
          spec:
            storageClassName: sc-nfs
            accessModes: ["ReadWriteOnce"]
            resources:
              requests:
                storage: 10Gi

## 5.2 配置grafana持久化存储

### 5.2.1 修改部署文件

    vi grafana-deployment.yaml


    volumes:
      - persistentVolumeClaim:
          claimName: grafana-data
        name: grafana-storage

### 5.2.2 创建PV、PVC

    vi grafana-data.yaml


    apiVersion: v1
    kind: PersistentVolume
    metadata:
      # 设置PV名称
      name: grafana-data
      # 设置PV标签，用于PVC的定向绑定
      labels:
        app: grafana-data
    spec:
      # 设置存储类别
      storageClassName: nfs
      # 设置访问模式
      accessModes:
        - ReadWriteMany
      # 设置PV的存储空间
      capacity:
        storage: 10Gi
      # 设置PV的回收策略
      persistentVolumeReclaimPolicy: Retain
      nfs:
        path: /home/project/kubernetes/grafana
        server: 192.168.100.200
    ---
    apiVersion: v1
    kind: PersistentVolumeClaim
    metadata:
      name: grafana-data
      namespace: monitoring
    spec:
      # 设置PVC存储类别，用于指定存储类型
      storageClassName: nfs
      # 设置访问模式，匹配相同模式的PV
      accessModes:
      - ReadWriteMany
      # 设置PVC所申请存储空间的大小
      resources:
        requests:
          storage: 8Gi

### 5.2.3 部署grafana存储

    kubectl apply -f grafana-data.yaml

# 6. 配置grafana service

    vi grafana-service.yaml


    apiVersion: v1
    kind: Service
    metadata:
      labels:
        app.kubernetes.io/component: grafana
        app.kubernetes.io/name: grafana
        app.kubernetes.io/part-of: kube-prometheus
        app.kubernetes.io/version: 7.5.4
      name: grafana
      namespace: monitoring
    spec:
      #   修改为NodePort
      type: NodePort
      ports:
      - name: http
        port: 3000
        # 设置绑定节点的端口
        nodePort: 32000
        targetPort: http
      selector:
        app.kubernetes.io/component: grafana
        app.kubernetes.io/name: grafana
        app.kubernetes.io/part-of: kube-prometheus

# 7.部署Prometheus Operator

    kubectl apply -f .

# 8.验证Prometheus Operator

## 8.1 监控服务资源运行

    # pod运行
    kubectl -n monitoring get pod -o wide

    # 存储资源PVC
    kubectl -n monitoring get pvc

    # 网络资源service
    kubectl -n monitoring get svc

## 8.2 访问grafana

http://worker节点IP:32000

- 默认用户名/密码：admin/admin

## 8.3 导入监控大盘模版

Manage ---> Import ---> 模版ID：13105

# 9.配置告警

Prometheus的告警功能由Prometheus Server和AlertManager共同完成，Prometheus Server对配置的告警规则周期性的计算，将触发告警条件的规则生成告警通知并发送给AlertManager，AlertManager对告警通知进行分组、去重后再根据路由规则将其路由到不同的receiver，如Email、短信或Webhook等

## 9.1 配置邮箱告警

### 9.1.1 发送邮箱开启SMTP服务，获取登录授权码

### 9.1.2 创建AlertManager配置文件

    vi alertmanager.yaml


    global:
      # 设置告警恢复时间间隔，即告警不再继续产生的时长
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.139.com:465'
      smtp_from: 'sxs0618@139.com'
      smtp_auth_username: 'sxs0618@139.com'
      # 设置邮箱授权码
      smtp_auth_password: 'xxxxxxxxxxxx'
      smtp_hello: 'test'
      smtp_require_tls: false

    # 设置告警通知模版
    templates:
      - './*.tmpl'

    route:
      # 设置告警分组的属性依据
      group_by: ['alertname']
      # 设置告警发送前的等待时间
      group_wait: 30s
      # 设置告警发送时间间隔
      group_interval: 5m
      # 设置分组内相同告警的发送时间间隔
      repeat_interval: 12h
      # 设置告警接收者，匹配receivers配置项
      receiver: default

      # 设置子路由，即通过匹配告警规则的标签指定接收者
      # routes:
      # - receiver: email
        # group_wait: 10s
        # match:
          # severity: warning

    receivers:
    - name: default
      email_configs:
      - to: '523343553@qq.com'
        html: '{{ template "email.html" . }}'
        send_resolved: true

### 9.1.3 创建AlertManager告警模版

    mkdir template
    vi template/email.tmpl


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

### 9.1.4 更新AlertManager配置文件

    kubectl -n monitoring delete secrets alertmanager-main
    kubectl -n monitoring create secret generic alertmanager-main --from-file=alertmanager.yaml --from-file=./template/email.tmpl

### 9.1.5 验证告警

## 9.2 配置钉钉告警

### 9.2.1 钉钉群创建机器人

### 9.2.2 部署钉钉告警插件

#### 9.2.2.1 创建钉钉告警插件

    vi dingtalk-deployment.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: dingtalk
      namespace: monitoring
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: dingtalk
      template:
        metadata:
          name: dingtalk
          labels:
            app: dingtalk
        spec:
          containers:
          - name: dingtalk
            image: registry.cn-hangzhou.aliyuncs.com/kubernetess/prometheus-webhook-dingtalk:v2.1.0
            imagePullPolicy: IfNotPresent
            resources:
              limits:
                cpu: 100m
                memory: 100Mi
              requests:
                cpu: 50m
                memory: 50Mi
            ports:
            - containerPort: 8060
            volumeMounts:
            - name: config
              mountPath: /etc/prometheus-webhook-dingtalk
          volumes:
          - name: config
            configMap:
              name: dingtalk-config
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: dingtalk
      namespace: monitoring
      labels:
        app: dingtalk
      annotations:
        prometheus.io/scrape: 'false'
    spec:
      selector:
        app: dingtalk
      ports:
      - name: dingtalk
        port: 8060
        protocol: TCP
        targetPort: 8060

#### 9.2.2.2 创建钉钉告警插件配置文件

    vi dingtalk-config.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: dingtalk-config
      namespace: monitoring
    data:
      config.yml: |-
        templates:
          - /etc/prometheus-webhook-dingtalk/template.tmpl
        targets:
          webhook:
            url: https://oapi.dingtalk.com/robot/send?access_token=xxxxxxxxx
            secret: xxxxxxxxx
            mention:
              all: true
      template.tmpl: |-
        {{ define "__subject" }}[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}] {{ .GroupLabels.SortedPairs.Values | join " " }} {{ if gt (len .CommonLabels) (len .GroupLabels) }}({{ with .CommonLabels.Remove .GroupLabels.Names }}{{ .Values | join " " }}{{ end }}){{ end }}{{ end }}
        {{ define "__alertmanagerURL" }}{{ .ExternalURL }}/#/alerts?receiver={{ .Receiver }}{{ end }}

        {{ define "__text_alert_list" }}{{ range . }}
        **Labels**
        {{ range .Labels.SortedPairs }} - {{ .Name }}: {{ .Value | markdown | html }}
        {{ end }}
        **Annotations**
        {{ range .Annotations.SortedPairs }} - {{ .Name }}: {{ .Value | markdown | html }}
        {{ end }}
        **Source:** [{{ .GeneratorURL }}]({{ .GeneratorURL }})
        {{ end }}{{ end }}

        {{ define "default.__text_alert_list" }}{{ range . }}
        ---
        **告警级别:** {{ .Labels.severity | upper }}

        **运营团队:** {{ .Labels.team | upper }}

        **触发时间:** {{ dateInZone "2006.01.02 15:04:05" (.StartsAt) "Asia/Shanghai" }}

        **事件信息:**
        {{ range .Annotations.SortedPairs }} - {{ .Name }}: {{ .Value | markdown | html }}


        {{ end }}

        **事件标签:**
        {{ range .Labels.SortedPairs }}{{ if and (ne (.Name) "severity") (ne (.Name) "summary") (ne (.Name) "team") }} - {{ .Name }}: {{ .Value | markdown | html }}
        {{ end }}{{ end }}
        {{ end }}
        {{ end }}
        {{ define "default.__text_alertresovle_list" }}{{ range . }}
        ---
        **告警级别:** {{ .Labels.severity | upper }}

        **运营团队:** {{ .Labels.team | upper }}

        **触发时间:** {{ dateInZone "2006.01.02 15:04:05" (.StartsAt) "Asia/Shanghai" }}

        **结束时间:** {{ dateInZone "2006.01.02 15:04:05" (.EndsAt) "Asia/Shanghai" }}

        **事件信息:**
        {{ range .Annotations.SortedPairs }} - {{ .Name }}: {{ .Value | markdown | html }}


        {{ end }}

        **事件标签:**
        {{ range .Labels.SortedPairs }}{{ if and (ne (.Name) "severity") (ne (.Name) "summary") (ne (.Name) "team") }} - {{ .Name }}: {{ .Value | markdown | html }}
        {{ end }}{{ end }}
        {{ end }}
        {{ end }}

        {{/* Default */}}
        {{ define "default.title" }}{{ template "__subject" . }}{{ end }}
        {{ define "default.content" }}#### \[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}\] **[{{ index .GroupLabels "alertname" }}]({{ template "__alertmanagerURL" . }})**
        {{ if gt (len .Alerts.Firing) 0 -}}

        {{ template "default.__text_alert_list" .Alerts.Firing }}


        {{- end }}

        {{ if gt (len .Alerts.Resolved) 0 -}}
        {{ template "default.__text_alertresovle_list" .Alerts.Resolved }}


        {{- end }}
        {{- end }}

        {{/* Legacy */}}
        {{ define "legacy.title" }}{{ template "__subject" . }}{{ end }}
        {{ define "legacy.content" }}#### \[{{ .Status | toUpper }}{{ if eq .Status "firing" }}:{{ .Alerts.Firing | len }}{{ end }}\] **[{{ index .GroupLabels "alertname" }}]({{ template "__alertmanagerURL" . }})**
        {{ template "__text_alert_list" .Alerts.Firing }}
        {{- end }}

        {{/* Following names for compatibility */}}
        {{ define "ding.link.title" }}{{ template "default.title" . }}{{ end }}
        {{ define "ding.link.content" }}{{ template "default.content" . }}{{ end }}

#### 9.2.2.2 部署钉钉告警插件

    kubectl apply -f dingtalk-config.yaml
    kubectl apply -f dingtalk-deployment.yaml

### 9.2.3 修改alertmanager配置文件

    vi alertmanager.yaml


    global:
      # 设置告警恢复时间间隔，即告警不再继续产生的时长
      resolve_timeout: 5m
      smtp_smarthost: 'smtp.qq.com:465'
      smtp_from: '784956466@qq.com'
      smtp_auth_username: '784956466@qq.com'
      # 设置邮箱授权码
      smtp_auth_password: 'njfzkaerzhslbcfd'
      smtp_hello: 'test'
      smtp_require_tls: false

    # 设置告警通知模版
    templates:
      - './*.tmpl'

    route:
      # 设置告警分组的属性依据
      group_by: ['alertname','severity','namespace','node','job','service']
      # 设置告警发送前的等待时间
      group_wait: 30s
      # 设置告警发送时间间隔
      group_interval: 5m
      # 设置分组内相同告警的发送时间间隔
      repeat_interval: 12h
      # 设置告警接收者，匹配receivers配置项
      receiver: default

      routes:
      - receiver: webhook
        group_wait: 10s
        match:
          severity: critical

    receivers:
    - name: default
      email_configs:
      - to: '523343553@qq.com'
        html: '{{ template "email.html" . }}'
        send_resolved: true
    - name: 'webhook'
      webhook_configs:
      - url: 'http://dingtalk.monitoring.svc.cluster.local:8060/dingtalk/webhook/send'
        send_resolved: true

### 9.2.4 更新AlertManager配置文件

    kubectl -n monitoring delete secrets alertmanager-main
    kubectl -n monitoring create secret generic alertmanager-main --from-file=alertmanager.yaml --from-file=./template/email.tmpl

### 9.2.5 验证钉钉告警

--------

# 参考文档

- https://zhuanlan.zhihu.com/p/469202200
- https://www.jianshu.com/p/a55e95b09ff5
- https://www.cnblogs.com/pollos/articles/17369294.html
- https://blog.csdn.net/qq_43164571/article/details/124802412
- https://blog.csdn.net/weixin_45444133/article/details/120434811