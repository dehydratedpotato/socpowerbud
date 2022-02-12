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
// - (arm64) Roughly 80% faster output as when using the same sampiling intervals compared to previous version
// - Finer tuning for sampling inteval, interval can now be float rather than just and int
// - better management of usage function
// - made sure to prevent negative sampling intervals
// - added ability to choose which cluster frequency to retrieve, as well as better command line option combination options for cluster types (valid: -c, -cq, -cqe, -cqp, -ce, -cp, -qe, -qp invalid: -e, -p, )

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
    printf("    -c         : print frequency information for CPU cores       (arm64)\n");
    printf("    -e         : print frequency information for ECPU types      (arm64)\n");
    printf("    -p         : print frequency information for PCPU types      (arm64)\n");
    printf("    -q         : print frequency information for CPU clusters\n");
    printf("    -r         : remove average frequency estimation from output (arm64)\n");
    printf("    -a         : print average frequency estimation only\n");
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
    
    options.average     = false;
    options.r_average   = false;
    
    options.looping     = false;
    options.loop        = 0;
    
    options.interval    = 0.8;
    
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
                
            case 'r':   options.r_average = true;
                        break;
                
            case 'a':   options.average = true;
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
    else if ((options.efficiency == true || options.performance == true) && (options.cores == false && options.cluster == false))
    {
        ERROR("cluster type selection only allowed using additional options -q or -c");
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
    float           cpu_max_freq      = return_cpu_max_freq();

    if (options.cores == true || options.efficiency == true || options.performance == true || options.r_average == true)
    {
        ERROR("command line option used not yet supported on x86");
    }

    printf("\e[1m\n%s%9s%14s%16s%10s\n\n\e[0m", "Name", "Type", "Max Freq", "Active Freq", "Freq %");

    while(looper < counterLooper)
    {
        cpu_active_freq = return_cpu_active_freq();
        
        // IF is here because it wont work in the return_cpu_active_freq() func

        if (cpu_active_freq > cpu_max_freq)
        {
            cpu_active_freq = cpu_max_freq;
        }
        
        printf("CPU %11s%10.2f MHz%10.2f MHz %8.2f%%\n", "Complex", cpu_max_freq, cpu_active_freq, (cpu_active_freq / cpu_max_freq) * 100);
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }

    #elif defined(__aarch64__)
    
    NSMutableArray * e_cpu_last_sample          = [[NSMutableArray alloc] init];
    NSMutableArray * e_cpu_first_sample         = [[NSMutableArray alloc] init];
    
    NSMutableArray * p_cpu_last_sample          = [[NSMutableArray alloc] init];
    NSMutableArray * p_cpu_first_sample         = [[NSMutableArray alloc] init];

    NSMutableArray * e_cpu_cores_first_sample   = [[NSMutableArray alloc] init];
    NSMutableArray * e_cpu_cores_last_sample    = [[NSMutableArray alloc] init];
    
    NSMutableArray * p_cpu_cores_first_sample   = [[NSMutableArray alloc] init];
    NSMutableArray * p_cpu_cores_last_sample    = [[NSMutableArray alloc] init];

    int             e_core_count        = get_sysctl("hw.perflevel0.physicalcpu");
    int             p_core_count        = get_sysctl("hw.perflevel1.physicalcpu");

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
        
        if (options.average == true || options.all == true)
        {
            if (options.r_average == false)
            {
                printf("CPU%12s%10.2f MHz%11.2f MHz %9s\n", "Average", p_cpu_max_freq, cpu_avg_freq, [return_cpu_freq_percent(PCPU, cpu_avg_freq) UTF8String]);
            }
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
