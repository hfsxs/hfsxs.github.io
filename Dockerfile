FROM registry.cn-hangzhou.aliyuncs.com/swords/nginx

RUN ln -sf /dev/stdout /var/log/nginx/access.log \
&& ln -sf /dev/stderr /var/log/nginx/error.log

COPY . /var/lib/nginx/html
