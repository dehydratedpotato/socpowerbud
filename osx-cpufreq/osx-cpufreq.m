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

struct option options_long[] =
{
    { "help",        no_argument,       0, 'h' },
    { "version",     no_argument,       0, 'v' },
    
    { "loop-rate",   required_argument, 0, 'l' },
    { "sample-rate", required_argument, 0, 'i' },
    { "select-core", required_argument, 0, 's' },
    
    { "cores",       no_argument,       0, 'c' },
    { "clusters",    no_argument,       0, 'C' },
    { "package",     no_argument,       0, 'P' },
    
    { "e-cluster",   no_argument,       0, 'e' },
    { "p-cluster",   no_argument,       0, 'p' },
    { NULL,          0,                 0, 0 }
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void print_help_info(void)
{
    printf("\e[1m\nUsage: osx-cpufreq [-l loop_count] [-i sample_interval] [-s core]\n\n\e[0m");
    
    printf("  This project is designed to get the active frequency of your Macs CPU cores\n");
    printf("  and package, as fast and accurate as possible, without requiring sudo or a\n");
    printf("  kernel extension. Made with love by BitesPotatoBacks.\n\n");
    
    printf("\e[1mThe following command-line options are supported:\n\n\e[0m");

    printf("  -h | --help            show this message\n");
    printf("  -v | --version         print version number\n\n");
    
    printf("  -l | --loop-rate <N>   loop output (0=infinite) [default: disabled]\n");
    printf("  -i | --sample-rate <N> set sampling rate (may effect accuracy) [default: 0.8s]\n");
    printf("  -s | --select-core <N> selected specific CPU core [default: disabled]\n\n");
    
    printf("  -c | --cores           print frequency information for CPU cores\n");
    printf("  -C | --clusters        print frequency information for CPU clusters\n");
    printf("  -P | --package         print frequency information for CPU package\n");
    
    #if defined(__aarch64__)
    
    printf("  -e | --e-cluster       print frequency information for ECPU types (ARM64)\n");
    printf("  -p | --p-cluster       print frequency information for PCPU types (ARM64)\n");
    
    #endif
    
    printf("\n");
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void print_script_output(struct options options, int looper, int loop_key)
{
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
    
    while(looper < loop_key)
    {
        [NSThread sleepForTimeInterval:options.interval];
        
        cpu_active_freq = return_cpu_active_freq();
        
        if (options.package == true || options.cluster == true || options.all == true)
        {
            printf("\n");
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
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
            
            if (options.all == true)
            {
                printf("\n");
            }
        }
    }
    
    #elif defined(__aarch64__)
    
    if ((options.efficiency == true || options.performance == true) && (options.cores == false && options.cluster == false))
    {
        ERROR("cluster type selection only allowed using additional options -C or -c");
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

    int             e_core_count        = get_cpus(ECPU);
    int             p_core_count        = get_cpus(PCPU);

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
    
    while(looper < loop_key)
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
            print_freqs(0, -1, cpu_avg_freq, p_cpu_max_freq, (char *)[return_cpu_freq_percent(PCPU, cpu_avg_freq) UTF8String]);
        }
        
        if (options.cluster == true || options.all == true)
        {
            if (options.efficiency == true || options.all_cluster == true)
            {
                print_freqs('E', -1, e_cpu_active_freq, e_cpu_max_freq, (char *)[return_cpu_freq_percent(ECPU, e_cpu_active_freq) UTF8String]);
            }
            
            if (options.performance == true || options.all_cluster == true)
            {
                print_freqs('P', -1, p_cpu_active_freq, p_cpu_max_freq, (char *)[return_cpu_freq_percent(PCPU, p_cpu_active_freq) UTF8String]);
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
                    print_freqs('E', options.select_core, e_cpu_core_freq, e_cpu_max_freq, (char *)[return_cpu_freq_percent(ECPU, e_cpu_core_freq) UTF8String]);
                }
                else
                {
                    for (int i = 0; i < e_core_count; i++)
                    {
                        e_cpu_core_freq = return_cpu_active_freq(ECPU, e_cpu_cores_first_sample[i], e_cpu_cores_last_sample[i]);
                        print_freqs('E', i, e_cpu_core_freq, e_cpu_max_freq, (char *)[return_cpu_freq_percent(ECPU, e_cpu_core_freq) UTF8String]);
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
                    print_freqs('P', options.select_core, p_cpu_core_freq, p_cpu_max_freq, (char *)[return_cpu_freq_percent(PCPU, p_cpu_core_freq) UTF8String]);
                }
                else
                {
                    for (int i = 0; i < p_core_count; i++)
                    {
                        p_cpu_core_freq = return_cpu_active_freq(PCPU, p_cpu_cores_first_sample[i], p_cpu_cores_last_sample[i]);
                        print_freqs('P', i, p_cpu_core_freq, p_cpu_max_freq, (char *)[return_cpu_freq_percent(PCPU, p_cpu_core_freq) UTF8String]);
                    }
                }
            }
        }
        
        [e_cpu_cores_first_sample removeAllObjects];
        [e_cpu_cores_last_sample removeAllObjects];
        
        [p_cpu_cores_first_sample removeAllObjects];
        [p_cpu_cores_last_sample removeAllObjects];
        
        if (options.looping == false || options.loop > 0)
        {
            looper++;
            
            if (options.all == true)
            {
                printf("\n");
            }
        }
    }
    
    #endif
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int main(int argc, char * argv[])
{
    struct options options;
    
    int             option;
    int             option_index;
    
    int             looper  = 0;
    int             loop_key = 0;
    
    options.all             = true;
    options.cores           = false;
    options.package         = false;
    options.cluster         = false;
    options.all_cores       = true;
    options.all_cluster     = true;
    options.efficiency      = false;
    options.performance     = false;
    options.selecting_core  = false;
    options.looping         = false;
    options.loop            = 0;
    
    #if defined(__x86_64__)
    
    options.interval        = 0;
    
    #elif defined(__aarch64__)
    
    options.interval        = 0.8;
    
    #endif
    
    while((option = getopt_long(argc, argv, "hvl:i:s:cCPep", options_long, &option_index)) != -1)
    {
        switch(option)
        {
            default:    options.all = true;
                        break;
            case 'v':   printf("\e[1mosx-cpufreq\e[0m: version %s\n", VERSION);
                        return 0;
                        break;
            case 'h':   print_help_info();
                        return 0;
                        break;
            case 'l':   options.loop = atoi(optarg);
                        options.looping = true;
                        break;
            case 'i':   options.interval = atoi(optarg);
                        break;
            case 's':   options.select_core = atoi(optarg);
                        options.selecting_core = true;
                        break;
            case 'c':   options.cores = true;
                        options.all_cores = true;
                        options.all = false;
                        break;
            case 'C':   options.cluster = true;
                        options.all = false;
                        break;
            case 'P':   options.package = true;
                        options.all = false;
                        break;
            case 'e':   options.efficiency = true;
                        options.all_cluster = false;
                        options.all_cores = false;
                        options.all = false;
                        break;
            case 'p':   options.performance = true;
                        options.all_cluster = false;
                        options.all_cores = false;
                        options.all = false;
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
       loop_key = 1;
    }
    else
    {
        if (options.loop == 0)
        {
            loop_key = 1;
            
            if (options.interval == 0)
            {
                options.interval = 0.8;
            }
        }
        else
        {
            loop_key = options.loop;
        }
    }
    
    print_script_output(options, looper, loop_key);

    return 0;
}
