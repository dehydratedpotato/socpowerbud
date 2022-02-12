
CC = clang
CFLAGS = -fobjc-arc -arch arm64 -arch x86_64 -lIOReport -framework Foundation

osx-cpufreq:
	$(CC) $(CFLAGS) osx-cpufreq.m arm64/arm64.m x86_64/x86_64.m -o $@
