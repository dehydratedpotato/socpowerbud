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
        case 0:  return [NSMutableArray arrayWithObjects: @"0", @"600", @"972", @"1332", @"1704", @"2064", nil]; break;
        case 1:  return [NSMutableArray arrayWithObjects: @"0", @"600", @"828", @"1056", @"1284", @"1500", @"1728", @"1956", @"2184", @"2388", @"2592", @"2772", @"2988", @"3096", @"3144", @"3204", nil]; break;
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSString * return_cpu_freq_percent(char cpu_cluster, float cpu_freq)
{
    NSString * cpu_freq_string;
    
    float cpu_max_freq;
    
    switch(cpu_cluster)
    {
        default: ERROR("incorrect cluster input"); break;
        case 0:  cpu_max_freq = return_cpu_max_freq(ECPU); break;
        case 1:  cpu_max_freq = return_cpu_max_freq(PCPU); break;
    }
    
    if (cpu_freq <= 0.009)
    {
        cpu_freq_string = @"Idle";
    }
    else
    {
        cpu_freq_string = [NSString stringWithFormat:@"%.2f%%", (cpu_freq / cpu_max_freq) * 100];
    }
    
    return cpu_freq_string;
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
        default: ERROR("incorrect cluster input"); break;
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
    NSMutableArray * cpu_nominal_freqs;
    
    switch(cpu_cluster)
    {
        default:  ERROR("incorrect cluster input"); break;
        case 0:   cpu_nominal_freqs = get_cpu_nominal_freqs(ECPU); break;
        case 1:   cpu_nominal_freqs = get_cpu_nominal_freqs(PCPU); break;
    }
    
    return [cpu_nominal_freqs[[cpu_nominal_freqs count] - 1] floatValue];
}

#endif
