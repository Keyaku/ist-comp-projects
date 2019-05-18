%{
#include <stdlib.h>

#include "diy.h"

#include "node.h"
#include "tabid.h"

void declare(int pub, int cnst, Node *type, char *name, Node *value);
void function(int pub, Node *type, char *name, Node *body);
void enter(int pub, int typ, char *name);
int checkargs(char *name, Node *args);
int nostring(Node *arg1, Node *arg2);
int intonly(Node *arg, int);
int noassign(Node *arg1, Node *arg2);
static int ncicl;
static char *fpar;

%}

%union {
	long i;    /* 4-byte integer value */
	double d;  /* number */
	char *s;   /* string */
	Node *n;   /* abstract Node type */
};

%token <i> INTEGER
%token <d> NUMBER
%token <s> IDENTIFIER STRING
%token DO WHILE IF THEN FOR IN UPTO DOWNTO STEP BREAK CONTINUE
%token TYPE_VOID TYPE_INT TYPE_STR TYPE_NUM CONST PUBLIC INC DEC
%nonassoc IFX
%nonassoc ELSE

%right ASSIGN
%left '|'
%left '&'
%nonassoc '~'
%left '=' NE
%left GE LE '>' '<'
%left '+' '-'
%left '*' '/' '%'
%nonassoc UMINUS '!' NOT REF
%nonassoc '[' '('


%type <n> type init finit blocop params
%type <n> bloco decls param base stmt step args list end brk lval expr
%type <i> ptr intp public

%token LOCAL POSINC POSDEC PTR CALL START PARAM NIL

%%

file:
	| file error ';'
	| file public type IDENTIFIER ';'          { IDnew($3->value.i, $4, 0);   declare($2, 0, $3, $4, 0); }
	| file public CONST type IDENTIFIER ';'    { IDnew($4->value.i+5, $5, 0); declare($2, 1, $4, $5, 0); }
	| file public type IDENTIFIER init         { IDnew($3->value.i, $4, 0);   declare($2, 0, $3, $4, $5); }
	| file public CONST type IDENTIFIER init   { IDnew($4->value.i+5, $5, 0); declare($2, 1, $4, $5, $6); }
	| file public type IDENTIFIER              { enter($2, $3->value.i, $4); } finit { function($2, $3, $4, $6); }
	| file public TYPE_VOID IDENTIFIER         { enter($2, 4, $4); } finit { function($2, intNode(TYPE_VOID, 4), $4, $6); }
	;

public:                          { $$ = nilNode(NIL); }
	| PUBLIC                     { $$ = 1; }
	;

ptr:                             { $$ = nilNode(NIL); }
	| '*'                        { $$ = 10; }
	;

type: TYPE_INT ptr               { $$ = intNode(TYPE_INT, 1+$2); }
	| TYPE_STR ptr               { $$ = intNode(TYPE_STR, 2+$2); }
	| TYPE_NUM ptr               { $$ = intNode(TYPE_NUM, 3+$2); }
	;

init: ASSIGN IDENTIFIER ';'      { $$ = strNode(IDENTIFIER, $2); $$->info = IDfind($2, 0) + 10; }
	| ASSIGN INTEGER ';'         { $$ = intNode(INTEGER, $2);    $$->info = nodeInt; }
	| ASSIGN '-' INTEGER ';'     { $$ = intNode(INTEGER, -$3);   $$->info = nodeInt; }
	| ASSIGN STRING ';'          { $$ = strNode(STRING, $2);     $$->info = nodeStr; }
	| ASSIGN CONST STRING ';'    { $$ = strNode(CONST, $3);      $$->info = nodeStr+5; }
	| ASSIGN NUMBER ';'          { $$ = realNode(NUMBER, $2);    $$->info = nodeReal; }
	| ASSIGN '-' NUMBER ';'      { $$ = realNode(NUMBER, -$3);   $$->info = nodeReal; }
    ;

finit: '(' params ')' blocop     { $$ = binNode('(', $4, $2); }
	| '(' ')' blocop             { $$ = binNode('(', $3, 0); }
	;

blocop: ';'                      { $$ = nilNode(NIL); }
	| bloco ';'                  { $$ = $1; }
	;

params: param
	| params ',' param           { $$ = binNode(',', $1, $3); }
	;

bloco: '{' { IDpush(); } decls list end '}'    { $$ = binNode('{', $5->attrib == NIL ? binNode(';', $4, $5) : $4, $3); IDpop(); }
	;

decls:                           { $$ = nilNode(NIL); }
	| decls param ';'            { $$ = binNode(';', $1, $2); }
	;

param: type IDENTIFIER           { $$ = binNode(PARAM, $1, strNode(IDENTIFIER, $2));
        IDnew($1->value.i, $2, 0);
		if (IDlevel() == 1) fpar[++fpar[0]] = $1->value.i;
	}
	;

stmt: base                       { $$ = $1; }
	| brk                        { $$ = $1; }
	;

base: ';'                        { $$ = nilNode(TYPE_VOID); }
	| DO { ncicl++; } stmt WHILE expr ';'  { $$ = binNode(WHILE, binNode(DO, nilNode(START), $3), $5); ncicl--; }
	| FOR lval IN expr UPTO expr step DO   { ncicl++; } stmt       { $$ = binNode(';', binNode(ASSIGN, $4, $2), binNode(FOR, binNode(IN, nilNode(START), binNode(LE, uniNode(PTR, $2), $6)), binNode(';', $10, binNode(ASSIGN, binNode('+', uniNode(PTR, $2), $7), $2)))); ncicl--; }
	| FOR lval IN expr DOWNTO expr step DO { ncicl++; } stmt       { $$ = binNode(';', binNode(ASSIGN, $4, $2), binNode(FOR, binNode(IN, nilNode(START), binNode(GE, uniNode(PTR, $2), $6)), binNode(';', $10, binNode(ASSIGN, binNode('-', uniNode(PTR, $2), $7), $2)))); ncicl--; }
	| IF expr THEN stmt %prec IFX          { $$ = binNode(IF, $2, $4); }
	| IF expr THEN stmt ELSE stmt          { $$ = binNode(ELSE, binNode(IF, $2, $4), $6); }
	| expr ';'                   { $$ = $1; }
	| bloco                      { $$ = $1; }
	| lval '#' expr ';'          { $$ = binNode('#', $3, $1); }
	| error ';'                  { $$ = nilNode(NIL); }
	;

end:                             { $$ = nilNode(NIL); }
	| brk;                       { $$ = $1; }

brk: BREAK intp ';'              { $$ = intNode(BREAK, $2);    if ($2 <= 0 || $2 > ncicl) yyerror("invalid break argument"); }
	| CONTINUE intp ';'          { $$ = intNode(CONTINUE, $2); if ($2 <= 0 || $2 > ncicl) yyerror("invalid continue argument"); }
	;

step:                            { $$ = intNode(INTEGER, 1); }
	| STEP expr                  { $$ = $2; }
	;

intp:                            { $$ = 1; }
	| INTEGER                    { $$ = $1->value.i; }
	;

list: base                       { $$ = $1; }
	| list base                  { $$ = binNode(';', $1, $2); }
	;

args: expr                       { $$ = binNode(',', nilNode(NIL), $1); }
	| args ',' expr              { $$ = binNode(',', $1, $3); }
	;

lval: IDENTIFIER                 { long pos; int typ = IDfind($1, &pos);
		if (pos == 0) $$ = strNode(IDENTIFIER, $1);
		else $$ = intNode(LOCAL, pos);
		$$->info = typ;
	}
	| IDENTIFIER '[' expr ']'    { Node *n;
		long pos; int siz, typ = IDfind($1, &pos);
		if (typ / 10 != 1 && typ % 5 != 2) yyerror("not a pointer");
		if (pos == 0) n = strNode(IDENTIFIER, $1);
		else n = intNode(LOCAL, pos);
		$$ = binNode('[', n, $3);
		if (typ >= 10) typ -= 10;
		else if (typ % 5 == 2) typ = nodeInt;
		if (typ >= 5) typ -= 5;
		$$->info = typ;
	}
	;

expr: lval                       { $$ = uniNode(PTR, $1);     $$->info = $1->info; }
	| '*' lval                   { $$ = uniNode(PTR, uniNode(PTR, $2)); if ($2->info % 5 == 2) $$->info = nodeInt; else if ($2->info / 10 == 1) $$->info = $2->info % 10; else yyerror("can dereference lvalue"); }
	| lval ASSIGN expr           { $$ = binNode(ASSIGN, $3, $1); if ($$->info % 10 > 5) yyerror("constant value to assignment"); if (noassign($1, $3)) yyerror("illegal assignment"); $$->info = $1->info; }
	| INTEGER                    { $$ = intNode(INTEGER, $1); $$->info = nodeInt; }
	| STRING                     { $$ = strNode(STRING, $1);  $$->info = nodeStr; }
	| NUMBER                     { $$ = realNode(NUMBER, $1); $$->info = nodeReal; }
	| '-' expr %prec UMINUS      { $$ = uniNode(UMINUS, $2);  $$->info = $2->info; nostring($2, $2); }
	| '~' expr %prec UMINUS      { $$ = uniNode(NOT, $2);     $$->info = intonly($2, 0); }
	| '&' lval %prec UMINUS      { $$ = uniNode(REF, $2);     $$->info = $2->info + 10; }
	| expr '!'                   { $$ = uniNode('!', $1);     $$->info = 3; intonly($1, 0); }
	| INC lval                   { $$ = uniNode(INC, $2);     $$->info = intonly($2, 1); }
	| DEC lval                   { $$ = uniNode(DEC, $2);     $$->info = intonly($2, 1); }
	| lval INC                   { $$ = uniNode(POSINC, $1);  $$->info = intonly($1, 1); }
	| lval DEC                   { $$ = uniNode(POSDEC, $1);  $$->info = intonly($1, 1); }
	| expr '+' expr              { $$ = binNode('+', $1, $3); $$->info = nostring($1, $3); }
	| expr '-' expr              { $$ = binNode('-', $1, $3); $$->info = nostring($1, $3); }
	| expr '*' expr              { $$ = binNode('*', $1, $3); $$->info = nostring($1, $3); }
	| expr '/' expr              { $$ = binNode('/', $1, $3); $$->info = nostring($1, $3); }
	| expr '%' expr              { $$ = binNode('%', $1, $3); $$->info = intonly($1, 0); intonly($3, 0); }
	| expr '<' expr              { $$ = binNode('<', $1, $3); $$->info = nodeInt; }
	| expr '>' expr              { $$ = binNode('>', $1, $3); $$->info = nodeInt; }
	| expr GE expr               { $$ = binNode(GE, $1, $3);  $$->info = nodeInt; }
	| expr LE expr               { $$ = binNode(LE, $1, $3);  $$->info = nodeInt; }
	| expr NE expr               { $$ = binNode(NE, $1, $3);  $$->info = nodeInt; }
	| expr '=' expr              { $$ = binNode('=', $1, $3); $$->info = nodeInt; }
	| expr '&' expr              { $$ = binNode('&', $1, $3); $$->info = intonly($1, 0); intonly($3, 0); }
	| expr '|' expr              { $$ = binNode('|', $1, $3); $$->info = intonly($1, 0); intonly($3, 0); }
	| '(' expr ')'               { $$ = $2; $$->info = $2->info; }
	| IDENTIFIER '(' args ')'    { $$ = binNode(CALL, strNode(IDENTIFIER, $1), $3);
		$$->info = checkargs($1, $3); }
	| IDENTIFIER '(' ')'         { $$ = binNode(CALL, strNode(IDENTIFIER, $1), nilNode(TYPE_VOID));
		$$->info = checkargs($1, 0); }
	;

%%

/* ********************* Semantic analysis functions ********************* */
void declare(int pub, int cnst, Node *type, char *name, Node *value)
{
	int typ;
	if (!value) {
		if (!pub && cnst) yyerror("local constants must be initialised");
		return;
	}
	/* if (value->attrib = INTEGER && value->value.i == 0 && type->value.i > 10) */
	if (value->attrib == INTEGER && value->value.i == 0 && type->value.i > 10) { return; /* NULL pointer */ }
	if ((typ = value->info) % 10 > 5) { typ -= 5; }
	if (type->value.i != typ) {
		yyerror("wrong types in initialization");
	}
}

void enter(int pub, int typ, char *name) {
	fpar = malloc(32); /* 31 arguments, at most */
	fpar[0] = 0; /* argument count */
	if (IDfind(name, (long*)IDtest) < 20) {
		IDnew(typ+20, name, (long)fpar);
	}
	IDpush();
	if (typ != 4) { IDnew(typ, name, 0); }
}

int checkargs(char *name, Node *args) {
	char *arg;
	int typ;
    if ((typ = IDsearch(name, (long*)&arg,IDlevel(),1)) < 20) {
		yyerror("ident not a function");
		return 0;
	}
	if (args == 0 && arg[0] == 0) {
		;
	} else if (args == 0 && arg[0] != 0) {
		yyerror("function requires no arguments");
	} else if (args != 0 && arg[0] == 0) {
		yyerror("function requires arguments");
	} else {
		int err = 0, null, i = arg[0], typ;
		do {
			Node *n;
			if (i == 0) {
				yyerror("too many arguments.");
				err = 1;
				break;
			}
			n = RIGHT_CHILD(args);
			typ = n->info;
			if (typ % 10 > 5) { typ -= 5; /* remove CONST */ }
			null =  (n->attrib == INTEGER && n->value.i == 0 && arg[i] > 10) ? 1 : 0;
			if (!null && arg[i] != typ) {
				yyerror("wrong argument type");
				err = 1;
				break;
			}
			args = LEFT_CHILD(args);
			i--;
		} while (args->attrib != NIL);

		if (!err && i > 0) {
			yyerror("missing arguments");
		}
	}

	return typ % 20;
}

int nostring(Node *arg1, Node *arg2) {
	if (arg1->info % 5 == 2 || arg2->info % 5 == 2) {
		yyerror("cannot use strings");
	}
	return arg1->info % 5 == 3 || arg2->info % 5 == 3 ? 3 : 1;
}

int intonly(Node *arg, int novar) {
	if (arg->info % 5 != 1) {
		yyerror("only integers can be used");
	}
	if (arg->info % 10 > 5 && novar) {
		yyerror("argument is constant");
	}
	return 1;
}

int noassign(Node *arg1, Node *arg2) {
	int t1 = arg1->info, t2 = arg2->info;
	if (t1 == t2) { return 0; }
	if (t1 == 3 && t2 == 1) { return 0; /* real := int */ }
	if (t1 == 1 && t2 == 3) { return 0; /* int := real */ }
	if (t1 == 2 && t2 == 11) { return 0; /* string := int* */ }
	if (t1 == 2 && arg2->attrib == INTEGER && arg2->value.i == 0){
		return 0; /* string := 0 */
	}
	if (t1 > 10 && t1 < 20 && arg2->attrib == INTEGER && arg2->value.i == 0) {
		return 0; /* pointer := 0 */
	}
	return 1;
}

void function(int pub, Node *type, char *name, Node *body)
{
	Node *bloco = LEFT_CHILD(body);
	IDpop();
	if (bloco != 0) { /* not a forward declaration */
		long par;
		int fwd = IDfind(name, &par);
		if (fwd > 40) { yyerror("duplicate function"); }
		else { IDreplace(fwd+40, name, par); }
	}
}

