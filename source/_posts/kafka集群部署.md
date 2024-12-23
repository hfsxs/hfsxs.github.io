---
title: Kafka集群部署
categories:
  - 工作
tags:
  - Linux
  - Kafka
  - 消息队列
  - 中间件
  - 云计算
date: 2024-08-01 14:15:30
---

Kafka，由Scala和Java开发的开源的高可靠、高吞吐量、低延迟的流式数据平台，可用作分布式发布-订阅消息队列系统。Kafka基于ZooKeeper同步服务，将消息数据以分区的方式并行地存储于分布式集群的磁盘，并以多副本的方式构建数据冗余机制，适用于大数据实时数据流处理领域，如消费者在网站上所有动作流数据（网页浏览、点击、搜索以及其他用户行动）

# 体系架构

![集群架构](/img/wiki/kafka/001集群架构.jpg)

Kafka是典型的分布式消息队列系统，由消息生产者Producer、消息消费者Consumer、消息服务器Broker和分布式协调服务器ZooKeeper组成

消息队列，Message Queue，简称为MQ，数据传输过程中的数据链表，是应用程序间异步数据处理机制，实质就是一个保存数据的队列的存储容器，工作流程为：消息的发布者将消息发布到MQ，消息使用者从MQ获取消息，而双方都无需关心传输的方式。基于消息队列设计的消息系统即是将数据以这种异步方式从一个应用程序传输到另外一个应用程序，数据的发送方与接收方不必考虑如何将数据共享与接收，也不必顾及数据的存储问题，只需专注于自身的业务逻辑即可。这样，应用程序之间通过消息系统以异步传输的方式进行数据传输，减少了系统组件之间的直接依赖，解耦了业务逻辑与数据传输逻辑，提高了数据传输的容错性，避免了流量高峰的冲击。消息系统有两种消息传递模式，即点对点方式和基于发布-订阅（publish-subscribe）方式

- 点对点消息系统，将消息保留在队列中，一个或者多个消费者可以消耗队列中的消息，但是消息最多只能被一个消费者消费，且一旦有一个消费者将其消费掉，消息就从该队列中消失。注意，多个消费者可以同时工作，但最终能拿到该消息的只有其中一个，典型的例子就是订单处理系统，多个订单处理器可以同时工作，但是对于一个特定的订单，只有其中一个订单处理器可以拿到该订单进行处理

- 发布-订阅消息系统，将消息保留在主题中，不同于点对点系统，消费者可以订阅一个或多个主题并使用该主题中的所有消息，消息生产者称为发布者，消息使用者称为订阅者。典型的例子是Dish电视，只需发布不同的渠道，如运动，电影，音乐等，任何人都可通过主题订阅自己的频道集

## 1.Producer

Producer，生产者，即消息的创建者，将消息发布到Kafka

## 2.Consumer

Consumer，消费者，即消息的使用者，从Kafka获取消息，每个Consumer都从属于特定的ConsumerGroup（消费者组，可进行指定，若不指定则属于默认组）

## 3.Broker

Broker，Kafka服务器节点，相当于MQ节点，用于存储消息数据，多个Broker节点即构成Kafka集群

### 3.1 Topic

Topic，主题，Kafka所存储消息的逻辑上的类别，生产者和消费者的操作对象

### 3.2 Partition

Partition，分区，Kafka数据存储的基本单元，是一个有序且不可变的记录序列，新纪录从末尾进行追加，且每个Topic都被分割为一个或多个物理上的Partition，并以文件形式分散存储于Broker节点。由于Kafka基于文件进行数据存储，文件内容必然会扩展到单个磁盘的上限，因此将文件分割为一个一个的Partition，一个Partition对应一个文件。这样，就将数据分割到不同的Broker进行存储，还实现了负载均衡

### 3.3 Replication

Replication，副本，分区的备份，默认为1，最大值为集群Broker节点数，是Kafka的数据冗余机制。所有副本数据一致，但只有一个作为ReplicationLeader负责与生产者、消费者交互及数据同步，其余作为ReplicationFollower，只作为备份，并从replicationLeader同步数据，直到ReplicationLeader损坏或失效，再由ReplicationManager选举新的ReplicationLeader，完成副本状态切换

### 3.4 Offset

Offset，偏移量，long型数字，消息的唯一序号，由于Partition文件是有序的记录，所以也标识了该消息在Partition中的位置

### 3.5 LogSegment

LogSegment，日志段，Kafka日志对象分片的最小单位，每个分区被划分为多个LogSegment。LogSegment是逻辑概念，由一个日志文件（.log数据文件）和两个索引文件（.index和.timeindex，即表示偏移量索引文件和消息时间戳索引文件）组成

## 4.ZooKeeper

ZooKeeper，开源的分布式应用程序协调服务，通常用作分布式架构的配置和同步服务，为分布式应用提供一致性服务，如配置维护、域名服务、分布式同步、组服务等。Kafka集群依赖于ZooKeeper共享信息与协调管理，如集群元数据存储（如Topic、Broker注册等）、协调Broker与Producer、Consumer（如Broker状态监控及Leader选举）

# 工作流程

![工作流程](/img/wiki/kafka/002工作流程.jpg)

Kafka工作流程大致分为三步，生产消息，即生产者将消息发送到Kafka集群，并选择目标分区；存储消息，即Broker将消息持久化到磁盘，并通过副本机制保证数据的高可用性和容错性；消费消息，即消费者从Kafka集群拉取消息，并进行处理。同时，消费者需要定期提交消费进度，以确保消息的准确处理和故障恢复

## 1.生产消息

### 1.1 创建生产者实例

生产者创建KafkaProducer实例，并配置必要的参数，如Kafka Broker的地址、序列化器（Serializer）等，然后与Kafka的Producer API建立连接

### 1.2 构建消息

生产者构建消息记录（ProducerRecord），包括目标主题、消息键（Key）和消息值（Value）

### 1.3 发送消息

生产者调用send()方法将消息发送到Kafka集群，发送方式有两种，即同步和异步

### 1.4 选择分区

Kafka根据消息键和分区策略（如轮询或哈希）选择目标分区，若消息键为空，则基于轮询策略将消息均匀分配到各个分区

### 1.5 消息序列化

生产者将消息键和消息值序列化为字节数组，以便在网络上传输和存储

### 1.6 消息发送

生产者将序列化后的消息发送到目标分区的Leader Broker

### 1.7 消息确认

Leader Broker接收到消息后，将其写入本地日志文件，并向生产者发送确认（ACK）

## 2.存储消息

### 2.1 接收消息

kafka集群Leader Broker节点接收到生产者发送的消息后，将消息追加到对应主题的分区日志文件，属于顺序写磁盘，相比于随机写的吞吐量更高

### 2.2 副本同步

Leader Broker将消息同步到从副本（Follower）Broker，从副本将消息写入本地日志文件向Leader发送确认

### 2.3 消息提交

Leader Broker收到足够数量的从副本确认后，将消息标记为已提交（Committed），已提交的消息即对消费者可见

### 2.4 日志管理

Kafka集群定期清理过期的日志段（Log Segment），以释放磁盘空间。此外，日志压缩（Log Compaction）功能也能用于清理数据，以便保留每个键的最新消息

## 3.消费消息

### 3.1 创建消费者实例

首先，消费者创建一个KafkaConsumer实例，并配置必要的参数，如Kafka Broker的地址、反序列化器（Deserializer）等

### 3.2 订阅主题

消费者调用subscribe()方法订阅一个或多个主题，可以单独消费消息，也可以组成消费组（Consumer Group）共同消费

### 3.3 拉取消息

消费者调用poll()方法从Kafka集群拉取消息，可根据需要设置拉取间隔和拉取数量

### 3.4 消息反序列化

消费者将消息键和消息值反序列化为原始数据类型，以便进行处理

### 3.5 处理消息

消费者处理拉取到的消息，执行业务逻辑

### 3.6 提交偏移量

消费者定期提交消费进度，即消费偏移量，以确保消息的准确处理和故障恢复，可选择自动提交或手动提交

# 应用场景

## 1.消息系统

消息系统通常应用与解耦生产者和消费者、缓存消息等场景

## 2.监控指标

即操作监控数据，涉及聚合来自分布式应用程序的统计信息，以产生操作数据的集中反馈

## 3.日志聚合

用于跨组织从多个服务收集日志，并以标准格式提供给多个服务器

## 4.流处理

流处理框架（Storm和Spark Streaming）从Kafka读取数据并对其进行处理，将处理后的数据写入Kafka后供用户和应用程序使用，如在线教育的课程与习题数据的计算与消费

---------

# 1.配置Java环境

# 2.ZooKeeper集群部署

Kafka安装包实际上内置了ZooKeeper，但为了保障整个集群的性能，建议单独部署

## 2.1 下载ZooKeeper

    wget https://archive.apache.org/dist/zookeeper/zookeeper-3.6.4/apache-zookeeper-3.6.4-bin.tar.gz
    tar -xzvf apache-zookeeper-3.6.4-bin.tar.gz && sudo mv apache-zookeeper-3.6.4 /usr/local/zookeeper
    sudo mkdir -p /usr/local/zookeeper/data

## 2.2 配置ZooKeeper集群

    sudo cp /usr/local/zookeeper/conf/zoo_sample.cfg /usr/local/zookeeper/conf/zoo.cfg
    sudo vi /usr/local/zookeeper/conf/zoo.cfg


    # 设置Zookeeper服务端口
    clientPort = 2181
    # 设置Zookeeper服务器之间或与客户端之间的心跳时长，默认为2000，单位为毫秒，直接影响事件触发、回话超时和数据同步等
    tickTime = 2000
    # 设置集群Lollower节点和Leader节点初始连接的超时时长，其值为tickTime数，即n个tickTime时间，默认为10
    initLimit = 5
    # 设置集群Lollower节点和Leader节点初始化后请求与应答的超时时长，其值为tickTime数，即n个tickTime时间，默认为2
    syncLimit = 2
    # 设置Zookeeper本地数据目录，默认为/tmp/zookeeper
    dataDir = /usr/local/zookeeper/data
    # 设置Zookeeper集群节点
    server.1 = 172.16.100.101:2888:3888
    server.2 = 172.16.100.102:2888:3888
    server.3 = 172.16.100.103:2888:3888

## 2.3 配置节点myid文件

    echo 1 > /usr/local/zookeeper/data/myid
    echo 2 > /usr/local/zookeeper/data/myid
    echo 3 > /usr/local/zookeeper/data/myid

- 注：myid文件是Zookeeper集群节点的唯一标识符，用于集群节点内部的互相识别、通信和协调，对应配置文件的server.x参数

## 2.4 创建启动脚本

    sudo vi /lib/systemd/system/zookeeper.service


    [Unit]
    Description = Apache Zookeeper
    Documentation = http://zookeeper.apache.org

    [Service]
    Type = forking
    User = root
    Group = root
    ExecStart = /usr/local/zookeeper/bin/zkServer.sh --config /usr/local/zookeeper/conf start
    ExecStop = /usr/local/zookeeper/bin/zkServer.sh --config /usr/local/zookeeper/conf stop
    Restart = on-abnormal

    [Install]
    WantedBy = multi-user.target

## 2.5 启动集群

    sudo systemctl daemon-reload
    sudo systemctl start zookeeper.service
    sudo systemctl enable zookeeper.service

## 2.6 验证集群状态

    sudo /usr/local/zookeeper/bin/zkServer.sh status

# 3.Kafka集群部署

## 3.1 下载安装包

    wget https://downloads.apache.org/kafka/3.6.2/kafka_2.12-3.6.2.tgz
    tar -xzvf kafka_2.12-3.6.2.tgz && sudo mv kafka_2.12-3.6.2 /usr/local/kafka

## 3.2 配置Kafka集群

    sudo cp /usr/local/kafka/config/server.properties /usr/local/kafka/config/server.properties.bak
    sudo mkdir -p /usr/local/kafka/data 
    sudo cp /usr/local/kafka/config/server.properties /usr/local/kafka/config/server.properties.bak
    sudo vi /usr/local/kafka/config/server.properties


    # 设置监听端口
    port = 9092
    # 设置Broker节点全局唯一ID，不能重复，类似于Zookeeper的myid
    broker.id = 1
    # 设置数据文件存储路径，默认为/tmp
    log.dirs = /usr/local/kafka/data
    # 设置Topic默认分区数，默认为1，建议对业务压测之后根据实际情况进行设置
    num.partitions = 3
    # 设置Zookeeper集群地址
    zookeeper.connect = 172.100.100.101:2181,172.100.100.102:2181,172.100.100.103:2181

## 3.3 创建启动脚本

    sudo vi /lib/systemd/system/kafka.service


    Description = Apache Kafka
    Documentation = https://kafka.apache.org
    After = network.target zookeeper.service

    [Service]
    Type = simple
    User = root
    Group = root
    ExecStart = /usr/local/kafka/bin/kafka-server-start.sh /usr/local/kafka/config/server.properties
    ExecStop = /usr/local/kafka/bin/kafka-server-stop.sh
    Restart = on-failure

    [Install]
    WantedBy = multi-user.target

## 3.4 启动Kafka集群

    sudo systemctl daemon-reload
    sudo systemctl start kafka.service
    sudo systemctl enable kafka.service

## 3.5 验证Kafka集群

---------

# 参考文档

- https://blog.csdn.net/shenaohuoli132/article/details/137600814
- https://blog.csdn.net/wudidahuanggua/article/details/127086186
- https://blog.csdn.net/Blue_Pepsi_Cola/article/details/137432969