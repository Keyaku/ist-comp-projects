SRCDIR=src
EXEC=diy
LANG=$(SRCDIR)/diy
EXT=diy # file extension: .$(EXT)
LIB=lib # compiler library directory
UTIL=util # compiler library: lib$(LIB).a
RUN=run # runtime directory
EXS=exs # examples directory
CC=gcc
CFLAGS=-g -DYYDEBUG
LDFLAGS = -I$(LIB) -L$(LIB) -l$(UTIL)

CINFILES = $(LANG).c $(LANG).h
LEXFILES = $(SRCDIR)/lex.yy.c
YACCFILES= $(SRCDIR)/y.tab.c
BURGFILES= $(SRCDIR)/yyselect.c
COUTFILES = $(LEXFILES) $(YACCFILES) $(SRCDIR)/y.code.c $(BURGFILES)


# RULES
all: $(EXEC)

$(EXEC): $(CINFILES) $(LANG).l $(LANG).y $(LANG).brg
	make -C $(LIB)
	byacc -o $(YACCFILES) -dvr $(LANG).y
	flex -o $(LEXFILES) -l $(LANG).l
	pburg -T $(LANG).brg $(BURGFILES)
	$(LINK.c) -o $@ $(ARCH) $(COUTFILES) $(LANG).c


examples:: $(LANG)
	make -C $(EXS)

zip::
	zip -r proj.zip Makefile $(SRCDIR) $(LIB) $(EXS)

clean::
	make -C $(LIB) clean
	make -C $(RUN) clean
	make -C $(EXS) clean
	rm -rf *.o $(EXEC) *.dSYM $(COUTFILES) $(SRCDIR)/y.tab.h $(SRCDIR)/y.output *.asm *~
