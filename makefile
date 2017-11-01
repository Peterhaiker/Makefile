objects=main.o a.o b.o

run:$(objects)
	gcc -o run main.o a.o b.o

main.o:a.c b.c a.h b.h
a.o:a.h
b.o:b.h
.PHONY:rm
rm:
	rm *.o
