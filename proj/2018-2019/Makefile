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
LDFLAGS = -I$(LIB) -I$(SRCDIR) -L$(LIB) -l$(UTIL)

CFILES = lex.yy.c y.tab.c #yyselect.c


# RULES
all: $(EXEC)

$(EXEC): $(LANG).y $(LANG).l #$(LANG).brg
	make -C $(LIB)
	flex -l $(LANG).l
	byacc -dv $(LANG).y
	#pburg -T $(LANG).brg
	$(LINK.c) -o $@ $(ARCH) $(LDFLAGS) $(CFILES)


examples:: $(LANG)
	make -C $(EXS)

zip::
	zip -r proj.zip Makefile $(LANG).l $(LANG).y $(EXS)

clean::
	make -C $(LIB) clean
	make -C $(RUN) clean
	make -C $(EXS) clean
	rm -rf *.o $(EXEC) *.dSYM lex.yy.c y.tab.c y.tab.h y.output yyselect.c *.asm *~
