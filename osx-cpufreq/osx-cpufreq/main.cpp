
// gcc -o osx-cpufreq main.cpp -arch x86_64 -arch arm64

#include <iostream>
#include <unistd.h>
#include <cmath>
#include <mach/mach_time.h>

uint64_t rdtsc(void);

#if defined(__x86_64__)

uint64_t rdtsc(void)
{
    uint32_t ret0[2];
    __asm volatile("rdtsc" : "=a"(ret0[0]), "=d"(ret0[1]));
    return ((uint64_t)ret0[1] << 32) | ret0[0];
}

#endif

double getCurrentFrequency()
{
    #if defined(__x86_64__)
    
    uint64_t startCount = rdtsc();
    sleep(1);
    uint64_t endCount = rdtsc();
    
    uint64_t frequency = (endCount - startCount);
    
    return frequency;
    
    #elif defined(__aarch64__)
    
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    
    const size_t testDurationFromCycles = 65536;
    auto firstSampleBegin = mach_absolute_time();
    size_t cycles = 2 * testDurationFromCycles;
    
    __asm volatile(".align 4\n Lcyclemeasure1:\nsubs %[counter],%[counter],#1\nbne Lcyclemeasure1\n " : [counter] "+r"(cycles));
    
    auto firstSampleEnd = mach_absolute_time();
    double firstNanosecondSet = (double) (firstSampleEnd - firstSampleBegin) * (double)info.numer / (double)info.denom;
    auto lastSampleBegin = mach_absolute_time();
    
    cycles = testDurationFromCycles;
    
    __asm volatile(".align 4\n Lcyclemeasure2:\nsubs %[counter],%[counter],#1\nbne Lcyclemeasure2\n " : [counter] "+r"(cycles));
    
    auto lastSampleEnd = mach_absolute_time();
    double lastNanosecondSet = (double) (lastSampleEnd - lastSampleBegin) * (double)info.numer / (double)info.denom;
    double nanoseconds = (firstNanosecondSet - lastNanosecondSet);
    
    if ((fabs(nanoseconds - firstNanosecondSet / 2) > 0.05 * nanoseconds) || (fabs(nanoseconds - lastNanosecondSet) > 0.05 * nanoseconds)) { return 0; }

    double frequency = (double)(testDurationFromCycles) / nanoseconds;
    
    return frequency;
    
    #endif
}

int main(int argc, char * argv[])
{
    int arg;
    int argOutput = 0;
    
    while((arg = getopt(argc, argv, "kmgh")) != -1)
    {
        switch(arg)
        {
            case 'k':
                argOutput = 1;
                break;
            case 'm':
                argOutput = 2;
                break;
            case 'g':
                argOutput = 3;
                break;
            case 'h':
                printf("%s [options]\n", argv[0]);
                printf("    -k         : output in kilohertz (kHz)\n");
                printf("    -m         : output in megahertz (mHz)\n");
                printf("    -g         : output in gigahertz (gHz)\n");
                printf("    -h         : help\n");
                return 0;
                break;
        }
    }
    
    #if defined(__x86_64__)
    
    switch(argOutput)
    {
        case 0:
            printf("%.0f Hz\n", getCurrentFrequency());
            break;
        case 1:
            printf("%.0f kHz\n", getCurrentFrequency()*.001);
            break;
        case 2:
            printf("%.0f mHz\n", getCurrentFrequency()*.000001);
            break;
        case 3:
            printf("%.4f gHz\n", getCurrentFrequency()*.000000001);
            break;
    }
    
    #elif defined(__aarch64__)
    
    switch(argOutput)
    {
        case 0:
            printf("%.0f Hz\n", getCurrentFrequency()*1000000000);
            break;
        case 1:
            printf("%.0f kHz\n", getCurrentFrequency()*1000000);
            break;
        case 2:
            printf("%.0f mHz\n", getCurrentFrequency()*1000);
            break;
        case 3:
            printf("%.4f gHz\n", getCurrentFrequency());
            break;
    }
    
    #endif
    
    return 0;
}
