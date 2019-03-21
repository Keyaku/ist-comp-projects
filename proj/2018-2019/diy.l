%option stack

%{

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

int yyerror(const char *s);
int octal(char *s);

%}

%x COM STR

HEX [0-9a-fA-F]

%%

[ \t\r\n]+        ;

"=<"              yy_push_state(COM);
<COM>.|\n         ;
<COM>"=<"         yy_push_state(COM);
<COM>"=>"         yy_pop_state();

"==".*\n          ;

void              return TYPE_VOID;
integer           return TYPE_INT;
string            return TYPE_STR;
number            return TYPE_NUM;
public            return PUBLIC;
const             return CONST;
if                return IF;
then              return THEN;
else              return ELSE;
while             return WHILE;
do                return DO;
for               return FOR;
in                return IN;
step              return STEP;
upto              return UPTO;
downto            return DOWNTO;
break             return BREAK;
continue          return CONTINUE;

"<="              return LE;
">="              return GE;
"="               return EQ;
"<>"              return NE;
"++"              return INC;
"--"              return DEC;
":="              return ASSIGN;
[-+*/%<>!|&~]     return *yytext;
[#{}()\[\];,]     return *yytext;

[a-zA-Z_\b]\w* yylval.str = strdup(yytext); return IDENTIFIER;

0                 yylval.i = 0; return INT;
[1-9]\d*          { errno = 0; yylval.i = strtol(yytext, NULL, 10);
					if (errno == ERANGE) yyerror("decimal overflow");
					return INT; }
0b[0-1]*          { errno = 0; yylval.i = strtol(yytext, NULL, 2);
					if (errno == ERANGE) yyerror("binary overflow");
					return INT; }
0\d*              yylval.i = octal(yytext); return INT;
\d+\.\d+          { errno = 0; yylval.d = strtod(yytext, NULL);
					if (errno == ERANGE) yyerror("floating-point overflow");
					return INT; }

\"[.*$]*[^\\]\"   yylval.str = malloc(yyleng); *yylval.str = 0; REJECT;
\"                yy_push_state(STR);
<STR>\"           yy_pop_state(); return STRING;
<STR>"\n"         strcat(yylval.str, "\n");
<STR>"\r"         strcat(yylval.str, "\r");
<STR>"\t"         strcat(yylval.str, "\t");
<STR>"\0"         yyerror("NULL character in string");
<STR>.|\n         strcat(yylval.str, yytext);
<STR>\\{HEX}?{HEX} { char c = (char) strtol(yytext+1, NULL, 16);
					strncat(yylval.str, &c, 1); }

.                 yyerror("Unknown character");

%%

/* Code */
int yywrap(void) {
	if (YYSTATE == COM) yyerror("unterminated comment");
	if (YYSTATE == STR) yyerror("unterminated string");
	return 1;
}
char *getyytext() { return yytext; }

int octal(char *s)
{
	int idx, a = 0, b = 0, c = 0, len = strlen(s);

	for (idx = 0; idx < len; idx++) {
		if (s[idx] < '0' || s[idx] > '9') { break; }
		if (s[idx] == '9') { c = 11; }
		else { c = s[idx] - '0'; }
		b = b * 8 + c;
		if (b < a) {
			yyerror("octal overflow");
			break;
		}
		a = b;
	}

	return a;
}
