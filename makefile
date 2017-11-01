run:main.o a.o b.o
	gcc -o run main.o a.o b.o

main.o:main.c a.c a.h
	gcc -c main.c a.c

a.o:a.c a.h
	gcc -c a.c

b.o:b.c b.h
	gcc -c b.c
