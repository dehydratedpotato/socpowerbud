# Changelog

### x86_64 v0.2.0 (April 16, 2022)
This release is a light feature update for the SFMRM x86_64-client.

**New features for SFMRM x86_64-client are the following:**

- GPU Limited Dynamic Frequency Metric
- CPU Package Clock Multiplier Metric

___

### arm64 v0.1.1 (April 16, 2022)
This release is small bug fix for the SFMRM arm64-client. The previous release for SFMRM x86_64-client is available as well.

**Bug fixes for SFMRM  arm64-client are the following:**

- Fixed long command lien option for `--state-freqs` being broken


___

### v0.1.0 (April 6, 2022)
This is the first release of SFMRM, the latest and greatest iteration of both the `macos-cpufreq` and `M1-gpufreq` project. It brings new features, extreme efficiency and accuracy improvements, as well as a much better looking command line output.

**Bug Fixes:**
- The extreme for-loop inaccuracy has now been fixed, which brings Powermetrics level accuracy to the frequency metrics.
- Extra white space when using output looping

**Code Cleanup:**
- The code of the project has been completely rewritten with extreme efficiency and detailed comments.
- Command line options have been simplified

**Features:**
- (x86_64) CPU Performance Limiters and Limited Turbo Boost Metrics
- (x86_64) GPU Performance Limiters
- (arm64) GPU Active Frequency Metrics
- (all architectures) CPU Model Details (Name, Core Counts, etc.)
- (all architectures) New Active and Idle Residency Metrics for both the CPU (per-core, per-cluster) and GPU (complex)
