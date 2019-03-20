%option stack

%{

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

void yyerror(const char *s);

%}

%x COM STR

%%

[ \t\r\n]+        ;

"=<"              yy_push_state(COM);
<COM>.|\n         ;
<COM>"=<"         yy_push_state(COM);
<COM>"=>"         yy_pop_state();

"==".*\n          ;

void              ;
integer           ;
string            ;
public            ;
number            ;
const             ;
if                ;
then              ;
else              ;
while             ;
do                ;
for               return FOR;
in                ;
step              ;
upto              ;
downto            ;
break             ;
continue          ;

[a-zA-Z_\b][a-zA-Z_\b0-9]* yylval.str = strdup(yytext); return NAME;

[0-9]+            yylval.i = strtol(yytext, 0, 10); return INT;

\"[.*$]*[^\\]\"   yylval.str = malloc(yyleng); *yylval.str = 0; REJECT;
\"                yy_push_state(STR);
<STR>\"           yy_pop_state(); return STRING;
<STR>"\n"         strcat(yylval.str, "\n");
<STR>"\t"         strcat(yylval.str, "\t");
<STR>"\0"         yyerror("NULL character in string");
<STR>.|\n         strcat(yylval.str, yytext);

[0-9]+\.[0.9]     yylval.f = strtof(yytext, 0); return NUMBER;

.                 yyerror("Unknown character");

%%

/* Code */
int yywrap(void) {
	if (YYSTATE == COM) yyerror("unterminated comment");
	if (YYSTATE == STR) yyerror("unterminated string");
	return 1;
}
char *getyytext() { return yytext; }
