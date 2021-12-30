<h1 align="center" style="">osx-cpufreq</h1>

<p align="center">
    Get the current average CPU frequency on macOS (all cores or efficiency cores).
</p>
<p align="center">
            <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/releases">
                <img alt="Supported Architectures" src="https://img.shields.io/badge/architectures-Apple_Silicon,_Intel-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
    <!-- <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/osx-cpufreq.svg"/></a>-->
    <br>
</p>

## Preparation 
Download the precompiled binary from the [releases](https://github.com/BitesPotatoBacks/osx-cpufreq/releases) and run these commands to fix the binary permissions:
```
chmod 755 ./osx-cpufreq | xattr -cr ./osx-cpufreq
```
## Usage
```
./osx-cpufreq
```

The default output is formatted in hertz (Hz). Available command line options are:
```
    -k         : output in kilohertz (kHz)
    -m         : output in megahertz (mHz)
    -g         : output in gigahertz (gHz)
    -e         : get E-Cluster frequency (arm64 only)
    -v         : print version number
    -h         : help
```
<!-- If you would like to add the binary to your `usr/local/bin/`, you may also run the following:
```
sudo cp ./osx-cpufreq /usr/local/bin
``` -->

## Example

Here is an example running `./osx-cpufreq -m` in a for loop.

Output on an M1 Mac Mini:
```
829 mHz
2064 mHz
2064 mHz
1702 mHz
1333 mHz
```
Output on an Intel Macbook Pro:
```
3001 mHz
3015 mHz
3001 mHz
3008 mHz
3003 mHz
```

## Bugs and Issues
If you can't diagnose the problem yourself, feel free to open an Issue. I'll try to figure out what's going on as soon as possible.

## Credits
[https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp](https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp)
