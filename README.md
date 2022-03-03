<h1 align="center" style="">macos-cpufreq</h1>

<p align="center">
   Get the active frequency of your CPU, per core and per cluster, without needing sudo.
</p>
<p align="center">
    <a href="">
       <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple_Silicon-M1_(M1_Pro/Max_Unofficial)-red.svg"/>
    </a>
    <a href="">
       <img alt="Intel" src="https://img.shields.io/badge/Intel-Ivy_Bridge_And_Newer-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/macos-cpufreq/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/macos-cpufreq.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/macos-cpufreq/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/macos-cpufreq.svg"/>
    </a>
    <a href="https://cash.app/$bitespotatobacks">
        <img alt="License" src="https://img.shields.io/badge/donate-Cash_App-default.svg"/>
    </a>
    <br>
</p>

## What It Does and How It Works
This project is designed to get the active frequency of your Macs CPU cores and package, as fast and accurate as possible, without requiring `sudo` or a kernel extension. Each architecture supported by this project uses its own special technique to fetch this data.
### On Apple Silicon
CPU core and package frequencies are fetched by accessing the CPUs performance state counter values (which are hidden away in `IOReport`), accessing the voltage state frequencies (which are hidden away in the `IORegistry`), and performing some calculations based on both of them during a specified time interval (default 0.8 seconds). This method is not only extremely accurate, but it is also the same trick used by the closed source OS X command line utility [Powermetrics](https://www.unix.com/man-page/osx/1/powermetrics/).
### On Intel
CPU core and package frequencies are calculated by measuring CPU performance using some tricky assembely language magic, in a way so efficenct that allows data to be outputted in as little as ~0.011 seconds. Supports all Mac notebooks and desktops that feature Ivy Bridge CPUs or newer.
## Usage
### Preparation
Download the precompiled binary from the [releases](https://github.com/BitesPotatoBacks/macos-cpufreq/releases), `cd` into your Downloads folder, and run the following commands to fix the binary permissions:
```
chmod 755 ./macos-cpufreq
xattr -cr ./macos-cpufreq
```
Now you can simply run `./macos-cpufreq`.

### Examples
Here is an example running `./macos-cpufreq` on an M1 Mac Mini during a Geekbench run:
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
The following command-line options are supported:
```
  -h | --help            show this message
  -v | --version         print version number

  -l | --loop-rate <N>   loop output (0=infinite) [default: disabled]
  -i | --sample-rate <N> set sampling rate (may effect accuracy) [default: 0.8s]
  -s | --select-core <N> selected specific CPU core [default: disabled]

  -c | --cores           print frequency information for CPU cores
  -C | --clusters        print frequency information for CPU clusters
  -P | --package         print frequency information for CPU package
  -e | --e-cluster       print frequency information for ECPU types (ARM64)
  -p | --p-cluster       print frequency information for PCPU types (ARM64)
```

## Bugs and Issues
### Known Problems
- Support for M1 Pro/Max currently unofficial
- Support for Intel Xeon CPUs currently limited
<!-- - Looping the output using -l does not refresh per core frequencies on arm64 --><!--Fixed with version 2.4.0--> 

If any other bugs or issues are identified, please let me know in the [issues](https://github.com/BitesPotatoBacks/macos-cpufreq/issues) section.

## Support ❤️
If you would like to support me, you can donate to my **[Cash App](https://cash.app/$bitespotatobacks).**
