CC=clang
CFLAGS=-fobjc-arc -funroll-loops -Ofast -arch arm64 -mmacosx-version-min=11.0
LIBS=-lIOReport -framework Foundation -framework IOKit

mxsocpwrbud:
	$(CC) $(CFLAGS) $(LIBS) *.m -o mxsocpwrbud
	
clean:
	rm -rf mxsocpwrbud
