%{

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

void yyerror(const char *s);

int nested = 0;

%}

SPACE [ \t]

%x COM STR

%%

"=<"              BEGIN COM;
<COM>.|\n         ;
<COM>"=<"         nested++;
<COM>"=>"         if (nested == 0) { BEGIN 0; } else { nested--; }

[0-9]+            yylval.i = strtol(yytext, 0, 10); return INT;

\"                BEGIN STR;
<STR>\"           BEGIN 0; return STRING;
<STR>.|\n         strcat(yylval.str, yytext);
<STR>"*n"         strcat(yylval.str, "\n");
<STR>"*t"         strcat(yylval.str, "\t");
<STR>"*0"         strcat(yylval.str, "\0");

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
