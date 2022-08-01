<h1 align="center" style="">M<i>x</i>SocPowerBuddy</h1>
<p align="center">
A sudoless implementation to profile your Apple M-Series CPU+GPU active core and cluster frequencies, residencies, power consumption, and other metrics.
</p>
<p align="center">
<a href="">
       <img alt="Silicon Support" src="https://img.shields.io/badge/SoC_Support-All_M1_Series_Offical-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/MxSocPowerBuddy/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/MxSocPowerBuddy.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/MxSocPowerBuddy/stargazers">
        <img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/MxSocPowerBuddy.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/MxSocPowerBuddy/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/MxSocPowerBuddy.svg"/>
    </a>
</p>

## Project Deets
Unlike `powermetrics`, this tool currently lacks Instructions retired/per-clock statistics (for now), but otherwise offers everything `powermetrics -s cpu_power,gpu_power` does (yet without needing `sudo`).

There are some metrics exclusive to this project (such as per-core power draw, silicon IDs, microarch names, and unit measurement choices), which you will not find in `powermetrics`. This tool also has a higher potential for efficency -- and is actually open source! Yay!


## Installation and Usage

1. Download .zip file from [latest release](https://github.com/BitesPotatoBacks/MxSocPowerBuddy/releases).
2. Unzip the downloaded .zip file (via Finder or Terminal)
3. Move the binary from the unzipped folder into your desired location 
4. You may now run the tool using `./mxsocpwrbud`

<details>

<summary>Example Output</summary>

The following is a single metric sample taken by executing `mxsocpwrbud -a` on an Macmini9,1 while running an GeekBench Benchmark:

```
Apple M1 T8103 (Sample 1):

	4-Core Icestorm ECPU:

		Power Consumption: 63.16 mW
		Active Frequency:  1237.05 MHz
		Active Residency:  39.85%
		P-State Distribution: (972 MHz: 64.18%  1332 MHz: 12.07%  1704 MHz: 10.50%  2064 MHz: 13.26%) 

		Core 0:
			Power Consumption: 8.42 mW
			Active Frequency:  1134.73 MHz
			Active Residency:  12.04%
		Core 1:
			Power Consumption: 8.42 mW
			Active Frequency:  1109.80 MHz
			Active Residency:  14.61%
		Core 2:
			Power Consumption: 14.74 mW
			Active Frequency:  1192.51 MHz
			Active Residency:  16.16%
		Core 3:
			Power Consumption: 16.84 mW
			Active Frequency:  1467.09 MHz
			Active Residency:  10.30%

	4-Core Firestorm PCPU:

		Power Consumption: 1164.21 mW
		Active Frequency:  2698.44 MHz
		Active Residency:  39.47%
		P-State Distribution: (600 MHz: 0.06%  828 MHz: 2.05%  1056 MHz: 4.15%  1284 MHz: 4.26%  1500 MHz: 4.14%  1728 MHz: 4.16%  1956 MHz: 4.17%  2184 MHz: 4.13%  2388 MHz: 3.62%  2592 MHz: 2.07%  2772 MHz: 2.09%  2988 MHz: 2.06%  3096 MHz: 2.07%  3204 MHz: 60.95%) 

		Core 4:
			Power Consumption: 1096.84 mW
			Active Frequency:  2699.33 MHz
			Active Residency:  39.46%
		Core 5:
			Power Consumption: 2.11 mW
			Active Frequency:  3065.56 MHz
			Active Residency:  0.09%
		Core 6:
			Power Consumption: 0.00 mW
			Active Frequency:  3204.00 MHz
			Active Residency:  0.00%
		Core 7:
			Power Consumption: 0.00 mW
			Active Frequency:  600.00 MHz
			Active Residency:  0.01%

	8-Core Integrated Graphics:

		Power Consumption: 2.11 mW
		Active Frequency:  708.43 MHz
		Active Residency:  1.81%
		P-State Distribution: (396 MHz: 3.57%  720 MHz: 96.43%) 

```

</details>

Tool usage is listed by `mxsocpwrbud --help`.

## Issues
#### No issues identified as of patch v0.1.2

If any bugs or issues are found, please let me know in the [issues](https://github.com/BitesPotatoBacks/MxSocPowerBuddy/issues) section.

## Support
If you would like to support this project, a small donation to my [Cash App](https://cash.app/$bitespotatobacks) would be much appreciated!
