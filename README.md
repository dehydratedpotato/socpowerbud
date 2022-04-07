<h1 align="center" style="">SFMRM  ('sifˌmərˌim)</h1>

<p align="center">
   <b>S</b>udoless <b>F</b>requency <b>M</b>etric <b>R</b>etrieval for <b>M</b>acOS
</p>
<p align="center">
    <a href="">
       <img alt="Apple Silicon" src="https://img.shields.io/badge/Apple_Silicon-M1_Support-red.svg"/>
    </a>
    <a href="">
       <img alt="Intel" src="https://img.shields.io/badge/Intel-Full_Support-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/SFMRM/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/SFMRM.svg"/>
    </a>
    <a href="https://cash.app/$bitespotatobacks">
        <img alt="License" src="https://img.shields.io/badge/donate-Cash_App-default.svg"/>
    </a>
    <br>
</p>

This project is designed to retrieve active frequency and residency metrics from your Macs CPU (per-core, per-cluster) and GPU (complex) as accurately as possible, without requiring sudo or a kernel extension.



If you would like to support my efforts towards this project, consider donating to my **[Cash App](https://cash.app/$bitespotatobacks).**

## Project Details

<details>
<summary><strong>Installation</strong></summary>
   
### 1. Download
Download the file named `SFMRM.sh` from the [latest release](https://github.com/BitesPotatoBacks/SFMRM/releases) (or [click here](https://github.com/BitesPotatoBacks/SFMRM/releases/download/v0.1.0/SFMRM.sh) for a direct download). This is the script that manages the versions for your systems architecture specific binaries (which are the files that actually retrieve your metrics). You may download the `.zip` files for these binaries if you wish, but I recommend using `SFMRM.sh` if you want the latest features and bug fixes without having to lift a finger.
   
### 2. Preparation
`cd` into your Downloads folder via the Terminal, and fix the file permissions of your binary using these terminal commands:
```
chmod 755 ./SFMRM
xattr -cr ./SFMRM
```
### 3. Running
To view your systems metrics, you now may run `./SFMRM.sh` alongside any command line option available to your architecture (documented in next section).
</details>
  
<details>
<summary><strong>Command Line Options</strong></summary>
   
   Here are the available command line options. Please note some options are architecture specific.
   
```
  -h | --help             show this message
  -v | --version          print version number

  -l | --loop-rate <N>    set output loop rate (0=infinite) [default: disabled]
  -i | --sample-rate <N>  set data sampling interval [default: 1000ms]
   
  -c | --hide-cores       hide per-core frequency and residency metrics
  -g | --gpu-only         only show GPU complex frequency and residency metrics
   
  -p | --pkg-only         only show CPU Package frequency and residency metrics (x86_64)

  -e | --ecpu-only        only show E-Cluster frequency and residency metrics   (arm64)
  -p | --pcpu-only        only show P-Cluster frequency and residency metrics   (arm64)
  -s | --state-freqs      show state frequency distributions for all groups     (arm64)

```
   
</details>
   

  
  ## Example Outputs
  
  <details>
<summary><strong>Apple Silicon (Apple M1) </strong></summary>
     
Here is an example of `SFMRM.sh`'s output (using binary `sfmrm-arm64-client`) on an M1 Mac Mini:
     
```
*** Sampling: Apple M1 [T8103] (4P+4E+8GPU) ***

**** "Icestorm" Efficiency Cluster Metrics ****

E-Cluster [0]  HW Active Frequency: 974 MHz
E-Cluster [0]  HW Active Residency: 99.851%
E-Cluster [0]  Idle Frequency:      0.149%

  Core 0:
          Active Frequency: 973 MHz
          Active Residency: 86.764%
          Idle Residency:   13.236%
  Core 1:
          Active Frequency: 974 MHz
          Active Residency: 85.823%
          Idle Residency:   14.177%
  Core 2:
          Active Frequency: 973 MHz
          Active Residency: 85.298%
          Idle Residency:   14.702%
  Core 3:
          Active Frequency: 973 MHz
          Active Residency: 83.335%
          Idle Residency:   16.665%

**** "Firestorm" Performance Cluster Metrics ****

P-Cluster [0]  HW Active Frequency: 2993 MHz
P-Cluster [0]  HW Active Residency: 0.120%
P-Cluster [0]  Idle Frequency:      99.880%

  Core 4:
          Active Frequency: 3084 MHz
          Active Residency: 0.114%
          Idle Residency:   99.886%
  Core 5:
          Active Frequency: 0 MHz
          Active Residency: 0.000%
          Idle Residency:   100.000%
  Core 6:
          Active Frequency: 600 MHz
          Active Residency: 0.004%
          Idle Residency:   99.996%
  Core 7:
          Active Frequency: 0 MHz
          Active Residency: 0.000%
          Idle Residency:   100.000%

**** Integrated Graphics Metrics ****

GPU  Active Frequency: 706 MHz
GPU  Active Residency: 0.220%
GPU  Idle Frequency:   99.780%
```
  </details>
  
  <details>
<summary><strong>Intel (Intel® Core™ i7-4578U)</strong></summary>
     
Here is an example of `SFMRM.sh`'s output (using binary `sfmrm-x86_64-client`) on an 13" MacBook Pro with an Intel® Core™ i7-4578U:
     
```
*** Sampling: Intel(R) Core(TM) i7-4578U CPU @ 3.00GHz ***

**** Package Metrics ****

Package  Performance Limiters: MAX_TURBO_LIMIT
Package  Maximum Turbo Boost:  3500 MHz

Package  Active Frequency: 1253 MHz
Package  Active Residency: 4.00% 
Package  Idle Residency:   96.00% 

  Core 0:
          Active Frequency: 1337 MHz
          Active Residency: 10.00% 
          Idle Residency:   90.00% 
  Core 1:
          Active Frequency: 1525 MHz
          Active Residency: 1.98% 
          Idle Residency:   98.02% 
  Core 2:
          Active Frequency: 3500 MHz
          Active Residency: 4.00% 
          Idle Residency:   96.00% 
  Core 3:
          Active Frequency: 0 MHz
          Active Residency: 0.00% 
          Idle Residency:   100.00% 

**** Integrated Graphics Metrics ****

iGPU  Performance Limiters: VR_ICCMAX

iGPU  Active Residency: 2.00%
iGPU  Idle Frequency:   98.00%
```
     
  </details>
   
   
## Reading
   
<details>
<summary><strong>Benefits of SFMRM over Powermetrics for Frequency Metric Retrieval</strong></summary>
   
### On Apple Silicon
SFMRM can access the same frequency and residency metrics as Powermetrics does, without needing `sudo` or a kernel extension. SFMRM also offers performance cluster, efficency cluster, and GPU compelx core counts, as well as CPU codenames. No need for `sudo` or a kernel extension.
      
### On Intel
SFMRM does not access the same information for frequency metrics as does Powermetrcis, but it uses highly accurate assembely to retrieve the same data. SFMRM does access the same information that Powermetrics uses for reporting CPU performance limiters, though. SFMRM also offers some metrics that Powermetrics doesn't; such as iGPU performance limiters, CPU maximum Turbo Boost speed, and active residencies. No need for `sudo` or a kernel extension.

      
      
   </details>

## Bugs and Issues
<details>
<summary><strong>Identified</strong></summary>
   
- Support for M1 Pro/Max/Ultra currently unofficial
   
   </details>
   
If any other bugs or issues are identified or you want your system supported, please let me know in the [issues](https://github.com/BitesPotatoBacks/SFMRM/issues) section.

