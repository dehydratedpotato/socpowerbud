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
    printf("    -s <value> : print frequency information for selected CPU core\n");
    printf("    -c         : print frequency information for CPU cores\n");
    printf("    -q         : print frequency information for CPU clusters\n");
    printf("    -a         : print frequency information for CPU package\n");
    printf("    -e         : print frequency information for ECPU types   (arm64)\n");
    printf("    -p         : print frequency information for PCPU types   (arm64)\n");
    printf("    -v         : print version number\n");
    printf("    -h         : help\n");
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int main(int argc, char * argv[])
{
    struct options  options;
    int             option;
    
    int             looper  = 0;
    int             counterLooper = 0;
    
    options.all             = true;
    
    options.efficiency      = false;
    options.performance     = false;
    
    options.cores           = false;
    options.all_cores       = true;
    options.selecting_core  = false;
    
    options.cluster         = false;
    options.all_cluster     = true;
    
    options.package         = false;
    
    options.looping         = false;
    options.loop            = 0;
    
    #if defined(__x86_64__)
    
    options.interval        = 0;
    
    #elif defined(__aarch64__)
    
    options.interval        = 0.8;
    
    #endif
    
    while((option = getopt(argc, argv, "i:l:s:cqaepvh")) != -1)
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
                
            case 's':   options.select_core = atoi(optarg);
                        options.selecting_core = true;
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
        ERROR("sampling interval can not be a negative integer");
    }
    
    if (options.loop < 0)
    {
        ERROR("loop count can not be a negative integer");
    }
    
    if (options.selecting_core == true && options.select_core < 0)
    {
        ERROR("core selection can not be a negative integer");
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
            
            if (options.interval == 0)
            {
                options.interval = 0.8;
            }
        }
        else
        {
            counterLooper = options.loop;
        }
    }
    
    #if defined(__x86_64__)
    
    int             physical_cpus     = get_sysctl_int(SYSCTL_CPUS);

    float           cpu_base_freq     = return_cpu_base_freq();
    float           cpu_active_freq;

    if (options.efficiency == true || options.performance == true)
    {
        ERROR("cluster type selection only available on arm64");
    }
    
    if (options.selecting_core == true && options.select_core > (physical_cpus - 1))
    {
        ERROR("core selection must be in range of physical core count")
    }
    
    check_cpu_generation();
    
    while(looper < counterLooper)
    {
        [NSThread sleepForTimeInterval:options.interval];
        
        cpu_active_freq = return_cpu_active_freq();
        
        // Printing frequencies
        
        printf("\n");
        
        if (options.package == true || options.cluster == true || options.all == true)
        {
            printf("Package Frequencies\n------------------------\n");
            printf("CPU..........(Package) : %.0f MHz (%.0f MHz: %.2f%%)\n", cpu_active_freq, cpu_base_freq, (cpu_active_freq / cpu_base_freq) * 100);
        }
        
        printf("\n");
        
        if (options.cores == true || options.all == true)
        {
            printf("Core Frequencies\n------------------------\n");
            
            if (options.selecting_core == true)
            {
                cpu_active_freq = return_cpu_active_freq();
                printf("CORE%d...........(Core) : %.0f MHz (%.0f MHz: %.2f%%)\n", options.select_core, cpu_active_freq, cpu_base_freq, (cpu_active_freq / cpu_base_freq) * 100);
            }
            else
            {
                for (int i = 0; i < physical_cpus; i++)
                {
                    cpu_active_freq = return_cpu_active_freq();
                    printf("CORE%d...........(Core) : %.0f MHz (%.0f MHz: %.2f%%)\n", i, cpu_active_freq, cpu_base_freq, (cpu_active_freq / cpu_base_freq) * 100);
                }
            }
        }
        
        printf("\n");
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }

    #elif defined(__aarch64__)
    
    // early error checking
    
    if ((options.efficiency == true || options.performance == true) && (options.cores == false && options.cluster == false))
    {
        ERROR("cluster type selection only allowed using additional options -q or -c");
    }
    
    if (options.selecting_core == true && options.cores != true)
    {
        ERROR("core selection only allowed using additional option -c");
    }
    
    if ((options.performance != true && options.efficiency != true) && options.selecting_core == true)
    {
        ERROR("core selection only allowed using additional options -e or -p");
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
    
    if (options.efficiency == true && options.selecting_core == true && options.select_core > (e_core_count - 1))
    {
        ERROR("core selection must be in range of efficiency core count");
    }
    else if (options.performance == true && options.selecting_core == true && options.select_core > (p_core_count - 1))
    {
        ERROR("core selection must be in range of performance core count");
    }
    
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
        
        if (options.package == true || options.cluster == true || options.all == true)
        {
            printf("\n");
            printf("Package Frequencies\n------------------------\n");
        }
        
        if (options.package == true || options.all == true)
        {
            printf("CPU..........(Package) : %.0f MHz (%.0f MHz: %s)\n", cpu_avg_freq, p_cpu_max_freq, [return_cpu_freq_percent(PCPU, cpu_avg_freq) UTF8String]);
        }
        
        if (options.cluster == true || options.all == true)
        {
            if (options.efficiency == true || options.all_cluster == true)
            {
                printf("ECPU.........(Cluster) : %.0f MHz (%.0f MHz: %s)\n", e_cpu_active_freq, e_cpu_max_freq, [return_cpu_freq_percent(ECPU, e_cpu_active_freq) UTF8String]);
            }
            
            if (options.performance == true || options.all_cluster == true)
            {
                printf("PCPU.........(Cluster) : %.0f MHz (%.0f MHz: %s)\n", p_cpu_active_freq, p_cpu_max_freq, [return_cpu_freq_percent(PCPU, p_cpu_active_freq) UTF8String]);
            }
        }
        
        printf("\n");
        
        if (options.cores == true || options.all == true)
        {
            if (options.efficiency == true || options.all_cores == true)
            {
                printf("E-Core Frequencies\n------------------------\n");
                
                if (options.efficiency == true && options.selecting_core == true)
                {
                    e_cpu_core_freq = return_cpu_active_freq(ECPU, e_cpu_cores_first_sample[options.select_core], e_cpu_cores_last_sample[options.select_core]);

                    printf("ECORE%d..........(Core) : %.0f MHz (%.0f MHz: %s)\n", options.select_core, e_cpu_core_freq, e_cpu_max_freq, [return_cpu_freq_percent(ECPU, e_cpu_core_freq) UTF8String]);
                }
                else
                {
                    for (int i = 0; i < e_core_count; i++)
                    {
                        e_cpu_core_freq = return_cpu_active_freq(ECPU, e_cpu_cores_first_sample[i], e_cpu_cores_last_sample[i]);
                        printf("ECORE%d..........(Core) : %.0f MHz (%.0f MHz: %s)\n", i, e_cpu_core_freq, e_cpu_max_freq, [return_cpu_freq_percent(ECPU, e_cpu_core_freq) UTF8String]);
                    }
                }
            }
            
            printf("\n");
        
            if (options.performance == true || options.all_cores == true)
            {
                printf("P-Core Frequencies\n------------------------\n");
                
                if (options.performance == true && options.selecting_core == true)
                {
                    p_cpu_core_freq = return_cpu_active_freq(PCPU, p_cpu_cores_first_sample[options.select_core], p_cpu_cores_last_sample[options.select_core]);
                    printf("PCORE%d..........(Core) : %.0f MHz (%.0f MHz: %s)\n", options.select_core, p_cpu_core_freq, p_cpu_max_freq, [return_cpu_freq_percent(PCPU, p_cpu_core_freq) UTF8String]);
                }
                else
                {
                    for (int i = 0; i < p_core_count; i++)
                    {
                        p_cpu_core_freq = return_cpu_active_freq(PCPU, p_cpu_cores_first_sample[i], p_cpu_cores_last_sample[i]);
                        printf("PCORE%d..........(Core) : %.0f MHz (%.0f MHz: %s)\n", i, p_cpu_core_freq, p_cpu_max_freq, [return_cpu_freq_percent(PCPU, p_cpu_core_freq) UTF8String]);
                    }
                }
                
                printf("\n");
            }
        }
        
        [e_cpu_cores_first_sample removeAllObjects];
        [e_cpu_cores_last_sample removeAllObjects];
        
        [p_cpu_cores_first_sample removeAllObjects];
        [p_cpu_cores_last_sample removeAllObjects];
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
        }
    }
    
    #endif

    return 0;
}
