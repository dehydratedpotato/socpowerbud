
CC = clang
CFLAGS = -fobjc-arc -funroll-loops -arch x86_64 -lIOReport -framework Foundation -framework IOKit -mmacosx-version-min=10.11

sfmrm-x86_64-client:
	$(CC) $(CFLAGS) x86_64.m -o $@
	
clean:
	rm -rf sfmrm-x86_64-client
