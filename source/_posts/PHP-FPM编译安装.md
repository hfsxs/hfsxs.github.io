---
title: PHP-FPM编译安装
categories:
  - 工作
tags:
  - Linux
  - PHP
  - 云计算
date: 2020-02-02 10:00:43
---

# 1.安装依赖包

    yum install -y gcc gcc-c++ make autoconf epel-release pcre-devel openssl-devel perl-devel \
    libzip-devel bzip2-devel sqlite-devel  libxml2-devel libcurl-devel libicu-devel libxslt-devel \
    libsodium-devel oniguruma-devel libjpeg-devel libpng-devel freetype-devel

    apt install -y gcc g++ make autoconf libssl-dev libpcre3-dev libsqlite3-dev libzip-dev \
    libbz2-dev zlib1g-dev libxml2-dev libcurl4-openssl-dev libonig-dev libxslt1-dev libpng-dev \
    libsodium-dev libjpeg-dev libfreetype6-dev

# 2.编译安装php-fpm

    tar -zxvf php-8.1.8.tar.gz && cd php-8.1.8

    ./configure --prefix=/usr/local/php --with-config-file-path=/etc --enable-fpm --with-fpm-user=www --with-fpm-group=www \
    --with-mysqli --with-pdo-mysql --with-bz2 --with-zip --disable-ipv6 --enable-xml --with-curl --enable-calendar --enable-gd --with-xsl \
    --with-openssl --with-zlib --enable-mbstring --with-gettext --enable-bcmath --enable-sockets --with-libdir=lib64 --without-pear --disable-rpath  \
    --with-sodium --enable-opcache --enable-dom --with-libxml --disable-debug --enable-intl --with-jpeg --with-freetype
    make && make install

# 3.创建配置文件

    cp /usr/local/php/etc/php-fpm.conf.default /usr/local/php/etc/php-fpm.conf
    cp /usr/local/php/etc/php-fpm.d/www.conf.default /usr/local/php/etc/php-fpm.d/www.conf
    cp php.ini-production /etc/php.ini

# 4.配置php-fpm服务

    cp sapi/fpm/init.d.php-fpm /etc/init.d/php-fpm
    chmod +x /etc/init.d/php-fpm

# 5.修改配置文件

    sed -i 's@;date.timezone =@date.timezone = Asia/Shanghai@g' /etc/php.ini
    sed -i 's@max_execution_time = 30@max_execution_time = 300@g' /etc/php.ini
    sed -i 's@post_max_size = 8M@post_max_size = 32M@g' /etc/php.ini
    sed -i 's@max_input_time = 60@max_input_time = 300@g' /etc/php.ini
    sed -i 's@memory_limit = 128M@memory_limit = 128M@g' /etc/php.ini
    sed -i 's@;always_populate_raw_post_data = -1@always_populate_raw_post_data = -1@g' /etc/php.ini

# 6.配置opcache缓存

    opcahce=`find /usr/local/php -name 'opcache.so'` && echo zend_extension=$opcahce >> /etc/php.ini

# 7.启动php-fpm服务

    /etc/init.d/php-fpm start