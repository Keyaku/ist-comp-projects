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

LEXFILES = $(SRCDIR)/lex.yy.c
YACCFILES= $(SRCDIR)/y.tab.c
BURGFILES= $(SRCDIR)/yyselect.c
CFILES =  $(LEXFILES) $(YACCFILES) $(SRCDIR)/y.code.c #$(BURGFILES)


# RULES
all: $(EXEC)

$(EXEC): $(LANG).y $(LANG).l #$(LANG).brg
	make -C $(LIB)
	flex -o $(LEXFILES) -l $(LANG).l
	byacc -o $(YACCFILES) -dvr $(LANG).y
	#pburg -T $(LANG).brg
	$(LINK.c) -o $@ $(ARCH) $(LDFLAGS) $(CFILES) $(LANG).c


examples:: $(LANG)
	make -C $(EXS)

zip::
	zip -r proj.zip Makefile $(SRCDIR) $(EXS)

clean::
	make -C $(LIB) clean
	make -C $(RUN) clean
	make -C $(EXS) clean
	rm -rf *.o $(EXEC) *.dSYM $(CFILES) $(SRCDIR)/y.tab.h $(SRCDIR)/y.output *.asm *~
