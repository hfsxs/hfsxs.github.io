---
title: Linux系统搭建FTP服务器
categories:
  - 工作
tags:
  - Linux
  - FTP
  - 云计算
date: 2020-02-06 17:45:19
---

# 1.安装ftp

    yum install -y vsftpd
    apt install -y vsftpd

# 2.创建配置文件

    mv /etc/vsftpd/vsftpd.conf /etc/vsftpd/vsftpd.conf.bak
    vi /etc/vsftpd/vsftpd.conf


    # 开启监听
    listen=YES
    # 验证文件的名字                            
    pam_service_name=vsftpd
    # 允许由userlist_file文件限制登陆的用户                         
    userlist_enable=YES
    # 支持tcp_wrappers,限制访问(/etc/hosts.allow,/etc/hosts.deny)                          
    tcp_wrappers=YES
    # 显示目录档案
    dirmessage_enable=YES
    # 自定义ftp上传路径（注意文件夹权限）
    local_root=/projects

    # 工作模式及其端口设置
    # VSFTP有两种工作模式，即PORT模式，主动模式；PASV模式，被动模式

    # 设置FTP服务器监听端口，默认为21
    listen_port=21
    # 设置使用20端口传输数据，默认为YES
    connect_from_port_20=YES
    # PORT模式下FTP数据连接使用的端口，默认值为20。
    ftp_data_port=20

    # 设置是否启用PASV模式，默认值为YES
    # pasv_enable=NO
    # 设置PASV模式工作端口范围
    # pasv_min_port=0
    # pasv_max_port=0

    # 所有登陆用户都写权限,全局设置，默认为YES
    write_enable=YES
    # 是否允许本地用户登陆，默认为YES
    local_enable=YES
    # 本地用户登陆后所在目录，默认为该用户的家目录
    local_root=/ftp
    # 本地用户上传文件时的umask值，默认为077
    local_umask=022
    # 本地用户上传文件的权限，与chmod 所使用的数值相同，默认为0666
    # file_open_mode=0755

    # 设置登陆用户切换目录的权限
    # 禁用用户列表文件控制目录切换权限，所有用户权限由chroot_local_user控制，默认为NO
    # chroot_list_enable=NO
    # 设置控制权限，默认为NO，
    chroot_local_user=YES
    # 设置控制目录切换的列表文件的路径
    # chroot_list_file=/etc/vsftpd.chroot_list

    # 启用日志文件             
    xferlog_enable=YES
    # 使用本地时间而不是GMT                   
    use_localtime=YES
    # vsftpd日志存放位置                     
    vsftpd_log_file=/var/log/vsftpd.log
    # 用户登陆日志   
    dual_log_enable=YES
    # 记录上传下载文件的日志             
    xferlog_file=/var/log/xferlog
    # 记录日志使用标准格式          
    xferlog_std_format=YES
    # 登陆超时时间              
    idle_session_timeout=60

    # 是否允许匿名用户登入，默认为YES
    anonymous_enable=NO
    # 匿名登陆是否需要密码，默认为NO
    # no_anon_password=NO
    # 匿名登陆所使用的用户名，默认为ftp
    # ftp_username=ftp
    # 匿名登陆的家目录，默认为/var/ftp，权限不能为777
    # anon_root=/var/ftp
    # 匿名登陆是否有上传文件（非目录）的权限，默认为NO
    # anon_upload_enable=NO
    # 匿名登陆是否允许下载可阅读的档案，默认为YES
    # anon_world_readable_only=YES
    # 匿名登陆是否有新增目录的权限，默认为NO
    # anon_mkdir_write_enable=YES/NO（NO）
    # 匿名登陆是否有删除或者重命名的权限，默认为NO
    # anon_other_write_enable=NO
    # 设置是否改变匿名用户上传文件（非目录）的属主，默认为NO
    # chown_uploads=NO
    # 设置匿名用户上传文件（非目录）的属主
    # chown_username=username
    # 设置匿名登入者新增或上传档案时的umask值，默认为077，则新建档案的对应权限为700
    anon_umask=022
    # 匿名登陆是否启用email地址验证功能，默认为NO
    # deny_email_enable=NO
    # 匿名登陆email地址验证的验证文件定义，输入该文件内的email address，则允许登陆
    # banned_email_file=/etc/vsftpd/banner_emails

    # 设置数据传输模式
    # 禁用ASCII模式上传数据，即用二进制模式，默认为NO
    # ascii_upload_enable=NO
    # 禁用ASCII模式下载数据，即用二进制模式，默认为NO
    # ascii_download_enable=YES/NO（NO）

    # 欢迎语设置
    # 是否启用文件式欢迎语，默认为YES
    dirmessage_enable=YES
    # 定义文件式欢迎语的文件路径，默认为.message
    # message_file=.message
    # 定义文件式欢迎语的文件路径，默认不启用
    # banner_file=/etc/vsftpd/banner
    # 定义字符串式欢迎语，默认为空
    ftpd_banner=Welcome to FTP server

# 3.创建ftp登陆用户

    useradd -d /home/vsftp/ -g ftp -s /sbin/nologin vsftp
    passwd vsftp

# 4.创建ftp服务器上传目录，并授予权限

    mkdir -p /ftp && chown -R vsftp.vsftp /ftp

# 5.启动vsftpd服务器

    service vsftpd start

---------

# 参考文档

- http://blog.51cto.com/yuanbin/108262