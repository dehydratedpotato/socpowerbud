//
//  socpwrbud.m
//  socpwrbud
//
//  Copyright (c) 2023 dehydratedpotato.
//

#import "socpwrbud.h"
#import <getopt.h>
#import <stdarg.h>

#define TOOL_VERSION "v0.4.1"

#define METRIC_ACTIVE     "%active"
#define METRIC_IDLE       "%idle"
#define METRIC_FREQ       "freq"
#define METRIC_DVFS       "dvfs"
#define METRIC_DVFSMS     "dvfs_ms"
#define METRIC_DVFSVOLTS  "dvfs_volts"
#define METRIC_POWER      "power"
#define METRIC_VOLTS      "volts"
#define METRIC_INSNS      "insns"
#define METRIC_CYCLES     "cycles"
#define METRIC_CORES      "cores"

#define UNIT_ECPU         "ecpu"
#define UNIT_PCPU         "pcpu"
#define UNIT_GPU          "gpu"

#define METRIC_COUNT 11
#define UNITS_COUNT 3
#define OPT_COUNT 11

typedef struct param_set {
    const char* name;
    const char* description;
} param_set;

static const struct param_set metrics_set[METRIC_COUNT] = {
    { METRIC_ACTIVE,   "show active residencies" },
    { METRIC_IDLE,     "show idle residencies" },
    { METRIC_FREQ,     "show active frequencies" },
    { METRIC_DVFS,     "show dvfs state distributions" },
    { METRIC_DVFSVOLTS,"show (milli)volts of dvfs states" },
    { METRIC_DVFSMS,   "show time spent in ms of dvfs states" },
    { METRIC_POWER,    "show power consumption of units" },
    { METRIC_VOLTS,    "show voltage of units" },
    { METRIC_INSNS,    "show instructions retired / per-clock metrics of supporting units" },
    { METRIC_CYCLES,   "show the supposed cycles spent during sample of supporting units" },
    { METRIC_CORES,    "show per-core stats for selected metrics on supporting units" }
};

static const struct param_set units_set[UNITS_COUNT] = {
    { UNIT_ECPU, "efficiency cluster(s) statistics" },
    { UNIT_PCPU, "performance cluster(s) statistics" },
    { UNIT_GPU,  "integrated graphics statistics" },
};

static const struct option long_opts[OPT_COUNT] = {
    { "help", no_argument, 0, 'h' },
    { "version", no_argument, 0, 'v' },
    { "interval", required_argument, 0, 'i' },
    { "samples", required_argument, 0, 's' },
    { "output", required_argument, 0, 'o' },
    { "hide-unit", required_argument, 0, 'H' },
    { "metrics", required_argument, 0, 'm' },
    { "all-metrics", no_argument, 0, 'a' },
    { "set-watts", no_argument, 0, 'w' },
    { "set-ghz", no_argument, 0, 'g' },
    { "property-list", no_argument, 0, 'p' },
};

static const char* long_opts_description[OPT_COUNT] = {
    "               print this message and exit\n",
    "            print tool version number and exit\n\n",
    " <N>       perform samples between N ms [default: 175ms]\n",
    " <N>        collect and display N samples (0=inf) [default: 1]\n",
    " <file>      set a file for metric stdout\n\n",
    " <unit>   comma separated list of unit statistics to hide\n",
    " <metrics>  comma separated list of metrics to report\n",
    "        report all available metrics for the visible units\n\n",
    "          set power measurement to watts (default is mW)\n",
    "            set frequency measurement to GHz (default is MHz)\n",
    "      output as property list rather than plain text\n\n",
};

#define VOLTAGE_STATES_ECPU CFSTR("voltage-states1-sram")
#define VOLTAGE_STATES_PCPU CFSTR("voltage-states5-sram")
#define VOLTAGE_STATES_GPU CFSTR("voltage-states9")

#define PWR_UNIT_MWATT 1
#define PWR_UNIT_WATT 1e-3
#define FREQ_UNIT_MHZ 1
#define FREQ_UNIT_GHZ 1e-3

#define PWR_UNIT_MWATT_LABEL "mW"
#define PWR_UNIT_WATT_LABEL "W"
#define FREQ_UNIT_MHZ_LABEL "MHz"
#define FREQ_UNIT_GHZ_LABEL "GHz"

static NSArray* pleb_complex_freq_chankeys = @[@"ECPU", @"PCPU", @"GPUPH"];
static NSArray* pleb_core_freq_chankeys = @[@"ECPU", @"PCPU"];
static NSArray* pleb_complex_pwr_chankeys = @[@"ECPU", @"PCPU", @"GPU"];
static NSArray* pleb_core_pwr_chankeys = @[@"ECPU", @"PCPU"];

static NSArray* promax_complex_freq_chankeys = @[@"ECPU", @"PCPU", @"PCPU1", @"GPUPH"];
static NSArray* promax_core_freq_chankeys = @[@"ECPU0", @"PCPU0", @"PCPU1"];
static NSArray* promax_complex_pwr_chankeys = @[@"EACC_CPU", @"PACC0_CPU", @"PACC1_CPU", @"GPU0"];
static NSArray* promax_core_pwr_chankeys = @[@"EACC_CPU", @"PACC0_CPU", @"PACC1_CPU"];

static NSArray* ultra_complex_freq_chankeys = @[@"DIE_0_ECPU", @"DIE_1_ECPU", @"DIE_0_PCPU", @"DIE_0_PCPU1", @"DIE_1_PCPU", @"DIE_1_PCPU1", @"GPUPH"];
static NSArray* ultra_core_freq_chankeys = @[@"DIE_0_ECPU_CPU", @"DIE_1_ECPU_CPU", @"DIE_0_PCPU_CPU", @"DIE_0_PCPU1_CPU", @"DIE_1_PCPU_CPU", @"DIE_1_PCPU1_CPU"];
static NSArray* ultra_complex_pwr_chankeys = @[@"DIE_0_EACC_CPU", @"DIE_1_EACC_CPU", @"DIE_0_PACC0_CPU", @"DIE_0_PACC1_CPU", @"DIE_1_PACC0_CPU", @"DIE_1_PACC1_CPU", @"GPU0_0"];
static NSArray* ultra_core_pwr_chankeys = @[@"DIE_0_EACC_CPU", @"DIE_1_EACC_CPU", @"DIE_0_PACC0_CPU", @"DIE_0_PACC1_CPU", @"DIE_1_PACC0_CPU", @"DIE_1_PACC1_CPU"];

static NSString* ptype_state     = @"P";
static NSString* vtype_state     = @"V";
static NSString* idletype_state  = @"IDLE";
static NSString* downtype_state  = @"DOWN";
static NSString* offtype_state   = @"OFF";

static const char* power_consumption_string = "\t\tPower Consumption: %.2f %s\n";
static const char* active_voltage_string = "\n\t\tActive Voltage:    %.2f mV\n";
static const char* active_frequency_string = "\t\tActive Frequency:  %g %s\n";
static const char* active_residency_string = "\t\tActive Residency:  %.1f%%\n";
static const char* idle_residency_string = "\t\tIdle Residency:    %.1f%%\n";
static const char* dvfs_distribution_string = "\t\tDvfs Distribution: ";

static const char* core_power_consumption_string = "\t\t\tPower Consumption: %.2f %s\n";
static const char* core_active_voltage_string = "\t\t\tActive Voltage:    %.2f mV\n";
static const char* core_active_frequency_string = "\t\t\tActive Frequency:  %g %s\n";
static const char* core_active_residency_string = "\t\t\tActive Residency:  %.1f%%\n";
static const char* core_idle_residency_string = "\t\t\tIdle Residency:    %.1f%%\n";
static const char* core_dvfs_distribution_string = "\t\t\tDvfs Distribution: ";

/* data structs
 */
typedef struct pwr_samples_perf_data {
    NSMutableArray* cluster_pwr; /* power of each cluster */
    NSMutableArray* core_pwr; /* core_pwr[CLUSTER][CORE]: power of each core */
} pwr_samples_perf_data;

typedef struct cpu_samples_perf_data {
    NSMutableArray* sums; /* sum of state distribution ticks per-cluster */
    NSMutableArray* distribution; /* distribution[CLUSTER][STATE]: distribution of individual states */
    NSMutableArray* freqs; /* calculated "active" frequency per-cluster */
    NSMutableArray* volts; /* calculated "active" voltage per-cluster */
    NSMutableArray* residency; /* calculated "active" usage/residency per-cluster */
} cpu_samples_perf_data;

typedef struct clpc_samples_perf_data {
    NSMutableArray* insn_retired; /* (cluster) instructions retired during sample */
    NSMutableArray* insn_perclk; /* (cluster) instructions per clock during sample */
} clpc_samples_perf_data;
//
//typedef struct core_samples_perf_data {
//    NSMutableArray* sums; /* sums[CLUSTER][CORE]: sum of state distribution ticks per-core in cluster */
//    NSMutableArray* distribution; /* distribution[CLUSTER][CORE][STATE]: distribution of individual states */
//    NSMutableArray* freqs; /* freqs[CLUSTER][CORE]: calculated "active" frequency per-core */
//    NSMutableArray* volts; /* volts[CLUSTER][CORE]: calculated "active" voltage per-core */
//    NSMutableArray* residency; /* residency[CLUSTER][CORE]: calculated "active" usage/residency per-core */
//} core_samples_perf_data;

typedef struct unit_data {
    NSString* silicon_code; /* codename, i.e. T6001 (Apple M1 Max) */
    NSString* silicon_name; /* lowercased name, i.e. apple m1 max*/
    NSString* pcpu_microarch; /* such as Firestorm */
    NSString* ecpu_microarch; /* such as Icestorm */
    
    NSMutableArray* percluster_ncores;
    int gpu_ncores;
    
    struct {
        IOReportSubscriptionRef pwr_sub;
        CFMutableDictionaryRef pwr_sub_chann;
        CFMutableDictionaryRef energy_chann;
        CFMutableDictionaryRef pmp_chann;
        
        pwr_samples_perf_data perf_data;
        
        NSArray* complex_channkeys; /* list of key stubs for cluster channels */
        NSArray* core_channkeys; /* list of key stubs for core channels */
    } pwr_samples;

    struct {
        IOReportSubscriptionRef cpu_sub;
        CFMutableDictionaryRef cpu_sub_chann;
        CFMutableDictionaryRef cpu_chann;
        CFMutableDictionaryRef gpu_chann;
    
        cpu_samples_perf_data cluster_perf_data;
        cpu_samples_perf_data core_perf_data;
        
        NSArray* complex_channkeys; /* list of key stubs for cluster channels */
        NSArray* core_channkeys; /* list of key stubs for core channels */
        
        NSArray* dvfs_freq_states; /* ...[CLUSTER][STATE]: list of dvfs freq states */
        NSArray* dvfs_voltage_states; /* ...[CLUSTER][STATE]: list of dvfs voltage states */
    } soc_samples;

    struct {
        IOReportSubscriptionRef clpc_sub;
        CFMutableDictionaryRef clpc_sub_chann;
        CFMutableDictionaryRef clpc_chann;
        
        clpc_samples_perf_data perf_data;
    } clpc_samples;
} unit_data;

typedef struct cmd_data {
    float pwr_unit; /* unit of measurement, mW (default) or W */
    const char* pwr_unit_label;
    float freq_unit; /* unit of measurement, mhz (default) or ghz */
    const char* freq_unit_label;
    
    int interval; /* sleep time between samples */
    int samples; /* target samples to make */
    
    bool plist;
    
    FILE* file_out;
    
    struct {
        bool hide_ecpu;
        bool hide_pcpu;
        bool hide_gpu;
        bool show_active;
        bool show_idle;
        bool show_freq;
        bool show_volts;
        bool show_percore;
        bool show_dvfs;
        bool show_dvfs_ms;
        bool show_dvfs_volts;
        bool show_pwr;
        bool show_insns;
        bool show_cycles;
    } flags;
} cmd_data;

/* defs
 */
static void error(int, const char*, ...);
static void usage(cmd_data*cmd);

static void sample(unit_data* unit_data, cmd_data* cmd_data);
static void format(unit_data* unit_data);

static inline void output_text(unit_data* unit_data, cmd_data* cmd_data, int* current_loop);
static inline void output_plist(unit_data* unit_data, cmd_data* cmd_data, int* current_loop);

static inline void init_cmd_data(cmd_data* data);
static inline void init_unit_data(unit_data* data);

int main(int argc, char * argv[]) {
    cmd_data* cmd = malloc(sizeof(cmd_data));
    unit_data* unit = malloc(sizeof(unit_data));
    
    init_cmd_data(cmd);
    
    NSString* active_metrics_str = nil;
    NSArray* active_metrics_list = nil;
    NSString* hide_units_str = nil;
    NSArray* hide_units_list = nil;
    
    int opt = 0;
    int optindex = 0;
    
    while((opt = getopt_long(argc, argv, "hvi:s:po:m:H:wga", long_opts, &optindex)) != -1) {
        switch(opt) {
            case '?':
            case 'h':
                usage(cmd);
            case 'v':
                printf("%s %s (build %s %s)\n", getprogname(), TOOL_VERSION, __DATE__, __TIME__);
                return 0;
            case 'i':
                cmd->interval = atoi(optarg);
                if (cmd->interval < 1) cmd->interval = 1;
                break;
            case 's':
                cmd->samples = atoi(optarg);
                if (cmd->samples <= 0) cmd->samples = -1;
                break;
            case 'm':
                active_metrics_str = [NSString stringWithFormat:@"%s", strdup(optarg)];
                active_metrics_list = [active_metrics_str componentsSeparatedByString:@","];
                active_metrics_str = nil;
                
                memset(&cmd->flags, 0, sizeof(cmd->flags));
                
                for (int i = 0; i < [active_metrics_list count]; i++) {
                    NSString* string = [active_metrics_list[i] lowercaseString];
                    
                    // ew, chained ifs
                    if ([string isEqual:[NSString stringWithUTF8String:METRIC_ACTIVE]])
                        cmd->flags.show_active = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_IDLE]])
                        cmd->flags.show_idle = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_FREQ]])
                        cmd->flags.show_freq = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_VOLTS]])
                        cmd->flags.show_volts = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_CORES]])
                        cmd->flags.show_percore = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_DVFS]])
                        cmd->flags.show_dvfs = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_DVFSMS]])
                        cmd->flags.show_dvfs_ms = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_DVFSVOLTS]])
                        cmd->flags.show_dvfs_volts = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_POWER]])
                        cmd->flags.show_pwr = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_INSNS]])
                        cmd->flags.show_insns = true;
                    else if ([string isEqual:[NSString stringWithUTF8String:METRIC_CYCLES]])
                        cmd->flags.show_cycles = true;
                    else
                        error(1, "Incorrect metric option \"%s\" in list", [string UTF8String]);
                }
                
                active_metrics_list = nil;
                break;
            case 'H':
                hide_units_str = [NSString stringWithFormat:@"%s", strdup(optarg)];
                hide_units_list = [hide_units_str componentsSeparatedByString:@","];
                hide_units_str = nil;
                
                for (int i = 0; i < [hide_units_list count]; i++) {
                    NSString* string = [hide_units_list[i] lowercaseString];

                    if ([string isEqual:@"ecpu"]) {
                        cmd->flags.hide_ecpu = true;
                    } else if ([string isEqual:@"pcpu"]){
                        cmd->flags.hide_pcpu = true;
                    }  else if ([string isEqual:@"gpu"]) {
                        cmd->flags.hide_gpu = true;
                    } else
                        error(1, "Incorrect unit option \"%s\" in list", [string UTF8String]);
                }
                
                hide_units_list = nil;
                break;
            case 'w':
                cmd->pwr_unit = PWR_UNIT_WATT;
                cmd->pwr_unit_label = PWR_UNIT_WATT_LABEL;
                break;
            case 'g':
                cmd->freq_unit = FREQ_UNIT_GHZ;
                cmd->freq_unit_label = FREQ_UNIT_GHZ_LABEL;
                break;
            case 'p':
                cmd->plist = true;
                break;
            case 'o':
            {
                char* name = strdup(optarg);
                cmd->file_out = fopen(strdup(optarg), "w");
                
                if (cmd->file_out == NULL) error(1, "Bad file provided: \"%s\"", name);
            }
                break;
            case 'a':
                cmd->flags.show_active = true;
                cmd->flags.show_idle = true;
                cmd->flags.show_freq = true;
                cmd->flags.show_volts = true;
                cmd->flags.show_dvfs = true;
                cmd->flags.show_dvfs_volts = true;
                cmd->flags.show_dvfs_ms = true;
                cmd->flags.show_percore = true;
                cmd->flags.show_pwr = true;
                cmd->flags.show_insns = true;
                cmd->flags.show_cycles = true;
                break;
        }
    }
    
    init_unit_data(unit); /* do this after so no slowdowns when printing version or help */
    
    int current_loop = 0;
    
    for(; cmd->samples--;) {
        sample(unit, cmd);
        format(unit);
        
        if (cmd->plist == false) {
            output_text(unit, cmd, &current_loop);
        } else {
            fprintf(cmd->file_out, "<?xml version=\"1.0\" encoding=\"UTF-8\"?>\n<!DOCTYPE plist PUBLIC \"-//Apple//DTD PLIST 1.0//EN\" \"http://www.apple.com/DTDs/PropertyList-1.0.dtd\">\n<plist version=\"1.0\">\n");
            
            fprintf(cmd->file_out, "<dict>\n");
            output_plist(unit, cmd, &current_loop);
            fprintf(cmd->file_out, "</dict>\n</plist>\n");
        }
        
        for (int i = 0; i < [unit->percluster_ncores count] + 1; i++) {
            
            /* cluster */
            [unit->soc_samples.cluster_perf_data.distribution[i] removeAllObjects];
            unit->soc_samples.cluster_perf_data.freqs[i] = @0;
            unit->soc_samples.cluster_perf_data.volts[i] = @0;
            unit->soc_samples.cluster_perf_data.residency[i] = @0;
            unit->soc_samples.cluster_perf_data.sums[i] = @0;
            unit->pwr_samples.perf_data.cluster_pwr[i] = @0;
            
            /* clpc */
            unit->clpc_samples.perf_data.insn_perclk[i] = @0;
            unit->clpc_samples.perf_data.insn_retired[i] = @0;
            
            /* core */
            if (i < [unit->percluster_ncores count]) {
                
                for (int ii = 0; ii < [unit->percluster_ncores[i] intValue]; ii++) {
                    [unit->soc_samples.core_perf_data.distribution[i][ii] removeAllObjects];
                    unit->soc_samples.core_perf_data.sums[i][ii] = @0;
                    unit->soc_samples.core_perf_data.freqs[i][ii] = @0;
                    unit->soc_samples.core_perf_data.volts[i][ii] = @0;
                    unit->soc_samples.core_perf_data.residency[i][ii] = @0;
                    unit->pwr_samples.perf_data.core_pwr[i][ii] = @0;
                }
            }
        }
        
        current_loop++;
    }
    return 0;
}

static void error(int exitcode, const char* format, ...) {
    va_list args;
    fprintf(stderr, "\e[1m%s:\033[0;31m error:\033[0m\e[0m ", getprogname());
    va_start(args, format);
    vfprintf(stderr, format, args);
    va_end(args);
    fprintf(stderr, "\n");
    exit(exitcode);
}

static void usage(cmd_data* cmd_data) {
    fprintf(cmd_data->file_out, "\e[1m\nUsage: %s [-wgap] [-i interval] [-s samples]\n\n\e[0m", getprogname());
    fprintf(cmd_data->file_out, "  A sudoless tool to profile your Apple M-Series CPU+GPU active core\n  and cluster frequencies, residencies, power consumption, and other metrics.\n  Inspired by Powermetrics. Thrown together by dehydratedpotato.\n\n\e[1mThe following command-line options are supported:\e[0m\n\n");

    for (int i = 0; i < OPT_COUNT; i++) {
        fprintf(cmd_data->file_out, "    -%c, --%s%s", long_opts[i].val, long_opts[i].name, long_opts_description[i]);
    }
    
    fprintf(cmd_data->file_out, "\e[1mThe following are metrics supported by --metrics:\e[0m\n\n");
    
    for (int i = 0; i < METRIC_COUNT; i++) {
        fprintf(cmd_data->file_out, "    %-15s%s\n", metrics_set[i].name, metrics_set[i].description);
    }
    
    fprintf(cmd_data->file_out, "\n    default: %s,%s,%s,%s,%s\n\n\e[1mThe following are units supported by --hide-units:\e[0m\n\n", METRIC_ACTIVE, METRIC_FREQ, METRIC_DVFS, METRIC_INSNS, METRIC_CORES);
    
    for (int i = 0; i < UNITS_COUNT; i++) {
        fprintf(cmd_data->file_out, "    %-15s%s\n", units_set[i].name, units_set[i].description);
    }
    
    exit(0);
}

static void sample(unit_data* unit_data, cmd_data* cmd_data) {
    
    CFDictionaryRef cpusamp_a  = IOReportCreateSamples(unit_data->soc_samples.cpu_sub, unit_data->soc_samples.cpu_sub_chann, NULL);
    CFDictionaryRef pwrsamp_a  = IOReportCreateSamples(unit_data->pwr_samples.pwr_sub, unit_data->pwr_samples.pwr_sub_chann, NULL);
    CFDictionaryRef clpcsamp_a = IOReportCreateSamples(unit_data->clpc_samples.clpc_sub, unit_data->clpc_samples.clpc_sub_chann, NULL);
    
    [NSThread sleepForTimeInterval: (cmd_data->interval * 1e-3)];
    
    CFDictionaryRef cpusamp_b  = IOReportCreateSamples(unit_data->soc_samples.cpu_sub, unit_data->soc_samples.cpu_sub_chann, NULL);
    CFDictionaryRef pwrsamp_b  = IOReportCreateSamples(unit_data->pwr_samples.pwr_sub, unit_data->pwr_samples.pwr_sub_chann, NULL);
    CFDictionaryRef clpcsamp_b = IOReportCreateSamples(unit_data->clpc_samples.clpc_sub, unit_data->clpc_samples.clpc_sub_chann, NULL);
    
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
    
    IOReportIterate(cpu_delta, ^int(IOReportSampleRef sample) {
        for (int i = 0; i < IOReportStateGetCount(sample); i++) {
            NSString* subgroup    = IOReportChannelGetSubGroup(sample);
            NSString* idx_name    = IOReportStateGetNameForIndex(sample, i);
            NSString* chann_name  = IOReportChannelGetChannelName(sample);
            uint64_t  residency   = IOReportStateGetResidency(sample, i);
            
            for (int ii = 0; ii < [unit_data->percluster_ncores count] + 1; ii++) {
                if ([subgroup isEqual: @"CPU Complex Performance States"] || [subgroup isEqual: @"GPU Performance States"]) {
                    
                    if (![chann_name isEqual:unit_data->soc_samples.complex_channkeys[ii]]) continue;
                    
                    /* active residency*/
                    if ([idx_name rangeOfString:ptype_state].location != NSNotFound ||
                        [idx_name rangeOfString:vtype_state].location != NSNotFound)
                    {
                        NSNumber* sum = [[NSNumber alloc] initWithUnsignedLongLong:([unit_data->soc_samples.cluster_perf_data.sums[ii] unsignedLongLongValue] + residency)];
                        NSNumber* distribution = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                        
                        unit_data->soc_samples.cluster_perf_data.sums[ii] = sum;
                        [unit_data->soc_samples.cluster_perf_data.distribution[ii] addObject:distribution];
                        
                        sum = nil;
                        distribution = nil;
                        
                        /* idle residency */
                    } else if ([idx_name rangeOfString:idletype_state].location != NSNotFound ||
                               [idx_name rangeOfString:offtype_state].location != NSNotFound)
                    {
                        NSNumber* res = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                        
                        unit_data->soc_samples.cluster_perf_data.residency[ii] = res;
                        
                        res = nil;
                    }
                }
                else if ([subgroup isEqual:@"CPU Core Performance States"] && ii < [unit_data->percluster_ncores count]) {
                    for (int iii = 0; iii < [unit_data->percluster_ncores[ii] intValue]; iii++) {
                        @autoreleasepool {
                            NSString* key = [NSString stringWithFormat:@"%@%d",unit_data->soc_samples.core_channkeys[ii], iii, nil];
                            
                            if (![chann_name isEqual:key]) {
                                key = nil;
                                continue;
                            }
                            
                            /* active residency */
                            if ([idx_name rangeOfString:ptype_state].location != NSNotFound ||
                                [idx_name rangeOfString:vtype_state].location != NSNotFound)
                            {
                                NSNumber* sum = [[NSNumber alloc] initWithUnsignedLongLong:([unit_data->soc_samples.core_perf_data.sums[ii][iii] unsignedLongLongValue] + residency)];
                                NSNumber* distribution = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                                
                                unit_data->soc_samples.core_perf_data.sums[ii][iii] = sum;
                                [unit_data->soc_samples.core_perf_data.distribution[ii][iii] addObject: distribution];
                                
                                sum = nil;
                                distribution = nil;
                                
                                /* idle residency */
                            } else if ([idx_name rangeOfString:idletype_state].location != NSNotFound ||
                                       [idx_name rangeOfString:offtype_state].location != NSNotFound)
                            {
                                NSNumber* res = [[NSNumber alloc] initWithUnsignedLongLong:residency];
                                
                                unit_data->soc_samples.core_perf_data.residency[ii][iii] = res;
                                
                                res = nil;
                            }
                            
                            key = nil;
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
    
    IOReportIterate(pwr_delta, ^int(IOReportSampleRef sample) {
        NSString* chann_name  = IOReportChannelGetChannelName(sample);
        NSString* group       = IOReportChannelGetGroup(sample);
        long      value       = IOReportSimpleGetIntegerValue(sample, 0);
        
        if ([group isEqual:@"Energy Model"]) {
            for (int ii = 0; ii < [unit_data->percluster_ncores count] + 1; ii++) {
                if ([chann_name isEqual:unit_data->pwr_samples.complex_channkeys[ii]]) {
                    NSNumber* pwr = [[NSNumber alloc] initWithFloat:(float)value / (cmd_data->interval * 1e-3)];
                    
                    unit_data->pwr_samples.perf_data.cluster_pwr[ii] = pwr;
                    pwr = nil;
                }
                
                if (ii < [unit_data->percluster_ncores count]) {
                    for (int iii = 0; iii < [unit_data->percluster_ncores[ii] intValue]; iii++) {
                        @autoreleasepool {
                            NSString* key = [[NSString alloc] initWithFormat:@"%@%d",unit_data->pwr_samples.core_channkeys[ii], iii, nil];
                            
                            if ([chann_name isEqual:key]) {
                                NSNumber* pwr = [[NSNumber alloc] initWithFloat:(float)value / (cmd_data->interval * 1e-3)];
                                
                                unit_data->pwr_samples.perf_data.core_pwr[ii][iii] = pwr;
                                
                                pwr = nil;
                            }
                            
                            key = nil;
                        }
                    }
                }
            }
            /* the gpu entry doen't seem to exist on pleb silicon so we have to read from PMP */
        } else if ([group isEqual:@"PMP"] && [chann_name isEqual:@"GPU"] &&
                 [unit_data->silicon_name length] == 8 /* 8 == length of "Apple Mx" */)
        {
            NSNumber* pwr = [[NSNumber alloc] initWithFloat:(float)value / (cmd_data->interval * 1e-3)];
            
            unit_data->pwr_samples.perf_data.cluster_pwr[2] = pwr; /* constant 2 is always true when this logic executes */
            pwr = nil;
        }
        
        chann_name = nil;
        group = nil;
        
        return kIOReportIterOk;
    });
    
    IOReportIterate(clpc_delta, ^int(IOReportSampleRef sample) {
        NSString* chann_name  = IOReportChannelGetChannelName(sample);
        
        for (int i = 0; i < [unit_data->percluster_ncores count]; i++) {
            long value = IOReportArrayGetValueAtIndex(sample, i);
            
            NSNumber* insn = [[NSNumber alloc] initWithLong:value];
            
            if ([chann_name isEqual:@"CPU cycles, by cluster"])
                unit_data->clpc_samples.perf_data.insn_perclk[i] = insn;
            if ([chann_name isEqual:@"CPU instructions, by cluster"])
                unit_data->clpc_samples.perf_data.insn_retired[i] = insn;
            
            insn = nil;
        }
        
        chann_name = nil;
        
        return kIOReportIterOk;
    });
    
    CFRelease(cpu_delta);
    CFRelease(pwr_delta);
    CFRelease(clpc_delta);
}

static void format(unit_data* unit_data) {
    uint64_t res = 0;
    uint64_t core_res = 0;
    
    for (int i = 0; i < [unit_data->percluster_ncores count] + 1; i++) {
        /* formatting cpu freqs */
        for (int ii = 0; ii < [unit_data->soc_samples.cluster_perf_data.distribution[i] count]; ii++) {
            @autoreleasepool {
                res = [unit_data->soc_samples.cluster_perf_data.distribution[i][ii] unsignedLongLongValue];
                
                if (res != 0) {
                    float perc = (res / [unit_data->soc_samples.cluster_perf_data.sums[i] floatValue]);\
                    
                    NSNumber* distribution = [[NSNumber alloc] initWithFloat: perc];
                    NSNumber* freq = [[NSNumber alloc] initWithFloat: ([unit_data->soc_samples.cluster_perf_data.freqs[i] floatValue] + ([unit_data->soc_samples.dvfs_freq_states[i][ii] floatValue]*perc))];
                    NSNumber* volt = [[NSNumber alloc] initWithFloat: ([unit_data->soc_samples.cluster_perf_data.volts[i] floatValue] + ([unit_data->soc_samples.dvfs_voltage_states[i][ii] floatValue]*perc))];
                    
                    unit_data->soc_samples.cluster_perf_data.freqs[i] = freq;
                    unit_data->soc_samples.cluster_perf_data.volts[i] = volt;
                    [unit_data->soc_samples.cluster_perf_data.distribution[i] replaceObjectAtIndex:ii withObject:distribution];
                    
                    distribution = nil;
                    freq = nil;
                    volt = nil;
                }
                
                if (i < [unit_data->percluster_ncores count]) {
                    for (int iii = 0; iii < [unit_data->percluster_ncores[i] intValue]; iii++) {
                        
                        /* sometimes a state is missing for cores on M2 so break when the index is too big */
                        if (ii > [unit_data->soc_samples.core_perf_data.distribution[i][iii] count] - 1) break;
                        
                        core_res = [unit_data->soc_samples.core_perf_data.distribution[i][iii][ii] unsignedLongLongValue];
                        
                        if (core_res != 0) {
                            float core_perc = (core_res / [unit_data->soc_samples.core_perf_data.sums[i][iii] floatValue]);
                            
                            NSNumber* distribution = [[NSNumber alloc] initWithFloat:core_perc];
                            NSNumber* freq = [[NSNumber alloc] initWithFloat: ([unit_data->soc_samples.core_perf_data.freqs[i][iii] floatValue] +
                                                                               ([unit_data->soc_samples.dvfs_freq_states[i][ii] floatValue] * core_perc))];
                            NSNumber* volt = [[NSNumber alloc] initWithFloat: ([unit_data->soc_samples.core_perf_data.volts[i][iii] floatValue] +
                                                                               ([unit_data->soc_samples.dvfs_voltage_states[i][ii] floatValue] * core_perc))];
                            
                            unit_data->soc_samples.core_perf_data.freqs[i][iii] = freq;
                            unit_data->soc_samples.core_perf_data.volts[i][iii] = volt;
                            [unit_data->soc_samples.core_perf_data.distribution[i][iii] replaceObjectAtIndex:ii withObject:distribution];
                            
                            distribution = nil;
                            freq = nil;
                            volt = nil;
                        }
                    }
                }
            }
        }
        
        /* formatting idle residency */
        float res = [unit_data->soc_samples.cluster_perf_data.residency[i] floatValue];
        
        if (res != 0) {
            unit_data->soc_samples.cluster_perf_data.residency[i] = [[NSNumber alloc] initWithFloat:((res / ([unit_data->soc_samples.cluster_perf_data.sums[i] floatValue] + res)) * 100)];
        }
        
        if (i < [unit_data->percluster_ncores count]) {
            for (int iii = 0; iii < [unit_data->percluster_ncores[i] intValue]; iii++) {
                float core_res = [unit_data->soc_samples.core_perf_data.residency[i][iii] floatValue];
                
                if (core_res != 0) {
                    NSNumber* a = [[NSNumber alloc] initWithFloat:(core_res / ([unit_data->soc_samples.core_perf_data.sums[i][iii] floatValue] + core_res)) * 100];
                    unit_data->soc_samples.core_perf_data.residency[i][iii] = a;
                    
                    a = nil;
                }
            }
        }
    }
}

static inline void output_text(unit_data* unit_data, cmd_data* cmd_data, int* current_loop) {
    int current_core = 0;

    cpu_samples_perf_data* core_perf_data = &unit_data->soc_samples.core_perf_data;
    cpu_samples_perf_data* cluster_perf_data = &unit_data->soc_samples.cluster_perf_data;
    pwr_samples_perf_data* pwr_perf_data = &unit_data->pwr_samples.perf_data;
    
    fprintf(cmd_data->file_out, "%s %s (Sample %d):\n\n", [[unit_data->silicon_name capitalizedString] UTF8String], [unit_data->silicon_code UTF8String], *current_loop + 1);
    
    for (int i = 0; i < [unit_data->percluster_ncores count] + 1; i++) {
        if (([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"ECPU"].location != NSNotFound && cmd_data->flags.hide_ecpu) ||
            ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"PCPU"].location != NSNotFound && cmd_data->flags.hide_pcpu) ||
            ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"GPU"].location != NSNotFound && cmd_data->flags.hide_gpu)) continue; /* continue when hidden */
        
        char* microarch = "Unknown";
        
        /* opening metrics
         */
        if ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"ECPU"].location != NSNotFound)
            microarch = (char *) [unit_data->ecpu_microarch UTF8String];
        else if ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"PCPU"].location != NSNotFound)
            microarch = (char *) [unit_data->pcpu_microarch UTF8String];
        
        if ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"CPU"].location != NSNotFound) {
            fprintf(cmd_data->file_out, "\t%d-Core %s %s:\n\n", [unit_data->percluster_ncores[i] intValue], microarch, [unit_data->soc_samples.complex_channkeys[i] UTF8String]);
            
            if (cmd_data->flags.show_cycles) fprintf(cmd_data->file_out, "\t\tSupposed Cycles Spent:  %ld\n", [unit_data->clpc_samples.perf_data.insn_perclk[i] longValue]);
            
            /* instructions metrics are only available on CPU clusters */
            if (cmd_data->flags.show_insns) {
                float retired = [unit_data->clpc_samples.perf_data.insn_retired[i] floatValue];
                
                if (retired > 0) {
                    fprintf(cmd_data->file_out, "\t\tInstructions Retired:   %.5e\n", retired);
                    fprintf(cmd_data->file_out, "\t\tInstructions Per-Clock: %.5f\n\n", retired / [unit_data->clpc_samples.perf_data.insn_perclk[i] floatValue]);
                } else {
                    fprintf(cmd_data->file_out, "\t\tInstructions Retired:   0\n");
                    fprintf(cmd_data->file_out, "\t\tInstructions Per-Clock: 0\n\n");
                }
            }
        } else
            fprintf(cmd_data->file_out, "\t%d-Core Integrated Graphics:\n\n", unit_data->gpu_ncores);
        
        /* clusters
         */
        if (cmd_data->flags.show_pwr) fprintf(cmd_data->file_out, power_consumption_string, (float)([pwr_perf_data->cluster_pwr[i] floatValue] * cmd_data->pwr_unit), cmd_data->pwr_unit_label);
        if (cmd_data->flags.show_volts) fprintf(cmd_data->file_out, active_voltage_string, [cluster_perf_data->volts[i] floatValue]);
        if (cmd_data->flags.show_freq) fprintf(cmd_data->file_out, active_frequency_string, (float)(fabs([cluster_perf_data->freqs[i] floatValue] * cmd_data->freq_unit)), cmd_data->freq_unit_label);
        if (cmd_data->flags.show_idle) fprintf(cmd_data->file_out, "\n");
        if (cmd_data->flags.show_active)fprintf(cmd_data->file_out, active_residency_string,  fabs(100-[cluster_perf_data->residency[i] floatValue]));
        if (cmd_data->flags.show_idle) fprintf(cmd_data->file_out, idle_residency_string,  fabs([cluster_perf_data->residency[i] floatValue]));
        
        /* cluster dvfs
         */
        if (cmd_data->flags.show_dvfs) {
            if ([cluster_perf_data->freqs[i] floatValue] > 0) {
                fprintf(cmd_data->file_out, "%s", dvfs_distribution_string);
                
                for (int iii = 0; iii < [unit_data->soc_samples.dvfs_freq_states[i] count]; iii++) {
                    float res = [cluster_perf_data->distribution[i][iii] floatValue];
                    
                    if (res > 0) {
                        if (!cmd_data->flags.show_dvfs_volts) {
                            fprintf(cmd_data->file_out, "%.fMHz: %.2f%%",[unit_data->soc_samples.dvfs_freq_states[i][iii] floatValue], res*100);
                        } else {
                            fprintf(cmd_data->file_out, "%.fMHz, %.fmV: %.2f%%",[unit_data->soc_samples.dvfs_freq_states[i][iii] floatValue], [unit_data->soc_samples.dvfs_voltage_states[i][iii] floatValue], res*100);
                        }
                        
                        if (cmd_data->flags.show_dvfs_ms) fprintf(cmd_data->file_out, " (%.fms)", res * cmd_data->interval);
                        fprintf(cmd_data->file_out, "   ");
                    }
                }
                fprintf(cmd_data->file_out, "\n");
            }
        }
        fprintf(cmd_data->file_out, "\n");
        
        /* cores
         */
        if (i < [unit_data->percluster_ncores count]) {
            for (int ii = 0; ii < [unit_data->percluster_ncores[i] intValue]; ii++) {
                fprintf(cmd_data->file_out, "\t\tCore %d:\n", current_core);
                
                if (cmd_data->flags.show_pwr) fprintf(cmd_data->file_out, core_power_consumption_string, (float)([pwr_perf_data->core_pwr[i][ii] floatValue] * cmd_data->pwr_unit), cmd_data->pwr_unit_label);
                if (cmd_data->flags.show_volts) fprintf(cmd_data->file_out, core_active_voltage_string, [core_perf_data->volts[i][ii] floatValue]);
                if (cmd_data->flags.show_freq) fprintf(cmd_data->file_out, core_active_frequency_string,  (float)(fabs([core_perf_data->freqs[i][ii] floatValue] * cmd_data->freq_unit)), cmd_data->freq_unit_label);
                if (cmd_data->flags.show_active) fprintf(cmd_data->file_out,  core_active_residency_string,  (float)(fabs(100-[core_perf_data->residency[i][ii] floatValue])));
                if (cmd_data->flags.show_idle)  fprintf(cmd_data->file_out, core_idle_residency_string,  (float)(fabs([core_perf_data->residency[i][ii] floatValue])));
                
                /* core dvfs
                 */
                if (cmd_data->flags.show_dvfs) {
                    if ([core_perf_data->freqs[i][ii] floatValue] > 0) {
                        fprintf(cmd_data->file_out, "%s", core_dvfs_distribution_string);
                        
                        for (int iii = 0; iii < [unit_data->soc_samples.dvfs_freq_states[i] count]; iii++) {
                            float res = [core_perf_data->distribution[i][ii][iii] floatValue];
                            
                            if (res > 0) {
                                if (!cmd_data->flags.show_dvfs_volts) {
                                    fprintf(cmd_data->file_out, "%.fMHz: %.2f%%",[unit_data->soc_samples.dvfs_freq_states[i][iii] floatValue], res*100);
                                } else {
                                    fprintf(cmd_data->file_out, "%.fMHz, %.fmV: %.2f%%",[unit_data->soc_samples.dvfs_freq_states[i][iii] floatValue], [unit_data->soc_samples.dvfs_voltage_states[i][iii] floatValue], res*100);
                                }
                                if (cmd_data->flags.show_dvfs_ms) fprintf(cmd_data->file_out, " (%.fms)", res * cmd_data->interval);
                                fprintf(cmd_data->file_out, "   ");
                            }
                        }
                        fprintf(cmd_data->file_out, "\n");
                    } else {
                        fprintf(cmd_data->file_out, "\t\t\tDvfm Distribution: None\n");
                    }
                }
                
                current_core++;
            }
            fprintf(cmd_data->file_out, "\n");
        }
    }
}

static inline void output_plist(unit_data* unit_data, cmd_data* cmd_data, int* current_loop) {
    int current_core = 0;

    cpu_samples_perf_data* core_perf_data = &unit_data->soc_samples.core_perf_data;
    cpu_samples_perf_data* cluster_perf_data = &unit_data->soc_samples.cluster_perf_data;
    pwr_samples_perf_data* pwr_perf_data = &unit_data->pwr_samples.perf_data;
    
    fprintf(cmd_data->file_out, "<key>processor</key><string>%s</string>\n<key>soc_id</key><string>%s</string>\n<key>sample</key><integer>%d</integer>\n",
            [[unit_data->silicon_name capitalizedString] UTF8String],
            [unit_data->silicon_code UTF8String],
            *current_loop + 1);
    
    for (int i = 0; i < [unit_data->percluster_ncores count] + 1; i++) {
        if (([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"ECPU"].location != NSNotFound && cmd_data->flags.hide_ecpu) ||
            ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"PCPU"].location != NSNotFound && cmd_data->flags.hide_pcpu) ||
            ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"GPU"].location != NSNotFound && cmd_data->flags.hide_gpu)) continue; /* continue when hidden */
        
        char* microarch = "Unknown";
        
        /* opening metrics
         */
        if ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"ECPU"].location != NSNotFound)
            microarch = (char *) [unit_data->ecpu_microarch UTF8String];
        else if ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"PCPU"].location != NSNotFound)
            microarch = (char *) [unit_data->pcpu_microarch UTF8String];
        
        if ([unit_data->soc_samples.complex_channkeys[i] rangeOfString:@"CPU"].location != NSNotFound) {
            fprintf(cmd_data->file_out, "<key>%s</key>\n<dict>\n\t<key>microarch</key><string>%s</string>\n\t<key>core_cnt</key><integer>%d</integer>\n",  [unit_data->soc_samples.complex_channkeys[i] UTF8String], microarch, [unit_data->percluster_ncores[i] intValue]);
            
            if (cmd_data->flags.show_cycles)
                fprintf(cmd_data->file_out, "\t<key>cycles_spent</key><integer>%ld</integer>\n", [unit_data->clpc_samples.perf_data.insn_perclk[i] longValue]);
            
            /* instructions metrics are only available on CPU clusters */
            if (cmd_data->flags.show_insns) {
                float retired = [unit_data->clpc_samples.perf_data.insn_retired[i] floatValue];
                
                if (retired > 0) {
                    fprintf(cmd_data->file_out, "\t<key>instrcts_ret</key><real>%.f</real>\n", retired);
                    fprintf(cmd_data->file_out, "\t<key>instrcts_per_clk</key><real>%.5f</real>\n", retired / [unit_data->clpc_samples.perf_data.insn_perclk[i] floatValue]);
                } else {
                    fprintf(cmd_data->file_out, "\t<key>instrcts_ret</key><real>0</real>\n");
                    fprintf(cmd_data->file_out, "\t<key>instrcts_per_clk</key><real>0</real>\n");
                }
            }
        } else
            fprintf(cmd_data->file_out, "<key>GPU</key>\n<dict>\n\t<key>core_cnt</key><integer>%d</integer>\n", unit_data->gpu_ncores);
        
        /* clusters
         */
        if (cmd_data->flags.show_pwr) fprintf(cmd_data->file_out, "\t<key>power</key><real>%.2f</real>\n", (float)([pwr_perf_data->cluster_pwr[i] floatValue] * cmd_data->pwr_unit));
        if (cmd_data->flags.show_volts) fprintf(cmd_data->file_out, "\t<key>mvolts</key><real>%.f</real>\n", [cluster_perf_data->volts[i] floatValue]);
        if (cmd_data->flags.show_freq) fprintf(cmd_data->file_out, "\t<key>freq</key><real>%.2f</real>\n", (float)(fabs([cluster_perf_data->freqs[i] floatValue] * cmd_data->freq_unit)));
        if (cmd_data->flags.show_active)fprintf(cmd_data->file_out, "\t<key>freq</key><real>%.2f</real>\n",  fabs(100-[cluster_perf_data->residency[i] floatValue]));
        if (cmd_data->flags.show_idle) fprintf(cmd_data->file_out, "\t<key>idle_res</key><real>%.2f</real>\n",  fabs([cluster_perf_data->residency[i] floatValue]));
        
        /* cluster dvfs
         */
        if (cmd_data->flags.show_dvfs) {
            if ([cluster_perf_data->freqs[i] floatValue] > 0) {
                fprintf(cmd_data->file_out, "\t<key>dvfs_distrib</key>\n\t<dict>\n");
                
                for (int iii = 0; iii < [unit_data->soc_samples.dvfs_freq_states[i] count]; iii++) {
                    float res = [cluster_perf_data->distribution[i][iii] floatValue];
                    
                    if (res > 0) {
                        fprintf(cmd_data->file_out, "\t\t<key>%ld</key>\n\t\t<dict>\n",[unit_data->soc_samples.dvfs_freq_states[i][iii] longValue]);
                        
                        if (cmd_data->flags.show_dvfs_volts) fprintf(cmd_data->file_out, "\t\t\t<key>state_mvolts</key><real>%.f</real>\n", [unit_data->soc_samples.dvfs_voltage_states[i][iii] floatValue]);
                        
                        fprintf(cmd_data->file_out, "\t\t\t<key>residency</key><real>%.2f</real>\n",res * 100);
                        
                        if (cmd_data->flags.show_dvfs_ms) fprintf(cmd_data->file_out, "\t\t\t<key>time_ms</key><real>%.f</real>\n", res * cmd_data->interval);
                        fprintf(cmd_data->file_out, "\t\t</dict>\n");
                    }
                }
                fprintf(cmd_data->file_out, "\t</dict>\n");
            }
        }

        
        /* cores
         */
        if (i < [unit_data->percluster_ncores count]) {
            for (int ii = 0; ii < [unit_data->percluster_ncores[i] intValue]; ii++) {
                fprintf(cmd_data->file_out, "\t<key>core_%d</key>\n\t<dict>\n", current_core);
                
                if (cmd_data->flags.show_pwr) fprintf(cmd_data->file_out, "\t\t<key>power</key><real>%.2f</real>\n", (float)([pwr_perf_data->core_pwr[i][ii] floatValue] * cmd_data->pwr_unit));
                if (cmd_data->flags.show_volts) fprintf(cmd_data->file_out, "\t\t<key>mvolts</key><real>%.f</real>\n", [core_perf_data->volts[i][ii] floatValue]);
                if (cmd_data->flags.show_freq) fprintf(cmd_data->file_out, "\t\t<key>freq</key><real>%.2f</real>\n",  (float)(fabs([core_perf_data->freqs[i][ii] floatValue] * cmd_data->freq_unit)));
                if (cmd_data->flags.show_active) fprintf(cmd_data->file_out, "\t\t<key>active_res</key><real>%.2f</real>\n",  (float)(fabs(100-[core_perf_data->residency[i][ii] floatValue])));
                if (cmd_data->flags.show_idle)  fprintf(cmd_data->file_out, "\t\t<key>idle_res</key><real>%.2f</real>\n",  (float)(fabs([core_perf_data->residency[i][ii] floatValue])));
                
                /* core dvfs
                 */
                if (cmd_data->flags.show_dvfs) {
                    fprintf(cmd_data->file_out,  "\t\t<key>dvfs_distrib</key>\n\t\t<dict>\n");
                    
                    for (int iii = 0; iii < [unit_data->soc_samples.dvfs_freq_states[i] count]; iii++) {
                        float res = [core_perf_data->distribution[i][ii][iii] floatValue];
                        
                        if (res > 0) {
                            fprintf(cmd_data->file_out, "\t\t\t<key>%ld</key>\n\t\t\t<dict>\n",[unit_data->soc_samples.dvfs_freq_states[i][iii] longValue]);
                            
                            if (cmd_data->flags.show_dvfs_volts)
                                fprintf(cmd_data->file_out, "\t\t\t\t<key>state_mvolts</key><real>%.f</real>\n",[unit_data->soc_samples.dvfs_voltage_states[i][iii] floatValue]);
                            
                            fprintf(cmd_data->file_out, "\t\t\t\t<key>residency</key><real>%.2f</real>\n",res * 100);
                            
                            if (cmd_data->flags.show_dvfs_ms) fprintf(cmd_data->file_out, "\t\t\t\t<key>time_ms</key><real>%.f</real>\n", res * cmd_data->interval);
                            fprintf(cmd_data->file_out, "\t\t\t</dict>\n");
                        }
                    }
                    fprintf(cmd_data->file_out, "\t\t</dict>\n");
                }
                
                fprintf(cmd_data->file_out, "\t</dict>\n");
                
                current_core++;
            }
        }
        
        fprintf(cmd_data->file_out, "</dict>\n");
    }
}

static inline void make_dvfs_table(NSMutableArray* freq_states, NSMutableArray* volt_states) {
    NSData* frmt_data;
    
    const unsigned char* databytes;
    
    io_registry_entry_t entry;
    io_iterator_t iter;
    CFMutableDictionaryRef service;
    
    mach_port_t port;
    if (@available(macOS 12, *))
        port = kIOMainPortDefault;
    else
        port = kIOMasterPortDefault;

    if (!(service = IOServiceMatching("AppleARMIODevice")))
        error(1, "Failed to find AppleARMIODevice service in IORegistry");
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        error(1, "Failed to access AppleARMIODevice service in IORegistry");

    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        
        /* check if the first voltage state is here. if so, the others should be... kinda gross, should probably fix this later
         */
        if (IORegistryEntryCreateCFProperty(entry, VOLTAGE_STATES_ECPU, kCFAllocatorDefault, 0) != nil) {

            for (int i = 3; i--;) {
                const void* data = nil;
                
                /* maybe i'll add voltage-states-13-sram in the future for higher end silicon, but it's not all that necessary anyway... */
                switch(i) {
                    case 2: data = IORegistryEntryCreateCFProperty(entry, CFSTR("voltage-states1-sram"), kCFAllocatorDefault, 0); break;
                    case 1: data = IORegistryEntryCreateCFProperty(entry, CFSTR("voltage-states5-sram"), kCFAllocatorDefault, 0); break;
                    case 0: data = IORegistryEntryCreateCFProperty(entry, CFSTR("voltage-states9"), kCFAllocatorDefault, 0); break;
                }
                
                if (data != nil) {
                    freq_states[2-i] = [[NSMutableArray alloc] init];
                    volt_states[2-i] = [[NSMutableArray alloc] init];
                    
                    frmt_data = (NSData*)CFBridgingRelease(data);
                    databytes = [(NSData*)CFBridgingRelease(data) bytes];
                    
                    for (int ii = 0; ii < [frmt_data length] - 4; ii += 8) {
                        uint32_t freq_dword = *(uint32_t*)(databytes + ii) * 1e-6;
                        uint32_t volt_dword = *(uint32_t*)(databytes + ii + 4);
                        
                        if (freq_dword != 0) [freq_states[2-i] addObject:[NSNumber numberWithUnsignedInt:freq_dword]];
                        [volt_states[2-i] addObject:[NSNumber numberWithUnsignedInt:volt_dword]];
                    }
                }
            }
            
            break;
        }
    }
    
    IOObjectRelease(entry);
    IOObjectRelease(iter);
}

static inline void get_core_counts(unit_data* unit_data) {
    io_registry_entry_t entry;
    io_iterator_t       iter;
    
    CFMutableDictionaryRef service;
    
    mach_port_t port;
    if (@available(macOS 12, *))
        port = kIOMainPortDefault;
    else
        port = kIOMasterPortDefault;

    if (!(service = IOServiceMatching("AppleARMIODevice")))
        error(1, "Failed to find AppleARMIODevice service in IORegistry");
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        error(1, "Failed to access AppleARMIODevice service in IORegistry");
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        const void* data = IORegistryEntryCreateCFProperty(entry, CFSTR("clusters"), kCFAllocatorDefault, 0);

        if (data != nil) {
            NSData* frmt_data = (NSData*)CFBridgingRelease(data);
            const unsigned char* databytes = [frmt_data bytes];
            
            /* every 4th index after the first is our byte data for the cluster core count */
            for (int ii = 0; ii < [frmt_data length]; ii += 4) {
                NSString* datastrng = [[NSString alloc] initWithFormat:@"%02x", databytes[ii]];
                
                /* Ultra support */
                if ([unit_data->silicon_name rangeOfString:@"ultra"].location != NSNotFound) {
                    for (int i = 2; i--;)
                        [unit_data->percluster_ncores addObject:[NSNumber numberWithInt: (int) atof([datastrng UTF8String])]];
                } else
                    [unit_data->percluster_ncores addObject:[NSNumber numberWithInt: (int) atof([datastrng UTF8String])]];
                
                datastrng = nil;
            }
            
            break;
        }
    }
    
    /* pull gpu core counts from a different spot
     */
    if (!(service = IOServiceMatching("AGXAccelerator")))
        error(1, "Failed to find AGXAccelerator service in IORegistry");
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        error(1, "Failed to access AGXAccelerator service in IORegistry");
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {

        CFTypeRef a = IORegistryEntryCreateCFProperty(entry, CFSTR("gpu-core-count"), kCFAllocatorDefault, 0);
        
        if (a != nil) unit_data->gpu_ncores = [(__bridge NSNumber *)a intValue];
        
        break;
    }
    
    IOObjectRelease(entry);
    IOObjectRelease(iter);
}

static inline void get_silicon_code(unit_data* unit_data) {
    if ([unit_data->silicon_name rangeOfString:@"m1"].location != NSNotFound) {
        if ([unit_data->silicon_name rangeOfString:@"m1 pro"].location != NSNotFound) {
            unit_data->silicon_code = @"T6000";
            return;
        } else if ([unit_data->silicon_name rangeOfString:@"m1 max"].location != NSNotFound) {
            unit_data->silicon_code = @"T6001";
            return;
        } else if ([unit_data->silicon_name rangeOfString:@"m1 ultra"].location != NSNotFound) {
            unit_data->silicon_code = @"T6002";
            return;
        } else {
            unit_data->silicon_code = @"T8103";
            return;
        }
    } else if ([unit_data->silicon_name rangeOfString:@"m2"].location != NSNotFound) {
        if ([unit_data->silicon_name rangeOfString:@"m2 pro"].location != NSNotFound) {
            unit_data->silicon_code = @"T6020";
            return;
        } else if ([unit_data->silicon_name rangeOfString:@"m2 max"].location != NSNotFound) {
            unit_data->silicon_code = @"T6021";
            return;
        } else if ([unit_data->silicon_name rangeOfString:@"m2 ultra"].location != NSNotFound) {
            unit_data->silicon_code = @"T6022";
            return;
        } else {
            unit_data->silicon_code = @"T8112";
            return;
        }
    } else {
        unit_data->silicon_code = @"T****";
    }
    
    io_registry_entry_t entry;
    io_iterator_t       iter;
    
    CFMutableDictionaryRef servicedict;
    CFMutableDictionaryRef service;
    
    mach_port_t port;
    if (@available(macOS 12, *))
        port = kIOMainPortDefault;
    else
        port = kIOMasterPortDefault;
    
    if (!(service = IOServiceMatching("IOPlatformExpertDevice")))
        return;
    if (!(IOServiceGetMatchingServices(port, service, &iter) == kIOReturnSuccess))
        return;
    
    while ((entry = IOIteratorNext(iter)) != IO_OBJECT_NULL) {
        if ((IORegistryEntryCreateCFProperties(entry, &servicedict, kCFAllocatorDefault, 0) != kIOReturnSuccess)) return;
        
        const void* data = CFDictionaryGetValue(servicedict, @"platform-name");;
        
        if (data != nil) {
            NSData* frmt_data = (NSData*)CFBridgingRelease(data);
            
            const unsigned char* databytes = [frmt_data bytes];
            
            unit_data->silicon_code = [[NSString stringWithFormat:@"%s", databytes] capitalizedString];
            
            frmt_data = nil;
        }
    }
    
    IOObjectRelease(entry);
    IOObjectRelease(iter);
//    CFRelease(service);
    
    return;
}

static inline void get_microarches(unit_data* unit_data) {
    if ([unit_data->silicon_name rangeOfString:@"m1"].location != NSNotFound) {
        unit_data->ecpu_microarch = @"Icestorm";
        unit_data->pcpu_microarch = @"Firestorm";
        return;
    } else if ([unit_data->silicon_name rangeOfString:@"m2"].location != NSNotFound) {
        unit_data->ecpu_microarch = @"Blizzard";
        unit_data->pcpu_microarch = @"Avalanche";
        return;
    } else {
        unit_data->ecpu_microarch = @"Unknown";
        unit_data->pcpu_microarch = @"Unknown";
    }
    
    io_registry_entry_t     service;
    NSData *                data;

    const unsigned char *   ecpu_microarch = NULL;
    const unsigned char *   pcpu_microarch = NULL;
    
    mach_port_t port;
    if (@available(macOS 12, *))
        port = kIOMainPortDefault;
    else
        port = kIOMasterPortDefault;
    
    int cores = [unit_data->percluster_ncores[0] intValue] + [unit_data->percluster_ncores[1] intValue] - 1;
    
    if ((service = IORegistryEntryFromPath(port, "IOService:/AppleARMPE/cpu0"))) {
        if ((data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("compatible"), kCFAllocatorDefault, 0)))
            ecpu_microarch = [data bytes];
    }
    
    if ((service = IORegistryEntryFromPath(port, [[NSString stringWithFormat:@"IOService:/AppleARMPE/cpu%d", cores] UTF8String]))) {
        if ((data = (__bridge NSData *)(CFDataRef)IORegistryEntryCreateCFProperty(service, CFSTR("compatible"), kCFAllocatorDefault, 0)))
            pcpu_microarch = [data bytes];
    }
    
    unit_data->ecpu_microarch = [[[NSString stringWithFormat:@"%s", ecpu_microarch] componentsSeparatedByString:@","][1] capitalizedString];
    unit_data->pcpu_microarch = [[[NSString stringWithFormat:@"%s", pcpu_microarch] componentsSeparatedByString:@","][1] capitalizedString];
}

static inline void init_unit_data(unit_data* data) {
    memset((void*)data, 0, sizeof(unit_data));

    cpu_samples_perf_data* core_perf_data = &data->soc_samples.core_perf_data;
    cpu_samples_perf_data* cluster_perf_data = &data->soc_samples.cluster_perf_data;
    pwr_samples_perf_data* pwr_perf_data = &data->pwr_samples.perf_data;
    clpc_samples_perf_data* clpc_perf_data = &data->clpc_samples.perf_data;
    
    /* get soc name
     */
    size_t len = 32;
    char* cpubrand = malloc(len);
    sysctlbyname("machdep.cpu.brand_string", cpubrand, &len, NULL, 0);

    if (cpubrand != NULL)
        data->silicon_name = [[NSString stringWithFormat:@"%s", cpubrand, nil] lowercaseString];
    else
        data->silicon_name = @"Unknown SoC";
    
    free(cpubrand);
    
    /* get constant data
     */
    NSMutableArray* freq_states = [NSMutableArray arrayWithCapacity:3];
    NSMutableArray* volt_states = [NSMutableArray arrayWithCapacity:3];
    
    make_dvfs_table(freq_states, volt_states);
    
    data->percluster_ncores = [NSMutableArray arrayWithCapacity:3];
    
    get_core_counts(data);
    get_silicon_code(data);
    get_microarches(data);
    
    /* input chann keys / dvfs stuff
     */
    if ([data->silicon_name rangeOfString:@"virtual"].location != NSNotFound) {
        error(1, "Running this tool in a Virtual Machine is not allowed");
    }
    
    if ([data->silicon_name rangeOfString:@"pro"].location != NSNotFound ||
        [data->silicon_name rangeOfString:@"max"].location != NSNotFound) {

        data->soc_samples.complex_channkeys = promax_complex_freq_chankeys;
        data->soc_samples.core_channkeys = promax_core_freq_chankeys;
        data->pwr_samples.complex_channkeys = promax_complex_pwr_chankeys;
        data->pwr_samples.core_channkeys = promax_core_pwr_chankeys;
        
        data->soc_samples.dvfs_freq_states = [NSArray arrayWithObjects: freq_states[0], freq_states[1], freq_states[1], freq_states[2], nil];
        data->soc_samples.dvfs_voltage_states = [NSArray arrayWithObjects: volt_states[0], volt_states[1], volt_states[1], volt_states[2], nil];
    } else if ([data->silicon_name rangeOfString:@"ultra"].location != NSNotFound) {
        data->soc_samples.complex_channkeys = ultra_complex_freq_chankeys;
        data->soc_samples.core_channkeys = ultra_core_freq_chankeys;
        data->pwr_samples.complex_channkeys = ultra_complex_pwr_chankeys;
        data->pwr_samples.core_channkeys = ultra_core_pwr_chankeys;
        
        data->soc_samples.dvfs_freq_states = [NSArray arrayWithObjects: freq_states[0], freq_states[0], freq_states[1], freq_states[1], freq_states[1], freq_states[1], freq_states[2], nil];
        data->soc_samples.dvfs_voltage_states = [NSArray arrayWithObjects: volt_states[0], volt_states[0], volt_states[1], volt_states[1], volt_states[1], volt_states[1], volt_states[2], nil];
    } else {
        data->soc_samples.complex_channkeys = pleb_complex_freq_chankeys;
        data->soc_samples.core_channkeys = pleb_core_freq_chankeys;
        data->pwr_samples.complex_channkeys = pleb_complex_pwr_chankeys;
        data->pwr_samples.core_channkeys = pleb_core_pwr_chankeys;
        
        data->soc_samples.dvfs_freq_states = freq_states;
        data->soc_samples.dvfs_voltage_states = volt_states;
    }
    
    NSUInteger percluster_ncores = [data->percluster_ncores count];
    
    /* cluster (+ 1 for GPU) */
    cluster_perf_data->distribution = [NSMutableArray arrayWithCapacity:percluster_ncores + 1];
    cluster_perf_data->freqs = [NSMutableArray arrayWithCapacity:percluster_ncores + 1];
    cluster_perf_data->volts = [NSMutableArray arrayWithCapacity:percluster_ncores + 1];
    cluster_perf_data->residency = [NSMutableArray arrayWithCapacity:percluster_ncores + 1];
    cluster_perf_data->sums = [NSMutableArray arrayWithCapacity:percluster_ncores + 1];
    pwr_perf_data->cluster_pwr = [NSMutableArray arrayWithCapacity:percluster_ncores + 1];
    
    /* core */
    core_perf_data->distribution = [NSMutableArray arrayWithCapacity:percluster_ncores];
    core_perf_data->freqs = [NSMutableArray arrayWithCapacity:percluster_ncores];
    core_perf_data->volts = [NSMutableArray arrayWithCapacity:percluster_ncores];
    core_perf_data->residency = [NSMutableArray arrayWithCapacity:percluster_ncores];
    core_perf_data->sums = [NSMutableArray arrayWithCapacity:percluster_ncores];
    pwr_perf_data->core_pwr = [NSMutableArray arrayWithCapacity:percluster_ncores];
    
    /* clpc */
    clpc_perf_data->insn_perclk = [NSMutableArray arrayWithCapacity:percluster_ncores];
    clpc_perf_data->insn_retired = [NSMutableArray arrayWithCapacity:percluster_ncores];
    
    for (int i = 0; i < percluster_ncores + 1; i++) {
        
        /* cluster */
        cluster_perf_data->distribution[i] = [NSMutableArray array];
        cluster_perf_data->freqs[i] = @0;
        cluster_perf_data->volts[i] = @0;
        cluster_perf_data->residency[i] = @0;
        cluster_perf_data->sums[i] = @0;
        pwr_perf_data->cluster_pwr[i] = @0;

        if (i < percluster_ncores) {
            /* clpc */
            clpc_perf_data->insn_perclk[i] = @0;
            clpc_perf_data->insn_retired[i] = @0;
            
            int cluster_ncores = [data->percluster_ncores[i] intValue];
            
            /* core */
            core_perf_data->distribution[i] = [NSMutableArray arrayWithCapacity:cluster_ncores];
            core_perf_data->freqs[i] = [NSMutableArray arrayWithCapacity:cluster_ncores];
            core_perf_data->volts[i] = [NSMutableArray arrayWithCapacity:cluster_ncores];
            core_perf_data->residency[i] = [NSMutableArray arrayWithCapacity:cluster_ncores];
            core_perf_data->sums[i] = [NSMutableArray arrayWithCapacity:cluster_ncores];
            pwr_perf_data->core_pwr[i] =  [NSMutableArray arrayWithCapacity:cluster_ncores];
            
            for (int ii = 0; ii < cluster_ncores; ii++) {
                core_perf_data->distribution[i][ii] = [NSMutableArray array];
                core_perf_data->sums[i][ii] = @0;
                core_perf_data->freqs[i][ii] = @0;
                core_perf_data->volts[i][ii] = @0;
                core_perf_data->residency[i][ii] = @0;
                pwr_perf_data->core_pwr[i][ii] = @0;
            }
        }
    }
    
    data->soc_samples.cpu_chann = IOReportCopyChannelsInGroup(@"CPU Stats", 0, 0, 0, 0);
    data->soc_samples.gpu_chann = IOReportCopyChannelsInGroup(@"GPU Stats", 0, 0, 0, 0);
    data->pwr_samples.energy_chann = IOReportCopyChannelsInGroup(@"Energy Model", 0, 0, 0, 0);
    data->pwr_samples.pmp_chann = IOReportCopyChannelsInGroup(@"PMP", 0, 0, 0, 0);
    data->clpc_samples.clpc_chann = IOReportCopyChannelsInGroup(@"CLPC Stats", 0, 0, 0, 0);
    
    IOReportMergeChannels(data->soc_samples.cpu_chann, data->soc_samples.gpu_chann, NULL);
    IOReportMergeChannels(data->pwr_samples.energy_chann, data->pwr_samples.pmp_chann, NULL);
    
    data->soc_samples.cpu_sub  = IOReportCreateSubscription(NULL, data->soc_samples.cpu_chann, &data->soc_samples.cpu_sub_chann, 0, 0);
    data->pwr_samples.pwr_sub  = IOReportCreateSubscription(NULL, data->pwr_samples.energy_chann, &data->pwr_samples.pwr_sub_chann, 0, 0);
    data->clpc_samples.clpc_sub = IOReportCreateSubscription(NULL, data->clpc_samples.clpc_chann, &data->clpc_samples.clpc_sub_chann, 0, 0);
    
    CFRelease(data->soc_samples.cpu_chann);
    CFRelease(data->soc_samples.gpu_chann);
    CFRelease(data->pwr_samples.energy_chann);
    CFRelease(data->pwr_samples.pmp_chann);
    CFRelease(data->clpc_samples.clpc_chann);
}

static inline void init_cmd_data(cmd_data* data) {
    memset((void*)data, 0, sizeof(cmd_data));
    
    data->interval = 275;
    data->samples = 1;
    
    data->file_out = stdout;
    data->pwr_unit = PWR_UNIT_MWATT;
    data->pwr_unit_label = PWR_UNIT_MWATT_LABEL;
    data->freq_unit = FREQ_UNIT_MHZ;
    data->freq_unit_label = FREQ_UNIT_MHZ_LABEL;
    
    data->flags.show_active = true;
    data->flags.show_pwr = true;
    data->flags.show_freq = true;
    data->flags.show_dvfs = true;
    data->flags.show_insns = true;
    data->flags.show_percore = true;
}
