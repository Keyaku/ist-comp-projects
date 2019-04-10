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
};

%0 <i> INTEGER
%0 <d> NUMBER
%0 <s> STRING IDENTIFIER

%0 TYPE_VOID TYPE_INT TYPE_STR TYPE_NUM
%0 PUBLIC CONST
%0 IF THEN ELSE
%0 WHILE DO FOR IN STEP UPTO DOWNTO BREAK CONTINUE

%0 LE GE EQ NE INC DEC ASSIGN

%2 IFX
%2 ELSE
%> ASSIGN
%< '<' '>' LE GE EQ NE
%< '+' '-'
%< '*' '/' '%'
%2 '~'
%< '|'
%< '&'
%2 '(' ')' '[' ']'
%2 PTR ADDR '!' UMINUS INC DEC

%type<i> lval rval

%%

file: decl;
decl:
	| decl def
	;

def: ';'
	| publ cons type atr lval       {}
	| publ cons type atr lval init  {}
	;

publ:
	| PUBLIC                        {}
	;

cons:
	| CONST                         {}
	;

atr:
	| '*'                           {}
	;

type: TYPE_VOID| TYPE_INT | TYPE_NUM | TYPE_STR
	;

init: ASSIGN INTEGER                {}
	| ASSIGN NUMBER                 {}
	| ASSIGN cons STRING            {}
	| ASSIGN IDENTIFIER             {}
	| '(' params ')'                {}
	| '(' params ')' body           {}
	;

params: param                       {}
	|   param ',' params            {}
	;

param: type atr IDENTIFIER          {}
	;

body: '{' param ';' '}'             {}
	| '{' param ';' instr '}'       {}
	;

lval: IDENTIFIER                    {}
	;

rval: lval                       { $$ = $1; }
	| rval '+' rval              { $$ = $1 + $3; }
	| rval '-' rval              { $$ = $1 - $3; }
	| rval '*' rval              { $$ = $1 * $3; }
	| rval '/' rval              { $$ = $1 / $3; }
	| rval '%' rval              { $$ = $1 % $3; }
	| rval LE rval               { $$ = ($1 <= $3); }
	| rval GE rval               { $$ = ($1 >= $3); }
	| rval EQ rval               { $$ = ($1 == $3); }
	| rval NE rval               { $$ = ($1 != $3); }
	;

atto: UPTO                          {}
	| DOWNTO                        {}
	;

step:
	| STEP rval                     {}
	;

break: BREAK                        {}
	|  BREAK INTEGER                {}
	;

cont: CONTINUE                      {}
	| CONTINUE INTEGER              {}
	;

instr: IF rval THEN instr %prec IFX {}
	| IF rval THEN instr ELSE instr {}
	| DO instr WHILE rval ';'       {}
	| FOR lval IN rval atto rval step DO instr {}
	| rval ';'                      {}
	| body                          {}
	| break                         {}
	| cont                          {}
	| lval '#' rval                 {}
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
	int retval = 0;

	if (yyparse() != 0 || errors > 0) {
		fprintf(stderr, "%d errors in %s\n", errors, infile);
		retval = 1;
	}

	return retval;
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
