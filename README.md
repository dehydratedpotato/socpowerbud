<h1 align="center" style="">SocPowerBuddy</h1>
<p align="center">
A sudoless alternative to Powermetrics; able to profile your Apple M-Series CPU+GPU active core and cluster frequencies, residencies, power consumption, and other metrics.
</p>
<p align="center">
<a href="">
       <img alt="Silicon Support" src="https://img.shields.io/badge/SoC_Support-M1_Series_(Tested)-orange.svg"/>
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

## Project Deets
SocPowerBuddy now reports every statistic offered by `powermetrics -s cpu_power,gpu_power`, yet without needing `sudo`.
<details>

<summary>List of available metrics</summary>

- Per-Core Metrics for Clusters
- Active and Idle Residencies
- Active Frequencies
- DVFM (Similar to P-State) Distribution and Time Spent
- Power Consumption
- Instructions Retired and Per-Clock
- Supposed CPU Cycles Spent (during sample)

</details>

There are some metrics exclusive to this project (such as per-core power draw, silicon IDs, microarch names, and unit measurement choices), which you will not find in `powermetrics`. This tool also has a higher potential for efficency -- and is actually open source! Yay!

## Installation and Usage

1. Download the .zip file from [latest release](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases).
2. Unzip the downloaded file (via Finder or Terminal)
3. Move the binary from the unzipped folder into your desired location (such as `/usr/bin`) 
4. You may now run the tool using the `socpwrbud` binary

<details>

<summary>Example Output</summary>

The following is a single metric sample taken by executing `socpwrbud -a -i 275` on an Macmini9,1:

```
Apple M1 T8103 (Sample 1):

	4-Core Icestorm ECPU:

		Supposed Cycles Spent:  59481201
		Instructions Retired:   5.64512e+07
		Instructions Per-Clock: 0.94906

		Power Consumption: 14.55 mW
		Active Frequency:  983.11 MHz

		Active Residency:  14.00%
		Idle Residency:    86.00%
		Dvfm Distribution: (972 MHz: 98.98% [272ms]   2064 MHz: 1.02% [3ms])  

		Core 0:
			Power Consumption: 3.64 mW
			Active Frequency:  981.60 MHz
			Active Residency:  10.10%
			Idle Residency:    89.90%
			Dvfm Distribution: (972 MHz: 99.12% [273ms]   2064 MHz: 0.88% [2ms])  
		Core 1:
			Power Consumption: 3.64 mW
			Active Frequency:  986.19 MHz
			Active Residency:  4.49%
			Idle Residency:    95.51%
			Dvfm Distribution: (972 MHz: 98.70% [271ms]   2064 MHz: 1.30% [4ms])  
		Core 2:
			Power Consumption: 0 mW
			Active Frequency:  983.45 MHz
			Active Residency:  2.13%
			Idle Residency:    97.87%
			Dvfm Distribution: (972 MHz: 98.95% [272ms]   2064 MHz: 1.05% [3ms])  
		Core 3:
			Power Consumption: 3.64 mW
			Active Frequency:  978.33 MHz
			Active Residency:  2.70%
			Idle Residency:    97.30%
			Dvfm Distribution: (972 MHz: 99.42% [273ms]   2064 MHz: 0.58% [2ms])  

	4-Core Firestorm PCPU:

		Supposed Cycles Spent:  313447262
		Instructions Retired:   8.14210e+08
		Instructions Per-Clock: 2.59760

		Power Consumption: 723.64 mW
		Active Frequency:  3191.44 MHz

		Active Residency:  29.01%
		Idle Residency:    70.99%
		Dvfm Distribution: (600 MHz: 0.36% [1ms]   1500 MHz: 0.03% [0ms]   1956 MHz: 0.21% [1ms]   3204 MHz: 99.40% [273ms])  

		Core 4:
			Power Consumption: 530.91 mW
			Active Frequency:  3194.33 MHz
			Active Residency:  28.95%
			Idle Residency:    71.05%
			Dvfm Distribution: (600 MHz: 0.28% [1ms]   1500 MHz: 0.03% [0ms]   1956 MHz: 0.16% [0ms]   3204 MHz: 99.54% [274ms])  
		Core 5:
			Power Consumption: 14.55 mW
			Active Frequency:  3103.99 MHz
			Active Residency:  0.90%
			Idle Residency:    99.10%
			Dvfm Distribution: (600 MHz: 2.78% [8ms]   1956 MHz: 2.22% [6ms]   3204 MHz: 95.00% [261ms])  
		Core 6:
			Power Consumption: 0 mW
			Active Frequency:  0 MHz
			Active Residency:  0%
			Idle Residency:    100%
			Dvfm Distribution: None
		Core 7:
			Power Consumption: 0 mW
			Active Frequency:  0 MHz
			Active Residency:  0%
			Idle Residency:    100%
			Dvfm Distribution: None

	8-Core Integrated Graphics:

		Power Consumption: 0 mW
		Active Frequency:  705.69 MHz

		Active Residency:  1.56%
		Idle Residency:    98.44%
		Dvfm Distribution: (396 MHz: 4.42% [12ms]   720 MHz: 95.58% [263ms])  
```

</details>

Tool usage is listed by `socpwrbud --help`.

## Issues
- There may be some memory fragmentation that results in slow-rising memory consumption (~1mb every 60 samples) during long sampling periods (see [#6](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues/6))
- M1 Ultra support is still iffy (see [#5](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues/5)) but should be fixed with release [v0.3.1](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases/tag/v0.3.1)
- M2 support is unknown but should work

If any bugs or issues are found, please let me know in the [issues](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues) section.


## Support
If you would like to support this project, a small donation to my [Cash App](https://cash.app/$bitespotatobacks) would be much appreciated!
