#!/bin/bash


cd /web/hexo/hexo
docker build -t registry.cn-hangzhou.aliyuncs.com/geekers/hexo:$(date "+v3.%y.%s") .
