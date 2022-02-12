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

float return_cpu_active_freq(void)
{
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

    float cpu_freq = (float)(magic_number / nanoseconds);

    return cpu_freq * 1e+3;
}

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float return_cpu_max_freq(void)
{
    uint64_t first_sample = __rdtsc();
    sleep(1);
    uint64_t last_sample = __rdtsc();

    return (float)((last_sample - first_sample) / 1e+6);
}

#endif
