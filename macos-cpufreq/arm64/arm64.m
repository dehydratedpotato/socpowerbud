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

#if defined(__aarch64__)

#include <Foundation/Foundation.h>
#include "arm64.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSString * const cache_corecnt0         = @"CpuClusterCoreCount0";
NSString * const cache_corecnt1         = @"CpuClusterCoreCount1";

NSString * const cache_maxfreq0         = @"CpuClusterMaxFreq0";
NSString * const cache_maxfreq1         = @"CpuClusterMaxFreq1";

NSString * const cache_voltfreq0        = @"CpuClusterVoltageFreqs0";
NSString * const cache_voltfreq1        = @"CpuClusterVoltageFreqs1";

NSString * const cache_predef_corecnt   = @"IsUsingPredefinedClusterCoreCounts";
NSString * const cache_predef_voltfreq  = @"IsUsingPredefinedVoltageFreqs";

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_cpu_states(char cpu_cluster, int cpu_sub_group, int cpu_core)
{
    NSString * cpu_type;
    NSString * cpu_state;
    
    NSMutableArray * cpu_state_values = [NSMutableArray array];
    
    switch(cpu_cluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 0:  cpu_type = @"ECPU"; break;
        case 1:  cpu_type = @"PCPU"; break;
    }
    
    switch(cpu_sub_group) {
        default: ERROR("incorrect performance state subgroup input"); break;
        case 0:  cpu_state = @"CPU Complex Performance States"; break;
        case 1:  cpu_state = @"CPU Core Performance States"; break;
    }
    
    switch(cpu_core)
    {
        default: cpu_type = [NSString stringWithFormat:@"%@%i", cpu_type, cpu_core]; break;
        case 0:  cpu_type = [NSString stringWithFormat:@"%@", cpu_type]; cpu_state = @"CPU Complex Performance States"; break;
    }
    
    CFMutableDictionaryRef channels = IOReportCopyChannelsInGroup(@"CPU Stats", 0, 0, 0, 0);
    CFMutableDictionaryRef subbed_channels = NULL;
    
    IOReportSubscriptionRef subscription = IOReportCreateSubscription(NULL, channels, &subbed_channels, 0, 0);
    
    if (!subscription)
    {
        ERROR("failed to access CPU Stats from IOReport");
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
        ERROR("failed to access performance state information from CPU Stats in IOReport");
    }
    
    if ([cpu_state_values count] == 0)
    {
        ERROR("missing performance state values in IOReport");
    }
    
    return cpu_state_values;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_cpu_nominal_freqs(char cpu_cluster)
{
    NSUserDefaults *        user_defaults = [NSUserDefaults standardUserDefaults];
    
    NSMutableArray *        nominal_freqs = [NSMutableArray array];
    NSMutableArray *        p_cpu_nominal_freqs = [NSMutableArray array];
    NSMutableArray *        e_cpu_nominal_freqs = [NSMutableArray array];
    
    NSString *              machine;
    
    if (![user_defaults objectForKey:cache_voltfreq0] || ![user_defaults objectForKey:cache_voltfreq1])
    {
        io_registry_entry_t     service;

        NSData *                data;
        NSString *              data_string;

        const unsigned char *   data_bytes;
        float                   formatted_data;
        
        bool                    access_err = false;
        
        if ((service = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/AppleARMPE/arm-io/AppleT810xIO/pmgr")) || (service = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/arm-io/pmgr")))
        {
            switch(cpu_cluster)
            {
                case 0:  data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("voltage-states1-sram"), kCFAllocatorDefault, 0); break;
                case 1:  data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("voltage-states5-sram"), kCFAllocatorDefault, 0); break;
            }

            if (data) {
                data_bytes = [data bytes];

                [nominal_freqs addObject:@"0"];

                for (int i = 4; i < ([data length] + 4); i += 4)
                {
                    data_string = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", data_bytes[i - 1], data_bytes[i - 2], data_bytes[i - 3], data_bytes[i - 4]];
                    formatted_data = atof([data_string UTF8String]) * 1e-6;

                    if (formatted_data >= 600)
                    {
                        [nominal_freqs addObject:@(formatted_data)];
                    }
                }
                
                [user_defaults setBool:NO forKey:cache_predef_voltfreq];
            }
            else
            {
                access_err = true;
            }
        }
        else
        {
            access_err = true;
        }
        
        if (access_err)
        {
            [user_defaults setBool:YES forKey:cache_predef_voltfreq];
            
            if ([user_defaults objectForKey:cache_predef_voltfreq] != nil)
            {
                switch(cpu_cluster)
                {
                     case 0: WARNING("failed to access ECPU voltage state frequencies from the IORegistry, now using predefined values. Accuracy may be affected.") break;
                     case 1: WARNING("failed to access PCPU voltage state frequencies from the IORegistry, now using predefined values. Accuracy may be affected.") break;
                }
            }
            
            machine = [NSString stringWithFormat:@"%s", get_sysctl_char(SYSCTL_PRODUCT)];
            e_cpu_nominal_freqs = [NSMutableArray arrayWithObjects: @"0", @"600", @"972", @"1332", @"1704", @"2064", nil];
        
            if ([machine isEqual: @"MacBookPro18,1"] || [machine isEqual: @"MacBookPro18,2"] || [machine isEqual: @"MacBookPro18,3"] || [machine isEqual: @"MacBookPro18,4"])
            {
                p_cpu_nominal_freqs = [NSMutableArray arrayWithObjects: @"0", @"600", @"828", @"1056", @"1296", @"1524", @"1752", @"1980", @"2208", @"2448", @"2676", @"2904", @"3036", @"3132", @"3168", @"3228", nil];
            }
            else
            {
                p_cpu_nominal_freqs = [NSMutableArray arrayWithObjects: @"0", @"600", @"828", @"1056", @"1284", @"1500", @"1728", @"1956", @"2184", @"2388", @"2592", @"2772", @"2988", @"3096", @"3144", @"3204", nil];
            }
            
            switch(cpu_cluster)
            {
                 case 0:  nominal_freqs = e_cpu_nominal_freqs; break;
                 case 1:  nominal_freqs = p_cpu_nominal_freqs; break;
            }
        }
        
        switch(cpu_cluster)
        {
            case 0:   [user_defaults setObject:nominal_freqs forKey:cache_voltfreq0];  break;
            case 1:   [user_defaults setObject:nominal_freqs forKey:cache_voltfreq1]; break;
        }
        
        return nominal_freqs;
    }
    else
    {
        switch(cpu_cluster)
        {
            case 0:   return [user_defaults objectForKey:cache_voltfreq0];  break;
            case 1:   return [user_defaults objectForKey:cache_voltfreq1]; break;
        }
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSString * return_cpu_freq_percent(char cpu_cluster, float cpu_freq)
{
    NSString * cpu_freq_percent_string;
    
    float cpu_max_freq = 0;
    
    switch(cpu_cluster)
    {
        case 0:  cpu_max_freq = return_cpu_max_freq(ECPU); break;
        case 1:  cpu_max_freq = return_cpu_max_freq(PCPU); break;
    }
    
    if (cpu_freq <= 0.44 || ((cpu_freq / cpu_max_freq) * 100) <= 0.009)
    {
        cpu_freq_percent_string = @"Idle";
    }
    else
    {
        cpu_freq_percent_string = [NSString stringWithFormat:@"%.2f%%", (cpu_freq / cpu_max_freq) * 100];
    }
    
    return cpu_freq_percent_string;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_active_freq(char cpu_cluster, NSMutableArray * first_sample, NSMutableArray * last_sample)
{
    NSMutableArray * cpu_nominal_freqs = [NSMutableArray array];
    
    float first_sample_sum = 0;
    float last_sample_sum = 0;
    float sample_sum = 0;
    
    float state_percent = 0;
    float state_freq = 0;
    
    switch(cpu_cluster)
    {
        case 0:  cpu_nominal_freqs = get_cpu_nominal_freqs(ECPU); break;
        case 1:  cpu_nominal_freqs = get_cpu_nominal_freqs(PCPU); break;
    }
    
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
    
    if (isnan(state_freq) || state_freq > return_cpu_max_freq(cpu_cluster))
    {
        return return_cpu_max_freq(cpu_cluster);
    }

    return state_freq;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_avg_freq(float e_cluster_freq, float p_cluster_freq)
{
    NSMutableArray * cpu_cluster_freqs;
    
    float cpu_avg_freq = 0;
    float cpu_max_freq = return_cpu_max_freq(PCPU);

    cpu_cluster_freqs = [NSMutableArray arrayWithObjects: @(e_cluster_freq), @(p_cluster_freq), nil];

    for (int i = 0; i < 2; i++)
    {
        cpu_avg_freq += [cpu_cluster_freqs[i] floatValue];
    }
    
    cpu_avg_freq = cpu_avg_freq / 2;

    if (cpu_avg_freq <= 0)
    {
        cpu_avg_freq = e_cluster_freq;
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
    NSUserDefaults *        user_defaults = [NSUserDefaults standardUserDefaults];
    
    if (![user_defaults integerForKey:cache_maxfreq0] || ![user_defaults integerForKey:cache_maxfreq1])
    {
        NSMutableArray * cpu_nominal_freqs;

        switch(cpu_cluster)
        {
            case 0:   cpu_nominal_freqs = get_cpu_nominal_freqs(ECPU); [user_defaults setInteger:[cpu_nominal_freqs[[cpu_nominal_freqs count] - 1] floatValue] forKey:cache_maxfreq0]; break;
            case 1:   cpu_nominal_freqs = get_cpu_nominal_freqs(PCPU); [user_defaults setInteger:[cpu_nominal_freqs[[cpu_nominal_freqs count] - 1] floatValue] forKey:cache_maxfreq1]; break;
        }
        
        return [cpu_nominal_freqs[[cpu_nominal_freqs count] - 1] floatValue];
    }
    else
    {
        switch(cpu_cluster)
        {
            case 0:   return (float) [user_defaults integerForKey:cache_maxfreq0];  break;
            case 1:   return (float) [user_defaults integerForKey:cache_maxfreq1]; break;
        }
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int get_cpus(int cpu_cluster)
{
    NSUserDefaults *        user_defaults = [NSUserDefaults standardUserDefaults];

    if (![user_defaults integerForKey:cache_corecnt0] || ![user_defaults integerForKey:cache_corecnt1])
    {
        int                     e_core_count = 0;
        int                     p_core_count = 0;
        NSString *              machine;
        
        io_registry_entry_t     service;

        NSData *                data;
        NSString *              data_string;
        
        const unsigned char *   data_bytes;
        float                   formatted_data;
        int                     core_count;
        
        size_t len = 4;
        
        if (sysctlbyname(SYSCTL_ECPU, NULL, &len, NULL, 0) != -1 && sysctlbyname(SYSCTL_PCPU, NULL, &len, NULL, 0) != -1)
        {
            switch(cpu_cluster)
            {
                case 0:  sysctlbyname(SYSCTL_ECPU, &core_count, &len, NULL, 0); [user_defaults setInteger:core_count forKey:cache_corecnt0]; break;
                case 1:  sysctlbyname(SYSCTL_PCPU, &core_count, &len, NULL, 0); [user_defaults setInteger:core_count forKey:cache_corecnt1]; break;
            }
            
            [user_defaults setBool:NO forKey:cache_predef_corecnt];
            
            return core_count;
        }
        else if ((service = IORegistryEntryFromPath(kIOMasterPortDefault, "IODeviceTree:/cpus")) || (service = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/AppleARMPE/cpus")))
        {
            switch(cpu_cluster)
            {
                case 0:  data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("e-core-count"), kCFAllocatorDefault, 0); break;
                case 1:  data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("p-core-count"), kCFAllocatorDefault, 0); break;
            }

            if (data) {
                data_bytes = [data bytes];

                data_string  = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", data_bytes[3], data_bytes[2], data_bytes[1], data_bytes[0]];
                formatted_data = atof([data_string UTF8String]);
                
                core_count = (int)formatted_data;
                
                switch(cpu_cluster)
                {
                    case 0:  [user_defaults setInteger:core_count forKey:cache_corecnt0]; break;
                    case 1:  [user_defaults setInteger:core_count forKey:cache_corecnt1]; break;
                }
                
                [user_defaults setBool:NO forKey:cache_predef_corecnt];

                return core_count;
            }
            else
            {
                [user_defaults setBool:YES forKey:cache_predef_corecnt];
                ERROR("property data unavailable in IORegistry")
            }
        }
        else
        {
            if ([user_defaults objectForKey:cache_predef_corecnt] != nil)
            {
                switch(cpu_cluster)
                {
                    case 0:  WARNING("failed to access ECPU core counts from the IORegistry, now using predefined values. Accuracy may be affected.") break;
                    case 1:  WARNING("failed to access PCPU core counts from the IORegistry, now using predefined values. Accuracy may be affected.") break;
                }
            }
            
            [user_defaults setBool:YES forKey:cache_predef_corecnt];
            
            machine = [NSString stringWithFormat:@"%s", get_sysctl_char(SYSCTL_PRODUCT)];
            
            if ([machine isEqual: @"Macmini9,1"] || [machine isEqual: @"iMac21,1"] || [machine isEqual: @"MacBookAir10,1"] || [machine isEqual: @"MacBookPro17,1"])
            {
                e_core_count = 4;
                p_core_count = 4;
            }
            else if ([machine isEqual: @"MacBookPro18,1"] && get_sysctl_int(SYSCTL_CPUS) < 10)
            {
                e_core_count = 2;
                p_core_count = 6;
            }
            else if (([machine isEqual: @"MacBookPro18,1"] || [machine isEqual: @"MacBookPro18,2"] || [machine isEqual: @"MacBookPro18,3"] || [machine isEqual: @"MacBookPro18,4"]) && get_sysctl_int(SYSCTL_CPUS) >= 10)
            {
                e_core_count = 2;
                p_core_count = 8;
            }
            else
            {
                e_core_count = 2;
                p_core_count = 4;
            }
            
            switch(cpu_cluster)
            {
                case 0:  [user_defaults setInteger:e_core_count forKey:cache_corecnt0]; return e_core_count; break;
                case 1:  [user_defaults setInteger:p_core_count forKey:cache_corecnt1]; return p_core_count; break;
            }
        }
    }
    else
    {
        switch(cpu_cluster)
        {
            case 0:  return (int) [user_defaults integerForKey:cache_corecnt0]; break;
            case 1:  return (int) [user_defaults integerForKey:cache_corecnt1]; break;
        }
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

void print_freqs(char type, int core, float active_freq, float max_freq, char * freq_percent)
{
    if (type == 0)
    {
        printf("CPU_PACKAGE............ : %.0f MHz (%.0f MHz: %s)\n", active_freq, max_freq, freq_percent);
    }
    else if (core > -1)
    {
        printf("%cCPU_CORE_%d............ : %.0f MHz (%.0f MHz: %s)\n", type, core, active_freq, max_freq, freq_percent);
    }
    else
    {
        printf("%cCPU_CLUSTER........... : %.0f MHz (%.0f MHz: %s)\n", type, active_freq, max_freq, freq_percent);
    }
}

#endif
