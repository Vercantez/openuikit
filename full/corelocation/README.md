# CoreLocation

This directory provides the portable CoreLocation framework boundary used by
unchanged iOS application sources. It builds one ARM64 Mach-O framework binary
with two views of the same runtime identity:

- `CoreLocation.swift` is the Swift module and implements coordinates,
  WGS-84 distance, regions, authorization, deterministic host-injected
  location/heading delivery, and fail-closed or host-injected geocoding.
- `CoreLocationObjC.m` exports the canonical C coordinate/constants ABI and
  bridges C structure properties to the Swift-defined Objective-C classes.
- `include/CoreLocation.h` and `module.modulemap` are the Clang framework
  surface for unchanged Objective-C consumers.

Without a host location provider, authorization requests fail closed and no
location is invented. The `OpenUIKitHost` SPI lets a Linux host explicitly set
authorization and inject locations, headings, errors, and geocoder results.
Delivery is synchronous and deterministic so headless applications and tests
do not depend on a nonexistent location daemon or main-run-loop timing.

`tests/test_corelocation_host.sh` proves the Apple Xcode 26.1 value/geometry
transcript, the ARM64 dylib identity, 37 C/Objective-C boundary exports, mixed
Clang-header and Swift-module runtime use, and exact untouched consumers from
the pinned Home Assistant and Wikipedia repositories. Firefox has no
CoreLocation import at its pinned corpus revision and is guarded as an explicit
absence rather than represented by a fabricated consumer.
