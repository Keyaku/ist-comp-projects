#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>
#include <unistd.h>

#include "node.h"
#include "diy.h"

extern void* yyin;
extern void* yyout;
extern int IDdebug;

char *infile = "<<stdin>>",
	outfile[64] = "out.asm",
	*ext = ".asm";

int errors, trace;


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
	extern int yylex();
	extern char **yyname;
	int tk;
	/* Outputting lexer content */
	while ((tk = yylex())) {
		if (tk > 256) {
			printf("%d:\t%s\n", tk, yyname[tk]);
		} else {
			printf("%d:\t%c\n", tk, tk);
		}
	}

	return 0;
}

int compiler() {
	extern int yyparse(void);
	if (yyparse() != 0 || errors > 0) {
		fprintf(stderr, "%d errors in %s\n", errors, infile);
		fclose(yyout); yyout = NULL;
		unlink(outfile);
		return 1;
	}
	return 0;
}

typedef enum { LEXER = 0, COMPILER } Mode;
int (*fn[])() = { lexer, compiler };

int main(int argc, char *argv[]) {
#ifdef YYDEBUG
	extern int yydebug;
	yydebug = getenv("YYDEBUG") ? 1 : 0;
#endif
	int retval = 0;
	Mode mode = COMPILER;

	/* Checking for trace flag */
	if (argc > 1 && strcmp(argv[1], "-trace") == 0) { IDdebug = trace = 1; argc--; argv++; }

	/* Opening file from input or from given argument */
	if (argc > 1) {
		if ((yyin = fopen(infile = argv[1], "r")) == NULL) {
			perror(argv[1]);
			return 1;
		}
		argc--; argv++;
	}

	/* Preparing output file */
	if (argc == 1) {
		char *ptr;
		outfile[0] = 0;
		strcpy(outfile, argv[0]);
		if ((ptr = strrchr(outfile, '.')) == 0) {
			ptr = outfile + strlen(outfile);
		}
		strcpy(ptr, ext);
	}
	else if (argc > 1) { strcpy(outfile, argv[1]); }

	if ((yyout = fopen(outfile, "w")) == NULL) {
		perror(outfile);
		return 1;
	}

	/* Executing the appropriate code for this part */
	retval = fn[mode]();

	fclose(yyin);
	fclose(yyout);

	return retval;
}
