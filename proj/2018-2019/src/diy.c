#include <stdio.h>
#include <stdarg.h>

#include "node.h"
#include "diy.h"

extern int yylex(), yyparse(void);
extern void* yyin;
extern void* yyout;
extern char **yyname;
int tk;

char *infile = "<<stdin>>",
	*outfile = NULL;

int errors;

#ifndef YYERRCODE
#define YYERRCODE 256
#endif


/* Auxiliary */
int yyerror(char *s, ...)
{
	extern int yylineno;
	extern char *getyytext();
	va_list args;

	fprintf(stderr, "%s: ", infile);

	va_start(args, s);
	vfprintf(stderr, s, args);
	va_end(args);

	fprintf(stderr, " at or before '%s' in line %d\n", getyytext(), yylineno);
	errors++;

	return 1;
}


/* **************************** MAIN **************************** */
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
	int retval = 0;
	Mode mode = COMPILER;

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
