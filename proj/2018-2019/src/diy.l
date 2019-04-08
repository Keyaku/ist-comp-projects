%option stack

%{

#include <stdlib.h>
#include <string.h>
#include <errno.h>
#include "node.h"
#include "y.tab.h"

#define bool unsigned char
#define true  1
#define false 0

#define arrlen(x)  (sizeof(x) / sizeof((x)[0]))

extern int tk;

int yyerror(const char *s);
bool can_delimit(char *s);

int octal(char *s);

%}

%x COM CHR

HEX [0-9a-fA-F]
ID [a-zA-Z][a-zA-Z0-9_]

%%

[ \t\r]+          ;

[\n]+             if (can_delimit(yytext)) { return ';'; }

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

{ID}*             yylval.s = strdup(yytext); return IDENTIFIER;

0                 yylval.i = 0; return INTEGER;
[1-9]\d*          { errno = 0; yylval.i = strtol(yytext, NULL, 10);
					if (errno == ERANGE) yyerror("decimal overflow");
					return INTEGER; }
0b[0-1]*          { errno = 0; yylval.i = strtol(yytext, NULL, 2);
					if (errno == ERANGE) yyerror("binary overflow");
					return INTEGER; }
0\d*              yylval.i = octal(yytext); return INTEGER;
\d+\.\d+          { errno = 0; yylval.d = strtod(yytext, NULL);
					if (errno == ERANGE) yyerror("floating-point overflow");
					return INTEGER; }

\"([^"\\]|\\(.|\n))*\" yylval.s = malloc(yyleng); *yylval.s = 0; REJECT;

\"                yy_push_state(CHR);
<CHR>\"           yy_pop_state(); return STRING;
<CHR>"\""         strcat(yylval.s, "\"");
<CHR>"\n"         strcat(yylval.s, "\n");
<CHR>"\r"         strcat(yylval.s, "\r");
<CHR>"\t"         strcat(yylval.s, "\t");
<CHR>"\0"         yyerror("NULL character in string");
<CHR>"\."         yyerror("invalid escape sequence in string");
<CHR>[^"]         strcat(yylval.s, yytext);
<CHR>.            ;
<CHR>\\{HEX}{HEX}? { char c = (char) strtol(yytext+1, NULL, 16);
					strncat(yylval.s, &c, 1); }

.                 yyerror("Unknown character");

%%

/* Code */
int yywrap(void) {
	if (YYSTATE == COM) yyerror("unterminated comment");
	if (YYSTATE == CHR) yyerror("unterminated string");
	return 1;
}
char *getyytext() { return yytext; }

bool can_delimit(char *s)
{
	int i, delimiter[] = {
		STRING,     // Literals
		INTEGER,
		NUMBER,
		IDENTIFIER, // Identifiers
		')',        // Special characters
		'!',
	};

	for (i = 0; i < arrlen(delimiter); i++) {
		if (tk == delimiter[i]) {
			return true;
		}
	}
	return false;
}

int octal(char *s)
{
	int idx, a = 0, b = 0, c = 0, len = strlen(s);

	for (idx = 0; idx < len; idx++) {
		if (s[idx] < '0' || s[idx] > '9') { break; }
		c = s[idx] - '0';
		if (c > 7) {
			c -= 8;
			b = (b+1) * 8 + c;
		} else {
			b = b * 8 + c;
		}

		if (b < a) {
			yyerror("octal overflow");
			break;
		}
		a = b;
	}

	return a;
}
