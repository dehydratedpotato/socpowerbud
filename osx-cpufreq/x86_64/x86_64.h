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

#ifndef x86_64_h
#define x86_64_h

#if defined(__x86_64__)

#include "model_data/model_data.h"
#include "../universal/universal.h"
#include <mach/mach_time.h>
#include <x86intrin.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#define SYSCTL_CPUS      "hw.physicalcpu"
#define SYSCTL_CPU_MODEL "machdep.cpu.brand_string"
#define SYSCTL_MACHINE   "hw.product"

#define RATED            0
#define TURBO            1

#define FIRST_MEASURE   { asm volatile("firstmeasure:\ndec %[counter]\njnz firstmeasure\n " : [counter] "+r"(cycles)); }
#define LAST_MEASURE    { asm volatile("lastmeasure:\ndec %[counter]\njnz lastmeasure\n " : [counter] "+r"(cycles)); }
                               
// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

float get_cpu_active_freq(void);
float return_cpu_active_freq(void);
float return_cpu_static_freq(int type);

#endif
#endif /* x86_64_h */
