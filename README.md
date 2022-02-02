<h1 align="center" style="">osx-cpufreq</h1>

<p align="center">
    Get your CPUs current frequency, per core and per cluster
</p>
<p align="center">
    <a href="">
       <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple_Silicon-Full_Support-red.svg"/>
    </a>
    <a href="">
       <img alt="Intel" src="https://img.shields.io/badge/Intel-Limited_Support-blue.svg"/>
    </a>
        <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/stargazers">
        <img alt="License" src="https://img.shields.io/github/stars/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
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
CPU         Frequency     Percent

ECPU:      2060.14 MHz     99.81%
PCPU:      1670.64 MHz     52.14%

ECPU 1:    1356.76 MHz     65.73%
ECPU 2:     892.25 MHz     43.23%
ECPU 3:    2064.00 MHz    101.65%
ECPU 4:    2025.28 MHz     98.12%

PCPU 1:    3171.96 MHz     99.00%
PCPU 2:    3106.88 MHz     96.97%
PCPU 3:    1026.78 MHz     32.05%
PCPU 4:       0.51 MHz      0.02%
```
### Options
Available command line options are:
```
    -i <int>   : set sampling interval (may effect accuracy)   (arm64)
    -c         : print active frequency for all cores          (arm64)
    -e         : print active frequency for efficiency cores   (arm64)
    -p         : print active frequency for performance cores  (arm64)
    -l         : print active frequency for all clusters
    -m         : print maximum frequency for all clusters
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

## Changelog

```markdown
## [2.0.0] - Feb 1, 2022:
- (arm64) Support to get current CPU frequency _per core_
- (arm64) Support to get current CPU frequency _per cluster_
- Previous version experimental features have been removed due to inaccuracies

## [1.4.1] - Jan 11, 2022
- (arm64) Fixed static frequency estimation issue when trying to set efficiency cores only option 
- (arm64) Fixed static frequency returning incorrect double length
- Added error handling for faulty static frequency estimations
- Modified current frequency returning the static frequency on error to be disabled by default (can be reenabled using `-s`)
- Marked static frequency options as experimental due to accuracy issues

## [1.4.0] - Jan 11, 2022
- Added option to print static frequency rather than the current frequency
- Fixed current frequency returning `0` on errors by returning the static frequency on error (can be disabled using `-d`)

## [1.3.0] - Jan 4, 2022
- Removed rdtsc() in favor of inline asm to improve accuracy on x86

## [1.2.1] - Dec 31, 2021
- Improved readability regarding efficiency cores

## [1.2.0] - Dec 30, 2021
- Translated to Objective-C
- Added frequency fetching for efficiency cores on arm64

## [1.1.0] - Dec 26, 2021
- Intel (x86) support
- Rename to reflect universal support

## [1.0.0] - Nov 21, 2021
- Initial Release
```
<!-- 
Removing credits from public readme due to no longer using the methods derived from the following:
https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp
http://uob-hpc.github.io/2017/11/22/arm-clock-freq.html
-->
