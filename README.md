<h1 align="center" style="">SocPowerBuddy</h1>
<p align="center">
A sudoless implementation to profile your Apple M-Series CPU+GPU active core and cluster frequencies, residencies, power consumption, and other metrics.
</p>
<p align="center">
<a href="">
       <img alt="Silicon Support" src="https://img.shields.io/badge/SoC_Support-All_M1_Series_Offical-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/stargazers">
        <img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
</p>

## Project Deets and News
SocPowerBuddy now reports every statistic offered by `powermetrics -s cpu_power,gpu_power`, yet without needing `sudo`.

There are some metrics exclusive to this project (such as per-core power draw, silicon IDs, microarch names, and unit measurement choices), which you will not find in `powermetrics`. This tool also has a higher potential for efficency -- and is actually open source! Yay!

## Installation and Usage

1. Download .zip file from [latest release](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases).
2. Unzip the downloaded .zip file (via Finder or Terminal)
3. Move the binary from the unzipped folder into your desired location 
4. You may now run the tool using `./socpwrbud`

<details>

<summary>Example Output</summary>

The following is a single metric sample taken by executing `socpwrbud -a -i 275` on an Macmini9,1 while running an GeekBench Benchmark:

```
Apple M1 T8103 (Sample 1):

	4-Core Icestorm ECPU:

		Instructions Retired:   1.14869e+08
		Instructions Per-Clock: 1.35419

		Power Consumption: 21.82 mW
		Active Frequency:  1032.62 MHz
		Active Residency:  20.49%
		Dvfm Distribution: (972 MHz: 85.39% [235ms]   1332 MHz: 13.52% [37ms]   2064 MHz: 1.09% [3ms])  

		Core 0:
			Power Consumption: 3.64 mW
			Active Frequency:  1040.09 MHz
			Active Residency:  10.42%
			Dvfm Distribution: (972 MHz: 84.94% [234ms]   1332 MHz: 13.17% [36ms]   2064 MHz: 1.89% [5ms])  
		Core 1:
			Power Consumption: 3.64 mW
			Active Frequency:  1042.85 MHz
			Active Residency:  8.92%
			Dvfm Distribution: (972 MHz: 82.78% [228ms]   1332 MHz: 16.01% [44ms]   2064 MHz: 1.21% [3ms])  
		Core 2:
			Power Consumption: 3.64 mW
			Active Frequency:  1035.74 MHz
			Active Residency:  5.54%
			Dvfm Distribution: (972 MHz: 83.02% [228ms]   1332 MHz: 16.62% [46ms]   2064 MHz: 0.36% [1ms])  
		Core 3:
			Power Consumption: 0 mW
			Active Frequency:  1144.24 MHz
			Active Residency:  2.10%
			Dvfm Distribution: (972 MHz: 56.57% [156ms]   1332 MHz: 41.25% [113ms]   2064 MHz: 2.17% [6ms])  

	4-Core Firestorm PCPU:

		Instructions Retired:   4.08990e+09
		Instructions Per-Clock: 4.67874

		Power Consumption: 4254.55 mW
		Active Frequency:  3126.83 MHz
		Active Residency:  96.16%
		Dvfm Distribution: (600 MHz: 0.02% [0ms]   1956 MHz: 1.39% [4ms]   2184 MHz: 1.45% [4ms]   2388 MHz: 2.90% [8ms]   2592 MHz: 1.45% [4ms]   2772 MHz: 1.86% [5ms]   2988 MHz: 1.42% [4ms]   3144 MHz: 1.46% [4ms]   3204 MHz: 88.05% [242ms])  

		Core 4:
			Power Consumption: 247.27 mW
			Active Frequency:  3166.74 MHz
			Active Residency:  7.32%
			Dvfm Distribution: (600 MHz: 0.24% [1ms]   2772 MHz: 3.02% [8ms]   2988 MHz: 8.34% [23ms]   3204 MHz: 88.41% [243ms])  
		Core 5:
			Power Consumption: 3650.91 mW
			Active Frequency:  3123.67 MHz
			Active Residency:  90.59%
			Dvfm Distribution: (1956 MHz: 1.48% [4ms]   2184 MHz: 1.54% [4ms]   2388 MHz: 3.08% [8ms]   2592 MHz: 1.54% [4ms]   2772 MHz: 1.73% [5ms]   2988 MHz: 1.50% [4ms]   3144 MHz: 1.55% [4ms]   3204 MHz: 87.59% [241ms])  
		Core 6:
			Power Consumption: 0 mW
			Active Frequency:  3173.20 MHz
			Active Residency:  0.01%
			Dvfm Distribution: (2772 MHz: 7.13% [20ms]   3204 MHz: 92.87% [255ms])  
		Core 7:
			Power Consumption: 0 mW
			Active Frequency:  3204 MHz
			Active Residency:  0.00%
			Dvfm Distribution: (3204 MHz: 100% [275ms])  

	8-Core Integrated Graphics:

		Power Consumption: 3.64 mW
		Active Frequency:  705.09 MHz
		Active Residency:  1.10%
		Dvfm Distribution: (396 MHz: 4.60% [13ms]   720 MHz: 95.40% [262ms])  
```

</details>

Tool usage is listed by `socpwrbud --help`.

## Issues
#### No issues identified as of latest release

If any bugs or issues are found, please let me know in the [issues](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues) section.

## Support
If you would like to support this project, a small donation to my [Cash App](https://cash.app/$bitespotatobacks) would be much appreciated!
