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

%token FOR

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
