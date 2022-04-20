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

This project is designed to retrieve active frequency and residency metrics from your Macs CPU (per-core, per-cluster) and GPU (complex) as accurately and efficiently as possible; accessing the same data as the Powermetrics command line tool, but without requiring `sudo` or a kernel extension. This is the product of months of reverse engineering, deep analysis, and rigorous testing.

If you would like to support my efforts towards this project, please consider donating to my **[Cash App](https://cash.app/$bitespotatobacks).**

## Installation and Usage

Installation and usage is simple:


1. Download your architecture specific binary .zip from the [latest release](https://github.com/BitesPotatoBacks/SFMRM/releases).
2. Unzip the downloaded file (from Finder or Terminal)
3. Move the binary to your desired location and execute via the Terminal using `sfmrm-${ARCH}-client`.

To see all available cmd options for your binary, use `sfmrm-${ARCH}-client --help`.
   
## Capabilities
   
   The following metrics are available on specific architectures.
   
<details>
<summary><strong>On Apple Silicon</strong></summary>
      

      
- CPU Name, Code Name, and Core Counts
- CPU Cluster Microarchitecture Names
- CPU Per-core and Per-cluster Active Frequencies and Active/Idle Residencies
- CPU (Clusters) and GPU P-State frequency distribution
- GPU Complex Active Frequencies and Active/Idle Residencies
      
</details>
   
<details>
<summary><strong>On Intel</strong></summary>
   

      
- CPU Brand Name and Base Frequency
- CPU Performance Limits, Maximum (P-Limited) Turbo Boost, and Package Clock Multiplier
- CPU Per-core and Package Active Frequencies and Active/Idle Residencies
- GPU Performance Limits, Maximum (P-Limited) Dynamic Frequnecy, and Residencies
      
</details>

  ## Example Outputs
   
   The following shows examples on what outputs to expect on specific architectures. 
  
  <details>
<summary><strong>On Apple Silicon</strong></summary>
     
Here is an example using binary `sfmrm-arm64-client` on an M1 Mac Mini:
     
```
*** Sampling: Apple M1 [T8103] (4P+4E+8GPU) ***

**** "Icestorm" Efficiency Cluster Metrics ****

E-Cluster [0]  HW Active Frequency: 1071 MHz
E-Cluster [0]  HW Active Residency: 11.994%
E-Cluster [0]  Idle Frequency:      88.006%

  Core 0:
          Active Frequency: 1129 MHz
          Active Residency: 6.799%
          Idle Residency:   93.201%
  Core 1:
          Active Frequency: 1004 MHz
          Active Residency: 4.364%
          Idle Residency:   95.636%
  Core 2:
          Active Frequency: 990 MHz
          Active Residency: 3.951%
          Idle Residency:   96.049%
  Core 3:
          Active Frequency: 1032 MHz
          Active Residency: 2.023%
          Idle Residency:   97.977%

**** "Firestorm" Performance Cluster Metrics ****

P-Cluster [0]  HW Active Frequency: 1473 MHz
P-Cluster [0]  HW Active Residency: 4.383%
P-Cluster [0]  Idle Frequency:      95.617%

  Core 4:
          Active Frequency: 1487 MHz
          Active Residency: 3.730%
          Idle Residency:   96.270%
  Core 5:
          Active Frequency: 1396 MHz
          Active Residency: 0.739%
          Idle Residency:   99.261%
  Core 6:
          Active Frequency: 600 MHz
          Active Residency: 0.005%
          Idle Residency:   99.995%
  Core 7:
          Active Frequency: 600 MHz
          Active Residency: 0.005%
          Idle Residency:   99.995%

**** Integrated Graphics Metrics ****

GPU  Active Frequency: 712 MHz
GPU  Active Residency: 1.581%
GPU  Idle Frequency:   98.419%
```
  </details>
  
  <details>
<summary><strong>On Intel</strong></summary>
     
Here is an example using binary `sfmrm-x86_64-client` on an Intel® Core™ i7-4578U 13" MacBook Pro:
     
```
*** Sampling: Intel(R) Core(TM) i7-4578U CPU @ 3.00GHz ***

**** Package Metrics ****

Package  Performance Limiters: MAX_TURBO_LIMIT
Package  Maximum Turbo Boost:  3500 MHz

Package  Clock Multiplier: x21.8
Package  Active Frequency: 2184 MHz
Package  Active Residency: 55.83% 
Package  Idle Residency:   44.17% 

  Core 0:
          Active Frequency: 2207 MHz
          Active Residency: 66.34% 
          Idle Residency:   33.66% 
  Core 1:
          Active Frequency: 2132 MHz
          Active Residency: 47.00% 
          Idle Residency:   53.00% 
  Core 2:
          Active Frequency: 2992 MHz
          Active Residency: 65.00% 
          Idle Residency:   35.00% 
  Core 3:
          Active Frequency: 2412 MHz
          Active Residency: 45.00% 
          Idle Residency:   55.00% 

**** Integrated Graphics Metrics ****

iGPU  Performance Limiters:      VR_ICCMAX
iGPU  Limited Dynamic Frequency: 1200 MHz

iGPU  Active Residency: 4.00%
iGPU  Idle Frequency:   96.00%
```
     
  </details>
   
   <!--
## Reading
   
<details>
<summary><strong>Benefits of SFMRM over Powermetrics for Frequency Metric Retrieval</strong></summary>
   
### On Apple Silicon
SFMRM can access the same frequency and residency metrics as Powermetrics does, without needing `sudo` or a kernel extension. SFMRM also offers performance cluster, efficency cluster, and GPU compelx core counts, as well as CPU codenames. No need for `sudo` or a kernel extension.
      
### On Intel
SFMRM does not access the same information for frequency metrics as does Powermetrcis, but it uses highly accurate assembely to retrieve the same data. SFMRM does access the same information that Powermetrics uses for reporting CPU performance limiters, though. SFMRM also offers some metrics that Powermetrics doesn't; such as iGPU performance limiters, CPU maximum Turbo Boost speed, and active residencies. No need for `sudo` or a kernel extension.

      
      
   </details>
-->
## Bugs and Issues
<details>
<summary><strong>Identified</strong></summary>
   
- Outputs on M1 Pro/Max/Ultra may not work as expected (IOReport entries are unknown so support is unofficial)
   
   </details>
   
If any other bugs or issues are identified or you want your system supported, please let me know in the [issues](https://github.com/BitesPotatoBacks/SFMRM/issues) section.

