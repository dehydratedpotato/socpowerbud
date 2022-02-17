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

// CHANGELOG:
// universal Changed "Average" and "Complex" freqs to "Package"
// x86 Per-Core Freq Reporting (Unofficial Support on Ice Lake and Newer)
// x86 cluster freq reporitng
// x86 Limiting output to no more than turbo frequency rather than RDTSC which reduces output time to ~.011s with default sampling intevral
// x86 Limiting output to no less than 800 MHz
// x86 Changed Functionality of Smapling Intevral
// x86 added base freq column
// x86 Default to using base clock if cannot find turbo freq

// NEW FILES:
// - Added model_data.h and model_data.m in order to find system turbo speed
// - Added universal.m in order to bring simple systcl access to all archs

// KNOWN ISSUES:
// x86 Per-core method slightly inaccurate on Ice Lake and newer
// x86 Per-core mthod does not account for idle c-states

#include <Foundation/Foundation.h>
#include "universal/universal.h"

#if defined(__x86_64__)

#include "x86_64/x86_64.h"

#elif defined(__aarch64__)

#include "arm64/arm64.h"

#endif

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void usage(void)
{
    printf("Usage:\n");
    printf("./osx-cpufreq [options]\n");
    printf("    -l <value> : loop output (0 = infinite)\n");
    printf("    -i <value> : set sampling interval (may effect accuracy)\n");
    printf("    -c         : print frequency information for CPU cores\n");
    printf("    -q         : print frequency information for CPU clusters\n");
    printf("    -a         : print frequency information for CPU package\n");
    printf("    -e         : print frequency information for ECPU types    (arm64)\n");
    printf("    -p         : print frequency information for PCPU types    (arm64)\n");
    printf("    -v         : print version number\n");
    printf("    -h         : help\n");
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int main(int argc, char * argv[])
{
    struct options  options;
    int             option;
    
    int             looper = 0;
    int             counterLooper = 0;
    
    options.all         = true;
    
    options.efficiency  = false;
    options.performance = false;
    
    options.cores       = false;
    options.all_cores   = true;
    
    options.cluster     = false;
    options.all_cluster = true;
    
    options.package     = false;
    
    options.looping     = false;
    options.loop        = 0;
    
    #if defined(__x86_64__)
    
    options.interval    = 0;
    
    #elif defined(__aarch64__)
    
    options.interval    = 0.8;
    
    #endif
    
    while((option = getopt(argc, argv, "i:l:cepqavh")) != -1)
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
                        options.all_cores = true;
                        options.all = false;
                        break;
                
            case 'e':   options.efficiency = true;
                        options.all = false;
                        options.all_cluster = false;
                        options.all_cores = false;
                        break;
            case 'p':   options.performance = true;
                        options.all = false;
                        options.all_cluster = false;
                        options.all_cores = false;
                        break;
                
            case 'q':   options.cluster = true;
                        options.all = false;
                        break;
                
            case 'a':   options.package = true;
                        options.all = false;
                        break;
                
            case 'v':   printf("\e[1mosx-cpufreq\e[0m: version %s\n", VERSION);
                        return 0;
                        break;
                
            case 'h':   usage();
                        return 0;
                        break;
        }
    }
    
    if (options.interval < 0)
    {
        ERROR("sampling interval can not be a negative");
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
    
    int             physical_cpus     = get_sysctl_int(SYSCTL_CPUS);

    float           cpu_max_freq      = return_cpu_static_freq(TURBO);
    float           cpu_base_freq      = return_cpu_static_freq(RATED);
    float           cpu_active_freq;

    if (options.efficiency == true || options.performance == true)
    {
        ERROR("cluster type selection only available on arm64");
    }
    
    printf("\e[1m\n%s%9s%14s%15s%15s%10s\n\n\e[0m", "Name", "Type", "Max Freq", "Base Freq", "Active Freq", "Freq %");

    while(looper < counterLooper)
    {
        [NSThread sleepForTimeInterval:options.interval];
        
        cpu_active_freq = return_cpu_active_freq();
        
        // Printing frequencies
        
        if (options.package == true || options.cluster == true || options.all == true)
        {
            printf("CPU %11s%10.2f MHz%10.2f MHz%10.2f MHz %8.2f%%\n", "Package", cpu_max_freq, cpu_base_freq, cpu_active_freq, (cpu_active_freq / cpu_base_freq) * 100);
        }
        if (options.cores == true || options.all == true)
        {
            for (int i = 0; i < physical_cpus; i++)
            {
                cpu_active_freq = return_cpu_active_freq();
                printf("CPU %i%10s%10.2f MHz%10.2f MHz%10.2f MHz %8.2f%%\n", i, "Core", cpu_max_freq, cpu_base_freq, cpu_active_freq, (cpu_active_freq / cpu_base_freq) * 100);
            }
        }
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }

    #elif defined(__aarch64__)
    
    if ((options.efficiency == true || options.performance == true) && (options.cores == false && options.cluster == false))
    {
        ERROR("cluster type selection only allowed using additional options -q or -c");
    }
    
    NSMutableArray * e_cpu_last_sample          = [[NSMutableArray alloc] init];
    NSMutableArray * e_cpu_first_sample         = [[NSMutableArray alloc] init];
    
    NSMutableArray * p_cpu_last_sample          = [[NSMutableArray alloc] init];
    NSMutableArray * p_cpu_first_sample         = [[NSMutableArray alloc] init];

    NSMutableArray * e_cpu_cores_first_sample   = [[NSMutableArray alloc] init];
    NSMutableArray * e_cpu_cores_last_sample    = [[NSMutableArray alloc] init];
    
    NSMutableArray * p_cpu_cores_first_sample   = [[NSMutableArray alloc] init];
    NSMutableArray * p_cpu_cores_last_sample    = [[NSMutableArray alloc] init];

    int             e_core_count        = get_sysctl_int(SYSCTL_ECPU);
    int             p_core_count        = get_sysctl_int(SYSCTL_PCPU);

    float           e_cpu_max_freq      = return_cpu_max_freq(ECPU);
    float           p_cpu_max_freq      = return_cpu_max_freq(PCPU);
    
    float           e_cpu_active_freq;
    float           p_cpu_active_freq;
    
    float           e_cpu_core_freq;
    float           p_cpu_core_freq;
    
    float           cpu_avg_freq;
    
    printf("\e[1m\n%s%10s%14s%16s%10s\n\n\e[0m", "Name", "Type", "Max Freq", "Active Freq", "Freq %");
    
    while(looper < counterLooper)
    {
        // First samples
        
        e_cpu_first_sample = get_cpu_states(ECPU, COMPLEX, COMPLEX);
        p_cpu_first_sample = get_cpu_states(PCPU, COMPLEX, COMPLEX);
        
        for (int i = 0; i < e_core_count; i++)
        {
            [e_cpu_cores_first_sample addObject:get_cpu_states(ECPU, CORE, i)];
        }
        
        for (int i = 0; i < p_core_count; i++)
        {
            [p_cpu_cores_first_sample addObject:get_cpu_states(PCPU, CORE, i)];
        }
        
        [NSThread sleepForTimeInterval:options.interval];
        
        // Last samples
        
        e_cpu_last_sample  = get_cpu_states(ECPU, COMPLEX, COMPLEX);
        p_cpu_last_sample  = get_cpu_states(PCPU, COMPLEX, COMPLEX);
        
        for (int i = 0; i < e_core_count; i++)
        {
            [e_cpu_cores_last_sample addObject:get_cpu_states(ECPU, CORE, i)];
        }
        
        for (int i = 0; i < p_core_count; i++)
        {
            [p_cpu_cores_last_sample addObject:get_cpu_states(PCPU, CORE, i)];
        }
        
        // Printing frequencies
        
        e_cpu_active_freq = return_cpu_active_freq(ECPU, e_cpu_first_sample, e_cpu_last_sample);
        p_cpu_active_freq = return_cpu_active_freq(PCPU, p_cpu_first_sample, p_cpu_last_sample);
        cpu_avg_freq = return_cpu_avg_freq(e_cpu_active_freq, p_cpu_active_freq);
        
        if (options.package == true || options.all == true)
        {
            printf("CPU%12s%10.2f MHz%11.2f MHz %9s\n", "Package", p_cpu_max_freq, cpu_avg_freq, [return_cpu_freq_percent(PCPU, cpu_avg_freq) UTF8String]);
        }
        
        if (options.cluster == true || options.all == true)
        {
            if (options.efficiency == true || options.all_cluster == true)
            {
                printf("ECPU%11s%10.2f MHz%11.2f MHz %9s\n", "Cluster", e_cpu_max_freq, e_cpu_active_freq, [return_cpu_freq_percent(ECPU, e_cpu_active_freq) UTF8String]);
            }
            
            if (options.performance == true || options.all_cluster == true)
            {
                printf("PCPU%11s%10.2f MHz%11.2f MHz %9s\n", "Cluster", p_cpu_max_freq, p_cpu_active_freq, [return_cpu_freq_percent(PCPU, p_cpu_active_freq) UTF8String]);
            }
            
            printf("\n");
        }
        
        if (options.cores == true || options.all == true)
        {
            if (options.efficiency == true || options.all_cores == true)
            {
                for (int i = 0; i < e_core_count; i++)
                {
                    e_cpu_core_freq = return_cpu_active_freq(ECPU, e_cpu_cores_first_sample[i], e_cpu_cores_last_sample[i]);
                    printf("ECPU %i%9s%10.2f MHz%11.2f MHz %9s\n", i, "Core", e_cpu_max_freq, e_cpu_core_freq, [return_cpu_freq_percent(ECPU, e_cpu_core_freq) UTF8String]);
                }
                
                printf("\n");
            }
        
            if (options.performance == true || options.all_cores == true)
            {
                for (int i = 0; i < p_core_count; i++)
                {
                    p_cpu_core_freq = return_cpu_active_freq(PCPU, p_cpu_cores_first_sample[i], p_cpu_cores_last_sample[i]);
                    printf("PCPU %i%9s%10.2f MHz%11.2f MHz %9s\n", i, "Core", p_cpu_max_freq, p_cpu_core_freq, [return_cpu_freq_percent(PCPU, p_cpu_core_freq) UTF8String]);
                }
                
                printf("\n");
            }
        }
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }
    
    #endif

    return 0;
}
