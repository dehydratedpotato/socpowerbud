/*
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
#include <mach/processor_info.h>
#include <mach/mach_time.h>
#include <sys/sysctl.h>
#include <getopt.h>
#include <stdarg.h>

/* macros and struct datas */

#define name        "SFMRM"
#define type        "x86_64-client"
#define version     "0.1.0"

typedef struct {
    bool    islooping;
    
    int     looprate;
    int     samplerate;
    
    int     looper;
    int     looperKey;
    
    bool    all;
    
    bool    pkg;
    bool    gpu;
    
    bool    hidecores;
} cmdOptions;

/* special functions for clang style error and warning reporting */
 
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

void warnf( const char * format, ... )
{
    va_list args;
    fprintf(stderr, "\e[1m%s:\033[0;35m warning:\033[0m\e[0m ", name);
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
}

/* easy access sysctl functions */

char * sysctlbynameChar(char * entry)
{
    char * variable = NULL;
    size_t len;
    
    if (sysctlbyname(entry, NULL, &len, NULL, 0) != -1) {
        variable = malloc(len);
        sysctlbyname(entry, variable, &len, NULL, 0);
    } else
        errf("invalid output from sysctl");
    
    return variable;
}

uint64_t sysctlbynameUint64_t(char * entry)
{
    uint64_t variable  = 0;
    size_t len         = sizeof(variable);
    
    if (sysctlbyname(entry, NULL, &len, NULL, 0) != -1) {
        sysctlbyname(entry, &variable, &len, NULL, 0);
    } else
        errf("invalid output from sysctl");
    
    return variable;
}

int sysctlbynameInt(char * entry)
{
    int variable  = 0;
    size_t len    = 4;
    
    if (sysctlbyname(entry, NULL, &len, NULL, 0) != -1) {
        sysctlbyname(entry, &variable, &len, NULL, 0);
    } else
        errf("invalid output from sysctl");
    
    return variable;
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
extern long IOReportSimpleGetIntegerValue(CFDictionaryRef, int);
extern NSString* IOReportChannelGetChannelName(CFDictionaryRef);
extern NSString* IOReportChannelGetSubGroup(CFDictionaryRef);

/* measure the CPUs active frequnecy */

float cpuGenerateFrequencyMetrics( int sampleType, float curState, float maximumTurboFrequency  )
{
    float cpuFrequency;
    
    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    size_t cycles;
    
    /*
     * here we estimate the frequnecy using some tight loops...
     *
     * this method can only calculate the frequency of the package, it is incapable of measuring the core speed (if only macOS let us set thread affinities),
     * but because of behaviors with identical frequencies across active cores in a package (core specific turbo boosts being an exception), we can just
     * regurgitate a resampled package frequency as a core speed (that is, unless the core is inactive). This will be the implementation until we can access
     * P-State distributions without needing kernal privileges or sudo.
     */
    
    double magicNumber = (double) info.numer / (double) info.denom;
    
    /* first measure */

    uint64_t firstSampleBegin = mach_absolute_time();

    cycles = 262144;
    asm volatile("firstmeasure:\ndec %[counter]\njnz firstmeasure\n " : [counter] "+r"(cycles));

    uint64_t firstSampleEnd = mach_absolute_time();
    double firstTiming = (double) (firstSampleEnd - firstSampleBegin) * magicNumber;
    
    /* last measure */
    
    uint64_t lastSampleBegin = mach_absolute_time();

    cycles = 131072;
    asm volatile("lastmeasure:\ndec %[counter]\njnz lastmeasure\n " : [counter] "+r"(cycles));

    uint64_t lastSampleEnd = mach_absolute_time();
    double lastTiming = (double) (lastSampleEnd - lastSampleBegin) * magicNumber;
    double totalTiming = (firstTiming - lastTiming);
    
    cpuFrequency = (float) (131072 / totalTiming) * 1e+3;
    
    /* making sure we don't return unrealistic values... */
    
    if (cpuFrequency > maximumTurboFrequency)
        cpuFrequency = maximumTurboFrequency;
    else if (cpuFrequency < 800)
        cpuFrequency = 800;
    
    if (sampleType == 1 && curState <= 0.0005555)
        cpuFrequency = 0;

    return cpuFrequency;
}

/* calculate the CPU usage */

NSMutableArray * cpuGenerateResidencyMetrics( int interval, natural_t coreCount )
{
    NSMutableArray *        uses            = [NSMutableArray array];
    
    processor_info_array_t  firstSample,
                            lastSample;
    
    mach_msg_type_number_t  processorMsgCount;
    
    float                   totalUsage      = 0,
                            totalTicks      = 0,
                            idleResidency   = 0,
                            idleAverage     = 0;
    
    /* accessing per-core tick values form host processor info */

    if (host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &coreCount, &firstSample, &processorMsgCount) == KERN_SUCCESS) {
        [NSThread sleepForTimeInterval:(interval * 1e-3)];
        
        if (host_processor_info(mach_host_self(), PROCESSOR_CPU_LOAD_INFO, &coreCount, &lastSample, &processorMsgCount) == KERN_SUCCESS) {
            
            /* formatting all of our datas */
            
            for (int i = 0; i < coreCount; i++) {

                totalUsage = ((lastSample[(CPU_STATE_MAX * i) + CPU_STATE_USER] - firstSample[(CPU_STATE_MAX * i) + CPU_STATE_USER]) +
                        (lastSample[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM] - firstSample[(CPU_STATE_MAX * i) + CPU_STATE_SYSTEM]) +
                        (lastSample[(CPU_STATE_MAX * i) + CPU_STATE_NICE]   - firstSample[(CPU_STATE_MAX * i) + CPU_STATE_NICE]));

                totalTicks = totalUsage + (lastSample[(CPU_STATE_MAX * i) + CPU_STATE_IDLE] - firstSample[(CPU_STATE_MAX * i) + CPU_STATE_IDLE]);
                
                idleResidency = (float) totalUsage / (float) totalTicks * 100;
                
                if (!(isnormal(idleResidency)))
                    idleResidency = 0;
                
                idleAverage += idleResidency;

                [uses addObject:@(idleResidency)];
            }
            
            [uses addObject:@(idleAverage / coreCount)];
        } else
            goto err;
    } else
        goto err;

    /*
     * no we'll have an array formatted something like this:
     *  idx 0 = Core 0 idle %
     *  idx 1 = Core 1 idle %
     *  idx 2 = Core 2 idle %
     *  ...
     *  idx N = CPU PKG idle %
     */
    
    return uses;
    
err:
    errf("failed to access CPU core residencies from host info");
    return NULL;
}

/* calculate the GPU usage */

float gpuGenerateResidencyMetrics ( void )
{
    mach_port_t         port = kIOMasterPortDefault;
    io_registry_entry_t entry;
    
    NSMutableArray *    performanceStatistics = [NSMutableArray array];
    
    /* using kIOMainPortDefault if on MacOS Monterey or newer */
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;
    
    /* accessing the IntelAccelerator IGPU entry from the registry */
    
    if ((entry = IORegistryEntryFromPath(port, "IOService:/AppleACPIPlatformExpert/PCI0/AppleACPIPCI/IGPU/IntelAccelerator"))) {
        
        /* accessing the performance statistics so we can get the device utilization  */
        
        if ((performanceStatistics = (__bridge NSMutableArray *) IORegistryEntryCreateCFProperty(entry, CFSTR("PerformanceStatistics"), kCFAllocatorDefault, 0))) {
            
            return [[performanceStatistics valueForKey:@"Device Utilization %"] floatValue];
        } else
            goto err;
    } else
        goto err;

err:
    errf("failed to access GPU utilization from the registry");
    return 0;
}


/* get the maximum turbo boost speed of the CPU */

float cpuGenerateMaximumTurboBoost( void )
{
    mach_port_t         port = kIOMasterPortDefault;

    io_registry_entry_t entry;

    NSMutableArray *    plimitArray     = [NSMutableArray array];
    NSMutableArray *    pstateArray     = [NSMutableArray array];
    
    float               turboSpeed      = 0;
    int                 limitedBoost    = 0;
    
    /* using kIOMainPortDefault if on MacOS Monterey or newer */

    if (@available(macOS 12, *)) port = kIOMainPortDefault;
    
    /* accessing the x86 platform plugin entry in the registry so we can pull P-State information */
    
    if ((entry = IORegistryEntryFromPath(port, "IOService:/AppleACPIPlatformExpert/CPU0/AppleACPICPU/X86PlatformPlugin"))) {
        
        /* looking for what P-State the CPU is limited to turbo to */
        
        if ((plimitArray = (__bridge NSMutableArray *) IORegistryEntryCreateCFProperty(entry, CFSTR("IOPPFDiagDict"), kCFAllocatorDefault, 0)))
            limitedBoost = [[[plimitArray valueForKey:@"CPUPLimitDict"] valueForKey:@"currentLimit"] intValue];
        else
            goto plimit_err;
        
        /* looking for that limited P-State... */
        
        if ((pstateArray = (__bridge NSMutableArray *) IORegistryEntryCreateCFProperty(entry, CFSTR("CPUPStates"), kCFAllocatorDefault, 0)))
            turboSpeed = [[pstateArray[limitedBoost] valueForKey:@"Frequency"] floatValue];
        else
            goto pstate_err;
        
    } else
        goto pstate_err;
    
    /* now we should have a dictionary with all of our active performance limiter keys and values! */

    return turboSpeed;
    
plimit_err:
    errf("failed to access turbo boost limit information from the registry");
    return 0;
    
pstate_err:
    errf("failed to access P-State information from the registry");
    return 0;
}


/* access CPU or GPU performance limiters from the IOReport */

NSMutableDictionary * IOReportGetPerformanceLimiters( int group )
{
    CFDictionaryRef         statsSamples         = NULL;
    CFMutableDictionaryRef  statsChannels        = NULL,
                            statsSubbedChannels  = NULL;
    
    IOReportSubscriptionRef statsSubscription    = NULL;
    
    NSMutableDictionary *   performanceLimiters  = [NSMutableDictionary dictionary];
    
    /* accessing performance limiters for the CPU and GPU from the pmtelemetry_cpu group in the registry */
    
    if (!(statsChannels = IOReportCopyChannelsInGroup(@"pmtelemetry_cpu", 0, 0, 0, 0)))
        goto err;
    
    if (!(statsSubscription = IOReportCreateSubscription(NULL, statsChannels, &statsSubbedChannels, 0, 0)))
        goto err;
    
    if ((statsSamples = IOReportCreateSamples(statsSubscription, statsSubbedChannels, NULL))) {
        IOReportIterate(statsSamples, ^(IOReportSampleRef ch) {
                
                if ([IOReportChannelGetSubGroup(ch) isEqual: @"msr limits"]) {
                    
                    if (IOReportSimpleGetIntegerValue(ch, 0) > 0) {
                        switch(group) {
                            default:
                            case 0: if ([IOReportChannelGetChannelName(ch) rangeOfString:@"CPU"].location != NSNotFound)
                                        [performanceLimiters setValue:[NSNumber numberWithLong:IOReportSimpleGetIntegerValue(ch, 0)] forKey:[IOReportChannelGetChannelName(ch) stringByReplacingOccurrencesOfString:@"CPU LIMIT " withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [IOReportChannelGetChannelName(ch) length])]]; break;
                                
                            case 1: if ([IOReportChannelGetChannelName(ch) rangeOfString:@"GPU"].location != NSNotFound)
                                        [performanceLimiters setValue:[NSNumber numberWithLong:IOReportSimpleGetIntegerValue(ch, 0)] forKey:[IOReportChannelGetChannelName(ch) stringByReplacingOccurrencesOfString:@"GPU LIMIT " withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [IOReportChannelGetChannelName(ch) length])]]; break;
                        }
                    }
                }

            return kIOReportIterOk;
        });
    } else
        goto err;
    
    return performanceLimiters;
    
err:
    errf("failed to access performance limiters from the registry");
    return NULL;
}

void generateOutput( cmdOptions * cmdOptions )
{
    NSMutableDictionary * cpuPLimiters              = [NSMutableDictionary dictionary],
                        * gpuPLimiters              = [NSMutableDictionary dictionary];
    
    NSMutableArray *    cpuActiveResidencies        = [NSMutableArray array],
                   *    cpuPLimtersSortedKeys       = [NSMutableArray array],
                   *    gpuPLimtersSortedKeys       = [NSMutableArray array];
    
    NSArray *           cpuPLimitersSortedValues    = [NSArray array],
            *           gpuPLimitersSortedValues    = [NSArray array];
    
    NSOrderedSet *      cpuPLimitersUniqueValues,
                 *      gpuPLimitersUniqueValues;
    
    int                 cpuCoreCount        = sysctlbynameInt("hw.logicalcpu");
    
    float               turboBoostSpeed;
    float               gpuActiveResidency  = 0;
    
    char * stylize      = "\e[0;35m";
    char * destylize    = "\e[0m";
    
    
    /* print our sampling header */
    
    printf("\n\e[1m*** Sampling: %s ***\n\e[0m", sysctlbynameChar("machdep.cpu.brand_string"));
    
    
    while(cmdOptions->looper < cmdOptions->looperKey) {
        
        /*
         * accessing and formatting performance limiters here...
         * we do this so our values are in order of least to greatest, that way we know whether the system is actually being limited
         */
        
        cpuPLimiters = IOReportGetPerformanceLimiters(0);
        gpuPLimiters = IOReportGetPerformanceLimiters(1);
        
        cpuPLimitersSortedValues    = [[cpuPLimiters allValues] sortedArrayUsingSelector:@selector(compare:)];
        gpuPLimitersSortedValues    = [[gpuPLimiters allValues] sortedArrayUsingSelector:@selector(compare:)];
        
        cpuPLimitersUniqueValues    = [NSOrderedSet orderedSetWithArray:cpuPLimitersSortedValues];
        gpuPLimitersUniqueValues    = [NSOrderedSet orderedSetWithArray:gpuPLimitersSortedValues];
        
        cpuPLimtersSortedKeys       = [NSMutableArray arrayWithCapacity:[cpuPLimiters count]];
        gpuPLimtersSortedKeys       = [NSMutableArray arrayWithCapacity:[cpuPLimiters count]];
        
        for (id value in cpuPLimitersUniqueValues) {
            NSArray * cpuKeys = [cpuPLimiters allKeysForObject:value];
            [cpuPLimtersSortedKeys addObjectsFromArray:[cpuKeys sortedArrayUsingSelector:@selector(compare:)]];
        }
        
        for (id value in gpuPLimitersUniqueValues) {
            NSArray * gpuKeys = [gpuPLimiters allKeysForObject:value];
            [gpuPLimtersSortedKeys addObjectsFromArray:[gpuKeys sortedArrayUsingSelector:@selector(compare:)]];
        }
        
        /* pulling and printing all of our datas for each group */
        
        gpuActiveResidency    = gpuGenerateResidencyMetrics();
        cpuActiveResidencies  = cpuGenerateResidencyMetrics(cmdOptions->samplerate, (natural_t) cpuCoreCount);
        turboBoostSpeed       = cpuGenerateMaximumTurboBoost();

        /* Package */
        
        if (cmdOptions->all == true || cmdOptions->pkg == true) {
            
            printf("\e[1m\n**** Package Metrics ****\n\n\e[0m");
            
            printf("Package  Performance Limiters:%s %s", stylize, [[NSString stringWithFormat:@"%@", [cpuPLimtersSortedKeys lastObject]] UTF8String]); // breaks without NSString

            for (int i = 0; i < [cpuPLimtersSortedKeys count] - 1; i++) {
                if ([cpuPLimitersSortedValues[i] intValue] == [[cpuPLimitersSortedValues lastObject] intValue])
                    printf(", %s", [[NSString stringWithFormat:@"%@", cpuPLimtersSortedKeys[i]] UTF8String]);
            }

            printf("%s\n", destylize);

            printf("Package  Maximum Turbo Boost:%s  %.f MHz%s\n\n", stylize, turboBoostSpeed, destylize);
            
            printf("Package  Active Frequency:%s %.f MHz%s\n", stylize, cpuGenerateFrequencyMetrics(0, 0, turboBoostSpeed), destylize);
            printf("Package  Active Residency:%s %.2f%% %s\n", stylize, [cpuActiveResidencies[[cpuActiveResidencies count] - 1] floatValue], destylize);
            printf("Package  Idle Residency:%s   %.2f%% %s\n", stylize, 100 - [cpuActiveResidencies[[cpuActiveResidencies count] - 1] floatValue], destylize);
            
            [cpuActiveResidencies removeLastObject];
            
            if (cmdOptions->hidecores == false) {
                
                printf("\n");
            
                for (int i = 0; i < cpuCoreCount; i++) {
                    
                    printf("  Core %d:\n", i);
                    printf("          Active Frequency:%s %.f MHz%s\n", stylize, cpuGenerateFrequencyMetrics(1, [cpuActiveResidencies[i] floatValue], turboBoostSpeed), destylize);
                    printf("          Active Residency:%s %.2f%% %s\n", stylize, [cpuActiveResidencies[i] floatValue], destylize);
                    printf("          Idle Residency:%s   %.2f%% %s\n", stylize, 100 - [cpuActiveResidencies[i] floatValue], destylize);
                }
            }
        }
        
        /* iGPU */
        
        if (cmdOptions->all == true || cmdOptions->gpu == true) {
        
            printf("\e[1m\n**** Integrated Graphics Metrics ****\n\n\e[0m");
            
            printf("iGPU  Performance Limiters:%s %s", stylize, [[NSString stringWithFormat:@"%@", [gpuPLimtersSortedKeys lastObject]] UTF8String]);  // breaks without NSString

            for (int i = 0; i < [gpuPLimtersSortedKeys count] - 1; i++) {
                if ([gpuPLimitersSortedValues[i] intValue] == [[gpuPLimitersSortedValues lastObject] intValue])
                    printf(", %s", [[NSString stringWithFormat:@"%@", gpuPLimtersSortedKeys[i]] UTF8String]);
            }

            printf("%s\n\n", destylize);
            
            //printf("iGPU  Max Dynamic Frequency:%s %s\n\n%s", stylize, "2", destylize);
            
            printf("iGPU  Active Residency:%s %.2f%%%s\n", stylize, gpuActiveResidency, destylize);
            printf("iGPU  Idle Frequency:%s   %.2f%%%s\n", stylize, 100 - gpuActiveResidency, destylize);
        }
        
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
    
    printf("  -p | --pkg-only         only show CPU Package frequency and residency metrics\n");
    printf("  -g | --gpu-only         only show GPU complex residency metrics\n\n");
    
    printf("  -c | --hide-cores       hide per-core frequency and residency metrics\n");
    
    printf("\n");
}


int main(int argc, char * argv[])
{
    cmdOptions cmdOptions;
    
    cmdOptions.all          = true;
    
    cmdOptions.pkg          = false;
    cmdOptions.gpu          = false;
    
    cmdOptions.hidecores    = false;
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
        
        { "pkg-only",       no_argument,       0, 'e' },
        { "gpu-only",       no_argument,       0, 'g' },
        
        { "hide-cores",     no_argument,       0, 'c' },
        { NULL,             0,                 0,  0  }
    };
    
    
    int     option;
    int     optionIndex;
    
    /* command line option handling */
    
    while((option = getopt_long(argc, argv, "hvl:i:pgc", longCmdOpts, &optionIndex)) != -1)
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
            case 'p':
                    cmdOptions.pkg = true;
                    cmdOptions.all = false;
                    break;
            case 'g':
                    cmdOptions.gpu = true;
                    cmdOptions.all = false;
                    break;
            case 'c':
                    cmdOptions.hidecores = true;
                    break;
        }
    }
    
    if (cmdOptions.samplerate < 1)
        errf("sampling interval must be a value larger than 1 millisecond");
    
    if (cmdOptions.samplerate <= 50)
        warnf("sampling interval very low (%d ms), accuracy may be affected", cmdOptions.samplerate);
    
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
}
