/*
 *  socpwrbud.m
 *  SocPowerBuddy
 *
 *  Created by BitesPotatoBacks on 6/30/22.
 *  Copyright (c) 2022 BitesPotatoBacks.
 */

#include <getopt.h>
#include <stdarg.h>
#include "socpwrbud.h"

/*
 * Main Macros
 */
#define __DEBUG__
#define __RELEASE__       "v0.3.1"

#define METRIC_ACTIVE     "%active"
#define METRIC_IDLE       "%idle"
#define METRIC_FREQ       "freq"
#define METRIC_DVFM       "dvfm"
#define METRIC_DVFMMS     "dvfm_ms"
#define METRIC_POWER      "power"
#define METRIC_INSTRCTS   "intstrcts"
#define METRIC_CYCLES     "cycles"
#define METRIC_CORES      "cores"

#define UNIT_ECPU         "ecpu"
#define UNIT_PCPU         "pcpu"
#define UNIT_GPU          "gpu"
//#define UNIT_ANE          "ane"

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
#define METRIC_COUNT 9

static struct param_set metrics_set[] =
{
    { METRIC_ACTIVE,   "show active residencies of units" },
    { METRIC_IDLE,     "show idle residencies of units" },
    { METRIC_FREQ,     "show active frequencies of units" },
    { METRIC_DVFM,     "show dvfm state distribution of units" },
    { METRIC_DVFMMS,   "show time spent in dvfm states during sample of units" },
    { METRIC_POWER,    "show power consumption of units" },
    { METRIC_INSTRCTS, "show instructions retired / per-clock metrics of supporting units" },
    { METRIC_CYCLES,   "show the supposed cycles spent during sample of supporting units" },
    { METRIC_CORES,    "show per-core stats for selected metrics on supporting units" }
};

#define UNITS_COUNT 3

static struct param_set units_set[] =
{
    { UNIT_ECPU, "efficiency cluster(s) statistics" },
    { UNIT_PCPU, "performance cluster(s) statistics" },
    { UNIT_GPU,  "integrated graphics statistics" },
//    { UNIT_ANE,  "neural engine statistics" },
};

#define OPT_COUNT 11

static struct long_opts_extended long_opts_set[] =
{
    {{ "help", no_argument, 0, 'h' },
        "               print this message and exit\n"
    },
    {{ "version", no_argument, 0, 'v' },
        "            print tool version number and exit\n\n"
    },
    {{ "interval", required_argument, 0, 'i' },
        " <N>       perform samples between N ms [default: 175ms]\n"
    },
    {{ "samples", required_argument, 0, 's' },
        " <N>        collect and display N samples (0=inf) [default: 1]\n"
    },

    {{ "output", required_argument, 0, 'o' },
        " <file>      set a file for metric stdout\n\n"
    },
    {{ "hide-unit", required_argument, 0, 'H' },
        " <unit>   comma separated list of unit statistics to hide\n"
    },
    {{ "metrics", required_argument, 0, 'm' },
        " <metrics>  comma separated list of metrics to report\n"
    },
    {{ "all-metrics", no_argument, 0, 'a' },
        "        report all available metrics for the visible units\n\n"
    },
    {{ "set-watts", no_argument, 0, 'w' },
        "          set power measurement to watts (default is mW)\n"
    },
    {{ "set-ghz", no_argument, 0, 'g' },
        "            set frequency measurement to GHz (default is MHz)\n"
    },
    {{ "property-list", no_argument, 0, 'p' },
        "      output as property list rather than plain text\n\n"
    },
};

static void usage(cmd_data*);
static struct option* unextended_long_opts_extended(void);

/*
 * Main
 */
int main(int argc, char * argv[])
{
    @autoreleasepool
    {
        iorep_data       iorep;
        variating_data   vd;
        static_data      sd;
        bool_data        bd;
        cmd_data         cmd;
        
        int opt      = 0;
        int optindex = 0;
        unsigned int current_loop = 0;
        
        cmd.power_measure    = 1;
        cmd.freq_measure     = 1;
        cmd.power_measure_un = "mW";
        cmd.freq_measure_un  = "MHz";
        cmd.plist            = false;
        cmd.file_out         = stdout;
        
        cmd.interval   = 175;
        cmd.samples    = 1;
        cmd.hide_units = [NSArray array];
        cmd.metrics    = [NSArray arrayWithObjects:[NSString stringWithUTF8String: METRIC_ACTIVE],
                          [NSString stringWithUTF8String: METRIC_POWER],
                                                   [NSString stringWithUTF8String: METRIC_FREQ],
                                                   [NSString stringWithUTF8String: METRIC_DVFM],
                                                   [NSString stringWithUTF8String: METRIC_INSTRCTS],
                                                   [NSString stringWithUTF8String: METRIC_CORES], nil];
        bd.ecpu = true;
        bd.pcpu = true;
        bd.gpu  = true;
//        bd.ane  = true;
        
        bd.res       = false;
        bd.idle      = false;
        bd.freq      = false;
        bd.cores     = false;
        bd.dvfm      = false;
        bd.dvfm_ms   = false;
        bd.power     = false;
        bd.intstrcts = false;
        bd.cycles    = false;
        
        NSString* metrics_str;
        NSString* hide_unit_str;
        
        struct option* long_opts = unextended_long_opts_extended();

        while((opt = getopt_long(argc, argv, "hvi:s:po:m:H:wga", long_opts, &optindex)) != -1) {
            switch(opt) {
                case '?':
                case 'h': usage(&cmd);
                case 'v': printf("%s %s (build %s %s)\n", getprogname(), __RELEASE__, __DATE__, __TIME__);
                          return 0;
                case 'i': cmd.interval = atoi(optarg);
                          break;
                case 's': cmd.samples = atoi(optarg);
                          break;
                case 'm': metrics_str = [NSString stringWithFormat:@"%s", strdup(optarg)];
                          cmd.metrics = [metrics_str componentsSeparatedByString:@","];
                          break;
                case 'H': hide_unit_str = [NSString stringWithFormat:@"%s", strdup(optarg)];
                          cmd.hide_units = [hide_unit_str componentsSeparatedByString:@","];
                          break;
                case 'w': cmd.power_measure = 1e-3;
                          cmd.power_measure_un = "W";
                          break;
                case 'g': cmd.freq_measure = 1e-3;
                          cmd.freq_measure_un = "GHz";
                          break;
                case 'p': cmd.plist = true;
                          break;
                case 'o': cmd.file_out = fopen(strdup(optarg), "w");
                          break;
                case 'a': cmd.metrics = [NSArray arrayWithObjects:[NSString stringWithUTF8String: METRIC_ACTIVE],
                                        [NSString stringWithUTF8String: METRIC_IDLE],
                                        [NSString stringWithUTF8String: METRIC_DVFM],
                                        [NSString stringWithUTF8String: METRIC_DVFMMS],
                                        [NSString stringWithUTF8String: METRIC_POWER],
                                        [NSString stringWithUTF8String: METRIC_INSTRCTS],
                                        [NSString stringWithUTF8String: METRIC_FREQ],
                                        [NSString stringWithUTF8String: METRIC_CYCLES],
                                        [NSString stringWithUTF8String: METRIC_CORES], nil];
            }
        }
        
        for (int i = 0; i < [cmd.metrics count]; i++) {
            if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_ACTIVE]])         bd.res        = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_IDLE]])      bd.idle       = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_FREQ]])      bd.freq       = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_CORES]])     bd.cores      = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_DVFM]])      bd.dvfm       = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_DVFMMS]])    bd.dvfm_ms    = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_POWER]])     bd.power      = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_INSTRCTS]])  bd.intstrcts  = true;
            else if ([cmd.metrics[i] isEqual:[NSString stringWithUTF8String:METRIC_CYCLES]])    bd.cycles     = true;
            else error(1, "Incorrect metric option \"%s\" in list", [cmd.metrics[i] UTF8String]);
        }

        for (int i = 0; i < [cmd.hide_units count]; i++) {
            if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_ECPU]])       bd.ecpu   = false;
            else if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_PCPU]])  bd.pcpu   = false;
            else if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_GPU]])   bd.gpu    = false;
//            else if ([cmd.hide_units[i] isEqual:[NSString stringWithUTF8String:UNIT_ANE]])   bd.ane    = false;
            else error(1, "Incorrect unit option \"%s\" in list", [cmd.hide_units[i] UTF8String]);
        }
        
        if (cmd.interval < 1) cmd.interval = 1;
//        if (cmd.interval < 3 && (bd.intstrcts == true || bd.cycles == true)) cmd.interval = 3;
        
        /*
         * init our data
         */
        sd.gpu_core_count       = 0;
        sd.dvfm_states_holder   = [NSMutableArray array];
        sd.cluster_core_counts  = [NSMutableArray array];
        sd.extra                = [NSMutableArray array];
        
        vd.cluster_sums         = [NSMutableArray array];
        vd.cluster_residencies  = [NSMutableArray array];
        vd.cluster_freqs        = [NSMutableArray array];
        vd.cluster_use          = [NSMutableArray array];
        
        vd.core_sums            = [NSMutableArray array];
        vd.core_residencies     = [NSMutableArray array];
        vd.core_freqs           = [NSMutableArray array];
        vd.core_use             = [NSMutableArray array];
        
        vd.cluster_pwrs         = [NSMutableArray array];
        vd.core_pwrs            = [NSMutableArray array];
        
        vd.cluster_instrcts_ret = [NSMutableArray array];
        vd.cluster_instrcts_clk = [NSMutableArray array];
        
        generateProcessorName(&sd);
        
        generateDvfmTable(&sd);
        generateCoreCounts(&sd);
        generateSiliconsIds(&sd);
        generateMicroArchs(&sd);
        
        /*
         * generating data to support other silicon
         */
        if (([sd.extra[0] rangeOfString:@"Pro"].location != NSNotFound) ||
            ([sd.extra[0] rangeOfString:@"Max"].location != NSNotFound))
        {
            sd.complex_pwr_channels = @[@"EACC_CPU", @"PACC0_CPU", @"PACC1_CPU", @"GPU0"];
            sd.core_pwr_channels    = @[@"EACC_CPU", @"PACC0_CPU", @"PACC1_CPU"];

            sd.complex_freq_channels = @[@"ECPU", @"PCPU", @"PCPU1", @"GPUPH"];
            sd.core_freq_channels    = @[@"ECPU0", @"PCPU0", @"PCPU1"];
            
            sd.dvfm_states = @[sd.dvfm_states_holder[0],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[2]];
            
        } else if ([sd.extra[0] rangeOfString:@"Ultra"].location != NSNotFound) {
            sd.complex_pwr_channels = @[@"DIE_0_EACC_CPU", @"DIE_1_EACC_CPU", @"DIE_0_PACC0_CPU", @"DIE_0_PACC1_CPU", @"DIE_1_PACC0_CPU", @"DIE_1_PACC1_CPU", @"GPU0_0"];
            sd.core_pwr_channels    = @[@"DIE_0_EACC_CPU", @"DIE_1_EACC_CPU", @"DIE_0_PACC0_CPU", @"DIE_0_PACC1_CPU", @"DIE_1_PACC0_CPU", @"DIE_1_PACC1_CPU"];

            sd.complex_freq_channels = @[@"DIE_0_ECPU", @"DIE_1_ECPU", @"DIE_0_PCPU", @"DIE_0_PCPU1", @"DIE_1_PCPU", @"DIE_1_PCPU1", @"GPUPH"];
            sd.core_freq_channels    = @[@"DIE_0_ECPU_CPU", @"DIE_1_ECPU_CPU", @"DIE_0_PCPU_CPU", @"DIE_0_PCPU1_CPU", @"DIE_1_PCPU_CPU", @"DIE_1_PCPU1_CPU"];
            
            sd.dvfm_states = @[sd.dvfm_states_holder[0],
                               sd.dvfm_states_holder[0],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[2]];
        } else {
            sd.complex_pwr_channels = @[@"ECPU", @"PCPU", @"GPU"];
            sd.core_pwr_channels    = @[@"ECPU", @"PCPU"];

            sd.complex_freq_channels = @[@"ECPU", @"PCPU", @"GPUPH"];
            sd.core_freq_channels    = @[@"ECPU", @"PCPU"];
            
            sd.dvfm_states = @[sd.dvfm_states_holder[0],
                               sd.dvfm_states_holder[1],
                               sd.dvfm_states_holder[2]];
        }

        /*
         * adding the proper object counts to our arrays based on cores/complexes
         */
        for (int i = 0; i < ([sd.cluster_core_counts count]+1); i++) {
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
        
        /*
         * subscribing to ioreport
         * doing it outside of sampling function, that way we don't waste resources constantly subscribing when looping
         */
        iorep.cpusubchn  = NULL;
        iorep.pwrsubchn  = NULL;
        iorep.clpcsubchn = NULL;
        iorep.cpuchn_cpu = IOReportCopyChannelsInGroup(@"CPU Stats", 0, 0, 0, 0);
        iorep.cpuchn_gpu = IOReportCopyChannelsInGroup(@"GPU Stats", 0, 0, 0, 0);
        iorep.pwrchn_eng = IOReportCopyChannelsInGroup(@"Energy Model", 0, 0, 0, 0);
        iorep.pwrchn_pmp = IOReportCopyChannelsInGroup(@"PMP", 0, 0, 0, 0);
        iorep.clpcchn    = IOReportCopyChannelsInGroup(@"CLPC Stats", 0, 0, 0, 0);
        
        IOReportMergeChannels(iorep.cpuchn_cpu, iorep.cpuchn_gpu, NULL);
        IOReportMergeChannels(iorep.pwrchn_eng, iorep.pwrchn_pmp, NULL);

        iorep.cpusub  = IOReportCreateSubscription(NULL, iorep.cpuchn_cpu, &iorep.cpusubchn, 0, 0);
        iorep.pwrsub  = IOReportCreateSubscription(NULL, iorep.pwrchn_eng, &iorep.pwrsubchn, 0, 0);
        iorep.clpcsub = IOReportCreateSubscription(NULL, iorep.clpcchn, &iorep.clpcsubchn, 0, 0);
        
        /*
         * dealing with outputing
         */
        if (cmd.samples <= 0) cmd.samples = -1;
        for(int L = cmd.samples; L--;) { 
            sample(&iorep, &sd, &vd, &cmd);
            format(&sd, &vd);
            
            if (cmd.plist == false)
                textOutput(&iorep, &sd, &vd, &bd, &cmd, current_loop);
            else {
                fprintf(cmd.file_out, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n");
                fprintf(cmd.file_out, "<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n");
                fprintf(cmd.file_out, "<plist version=\"1.0\">\n");
                
                fprintf(cmd.file_out, "<dict>\n");
                plistOutput(&iorep, &sd, &vd, &bd, &cmd, current_loop);
                fprintf(cmd.file_out, "</dict>\n</plist>\n");
            }
            
            /*
             * emptying our arrays for the next loop
             */
            for (int i = 0; i < ([sd.cluster_core_counts count]+1); i++) {
                [vd.cluster_residencies[i] removeAllObjects];
                vd.cluster_pwrs[i]  = @0;
                vd.cluster_use[i]   = @0;
                vd.cluster_sums[i]  = @0;
                vd.cluster_freqs[i] = @0;
            }

            for (int i = 0; i < ([sd.cluster_core_counts count]); i++) {
                for (int ii = 0; ii < [sd.cluster_core_counts[i] intValue]; ii++) {
                    [vd.core_residencies[i][ii] removeAllObjects];
                    vd.core_pwrs[i][ii]  = @0;
                    vd.core_use[i][ii]   = @0;
                    vd.core_freqs[i][ii] = @0;
                    vd.core_sums[i][ii]  = @0;
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
static void usage(cmd_data*cmd)
{
    fprintf(cmd->file_out, "\e[1m\nUsage: %s [-wgap] [-i interval] [-s samples]\n\n\e[0m", getprogname());
    fprintf(cmd->file_out, "  A sudoless implementation to profile your Apple M-Series CPU+GPU active core\n  and cluster frequencies, residencies, power consumption, and other metrics.\n  Inspired by Powermetrics. Made with love by BitesPotatoBacks.\n\n\e[1mThe following command-line options are supported:\e[0m\n\n");

    for (int i = 0; i < OPT_COUNT; i++)
        fprintf(cmd->file_out, "    -%c, --%s%s", long_opts_set[i].getopt_long.val, long_opts_set[i].getopt_long.name, long_opts_set[i].description);
    
    fprintf(cmd->file_out, "\e[1mThe following are metrics supported by --metrics:\e[0m\n\n");
    
    for (int i = 0; i < METRIC_COUNT; i++)
        fprintf(cmd->file_out, "    %-15s%s\n", metrics_set[i].param_name, metrics_set[i].description);
    
    fprintf(cmd->file_out, "\n    default: %s,%s,%s,%s,%s\n\n\e[1mThe following are units supported by --hide-units:\e[0m\n\n", METRIC_ACTIVE, METRIC_FREQ, METRIC_DVFM, METRIC_INSTRCTS, METRIC_CORES);
    
    for (int i = 0; i < UNITS_COUNT; i++)
        fprintf(cmd->file_out, "    %-15s%s\n", units_set[i].param_name, units_set[i].description);
    
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
