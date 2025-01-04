---
title: Linux系统配置Iptables防火墙
categories:
  - 工作
tags:
  - Linux
  - Iptables
  - 网络
  - 防火墙
  - 云计算
date: 2020-02-06 09:30:56
---

Iptables，开源的数据包过滤网络防火墙系统，目前已集成于Linux内核，属于Netfilter项目，性能稳定而高效。Iptables工作于网络层，用于实现IP数据包的检测过滤、封包重定向、网络地址转换（NAT）、包速率限制等安全功能，且按照不同的目的被组织成表集合，从而完成对网络数据包进出设备及传输的控制，具备了网络防火墙功能，用以代替昂贵的商业防火墙解决方案

# 系统架构

Iptables防火墙系统由两部分组成，即netfilter和iptables

## 1.netfilter

netfilter，工作于内核空间，集成于Linux内核的通用网络包过滤模块，用于对进出内核协议栈的数据包进行过滤或修改，从而实现防火墙功能，是Iptables防火墙系统的核心

## 2.iptables

iptables，工作于用户空间，本身并不具备包过滤功能，而是用户制定、管理和存储netfilter操作规则及数据包处理逻辑的接口与命令工具，即数据包触发某条规则就执行相应的处理逻辑

# 工作原理

Iptables防火墙的核心处理机制是由netfilter对IP数据包进行过滤，所有经过主机的数据包都必然经过netfilter所设的五个控制模块中的某个或某几个，并以用户定义的防火墙规则进行相应的处理动作，最终完成过滤过程。这五个控制模块即为链，每个链对数据包相同的处理动作即为表，由用户通过iptables工具定义的数据包处理逻辑即为规则。表由若干链（处理环节）组成，链由一条或若干条规则（处理逻辑）组成，规则由一些信息包过滤表组成

形象地讲，数据包类似于原始水流，netfilter所设的控制模块类似于自来水厂所设置的处理环节，iptables定义的过滤数据包的规则就是自来水厂设计的供水方案。自来水厂的原始水流必须经过若干或所有的处理环节，也即是完全符合供水方案之后，才能产生符合标准的自来水，最后经过管道输送给居民

## 1.规则

rules，规则，用户定义的数据包过滤机制，由匹配条件和处理动作两个要素组成，一般定义为：若数据包符合某个条件，就对这个数据包做出这样的处理，也即是符合rule的流量将会去往target。rule的处理对象是IP数据流，通常以五元组标识，即SourceIP、SourcePort、DestIP、DestPort和网络协议。对五元组中的某个或某些要素进行过滤，如放行（accept）、拒绝（reject）和丢弃（drop）等，即构成了rule，防火墙的的配置工作主要就是添加、修改和删除这些rule

### 1.1 匹配条件

匹配条件，由网络五元组标识

- S_IP，源IP
- S_PORT，源端口
- D_IP，目的IP
- D_PORT，目的端口
- TCP/UDP，四层协议

### 1.2 处理动作

处理动作，被称为target，即对数据包进行堵、放行或丢弃的过滤方式

- ACCEPT，允许数据包通过
- DROP，直接丢弃数据包，不回应任何信息，客户端只有当该链接超时后才会有反应
- REJECT，拒绝数据包，会给客户端发送一个响应的信息
- SNAT，源NAT，即改写数据包的源IP为指定IP或IP段，可指定端口范围，用于解决私网用户用同一个公网IP上网的问题
- DNAT，目的NAT，即改写数据包的目的IP为指定IP或IP段，可指定端口范围，用于解决私网服务端用公网IP接收请求的问题
- MASQUERADE，SNAT的特殊形式，适用于动态的、临时会变的IP
- REDIRECT，在本机做端口映射
- LOG，日志记录，可用于规则的调试

## 2.链

chains，链，即数据包报文的传输路径，可以理解为规则的检查清单，每条链都存储有一条或数条按照顺序排列的规则待检查。数据包到达某个链，则按顺序从链中第一条规则一个个的进行匹配，若满足就会根据该条规则所定义的方法处理该数据包，否则将继续检查下一条规则，直到匹配到一条规则为止。若该数据包不符合链中任一条规则，就会根据该链预先定义的默认策略进行处理。就这样，每个检查清单上的匹配过程，最终形成了一条有顺序的链。Iptables默认维护五个链，即：

- PREROUTING，数据包到达本机之后进入路由表之前，即路由前数据过滤，用于目标地址转换（DNAT）
- INPUT，数据包通过路由表后目的地为本机，即入站数据过滤
- FORWARDING，数据包通过路由表后目的地不是本机，即转发数据过滤，用于数据转发
- OUTPUT，数据包由本机产生且向外转发，即出站数据过滤
- POSTROUTIONG，数据包通过路由表后发送到网卡接口之前，即路由后过滤，用于源地址转换（SNAT，MASQUERADE）

## 3.表

tables，表，存储于链中相同功能的规则集合，实际使用时规则定义的入口，也即是明确每种表能够应用于哪些链。Iptables默认维护四张表，即：

- filter，过滤规则表，即控制数据包是否允许进出及转发，默认表，对应内核模iptables_filter，可以控制的链：INPUT、FORWARD 和 OUTPUT
- nat，network address translation，网络地址转换规则表，用于修改数据包IP地址、端口等信息，即控制数据包地址转换，对应内核模块iptables_nat，可以控制的链有：PREROUTING、INPUT、OUTPUT和POSTROUTING
- mangle，修改数据标记位规则表，拆解报文做出修改并重新封装，用于修改数据包的TOS(Type Of Service，服务类型)、TTL(Time To Live，生存周期)指以及为数据包设置Mark标记，以实现Qos(Quality Of Service，服务质量)调整以及策略路由等应用，由于需要相应的路由设备支持，因此应用并不广泛，对应内核模块iptables_mangle，即修改数据包的原数据，可以控制的链有：PREROUTING、INPUT、OUTPUT、FORWARD和POSTROUTING
- raw，跟踪数据表规则表，用于决定数据包是否被状态跟踪机制处理，匹配数据包时优于其他表，对应内核模块iptables_raw，即控制nat表连接追踪机制的启用状况，可以控制的链路有：PREROUTING、OUTPUT

---------

- 注：数据报文必须按顺序匹配每条链上的一个个规则，所以编写的规则顺序极其关键，每条链上各个表被匹配的优先级为：raw ---> mangle ---> nat ---> filter

## 4.链表关系

链是数据报文流转过程中的处理环节，表是某些相似规则的集合，但由于处理环节的分工不同，每个处理环节可能具有不同的表。实际上，除了Ouptput链能同时有四种表，其他链都只有两种或三种表

![iptables001](/img/wiki/iptables/iptables001.jpg)

# 工作流程

![iptables002](/img/wiki/iptables/iptables002.jpg)

- 1.数据包到达网卡，先进入PREROUTING（路由前）链，做路由决策，判断数据包应发往何处，本机或其他机器
- 2.若数据包原目标地址为本机，则数据包前往INPUT（入站）链，到达INPUT链后本机任何进程都可进行接收
- 3.本机程序发送出数据包，经过OUTPUT链到达POSTROUTING（路由后）链，最后由网卡输出。此时，Iptables相当于主机防火墙的作用，过滤数据包用于服务器本机的安全控制
- 4.若数据包原目标地址非本机，即需要转发出去，且内核允许转发，数据包则前往FORWARD链，再经过POSTROUTING（路由后）链，最后由网卡输出。此时，Iptables相当于网络防火墙的作用，作为网关用于数据包的过滤与转发

---------

Iptables防火墙的的配置工作主要就是通过iptables工具添加、修改和删除规则，且必须注意其顺序，语法为：

    iptables [-t table] command [match] [target]
    iptables -t 表名 <-A/I/D/R> 规则链名 [规则号] <-i/o 网卡名> -p 协议名 <-s 源IP/源子网> --sport 源端口 <-d 目标IP/目标子网> --dport 目标端口 -j 动作

- -t，设置所要操作的表，不指定则默认为filter
- command，设置具体操作动作，如对指定链添加/删除规则
- match，设置所要处理的数据包的匹配规则
- target，设置数据包的处理动作

# 1.安装iptables

    sudo yum install -y iptables
    sudo apt install -y iptables
    sudo systemctl start iptables
    sudo systemctl status iptables
    sudo systemctl enable iptables

# 2.查询规则

## 2.1 查询全部规则

    # Chain，所属链；policy ACCEPT，该链默认规则；target，对应处理动作；prot，对应协议；opt，规则对应选项；source，对应源IP或网段；destination，对应目的IP或网段
    iptables -L
    # 查询规则命中，pkts，命中规则报文个数；bytes，命中规则报文总和；in，规则对应的入向接口；out，规则对应的出向接口
    iptables -vL
    # 查询规则显示行号
    iptables -vL --line-number

## 2.2 指定表查询

    iptables -t filter -L

## 2.3 指定链查询

    iptables -L INPUT

# 3.新增规则

- -I <CHAIN>，insert，插入规则，即在指定链规则的首位插入，其后加上#则表示插入到指定链的第#号规则的位置
- -A <CHAIN>，append，追加规则，即在指定链规则的末尾插入
- -s <S_IP>，指定源IP，其前加!表示取反
- -j <ACTION>，指定执行的动作
- -d <D_IP>，指定目标IP
- -i <NIC>，指定网卡入口流量
- -o <NIC>，指定网卡出口流量
- -p <TCP|UDP|ICMP>，指定网络协议

## 3.1 插入规则到首位

    # 查看规则
    iptables -nvL INPUT
    # iptables -t filter -I INPUT -s 1.1.1.1 -j DROP

## 3.2 插入规则到位置

    iptables -I INPUT 3 -s 3.3.3.3 -j ACCEPT

## 3.3 插入规则到末尾

    iptables -A INPUT -s 255.255.255.255 -j ACCEPT

# 4.修改规则

- -R <CHAIN> #，修改指定链中指定序号的规则

## 4.1 修改规则

    # 将INPUT链filter表编号为1的规则为：-s 10.37.129.3 -j ACCEPT
    iptables -t filter -R INPUT 1 -s 10.37.129.3 -j ACCEPT

## 4.2 修改链的默认策略

    # -P，policy，即策略，将FORWARD链的默认规则设置为DROP
    iptables -P FORWARD DROP

- 注：规则的修改操作实质上是将整个规则替换为新规则，而不是只在命令中输入修改部分的内容，非常容易出错，建议将规则删除掉重新编写

# 5.删除规则

- -D <CHAIN>，根据规则的具体匹配条件与动作进行删除，其后加上#则表示根据规则的编号进行删除
- -F <CHAIN>，清空指定链上的所有规则
- -t <TABLE> -F，清空某种表在所有链上的规则

## 5.1 删除指定规则

    iptables -D INPUT -s 1.1.1.1 -j DROP

## 5.2 删除指定编号的规则

    iptables -D INPUT 5

# 6.保存规则

Iptables系统以命令行设置的规则临时有效，系统重启之后即会丢失，其规则保存文件为/etc/sysconfig/iptables，写入到这个文件的规则才会永久生效

## 6.1 当前规则保存到规则文件

    service iptables save

## 6.2 备份规则文件

    iptables-save > iptables.ini
    
## 6.3 从文件恢复规则

    iptables-restore < iptables.ini

# 7.清空规则

    # 清空某个表中所有链上的规则
    iptables -t filter -F

    # 清空链内所有规则，不指定链则清空所有链
    iptables -F INPUT

    # 删除自定义空链，若链内有规则则无法删除
    iptables -X

    # 计数器清零
    iptables -Z

# 8.防火墙配置实例

## 8.1 端口开放

    # 允许本地回环接口，即允许本机访问本机
    iptables -A INPUT -s 127.0.0.1 -d 127.0.0.1 -j ACCEPT
    # 允许已建立的或相关连的通行
    iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
    # 允许所有本机向外的访问
    iptables -A OUTPUT -j ACCEPT
    # 允许访问80端口
    iptables -A INPUT -p tcp --dport 80 -j ACCEPT
    # 允许192.168.1.0/24网段访问22端口
    iptables -A INPUT -s 192.168.1.0/24 -p tcp --dport 22 -j ACCEPT

## 8.2 封禁所有非开放的策略

    # 禁止其他未允许的规则访问
    iptables -A INPUT -j reject
    # 禁止其他未允许的规则访问
    iptables -A FORWARD -j REJECT

## 8.3 设置默认规则

    # 默认封禁所有入口
    iptables -P INPUT DROP
    # 默认封禁所有转发
    iptables -P FORWARD DROP
    # 默认开放所有出口
    iptables -P OUTPUT ACCEPT

## 8.4 白名单配置

    # 允许内网访问
    iptables -I INPUT -p all -s 192.168.1.0/24 -j ACCEPT
    # 允许指定IP访问3306端口
    iptables -I INPUT -p tcp -s 183.121.3.7 --dport 3306 -j ACCEPT

## 8.5 黑名单配置

    # 封禁单个IP
    iptables -I INPUT -s 123.45.6.7 -j DROP
    # 封禁IP段
    iptables -I INPUT -s 123.45.6.0/24 -j DROP
    # 封禁不在指定网段的IP通过网卡ens33的访问
    iptables -I INPUT -p tcp ! -s 192.168.1.0/24 -i ens33 -j DROP

## 8.6 端口映射

    # --dport 80，目的IP为公网IP 80端口的流量包；-j DNAT --to-destination 192.168.0.3:80，改写目的IP为
    内网IP端口，也即将访问公网IP 80端口的流量转发到内网IP的80端口，实现了无公网IP内网服务器的服务发布，解决了流
    量进不来的问题
    iptables -t nat -A PREROUTING -i ppp0 -p tcp --dport 80 -j DNAT --to-destination 192.168.0.3:80

## 8.7 IP映射

    # -s 192.168.100.0/24 -o ens36，经网卡ens36源且IP网段为192.168.100.0/24的出口流量包；
    -j SNAT --to-source 12.0.0.1，改写源IP为公网IP 12.0.0.1，也即将内网服务器的访问流量路由到公网
    IP，实现了内部局域网共享公网IP进行外网访问，解决了流量出不去的问题
    iptables -t nat -A POSTROUTING -s 192.168.100.0/24 -o ens36 -j SNAT --to-source 12.0.0.1

---------

# 参考文档

- https://blog.csdn.net/fly910905/article/details/123690660
- https://blog.csdn.net/chocolee911/article/details/80688200
- https://blog.csdn.net/shujuliu818/article/details/125649998
- https://blog.csdn.net/qq_42197548/article/details/131461599
- https://blog.csdn.net/weixin_44431371/article/details/120034719
- https://blog.csdn.net/weixin_53139887/article/details/122418822