---
title: Linux系统内核优化
categories:
  - 工作
tags:
  - Linux
  - 性能优化
  - 云计算
date: 2023-06-10 18:40:59
---

Linux系统内核参数默认值的设定通常偏向稳定保守，目的是以性能换取稳定，适用于通用场景，并不符合高并发量的生产环境。因此，根据实际业务特性与需求优化内核参数，是系统稳定高效运行的强有力的保障，可充分发挥服务器硬件计算能力、提高资源利用以及节省硬件成本。但由于内核程序极其庞大与复杂，参数的数量繁多，某个功能的新增或修改很有可能影响其他功能，甚至导致整个系统的崩溃。所以，一定要结合实际的场景进行优化，切忌过度优化，优化的参数需要具体了解其功能，以免出现不必要的问题

# /proc

/proc，虚拟文件系统，用于内核参数的调整，动态存储于内存，原理是将内核运行的关键数据结构以文件方式呈现于该虚拟文件系统目录中的特定文件，相当于将不可见的数据结构以可视化的方式呈现出来，调试内核参数即可通过实时观察这些文件来判断其作用。这些文件只是类似于接口的存在，并不是真实文件，故其文件大小都为0，对其的的调用只是内核数据结构的映射。文件目录如下：

- cmdline，系统启动时输入给内核命令行参数
- cpuinfo，CPU的硬件信息，如型号、家族、缓存大小等
- devices，主设备号及设备组的列表，当前加载的各种设备，如块设备、字符设备
- dma，使用的DMA通道
- filesystems，当前内核支持的文件系统，用于为mount命令指定文件系统
- interrupts ，中断的使用及触发次数，调试中断时很有用
- ioports，即IO端口，当前在用的已注册的I/O端口范围
- kcore，伪文件，以core文件格式给出系统物理内存映象，可用GDB查探当前内核的任意数据结构，对应dmesg命令，可取代系统调用syslog记录内核日志
- kallsym，内核符号表，文件保存了内核输出的符号定义, modules(X)使用该文件动态地连接和捆绑可装载的模块
- loadavg，平均负载，给出了在过去的 1、 5、15分钟里在运行队列里的任务数、总作业数以及正在运行的作业总数
- locks，内核锁
- meminfo，物理内存、交换空间等信息，系统内存占用情况，对应df命令
- misc，杂项
- modules，已加载的模块列表，对应lsmod命令
- mounts，已加载的文件系统的列表，对应mount命令，无参数
- partitions，系统识别的分区表
- slabinfo，sla池信息
- stat，全面统计状态表，CPU内存的利用率等都是从这里提取数据，对应ps命令
- swaps，对换空间的利用情况
- sys，存放硬件设备的驱动程序信息，可通过/sys/block优化磁盘I/O
- version，指明当前正在运行的内核版本

Linux系统内核参数按照功能大体分为网络相关参数、文件系统参数、内存参数以及内核参数几类，




    # 设置系统进程最大打开文件数，即系统当前最大文件句柄数，系统级别的限制，默认值通常与物理内存有关，配合单个进程最大打开文件数ulimit的open file值（默认1024），达到高并发业务的需求
    fs.file-max = 6553560


    # 设置是否启用非本地IP地址socket监听，作为网关、反向代理或负载均衡双机热备高可用绑定虚拟VIP时须开启
    net.ipv4.ip_nonlocal_bind = 1
    # 设置是否启用IPv4转发，作为路由网关、反向代理与负载均衡开启客户端IP透传时须开启
    net.ipv4.ip_forward = 1 
    # 设置是否启用重用，即是否将TIME_WAIT状态的socket重新用于新的TCP链接，适用于高并发场景，默认为0
    net.ipv4.tcp_tw_reuse = 1
    # 设置是否将TIME-WAIT状态的socket重新用于新的TCP连接，适用于高并发场景，快速回收TIME-WAIT状态的连接
    net.ipv4.tcp_tw_recycle = 1
    # 设置启用keepalive长连接时，TCP发送keepalive消息的频度，默认为2小时，设为10分钟可更快清理无效链接
    net.ipv4.tcp_keepalive_time = 600
    # 设置启用keepalive长连接时，超时探测包的发送次数
    net.ipv4.tcp_keepalive_probes = 3
    # 设置启用keepalive长连接时，探测包的发送间隔，单位为秒
    net.ipv4.tcp_keepalive_intvl = 15 




    # 设置是否开启TCP时间戳，默认为0
    net.ipv4.tcp_timestamps = 1









---------

# 参考文档

- https://www.cnblogs.com/eddie1127/p/11806372.html


https://www.cnblogs.com/soymilk2019/p/13725248.html
https://blog.csdn.net/weixin_42255494/article/details/116497513
https://blog.csdn.net/alwaysbefine/article/details/123858239
https://www.lxlinux.net/311.html