---
title: Linux系统磁盘扩容方案
categories:
  - 工作
tags:
  - Linux
  - LVM
  - 磁盘分区
  - 存储
  - 云计算
date: 2020-02-06 20:12:06
---

LVM，Logical Volume Manager，即逻辑卷管理，Linux系统磁盘分区管理机制，是建立在硬盘和分区之上的一个逻辑层，为文件系统屏蔽了下层磁盘分区布局，从而提高磁盘分区管理的灵活性。其工作机制是将若干磁盘分区连接为一个整块的卷组（Volume Group），从而形成一个存储池，系统管理员可以从存储池随意创建逻辑卷组（Logical Volumes），最终在逻辑卷组上创建文件系统。由此，可以灵活方便地调整存储卷组的大小，并对磁盘存储按照组的方式命名、管理和分配，如按照使用用途进行定义development和sales，而不是使用物理磁盘名sda和sdb。若系统添加了新的磁盘，也不必将磁盘的文件移动到新的磁盘，而是通过LVM直接扩展文件系统，即可实现跨越磁盘的扩容。此外，LVM机制还适用于快照、热备份和数据动态迁移的场景，当某个物理硬盘出现故障时，可以在不停机的情况下进行数据恢复和重建从而提高了数据的可靠性与可用性

# 核心概念

## 1.PV

PV，Physical Volume，即物理卷，LVM的基本存储逻辑块，处于最底层，可以是整个硬盘、硬盘上的分区或从逻辑上与磁盘分区具有同样功能的设备，如hda1、sda1, c0d0p1、raid等。其基本单元为PE，Physical Extent，即物理区域，是具有唯一编号的可以被LVM寻址的最小存储单元，大小可根据实际情况在创建物理卷时指定，默认为4MB，大小确定后将不能改变，且同一个卷组中的所有物理卷的PE的大小需一致

## 2.VG

VG，Volume Group，即逻辑卷组，基于物理卷所建立的操作系统逻辑上的硬盘，相当于非LVM系统的物理硬盘，由一个或多个PV组成且可动态地添加，一个或多个VG即构成一个LVM系统。基于VG即可建立逻辑分区（LV，Logical Volume），相当于非LVM系统中的硬盘分区，其上可创建文件系统，如/root、/home等，且大小可伸缩

# 2.创建流程

## 2.1 创建物理卷

pvcreate命令用于将物理磁盘或分区创建为物理卷

## 2.2 创建卷组

vgcreate命令用于将多个物理卷组成一个卷组

## 2.3 创建逻辑卷

lvcreate命令用于在卷组上创建逻辑卷

## 2.4 格式化逻辑卷

mkfs命令用于格式化逻辑卷，以便挂载使用

## 2.5 挂载逻辑卷

mount命令用于将逻辑卷挂载到指定的目录下

---------

# 1.安装LVM

    yum install -y lvm
    apt install -y lvm

# 2.添加磁盘

## 2.1 查看当前磁盘

    lsblk


    NAME MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT                                                                                  
    sr0   11:0    1 1024M  0 rom                                                                                              
    vda   252:0    0  256G  0 disk                                                                                             
    ├─vda1  252:1    0    1G  0 part /boot                                                                                       
    └─vda2  252:2    0  255G  0 part                                                                                             
      ├─centos_centos7-root 253:0 0 50G 0 lvm  /                                                                                           
      ├─centos_centos7-swap 253:1 0 2G 0 lvm  [SWAP]                                                                                      
      └─centos_centos7-home 253:2 0 203G 0 lvm  /home                                                                                       
    vdb   252:16   0  100G  0 disk

## 2.2 查看当前系统分区

    fdisk -l


    Disk /dev/vda: 274.9 GB, 274877906944 bytes, 536870912 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk label type: dos
    Disk identifier: 0x0007a3a7

       Device Boot      Start         End      Blocks   Id  System
    /dev/vda1   *        2048     2099199     1048576   83  Linux
    /dev/vda2         2099200   536870911   267385856   8e  Linux LVM

    Disk /dev/mapper/centos_centos7-root: 53.7 GB, 53687091200 bytes, 104857600 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/mapper/centos_centos7-swap: 2147 MB, 2147483648 bytes, 4194304 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/mapper/centos_centos7-home: 218.0 GB, 217961201664 bytes, 425705472 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes


    Disk /dev/vdb: 107.4 GB, 107374182400 bytes, 209715200 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes

## 2.3 查看当前文件系统 

    df -h


    Filesystem                       Size  Used Avail Use% Mounted on
    devtmpfs                         908M     0  908M   0% /dev
    tmpfs                            919M     0  919M   0% /dev/shm
    tmpfs                            919M  8.6M  911M   1% /run
    tmpfs                            919M     0  919M   0% /sys/fs/cgroup
    /dev/mapper/centos_centos7-root   50G  2.0G   49G   4% /
    /dev/mapper/centos_centos7-home  203G   33M  203G   1% /home
    /dev/vda1                       1014M  223M  792M  22% /boot
    tmpfs                             82M     0   82M   0% /run/user/1000
    tmpfs                             82M     0   82M   0% /run/user/0

# 3.查看当前逻辑卷组

    vgdisplay


    --- Volume group ---
    VG Name               centos_centos7
    System ID             
    Format                lvm2
    Metadata Areas        1
    Metadata Sequence No  4
    VG Access             read/write
    VG Status             resizable
    MAX LV                0
    Cur LV                3
    Open LV               3
    Max PV                0
    Cur PV                1
    Act PV                1
    VG Size               <255.00 GiB
    PE Size               4.00 MiB
    Total PE              65279
    Alloc PE / Size       65278 / 254.99 GiB
    Free  PE / Size       1 / 4.00 MiB
    VG UUID               lLM9n5-z4TE-QIfp-NzXY-LVrS-gfRt-G4wnW0

# 4.基于新磁盘创建物理卷

## 4.1 创建物理卷

    pvcreate /dev/vdb
      Physical volume "/dev/vdb" successfully created.

## 4.2 验证物理卷

    pvscan 
      PV /dev/vdb    VG lvm00            lvm2 [<100.00 GiB / 96.00 MiB free]
      PV /dev/vda2   VG centos_centos7   lvm2 [<255.00 GiB / 4.00 MiB free]
      Total: 2 [354.99 GiB] / in use: 2 [354.99 GiB] / in no VG: 0 [0   ]

    pvdisplay 
      --- Physical volume ---
      PV Name               /dev/vdb
      VG Name               lvm00
      PV Size               100.00 GiB / not usable 4.00 MiB
      Allocatable           yes 
      PE Size               4.00 MiB
      Total PE              25599
      Free PE               24
      Allocated PE          25575
      PV UUID               oJo0QX-053y-pmGd-1uVQ-9ucZ-I6Rk-7YUDEj

# 5.基于物理卷创建逻辑卷组

## 5.1 创建逻辑卷组

    vgcreate lvm00 /dev/vdb
      Volume group "lvm00" successfully created

## 5.2 验证逻辑卷组

    vgscan 
      Reading volume groups from cache.
      Found volume group "lvm00" using metadata type lvm2
      Found volume group "centos_centos7" using metadata type lvm2

    vgdisplay 
      --- Volume group ---
      VG Name               lvm00
      System ID             
      Format                lvm2
      Metadata Areas        1
      Metadata Sequence No  2
      VG Access             read/write
      VG Status             resizable
      MAX LV                0
      Cur LV                1
      Open LV               1
      Max PV                0
      Cur PV                1
      Act PV                1
      VG Size               <100.00 GiB
      PE Size               4.00 MiB
      Total PE              25599
      Alloc PE / Size       25575 / 99.90 GiB
      Free  PE / Size       24 / 96.00 MiB
      VG UUID               Se1Djo-IpJw-vj9b-2eBm-WrH6-mLLb-2rb4w1

# 6.基于逻辑卷组创建逻辑卷

## 6.1 创建逻辑卷

    lvcreate -L 99.9G -n data lvm00

## 6.2 验证逻辑卷

    lvscan
      ACTIVE            '/dev/lvm00/data' [99.90 GiB] inherit
      ACTIVE            '/dev/centos_centos7/swap' [2.00 GiB] inherit
      ACTIVE            '/dev/centos_centos7/home' [202.99 GiB] inherit
      ACTIVE            '/dev/centos_centos7/root' [50.00 GiB] inherit

    lvdisplay 
      --- Logical volume ---
      LV Path                /dev/lvm00/data
      LV Name                data
      VG Name                lvm00
      LV UUID                59KnzQ-a5rz-NwKP-a3aI-mgB3-dy2B-zdj3wX
      LV Write Access        read/write
      LV Creation host, time centos7, 2020-02-06 20:22:34 +0800
      LV Status              available
      # open                 1
      LV Size                99.90 GiB
      Current LE             25575
      Segments               1
      Allocation             inherit
      Read ahead sectors     auto
      - currently set to     8192
      Block device           253:3

# 7.基于逻辑卷创建磁盘分区

## 7.1 格式化磁盘分区

    mkfs.ext4 /dev/lvm00/data

## 7.2 挂载磁盘分区

    mkdir -p /data
    mount /dev/lvm00/data /data

# 8.验证文件系统

    df -h


    Filesystem                       Size  Used Avail Use% Mounted on
    devtmpfs                         908M     0  908M   0% /dev
    tmpfs                            919M     0  919M   0% /dev/shm
    tmpfs                            919M  8.6M  911M   1% /run
    tmpfs                            919M     0  919M   0% /sys/fs/cgroup
    /dev/mapper/centos_centos7-root   50G  2.0G   49G   4% /
    /dev/mapper/centos_centos7-home  203G   33M  203G   1% /home
    /dev/vda1                       1014M  223M  792M  22% /boot
    tmpfs                             82M     0   82M   0% /run/user/1000
    tmpfs                             82M     0   82M   0% /run/user/0
    /dev/mapper/lvm00-data            99G   61M   94G   1% /data

---------

# 参考文档

- https://blog.51cto.com/13911915/2155531
- https://blog.csdn.net/m0_57554344/article/details/130558310
- https://blog.csdn.net/weixin_48195231/article/details/131010340