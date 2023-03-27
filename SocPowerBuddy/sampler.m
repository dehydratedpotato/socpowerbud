/*
 *  sampler.m
 *  SocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 7/19/22.
 *  Copyright (c) 2022 BitesPotatoBacks.
 */

#include "socpwrbud.h"

void sample(iorep_data* iorep,  // holds our channel subs from the iorep
            static_data* sd,    // for accessing static data(i.e. core counts, cluster counts, etc)
            variating_data* vd, // for get/setting variating data (i.e. residencies from the iorep)
            cmd_data* cmd)      // command line arg data (i.e. intervals)
{
    NSString* ptype_state     = @"P";
    NSString* vtype_state     = @"V";
    NSString* idletype_state  = @"IDLE";
    NSString* offtype_state   = @"OFF";
    
    CFDictionaryRef cpusamp_a  = IOReportCreateSamples(iorep->cpusub, iorep->cpusubchn, NULL);
    CFDictionaryRef pwrsamp_a  = IOReportCreateSamples(iorep->pwrsub, iorep->pwrsubchn, NULL);
    CFDictionaryRef clpcsamp_a = IOReportCreateSamples(iorep->clpcsub, iorep->clpcsubchn, NULL);
    
    [NSThread sleepForTimeInterval: (cmd->interval * 1e-3)];
    
    CFDictionaryRef cpusamp_b  = IOReportCreateSamples(iorep->cpusub, iorep->cpusubchn, NULL);
    CFDictionaryRef pwrsamp_b  = IOReportCreateSamples(iorep->pwrsub, iorep->pwrsubchn, NULL);
    CFDictionaryRef clpcsamp_b = IOReportCreateSamples(iorep->clpcsub, iorep->clpcsubchn, NULL);
    
    // deltas
    CFDictionaryRef cpu_delta  = IOReportCreateSamplesDelta(cpusamp_a, cpusamp_b, NULL);
    CFDictionaryRef pwr_delta  = IOReportCreateSamplesDelta(pwrsamp_a, pwrsamp_b, NULL);
    CFDictionaryRef clpc_delta = IOReportCreateSamplesDelta(clpcsamp_a, clpcsamp_b, NULL);
    
    CFRelease(cpusamp_a);
    CFRelease(cpusamp_b);
    CFRelease(pwrsamp_a);
    CFRelease(pwrsamp_b);
    CFRelease(clpcsamp_a);
    CFRelease(clpcsamp_b);
    
    IOReportIterate(cpu_delta, ^(IOReportSampleRef sample) {
        for (int i = 0; i < IOReportStateGetCount(sample); i++) {
            NSString* subgroup    = IOReportChannelGetSubGroup(sample);
            NSString* idx_name    = IOReportStateGetNameForIndex(sample, i);
            NSString* chann_name  = IOReportChannelGetChannelName(sample);
            uint64_t  residency   = IOReportStateGetResidency(sample, i);
            
            for (int ii = 0; ii < [sd->complex_freq_channels count]; ii++) {
                if ([subgroup isEqual: @"CPU Complex Performance States"] || [subgroup isEqual: @"GPU Performance States"])
                {
                    if ([chann_name isEqual:sd->complex_freq_channels[ii]])
                    {
                        if ([idx_name rangeOfString:ptype_state].location != NSNotFound ||
                            [idx_name rangeOfString:vtype_state].location != NSNotFound)
                        {
                            NSNumber* a = [[NSNumber alloc] initWithUnsignedLongLong:([vd->cluster_sums[ii] unsignedLongLongValue] + residency)];
                            NSNumber* b = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                            
                            vd->cluster_sums[ii] = a;
                            [vd->cluster_residencies[ii] addObject:b];
                            
                            a = nil;
                            b = nil;
                            
                        } else if ([idx_name rangeOfString:idletype_state].location != NSNotFound ||
                                   [idx_name rangeOfString:offtype_state].location != NSNotFound)
                        {
                            NSNumber* a = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                            
                            vd->cluster_use[ii] = a;
                            
                            a = nil;
                        }
                    }
                }
                else if ([subgroup isEqual:@"CPU Core Performance States"])
                {
                    if (ii <= ([sd->cluster_core_counts count]-1))
                    {
                        for (int iii = 0; iii < [sd->cluster_core_counts[ii] intValue]; iii++)
                        {
                            @autoreleasepool {
                                NSString* key = [NSString stringWithFormat:@"%@%d",sd->core_freq_channels[ii], iii, nil];
                                
                                if ([chann_name isEqual:key]) {
                                    if ([idx_name rangeOfString:ptype_state].location != NSNotFound ||
                                        [idx_name rangeOfString:vtype_state].location != NSNotFound)
                                    {
                                        NSNumber* a = [[NSNumber alloc] initWithUnsignedLongLong:([vd->core_sums[ii][iii] unsignedLongLongValue] + residency)];
                                        NSNumber* b = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                                        
                                        vd->core_sums[ii][iii] = a;
                                        [vd->core_residencies[ii][iii] addObject:b];
                                        
                                        a = nil;
                                        b = nil;
                                        
                                    } else if ([idx_name rangeOfString:idletype_state].location != NSNotFound ||
                                               [idx_name rangeOfString:offtype_state].location != NSNotFound)
                                    {
                                        NSNumber* a = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                                        
                                        vd->core_use[ii][iii] = a;
                                        
                                        a = nil;
                                        
                                    }
                                }
                                
                                key = nil;
                            }
                        }
                    }
                }
            }
            
            chann_name = nil;
            subgroup = nil;
            idx_name = nil;
        }
        
        return kIOReportIterOk;
    });
    
    IOReportIterate(pwr_delta, ^(IOReportSampleRef sample) {
        NSString* chann_name  = IOReportChannelGetChannelName(sample);
        NSString* group       = IOReportChannelGetGroup(sample);
        long      value       = IOReportSimpleGetIntegerValue(sample, 0);
        
        if ([group isEqual:@"Energy Model"]) {
            for (int ii = 0; ii < [sd->complex_freq_channels count]; ii++) {
                
                if ([chann_name isEqual:sd->complex_pwr_channels[ii]])
                {
                    NSNumber* a = [[NSNumber alloc] initWithFloat:(float)value/(cmd->interval*1e-3)];
                    
                    vd->cluster_pwrs[ii] = a;
                    
                    a = nil;
                }
                
                if (ii <= ([sd->cluster_core_counts count]-1))
                {
                    for (int iii = 0; iii < [sd->cluster_core_counts[ii] intValue]; iii++)
                    {
                        @autoreleasepool
                        {
                            NSString* val = [[NSString alloc] initWithFormat:@"%@%d",sd->core_pwr_channels[ii], iii, nil];
                            
                            if ([chann_name isEqual:val])
                            {
                                NSNumber* a = [[NSNumber alloc] initWithFloat:(float)value/(cmd->interval*1e-3)];
                                
                                vd->core_pwrs[ii][iii] = a;
                                
                                a = nil;
                            }
                            
                            val = nil;
                            
                        }
                    }
                }
            }
        }
        
        /*
         * the GPU entry doen't seem to exist on Apple M1 Energy Model (probably same with M2)
         * so we are grabbing that from the PMP
         */
        if ([group isEqual:@"PMP"] && [chann_name isEqual:@"GPU"]) {
            if ([sd->extra[0] isEqual:@"Apple M1"] || [sd->extra[0] isEqual:@"Apple M2"]) {
                
                NSNumber* a = [[NSNumber alloc] initWithFloat:(float)value/(cmd->interval*1e-3)];
                
                vd->cluster_pwrs[[vd->cluster_pwrs count]-1] = a;
                
                a = nil;
            }
        }
        
        chann_name = nil;
        group = nil;
        
        return kIOReportIterOk;
    });
    
    IOReportIterate(clpc_delta, ^(IOReportSampleRef sample) {
        NSString* chann_name  = IOReportChannelGetChannelName(sample);
        
        for (int i = 0; i < [sd->cluster_core_counts count]; i++) {
            long value = IOReportArrayGetValueAtIndex(sample, i);
            
            NSNumber* a = [[NSNumber alloc] initWithLong:value];
            
            if ([chann_name isEqual:@"CPU cycles, by cluster"])
                [vd->cluster_instrcts_clk addObject:a];
            if ([chann_name isEqual:@"CPU instructions, by cluster"])
                [vd->cluster_instrcts_ret addObject:a];
            
            a = nil;
        }
        
        if ([vd->cluster_instrcts_ret count] == [sd->cluster_core_counts count]) return kIOReportIterFailed; // Naming makes this an incorrect usage but it exits our iteration, so...
        
        chann_name = nil;
        
        return kIOReportIterOk;
    });
    
    CFRelease(cpu_delta);
    CFRelease(pwr_delta);
    CFRelease(clpc_delta);
}

void format(static_data* sd, variating_data* vd)
{
    uint64_t res = 0;
    uint64_t core_res = 0;
    
    for (int i = 0; i < [sd->complex_freq_channels count]; i++) {
        /* formatting cpu freqs */
        for (int ii = 0; ii < [vd->cluster_residencies[i] count]; ii++)
        {
            @autoreleasepool
            {
                res = [vd->cluster_residencies[i][ii] unsignedLongLongValue];
                
                if (res != 0)
                {
                    float perc = (res / [vd->cluster_sums[i] floatValue]);\
                    
                    NSNumber* a = [[NSNumber alloc] initWithFloat: perc];
                    NSNumber* b = [[NSNumber alloc] initWithFloat: ([vd->cluster_freqs[i] floatValue] + ([sd->dvfm_states[i][ii] floatValue]*perc))];
                    NSNumber* v = [[NSNumber alloc] initWithFloat: ([vd->cluster_volts[i] floatValue] + ([sd->dvfm_states_voltages[i][ii] floatValue]*perc))];
                    
                    vd->cluster_freqs[i] = b;
                    vd->cluster_volts[i] = v;
                    [vd->cluster_residencies[i] replaceObjectAtIndex:ii withObject:a];
                    
                    a = nil;
                    b = nil;
                    v = nil;
                }
                
                if (i <= ([sd->cluster_core_counts count]-1)) {
                    for (int iii = 0; iii < [sd->cluster_core_counts[i] intValue]; iii++) {
                        
                        core_res = [vd->core_residencies[i][iii][ii] unsignedLongLongValue];
                        
                        if (core_res != 0)
                        {
                            float core_perc = (core_res / [vd->core_sums[i][iii] floatValue]);
                            
                            NSNumber* a  = [[NSNumber alloc] initWithFloat:core_perc];
                            NSNumber* b = [[NSNumber alloc] initWithFloat: ([vd->core_freqs[i][iii] floatValue] +
                                                                            ([sd->dvfm_states[i][ii] floatValue] *
                                                                             core_perc))];
                            NSNumber* v = [[NSNumber alloc] initWithFloat: ([vd->core_volts[i][iii] floatValue] +
                                                                            ([sd->dvfm_states_voltages[i][ii] floatValue] *
                                                                             core_perc))];
                            
                            vd->core_freqs[i][iii] = b;
                            vd->core_volts[i][iii] = v;
                            [vd->core_residencies[i][iii] replaceObjectAtIndex:ii withObject:a];
                            
                            a = nil;
                            b = nil;
                            v = nil;
                        }
                    }
                }
            }
        }
        
        /* formatting idle residency */
        vd->cluster_use[i] = [[NSNumber alloc] initWithFloat:(([vd->cluster_use[i] floatValue] /
                                                         ([vd->cluster_sums[i] floatValue] +
                                                          [vd->cluster_use[i] floatValue])) * 100)];
        
        if (i <= ([sd->cluster_core_counts count]-1)) {
            for (int iii = 0; iii < [sd->cluster_core_counts[i] intValue]; iii++) {
                NSNumber* a = [[NSNumber alloc] initWithFloat:(100 - ([vd->core_use[i][iii] floatValue] /
                                                                   ([vd->core_sums[i][iii] floatValue] +
                                                                    [vd->core_use[i][iii] floatValue])) * 100)];
                vd->core_use[i][iii] = a;
                
                a = nil;
            }
        }
    }
}
