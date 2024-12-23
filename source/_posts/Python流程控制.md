---
title: Python流程控制
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-02-04 10:05:15
---

流程控制，即代码执行方式与顺序的控制，使得程序按照一定的结构进行执行，一般分为三种结构，即顺序结构、条件判断结构和循环控制结构。初学者建议以伪代码或流程图的方式将程序拆解，以培养编程语言的逻辑思维，厘清程序的控制逻辑

# 1.顺序结构

顺序结构，Python默认结构，即是按照代码的位置自上而下的执行，每行代码只执行一次

    >>> print('<- 欢迎使用幂运算器 ->')
    <- 欢迎使用幂运算器 ->
    >>> n = float(input('请输入底数:'))
    请输入底数:9
    >>> m = float(input('请输入指数:'))
    请输入指数:3
    >>> result = n ** m
    >>> print(f'{n}的{m}次幂等于{result}')
    9.0的3.0次幂等于729.0

# 2.条件结构

条件判断，Python程序的逻辑实现，即是依据一条或多条逻辑判断语句的执行结果（True或False）决定执行的代码块，关键字为if、elif和else

## 2.1 单分支判断结构

    >>> m = int(input('请输入数字:'))
    请输入数字:-3
    >>> if m < 0:
    ...     n = -m
    ... 
    >>> print(f'{m}的绝对值为{n}')
    -3的绝对值为3

## 2.2 双分支判断结构

    >>> age = int(input('请输入您的年龄: '))
    请输入您的年龄: 24
    >>> if age >= 18:
    ...     print('您已成年')
    ... else:
    ...     print('您未成年')
    ... 
    您已成年

## 2.3 多分支判断结构

    >>> score = float(input('请输入您的分数: '))
    请输入您的分数: 81
    >>> if score > 85:
    ...     print('优')
    ... elif score > 70:
    ...     print('良')
    ... elif score > 60:
    ...     print('中')
    ... else:
    ...     print('不及格')
    ... 
    良

## 2.4 嵌套判断结构

    >>> username = input('请输入用户名: ')
    请输入用户名: admin
    >>> password = input('请输入密码: ')
    请输入密码: admin123
    >>> if username == 'admin':
    ...     if password == 'admin123':
    ...         print('登录成功!')
    ...     else:
    ...         print('密码错误!')
    ... else:
    ...     print('用户不存在!')
    ... 
    登录成功!

# 3.循环结构

循环结构，Python程序的控制实现，即是控制代码或代码块循环往复执行直到满足退出条件才能退出，关键字为for、while、break、continue和pass

## 3.1 while循环

Python语言while语句表示某条件下循环执行某段程序，直到满足退出的条件才退出循环，可翻译为“当...就...，否则就结束循环”，用于处理重复执行的任务，基本形式为：

    while 判断条件(condition)：
        执行语句(statements)

---------

### 3.1.1 遍历循环

    >>> n = 100
    >>> sum =0
    >>> counter = 1
    >>> while counter <=n:
    ...     sum = sum + counter
    ...     counter += 1
    ... 
    >>> print("1到 %d 之和为: %d" % (n,sum))
    1到 100 之和为: 5050

### 3.1.2 else语句

    >>> while i < num:
    ...     print(i)
    ...     i +=1
    ... else:
    ...     print("执行完毕，结束循环！")
    ... 
    0
    1
    2
    3
    4
    5
    6
    7
    8
    9
    执行完毕，结束循环！

### 3.1.3 无限循环

若while循环的判断语句永远为true，循环将会一直进行下去，即为无限循环

    >>> var = 1
    >>> while var == 1:
    ...     n = int(input("请输入一个数字:"))
    ...     print("你输入的数字为 %d" %n)
    ... 
    请输入一个数字:3
    你输入的数字为 3
    请输入一个数字:2
    你输入的数字为 2
    请输入一个数字:67
    你输入的数字为 67
    请输入一个数字:

## 3.2 for循环

Python语言for循环通常用于遍历可迭代对象，如字符串、列表或字典，即每次从这些对象中取出一个元素进行操作，直到全部遍历完成才退出循环，语法格式如下：

    for 目标 in 迭代对象
        循环体

### 3.2.1 元素循环

    >>> for l in 'Python':
    ...     print("当前字母为：%s" %l)
    ... 
    当前字母为：P
    当前字母为：y
    当前字母为：t
    当前字母为：h
    当前字母为：o
    当前字母为：n

### 3.2.2 索引循环

    >>> database = ['mysql','redis','mongodb']
    >>> for index in range(len(database)):
    ...     print("当前数据库为：%s" %database[index])
    ... 
    当前数据库为：mysql
    当前数据库为：redis
    当前数据库为：mongodb

## 3.3 嵌套循环

嵌套循环即是循环体内再定义另一个循环，但建议循环嵌套不超过3层，否则将会降低程序执行效率

    #!/usr/bin/python3
    # -*- coding: utf-8 -*-

    week = ['一','二','三','四','五']

    for w in week:
        print(f"今天是周{w}")
        for i in range(1,9):
            if i > 6:
                print(f"已经学习{i}小时了，可以休息了")
            else:
                print(f"学习不足{i}小时，继续努力")

## 3.4 循环控制

循环控制语句用于在循环中进行特定操作，如提前终止循环或跳过当前迭代、条件判断之后再执行特定操作等等

### 3.4.1 终止循环

Python语言break语句用于终止循环，即循环条件没有False或序列还没被完全迭代完成的情况下停止执行循环语句，可用于while和for循环。嵌套循环的情况下，break语句将停止执行最深层的循环，并开始执行下一行代码

    >>> for w in 'Python':
    ...     if w == 'h':
    ...         break
    ...     print("当前字母为：",w)
    ... 
    当前字母为： P
    当前字母为： y
    当前字母为： t

### 3.4.2 跳过循环

Python语言continue语句用于跳出本次循环，而不是整个循环，也即是跳过当前循环的剩余语句，然后继续进行下一轮循环，可用于while和for循环

    >>> for w in 'Python':
    ...     if w == 'h':
    ...         continue
    ...     print("当前字母为：",w)
    ... 
    当前字母为： P
    当前字母为： y
    当前字母为： t
    当前字母为： o
    当前字母为： n

### 3.4.3 pass语句

Python语言pass语句是空语句，即不做任务操作，一般用作站位语句，保持程序结构的完整性

    >>> for w in 'Python':
    ...     if w == 'h':
    ...         pass
    ...     print("当前字母为：",w)
    ... 
    当前字母为： P
    当前字母为： y
    当前字母为： t
    当前字母为： h
    当前字母为： o
    当前字母为： n

### 3.4.4 if/else语句

if/else语句用于循环中的条件判断，即根据条件判断的结构执行不同的操作

    #!/usr/bin/python3
    # -*- coding: utf-8 -*-

    video = {'电影': 268,'电视剧': 32,'纪录片': 18}

    for key,value in video.items():
        if value > 30:
           print(f"{key}观看数量达标")
        else:
           print(f"{key}观看过少")