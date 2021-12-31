
// building:    clang main.m -fobjc-arc -arch arm64 -arch x86_64 -o osx-cpufreq

#include <Foundation/Foundation.h>
#include <mach/mach_time.h>

double getCurrentFrequency(void);

#if defined(__x86_64__)

uint64_t rdtsc(void)
{
    uint32_t a, d;
    asm volatile("rdtsc" : "=a"(a), "=d"(d));

    return ((uint64_t)d << 32) | a;
}

double getCurrentFrequency(void)
{
    uint64_t startCount = rdtsc();
    sleep(1);
    uint64_t endCount = rdtsc();

    uint64_t frequency = (endCount - startCount);

    return frequency;
}

#elif defined(__aarch64__)

double getCurrentFrequency(void)
{
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    const size_t testDurationFromCycles = 65536;
    __auto_type firstSampleBegin = mach_absolute_time();
    size_t cycles = 2 * testDurationFromCycles;
    
    asm volatile(".align 4\n Lcyclemeasure1:\nsubs %[counter],%[counter],#1\nbne Lcyclemeasure1\n " : [counter] "+r"(cycles));
    
    __auto_type firstSampleEnd = mach_absolute_time();
    double firstNanosecondSet = (double) (firstSampleEnd - firstSampleBegin) * (double)info.numer / (double)info.denom;
    __auto_type lastSampleBegin = mach_absolute_time();
    
    cycles = testDurationFromCycles;
    
    asm volatile(".align 4\n Lcyclemeasure2:\nsubs %[counter],%[counter],#1\nbne Lcyclemeasure2\n " : [counter] "+r"(cycles));
    
    __auto_type lastSampleEnd = mach_absolute_time();
    double lastNanosecondSet = (double) (lastSampleEnd - lastSampleBegin) * (double)info.numer / (double)info.denom;
    double nanoseconds = (firstNanosecondSet - lastNanosecondSet);
    
    if ((fabs(nanoseconds - firstNanosecondSet / 2) > 0.05 * nanoseconds) || (fabs(nanoseconds - lastNanosecondSet) > 0.05 * nanoseconds)) { return 0; }

    double frequency = (double)(testDurationFromCycles) / nanoseconds;
    
    return frequency;
}

#endif

int main(int argc, char * argv[])
{
    int arg;
    int argOpt = 0;
    int qosOpt = 0;
    double freqFormat = 1;
    
    NSString *freqMeasurement = @"Hz";
    
    NSOperationQueue *queue = [[NSOperationQueue alloc] init];
    
    while((arg = getopt(argc, argv, "kmgevh")) != -1)
    {
        switch(arg)
        {
            case 'k':   argOpt = 1; break;
            case 'm':   argOpt = 2; break;
            case 'g':   argOpt = 3; break;
            case 'e':   qosOpt = 1; break;
            case 'v':   argOpt = 4; break;
            case 'h':   printf("Usage: %s [-kmgevh]\n", argv[0]);
                        printf("    -k         : print output in kilohertz (kHz)\n");
                        printf("    -m         : print output in megahertz (mHz)\n");
                        printf("    -g         : print output in gigahertz (gHz)\n");
                        printf("    -e         : get frequency of efficiency cores (arm64 only)\n");
                        printf("    -v         : print version number\n");
                        printf("    -h         : help\n");
                        return 0;
                        break;
        }
    }

    switch(argOpt)
    {
        #if defined(__x86_64__)
            
        case 0: freqFormat = 1; break;
        case 1: freqFormat = .001; break;
        case 2: freqFormat = .000001; break;
        case 3: freqFormat = .000000001; break;
            
        #elif defined(__aarch64__)
            
        case 0: freqFormat = 1000000000; break;
        case 1: freqFormat = 1000000; break;
        case 2: freqFormat = 1000; break;
        case 3: freqFormat = 1; break;
            
        #endif
            
        case 4: printf("osx-cpufreq: version 1.2.0\n"); return 0; break;
    }
    
    switch(argOpt)
    {
        case 0: freqMeasurement = @"Hz"; break;
        case 1: freqMeasurement = @"kHz"; break;
        case 2: freqMeasurement = @"mHz"; break;
        case 3: freqMeasurement = @"gHz"; break;
    }
    
    if (qosOpt == 1)
    {
        #if defined(__x86_64__)
            
        printf("System architecture is x86_64: efficiency cores unavailable\n");
        return 0;
            
        #elif defined(__aarch64__)
            
        [queue setQualityOfService:NSQualityOfServiceBackground];
            
        #endif
    }
    
    NSOperation *operation = [NSBlockOperation blockOperationWithBlock: ^{
                                switch(argOpt)
                                {
                                    case 3: printf("%.4f %s\n", getCurrentFrequency()*freqFormat, [freqMeasurement UTF8String]); break;
                                    default: printf("%.0f %s\n", getCurrentFrequency()*freqFormat, [freqMeasurement UTF8String]); break;
                                }
                              }];
    
    [queue addOperation:operation];
    [queue waitUntilAllOperationsAreFinished];
    
    return 0;
}
