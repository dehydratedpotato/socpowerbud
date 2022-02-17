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

#if defined(__x86_64__)

#include <Foundation/Foundation.h>
#include "x86_64.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float get_cpu_active_freq(void)
{
    float cpu_freq;
    
    int magic_number = 2 << 16;

    mach_timebase_info_data_t info;
    mach_timebase_info(&info);
    size_t cycles;

    uint64_t first_sample_begin = mach_absolute_time();

    cycles = magic_number * 2;
    FIRST_MEASURE

    uint64_t first_sample_end = mach_absolute_time();
    double first_ns_set = (double) (first_sample_end - first_sample_begin) * (double)info.numer / (double)info.denom;
    uint64_t lastSampleBegin = mach_absolute_time();

    cycles = magic_number;
    LAST_MEASURE

    uint64_t last_sample_end = mach_absolute_time();
    double last_ns_set = (double) (last_sample_end - lastSampleBegin) * (double)info.numer / (double)info.denom;
    double nanoseconds = (first_ns_set - last_ns_set);

    cpu_freq = (float)(magic_number / nanoseconds);
    
    return cpu_freq * 1e+3;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_active_freq(void)
{
    float cpu_freq = get_cpu_active_freq();
    float max_freq = return_cpu_static_freq(TURBO);
    
    if (cpu_freq > max_freq)
    {
        return max_freq;
    }
    else if (cpu_freq < 800)
    {
        return 800;
    }
    else
    {
        return cpu_freq;
    }
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_static_freq(int type)
{
    NSString * machine;
    NSString * cpu_model;
    NSString * cpu_max_freq;
    
    NSMutableArray * cpu_model_array;
    NSDictionary * cpu_dictionary;
    
    float cpu_max_freq_rated = 0;
    float cpu_max_freq_turbo = 0;
    
    machine = [NSString stringWithFormat:@"%s", get_sysctl_string(SYSCTL_MACHINE)];
    machine = [machine stringByReplacingOccurrencesOfString:@"[^a-zA-Z]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [machine length])];
    
    cpu_model = [NSString stringWithFormat:@"%s", get_sysctl_string(SYSCTL_CPU_MODEL)];
    cpu_model = [cpu_model stringByReplacingOccurrencesOfString:@"[@]" withString:@"" options:NSRegularExpressionSearch range:NSMakeRange(0, [cpu_model length])];
    
    cpu_model_array = [[cpu_model componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] mutableCopy];
    
    if ([machine isEqual:@"MacBook"])
    {
        cpu_dictionary = generate_macbook_data();
    }
    else if ([machine isEqual:@"MacBookAir"])
    {
        cpu_dictionary = generate_macbook_air_data();
    }
    else if ([machine isEqual:@"MacBookPro"])
    {
        cpu_dictionary = generate_macbook_pro_data();
    }
    
    if ([machine isEqual:@"iMac"])
    {
        cpu_dictionary = generate_imac_data();
    }
    else if ([machine isEqual:@"iMacPro"])
    {
        cpu_dictionary = generate_imac_pro_data();
    }
    else if ([machine isEqual:@"Macmini"])
    {
        cpu_dictionary = generate_mac_mini_data();
    }
    else if ([machine isEqual:@"MacPro"])
    {
        cpu_dictionary = generate_mac_pro_data();
    }
    
    for (int i = 0; i < [cpu_model_array count]; i++)
    {
        if (!([[cpu_dictionary valueForKey:cpu_model_array[i]] floatValue] <= 0))
        {
            cpu_max_freq = [cpu_dictionary valueForKey:cpu_model_array[i]];
        }
    }

    cpu_max_freq_turbo = [cpu_max_freq floatValue];
    
    if (cpu_max_freq_turbo <= 0 && [[cpu_model_array lastObject] floatValue] > 0)
    {
        cpu_max_freq_turbo = [[cpu_model_array lastObject] floatValue] * 1e+3;
        WARNING("defaulting to base")
    }
    
    if ([[cpu_model_array lastObject] floatValue] > 0)
    {
        cpu_max_freq_rated = [[cpu_model_array lastObject] floatValue] * 1e+3;
    }
    
    switch(type)
    {
        default:    ERROR("no maximum frequency type has been chsoen"); break;
        case 0:     return cpu_max_freq_rated;
        case 1:     return cpu_max_freq_turbo;
    }
}

#endif
