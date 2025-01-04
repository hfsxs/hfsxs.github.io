---
title: Python格式化输出
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-09-15 15:10:09
---

格式化输出，即字符的转化与连接操作，通常配合输出函数print()使用，所以又被称为字符串格式化输出。格式化使得程序的输出更加的美观、易读，工作机制是输出的文本预先为变量留出一个位置，被称为占位符，输出时直接用变量的值代替这个占位符进行输出，即可按照将占位符标明的格式进行输出。Python程序的格式化方式分为三种，即%方式、format()方法和f-string方式

# 1.%格式化

%格式化是Python最早使用的传统格式化方式，即以百分号%作为占位符，输出时按照顺序将变量的值填充到占位符百分号%前面所对应的位置

## 1.1 字符串格式化

%s表示字符串类型的变量，%%表示百分号%

    str = 'Python'
    >>> print("This is %s!" %str)
    This is Python!
    >>> name = 'Lilei'
    >>> age = 15
    >>> print("My name is %s,I am %d years old" %(name,age))
    My name is Lilei,I am 15 years old

## 1.2 整数格式化

%d表示十进制整数，%b表示二进制整数，%o表示八进制整数，%x表示十六进制的整数

    >>> x = 16
    >>> x8 = 0o20
    >>> x16 = 0x10
    print("%d的八进制数为%o,十六进制数为%x" %(x,x8,x16))
    16的八进制数为20,十六进制数为10

## 1.3 浮点数格式化

%f表示浮点类型的变量，小数点保留位数用".数字f"表示，如.3f表示保留三位小数

    >>> r = 3
    >>> s = 3.14 * r * r
    >>> print("半径为%d的圆面积为%.3f" %(r,s))
    半径为3的圆面积为28.260

# 2.format()方法

format()方法格式化自由度更高，不再区分填充值的类型,使用花括号{}作为占位符，即用传入的参数依次替换字符串内的占位符，如{变量1}、{变量2}。此外，format()方法还支持指定顺序填充及关键字填充等功能，用法浅显易懂

    >>> name = 'Lilei'
    >>> no = 1000
    >>> print("My name is {},no is {}".format(name,no))
    My name is Lilei,no is 1000
    # 指定顺序填充，即是按照format()方法所传入参数的索引进行填充，序号从0开始
    >>> print("{1} is th no of {0}" .format(name,no))
    1000 is th no of Lilei
    # 指定关键字进行填充
    >>> print("{name} no is {no}".format(name='Lilei',no=1000))
    Lilei no is 1000

# 3.f-string格式化

f-string格式化方法自Python3.6开始引入，以f开头，可在其中使用花括号{}替换变量，非常简单易懂，建议使用

    >>> print(f'My name is {name},no is {no}')
    My name is Lilei,no is 1000