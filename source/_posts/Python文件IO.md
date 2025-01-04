---
title: Python文件IO
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-11-12 15:45:24
---

file，即文件，用于将存储于内存的数据持久化到磁盘，以防程序结束或关闭后丢失数据，方便程序再次将数据读取到内存进行处理。现代操作系统不允许普通程序直接操作磁盘，而是由文件系统完成文件的读写。Python内置函数open()用于文件的读写操作，流程类似于将大象塞进冰箱，分三步走，即打开文件、操作文件、关闭文件：

- 1.open()函数打开文件获取文件对象，并指定访问模式，可将之赋值给变量，即文件句柄（包含了文件的文件名、字符集、文件大小、硬盘上的起始位置）
- 2.通过文件对象执行读、写、追加操作
- 3.关闭并释放文件对象

# 1.文件打开与关闭

## 1.1 文件打开

Python内置函数open()用于文件的打开，语法格式如下：

    f = open(filename, mode='r', buffering=None, encoding=None，errors=None)

- filename，设置文件名称，通常是一个文件路径，绝对路径相对路径均可
- mode，设置文件打开模式，可选参数，默认为r，表示文本文件的只读模式，若文件不存在则报错；w表示只写模式，若文件不存在则新建后再写入，文件存在则先清空再写入；a表示追加模式，若文件不存在则新建再写入，文件存在则在文件末尾追加写入；x表示新建模式，若文件存在则报错，文件不存在则新建再写入，比w模式更安全；b表示二进制模式，以bytes类型操作数据，如rb、wb、ab；+表示可读可写模式，r+表示打开文件用于读写，可配合seek()和tell()方法实现更多操作，w+表示读写之前清空文件内容（不建议使用），a+表示只能在文件末尾使用（不建议使用）
- buffering，设置文件IO缓冲区的大小，即先将数据存入内存缓冲区再一次性操作磁盘IO，以免频繁地操作磁盘IO导致程序效率的降低。若不设置则表示不开启缓存，默认为-1，表示全缓冲，即与系统及磁盘块大小有关，设为大于1的整数表示字节数为buffering的全缓冲，也就是多少字节后执行一次写操作；1表示行缓冲，及遇到换行符执行一次写操作；0表示无缓冲模式
- encoding，设置文件编码，默认为UTF-8，用于打开文本文件，若与文件保存时的编码方式不一致，则可能因无法解码而导致文件打开失败
- errors，设置文本文件发生编码错误时的处理方式，用于处理编码不规范的文件，如读取GBK编码文件，建议设为ignore，即忽略编码错误继续执行
- f，变量，文件对象，其值即为open()函数的返回值所赋予，文件的读写操作都要由其来执行

---------

    >>> f = open('test.txt','w')
    # 输出文件名称
    print(f.name)
    test.txt
    # 输出文件的访问模式
    >>> print(f.mode)
    w
    # 判断文件是否已被关闭
    >>> print(f.closed)
    False

## 1.2 文件关闭

Python内置函数close()用于文件对象的关闭，close()函数的调用将刷新缓冲区还未完全被写入到文件的信息，保障了数据的完整性，同时也会释放文件的读写权限与系统资源，以便于其他程序操作该文件，所以文件操作完毕后关闭文件非常有必要

    >>> f = open('test.txt','w')
    >>> print(f.closed)
    False
    >>> f.close()
    >>> print(f.closed)
    True

### 1.2.1 文件异常关闭

文件操作往往会抛出异常，为了保障对文件的操作无论是正常结束还异常结束都能够关闭文件，建议对close()方法的调用放在异常处理的finally代码块中，以防文件操作异常导致的数据丢失

### 1.2.2 文件自动关闭

Python内置的with as代码块用于close()函数的自动调用，以自动释放系统资源，替代finally代码块，优化了代码结构，提高程序的可读性

    >>> with open('test','w') as f:
    ...     pass
    ... 
    >>> print(f.closed)
    True
    >>> with open('test','w') as f1,open('test.txt','r') as f2:
    ...     pass
    ... 
    >>> print(f1.closed)
    True
    >>> print(f2.closed)
    True

# 2.文件读操作

Python内置函数open()创建的文件对象所属的read()、readline()、readlines()方法用于对文件进行读操作

## 2.1 read()

read()方法将从文件的当前位置一次性读取一定大小的数据（忽略文件末尾的换行符）, 并返回字符串或字节对象。该方法有一个数字类型的可选参数size，表示指定读取的数据量，适用于文件大小不确定的场景，反复调用read(size)比较保险；若将之省略或设为负值，则表示读取文件的所有数据，适用于小文件的场景

    >>> with open('test.txt','r') as f:
    ...     str = f.read()
    ...     print(str)
    ... 
    Hello!
    This is a test.

---------

    >>> f = open('test.txt','r')
    >>> str = f.read(10)
    >>> print(str)
    Hello!
    Thi
    >>> f.close()

## 2.2 readline()

readline()方法将从文件当前位置读取一行内容，并将文件指针移动到下一行的开始，为下一次读取做准备，返回值也是字符串或字节对象。该方法也可设置读取的数据大小，表示只读取当前位置当前行的size个字符，适用于读一行就处理一行的场景，且不能回头只能前进

    >>> f = open('test.txt','r')
    >>> str = f.readline()
    >>> print(str)
    Hello!
    >>> print(str)
    Hello!
    >>> strs = f.readline()
    >>> print(strs)
    This is a test.
    >>> str = f.readline()
    >>> print(str)

    >>>
    >>> f.close()

---------

    >>> f = open('test.txt','r')
    >>> str = f.read(3)
    >>> print(str)
    Hel
    >>> str = f.read(3)
    >>> print(str)
    lo!
    >>> str = f.read(3)
    >>> print(str)

    Th
    >>> str = f.read()
    >>> print(str)
    is is a test.

    >>> 
    >>> f.close()

## 2.3 readlines()

readlines()方法将文件的所有行一行一行全部读入一个列表，按顺序一个一个作为列表的元素，并返回这个列表。该方法将会读取文件的所有数据，并将指针移动到文件结尾处，也可指定size读取的直到指定字符所在的行，适用于配置文件

    >>> f = open('test.txt','r')
    >>> list = f.readlines()
    >>> print(list)
    ['Hello!\n', 'This is a test.\n']
    >>> f.close()

---------

    >>> f = open('test.txt','r')
    >>> f.readlines(3)
    ['Hello!\n']
    >>> f.close()
    >>> f = open('test.txt','r')
    >>> f.readlines(3)
    ['Hello!\n']
    >>> f.readlines(3)
    ['This is a test.\n']
    >>> f.readlines(3)
    []

## 2.4 文件遍历

文件对象作为迭代器可快速地循环遍历文件的所有数据，每次循环一行数据而不需要一次性全部读取，且会在行末添加换行符’\n’，适用于通用场景及大文件场景，但与readline()方法一样只能前进不能回退

    >>> with open('hosts.ini','r') as f:
    ...     for line in f:
    ...         print(line,end='')
    ... 
    node01
    node02
    node03
    node04
    >>> 

# 3.文件写操作

Python内置函数open()创建的文件对象所属的write()与writelines()方法用于对文件进行写操作

## 3.1 write()

write()方法将字符串或字节对象写入文件，并返回写入的字符数，且不会在字符串的结尾添加换行符('\n')。该方法在内存中操作，不会立刻写回硬盘，执行close()方法才会将所有写入操作落盘。若需立刻保存到硬盘，也即是在未关闭文件的情况下写入文件，使用flush()方法即可

    >>> with open('test.txt','w') as f:
    ...     f.write('Hello!\n This is a test.\n')
    ... 
    24

## 3.2 writelines()

writelines()方法将一个字符串列表写入文件，且不添加行分隔符，因此通常需要为每一行末尾添加行分隔符

    >>> hosts = ['node01\n','node02\n','node03\n']
    >>> with open('hosts.ini','w') as f:
    ...     f.writelines(hosts)
    ... 
    >>> f = open('hosts.ini','r+')
    >>> f.read()
    'node01\nnode02\nnode03\n'
    >>> f.writelines("node04\n")
    >>> f.close()
    >>> with open('hosts.ini','r') as f:
    ...     f.read()
    ... 
    'node01\nnode02\nnode03\nnode04\n'

# 4.文件指针

文件读写指针用于标记文件的当前位置，第一次打开文件时，文件指针通常会指向文件的开始位置，调用read()方法后则会将文件指针移动到读取内容的末尾，默认情况下是文件末尾，重新打开文件时文件指针则会还原到文件开始位置

## 4.1 指针定位

tell()方法用于返回文件指针的当前位置，其值为文件开头开始算起的字节数

    >>> f = open('hosts.ini','rb')
    >>> f.tell()
    0
    >>> f.read(3)
    'nod'
    >>> f.tell()
    3
    >>> f.readline(3)
    'e01'
    >>> f.tell()
    6

## 4.2 指针更改

seek()方法用于指定文件指针的当前位置，语法格式如下：

    f.seek(offset,from_what)

- from_what，即起始位置，默认为0，表示如果是0表示文件开头，1表示文件指针的当前位置，2文件末尾
- offset，即偏移量，seek(x)或seek(x,0)表示从文件首行首字符开始移动x个字符；seek(x,1)表示从文件当前位置往后移动x个字符；seek(-x,2)表示从文件结尾往前移动x个字符

---------

    >>> f.read()
    b'\nnode02\nnode03\nnode04\n'
    >>> f.tell()
    28
    >>> f.seek(-8,2)
    20
    >>> f.read()
    b'\nnode04\n'
    >>> f.seek(0)
    0
    >>> f.seek(3)
    3
    >>> f.read(3)
    b'e01'
    >>> f.tell()
    6
    >>> f.seek(4,1)
    10
    >>> f.read(3)
    b'e02'
    >>> f.close()