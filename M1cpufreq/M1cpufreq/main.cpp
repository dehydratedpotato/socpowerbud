
#include <iostream>
#include <unistd.h>
#include <cmath>
#include <mach/mach_time.h>

double currentFrequency()
{
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
    
    switch(argOutput)
    {
        case 0:
            printf("%.0f Hz\n", currentFrequency()*1000000000);
            break;
        case 1:
            printf("%.0f kHz\n", currentFrequency()*1000000);
            break;
        case 2:
            printf("%.0f mHz\n", currentFrequency()*1000);
            break;
        case 3:
            printf("%.4f gHz\n", currentFrequency());
            break;
    }
    return 0;
}
