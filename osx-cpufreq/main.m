//
//    MIT License
//
//    Copyright (c) 2021-2022 BitesPotatoBacks
//
//    Permission is hereby granted, free of charge, to any person obtaining a copy
//    of this software and associated documentation files (the "Software"), to deal
//    in the Software without restriction, including without limitation the rights
//    to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//    copies of the Software, and to permit persons to whom the Software is
//    furnished to do so, subject to the following conditions:
//
//    The above copyright notice and this permission notice shall be included in all
//    copies or substantial portions of the Software.
//
//    THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//    IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//    FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//    AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//    LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//    OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//    SOFTWARE.
//
//    Building:    clang main.m -fobjc-arc -arch arm64 -arch x86_64 -o osx-cpufreq -lIOReport -framework Foundation

#include <Foundation/Foundation.h>
#include <mach/mach_time.h>
#include <sys/sysctl.h>

#define ERROR(error) { printf("%s: %s\n", "osx-cpufreq", error); exit(-1); }

#if defined(__x86_64__)

#include <x86intrin.h>

#define FIRST_CYCLE_MEASURE { asm volatile("firstmeasure:\ndec %[counter]\njnz firstmeasure\n " : [counter] "+r"(cycles)); }
#define LAST_CYCLE_MEASURE { asm volatile("lastmeasure:\ndec %[counter]\njnz lastmeasure\n " : [counter] "+r"(cycles)); }

double intelNominalFrequency(void)
{
    uint64_t startCount = __rdtsc();
    sleep(1);
    uint64_t endCount = __rdtsc();

    return (double)((endCount - startCount) / 1e+6);
}

#endif

enum { kIOReportIterOk, kIOReportFormatState = 2 };

typedef struct IOReportSubscriptionRef* IOReportSubscriptionRef;
typedef CFDictionaryRef IOReportSampleRef;

extern IOReportSubscriptionRef IOReportCreateSubscription(void* a, CFMutableDictionaryRef desiredChannels, CFMutableDictionaryRef* subbedChannels, uint64_t channel_id, CFTypeRef b);
extern CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub, CFMutableDictionaryRef subbedChannels, CFTypeRef a);

extern CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString*, NSString*, uint64_t, uint64_t, uint64_t);
extern CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t, uint64_t);

typedef int (^ioreportiterateblock)(IOReportSampleRef ch);
extern void IOReportIterate(CFDictionaryRef samples, ioreportiterateblock);

extern int IOReportGetChannelCount(CFMutableDictionaryRef);
extern int IOReportChannelGetFormat(CFDictionaryRef samples);
extern long IOReportSimpleGetIntegerValue(CFDictionaryRef, int);

extern int IOReportStateGetCount(CFDictionaryRef);
extern uint64_t IOReportStateGetResidency(CFDictionaryRef, int);
extern NSString* IOReportStateGetNameForIndex(CFDictionaryRef, int);
extern NSString* IOReportChannelGetChannelName(CFDictionaryRef);
extern NSString* IOReportChannelGetGroup(CFDictionaryRef);
extern NSString* IOReportChannelGetSubGroup(CFDictionaryRef);
extern uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef, int);

NSMutableArray * getPerformanceStates(int cpuCluster, int cpuSubgroup, int cpuCore)
{
    NSString * cpuType, * cpuStateType;
    NSMutableArray * performanceStateValues = [NSMutableArray array];
    
    switch(cpuCluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 0: cpuType = @"ECPU"; break;
        case 1: cpuType = @"PCPU"; break;
    }
    
    switch(cpuSubgroup) {
        default: ERROR("incorrect performance state subgroup input"); break;
        case 0: cpuStateType = @"CPU Complex Performance States"; break;
        case 1: cpuStateType = @"CPU Core Performance States"; break;
    }
    
    switch(cpuCore)
    {
        default: cpuType = [NSString stringWithFormat:@"%@%i", cpuType, cpuCore]; break;
        case 0: cpuType = [NSString stringWithFormat:@"%@", cpuType]; cpuStateType = @"CPU Complex Performance States"; break;
    }
    
    CFMutableDictionaryRef channels = IOReportCopyChannelsInGroup(@"CPU Stats", 0x0, 0x0, 0x0, 0x0);
    CFMutableDictionaryRef subbedChannels = NULL;
    
    IOReportSubscriptionRef subscription = IOReportCreateSubscription(NULL, channels, &subbedChannels, 0, 0);
    
    if (!subscription)
    {
        ERROR("error finding channel");
    }
    
    CFDictionaryRef samples = NULL;
    
    if ((samples = IOReportCreateSamples(subscription, subbedChannels, NULL)))
    {
        IOReportIterate(samples, ^(IOReportSampleRef ch)
        {
            NSString * channelName = IOReportChannelGetChannelName(ch);
            NSString * subgroup = IOReportChannelGetSubGroup(ch);
            uint64_t value;

            for (int i = 0; i < IOReportStateGetCount(ch); i++)
            {
                if ([channelName isEqual: cpuType] && [subgroup isEqual: cpuStateType])
                {
                    value = IOReportStateGetResidency(ch, i);
                    [performanceStateValues addObject:@(value)];
                }
            }
            
            return kIOReportIterOk;
        });
    }
    else
    {
        ERROR("error accessing performance state information");
    }
    
    if ([performanceStateValues count] == 0)
    {
        ERROR("missing performance state values");
    }
    
    return performanceStateValues;
}

int getSysctl(char * entry)
{
    int variable;
    size_t len = 4;
    
    if (sysctlbyname(entry, &variable, &len, NULL, 0) == -1)
    {
        ERROR("invalid output from sysctl");
    }
    else
    {
        sysctlbyname(entry, &variable, &len, NULL, 0);
        return variable;
    }
}

float getCurrentFrequency(int cpuCluster, int cpuSubgroup, int cpuCore, NSArray * cpuNominalFrequencies, int interval)
{
    #if defined(__x86_64__)
    
    int magicNumber = 2 << 16;
    
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
        
    float frequency = (float)(magicNumber / nanoseconds);
    
    return frequency * 1e+3;
    
    #elif defined(__aarch64__)
    
    float firstSum = 0, lastSum = 0, finalSum = 0;
    float stateSum = 0, finalStateSum = 0;
    
    NSMutableArray * firstMeasure = getPerformanceStates(cpuCluster, cpuSubgroup, cpuCore);
    sleep(interval);
    NSMutableArray * lastMeasure = getPerformanceStates(cpuCluster, cpuSubgroup, cpuCore);
    
    for (int i = 0; i < [firstMeasure count]; i++)
    {
        firstSum += [firstMeasure[i] floatValue];
        lastSum += [lastMeasure[i] floatValue];
    }
    
    finalSum = lastSum - firstSum;
    
    for (int i = 0; i < [firstMeasure count]; i++)
    {
        stateSum = ([lastMeasure[i] floatValue] - [firstMeasure[i] floatValue]) / finalSum;
        finalStateSum += stateSum * [cpuNominalFrequencies[i] floatValue];
    }

    return finalStateSum;
    
    #endif
}

void outputFrequency(int coreCount, int cpuCluster, int cpuSubgroup, int cpuNominalFrequency, NSArray * cpuNominalFrequencies, bool complex, int interval)
{
    float currentFrequency, frequencyPercentage;
    char * cpu;
    
    switch(cpuCluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 0: cpu = "E"; break;
        case 1: cpu = "P"; break;
    }
    
    for (int i = 0; i < coreCount; i++)
    {
        currentFrequency = getCurrentFrequency(cpuCluster, cpuSubgroup, i, cpuNominalFrequencies, interval);
        frequencyPercentage = (currentFrequency / cpuNominalFrequency) * 100;
        
        if (currentFrequency > cpuNominalFrequency)
        {
            currentFrequency = cpuNominalFrequency;
        }
        
        if (complex == false)
        {
            if (frequencyPercentage == 0 || frequencyPercentage <= 0.009)
            {
                printf("%sCPU %i:%11.2f MHz %6sIdle\n", cpu, i + 1, currentFrequency, "");
            }
            else
            {
                printf("%sCPU %i:%11.2f MHz %9.2f%%\n", cpu, (i + 1), currentFrequency, frequencyPercentage);
            }
        }
        else
        {
            if (frequencyPercentage == 0 || currentFrequency <= 0.009)
            {
                printf("%sCPU:%13.2f MHz %6sIdle\n", cpu, currentFrequency, "");
            }
            else
            {
                printf("%sCPU:%13.2f MHz %9.2f%%\n", cpu, currentFrequency, frequencyPercentage);
            }
        }

    }
}

int main(int argc, char * argv[])
{
    int option, outputID = 0, interval = 1;
    
    while((option = getopt(argc, argv, "i:ceplmvh")) != -1)
    {
        switch(option)
        {
            default:    outputID = 0; break;
            case 'l':   outputID = 1; break;
            case 'c':   outputID = 2; break;
            case 'e':   outputID = 3; break;
            case 'p':   outputID = 4; break;
            case 'm':   outputID = 5; break;
            case 'i':   interval = atoi(optarg); break;
            case 'v':   printf("%s: version 2.0.0\n", "osx-cpufreq"); return 0; break;
            case 'h':   printf("Usage: %s [-iceplmvh]\n", "osx-cpufreq");
                        printf("    -i <int>   : set sampling interval (may effect accuracy)   (arm64)\n");
                        printf("    -c         : print active frequency for all cores          (arm64)\n");
                        printf("    -e         : print active frequency for efficiency cores   (arm64)\n");
                        printf("    -p         : print active frequency for performance cores  (arm64)\n");
                        printf("    -l         : print active frequency for all clusters\n");
                        printf("    -m         : print maximum frequency for all clusters\n");
                        printf("    -v         : print version number\n");
                        printf("    -h         : help\n");
                        return 0;
                        break;
        }
    }
    
    #if defined(__x86_64__)
    
    float frequency;
    
    if (interval != 1) {
        ERROR("command line option used not yet supported on x86");
    }
    
    #elif defined(__aarch64__)
    
    int efficiencyMaximumFreq = 2064, performanceMaximumFreq = 3204;
    int performanceCoreCount = getSysctl("hw.perflevel0.physicalcpu");
    int efficiencyCoreCount = getSysctl("hw.perflevel1.physicalcpu");
    
    NSArray * efficiencyNominalFreqs = @[
        @"0",
        @"600",
        @"972",
        @"1332",
        @"1704",
        @"2064"
    ];
    
    NSArray * performanceNominalFreqs = @[
        @"0",
        @"600",
        @"828",
        @"1056",
        @"1284",
        @"1500",
        @"1728",
        @"1956",
        @"2184",
        @"2388",
        @"2592",
        @"2772",
        @"2988",
        @"3096",
        @"3144",
        @"3204"
    ];
    
    #endif

    switch(outputID)
    {
        #if defined(__x86_64__)
            
        case 0:
        case 1:     frequency = getCurrentFrequency(0, 0, 0, NULL, 0);
                    printf("\n%s%18s%12s\n\n", "CPU", "Frequency", "Percent");
                    printf("CPU:%13.2f MHz %9.2f%%\n", frequency, (frequency / intelNominalFrequency()) * 100);
                    break;
        case 2:
        case 3:
        case 4:     ERROR("command line option used not yet supported on x86");
                    break;
            
        case 5:     printf("CPU Max:%8.0f MHz\n", intelNominalFrequency());
                    break;
            
        #elif defined(__aarch64__)
            
        case 0:     printf("\n%s%18s%12s\n\n", "CPU", "Frequency", "Percent");
                    outputFrequency(1, 0, 0, efficiencyMaximumFreq, efficiencyNominalFreqs, true, interval);
                    outputFrequency(1, 1, 0, performanceMaximumFreq, performanceNominalFreqs, true, interval);
                    printf("\n");
                    outputFrequency(efficiencyCoreCount, 0, 1, efficiencyMaximumFreq, efficiencyNominalFreqs, false, interval);
                    printf("\n");
                    outputFrequency(performanceCoreCount, 1, 1, performanceMaximumFreq, performanceNominalFreqs, false, interval);
                    printf("\n");
                    break;
            
        case 1:     printf("\n%s%18s%12s\n\n", "CPU", "Frequency", "Percent");
                    outputFrequency(1, 0, 0, efficiencyMaximumFreq, efficiencyNominalFreqs, 1, interval);
                    outputFrequency(1, 1, 0, performanceMaximumFreq, performanceNominalFreqs, 1, interval);
                    break;
            
        case 2:     printf("\n%s%18s%12s\n\n", "CPU", "Frequency", "Percent");
                    outputFrequency(efficiencyCoreCount, 0, 1, efficiencyMaximumFreq, efficiencyNominalFreqs, false, interval);
                    printf("\n");
                    outputFrequency(performanceCoreCount, 1, 1, performanceMaximumFreq, performanceNominalFreqs, false, interval);
                    printf("\n");
                    break;
            
        case 3:     printf("\n%s%18s%12s\n\n", "CPU", "Frequency", "Percent");
                    outputFrequency(efficiencyCoreCount, 0, 1, efficiencyMaximumFreq, efficiencyNominalFreqs, false, interval);
                    printf("\n");
                    break;
            
        case 4:     printf("\n%s%18s%12s\n\n", "CPU", "Frequency", "Percent");
                    outputFrequency(performanceCoreCount, 1, 1, performanceMaximumFreq, performanceNominalFreqs, false, interval);
                    printf("\n");
                    break;
            
        case 5:     printf("ECPU Max:%8i MHz\n", efficiencyMaximumFreq);
                    printf("PCPU Max:%8i MHz\n", performanceMaximumFreq);
                    break;
            
        #endif
    }

    return 0;
}
