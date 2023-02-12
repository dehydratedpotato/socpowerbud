<h1 align="center">SoC Power Buddy</h1>
<p align="center">
A sudoless command-line tool to get per-core active frequencies, residency, power, and more (for Apple Silicon CPUs and GPUs).
</p>
<p align="center">
    <a href="https://github.com/BitesPotatoBacks/SocPowerBuddy/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/SocPowerBuddy.svg"/>
    </a>
    <a href="">
       <img alt="Platform" src="https://img.shields.io/badge/platform-macOS-lightgray.svg"/>
    </a>
    <a href="">
       <img alt="Silicon Support" src="https://img.shields.io/badge/support-M1_Series-orange.svg"/>
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

## Project Deets
### Wat it do
SocPowerBuddy samples counter values from the IOReport (across a sampling interval) and returns accurate averages of the related metric.

It is based on reverse engineering `powermetrics`, and reports every statistic offered by `powermetrics -s cpu_power,gpu_power` (see [full metric list](#features) and [example output](#example)), yet without needing `sudo`. Note that some metrics and features are exclusive to this project, those of which you will not find in `powermetrics`.

Officially tested on M1, as well as M1 Pro, Max, and Ultra (see [compatibility notes](#compatibility-notes))

### Why it do
Because needing to be system admin in order to monitor Apple Silicon frequencies is dumb (yeah, I'm looking at you, `powermetrics`). So here you go! No administrative privileges needed! 

### Example Output
**Note:** The following is a single output from the project on a Macmini9,1.
<details>

<summary>Expand Example</summary>

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
| M1 Pro | t6000 | Fully Working |
| M1 Max | t6001 | Fully Working |
| M1 Ultra | t6002 | Should work (see [#5](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues/5) and patch [v0.3.1](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases/tag/v0.3.1)) |
| M2 | t8112 | Should work |
| M2 Pro | t6020 | Untested |
| M2 Max | t6021 | Untested |

## Contribution
If any bugs or issues are found, please let me know in the [issues](https://github.com/BitesPotatoBacks/SocPowerBuddy/issues) section. If the problem is related to missing IOReport entries, please share the output of the `iorepdump` tool found in the [latest release](https://github.com/BitesPotatoBacks/SocPowerBuddy/releases/latest). Feel free to open a PR if you know what you're doing :smile:




