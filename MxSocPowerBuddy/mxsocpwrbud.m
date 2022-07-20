/*
 *  mxsocpwrbud.m
 *  MxSocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 6/30/22.
 *  Copyright (c) 2022 BitesPotatoBacks. All rights reserved.
 */

#include <getopt.h>
#include <stdarg.h>
#include "bridge.h"

/*
 * Main Macros
 */
#define __DEBUG__
#define __RELEASE__       "v0.1.1"

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

typedef struct param_set {
    const char* param_name;
    const char* description;
} param_set;

typedef struct long_opts_extended {
    struct option  getopt_long;
    const char*    description;
} long_opts_extended;

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
        " <N>       perform samples between N ms [default: 475ms]\n"
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

static void usage(void);
static struct option* unextended_long_opts_extended(void);


/*
 * Main
 */
int main(int argc, char * argv[])
{
    @autoreleasepool
    {
        iorep_data iorep;
        variating_data vd;
        static_data sd;
        cmd_data cmd;
        
        /* initializing our cmd opts */
        cmd.power_measure    = 1;
        cmd.freq_measure     = 1;
        cmd.power_measure_un = "mW";
        cmd.freq_measure_un  = "MHz";
        
        cmd.interval = 475;
        cmd.samples  = 1;
        
        cmd.hide_units = [NSArray array];
        cmd.metrics    = [NSArray arrayWithObjects:[NSString stringWithUTF8String: METRIC_RES],
                                                   [NSString stringWithUTF8String: METRIC_FREQ],
//                                                   [NSString stringWithUTF8String: METRIC_PSTATE],
//                                                   [NSString stringWithUTF8String: METRIC_POWER],
                                                   [NSString stringWithUTF8String: METRIC_CORES], nil];
        /* command line arg flag vars and rando */
        int opt      = 0;
        int optindex = 0;
        unsigned int current_core = 0;
        unsigned int current_loop = 0;

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
        
        NSString* metrics_str;
        NSString* hide_unit_str;
        
        struct option* long_opts = unextended_long_opts_extended();
        /* parsing cmd opts */
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
        /* processing metric values */
        for (int i = 0; i < [cmd.metrics count]; i++) {
            if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_RES]]) res = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_FREQ]]) freq = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_CORES]]) cores = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_PSTATE]]) pstate = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_POWER]]) power = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_INSTRCTS]]) intstrcts = true;
            else error(1, "Incorrect metric option \"%s\" in list", [cmd.metrics[i] UTF8String]);
        }
        /* processing hidden unit values */
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
        
        
        /* init our static data arrays */
        sd.gpu_core_count = 0;
        sd.pstate_nominal_freqs_holder = [NSMutableArray array];
        sd.cluster_core_counts         = [NSMutableArray array];
        sd.extra                       = [NSMutableArray array];
        
        generatefreqs(&sd);
        generateextra(&sd);
        generatecorecnt(&sd);
        
        /* generating data to support other silicon */
        if (([sd.extra[0] rangeOfString:@"Pro"].location != NSNotFound) ||
            ([sd.extra[0] rangeOfString:@"Max"].location != NSNotFound))
        {
            sd.complex_pwr_channels = @[@"EACC_CPU", @"PACC0_CPU", @"PACC1_CPU", @"GPU0"];
            sd.core_pwr_channels    = @[@"EACC_CPU", @"PACC0_CPU", @"PACC1_CPU"];

            sd.complex_freq_channels = @[@"ECPU", @"PCPU", @"PCPU1", @"GPUPH"];
            sd.core_freq_channels    = @[@"ECPU0", @"PCPU0", @"PCPU1"];
            
            sd.pstate_nominal_freqs = @[ sd.pstate_nominal_freqs_holder[0],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[2]];
            
        } else if ([sd.extra[0] rangeOfString:@"Ultra"].location != NSNotFound) {
            sd.complex_pwr_channels = @[@"EACC_CPU0", @"EACC_CPU1", @"PACC0_CPU", @"PACC1_CPU", @"PACC2_CPU", @"PACC3_CPU", @"GPU0"];
            sd.core_pwr_channels    = @[@"EACC_CPU0", @"EACC_CPU1", @"PACC0_CPU", @"PACC1_CPU", @"PACC2_CPU", @"PACC3_CPU",];

            sd.complex_freq_channels = @[@"ECPU", @"ECPU1", @"PCPU", @"PCPU1", @"PCPU2", @"PCPU3", @"GPUPH"];
            sd.core_freq_channels    = @[@"ECPU0", @"ECPU1", @"PCPU0", @"PCPU1",  @"PCPU2", @"PCPU3"];
            
            sd.pstate_nominal_freqs = @[ sd.pstate_nominal_freqs_holder[0],
                                         sd.pstate_nominal_freqs_holder[0],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[2]];
        } else {
            sd.complex_pwr_channels = @[@"ECPU", @"PCPU", @"GPU"];
            sd.core_pwr_channels    = @[@"ECPU", @"PCPU"];

            sd.complex_freq_channels = @[@"ECPU", @"PCPU", @"GPUPH"];
            sd.core_freq_channels    = @[@"ECPU", @"PCPU"];
            
            sd.pstate_nominal_freqs = @[ sd.pstate_nominal_freqs_holder[0],
                                         sd.pstate_nominal_freqs_holder[1],
                                         sd.pstate_nominal_freqs_holder[2]];
        }

        
        /* init our varaiting data arrays */
        
        vd.cluster_sums         = [NSMutableArray array];
        vd.cluster_residencies  = [NSMutableArray array];
        vd.cluster_freqs        = [NSMutableArray array];
        
        vd.core_sums            = [NSMutableArray array];
        vd.core_residencies     = [NSMutableArray array];
        vd.core_freqs           = [NSMutableArray array];
        
        vd.cluster_pwrs         = [NSMutableArray array];
        vd.core_pwrs            = [NSMutableArray array];
        
        vd.cluster_use         = [NSMutableArray array];
        vd.core_use            = [NSMutableArray array];

        for (int i = 0; i < ([sd.cluster_core_counts count]+1); i++) { // +1 extra arr for GPU
            [vd.cluster_residencies addObject:[NSMutableArray array]];
            [vd.cluster_pwrs addObject:@0];
            [vd.cluster_freqs addObject:@0];
            [vd.cluster_use addObject:@0];
            [vd.cluster_sums addObject:@0];
            
            if (i <= ([sd.cluster_core_counts count]-1)) {
                [vd.core_pwrs addObject:[NSMutableArray array]];
                [vd.core_residencies addObject:[NSMutableArray array]];
                [vd.core_freqs addObject:[NSMutableArray array]];
                [vd.core_use addObject:[NSMutableArray array]];
                [vd.core_sums addObject:[NSMutableArray array]];
            }
        }
        
        for (int i = 0; i < ([sd.cluster_core_counts count]); i++) {
            for (int ii = 0; ii < [sd.cluster_core_counts[i] intValue]; ii++) {
                [vd.core_pwrs[i] addObject:[NSMutableArray array]];
                [vd.core_residencies[i] addObject:[NSMutableArray array]];
                [vd.core_use[i] addObject:@0];
                [vd.core_freqs[i] addObject:@0];
                [vd.core_sums[i] addObject:@0];
            }
        }
        
        /* subscribing to ioreport stuff here so we don't waste resources constantly pulling the data from within our loop */
        iorep.cpusubchn = NULL;
        iorep.pwrsubchn = NULL;
        iorep.cpusamp_a = NULL;
        iorep.cpusamp_b = NULL;
        iorep.pwrsamp_a = NULL;
        iorep.pwrsamp_b = NULL;
        iorep.cpuchn_cpu = IOReportCopyChannelsInGroup(@"CPU Stats", 0, 0, 0, 0);
        iorep.cpuchn_gpu = IOReportCopyChannelsInGroup(@"GPU Stats", 0, 0, 0, 0);
        iorep.pwrchn_eng = IOReportCopyChannelsInGroup(@"Energy Model", 0, 0, 0, 0);
        iorep.pwrchn_pmp = IOReportCopyChannelsInGroup(@"PMP", 0, 0, 0, 0);
        
        IOReportMergeChannels(iorep.cpuchn_cpu, iorep.cpuchn_gpu, NULL);
        IOReportMergeChannels(iorep.pwrchn_eng, iorep.pwrchn_pmp, NULL);

        iorep.cpusub = IOReportCreateSubscription(NULL, iorep.cpuchn_cpu, &iorep.cpusubchn, 0, 0);
        iorep.pwrsub = IOReportCreateSubscription(NULL, iorep.pwrchn_eng, &iorep.pwrsubchn, 0, 0);
        
        
        if (cmd.samples <= 0) cmd.samples = -1;
        for(int L = cmd.samples; L--;) {
            sample(&iorep, &sd, &vd, &cmd);
            format(&sd, &vd);
            
            current_core = 0;
            fprintf(stdout, "%s %s (Sample %d):\n\n", [sd.extra[0] UTF8String], [sd.extra[1] UTF8String], current_loop + 1);
            
            for (int i = 0; i < [vd.cluster_freqs count]; i++) {
                
                /* making sure non of the ic metrics should be hidden */
                if ((ecpu && [sd.complex_freq_channels[i] rangeOfString:@"ECPU"].location != NSNotFound) ||
                    (pcpu && [sd.complex_freq_channels[i] rangeOfString:@"PCPU"].location != NSNotFound) ||
                    (gpu && [sd.complex_freq_channels[i] rangeOfString:@"GPU"].location != NSNotFound)) {
                
                    char* microarch = "?";
                    
                    /* setting microarch for cpu cluster */
                    if ([sd.complex_freq_channels[i] rangeOfString:@"ECPU"].location != NSNotFound) microarch = (char*)[sd.extra[2] UTF8String];
                    else if ([sd.complex_freq_channels[i] rangeOfString:@"PCPU"].location != NSNotFound) microarch = (char*)[sd.extra[3] UTF8String];
                    
                    /* setting header based on ic */
                    if ([sd.complex_freq_channels[i] rangeOfString:@"CPU"].location != NSNotFound)
                        fprintf(stdout, "\t%d-Core %s %s:\n\n", [sd.cluster_core_counts[i] intValue], microarch, [sd.complex_freq_channels[i] UTF8String]);
                    else
                        fprintf(stdout, "\t%d-Core Integrated Graphics:\n\n", sd.gpu_core_count);

                    /*
                     * printing outputs based on tuned cmd args
                     */
                    if (power) fprintf(stdout, "\t\tPower Consumption: %.2f %s\n", [vd.cluster_pwrs[i] floatValue] * cmd.power_measure, cmd.power_measure_un);
                    if (freq)  fprintf(stdout, "\t\tActive Frequency:  %.2f %s\n", [vd.cluster_freqs[i] floatValue] * cmd.freq_measure, cmd.freq_measure_un);
                    if (res)   fprintf(stdout, "\t\tActive Residency:  %.2f%%\n",  [vd.cluster_use[i] floatValue]);
                    
                    if (pstate) {
                        if ([vd.cluster_freqs[i] floatValue] > 0) {
                            fprintf(stdout, "\t\tP-State Distribution: (");
                            for (int iii = 0; iii < [sd.pstate_nominal_freqs[i] count]; iii++) {
                                float res = [vd.cluster_residencies[i][iii] floatValue];
                                if (res > 0) {
                                    fprintf(stdout, "%.f MHz: %.2f%%  ",[sd.pstate_nominal_freqs[i][iii] floatValue], [vd.cluster_residencies[i][iii] floatValue]*100);
                                }
                            }
                            printf("\b\b)\n");
                        }
                    }
                    printf("\n");
                    
                    if (i <= ([sd.cluster_core_counts count]-1)) {
                        for (int ii = 0; ii < [sd.cluster_core_counts[i] intValue]; ii++) {
                            fprintf(stdout, "\t\tCore %d:\n", /*[sd.complex_freq_channels[i] UTF8String], ii,*/current_core);
                            if (power) fprintf(stdout, "\t\t\tPower Consumption: %.2f %s\n", [vd.core_pwrs[i][ii] floatValue] * cmd.power_measure, cmd.power_measure_un);
                            if (freq)  fprintf(stdout, "\t\t\tActive Frequency:  %.2f %s\n", [vd.core_freqs[i][ii] floatValue] * cmd.freq_measure, cmd.freq_measure_un);
                            if (res)   fprintf(stdout, "\t\t\tActive Residency:  %.2f%%\n", [vd.core_use[i][ii] floatValue]);
                            current_core++;
                        }
                        printf("\n");
                    }
                }
            }
            
            /* emptying our arrays */
            
            for (int i = 0; i < ([sd.cluster_core_counts count]+1); i++) {
                [vd.cluster_residencies[i] removeAllObjects];
                vd.cluster_pwrs[i] = @0;
                vd.cluster_use[i] = @0;
                vd.cluster_sums[i] = @0;
                vd.cluster_freqs[i] = @0;
            }

            for (int i = 0; i < ([sd.cluster_core_counts count]); i++) {
                for (int ii = 0; ii < [sd.cluster_core_counts[i] intValue]; ii++) {
                    [vd.core_residencies[i][ii] removeAllObjects];
                    vd.core_pwrs[i][ii] = @0;
                    vd.core_use[i][ii] = @0;
                    vd.core_freqs[i][ii] = @0;
                    vd.core_sums[i][ii] = @0;
                }
            }
            
            current_loop++;
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
void error(int exitcode, const char* format, ...) {
    va_list args;
    fprintf(stderr, "\e[1m%s:\033[0;31m error:\033[0m\e[0m ", getprogname());
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
    exit(exitcode);
}
