%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
void yyerror(char *s);
%}

%union {
	long i;    /* 4-byte integer value */
	char *str; /* string */
	double f;  /* number */
};

%token <i> INT
%token <str> STRING NAME
%token <f> NUMBER

%token VOID
%token TYPE_INT
%token TYPE_STR
%token TYPE_NUM
%token PUBLIC
%token CONST
%token IF
%token THEN
%token ELSE
%token WHILE
%token DO
%token FOR
%token IN
%token STEP
%token UPTO
%token DOWNTO
%token BREAK
%token CONTINUE

%%

file	:
	;

%%

char **yynames =
#if YYDEBUG > 0
		(char**)yyname;
#else
		0;
#endif
