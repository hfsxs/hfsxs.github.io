---
title: Kafka集群基于Kubernetes的部署
categories:
  - 工作
tags:
  - Linux
  - Kafka
  - Kubernetes
  - 容器云
  - 云计算
date: 2023-03-31 15:45:31
---

# 1.部署nfs

# 2.部署StorageClass

# 3.部署zookeeper集群

    vi zookeeper.yaml
    
  
    apiVersion: v1
    kind: Service
    metadata:
      name: zookeeper
      namespace: logging
      labels:
        app: zookeeper
    spec:
      ports:
        - port: 2181
          name: client
      selector:
        app: zookeeper
    ---
    apiVersion: v1
    kind: Service
    metadata:
      name: zookeepers
      namespace: logging
      labels:
        app: zookeeper
    spec:
      ports:
        - port: 2888
          name: server
        - port: 3888
          name: leader-election
      clusterIP: None
      selector:
        app: zookeeper
    ---
    apiVersion: policy/v1beta1
    kind: PodDisruptionBudget
    metadata:
      name: zookeeper-pdb
      namespace: logging
    spec:
      selector:
        matchLabels:
          app: zookeeper
      maxUnavailable: 1
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: zookeeper
      namespace: logging
    spec:
      selector:
        matchLabels:
          app: zookeeper
      serviceName: zookeepers
      replicas: 3
      updateStrategy:
        type: RollingUpdate
      podManagementPolicy: Parallel
      template:
        metadata:
          labels:
            app: zookeeper
        spec:
          containers:
            - name: zookeeper
              imagePullPolicy: IfNotPresent
              image: registry.cn-hangzhou.aliyuncs.com/swords/zookeeper:v3.6.0
              resources:
                limits:
                  cpu: 500m
                  memory: 512Mi
                requests:
                  cpu: 200m
                  memory: 300M
              ports:
                - containerPort: 2181
                  name: client
                - containerPort: 2888
                  name: server
                - containerPort: 3888
                  name: leader-election
              command:
                - bash
                - -x
                - -c
                - |
                  SERVERS=3 &&
                  HOST=`hostname -s` &&
                  DOMAIN=`hostname -d` &&
                  CLIENT_PORT=2181 &&
                  SERVER_PORT=2888 &&
                  ELECTION_PORT=3888 &&
                  PROMETHEUS_PORT=7000 &&
                  ZOO_DATA_DIR=/var/lib/zookeeper/data &&
                  ZOO_DATA_LOG_DIR=/var/lib/zookeeper/datalog &&
                  {
                    echo "clientPort=${CLIENT_PORT}"
                    echo 'tickTime=2000'
                    echo 'initLimit=300'
                    echo 'syncLimit=10'
                    echo 'maxClientCnxns=2000'
                    echo 'maxSessionTimeout=60000000'
                    echo "dataDir=${ZOO_DATA_DIR}"
                    echo "dataLogDir=${ZOO_DATA_LOG_DIR}"
                    echo 'autopurge.snapRetainCount=10'
                    echo 'autopurge.purgeInterval=1'
                    echo 'preAllocSize=131072'
                    echo 'snapCount=3000000'
                    echo 'leaderServes=yes'
                    echo 'standaloneEnabled=false'
                    echo '4lw.commands.whitelist=*'
                    echo 'metricsProvider.className=org.apache.zookeeper.metrics.prometheus.PrometheusMetricsProvider'
                    echo "metricsProvider.httpPort=${PROMETHEUS_PORT}"
                  } > /conf/zoo.cfg &&
                  {
                    echo "zookeeper.root.logger=CONSOLE"
                    echo "zookeeper.console.threshold=INFO"
                    echo "TZ=Asia/Shanghai"
                    echo "log4j.rootLogger=\${zookeeper.root.logger}"
                    echo "log4j.appender.CONSOLE=org.apache.log4j.ConsoleAppender"
                    echo "log4j.appender.CONSOLE.Threshold=\${zookeeper.console.threshold}"
                    echo "log4j.appender.CONSOLE.layout=org.apache.log4j.PatternLayout"
                    echo "log4j.appender.CONSOLE.layout.ConversionPattern=%d{ISO8601} [myid:%X{myid}] - %-5p [%t:%C{1}@%L] - %m%n"
                  } > /conf/log4j.properties &&
                  echo 'JVMFLAGS="-Xms128M -Xmx4G -XX:+UseG1GC -XX:+CMSParallelRemarkEnabled"' > /conf/java.env &&
                  if [[ $HOST =~ (.*)-([0-9]+)$ ]]; then
                      NAME=${BASH_REMATCH[1]}
                      ORD=${BASH_REMATCH[2]}
                  else
                      echo "Failed to parse name and ordinal of Pod"
                      exit 1
                  fi &&
                  mkdir -p ${ZOO_DATA_DIR} &&
                  mkdir -p ${ZOO_DATA_LOG_DIR} &&
                  export MY_ID=$((ORD+1)) &&
                  echo $MY_ID > $ZOO_DATA_DIR/myid &&
                  for (( i=1; i<=$SERVERS; i++ )); do
                      echo "server.$i=$NAME-$((i-1)).$DOMAIN:$SERVER_PORT:$ELECTION_PORT" >> /conf/zoo.cfg;
                  done &&
                  chown -Rv zookeeper "$ZOO_DATA_DIR" "$ZOO_DATA_LOG_DIR" "$ZOO_LOG_DIR" "$ZOO_CONF_DIR" &&
                  zkServer.sh start-foreground
              readinessProbe:
                exec:
                  command:
                    - bash
                    - -c
                    - "OK=$(echo ruok | nc 127.0.0.1 2181); if [[ \"$OK\" == \"imok\" ]]; then exit 0; else exit 1; fi"
                initialDelaySeconds: 10
                timeoutSeconds: 5
              livenessProbe:
                exec:
                  command:
                    - bash
                    - -c
                    - "OK=$(echo ruok | nc 127.0.0.1 2181); if [[ \"$OK\" == \"imok\" ]]; then exit 0; else exit 1; fi"
                initialDelaySeconds: 10
                timeoutSeconds: 5
              volumeMounts:
                - name: data
                  mountPath: /var/lib/zookeeper
          securityContext:
            runAsUser: 0
            fsGroup: 0
          affinity:
            podAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: app
                    operator: In
                    values:
                    - zookeeper
                topologyKey: "kubernetes.io/hostname"
      volumeClaimTemplates:
        - metadata:
            name: data
          spec:
            storageClassName: sc-nfs
            accessModes:
              - ReadWriteOnce
            resources:
              requests:
                storage: 10Gi
    

# 4.部署kafka集群

    vi kafka.yaml


    apiVersion: v1
    kind: Service
    metadata:
      name: kafka
      namespace: logging
      labels:
        app: kafka
    spec:
      ports:
      - port: 9092
        name: server
      clusterIP: None
      selector:
        app: kafka
    ---
    apiVersion: policy/v1beta1
    kind: PodDisruptionBudget
    metadata:
      name: kafka-pdb
      namespace: logging
    spec:
      selector:
        matchLabels:
          app: kafka
      minAvailable: 2
    ---
    apiVersion: apps/v1
    kind: StatefulSet
    metadata:
      name: kafka
      namespace: logging
    spec:
      selector:
        matchLabels:
          app: kafka
      serviceName: kafka
      replicas: 3
      template:
        metadata:
          labels:
            app: kafka
        spec:
          terminationGracePeriodSeconds: 300
          imagePullSecrets:
          - name: regauth
          containers:
          - name: kafka
            imagePullPolicy: IfNotPresent
            image: registry.cn-hangzhou.aliyuncs.com/swords/kafka:v2.12
            resources:
              limits:
                cpu: 500m
                memory: 1024Mi
              requests:
                cpu: 100m
                memory: 800Mi
            ports:
            - containerPort: 9092
              name: server
            command:
            - sh
            - -c
            - "exec /opt/kafka/bin/kafka-server-start.sh /opt/kafka/config/server.properties --override broker.id=${HOSTNAME##*-} \
              --override listeners=PLAINTEXT://:9092 \
              --override zookeeper.connect=zookeeper-0.zookeepers.logging.svc.cluster.local:2181,zookeeper-1.zookeepers.logging.svc.cluster.local:2181 \
              --override log.dir=/opt/kafka/logs \
              --override auto.create.topics.enable=true \
              --override auto.leader.rebalance.enable=true \
              --override background.threads=10 \
              --override compression.type=producer \
              --override delete.topic.enable=false \
              --override leader.imbalance.check.interval.seconds=300 \
              --override leader.imbalance.per.broker.percentage=10 \
              --override log.flush.interval.messages=9223372036854775807 \
              --override log.flush.offset.checkpoint.interval.ms=60000 \
              --override log.flush.scheduler.interval.ms=9223372036854775807 \
              --override log.retention.bytes=-1 \
              --override log.retention.hours=72 \
              --override log.roll.hours=168 \
              --override log.roll.jitter.hours=0 \
              --override log.segment.bytes=1073741824 \
              --override log.segment.delete.delay.ms=60000 \
              --override message.max.bytes=1000012 \
              --override min.insync.replicas=1 \
              --override num.io.threads=8 \
              --override num.network.threads=3 \
              --override num.recovery.threads.per.data.dir=1 \
              --override num.replica.fetchers=1 \
              --override offset.metadata.max.bytes=4096 \
              --override offsets.commit.required.acks=-1 \
              --override offsets.commit.timeout.ms=5000 \
              --override offsets.load.buffer.size=5242880 \
              --override offsets.retention.check.interval.ms=600000 \
              --override offsets.retention.minutes=1440 \
              --override offsets.topic.compression.codec=0 \
              --override offsets.topic.num.partitions=50 \
              --override offsets.topic.replication.factor=3 \
              --override offsets.topic.segment.bytes=104857600 \
              --override queued.max.requests=500 \
              --override quota.consumer.default=9223372036854775807 \
              --override quota.producer.default=9223372036854775807 \
              --override replica.fetch.min.bytes=1 \
              --override replica.fetch.wait.max.ms=500 \
              --override replica.high.watermark.checkpoint.interval.ms=5000 \
              --override replica.lag.time.max.ms=10000 \
              --override replica.socket.receive.buffer.bytes=65536 \
              --override replica.socket.timeout.ms=30000 \
              --override request.timeout.ms=30000 \
              --override socket.receive.buffer.bytes=102400 \
              --override socket.request.max.bytes=104857600 \
              --override socket.send.buffer.bytes=102400 \
              --override unclean.leader.election.enable=true \
              --override zookeeper.session.timeout.ms=6000 \
              --override zookeeper.set.acl=false \
              --override broker.id.generation.enable=true \
              --override connections.max.idle.ms=600000 \
              --override controlled.shutdown.enable=true \
              --override controlled.shutdown.max.retries=3 \
              --override controlled.shutdown.retry.backoff.ms=5000 \
              --override controller.socket.timeout.ms=30000 \
              --override default.replication.factor=2 \
              --override fetch.purgatory.purge.interval.requests=1000 \
              --override group.max.session.timeout.ms=300000 \
              --override group.min.session.timeout.ms=6000 \
              --override inter.broker.protocol.version=2.2.0 \
              --override log.cleaner.backoff.ms=15000 \
              --override log.cleaner.dedupe.buffer.size=134217728 \
              --override log.cleaner.delete.retention.ms=86400000 \
              --override log.cleaner.enable=true \
              --override log.cleaner.io.buffer.load.factor=0.9 \
              --override log.cleaner.io.buffer.size=524288 \
              --override log.cleaner.io.max.bytes.per.second=1.7976931348623157E308 \
              --override log.cleaner.min.cleanable.ratio=0.5 \
              --override log.cleaner.min.compaction.lag.ms=0 \
              --override log.cleaner.threads=1 \
              --override log.cleanup.policy=delete \
              --override log.index.interval.bytes=4096 \
              --override log.index.size.max.bytes=10485760 \
              --override log.message.timestamp.difference.max.ms=9223372036854775807 \
              --override log.message.timestamp.type=CreateTime \
              --override log.preallocate=false \
              --override log.retention.check.interval.ms=300000 \
              --override max.connections.per.ip=2147483647 \
              --override num.partitions=4 \
              --override producer.purgatory.purge.interval.requests=1000 \
              --override replica.fetch.backoff.ms=1000 \
              --override replica.fetch.max.bytes=1048576 \
              --override replica.fetch.response.max.bytes=10485760 \
              --override reserved.broker.max.id=1000 "
            env:
            - name: KAFKA_HEAP_OPTS
              value : "-Xmx512M -Xms512M"
            - name: KAFKA_OPTS
              value: "-Dlogging.level=INFO"
            - name: TZ
              value: Asia/Shanghai
            volumeMounts:
            - name: data
              mountPath: /opt/kafka/logs
            readinessProbe:
              tcpSocket:
                port: 9092
              timeoutSeconds: 1
              initialDelaySeconds: 5
          securityContext:
            runAsUser: 1000
            fsGroup: 1000
          affinity:
            podAntiAffinity:
              requiredDuringSchedulingIgnoredDuringExecution:
              - labelSelector:
                  matchExpressions:
                  - key: app
                    operator: In
                    values:
                    - kafka
                topologyKey: "kubernetes.io/hostname"
      volumeClaimTemplates:
      - metadata:
          name: data
        spec:
          accessModes: [ "ReadWriteMany" ]
          storageClassName: sc-nfs
          resources:
            requests:
              storage: 10Gi

# 5.查看kfka集群状态
    
    kubectl -n logging get pod -o wide
    
# 6.验证kafka集群

---------

# 参考文档

- https://www.orchome.com/1277
- https://www.jianshu.com/p/50a9d38ada27
- https://blog.csdn.net/shanghaibao123/article/details/124351255