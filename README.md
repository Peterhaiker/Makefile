# Makefile 语法规则  
##基本语法  
```
target:dependency file
  command
```  
**target**:将要生成的目标文件  
**dependency file**:生成前面目标文件需要的依赖文件  
**command**:生成这个目标文件需要执行的命令**以tab开头**  

##执行语法  
```
make label
```
**label**:label就是makefile文件中的target字段，如果不指定那么默认会执行第一个，若果后面还有就不会执行，所以可以指定执行哪一个  

##增加变量(宏)  
```
variable=file1 file2 ...
target:$(variable)
  command
```
假如依赖文件太多我们可以使用如上形式，下次修改依赖文件只要改variable后面的即可  

##注意事项  
* 一行写不下的可以用反斜杠转义空格  
    make不管你的命令或编译是否成功，它只负责依赖关系，依赖不满足就退出  
    make只会在依赖文件比target还要新的时候才执行后面的命令，否则跳过  
