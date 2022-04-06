
CC = clang
CFLAGS = -fobjc-arc -funroll-loops -arch arm64 -lIOReport -framework Foundation -framework IOKit -mmacosx-version-min=11.0

sfmrm-arm64-client:
	$(CC) $(CFLAGS) arm64.m -o $@
	
clean:
	rm -rf sfmrm-arm64-client
