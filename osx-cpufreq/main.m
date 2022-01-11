// building:    clang main.m -fobjc-arc -arch arm64 -arch x86_64 -o osx-cpufreq

#include <Foundation/Foundation.h>
#include <mach/mach_time.h>

#if defined(__x86_64__)

#include <x86intrin.h>

#define FIRST_CYCLE_MEASURE { asm volatile("firstmeasure:\ndec %[counter]\njnz firstmeasure\n " : [counter] "+r"(cycles)); }
#define LAST_CYCLE_MEASURE { asm volatile("lastmeasure:\ndec %[counter]\njnz lastmeasure\n " : [counter] "+r"(cycles)); }

#elif defined(__aarch64__)

#include <sys/time.h>

#define FIRST_CYCLE_MEASURE { asm volatile(".align 4\n firstmeasure:\nsubs %[counter],%[counter],#1\nbne firstmeasure\n " : [counter] "+r"(cycles)); }
#define LAST_CYCLE_MEASURE { asm volatile(".align 4\n lastmeasure:\nsubs %[counter],%[counter],#1\nbne lastmeasure\n " : [counter] "+r"(cycles)); }
#define STATIC_MEASURE { asm volatile ("add %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\nadd %[counter], %[counter], #1\n" : [counter] "+r"(cycles));}

#endif

double getCurrentFrequency(void)
{
    int magicNumber = 2 << 16; // 65536
    
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    size_t cycles;
    
    uint64_t firstSampleBegin = mach_absolute_time();
    
    cycles = magicNumber * 2;
    FIRST_CYCLE_MEASURE
    
    uint64_t firstSampleEnd = mach_absolute_time();
    double firstNanosecondSet = (double) (firstSampleEnd - firstSampleBegin) * (double)info.numer / (double)info.denom;
    uint64_t lastSampleBegin = mach_absolute_time();
    
    cycles = magicNumber;
    LAST_CYCLE_MEASURE
    
    uint64_t lastSampleEnd = mach_absolute_time();
    double lastNanosecondSet = (double) (lastSampleEnd - lastSampleBegin) * (double)info.numer / (double)info.denom;
    double nanoseconds = (firstNanosecondSet - lastNanosecondSet);
    
    if ((fabs(nanoseconds - firstNanosecondSet / 2) > 0.05 * nanoseconds) || (fabs(nanoseconds - lastNanosecondSet) > 0.05 * nanoseconds)) { return 0; }

    double frequency = (double)(magicNumber / nanoseconds);
    return frequency;
}

double getStaticFrequency(void)
{
    double frequency;
    
    #if defined(__x86_64__)
    
    uint64_t startCount = __rdtsc();
    sleep(1);
    uint64_t endCount = __rdtsc();

    frequency = (double)((endCount - startCount) / 1e+9);
    
    #elif defined(__aarch64__)
    
    struct timeval time;
    long cycles;
      
    gettimeofday(&time, NULL);
    double sampleBegin = (time.tv_sec + time.tv_usec) * 1e-6;
    
    for (cycles = 0; cycles < 1e+9;) { STATIC_MEASURE }

    gettimeofday(&time, NULL);
    double sampleEnd = (time.tv_sec + time.tv_usec) * 1e-6;
      
    frequency = (cycles / (sampleEnd - sampleBegin)) * 1e-6;
    
    #endif
    
    return frequency;
}

int main(int argc, char * argv[])
{
    int option;
    int qosID = 0;
    int formatID = 0;
    int freqTypeID = 0;
    int returnTypeID = 0;
    
    double frequencyFormat = 1;

    NSString *frequencyMeasurement = @"Hz";
    NSOperationQueue *operationQueue = [[NSOperationQueue alloc] init];
    
    while((option = getopt(argc, argv, "kmgexdvh")) != -1)
    {
        switch(option)
        {
            case 'e':   qosID = 1; break;
            case 'x':   freqTypeID = 1; break;
            case 'd':   returnTypeID = 1; break;
            case 'k':   formatID = 1; break;
            case 'm':   formatID = 2; break;
            case 'g':   formatID = 3; break;
            case 'v':   formatID = 4; break;
            case 'h':   printf("Usage: %s [-kmgexdvh]\n", argv[0]);
                        printf("    -k         : print output in kilohertz (kHz)\n");
                        printf("    -m         : print output in megahertz (mHz)\n");
                        printf("    -g         : print output in gigahertz (gHz)\n");
                        printf("    -e         : get frequency of efficiency cores (arm64 only)\n");
                        printf("    -x         : get static frequency instead of current frequency\n");
                        printf("    -d         : disable return static frequency on error\n");
                        printf("    -v         : print version number\n");
                        printf("    -h         : help\n");
                        return 0;
                        break;
        }
    }

    switch(formatID)
    {
        case 0: frequencyFormat = 1e+9; frequencyMeasurement = @"Hz"; break;
        case 1: frequencyFormat = 1e+6; frequencyMeasurement = @"kHz"; break;
        case 2: frequencyFormat = 1e+3; frequencyMeasurement = @"mHz"; break;
        case 3: frequencyFormat = 1; frequencyMeasurement = @"gHz"; break;
        case 4: printf("%s: version 1.4.0\n", argv[0]); return 0; break;
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
        
                                    double frequency;
            
                                    switch(freqTypeID)
                                    {
                                        case 1: frequency = getStaticFrequency() * frequencyFormat; break;
                                        default: frequency = getCurrentFrequency() * frequencyFormat; break;
                                    }
                                    
                                    if (frequency <= 0 && returnTypeID == 0) {
                                        frequency = getStaticFrequency() * frequencyFormat;
                                    }
                                    
                                    switch(formatID)
                                    {
                                        case 3: printf("%.4f %s\n", frequency, [frequencyMeasurement UTF8String]); break;
                                        default: printf("%.0f %s\n", frequency, [frequencyMeasurement UTF8String]); break;
                                    }
                              }];
    
    [operationQueue addOperation:mainOperation];
    [operationQueue waitUntilAllOperationsAreFinished];
    
    return 0;
}
