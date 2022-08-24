/*
 *  iorepdump.m
 *  SocPowerBuddy (IOReportDumper)
 *
 *  Created by BitesPotatoBacks on 8/19/22.
 *  Copyright (c) 2022 BitesPotatoBacks. All rights reserved.
 */

#include "../SocPowerBuddy/socpwrbud.h"

extern CFMutableDictionaryRef IOReportCopyAllChannels(uint64_t, uint64_t);
extern int IOReportChannelGetFormat(CFDictionaryRef samples);

enum {
    kIOReportInvalidFormat     = 0,
    kIOReportFormatSimple      = 1,
    kIOReportFormatState       = 2,
    kIOReportFormatSimpleArray = 4
};

NSString* getcpu(void)
{
    size_t len = 32;
    char*  cpubrand = malloc(len);
    sysctlbyname("machdep.cpu.brand_string", cpubrand, &len, NULL, 0);

    NSString* ret = [NSString stringWithFormat:@"%s", cpubrand, nil];
    
    free(cpubrand);
    
    return ret;
}

int main(int argc, char* argv[])
{
    @autoreleasepool
    {
        NSString* cpu = getcpu();
        int clusters = 2;
        
        if (([cpu rangeOfString:@"Pro"].location != NSNotFound) ||
            ([cpu rangeOfString:@"Max"].location != NSNotFound))
            clusters = 3;
        else if ([cpu rangeOfString:@"Ultra"].location != NSNotFound)
            clusters = 6;
        
        CFMutableDictionaryRef  subchn = NULL;
        CFMutableDictionaryRef  chn    = IOReportCopyAllChannels(0, 0);
        IOReportSubscriptionRef sub    = IOReportCreateSubscription(NULL, chn, &subchn, 0, 0);

        IOReportIterate(IOReportCreateSamples(sub, subchn, NULL), ^(IOReportSampleRef sample) {
            NSString* group         = IOReportChannelGetGroup(sample);
            NSString* subgroup      = IOReportChannelGetSubGroup(sample);
            NSString* chann_name    = IOReportChannelGetChannelName(sample);
            
            if ([group isEqual:@"CPU Stats"]  ||
                [group isEqual:@"GPU Stats"]  ||
                [group isEqual:@"AMC Stats"]  ||
                [group isEqual:@"CLPC Stats"] ||
                [group isEqual:@"PMP"]        ||
                [group isEqual:@"Energy Model"])  {
            
                switch (IOReportChannelGetFormat(sample)) {
                    case kIOReportFormatSimple:
                        printf("Grp: %s   Subgrp: %s   Chn: %s   Int: %ld\n", [group UTF8String] , [subgroup UTF8String], [chann_name UTF8String], IOReportSimpleGetIntegerValue(sample, 0));
                        break;
                    case kIOReportFormatState:
                        for (int i = 0; i < IOReportStateGetCount(sample); i++)
                            printf("Grp: %s   Subgrp: %s   Chn: %s   State: %s   Res: %lld\n", [group UTF8String] , [subgroup UTF8String], [chann_name UTF8String], [IOReportStateGetNameForIndex(sample, i) UTF8String], IOReportStateGetResidency(sample, i));
                        break;
                    case kIOReportFormatSimpleArray:
                        for (int i = 0; i < clusters; i++)
                            printf("Grp: %s   Subgrp: %s   Chn: %s   Arr: %lld\n", [group UTF8String] , [subgroup UTF8String], [chann_name UTF8String], IOReportArrayGetValueAtIndex(sample, i));
                        break;
                }
                
            }
            return kIOReportIterOk;
        });
    
        return 0;
    }
}
