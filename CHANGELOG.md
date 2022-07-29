## v0.1.2 (July 29, 2022)
### Release Notes
This patch contains improvements to portability, metrics management, and includes a fix for a juicy memory leak issue.

### Changelog
**Fixes**
- Fixed a memory leak that resulted in the tool consuming ~1.5 MB of memory every sample

**Improvements**
- Now pulling Silicon IDs/Code names from the IORegistry
- Now pulling CPU micro architectures from the IORegistry
- Improved managing metrics for visible units by adding command line arg `-a`

___

## v0.1.1 (July 20, 2022)
### Release Notes
This patch brings support for Apple M1 Pro/Max/Ultra Silicon with increased portability and chance of supporting new silicon as well.

### Changelog
**Features and Fixes**
- **ADDED** Apple M1 Pro/max/Ultra support (closes issue #2)
- **FIXED** Unit hiding not working for ECPU due to unfixed loop code

**Improvements**
- Code reduction and increased portability

___

## v0.1.0 (July 1, 2022)
### Release Notes
Initial Release for new and final renamed iteration of the project. More features to come in upcoming versions (see README for deets)
