
/*
 * SFMRM ARM64-client version 0.1.0
 *
 * MIT License
 *
 * Copyright (c) 2022 BitesPotatoBacks
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in all
 * copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
 * SOFTWARE.
 */

#include <Foundation/Foundation.h>
#include <sys/sysctl.h>
#include <getopt.h>
#include <stdarg.h>

/* macros and struct datas */

#define name        "SFMRM"
#define type        "ARM64-client"
#define version     "0.1.1"

typedef struct {
    NSMutableArray *    gpuComplexFirstSample;
    NSMutableArray *    gpuComplexLastSample;
    
    NSMutableArray *    eCpuComplexFirstSample;
    NSMutableArray *    eCpuComplexLastSample;
    NSMutableArray *    eCpuCoreFirstSample;
    NSMutableArray *    eCpuCoreLastSample;
    
    NSMutableArray *    pCpuComplexFirstSample;
    NSMutableArray *    pCpuComplexLastSample;
    NSMutableArray *    pCpuCoreFirstSample;
    NSMutableArray *    pCpuCoreLastSample;
} rawSampleData;

typedef struct {
    NSMutableArray *    gpuComplexStateResidency;
    NSMutableArray *    eCpuComplexStateResidency;
    NSMutableArray *    pCpuComplexStateResidency;
    
    float               gpuComplexFrequency;
    float               eCpuComplexFrequency;
    float               pCpuComplexFrequency;
    
    NSMutableArray *    eCpuCoreFrequencies;
    NSMutableArray *    pCpuCoreFrequencies;
    
    float               gpuComplexIdleResidency;
    float               eCpuComplexIdleResidency;
    float               pCpuComplexIdleResidency;
    
    NSMutableArray *    eCpuCoreIdleResidencies;
    NSMutableArray *    pCpuCoreIdleResidencies;
} formattedSampleData;

typedef struct {
    bool    islooping;
    
    int     looprate;
    int     samplerate;
    
    int     looper;
    int     looperKey;
    
    bool    all;
    
    bool    ecpu;
    bool    pcpu;
    bool    gpu;
    
    bool    hidecores;
    bool    statefreqs;
} cmdOptions;

/* special functions for clang style error reporting */
 
void errf( const char * format, ... )
{
    va_list args;
    fprintf(stderr, "\e[1m%s:\033[0;31m error:\033[0m\e[0m ", name);
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
    
    exit(-1);
}

/*
 * Specific external functions for IOReport (derived from Private SDK)
 * see https://github.com/samdmarshall/OSXPrivateSDK/blob/master/PrivateSDK10.10.sparse.sdk/usr/local/include/IOReport.h
 */

enum { kIOReportIterOk };

typedef struct IOReportSubscriptionRef* IOReportSubscriptionRef;
typedef CFDictionaryRef IOReportSampleRef;

extern IOReportSubscriptionRef IOReportCreateSubscription(void* a, CFMutableDictionaryRef desiredChannels, CFMutableDictionaryRef* subbedChannels, uint64_t channel_id, CFTypeRef b);
extern CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub, CFMutableDictionaryRef subbedChannels, CFTypeRef a);

extern CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString*, NSString*, uint64_t, uint64_t, uint64_t);

typedef int (^ioreportiterateblock)(IOReportSampleRef ch);
extern void IOReportIterate(CFDictionaryRef samples, ioreportiterateblock);

extern int IOReportStateGetCount(CFDictionaryRef);
extern uint64_t IOReportStateGetResidency(CFDictionaryRef, int);
extern NSString* IOReportChannelGetChannelName(CFDictionaryRef);
extern NSString* IOReportChannelGetSubGroup(CFDictionaryRef);

/* functions for injecting all of our sample data into our given arrays */

void IOReportInjectRawSampleData( float interval,
                                  int eCpuCoreCount,
                                  int pCpuCoreCount,
                                  rawSampleData * rawSampleData )
{
    CFDictionaryRef         cpuStatsSamples         = NULL;
    CFMutableDictionaryRef  cpuStatsChannels        = NULL,
                            cpuStatsSubbedChannels  = NULL;
    
    CFDictionaryRef         gpuStatsSamples         = NULL;
    CFMutableDictionaryRef  gpuStatsChannels        = NULL,
                            gpuStatsSubbedChannels  = NULL;
    
    IOReportSubscriptionRef cpuStatsSubscription    = NULL;
    IOReportSubscriptionRef gpuStatsSubscription    = NULL;
    
    NSString *              cpuComplexPstateType    = @"CPU Complex Performance States";
    NSString *              cpuCorePstateType       = @"CPU Core Performance States";
    NSString *              gpuComplexPstateType    = @"GPU Performance States";

    NSString *              eCpuSubtype             = @"ECPU";
    NSString *              pCpuSubtype             = @"PCPU";
    NSString *              gpuphSubtype            = @"GPUPH";
    
    /*
     * This is where we access the IOReport for CPU and GPU samples...
     * we sample twice between a specified interval so we have enough data to perform our calculations later on. This requires us to call IOReportCreateSamples(..) twice
     * for each group in order to refresh the data we're sampling. DRY rule violations will be improved in an upcoming release.
     */
    
    if (!(cpuStatsChannels = IOReportCopyChannelsInGroup(@"CPU Stats", 0, 0, 0, 0)))
        goto cpu_err;
    if (!(gpuStatsChannels = IOReportCopyChannelsInGroup(@"GPU Stats", 0, 0, 0, 0)))
        goto gpu_err;
    
    if (!(cpuStatsSubscription = IOReportCreateSubscription(NULL, cpuStatsChannels, &cpuStatsSubbedChannels, 0, 0)))
        goto cpu_err;
    if (!(gpuStatsSubscription = IOReportCreateSubscription(NULL, gpuStatsChannels, &gpuStatsSubbedChannels, 0, 0)))
        goto gpu_err;
    
    /* CPU first sample */
        
    if ((cpuStatsSamples = IOReportCreateSamples(cpuStatsSubscription, cpuStatsSubbedChannels, NULL))) {
        
        /* ECPU and PCPU Complex Sampling */
        
        IOReportIterate(cpuStatsSamples, ^(IOReportSampleRef ch) {
            
            for (int i = 0; i < IOReportStateGetCount(ch); i++) {
                
                if ([IOReportChannelGetSubGroup(ch) isEqual: cpuComplexPstateType]) {
                    
                    if ([IOReportChannelGetChannelName(ch) isEqual: eCpuSubtype])
                        [rawSampleData->eCpuComplexFirstSample addObject:@(IOReportStateGetResidency(ch, i))];
                    else if ([IOReportChannelGetChannelName(ch) isEqual: pCpuSubtype])
                        [rawSampleData->pCpuComplexFirstSample addObject:@(IOReportStateGetResidency(ch, i))];
                }
            }

            return kIOReportIterOk;
        });
        
        /* ECPU Core sampling */
        
        for (int i = 0; i < eCpuCoreCount; i++) {
            
            [rawSampleData->eCpuCoreFirstSample addObject: [NSMutableArray array]];
            
            IOReportIterate(cpuStatsSamples, ^(IOReportSampleRef ch) {
                for (int ii = 0; ii < IOReportStateGetCount(ch); ii++) {
                    if ([IOReportChannelGetSubGroup(ch) isEqual: cpuCorePstateType]) {
                        if ([IOReportChannelGetChannelName(ch) isEqual: [NSString stringWithFormat:@"%@%d", eCpuSubtype, i]])
                            [rawSampleData->eCpuCoreFirstSample[i] addObject:@(IOReportStateGetResidency(ch, ii))];
                    }
                }

                return kIOReportIterOk;
            });
        }
        
        /* ECPU Core sampling */
        
        for (int i = 0; i < pCpuCoreCount; i++) {
            
            [rawSampleData->pCpuCoreFirstSample addObject: [NSMutableArray array]];
            
            IOReportIterate(cpuStatsSamples, ^(IOReportSampleRef ch) {
                for (int ii = 0; ii < IOReportStateGetCount(ch); ii++) {
                    if ([IOReportChannelGetSubGroup(ch) isEqual: cpuCorePstateType]) {
                        if ([IOReportChannelGetChannelName(ch) isEqual: [NSString stringWithFormat:@"%@%d", pCpuSubtype, i]])
                            [rawSampleData->pCpuCoreFirstSample[i] addObject:@(IOReportStateGetResidency(ch, ii))];
                    }
                }

                return kIOReportIterOk;
            });
        }
    } else
        goto cpu_err;
    
    /* GPU first sample */
        
    if ((gpuStatsSamples = IOReportCreateSamples(gpuStatsSubscription, gpuStatsSubbedChannels, NULL))) {
        IOReportIterate(gpuStatsSamples, ^(IOReportSampleRef ch) {
            for (int i = 0; i < IOReportStateGetCount(ch); i++) {
                
                if ([IOReportChannelGetSubGroup(ch) isEqual: gpuComplexPstateType]) {
                    
                    if ([IOReportChannelGetChannelName(ch) isEqual: gpuphSubtype])
                        [rawSampleData->gpuComplexFirstSample addObject:@(IOReportStateGetResidency(ch, i))];
                }
            }
            
            return kIOReportIterOk;
        });
    } else
        goto gpu_err;
    
    [NSThread sleepForTimeInterval: (interval * 1e-3)];
    
    /* now this is the second half where we do all of our last samples */
    
    /* CPU first sample */
        
    if ((cpuStatsSamples = IOReportCreateSamples(cpuStatsSubscription, cpuStatsSubbedChannels, NULL))) {
        
        /* ECPU and PCPU Complex Sampling */
        
        IOReportIterate(cpuStatsSamples, ^(IOReportSampleRef ch) {
            
            for (int i = 0; i < IOReportStateGetCount(ch); i++) {
                
                if ([IOReportChannelGetSubGroup(ch) isEqual: cpuComplexPstateType]) {
                    
                    if ([IOReportChannelGetChannelName(ch) isEqual: eCpuSubtype])
                        [rawSampleData->eCpuComplexLastSample addObject:@(IOReportStateGetResidency(ch, i))];
                    else if ([IOReportChannelGetChannelName(ch) isEqual: pCpuSubtype])
                        [rawSampleData->pCpuComplexLastSample addObject:@(IOReportStateGetResidency(ch, i))];
                }
            }

            return kIOReportIterOk;
        });
        
        /* ECPU Core sampling */
        
        for (int i = 0; i < eCpuCoreCount; i++) {
            
            [rawSampleData->eCpuCoreLastSample addObject: [NSMutableArray array]];
            
            IOReportIterate(cpuStatsSamples, ^(IOReportSampleRef ch) {
                for (int ii = 0; ii < IOReportStateGetCount(ch); ii++) {
                    if ([IOReportChannelGetSubGroup(ch) isEqual: cpuCorePstateType]) {
                        if ([IOReportChannelGetChannelName(ch) isEqual: [NSString stringWithFormat:@"%@%d", eCpuSubtype, i]])
                            [rawSampleData->eCpuCoreLastSample[i] addObject:@(IOReportStateGetResidency(ch, ii))];
                    }
                }

                return kIOReportIterOk;
            });
        }
        
        /* ECPU Core sampling */
        
        for (int i = 0; i < pCpuCoreCount; i++) {
            
            [rawSampleData->pCpuCoreLastSample addObject: [NSMutableArray array]];
            
            IOReportIterate(cpuStatsSamples, ^(IOReportSampleRef ch) {
                for (int ii = 0; ii < IOReportStateGetCount(ch); ii++) {
                    if ([IOReportChannelGetSubGroup(ch) isEqual: cpuCorePstateType]) {
                        if ([IOReportChannelGetChannelName(ch) isEqual: [NSString stringWithFormat:@"%@%d", pCpuSubtype, i]])
                            [rawSampleData->pCpuCoreLastSample[i] addObject:@(IOReportStateGetResidency(ch, ii))];
                    }
                }

                return kIOReportIterOk;
            });
        }
        
    } else
        goto cpu_err;
    
    /* GPU last sample */
    
    if ((gpuStatsSamples = IOReportCreateSamples(gpuStatsSubscription, gpuStatsSubbedChannels, NULL))) {
        IOReportIterate(gpuStatsSamples, ^(IOReportSampleRef ch) {
            for (int i = 0; i < IOReportStateGetCount(ch); i++) {
                
                if ([IOReportChannelGetSubGroup(ch) isEqual: gpuComplexPstateType]) {
                    
                    if ([IOReportChannelGetChannelName(ch) isEqual: gpuphSubtype])
                        [rawSampleData->gpuComplexLastSample addObject:@(IOReportStateGetResidency(ch, i))];
                }
            }
            
            return kIOReportIterOk;
        });
    } else
        goto gpu_err;
            
    return;
    
cpu_err:
    errf("encountered an error while accessing CPU data from IOReport");
    
gpu_err:
    errf("encountered an error while accessing GPU data from IOReport");
}

void IOReportFormatRawSampleData( NSArray * eCpuClusterStateFreqs,
                                  NSArray * pCpuClusterStateFreqs,
                                  NSArray * gpuClusterStateFreqs,
                                  int eCpuCoreCount,
                                  int pCpuCoreCount,
                                  rawSampleData * rawSampleData,
                                  formattedSampleData * formattedSampleData )
{
    unsigned long long  eCpuComplexStateCounterValues  = 0,
                        eCpuComplexStateDifference     = 0,
                        eCpuComplexIdleValues          = 0,
                        eCpuComplexTotalResidency      = 0;
    
    unsigned long long  pCpuComplexStateCounterValues  = 0,
                        pCpuComplexStateDifference     = 0,
                        pCpuComplexIdleValues          = 0,
                        pCpuComplexTotalResidency      = 0;
    
    unsigned long long  gpuComplexStateCounterValues   = 0,
                        gpuComplexStateDifference      = 0,
                        gpuComplexIdleValues           = 0,
                        gpuComplexTotalResidency       = 0;
    
    float               eCpuCoreFrequencyTemp          = 0;
    float               pCpuCoreFrequencyTemp          = 0;
    
    unsigned long long  eCpuCoreStateCounterValuesTemp = 0,
                        eCpuCoreStateDifferenceTemp    = 0,
                        eCpuCoreIdleValuesTemp         = 0,
                        eCpuCoreTotalResidencyTemp     = 0;
    
    unsigned long long  pCpuCoreStateCounterValuesTemp = 0,
                        pCpuCoreStateDifferenceTemp    = 0,
                        pCpuCoreIdleValuesTemp         = 0,
                        pCpuCoreTotalResidencyTemp     = 0;
    
    NSMutableArray *    eCpuCoreStateCounterValues     = [NSMutableArray array];
    NSMutableArray *    eCpuCoreStateResidencies       = [NSMutableArray array];
    
    NSMutableArray *    pCpuCoreStateCounterValues     = [NSMutableArray array];
    NSMutableArray *    pCpuCoreStateResidencies       = [NSMutableArray array];
    
    /*
     * here we calculate togethar all of the differences between the two state counter value samples of each group...
     * we know how many states there are for each group, so we're just using static ints for our loops (rather than [ourStateArray count]) until I know that those state counts
     * end up changing for some new generations of silicon. This way is more efficient and lets our compiler unroll our for loops.
     */
    
    /* Complex Calculations */
    
    for (int i = 1; i < 16; i++) {
        if (i < 6) {
            eCpuComplexStateCounterValues += [rawSampleData->eCpuComplexLastSample[i] unsignedLongLongValue] - [rawSampleData->eCpuComplexFirstSample[i] unsignedLongLongValue];
            gpuComplexStateCounterValues += [rawSampleData->gpuComplexLastSample[i] unsignedLongLongValue] - [rawSampleData->gpuComplexFirstSample[i] unsignedLongLongValue];
        }
        
        pCpuComplexStateCounterValues += [rawSampleData->pCpuComplexLastSample[i] unsignedLongLongValue] - [rawSampleData->pCpuComplexFirstSample[i] unsignedLongLongValue];
    }
    
    /* Core Calculations */
    
    for (int i = 0; i < eCpuCoreCount; i++) {
        
        for (int ii = 1; ii < 6; ii++)
            eCpuCoreStateCounterValuesTemp += [rawSampleData->eCpuCoreLastSample[i][ii] unsignedLongLongValue] - [rawSampleData->eCpuCoreFirstSample[i][ii] unsignedLongLongValue];
        
        [eCpuCoreStateCounterValues addObject:[NSNumber numberWithUnsignedLongLong: eCpuCoreStateCounterValuesTemp]];
        
        eCpuCoreStateCounterValuesTemp = 0;
    }
    
    for (int i = 0; i < pCpuCoreCount; i++) {
        
        for (int ii = 1; ii < 16; ii++)
            pCpuCoreStateCounterValuesTemp += [rawSampleData->pCpuCoreLastSample[i][ii] unsignedLongLongValue] - [rawSampleData->pCpuCoreFirstSample[i][ii] unsignedLongLongValue];
        
        [pCpuCoreStateCounterValues addObject:[NSNumber numberWithUnsignedLongLong: pCpuCoreStateCounterValuesTemp]];
        
        pCpuCoreStateCounterValuesTemp = 0;
    }
    
    /*
     * now we calculate the active frequencies for our groups...
     * we do this by multiplying a groups state residency (the difference between the groups states from both samples) against that states associated nominal frequency
     */
    
    /* Complex Calculations */
    
    for (int i = 1; i < 16; i++) {
        if (i < 6) {
            eCpuComplexStateDifference = [rawSampleData->eCpuComplexLastSample[i] unsignedLongLongValue] - [rawSampleData->eCpuComplexFirstSample[i] unsignedLongLongValue];
            [formattedSampleData->eCpuComplexStateResidency addObject:@((float) eCpuComplexStateDifference / (float) eCpuComplexStateCounterValues)];
            formattedSampleData->eCpuComplexFrequency += [formattedSampleData->eCpuComplexStateResidency[i-1] floatValue] * [eCpuClusterStateFreqs[i] floatValue];
            
            gpuComplexStateDifference = [rawSampleData->gpuComplexLastSample[i] unsignedLongLongValue] - [rawSampleData->gpuComplexFirstSample[i] unsignedLongLongValue];
            [formattedSampleData->gpuComplexStateResidency addObject:@((float) gpuComplexStateDifference / (float) gpuComplexStateCounterValues)];
            formattedSampleData->gpuComplexFrequency += [formattedSampleData->gpuComplexStateResidency[i-1] floatValue] * [gpuClusterStateFreqs[i] floatValue];
        }
        
        pCpuComplexStateDifference = [rawSampleData->pCpuComplexLastSample[i] unsignedLongLongValue] - [rawSampleData->pCpuComplexFirstSample[i] unsignedLongLongValue];
        [formattedSampleData->pCpuComplexStateResidency addObject:@((float) pCpuComplexStateDifference / (float) pCpuComplexStateCounterValues)];
        formattedSampleData->pCpuComplexFrequency += [formattedSampleData->pCpuComplexStateResidency[i-1] floatValue] * [pCpuClusterStateFreqs[i] floatValue];
    }
    
    /* Core Calculations */
    
    for (int i = 0; i < eCpuCoreCount; i++) {
        
        [eCpuCoreStateResidencies addObject:[NSMutableArray array]];
        
        for (int ii = 1; ii < 6; ii++) {
            eCpuCoreStateDifferenceTemp += [rawSampleData->eCpuCoreLastSample[i][ii] unsignedLongLongValue] - [rawSampleData->eCpuCoreFirstSample[i][ii] unsignedLongLongValue];
            [eCpuCoreStateResidencies[i] addObject:@((float) eCpuCoreStateDifferenceTemp / (float) [eCpuCoreStateCounterValues[i] floatValue])];
            
            eCpuCoreStateDifferenceTemp = 0;
            eCpuCoreFrequencyTemp += [eCpuCoreStateResidencies[i][ii-1] floatValue] * [eCpuClusterStateFreqs[ii] floatValue];
        }
        
        [formattedSampleData->eCpuCoreFrequencies addObject:[NSNumber numberWithFloat: eCpuCoreFrequencyTemp]];
        
        eCpuCoreFrequencyTemp = 0;
    }
    
    for (int i = 0; i < pCpuCoreCount; i++) {
        
        [pCpuCoreStateResidencies addObject:[NSMutableArray array]];
        
        for (int ii = 1; ii < 16; ii++) {
            pCpuCoreStateDifferenceTemp += [rawSampleData->pCpuCoreLastSample[i][ii] unsignedLongLongValue] - [rawSampleData->pCpuCoreFirstSample[i][ii] unsignedLongLongValue];
            [pCpuCoreStateResidencies[i] addObject:@((float) pCpuCoreStateDifferenceTemp / (float) [pCpuCoreStateCounterValues[i] floatValue])];
            
            pCpuCoreStateDifferenceTemp = 0;
            pCpuCoreFrequencyTemp += [pCpuCoreStateResidencies[i][ii-1] floatValue] * [pCpuClusterStateFreqs[ii] floatValue];
        }
        
        [formattedSampleData->pCpuCoreFrequencies addObject:[NSNumber numberWithFloat: pCpuCoreFrequencyTemp]];
        
        pCpuCoreFrequencyTemp = 0;
    }

    /*
     * here we're calculating all of the groups idle residency percentages...
     * we do this by creating a total residency value for each group (based on our idle and active residencies) and dividing the differences of that groups idle values from it
     * we don't need to calculate the active residency percentages because it's the opposite of the idle residency, so we just subtract 100 from our idles later to get that data
     */
    
    /* Complex Calculations */
    
    eCpuComplexIdleValues = [rawSampleData->eCpuComplexLastSample[0] unsignedLongLongValue] - [rawSampleData->eCpuComplexFirstSample[0] unsignedLongLongValue];
    eCpuComplexTotalResidency = eCpuComplexIdleValues + eCpuComplexStateCounterValues;
    formattedSampleData->eCpuComplexIdleResidency = ((float) eCpuComplexIdleValues / (float) eCpuComplexTotalResidency) * 100;
    
    pCpuComplexIdleValues = [rawSampleData->pCpuComplexLastSample[0] unsignedLongLongValue] - [rawSampleData->pCpuComplexFirstSample[0] unsignedLongLongValue];
    pCpuComplexTotalResidency = pCpuComplexIdleValues + pCpuComplexStateCounterValues;
    formattedSampleData->pCpuComplexIdleResidency = ((float) pCpuComplexIdleValues / (float) pCpuComplexTotalResidency) * 100;
    
    gpuComplexIdleValues = [rawSampleData->gpuComplexLastSample[0] unsignedLongLongValue] - [rawSampleData->gpuComplexFirstSample[0] unsignedLongLongValue];
    gpuComplexTotalResidency = gpuComplexIdleValues + gpuComplexStateCounterValues;
    formattedSampleData->gpuComplexIdleResidency = ((float) gpuComplexIdleValues / (float) gpuComplexTotalResidency) * 100;
    
    /* Core Calculations */
    
    for (int i = 0; i < eCpuCoreCount; i++) {
        eCpuCoreIdleValuesTemp = [rawSampleData->eCpuCoreLastSample[i][0] unsignedLongLongValue] - [rawSampleData->eCpuCoreFirstSample[i][0] unsignedLongLongValue];
        eCpuCoreTotalResidencyTemp = eCpuCoreIdleValuesTemp + [eCpuCoreStateCounterValues[i] unsignedLongLongValue];
        [formattedSampleData->eCpuCoreIdleResidencies addObject:@(((float) eCpuCoreIdleValuesTemp / (float) eCpuCoreTotalResidencyTemp) * 100)];
    }
    
    for (int i = 0; i < pCpuCoreCount; i++) {
        pCpuCoreIdleValuesTemp = [rawSampleData->pCpuCoreLastSample[i][0] unsignedLongLongValue] - [rawSampleData->pCpuCoreFirstSample[i][0] unsignedLongLongValue];
        pCpuCoreTotalResidencyTemp = pCpuCoreIdleValuesTemp + [pCpuCoreStateCounterValues[i] unsignedLongLongValue];
        [formattedSampleData->pCpuCoreIdleResidencies addObject:@(((float) pCpuCoreIdleValuesTemp / (float) pCpuCoreTotalResidencyTemp) * 100)];
    }
    
    /* checking that our values are correct, otherwise we replace them */
    
    if (!(isnormal(formattedSampleData->eCpuComplexFrequency))) {
        formattedSampleData->eCpuComplexFrequency = 972;
        formattedSampleData->eCpuComplexIdleResidency = 100;
    }

    if (!(isnormal(formattedSampleData->pCpuComplexFrequency))) {
        formattedSampleData->pCpuComplexFrequency = 600;
        formattedSampleData->pCpuComplexIdleResidency = 100;
    }
    
    if (!(isnormal(formattedSampleData->gpuComplexFrequency))) {
        formattedSampleData->gpuComplexFrequency = 0;
        formattedSampleData->gpuComplexIdleResidency = 100;
    }
    
    for (int i = 0; i < eCpuCoreCount; i++) {
        if (!(isnormal([formattedSampleData->eCpuCoreFrequencies[i] floatValue])) || [formattedSampleData->eCpuCoreIdleResidencies[i] floatValue] >= 99.9994445)
            [formattedSampleData->eCpuCoreFrequencies replaceObjectAtIndex:i withObject:@(0)];
    }
    
    for (int i = 0; i < pCpuCoreCount; i++) {
        if (!(isnormal([formattedSampleData->pCpuCoreFrequencies[i] floatValue])) || [formattedSampleData->pCpuCoreIdleResidencies[i] floatValue] >= 99.9994445)
            [formattedSampleData->pCpuCoreFrequencies replaceObjectAtIndex:i withObject:@(0)];
    }
}

/* function for returning CPU cluster and GPU P-State frequencies */

NSMutableArray * generateStateFrequencies( void )
{
    mach_port_t         port = kIOMasterPortDefault;
    
    io_registry_entry_t entry;
    
    NSData *            data;
    NSString *          dataString;
    unsigned char *     dataBytes;
    
    float formattedFrequency;
    
    NSMutableArray * gpuStateFrequencies    = [NSMutableArray array];
    NSMutableArray * eCpuStateFrequencies   = [NSMutableArray array];
    NSMutableArray * pCpuStateFrequencies   = [NSMutableArray array];
    
    NSMutableArray * allStateFrequencies    = [NSMutableArray array];
    
    [eCpuStateFrequencies addObject:@"0"];
    [pCpuStateFrequencies addObject:@"0"];
    
    /*
     * accessing the voltage state entries from the PMGR for our per-state nominal frequencies.
     * the data given from the registry is formatted as 32 Bit integers stored in hexadecimal, so we have to translate them to our required float values
     */
    
    if ((entry = IORegistryEntryFromPath(port, "IOService:/AppleARMPE/arm-io/AppleT810xIO/pmgr")) || (entry = IORegistryEntryFromPath(port, "IOService:/arm-io/pmgr"))) {
        
        /* GPU */
        
        if ((data = (__bridge NSData *) (CFDataRef) IORegistryEntryCreateCFProperty(entry, CFSTR("voltage-states9"), kCFAllocatorDefault, 0))) {
            dataBytes = [data bytes];
            
            /*
             * the voltage states hold both state voltages and state frequency data, but the state voltages are located every other 4 bytes
             * so we make sure that our for loop skips every other 4 bytes in the hexadecimal so we only get our frequency data
             */

            for (int i = 4; i < ([data length] + 4); i += 8) {
                dataString = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", dataBytes[i - 1], dataBytes[i - 2], dataBytes[i - 3], dataBytes[i - 4]];
                formattedFrequency = atof([dataString UTF8String]) * 1e-6;
                
                [gpuStateFrequencies addObject:@(formattedFrequency)];
            }
        } else
            goto gpu_err;
        
        /* PCPU */
        
        if ((data = (__bridge NSData *) (CFDataRef) IORegistryEntryCreateCFProperty(entry, CFSTR("voltage-states1-sram"), kCFAllocatorDefault, 0))) {
            dataBytes = [data bytes];
            
            for (int i = 4; i < ([data length] + 4); i += 8) {
                dataString = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", dataBytes[i - 1], dataBytes[i - 2], dataBytes[i - 3], dataBytes[i - 4]];
                formattedFrequency = atof([dataString UTF8String]) * 1e-6;

                [eCpuStateFrequencies addObject:@(formattedFrequency)];
            }
        } else
            goto ecpu_err;
        
        /* ECPU */
        
        if ((data = (__bridge NSData *) (CFDataRef) IORegistryEntryCreateCFProperty(entry, CFSTR("voltage-states5-sram"), kCFAllocatorDefault, 0))) {
            dataBytes = [data bytes];
            
            for (int i = 4; i < ([data length] + 4); i += 8) {
                dataString = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", dataBytes[i - 1], dataBytes[i - 2], dataBytes[i - 3], dataBytes[i - 4]];
                formattedFrequency = atof([dataString UTF8String]) * 1e-6;
                
                [pCpuStateFrequencies addObject:@(formattedFrequency)];
            }
        } else
            goto pcpu_err;
        
    } else {
        goto err;
    }

    [allStateFrequencies addObject:pCpuStateFrequencies];
    [allStateFrequencies addObject:eCpuStateFrequencies];
    [allStateFrequencies addObject:gpuStateFrequencies];

    /*
     * no we'll have an array formatted something like this:
     *  idx 0 = PCPU freqs
     *  idx 1 = ECPU freqs
     *  idx 2 = GPU freqs
     */
    
    return allStateFrequencies;
    
err:
    errf("failed to access PMGR data from the registry");
    return NULL;
    
gpu_err:
    errf("failed to access GPU performance state frequencies from the registry");
    return NULL;
    
ecpu_err:
    errf("failed to access ECPU performance state frequencies from the registry");
    return NULL;
    
pcpu_err:
    errf("failed to access PCPU performance state frequencies from the registry");
    return NULL;
}

/* function for returning CPU cluster and GPU core counts */

NSMutableArray * generateCoreCountArray( void )
{
    mach_port_t         port = kIOMasterPortDefault;
    
    io_registry_entry_t cpuRegEntry;
    io_registry_entry_t gpuRegEntry;
    
    io_iterator_t       gpuIOIter;
    
    NSData *            data;
    NSString *          dataString;
    unsigned char *     dataBytes;

    CFMutableDictionaryRef gpuService;
    CFTypeRef           gpuCoreCount;
    
    NSMutableArray *    cores = [NSMutableArray array];
    
    /* using kIOMainPortDefault if on MacOS Monterey or newer */

    if (@available(macOS 12, *)) port = kIOMainPortDefault;
        
    /*
     * fetching CPU core count from the registry
     * this data is located in both the IODeviceTree and the IOService, so we just check for both entry locations in case one is missing in your system for some reason
     */
    
    if ((cpuRegEntry = IORegistryEntryFromPath(port, "IODeviceTree:/cpus")) || (cpuRegEntry = IORegistryEntryFromPath(port, "IOService:/AppleARMPE/cpus"))) {
        
        /* PCPU */
        
        if ((data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(cpuRegEntry, CFSTR("p-core-count"), kCFAllocatorDefault, 0))) {
            dataBytes  = [data bytes];
            dataString = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", dataBytes[3], dataBytes[2], dataBytes[1], dataBytes[0]];
            [cores addObject:[NSNumber numberWithInt:(int)atof([dataString UTF8String])]];
        } else {
            [cores addObject:[NSNumber numberWithInt:0]];
        }
        
        /* ECPU */
        
        if ((data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(cpuRegEntry, CFSTR("e-core-count"), kCFAllocatorDefault, 0))) {
            dataBytes  = [data bytes];
            dataString = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", dataBytes[3], dataBytes[2], dataBytes[1], dataBytes[0]];
            [cores addObject:[NSNumber numberWithInt:(int)atof([dataString UTF8String])]];
        } else {
            [cores addObject:[NSNumber numberWithInt:0]];
        }
        
    } else {
        [cores addObject:[NSNumber numberWithInt:0]];
        [cores addObject:[NSNumber numberWithInt:0]];
    }
    
    /*
     * fetching GPU core count from the registry by matching a service rather than creating an property from an entry
     * this way we aren't looking for a specific GPU name, which means this code should work on all silicon variants
     */
    
    if ((gpuService = IOServiceMatching("AGXAccelerator"))) {
        if (IOServiceGetMatchingServices(port, gpuService, &gpuIOIter) == kIOReturnSuccess) {
            while ((gpuRegEntry = IOIteratorNext(gpuIOIter)) != IO_OBJECT_NULL) {
                if ((gpuCoreCount = IORegistryEntrySearchCFProperty(gpuRegEntry, kIOServicePlane, CFSTR("gpu-core-count"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents)))
                    [cores addObject:[NSNumber numberWithInt:[(__bridge NSNumber *)gpuCoreCount intValue]]];
                else
                    [cores addObject:[NSNumber numberWithInt:0]];
            }
        } else {
            [cores addObject:[NSNumber numberWithInt:0]];
        }
    } else {
        [cores addObject:[NSNumber numberWithInt:0]];
    }
    
    /*
     * no we'll have an array formatted something like this:
     *  idx 0 = PCPU cores
     *  idx 1 = ECPU cores
     *  idx 2 = GPU cores
     */
    
    return cores;
}

/* detect the CPU name, code name, and cluster microarchitectures */

NSMutableArray * generateSiliconData( void )
{
    NSMutableArray *    siliconIDs = [NSMutableArray array];
  
    NSString *          cpuBrandString;
    char *              cpuBrand;
    
    char *              entry = "machdep.cpu.brand_string";
    size_t              len;
    
    if (sysctlbyname(entry, NULL, &len, NULL, 0) == -1)
        goto err;
    else {
        cpuBrand = malloc(len);
        sysctlbyname(entry, cpuBrand, &len, NULL, 0);
        
        cpuBrandString = [NSString stringWithFormat:@"%s", cpuBrand, nil];
        
        [siliconIDs addObject:cpuBrandString];
        
        /* generating the silicon code names */
        
        if ([cpuBrandString rangeOfString:@"Max"].location != NSNotFound)
            [siliconIDs addObject:@"T6001"];
        else if ([cpuBrandString rangeOfString:@"Pro"].location != NSNotFound)
            [siliconIDs addObject:@"T6000"];
        else if ([cpuBrandString isEqual: @"Apple M1"])
            [siliconIDs addObject:@"T8103"];
        else
            [siliconIDs addObject:@"T****"];
        
        /* generating cluster microarchitecture (setting M2 checking here early so I don't have to implement it later) */
        
        if ([cpuBrandString rangeOfString:@"M1"].location != NSNotFound) {
            [siliconIDs addObject:@"Icestorm"];
            [siliconIDs addObject:@"Firestorm"];
        } else if ([cpuBrandString rangeOfString:@"M2"].location != NSNotFound) {
            [siliconIDs addObject:@"Blizzard"];
            [siliconIDs addObject:@"Avalanche"];
        } else {
            [siliconIDs addObject:@"Unknown"];
            [siliconIDs addObject:@"Unknown"];
        }
    }
    
    /*
     * no we'll have an array formatted something like this:
     *  idx 0 = CPU name
     *  idx 1 = CPU code name
     *  idx 2 = ECPU cluster microarchitecture
     *  idx 3 = PCPU cluster microarchitecture
     */
    
    return siliconIDs;
    
err:
    errf("failed to identify CPU type");
    return NULL;
}

/* function to output our metrics */

void generateOutput( cmdOptions * cmdOptions )
{
    /* generating misc datas */
    
    NSMutableArray * allStateFrequencies    = generateStateFrequencies();
    NSMutableArray * coreCounts             = generateCoreCountArray();
    NSMutableArray * siliconData            = generateSiliconData();
    
    NSArray * pCpuClusterStateFreqs         = allStateFrequencies[0];
    NSArray * eCpuClusterStateFreqs         = allStateFrequencies[1];
    NSArray * gpuComplexStateFreqs          = allStateFrequencies[2];
    
    /* print our sampling header */
    
    printf("\n\e[1m*** Sampling: %s [%s] (%dP+%dE+%dGPU) ***\n\e[0m",
           [siliconData[0] UTF8String],
           [siliconData[1] UTF8String],
           [coreCounts[0] intValue],
           [coreCounts[1] intValue],
           [coreCounts[2] intValue]);
    
    
    char * stylize      = "\e[0;35m";
    char * destylize    = "\e[0m";
    
    int coreCounter     = 0;
    
    rawSampleData rawSampleData;
    formattedSampleData formattedSampleData;

    /* initializing all of our NSMutableArrays so we can inject data into them */
    
    rawSampleData.gpuComplexFirstSample             = [NSMutableArray array];
    rawSampleData.gpuComplexLastSample              = [NSMutableArray array];
    
    rawSampleData.eCpuComplexFirstSample            = [NSMutableArray array];
    rawSampleData.eCpuComplexLastSample             = [NSMutableArray array];
    rawSampleData.eCpuCoreFirstSample               = [NSMutableArray array];
    rawSampleData.eCpuCoreLastSample                = [NSMutableArray array];
    
    rawSampleData.pCpuComplexFirstSample            = [NSMutableArray array];
    rawSampleData.pCpuComplexLastSample             = [NSMutableArray array];
    rawSampleData.pCpuCoreFirstSample               = [NSMutableArray array];
    rawSampleData.pCpuCoreLastSample                = [NSMutableArray array];
    
    formattedSampleData.gpuComplexStateResidency    = [NSMutableArray array];
    formattedSampleData.eCpuComplexStateResidency   = [NSMutableArray array];
    formattedSampleData.pCpuComplexStateResidency   = [NSMutableArray array];
    
    formattedSampleData.eCpuCoreFrequencies         = [NSMutableArray array];
    formattedSampleData.pCpuCoreFrequencies         = [NSMutableArray array];
    
    formattedSampleData.eCpuCoreIdleResidencies     = [NSMutableArray array];
    formattedSampleData.pCpuCoreIdleResidencies     = [NSMutableArray array];
    
    /* initializing our frequency vars so we don't end up with massive miscalculated values */
    
    formattedSampleData.gpuComplexFrequency         = 0;
    formattedSampleData.eCpuComplexFrequency        = 0;
    formattedSampleData.pCpuComplexFrequency        = 0;
    
    while(cmdOptions->looper < cmdOptions->looperKey) {
        
        /* injecting sample data into our struct */
        
        IOReportInjectRawSampleData(cmdOptions->samplerate,
                                    [coreCounts[1] intValue],
                                    [coreCounts[0] intValue],
                                    &rawSampleData);

        /* formatting our injected data */
        
        IOReportFormatRawSampleData(eCpuClusterStateFreqs,
                                    pCpuClusterStateFreqs,
                                    gpuComplexStateFreqs,
                                    [coreCounts[1] intValue],
                                    [coreCounts[0] intValue],
                                    &rawSampleData,
                                    &formattedSampleData);
        
        
        /* printing all of our datas for each group */

        /* ECPU */
        
        if (cmdOptions->all == true || cmdOptions->ecpu == true) {
            
            printf("\e[1m\n**** \"%s\" Efficiency Cluster Metrics ****\n\n\e[0m", [siliconData[2] UTF8String]);
            
            printf("E-Cluster [0]  HW Active Frequency:%s %.f MHz%s\n", stylize, formattedSampleData.eCpuComplexFrequency, destylize);
            printf("E-Cluster [0]  HW Active Residency:%s %.3f%%%s\n", stylize, 100 - formattedSampleData.eCpuComplexIdleResidency, destylize);
            printf("E-Cluster [0]  Idle Frequency:%s      %.3f%%%s\n", stylize, formattedSampleData.eCpuComplexIdleResidency, destylize);
            
            if (cmdOptions->hidecores == false) {
                
                printf("\n");
            
                for (int i = 0; i < [coreCounts[1] intValue]; i++) {
                    printf("  Core %d:\n", coreCounter);
                    printf("          Active Frequency:%s %.f MHz%s\n", stylize, [formattedSampleData.eCpuCoreFrequencies[i] floatValue], destylize);
                    printf("          Active Residency:%s %.3f%%%s\n", stylize, 100 - [formattedSampleData.eCpuCoreIdleResidencies[i] floatValue], destylize);
                    printf("          Idle Residency:%s   %.3f%%%s\n", stylize, [formattedSampleData.eCpuCoreIdleResidencies[i] floatValue], destylize);
                    
                    coreCounter++;
                }
            }
            
            if (cmdOptions->statefreqs == true) {
                
                printf("\nE-Cluster [0]  State Distribution: (");

                for (int i = 1; i < 6; i++)
                    printf("%.f: %s%.1f%%%s, ", [eCpuClusterStateFreqs[i] floatValue], stylize, 100 * [formattedSampleData.eCpuComplexStateResidency[i-1] floatValue], destylize);
                
                printf("\b\b)\n");
            }
        }
        
        /* PCPU */
        
        if (cmdOptions->all == true || cmdOptions->pcpu == true) {
        
            printf("\e[1m\n**** \"%s\" Performance Cluster Metrics ****\n\n\e[0m", [siliconData[3] UTF8String]);
            
            printf("P-Cluster [0]  HW Active Frequency:%s %.f MHz%s\n", stylize, formattedSampleData.pCpuComplexFrequency, destylize);
            printf("P-Cluster [0]  HW Active Residency:%s %.3f%%%s\n", stylize, 100 - formattedSampleData.pCpuComplexIdleResidency, destylize);
            printf("P-Cluster [0]  Idle Frequency:%s      %.3f%%%s\n", stylize, formattedSampleData.pCpuComplexIdleResidency, destylize);
            
            if (cmdOptions->hidecores == false) {
                
                printf("\n");
        
                for (int i = 0; i < [coreCounts[0] intValue]; i++) {
                    printf("  Core %d:\n", coreCounter);
                    printf("          Active Frequency:%s %.f MHz%s\n", stylize, [formattedSampleData.pCpuCoreFrequencies[i] floatValue], destylize);
                    printf("          Active Residency:%s %.3f%%%s\n", stylize, 100 - [formattedSampleData.pCpuCoreIdleResidencies[i] floatValue], destylize);
                    printf("          Idle Residency:%s   %.3f%%%s\n", stylize, [formattedSampleData.pCpuCoreIdleResidencies[i] floatValue], destylize);
                    
                    coreCounter++;
                }
            }
            
            if (cmdOptions->statefreqs == true) {
        
                printf("\nP-Cluster [0]  State Distribution: (");

                for (int i = 1; i < 16; i++)
                    printf("%.f: %s%.1f%%%s, ", [pCpuClusterStateFreqs[i] floatValue], stylize, 100 * [formattedSampleData.pCpuComplexStateResidency[i-1] floatValue], destylize);
                
                printf("\b\b)\n");
            }
        }
        
        /* GPU */
        
        if (cmdOptions->all == true || cmdOptions->gpu == true) {
        
            printf("\e[1m\n**** Integrated Graphics Metrics ****\n\n\e[0m");
            
            printf("GPU  Active Frequency:%s %.f MHz%s\n", stylize, formattedSampleData.gpuComplexFrequency, destylize);
            printf("GPU  Active Residency:%s %.3f%%%s\n", stylize, 100 - formattedSampleData.gpuComplexIdleResidency, destylize);
            printf("GPU  Idle Frequency:%s   %.3f%%%s\n", stylize, formattedSampleData.gpuComplexIdleResidency, destylize);
            
            if (cmdOptions->statefreqs == true) {
            
                printf("\nGPU  State Distribution: (");

                for (int i = 1; i < 6; i++)
                    printf("%.f: %s%.1f%%%s, ", [gpuComplexStateFreqs[i] floatValue], stylize, 100 * [formattedSampleData.gpuComplexStateResidency[i-1] floatValue], destylize);
                
                printf("\b\b)\n");
            }
        }
        
        
        /* destroying all previous data */
        
        [rawSampleData.gpuComplexFirstSample removeAllObjects];
        [rawSampleData.gpuComplexLastSample removeAllObjects];
        
        [rawSampleData.eCpuComplexFirstSample removeAllObjects];
        [rawSampleData.eCpuComplexLastSample removeAllObjects];
        [rawSampleData.eCpuCoreFirstSample removeAllObjects];
        [rawSampleData.eCpuCoreLastSample removeAllObjects];
        
        [rawSampleData.pCpuComplexFirstSample removeAllObjects];
        [rawSampleData.pCpuComplexLastSample removeAllObjects];
        [rawSampleData.pCpuCoreFirstSample removeAllObjects];
        [rawSampleData.pCpuCoreLastSample removeAllObjects];
        
        [formattedSampleData.gpuComplexStateResidency removeAllObjects];
        [formattedSampleData.eCpuComplexStateResidency removeAllObjects];
        [formattedSampleData.pCpuComplexStateResidency removeAllObjects];
        
        [formattedSampleData.eCpuCoreFrequencies removeAllObjects];
        [formattedSampleData.pCpuCoreFrequencies removeAllObjects];
        
        [formattedSampleData.eCpuCoreIdleResidencies removeAllObjects];
        [formattedSampleData.pCpuCoreIdleResidencies removeAllObjects];
        
        formattedSampleData.gpuComplexFrequency         = 0;
        formattedSampleData.eCpuComplexFrequency        = 0;
        formattedSampleData.pCpuComplexFrequency        = 0;
            
        coreCounter = 0;
        
        if (cmdOptions->islooping == false || cmdOptions->looprate > 0)
            cmdOptions->looper++;
    }
}

/* function for 'help' output */

void generateHelpOutput( void )
{
    printf("\e[1m\nUsage: %s [-l loop_count] [-i sample_interval]\n\n\e[0m", name);
    
    printf("  This project is designed to retrieve active frequency and residency metrics\n");
    printf("  from your Macs CPU (per-core, per-cluster) and GPU (complex) as accurately as\n");
    printf("  possible, without requiring sudo or a kernel extension. \n\n");
    
    printf("  Made with love by BitesPotatoBacks\n\n");
    
    printf("\e[1mThe following command-line options are supported:\n\n\e[0m");

    printf("  -h | --help             show this message\n");
    printf("  -v | --version          print version number\n\n");
    
    printf("  -l | --loop-rate <N>    set output loop rate (0=infinite) [default: disabled]\n");
    printf("  -i | --sample-rate <N>  set data sampling interval [default: 1000ms]\n\n");
    
    printf("  -e | --ecpu-only        only show E-Cluster frequency and residency metrics\n");
    printf("  -p | --pcpu-only        only show P-Cluster frequency and residency metrics\n");
    printf("  -g | --gpu-only         only show GPU complex frequency and residency metrics\n\n");
    
    printf("  -c | --hide-cores       hide per-core frequency and residency metrics\n");
    printf("  -s | --state-freqs      show state frequency distributions for all groups\n");
    
    printf("\n");
}


int main(int argc, char * argv[])
{
    cmdOptions cmdOptions;
    
    cmdOptions.all          = true;
    
    cmdOptions.ecpu         = false;
    cmdOptions.pcpu         = false;
    cmdOptions.gpu          = false;
    
    cmdOptions.hidecores    = false;
    cmdOptions.statefreqs = false;
    cmdOptions.islooping    = false;
    
    cmdOptions.looprate     = 0;
    cmdOptions.samplerate   = 1000;
    
    cmdOptions.looper       = 0;
    cmdOptions.looperKey    = 0;
    
    
    struct option longCmdOpts[] = {
        { "help",           no_argument,       0, 'h' },
        { "version",        no_argument,       0, 'v' },
        
        { "loop-rate",      required_argument, 0, 'l' },
        { "sample-rate",    required_argument, 0, 'i' },
        
        { "ecpu-only",      no_argument,       0, 'e' },
        { "pcpu-only",      no_argument,       0, 'p' },
        { "gpu-only",       no_argument,       0, 'g' },
        
        { "hide-cores",     no_argument,       0, 'c' },
        { "state-freqs",    no_argument,       0, 's' },
        { NULL,             0,                 0,  0  }
    };
    
    
    int     option;
    int     optionIndex;
    
    /* command line option handling */
    
    while((option = getopt_long(argc, argv, "hvl:i:epgcs", longCmdOpts, &optionIndex)) != -1)
    {
        switch(option)
        {
            default:
                    cmdOptions.all = true;
                    break;
            case 'h':
                    generateHelpOutput();
                    return 0;
                    break;
            case 'v':
                    printf("\e[1m%s\e[0m: %s version %s\n", name, type, version);
                    return 0;
                    break;
            case 'l':
                    cmdOptions.looprate = atoi(optarg);
                    cmdOptions.islooping = true;
                    break;
            case 'i':
                    cmdOptions.samplerate = atoi(optarg);
                    break;
            case 'e':
                    cmdOptions.ecpu = true;
                    cmdOptions.all = false;
                    break;
            case 'p':
                    cmdOptions.pcpu = true;
                    cmdOptions.all = false;
                    break;
            case 'g':
                    cmdOptions.gpu = true;
                    cmdOptions.all = false;
                    break;
            case 'c':
                    cmdOptions.hidecores = true;
                    break;
            case 's':
                    cmdOptions.statefreqs = true;
                    break;
        }
    }
    
    if (cmdOptions.samplerate < 1)
        errf("sampling interval must be a value larger than 1 millisecond");
    
    if (cmdOptions.looprate < 0)
        errf("output looping rate must be a non-negative integer");
    
    if (cmdOptions.islooping == false)
        cmdOptions.looperKey = 1;
    else {
        if (cmdOptions.looprate == 0) {
            cmdOptions.looperKey = 1;
            
            if (cmdOptions.samplerate == 0)
                cmdOptions.samplerate = 1000;
        } else
            cmdOptions.looperKey = cmdOptions.looprate;
    }
    
    /* outputting all of our metrics! */
    
    generateOutput(&cmdOptions);

    return 0;
}
