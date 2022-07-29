
CC=clang
CFLAGS=-fobjc-arc -funroll-loops -Ofast -arch arm64 -mmacosx-version-min=11.0
LIBS=-lIOReport -framework Foundation -framework IOKit

PROGS= mxsocpwrbud

all: $(PROGS)

mxsocpwrbud: *.m
	$(CC) $(CFLAGS) -o $@ $^ ${LIBS}
	
clean:
	rm -rf ${PROGS} *.o
