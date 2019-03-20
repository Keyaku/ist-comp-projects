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

%token TYPE_VOID TYPE_INT TYPE_STR TYPE_NUM
%token PUBLIC CONST
%token IF THEN ELSE
%token WHILE DO FOR IN STEP UPTO DOWNTO BREAK CONTINUE

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
