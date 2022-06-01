## v1.3.3 (2022-06-01)

### Feat

- **Packager.cmake**: add version prefix (vpp version) to hicn packages

## v1.3.2 (2022-05-30)

### Fix

- **PAckager.cmake**: wrong regex for version
- add quptes for version string comparison
- remove eventual dots in version component
- correct version handling when minor is not present in tag
- **Packager.cmake**: remove VERSION_PREFIX

### Feat

- add module to import unity test framework
- add compilation commands to cmake output files by default

## v1.3.1 (2022-03-31)

### Fix

- **Packager.cmake**: fix version regex parsing

## v1.3.0 (2022-03-25)

### Feat

- add property 'OBJECT_LIBRARIES' to build_module macro
- **cmake-modules**: update functions
- add macros to retrieve CPU information

### Fix

- set PRIVATE for compile options for test coverage
- **gtest**: new gtest repo
- do not retrieve VPP version by using package manager

## v1.1.2 (2021-12-09)

## v1.1.1 (2021-11-16)

### Feat

- **FindHicn.cmake**: add version check on hproxy dependencies

## v1.1.0 (2021-11-15)

### Feat

- improve macros to create and install cmake config files #promote MINOR
- **kafka**: update kafka wrapper lib version
- add macros to create cmake config installation files

## v1.0.6 (2021-11-10)

### Feat

- **Packager.cmake**: extract package version from the tag
- **Packager.cmake**: extract package version from the tag

## v1.0.5 (2021-11-09)

### Fix

- **Packager.cmake**: correct check branch

## v1.0.4 (2021-11-09)

### Fix

- **PAckager.cmake**: wrong string compare between current version and next version

## v1.0.3 (2021-11-08)

### Feat

- **Packager.cmake**: add build number to deb package name

## v1.0.2 (2021-11-05)

### Feat

- **Packager.cmake**: extract next version from git log

## v1.0.1 (2021-11-04)

### Fix

- **Packager.cmake**: correct generation packages

### Feat

- **find<library>.cmake**: search exact version of packages in find<module>.cmake
- **FindModernCppKafka.cmake**: add FindModernCppKafka.cmake module

## v1.0.0 (2021-10-14)

### Refactor

- clean up cmake modules

### BREAKING CHANGE

- Ref: SPT-690
#promote MAJOR

## v0.0.1 (2021-10-13)
