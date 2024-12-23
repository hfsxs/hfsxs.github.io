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
date: 2024-06-14 09:56:18
---

Linux系统磁盘扩容分为两种方案，即新增磁盘和分区调整，前者是将新增的磁盘扩容为单独的分区，或者是将新磁盘加入到LVM的卷组再扩容到指定的逻辑分区，后者只能是基于LVM将空闲较多的逻辑分区扩容到容量紧张的逻辑分区

# 1.新增磁盘

新增一块100G的硬盘，其中80G挂载到/data用于数据存储，20G用于扩容根分区

# 1.1 查看当前所挂载磁盘

    lsblk 
    
    NAME                    MAJ:MIN RM  SIZE RO TYPE MOUNTPOINT
    sr0                      11:0    1 1024M  0 rom  
    vda                     252:0    0  256G  0 disk 
    ├─vda1                  252:1    0    1G  0 part /boot
    └─vda2                  252:2    0  255G  0 part 
      ├─centos_centos7-root 253:0    0   50G  0 lvm  /
      ├─centos_centos7-swap 253:1    0    2G  0 lvm  [SWAP]
      └─centos_centos7-home 253:2    0  203G  0 lvm  /home
    vdc                     252:32   0  100G  0 disk 

# 1.2 数据分区

### 1.2.1 创建分区

    fdisk /dev/vdc


    Welcome to fdisk (util-linux 2.23.2).

    Changes will remain in memory only, until you decide to write them.
    Be careful before using the write command.

    Device does not contain a recognized partition table
    Building a new DOS disklabel with disk identifier 0xe2af3ac8.

    Command (m for help): n
    Partition type:
       p   primary (0 primary, 0 extended, 4 free)
       e   extended
    Select (default p): 
    Using default response p
    Partition number (1-4, default 1): 
    First sector (2048-209715199, default 2048): 
    Using default value 2048
    Last sector, +sectors or +size{K,M,G} (2048-209715199, default 209715199): +80G
    Partition 1 of type Linux and of size 80 GiB is set

    Command (m for help): w
    The partition table has been altered!

    Calling ioctl() to re-read partition table.
    Syncing disks.

### 1.2.2 验证磁盘分区

    fdisk -l /dev/vdc 

    Disk /dev/vdc: 107.4 GB, 107374182400 bytes, 209715200 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk label type: dos
    Disk identifier: 0xe2af3ac8

       Device Boot      Start         End      Blocks   Id  System
    /dev/vdc1            2048   167774207    83886080   83  Linux

### 1.2.3 格式化分区

    mkfs.ext4 /dev/vdc1

### 1.2.4 挂载磁盘分区

    # 新建挂载点
    mkdir -p /data
    # 挂载磁盘分区
    mount /dev/vdc1 /data

### 1.2.5 验证文件系统

    df -h

    Filesystem                       Size  Used Avail Use% Mounted on
    devtmpfs                         908M     0  908M   0% /dev
    tmpfs                            919M     0  919M   0% /dev/shm
    tmpfs                            919M  8.6M  911M   1% /run
    tmpfs                            919M     0  919M   0% /sys/fs/cgroup
    /dev/mapper/centos_centos7-root   50G  1.9G   49G   4% /
    /dev/mapper/centos_centos7-home  203G   33M  203G   1% /home
    /dev/vda1                       1014M  236M  779M  24% /boot
    tmpfs                             82M     0   82M   0% /run/user/1000
    /dev/vdc1                         79G   57M   75G   1% /data

### 1.2.6 配置分区开机自动挂载

#### 1.2.6.1 指定卷标，即盘符

    e2label /dev/vdc1 data

#### 1.2.6.2 查找设备uuid

    lsblk -f

    NAME                    FSTYPE      LABEL UUID                                   MOUNTPOINT
    sr0                                                                              
    vda                                                                              
    ├─vda1                  xfs               1d624794-ee47-4428-a34f-a887a3dcd04a   /boot
    └─vda2                  LVM2_member       sJdHkg-yBlF-j1Jb-vy26-aRqR-T2DU-oM3WSV 
      ├─centos_centos7-root xfs               af45f5b5-27fe-4157-b543-56d14d88a56d   /
      ├─centos_centos7-swap swap              aa7f679b-71c8-4f03-9b81-95ae2749c284   [SWAP]
      └─centos_centos7-home xfs               fd6c83c5-069c-49c5-aa4d-09979554ea3a   /home
    vdc                                                                              
    └─vdc1                  ext4        data  bec2696a-a272-447c-bb1c-ce42737144da   /data

#### 1.2.6.3 配置分区自动挂载

    # 也可用设备名称或卷标
    echo "UUID=bec2696a-a272-447c-bb1c-ce42737144da  /data  ext4  defaults  1  2" >> /etc/fstab

#### 1.2.6.4 重启系统，验证磁盘自动挂载

    reboot

## 1.3 扩容分区

### 1.3.1 创建分区

    fdisk /dev/vdc

### 1.3.2 验证分区

    fdisk -l /dev/vdc 

    Disk /dev/vdc: 107.4 GB, 107374182400 bytes, 209715200 sectors
    Units = sectors of 1 * 512 = 512 bytes
    Sector size (logical/physical): 512 bytes / 512 bytes
    I/O size (minimum/optimal): 512 bytes / 512 bytes
    Disk label type: dos
    Disk identifier: 0xe2af3ac8

       Device Boot      Start         End      Blocks   Id  System
    /dev/vdc1            2048   167774207    83886080   83  Linux
    /dev/vdc2       167774208   209715199    20970496   83  Linux

### 1.3.2 创建物理卷

    pvcreate /dev/vdc2
      Physical volume "/dev/vdc2" successfully created.

### 1.3.3 查看逻辑卷组名称

    pvdisplay | grep VG
    VG Name               centos_centos7

### 1.3.4 将建物理卷加入逻辑卷组

     vgextend centos_centos7 /dev/vdc2
      Volume group "centos_centos7" successfully extended

### 1.3.5 验证卷组空闲空间

    vgdisplay | grep Free
     Free  PE / Size       5120 / 20.00 GiB

### 1.3.6 查看要扩容的逻辑卷路径

    lvdisplay | grep Path
      LV Path                /dev/centos_centos7/swap
      LV Path                /dev/centos_centos7/home
      LV Path                /dev/centos_centos7/root

### 1.3.7 将空闲空间扩容到逻辑分区

    lvextend -L +19.9G /dev/centos_centos7/root
      Rounding size to boundary between physical extents: 19.90 GiB.
      Size of logical volume centos_centos7/root changed from 50.00 GiB (12800 extents) to 69.90 GiB (17895 extents).
      Logical volume centos_centos7/root successfully resized.

### 1.3.8 重定义文件系统大小

    resize2fs -p /dev/vg_oracle02/lv_var

    # xfs格式文件系统为xfs_growfs命令
    xfs_growfs /dev/centos_centos7/root
    meta-data=/dev/mapper/centos_centos7-root isize=512    agcount=4, agsize=3276800 blks
         =                       sectsz=512   attr=2, projid32bit=1
         =                       crc=1        finobt=0 spinodes=0
    data     =                       bsize=4096   blocks=13107200, imaxpct=25
             =                       sunit=0      swidth=0 blks
    naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
    log      =internal               bsize=4096   blocks=6400, version=2
             =                       sectsz=512   sunit=0 blks, lazy-count=1
    realtime =none                   extsz=4096   blocks=0, rtextents=0
    data blocks changed from 13107200 to 18324480

### 1.3.9 验证文件系统

    df -h

    Filesystem                       Size  Used Avail Use% Mounted on
    devtmpfs                         908M     0  908M   0% /dev
    tmpfs                            919M     0  919M   0% /dev/shm
    tmpfs                            919M  8.6M  911M   1% /run
    tmpfs                            919M     0  919M   0% /sys/fs/cgroup
    /dev/mapper/centos_centos7-root   70G  1.9G   69G   3% /
    /dev/mapper/centos_centos7-home  203G   33M  203G   1% /home
    /dev/vda1                       1014M  236M  779M  24% /boot
    tmpfs                             82M     0   82M   0% /run/user/1000
    /dev/vdc1                         79G   57M   75G   1% /data

# 2.扩容分区

将数据分区/home部分空间扩容到分区/root

## 2.1 查看文件系统格式

文件系统的扩缩容方式依赖于其格式，如Centos7系列默认的XFS文件系统就不支持在线缩容，用EXT4的方式进行扩缩容就会报错（Superblock错误）。因此，建议扩缩容操作之前先确认文件系统的格式

    lsblk -f
    NAME                    FSTYPE      LABEL UUID                                   MOUNTPOINT
    sr0                                                                              
    vda                                                                              
    ├─vda1                  xfs               1d624794-ee47-4428-a34f-a887a3dcd04a   /boot
    └─vda2                  LVM2_member       sJdHkg-yBlF-j1Jb-vy26-aRqR-T2DU-oM3WSV 
      ├─centos_centos7-root xfs               af45f5b5-27fe-4157-b543-56d14d88a56d   /
      ├─centos_centos7-swap swap              aa7f679b-71c8-4f03-9b81-95ae2749c284   [SWAP]
      └─centos_centos7-home xfs               be669905-d291-487e-a52c-2d362ad47ec6   /home

## 2.2 卸载分区

### 2.2.1 安装fuser工具

    yum install -y psmisc

### 2.2.2 终止分区进程

    fuser -m -v -i -k /home

                     用户     进程号 权限   命令
    /home:               root     kernel mount /home
                     sword      7903 ..c.. bash
    杀死进程 7903 ? (y/N) y

### 2.2.3 卸载分区

    umount /home

## 2.3 缩减文件系统

### 2.3.1 XFS格式

#### 2.3.1.1 安装工具

    yum -y install xfsdump

#### 2.3.1.2 缩减逻辑卷空间，使之成为空闲空间

    lvresize -L 100G /dev/mapper/centos_centos7-home 
      WARNING: Reducing active logical volume to 100.00 GiB.
      THIS MAY DESTROY YOUR DATA (filesystem etc.)
    Do you really want to reduce centos_centos7/home? [y/n]: y
      Size of logical volume centos_centos7/home changed from 202.99 GiB (51966 extents) to 100.00 GiB (25600 extents).
      Logical volume centos_centos7/home successfully resized.

#### 2.3.1.3 重新格式化缩减的逻辑分区

    mkfs.xfs -f /dev/mapper/centos_centos7-home
    meta-data=/dev/mapper/centos_centos7-home isize=512    agcount=4, agsize=6553600 blks
             =                       sectsz=512   attr=2, projid32bit=1
             =                       crc=1        finobt=0, sparse=0
    data     =                       bsize=4096   blocks=26214400, imaxpct=25
             =                       sunit=0      swidth=0 blks
    naming   =version 2              bsize=4096   ascii-ci=0 ftype=1
    log      =internal log           bsize=4096   blocks=12800, version=2
             =                       sectsz=512   sunit=0 blks, lazy-count=1
    realtime =none                   extsz=4096   blocks=0, rtextents=0

    resize2fs -f /dev/mapper/VolGroup-lv_data 15G

#### 2.3.1.4 挂载缩减的分区

     mount /dev/mapper/centos_centos7-home /home

### 2.3.2 EXT4格式

#### 2.3.2.1 缩减逻辑卷空间，使之成为空闲空间

    lvreduce -L 100G /dev/mapper/centos_centos7-home

#### 2.3.2.2 重新挂载数据分区

    mount /dev/mapper/centos_centos7-home

## 2.4 验证空闲空间

    vgdisplay | grep Free
      Free  PE / Size       26367 / <103.00 GiB

## 2.5 将空闲空间扩容到根分区

    lvextend -L +103G /dev/mapper/centos_centos7-root

## 2.6 重定义文件系统大小

    # XFS格式
    xfs_growfs /dev/mapper/centos_centos7-root
    # EXT4格式
    resize2fs -p /dev/mapper/centos_centos7-root

## 2.7 验证分区扩容

    df -h
    文件系统                         容量  已用  可用 已用% 挂载点
    devtmpfs                         908M     0  908M    0% /dev
    tmpfs                            919M     0  919M    0% /dev/shm
    tmpfs                            919M  8.5M  911M    1% /run
    tmpfs                            919M     0  919M    0% /sys/fs/cgroup
    /dev/mapper/centos_centos7-root  153G  1.6G  152G    2% /
    /dev/vda1                       1014M  193M  822M   19% /boot
    tmpfs                             82M     0   82M    0% /run/user/0
    /dev/mapper/centos_centos7-home  100G   33M  100G    1% /home

---------

# 参考文档

- https://cloud.tencent.com/developer/article/2095805
- https://blog.csdn.net/niechel/article/details/129217219
- https://blog.csdn.net/weixin_53389944/article/details/129205588