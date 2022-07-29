/*
 *  sampler.m
 *  MxSocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 7/19/22.
 *  Copyright (c) 2022 BitesPotatoBacks. All rights reserved.
 */

#include "mxsocpwrbud.h"

void sample(iorep_data* iorep,  // holds our channel subs from the iorep
            static_data* sd,    // for accessing static data(i.e. core counts, cluster counts, etc)
            variating_data* vd, // for get/setting variating data (i.e. residencies from the iorep)
            cmd_data* cmd)      // command line arg data (i.e. intervals)
{
    CFDictionaryRef cpu_delta = NULL;
    CFDictionaryRef pwr_delta = NULL;
    CFDictionaryRef cpusamp_a = NULL;
    CFDictionaryRef cpusamp_b = NULL;
    CFDictionaryRef pwrsamp_a = NULL;
    CFDictionaryRef pwrsamp_b = NULL;
    
    NSString* ptype_state     = @"P";
    NSString* vtype_state     = @"V";
    NSString* idletype_state  = @"IDLE";
    NSString* offtype_state   = @"OFF";
    
    /*
     * Creating dual samples so we may find the delta between them
     */
    cpusamp_a = IOReportCreateSamples(iorep->cpusub, iorep->cpusubchn, NULL);
    pwrsamp_a = IOReportCreateSamples(iorep->pwrsub, iorep->pwrsubchn, NULL);
    
    [NSThread sleepForTimeInterval:(cmd->interval*1e-3)];
    
    cpusamp_b = IOReportCreateSamples(iorep->cpusub, iorep->cpusubchn, NULL);
    pwrsamp_b = IOReportCreateSamples(iorep->pwrsub, iorep->pwrsubchn, NULL);
    
    //IOReport
    
    /*
     * Iterating through the delta(s) of our CPU/GPU Stat samples (for our frequencies)
     */
    cpu_delta = IOReportCreateSamplesDelta(cpusamp_a, cpusamp_b, NULL);
    pwr_delta = IOReportCreateSamplesDelta(pwrsamp_a, pwrsamp_b, NULL);
    
    IOReportIterate(cpu_delta, ^(IOReportSampleRef sample) {
        for (int i = 0; i < IOReportStateGetCount(sample); i++) {
            NSString* subgroup    = IOReportChannelGetSubGroup(sample);
            NSString* idx_name    = IOReportStateGetNameForIndex(sample, i);
            NSString* chann_name  = IOReportChannelGetChannelName(sample);
            uint64_t  residency   = IOReportStateGetResidency(sample, i);
            
            for (int ii = 0; ii < [sd->complex_freq_channels count]; ii++) {
                if ([subgroup isEqual: @"CPU Complex Performance States"] || [subgroup isEqual: @"GPU Performance States"]) {
                    if ([chann_name isEqual:sd->complex_freq_channels[ii]]) {
                        if ([idx_name rangeOfString:ptype_state].location != NSNotFound ||
                            [idx_name rangeOfString:vtype_state].location != NSNotFound)
                        {
                            vd->cluster_sums[ii] = [NSNumber numberWithUnsignedLongLong:([vd->cluster_sums[ii] unsignedLongLongValue] + residency)];
                            [vd->cluster_residencies[ii] addObject:[NSNumber numberWithUnsignedLongLong:residency]];
                        } else if ([idx_name rangeOfString:idletype_state].location != NSNotFound ||
                                   [idx_name rangeOfString:offtype_state].location != NSNotFound)
                            vd->cluster_use[ii] = [NSNumber numberWithUnsignedLongLong:residency];
                    }
                } else if ([subgroup isEqual:@"CPU Core Performance States"]) {
                    if (ii <= ([sd->cluster_core_counts count]-1)) {
                        for (int iii = 0; iii < [sd->cluster_core_counts[ii] intValue]; iii++) {
                            if ([chann_name isEqual:[NSString stringWithFormat:@"%@%d",sd->core_freq_channels[ii], iii, nil]]) {
                                if ([idx_name rangeOfString:ptype_state].location != NSNotFound ||
                                    [idx_name rangeOfString:vtype_state].location != NSNotFound)
                                {
                                    vd->core_sums[ii][iii] = [NSNumber numberWithUnsignedLongLong:([vd->core_sums[ii][iii] unsignedLongLongValue] + residency)];
                                    [vd->core_residencies[ii][iii] addObject:[NSNumber numberWithUnsignedLongLong:residency]];
                                } else if ([idx_name rangeOfString:idletype_state].location != NSNotFound ||
                                           [idx_name rangeOfString:offtype_state].location != NSNotFound)
                                    vd->core_use[ii][iii] = [NSNumber numberWithUnsignedLongLong:residency];
                            }
                        }
                    }
                }
            }
        }
        return kIOReportIterOk;
    });
    
    /*
     * Iterating through the delta(s) of our Energy Model samples
     */
    IOReportIterate(pwr_delta, ^(IOReportSampleRef sample) {
        NSString* chann_name  = IOReportChannelGetChannelName(sample);
        NSString* group       = IOReportChannelGetGroup(sample);
        long      value       = IOReportSimpleGetIntegerValue(sample, 0);
        
        for (int ii = 0; ii < [sd->complex_freq_channels count]; ii++) {
            if ([group isEqual:@"Energy Model"]) {
                if ([chann_name isEqual:sd->complex_pwr_channels[ii]])
                    vd->cluster_pwrs[ii] = [NSNumber numberWithFloat:(float)value/(cmd->interval/1e+3)];
                
                if (ii <= ([sd->cluster_core_counts count]-1)) {
                    for (int iii = 0; iii < [sd->cluster_core_counts[ii] intValue]; iii++) {
                        if ([chann_name isEqual:[NSString stringWithFormat:@"%@%d",sd->core_pwr_channels[ii], iii, nil]])
                            vd->core_pwrs[ii][iii] = [NSNumber numberWithFloat:(float)value/(cmd->interval/1e+3)];
                    }
                }
            }
            
            /*
             * the GPU entry doen't seem to exist on Apple M1 Energy Model (probably same with M2)
             * so we are grabbing that from the PMP
             */
            if ([sd->extra[0] isEqual:@"Apple M1"] || [sd->extra[0] isEqual:@"Apple M2"]) {
                if ([group isEqual:@"PMP"]) {
                    if ([chann_name isEqual:@"GPU"])
                        vd->cluster_pwrs[[vd->cluster_pwrs count]-1] = [NSNumber numberWithFloat:(float)value/(cmd->interval/1e+3)];
                }
            }
        }
        
        return kIOReportIterOk;
    });
    
    CFRelease(cpu_delta);
    CFRelease(pwr_delta);
    
    CFRelease(cpusamp_a);
    CFRelease(cpusamp_b);
    CFRelease(pwrsamp_a);
    CFRelease(pwrsamp_b);
    
//    iorep->cpusamp_a = iorep->cpusamp_b;
//    iorep->pwrsamp_a = iorep->pwrsamp_b;
}

void format(static_data* sd, variating_data* vd)
{
    uint64_t res = 0;
    uint64_t core_res = 0;
    
    for (int i = 0; i < [sd->complex_freq_channels count]; i++) {
        /* formatting cpu freqs */
        for (int ii = 0; ii < [vd->cluster_residencies[i] count]; ii++) {
            res = [vd->cluster_residencies[i][ii] unsignedLongLongValue];
            if (res != 0) {
                float perc = (res / [vd->cluster_sums[i] floatValue]);
                vd->cluster_freqs[i] = [NSNumber numberWithFloat:([vd->cluster_freqs[i] floatValue] + ([sd->pstate_nominal_freqs[i][ii] floatValue]*perc))];
                [vd->cluster_residencies[i] replaceObjectAtIndex:ii withObject:[NSNumber numberWithFloat:perc]];
            }

            if (i <= ([sd->cluster_core_counts count]-1)) {
                for (int iii = 0; iii < [sd->cluster_core_counts[i] intValue]; iii++) {
                    core_res = [vd->core_residencies[i][iii][ii] unsignedLongLongValue];
                    if (core_res != 0) {
                        float core_perc = (core_res / [vd->core_sums[i][iii] floatValue]);
                        vd->core_freqs[i][iii] = [NSNumber numberWithFloat:([vd->core_freqs[i][iii] floatValue] + ([sd->pstate_nominal_freqs[i][ii] floatValue]*core_perc))];
                    }
                }
            }
        }
        
        /* formatting active residency */
        vd->cluster_use[i] = [NSNumber numberWithFloat:(100-([vd->cluster_use[i] floatValue]/([vd->cluster_sums[i] floatValue]+[vd->cluster_use[i] floatValue]))*100)];
        
        if (i <= ([sd->cluster_core_counts count]-1)) {
            for (int iii = 0; iii < [sd->cluster_core_counts[i] intValue]; iii++)
                vd->core_use[i][iii] = [NSNumber numberWithFloat:(100-([vd->core_use[i][iii] floatValue]/([vd->core_sums[i][iii] floatValue]+[vd->core_use[i][iii] floatValue]))*100)];
        }
    }
}
