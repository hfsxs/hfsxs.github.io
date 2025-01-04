---
title: Ubuntu桌面配置及优化
categories:
  - 极客
tags:
  - Linux
  - Ubuntu
  - 极客
date: 2021-01-03 17:12:24
---

# 1.设置系统禁用UTC

    sudo timedatectl set-local-rtc 1 --adjust-system-clock
    
# 2.配置中文环境

## 2.1 安装中文字体

    sudo apt -y install xfonts-intl-chinese xfonts-wqy fonts-wqy-zenhei fonts-wqy-microhei 
    
## 2.2 设置中文字符

    sudo dpkg-reconfigure locales
    
## 2.3 安装中文输入法

    sudo apt -y install ibus-clutter ibus-libpinyin
    
# 3.安装美化工具

    sudo apt -y install gnome-tweak-tool 
    # gnome-shell-extensions chrome-gnome-shell gnome-shell-extentions-dashtodock

# 4.下载安装主题及图标

## 4.1 安装主题

    tar -xzvf WhiteSur.tar.gz && sudo mv WhiteSur /usr/share/themes

## 4.2 安装图标

    tar -xzvf Bigsur.tar.gz && sudo mv Bigsur /usr/share/icons
  
- 注：主题与图标下载网站为 https://www.gnome-look.org

# 5.安装常用插件

- dock插件  
  dash to dock

- 托盘插件  
  TopIcons Plus

- 顶部状态栏天气插件  
  OpenWeather

- 注：插件下载网站为 https://extensions.gnome.org

# 6.安装微信、QQ

    sudo apt install git
    git clone https://gitee.com/wszqkzqk/deepin-wine-for-ubuntu.git
    cd deepin-wine-for-ubuntu && ./install_2.8.22.sh
    wget https://packages.deepin.com/deepin/pool/non-  free/d/deepin.com.wechat/deepin.com.wechat_2.6.2.31deepin0_i386.deb
    wget https://mirrors.aliyun.com/deepin/pool/non- free/d/deepin.com.wechat/deepin.com.qq.im_9.1.8deepin0_i386.deb
    sudo dpkg -i deepin.com*.deb
    
# 7.配置系统开机禁用桌面环境
    
    sudo systemctl set-default multi-user.target
    
# 8.安装软件管理包

    sudo apt -y install gnome-software 

# 9.禁用包管理服务packageKit

    sudo systemctl stop packagekit.service
    sudo systemctl disable packagekit.service
    sudo systemctl mask packagekit.service
    sudo mv -v /etc/apt/apt.conf.d/20packagekit{,.disabled}

---------

# 参考文档

- https://zhuanlan.zhihu.com/p/139305626
- https://www.cnblogs.com/feipeng8848/p/12808128.html