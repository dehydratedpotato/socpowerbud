<h1 align="center" style="">osx-cpufreq</h1>

<p align="center">
    Get your CPUs current frequency, per core and per cluster.
</p>
<p align="center">
    <a href="">
       <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple_Silicon-M1_(M1_Pro/Max_Unofficial)-red.svg"/>
    </a>
    <a href="">
       <img alt="Intel" src="https://img.shields.io/badge/Intel-Ivy_Bridge_And_Newer-blue.svg"/>
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
This project is designed to get the current CPU frequency of your system as accurately as possible, without requiring `sudo` or a kernel extension. Each architecture supported by this project offers different amounts of data and uses its own technique:
### On Apple Silicon
For Apple Silicon, this project is able to pull the current frequency of your CPU cores, clusters, and package. This feat is achieved by accessing the CPU performance state values (which are hidden away in `IOReport`), and performing some calculations based on them during a specified time interval (default 1 second). This method is not only extremely accurate, but it is also the same concept used by the closed source OS X command line utility [Powermetrics](https://www.unix.com/man-page/osx/1/powermetrics/).
### On Intel
For Intel, this project is able to pull the current frequency of your CPU cores and package. This is achieved by measuring performance using some tricky assembely language magic, in a way so efficenct it can ouput data in as little as ~0.011 seconds. Supports all Mac notebooks and desktops that feature Ivy Bridge CPUs or newer.
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

CPU      Package   3204.00 MHz   1741.50 MHz    54.35%
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
Here is an example running `./osx-cpufreq` on an 13" MacBook Pro with an dual-core i7-4578U:
```
Name     Type      Max Freq      Base Freq    Active Freq    Freq %

CPU     Package   3500.00 MHz   3000.00 MHz   3091.17 MHz   103.04%
CPU 0      Core   3500.00 MHz   3000.00 MHz   2344.13 MHz    78.14%
CPU 1      Core   3500.00 MHz   3000.00 MHz   3286.00 MHz   109.53%
```
### Options
Available command line options are:
```
./osx-cpufreq [options]
    -l <value> : loop output (0 = infinite)
    -i <value> : set sampling interval (may effect accuracy)
    -c         : print frequency information for CPU cores
    -q         : print frequency information for CPU clusters
    -a         : print frequency information for CPU package
    -e         : print frequency information for ECPU types    (arm64)
    -p         : print frequency information for PCPU types    (arm64)
    -v         : print version number
    -h         : help
```

## Bugs and Issues
### Known Problems:
- Support for M1 Pro/Max is unofficial
- Support for Xeon CPUs in Mac Pros and iMac Pros currently limited

If any other bugs or issues are identified, please let me know!

## Support ❤️
If you would like to support me, you can donate to my [Cash App](https://cash.app/$bitespotatobacks).
