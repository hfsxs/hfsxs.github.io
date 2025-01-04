---
title: Hexo搭建博客
categories:
  - 极客
tags:
  - Linux
  - Hexo
  - Nodejs
  - 博客
  - 极客
date: 2023-02-16 14:55:09
---

Hexo，快速、简洁且高效的博客框架，将Markdown文件解析为静态网页。相比于Docsify更适合作为博客使用，因为其具有大量靓丽的主题，缺点是需要一点点技术，但也很简单

# 1.安装Git、Nodejs

# 2.安装hexo

    sudo npm install -g hexo-cli
    sudo ln -s /usr/local/nodejs/lib/node_modules/hexo-cli/bin/hexo /usr/local/bin

# 3.初始化hexo

    sudo mkdir -p /web && cd /web
    sudo hexo init hexo
    sudo npm install

---------

- _config.yml，hexo主配置文件
- db.json，hexo文件存储，以后的博客文章文件应该就是存储在这里
- node_modules，node的模块
- package.json，hexo的插件
- package-lock.json，node的相关依赖
- public，Markdown文件渲染的静态网页目录，可在主配置文件自定义
- scaffolds，hexo命令的模板文件,默认为post
- source，hexo命令写作的源Markdown文件所在目录，将Markdown文件手动拷贝至此目录即可不用hexo命令新建博客
- themes，hexo主题文件所在目录

# 4.配置hexo主题

# 5.启动本地服务器

    hexo -s

# 6.hexo写文章

    hexo new 测试

---------

# 参考文档

- https://hexo.io/zh-cn/docs
- https://www.modb.pro/db/127951
- https://blog.shipengx.com/archives/afb81b2.html
- https://blog.csdn.net/Mo_0214/article/details/137501214
