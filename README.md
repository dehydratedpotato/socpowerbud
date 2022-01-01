<h1 align="center" style="">osx-cpufreq</h1>

<p align="center">
    Get your CPUs current frequency (all cores or efficiency cores) on macOS.
</p>
<p align="center">
            <a href="">
                <img alt="Architectures" src="https://img.shields.io/badge/architectures-Apple_Silicon,_Intel-orange.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/releases">
        <img alt="Releases" src="https://img.shields.io/github/release/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
    <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/blob/main/LICENSE">
        <img alt="License" src="https://img.shields.io/github/license/BitesPotatoBacks/osx-cpufreq.svg"/>
    </a>
        <a href="https://cash.app/$bitespotatobacks">
        <img alt="License" src="https://img.shields.io/badge/donate-Cash_App-default.svg"/>
    </a>
    <!-- <a href="https://github.com/BitesPotatoBacks/osx-cpufreq/stargazers"><img alt="Stars" src="https://img.shields.io/github/stars/BitesPotatoBacks/osx-cpufreq.svg"/></a>-->
    <br>
</p>

## Preparation 
Download the precompiled binary from the [releases](https://github.com/BitesPotatoBacks/osx-cpufreq/releases), `cd` into your Downloads folder, and run these commands to fix the binary permissions:
```
chmod 755 ./osx-cpufreq | xattr -cr ./osx-cpufreq
```
## Usage
```
./osx-cpufreq
```

The default output is formatted in hertz (Hz). Available command line options are:
```
    -k         : print output in kilohertz (kHz)
    -m         : print output in megahertz (mHz)
    -g         : print output in gigahertz (gHz)
    -e         : get frequency of efficiency cores (arm64 only)
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

## Changelog

```markdown
## [1.2.1] - Dec 31, 2021
- Improved readability regarding efficiency cores

## [1.2.0] - Dec 30, 2021
- Translated to Objective-C
- Added E-Cluster frequency fetching on arm64

## [1.1.0] - Dec 26, 2021
- Intel (x86) support
- Rename to reflect universal support

## [1.0.0] - Nov 21, 2021
- Initial Release
```
## Support ❤️
If you would like to support me, you can donate to my [Cash App](https://cash.app/$bitespotatobacks)
<a href="https://cash.app/$bitespotatobacks"><img src="https://upload.wikimedia.org/wikipedia/commons/thumb/c/c5/Square_Cash_app_logo.svg/1200px-Square_Cash_app_logo.svg.png" alt="Cash App" width="17" height="17"></a>
## Bugs and Issues
If you can't diagnose the problem yourself, feel free to open an Issue. I'll try to figure out what's going on as soon as possible.

## Credits
[https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp](https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp)
