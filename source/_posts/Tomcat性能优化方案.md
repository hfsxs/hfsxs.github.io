---
title: Tomcat性能优化方案
categories:
  - 工作
tags:
  - Linux
  - Tomcat
  - Java
  - 性能优化
  - 云计算
date: 2021-07-21 18:06:54
---

# 1.内存

默认为128M，内存溢出报错 OUT of memory

# 2.maxpermsize

默认64M，决定了保持对象的大小，溢出报错 outofmemoryerror:permgen

# 3.maxthreads

最大并发线程数，默认为200，请求量大于该值时，并发请求将进入等待队列。增加该值能提供并发处理能力，但会消耗系统资源，一般设为最大请求数即可。此外，该值还受限于操作系统的内核参数，即Linux的open files

# 4.connection timeout

连接超时时长，默认为60秒，表示从开始接受请求到开始处理请求的等待时间，故障表现为502异常

# 5.acceptcount

最大队列数，默认为100，表示所有线程都在处理请求时，新请求进入等待队列的最大个数。超出该值时，所有新请求都将被拒绝，故障表现为 connection refused