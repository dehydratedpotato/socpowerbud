/*
 *  static.m
 *  SocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 7/19/22.
 *  Copyright (c) 2022 BitesPotatoBacks.
 */

#include "socpwrbud.h"

/*
 * gather our dvfm nominal freq arrays
 */
void generateDvfmTable(static_data* sd)
{
    NSData* frmt_data;
    NSString* datastrng = [[NSString alloc] init];
    
    const unsigned char* databytes;
    
    io_registry_entry_t entry;
    io_iterator_t       iter;
    mach_port_t         port = kIOMasterPortDefault;
    
    CFMutableDictionaryRef servicedict;
    CFMutableDictionaryRef service;
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;
    
    /* accessing pmgr for dvfm freqs, using a service matching method to increase portability */
    for (int i = 3; i--;) {
        if (!(service = IOServiceMatching("AppleARMIODevice")))
            error(1, "Failed to find AppleARMIODevice service in IORegistry");
        if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
            error(1, "Failed to access AppleARMIODevice service in IORegistry");
    
        while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
            if (IORegistryEntryCreateCFProperties(entry, &servicedict, kCFAllocatorDefault, 0) != kIOReturnSuccess)
                error(1, "Failed to create CFProperties for AppleARMIODevice service in IORegistry");

            const void* data = nil;
            
            /* maybe i'll add voltage-states-13-sram in the future for higher end silicon, but it's not all that necessary anyway... */
            switch(i) {
                case 2: data = CFDictionaryGetValue(servicedict, @"voltage-states1-sram"); break;
                case 1: data = CFDictionaryGetValue(servicedict, @"voltage-states5-sram"); break;
                case 0: data = CFDictionaryGetValue(servicedict, @"voltage-states9"); break;
            }

            if (data != nil) {
                [sd->dvfm_states_holder addObject:[NSMutableArray array]];
                
                frmt_data = (NSData*)CFBridgingRelease(data);
                databytes = [frmt_data bytes];

                /* data is formatted as 32-bit litte-endian hexadecimal, converting to an array of human readable integers */
                for (int ii = 4; ii < ([frmt_data length] + 4); ii += 8) {
                    datastrng = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", databytes[ii-1], databytes[ii-2], databytes[ii-3], databytes[ii-4]];
                    float freq = atof([datastrng UTF8String]) * 1e-6;
                    
                    if (freq != 0) // this will just skip the dvfm freqs of 0 mhz
                        [sd->dvfm_states_holder[2-i] addObject:[NSNumber numberWithFloat:atof([datastrng UTF8String]) * 1e-6]];
                }
                
                break;
            }
        }
        
        IOObjectRelease(entry);
        IOObjectRelease(iter);
        CFRelease(service);
        CFRelease(servicedict);
    }
}

/*
 * gather our complex core counts
 */
void generateCoreCounts(static_data* sd)
{
    NSString*           datastrng = [[NSString alloc] init];
    
    io_registry_entry_t entry;
    io_iterator_t       iter;
    mach_port_t         port = kIOMasterPortDefault;
    
    CFMutableDictionaryRef servicedict;
    CFMutableDictionaryRef service;
    CFTypeRef gpucorecnt;
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;

    /* reading cluster core counts from the pmgr again with a service matching method */
    if (!(service = IOServiceMatching("AppleARMIODevice")))
        error(1, "Failed to find AppleARMIODevice service in IORegistry");
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        error(1, "Failed to access AppleARMIODevice service in IORegistry");

    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        if (IORegistryEntryCreateCFProperties(entry, &servicedict, kCFAllocatorDefault, 0) != kIOReturnSuccess)
            error(1, "Failed to create CFProperties for AppleARMIODevice service in IORegistry");

        const void* data = CFDictionaryGetValue(servicedict, @"clusters");;

        if (data != nil) {
            NSData* frmt_data = (NSData*)CFBridgingRelease(data);
            const unsigned char* databytes = [frmt_data bytes];
            
            /* every 4th index after the first is our byte data for the cluster core count */
            for (int ii = 0; ii < [frmt_data length]; ii += 4) {
                datastrng = [NSString stringWithFormat:@"%02x", databytes[ii]];
                
                /* Ultra support */
                if ([sd->extra[0] rangeOfString:@"Ultra"].location != NSNotFound) {
                    for (int i = 2; i--;)
                        [sd->cluster_core_counts addObject:[NSNumber numberWithInt: (int) atof([datastrng UTF8String])]];
                } else
                    [sd->cluster_core_counts addObject:[NSNumber numberWithInt: (int) atof([datastrng UTF8String])]];
            }
        }
    }

    /* pull gpu core counts from a different spot */
    if (!(service = IOServiceMatching("AGXAccelerator")))
        error(1, "Failed to find AGXAccelerator service in IORegistry");
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        error(1, "Failed to access AGXAccelerator service in IORegistry");
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        if (!(gpucorecnt = IORegistryEntrySearchCFProperty(entry, kIOServicePlane, CFSTR("gpu-core-count"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents)))
            error(1, "Failed to read \"gpu-core-count\" from AGXAccelerator service in IORegistry");
        
        /* the data here is just a straight int so we don't need to use a loop */
        sd->gpu_core_count = [(__bridge NSNumber *)gpucorecnt intValue];
    }
    
    IOObjectRelease(entry);
    IOObjectRelease(iter);
    CFRelease(servicedict);
}

/*
 * find silicon id from ioreg
 */
void generateSiliconsIds(static_data * sd)
{
    io_registry_entry_t entry;
    io_iterator_t       iter;
    mach_port_t         port = kIOMasterPortDefault;
    
    CFMutableDictionaryRef servicedict;
    CFMutableDictionaryRef service;
    
    if (!(service = IOServiceMatching("IOPlatformExpertDevice")))
        goto error;
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        goto error;
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        if ((IORegistryEntryCreateCFProperties(entry, &servicedict, kCFAllocatorDefault, 0) != kIOReturnSuccess))
            goto error;
        
        const void* data = CFDictionaryGetValue(servicedict, @"platform-name");;
        
        if (data != nil) {
            NSData* frmt_data = (NSData*)CFBridgingRelease(data);
            const unsigned char* databytes = [frmt_data bytes];
            [sd->extra addObject:[[NSString stringWithFormat:@"%s", databytes] capitalizedString]];
        } else
            goto error;
    }
    
    IOObjectRelease(entry);
    IOObjectRelease(iter);
    CFRelease(service);
    
    return;
    
error:
    /* find the silicon id using stored strings if can't access ioreg */
    if ([sd->extra[0] rangeOfString:@"M1"].location != NSNotFound) {
        if ([sd->extra[0] rangeOfString:@"M1 Pro"].location != NSNotFound)
            [sd->extra addObject:@"T6000"];
        else if ([sd->extra[0] rangeOfString:@"M1 Max"].location != NSNotFound)
            [sd->extra addObject:@"T6001"];
        else if ([sd->extra[0] rangeOfString:@"M1 Ultra"].location != NSNotFound)
            [sd->extra addObject:@"T6002"];
        else
            [sd->extra addObject:@"T8103"];
    } else if ([sd->extra[0] isEqual:@"Apple M2"])
        [sd->extra addObject:@"T8112"];
    else
        [sd->extra addObject:@"T****"];
}

/*
 * find micro archs from ioreg
 */
void generateMicroArchs(static_data* sd)
{
    io_registry_entry_t     service;
    NSData *                data;

    const unsigned char *   ecpu_microarch;
    const unsigned char *   pcpu_microarch;
    
    int cores = [sd->cluster_core_counts[0] intValue] + [sd->cluster_core_counts[1] intValue] - 1;
    
    if ((service = IORegistryEntryFromPath(kIOMasterPortDefault, "IOService:/AppleARMPE/cpu0"))) {
        if ((data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("compatible"), kCFAllocatorDefault, 0)))
            ecpu_microarch = [data bytes];
        else
            goto error;
    } else
        goto error;
    
    if ((service = IORegistryEntryFromPath(kIOMasterPortDefault,
                                           [[NSString stringWithFormat:@"IOService:/AppleARMPE/cpu%d", cores] UTF8String])))
    {
        if ((data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("compatible"), kCFAllocatorDefault, 0)))
            pcpu_microarch = [data bytes];
        else
            goto error;
    } else
        goto error;
    
    [sd->extra addObject:[[[NSString stringWithFormat:@"%s", ecpu_microarch]
                           componentsSeparatedByString:@","][1] capitalizedString]];
    [sd->extra addObject:[[[NSString stringWithFormat:@"%s", pcpu_microarch]
                           componentsSeparatedByString:@","][1] capitalizedString]];

    return;
    
error:
    /* find the mirco arch using stored strings if can't access ioreg */
    if ([sd->extra[0] rangeOfString:@"M1"].location != NSNotFound) {
        [sd->extra addObject:@"Icestorm"];
        [sd->extra addObject:@"Firestorm"];
    } else if ([sd->extra[0] rangeOfString:@"M2"].location != NSNotFound) {
        [sd->extra addObject:@"Blizzard"];
        [sd->extra addObject:@"Avalanche"];
    } else {
        [sd->extra addObject:@"Unknown"];
        [sd->extra addObject:@"Unknown"];
    }
}

/*
 * find cpu model name
 */
void generateProcessorName(static_data* sd)
{
    size_t len = 32;
    char*  cpubrand = malloc(len);
    sysctlbyname("machdep.cpu.brand_string", cpubrand, &len, NULL, 0);

    if (strcmp(cpubrand, "") != 0)
        [sd->extra addObject:[NSString stringWithFormat:@"%s", cpubrand, nil]];
    else
        [sd->extra addObject:@"Unknown SoC"];
    
    free(cpubrand);
}
