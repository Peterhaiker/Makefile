objects=main.o a.o b.o
sources:=$(objects:.o=.c)
vpath= %.h /tmp

bar:=Huh?
foo:=$(bar)
bar:=hello
Foo:=BAR
Foo?=bar
all:
	@echo $(Foo)
	@echo $(sources)

run:$(objects)
	gcc -o run main.o a.o b.o

main.o:a.c b.c main.c a.h b.h
a.o:a.h
b.o:b.h
.PHONY:rm
rm:
	rm *.o
