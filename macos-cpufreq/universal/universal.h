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

#ifndef universal_h
#define universal_h

#include <sys/sysctl.h>
#include <getopt.h>

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#define VERSION         "2.6.0"

#define ERROR(ERR)      { printf("\e[1mmacos-cpufreq\e[0m:\033[0;31m error:\033[0m %s\n", ERR); exit(-1); }
#define WARNING(WRN)    { printf("\e[1mmacos-cpufreq\e[0m:\033[0;35m warning:\033[0m %s\n", WRN); }
#define ALERT(ALRT)     { printf("\e[1mmacos-cpufreq\e[0m:\033[0;32m alert:\033[0m %s\n", ALRT); exit(0); }

#define SYSCTL_PRODUCT   "hw.product"
#define SYSCTL_CPUS      "hw.physicalcpu"
#define SYSCTL_CPU_MODEL "machdep.cpu.brand_string"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

struct options
{
    bool all;
    bool efficiency;
    bool performance;
    bool cores;
    bool all_cores;
    bool cluster;
    bool all_cluster;
    bool package;
    bool looping;
    bool selecting_core;

    int loop;
    int select_core;
    
    float interval;
};

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

int get_sysctl_int(char * entry);
uint64_t get_sysctl_uint64(char * entry);
char * get_sysctl_char(char * entry);

#endif /* universal_h */
