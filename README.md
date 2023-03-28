<h1 align="center">SoC Power Buddy</h1>
<p align="center">
A sudoless command-line utility designed to profile per-core frequencies, cycles, instructions, power, and more - for Apple Silicon CPUs and GPUs!
</p>
<p align="center">
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
    <a href="">
       <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-lightgray.svg"/>
    </a>
    <a href="">
       <img alt="Silicon Support" src="https://img.shields.io/badge/support-Apple_Silicon-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/stargazers">
        <img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
</p>

___

- **Table of contents**
  - **[Project Deets](#project-deets)**
    - [Wat it do?](#wat-it-do)
    - [Why it do?](#why-it-do)
    - [Example Output](#example-output)
  - [Features](#features)
  - **[Installation, Usage, and Making](#installation-usage-and-making)**
    - [Install using Homebrew](#install-using-homebrew)
    - [Install manually](#install-manually)
    - [Building yourself](#building-yourself)
  - [Outside Influence](#outside-influence)
  - [Compatibility Notes](#compatibility-notes)
  - [Contribution](#contribution)

___
# 📰 News!
I just started a new project, [Frequency Stats](https://github.com/BitesPotatoBacks/FrequencyStats), which is a menubar app that provides CPU and GPU frequency metrics without needing to install a dameon or a kext. It was inspired by this tool, check it out if you want something more convenient for frequency monitoring! New features to come!

## Project Deets
### Wat it do
SocPowerBuddy samples counter values from the IOReport (across a sampling interval) and returns accurate averages of the related metric.

It is based on reverse engineering `powermetrics`, and reports every statistic offered by `powermetrics -s cpu_power,gpu_power` (see [full metric list](#features) and [example output](#example)), yet without needing `sudo`. Note that some metrics and features are exclusive to this project, those of which you will not find in `powermetrics`.

Officially tested on M1, as well as M1 Pro, Max, and Ultra (see [compatibility notes](#compatibility-notes))

### Why it do
Because needing to be system admin in order to monitor Apple Silicon frequencies is dumb (yeah, I'm looking at you, `powermetrics`). So here you go! No administrative privileges needed! 

### Example Output
**Note:** The following is a nice big juicy output of `socpwrbud` running on a Macmini9,1.
<details>

<summary>Expand Example to see!</summary>

```
Apple M1 T8103 (Sample 1):

	4-Core Icestorm ECPU:

		Supposed Cycles Spent:  1318404262
		Instructions Retired:   1.66480e+09
		Instructions Per-Clock: 1.26274

		Power Consumption: 65.89 mW

		Active Voltage:    825.13 mV
		Active Frequency:  1323.49 MHz

		Active Residency:  29.4%
		Idle Residency:    70.6%
		Dvfm Distribution: 972MHz, 771mV: 52.64% (1086ms)   1332MHz, 800mV: 19.08% (394ms)   1704MHz, 887mV: 7.24% (149ms)   2064MHz, 962mV: 21.05% (434ms)   

		Core 0:
			Power Consumption: 14.53 mW
			Active Voltage:    831.05 mV
			Active Frequency:  1356.95 MHz
			Active Residency:  15.6%
			Idle Residency:    84.4%
			Dvfm Distribution: 972MHz, 771mV: 49.64% (1025ms)   1332MHz, 800mV: 18.59% (384ms)   1704MHz, 887mV: 8.02% (166ms)   2064MHz, 962mV: 23.75% (490ms)   
		Core 1:
			Power Consumption: 13.57 mW
			Active Voltage:    831.42 mV
			Active Frequency:  1361.03 MHz
			Active Residency:  14.9%
			Idle Residency:    85.1%
			Dvfm Distribution: 972MHz, 771mV: 48.81% (1007ms)   1332MHz, 800mV: 20.44% (422ms)   1704MHz, 887mV: 5.65% (117ms)   2064MHz, 962mV: 25.10% (518ms)   
		Core 2:
			Power Consumption: 12.11 mW
			Active Voltage:    838.65 mV
			Active Frequency:  1397.5 MHz
			Active Residency:  12.1%
			Idle Residency:    87.9%
			Dvfm Distribution: 972MHz, 771mV: 47.09% (972ms)   1332MHz, 800mV: 17.68% (365ms)   1704MHz, 887mV: 6.34% (131ms)   2064MHz, 962mV: 28.88% (596ms)   
		Core 3:
			Power Consumption: 7.75 mW
			Active Voltage:    845.17 mV
			Active Frequency:  1424.25 MHz
			Active Residency:  9.0%
			Idle Residency:    91.0%
			Dvfm Distribution: 972MHz, 771mV: 48.17% (994ms)   1332MHz, 800mV: 11.96% (247ms)   1704MHz, 887mV: 7.28% (150ms)   2064MHz, 962mV: 32.60% (673ms)   

	4-Core Firestorm PCPU:

		Supposed Cycles Spent:  3590801722
		Instructions Retired:   1.37992e+10
		Instructions Per-Clock: 3.84294

		Power Consumption: 1912.79 mW

		Active Voltage:    1051.20 mV
		Active Frequency:  3003.88 MHz

		Active Residency:  53.3%
		Idle Residency:    46.7%
		Dvfm Distribution: 600MHz, 781mV: 0.20% (4ms)   828MHz, 781mV: 0.70% (15ms)   1056MHz, 781mV: 1.85% (38ms)   1284MHz, 800mV: 2.17% (45ms)   1500MHz, 812mV: 1.62% (33ms)   1728MHz, 831mV: 1.62% (34ms)   1956MHz, 865mV: 1.63% (34ms)   2184MHz, 909mV: 1.06% (22ms)   2388MHz, 953mV: 0.95% (20ms)   2592MHz, 1003mV: 0.36% (7ms)   2772MHz, 1053mV: 0.72% (15ms)   2988MHz, 1081mV: 0.36% (7ms)   3096MHz, 1081mV: 0.03% (1ms)   3144MHz, 1081mV: 0.43% (9ms)   3204MHz, 1081mV: 86.30% (1781ms)   

		Core 4:
			Power Consumption: 1038.76 mW
			Active Voltage:    1034.99 mV
			Active Frequency:  2895.56 MHz
			Active Residency:  33.9%
			Idle Residency:    66.1%
			Dvfm Distribution: 600MHz, 781mV: 0.31% (6ms)   828MHz, 781mV: 1.07% (22ms)   1056MHz, 781mV: 2.68% (55ms)   1284MHz, 800mV: 3.42% (71ms)   1500MHz, 812mV: 2.54% (52ms)   1728MHz, 831mV: 2.55% (53ms)   1956MHz, 865mV: 2.56% (53ms)   2184MHz, 909mV: 1.65% (34ms)   2388MHz, 953mV: 1.48% (31ms)   2592MHz, 1003mV: 0.56% (12ms)   2772MHz, 1053mV: 1.13% (23ms)   2988MHz, 1081mV: 0.56% (12ms)   3096MHz, 1081mV: 0.05% (1ms)   3144MHz, 1081mV: 0.67% (14ms)   3204MHz, 1081mV: 78.77% (1626ms)   
		Core 5:
			Power Consumption: 687.02 mW
			Active Voltage:    1044.88 mV
			Active Frequency:  2970.58 MHz
			Active Residency:  21.5%
			Idle Residency:    78.5%
			Dvfm Distribution: 600MHz, 781mV: 0.02% (0ms)   828MHz, 781mV: 0.25% (5ms)   1056MHz, 781mV: 2.36% (49ms)   1284MHz, 800mV: 2.66% (55ms)   1500MHz, 812mV: 2.22% (46ms)   1728MHz, 831mV: 2.20% (45ms)   1956MHz, 865mV: 2.41% (50ms)   2184MHz, 909mV: 1.72% (35ms)   2388MHz, 953mV: 0.81% (17ms)   2592MHz, 1003mV: 0.11% (2ms)   2988MHz, 1081mV: 0.01% (0ms)   3096MHz, 1081mV: 0.01% (0ms)   3204MHz, 1081mV: 85.22% (1759ms)   
		Core 6:
			Power Consumption: 23.26 mW
			Active Voltage:    836.13 mV
			Active Frequency:  1626.58 MHz
			Active Residency:  3.1%
			Idle Residency:    96.9%
			Dvfm Distribution: 600MHz, 781mV: 0.19% (4ms)   828MHz, 781mV: 0.54% (11ms)   1056MHz, 781mV: 15.96% (329ms)   1284MHz, 800mV: 18.74% (387ms)   1500MHz, 812mV: 15.62% (322ms)   1728MHz, 831mV: 15.51% (320ms)   1956MHz, 865mV: 15.60% (322ms)   2184MHz, 909mV: 11.87% (245ms)   2388MHz, 953mV: 5.66% (117ms)   3204MHz, 1081mV: 0.31% (6ms)   
		Core 7:
			Power Consumption: 60.56 mW
			Active Voltage:    895.57 mV
			Active Frequency:  2009.28 MHz
			Active Residency:  4.0%
			Idle Residency:    96.0%
			Dvfm Distribution: 828MHz, 781mV: 0.17% (4ms)   1056MHz, 781mV: 12.91% (266ms)   1284MHz, 800mV: 14.16% (292ms)   1500MHz, 812mV: 11.83% (244ms)   1728MHz, 831mV: 11.81% (244ms)   1956MHz, 865mV: 11.79% (243ms)   2184MHz, 909mV: 8.32% (172ms)   2388MHz, 953mV: 4.13% (85ms)   3204MHz, 1081mV: 24.89% (514ms)   

	8-Core Integrated Graphics:

		Power Consumption: 2.42 mW

		Active Voltage:    627.71 mV
		Active Frequency:  711.288 MHz

		Active Residency:  2.6%
		Idle Residency:    97.4%
		Dvfm Distribution: 396MHz, 400mV: 2.69% (56ms)   720MHz, 634mV: 97.31% (2008ms)   
```

</details>

# Features

The following is sampled per-cluster and is available for all sampled compute units!
- Active and Idle Residencies
- Active Frequencies
- DVFM (Similar to P-State) Distribution and Time Spent
- Power Consumption
- (Static) Silicon IDs

The following is sampled per-cluster but exclusive to the CPU!
- Instructions Retired and Per-cylce
- Supposed CPU Cycles Spent
- (Static) Per-Core metrics
- (Static) Micro architecture names

# Installation, Usage, and Making
**Note:** Tool usage is listed by `socpwrbud --help`

### Install using Homebrew
1. If you dont have Hombrew, [install it](https://brew.sh/index_ko)!
2. Add my tap using `brew tap BitesPotatoBacks/tap`
3. Install the tool with `brew install socpwrbud`
4. Run `socpwrbud`!

### Install manually
1. Download the bin from [latest release](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases).
2. Unzip the downloaded file into your desired dir (such as `/usr/bin`) 
4. Run `socpwrbud`!

### Building yourself
The source is bundled in a Xcode project and contains a make file. Simply run `make` or build via Xcode! The choice is yours.

___

## Outside Influence
This project has recently influenced the CPU/GPU power related metric gathering on [NeoAsitop](https://github.com/op06072/NeoAsitop)! Yay! Go check it out :heart:

## Compatibility Notes
Here's a sick table. 
| Silicon | Codename | Support Status |
|----|---|---|
| M1 | t8103 | Fully Working |
| M1 Pro | t6000 | Works (But no tests for binned 8-Core model) |
| M1 Max | t6001 | Fully Working |
| M1 Ultra | t6002 | Fully Working (see [#5](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues/5) and patch [v0.3.1](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases/tag/v0.3.1)) |
| M2 | t8112 | Should work? |
| M2 Pro | t6020 | Should work? |
| M2 Max | t6021 | Should work? |

## Contribution
If any bugs or issues are found, please let me know in the [issues](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues) section. If the problem is related to missing IOReport entries, please share the output of the `iorepdump` tool found in the [latest release](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases/latest). Feel free to open a PR if you know what you're doing :smile:




