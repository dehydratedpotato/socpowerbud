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
Package Frequencies
------------------------
CPU..........(Package) : 1416 MHz (3204 MHz: 44.20%)
ECPU.........(Cluster) : 756 MHz (2064 MHz: 36.62%)
PCPU.........(Cluster) : 2077 MHz (3204 MHz: 64.81%)

E-Core Frequencies
------------------------
ECORE0..........(Core) : 795 MHz (2064 MHz: 38.52%)
ECORE1..........(Core) : 645 MHz (2064 MHz: 31.27%)
ECORE2..........(Core) : 597 MHz (2064 MHz: 28.92%)
ECORE3..........(Core) : 594 MHz (2064 MHz: 28.76%)

P-Core Frequencies
------------------------
PCORE0..........(Core) : 2078 MHz (3204 MHz: 64.86%)
PCORE1..........(Core) : 988 MHz (3204 MHz: 30.83%)
PCORE2..........(Core) : 1829 MHz (3204 MHz: 57.09%)
PCORE3..........(Core) : 929 MHz (3204 MHz: 28.98%)
```
Here is an example running `./osx-cpufreq` on an 13" MacBook Pro with an dual-core i7-4578U:
```
Package Frequencies
------------------------
CPU..........(Package) : 2209 MHz (3000 MHz: 73.64%)

Core Frequencies
------------------------
CORE0...........(Core) : 1782 MHz (3000 MHz: 59.39%)
CORE1...........(Core) : 1576 MHz (3000 MHz: 52.54%)
```
### Options
Available command line options are:
```
./osx-cpufreq [options]
    -l <value> : loop output (0 = infinite)
    -i <value> : set sampling interval (may effect accuracy)
    -s <value> : print frequency information for selected CPU core
    -c         : print frequency information for CPU cores
    -q         : print frequency information for CPU clusters
    -a         : print frequency information for CPU package
    -e         : print frequency information for ECPU types   (arm64)
    -p         : print frequency information for PCPU types   (arm64)
    -v         : print version number
    -h         : help
```

## Bugs and Issues
### Known Problems:
- Support for M1 Pro/Max is unofficial
- Support for Xeon CPUs in Mac Pros and iMac Pros currently limited
<!-- - Looping the output using -l does not refresh per core frequencies on arm64 --><!--Fixed with version 2.4.0--> 

If any other bugs or issues are identified, please let me know!

## Support ❤️
If you would like to support me, you can donate to my [Cash App](https://cash.app/$bitespotatobacks).
