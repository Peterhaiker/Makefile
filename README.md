# Makefile 语法规则  
##快速上手
###基本语法  
```
target:dependency file
  command
```  
**target**:将要生成的目标文件  
**dependency file**:生成前面目标文件需要的依赖文件  
**command**:生成这个目标文件需要执行的命令**以tab开头**  

###执行语法  
```
make label
```
**label**:label就是makefile文件中的target字段，如果不指定那么默认会执行第一个，若果后面还有就不会执行，所以可以指定执行哪一个  

###增加变量(宏)  
```
variable=file1 file2 ...
target:$(variable)
  command
```
假如依赖文件太多我们可以使用如上形式，下次修改依赖文件只要改variable后面的即可  

###自动推导  
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
###清空中间文件  
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

###注意事项  
* 一行写不下的可以用反斜杠转义空格  
    make不管你的命令或编译是否成功，它只负责依赖关系，依赖不满足就退出  
    make只会在依赖文件比target还要新的时候才执行后面的命令，否则跳过  
    makefile中的命令都要以tab键开头

##makefile总述  
###makefile里包含什么  
makefile包括五个东西:**显示规则**,**隐晦规则**,**变量定义**,**文件指示**,**注释**  
* **显示规则**:显式规则说明了，如何生成一个或多的的目标文件。这是由Makefile的书写者明显指出，要生成的文件，文件的依赖文件，生成的命令  
    **隐晦规则**:由于我们的make有自动推导的功能，所以隐晦的规则可以让我们比较粗糙地简略地书写Makefile，这是由make所支持的
    **变量定义**:就是上面介绍的类似宏的变量  
    **注释**:使用#字符，是行注释  

###makefile文件名  
make命令默认寻找**GNUmakefile,makefile,Makefile**，你也可以在使用make时指定`-f`选项后接自定义文件名  

###引用其它makefile  
```
include foo.make *.mk $(bar)
```
include前面可以有空格除了tab键，可以包含路径和通配符。包含进来的内容会被原样粘贴在include所在位置，如果文件名没找到：  
1. 如果执行make时指定了`-l`或`--include-dir`选项，那么会在这个指定的目录下找  
2. 如果`<prefix>/include(一般是/usr/local/bin或/usr/include)`存在的话，make也会去找  
如果没有找到，它会在载入所有文件后再找一次，若还是没找到，则出错退出。可以在include前加上`-`来忽略这种错误  

###环境变量MAKEFILES  
如果你的当前环境中定义了环境变量MAKEFILES，那么，make会把这个变量中的值做一个类似于include的动作。这个变量中的值是其它的Makefile，用空格分隔。只是，它和include不同的是，从这个环境变中引入的Makefile的“目标”不会起作用，如果环境变量中定义的文件发现错误，make也会不理

但是在这里我还是建议不要使用这个环境变量，因为只要这个变量一被定义，那么当你使用make时，所有的Makefile都会受到它的影响，这绝不是你想看到的。在这里提这个事，只是为了告诉大家，也许有时候你的Makefile出现了怪事，那么你可以看看当前环境中有没有定义这个变量  

###make工作方式  
GNU的make工作时步骤如下：
1. 读入所有makefile  
2. 载入include包含的makefile  
3. 初始化文件中的变量  
4. 推导隐晦规则，并分析所有规则  
5. 为所有目标文件创建依赖关系链  
6. 根据依赖关系，决定那些目标要重新生成  
7. 执行生成命令  
1-5步为第一个阶段，6-7为第二个阶段。第一个阶段中，如果定义的变量被使用了，那么，make会把其展开在使用的位置。但make并不会完全马上展开，make使用的是拖延战术，如果变量出现在依赖关系的规则中，那么仅当这条依赖被决定要使用了，变量才会在其内部展开  

##书写规则  
###概述  
规则包含两个部分，一个是依赖关系，一个是生成目标的方法  
在Makefile中，规则的顺序是很重要的，因为，Makefile中只应该有一个最终目标，其它的目标都是被这个目标所连带出来的，所以一定要让make知道你的最终目标是什么。一般来说，定义在Makefile中的目标可能会有很多，但是第一条规则中的目标将被确立为最终的目标。如果第一条规则中的目标有很多个，那么，第一个目标会成为最终的目标。make所完成的也就是这个目标  

###在规则中使用通配符  
make支持3中通配符`*,?,[]`,还有一个`~`代表主目录
注意在对变量使用通配符时并不会展开，也就是原样字符，但是在变量被替换为它的值后会在里面展开这个通配符的内容，比如：
```
objects=*.o
#objects就是*.o，不会展开。如果希望通配符起作用，使用如下语法：
objects:=$(wildcard*.o)
```
关于wildcard会在下面讨论  

###文件搜寻  
在一些大的工程中，有大量的源文件，我们通常的做法是把这许多的源文件分类，并存放在不同的目录中。所以，当make需要去找寻文件的依赖关系时，你可以在文件前加上路径，但最好的方法是把一个路径告诉make，让make在自动去找  
Makefile文件中的特殊变量“VPATH”就是完成这个功能的，如果没有指明这个变量，make只会在当前的目录中去找寻依赖文件和目标文件。如果定义了这个变量，那么，make就会在当当前目录找不到的情况下，到所指定的目录中去找寻文件了  
```
VPATH=src:../headers
```
上面的的定义指定两个目录，“src”和“../headers”，make会按照这个顺序进行搜索。目录由“冒号”分隔。当然，当前目录永远是最高优先搜索的地方  

另一个设置文件搜索路径的方法是使用make的“vpath”关键字（注意，它是全小写的），这不是变量，这是一个make的关键字，这和上面提到的那个VPATH变量很类似，但是它更为灵活。它可以指定不同的文件在不同的搜索目录中。这是一个很灵活的功能。它的使用方法有三种：  
```
vpath <pattern> <directories>
为符合模式<pattern>的文件指定搜索目录<directories>。

vpath <pattern>
清除符合模式<pattern>的文件的搜索目录。

vpath
清除所有已被设置好了的文件搜索目录
```
vapth使用方法中的pattern需要包含“%”字符。“%”的意思是匹配零或若干字符，例如，“%.h”表示所有以“.h”结尾的文件。pattern指定了要搜索的文件集，而directories则指定了pattern的文件集的搜索的目录  
```
vpath %.h ../headers
```
我们可以连续地使用vpath语句，以指定不同搜索策略。如果连续的vpath语句中出现了相同的pattern，或是被重复了的pattern，那么，make会按照vpath语句的先后顺序来执行搜索。如：
```
vpath %.c foo
vpath % blish
vpath %.c bar
```
其表示“.c”结尾的文件，先在“foo”目录，然后是“blish”，最后是“bar”目录  
```
vpath %.c foo:bar
vpath % blish
```
而上面的语句则表示“.c”结尾的文件，先在“foo”目录，然后是“bar”目录，最后才是“blish”目录  

###伪目标  
最早先的一个例子中，我们提到过一个“clean”的目标，这是一个“伪目标”  
```
clean:
  rm *.o temp
```
正像我们前面例子中的“clean”一样，即然我们生成了许多文件编译文件，我们也应该提供一个清除它们的“目标”以备完整地重编译而用(以`make clean`来使用该目标)  
因为，我们并不生成“clean”这个文件。“伪目标”并不是一个文件，只是一个标签，由于“伪目标”不是文件，所以make无法生成它的依赖关系和决定它是否要执行。我们只有通过显示地指明这个“目标”才能让其生效。当然，“伪目标”的取名不能和文件名重名，不然其就失去了“伪目标”的意义了。这时候，**.PHONY**就派上用场了。我们可以使用一个特殊的标记“.PHONY”来显示地指明一个目标是“伪目标”，向make说明，不管是否有这个文件，这个目标就是“伪目标”  
```
.PHONY:clean
```
只要有这个声明，不管是否有“clean”文件，要运行“clean”这个目标，只有“make clean”这样。于是整个过程可以这样写：
```
.PHONY:clean
clean:
  rm *.o temp
```
伪目标一般没有依赖的文件。但是，我们也可以为伪目标指定所依赖的文件。伪目标同样可以作为“默认目标”，只要将其放在第一个。一个示例就是，如果你的Makefile需要一口气生成若干个可执行文件，但你只想简单地敲一个make完事，并且，所有的目标文件都写在一个Makefile中，那么你可以使用“伪目标”这个特性：  
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
我们知道，Makefile中的第一个目标会被作为其默认目标。我们声明了一个“all”的伪目标，其依赖于其它三个目标。**由于伪目标的特性是，总是被执行的**，所以其依赖的那三个目标就总是不如“all”这个目标新。所以，其它三个目标的规则总是会被决议。也就达到了我们一口气生成多个目标的目的。“.PHONY : all”声明了“all”这个目标为“伪目标”  
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
“make clean”将清除所有要被清除的文件。“cleanobj”和“cleandiff”这两个伪目标有点像“子程序”的意思。我们可以输入“make cleanall”和“make cleanobj”和“make cleandiff”命令来达到清除不同种类文件的目的
