%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "node.h"
#include "tabid.h"

extern int yylex(), yyparse(void);
extern void* yyin;
int yyerror(char *s);
int tk;

char *infile = "<<stdin>>";
int errors;

#ifndef YYERRCODE
#define YYERRCODE 256
#endif

%}

%union {
	long i;    /* 4-byte integer value */
	double d;  /* number */
	char *s;   /* string */
	Node *n;   /* abstract Node type */
};

%0 <i> INTEGER
%0 <d> NUMBER
%0 <s> STRING IDENTIFIER

%0 TYPE_VOID TYPE_INT TYPE_STR TYPE_NUM
%0 PUBLIC CONST
%0 IF THEN ELSE
%0 WHILE DO FOR IN STEP UPTO DOWNTO BREAK CONTINUE

%0 LE GE NE INC DEC ASSIGN

%2 IFX
%2 ELSE
%> ASSIGN
%< '<' '>' '=' LE GE NE
%< '+' '-'
%< '*' '/' '%'
%2 '~'
%< '|'
%< '&'
%2 '(' ')' '[' ']'
%2 PTR ADDR '!' UMINUS INC DEC

%%

file: decl;
decl:| decl def
	;

def: publ cons type star ident init ';'    {}
	;

publ:| PUBLIC                        {}
	;

cons:| CONST                         {}
	;

type: TYPE_VOID | TYPE_INT | TYPE_NUM | TYPE_STR
	;

star:| '*'
	;

ident: IDENTIFIER
	;

init: ASSIGN cte
	| ASSIGN ident
	|'(' initparams ')' initbody
	;

param: type star ident
	;

params: param
	| params ',' param
	;

initparams:| params
	;
initbody:| body;

bparam:| bparam param ';'
	;

iparam:| iparam instr
	;

cte: INTEGER
	| cons STRING
	| NUMBER
	;

body: '{' bparam iparam '}'
	;

atto: UPTO | DOWNTO
	;

step:| STEP rval
	;
integer:| INTEGER
	;

instr: IF rval THEN instr %prec IFX
	| IF rval THEN instr ELSE instr
	| DO instr WHILE rval ';'
	| FOR lval IN rval atto rval step DO instr
	| rval ';'
	| body
	| BREAK integer ';'
	| CONTINUE integer ';'
	| lval '#' rval ';'
	;

lval: ident
	| lval '[' rval ']'
	| '*' lval %prec '*'
	;

rval: lval,
	| '(' rval ')'
	| cte
	| rval '(' args ')'
	| rval '(' ')'
		| '-' rval %prec UMINUS
		| '!' rval
	| '&' lval %prec ADDR
	| '~' rval
	| lval INC
	| lval DEC
	| INC lval
	| DEC lval
		| rval '*' rval	 {}
		| rval '/' rval	 {}
		| rval '%' rval	 {}
		| rval '+' rval	 {}
		| rval '-' rval	 {}
	| rval '<' rval	     {}
	| rval '>' rval	     {}
	| rval GE rval	     {}
	| rval LE rval	     {}
	| rval '=' rval	     {}
	| rval NE rval	     {}
		| rval '&' rval	 {}
		| rval '|' rval	 {}
	| lval ASSIGN rval
	;

args: rval
	| args ',' rval
	;

%%

int yyerror(char *s)
{
	extern int yylineno;
	extern char *getyytext();
	fprintf(stderr, "%s: %s at or before '%s' in line %d\n", infile, s, getyytext(), yylineno);
	errors++;
	return 1;
}

int lexer() {
	/* Outputting lexer content */
	while ((tk = yylex())) {
		if (tk > YYERRCODE) {
			printf("%d:\t%s\n", tk, yyname[tk]);
		} else {
			printf("%d:\t%c\n", tk, tk);
		}
	}

	return 0;
}

int compiler() {
	return yyparse();
}

typedef enum project_mode { LEXER = 0, COMPILER, ASSEMBLY } Mode;
int (*fn[])() = { lexer, compiler };

int main(int argc, char *argv[]) {
	extern YYSTYPE yylval;
	Mode mode = COMPILER;
#ifdef YYDEBUG
	extern int yydebug;
	yydebug = getenv("YYDEBUG") ? 1 : 0;
#endif

	/* Opening file from input or from given argument */
	if (argc > 1) {
		infile = argv[1];
		yyin = fopen(infile, "r");
	}

	/* Executing the appropriate code for this part */
	return fn[mode]();
}
