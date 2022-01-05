// building:    clang main.m -fobjc-arc -arch arm64 -arch x86_64 -o osx-cpufreq

#include <Foundation/Foundation.h>
#include <mach/mach_time.h>

#if defined(__x86_64__)

#define FIRST_CYCLE_MEASURE { asm volatile("firstmeasure:\ndec %[counter]\njnz firstmeasure\n " : [counter] "+r"(cycles)); } // decrements 'counter' (131072) and loops until zero
#define LAST_CYCLE_MEASURE { asm volatile("lastmeasure:\ndec %[counter]\njnz lastmeasure\n " : [counter] "+r"(cycles)); }

#elif defined(__aarch64__)

#define FIRST_CYCLE_MEASURE { asm volatile(".align 4\n firstmeasure:\nsubs %[counter],%[counter],#1\nbne firstmeasure\n " : [counter] "+r"(cycles)); }
#define LAST_CYCLE_MEASURE { asm volatile(".align 4\n lastmeasure:\nsubs %[counter],%[counter],#1\nbne lastmeasure\n " : [counter] "+r"(cycles)); }

#endif

double getCurrentFrequency(void)
{
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    size_t cycles;
    
    uint64_t firstSampleBegin = mach_absolute_time();
    
    cycles = 131072;
    FIRST_CYCLE_MEASURE
    
    uint64_t firstSampleEnd = mach_absolute_time();
    double firstNanosecondSet = (double) (firstSampleEnd - firstSampleBegin) * (double)info.numer / (double)info.denom;
    uint64_t lastSampleBegin = mach_absolute_time();
    
    cycles = 65536;
    LAST_CYCLE_MEASURE
    
    uint64_t lastSampleEnd = mach_absolute_time();
    double lastNanosecondSet = (double) (lastSampleEnd - lastSampleBegin) * (double)info.numer / (double)info.denom;
    double nanoseconds = (firstNanosecondSet - lastNanosecondSet);
    
    if ((fabs(nanoseconds - firstNanosecondSet / 2) > 0.05 * nanoseconds) || (fabs(nanoseconds - lastNanosecondSet) > 0.05 * nanoseconds)) { return 0; }

    double frequency = (double)(65536 / nanoseconds);
    return frequency;
}

int main(int argc, char * argv[])
{
    int option;
    int optionID = 0;
    int qosID = 0;
    
    double frequencyFormat = 1;

    NSString *frequencyMeasurement = @"Hz";
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    while((option = getopt(argc, argv, "kmgevh")) != -1)
    {
        switch(option)
        {
            case 'e':   qosID = 1; break;
            case 'k':   optionID = 1; break;
            case 'm':   optionID = 2; break;
            case 'g':   optionID = 3; break;
            case 'v':   optionID = 4; break;
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

    switch(optionID)
    {
        case 0: frequencyFormat = 1000000000; frequencyMeasurement = @"Hz"; break;
        case 1: frequencyFormat = 1000000; frequencyMeasurement = @"kHz"; break;
        case 2: frequencyFormat = 1000; frequencyMeasurement = @"mHz"; break;
        case 3: frequencyFormat = 1; frequencyMeasurement = @"gHz"; break;
        case 4: printf("%s: version 1.3.0\n", argv[0]); return 0; break;
    }
    
    if (qosID == 1)
    {
        #if defined(__x86_64__)

        printf("%s: efficiency cores unavailable on x86\n", argv[0]);
        return 0;
            
        #elif defined(__aarch64__)
            
        [operationQueue setQualityOfService:NSQualityOfServiceBackground];
            
        #endif
    }
    
    NSOperation *mainOperation = [NSBlockOperation blockOperationWithBlock: ^{
                                    switch(optionID)
                                    {
                                        case 3: printf("%.4f %s\n", getCurrentFrequency()*frequencyFormat, [frequencyMeasurement UTF8String]); break;
                                        default: printf("%.0f %s\n", getCurrentFrequency()*frequencyFormat, [frequencyMeasurement UTF8String]); break;
                                    }
                              }];
    
    [operationQueue addOperation:mainOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    return 0;
}
