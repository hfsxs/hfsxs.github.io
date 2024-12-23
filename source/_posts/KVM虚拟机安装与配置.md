---
title: KVM虚拟机安装与配置
categories:
  - 工作
tags:
  - Linux
  - KVM
  - 虚拟化
  - 云计算
date: 2020-10-31 10:06:33
---

KVM，Kernel-based Virtual Machine，即基于内核的虚拟机，开源的操作系统虚拟化模块，目前已集成到Linux的各个发行版，用于Linux实现Hypervisor，是基于虚拟化扩展（Intel VT或AMD-V）的X86硬件的原生全虚拟化解决方案

KVM最初由Qumranet公司的Avi Kivity开发，作为VDI产品的后台虚拟化解决方案。为了简化开发，Avi Kivity并没有选择从底层开始新写一个Hypervisor，通过加载模块的方式使Linux变成一个Hypervisor，硬件管理等还是通过Linux kernel来完成。2006年10月，在先后完成了基本功能、动态迁移以及主要的性能优化之后，Qumranet正式对外宣布了KVM的诞生。同月，KVM模块的源代码被正式纳入Linux kernel，成为内核源代码的一部分。KVM支持多种处理器平台，如最常见的以Intel和AMD为代表的x86和x86_64平台，其余如PowerPC、S/390、ARM等非x86架构的平台

# 虚拟化

虚拟化，计算机领域资源管理技术，通过将计算机的各种实体资源(CPU、内 存、存储、网络等)予以抽象和转化，并进行分割、组合，最终实现最大化利用物理资源的解决方案。实现原理是通过引入Virtual Machine Monitor(VMM，虚拟机监控器，也称为Hypervisor) ，将物理主机抽象、分割成多个虚拟的逻辑意义上的主机，向下掌控实际的物理资源，向上支撑多个操作系统及其之上的运行环境和应用程序

## 软件虚拟化和硬件虚拟化

### 1.软件虚拟化技术

软件虚拟化，通过纯软件的环境来模拟执行虚拟机操作系统的指令，如QEMU，原理是通过软件的二进制翻译仿真出目标平台呈现给虚拟机，虚拟机的每一条目标平台指令都会被QEMU截取并翻译成宿主机平台的指令，然后交给实际的物理平台执行。显然，由于新增了模拟翻译工作量，其性能是比较差的，软件复杂度也大大增加。但优点是可以呈现各种平台给虚拟机，只需其二进制翻译支持

### 2.硬件虚拟化技术

硬件虚拟化，计算机硬件本身提供了让客户机指令独立执行的能力，不再完全依赖于VMM。以x86架构为例，其提供一个略微受限制的硬件运行环境供客户机运行（non-root mode），绝大多数情况下客户机在此受限环境中运行与原生系统在非虚拟化环境中运行没有什么区别，不需要像软件虚拟化那样每条指令都先翻译再执行。而VMM运行在root mode，拥有完整的硬件访问控制权限。只在少数必要时，某些客户机指令的运行才需要被VMM截获并做相应处理，之后客户机返回并继续运行于non-root mode。其性能接近于原生系统，且极大地简化了VMM的软件设计架构

## 半虚拟化和全虚拟化

### 1.半虚拟化

Para-Virtualization，即半虚拟化，是基于软件虚拟化的配合VMM，并通过修改虚拟机操作系统代码，将原来在物理机上执行的一些特权指令修改成可以和VMM直接交互的方式，从而实现操作系统的定制化。这样，就不会再有捕获异常、翻译和模拟的过程，性能损耗较少

### 2.全虚拟化

Full Virtualization，即全虚拟化，客户机的操作系统完全不需改动，所有软件都能在虚拟机中运行。由于全虚拟化需要模拟出完整的、和 物理平台一模一样的平台给客户机，将会增加虚拟化层的复杂度

---------

2005年硬件虚拟化兴起之前，软件实现的全虚拟化完败于VMM和客户机操作系统协同运作的半虚拟化。2006年之后以Intel VT-x、VT-d为代表的硬件虚拟化技术的兴起，让由硬件虚拟化辅助的全虚拟化全面超过了半虚拟化。但是，以virtio为代表的半虚拟化技术也一直在演进发展，性能上只是略逊于全虚拟化，加之其较少的平台依赖性，依然受到广泛的欢迎

# 1.体系架构

KVM虚拟化的核心主要由两个模块构成，即KVM内核模块和QEMU

## 1.1 KVM内核模块

KVM模块是KVM虚拟化技术的核心部分，目前已集成于Linux内核，是标准的Linux字符集设备（/dev/kvm），负责宿主机物理CPU和内存的虚拟化，如初始化CPU硬件并打开虚拟化模式、创建虚拟机的内核数据结构、CPU执行模式的切换、vCPU的执行、管理虚拟机的虚拟内存、地址与宿主机物理内存、地址之间的的映射关系等。KVM模块将Linux主机变成为一个虚拟机监视器（VMM），并在原有的Linux两种执行模式基础上新增用于虚拟机运行的客户模式，该客户模式拥有自己独立的内核模式和用户模式

## 1.2 QEMU

QEMU，即Quick Emulator，由法布里斯·贝拉(Fabrice Bellard)以C语言编写的开源的处理器模拟软件，纯软件的实现虚拟化技术，可独立运行，但性能较低。QEMU有两种工作模式：系统模式，可模拟整个计算机系统；用户模式，可运行不同于当前硬件平台的其他平台上的程序，如x86平台运行ARM平台的程序。开源的VirtualBox、Xen虚拟化产品，其核心底层的虚拟化部分就有集成和使用QEMU

---------

KVM为适配QEMU，将其代码进行部分修改，即为QEMU-KVM，再与KVM组合即成为KVM虚拟化平台，二者相互配合完成虚拟化工作

# 2.工作原理

## 2.1 KVM内核

KVM内核运行于内核模式，负责硬件的虚拟化、客户模式的切换及处理因I/O或者其他指令引起的客户模式退出，即异常处理。由于计算机用户无法直接跟内核模块交互，因此借助运行于用户模式的QEMU模拟的设备来实现和内核模式的KVM的交互。KVM模块提供/dev/kvm接口，需要用户空间程序通过借口设置一个客户机虚拟服务器的地址空间，向他提供模拟的I/O，并将它的视频显示映射回宿主的显示屏

## 2.2 QEMU-KVM

QEMU-KVM运行于用户模式，将虚拟机以常规Linux进程的方式创建并运行，并模拟虚拟机的硬件设备，如磁盘，网卡，显卡等。QEMU-KVM通过KVM模块提供的系统接口调用进入内核空间，由KVM模块将虚拟机置于CPU的内核模式运行，IO操作则由KVM模块进行模式切换，将会从上次系统调用的接口返回给QEMU-KVM，最后再由QEMU-KVM负责解析和处理。QEMU-KVM依赖于KVM内核的配合，达到了硬件虚拟化的速度，大大弥补了软件虚拟化性能不足的弱点。此外，由于QEMU模拟IO设备效率不高，目前通常采用半虚拟化的virtio方式虚拟IO设备

## 2.3 KVM虚拟机

KVM虚拟机运行于客户模式，是一个标准的Linux进程，其虚拟CPU对应QEMU进程中的一个执行线程，内存空间被映射到QEMU的进程地址空间，在启动时分配

# 3.工作流程

## 3.1 创建虚拟机

运行于用户模式的Qemu-kvm通过ioctl系统调用操作/dev/kvm字符设备，即kvm模块，创建VM和VCPU

## 3.2 数据结构初始化

KVM内核模块负责数据结构的创建即初始化，然后进行CPU模式切换，返回到用户模式

## 3.3 虚拟机调度

Qemu-kvm通过ioctl调用运行VCPU，即调度相应的虚拟机运行

## 3.4 运行虚拟机

Linux内核进行相关处理后，执行VMLAUNCH指令，通过VM-Entry进入虚拟机并运行于非根模式下

## 3.5 虚拟机执行指令

虚拟机执行非特权指令可直接在宿主机物理CPU上运行，特权指令、外部中断、或虚拟机内部异常时将产生VM-Exit，并将相关信息记录到VMCS（virtual-machine control data structures，虚拟机控制数据结构）

# 4.管理工具

虚拟化解决方案离不开良好的管理和运维工具，部署、运维、管理的复杂度与灵活性是企业实施虚拟化时重点考虑的问题。KVM目前已经有从libvirt API、virsh命令行到OpenStack云管理平台等一整套管理工具，尽管与老牌虚拟化巨头VMware提供的商业化虚拟化管理工具相比在功能和易用性上有所差距，但KVM这一整套管理工具都是API化的、开源的，在使用的灵活性以及对其做二次开发的定制化方面仍有一定优势

## 4.1 libvirt

libvirt，最广为流行的对KVM虚拟化进行管理的工具和应用程序接口，已经是事实上的虚拟化接口标准。作为通用的虚拟化API，不但能管理KVM，还能管理VMware、Hyper-V、Xen、VirtualBox等其他虚拟化方案

## 4.2 virsh

virsh，由C语言编写的使用libvirt API的虚拟化管理工具，源代码也在libvirt这个开源项目中，常用的管理KVM虚拟化的命令行工具，对于系统管理员在单个宿主机上进行运维操作可能是最佳选择

## 4.3 virt-manager

virt-manager，虚拟机图形化管理软件，底层与虚拟化交互的部分仍然是调用libvirt API来操作。virt-manager除了提供虚拟机生命周期（包括：创建、启动、停 止、打快照、动态迁移等）管理的基本功能，还提供性能和资源使用率的监控，同时内置了VNC和SPICE客户端，方便图形化连接到虚拟客户机中。virt-manager在RHEL、 CentOS、Fedora等操作系统上是非常流行的虚拟化管理软件，在管理的机器数量规模较小时，virt-manager是很好的选择。因其图形化操作的易用性，成为新手入门学习虚拟化操作的首选管理软件

## 4.4 OpenStack

OpenStack，开源的基础架构即服务（IaaS）云计算管理平台，可用于构建共有云和私有云服务的基础设施，是目前业界使用最广泛功能最强大的云管理平台，不仅提供了管理虚拟机的丰富功能，还有非常多其他重要管理功能，如对象存储、块存储、网络、镜像、身份验证、编排服务、控制面板等，同样是基于libvirt API来完成对底层虚拟化的管理

---------

# 1.查看宿主机是否开启虚拟化功能

    # 若为0表示未开启，重启进入BIOS开启
    egrep '(vmx|svm)' /proc/cpuinfo|wc -l

# 2.安装kvm

    sudo yum -y install qemu-kvm libvirt virt-install
    sudo apt -y install qemu qemu-kvm libvirt-bin virtinst libosinfo-bin
    sudo apt -y install qemu qemu-kvm libvirt-daemon-system libvirt-clients virtinst libosinfo-bin

# 3.将当前用户添加到libvirt组用于管理虚拟机

    sudo usermod -a -G libvirt $USER

# 4.启动kvm管理工具进程

    sudo systemctl start libvirtd
    sudo systemctl enable libvirtd

# 5.安装虚拟机

## 5.1 查看可用操作系统类型

    osinfo-query os

## 5.2 安装centos7虚拟机

    sudo virt-install \
    --name=centos7 --memory=1024,maxmemory=2048 --vcpus=1,maxvcpus=2 --os-variant=centos7.0 \
    --location=/home/kvm/images/CentOS-7-x86_64-Minimal-2009.iso --disk /home/kvm/templates/centos7.qcow2,size=30 --network network=default \
    --graphics=none --console=pty,target_type=serial --extra-args='console=ttyS0'

## 5.3 安装debian10虚拟机

    sudo virt-install \
    --name=debian10 --memory=1024,maxmemory=2048 --vcpus=1,maxvcpus=2 --os-variant=debian10 \
    --location=/home/kvm/images/debian-10.9.0-amd64-netinst.iso --disk /home/kvm/templates/debian10.qcow2,size=30 --network network=default \
    --graphics=none --console=pty,target_type=serial --extra-args='console=ttyS0'

## 5.4 安装ubuntu18虚拟机

    sudo virt-install \
    --name=ubuntu18 --memory=1024,maxmemory=2048 --vcpus=1,maxvcpus=2 --os-variant=ubuntu18.04 \
    --location=/home/kvm/images/ubuntu-18.04.5-server-amd64.iso --disk /home/kvm/templates/ubuntu18.qcow2,size=30 --network network=default \
    --graphics=none --console=pty,target_type=serial --extra-args='console=ttyS0'

# 6.常用虚拟机管理命令

    # 查看所有虚拟机状态
    sudo virsh list –all
    # 启动虚拟机centos7
    sudo virsh start centos7
    # 设置虚拟机开机启动
    sudo virsh autostart centos7
    # 解除虚拟机自动启动
    sudo virsh autostart --disable centos7
    # 进入虚拟机
    sudo virsh console centos7
    # 挂起虚拟机
    sudo virsh suspend centos7
    # 恢复挂起的虚拟机
    sudo virsh resume centos7
    # 关闭虚拟机
    sudo virsh shutdown centos7
    # 强制关闭虚拟机
    sudo virsh destroy centos7
    # 删除虚拟机，只删除配置文件，保留虚拟机磁盘
    sudo virsh undefine centos7

# 7.克隆虚拟机

    # 克隆之前先关闭虚拟机
    sudo virsh shutdown centos7
    sudo virt-clone -o centos7 -n master -f /home/kvm/servers/master.qcow2

# 8.kvm开启虚拟机嵌套虚拟化

## 8.1 查看宿主机是否已开启嵌套虚拟化功能

    cat /sys/module/kvm_intel/parameters/nested

## 8.2 创建配置文件

    vi /etc/modprobe.d/kvm-nested.conf


    options kvm-intel nested=1
    options kvm-intel enable_shadow_vmcs=1
    options kvm-intel enable_apicv=1
    options kvm-intel ept=1

## 8.3 关闭所有虚拟机，重新启用kvm_intel模块

    modprobe -r kvm_intel
    modprobe -a kvm_intel

## 8.4 验证嵌套虚拟化功能

    cat /sys/module/kvm_intel/parameters/nested

## 8.5 设置虚拟机配置文件支持嵌套虚拟化

    virsh edit node01


    <cpu mode='custom' match='exact'>

      # 开启虚拟机嵌套功能
      <feature policy='require' name='vmx'/>

    </cpu>

## 8.6 开启虚拟机，验证嵌套虚拟化功能

---------

# 参考文档

- https://cloud.tencent.com/developer/article/1079148
- https://blog.csdn.net/yulsh/article/details/91790804
- https://blog.csdn.net/weixin_30875157/article/details/97096593