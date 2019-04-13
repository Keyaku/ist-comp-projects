%{
#include <stdio.h>
#include <stdlib.h>
#include <stdarg.h>
#include <string.h>

#include "node.h"
#include "tabid.h"

extern int yylex(), yyparse(void);
extern void* yyin;
extern void* yyout;
int yyerror(char *s);
int tk;

char *infile = "<<stdin>>",
	*outfile = NULL;

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

%token <i> INTEGER
%token <d> NUMBER
%token <s> STRING IDENTIFIER

%token TYPE_VOID TYPE_INT TYPE_STR TYPE_NUM
%token PUBLIC CONST
%token IF THEN ELSE
%token WHILE DO FOR IN STEP UPTO DOWNTO BREAK CONTINUE

%token LT LE GT GE EQ NE INC DEC ASSIGN BAND BOR
%token tMUL tDIV tMOD tADD tSUB

%nonassoc IFX
%nonassoc ELSE
%right ASSIGN
%left '<' '>' '=' LE GE NE
%left '+' '-'
%left '*' '/' '%'
%nonassoc '~' BNOT
%left '|' BOR
%left '&' BAND
%nonassoc '(' ')' '[' ']'
%nonassoc PTR ADDR '!' NOT UMINUS INC DEC

%token FILE_TOKEN DECLARATION DEFINITION BODY PARAM PARAMS
%token tBPARAM tIPARAM CTE tBODY tFORTO tUPTO tDOWNTO tSTEP tARGS tSTACK

%token ATTRIBUTES MODIFIERS REFERENCE TYPE INDEX LOAD CALL END
%token INITIALIZERS INITIALIZATION

%type<n> PUBLIC CONST TYPE ASSIGN

%type<n> decl def
%type<n> atr mod ref publ cons type star ident init
%type<n> cte integer instr lval rval args
%type<n> param params body forto step
%type<n> initparams initbody bparam iparam


%%

file: decl;                                      { printNode(uniNode(FILE_TOKEN, $1), yyout, (char**)yyname); }
decl:                                            { $$ = nilNode(END); }
	| decl def                                   { $$ = uniNode(DECLARATION, $2); }
	;

atr: mod ref                                     { $$ = binNode(ATTRIBUTES, $1, $2); }
	;

mod: publ cons                                   { $$ = binNode(MODIFIERS, $1, $2); }
	;

publ:                                            { $$ = nilNode(END); }
	| PUBLIC                                     { $$ = nilNode(PUBLIC); }
	;

cons:                                            { $$ = nilNode(END); }
	| CONST                                      { $$ = nilNode(CONST); }
	;

ref: type star                                   { $$ = binNode(REFERENCE, $1, $2); }
	;

star:                                            { $$ = nilNode(END); }
	| '*'                                        { $$ = nilNode('*'); }
	;

type: TYPE_VOID                                  { $$ = nilNode(TYPE_VOID); }
	| TYPE_INT                                   { $$ = nilNode(TYPE_INT); }
	| TYPE_NUM                                   { $$ = nilNode(TYPE_NUM); }
	| TYPE_STR                                   { $$ = nilNode(TYPE_STR); }
	;

def: atr ident init ';'                          { $$ = binNode(DEFINITION, $1, binNode(INITIALIZATION, $2, $3)); }
	;

ident: IDENTIFIER                                { $$ = strNode(IDENTIFIER, $1); }
	;

init: ASSIGN cte                                 { $$ = binNode(ASSIGN, $1, $2); }
	| ASSIGN ident                               { $$ = binNode(ASSIGN, $1, $2); }
	|'(' initparams ')' initbody                 { $$ = binNode(INITIALIZERS, $2, $4); }
	;

param: ref ident                                 { $$ = binNode(PARAM, $1, $2); }
	;

params: param                                    { $$ = $1; }
	| params ',' param                           { $$ = addNode($1, $3, -1); }
	;

initparams:                                      { $$ = nilNode(END); }
	| params                                     { $$ = uniNode(PARAMS, $1); }
	;
initbody:                                        { $$ = nilNode(END); }
	| body                                       { $$ = uniNode(BODY, $1); }
	;

bparam:                                          { $$ = nilNode(END); }
	| bparam param ';'                           { $$ = binNode(tBPARAM, $1, $2); }
	;

iparam:                                          { $$ = nilNode(END); }
	| iparam instr                               { $$ = binNode(tIPARAM, $1, $2); }
	;

cte: INTEGER                                     { $$ = intNode(INTEGER, $1); }
	| cons STRING                                { $$ = binNode(CTE, $1, strNode(STRING, $2)); }
	| NUMBER                                     { $$ = realNode(NUMBER, $1); }
	;

body: '{' bparam iparam '}'                      { $$ = binNode(tBODY, $2, $3); }
	;

forto: UPTO  rval                                { $$ = uniNode(tUPTO,   $2); }
	| DOWNTO rval                                { $$ = uniNode(tDOWNTO, $2); }
	;

step:                                            { $$ = nilNode(END); }
	| STEP rval                                  { $$ = uniNode(tSTEP, $2); }
	;

instr: IF rval THEN instr %prec IFX              { $$ = binNode(IF, $2, uniNode(THEN, $4)); }
	| IF rval THEN instr ELSE instr              { $$ = binNode(IF, $2, binNode(THEN, $4, uniNode(ELSE, $6))); }
	| DO instr WHILE rval ';'                    { $$ = binNode(DO, $2, uniNode(WHILE, $4)); }
	| FOR lval IN rval forto step DO instr   {
		$$ = binNode
		(FOR, $2, binNode
			(IN, $4, binNode
				(tFORTO, $5, binNode
					(tSTEP, $6, uniNode
						(DO, $8)
					)
				)
			)
		);
	}
	| rval ';'                                   { $$ = $1; }
	| body                                       { $$ = $1; }
	| BREAK integer ';'                          { $$ = uniNode(BREAK, $2); }
	| CONTINUE integer ';'                       { $$ = uniNode(CONTINUE, $2); }
	| lval '#' rval ';'                          { $$ = binNode(tSTACK, $1, $3); }
	;

integer:                                         { $$ = nilNode(END); }
	| INTEGER                                    { $$ = intNode(INTEGER, $1); }
	;

lval: ident                                      { $$ = $1; }
	| lval '[' rval ']'                          { $$ = binNode(INDEX, $1, $3); }
	| '*' lval %prec '*'                         { $$ = uniNode(LOAD, $2); }
	;

rval: lval,                                      { $$ = uniNode(LOAD, $1); }
	| '(' rval ')'                               { $$ = $2; }
	| cte                                        {}
	| rval '(' args ')'                          { $$ = binNode(CALL, $1, $3); }
	| rval '(' ')'                               { $$ = uniNode(CALL, $1); }
		| '-' rval %prec UMINUS                  { $$ = uniNode(UMINUS, $2); }
		| '!' rval                               { $$ = uniNode(NOT, $2);  }
	| '&' lval %prec ADDR                        { $$ = uniNode(PTR, $2);  }
	| '~' rval                                   { $$ = uniNode(BNOT, $2); }
	| lval INC                                   { $$ = binNode(INC, $1, intNode(INTEGER, $1->info == 3 ? 4 : 1)); }
	| lval DEC                                   { $$ = binNode(DEC, $1, intNode(INTEGER, $1->info == 3 ? 4 : 1)); }
	| INC lval                                   { $$ = binNode(INC, intNode(INTEGER, $2->info == 3 ? 4 : 1), $2); }
	| DEC lval                                   { $$ = binNode(DEC, intNode(INTEGER, $2->info == 3 ? 4 : 1), $2); }
		| rval '*' rval	                         { $$ = binNode(tMUL, $1, $3);   }
		| rval '/' rval	                         { $$ = binNode(tDIV, $1, $3);   }
		| rval '%' rval	                         { $$ = binNode(tMOD, $1, $3);   }
		| rval '+' rval	                         { $$ = binNode(tADD, $1, $3);   }
		| rval '-' rval	                         { $$ = binNode(tSUB, $1, $3);   }
	| rval '<' rval	                             { $$ = binNode(LT, $1, $3);     }
	| rval '>' rval	                             { $$ = binNode(GT, $1, $3);     }
	| rval GE rval	                             { $$ = binNode(GE, $1, $3);     }
	| rval LE rval	                             { $$ = binNode(LE, $1, $3);     }
	| rval '=' rval	                             { $$ = binNode(EQ, $1, $3);     }
	| rval NE rval	                             { $$ = binNode(NE, $1, $3);     }
		| rval '&' rval	                         { $$ = binNode(BAND, $1, $3);   }
		| rval '|' rval	                         { $$ = binNode(BOR, $1, $3);    }
	| lval ASSIGN rval                           { $$ = binNode(ASSIGN, $1, $3); }
	;

args: rval                                       { $$ = binNode(tARGS, $1, nilNode(END));      }
	| args ',' rval                              { $$ = binNode(tARGS, $1, $3);  }
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

typedef enum { LEXER = 0, COMPILER, ASSEMBLY } Mode;
int (*fn[])() = { lexer, compiler };

int main(int argc, char *argv[]) {
	extern YYSTYPE yylval;
	int retval = 0;
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
	retval = fn[mode]();

	fclose(yyin);
	fclose(yyout);

	return retval;
}
