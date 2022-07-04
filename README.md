<h1 align="center" style="">M<i>x</i>SocPowerBuddy</h1>
<p align="center">

</p>
<p align="center">
    <a href="https://github.com/BitesPotatoBacks/MxSocPowerBuddy/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/MxSocPowerBuddy.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/MxSocPowerBuddy/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/MxSocPowerBuddy.svg"/>
    </a>
   <a href="https://github.com/BitesPotatoBacks/MxSocPowerBuddy/stargazers">
        <img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/MxSocPowerBuddy.svg"/>
    </a>
    <br>
</p>

A sudoless implementation to profile your Apple M-Series CPU+GPU active core and cluster frequencies, residencies, power consumption, and other metricss.

The tool is up to 35% faster than `powermetrics -s cpu_power,gpu_power` when using the same sampling interval, but with higher efficiency and the same level of accuracy. It currently lacks Instrcutions retired/per-clock metrics, but otherwise offers everything `powermetrics -s cpu_power,gpu_power` does, plus extra statistics (and even more to come).

## Installation and Usage

1. Download .zip file from [latest release](https://github.com/BitesPotatoBacks/MxSocPowerBuddy/releases).
2. Unzip the downloaded .zip file (via Finder or Terminal)
3. `cd` into the dir containing the unzipped binary and perform a `xattr cr ./mxsocpwrbud`, as the binary is not codesigned (future releases will be)
3. Move the binary to your desired location 
4. You may now run the tool using `mxsocpwrbud`

<details>

<summary>Example Output</summary>

The following is a single metric sample taken by executing `mxsocpwrbud -i1000 -m%res,freq,power,cores,pstates` on an Macmini9,1 while running an GeekBench Benchmark:

```
Apple M1 T8103 (Sample 1):

	4-Core Icestorm E-Cluster:

		Power Consumption: 51.00 mW
		Active Frequency:  1092.65 MHz
		Active Residency:  48.676%
		P-State Distribution: 972 [P1]: 72.52% 1332 [P2]: 22.99% 1704 [P3]: 3.10% 2064 [P4]: 1.39% 

		Core 0:
			Power Consumption: 10.00 mW
			Active Frequency:  1091.69 MHz
			Active Residency:  18.501%
		Core 1:
			Power Consumption: 9.00 mW
			Active Frequency:  1132.19 MHz
			Active Residency:  14.999%
		Core 2:
			Power Consumption: 14.00 mW
			Active Frequency:  1115.10 MHz
			Active Residency:  21.232%
		Core 3:
			Power Consumption: 6.00 mW
			Active Frequency:  1048.75 MHz
			Active Residency:  13.521%

	4-Core Firestorm P-Cluster:

		Power Consumption: 786.00 mW
		Active Frequency:  2652.62 MHz
		Active Residency:  17.157%
		P-State Distribution: 600 [P0]: 0.03% 1056 [P2]: 7.16% 1284 [P3]: 4.87% 1500 [P4]: 4.89% 1728 [P5]: 4.90% 1956 [P6]: 2.43% 2184 [P7]: 4.90% 2388 [P8]: 2.43% 2592 [P9]: 4.90% 2772 [P10]: 2.44% 2988 [P11]: 2.44% 3144 [P13]: 2.81% 3204 [P14]: 55.80% 

		Core 4:
			Power Consumption: 593.00 mW
			Active Frequency:  2652.86 MHz
			Active Residency:  17.163%
		Core 5:
			Power Consumption: 1.00 mW
			Active Frequency:  3204.00 MHz
			Active Residency:  0.042%
		Core 6:
			Power Consumption: 0.00 mW
			Active Frequency:  3170.85 MHz
			Active Residency:  0.007%
		Core 7:
			Power Consumption: 0.00 mW
			Active Frequency:  0.00 MHz
			Active Residency:  0.000%

	8-Core  Integrated Graphics:

		Power Consumption: 4728.00 mW
		SRAM Power Draw:   0.00 mW
		Active Frequency:  1272.99 MHz
		Active Residency:  70.175%
		P-State Distribution: 396 [P0]: 0.38% 720 [P2]: 0.30% 1278 [P5]: 99.32% 

```

</details>

Tool usage is listed by `mxsocpwrbud --help`.

## Planned Features
The following features shall be implemented in upcoming minor updates:
- ANE metrics (frequencies, residencies, power)
- CPU Interrupts retired/per-clock
- GPU requested frequencies
- CPU per-cluster and GPU throttling statistics

## Potenial Issues
MxSocPowerBuddy has been written for portability, but has only been tested on Apple M1. Compatibillity issues (if any) will be fixed as soon as possible when identifed.

If any bugs or issues are found, please let me know in the [issues](https://github.com/BitesPotatoBacks/MxSocPowerBuddy/issues) section.

## Support
If you would like to support this project, a small donation to my [Cash App](https://cash.app/$bitespotatobacks) would be much appreciated!
