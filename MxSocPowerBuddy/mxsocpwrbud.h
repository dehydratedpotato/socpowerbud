/*
 *  samplers.h
 *  MxSocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 7/19/22.
 *  Copyright (c) 2022 BitesPotatoBacks. All rights reserved.
 */

#ifndef mxsocpwrbud_h
#define mxsocpwrbud_h

#include <Foundation/Foundation.h>
#include <sys/sysctl.h>

/*
 * Extern declarations
 */
enum {
    kIOReportIterOk
};

typedef struct IOReportSubscriptionRef* IOReportSubscriptionRef;
typedef CFDictionaryRef IOReportSampleRef;

extern IOReportSubscriptionRef IOReportCreateSubscription(void* a, CFMutableDictionaryRef desiredChannels, CFMutableDictionaryRef* subbedChannels, uint64_t channel_id, CFTypeRef b);
extern CFDictionaryRef IOReportCreateSamples(IOReportSubscriptionRef iorsub, CFMutableDictionaryRef subbedChannels, CFTypeRef a);
extern CFDictionaryRef IOReportCreateSamplesDelta(CFDictionaryRef prev, CFDictionaryRef current, CFTypeRef a);

extern CFMutableDictionaryRef IOReportCopyChannelsInGroup(NSString*, NSString*, uint64_t, uint64_t, uint64_t);

typedef int (^ioreportiterateblock)(IOReportSampleRef ch);
extern void IOReportIterate(CFDictionaryRef samples, ioreportiterateblock);

extern int IOReportStateGetCount(CFDictionaryRef);
extern uint64_t IOReportStateGetResidency(CFDictionaryRef, int);
extern long IOReportSimpleGetIntegerValue(CFDictionaryRef, int);
extern NSString* IOReportChannelGetChannelName(CFDictionaryRef);
extern NSString* IOReportChannelGetSubGroup(CFDictionaryRef);
extern NSString* IOReportStateGetNameForIndex(CFDictionaryRef, int);

extern void IOReportMergeChannels(CFMutableDictionaryRef, CFMutableDictionaryRef, CFTypeRef);
extern NSString* IOReportChannelGetGroup(CFDictionaryRef);
/*
 * Typedefs
 */

/* raw data form the ioreport */
typedef struct {
    /* data for Nergy Model*/
    IOReportSubscriptionRef pwrsub;
    CFMutableDictionaryRef  pwrsubchn;
    CFMutableDictionaryRef  pwrchn_eng;
    CFMutableDictionaryRef  pwrchn_pmp;

    /* datat for CPU/GPU Stats */
    IOReportSubscriptionRef cpusub;
    CFMutableDictionaryRef  cpusubchn;
    CFMutableDictionaryRef  cpuchn_cpu;
    CFMutableDictionaryRef  cpuchn_gpu;
} iorep_data;

typedef struct {
    NSArray* complex_pwr_channels;
    NSArray* core_pwr_channels;
    
    NSArray* complex_freq_channels;
    NSArray* core_freq_channels;
    
    NSMutableArray* pstate_nominal_freqs_holder;
    NSArray* pstate_nominal_freqs;
    NSMutableArray* cluster_core_counts;
    int gpu_core_count;
    
    NSMutableArray* extra;
} static_data;

typedef struct {
    /* data for freuencies */
    NSMutableArray* cluster_sums;
    NSMutableArray* cluster_residencies;
    NSMutableArray* cluster_freqs;

    NSMutableArray* core_sums;
    NSMutableArray* core_residencies;
    NSMutableArray* core_freqs;

    
    /* data for usage */
    NSMutableArray* cluster_use;
    NSMutableArray* core_use;
    
    /* data for power draw */
    NSMutableArray* cluster_pwrs;
    NSMutableArray* core_pwrs;
} variating_data;

/* for cmd opts */
typedef struct cmd_data {
    float        power_measure;
    float        freq_measure;
    const char*  power_measure_un;
    const char*  freq_measure_un;
    
    unsigned int interval;
    int          samples;
    NSArray*     metrics;
    NSArray*     hide_units;
} cmd_data;


/*
 * Function declarations
 */
void error(int, const char*, ...);

void sample(iorep_data*, static_data*, variating_data*, cmd_data*);
void format(static_data*, variating_data*);

void generatePstates(static_data*);
void generateCoreCounts(static_data*);

void generateProcessorName(static_data* sd);
void generateSiliconsIds(static_data*);
void generateMicroArchs(static_data*);

#endif /* mxsocpwrbud_h */
