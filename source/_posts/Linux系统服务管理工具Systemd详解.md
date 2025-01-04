---
title: Linux系统服务管理工具Systemd详解
categories:
  - 工作
tags:
  - Linux
  - init
  - Systemd
  - 操作系统
  - 云计算
date: 2024-03-25 10:05:24
---

Systemd，当前Linux发行版最为流行的init系统和服务管理工具，通过套接字激活机制，使得无论有无依赖关系的程序全部并行启动，且仅按照系统启动的需要启动相应的服务，最大化地加快启动速度。Systemd使用单个配置文件管理所有服务，并提供了丰富的命令行工具。此外，Systemd还支持动态加载和卸载服务，可以在系统运行时添加或删除服务

# 1.init系统

init，即系统初始化进程，Linux系统启动的第一个进程，是其他所有进程的起点，pid为1。其发展大体上分为三个阶段，即sysvinit -> upstart -> systemd

## 1.1 sysvinit

类Unix系统最初启用的init初始化系统，以脚本的形式管理系统服务，按照特定的顺序启动系统服务，并运行对应的启动脚本。由于启动方式为按照顺序逐个的串行启动，所以启动速度较慢，目前基本已弃用

## 1.2 Upstart

最初由Ubuntu8.04启用，以事件驱动，支持并行启动多个服务，启动速度大大加快，能够自动监测服务的状态，且服务崩溃或停止运行时支持自动重启

## 1.3 Systemd

当前最新的初始化系统和系统管理器，由于其高效的性能和简便的管理，大多数Linux发行版当前都以其取代传统的SysV，以完成初始化系统。Systemd，最初由Fedora15启用，以.service服务文件将所有守护进程加入到cgroups排序，而不是像SysVinit那样使用bash脚本，可通过/cgroup/systemd文件查看系统等级，兼容SysV和LSB初始化脚本。其管理命令为systemctl，是管理Systemd守护进程及服务的工具，如开启、重启、关闭、启用、禁用、重载和状态

# 2.​Systemd架构

## 2.1 第一层

​​内核层​​面依赖，如cgroup、autofs、kdbus

## 2.2 第二层

libraries​，依赖库​

## 2.3 第三层

​Systemd Core​​，systemd核心库

## 2.4 第四层

​Systemd daemons​​及targets，自带的基本unit、target，类似于sysvinit自带的脚本

## 2.5 第五层

命令行工具，如systemctl，用户通过其进行操作Systemd

# 3.工作机制

Unit，​Systemd管理和控制系统资源、服务或任务的基本配置单元，用于定义系统服务和其他资源，包括服务的启动顺序、依赖关系、部署状态等，每个unit都有名称、类型和配置文件，如docker.service、mysql.socket等。Systemd通过配置单元文件，来定义所有的管理工作

## 3.1 单元类型

### 3.1.1 Service unit

.service服务，用于封装后台服务进程的单元

### 3.1.2 Target unit

.target服务，为其他配置单元进行逻辑分组的单元，本身实际上并不做什么，只用于引用其他配置单元，从而对配置单元做一个统一的控制。此外，还可以实现进程运行级别，如系统图形化模式需要运行的许多服务和配置命令都由一个个配置单元表示，将所有这些配置单元组合为一个目标(target)，即表示将这些配置单元全部执行一遍（multi-user.target，相当于传统SysV系统的运行级别5）

### 3.1.3 Device Unit

.device服务，封装Linux设备树中的某个设备的单元，每个使用udev规则标记的设备都将在Systemd中作为一个设备配置单元

### 3.1.4 Mount Unit

.mount服务，封装文件系统结构层次中挂载点的单元，以完成挂载点的监控和管理，如系统启动自动挂载、某些条件的自动卸载等等，即将/etc/fstab文件中的条目都转换为挂载点，并在开机时处理

### 3.1.5 Automount Unit

.automount服务，封装系统结构层次中自动挂载点的单元，该单元对应一个挂载配置单元，并于系统启动时被触发，从而执行挂载点定义的挂载操作

### 3.1.6 Path Unit

.path服务，文件系统的文件或目录，用于监控指定目录或文件的变化，并触发其它Unit

### 3.1.7 Scope Unit

用于cgroups，表示Systemd外部创建的进程，即由Systemd运行产生的、不是由用户创建的文件，描述一些系统服务的分组信息

### 3.1.8 Slice Unit

.slice服务，进程组，用于cgroups，表示一组按层级排列的单位，并不包含进程，但会组建一个层级，并将scope和service都放置其中

### 3.1.9 Snapshot Unit

.snapshot服务，用于表示由Systemctl snapshot命令创建的单元运行状态的快照，类似于target，保存了系统当前的运行状态，是一组配置单元

### 3.1.10 Socket Unit

.socket服务，封装系统和互联网中的套接字，有一个相应的服务配置单元，相应的服务在第一个客户端连接进入套接字时就会启动，如nscd.socket在有新连接后便启动nscd.service，支持流式、数据报和连续包的AF_INET、AF_INET6、AF_UNIX socket

### 3.1.11 Swap Unit

.swap服务，类似于Mount单元，用于管理交换分区，使得交换分区在启动时被激活

### 3.1.12 Timer Unit

.timer服务，定时器配置单元，用于定时触发用户定义的操作，类似于atd、crontab等传统的定时服务

## 3.2 配置文件目录

- /etc/systemd/system.conf，Systemd全局配置文件
- /etc/systemd/logind.conf，登录管理器的配置文件，用于管理用户登录时的会话
- /etc/systemd/systemd-journald.conf，journal日志配置文件，用于管理系统日志
- /etc/systemd/timesyncd.conf，timesyncd时间同步服务配置文件
- /etc/systemd/system/，所有系统服务单元文件的配置文件，包括启动时运行的系统服务和用户服务
- /usr/lib/systemd/system/，所有已安装软件的服务单元文件，包括系统服务和第三方软件服务
- /run/systemd/system/，所有正在运行的服务单元文件，基于/etc/systemd/system/和/usr/lib/systemd/system/目录中的文件生成
- /etc/systemd/user/，用户定义的服务单元文件，用户登录时自动启动
- /usr/lib/systemd/systemd-sleep，系统睡眠模式相关的服务脚本

## 3.3 配置文件

Unit配置文件由三部分组成，即Unit、Service和Install段

### 3.3.1 Unit

Unit段所有Unit文件通用，用于定义Unit的元数据、配置及与其他Unit的关系

- Description，Unit描述信息
- Documentation，Unit说明文档
- Requires，强依赖关系，即所依赖的Unit未启动时当前Unit也不能启动
- BindsTo，强依赖关系，即所依赖的Unit未启动时当前Unit也不能启动，且强依赖终止或重启时当前Unit也会跟随其状态
- Wants，弱依赖关系，即所依赖的Unit未启动时当前Unit也可启动
- After，先后依赖关系，即当前Unit需在其全部启动之后才能启动
- Before：与After相反，即当前Unit启动之后才会启动其指定的Unit
- RequiresOverridable，类似于Requires，但允许在启动时覆盖依赖的Unit，如在容器中运行
- PartOf，从属关系，即当前Unit是其一部分，随其终止而终止
- Conflicts，互斥关系，即当前Unit不能与其一起启动
- OnFailure，当前Unit启动失败时，就将自动启动其指定的Unit

### 3.3.2 Service

service段是服务（Service）类型Unit特有的字段，用于定义服务的具体管理和执行动作

#### 3.3.2.1 生命周期控制

Type，定义启动进程行为
- simple，默认值，表示执行ExecStart指定的命令，启动主进程
- forking，表示以fork方式从父进程创建子进程，创建后父进程立即退出
- oneshot，表示启动一次性进程，当前服务退出后再继续执行
- dbus，表示当前服务通过D-Bus启动
- notify，表示当前服务启动完毕将会通知Systemd，再继续执行
- idle，表示其他任务执行完毕才会运行当前服务
- PrivateTmp，是否启用私有临时文件目录，设为true则会在/tmp目录生成类似systemd-private-*-apache.service-RedVyu的文件夹，以提高文件的安全性，且该目录会随服务的重启而自动清理，无需再定义临时目录清理规则
- RemainAfterExit，默认为false，配置为true表示Systemd只会负责启动服务进程，之后即便服务进程退出了，也仍然会认为这个服务还在运行中，主要用于启动注册后立即退出的非常驻内存，且需等待消息按需启动的特殊类型服务

#### 3.3.2.2 服务启动控制

- ExecStart，当前服务的启动命令
- ExecStartPre，当前服务启动之前执行的命令
- ExecStartPost，当前服务启动之后执行的命令
- ExecReload，当前服务重启时执行的命令
- ExecStop，当前服务停止时执行的命令
- ExecStopPost，当前服务停止之后执行的命令
- RestartSec，当前服务退出时自动重启间隔的秒数
- Restart，当前服务退出时自动重启的模式，no，默认值，退出后不自动重启；on-success，正常退出即退出码为0时自动重启；on-failure，非正常退出即退出码不为0时自动重启，包括被信号终止或超时，建议守护进程设为此值；on-abnormal，被信号终止或超时才会自动重启；on-abort，收到没有捕捉到终止信号时才会自动重启；on-watchdog，超时退出时才会自动重启；always，无论是什么原因总是重启
- TimeoutStartSec，启动服务等待时长，单位为秒，超时则将判断为启动失败，特别对于Docker容器而，由于第一次运行时可能需要下载镜像，很容易被误判为启动失败杀死，可设置为0，即关闭超时检测
- TimeoutStopSec，停止服务时的等待秒数，超时则将通过SIGKILL信号强行终止服务进程
- KillMode，当前服务停止的方式，control-group，默认值，表示当前控制组所有子进程都被kill；process，主进程被kill；mixed，主进程收到SIGTERM信号，子进程收到SIGKILL信号；none，没有进程会被杀掉，只是执行服务的stop命令

#### 3.3.2.3 上下文配置

- Environment，设置服务的环境变量
- EnvironmentFile，指定加载一个包含服务所需的环境变量的列表的文件，文件中的每一行都是一个环境变量的定义，该文件内部的key=value键值对，可以用$key的形式，在当前配置文件中获取
- Nice，设置服务的进程优先级，值越小优先级越高，默认为0，-20为最高优先级，19为最低优先级
- WorkingDirectory，设置服务的工作目录
- RootDirectory，指定服务进程的根目录，服务将无法访问指定目录以外的任何文件
- User，设置运行服务的用户
- Group，设置运行服务的用户组
- MountFlags，设置服务的Mount Namespace，影响进程上下文中挂载点的信息，即服务是否会继承主机上已有挂载点，以及如果服务运行执行了挂载或卸载设备的操作，是否会真实地在主机上产生效果，shared，服务与主机共用一个Mount Namespace，继承主机挂载点，且服务挂载或卸载设备会真实地反映到主机上；slave，服务使用独立的Mount Namespace，能继承主机挂载点，但对挂载点的操作只有在自己的Namespace内生效，不会反映到主机上；private，服务使用独立的Mount Namespace，启动时没有任何任何挂载点，对挂载点的操作也不会反映到主机上
- LimitCPU/LimitSTACK/LimitNOFILE/LimitNPROC，限制服务占用的系统资源，如CPU、程序堆栈、文件句柄数量、子进程数量等

#### 3.3.2.4 输出日志控制

Systemd输出日志到journal，不指定则默认syslog

- StandardError=journal
- StandardOutput=journal
- StandardInput=null

#### 3.3.2.5 文件占位符

Unit文件可能会需要使用到一些与运行环境有关的信息，如节点ID、运行服务的用户等，这些信息由占位符表示，实际运行被动态地替换实际的值

- %n，完整的Unit文件名字，包括.service后缀名
- %p，Unit模板文件名中@符号之前的部分，不包括符号@
- %i，Unit模板文件名中@符号之后的部分，不包括符号@和.service后缀名
- %t，存放系统运行文件的目录，通常为run
- %u，运行服务的用户，不指定则默认为root
- %U，运行服务的用户ID
- %h，运行服务的用户家目录，即%{HOME}环境变量的值
- %s，运行服务的用户默认Shell类型，即%{SHELL}环境变量的值
- %m，实际运行节点的机器ID，用于标识服务的运行位置
- %b，Boot ID，随机数，每个节点各不相同，并且每次节点重启时都会改变
- %H，实际运行节点的主机名
- %v，系统操作内核版本，即uname -r命令的输出
- %%，Unit模板文件中表示一个普通的百分号

## 3.4 Install

Install部分配置的目标模块通常是特定运行目标的.target 文件，使得服务开机自启

- WantedBy，类似于Unit部分的Wants，表示依赖当前Unit的模块，其值为一个或多个Target，当前Unit激活时（enable）符号链接将会被放入/etc/systemd/system目录，并以<Target 名> + .wants后缀构成子目录，如/etc/systemd/system/multi-user.target.wants/
- RequiredBy，类似于Unit部分的WantedBy，当前Unit激活时，符号链接将会被放入/etc/systemd/system，并以<Target 名> + .required后缀构成子目录
- Also，当前Unit enable/disable时，同时enable/disable的其他Unit
- Alias，当前Unit可用于启动的别名

## 3.5 单元状态

- active (running)，正在运行
- active (exited)，已完成运行并退出
- inactive (dead)，Unit已经停止运行
- activating (start)，正在启动
- activating (auto-restart)，正在自动重启
- deactivating (stop)，正在停止
- deactivating (restart)，正在重启
- failed，启动失败，或者在运行过程中突然停止

# 4.服务生命周期

- 加载阶段，Systemd加载服务的Unit文件，并根据配置启动或禁止服务
- 准备阶段，Systemd准备服务的启动环境，包括设置环境变量、创建所需目录、检查依赖关系等操作
- 启动阶段，Systemd启动服务，执行服务的启动命令或程序，并记录服务的PID
- 运行阶段，服务正常运行期间，Systemd监视服务的状态，并记录日志、处理信号等操作
- 停止阶段，服务需要停止时，Systemd发送stop信号给服务进程，并等待服务进程退出
- 停止后处理阶段，服务进程退出后，Systemd执行服务的停止后处理命令或程序，并记录服务的退出状态
- 卸载阶段，服务不再需要时，Systemd卸载服务的Unit文件，并清理相关的运行时文件和日志

# 5.配置实例

    sudo vi /lib/systemd/system/docker.service

    
    [Unit]
    Description=Docker Application Container Engine
    Documentation=https://docs.docker.com
    BindsTo=containerd.service
    After=network-online.target firewalld.service containerd.service
    Wants=network-online.target
    Requires=docker.socket

    [Service]
    Type=notify
    ExecStart=/usr/bin/dockerd -H fd:// --containerd=/run/containerd/containerd.sock
    ExecReload=/bin/kill -s HUP $MAINPID
    TimeoutSec=0
    RestartSec=2
    Restart=always
    StartLimitBurst=3
    StartLimitInterval=60s
    LimitNOFILE=infinity
    LimitNPROC=infinity
    LimitCORE=infinity
    TasksMax=infinity
    Delegate=yes
    KillMode=process

    [Install]
    WantedBy=multi-user.target

# 6.相关命令

## 6.1 状态查询

    # Systemd系统状态
    systemctl status

    # Unit状态
    sysystemctl status httpd.service

    # 远程主机Unit状态
    systemctl -H root@hostname.example.com status httpd.service

    # Unit是否正在运行
    systemctl is-active httpd.service

    # Unit是否处于启动失败状态
    systemctl is-failed httpd.service

    # Unit是否开机自启
    systemctl is-enabled httpd.service

    # 所有启动的Unit
    systemctl list-units

    # 查询系统默认的target
    systemctl get-default

    # 设置默认Target 
    sudo systemctl set-default multi-user.target

    # 切换Target默认不会关闭原来Target启动的进程，改命令即可达到这个效果
    sudo systemctl isolate multi-user.target

    # 查看target类型
    systemctl list-unit-files --type=target

    # target包含哪些unit
    systemctl list-dependencies multi-user.target
    
    # 查看配置文件
    systemctl cat multi-user.target

# 6.2 服务管理

    # 启动服务
    sudo systemctl start apache.service

    # 停止服务
    sudo systemctl stop apache.service

    # 重启服务
    sudo systemctl restart apache.service

    # kill服务的所有子进程
    sudo systemctl kill apache.service

    # 重载服务配置文件
    sudo systemctl reload apache.service

    # 重载所有修改过的配置文件
    sudo systemctl daemon-reload

    # 设置开机自启，将在/etc/systemd/system/建立服务的符号链接，并指向/usr/lib/systemd/system/
    systemctl enable apache.service

    # 取消开机自启
    systemctl disable apache.service

    # 查看Unit的所有底层参数
    systemctl show httpd.service

    # 显示Unit指定属性的值
    systemctl show -p CPUShares httpd.service

    # 设置Unit的指定属性
    sudo systemctl set-property httpd.service CPUShares=500

# 6.3 日志管理

    # 查看sshd服务日志
    journalctl -u sshd
    # 查看sshd服务日志，并直接跳转到日志末尾
    journalctl -eu sshd
    # 查看sshd服务日志，并直接跳转到日志末尾，同时打印可用的服务描述
    journalctl -xeu sshd
    # 以实时更新的方式查看sshd服务日志
    journalctl -u sshd -f
    # 读取journal文件内容，一般存放于/run/log/journal/ 
    journalctl --file ${FILENAME}

# 6.4 系统时间管理

timedatectl用于管理系统时间

    # 列出所有时区
    timedatectl list-timezones
    # 修改系统时区为Asia/Shanghai
    timedatectl set-timezone Asia/Shanghai
    # 修改系统时间
    timedatectl set-time "2022-2-20 12:00:00"

# 6.5 主机信息管理

hostnamectl用于管理当前主机的信息

    # 显示主机信息，如主机名、主机类型、虚拟化技术、CPU架构、内核版本、操作系统等
    hostnamectl
    # 设置主机名，通过su -命令重新加载终端或重新登录系统即可生效
    hostnamectl set-hostname hostname.example.com

# 6.6 本地化设置管理

localectl用于查看本地化设置

    # 显示本地化配置
    localectl
    # 设置本地语言，配置为英文
    localectl set-locale LANG=en_GB.utf8

---------

# 参考文档

- https://juejin.cn/post/6992390303814516749
- https://blog.csdn.net/qiqi_6666/article/details/131688840
- https://blog.csdn.net/yuelai_217/article/details/130949299