---
title: Kubernetes集群部署EFK日志管理平台
categories:
  - 工作
tags:
  - Linux
  - Kubernetes
  - ELK
  - 云原生
  - 容器云
  - 云计算
date: 2022-12-10 10:06:21
---

EFK是Kubernetes官方推荐的的日志管理系统解决方案，通过Fluentd/Fluent Bit或Filebeat之类的节点级代理程序进行日志采集，实时推送给Elasticsearch集群进行存储和分析，而后再经由Kibana进行数据可视化，这样的组合即简称为EFK。Kubernetes二进制包即包含EFK部署所需资源，可作为参考

---------

# 1.部署nfs

# 2.部署StorageClass

# 3.创建命名空间

    kubectl create namespace logging

# 4.部署elasticsearch

## 4.1 创建elasticsearch应用资源部署文件

    vi es-statefulset.yaml


    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: es-cluster
      namespace: logging
    spec:
      serviceName: elasticsearch
      replicas: 3
      selector:
        matchLabels:
          app: elasticsearch
      template:
        metadata:
          labels:
            app: elasticsearch
        spec:
          containers:
          - name: elasticsearch
            image: elasticsearch:7.12.1
            imagePullPolicy: IfNotPresent
            resources:
              limits:
                cpu: 100m
                memory: 1Gi
              requests:
                cpu: 100m
                memory: 1Gi
            ports:
            - containerPort: 9200
              name: rest
              protocol: TCP
            - containerPort: 9300
              name: inter-node
              protocol: TCP
            volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
            env:
              - name: cluster.name
                value: k8s-logs
              - name: node.name
                valueFrom:
                  fieldRef:
                    fieldPath: metadata.name
              - name: discovery.seed_hosts
                value: "elasticsearch"
              - name: cluster.initial_master_nodes
                value: "es-cluster-0,es-cluster-1,es-cluster-2"
              - name: ES_JAVA_OPTS
                value: "-Xms2g -Xmx2g"
          initContainers:
          - name: fix-permissions
            image: busybox
            imagePullPolicy: IfNotPresent
            command: ["sh", "-c", "chown -R 1000:1000 /usr/share/elasticsearch/data"]
            securityContext:
              privileged: true
            volumeMounts:
            - name: data
              mountPath: /usr/share/elasticsearch/data
          - name: increase-vm-max-map
            image: busybox
            imagePullPolicy: IfNotPresent
            command: ["sysctl", "-w", "vm.max_map_count=262144"]
            securityContext:
              privileged: true
          - name: increase-fd-ulimit
            image: busybox
            imagePullPolicy: IfNotPresent
            command: ["sh", "-c", "ulimit -n 65536"]
            securityContext:
              privileged: true
          affinity:
            # 设置反亲和性，防止有POD被调度到同一节点
            podAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: app
                    operator: In
                    values:
                    - elasticsearch
                topologyKey: "kubernetes.io/hostname"
      # 设置持久化数据存储
      volumeClaimTemplates:
      - metadata:
          name: data
          annotations:
            volume.beta.kubernetes.io/storage-class: sc-nfs
        spec:
          accessModes: [ "ReadWriteOnce" ]
          resources:
            requests:
              storage: 10Gi

## 4.2 创建elasticsearch service资源部署文件

    vi es-service.yaml


    apiVersion: v1
    kind: Service
    metadata:
      name: elasticsearch
      namespace: logging
      labels:
        app: elasticsearch
    spec:
      selector:
        app: elasticsearch
      clusterIP: None
      ports:
        - port: 9200
          name: rest
        - port: 9300
          name: inter-node

## 4.3 部署elasticsearch

    kubectl apply -f es-service.yaml
    kubectl apply -f es-statefulset.yaml   

# 5.部署kibana

## 5.1 创建配置文件

    vi kibana.yml


    server.name: kibana
    server.host: "0"
    i18n.locale: "zh-CN"
    elasticsearch.hosts: [ "http://elasticsearch:9200" ]
    monitoring.ui.container.elasticsearch.enabled: true

## 5.2 部署配置文件

    kubectl -n logging create configmap kibana-yml --from-file=kibana.yml

## 5.3 创建kibana应用资源部署文件

    vi kibana.yaml


    apiVersion: v1
    kind: Service
    metadata:
      name: kibana
      namespace: logging
      labels:
        app: kibana
    spec:
      ports:
      - port: 5601
        nodePort: 35601
      selector:
        app: kibana
      type: NodePort
    ---
    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: kibana
      namespace: logging
      labels:
        app: kibana
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: kibana
      template:
        metadata:
          labels:
            app: kibana
        spec:
          containers:
          - name: kibana
            image:  kibana:7.12.1
            imagePullPolicy: IfNotPresent
            resources:
              limits:
                cpu: 1000m
                memory: 1Gi
              requests:
                cpu: 500m
                memory: 512Mi
            env:
              - name: ELASTICSEARCH_URL
                value: http://elasticsearch:9200
            ports:
            - containerPort: 5601
            volumeMounts:
            - name: kibana-yml
              mountPath: /usr/share/kibana/config/kibana.yml
              subPath: kibana.yml
          volumes:
          - name: kibana-yml
            configMap:
              name: kibana-yml

## 5.2 部署kibana

    kubectl apply -f kibana.yaml

# 6.部署logstash

## 6.1 创建配置文件

    vi logstash.yml


    http.host: "0.0.0.0"
    xpack.monitoring.elasticsearch.hosts: [ "http://elasticsearch:9200" ]

# 6.2 创建日志解析配置文件

    vi logstash-conf.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: logstash-conf
      namespace: logging
    data:
      logstash.conf: |-

        input {

          kafka {
            bootstrap_servers => ["kafka-0.kafka:9092,kafka-1.kafka:9092,kafka-2.kafka:9092"]
            client_id => "kubernetes"
            group_id => "kubernetes"
            auto_offset_reset => "latest"
            consumer_threads => 3
            decorate_events => false
            topics => ["sshd","nginx-access","nginx-error","container"]
            codec => "json"
            }
          }

        filter {

          if "nginx-access" in [tags] {

            grok {

              match => { "message" => "%{IPORHOST:remote_addr} - %{DATA:remote_user} \[%{HTTPDATE:access_time}\] \"%{WORD:http_method} %{DATA:url} HTTP/%{NUMBER:http_version}\" %{NUMBER:response_code} %{NUMBER:bytes_sent} %{NUMBER:body_bytes_sent} \"%{DATA:http_referer}\" \"%{DATA:http_user_agent}\" \"%{DATA:http_x_forwarded_for}\" \"%{DATA:request_time}\" \"%{DATA:upstream_response_time}\" \"%{DATA:upstream_status}\" \"%{HOSTPORT:upstream_addr}\""}

            }

            date {
              match => ["access_time", "dd/MMM/yyyy:HH:mm:ss Z"]
              remove_field => ["timestamp"]
              }

            if [http_user_agent] != "-" {
              useragent {
              target => "http_user"
              source => "http_user_agent"
              }
            }

            urldecode{
              all_fields=>true
            }

            mutate {
              convert => ["request_time", "float"]
              convert => ["upstream_response_time", "float"]
              convert => ["body_bytes_sent", "integer"]

              # 剔除掉多余字段
              remove_field => ["_id","_score","_type","message","http_user_agent","url_tmp"]
            }
          }

          if "nginx-error" in [tags] {

            grok {
              match => [ "message" , "(?<timestamp>%{YEAR}[./-]%{MONTHNUM}[./-]%{MONTHDAY}[- ]%{TIME}) \[%{LOGLEVEL:severity}\] %{POSINT:pid}#%{NUMBER}: %{GREEDYDATA:errormessage}(?:, client: (?<clientip>%{IP}|%{HOSTNAME}))(?:, server: %{IPORHOST:server}?)(?:, request: %{QS:request})?(?:, upstream: (?<upstream>\"%{URI}\"|%{QS}))?(?:, host: %{QS:request_host})?(?:, referrer: \"%{URI:referrer}\")?"]
            }

            mutate {
              convert => [ "[geoip][coordinates]", "float"]
              remove_field => ["timestamp","message","_id","_score","_type"]
            }
          }

          if "sshd" in [tags] {

            grok {
              match => {"message" => ".*sshd\[\d+\]: %{WORD:status} .* %{USER:username} from.*%{IP:clientip}.*"}
            }

            if [message] !~ "Accepted | Invalid | Failed" {

              drop {}
            }

            mutate {

              convert => [ "[geoip][coordinates]", "float"]
              remove_field => ["timestamp","message","_id","_score","_type"]
            }

          }

          if "container" in [tags] {

            mutate {
              remove_field => ["log","agent","ecs","containers","host","container"]
            }
          }

          if "_geoip_lookup_failure" in [tags] { drop { } }

        }

        output{

          if "nginx-access" in [tags] {
            elasticsearch{
              hosts => ["elasticsearch:9200"]
              index => "logstash-nginx-access-%{+YYYY.MM.dd}"
            }
          }

          if "nginx-error" in [tags] {
            elasticsearch{
              hosts => ["elasticsearch:9200"]
              index => "logstash-nginx-error-%{+YYYY.MM.dd}"
            }
          }

          if "sshd" in [tags] {
            elasticsearch{
              hosts => ["elasticsearch:9200"]
              index => "logstash-sshd-%{+YYYY.MM.dd}"
            }
          }

          if "container" in [tags] {
            elasticsearch{
              hosts => ["elasticsearch:9200"]
              index => "logstash-container-%{+YYYY.MM.dd}"
            }
          }

        # stdout { codec => rubydebug }

        }

## 6.3 创建logstash应用资源部署文件

    vi logstash.yaml


    apiVersion: apps/v1
    kind: Deployment
    metadata:
      name: logstash-deployment
      namespace: logging
    spec:
      replicas: 1
      selector:
        matchLabels:
          app: logstash
      template:
        metadata:
          labels:
            app: logstash
        spec:
          containers:
          - name: logstash
            image: registry.cn-hangzhou.aliyuncs.com/swords/logstash:v7.12.1
            imagePullPolicy: IfNotPresent
            env:
            - name: ES_JAVA_OPTS
              value: "-Xms512m -Xmx512m"
            - name: TZ
              value: Asia/Shanghai
            ports:
            - name: logport
              containerPort: 5044
              protocol: TCP
            command: ["logstash","-f","/usr/share/logstash/config/logstash.conf"]
            resources:
              limits:
                cpu: 1000m
                memory: 8192Mi
              requests:
                cpu: 100m
                memory: 200Mi
            volumeMounts:
            - name: logstash-conf
              mountPath: /usr/share/logstash/config/logstash.conf
              subPath: logstash.conf
            - name: timezone
              mountPath: /etc/localtime
            - name: logstash-yml
              mountPath: /usr/share/logstash/config/logstash.yml
              subPath: logstash.yml
          volumes:
          - name: logstash-conf
            configMap:
              name: logstash-conf
          - name: timezone
            hostPath:
              path: /etc/localtime
          - name: logstash-yml
            configMap:
              name: logstash-yml

# 6.4 部署logstash

    kubectl apply -f logstash-conf.yaml
    kubectl -n logging create configmap logstash-yml --from-file=logstash.yml
    kubectl apply -f logstash.yaml
   
# 7.部署kafka集群

# 8.部署日志采集程序

## 8.1 部署fluentd

### 8.1.1 创建配置文件

    vi fluentd-es-configmap.yaml


    kind: ConfigMap
    apiVersion: v1
    metadata:
      name: fluentd-config
      namespace: logging
    data:
      system.conf: |-
        <system>
          root_dir /tmp/fluentd-buffers/
        </system>
      containers.input.conf: |-
        <source>
          @id fluentd-containers.log
          @type tail                              # Fluentd 内置的输入方式，其原理是不停地从源文件中获取新的日志。
          path /var/log/containers/*.log          # 挂载的服务器Docker容器日志地址
          pos_file /var/log/es-containers.log.pos
          tag raw.kubernetes.*                    # 设置日志标签
          read_from_head true
          <parse>                                 # 多行格式化成JSON
            @type multi_format                    # 使用 multi-format-parser 解析器插件
            <pattern>
              format json                         # JSON解析器
              time_key time                       # 指定事件时间的时间字段
              time_format %Y-%m-%dT%H:%M:%S.%NZ   # 时间格式
            </pattern>
            <pattern>
              format /^(?<time>.+) (?<stream>stdout|stderr) [^ ]* (?<log>.*)$/
              time_format %Y-%m-%dT%H:%M:%S.%N%:z
            </pattern>
          </parse>
        </source>


        <match raw.kubernetes.**>           # 匹配tag为raw.kubernetes.**日志信息
          @id raw.kubernetes
          @type detect_exceptions           # 使用detect-exceptions插件处理异常栈信息
          remove_tag_prefix raw             # 移除 raw 前缀
          message log
          stream stream
          multiline_flush_interval 5
          max_bytes 500000
          max_lines 1000
        </match>

        <filter **>  # 拼接日志
          @id filter_concat
          @type concat                # Fluentd Filter 插件，用于连接多个事件中分隔的多行日志。
          key message
          multiline_end_regexp /\n$/  # 以换行符“\n”拼接
          separator ""
        </filter>


        <filter kubernetes.**>
          @id filter_kubernetes_metadata
          @type kubernetes_metadata
        </filter>


        <filter kubernetes.**>
          @id filter_parser
          @type parser                # multi-format-parser多格式解析器插件
          key_name log                # 在要解析的记录中指定字段名称。
          reserve_data true           # 在解析结果中保留原始键值对。
          remove_key_name_field true  # key_name 解析成功后删除字段。
          <parse>
            @type multi_format
            <pattern>
              format json
            </pattern>
            <pattern>
              format none
            </pattern>
          </parse>
        </filter>

        <filter kubernetes.**>
          @type record_transformer
          remove_keys $.docker.container_id,$.kubernetes.container_image_id,$.kubernetes.pod_id,$.kubernetes.namespace_id,$.kubernetes.master_url,$.kubernetes.labels.pod-template-hash
        </filter>


      #  <filter kubernetes.**>
      #    @id filter_log
      #    @type grep
      #    <regexp>
      #      key $.kubernetes.labels.logging
      #      pattern ^true$
      #    </regexp>
      #  </filter>

      forward.input.conf: |-
        <source>
          @id forward
          @type forward
        </source>

      output.conf: |-
        <match **>
          @id elasticsearch
          @type elasticsearch
          @log_level info
          include_tag_key true
          host 192.168.100.158
          port 9200
          logstash_format true
          logstash_prefix logstash-kubernetes  # 设置 index 前缀为 k8s
          request_timeout    30s
          <buffer>
            @type file
            path /var/log/fluentd-buffers/kubernetes.system.buffer
            flush_mode interval
            retry_type exponential_backoff
            flush_thread_count 2
            flush_interval 5s
            retry_forever
            retry_max_interval 30
            chunk_limit_size 2M
            queue_limit_length 8
            overflow_action block
          </buffer>
        </match>

### 8.1.2 创建fluentd应用资源部署文件

    vi fluentd.yaml


    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: fluentd-es
      namespace: logging
      labels:
        k8s-app: fluentd-es
        kubernetes.io/cluster-service: "true"
        addonmanager.kubernetes.io/mode: Reconcile
    ---
    kind: ClusterRole
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: fluentd-es
      labels:
        k8s-app: fluentd-es
        kubernetes.io/cluster-service: "true"
        addonmanager.kubernetes.io/mode: Reconcile
    rules:
    - apiGroups:
      - ""
      resources:
      - "namespaces"
      - "pods"
      verbs:
      - "get"
      - "watch"
      - "list"
    ---
    kind: ClusterRoleBinding
    apiVersion: rbac.authorization.k8s.io/v1
    metadata:
      name: fluentd-es
      labels:
        k8s-app: fluentd-es
        kubernetes.io/cluster-service: "true"
        addonmanager.kubernetes.io/mode: Reconcile
    subjects:
    - kind: ServiceAccount
      name: fluentd-es
      namespace: logging
      apiGroup: ""
    roleRef:
      kind: ClusterRole
      name: fluentd-es
      apiGroup: ""
    ---
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: fluentd-es
      namespace: logging
      labels:
        k8s-app: fluentd-es
        kubernetes.io/cluster-service: "true"
        addonmanager.kubernetes.io/mode: Reconcile
    spec:
      selector:
        matchLabels:
          k8s-app: fluentd-es
      template:
        metadata:
          labels:
            k8s-app: fluentd-es
            kubernetes.io/cluster-service: "true"
          annotations:
            scheduler.alpha.kubernetes.io/critical-pod: ''
        spec:
          serviceAccountName: fluentd-es
          containers:
          - name: fluentd-es
            image: quay.io/fluentd_elasticsearch/fluentd:v3.1.0
            env:
            - name: FLUENTD_ARGS
              value: --no-supervisor -q
            resources:
              limits:
                memory: 500Mi
              requests:
                cpu: 100m
                memory: 200Mi
            volumeMounts:
            - name: varlog
              mountPath: /var/log
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
              readOnly: true
            - name: config-volume
              mountPath: /etc/fluent/config.d
          # nodeSelector:
          # beta.kubernetes.io/fluentd-ds-ready: "true"
          tolerations:
          - operator: Exists
          terminationGracePeriodSeconds: 30
          volumes:
          - name: varlog
            hostPath:
              path: /var/log
          - name: varlibdockercontainers
            hostPath:
              path: /var/lib/docker/containers
          - name: config-volume
            configMap:
              name: fluentd-config

### 8.1.3 部署fluentd

    kubectl apply -f fluentd-es-configmap.yaml 
    kubectl apply -f fluentd.yaml

## 8.2 部署filebeat

### 8.2.1 创建配置文件

    vi filebeat-configmap.yaml


    apiVersion: v1
    kind: ConfigMap
    metadata:
      name: filebeat-conf
      namespace: logging
    data:
      filebeat.yml: |-
        filebeat.inputs:

          - type: log
            enabled: true
            paths:
              - /var/log/nginx/*access.log
            tags: ["nginx-access"]
            fields_under_root: true
            fields:
              log_topic: nginx-access

          - type: log
            enabled: true
            paths:
              - /var/log/nginx/*error.log
            tags: ["nginx-error"]
            fields_under_root: true
            fields:
              log_topic: nginx-error

          - type: log
            enabled: true
            paths:
              - /var/log/auth.log
            tags: ["sshd"]
            fields_under_root: true
            fields:
              log_topic: sshd

          - type: log
            enabled: true
            paths:
              - /var/log/containers/*.log
            tags: ["container"]
            symlinks: true
            fields_under_root: true
            fields:
              log_topic: container

        output.kafka: 
          hosts: ["kafka-0.kafka:9092","kafka-1.kafka:9092","kafka-2.kafka:9092"]
          topic: '%{[log_topic]}'
          partition.round_robin:
            reachable_only: false
          required_acks: 1
          compression: gzip
          max_message_bytes: 1000000

### 8.2.2 创建filebeat部署文件

    vi filebeat.yaml


    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: filebeat
      namespace: logging
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: filebeat
      labels:
        app: filebeat-clsterrole
    rules:
    - apiGroups:
      - ""
      resources:
      - nodes
      - events
      - namespaces
      - pods
      verbs:
      - get
      - watch
      - list
    - apiGroups:
      - ""
      resourceNames:
      - filebeat-prospectors
      resources:
      - configmaps
      verbs:
      - get
      - update
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: filebeat
      labels:
        app: filebeat-clusterrolebinding
    roleRef:
      apiGroup: ""
      kind: ClusterRole
      name: filebeat
    subjects:
    - apiGroup: ""
      kind: ServiceAccount
      name: filebeat
      namespace: logging
    ---
    apiVersion: apps/v1
    kind: DaemonSet
    metadata:
      name: filebeat
      namespace: logging
      labels:
        k8s-app: filebeat
    spec:
      selector:
        matchLabels:
          k8s-app: filebeat
      template:
        metadata:
          labels:
            k8s-app: filebeat
        spec:
          serviceAccountName: filebeat
          terminationGracePeriodSeconds: 30
          containers:
          - name: filebeat
            image: registry.cn-hangzhou.aliyuncs.com/swords/filebeat:7.12.1
            imagePullPolicy: IfNotPresent
            args: [
              "-c", "/etc/filebeat.yml",
              "-e",
            ]
            env:
            - name: NODE_NAME
              valueFrom:
                fieldRef:
                  fieldPath: spec.nodeName
            securityContext:
              runAsUser: 0
            resources:
              limits:
                cpu: 1000m
                memory: 1000Mi
              requests:
                cpu: 100m
                memory: 100Mi
            volumeMounts:
            - name: config
              mountPath: /etc/filebeat.yml
              readOnly: true
              subPath: filebeat.yml
            - name: data
              mountPath: /usr/share/filebeat/data
            - name: dockerlog
              mountPath: /home/docker/docker/containers
            - name: varlog
              mountPath: /var/log/
              readOnly: true
            - name: timezone
              mountPath: /etc/localtime
            - name: varlibdockercontainers
              mountPath: /var/lib/docker/containers
          tolerations:
          - operator: Exists
          volumes:
          - name: config
            configMap:
              defaultMode: 0644
              name: filebeat-conf
          - name: dockerlog
            hostPath:
              path: /var/log/containers/
          - name: varlog
            hostPath:
              path: /var/log/
          - name: data
            hostPath:
              path: /var/log/filebeat
              type: DirectoryOrCreate
          - name: timezone
            hostPath:
              path: /etc/localtime
          - name: varlibdockercontainers
            hostPath:
              path: /var/lib/docker/containers

### 8.2.3 部署filebeat

    kubectl apply -f filebeat-configmap.yaml
    kubectl apply -f filebeat.yaml

# 9.验证EFK资源

---------

# 参考文档

- https://i4t.com/4951.html
- https://www.cnblogs.com/99jianshao/p/15024955.html
- https://blog.csdn.net/heian_99/article/details/123405383

- https://blog.csdn.net/filtercomp/article/details/127125138
- https://blog.csdn.net/qq_45887180/article/details/122431406

- https://github.com/kubernetes/kubernetes/tree/release-1.20/cluster/addons/fluentd-elasticsearch
- https://github.com/opsnull/follow-me-install-kubernetes-cluster/blob/master/08-5.EFK%E6%8F%92%E4%BB%B6.md