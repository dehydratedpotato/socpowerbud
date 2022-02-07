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
//

#include <Foundation/Foundation.h>
#include <mach/mach_time.h>
#include <sys/sysctl.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#define ERROR(error)    { printf("%s: %s\n", "osx-cpufreq", error); exit(-1); }

#if defined(__x86_64__)

#include <x86intrin.h>

#define FIRST_CYCLE_MEASURE { asm volatile("firstmeasure:\ndec %[counter]\njnz firstmeasure\n " : [counter] "+r"(cycles)); }
#define LAST_CYCLE_MEASURE { asm volatile("lastmeasure:\ndec %[counter]\njnz lastmeasure\n " : [counter] "+r"(cycles)); }

#endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

struct options
{
    bool all;
    bool e_cores;
    bool p_cores;
    bool cores;
    bool cluster;
    int interval;
    bool average;
    bool r_average;
    bool looping;
    int loop;
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int get_sysctl(char * entry);

NSMutableArray * get_cpu_states(char cpu_cluster, int cpu_sub_group, int cpu_core);
NSMutableArray * get_cpu_nominal_freqs(char cpu_cluster);

void  print_cpu_freq_info(bool cluster, char cpu_cluster, int cpu_sub_group, int cpu_count, NSArray * cpu_nominal_freqs, int interval);
float return_cpu_active_freq(char cpu_cluster, int cpu_sub_group, int cpu_core, int interval, NSArray * cpu_nominal_freqs);
float return_cpu_avg_freq(int interval);
float return_cpu_max_freq(char cpu_cluster);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

enum { kIOReportIterOk };

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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int main(int argc, char * argv[])
{
    struct options  options;
    int             option;
    int             looper = 0;
    int             counterLooper = 0;
    
    options.all         = true;
    options.e_cores     = false;
    options.p_cores     = false;
    options.cores       = false;
    options.cluster     = false;
    options.average     = false;
    options.r_average   = false;
    options.looping     = false;
    options.loop        = 0;
    options.interval    = 1;
    
    while((option = getopt(argc, argv, "i:l:cepqravh")) != -1)
    {
        switch(option)
        {
            default:    options.all = true;
                        break;
                
            case 'l':   options.loop = atoi(optarg);
                        options.looping = true;
                        break;
                
            case 'i':   options.interval = atoi(optarg);
                        break;
                
            case 'c':   options.cores = true;
                        options.all = false;
                        break;
                
            case 'e':   options.e_cores = true;
                        options.all = false;
                        break;
            case 'p':   options.p_cores = true;
                        options.all = false;
                        break;
                
            case 'q':   options.cluster = true;
                        options.all = false;
                        break;
                
            case 'r':   options.r_average = true;
                        break;
                
            case 'a':   options.average = true;
                        options.all = false;
                        break;
                
            case 'v':   printf("%s: version 2.1.0\n", "osx-cpufreq");
                        return 0;
                        break;
                
            case 'h':   printf("Usage: %s [-licepqravh]\n", "osx-cpufreq");
                        printf("    -l <value> : loop output (0 = infinite)\n");
                        printf("    -i <value> : set sampling interval (may effect accuracy)\n");
                        printf("    -c         : print frequency information for all cores         (arm64)\n");
                        printf("    -e         : print frequency information for efficiency cores  (arm64)\n");
                        printf("    -p         : print frequency information for performance cores (arm64)\n");
                        printf("    -q         : print frequency information for all clusters\n");
                        printf("    -r         : remove average frequency estimation from output   (arm64)\n");
                        printf("    -a         : print average frequency estimation only\n");
                        printf("    -v         : print version number\n");
                        printf("    -h         : help\n");
                        return 0;
                        break;
        }
    }
    
    if (options.looping == false)
    {
       counterLooper = 1;
    }
    else
    {
        if (options.loop == 0)
        {
            counterLooper = 1;
        }
        else
        {
            counterLooper = options.loop;
        }
    }

    #if defined(__x86_64__)
    
    float           cpu_active_freq;
    float           cpu_max_freq      = return_cpu_max_freq(0);
    
    if (options.cores == true || options.e_cores == true || options.p_cores == true || options.r_average == true)
    {
        ERROR("command line option used not yet supported on x86");
    }
    
    printf("\e[1m\n%s%9s%14s%16s%10s\n\n\e[0m", "Name", "Type", "Max Freq", "Active Freq", "Freq %");
    
    while(looper < counterLooper)
    {
        cpu_active_freq = return_cpu_active_freq(0, 0, 0, 0, NULL);
        
        // IF is here because it wont work in the return_cpu_active_freq() func

        if (cpu_active_freq > cpu_max_freq)
        {
            cpu_active_freq = cpu_max_freq;
        }
        
        printf("CPU %11s%10.2f MHz%10.2f MHz %8.2f%%\n", "Complex", cpu_max_freq, cpu_active_freq, (cpu_active_freq / cpu_max_freq) * 100);
        sleep(options.interval);
        
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }

    #elif defined(__aarch64__)

    int             e_core_count        = get_sysctl("hw.perflevel0.physicalcpu");
    int             p_core_count        = get_sysctl("hw.perflevel1.physicalcpu");

    NSArray *       e_cpu_nominal_freqs = get_cpu_nominal_freqs('E');
    NSArray *       p_cpu_nominal_freqs = get_cpu_nominal_freqs('P');
    
    float           p_cpu_max_freq      = return_cpu_max_freq('P');
    float           cpu_avg_freq;
    
    while(looper < counterLooper)
    {
        cpu_avg_freq = return_cpu_avg_freq(options.interval);
        
        printf("\e[1m\n%s%10s%14s%16s%10s\n\n\e[0m", "Name", "Type", "Max Freq", "Active Freq", "Freq %");
        
        if (options.average == true || options.all == true)
        {
            if (options.r_average == false)
            {
                // dirty code having print for avg freq here, need to put inside print_cpu_freq_info() eventually
                
                printf("CPU %12s%10.2f MHz%10.2f MHz %8.2f%%\n", "Average", p_cpu_max_freq, cpu_avg_freq, (cpu_avg_freq / p_cpu_max_freq) * 100);
            }
        }
        if (options.cluster == true || options.all == true)
        {
            print_cpu_freq_info(true, 'E', 0, 0, e_cpu_nominal_freqs, options.interval);
            print_cpu_freq_info(true, 'P', 0, 0, p_cpu_nominal_freqs, options.interval);
            printf("\n");
        }
        
        if (options.cores == true || options.e_cores == true || options.all == true)
        {
            print_cpu_freq_info(false, 'E', 1, e_core_count, e_cpu_nominal_freqs, options.interval);
            printf("\n");
        }
        
        if (options.cores == true || options.p_cores == true || options.all == true)
        {
            print_cpu_freq_info(false, 'P', 1, p_core_count, p_cpu_nominal_freqs, options.interval);
            printf("\n");
        }
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }
    
    #endif

    return 0;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int get_sysctl(char * entry)
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

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_cpu_states(char cpu_cluster, int cpu_sub_group, int cpu_core)
{
    NSString * cpu_type;
    NSString * cpu_state;
    
    NSMutableArray * cpu_state_values = [NSMutableArray array];
    
    switch(cpu_cluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 'E': cpu_type = @"ECPU"; break;
        case 'P': cpu_type = @"PCPU"; break;
    }
    
    switch(cpu_sub_group) {
        default: ERROR("incorrect performance state subgroup input"); break;
        case 0: cpu_state = @"CPU Complex Performance States"; break;
        case 1: cpu_state = @"CPU Core Performance States"; break;
    }
    
    switch(cpu_core)
    {
        default: cpu_type = [NSString stringWithFormat:@"%@%i", cpu_type, cpu_core]; break;
        case 0: cpu_type = [NSString stringWithFormat:@"%@", cpu_type]; cpu_state = @"CPU Complex Performance States"; break;
    }
    
    CFMutableDictionaryRef channels = IOReportCopyChannelsInGroup(@"CPU Stats", 0x0, 0x0, 0x0, 0x0);
    CFMutableDictionaryRef subbed_channels = NULL;
    
    IOReportSubscriptionRef subscription = IOReportCreateSubscription(NULL, channels, &subbed_channels, 0, 0);
    
    if (!subscription)
    {
        ERROR("error finding channel");
    }
    
    CFDictionaryRef samples = NULL;
    
    if ((samples = IOReportCreateSamples(subscription, subbed_channels, NULL)))
    {
        IOReportIterate(samples, ^(IOReportSampleRef ch)
        {
            NSString * channel_name = IOReportChannelGetChannelName(ch);
            NSString * subgroup = IOReportChannelGetSubGroup(ch);
            uint64_t value;

            for (int i = 0; i < IOReportStateGetCount(ch); i++)
            {
                if ([channel_name isEqual: cpu_type] && [subgroup isEqual: cpu_state])
                {
                    value = IOReportStateGetResidency(ch, i);
                    [cpu_state_values addObject:@(value)];
                }
            }
            
            return kIOReportIterOk;
        });
    }
    else
    {
        ERROR("error accessing performance state information");
    }
    
    if ([cpu_state_values count] == 0)
    {
        ERROR("missing performance state values");
    }
    
    return cpu_state_values;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_cpu_nominal_freqs(char cpu_cluster)
{
    // need to figure out where to get these numbers so they don't have to be static in the code
    
    switch(cpu_cluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 'E': return [NSMutableArray arrayWithObjects: @"0", @"600", @"972", @"1332", @"1704", @"2064", nil]; break;
        case 'P': return [NSMutableArray arrayWithObjects: @"0", @"600", @"828", @"1056", @"1284", @"1500", @"1728", @"1956", @"2184", @"2388", @"2592", @"2772", @"2988", @"3096", @"3144", @"3204", nil]; break;
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void print_cpu_freq_info(bool cluster, char cpu_cluster, int cpu_sub_group, int cpu_count, NSArray * cpu_nominal_freqs, int interval)
{
    NSString * cpu_label;
    
    float cpu_active_freq;
    float cpu_freq_percent;
    float cpu_max_freq;
    
    int index = 1;
    char * cpu;
    
    switch(cpu_cluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 'E': cpu = "E"; cpu_max_freq = return_cpu_max_freq('E'); break;
        case 'P': cpu = "P"; cpu_max_freq = return_cpu_max_freq('P'); break;
    }
    
    if (cluster == false)
    {
        index = cpu_count;
    }
    
    for (int i = 0; i < index; i++)
    {
        cpu_active_freq = return_cpu_active_freq(cpu_cluster, cpu_sub_group, i, interval, cpu_nominal_freqs);
        cpu_freq_percent = (cpu_active_freq / cpu_max_freq) * 100;

        if (cpu_freq_percent > 100)
        {
            cpu_freq_percent = 100;
            cpu_active_freq = cpu_max_freq;
        }
        
        if (cluster == false)
        {
            cpu_label = [NSString stringWithFormat:@"%sCPU %i %9s", cpu, i + 1, "Core"];
        }
        else
        {
            cpu_label = [NSString stringWithFormat:@"%sCPU %11s", cpu, "Cluster"];
        }
        

        if (cpu_freq_percent <= 0.009 || cpu_active_freq <= 0.009)
        {
            printf("%s%10.2f MHz%10.2f MHz %9s\n", [cpu_label UTF8String], cpu_max_freq, cpu_active_freq, "Idle");
        }
        else
        {
            printf("%s%10.2f MHz%10.2f MHz %8.2f%%\n", [cpu_label UTF8String], cpu_max_freq, cpu_active_freq, cpu_freq_percent);
        }
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_active_freq(char cpu_cluster, int cpu_sub_group, int cpu_core, int interval, NSArray * cpu_nominal_freqs)
{
    #if defined(__x86_64__)

    int magic_number = 2 << 16;

    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    size_t cycles;

    uint64_t first_sample_begin = mach_absolute_time();

    cycles = magic_number * 2;
    FIRST_CYCLE_MEASURE

    uint64_t first_sample_end = mach_absolute_time();
    double first_ns_set = (double) (first_sample_end - first_sample_begin) * (double)info.numer / (double)info.denom;
    uint64_t lastSampleBegin = mach_absolute_time();

    cycles = magic_number;
    LAST_CYCLE_MEASURE

    uint64_t last_sample_end = mach_absolute_time();
    double last_ns_set = (double) (last_sample_end - lastSampleBegin) * (double)info.numer / (double)info.denom;
    double nanoseconds = (first_ns_set - last_ns_set);

    float cpu_freq = (float)(magic_number / nanoseconds);

    return cpu_freq * 1e+3;

    #elif defined(__aarch64__)
    
    float first_sample_sum = 0;
    float last_sample_sum = 0;
    float sample_sum = 0;
    
    float state_percent = 0;
    float state_freq = 0;
    
    NSMutableArray * first_sample = get_cpu_states(cpu_cluster, cpu_sub_group, cpu_core);
    sleep(interval);
    NSMutableArray * last_sample = get_cpu_states(cpu_cluster, cpu_sub_group, cpu_core);
    
    for (int i = 0; i < [first_sample count]; i++)
    {
        first_sample_sum += [first_sample[i] floatValue];
        last_sample_sum += [last_sample[i] floatValue];
    }
    
    sample_sum = last_sample_sum - first_sample_sum;
    
    for (int i = 0; i < [first_sample count]; i++)
    {
        state_percent = ([last_sample[i] floatValue] - [first_sample[i] floatValue]) / sample_sum;
        state_freq += state_percent * [cpu_nominal_freqs[i] floatValue];
    }
    
    if (isnan(state_freq))
    {
        return return_cpu_max_freq(cpu_cluster);
    }

    return state_freq;
    
    #endif
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_avg_freq(int interval)
{
    NSMutableArray * cpu_cluster_freqs;
    
    int size;
    
    float e_cluster_freq;
    float p_cluster_freq;
    float cpu_max_freq = return_cpu_max_freq('P');
    float cpu_avg_freq = 0;
    
    e_cluster_freq = return_cpu_active_freq('E', 0, 0, 0, get_cpu_nominal_freqs('E'));
    sleep(interval);
    p_cluster_freq = return_cpu_active_freq('P', 0, 0, 0, get_cpu_nominal_freqs('P'));
    
    cpu_cluster_freqs = [NSMutableArray arrayWithObjects: @(e_cluster_freq), @(p_cluster_freq), nil];
    size = sizeof(cpu_cluster_freqs) / sizeof(cpu_cluster_freqs[0]);
    
    for (int i = 0; i < size; i++)
    {
        cpu_avg_freq += [cpu_cluster_freqs[i] floatValue];
    }
    
    cpu_avg_freq = cpu_avg_freq / size;
    
    if (cpu_avg_freq <= 0)
    {
        // returning E-Cluster freq on problematic calculations
        // would return error but the inaccuracies occur too often...need to fix this in upcoming version
        
        cpu_avg_freq = return_cpu_active_freq('E', 0, 0, 0, get_cpu_nominal_freqs('E'));
        
        if (cpu_avg_freq == 0)
        {
            return return_cpu_max_freq('E');
        }
    }
    
    if (cpu_avg_freq > cpu_max_freq)
    {
        return cpu_max_freq;
    }
    
    return cpu_avg_freq;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_max_freq(char cpu_cluster)
{
    #if defined(__x86_64__)
    
    uint64_t first_sample = __rdtsc();
    sleep(1);
    uint64_t last_sample = __rdtsc();

    return (float)((last_sample - first_sample) / 1e+6);
    
    #elif defined(__aarch64__)
    
    NSMutableArray * cpu_nominal_freqs;
    
    switch(cpu_cluster)
    {
        default:    ERROR("incorrect cluster input"); break;
        case 'E':   cpu_nominal_freqs = get_cpu_nominal_freqs('E'); break;
        case 'P':   cpu_nominal_freqs = get_cpu_nominal_freqs('P'); break;
    }
    
    return [cpu_nominal_freqs[[cpu_nominal_freqs count] - 1] floatValue];
    
    #endif
}
