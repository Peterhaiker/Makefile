# Makefile 语法规则  
## 快速上手  
### 基本语法  
```
target:dependency file
  command
```  
**target**:将要生成的目标文件  
**dependency file**:生成前面目标文件需要的依赖文件  
**command**:生成这个目标文件需要执行的命令**以tab开头**  

### 执行语法  
```
make label
```
**label**:label就是makefile文件中的target字段，如果不指定那么默认会执行第一个，若果后面还有就不会执行，所以可以指定执行哪一个  

### 增加变量(宏)  
```
variable=file1 file2 ...
target:$(variable)
  command
```
假如依赖文件太多我们可以使用如上形式，下次修改依赖文件只要改variable后面的即可  

### 自动推导  
GNU的make很强大，它可以自动推导文件以及文件依赖关系后面的命令，于是我们就没必要去在每一个[.o]文件后都写上类似的命令，因为，我们的make会自动识别，并自己推导命令  
只要make看到一个[.o]文件，它就会自动的把[.c]文件加在依赖关系中，如果make找到一个whatever.o，那么whatever.c，就会是whatever.o的依赖文件。并且 cc -c whatever.c 也会被推导出来，于是，我们的makefile再也不用写得这么复杂。我们的是新的makefile又出炉了  
```
objects=file1 file2 ...

run:$(objects)
  gcc -o run $(objects)
main.o:a.h b.h #注意没有加main.c，因为会自动加上去，也没有命令，因为会自动推导  
a.o:a.h
b.o:b.h

```
### 清空中间文件  
```
#上面一大堆其它规则，在文件的最后有如下代码

clean:
  rm edit $(objects)
#更稳健的做法：
.PHONY:clean
clean:
  -rm run $(objects)
```
.PHONY代表伪目标，下面会介绍。rm前面的-代表也许某些文件出现问题，但不要管，继续做后面的事  

### 注意事项  
* 一行写不下的可以用反斜杠转义空格  
    make不管你的命令或编译是否成功，它只负责依赖关系，依赖不满足就退出  
    make只会在依赖文件比target还要新的时候才执行后面的命令，否则跳过  
    makefile中的命令都要以tab键开头

## makefile总述  
### makefile里包含什么  
makefile包括五个东西:**显示规则**,**隐晦规则**,**变量定义**,**文件指示**,**注释**  
* **显示规则**:显式规则说明了，如何生成一个或多的的目标文件。这是由Makefile的书写者明显指出，要生成的文件，文件的依赖文件，生成的命令  
    **隐晦规则**:由于我们的make有自动推导的功能，所以隐晦的规则可以让我们比较粗糙地简略地书写Makefile，这是由make所支持的
    **变量定义**:就是上面介绍的类似宏的变量  
    **注释**:使用#字符，是行注释  

### makefile文件名  
make命令默认寻找**GNUmakefile,makefile,Makefile**，你也可以在使用make时指定`-f`选项后接自定义文件名  

### 引用其它makefile  
```
include foo.make *.mk $(bar)
```
include前面可以有空格除了tab键，可以包含路径和通配符。包含进来的内容会被原样粘贴在include所在位置，如果文件名没找到：  
1. 如果执行make时指定了`-l`或`--include-dir`选项，那么会在这个指定的目录下找  
2. 如果`<prefix>/include(一般是/usr/local/bin或/usr/include)`存在的话，make也会去找  
如果没有找到，它会在载入所有文件后再找一次，若还是没找到，则出错退出。可以在include前加上`-`来忽略这种错误  

### 环境变量MAKEFILES  
如果你的当前环境中定义了环境变量MAKEFILES，那么，make会把这个变量中的值做一个类似于include的动作。这个变量中的值是其它的Makefile，用空格分隔。只是，它和include不同的是，从这个环境变中引入的Makefile的`目标`不会起作用，如果环境变量中定义的文件发现错误，make也会不理

但是在这里我还是建议不要使用这个环境变量，因为只要这个变量一被定义，那么当你使用make时，所有的Makefile都会受到它的影响，这绝不是你想看到的。在这里提这个事，只是为了告诉大家，也许有时候你的Makefile出现了怪事，那么你可以看看当前环境中有没有定义这个变量  

### make工作方式  
GNU的make工作时步骤如下：
1. 读入所有makefile  
2. 载入include包含的makefile  
3. 初始化文件中的变量  
4. 推导隐晦规则，并分析所有规则  
5. 为所有目标文件创建依赖关系链  
6. 根据依赖关系，决定那些目标要重新生成  
7. 执行生成命令  
1-5步为第一个阶段，6-7为第二个阶段。第一个阶段中，如果定义的变量被使用了，那么，make会把其展开在使用的位置。但make并不会完全马上展开，make使用的是拖延战术，如果变量出现在依赖关系的规则中，那么仅当这条依赖被决定要使用了，变量才会在其内部展开  

## 书写规则  
### 概述  
规则包含两个部分，一个是依赖关系，一个是生成目标的方法  
在Makefile中，规则的顺序是很重要的，因为，Makefile中只应该有一个最终目标，其它的目标都是被这个目标所连带出来的，所以一定要让make知道你的最终目标是什么。一般来说，定义在Makefile中的目标可能会有很多，但是第一条规则中的目标将被确立为最终的目标。如果第一条规则中的目标有很多个，那么，第一个目标会成为最终的目标。make所完成的也就是这个目标  

### 在规则中使用通配符  
make支持3中通配符`*,?,[]`,还有一个`~`代表主目录
注意在对变量使用通配符时并不会展开，也就是原样字符，但是在变量被替换为它的值后会在里面展开这个通配符的内容，比如：
```
objects=*.o
#objects就是*.o，不会展开。如果希望通配符起作用，使用如下语法：
objects:=$(wildcard*.o)
```
关于wildcard会在下面讨论  

### 文件搜寻  
在一些大的工程中，有大量的源文件，我们通常的做法是把这许多的源文件分类，并存放在不同的目录中。所以，当make需要去找寻文件的依赖关系时，你可以在文件前加上路径，但最好的方法是把一个路径告诉make，让make在自动去找  
Makefile文件中的特殊变量`VPATH`就是完成这个功能的，如果没有指明这个变量，make只会在当前的目录中去找寻依赖文件和目标文件。如果定义了这个变量，那么，make就会在当当前目录找不到的情况下，到所指定的目录中去找寻文件了  
```
VPATH=src:../headers
```
上面的的定义指定两个目录，`src`和`../headers`，make会按照这个顺序进行搜索。目录由`冒号`分隔。当然，当前目录永远是最高优先搜索的地方  

另一个设置文件搜索路径的方法是使用make的`vpath`关键字（注意，它是全小写的），这不是变量，这是一个make的关键字，这和上面提到的那个VPATH变量很类似，但是它更为灵活。它可以指定不同的文件在不同的搜索目录中。这是一个很灵活的功能。它的使用方法有三种：  
```
vpath <pattern> <directories>
为符合模式<pattern>的文件指定搜索目录<directories>。

vpath <pattern>
清除符合模式<pattern>的文件的搜索目录。

vpath
清除所有已被设置好了的文件搜索目录
```
vapth使用方法中的pattern需要包含`%`字符。`%`的意思是匹配零或若干字符，例如，`%.h`表示所有以`.h`结尾的文件。pattern指定了要搜索的文件集，而directories则指定了pattern的文件集的搜索的目录  
```
vpath %.h ../headers
```
我们可以连续地使用vpath语句，以指定不同搜索策略。如果连续的vpath语句中出现了相同的pattern，或是被重复了的pattern，那么，make会按照vpath语句的先后顺序来执行搜索。如：
```
vpath %.c foo
vpath % blish
vpath %.c bar
```
其表示`.c`结尾的文件，先在`foo`目录，然后是`blish`，最后是`bar`目录  
```
vpath %.c foo:bar
vpath % blish
```
而上面的语句则表示`.c`结尾的文件，先在`foo`目录，然后是`bar`目录，最后才是`blish`目录  

### 伪目标  
最早先的一个例子中，我们提到过一个`clean`的目标，这是一个`伪目标`  
```
clean:
  rm *.o temp
```
正像我们前面例子中的`clean`一样，即然我们生成了许多文件编译文件，我们也应该提供一个清除它们的`目标`以备完整地重编译而用(以`make clean`来使用该目标)  
因为，我们并不生成`clean`这个文件。`伪目标`并不是一个文件，只是一个标签，由于`伪目标`不是文件，所以make无法生成它的依赖关系和决定它是否要执行。我们只有通过显示地指明这个`目标`才能让其生效。当然，`伪目标`的取名不能和文件名重名，不然其就失去了`伪目标`的意义了。这时候，**.PHONY**就派上用场了。我们可以使用一个特殊的标记`.PHONY`来显示地指明一个目标是`伪目标`，向make说明，不管是否有这个文件，这个目标就是`伪目标`  
```
.PHONY:clean
```
只要有这个声明，不管是否有`clean`文件，要运行`clean`这个目标，只有`make clean`这样。于是整个过程可以这样写：
```
.PHONY:clean
clean:
  rm *.o temp
```
伪目标一般没有依赖的文件。但是，我们也可以为伪目标指定所依赖的文件。伪目标同样可以作为`默认目标`，只要将其放在第一个。一个示例就是，如果你的Makefile需要一口气生成若干个可执行文件，但你只想简单地敲一个make完事，并且，所有的目标文件都写在一个Makefile中，那么你可以使用`伪目标`这个特性：  
```
all : prog1 prog2 prog3
.PHONY : all

prog1 : prog1.o utils.o
cc -o prog1 prog1.o utils.o

prog2 : prog2.o
cc -o prog2 prog2.o

prog3 : prog3.o sort.o utils.o
cc -o prog3 prog3.o sort.o utils.o
```
我们知道，Makefile中的第一个目标会被作为其默认目标。我们声明了一个`all`的伪目标，其依赖于其它三个目标。**由于伪目标的特性是，总是被执行的**，所以其依赖的那三个目标就总是不如`all`这个目标新。所以，其它三个目标的规则总是会被决议。也就达到了我们一口气生成多个目标的目的。`.PHONY : all`声明了`all`这个目标为`伪目标`  
随便提一句，从上面的例子我们可以看出，目标也可以成为依赖。所以，伪目标同样也可成为依赖。看下面的例子：  
```
.PHONY: cleanall cleanobj cleandiff

cleanall : cleanobj cleandiff
rm program

cleanobj :
rm *.o

cleandiff :
rm *.diff
```
`make clean`将清除所有要被清除的文件。`cleanobj`和`cleandiff`这两个伪目标有点像`子程序`的意思。我们可以输入`make cleanall`和`make cleanobj`和`make cleandiff`命令来达到清除不同种类文件的目的

### 多目标  
此处待补充  

### 静态模式  
静态模式可以更容易的定义多目标的规则  
```
<targets...>:<target-pattern>:<prereq-patterns...>
  <commands>
```
* **target**:定义一系列目标文件，支持通配符  
    **target-pattern**:指明了targets模式，也就是目标集模式(从targets中选取符合这个模式的作为目标集)  
    **prereq-patterns**:是目标的依赖模式，它对target-pattern形成的模式再进行一次依赖目标的定义  

举例子：如果target-pattern定义成%.o，那么目标集中都是以.o结尾的。此时如果prereq-patterns中是%.c，那依赖文件就是把目标文件中所有的.o变成.c。示例如下：
```
objects=foo.o bar.o
all:$(objects)

$(objects:%.o:%.c)
$(CC) -c $(CFLAGS) $< -o $@
上面的例子中，指明了我们的目标从$object中获取，`%.o`表明要所有以`.o`结尾的目标，也就是`foo.o bar.o`，也就是变量$object集合的模式，而依赖模式`%.c`则取模式`%.o`的`%`，也就是`foo bar`，并为其加下`.c`的后缀，于是，我们的依赖目标就是`foo.c bar.c`。而命令中的`$<`和`$@`则是自动化变量，`$<`表示所有的依赖目标集（也就是`foo.c bar.c`），`$@`表示目标集（也就是`foo.o bar.o`）。于是，上面的规则展开后等价于下面的规则：
foo.o : foo.c
$(CC) -c $(CFLAGS) foo.c -o foo.o
bar.o : bar.c
$(CC) -c $(CFLAGS) bar.c -o bar.o
```
试想，如果我们的`%.o`有几百个，那种我们只要用这种很简单的`静态模式规则`就可以写完一堆规则，实在是太有效率了。再看一个例子：
```
files = foo.elc bar.o lose.o

$(filter %.o,$(files)): %.o: %.c
$(CC) -c $(CFLAGS) $< -o $@
$(filter %.elc,$(files)): %.elc: %.el
emacs -f batch-byte-compile $<
```
$(filter %.o,$(files))表示调用Makefile的filter函数，过滤`$filter`集，只要其中模式为`%.o`的内容。其的它内容，我就不用多说了吧。这个例字展示了Makefile中更大的弹性  

### 自动生成依赖项  
待补充  

## 书写命令  
### 显示命令  
通常make会显示正在执行的命令，前面加个@就不会显示命令而只显示命令执行时显示的内容  
执行make时带入参数`-n`或`--just-print`，那么只显示命令但不执行，有利于调试  
带参数`-s`或`--slient`则是全面禁止命令的显示  

### 命令执行  
如果你想让上一条命令的结果作用于下一条命令，那你应该使用`;`来分隔命令而不是放在两行  

### 命令出错的处理  
一般命令出错后make就会退出，有如下方法忽略命令出错的情况让它继续执行:
* 在命令前加`-`,make会永远把它当做执行成功  
    给make加上参数`-i`或是`--ignore-errors`，那么所有执行出错的命令都会被忽略  
    如果有个规则的目标叫`.IGNORE`,那这个规则中所有命令将会忽略错误  

额外话题：
make参数`-k`或`--keep-going`表示如果规则中的某个命令出错了，那就终止该目标规则的执行，继续执行其它规则  

### 嵌套执行make  
在一些大的工程中，我们会把我们不同模块或是不同功能的源文件放在不同的目录中，我们可以在每个目录中都书写一个该目录的Makefile，这有利于让我们的Makefile变得更加地简洁，而不至于把所有的东西全部写在一个Makefile中，这样会很难维护我们的Makefile，这个技术对于我们模块编译和分段编译有着非常大的好处  
例如，我们有一个子目录叫subdir，这个目录下有个Makefile文件，来指明了这个目录下文件的编译规则。那么我们总控的Makefile可以这样书写：
```
subsystem:
cd subdir && $(MAKE)

其等价于：

subsystem:
$(MAKE) -C subdir
```
定义$(MAKE)宏变量的意思是，也许我们的make需要一些参数，所以定义成一个变量比较利于维护。这两个例子的意思都是先进入`subdir`目录，然后执行make命令  
我们把这个Makefile叫做`总控Makefile`，**总控Makefile的变量可以传递到下级的Makefile中(如果你显示的声明)，但是不会覆盖下层的Makefile中所定义的变量，除非指定了`-e`参数**  
* 如果你要传递变量到下级Makefile中，那么你可以使用这样的声明：
    ```export <variable>
    ```
* 如果你不想让某些变量传递到下级Makefile中，那么你可以这样声明：
    ```
    unexport <variable...>
    ```
示例：
```
示例一：
export variable = value

其等价于：
variable = value
export variable

其等价于：
export variable := value

其等价于：
variable := value
export variable

示例二：
export variable += value

其等价于：
variable += value
export variable
```
**如果你要传递所有的变量，那么，只要一个export就行了。后面什么也不用跟，表示传递所有的变量**  
**SHELL和MAKEFLAGS总是传递到下层makefile中**，特别是MAKEFILES变量，其中包含了make的参数信息，如果我们执行`总控Makefile`时有make参数或是在上层Makefile中定义了这个变量，那么MAKEFILES变量将会是这些参数，并会传递到下层Makefile中，这是一个系统级的环境变量  
但是make命令中的有几个参数并不往下传递，它们是`-C`,`-f`,`-h``-o`和`-W`（有关Makefile参数的细节将在后面说明），如果你不想往下层传递参数，那么，你可以这样来：  
```
subsystem:
cd subdir && $(MAKE) MAKEFLAGS=
```
如果你定义了环境变量MAKEFLAGS，那么你得确信其中的选项是大家都会用到的，如果其中有`-t`,`-n`,和`-q`参数，那么将会有让你意想不到的结果，或许会让你异常地恐慌  
**`-w`或是`--print-directory`会在make的过程中输出一些信息，让你看到目前的工作目录。**比如，如果我们的下级make目录是`/home/hchen/gnu/make`，如果我们使用`make -w`来执行，那么当进入该目录时，我们会看到：  
```
make: Entering directory `/home/hchen/gnu/make'.
```
而在完成下层make后离开目录时，我们会看到：  
```
make: Leaving directory `/home/hchen/gnu/make'
```
当你使用`-C`参数来指定make下层Makefile时，`-w`会被自动打开的。如果参数中有`-s`（`--slient`）或是`--no-print-directory`，那么，`-w`总是失效的  

### 定义命令包  
如果Makefile中出现一些相同命令序列，那么我们可以为这些相同的命令序列定义一个变量(就是打包一组命令，下次直接输入包名即可，方便快捷)。定义这种命令序列的语法以`define`开始，以`endef`结束，如：  
```
define run-yacc
yacc $(firstword $^)
mv y.tab.c $@
endef
```
这里，`run-yacc`是这个命令包的名字，其不要和Makefile中的变量重名。在`define`和`endef`中的两行就是命令序列。还是把这个命令包放到一个示例中来看看吧  
```
foo.c : foo.y
$(run-yacc)
```
我们可以看见，要使用这个命令包，我们就好像使用变量一样。在这个命令包的使用中，命令包`run-yacc`中的`$^`就是`foo.y`，`$@`就是`foo.c`（有关这种以`$`开头的特殊变量，我们会在后面介绍），make在执行命令包时，命令包中的每个命令会被依次独立执行  

## 使用变量  
### 概述  
make中的变量类似与c中的宏，不同的是它可以修改。在Makefile中，变量可以使用在`目标`，`依赖目标`，`命令`或是Makefile的其它部分中  
变量的命名字可以包含字符、数字，下划线（可以是数字开头），但不应该含有`:`、`#`、`=`或是空字符（空格、回车等）。变量是大小写敏感的  
有一些变量是很奇怪字串，如`$<、$@`等，这些是自动化变量，我会在后面介绍  

### 变量基础  
变量在声明时需要给予初值，而在使用时，需要给在变量名前加上`$`符号，但最好用小括号`（）`或是大括号`{}`把变量给包括起来。如果你要使用真实的`$`字符，那么你需要用`$$`来表示  
```
objects = program.o foo.o utils.o
program : $(objects)
cc -o program $(objects)

$(objects) : defs.h
```
它会像c语言的宏一样原样展开  
另外，给变量加上括号完全是为了更加安全地使用这个变量，在上面的例子中，如果你不想给变量加上括号，那也可以，但我还是强烈建议你给变量加上括号  

### 变量中的变量  
在定义变量的值时，我们可以使用其它变量来构造变量的值，在Makefile中有两种方式来在用变量定义变量的值。

先看第一种方式，也就是简单的使用`=`号，在`=`左侧是变量，右侧是变量的值，右侧变量的值可以定义在文件的任何一处，也就是说，右侧中的变量不一定非要是已定义好的值，其也可以使用后面定义的值。如：  
```
foo = $(bar)
bar = $(ugh)
ugh = Huh?

all:
echo $(foo)
```
我们执行`make all`将会打出变量$(foo)的值是`Huh?`，可见，变量是可以使用后面的变量来定义的。可见，变量是可以使用后面的变量来定义的  
这个功能有好的地方，也有不好的地方，好的地方是，我们可以把变量的真实值推到后面来定义，如：  
```
CFLAGS = $(include_dirs) -O
include_dirs = -Ifoo -Ibar
```
当`CFLAGS`在命令中被展开时，会是`-Ifoo -Ibar -O`。但这种形式也有不好的地方，那就是递归定义，如：
```
CFLAGS = $(CFLAGS) -O
或
A = $(B)
B = $(A)
```
这会让make陷入无限的变量展开过程中去，当然，我们的make是有能力检测这样的定义，并会报错。还有就是如果在变量中使用函数，那么，这种方式会让我们的make运行时非常慢，更糟糕的是，他会使用得两个make的函数`wildcard`和`shell`发生不可预知的错误。因为你不会知道这两个函数会被调用多少次  
为了避免上面的这种方法，我们可以使用make中的另一种用变量来定义变量的方法。这种方法使用的是`:=`操作符，如：
```
x := foo
y := $(x) bar
x := later

其等价于：

y := foo bar
x := later
```
因为这种方法里，前面的变量不能使用后面的变量，只能使用前面已定义好了的变量，如：  
```
y := $(x) bar
x := foo

那么，y的值是`bar`，而不是`foo bar`
```
更复杂的例子：  
```
ifeq (0,${MAKELEVEL})
cur-dir := $(shell pwd)
whoami := $(shell whoami)
host-type := $(shell arch)
MAKE := ${MAKE} host-type=${host-type} whoami=${whoami}
endif
```
关于条件表达式和函数，我们在后面再说，对于系统变量`MAKELEVEL`，其意思是，如果我们的make有一个嵌套执行的动作（参见前面的`嵌套使用make`），那么，这个变量会记录了我们的当前Makefile的调用层数  
下面再以两个示例介绍另外两个定义变量时我们需要知道的：  
* 示例一：  
```
nullstring :=
space := $(nullstring) # end of the line
```
nullstring是一个Empty变量，其中什么也没有，而我们的space的值是一个空格。因为在操作符的右边是很难描述一个空格的，这里采用的技术很管用，先用一个Empty变量来标明变量的值开始了，而后面采用`#`注释符来表示变量定义的终止，这样，我们可以定义出其值是一个空格的变量。请注意这里关于`#`的使用，注释符`#`的这种特性值得我们注意，如果我们这样定义一个变量：  
```
dir := /foo/bar # directory to put the frobs in
```
dir这个变量的值是`/foo/bar`，后面还跟了4个空格，如果我们这样使用这样变量来指定别的目录——`$(dir)/file`那么就完蛋了  

* 示例二：  
```
FOO?=bar
```
其含义是，如果FOO没有被定义过，那么变量FOO的值就是`bar`，如果FOO先前被定义过，那么这条语将什么也不做，其等价于：  
```
ifeq ($(origin FOO), undefined)
FOO = bar
endif
```
### 变量高级用法  
* **变量值的替换**  
1. 我们可以替换变量中的共有的部分，其格式是`$(var:a=b)`或是`${var:a=b}`，其意思是，把变量`var`中所有以`a`字串`结尾`的`a`替换成`b`字串。这里的`结尾`意思是`空格`或是`结束符`。示例：  
```
foo := a.o b.o c.o
bar := $(foo:.o=.c)
```
这个示例中，我们先定义了一个`$(foo)`变量，而第二行的意思是把`$(foo)`中所有以`.o`字串`结尾`全部替换成`.c`，所以我们的`$(bar)`的值就是`a.c b.c c.c`  
2. 另外一种变量替换的技术是以`静态模式`（参见前面章节）定义的，如：  
```
foo := a.o b.o c.o
bar := $(foo:%.o=%.c)
```
这依赖于被替换字串中的有相同的模式，模式中必须包含一个`%`字符，这个例子同样让$(bar)变量的值为`a.c b.c c.c`  
* **把变量的值再当成变量**  
3. 
```
x = y
y = z
a := $($(x))
```
在这个例子中，$(x)的值是`y`，所以$($(x))就是$(y)，于是$(a)的值就是`z`。(注意，是`x=y`，而不是`x=$(y)`)  
4. 还可以有更多层次  
```
x = y
y = z
z = u
a := $($($(x)))
```
再复杂一点：  
```
x = $(y)
y = z
z = Hello
a := $($(x))
```
再复杂一点：  
```
x = variable1
variable2 := Hello
y = $(subst 1,2,$(x))
z = y
a := $($($(z)))
```
这个例子中，`$($($(z)))`扩展为`$($(y))`，而其再次被扩展为`$($(subst 1,2,$(x)))`。$(x)的值是`variable1`，subst函数把`variable1`中的所有`1`字串替换成`2`字串，于是，`variable1`变成`variable2`，再取其值，所以，最终，$(a)的值就是$(variable2)的值——`Hello`  
5. 要可以使用多个变量来组成一个变量的名字，然后再取其值:  
```
first_second = Hello
a = first
b = second
all = $($a_$b)
```
这里的`$a_$b`组成了`first_second`，于是，$(all)的值就是`Hello`  
6. 再来看看结合第一种技术的例子：  
```
a_objects := a.o b.o c.o
1_objects := 1.o 2.o 3.o

sources := $($(a1)_objects:.o=.c)
```
这个例子中，如果$(a1)的值是`a`的话，那么，$(sources)的值就是`a.c b.c c.c`；如果$(a1)的值是`1`，那么$(sources)的值是`1.c 2.c 3.c`  
7. 再来看一个这种技术和`函数`与`条件语句`一同使用的例子：  
```
fdef do_sort
func := sort
else
func := strip
endif

bar := a d b g q c
foo := $($(func) $(bar))
```
8. 当然，`把变量的值再当成变量`这种技术，同样可以用在操作符的左边：  
```
dir = foo
$(dir)_sources := $(wildcard $(dir)/*.c)
define $(dir)_print
lpr $($(dir)_sources)
endef
```
这个例子中定义了三个变量：`dir`，`foo_sources`和`foo_print`  

### 追加变量值  
```
objects = main.o foo.o bar.o utils.o
objects += another.o
#这时，objects=main.o foo.o bar.o utils.o another.o
```

### override指示符  
如果有变量是通常make的命令行参数设置的，那么Makefile中对这个变量的赋值会被忽略。如果你想在Makefile中设置这类参数的值，那么，你可以使用“override”指示符。其语法是：  
```
override <variable> = <value>
override <variable> := <value>
```
当然，你还可以追加：  
```
override <variable> += <more text>
```
对于多行的变量定义，我们用define指示符，在define指示符前，也同样可以使用ovveride指示符，如：  
```
override define foo
bar
endef
```

### 多行变量  
还有一种设置变量值的方法是使用define关键字。使用define关键字设置变量的值可以有换行，这有利于定义一系列的命令（前面我们讲过“命令包”的技术就是利用这个关键字）  
define指示符后面跟的是变量的名字，而重起一行定义变量的值，定义是以endef关键字结束。其工作方式和“=”操作符一样。变量的值可以包含函数、命令、文字，或是其它变量。因为命令需要以[Tab]键开头，所以如果你用define定义的命令变量中没有以[Tab]键开头，那么make就不会把其认为是命令。示例：  
```
define two-lines
echo foo
echo $(bar)
ende
```

### 环境变量  
make运行时系统环境变量会载入其中，但是makefile中重名的变量会覆盖它，除非使用`-e`参数(系统环境变量覆盖局部变量)  
因此，如果我们在环境变量中设置了“CFLAGS”环境变量，那么我们就可以在所有的Makefile中使用这个变量了。这对于我们使用统一的编译参数有比较大的好处。如果Makefile中定义了CFLAGS，那么则会使用Makefile中的这个变量，如果没有定义则使用系统环境变量的值，一个共性和个性的统一，很像“全局变量”和“局部变量”的特性  
当make嵌套调用时（参见前面的“嵌套调用”章节），上层Makefile中定义的变量会以系统环境变量的方式传递到下层的Makefile中。当然，默认情况下，只有通过命令行设置的变量会被传递。而定义在文件中的变量，如果要向下层Makefile传递，则需要使用exprot关键字来声明。（参见前面章节）  
当然，我并不推荐把许多的变量都定义在系统环境中，这样，在我们执行不用的Makefile时，拥有的是同一套系统变量，这可能会带来更多的麻烦  

### 目标变量  
前面讲述的都是在整个文件都可访问的全局变量。自动化变量除外(`$<`这种类型的自动化变量属于规则型变量)，这种变量的值依赖于规则的目标和依赖目标的定义  
我也可以设置**局部变量**(target-specific variable)，可以和全局变量同名，因为它的作用域只在这条规则及连带规则中  
```
语法：
<target ...> : <variable-assignment>

<target ...> : overide <variable-assignment>
```
`variable-assignment`可以是前面讲过的各种赋值表达式，如“=”、“:=”、“+=”或是“？=”。第二个语法是针对于make命令行带入的变量，或是系统环境变量  
这个特性非常的有用，当我们设置了这样一个变量，这个变量会作用到由这个目标所引发的所有的规则中去。如：  
```
prog : CFLAGS = -g
prog : prog.o foo.o bar.o
$(CC) $(CFLAGS) prog.o foo.o bar.o

prog.o : prog.c
$(CC) $(CFLAGS) prog.c

foo.o : foo.c
$(CC) $(CFLAGS) foo.c

bar.o : bar.c
$(CC) $(CFLAGS) bar.c
```
在这个示例中，不管全局的$(CFLAGS)的值是什么，在prog目标，以及其所引发的所有规则中（prog.o foo.o bar.o的规则），$(CFLAGS)的值都是“-g”  

### 模式变量  
在GNU的make中，还支持模式变量（Pattern-specific Variable），通过上面的目标变量中，我们知道，变量可以定义在某个目标上。模式变量的好处就是，我们可以给定一种“模式”，可以把变量定义在符合这种模式的所有目标上  
我们知道，make的“模式”一般是至少含有一个“%”的，所以，我们可以以如下方式给所有以[.o]结尾的目标定义目标变量：  
```
%.o : CFLAGS = -O

#模式变量语法：
<pattern ...> : <variable-assignment>

<pattern ...> : override <variable-assignment>
```
override同样是针对于系统环境传入的变量，或是make命令行指定的变量  

## 使用条件判断  
语法：  
```
<conditional-directive>
<text-if-true>
endif
或
<conditional-directive>
<text-if-true>
else
<text-if-false>
endif
```
其中，conditional-directive表示条件关键字，如`ifeq`。这样的关键字有4个：  
* 第一个`ifeq`  
    ```
ifeq (<arg1>, <arg2>)
ifeq '<arg1>' '<arg2>'
ifeq "<arg1>" "<arg2>"
ifeq "<arg1>" '<arg2>'
ifeq '<arg1>' "<arg2>"
    ```
参数可以是函数，如：  
```
ifeq ($(strip $(foo)),)
<text-if-empty>
endif
这个示例中使用了“strip”函数，如果这个函数的返回值是空（Empty），那么<text-if-empty>就生效
```
    第二个`ifneq`  
    ```
ifneq (<arg1>, <arg2>)
ifneq '<arg1>' '<arg2>'
ifneq "<arg1>" "<arg2>"
ifneq "<arg1>" '<arg2>'
ifneq '<arg1>' "<arg2>"
    ```
    第三个`ifdef`  
    ```
    ifdef <variable-name>
    ```
如果变量`variable-name`的值非空，那到表达式为真。否则，表达式为假。当然，`variable-name`同样可以是一个函数的返回值。注意，ifdef只是测试一个变量是否有值，其并不会把变量扩展到当前位置。还是来看两个例子：  
```
示例一：
bar =
foo = $(bar)
ifdef foo
frobozz = yes
else
frobozz = no
endif

示例二：
foo =
ifdef foo
frobozz = yes
else
frobozz = no
endif

第一个例子中，“$(frobozz)”值是"yes"，第二个则是"no"  
```
* 第四个`ifndef`  
    ```
    ifndef <variable-name>
    ```
在`conditional-directive`这一行上，多余的空格是被允许的，但是不能以[Tab]键做为开始（不然就被认为是命令）。而注释符“#”同样也是安全的。“else”和“endif”也一样，只要不是以[Tab]键开始就行了  
    特别注意的是，make是在读取Makefile时就计算条件表达式的值，并根据条件表达式的值来选择语句，所以，你最好不要把自动化变量（如“$@”等）放入条件表达式中，因为自动化变量是在运行时才有的。而且，为了避免混乱，make不允许把整个条件语句分成两部分放在不同的文件中  

## 使用函数  
在Makefile中可以使用函数来处理变量，从而让我们的命令或是规则更为的灵活和具有智能。make所支持的函数也不算很多，不过已经足够我们的操作了。函数调用后，函数的返回值可以当做变量来使用  
### 调用语法  
```
函数调用，很像变量的使用，也是以“$”来标识的:
$(<function><arguments>)
或是：
${<function><arguments>}
```
这里，<function>就是函数名，make支持的函数不多。<arguments>是函数的参数，参数间以逗号“,”分隔，而函数名和参数之间以“空格”分隔。函数调用以“$”开头，以圆括号或花括号把函数名和参数括起。感觉很像一个变量，是不是？函数中的参数可以使用变量，为了风格的统一，函数和变量的括号最好一样，如使用“$(subst a,b,$(x))”这样的形式，而不是“$(subst a,b,${x})”的形式。因为统一会更清楚，也会减少一些不必要的麻烦。来看个示例：  
```
comma:= ,
empty:=
space:= $(empty) $(empty)
foo:= a b c
bar:= $(subst $(space),$(comma),$(foo))
```
在这个示例中，$(comma)的值是一个逗号。$(space)使用了$(empty)定义了一个空格，$(foo)的值是“a b c”，$(bar)的定义用，调用了函数“subst”，这是一个替换函数，这个函数有三个参数，第一个参数是被替换字串，第二个参数是替换字串，第三个参数是替换操作作用的字串。这个函数也就是把$(foo)中的空格替换成逗号，所以$(bar)的值是“a,b,c”  

### 字符串处理函数  
* **subst**  
```
$(subst <from>,<to>,<text>)
名称：字符串替换函数——subst。
功能：把字串<text>中的<from>字符串替换成<to>。
返回：函数返回被替换过后的字符串
```
示例：  
```
$(subst ee,EE,feet on the street)
把“feet on the street”中的“ee”替换成“EE”，返回结果是“fEEt on the strEEt”
```
* **patsubst**  
```
$(patsubst <pattern>,<replacement><text>)
名称：模式字符串替换函数——patsubst。
功能：查找<text>中的单词（单词以“空格”、“Tab”或“回车”“换行”分隔）是否符合模式<pattern>，如果匹配的话，则以<replacement>替换。这里，<pattern>可以包括通配符“%”，表示任意长度的字串。如果<replacement>中也包含“%”，那么，<replacement>中的这个“%”将是<pattern>中的那个“%”所代表的字串。（可以用“/”来转义，以“/%”来表示真实含义的“%”字符）
返回：函数返回被替换过后的字符串。
```
示例：  
```
$(patsubst %.c,%.o,x.c.c bar.c)
把字串“x.c.c bar.c”符合模式[%.c]的单词替换成[%.o]，返回结果是“x.c.o bar.o”
```
备注：  
这和我们前面“变量章节”说过的相关知识有点相似。如：  
```
$(var:<pattern>=<replacement>)
相当于
$(patsubst <pattern>,<replacement>,$(var))

$(var:<suffix>=<replacement>)
相当于
$(patsubst %<suffix>,%<replacement>,$(var))
```
例如：  
```
objects=foo.o bar.o baz.o
那么，$(objects:.o=.c)和$(patsubst %.o,%.c,$(objects))是一样的
```
* **strip**  
```
$(strip <string>)
名称：去空格函数——strip。
功能：去掉<string>字串中开头和结尾的空字符。
返回：返回被去掉空格的字符串值。
```

示例：  
```
$(strip a b c)
把字串“a b c ”去到开头和结尾的空格，结果是“a b c”
```
* **findstring**  
```
$(findstring <find>,<in> )
名称：查找字符串函数——findstring
功能：在字串<in>中查找<find>字串
返回：如果找到，那么返回<find>，否则返回空字符串
    ```
示例：  
```
$(findstring a,a b c)
$(findstring a,b c)
第一个函数返回“a”字符串，第二个返回“”字符串(空字符串)
```
* **filter**  
```
$(filter <pattern...>,<text>)
名称：过滤函数——filter。
功能：以<pattern>模式过滤<text>字符串中的单词，保留符合模式<pattern>的单词。可以有多个模式。
返回：返回符合模式<pattern>的字串
```
示例：  
```
sources:=foo.c bar.c baz.s ugh.h
foo:$(sources)
cc $(filter %.c %.s,$(sources)) -o foo
$(filter %.c %.s,$(sources))返回值是 foo.c baz.s
```
* **filter-out**  
```
$(filter-out<pattern...>text>)
名称：反过滤函数——filter-out。
功能：以<pattern>模式过滤<text>字符串中的单词，去除符合模式<pattern>的单词。可以有多个模式。
返回：返回不符合模式<pattern>的字串
```
示例：  
```
objects=main1.o foo.o main2.o bar.o
mains=main1.o main2.o
$(filter-out $(mains),$(objects)) 返回值是“foo.o bar.o”
```
* **sort**  
```
$(sort <list>)
名称：排序函数——sort。
功能：给字符串<list>中的单词排序（升序）。
返回：返回排序后的字符串。
示例：$(sort foo bar lose)返回“bar foo lose” 。
备注：sort函数会去掉<list>中相同的单词
```
* **word**  
```
$(word <n>,<text>)
名称：取单词函数——word。
功能：取字符串<text>中第<n>个单词。（从一开始）
返回：返回字符串<text>中第<n>个单词。如果<n>比<text>中的单词数要大，那么返回空字符串。
示例：$(word 2, foo bar baz)返回值是“bar”
```
* **wordlist**  
```
名称：取单词串函数——wordlist。
功能：从字符串<text>中取从<s>开始到<e>的单词串。<s>和<e>是一个数字。
返回：返回字符串<text>中从<s>到<e>的单词字串。如果<s>比<text>中的单词数要大，那么返回空字符串。如果<e>大于<text>的单词数，那么返回从<s>开始，到<text>结束的单词串。
示例： $(wordlist 2, 3, foo bar baz)返回值是“bar baz”
```
* **words**  
```
名称：单词个数统计函数——words。
功能：统计<text>中字符串中的单词个数。
返回：返回<text>中的单词数。
示例：$(words, foo bar baz)返回值是“3”。
备注：如果我们要取<text>中最后的一个单词，我们可以这样：$(word $(words <text> ),<text> )
```
* **firstword**  
```
名称：首单词函数——firstword。
功能：取字符串<text>中的第一个单词。
返回：返回字符串<text>的第一个单词。
示例：$(firstword foo bar)返回值是“foo”。
备注：这个函数可以用word函数来实现：$(word 1,<text> )
```
以上，是所有的字符串操作函数，如果搭配混合使用，可以完成比较复杂的功能。这里，举一个现实中应用的例子。我们知道，make使用“VPATH”变量来指定“依赖文件”的搜索路径。于是，我们可以利用这个搜索路径来指定编译器对头文件的搜索路径参数CFLAGS，如：  
```
override CFLAGS += $(patsubst %,-I%,$(subst :, ,$(VPATH)))
```
如果我们的“$(VPATH)”值是“src:../headers”，那么“$(patsubst %,-I%,$(subst :, ,$(VPATH)))”将返回“-Isrc -I../headers”，这正是cc或gcc搜索头文件路径的参数

### 文件名操作函数  
下面我们要介绍的函数主要是处理文件名的。每个函数的参数字符串都会被当做一个或是一系列的文件名来对待  
* **dir**  
    ```
    $(dir <names...>)
    名称：取目录函数——dir。
功能：从文件名序列<names>中取出目录部分。目录部分是指最后一个反斜杠（“/”）之前的部分。如果没有反斜杠，那么返回“./”。
返回：返回文件名序列<names>的目录部分。
示例： $(dir src/foo.c hacks)返回值是“src/ ./”
    ```

* **notdir**  
```
名称：取文件函数——notdir。
功能：从文件名序列<names>中取出非目录部分。非目录部分是指最后一个反斜杠（“/”）之后的部分。
返回：返回文件名序列<names>的非目录部分。
示例： $(notdir src/foo.c hacks)返回值是“foo.c hacks”
```
* **suffix**  
```
$(suffix <names...>)
名称：取后缀函数——suffix。
功能：从文件名序列<names>中取出各个文件名的后缀。
返回：返回文件名序列<names>的后缀序列，如果文件没有后缀，则返回空字串。
示例：$(suffix src/foo.c src-1.0/bar.c hacks)返回值是“.c .c”
```
* **basename**  
```
$(basename <names...>)
名称：取前缀函数——basename。
功能：从文件名序列<names>中取出各个文件名的前缀部分。
返回：返回文件名序列<names>的前缀序列，如果文件没有前缀，则返回空字串。
示例：$(basename src/foo.c src-1.0/bar.c hacks)返回值是“src/foo src-1.0/bar hacks”
```
* **addsuffix**  
```
$(addsuffix <suffix>,<names...>)
名称：加后缀函数——addsuffix。
功能：把后缀<suffix>加到<names>中的每个单词后面。
返回：返回加过后缀的文件名序列。
示例：$(addsuffix .c,foo bar)返回值是“foo.c bar.c”
```
* **addprefix**  
```
$(addsuffix <suffix>,<names...>)
名称：加前缀函数——addprefix
功能：把前缀<prefix>加到<names>中的每个单词后面
返回：返回加过前缀的文件名序列
示例：$(addprefix src/,foo bar)返回值是“src/foo src/bar”
```
* **join**  
```
$(join <list1>,<list2>)
名称：连接函数——join。
功能：把<list2>中的单词对应地加到<list1>的单词后面。如果<list1>的单词个数要比<list2>的多，那么，<list1>中的多出来的单词将保持原样。如果<list2>的单词个数要比<list1>多，那么，<list2>多出来的单词将被复制到<list2>中。
返回：返回连接过后的字符串。
示例：$(join aaa bbb , 111 222 333)返回值是“aaa111 bbb222 333”
```

### foreach函数  
这个函数的意思是，把参数`list`中的单词逐一取出放到参数`var`所指定的变量中，然后再执行`text`所包含的表达式。每一次`text`会返回一个字符串，循环过程中，`text`的所返回的每个字符串会以空格分隔，最后当整个循环结束时，`text`所返回的每个字符串所组成的整个字符串（以空格分隔）将会是foreach函数的返回值  
所以，`var`最好是一个变量名，`list`可以是一个表达式，而`text`中一般会使用`var`这个参数来依次枚举`list`中的单词。举个例子：  
```
names:=a b c d
files:=$(foreach n,$(names),$(n).o)
```
上面的例子中，$(name)中的单词会被挨个取出，并存到变量“n”中，“$(n).o”每次根据“$(n)”计算出一个值，这些值以空格分隔，最后作为foreach函数的返回，所以，$(files)的值是“a.o b.o c.o d.o”  
注意，foreach中的`var`参数是一个临时的局部变量，foreach函数执行完后，参数`var`的变量将不在作用，其作用域只在foreach函数当中  

### if函数  
f函数很像GNU的make所支持的条件语句——ifeq（参见前面所述的章节），if函数的语法是：  
```
$(if <condition>,<then-part>)
或是
$(if <condition>,<then-part>,<else-part>)
```
可见，if函数可以包含“else”部分，或是不含。即if函数的参数可以是两个，也可以是三个。`condition`参数是if的表达式，如果其返回的为非空字符串，那么这个表达式就相当于返回真，于是，`then-part`会被计算，否则`else-part`会被计算。对应被计算的就是if函数的返回值  

### call函数  
call函数是唯一一个可以用来创建新的参数化的函数。你可以写一个非常复杂的表达式，这个表达式中，你可以定义许多参数，然后你可以用call函数来向这个表达式传递参数。其语法是：  
```
$(call <expression>,<parm1>,<parm2>,<parm3>...)
```
当make执行这个函数时，`expression`参数中的变量，如$(1)，$(2)，$(3)等，会被参数`parm1`，`parm2`，`parm3`依次取代。而`expression`的返回值就是call函数的返回值。例如：  
```
reverse=$(1) $(2)
foo=$(call reverse,a,b)
```
那么，foo的值就是“a b”。当然，参数的次序是可以自定义的，不一定是顺序的，如：
```
reverse = $(2) $(1)
foo = $(call reverse,a,b)
```
此时foo的值就是"b a"

### origin函数  
origin函数不像其它的函数，他并不操作变量的值，他只是告诉你你的这个变量是哪里来的？其语法是：  
```
$(origin <variable>)
```
注意，`variable`是变量的名字，不应该是引用。所以你最好不要在`variable`中使用“$”字符。Origin函数会以其返回值来告诉你这个变量的“出生情况”，下面，是origin函数的返回值:  
* **undefined**  
如果`variable`从来没有定义过，origin函数返回这个值“undefined”  
* **default**  
如果`variable`是一个默认的定义，比如“CC”这个变量，这种变量我们将在后面讲述  
* **environment**  
如果`variable`是一个环境变量，并且当Makefile被执行时，“-e”参数没有被打开  
* **file**  
如果`variable`这个变量被定义在Makefile中  
* **command line**  
如果`variable`这个变量是被命令行定义的  
* **override**  
如果variable是被override指示符重新定义的  
* **automatic**  
如果`variable`是一个命令运行中的自动化变量。关于自动化变量将在后面讲述  
这些信息对于我们编写Makefile是非常有用的，例如，假设我们有一个Makefile其包含了一个定义文件Make.def，在Make.def中定义了一个变量“bletch”，而我们的环境中也有一个环境变量“bletch”，此时，我们想判断一下，如果变量来源于环境，那么我们就把之重定义了，如果来源于Make.def或是命令行等非环境的，那么我们就不重新定义它。于是，在我们的Makefile中，我们可以这样写：  
```
ifdef bletch
ifeq "$(origin bletch)" "environment"
bletch=barf,gag,etc
endif
```
当然，你也许会说，使用override关键字不就可以重新定义环境中的变量了吗？为什么需要使用这样的步骤？是的，我们用override是可以达到这样的效果，可是override过于粗暴，它同时会把从命令行定义的变量也覆盖了，而我们只想重新定义环境传来的，而不想重新定义命令行传来的  

### shell函数  
shell函数也不像其它的函数。顾名思义，它的参数应该就是操作系统Shell的命令。它和反引号`\``是相同的功能。这就是说，shell函数把执行操作系统命令后的输出作为函数返回。于是，我们可以用操作系统命令以及字符串处理命令awk，sed等等命令来生成一个变量，如：  
```
contents:=$(shell cat foo)
files:=$(shell echo *.c)
```
注意，这个函数会新生成一个Shell程序来执行命令，所以你要注意其运行性能，如果你的Makefile中有一些比较复杂的规则，并大量使用了这个函数，那么对于你的系统性能是有害的。特别是Makefile的隐晦的规则可能会让你的shell函数执行的次数比你想像的多得多  

### 控制make的运行  
make提供了一些函数来控制make的运行。通常，你需要检测一些运行Makefile时的运行时信息，并且根据这些信息来决定，你是让make继续执行，还是停止  
* **error**  
```
$(error <text...>)
```
产生一个致命的错误，`text ...`是错误信息。注意，error函数不会在一被使用就会产生错误信息，所以如果你把其定义在某个变量中，并在后续的脚本中使用这个变量，那么也是可以的。例如：  
```
示例一：
ifdef ERROR_001
$(error error is $(ERROR_001))
endif

示例二：
ERR = $(error found an error!)
.PHONY: err
err: ; $(ERR)
```
示例一会在变量ERROR_001定义了后执行时产生error调用，而示例二则在目录err被执行时才发生error调用  
* **warining**  
```
$(warning <text...>)
```
这个函数很像error函数，只是它并不会让make退出，只是输出一段警告信息，而make继续执行  

## make的运行  
=======

### 文件名操作函数  
下面我们要介绍的函数主要是处理文件名的。每个函数的参数字符串都会被当做一个或是一系列的文件名来对待  
* **dir**  
    ```
    $(dir <names...>)
    名称：取目录函数——dir。
功能：从文件名序列<names>中取出目录部分。目录部分是指最后一个反斜杠（“/”）之前的部分。如果没有反斜杠，那么返回“./”。
返回：返回文件名序列<names>的目录部分。
示例： $(dir src/foo.c hacks)返回值是“src/ ./”
    ```

* **notdir**  
```
名称：取文件函数——notdir。
功能：从文件名序列<names>中取出非目录部分。非目录部分是指最后一个反斜杠（“/”）之后的部分。
返回：返回文件名序列<names>的非目录部分。
示例： $(notdir src/foo.c hacks)返回值是“foo.c hacks”
```
* **suffix**  
```
$(suffix <names...>)
名称：取后缀函数——suffix。
功能：从文件名序列<names>中取出各个文件名的后缀。
返回：返回文件名序列<names>的后缀序列，如果文件没有后缀，则返回空字串。
示例：$(suffix src/foo.c src-1.0/bar.c hacks)返回值是“.c .c”
```
* **basename**  
```
$(basename <names...>)
名称：取前缀函数——basename。
功能：从文件名序列<names>中取出各个文件名的前缀部分。
返回：返回文件名序列<names>的前缀序列，如果文件没有前缀，则返回空字串。
示例：$(basename src/foo.c src-1.0/bar.c hacks)返回值是“src/foo src-1.0/bar hacks”
```
* **addsuffix**  
```
$(addsuffix <suffix>,<names...>)
名称：加后缀函数——addsuffix。
功能：把后缀<suffix>加到<names>中的每个单词后面。
返回：返回加过后缀的文件名序列。
示例：$(addsuffix .c,foo bar)返回值是“foo.c bar.c”
```
* **addprefix**  
```
$(addsuffix <suffix>,<names...>)
名称：加前缀函数——addprefix
功能：把前缀<prefix>加到<names>中的每个单词后面
返回：返回加过前缀的文件名序列
示例：$(addprefix src/,foo bar)返回值是“src/foo src/bar”
```
* **join**  
```
$(join <list1>,<list2>)
名称：连接函数——join。
功能：把<list2>中的单词对应地加到<list1>的单词后面。如果<list1>的单词个数要比<list2>的多，那么，<list1>中的多出来的单词将保持原样。如果<list2>的单词个数要比<list1>多，那么，<list2>多出来的单词将被复制到<list2>中。
返回：返回连接过后的字符串。
示例：$(join aaa bbb , 111 222 333)返回值是“aaa111 bbb222 333”
```

### foreach函数  
这个函数的意思是，把参数`list`中的单词逐一取出放到参数`var`所指定的变量中，然后再执行`text`所包含的表达式。每一次`text`会返回一个字符串，循环过程中，`text`的所返回的每个字符串会以空格分隔，最后当整个循环结束时，`text`所返回的每个字符串所组成的整个字符串（以空格分隔）将会是foreach函数的返回值  
所以，`var`最好是一个变量名，`list`可以是一个表达式，而`text`中一般会使用`var`这个参数来依次枚举`list`中的单词。举个例子：  
```
names:=a b c d
files:=$(foreach n,$(names),$(n).o)
```
上面的例子中，$(name)中的单词会被挨个取出，并存到变量“n”中，“$(n).o”每次根据“$(n)”计算出一个值，这些值以空格分隔，最后作为foreach函数的返回，所以，$(files)的值是“a.o b.o c.o d.o”  
注意，foreach中的`var`参数是一个临时的局部变量，foreach函数执行完后，参数`var`的变量将不在作用，其作用域只在foreach函数当中  

### if函数  
f函数很像GNU的make所支持的条件语句——ifeq（参见前面所述的章节），if函数的语法是：  
```
$(if <condition>,<then-part>)
或是
$(if <condition>,<then-part>,<else-part>)
```
可见，if函数可以包含“else”部分，或是不含。即if函数的参数可以是两个，也可以是三个。`condition`参数是if的表达式，如果其返回的为非空字符串，那么这个表达式就相当于返回真，于是，`then-part`会被计算，否则`else-part`会被计算。对应被计算的就是if函数的返回值  

### call函数  
call函数是唯一一个可以用来创建新的参数化的函数。你可以写一个非常复杂的表达式，这个表达式中，你可以定义许多参数，然后你可以用call函数来向这个表达式传递参数。其语法是：  
```
$(call <expression>,<parm1>,<parm2>,<parm3>...)
```
当make执行这个函数时，`expression`参数中的变量，如$(1)，$(2)，$(3)等，会被参数`parm1`，`parm2`，`parm3`依次取代。而`expression`的返回值就是call函数的返回值。例如：  
```
reverse=$(1) $(2)
foo=$(call reverse,a,b)
```
那么，foo的值就是“a b”。当然，参数的次序是可以自定义的，不一定是顺序的，如：
```
reverse = $(2) $(1)
foo = $(call reverse,a,b)
```
此时foo的值就是"b a"

### origin函数  
origin函数不像其它的函数，他并不操作变量的值，他只是告诉你你的这个变量是哪里来的？其语法是：  
```
$(origin <variable>)
```
注意，`variable`是变量的名字，不应该是引用。所以你最好不要在`variable`中使用“$”字符。Origin函数会以其返回值来告诉你这个变量的“出生情况”，下面，是origin函数的返回值:  
* **undefined**  
如果`variable`从来没有定义过，origin函数返回这个值“undefined”  
* **default**  
如果`variable`是一个默认的定义，比如“CC”这个变量，这种变量我们将在后面讲述  
* **environment**  
如果`variable`是一个环境变量，并且当Makefile被执行时，“-e”参数没有被打开  
* **file**  
如果`variable`这个变量被定义在Makefile中  
* **command line**  
如果`variable`这个变量是被命令行定义的  
* **override**  
如果variable是被override指示符重新定义的  
* **automatic**  
如果`variable`是一个命令运行中的自动化变量。关于自动化变量将在后面讲述  
这些信息对于我们编写Makefile是非常有用的，例如，假设我们有一个Makefile其包含了一个定义文件Make.def，在Make.def中定义了一个变量“bletch”，而我们的环境中也有一个环境变量“bletch”，此时，我们想判断一下，如果变量来源于环境，那么我们就把之重定义了，如果来源于Make.def或是命令行等非环境的，那么我们就不重新定义它。于是，在我们的Makefile中，我们可以这样写：  
```
ifdef bletch
ifeq "$(origin bletch)" "environment"
bletch=barf,gag,etc
endif
```
当然，你也许会说，使用override关键字不就可以重新定义环境中的变量了吗？为什么需要使用这样的步骤？是的，我们用override是可以达到这样的效果，可是override过于粗暴，它同时会把从命令行定义的变量也覆盖了，而我们只想重新定义环境传来的，而不想重新定义命令行传来的  

### shell函数  
shell函数也不像其它的函数。顾名思义，它的参数应该就是操作系统Shell的命令。它和反引号`\``是相同的功能。这就是说，shell函数把执行操作系统命令后的输出作为函数返回。于是，我们可以用操作系统命令以及字符串处理命令awk，sed等等命令来生成一个变量，如：  
```
contents:=$(shell cat foo)
files:=$(shell echo *.c)
```
注意，这个函数会新生成一个Shell程序来执行命令，所以你要注意其运行性能，如果你的Makefile中有一些比较复杂的规则，并大量使用了这个函数，那么对于你的系统性能是有害的。特别是Makefile的隐晦的规则可能会让你的shell函数执行的次数比你想像的多得多  

### 控制make的运行  
make提供了一些函数来控制make的运行。通常，你需要检测一些运行Makefile时的运行时信息，并且根据这些信息来决定，你是让make继续执行，还是停止  
* **error**  
```
$(error <text...>)
```
产生一个致命的错误，`text ...`是错误信息。注意，error函数不会在一被使用就会产生错误信息，所以如果你把其定义在某个变量中，并在后续的脚本中使用这个变量，那么也是可以的。例如：  
```
示例一：
ifdef ERROR_001
$(error error is $(ERROR_001))
endif

示例二：
ERR = $(error found an error!)
.PHONY: err
err: ; $(ERR)
```
示例一会在变量ERROR_001定义了后执行时产生error调用，而示例二则在目录err被执行时才发生error调用  
* **warining**  
```
$(warning <text...>)
```
这个函数很像error函数，只是它并不会让make退出，只是输出一段警告信息，而make继续执行  

## make的运行  
一般来说，最简单的就是直接在命令行下输入make命令，make命令会找当前目录的makefile来执行，一切都是自动的。但也有时你也许只想让make重编译某些文件，而不是整个工程，而又有的时候你有几套编译规则，你想在不同的时候使用不同的编译规则，等等。本章节就是讲述如何使用make命令的  
### make的退出码  
* **0**:表示成功  
    **1**：如果make运行时出现错误，返回1
    **2**： 如果你使用了make的“-q”选项，并且make使得一些目标不需要更新，那么返回2  

### 指定makefile  
GNU make找寻默认的Makefile的规则是在当前目录下依次找三个文件——“GNUmakefile”、“makefile”和“Makefile”。其按顺序找这三个文件。我们也可以用`-f`指定其它文件。如果在make的命令行是，你不只一次地使用了“-f”参数，那么，所有指定的makefile将会被连在一起传递给make执行  

### 指定目标  
一般来说，make的最终目标是makefile中的第一个目标，而其它目标一般是由这个目标连带出来的。这是make的默认行为。当然，一般来说，你的makefile中的第一个目标是由许多个目标组成，你可以指示make，让其完成你所指定的目标。要达到这一目的很简单，需在make命令后直接跟目标的名字就可以完成（如前面提到的“make clean”形式）  
任何在makefile中的目标都可以被指定成终极目标，但是除了以“-”打头，或是包含了“=”的目标，因为有这些字符的目标，会被解析成命令行参数或是变量。甚至没有被我们明确写出来的目标也可以成为make的终极目标，也就是说，只要make可以找到其隐含规则推导规则，那么这个隐含目标同样可以被指定成终极目标  
有一个make的环境变量叫“MAKECMDGOALS”，这个变量中会存放你所指定的终极目标的列表，如果在命令行上，你没有指定目标，那么，这个变量是空值。这个变量可以让你使用在一些比较特殊的情形下。比如下面的例子：  
```
sources = foo.c bar.c
ifneq ( $(MAKECMDGOALS),clean)
include $(sources:.c=.d)
endif
```
基于上面的这个例子，只要我们输入的命令不是“make clean”，那么makefile会自动包含“foo.d”和“bar.d”这两个makefile  
使用指定终极目标的方法可以很方便地让我们编译我们的程序，例如下面这个例子：  
```
.PHONY: all
all: prog1 prog2 prog3 prog4
```
从这个例子中，我们可以看到，这个makefile中有四个需要编译的程序——“prog1”， “prog2”， “prog3”和 “prog4”，我们可以使用“make all”命令来编译所有的目标（如果把all置成第一个目标，那么只需执行“make”），我们也可以使用“make prog2”来单独编译目标“prog2”  
即然make可以指定所有makefile中的目标，那么也包括“伪目标”，于是我们可以根据这种性质来让我们的makefile根据指定的不同的目标来完成不同的事。在Unix世界中，软件发布时，特别是GNU这种开源软件的发布时，其makefile都包含了编译、安装、打包等功能。我们可以参照这种规则来书写我们的makefile中的目标:
* **all**：这个伪目标是所有目标的目标，其功能一般是编译所有的目标  
    **clean**：这个伪目标功能是删除所有被make创建的文件  
    **install**：这个伪目标功能是安装已编译好的程序，其实就是把目标执行文件拷贝到指定的目标中去  
    **print**：这个伪目标的功能是例出改变过的源文件  
    **tar**：这个伪目标功能是把源程序打包备份。也就是一个tar文件  
    **dist**：这个伪目标功能是创建一个压缩文件，一般是把tar文件压成Z文件。或是gz文件  
    **TAGS**：这个伪目标功能是更新所有的目标，以备完整地重编译使用  
    **check和test**：这两个伪目标一般用来测试makefile的流程  
当然一个项目的makefile中也不一定要书写这样的目标，这些东西都是GNU的东西，但是我想，GNU搞出这些东西一定有其可取之处（等你的UNIX下的程序文件一多时你就会发现这些功能很有用了），这里只不过是说明了，如果你要书写这种功能，最好使用这种名字命名你的目标，这样规范一些，规范的好处就是——不用解释，大家都明白。而且如果你的makefile中有这些功能，一是很实用，二是可以显得你的makefile很专业（不是那种初学者的作品）  

### 检查规则  
有时候，我们不想让我们的makefile中的规则执行起来，我们只想检查一下我们的命令，或是执行的序列。于是我们可以使用make命令的下述参数：  
```
-n
--just-print
--dry-run
--recon
```
不执行参数，这些参数只是打印命令，不管目标是否更新，把规则和连带规则下的命令打印出来，但不执行，这些参数对于我们调试makefile很有用处  
```
-t
--touch
```
这个参数的意思就是把目标文件的时间更新，但不更改目标文件。也就是说，make假装编译目标，但不是真正的编译目标，只是把目标变成已编译过的状态  
```
-q
--question
```
这个参数的行为是找目标的意思，也就是说，如果目标存在，那么其什么也不会输出，当然也不会执行编译，如果目标不存在，其会打印出一条出错信息  
```
-W <file>
--what-if=<file>
--assume-new=<file>
--new-file=<file>
```
这个参数需要指定一个文件。一般是是源文件（或依赖文件），Make会根据规则推导来运行依赖于这个文件的命令，一般来说，可以和“-n”参数一同使用，来查看这个依赖文件所发生的规则命令  
另外一个很有意思的用法是结合“-p”和“-v”来输出makefile被执行时的信息（这个将在后面讲述）  
### make的参数  
下面列举了所有GNU make 3.80版的参数定义。其它版本和产商的make大同小异，不过其它产商的make的具体参数还是请参考各自的产品文档  
* **这两个参数的作用是忽略和其它版本make的兼容性**  
    ```
    -b
    -m
    ```
    **认为所有的目标都需要更新(重编译)**  
    ```
    -B
    --always-make
    ```
    **指定读取makefile的目录。如果有多个“-C”参数，make的解释是后面的路径以前面的作为相对路径，并以最后的目录作为被指定目录**  
    ```
    -C <dir>
    --directory=<dir>

    例如：
    make -C ~hchen/test -C prog等价于make -C ~hchen/test/prog
    ```
    **输出make的调试信息**  
    ```
    --debug[=<options>]
    它有几种不同的级别可供选择，如果没有参数，那就是输出最简单的调试信息。下面是<options>的取值:  
    a —— 也就是all，输出所有的调试信息。（会非常的多）  
    b —— 也就是basic，只输出简单的调试信息。即输出不需要重编译的目标  
    v —— 也就是verbose，在b选项的级别之上。输出的信息包括哪个makefile被解析，不需要被重编译的依赖文件（或是依赖目标）等  
    i —— 也就是implicit，输出所以的隐含规则  
    j —— 也就是jobs，输出执行规则中命令的详细信息，如命令的PID、返回码等  
    m —— 也就是makefile，输出make读取makefile，更新makefile，执行makefile的信息  
    ```
    **相当于`--debug=a`**  
    ```
    -a
    ```
    **指明环境变量的值覆盖makefile中定义的变量的值**  
    ```
    -e
    --environment-overrides
    ```
    **指定需要执行的makefile**  
    ```
    -f=<file>
    --file=<file>
    --makefile=<file>
    ```
    **显示帮助信息**  
    ```
    -h
    --help
    ```
    **在执行时忽略所有错误**  
    ```
    -i
    --ignore-errors
    ```
    **指定一个被包含makefile的搜索目标。可以使用多个`-l`来指定多个目录**  
    ```
    -l <dir>
    --include-dir=<dir>
    ```
    **限制运行的命令个数**  
    ```
    -j jobsnum
    --jobs=jobsnum
    如果没有限制值，make能运行多少就运行多少，如果有一个以上的-j，那么只有最后一个有效
    ```
    **出错也继续运行**  
    ```
    -k
    --keep-going
    如果一个目标失败了，那么依赖于这个目标的目标也不会被执行
    ```
    **指定make运行命令的负载**  
    ```
    -l <load>
    --load-average[=<load]
    —max-load[=<load>]
    ```
    **仅输出执行过程中的命令序列，并不执行它**  
    ```
    -n
    --just-print
    --dry-run
    --recon
    ```
    **不重新生成指定的文件，即使依赖文件新于它**  
    ```
    -o <file>
    --old-file=<file>
    --assume-old=<file>
    ```
    **输出makefile中的所有数据，包括所有的规则和变量**  
    ```
    -p
    --print-data-base
    这个参数会让一个简单的makefile都会输出一堆信息。如果你只是想输出信息而不想执行makefile，你可以使用“make -qp”命令。如果你想查看执行makefile前的预设变量和规则，你可以使用“make –p –f /dev/null”。这个参数输出的信息会包含着你的makefile文件的文件名和行号，所以，用这个参数来调试你的makefile会是很有用的，特别是当你的环境变量很复杂的时候
    ```
    **仅仅是检查所指定的目标是否需要更新**  
    ```
    -q
    --question
    ```
    **禁止make使用任何隐含规则**  
    ```
    -r
    --no-builtin-rules
    ```
    **禁止make使用任何作用于变量上的隐含规则**  
    ```
    -R
    --no-builtin-variabes
    ```
    **在命令运行时不输出命令的输出**  
    ```
    -s
    --silent
    --quiet
    ```
    **取消“-k”选项的作用**  
    ```
    -S
    --no-keep-going
    --stop
    ```
    **阻止生成目标**  
    ```
    -t
    --touch
    相当于UNIX的touch命令，只是把目标的修改日期变成最新的，也就是阻止生成目标的命令运行
    ```
    **输出make程序的版本、版权等**  
    ```
    -v
    --version
    ```
    **输出运行makefile之前和之后的信息**  
    ```
    -w
    --print-directory
    这个参数对于跟踪嵌套式调用make时很有用
    ```
    **禁止“-w”选项**  
    ```
    --no-print-dircetory
    ```
    **假定目标<file>需要更新，如果和“-n”选项使用，那么这个参数会输出该目标更新时的运行动作。如果没有“-n”那么就像运行UNIX的“touch”命令一样，使得<file>的修改时间为当前时间**  
    ```
    -W <file>
    --what-if=<file>
    --new-file=<file>
    --assume-file=<file>
    ```
    **只要make发现有未定义的变量，那么就输出警告信息**  
    ```
    --warn-undefined-variables
    ```
## 隐含规则  

