#ifndef __DO_IT_YOURSELF_H__
#define __DO_IT_YOURSELF_H__


/* Types */
typedef unsigned char bool;
enum { false, true };

/* Functions */
#define arrlen(x)  (sizeof(x) / sizeof((x)[0]))

/* Yacc material */
int yyerror(char *s);
extern void* yyout;
int tk;

#endif
