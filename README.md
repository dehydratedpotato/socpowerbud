<h1 align="center" style="">osx-cpufreq</h1>

<p align="center">
    Get your CPUs current frequency, per core and per cluster
</p>
<p align="center">
    <a href="">
       <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple_Silicon-M1_Support-red.svg"/>
    </a>
    <a href="">
       <img alt="Intel" src="https://img.shields.io/badge/Intel-Limited_Support-blue.svg"/>
    </a>
        <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
<!--     <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/stargazers">
        <img alt="License" src="https://img.shields.io/github/stars/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a> -->
    <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
        <a href="https://cash.app/$bitespotatobacks">
        <img alt="License" src="https://img.shields.io/badge/donate-Cash_App-default.svg"/>
    </a>
    <!-- <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/osx-cpufreq.svg"/></a>-->
    <br>
</p>

## What It Does and How It Works
This project is designed to get the current frequency (or clock speed) of your CPU cores and clusters, without requiring `sudo` or a kernel extension. This near-impossible feat is achieved by accessing the CPU performance state values (which are hidden away in `IOReport`), and performing some calculations based on them during a specified time interval (default 1 second). 

This method is not only extremely accurate, but it is also the same concept used by the closed source OS X command line utility [Powermetrics](https://www.unix.com/man-page/osx/1/powermetrics/).
## Usage
### Preparation:
Download the precompiled binary from the [releases](https://github.com/BitesPotatoBacks/osx-cpufreq/releases), `cd` into your Downloads folder, and run these commands to fix the binary permissions:
```
chmod 755 ./osx-cpufreq
xattr -cr ./osx-cpufreq
```
Now you can simply run `./osx-cpufreq`.

### Example:
Here is an example running `./osx-cpufreq` on an M1 Mac Mini during a Geekbench run:
```
Name      Type      Max Freq     Active Freq    Freq %

CPU      Average   3204.00 MHz   1741.50 MHz    54.35%
ECPU     Cluster   2064.00 MHz   2061.42 MHz    99.88%
PCPU     Cluster   3204.00 MHz   3204.00 MHz   100.00%

ECPU 1      Core   2064.00 MHz   2038.20 MHz    98.75%
ECPU 2      Core   2064.00 MHz    363.53 MHz    17.61%
ECPU 3      Core   2064.00 MHz   1649.83 MHz    79.93%
ECPU 4      Core   2064.00 MHz    952.71 MHz    46.16%

PCPU 1      Core   3204.00 MHz   1714.70 MHz    53.52%
PCPU 2      Core   3204.00 MHz   3204.00 MHz   100.00%
PCPU 3      Core   3204.00 MHz   3180.97 MHz    99.28%
PCPU 4      Core   3204.00 MHz    116.81 MHz     3.65%
```
### Options
Available command line options are:
```
    -l <value> : loop output (0 = infinite)
    -i <value> : set sampling interval (may effect accuracy)
    -c         : print frequency information for all cores         (arm64)
    -e         : print frequency information for efficiency cores  (arm64)
    -p         : print frequency information for performance cores (arm64)
    -q         : print frequency information for all clusters
    -r         : remove average frequency estimation from output   (arm64)
    -a         : print average frequency estimation only
    -v         : print version number
    -h         : help
```

## Bugs and Issues
### Known Problems:
- The latest version has very limited x86 support, but further support will be implemented as soon as possible
- Support for M1 Pro/Max is unofficial

If any other bugs or issues are identified, please let me know!

## Support ❤️
If you would like to support me, you can donate to my [Cash App](https://cash.app/$bitespotatobacks).

<!-- ## Major Version Changelog

```markdown
## [2.1.0] - Feb 7, 2022:
Code Cleanup:
- Fixed a couple of DRY rule violations
- Improved handling of command line options
- Improved handling of maximum and nominal frequencies
Features:
- Added CPU type column to output
- Added maximum frequency column to output
- Added option to loop output an infinite or set amount of times (option `-l`)
- (arm64) Added average CPU frequency information to output (can be removed with `-r`)
- (x86) Added sampling interval support
Bug Fixes:
- Fixed possibility for CPU frequency percentage to print value over 100%
- Fixed possibility for CPU frequency to print as NAN

## [2.0.0] - Feb 1, 2022:
- (arm64) Support to get current CPU frequency _per core_
- (arm64) Support to get current CPU frequency _per cluster_
- Previous version experimental features have been removed due to inaccuracies
``` -->
<!-- 
Removing credits from public readme due to no longer using the methods derived from the following:
https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp
http://uob-hpc.github.io/2017/11/22/arm-clock-freq.html
-->
