---
title: ProxmoxVE虚拟化管理平台部署与配置
categories:
  - 极客
tags:
  - Linux
  - ProxmoxVE
  - KVM
  - 虚拟化
  - 极客
date: 2022-09-11 20:08:28
---

# 1.下载镜像包

# 2.制作U盘启动盘

# 3.安装PVE

# 4.删除无效订阅

    sed -i.backup -z "s/res === null || res === undefined || \!res || res\n\t\t\t.data.status.toLowerCase() \!== 'active'/false/g" /usr/share/javascript/proxmox-widget-toolkit/proxmoxlib.js
    systemctl restart pveproxy.service

# 5.注释Proxmox企业版更新源
    
    vi /etc/apt/sources.list.d/pve-enterprise.list
        

    # deb https://enterprise.proxmox.com/debian/pve buster pve-enterprise

# 6.配置国内apt源

# 7.删除local-lvm

    # 删除local-lvm分区
    lvremove pve/data
    # 将空闲分区分配给root
    lvextend -l +100%FREE -r pve/root
    

https://fedorapeople.org/groups/virt/virtio-win/direct-downloads/archive-virtio/virtio-win-0.1.221-1/

最后，在数据中心-存储页面删除local-lvm分区，编辑local分区，内容一项中勾选所有可选项

---------

# 参考文档

- https://www.nasge.com/archives/136.html
- https://post.smzdm.com/p/awkv4pq4
- https://cloud.tencent.com/developer/article/2007992
- https://foxi.buduanwang.vip/virtualization/pve/1868.html