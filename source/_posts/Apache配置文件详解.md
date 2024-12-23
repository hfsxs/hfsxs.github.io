---
title: Apache配置文件详解
categories:
  - 工作
tags:
  - Linux
  - Apache
  - Http服务器
  - 云计算
date: 2020-02-01 09:20:10 
---

    # 设置安装目录
    ServerRoot "/usr/local/httpd"

    # 设置HTTP服务器响应头，值为major|minor|minimal|productonly|os|full，显示Apache版本和操作系统名称
    ServerTokens OS 

    # Mutex default:logs

    # 设置监听端口，默认监听所有网卡
    #Listen 12.34.56.78:80
    Listen 80

    # 设置启用的模块
    LoadModule authn_file_module modules/mod_authn_file.so
    #LoadModule authn_dbm_module modules/mod_authn_dbm.so
    #LoadModule authn_anon_module modules/mod_authn_anon.so
    #LoadModule authn_dbd_module modules/mod_authn_dbd.so
    #LoadModule authn_socache_module modules/mod_authn_socache.so
    LoadModule authn_core_module modules/mod_authn_core.so
    LoadModule authz_host_module modules/mod_authz_host.so
    LoadModule authz_groupfile_module modules/mod_authz_groupfile.so
    LoadModule authz_user_module modules/mod_authz_user.so
    #LoadModule authz_dbm_module modules/mod_authz_dbm.so
    #LoadModule authz_owner_module modules/mod_authz_owner.so
    #LoadModule authz_dbd_module modules/mod_authz_dbd.so
    LoadModule authz_core_module modules/mod_authz_core.so
    LoadModule access_compat_module modules/mod_access_compat.so
    LoadModule auth_basic_module modules/mod_auth_basic.so
    #LoadModule auth_form_module modules/mod_auth_form.so
    #LoadModule auth_digest_module modules/mod_auth_digest.so
    #LoadModule allowmethods_module modules/mod_allowmethods.so
    #LoadModule file_cache_module modules/mod_file_cache.so
    #LoadModule cache_module modules/mod_cache.so
    #LoadModule mem_cache_module modules/mod_mem_cache.so
    #LoadModule cache_disk_module modules/mod_cache_disk.so
    #LoadModule cache_socache_module modules/mod_cache_socache.so
    #LoadModule socache_shmcb_module modules/mod_socache_shmcb.so
    #LoadModule socache_dbm_module modules/mod_socache_dbm.so
    #LoadModule socache_memcache_module
    modules/mod_socache_memcache.so
    #LoadModule watchdog_module modules/mod_watchdog.so
    #LoadModule macro_module modules/mod_macro.so
    #LoadModule dbd_module modules/mod_dbd.so
    #LoadModule dumpio_module modules/mod_dumpio.so
    #LoadModule buffer_module modules/mod_buffer.so
    #LoadModule ratelimit_module modules/mod_ratelimit.so
    LoadModule reqtimeout_module modules/mod_reqtimeout.so
    #LoadModule ext_filter_module modules/mod_ext_filter.so
    #LoadModule request_module modules/mod_request.so
    #LoadModule include_module modules/mod_include.so
    LoadModule filter_module modules/mod_filter.so
    #LoadModule substitute_module modules/mod_substitute.so
    #LoadModule sed_module modules/mod_sed.so
    LoadModule mime_module modules/mod_mime.so
    LoadModule log_config_module modules/mod_log_config.so
    #LoadModule log_debug_module modules/mod_log_debug.so
    #LoadModule logio_module modules/mod_logio.so
    LoadModule env_module modules/mod_env.so
    #LoadModule unique_id_module modules/mod_unique_id.so
    LoadModule setenvif_module modules/mod_setenvif.so
    LoadModule version_module modules/mod_version.so
    #LoadModule remoteip_module modules/mod_remoteip.so
    #LoadModule proxy_module modules/mod_proxy.so
    #LoadModule proxy_connect_module modules/mod_proxy_connect.so
    #LoadModule proxy_ftp_module modules/mod_proxy_ftp.so
    #LoadModule proxy_http_module modules/mod_proxy_http.so
    #LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so
    #LoadModule proxy_scgi_module modules/mod_proxy_scgi.so
    #LoadModule proxy_fdpass_module modules/mod_proxy_fdpass.so
    #LoadModule proxy_wstunnel_module modules/mod_proxy_wstunnel.so
    #LoadModule proxy_ajp_module modules/mod_proxy_ajp.so
    #LoadModule proxy_balancer_module modules/mod_proxy_balancer.so
    #LoadModule proxy_express_module modules/mod_proxy_express.so
    #LoadModule proxy_hcheck_module modules/mod_proxy_hcheck.so
    #LoadModule session_module modules/mod_session.so
    #LoadModule session_cookie_module modules/mod_session_cookie.so
    #LoadModule session_dbd_module modules/mod_session_dbd.so
    #LoadModule slotmem_shm_module modules/mod_slotmem_shm.so
    #LoadModule lbmethod_byrequests_module modules/mod_lbmethod_byrequests.so
    #LoadModule lbmethod_bytraffic_module modules/mod_lbmethod_bytraffic.so
    #LoadModule lbmethod_bybusyness_module modules/mod_lbmethod_bybusyness.so
    #LoadModule lbmethod_heartbeat_module modules/mod_lbmethod_heartbeat.so
    #LoadModule mpm_event_module modules/mod_mpm_event.so
    #LoadModule mpm_prefork_module modules/mod_mpm_prefork.so
    LoadModule mpm_worker_module modules/mod_mpm_worker.so
    LoadModule unixd_module modules/mod_unixd.so
    #LoadModule dav_module modules/mod_dav.so
    LoadModule status_module modules/mod_status.so
    LoadModule autoindex_module modules/mod_autoindex.so
    #LoadModule info_module modules/mod_info.so
    #LoadModule dav_fs_module modules/mod_dav_fs.so
    #LoadModule vhost_alias_module modules/mod_vhost_alias.so
    #LoadModule negotiation_module modules/mod_negotiation.so
    LoadModule dir_module modules/mod_dir.so
    #LoadModule actions_module modules/mod_actions.so
    #LoadModule speling_module modules/mod_speling.so
    #LoadModule userdir_module modules/mod_userdir.so
    LoadModule alias_module modules/mod_alias.so

    <IfModule unixd_module>
      # 设置运行用户及用户组        
      User daemon
      Group daemon
    </IfModule>

    # 设置服务进程数
    # StartServers    8
    # 设置服务器保持的最少空闲进程数，若空闲子进程小于此值，就创建一个新的子进程作准备
    #MinSpareServers    5   
    # 设置服务器保持的最大空闲进程数，若空闲子进程大于此值，就逐一删除子进程以提高系统性能
    #MaxSpareServers    20

    # 设置服务器最大进程数
    #ServerLimit    256
    # 设置服务器最大并发连接数
    #MaxClients    256
    # 设置子进程在结束处理请求之前最大能处理的连接请求数，超过此值就释放重新建立，为0表示永不释放
    #MaxRequestsPerChild  4000  

    # 设置pid文件路径
    PidFile /var/run/httpd.pid

    # 设置TCP连接超时时长，超过则主动关闭，接受下一个连接
    Timeout 60

    # 设置开启持久连接功能，实现一个连接处理多个请求，以提高响应速度，降低服务器开销
    KeepAlive On
    # 设置持久连接时长，即一个HTTP请求响应结束后不关闭连接，等待下一个请求的超时时长
    # KeepAliveTimeout 30
    # 设置一个连接所处理的最大请求数，默认为100，为0则表示无限制
    # MaxKeepAliveRequests 100

    # 设置管理员邮箱
    ServerAdmin you@example.com

    # 设置服务器域名和端口
    ServerName localhost:80

    # 设置服务器根目录访问控制权限
    <Directory />
      AllowOverride none
      Require all denied
    </Directory>

    # 设置网站根目录
    DocumentRoot "/usr/local/httpd/htdocs"

    # 设置网站根目录访问控制权限
    <Directory "/usr/local/httpd/htdocs">
      Options Indexes FollowSymLinks
      AllowOverride None
      Require all granted
    </Directory>

    # 设置默认索引页
    <IfModule dir_module>
      DirectoryIndex index.html
    </IfModule>

    <Files ".ht*">
      # 设置.ht文件拒绝访问
      Require all denied
    </Files>

    # 设置错误日志存储路径
    ErrorLog "logs/error_log"

    # 设置错误日志级别
    LogLevel warn

    <IfModule log_config_module>
      # 设置访问日志文件格式
      LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\"" combined
      LogFormat "%h %l %u %t \"%r\" %>s %b" common

      <IfModule logio_module>
        # 设置访问日志记录请求的输入/输出字节数，包括请求头与响应头正文之和，能正确反映SSL/TLS加密所造成的影响
        LogFormat "%h %l %u %t \"%r\" %>s %b \"%{Referer}i\" \"%{User-Agent}i\" %I %O" combinedio
      </IfModule>

      # 设置访问日志存储路径
      CustomLog "logs/access_log" common
    </IfModule>

    # 设置访问日志不记录客户端主机名，避免客户端域名反向解析造成服务器性能下降
    HostnameLookups Off 

    <IfModule alias_module>
      # 设置URL重定向
      ScriptAlias /cgi-bin/ "/usr/local/httpd/cgi-bin/"
    </IfModule>

    <IfModule cgid_module>

    </IfModule>

    <Directory "/usr/local/httpd/cgi-bin">
      AllowOverride None
      Options None
      Require all granted
    </Directory>

    <IfModule headers_module>

    </IfModule>

    <IfModule mime_module>
      TypesConfig /etc/httpd/conf/mime.types

      #AddType application/x-gzip .tgz

      #AddEncoding x-compress .Z
      #AddEncoding x-gzip .gz .tgz

      AddType application/x-compress .Z
      AddType application/x-gzip .gz .tgz
      AddType application/x-php .php

      #AddHandler cgi-script .cgi

      #AddHandler type-map var

      #AddType text/html .shtml
      #AddOutputFilter INCLUDES .shtml

      AddDefaultCharset UTF-8
    </IfModule>

    #MIMEMagicFile /etc/httpd/conf/magic
    #ErrorDocument 500 "The server made a boo boo."
    #ErrorDocument 404 /missing.html
    #ErrorDocument 404 "/cgi-bin/missing_handler.pl"
    #ErrorDocument 402 http://www.example.com/subscription_info.html

    #MaxRanges unlimited

    #EnableMMAP off
    #EnableSendfile on

    # Server-pool management (MPM specific)
    #Include /etc/httpd/conf/extra/httpd-mpm.conf

    # Multi-language error messages
    #Include /etc/httpd/conf/extra/httpd-multilang-errordoc.conf

    # Fancy directory listings
    #Include /etc/httpd/conf/extra/httpd-autoindex.conf

    # Language settings
    #Include /etc/httpd/conf/extra/httpd-languages.conf

    # User home directories
    #Include /etc/httpd/conf/extra/httpd-userdir.conf

    # Real-time info on requests and configuration
    #Include /etc/httpd/conf/extra/httpd-info.conf

    # 设置虚拟主机
    #Include /etc/httpd/conf/extra/httpd-vhosts.conf

    # Local access to the Apache HTTP Server Manual
    #Include /etc/httpd/conf/extra/httpd-manual.conf

    # Distributed authoring and versioning (WebDAV)
    #Include /etc/httpd/conf/extra/httpd-dav.conf

    # Various default settings
    #Include /etc/httpd/conf/extra/httpd-default.conf

    # Configure mod_proxy_html to understand HTML4/XHTML1
    <IfModule proxy_html_module>
      Include /etc/httpd/conf/extra/proxy-html.conf
    </IfModule>

    # 设置SSL安全连接
    #Include /etc/httpd/conf/extra/httpd-ssl.conf

    <IfModule ssl_module>
      SSLRandomSeed startup builtin
      SSLRandomSeed connect builtin
    </IfModule>