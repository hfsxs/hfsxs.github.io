---
title: Prometheus监控Kubernetes集群
categories:
  - 工作
tags:
  - Linux
  - Prometheus
  - Docker
  - Kubernetes
  - 容器
  - 监控告警
  - 云原生
  - 云计算
date: 2024-05-10 14:59:01
---

Prometheus监控Kubernetes集群可通过kube-prometheus方式部署于集群内部，也方便直接调用集群内的认证证书及暴露的监控地址，但将会增加集群的资源开销，也不利于业务的稳定。因此，可以将Prometheus部署于Kubernetes集群之外，也便于监控的集中管理。此时，涉及到的监控指标主要分为三类，即Node节点性能指标（节点CPU、内存、磁盘及网络性能）、Pod及容器资源性能指标（容器CPU及内存利用率）和Kubernetes集群资源性能指标（controller-manager、kube-scheduler、kube-proxy、Pod、Deployment、Service等状态），具体如下：

- Node节点监控指标，由节点上部署的node_exporter进行暴露
- Pod及容器资源监控指标，由集群组件kubelet内置的cAdvisor（开源的分析容器资源使用率和性能的代理工具）进行暴露，通过kubelet/metrics/cadvisor接口自动采集节点上所运行容器的CPU、内存、文件系统和网络资源的统计信息，无需做其他配置
- Kubernetes集群资源监控指标，则由kube-state-metrics服务进行暴露，通过监听Kubernetes集群ApiServer生成不同资源的状态的Metrics数据，其中8080端口用于暴露Kubernetes集群指标数据，8081端口用于暴露kube-state-metrics服务的指标数据
- service-endpoints，通过service的annotation中的相应信息实现

# 1.创建集群外部访问凭证

## 1.1 创建RBAC资源文件

    vi promethues-rbac.yaml


    apiVersion: v1
    kind: ServiceAccount
    metadata:
      name: prometheus
      namespace: kube-system
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRole
    metadata:
      name: prometheus
    rules:
    - apiGroups:
      - ""
      resources:
      - nodes
      - services
      - endpoints
      - pods
      - nodes/proxy
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - "extensions"
      resources:
        - ingresses
      verbs:
      - get
      - list
      - watch
    - apiGroups:
      - ""
      resources:
      - configmaps
      - nodes/metrics
      verbs:
      - get
    - nonResourceURLs:
      - /metrics
      verbs:
      - get
    ---
    apiVersion: rbac.authorization.k8s.io/v1
    kind: ClusterRoleBinding
    metadata:
      name: prometheus
    roleRef:
      apiGroup: rbac.authorization.k8s.io
      kind: ClusterRole
      name: prometheus
    subjects:
    - kind: ServiceAccount
      name: prometheus
      namespace: kube-system

## 1.2 创建RBAC

    kubectl apply -f promethues-rbac.yaml 

## 1.3 创建外部访问凭证

    kubectl -n kube-system describe secrets prometheus-token-5stl8 | grep token
    vi token.kubernetes


    eyJhbGciOiJSUzI1NiIsImtpZCI6InFhd0Q4b2VONWZaTV9fcXBUa1J6dGZZaE83WDhCNG44Uno0QWh3UnpkdTAifQ.eyJpc3MiOiJrdWJlcm5ldGVzL3NlcnZpY2VhY2NvdW50Iiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9uYW1lc3BhY2UiOiJrdWJlLXN5c3RlbSIsImt1YmVybmV0ZXMuaW8vc2VydmljZWFjY291bnQvc2VjcmV0Lm5hbWUiOiJwcm9tZXRoZXVzLXRva2VuLWxuNXpiIiwia3ViZXJuZXRlcy5pby9zZXJ2aWNlYWNjb3VudC9zZXJ2aWNlLWFjY291bnQubmFtZSI6InByb21ldGhldXMiLCJrdWJlcm5ldGVzLmlvL3NlcnZpY2VhY2NvdW50L3NlcnZpY2UtYWNjb3VudC51aWQiOiI5NjZlMjdhYy04MWZjLTQ0MTQtODVkOS0xMmJiOWQ0YTI3N2YiLCJzdWIiOiJzeXN0ZW06c2VydmljZWFjY291bnQ6a3ViZS1zeXN0ZW06cHJvbWV0aGV1cyJ9.dWeO5OpjI4EewpDeicF6i-DwaYWPL8pwsmXEc8ZZm-OM15KjwZXzFpYIhnkvXPpA38HZOBpNg7gfQewTNZbQdhTrBCLX9UQgGYLzkEnxoxy8VAC0QHGs8tGsSC2dQVhVkwL_Xkgtse9V7ArNHDgfoG_78W3TNjEoDExRtrkUi0pEAFazWWnL9sGm-P1bF6S5iw0mFIydpz8ul4csMvHVYW51iegRHHoLdtdL4o5ys5QIvFGpfJal2JRayRn4IbtlvY-k7b4wSPEBrfZlX0v1_hpk7jPcYek7w9G665A_PeoqSN_OvgyCY9A_FZNDpFek2uH4Jm2gu5vPwSxJp1SJQA

## 1.4 将访问凭证发送到Prometheus服务器

    scp token.kubernetes node01:/usr/local/prometheus

# 2.Kubernetes集群部署kube-state-metrics

## 2.1 部署kube-state-metrics

    curl -o kube-state-metrics-2.0.0.tar.gz https://github.com/kubernetes/kube-state-metrics/archive/refs/tags/v2.0.0.tar.gz
    tar -xzvf kube-state-metrics-2.0.0.tar.gz && cd kube-state-metrics-2.0.0/examples/standard
    kubectl apply -f .

# 3.Node节点监控配置

node_exporter可安装在集群内或集群外，集群内即以DaemonSet方式进行部署

    - job_name: kubernetes-nodes
      scheme: http 
      tls_config: 
        insecure_skip_verify: true 
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      kubernetes_sd_configs: 
      - role: node 
        api_server: https://172.18.100.100:8443 
        tls_config: 
          insecure_skip_verify: true 
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs: 
        - source_labels: [__address__] 
          regex: (.*):10250
          replacement: ${1}:9100
          target_label: __address__ 
          action: replace 
        - action: labelmap 
          regex: __meta_kubernetes_node_label_(.+)

# 4.集群组件监控配置

## 4.1 api-server监控配置

api-server的service部署于default命名空间，标签为component=apiserver，访问方式为https，端口为6443，因此配置基于service的endpoints服务发现即可

    - job_name: apiserver
      kubernetes_sd_configs: 
      - role: endpoints
        api_server: https://172.18.100.100:8443
        tls_config: 
          insecure_skip_verify: true
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      scheme: https 
      tls_config: 
        insecure_skip_verify: true 
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - source_labels: [__meta_kubernetes_namespace,__meta_kubernetes_service_name]
        action: keep
        regex: default;kubernetes
      - source_labels: [__meta_kubernetes_endpoints_name]
        action: replace
        target_label: endpoint
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: service
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace

## 4.2 controller-manager监控配置

kube-controller-manager部署于kube-system命名空间，标签为component=kube-controller-manager，默认没有配置service

### 4.2.1 创建service

    vi kube-controller-manager-service.yaml


    apiVersion: v1
    kind: Service
    metadata:
      labels:
        k8s-app: kube-controller-manager
      name: kube-controller-manager
      namespace: kube-system
    spec:
      selector:
        component: kube-controller-manager
      type: ClusterIP
      clusterIP: None
      ports:
      - name: https-metrics
        port: 10252
        targetPort: 10252
        protocol: TCP

### 4.2.2 配置监控端口

    sudo vi /etc/kubernetes/manifests/kube-controller-manager.yaml

    
    # 设置端口绑定，允许外部访问
    --bind-address=0.0.0.0
    # 设置监控端口，默认为0，表示开启https监控端口10257，此处配置文件http监控端口10252
    --port=10252

### 4.2.3 配置Prometheus

    - job_name: kubernetes-controller-manager
      kubernetes_sd_configs:
      - role: pod
        api_server: https://172.18.100.100:8443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      scheme: https
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_component]
        regex: kube-controller-manager
        action: keep
      - source_labels: [__meta_kubernetes_pod_ip]
        regex: (.+)
        target_label: __address__
        replacement: ${1}:10252
      - source_labels: [__meta_kubernetes_endpoints_name]
        action: replace
        target_label: endpoint
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: service
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace

## 4.3 scheduler监控配置

kube-scheduler部署于kube-system命名空间，匹配Pod对象，标签为component=kube-scheduler，默认没有配置service

### 4.3.1 创建service

    vi kube-scheduler.yaml


    apiVersion: v1
    kind: Service
    metadata:
      namespace: kube-system
      name: kube-scheduler
      labels:
        k8s-app: kube-scheduler
    spec:
      selector:
        component: kube-scheduler
      type: ClusterIP
      clusterIP: None
      ports:
      - name: http-metrics
        port: 10251
        targetPort: 10251
        protocol: TCP

### 4.3.2 配置监控端口

    sudo vi /etc/kubernetes/manifests/kube-scheduler.yaml


    # 设置端口绑定，允许外部访问
    --bind-address=0.0.0.0
    # 设置监控端口，默认为0，表示开启https监控端口10259，此处配置文件http监控端口10251
    --port=10251

### 4.3.3 配置Prometheus

    - job_name: kubernetes-scheduler
      kubernetes_sd_configs:
      - role: pod
        api_server: https://172.18.100.100:8443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      scheme: https
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - source_labels: [__meta_kubernetes_pod_label_component]
        regex: kube-scheduler
        action: keep
      - source_labels: [__meta_kubernetes_pod_ip]
        regex: (.+)
        target_label: __address__
        replacement: ${1}:10251
      - source_labels: [__meta_kubernetes_endpoints_name]
        action: replace
        target_label: endpoint
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: service
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace

## 4.4 kubelet监控配置

kubelet组件集成cAdvisor，通过/metrics/cadvisor端点暴露容器性能指标，也可通过/metrics端点暴露监控指标，端口为10250，role为node

    - job_name: kubernetes-kubelet
      metrics_path: /metrics/cadvisor
      scheme: https
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      kubernetes_sd_configs:
      - role: node
        api_server: https://172.18.100.100:8443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - action: labelmap
        regex: __meta_kubernetes_node_label_(.+)
      - source_labels: [__meta_kubernetes_endpoints_name]
        action: replace
        target_label: endpoint
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace
      - source_labels: [__meta_kubernetes_node_address_Hostname]
        action: replace
        target_label: node

## 4.5 proxy监控配置

kube-proxy组件http监控端口为10249，通过/metrics暴露监控指标，监控role为endpoints

### 4.5.1 配置监控端口

    kubectl -n kube-system edit configmap kube-proxy


    # 设置监控端口，允许外部访问
    metricsBindAddress: 0.0.0.0:10249

- 注：需要重启组件才能生效，kubectl get pods -n kube-system | grep kube-proxy |awk '{print $1}' | xargs kubectl delete pods -n kube-system

### 4.5.2 创建service

    sudo vi kube-proxy-service.yaml


    apiVersion: v1
    kind: Service
    metadata:
      labels:
        k8s-app: kube-proxy
      name: kube-proxy
      namespace: kube-system
    spec:
      selector:
        k8s-app: kube-proxy
      type: ClusterIP
      clusterIP: None
      ports:
      - name: https-metrics
        port: 10249
        targetPort: 10249
        protocol: TCP

### 4.5.2 配置Prometheus

    - job_name: kubernetes-proxy
      kubernetes_sd_configs:
      - role: endpoints
        api_server: https://172.18.100.100:8443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      scheme: http
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_name]
        regex: kube-proxy
        action: keep
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)

## 4.6 Etcd监控配置

Etcd启动参数--listen-metrics-url用于指定监控端口与协议，即通过http协议的2381端口对外暴露，且访问地址为本地。因此，需要先修改监控端口的绑定地址为0.0.0.0，才能与Promethues通信

    - job_name: kubernetes-etcd
      scheme: https
      tls_config:
        ca_file: /etc/kubernetes/pki/etcd/ca.crt
        cert_file: /etc/kubernetes/pki/etcd/server.crt
        key_file: /etc/kubernetes/pki/etcd/server.key
      scrape_interval: 5s
      static_configs:
      - targets: ['172.18.100.101:2379']
      - targets: ['172.18.100.102:2379']
      - targets: ['172.18.100.103:2379']

---------

    - job_name: etcd
      kubernetes_sd_configs:
      - role: pod
      relabel_configs:
      - source_labels:
          - __meta_kubernetes_pod_label_component
        regex: etcd
        action: keep
      - source_labels: [__meta_kubernetes_pod_ip]
        regex: (.+)
        target_label: __address__
        replacement: ${1}:2381
      - source_labels: [__meta_kubernetes_endpoints_name]
        action: replace
        target_label: endpoint
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace

# 5.集群资源监控配置

## 5.1 Pod及容器监控配置

    - job_name: kubernetes-pods 
      scheme: https
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      kubernetes_sd_configs: 
      - role: pod 
        api_server: https://172.18.100.100:8443
        tls_config: 
          insecure_skip_verify: true 
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs: 
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_path]
        action: replace
        target_label: __metrics_path__
        regex: (.+)
      - source_labels: [__address__, __meta_kubernetes_pod_annotation_prometheus_io_port]
        action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_pod_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: kubernetes_pod_name

## 5.2 Services后端Endpoint监控配置

    - job_name: kubernetes-service-endpoints
      kubernetes_sd_configs:
      - role: endpoints
        api_server: https://172.18.100.100:8443
        bearer_token_file: /usr/local/prometheus/token.kubernetes
        tls_config:
          insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      tls_config:
        insecure_skip_verify: true
      relabel_configs:
      - action: keep
        regex: true
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scrape
      - action: replace
        regex: (https?)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_scheme
        target_label: __scheme__
      - action: replace
        regex: (.+)
        source_labels:
        - __meta_kubernetes_service_annotation_prometheus_io_path
        target_label: __metrics_path__
      - action: replace
        regex: ([^:]+)(?::\d+)?;(\d+)
        replacement: $1:$2
        source_labels:
        - __address__
        - __meta_kubernetes_service_annotation_prometheus_io_port
        target_label: __address__
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels:
        - __meta_kubernetes_namespace
        target_label: kubernetes_namespace
      - action: replace
        source_labels:
        - __meta_kubernetes_service_name
        target_label: kubernetes_service_name

## 5.3 CoreDNS监控配置

CoreDNS组件通过service暴露9153监控端口，监控接口为/metrics

    - job_name: kubernetes-coredns
      kubernetes_sd_configs:
      - role: endpoints
        api_server: https://172.18.100.100:8443
        tls_config:
          insecure_skip_verify: true
        bearer_token_file: /usr/local/prometheus/token.kubernetes
      scheme: http
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - source_labels:
          - __meta_kubernetes_service_label_k8s_app
        regex: kube-dns
        action: keep
      - source_labels: [__meta_kubernetes_pod_ip]
        regex: (.+)
        target_label: __address__
        replacement: ${1}:9153
      - source_labels: [__meta_kubernetes_endpoints_name]
        action: replace
        target_label: endpoint
      - source_labels: [__meta_kubernetes_pod_name]
        action: replace
        target_label: pod
      - source_labels: [__meta_kubernetes_service_name]
        action: replace
        target_label: service
      - source_labels: [__meta_kubernetes_namespace]
        action: replace
        target_label: namespace

## 5.4 Service监控配置

    - job_name: "kubernetes-services"
      kubernetes_sd_configs:
      - role: service
      metrics_path: /probe
      params:
        module: [http_2xx]
      relabel_configs:
      - source_labels: [__meta_kubernetes_service_annotation_prometheus_io_probe]
        action: keep
        regex: true
      - source_labels: [__address__]
        target_label: __param_target
      - target_label: __address__
        replacement: blackbox-exporter.example.com:9115
      - source_labels: [__param_target]
        target_label: instance
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_service_name]
        target_label: kubernetes_name

## 5.5 Ingress监控配置

    - job_name: "kubernetes-ingresses"
      kubernetes_sd_configs:
      - role: ingress
      relabel_configs:
      - source_labels: [__meta_kubernetes_ingress_annotation_prometheus_io_probe]
        action: keep
        regex: true
      - source_labels: [__meta_kubernetes_ingress_scheme,__address__,__meta_kubernetes_ingress_path]
        regex: (.+);(.+);(.+)
        replacement: ${1}://${2}${3}
        target_label: __param_target
      - target_label: __address__
        replacement: blackbox-exporter.example.com:9115
      - source_labels: [__param_target]
        target_label: instance
      - action: labelmap
        regex: __meta_kubernetes_ingress_label_(.+)
      - source_labels: [__meta_kubernetes_namespace]
        target_label: kubernetes_namespace
      - source_labels: [__meta_kubernetes_ingress_name]
        target_label: kubernetes_name

## 5.6 kube-state-metrics监控配置

    - job_name: kubernetes-state-metrics
      scheme: http
      kubernetes_sd_configs:
      - api_server: https://172.18.100.100:8443
        role: endpoints
        namespaces:
          names: kube-system
        bearer_token_file: /usr/local/prometheus/token.kubernetes
        tls_config:
          insecure_skip_verify: true
      tls_config:
        insecure_skip_verify: true
      bearer_token_file: /usr/local/prometheus/token.kubernetes
      relabel_configs:
      - action: keep
        source_labels: [__meta_kubernetes_service_label_app_kubernetes_io_name]
        regex: kube-state-metrics
      - action: labelmap
        regex: __meta_kubernetes_service_label_(.+)
      - action: replace
        source_labels: [__meta_kubernetes_namespace]
        target_label: kubernetes_namespace
      - action: replace
        source_labels: [__meta_kubernetes_service_name]
        target_label: kubernetes_service_name

# 6.配置告警规则

    sudo vi /usr/local/prometheus/rules/kubernetes.yml


    groups:
    - name: kubernetes-system
      rules:
      - alert: KubeVersionMismatch
        annotations:
          description: There are {{ $value }} different semantic versions of Kubernetes components running.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeversionmismatch
          summary: Different semantic versions of Kubernetes components running.
        expr: |
          count(count by (git_version) (label_replace(kubernetes_build_info{job!~"kube-dns|coredns"},"git_version","$1","git_version","(v[0-9]*.[0-9]*).*"))) > 1
        for: 15m
        labels:
          severity: Warning
      - alert: KubeClientErrors
        annotations:
          description: Kubernetes API server client '{{ $labels.job }}/{{ $labels.instance }}' is experiencing {{ $value | humanizePercentage }} errors.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeclienterrors
          summary: Kubernetes API server client is experiencing errors.
        expr: |
          (sum(rate(rest_client_requests_total{code=~"5.."}[5m])) by (instance, job)
          /
          sum(rate(rest_client_requests_total[5m])) by (instance, job))
          > 0.01
        for: 15m
        labels:
          severity: Warning

    - name: kubernetes-apiserver
      rules:
      - alert: KubeClientCertificateExpiration
        annotations:
          description: A client certificate used to authenticate to the apiserver is expiring in less than 7.0 days.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeclientcertificateexpiration
          summary: Client certificate is about to expire.
        expr: apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 604800
        labels:
          severity: Warning
      - alert: KubeClientCertificateExpiration
        annotations:
          description: A client certificate used to authenticate to the apiserver is expiring in less than 24.0 hours.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeclientcertificateexpiration
          summary: Client certificate is about to expire.
      expr: |
        apiserver_client_certificate_expiration_seconds_count{job="apiserver"} > 0 and on(job) histogram_quantile(0.01, sum by (job, le) (rate(apiserver_client_certificate_expiration_seconds_bucket{job="apiserver"}[5m]))) < 86400
      labels:
        severity: critical
    - alert: AggregatedAPIErrors
      annotations:
        description: An aggregated API {{ $labels.name }}/{{ $labels.namespace }} has reported errors. It has appeared unavailable {{ $value | humanize }} times averaged over the past 10m.
        runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/aggregatedapierrors
        summary: An aggregated API has reported errors.
      expr: |
        sum by(name, namespace)(increase(aggregator_unavailable_apiservice_total[10m])) > 4
      labels:
        severity: warning
    - alert: AggregatedAPIDown
      annotations:
        description: An aggregated API {{ $labels.name }}/{{ $labels.namespace }} has been only {{ $value | humanize }}% available over the last 10m.
        runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/aggregatedapidown
        summary: An aggregated API is down.
      expr: |
        (1 - max by(name, namespace)(avg_over_time(aggregator_unavailable_apiservice[10m]))) * 100 < 85
      for: 5m
      labels:
        severity: warning
    - alert: KubeAPIDown
      annotations:
        description: KubeAPI has disappeared from Prometheus target discovery.
        runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeapidown
        summary: Target disappeared from Prometheus target discovery.
      expr: |
        absent(up{job="apiserver"} == 1)
      for: 15m
      labels:
        severity: critical
    - alert: KubeAPITerminatedRequests
      annotations:
        description: The apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests.
        runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeapiterminatedrequests
        summary: The apiserver has terminated {{ $value | humanizePercentage }} of its incoming requests.
      expr: |
        sum(rate(apiserver_request_terminations_total{job="apiserver"}[10m]))  / (  sum(rate(apiserver_request_total{job="apiserver"}[10m])) + sum(rate(apiserver_request_terminations_total{job="apiserver"}[10m])) ) > 0.20
      for: 5m
      labels:
        severity: warning

    - name: kube-apiserver-slos
      rules:
      - alert: KubeAPIErrorBudgetBurn
        annotations:
          description: The API server is burning too much error budget.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeapierrorbudgetburn
          summary: The API server is burning too much error budget.
        expr: sum(apiserver_request:burnrate1h) > (14.40 * 0.01000) and sum(apiserver_request:burnrate5m) > (14.40 * 0.01000)
        for: 2m
        labels:
          long: 1h
          severity: critical
          short: 5m
      - alert: KubeAPIErrorBudgetBurn
        annotations:
          description: The API server is burning too much error budget.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeapierrorbudgetburn
          summary: The API server is burning too much error budget.
        expr: sum(apiserver_request:burnrate6h) > (6.00 * 0.01000) and sum(apiserver_request:burnrate30m) > (6.00 * 0.01000)
        for: 15m
        labels:
          long: 6h
          severity: critical
          short: 30m
      - alert: KubeAPIErrorBudgetBurn
        annotations:
          description: The API server is burning too much error budget.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeapierrorbudgetburn
          summary: The API server is burning too much error budget.
        expr: sum(apiserver_request:burnrate1d) > (3.00 * 0.01000) and sum(apiserver_request:burnrate2h) > (3.00 * 0.01000)
        for: 1h
        labels:
          long: 1d
          severity: warning
          short: 2h
      - alert: KubeAPIErrorBudgetBurn
        annotations:
          description: The API server is burning too much error budget.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeapierrorbudgetburn
          summary: The API server is burning too much error budget.
        expr: sum(apiserver_request:burnrate3d) > (1.00 * 0.01000) and sum(apiserver_request:burnrate6h) > (1.00 * 0.01000)
        for: 3h
        labels:
          long: 3d
          severity: warning
          short: 6h

    - name: kubernetes-scheduler
      rules:
      - alert: KubeSchedulerDown
        annotations:
          description: KubeScheduler has disappeared from Prometheus target discovery.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeschedulerdown
          summary: Target disappeared from Prometheus target discovery.
        expr: absent(up{job="kube-scheduler"} == 1)
        for: 15m
        labels:
          severity: Critical
    - name: kubernetes-controller-manager
      rules:
      - alert: KubeControllerManagerDown
        annotations:
          description: KubeControllerManager has disappeared from Prometheus target discovery.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubecontrollermanagerdown
          summary: Target disappeared from Prometheus target discovery.
        expr: absent(up{job="kube-controller-manager"} == 1)
        for: 15m
        labels:
          severity: Critical

    - name: kubernetes-kubelet
      rules:
      - alert: KubeNodeNotReady
        annotations:
          description: '{{ $labels.node }} has been unready for more than 15 minutes.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubenodenotready
          summary: Node is not ready.
        expr: kube_node_status_condition{job="kube-state-metrics",condition="Ready",status="true"} == 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeNodeUnreachable
        annotations:
          description: '{{ $labels.node }} is unreachable and some workloads may be rescheduled.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubenodeunreachable
          summary: Node is unreachable.
        expr: |
          (kube_node_spec_taint{job="kube-state-metrics",key="node.kubernetes.io/unreachable",effect="NoSchedule"} unless ignoring(key,value) kube_node_spec_taint{job="kube-state-metrics",key=~"ToBeDeletedByClusterAutoscaler|cloud.google.com/impending-node-termination|aws-node-termination-handler/spot-itn"}) == 1
        for: 15m
        labels:
          severity: Warning
      - alert: KubeletTooManyPods
        annotations:
          description: Kubelet '{{ $labels.node }}' is running at {{ $value | humanizePercentage }} of its Pod capacity.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubelettoomanypods
          summary: Kubelet is running at capacity.
        expr: |
          count by(node) (
            (kube_pod_status_phase{job="kube-state-metrics",phase="Running"} == 1) * on(instance,pod,namespace,cluster) group_left(node) topk by(instance,pod,namespace,cluster) (1, kube_pod_info{job="kube-state-metrics"})
          )
          /
          max by(node) (
            kube_node_status_capacity{job="kube-state-metrics",resource="pods"} != 1
          ) > 0.95
        for: 15m
        labels:
          severity: Warning
      - alert: KubeNodeReadinessFlapping
        annotations:
          description: The readiness status of node {{ $labels.node }} has changed {{ $value }} times in the last 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubenodereadinessflapping
          summary: Node readiness status is flapping.
        expr: sum(changes(kube_node_status_condition{status="true",condition="Ready"}[15m])) by (node) > 2
        for: 15m
        labels:
          severity: Warning
      - alert: KubeletPlegDurationHigh
        annotations:
          description: The Kubelet Pod Lifecycle Event Generator has a 99th percentile duration of {{ $value }} seconds on node {{ $labels.node }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletplegdurationhigh
          summary: Kubelet Pod Lifecycle Event Generator is taking too long to relist.
        expr: node_quantile:kubelet_pleg_relist_duration_seconds:histogram_quantile{quantile="0.99"} >= 10
        for: 5m
        labels:
          severity: Warning
      - alert: KubeletPodStartUpLatencyHigh
        annotations:
          description: Kubelet Pod startup 99th percentile latency is {{ $value }} seconds on node {{ $labels.node }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletpodstartuplatencyhigh
          summary: Kubelet Pod startup latency is too high.
        expr: |
          histogram_quantile(0.99, sum(rate(kubelet_pod_worker_duration_seconds_bucket{job="kubelet", metrics_path="/metrics"}[5m])) by (instance, le)) * on(instance) group_left(node) kubelet_node_name{job="kubelet", metrics_path="/metrics"} > 60
        for: 15m
        labels:
          severity: Warning
      - alert: KubeletClientCertificateExpiration
        annotations:
          description: Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletclientcertificateexpiration
          summary: Kubelet client certificate is about to expire.
        expr: kubelet_certificate_manager_client_ttl_seconds < 604800
        labels:
          severity: Warning
      - alert: KubeletClientCertificateExpiration
        annotations:
          description: Client certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletclientcertificateexpiration
          summary: Kubelet client certificate is about to expire.
        expr: kubelet_certificate_manager_client_ttl_seconds < 86400
        labels:
          severity: Critical
      - alert: KubeletServerCertificateExpiration
        annotations:
          description: Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletservercertificateexpiration
          summary: Kubelet server certificate is about to expire.
        expr: kubelet_certificate_manager_server_ttl_seconds < 604800
        labels:
          severity: Warning
      - alert: KubeletServerCertificateExpiration
        annotations:
          description: Server certificate for Kubelet on node {{ $labels.node }} expires in {{ $value | humanizeDuration }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletservercertificateexpiration
          summary: Kubelet server certificate is about to expire.
        expr: kubelet_certificate_manager_server_ttl_seconds < 86400
        labels:
          severity: Critical
      - alert: KubeletClientCertificateRenewalErrors
        annotations:
          description: Kubelet on node {{ $labels.node }} has failed to renew its client certificate ({{ $value | humanize }} errors in the last 5 minutes).
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletclientcertificaterenewalerrors
          summary: Kubelet has failed to renew its client certificate.
        expr: increase(kubelet_certificate_manager_client_expiration_renew_errors[5m]) > 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeletServerCertificateRenewalErrors
        annotations:
          description: Kubelet on node {{ $labels.node }} has failed to renew its server certificate ({{ $value | humanize }} errors in the last 5 minutes).
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletservercertificaterenewalerrors
          summary: Kubelet has failed to renew its server certificate.
        expr: increase(kubelet_server_expiration_renew_errors[5m]) > 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeletDown
        annotations:
          description: Kubelet has disappeared from Prometheus target discovery.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubeletdown
          summary: Target disappeared from Prometheus target discovery.
        expr: absent(up{job="kubelet", metrics_path="/metrics"} == 1)
        for: 15m
        labels:
          severity: Critical

    - name: kubernetes-apps
      rules:
      - alert: KubeContainerWaiting
        annotations:
          description: Pod {{ $labels.namespace }}/{{ $labels.pod }} container {{ $labels.container}} has been in waiting state for longer than 1 hour.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubecontainerwaiting
          summary: Pod container waiting longer than 1 hour
        expr: sum by (namespace, pod, container) (kube_pod_container_status_waiting_reason{job="kube-state-metrics"}) > 0
        for: 1h
        labels:
          severity: warning
      - alert: KubePodCrashLooping
        annotations:
          description: Pod {{ $labels.namespace }}/{{ $labels.pod }} ({{ $labels.container }}) is restarting {{ printf "%.2f" $value }} times / 10 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubepodcrashlooping
          summary: Pod is crash looping.
        expr: rate(kube_pod_container_status_restarts_total{job="kube-state-metrics"}[10m]) * 60 * 5 > 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubePodNotReady
        annotations:
          description: Pod {{ $labels.namespace }}/{{ $labels.pod }} has been in a non-ready state for longer than 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubepodnotready
          summary: Pod has been in a non-ready state for more than 15 minutes.
        expr: sum by (namespace, pod) (max by(namespace, pod) (kube_pod_status_phase{job="kube-state-metrics", phase=~"Pending|Unknown"}) * on(namespace, pod) group_left(owner_kind) topk by(namespace, pod) (1, max by(namespace, pod, owner_kind) (kube_pod_owner{owner_kind!="Job"}))) > 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeDeploymentGenerationMismatch
        annotations:
          description: Deployment generation for {{ $labels.namespace }}/{{ $labels.deployment }} does not match, this indicates that the Deployment has failed but has not been rolled back.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubedeploymentgenerationmismatch
          summary: Deployment generation mismatch due to possible roll-back
        expr: kube_deployment_status_observed_generation{job="kube-state-metrics"} != kube_deployment_metadata_generation{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: Warning
      - alert: KubeDeploymentReplicasMismatch
        annotations:
          description: Deployment {{ $labels.namespace }}/{{ $labels.deployment }} has not matched the expected number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubedeploymentreplicasmismatch
          summary: Deployment has not matched the expected number of replicas.
        expr: (kube_deployment_spec_replicas{job="kube-state-metrics"}!=kube_deployment_status_replicas_available{job="kube-state-metrics"}) and (changes(kube_deployment_status_replicas_updated{job="kube-state-metrics"}[10m])==0)
        for: 15m
        labels:
          severity: Warning
      - alert: KubeStatefulSetReplicasMismatch
        annotations:
          description: StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} has not matched the expected number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubestatefulsetreplicasmismatch
          summary: Deployment has not matched the expected number of replicas.
        expr: |
          (
            kube_statefulset_status_replicas_ready{job="kube-state-metrics"}
              !=
            kube_statefulset_status_replicas{job="kube-state-metrics"}
          ) and (
            changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[10m])
              ==
            0
          )
        for: 15m
        labels:
          severity: Warning
      - alert: KubeStatefulSetGenerationMismatch
        annotations:
          description: StatefulSet generation for {{ $labels.namespace }}/{{ $labels.statefulset }} does not match, this indicates that the StatefulSet has failed but has not been rolled back.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubestatefulsetgenerationmismatch
          summary: StatefulSet generation mismatch due to possible roll-back
        expr: kube_statefulset_status_observed_generation{job="kube-state-metrics"} != kube_statefulset_metadata_generation{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: Warning
      - alert: KubeStatefulSetUpdateNotRolledOut
        annotations:
          description: StatefulSet {{ $labels.namespace }}/{{ $labels.statefulset }} update has not been rolled out.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubestatefulsetupdatenotrolledout
          summary: StatefulSet update has not been rolled out.
        expr: |
          (
            max without (revision) (
              kube_statefulset_status_current_revision{job="kube-state-metrics"}
                unless
              kube_statefulset_status_update_revision{job="kube-state-metrics"}
            )
              *
            (
              kube_statefulset_replicas{job="kube-state-metrics"}
                !=
              kube_statefulset_status_replicas_updated{job="kube-state-metrics"}
            )
          )  and (
            changes(kube_statefulset_status_replicas_updated{job="kube-state-metrics"}[5m])
              ==
            0
          )
        for: 15m
        labels:
          severity: Warning
      - alert: KubeDaemonSetRolloutStuck
        annotations:
          description: DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} has not finished or progressed for at least 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubedaemonsetrolloutstuck
          summary: DaemonSet rollout is stuck.
        expr: |
          (
            (
              kube_daemonset_status_current_number_scheduled{job="kube-state-metrics"}
               !=
              kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
            ) or (
              kube_daemonset_status_number_misscheduled{job="kube-state-metrics"}
               !=
              0
            ) or (
              kube_daemonset_updated_number_scheduled{job="kube-state-metrics"}
               !=
              kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
            ) or (
              kube_daemonset_status_number_available{job="kube-state-metrics"}
               !=
              kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"}
            )
          ) and (
            changes(kube_daemonset_updated_number_scheduled{job="kube-state-metrics"}[5m])
              ==
            0
          )
        for: 15m
        labels:
          severity: Warning
      - alert: KubeDaemonSetNotScheduled
        annotations:
          description: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are not scheduled.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubedaemonsetnotscheduled
          summary: DaemonSet pods are not scheduled.
        expr: kube_daemonset_status_desired_number_scheduled{job="kube-state-metrics"} - kube_daemonset_status_current_number_scheduled{job="kube-state-metrics"} > 0
        for: 10m
        labels:
          severity: Warning
      - alert: KubeDaemonSetMisScheduled
        annotations:
          description: '{{ $value }} Pods of DaemonSet {{ $labels.namespace }}/{{ $labels.daemonset }} are running where they are not supposed to run.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubedaemonsetmisscheduled
          summary: DaemonSet pods are misscheduled.
        expr: kube_daemonset_status_number_misscheduled{job="kube-state-metrics"} > 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeJobCompletion
        annotations:
          description: Job {{ $labels.namespace }}/{{ $labels.job_name }} is taking more than 12 hours to complete.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubejobcompletion
          summary: Job did not complete in time
        expr: kube_job_spec_completions{job="kube-state-metrics"} - kube_job_status_succeeded{job="kube-state-metrics"}  > 0
        for: 12h
        labels:
          severity: Warning
      - alert: KubeJobFailed
        annotations:
          description: Job {{ $labels.namespace }}/{{ $labels.job_name }} failed to complete. Removing failed job after investigation should clear this alert.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubejobfailed
          summary: Job failed to complete.
        expr: kube_job_failed{job="kube-state-metrics"}  > 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeHpaReplicasMismatch
        annotations:
          description: HPA {{ $labels.namespace }}/{{ $labels.hpa }} has not matched the desired number of replicas for longer than 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubehpareplicasmismatch
          summary: HPA has not matched descired number of replicas.
        expr: |
          (kube_hpa_status_desired_replicas{job="kube-state-metrics"}
            !=
          kube_hpa_status_current_replicas{job="kube-state-metrics"})
            and
          (kube_hpa_status_current_replicas{job="kube-state-metrics"}
            >
          kube_hpa_spec_min_replicas{job="kube-state-metrics"})
            and
          (kube_hpa_status_current_replicas{job="kube-state-metrics"}
            <
          kube_hpa_spec_max_replicas{job="kube-state-metrics"})
            and
          changes(kube_hpa_status_current_replicas{job="kube-state-metrics"}[15m]) == 0
        for: 15m
        labels:
          severity: Warning
      - alert: KubeHpaMaxedOut
        annotations:
          description: HPA {{ $labels.namespace }}/{{ $labels.hpa }} has been running at max replicas for longer than 15 minutes.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubehpamaxedout
          summary: HPA is running at max replicas
        expr: kube_hpa_status_current_replicas{job="kube-state-metrics"} == kube_hpa_spec_max_replicas{job="kube-state-metrics"}
        for: 15m
        labels:
          severity: Warning

    - name: kubernetes-resources
      rules:
      - alert: KubeCPUOvercommit
        annotations:
          description: Cluster has overcommitted CPU resource requests for Pods and cannot tolerate node failure.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubecpuovercommit
          summary: Cluster has overcommitted CPU resource requests.
        expr: sum(namespace_cpu:kube_pod_container_resource_requests:sum{}) / sum(kube_node_status_allocatable{resource="cpu"})   >
          ((count(kube_node_status_allocatable{resource="cpu"}) > 1) - 1) / count(kube_node_status_allocatable{resource="cpu"})
        for: 5m
        labels:
          severity: Warning
      - alert: KubeMemoryOvercommit
        annotations:
          description: Cluster has overcommitted memory resource requests for Pods and cannot tolerate node failure.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubememoryovercommit
          summary: Cluster has overcommitted memory resource requests.
        expr: |
          sum(namespace_memory:kube_pod_container_resource_requests:sum{})
          /
          sum(kube_node_status_allocatable{resource="memory"})
          >
          ((count(kube_node_status_allocatable{resource="memory"}) > 1) - 1)
          /
          count(kube_node_status_allocatable{resource="memory"})
        for: 5m
        labels:
          severity: Warning
        - alert: KubeCPUQuotaOvercommit
        annotations:
          description: Cluster has overcommitted CPU resource requests for Namespaces.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubecpuquotaovercommit
          summary: Cluster has overcommitted CPU resource requests.
        expr: sum(kube_resourcequota{job="kube-state-metrics", type="hard", resource="cpu"}) / sum(kube_node_status_allocatable{resource="cpu"}) > 1.5
        for: 5m
        labels:
          severity: Warning
      - alert: KubeMemoryQuotaOvercommit
        annotations:
          description: Cluster has overcommitted memory resource requests for Namespaces.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubememoryquotaovercommit
          summary: Cluster has overcommitted memory resource requests.
        expr: sum(kube_resourcequota{job="kube-state-metrics", type="hard", resource="memory"}) / sum(kube_node_status_allocatable{resource="memory",job="kube-state-metrics"}) > 1.5
        for: 5m
        labels:
          severity: Warning
      - alert: KubeQuotaAlmostFull
        annotations:
          description: Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubequotaalmostfull
          summary: Namespace quota is going to be full.
        expr: kube_resourcequota{job="kube-state-metrics", type="used"} / ignoring(instance, job, type) (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0) > 0.9 < 1
        for: 15m
        labels:
          severity: Info
      - alert: KubeQuotaFullyUsed
        annotations:
          description: Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubequotafullyused
          summary: Namespace quota is fully used.
        expr: kube_resourcequota{job="kube-state-metrics", type="used"} / ignoring(instance, job, type)
        (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0) == 1
        for: 15m
        labels:
          severity: Info
      - alert: KubeQuotaExceeded
        annotations:
          description: Namespace {{ $labels.namespace }} is using {{ $value | humanizePercentage }} of its {{ $labels.resource }} quota.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubequotaexceeded
          summary: Namespace quota has exceeded the limits.
        expr: kube_resourcequota{job="kube-state-metrics", type="used"} / ignoring(instance, job, type)
        (kube_resourcequota{job="kube-state-metrics", type="hard"} > 0) > 1
        for: 15m
        labels:
          severity: Warning
      - alert: CPUThrottlingHigh
        annotations:
          description: '{{ $value | humanizePercentage }} throttling of CPU in namespace {{ $labels.namespace }} for container {{ $labels.container }} in pod {{ $labels.pod }}.'
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/cputhrottlinghigh
          summary: Processes experience elevated CPU throttling.
        expr: sum(increase(container_cpu_cfs_throttled_periods_total{container!="", }[5m])) by (container, pod, namespace) /
        sum(increase(container_cpu_cfs_periods_total{}[5m])) by (container, pod, namespace) > ( 25 / 100 )
        for: 15m
        labels:
          severity: Info

    - name: kubernetes-storage
      rules:
      - alert: KubePersistentVolumeFillingUp
        annotations:
          description: The PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is only {{ $value | humanizePercentage }} free.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubepersistentvolumefillingup
          summary: PersistentVolume is filling up.
        expr: |
          kubelet_volume_stats_available_bytes{job="kubelet", metrics_path="/metrics"}
          /
          kubelet_volume_stats_capacity_bytes{job="kubelet", metrics_path="/metrics"}
          < 0.03
        for: 1m
        labels:
          severity: Critical
      - alert: KubePersistentVolumeFillingUp
        annotations:
          description: Based on recent sampling, the PersistentVolume claimed by {{ $labels.persistentvolumeclaim }} in Namespace {{ $labels.namespace }} is expected to fill up within four days. Currently {{ $value | humanizePercentage }} is available.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubepersistentvolumefillingup
          summary: PersistentVolume is filling up.
        expr: |
          (
          kubelet_volume_stats_available_bytes{job="kubelet", metrics_path="/metrics"}
          /
          kubelet_volume_stats_capacity_bytes{job="kubelet", metrics_path="/metrics"}
          ) < 0.15
          and
          predict_linear(kubelet_volume_stats_available_bytes{job="kubelet", metrics_path="/metrics"}[6h], 4 * 24 * 3600) < 0
        for: 1h
        labels:
          severity: Warning
      - alert: KubePersistentVolumeErrors
        annotations:
          description: The persistent volume {{ $labels.persistentvolume }} has status {{ $labels.phase }}.
          runbook_url: https://github.com/prometheus-operator/kube-prometheus/wiki/kubepersistentvolumeerrors
          summary: PersistentVolume is having issues with provisioning.
        expr: kube_persistentvolume_status_phase{phase=~"Failed|Pending",job="kube-state-metrics"} > 0
        for: 5m
        labels:
          severity: Critical

    - name: kubernetes-coredns
      rules:
      - alert: CoreDNSDown
        annotations:
          message: CoreDNS has disappeared from Prometheus target discovery.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednsdown
        expr: absent(up{job="kube-dns"} == 1)
        for: 15m
        labels:
          severity: Critical
      - alert: CoreDNSLatencyHigh
        annotations:
          message: CoreDNS has 99th percentile latency of {{ $value }} seconds for server {{ $labels.server }} zone {{ $labels.zone }} .
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednslatencyhigh
        expr: histogram_quantile(0.99, sum(rate(coredns_dns_request_duration_seconds_bucket{job="kube-dns"}[5m])) by(server, zone, le)) > 4
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSLatencyHigh
        annotations:
          message: CoreDNS has 99th percentile latency of {{ $value }} seconds for server {{ $labels.server }} zone {{ $labels.zone }} .
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednslatencyhigh
        expr: histogram_quantile(0.99, sum(rate(coredns_dns_request_duration_seconds_bucket{job="kube-dns"}[5m])) by(server, zone, le)) > 4
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSErrorsHigh
        annotations:
          message: CoreDNS is returning SERVFAIL for {{ $value | humanizePercentage }} of requests.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednserrorshigh
        expr: sum(rate(coredns_dns_responses_total{job="kube-dns",rcode="SERVFAIL"}[5m])) / sum(rate(coredns_dns_responses_total{job="kube-dns"}[5m])) > 0.03
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSErrorsHigh
        annotations:
          message: CoreDNS is returning SERVFAIL for {{ $value | humanizePercentage }} of requests.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednserrorshigh
        expr: sum(rate(coredns_dns_responses_total{job="kube-dns",rcode="SERVFAIL"}[5m])) / sum(rate(coredns_dns_responses_total{job="kube-dns"}[5m])) > 0.01
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSForwardLatencyHigh
        annotations:
          message: CoreDNS has 99th percentile latency of {{ $value }} seconds forwarding requests to {{ $labels.to }}.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednsforwardlatencyhigh
        expr: histogram_quantile(0.99, sum(rate(coredns_forward_request_duration_seconds_bucket{job="kube-dns"}[5m])) by(to, le)) > 4
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSForwardErrorsHigh
        annotations:
          message: CoreDNS is returning SERVFAIL for {{ $value | humanizePercentage }} of forward requests to {{ $labels.to }}.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednsforwarderrorshigh
        expr: sum(rate(coredns_forward_responses_total{job="kube-dns",rcode="SERVFAIL"}[5m])) / sum(rate(coredns_forward_responses_total{job="kube-dns"}[5m])) > 0.03
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSForwardErrorsHigh
        annotations:
          message: CoreDNS is returning SERVFAIL for {{ $value | humanizePercentage }} of forward requests to {{ $labels.to }}.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednsforwarderrorshigh
        expr: sum(rate(coredns_forward_responses_total{job="kube-dns",rcode="SERVFAIL"}[5m])) / sum(rate(coredns_forward_responses_total{job="kube-dns"}[5m])) > 0.01
        for: 10m
        labels:
          severity: Critical
      - alert: CoreDNSForwardHealthcheckFailureCount
        annotations:
          message: CoreDNS health checks have failed to upstream server {{ $labels.to }}.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.md#alert-name-corednsforwardhealthcheckfailurecount
        expr: sum(rate(coredns_forward_healthcheck_failures_total{job="kube-dns"}[5m])) by (to) > 0
        for: 10m
        labels:
          severity: Warning
      - alert: CoreDNSForwardHealthcheckBrokenCount
        annotations:
          message: CoreDNS health checks have failed for all upstream servers.
          runbook_url: https://github.com/povilasv/coredns-mixin/tree/master/runbook.
        expr: sum(rate(coredns_forward_healthcheck_broken_total{job="kube-dns"}[5m])) > 0
        for: 10m
        labels:
          severity: Warning
      - alert: CorednsPanicCount
        expr: increase(coredns_panics_total[1m]) > 0
        for: 0m
        labels:
          severity: Critical
        annotations:
          summary: "{{$labels.instance}} CoreDNS have Panics."
          description: "{{$labels.instance}} Number of CoreDNS panics encountered is {{ $value }}"
 
# 7.重载Prometheus，验证集群监控状态

    curl -XPOST http://127.0.0.1:9090/-/reload

# 8.导入grafana模版

Dashboards ---> Manage ---> Import ---> 模版ID：16420

---------

# 参考文档

- https://zhuanlan.zhihu.com/p/671898732
- https://blog.51cto.com/u_16099314/9650104
- https://www.cnblogs.com/suyj/p/16053993.html
- https://blog.csdn.net/MrFDd/article/details/134535787
- https://blog.csdn.net/qq_34939308/article/details/123314719
- https://blog.csdn.net/qq_33816243/article/details/126863790
- https://docs.tianshu.org.cn/docs/setup/monitor-pod-indicator-information