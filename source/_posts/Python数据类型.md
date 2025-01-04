---
title: Python数据类型
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-01-10 16:55:51
---

变量，即程序用于存储计算数据的内存单元，包含变量的标识、名称和数据。变量名即为存储单元的命名，通过给变量名赋值可以随时改变变量的值。Python变量使用前需进行赋值，赋值之后变量才会被创建并存储于内存，且赋值不需要类型声明

计算机程序的计算数据为适应不同的场景，将数据划分为不同的具备各自特点的类型，以便于高效的处理与展示数据，即数据类型即决定变量类型

# 1.数字类型

数字类型用于存储数学意义上的数值，是不可改变数据类型，即改变数字类型的数据将会重新分配全新的对象。Python支持四种不同的数字类型，即有符号整型int、长整型long（也可代表八进制和十六进制）、浮点型float和复数complex

    >>> print(100)
    100
    >>> print(0.24)
    0.24
    >>> print(-100)
    -100

## 1.1 数字类型转换

int()函数将变量x转化为整数，即只保留变量的整数部分，变量x可以是整数、浮点数或整数字符串
float()函数将变量x转化为浮点数，变量x可以是整数、浮点数或者数字字符串

    >>> x = 100
    >>> int(x)
    100
    >>> float(x)
    100.0
    >>> y = 0.24
    >>> float(y)
    0.24
    >>> int(y)
    0
    # 八进制数，以0o开头
    >>> print(0o12)
    10
    # 十六进制数，以0x开头
    >>> print(0xff00)
    65280

# 2.布尔类型

布尔类型，逻辑运算的计算结果，通常用于判断条件是否成立。Python布尔类型只有两个值，即True与False，首字母一定是大写

    >>> print(1 > 2)
    False
    >>> print(-1 < 2+6)
    True

- 注：None，即空值，Python程序特殊值，是空类型，不是布尔类型，也不能理解为0，因为0是整数类型

# 3.字符串类型

String，即字符串，由数字、字母、下划线等一串字符组成，表示为文本类型的数据，使用单引号''或双引号""创建，三引号'''则表示多行字符串。若字符串本身包含单引号或双引号，则用\标识，如‘I\'m \"OK\ "!’，字符串内容为I'm "OK"!

## 3.1 字符串定义

    # 空字符串
    >>> var = ''
    >>> var = "Hello Python!"
    >>> print(var)
    Hello Python!
    >>> var = 'Hello "Python"!'
    Hello "Python"!
    # len()函数获取字符串的长度
    >>> print(len(var))
    15

## 3.2 字符串运算

### 3.2.1 字符串拼接

字符串拼接，即字符串之间的加法运算，运算符为+，运算结果的数据类型还是字符串，作用类似于火车车厢的拼接

    >>> str1 = "Hello"
    >>> str2 = "!"
    >>> print(str1+str2)
    Hello!
    >>> print(str2+str1)
    !Hello

### 3.2.2 字符串连接

字符串连接，即是字符串的重复，运算符为*，运算结果的数据类型还是字符串，作用相当于字符串的复制

    >>> str = "哈哈"
    >>> print(str*2)
    哈哈哈哈

### 3.2.3 成员运算

成员运算，即是判断某个字符或字符串是否是其成员，运算结果的数据类型是布尔型

    >>> print("H" in str)
    False
    >>> str = "Hello !"
    >>> print("H" in str)
    True
    >>> print("H" not in str)
    False
    >>> print("e" not in str)
    False
    >>> print("*" not in str)
    True

## 3.3 字符串索引

字符串是序列不可变的数据类型，每个字符都是序列的成员，都有属于自己的编号，类似于房间编号，即为索引，通过索引可以取出字符串的成员，取值顺序有两种：

- 正索引，从左到右索引，默认从0开始，最大范围为字符串长度减1
- 负索引，从右到左索引，默认从-1开始，最大范围为字符串开头

---------

字符串索引取值由三部分构成，即字符串变量名或字符串本身、英文中括号、索引

    >>> str = "Hello!"
    >>> print(str)
    Hello!
    >>> print(str[1])
    e
    >>> print(str[-3])
    l

## 3.4 字符串切片

字符串切片，即是截取字符串的部分成员重新组成一个字符串，也即是获取其子串，语法格式为：字符串[star:end:step]，其中star为开始索引，默认为0；end为结束索引，默认字符串的长度，为空也表示字符串的长度；step为步长，可为正整数或负整数，默认为1，表示依次取值，为2表示跳过一个字符取值，为负整数则表示负索引顺序，依此类推

    >>> str = "Kubernetes"
    >>> print(str[1:6])
    ubern
    >>> print(str[1:6:1])
    ubern
    >>> print(str[1:6:2])
    uen
    >>> print(str[-1:-8:-2])
    stne
    >>> print(str[-8:-2])
    bernet
    >>> print(str[3:-2])
    ernet
    >>> print(str[:-2])
    Kubernet
    >>> print(str[3::-2])
    eu

- 注：截取的字符串包含开始索引的字符但不包含结束索引的字符，即左闭右开

## 3.5 转义字符

转义字符，用于表示具有特殊含义或无法常规用普通字符表达的特殊字符，如换行符、制表符等，由反斜杠\+特殊字符组成
    
    # 反斜杠\
    >>> print("\\")
    \
    print("\\User\\admin")
    \User\admin
    # 单引号
    >>> print("\'")
    '
    # 双引号
    >>> print("\"")
    "
    # 响铃
    >>> print("\a")
    >>> print("Error\a")
    Error
    # 制表符，即tab键
    >>> print("123\t45")
    123	45
    # 退格符
    >>> print("123\b45")
    # 换行符
    >>> print("123\n456")
    123
    456
    # 回车符，光标移动到初始位置，回车符之前的内容将被覆盖
    >>> print("123\r45")
    453
    # 行尾续行符
    >>> str = '123' \
    ...       ' 45'
    >>> print(str)
    123 45

# 4.列表类型

List，即列表，是可有序可重复的数据集，支持字符、数字、字符串以及嵌套列表，使用方括号[]创建，是Python中使用最频繁的数据类型。Python列表数据结构是表现为一个可变长度的顺序存储架构，每一个位置存放的都是对象的指针

## 4.1 列表定义

    # 空列表
    >>> list = []
    >>> stu = ['John','Bob','LiLei']

## 4.2 列表运算

### 4.2.1 列表连接

列表连接，即是列表的合并，运算符为+

    >>> list1 = ['1','2','3']
    >>> list2 = ['01','02','03']
    >>> print(list1+list2)
    ['1', '2', '3', '01', '02', '03']

### 4.2.2 列表乘法

列表乘法，即是列表的复制，运算符为*

    >>> print(list2*2)
    ['01', '02', '03', '01', '02', '03']
    >>> print(list2*3)
    ['01', '02', '03', '01', '02', '03', '01', '02', '03']

### 4.2.3 成员运算

元素运算，即是判断某个元素是否在列表中

    >>> print('01' in list2)
    True
    >>> print('1' in list2)
    False
    >>> print('1' not in list2)
    True
    >>> print('01' not in list2)
    False

## 4.3 列表索引

列表的每个元素都有各自的编号，也即列表的索引，通过索引可以取出列表的元素，跟字符串一样

    >>> list = ['a','b','3']
    >>> print(list[1])
    b
    >>> test = list[-1]
    >>> print(test)
    3
    # 创建嵌套列表，即列表的某个元素或某几个元素的数据类型为列表
    >>> list = ['Lilei',['no','001'],['age','18']]
    # 嵌套列表2次索引取值语法为：列表[索引][索引]，
    >>> print(list[2][1])
    18

## 4.4 列表切片

列表切片的语法与字符串切片一致，也是通过索引

    >>> list = ["Lilei",["No","001"],"F","18",["170CM","60KG"]]
    >>> print(list[1:4])
    [['No', '001'], 'F', '18']
    >>> print(list[1:5])
    [['No', '001'], 'F', '18', ['170CM', '60KG']]
    >>> print(list[-2::2])
    ['18']
    >>> print(list[:3:22])
    ['Lilei']
    >>> print(list[:3:-2])
    [['170CM', '60KG']]

## 4.5 列表遍历

    >>> list = ['node01','node02','node03']
    >>> for i in list:
    ...     print(i)
    ... 
    node01
    node02
    node03

# 5.元组类型

Tuple，即元组，是有序不可变的数据集，相当于只读列表，使用圆括号()创建，相比于列表，由于创建时间和占用空间更小所以处理速度更快，更适合多线程环境，代码也更安全

## 5.1 元组定义

    >>> tuple = ("node01","node02","nopde03")
    >>> print(tuple)
    ('node01', 'node02', 'nopde03')

## 5.2 元组运算

### 5.2.1 元组连接

元组连接，即是元组的合并，运算符为+

    >>> tuple1 = ("master01","master02","master03")
    >>> tuple2 = ("node01","node02","node03")
    >>> tuple3 = tuple
    >>> print(tuple1+tuple2)
    ('master01', 'master02', 'master03', 'node01', 'node02', 'node03')
    >>> print(tuple2+tuple1)
    ('node01', 'node02', 'node03', 'master01', 'master02', 'master03')

### 5.2.2 元组乘法

元组乘法，即是元组的复制，运算符为*

    # 定义单元素元组时需要加上一个逗号，否则()就将表示改变运算优先级的圆括号，而不是元组类型
    >>> tuple = ("master",)
    >>> print(tuple*3)
    ('master', 'master', 'master')

### 5.2.3 成员运算

    >>> tuple = ("node01","node02","node03")
    >>> print("node03" in tuple)
    True
    >>> print("node00" in tuple)
    False
    >>> print("node00" not in tuple)
    True
    >>> print("node01" not in tuple)
    False

## 5.3 元组索引

元组的索引用法与列表一致

    >>> print(tuple[2])
    node03
    >>> print(tuple[-2])
    node02

## 5.4 元组切片

元组的切片用法与列表一致

    >>> tuple = ("Lilei",["No","001"],"F","18",["170CM","60KG"])
    >>> print(tuple[1:4])
    (['No', '001'], 'F', '18')
    >>> print(tuple[1:5])
    (['No', '001'], 'F', '18', ['170CM', '60KG'])
    >>> print(tuple[-2:2])
    ()
    >>> print(tuple[:3:2])
    ('Lilei', 'F')
    >>> print(tuple[:3:-2])
    (['170CM', '60KG'],)

## 5.5 元组遍历

    >>> tuple = ('node01','node02','node03')
    >>> for i in tuple:
    ...     print(i)
    ... 
    node01
    node02
    node03

# 6.集合类型

Set，即集合，是无序不重复且可变的数据集，使用花括号{}创建，个元素以逗号,分隔，是数学概念集合的Python实现。由于集合的底层存储是基于哈希方式的实现，所以具有查找速度快的优势，且其数据元素不可重复，特别适用于需要大量查找和去重的应用场景，如爬虫不重复的链接地址

## 6.1 集合定义

    >>> set = {"node01","node01","node01"}
    >>> print(set)
    {'node01'}
    >>> set = {"node01","node02","node03"}
    >>> print(set)
    {'node03', 'node02', 'node01'}
    >>> len(set)
    3

## 6.2 集合运算

### 6.2.1 交集运算

    >>> set1 = {1,2,3}
    >>> set2 = {2,3,4}
    >>> set1 & set2
    {2, 3}

### 6.2.1 并集运算

    >>> set1 | set2
    {1, 2, 3, 4}

### 6.2.3 差集运算

    >>> set1 - set2
    {1}
    >>> set2 - set1
    {4}

### 6.2.4 成员运算

    >>> set = {"master","node01","node02"}
    >>> print("node03" in set)
    False
    >>> print("node03" not in set)
    True
    >>> print("node02" not in set)
    False
    >>> print("node02" in set)
    True

### 6.2.5 比较运算

集合的比较运算就是数学中集合的包含关系的体现，==表示相等，!=表示不等，<=表示子集，<表示真子集

    >>> set1 = {1,2,3,4,5,6}
    >>> set2 = {1,2,3,4,5}
    >>> set3 = set1
    >>> print(set1==set2,set1==set3,set2!=set1)
    False True True
    >>> print(set2<set1,set3<=set2,set1<set3)
    True False False

## 6.3 集合遍历

集合是无序数据类型，所以没有索引，不能通过引用索引来访问集合的元素，只能进行循环遍历

    set = {"master","node01","node02"}
    >>> for x in set:
    ...     print(x)
    ... 
    master
    node01
    node02

# 7.字典类型

Dict，即字典，是有序可变的键值对数据集，由索引(key)和它对应的值value组成，通过唯一的Key进行存取（重复Key则会被覆盖），使用花括号{}创建，元素以逗号,隔开，元素的k/v由冒号:连接，是典型的映射类数据。字典可精确描述不定长、可变、散列的数据类型，底层存储基于hash散列算法实现，具有非常快的查取和插入速度，根据key的值计算value的地址，可用于关键字存储、提取值

## 7.1 字典定义

    >>> dict = {}
    >>> print(dict)
    {}
    >>> dict = {"name":"LiLei","no":"001","age":"15"}
    >>> print(dict)
    {'name': 'LiLei', 'no': '001', 'age': '15'}
    >>> len(dict)
    3

## 7.2 字典访问

通过方括号内引用字典元素的key来访问字典的元素

    >>> name = dict["name"]
    >>> print(name)
    LiLei

## 7.3 字典修改

### 7.3.1 元素添加

    >>> dict["sex"] = "F"
    >>> print(dict)
    {'name': 'LiLei', 'no': '001', 'age': '15', 'sex': 'F'}

### 7.3.2 元素修改

    >>> print(dict)
    {'name': 'LiLei', 'no': '001', 'age': '15', 'sex': 'F'}
    >>> dict["age"] = 16
    >>> print(dict)
    {'name': 'LiLei', 'no': '001', 'age': 16, 'sex': 'F'}

### 7.3.3 元素删除

字典的元素删除使用del关键字

    >>> dict = {"name":"Lilei","no":"15","age":"15"}
    >>> print(dict)
    {'name': 'Lilei', 'no': '15', 'age': '15'}
    >>> del dict["age"]
    >>> print(dict)
    {'name': 'Lilei', 'no': '15'}

## 7.4 字典遍历

字典遍历可通过key、value、key/value进行循环

### 7.4.1 key循环遍历

默认情况下是循环key，也可指定循环key

    >>> for item in dict:
    ...     print(item)  
    ... 
    name
    no
    age

    >>> for item in dict.keys():
    ...     print(item)
    ...      
    name
    no
    age

### 7.4.2 value循环遍历

>>> for item in dict.values():
...     print(item)
... 
Lilei
15
15

#### 7.4.3 key/value循环遍历

    >>> for key,value in dict.items():
    ...     print(key,value)
    ... 
    name Lilei
    no 15
    age 15