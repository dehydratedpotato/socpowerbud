/*
 *  mxsocpwrbud.m
 *  MxSocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 6/30/22.
 *  Copyright (c) 2022 BitesPotatoBacks. All rights reserved.
 */

#include <Foundation/Foundation.h>
#include <sys/sysctl.h>
#include <getopt.h>
#include <stdarg.h>
/*
 * Main Macros
 */
#define __DEBUG__
#define __RELEASE__       "v0.1.0"

#define METRIC_RES        "%res"
#define METRIC_FREQ       "freq"
#define METRIC_PSTATE     "pstates"
#define METRIC_POWER      "power"
#define METRIC_INSTRCTS   "intstrcts"
#define METRIC_CORES      "cores"

#define UNIT_ECPU         "ecpu"
#define UNIT_PCPU         "pcpu"
#define UNIT_GPU          "gpu"
#define UNIT_ANE          "ane"

/*
 * Typedefs
 */
typedef struct command_options_set {
    float        power_measure;
    float        freq_measure;
    const char*  power_measure_un;
    const char*  freq_measure_un;
    
    unsigned int interval;
    int          samples;
    NSArray*     metrics;
    NSArray*     hide_units;
} command_options_set;

typedef struct param_set {
    const char* param_name;
    const char* description;
} param_set;

typedef struct long_opts_extended {
    struct option  getopt_long;
    const char*    description;
} long_opts_extended;

/* raw data form the ioreport */
typedef struct {
    NSMutableArray* gpu;
    NSMutableArray* ecpu;
    NSMutableArray* pcpu;
    NSMutableArray* ecores;
    NSMutableArray* pcores;
} samples_set;

/* data to format */
typedef struct {
    /* for power draw*/
    long gpu_pwr;
    long gpu_srm_pwr;
    NSMutableArray* cpu_pwr;
    NSMutableArray* cores_pwr;
    
    /* data for pstate distribs */
    NSMutableArray* gpu_st_res;
    NSMutableArray* cpu_st_res;
    
    /* data for idle res */
    float gpures;
    NSMutableArray* coreres;
    NSMutableArray* cpures;
    
    /* data for frequencies */
    float gpu_avgfreq;
    float ecpu_avgfreq;
    float pcpu_avgfreq;
    NSMutableArray* cores_avgfreq;
    
    /* static unchanging data */
    NSMutableArray* statefreqs;
    NSMutableArray* corecnts;
    NSMutableArray* extra;
} data_set;

/*
 * Global misc
 */
#define METRIC_COUNT 5 // 6 once all are ready

static struct param_set metrics_set[] =
{
    { METRIC_RES,      "show active residencies of unit(s)" },
    { METRIC_FREQ,     "show frequencies of unit(s)" },
    { METRIC_PSTATE,   "show pstate distribution of unit(s)" },
    { METRIC_POWER,    "show power consumption of unit(s)" },
//    { METRIC_INSTRCTS, "show instruction metrics of unit(s)" },
    { METRIC_CORES,    "show per-core metrics of unit(s)" }
};

#define UNITS_COUNT 3 // 4 once all are ready

static struct param_set units_set[] =
{
    { UNIT_ECPU, "efficiency cluster statistics" },
    { UNIT_PCPU, "performance cluster statistics" },
    { UNIT_GPU,  "integrated graphics statistics" },
//    { UNIT_ANE,  "neural engine statistics" },
};

#define OPT_COUNT 8

static struct long_opts_extended long_opts_set[] =
{
    {{ "help", no_argument, 0, 'h' },
        "               print this message and exit\n"
    },
    {{ "version", no_argument, 0, 'v' },
        "            print tool version number and exit\n\n"
    },
    {{ "interval", required_argument, 0, 'i' },
        " <N>       perform samples between N ms [default: 100ms]\n"
    },
    {{ "samples", required_argument, 0, 's' },
        " <N>        collect and display N samples (0=inf) [default: 1]\n\n"
    },
    {{ "metrics", required_argument, 0, 'm' },
        " <metrics>  comma separated list of metrics to report\n"
    },
    {{ "hide-unit", required_argument, 0, 'H' },
        " <unit>   comma separated list of unit statistics to hide\n\n"
    },
    {{ "set-watts", no_argument, 0, 'w' },
        "          set power measurement to watt (default is mW)\n"
    },
    {{ "set-ghz", no_argument, 0, 'g' },
        "            set frequency measurement to GHz (default is MHz)\n\n"
    },
};

/*
 * Extern declarations
 */
enum { kIOReportIterOk };

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

/*
 * Function declarations
 */
static void usage(void);
static void error(int, const char*, ...);

static void sample(unsigned int, unsigned int, bool, float, samples_set*, data_set*);
static void format(unsigned int, unsigned int, bool, samples_set*, data_set*);
static void generatefreqs(data_set*);
static void generatecorecnt(data_set*);
static void generateextra(data_set*);

static struct option* unextended_long_opts_extended(void);

/*
 * Main
 */
int main(int argc, char * argv[])
{
    @autoreleasepool
    {
        int opt      = 0;
        int optindex = 0;
        int corecntr = 0;
        
        int loop_handler = 0;
        unsigned int loop_counter = 0;

        bool ecpu = true;
        bool pcpu = true;
        bool gpu  = true;
        bool ane  = true;
        
        /* naturally true */
        bool res       = false;
        bool freq      = false;
        bool cores     = false;
        /* naturally false */
        bool pstate    = false;
        bool power     = false;
        bool intstrcts = false;
    
        command_options_set cmd;
        samples_set smpl;
        data_set dt;
        
        /* initializing our cmd opts */
        cmd.power_measure    = 1;
        cmd.freq_measure     = 1;
        cmd.power_measure_un = "mW";
        cmd.freq_measure_un  = "MHz";
        
        cmd.interval = 100; // ms
        cmd.samples  = 1;
        
        cmd.hide_units = [NSArray array];
        cmd.metrics    = [NSArray arrayWithObjects:[NSString stringWithUTF8String: METRIC_RES],
                                                   [NSString stringWithUTF8String: METRIC_FREQ],
                                                   [NSString stringWithUTF8String: METRIC_CORES], nil];
        
        /* initializing our sample data arrays and vars */
        smpl.gpu      = [NSMutableArray array];
        smpl.ecpu     = [NSMutableArray array];
        smpl.pcpu     = [NSMutableArray array];
        smpl.ecores   = [NSMutableArray array];
        smpl.pcores   = [NSMutableArray array];
        
        dt.gpu_pwr     = 0;
        dt.gpu_srm_pwr = 0;
        dt.cpu_pwr     = [NSMutableArray array];
        dt.cores_pwr   = [NSMutableArray arrayWithObjects:[NSMutableArray array],[NSMutableArray array], nil];
        
        dt.cpu_st_res      = [NSMutableArray arrayWithObjects:[NSMutableArray array],[NSMutableArray array], nil];
        dt.cores_avgfreq   = [NSMutableArray arrayWithObjects:[NSMutableArray array],[NSMutableArray array], nil];
        dt.coreres         = [NSMutableArray arrayWithObjects:[NSMutableArray array],[NSMutableArray array], nil];
        dt.cpures          = [NSMutableArray arrayWithObjects:@0.f,@0.f, nil];
        dt.gpu_st_res      = [NSMutableArray array]; // could lump into array with cpu state res, maybe next vers
        dt.statefreqs      = [NSMutableArray array];
        dt.corecnts        = [NSMutableArray array];
        dt.extra           = [NSMutableArray array];
        
        dt.gpures          = 0;
        dt.ecpu_avgfreq    = 0;
        dt.pcpu_avgfreq    = 0;
        dt.gpu_avgfreq     = 0;
        
        NSString* metrics_str;
        NSString* hide_unit_str;
        
        struct option* long_opts = unextended_long_opts_extended();
        
        while((opt = getopt_long(argc, argv, "hvi:s:m:H:wg", long_opts, &optindex)) != -1) {
            switch(opt) {
                case '?':
                case 'h': usage();
                case 'v': printf("%s %s (build %s %s)\n", getprogname(), __RELEASE__, __DATE__, __TIME__); return 0;
                case 'i': cmd.interval = atoi(optarg); break;
                case 's': cmd.samples = atoi(optarg); break;
                case 'm': metrics_str = [NSString stringWithFormat:@"%s", strdup(optarg)]; cmd.metrics = [metrics_str componentsSeparatedByString:@","]; break;
                case 'H': hide_unit_str = [NSString stringWithFormat:@"%s", strdup(optarg)]; cmd.hide_units = [hide_unit_str componentsSeparatedByString:@","]; break;
                case 'w': cmd.power_measure = 1e-3; cmd.power_measure_un = "W"; break;
                case 'g': cmd.freq_measure = 1e-3; cmd.freq_measure_un = "GHz"; break;
            }
        }
        
        for (int i = 0; i < [cmd.metrics count]; i++) {
            if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_RES]]) res = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_FREQ]]) freq = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_CORES]]) cores = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_PSTATE]]) pstate = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_POWER]]) power = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_INSTRCTS]]) intstrcts = true;
            else error(1, "Incorrect metric option \"%s\" in list", [cmd.metrics[i] UTF8String]);
        }
        
        for (int i = 0; i < [cmd.hide_units count]; i++) {
            if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_ECPU]]) ecpu = false;
            else if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_PCPU]]) pcpu = false;
            else if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_GPU]]) gpu = false;
            else if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_ANE]]) ane = false;
            else error(1, "Incorrect unit option \"%s\" in list", [cmd.hide_units[i] UTF8String]);
        }
        
        /* checking that our sample interval is proper */
        if (cmd.interval < 0)
            error(1, "Sampling interval must be a non-negative integer");
        else if (cmd.interval < 1)
            error(1, "Sampling interval must be a value larger than 0ms");
        
        /* generating static data */
        generatecorecnt(&dt);
        generatefreqs(&dt);
        generateextra(&dt);
        
        float time_frac = cmd.interval / 1e+3; // for power draw
        
        if (cmd.samples == 0) loop_handler = -1;

        while(loop_handler != cmd.samples)
        {
            sample([dt.corecnts[0] intValue], [dt.corecnts[1] intValue], cores, cmd.interval, &smpl, &dt);
            format([dt.corecnts[0] intValue], [dt.corecnts[1] intValue], cores, &smpl, &dt);
            
            fprintf(stdout, "%s %s (Sample %d):\n\n", [dt.extra[0] UTF8String], [dt.extra[1] UTF8String], loop_counter + 1);
            
            corecntr = 0;
        
            /* cpu metrics */
            for (int i = 2; i--;) {
                if (ecpu) {
                    if (i==1)
                        fprintf(stdout, "\t%d-Core %s E-Cluster:\n\n", [dt.corecnts[1-i] intValue], [dt.extra[2] UTF8String]);
                    else
                        fprintf(stdout, "\t%d-Core %s P-Cluster:\n\n", [dt.corecnts[1-i] intValue], [dt.extra[3] UTF8String]);
                        
                    if (power) fprintf(stdout, "\t\tPower Consumption: %.2f %s\n", (float)([dt.cpu_pwr[1-i] floatValue] / time_frac) * cmd.power_measure, cmd.power_measure_un);
                    if (freq)  fprintf(stdout, "\t\tActive Frequency:  %.2f %s\n", ((i==1) ? dt.ecpu_avgfreq : dt.pcpu_avgfreq) * cmd.freq_measure, cmd.freq_measure_un);
                    if (res)   fprintf(stdout, "\t\tActive Residency:  %.3f%%\n", 100-[dt.cpures[1-i] floatValue]);
                    
                    if (pstate) {
                        if (((i==1) ? dt.ecpu_avgfreq : dt.pcpu_avgfreq) != 0) {
                            fprintf(stdout, "\t\tP-State Distribution: ");
                            for (int ii = 0; ii < [dt.cpu_st_res[1-i] count]; ii++)
                                if ([dt.cpu_st_res[1-i][ii] floatValue] > 0) printf("%.f [P%d]: %.2f%% ", [dt.statefreqs[1-i][ii+1] floatValue], ii, [dt.cpu_st_res[1-i][ii] floatValue] *100);
                            printf("\b\b\n");
                        }
                    }
                    printf("\n");
                
                    if (cores) {
                        for (int ii = 0; ii < [dt.corecnts[0] intValue]; ii++) {
                            fprintf(stdout, "\t\tCore %d:\n", corecntr);
                            if (power) fprintf(stdout, "\t\t\tPower Consumption: %.2f %s\n", [dt.cores_pwr[1-i][ii] floatValue] * cmd.power_measure, cmd.power_measure_un);
                            if (freq)  fprintf(stdout, "\t\t\tActive Frequency:  %.2f %s\n", [dt.cores_avgfreq[1-i][ii] floatValue] * cmd.freq_measure, cmd.freq_measure_un);
                            if (res)   fprintf(stdout, "\t\t\tActive Residency:  %.3f%%\n", 100-[dt.coreres[1-i][ii] floatValue]);
                            corecntr++;
                        }
                        printf("\n");
                    }
                }
            }
            
            /* GPU metrics (will be moved to loop soon) */
            if (gpu) {
                fprintf(stdout, "\t%d-Core %s Integrated Graphics:\n\n", [dt.corecnts[2] intValue], ""/* [dt.extra[4] UTF8String]*/);
                if (power) fprintf(stdout, "\t\tPower Consumption: %.2f %s\n", (float)(dt.gpu_pwr / time_frac) * cmd.power_measure, cmd.power_measure_un);
                if (power) fprintf(stdout, "\t\tSRAM Power Draw:   %.2f %s\n", (float)(dt.gpu_srm_pwr / time_frac) * cmd.power_measure, cmd.power_measure_un);
                if (freq)  fprintf(stdout, "\t\tActive Frequency:  %.2f %s\n", dt.gpu_avgfreq * cmd.freq_measure, cmd.freq_measure_un);
                if (res)   fprintf(stdout, "\t\tActive Residency:  %.3f%%\n", 100-dt.gpures);
                
                if (pstate) {
                    if (dt.gpu_avgfreq != 0) {
                        fprintf(stdout, "\t\tP-State Distribution: ");
                        for (int i = 0; i < [dt.gpu_st_res count]; i++)
                            if ([dt.gpu_st_res[i] floatValue] > 0) printf("%.f [P%d]: %.2f%% ", [dt.statefreqs[2][i+1] floatValue], i, [dt.gpu_st_res[i] floatValue]  *100);
                        printf("\b\b\n\n");
                    }
                }
            }
            
            /* managing our vars to prevent horrible metric issues */
            [smpl.gpu    removeAllObjects];
            [smpl.ecpu   removeAllObjects];
            [smpl.pcpu   removeAllObjects];
            [smpl.ecores removeAllObjects];
            [smpl.pcores removeAllObjects];
            
            
            [dt.cpu_pwr       removeAllObjects];
            [dt.cores_pwr[0]  removeAllObjects];
            [dt.cores_pwr[1]  removeAllObjects];
            
            dt.gpu_pwr     = 0;
            dt.gpu_srm_pwr = 0;
            
            [dt.cpu_st_res[0]    removeAllObjects];
            [dt.cpu_st_res[1]    removeAllObjects];
            [dt.cores_avgfreq[0] removeAllObjects];
            [dt.cores_avgfreq[1] removeAllObjects];
            [dt.coreres[0]       removeAllObjects];
            [dt.coreres[1]       removeAllObjects];
            
            [dt.gpu_st_res removeAllObjects];
            
            [dt.cpures replaceObjectAtIndex:0 withObject:@0.f];
            [dt.cpures replaceObjectAtIndex:1 withObject:@0.f];
            
            dt.ecpu_avgfreq    = 0;
            dt.pcpu_avgfreq    = 0;
            dt.gpu_avgfreq     = 0;
            
            loop_counter++;
             
            /* checking to loop */
            if (cmd.samples >= 1)
                loop_handler++;
            else if (cmd.samples == 0)
                continue;
        }
        
    }
    return 0;
}

/*
 * Usage
 */
static void usage(void)
{
    fprintf(stdout, "\e[1m\nUsage: %s [-wg] [-i interval] [-s samples]\n\n\e[0m", getprogname());
    fprintf(stdout, "  A sudoless implementation to profile your Apple M-Series CPU+GPU active core\n  and cluster frequencies, residencies, power consumption, and other metrics.\n  Inspired by Powermetrics. Made with love by BitesPotatoBacks.\n\n\e[1mThe following command-line options are supported:\e[0m\n\n");

    for (int i = 0; i < OPT_COUNT; i++)
        fprintf(stdout, "    -%c, --%s%s", long_opts_set[i].getopt_long.val, long_opts_set[i].getopt_long.name, long_opts_set[i].description);
    
    fprintf(stdout, "\e[1mThe following are metrics supported by --metrics:\e[0m\n\n");
    
    for (int i = 0; i < METRIC_COUNT; i++)
        fprintf(stdout, "    %-15s%s\n", metrics_set[i].param_name, metrics_set[i].description);
    
    fprintf(stdout, "\n    default: %%res,freq,cores\n\n\e[1mThe following are units supported by --hide-units:\e[0m\n\n");
    
    for (int i = 0; i < UNITS_COUNT; i++)
        fprintf(stdout, "    %-15s%s\n", units_set[i].param_name, units_set[i].description);
    
    exit(0);
}

/*
 * we're using a customized struct for our long opts that way we can store definitions for them
 * this function is to convert that struct back the flavor we need for getopt_long()
 * inspired by a method found in pmtool
 */
static struct option* unextended_long_opts_extended(void)
{
    int count = sizeof(long_opts_set) / sizeof(long_opts_extended);
    struct option* retopt = calloc(count, sizeof(struct option));
    
    for (int i = 0; i < count; i++)
        bcopy(&long_opts_set[i].getopt_long, &retopt[i], sizeof(struct option));
    
    return retopt;
}

/*
 * nice error formatting and with exitting
 */
static void error(int exitcode, const char* format, ...) {
    va_list args;
    fprintf(stderr, "\e[1m%s:\033[0;31m error:\033[0m\e[0m ", getprogname());
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
    exit(exitcode);
}

/*
 * sample performance state counter data from IOReport and inject into nested arrays for formatting
 */
static void sample(unsigned int ecpucnt,      // ecluster core count
                   unsigned int pcpucnt,      // pcluster core count
                   bool cores,                // flag for whether getting core info
                   float ivl,                 // sampling interval (in ms)
                   samples_set* smpl,         // sample data
                   data_set* dt)              // formatted data
{
    IOReportSubscriptionRef cpusub            = NULL;
    CFDictionaryRef         cpusamples        = NULL;
    CFMutableDictionaryRef  cpuchannels       = NULL;
    CFMutableDictionaryRef  cpusubbedchannels = NULL;

    IOReportSubscriptionRef gpusub            = NULL;
    CFDictionaryRef         gpusamples        = NULL;
    CFMutableDictionaryRef  gpuchannels       = NULL;
    CFMutableDictionaryRef  gpusubbedchannels = NULL;
    
    IOReportSubscriptionRef pwrsub            = NULL;
    CFDictionaryRef         pwrsamples        = NULL;
    CFMutableDictionaryRef  pwrchannels       = NULL;
    CFMutableDictionaryRef  pwrsubbedchannels = NULL;
    
    CFDictionaryRef         cpusamples_a      = NULL;
    CFDictionaryRef         cpusamples_b      = NULL;
    CFDictionaryRef         gpusamples_a      = NULL;
    CFDictionaryRef         gpusamples_b      = NULL;
    CFDictionaryRef         pwrsamples_a      = NULL;
    CFDictionaryRef         pwrsamples_b      = NULL;

    /* creating channels */
    if (!(cpuchannels = IOReportCopyChannelsInGroup(@"CPU Stats", 0, 0, 0, 0)))
        error(1, "Failed to copy channels of IOReport CPU Stats group");
    if (!(gpuchannels = IOReportCopyChannelsInGroup(@"GPU Stats", 0, 0, 0, 0)))
        error(1, "Failed to copy channels of IOReport GPU Stats group");
    if (!(pwrchannels = IOReportCopyChannelsInGroup(@"PMP", 0, 0, 0, 0)))
        error(1, "Failed to copy channels of IOReport PMP group");
    
    /* creating subs */
    if (!(cpusub = IOReportCreateSubscription(NULL, cpuchannels, &cpusubbedchannels, 0, 0)))
        error(1, "Failed to subscribe to IOReport CPU Stats group");
    if (!(gpusub = IOReportCreateSubscription(NULL, gpuchannels, &gpusubbedchannels, 0, 0)))
        error(1, "Failed to subscribe to IOReport GPU Stats group");
    if (!(pwrsub = IOReportCreateSubscription(NULL, pwrchannels, &pwrsubbedchannels, 0, 0)))
        error(1, "Failed to subscribe to IOReport PMP group");
    
    /* Here we sample performance state counter data from the IOReport twice between an interval
    we only check errors on first samples because if these succeed that means all is well and samples after should work */
    if (!(cpusamples_a = IOReportCreateSamples(cpusub, cpusubbedchannels, NULL)))
        error(1, "Failed to first sample of IOReport CPU Stats group");
    if (!(gpusamples_a = IOReportCreateSamples(gpusub, gpusubbedchannels, NULL)))
        error(1, "Failed to first sample of IOReport GPU Stats group");
    if (!(pwrsamples_a = IOReportCreateSamples(pwrsub, pwrsubbedchannels, NULL)))
        error(1, "Failed to first sample of IOReport PMP group");
    
    [NSThread sleepForTimeInterval: (ivl * 1e-3)];
    
    cpusamples_b = IOReportCreateSamples(cpusub, cpusubbedchannels, NULL);
    gpusamples_b = IOReportCreateSamples(gpusub, gpusubbedchannels, NULL);
    pwrsamples_b = IOReportCreateSamples(pwrsub, pwrsubbedchannels, NULL);
    
    /* Now we make a delta of the samples and loop through to add the data we want to our arrays */
    if ((cpusamples = IOReportCreateSamplesDelta(cpusamples_a, cpusamples_b, NULL))) {
        IOReportIterate(cpusamples, ^(IOReportSampleRef sample) {
            for (int i = 0; i < IOReportStateGetCount(sample); i++) { // loop through all options available from sample
                if ([IOReportChannelGetSubGroup(sample) isEqual: @"CPU Complex Performance States"]) { // look for the complex performance state group(s)
                    if ([IOReportChannelGetChannelName(sample) isEqual: @"ECPU"]) // sort through the entries for ecluster
                        [smpl->ecpu addObject:@(IOReportStateGetResidency(sample, i))];
                    else if ([IOReportChannelGetChannelName(sample) isEqual: @"PCPU"]) // sort through the entries for pcluster
                        [smpl->pcpu addObject:@(IOReportStateGetResidency(sample, i))];
                }

                if (cores) {
                    if ([IOReportChannelGetSubGroup(sample) isEqual: @"CPU Core Performance States"]) { // look for the core performance state group(s)
                        /* sort through the entries for cores by matching entries to values <= core count and inject into nested arrays */
                        for (int ii = 0; ii < ecpucnt; ii++) {
                            if ([IOReportChannelGetChannelName(sample) isEqual: [NSString stringWithFormat:@"%@%d", @"ECPU", ii]]) {
                                if ([smpl->ecores count] < ecpucnt) [smpl->ecores addObject:[NSMutableArray array]];
                                [smpl->ecores[ii] addObject:@(IOReportStateGetResidency(sample, i))];
                            }
                        }
                        for (int ii = 0; ii < pcpucnt; ii++) {
                            if ([IOReportChannelGetChannelName(sample) isEqual: [NSString stringWithFormat:@"%@%d", @"PCPU", ii]]) {
                                if ([smpl->pcores count] < pcpucnt) [smpl->pcores addObject:[NSMutableArray array]];
                                [smpl->pcores[ii] addObject:@(IOReportStateGetResidency(sample, i))];
                            }
                        }
                    }
                }
            }
            return kIOReportIterOk;
        });
    } else
        error(1, "Failed to create sample delta for IOReport CPU Stats group");
    
    /* sampling for gpu following same method as for cpu clusters */
    if ((gpusamples = IOReportCreateSamplesDelta(gpusamples_a, gpusamples_b, NULL))) {
        IOReportIterate(gpusamples, ^(IOReportSampleRef sample) {
            for (int i = 0; i < IOReportStateGetCount(sample); i++) {
                if ([IOReportChannelGetSubGroup(sample) isEqual: @"GPU Performance States"]) {
                    if ([IOReportChannelGetChannelName(sample) isEqual: @"GPUPH"])
                        [smpl->gpu addObject:@(IOReportStateGetResidency(sample, i))];
                }
            }
            return kIOReportIterOk;
        });
    } else
        error(1, "Failed to create sample delta for IOReport GPU Stats group");
    
    /* same but slightly different method for pmp power (i.e no for loop) */
    if ((pwrsamples = IOReportCreateSamplesDelta(pwrsamples_a, pwrsamples_b, NULL))) {
        IOReportIterate(pwrsamples, ^(IOReportSampleRef sample) {
                if ([IOReportChannelGetSubGroup(sample) isEqual: @"Energy Counters"]) {

                    if ([IOReportChannelGetChannelName(sample) isEqual: @"ECPU"])
                        [dt->cpu_pwr addObject:@(IOReportSimpleGetIntegerValue(sample, 0))];
                    else if ([IOReportChannelGetChannelName(sample) isEqual: @"PCPU"])
                        [dt->cpu_pwr addObject:@(IOReportSimpleGetIntegerValue(sample, 0))];
                    else if ([IOReportChannelGetChannelName(sample) isEqual: @"GPU"])
                        dt->gpu_pwr = IOReportSimpleGetIntegerValue(sample, 0);
                    else if ([IOReportChannelGetChannelName(sample) isEqual: @"GPU SRAM"])
                        dt->gpu_srm_pwr = IOReportSimpleGetIntegerValue(sample, 0);
                    
                    if (cores) {
                        for (int ii = 0; ii < ecpucnt; ii++) {
                            if ([IOReportChannelGetChannelName(sample) isEqual: [NSString stringWithFormat:@"%@%d", @"ECORE", ii]]) {
                                [dt->cores_pwr[0] addObject:@(IOReportSimpleGetIntegerValue(sample, 0))];
                            }
                        }
                        for (int ii = 0; ii < pcpucnt; ii++) {
                            if ([IOReportChannelGetChannelName(sample) isEqual: [NSString stringWithFormat:@"%@%d", @"PCORE", ii]]) {
                                [dt->cores_pwr[1] addObject:@(IOReportSimpleGetIntegerValue(sample, 0))];
                            }
                        }
                    }
            
            }
            return kIOReportIterOk;
        });
    } else
        error(1, "Failed to create sample delta for IOReport PMP group");
}

/*
 * format our raw sample data into frequnecy/residency metrics
 * (this could be slimed down more with the right tricks)
 */
static void format(unsigned int ecpucnt,        // ecluster core count
                   unsigned int pcpucnt,        // pcluster core count
                   bool cores,                  // flag for whether getting core info
                   samples_set* smpl,           // sample data
                   data_set* dt)                // formatted data
{
    NSMutableArray* ecores_st_cntrvals = [NSMutableArray array];
    NSMutableArray* pcores_st_cntrvals = [NSMutableArray array];
    
    unsigned long ecpu_st_cntrvals  = 0;
    unsigned long pcpu_st_cntrvals  = 0;
    unsigned long gpu_st_cntrvals   = 0;
    
    float ecpu_freq_perc = 0;
    float pcpu_freq_perc = 0;
    float gpu_freq_perc  = 0;
    /* tmp storage for per core stuff */
    unsigned long tmp_ecore_sum = 0;
    unsigned long tmp_pcore_sum = 0;
    float tmp_ecore_freq = 0;
    float tmp_pcore_freq = 0;
    
    unsigned long max_eloop         = [smpl->ecpu count];
    unsigned long max_ploop         = [smpl->pcpu count];
    unsigned long max_gloop         = [smpl->gpu count];
    
    /* creating a sum of all the counter values from both samples */
    for (int i = 1; i < max_ploop; i++) {
        if (i < max_gloop) // looping through the gpu samples
            gpu_st_cntrvals += [smpl->gpu[i] unsignedLongValue]; // adding those diffs to a sum
        
        if (i < max_eloop) { // looping through the ecpu samples
            ecpu_st_cntrvals += [smpl->ecpu[i] unsignedLongValue];
            
            if (cores) {
                for (int ii = 0; ii < ecpucnt; ii++) { // applying same methods for the individual cores
                    if ([ecores_st_cntrvals count] < ecpucnt) [ecores_st_cntrvals addObject:[NSNumber numberWithUnsignedLong:0]];
                    tmp_ecore_sum = [ecores_st_cntrvals[ii] unsignedLongValue] + [smpl->ecores[ii][i] unsignedLongValue];
                    [ecores_st_cntrvals replaceObjectAtIndex:ii withObject:[NSNumber numberWithUnsignedLong:tmp_ecore_sum]];
                }
            }
        }
        /* same thing we did up there just for the pcpu now */
        pcpu_st_cntrvals += [smpl->pcpu[i] unsignedLongValue];
        
        if (cores) {
            for (int ii = 0; ii < pcpucnt; ii++) {
                if ([pcores_st_cntrvals count] < pcpucnt) [pcores_st_cntrvals addObject:[NSNumber numberWithUnsignedLong:0]];
                tmp_pcore_sum = [pcores_st_cntrvals[ii] unsignedLongValue] + [smpl->pcores[ii][i] unsignedLongValue];
                [pcores_st_cntrvals replaceObjectAtIndex:ii withObject:[NSNumber numberWithUnsignedLong:tmp_pcore_sum]];
            }
        }
    }
    
    /* getting our per-state freq percentages to determine our average freq */
    for (int i = 1; i < max_ploop; i++) {
        if (i < max_gloop) { // formatting gpu
            gpu_freq_perc = (float) ([smpl->gpu[i] floatValue] / gpu_st_cntrvals); // find residency of the pstate
            [dt->gpu_st_res addObject:[NSNumber numberWithFloat:gpu_freq_perc]];
            if (gpu_freq_perc > 0) dt->gpu_avgfreq += (gpu_freq_perc * [dt->statefreqs[2][i] floatValue]); // create the average freq that would come s a result of the res
        }

        if (i < max_eloop) { // formatting ecpu using same emthod
            ecpu_freq_perc = (float) ([smpl->ecpu[i] floatValue] / ecpu_st_cntrvals);
            [dt->cpu_st_res[0] addObject:[NSNumber numberWithFloat:ecpu_freq_perc]];
            if (ecpu_freq_perc > 0) dt->ecpu_avgfreq += (ecpu_freq_perc * [dt->statefreqs[0][i] floatValue]);

            if (cores) {
                for (int ii = 0; ii < ecpucnt; ii++) { // applying same methods for the individual cores
                    if ([dt->cores_avgfreq[0] count] < ecpucnt) {
                        [dt->cores_avgfreq[0] addObject:[NSNumber numberWithUnsignedLong:0]];
                        /* we quickly snatch the idle res of cores here to lessen for loop counts */
                        [dt->coreres[0] addObject:[NSNumber numberWithFloat:(((float) [smpl->ecores[ii][0] floatValue] / ([ecores_st_cntrvals[ii] floatValue] + [smpl->ecores[ii][0] floatValue])) * 100)]];
                    }
                    tmp_ecore_freq = (float) ([dt->statefreqs[0][i] longValue] * ([smpl->ecores[ii][i] floatValue] / [ecores_st_cntrvals[ii] floatValue]));
                    if (tmp_ecore_freq > 0) [dt->cores_avgfreq[0] replaceObjectAtIndex:ii withObject:[NSNumber numberWithFloat:([dt->cores_avgfreq[0][ii] floatValue] + tmp_ecore_freq)]];
                }
            }
        }
        
        /* formatting pcpu same way */
        pcpu_freq_perc = (float) ([smpl->pcpu[i] floatValue] / pcpu_st_cntrvals);
        [dt->cpu_st_res[1] addObject:[NSNumber numberWithFloat:pcpu_freq_perc]];
        if (pcpu_freq_perc > 0) dt->pcpu_avgfreq += (pcpu_freq_perc * [dt->statefreqs[1][i] floatValue]);

        if (cores) {
            for (int ii = 0; ii < pcpucnt; ii++) {
                if ([dt->cores_avgfreq[1] count] < pcpucnt) {
                    [dt->cores_avgfreq[1] addObject:[NSNumber numberWithUnsignedLong:0]];
                    [dt->coreres[1] addObject:[NSNumber numberWithFloat:(((float) [smpl->pcores[ii][0] floatValue] / ([pcores_st_cntrvals[ii] floatValue] + [smpl->pcores[ii][0] floatValue])) * 100)]];
                }
                tmp_pcore_freq = (float) ([dt->statefreqs[1][i] longValue] * ([smpl->pcores[ii][i] floatValue] / [pcores_st_cntrvals[ii] floatValue]));
                if (tmp_pcore_freq > 0) [dt->cores_avgfreq[1] replaceObjectAtIndex:ii withObject:[NSNumber numberWithFloat:([dt->cores_avgfreq[1][ii] floatValue] + tmp_pcore_freq)]];
            }
        }
    }
    
    /* getting the time spent in idle based on some already proccessed data */
    [dt->cpures replaceObjectAtIndex:0 withObject:[NSNumber numberWithFloat:(((float) [smpl->ecpu[0] unsignedLongValue] / (ecpu_st_cntrvals + [smpl->ecpu[0] unsignedLongValue])) * 100)]];
    [dt->cpures replaceObjectAtIndex:1 withObject:[NSNumber numberWithFloat:(((float) [smpl->pcpu[0] unsignedLongValue] / (pcpu_st_cntrvals + [smpl->pcpu[0] unsignedLongValue])) * 100)]];
    dt->gpures  = ((float) [smpl->gpu[0] unsignedLongValue] / (gpu_st_cntrvals + [smpl->gpu[0] unsignedLongValue])) * 100;
}

/*
 * gather our pstate nominal freq arrays
 */
static void generatefreqs(data_set* dt)
{
    NSData* frmt_data;
    NSString* datastrng;
    
    const unsigned char* databytes;
    
    io_registry_entry_t entry;
    io_iterator_t       iter;
    mach_port_t         port = kIOMasterPortDefault;
    
    CFMutableDictionaryRef servicedict;
    CFMutableDictionaryRef service;
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;
    
    /* accessing pmgr for pstate freqs, using a service matching method to increase portability */
    for (int i = 3; i--;) {
        if (!(service = IOServiceMatching("AppleARMIODevice")))
            error(1, "Failed to find AppleARMIODevice service in IORegistry");
        if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
            error(1, "Failed to access AppleARMIODevice service in IORegistry");
    
        while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
            if (IORegistryEntryCreateCFProperties(entry, &servicedict, kCFAllocatorDefault, 0) != kIOReturnSuccess)
                error(1, "Failed to create CFProperties for AppleARMIODevice service in IORegistry");

            const void* data = nil;
            
            switch(i) {
                case 2: data = CFDictionaryGetValue(servicedict, @"voltage-states1-sram"); break;
                case 1: data = CFDictionaryGetValue(servicedict, @"voltage-states5-sram"); break;
                case 0: data = CFDictionaryGetValue(servicedict, @"voltage-states9"); break;
            }

            if (data != nil) {
                [dt->statefreqs addObject:[NSMutableArray array]];
                if (i > 0) [dt->statefreqs[2-i] addObject:@0];
                
                frmt_data = (NSData*)CFBridgingRelease(data);
                databytes = [frmt_data bytes];

                /* data is formatted as 32-bit litte endian hex, converting to a human readable integer */
                for (int ii = 4; ii < ([frmt_data length] + 4); ii += 8) {
                    datastrng = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", databytes[ii-1], databytes[ii-2], databytes[ii-3], databytes[ii-4]];
                    [dt->statefreqs[2-i] addObject:[NSNumber numberWithFloat:atof([datastrng UTF8String]) * 1e-6]];
                }
                break;
            }
        }
        
        IOObjectRelease(entry);
        IOObjectRelease(iter);
    }
}

/*
 * gather our ecpu/pcpu/gpu core counts
 */
static void generatecorecnt(data_set* dt)
{
    NSString*            datastrng;
    const unsigned char* databytes;
    
    io_registry_entry_t entry;
    io_iterator_t       iter;
    mach_port_t         port = kIOMasterPortDefault;
    
    CFMutableDictionaryRef servicedict;
    CFMutableDictionaryRef service;
    CFTypeRef gpucorecnt;
    
    if (@available(macOS 12, *)) port = kIOMainPortDefault;

cpu_a:
    /* finding cpu core counts using a service matching method to increase portability */
    for (int i = 2; i--;) {
        if (!(service = IOServiceMatching("IOPlatformDevice")))
            error(1, "Failed to find IOPlatformDevice service in IORegistry");
        if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
            error(1, "Failed to access IOPlatformDevice service in IORegistry");

        while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
            if (IORegistryEntryCreateCFProperties(entry, &servicedict, kCFAllocatorDefault, 0) != kIOReturnSuccess)
                error(1, "Failed to create CFProperties for IOPlatformDevice service in IORegistry");

            const void* data = CFDictionaryGetValue(servicedict, i==1 ? @"e-core-count" : @"p-core-count");
            if (data != nil) {
                databytes = [(NSData*)CFBridgingRelease(data) bytes];
                datastrng = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", databytes[3], databytes[2], databytes[1], databytes[0]];
                [dt->corecnts addObject:[NSNumber numberWithInt: (int) atof([datastrng UTF8String])]];
                break;
            } else
                goto cpu_b;
        }
    }
    
    goto gpu;
    
cpu_b: /* we jump to this spot in case the core counts don't exist in IOPlatformDevice */
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

            for (int ii = 4; ii < ([frmt_data length] + 4); ii += 4) {
                datastrng = [NSString stringWithFormat:@"0x%02x%02x%02x%02x", databytes[ii-1], databytes[ii-2], databytes[ii-3], databytes[ii-4]];
                [dt->corecnts addObject:[NSNumber numberWithInt: (int) atof([datastrng UTF8String])]];
            }
        }
    }
    
gpu: /* finding GPU core counts, same method */
    if (!(service = IOServiceMatching("AGXAccelerator")))
        error(1, "Failed to find AGXAccelerator service in IORegistry");
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        error(1, "Failed to access AGXAccelerator service in IORegistry");
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        if (!(gpucorecnt = IORegistryEntrySearchCFProperty(entry, kIOServicePlane, CFSTR("gpu-core-count"), kCFAllocatorDefault, kIORegistryIterateRecursively | kIORegistryIterateParents)))
            error(1, "Failed to read \"gpu-core-count\" from AGXAccelerator service in IORegistry");
        
        [dt->corecnts addObject:[NSNumber numberWithInt:[(__bridge NSNumber *)gpucorecnt intValue]]];
    }
    
    IOObjectRelease(entry);
    IOObjectRelease(iter);
}

/*
 * figure out siliocn IDs code names, and cluster microarchs
 */
static void generateextra(data_set* dt)
{
    size_t len;
    char*  mib = "machdep.cpu.brand_string";

    if (sysctlbyname(mib, NULL, &len, NULL, 0) == -1)
        error(1, "Failed to query \"machdep.cpu.brand_string\" from sysctl");
    
    char*  cpubrand = malloc(len);
    sysctlbyname(mib, cpubrand, &len, NULL, 0);

    [dt->extra addObject:[NSString stringWithFormat:@"%s", cpubrand, nil]];
    
    /* silicon ID based on marketing name until can pull ID from reg */
    if ([dt->extra[0] rangeOfString:@"M1"].location != NSNotFound) {
        if ([dt->extra[0] rangeOfString:@"M1 Pro"].location != NSNotFound)
            [dt->extra addObject:@"T6000"];
        else if ([dt->extra[0] rangeOfString:@"M1 Max"].location != NSNotFound)
            [dt->extra addObject:@"T6001"];
        else if ([dt->extra[0] rangeOfString:@"M1 Ultra"].location != NSNotFound)
            [dt->extra addObject:@"T6002"];
        else
            [dt->extra addObject:@"T8103"];
    } else if ([dt->extra[0] rangeOfString:@"M2"].location != NSNotFound)
        [dt->extra addObject:@"T****"];
    
    /* determining microarch */
    if ([dt->extra[0] rangeOfString:@"M1"].location != NSNotFound) {
        [dt->extra addObject:@"Icestorm"];
        [dt->extra addObject:@"Firestorm"];
    } else if ([dt->extra[0] rangeOfString:@"M2"].location != NSNotFound) {
        [dt->extra addObject:@"Blizzard"];
        [dt->extra addObject:@"Avalanche"];
    } else {
        [dt->extra addObject:@"Unknown"];
        [dt->extra addObject:@"Unknown"];
    }
}
