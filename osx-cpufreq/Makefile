
CC = clang
CFLAGS = -fobjc-arc -arch arm64 -arch x86_64 -lIOReport -framework Foundation  -mmacosx-version-min=10.11

osx-cpufreq:
	$(CC) $(CFLAGS) osx-cpufreq.m universal/universal.m arm64/arm64.m x86_64/x86_64.m x86_64/model_data/model_data.m -o $@
