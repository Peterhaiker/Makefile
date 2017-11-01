/*
 * main.c
 * Copyright (C) 2017-11-01 12:22 
 * author  Peterhaiker 
 * email   <vim.memory@gmail.com>
 *
 * description:
 */

#include "stdio.h"
#include"a.h"
#include"b.h"

int main(int argc,char*argv[])
{
  printf("A=%d,B=%d\n",A,B);
  a();
  b();
  puts("main finished");
  return 0;
}
