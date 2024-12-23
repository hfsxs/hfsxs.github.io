---
title: Git安装与配置
categories:
  - 工作
tags:
  - Linux
  - Git
  - CICD
  - DevOps
  - 云计算
date: 2020-02-03 14:30:06
---

Git，由林纳斯于2005年以C语言开发的开源分布式版本控制系统，起初是管理Linux内核源代码，目前可用于敏捷高效地托管各种项目的源代码，简单快速且强大

# 核心概念

## 工作区

工作区，即本地开发环境，管理着本地代码目录，通过更改提交(commit)到本地仓库，之后再推送(push)到远程仓库

## 暂存区

暂存区，即stage或index，一般存储于.git目录下的index文件，也被称之为索引（index），是位于仓库和工作区之间的中间区域

## 仓库

仓库，repository，又称版本库，一般位于工作区下的隐藏目录.git，其中的所有文件都由Git管理，每个文件的修改、删除都被Git跟踪，以便于任何时刻都可以追踪历史或还原

## 远程仓库

远程仓库，Remote Repository，存储在服务器上的Git仓库，用于多人协作和备份。本地的个人开发者可以克隆远程仓库到本地，拉取（pull）远程后本地更改，最后再推送（push）本地更改到远程仓库。远程仓库分为公共仓库和私有仓库两种，如github属于公共仓库，也可用gitlab、gitea搭建私有仓库

# 工作流程

- 1.克隆Git资源作为工作目录
- 2.在克隆的资源上添加或修改文件，或更新资源其他人修改后的资源
- 3.查看修改内容，确认后提交修改
- 4.修改完成后，如果发现错误或冲突，可撤回提交并再次修改并提交

# 1.安装Git

    sudo yum install -y git
    sudo apt install -y git

# 2.创建Git仓库

    mkdir -p /web/gits && cd /web/gits
    # 初始化仓库
    git init

# 3.仓库新增文件

    echo "Git is simple." > Readme.md
    # 将文件添加到仓库
    git add Readme.md
    # 表示将目录下所有新增或修改一并添加到仓库
    # git add .
    # 将文件提交到仓库
    git commit

- 注：git commit命令，-m参数之后用于输入本次提交的说明，可输入任意内容，最好是有意义的，以便于从历史记录方便地找到改动记录，省略掉-m参数则会提示自由输入改动记录

# 4.查看仓库状态

    # 将会显示有变更的文件
    git status

# 5.查看文件改动

    # 比较文件的不同，即比较文件在暂存区和工作区的差异，将会显示文件具体修改的内容
    git diff

---------

# 参考文档

- https://zhuanlan.zhihu.com/p/30044692
- https://www.runoob.com/git/git-tutorial.html
- https://mp.weixin.qq.com/s/T3mP2YGzI7WSUr3C9S8ltw
- https://blog.csdn.net/m0_56145255/article/details/127600983