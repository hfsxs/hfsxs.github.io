---
title: Nextcloud搭建私有云盘
categories:
  - 极客
tags:
  - Linux
  - Nextcloud
  - 存储
  - 云存储
  - 私有云
  - 极客
date: 2020-02-20 11:24:16
---

CREATE DATABASE nextcloud;
GRANT ALL PRIVILEGES ON nextcloud.* TO 'nextcloud'@'localhost' IDENTIFIED BY 'your-strong_password';
FLUSH PRIVILEGES;