---
title: Python面向对象
categories:
  - 工作
tags:
  - Linux
  - Python
  - 编程语言
  - 云计算
date: 2023-12-01 15:32:11
---

Object Oriented Programming，即面向对象编程，简称为OOP，一种程序设计范式。不同于以函数及函数调用为核心的面相过程式编程，面向对象编程以对象为核心，将数据和操作数据的函数封装为类，从更高的层次进行系统建模，更贴近事物的自然运行模式。其思想概括为：把一组数据和处理数据的方法组成对象，把行为相同的对象归纳为类，通过封装隐藏对象的内部细节，通过继承实现类的特化和泛化，通过多态实现基于对象类型的动态分派。C语言即为典型的面向过程的语言，C++、Python是典型的面向对象的语言

# 1.类与对象

## 1.1 类

class，即类，具有相同属性和方法的一组对象的集合，属性是用于存储对象状态的类变量，方法是用于定义对象行为和操作的类函数。类可看作为模版或蓝图，用于创建具有相似特征的多个对象

## 1.2 对象

object，即对象，也称实例，是基于类这个模版创建的可直接引用的个体，是类的具象化，拥有类所定义的属性和方法。面向对象编程即是以对象为核心，以类和继承为构造机制，来认识、理解、刻画客观世界，从而设计、构建相应的软件系统。Python中一切皆对象

---------

总结，类是对象的抽象表现，是对象的设计蓝图，如动物类、植物类等；对象是类的具体表现，是依据类这个模版设计出的具体产物，如绿箩，由植物类所派生，具有植物通用的属性（如具有绿色叶片）和动作（如制造氧气）

## 1.3 创建类

创建类，即定义类，由class关键字实现，语法格式为：

    class 类名:
        方法列表

- class，用于定义类的关键字，其后为类名，最后的“:”代表类定义的起始
- 类名，即为符合Python语法的标识符，以大写字母开头，并采用驼峰命名法，建议以能够简洁明了地体现出其功能的词汇来命名

---------

    >>> class Student:
    ...     classroom = '101'
    ...     address = 'BeiJing' 
    ...     def __init__(self,name,age):
    ...         self.name = name
    ...         self.age = age
    ...     def introduce(self):
    ...         print(f'我是学生{self.name},今年{self.age}岁.')

## 1.4 创建对象

创建对象，即根据类模板创建对象，也就是类的实例化，故对象也被称为实例，语法格式为：

    对象名 = 类名(属性参数列表) 

- 对象名，就是变量名，命名规则与普通变量一致，首字母小写，以免与类名混淆
- 属性参数列表，由类方法__init__()定义，其中self参数自动传递不需要指定。对象创建成功后即可访问类的属性与方法，使用句点.表示法，语法为：对象名.属性名、对象名.方法名

---------

    # Student类实例化对象John
    >>> John = Student('John',15)

    # John对象访问Student类的属性age
    >>> John.age
    15

    # John对象访问Student类的方法introduce()
    >>> John.introduce()
    我是学生John,今年15岁.

# 2.类成员

类，由属性与方法这两个成员构成

## 2.1 类的属性

属性，即类的数据成员，用于存储数据，可以被类的实例访问与修改，通常由变量定义，也被称为成员变量，分为实例变量与类变量两种

### 2.1.1 实例变量

实例变量，实例对象个体本身拥有的数据，如Student类学生的名字和年龄，通过实例名加圆点的方式进行调用

    # John对象调用实例变量age
    >>> John.age
    15

### 2.1.2 类变量

类变量，属于类的变量，不属于单个的具体的对象，适用于所有实例具有相同字段的场景，所有实例共有且都可访问、修改，如Student类的classroom和address即为类变量，通过类名或实例名加圆点的方式进行调用，建议使用类名.类变量的访问方式，以免与实例变量混淆

    >>> Student.classroom
    '101'
    >>> John.address
    'BeiJing'

## 2.2 类的方法

方法，即类的函数，用于实现类的行为，可以访问、修改类属性，与普通的函数一样也是通过def关键字定义，不同的是方法的第一个参数必须为self且不需要传递实参。类方法分为实例方法、静态方法和类方法三种

### 2.2.1 实例方法

实例方法，由实例对象调用，至少有一个self参数且为第一个参数，执行实例方法时将会自动将调用该方法的实例并赋值给self。通常所说的类方法默认即为实例方法，定义时不需要使用使用特殊的关键字进行标识，如Student类所定义的方法introduce()即为实例方法

- 注：self表示类的实例而不是类本身，也不是Python的关键字，而是约定成俗的命名方式，完全可以由其他词汇代替，但不建议

### 2.2.2 构造方法

构造方法，一个特殊的实例方法，又被称为类的构造函数或初始化方法，实例化对象时将会被自动调用以初始化实例的属性。构造方法一般命名为__init__()，并传递对应的参数，其中第一个参数为self且无需传递实参

#### 2.2.2.1 默认构造方法

定义类时不是必须要定义构造方法，若没有显式地定义__init__() 方法，Python将会提供默认的无参数构造方法，且不进行任何初始化操作，即表示创建一个对象实例，并将其返回

    >>> class Student:
    ...     name = 'John'
    ...     age = 15
    ... 
    >>> obj1 = Student()

#### 2.2.2.2 无参构造方法

构造方法如下情况可以没有参数：

- 简单初始化，类属性的初始值都是固定的，不需要根据外部参数进行修改时，使用无参构造函数来设置属性的默认值，对类属性进行初始化
- 不依赖外部数据，若对象的创建和初始化过程不依赖于外部的变量或状态，也没有其他需要执行的初始化操作，可使用无参构造函数

---------

    >>> class Circle:
    ...     def __init__(self):
    ...         self.radius = 2.0
    ...     def get_area(self):
    ...         return 3.14 * self.radius * self.radius
    ... 
    >>> c1 = Circle()
    >>> c1.get_area()
    12.56

#### 2.2.2.3 有参构造方法

构造方法通过接收外部参数将属性赋予特定的值对实例进行初始化，从而完成基于不同需求或条件创建具有特定属性和行为的对象

    >>> class Circle:
    ...     def __init__(self,radius):
    ...         self.radius = radius
    ...     def get_area(self):
    ...         return 3.14 * self.radius * self.radius
    ... 
    >>> c1 = Circle(2.0)
    >>> c1.get_area()
    12.56

### 2.2.3 静态方法

静态方法，由类调用，属于类，与实例无关，无默认参数，使用类名.静态方法的调用方式。将实例方法的参数self去掉，再于方法定义的上方加上@staticmethod，就成为类静态方法

### 2.2.4 类方法

类方法，由类调用，使用类名.类方法的调用方式，以@classmethod装饰，至少传入一个cls参数（代指类本身，类似self），执行类方法时Python将自动将调用该方法的类赋值给cls。通常情况下，需要先实例化一个类对象才能调用该类的方法或属性，但类方法提供了不实例化类的情况下直接创建对象的方式，实现了封装实例化的过程，并提供更方便的接口给用户，即直接通过类名调用而无需先创建类的实例

---------

    >>> class Deo:
    ...     def __init__(self,name):
    ...         self.name = name
    ...     def ord(self):
    ...         print("实例方法")
    ...     @classmethod
    ...     def class_func(cls):
    ...         print("类方法")
    ...     @staticmethod
    ...     def static_func():
    ...         print("静态方法")
    ... 

    # 创建实例对象f
    >>> f = Deo("John")
    # 实例对象调用实例方法
    >>> f.ord()
    实例方法

    # 类调用类方法
    >>> Deo.class_func()
    类方法
    # 实例对象调用类方法
    >>> f.class_func()
    类方法

    # 类调用静态方法
    >>> Deo.static_func()
    静态方法

# 3.封装、继承与多态

面向对象编程具有三大重要特性，即封装、继承与多态

## 3.1 封装性

封装，即将数据与操作数据的功能代码置于对象内部以隐藏内部细节，只保留接口以供外界调用，而不能通过任何形式修改对象内部实现。封装性使得对象的调用更为简单而无需关心其内部逻辑，代码更易维护，同时一定程度上保障了代码的安全性。Python语言的变量默认为公有，可以在类的外部进行访问。但若是不希望所有的变量和方法能被外部访问，即限制某些成员的访问，以提高程序的健壮性、可靠性及业务的逻辑性，可在成员的名字前加上两个下划线__，使其成为私有成员（private）。私有成员只能在类的内部访问，外部无法访问，若需要外部访问时，在类的内部创建外部可以访问的get和set方法即可

    >>> class People:
    ...     def __init__(self,name,age):
    ...          self.__name = name
    ...          self.__age = age
    ...     def print_age(self):
    ...         print(f"我是{self.__name},{self.__age}岁.")
    ...     def get_name(self):
    ...         return self.__name
    ...     def set_name(self,name):
    ...         self.__name = name
    ...     def set_age(self,age):
    ...         self.__age = age
    ... 
    >>> person = People('John',15)
    >>> person.get_name()
    John
    >>> person.set_name('Tom')

## 3.2 继承性

继承，即基于已有类的基础上创建新类，新类被称为子类或派生类，被继承的类被称为父类、基类或超类。子类继承了父类中的所有属性和方法，但也还可以拥有自己的属性和方法

继承机制实现了代码的复用，即将多个类实现公共功能的共用代码置入父类，而其他类只需作为子类去继承即可，避免了代码的重复性

    >>> class People:
    ...     def __init__(self,name,age):
    ...         self.name = name
    ...         self.age = age
    ...     def intro(self):
    ...         print(f"我是{self.name},{self.age}岁.") 


### 3.2.1 单继承

    >>> class Student(People):
    ...     pass
    ...
    ...
    >>> s = Student('John',15)
    >>> s.intro()
    我是John,15岁.

- 继承的语法是定义类的时候，类名后面的圆括号()中指定父类，若未指定父类，则表明继承object类，即python最顶级的类
- 定义类Student，指定其父类为People，尽管Student类未定义任何方法，但仍可继承父类的intro()方法，并实例化对象s

### 3.2.2 多重继承

多重继承，即子类继承多个父类，按照父类的顺序从左向右依次继承，具体机制为：子类调用某个方法或变量时，首先内部查找，若未找到则开始根据继承机制查找父类；根据父类定义顺序，以深度优先的方式逐一查找父类，且一旦查找到则直接调用，之后不再继续查找

    >>> class Senior(Student,People):
    ...     def __init__(self,name,age,grade):
    ...         People.__init__(self,name,age)
    ...         self.grade = grade
    ...     def intros(self):
    ...         print(f"我是{self.name},{self.age}岁,{self.grade}年级在读.")
    ... 
    >>> s = Senior('John',15,1)
    >>> s.intros()
    我是John,15岁,1年级在读.
    >>> s.intro()
    我是John,15岁.

- Senior类继承了两个父类，即Student与People
- People.__init__(self,name,age)，即调用父类的初始化方法
- 对象s调用intros()方法，内部查找即可；调用intro()方法，首先内部查找，之后按照父类的定义顺序查找Student类，再查找People类

### 3.2.3 方法重写

方法重写，即子类对继承父类的方法进行重些以实现不同的功能，调用子类的该方法时将会执行重写后的方法

    >>> class Exam(Senior,Student,People):
    ...     def __init__(self,name,age,grade,score):
    ...         Senior.__init__(self,name,age,grade)
    ...         self.score = score
    # 重写父类Senior的intros()方法
    ...     def intros(self):
    ...         print(f"我是{self.name},{self.age}岁,{self.grade}年级在读,总分为{self.score}.")
    ... 
    >>> s = Exam('John',15,1,365)
    >>> s.intros()
    我是John,15岁,1年级在读,总分为365.

### 3.2.4 方法扩展

Python语言内置函数super()用于调用父类的方法，通常在子类的方法中使用，以便在对父类方法进行扩展或重写时能够保持父类的行为，特别适用于子类调用父类的初始化方法

    >>> class Exam(Senior,Student,People):
    ...     def __init__(self,name,age,grade,score):
    ...         super().__init__(name,age,grade)
    ...         self.score = score
    ...     def intros(self):
    ...         print(f"我是{self.name},{self.age}岁,{self.grade}年级在读,总分为{self.score}.")
    ... 
    >>> s = Exam('John',15,1,365)
    >>> s.intros()
    我是John,15岁,1年级在读,总分为365.

## 3.3 多态性

多态，即一类事物的多种形态，具体是指多个子类继承父类并重写方法后，同一方法所表现出的不同行为，也即是：一个接口，多种实现。多态性增强了程序的灵活性与扩展性，无论如何对象变化，使用同一种形式调用即可，如下所示：函数show()可通过同一方式去调用类Senior和Coll继承的并重写的父类方法intro()

    >>> class Stu:
    ...     def intro(self):
    ...         print('我是学生.')
    ... 
    >>> class Senior(Stu):
    ...     def intro(self):
    ...         print('我是中学生.')
    ... 
    >>> class Coll(Stu):
    ...     def intro(self):
    ...         print('我是大学生.')
    ... 
    >>> def show(s):
    ...     s.intro()
    ... 
    >>> a = Senior()
    >>> b = Coll()
    >>> show(a)
    我是中学生.
    >>> show(b)
    我是大学生.