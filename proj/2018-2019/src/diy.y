%{
#include <string.h>

#include "diy.h"

#include "node.h"
#include "tabid.h"

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
%token MUL DIV MOD ADD SUBT

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

%token FILE_TOKEN DECLARATION DEFINITION INSTRUCTION BODY PARAM PARAMS
%token BODY_PARAM INSTR_PARAM
%token CTE FOR_BLOCK FORSTEP FORTO UPTO DOWNTO ARG ARGS STACK

%token ATTRIBUTES MODIFIERS REFERENCE TYPE INDEX LOAD CALL STOP
%token PROCEDURE PARAMETERS INITIALIZATION

%type<n> PUBLIC CONST TYPE ASSIGN

%type<n> decl def
%type<n> atr mod ref publ cons type star ident init
%type<n> cte integer instr lval rval args
%type<n> param params body for forto do step
%type<n> initparams initbody bparam iparam


%%

file: decl;                                      { printNode(uniNode(FILE_TOKEN, $1), yyout, (char**)yyname); }
decl:                                            { $$ = nilNode(STOP); }
	| decl def                                   { $$ = binNode(DECLARATION, $1, $2); }
	;

atr: mod ref                                     { $$ = binNode(ATTRIBUTES, $1, $2); }
	;

mod: publ cons                                   { $$ = binNode(MODIFIERS, $1, $2); }
	;

publ:                                            { $$ = nilNode(STOP); }
	| PUBLIC                                     { $$ = nilNode(PUBLIC); }
	;

cons:                                            { $$ = nilNode(STOP); }
	| CONST                                      { $$ = nilNode(CONST); }
	;

ref: type star                                   { $$ = binNode(REFERENCE, $1, $2);  }
	;

star:                                            { $$ = nilNode(STOP); }
	| '*'                                        { $$ = nilNode(PTR); }
	;

type: TYPE_VOID                                  { $$ = nilNode(TYPE_VOID); }
	| TYPE_INT                                   { $$ = nilNode(TYPE_INT); }
	| TYPE_NUM                                   { $$ = nilNode(TYPE_NUM); }
	| TYPE_STR                                   { $$ = nilNode(TYPE_STR); }
	;

def: atr ident init ';'                          {
		$$ = binNode(DEFINITION, $1, binNode(PROCEDURE, $2, $3));
		IDnew($2->info, $2->value.s, 0);
	}
	;

ident: IDENTIFIER                                { $$ = strNode(IDENTIFIER, $1); }
	;

init: ASSIGN cte                                 { $$ = uniNode(ASSIGN, $2); }
	| ASSIGN ident                               { $$ = uniNode(ASSIGN, $2); }
	|'(' { IDpush(); } initparams { IDpop(); } ')' initbody  { $$ = binNode(INITIALIZATION, $3, $6); }
	;

cte: INTEGER                                     { $$ = intNode(INTEGER, $1); }
	| cons STRING                                { $$ = binNode(STRING, $1, strNode(STRING, $2)); }
	| NUMBER                                     { $$ = realNode(NUMBER, $1); }
	;

param: ref ident                                 {
		$$ = binNode(PARAM, $1, $2);

	}
	;

params: param                                    { $$ = $1; }
	| params ',' param                           { $$ = binNode(PARAMETERS, $1, $3); }
	;

initparams:                                      { $$ = nilNode(STOP); }
	| params                                     { $$ = $1; }
	;

initbody:                                        { $$ = nilNode(STOP); }
	| body                                       { $$ = $1; }
	;

bparam:                                          { $$ = nilNode(STOP); }
	| bparam param ';'                           { $$ = binNode(DEFINITION, $1, $2); }
	;

iparam:                                          { $$ = nilNode(STOP); }
	| iparam instr                               { $$ = binNode(INSTRUCTION, $1, $2); }
	;

body: '{' { IDpush(); } bparam iparam { IDpop(); } '}'   { $$ = binNode(BODY, $3, $4); }
	;

for: FOR lval IN rval                            { $$ = binNode(FOR, $2, uniNode(IN, $4)); }
	;

forto: UPTO  rval                                { $$ = uniNode(UPTO,   $2); }
	| DOWNTO rval                                { $$ = uniNode(DOWNTO, $2); }
	;

do: DO instr                                     { $$ = uniNode(DO, $2); }
	;

step:                                            { $$ = nilNode(STOP); }
	| STEP rval                                  { $$ = uniNode(STEP, $2); }
	;

instr: IF rval THEN instr %prec IFX              { $$ = binNode(IF, $2, uniNode(THEN, $4)); }
	| IF rval THEN instr ELSE instr              { $$ = binNode(IF, $2, binNode(THEN, $4, uniNode(ELSE, $6))); }
	| do WHILE rval ';'                          { $$ = binNode(WHILE, $1, $3); }
	| for forto step do                          {
		$$ = binNode(FOR_BLOCK, $1, binNode(FORTO, $2, binNode(FORSTEP, $3, $4)));
	}
	| rval ';'                                   { $$ = $1; }
	| body                                       { $$ = $1; }
	| BREAK integer ';'                          { $$ = uniNode(BREAK, $2); }
	| CONTINUE integer ';'                       { $$ = uniNode(CONTINUE, $2); }
	| lval '#' rval ';'                          { $$ = binNode(STACK, $1, $3); }
	;

integer:                                         { $$ = nilNode(STOP); }
	| INTEGER                                    { $$ = intNode(INTEGER, $1); }
	;

lval: ident                                      { $$ = $1; }
	| lval '[' rval ']'                          { $$ = binNode(INDEX, $1, $3); }
	| '*' lval %prec '*'                         { $$ = uniNode(LOAD, $2); }
	;

rval: lval,                                      { $$ = uniNode(LOAD, $1); }
	| '(' rval ')'                               { $$ = $2; }
	| cte                                        { $$ = $1; }
	| rval '(' args ')'                          { $$ = binNode(CALL, $1, $3); }
	| rval '(' ')'                               { $$ = binNode(CALL, $1, nilNode(STOP)); }
		| '-' rval %prec UMINUS                  { $$ = uniNode(UMINUS, $2); }
		| '!' rval                               { $$ = uniNode(NOT, $2);   }
	| '&' lval %prec ADDR                        { $$ = uniNode(ADDR, $2);  }
	| '~' rval                                   { $$ = uniNode(BNOT, $2);  }
	| lval INC                                   { $$ = binNode(INC, $1, intNode(INTEGER, $1->info == 3 ? 4 : 1)); }
	| lval DEC                                   { $$ = binNode(DEC, $1, intNode(INTEGER, $1->info == 3 ? 4 : 1)); }
	| INC lval                                   { $$ = binNode(INC, intNode(INTEGER, $2->info == 3 ? 4 : 1), $2); }
	| DEC lval                                   { $$ = binNode(DEC, intNode(INTEGER, $2->info == 3 ? 4 : 1), $2); }
		| rval '*' rval	                         { if (!is_int_or_num($1) || !is_int_or_num($3)) { return 1; } $$ = binNode(MUL, $1, $3); }
		| rval '/' rval	                         { if (!is_int_or_num($1) || !is_int_or_num($3)) { return 1; } $$ = binNode(DIV, $1, $3); }
		| rval '%' rval	                         { if (!is_int_or_num($1) || !is_int_or_num($3)) { return 1; } $$ = binNode(MOD, $1, $3); }
		| rval '+' rval	                         { if (!is_int_or_num($1) || !is_int_or_num($3)) { return 1; } $$ = binNode(ADD, $1, $3); }
		| rval '-' rval	                         { if (!is_int_or_num($1) || !is_int_or_num($3)) { return 1; } $$ = binNode(SUBT, $1, $3); }
	| rval '<' rval	                             { if (!can_cmp_val($1, $3)) { return 1; } $$ = binNode(LT, $1, $3); $$->info = TYPE_INT; }
	| rval '>' rval	                             { if (!can_cmp_val($1, $3)) { return 1; } $$ = binNode(GT, $1, $3); $$->info = TYPE_INT; }
	| rval LE rval	                             { if (!can_cmp_val($1, $3)) { return 1; } $$ = binNode(LE, $1, $3); $$->info = TYPE_INT; }
	| rval GE rval	                             { if (!can_cmp_val($1, $3)) { return 1; } $$ = binNode(GE, $1, $3); $$->info = TYPE_INT; }
	| rval NE rval	                             { if (!can_cmp_val($1, $3)) { return 1; } $$ = binNode(NE, $1, $3); $$->info = TYPE_INT; }
	| rval '=' rval	                             { if (!can_cmp_val($1, $3)) { return 1; } $$ = binNode(EQ, $1, $3); $$->info = TYPE_INT; }
		| rval '&' rval	                         { if (!is_int($1) || !is_int($3)) { return 1; } $$ = binNode(BAND, $1, $3); }
		| rval '|' rval	                         { if (!is_int($1) || !is_int($3)) { return 1; } $$ = binNode(BOR, $1, $3); }
	| lval ASSIGN rval                           { $$ = binNode(ASSIGN, $1, $3); }
	;

args: rval                                       { $$ = binNode(ARG, $1, nilNode(STOP)); }
	| args ',' rval                              { $$ = binNode(ARG, $1, $3);  }
	;

%%

/* ********************* Semantic analysis functions ********************* */
/* is_ checking functions */
bool is_any(const Node *n, NodeType *types, const char **types_str, int size)
{
	int i;
	char msg[256] = "Value is not of type";

	for (i = 0; i < size; i++) {
		if (n->type == types[i]) { return true; }
		strcat(msg, " "); strcat(msg, types_str[i]); strcat(msg, ",");
	}

	yyerror(msg);
	return false;
}

bool is_int(const Node *n)
{
	static NodeType types[] = { nodeInt };
	static const char *types_str[] = { "integer" };
	return is_any(n, types, types_str, arrlen(types));
}

bool is_num(const Node *n)
{
	static NodeType types[] = { nodeReal };
	static const char *types_str[] = { "number" };
	return is_any(n, types, types_str, arrlen(types));
}

bool is_str(const Node *n)
{
	static NodeType types[] = { nodeStr };
	static const char *types_str[] = { "string" };
	return is_any(n, types, types_str, arrlen(types));
}

bool is_int_or_num(const Node *n)
{
	static NodeType types[] = { nodeInt, nodeReal };
	static const char *types_str[] = { "integer", "number" };
	return is_any(n, types, types_str, arrlen(types));
}

bool is_val(const Node *n)
{
	static NodeType types[] = { nodeInt, nodeReal, nodeStr };
	static const char *types_str[] = { "integer", "number", "string" };
	return is_any(n, types, types_str, arrlen(types));
}

/* Comparator functions */
#define node_value(n) \
	n->type == nodeInt ? n->value.i : n->type == nodeReal ? n->value.d : n->type == nodeStr ? n->value.s : 0

bool can_cmp_val(const Node *n1, const Node *n2) {
	NodeType num_types[] = { nodeInt, nodeReal };

	/* Checking if they're numbers */
	if ((n1->type == num_types[0] && n2->type == num_types[1])
	|| (n1->type == num_types[1] && n2->type == num_types[0])) {
		return true;
	}
	/* Checking if they're of equal types */
	if (n1->type == n2->type) {
		return true;
	}

	yyerror("Nodes are not of proper type");
	return false;
}

