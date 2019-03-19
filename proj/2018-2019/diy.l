%{

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

void yyerror(const char *s);

%}

SPACE [ \t]

%x COM STR

%%

<COM>.|\n         ;
<COM>"*/"         BEGIN 0;

"/*"              BEGIN COM;

[0-9]+            yylval.i = strtol(yytext, 0, 10); return INT;

\"                BEGIN STR;
<STR>"*n"         strcat(yylval.str, "\n");
<STR>"*t"         strcat(yylval.str, "\t");
<STR>"*0"         strcat(yylval.str, "\0");
<STR>"*("         strcat(yylval.str, "{");
<STR>"*)"         strcat(yylval.str, "}");
<STR>\*[*'"]      strcat(yylval.str, yytext+1);
<STR>\*.          yyerror("invalid escape sequence in string");
<STR>.|\n         strcat(yylval.str, yytext);
<STR>\"           BEGIN 0; return STRING;

[0-9]+\.[0.9]     yylval.f = strtof(yytext, 0); return FLOAT;

"for"             return FOR;

.                 yyerror("Unknown character");

%%

/* Code */
int yywrap(void) {
	if (YYSTATE == COM) yyerror("unterminated comment");
	if (YYSTATE == STR) yyerror("unterminated string");
	return 1;
}
char *getyytext() { return yytext; }
