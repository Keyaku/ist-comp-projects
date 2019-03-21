%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>
#include "node.h"
#include "tabid.h"
extern int yylex();
extern void* yyin;
int yyerror(char *s);

char *infile = "<<stdin>>";
int errors;

#ifndef YYERRCODE
#define YYERRCODE 256
#endif

%}

%union {
	long i;    /* 4-byte integer value */
	char *str; /* string */
	double d;  /* number */
};

%token <i> INT
%token <str> STRING NAME
%token <d> NUMBER

%token TYPE_VOID TYPE_INT TYPE_STR TYPE_NUM
%token PUBLIC CONST
%token IF THEN ELSE
%token WHILE DO FOR IN STEP UPTO DOWNTO BREAK CONTINUE

%token LE GE EQ NE INC DEC ASSIGN

%%

start:;

%%

int yyerror(char *s)
{
	extern int yylineno;
	extern char *getyytext();
	fprintf(stderr, "%s: %s at or before '%s' in line %d\n", infile, s, getyytext(), yylineno);
	errors++;
	return 1;
}

int main(int argc, char *argv[]) {
	extern YYSTYPE yylval;
	int tk;
	yyin = fopen(argv[1], "r");
	while ((tk = yylex())) {
		if (tk > YYERRCODE) {
			printf("%d:\t%s\n", tk, yyname[tk]);
		} else {
			printf("%d:\t%c\n", tk, tk);
		}
	}
	return 0;
}
