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

#ifndef arm64_h
#define arm64_h

#if defined(__aarch64__)

#include "../universal/universal.h"

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

#define SYSCTL_ECPU     "hw.perflevel0.physicalcpu"
#define SYSCTL_PCPU     "hw.perflevel1.physicalcpu"

#define ECPU            0
#define PCPU            1

#define COMPLEX         0
#define CORE            1

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

NSMutableArray * get_cpu_states(char cpu_cluster, int cpu_sub_group, int cpu_core);
NSMutableArray * get_cpu_nominal_freqs(char cpu_cluster);

NSString * return_cpu_freq_percent(char cpu_cluster, float cpu_freq);

float return_cpu_active_freq(char cpu_cluster, NSMutableArray * first_sample, NSMutableArray * last_sample);
float return_cpu_avg_freq(float e_cluster_freq, float p_cluster_freq);
float return_cpu_max_freq(char cpu_cluster);

// - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

enum { kIOReportIterOk };

typedef struct IOReportSubscriptionRef* IOReportSubscriptionRef;
typedef CFDictionaryRef IOReportSampleRef;

extern IOReportSubscriptionRef IOReportCreateSubscription(void* a, CFMutableDictionaryRef desiredChannels, CFMutableDictionaryRef* subbedChannels, uint64_t channel_id, CFTypeRef b);
extern CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub, CFMutableDictionaryRef subbedChannels, CFTypeRef a);

extern CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString*, NSString*, uint64_t, uint64_t, uint64_t);
extern CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t, uint64_t);

typedef int (^ioreportiterateblock)(IOReportSampleRef ch);
extern void IOReportIterate(CFDictionaryRef samples, ioreportiterateblock);

extern int IOReportGetChannelCount(CFMutableDictionaryRef);
extern int IOReportChannelGetFormat(CFDictionaryRef samples);
extern long IOReportSimpleGetIntegerValue(CFDictionaryRef, int);

extern int IOReportStateGetCount(CFDictionaryRef);
extern uint64_t IOReportStateGetResidency(CFDictionaryRef, int);
extern NSString* IOReportStateGetNameForIndex(CFDictionaryRef, int);
extern NSString* IOReportChannelGetChannelName(CFDictionaryRef);
extern NSString* IOReportChannelGetGroup(CFDictionaryRef);
extern NSString* IOReportChannelGetSubGroup(CFDictionaryRef);
extern uint64_t IOReportArrayGetValueAtIndex(CFDictionaryRef, int);

#endif
#endif /* arm64_h */
