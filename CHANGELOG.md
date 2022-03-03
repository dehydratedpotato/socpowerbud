## v2.5.0 (Mar 2, 2022)
#### Features:
- New support for long (double dashed) command line options (for example, `--help` or `--version`)
- (arm64) The script now retrieves performance state nominal frequencies from voltage state data in the IORegistry. This will increase compatibly and portability.

#### Bug Fixes:
- Fixed issue [#1](https://github.com/BitesPotatoBacks/macos-cpufreq/issues/1) and now pulling core counts for clusters from IORegistry.
- Fixed extra whitespace in outputs when looping all data
- Fixed issue where frequency could return `0 MHz` while the precent does not return `Idle`

#### Notes:
- The project has been renamed to move away from the "old MacOS" vibe

## v2.4.0 (Feb 22, 2022)
Version 2.4.0 introduces a new output formatting and fixes major issues regarding the looping option (option `-l`).
#### Features:
- Redesigned output formatting to improve readability and to prevent inconsistent spacing
- Added command line option to select specific CPU Core to print frequency data for (option `-s`)

#### Bug Fixes:
- Fixed possibility for script to ignore incorrect negative loop counts and output no data
- (arm64) Fixed per core outputs not refreshing when using loop option (also fixes potential memory leak)
## v2.3.1 (Feb 18, 2022)
#### Code Cleanup:
- (x86) Fixed a few spelling mistakes and removed some macros

#### Bug Fixes:
- (x86) Fixed possibility where base frequency may return incorrectly
- (x86) Fixed issue where using an infinite loop with default sampling interval could overload command line with too much data
- (x86) Error handling for base and turbo frequency fetching improved

## v2.3.0 (Feb 17, 2022)
Version 2.3.0 brings support for per core frequency outputs on all Mac notebooks and desktops that feature Ivy Bridge CPUs or newer.
#### Features:
- (x86) Per core frequency is now supported (as above mentioned)
- (x86) Added the base frequency column
- (x86) RDTSC removed in favor of turbo frequencies for further accuracy and output efficiency (~99% faster outputs than previous version).
#### Notes:
- Support for Xeon CPUs in Mac Pros and iMac Pros currently limited

## v2.2.0 (Feb 12, 2022)
#### Code Cleanup:
- Majorly Improved output speed (~80% faster outputs than previous version)
- Reformatted source code structuring for better handling of architecture specific code

#### Features:
- Sampling intervals may now have the precision of a decimal rather than an integer
- (arm64) Improved command line options `-e` and `-p` to allow for better handling of cluster type selection.

#### Bug Fixes:
- Fixed possibility for script to ignore incorrect negative sampling intervals

## v2.1.0 (Feb 7, 2022)
#### Code Cleanup:
- Fixed a couple of DRY rule violations
- Improved handling of command line options
- Improved handling of maximum and nominal frequencies

#### Features:
- Added CPU type column to output
- Added maximum frequency column to output
- Added option to loop output an infinite or set amount of times (option `-l`)
- (arm64) Added average CPU frequency information to output (can be removed with `-r`)
- (x86) Added sampling interval support

#### Bug Fixes:
- Fixed possibility for CPU frequency percentage to print value over 100%
- Fixed possibility for CPU frequency to print as NAN

## v2.0.0 (Feb 1, 2022)
Version 2.0.0 introduces the most accurate CPU frequency measurements for Apple Silicon, using calculations and concepts derived from the source assembly of [OS X Powermetrics](https://www.unix.com/man-page/osx/1/powermetrics/). The most notable improvements are:
- (arm64) Support to get current CPU frequency _per core_
- (arm64) Support to get current CPU frequency _per cluster_
#### Notes:
- The latest version has very limited x86 support, but further support will be implemented as soon as possible
- Support for M1 Pro/Max is unofficial
- Previous version experimental features have been removed due to inaccuracies

## v1.4.1 (Jan 11, 2022)
- (arm64) Fixed static frequency estimation issue when trying to set efficiency cores only option 
- (arm64) Fixed static frequency returning incorrect double length
- Added error handling for faulty static frequency estimations
- Modified current frequency returning the static frequency on error to be disabled by default (can be reenabled using `-s`)
- Marked static frequency options as experimental due to accuracy issues

## v1.4.0 (Jan 11, 2022)
- Added option to print static frequency rather than the current frequency
- Fixed current frequency returning `0` on errors by returning the static frequency on error (can be disabled using `-d`)

## v1.3.0 (Jan 4, 2022)
- (x86) Removed rdtsc() in favor of inline asm to improve accuracy

## v1.2.1 (Dec 31, 2021)
- Improved readability regarding efficiency cores

## v1.2.0 (Dec 30, 2021)
- Translated to Objective-C
- (arm64) Added frequency fetching for efficiency cores

## v1.1.0 (Dec 26, 2021)
- Intel (x86) support
- Rename to reflect universal support

## v1.0.0 (Nov 21, 2021)
- Initial Release
