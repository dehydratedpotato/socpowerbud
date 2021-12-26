# osx-cpufreq
Get the current average CPU frequency on MacOS. Supports Intel (x86) and Apple Silicon (arm64).
## Usage
Download the precompiled binary from the [releases](https://github.com/BitesPotatoBacks/osx-cpufreq/releases) and run it in the terminal like so: `./osx-cpufreq`

The default output is formatted in hertz. Available command line options are:
```
    -k         : output in kilohertz (kHz)
    -m         : output in megahertz (mHz)
    -g         : output in gigahertz (gHz)
    -h         : help
```
If you would like to add the binary to your `usr/local/bin/`, you may run the following: `sudo cp ./osx-cpufreq /usr/local/bin`

## Example

Here is an example using the `-m` option contained in a shell loop: `while true; do ./osx-cpufreq -m; sleep 2; done`

Here is the output of the example:
```zsh
829 mHz
2064 mHz
2064 mHz
1702 mHz
1333 mHz
0 mHz
1702 mHz
1695 mHz
```
## Future Features
The ability to get the current CPU frequency of a specific core, rather than pulling a total from all cores.

This is partially supported by running `osx-cpufreq` through [this script](https://github.com/BitesPotatoBacks/CPU-Lock).

## Bugs and Issues
If you can't diagnose the problem yourself, feel free to open an Issue. I'll try to figure out what's going on as soon as possible.

## Credits
[https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp](https://github.com/lemire/iosbitmapdecoding/blob/master/bitmapdecoding/bitmapdecoding.cpp)

[https://github.com/somdipdey/osx-temp-freq/blob/master/smc.c](https://github.com/somdipdey/osx-temp-freq/blob/master/smc.c)
