# Coordinate-space oracle — iOS 26.1

Captured 2026-09-07 on a private iPhone SE (3rd generation), 375×667 pt at
2x, iOS 26.1. Reproduce from `uikit/`:

```sh
SIM_DEVICE_SUFFIX=-uikit-blocking-types-coordinate scripts/coordinate_space_probe_sim.sh /tmp/coordinate-oracle
```

The unmodified `Documents/coordinate-space.txt` is carried as `ios-26.1.txt`.
The probe converts through `UICoordinateSpace` existential values using a
nested view hierarchy, nonzero child bounds origin, and a 90° transform.
It also supplies a custom NSObject protocol conformer whose methods log
calls and return distinct sentinels. Real UIView never calls those custom
methods: conversion to/from that space uses the hierarchy root. From child
point (8,9), the output is (55,85) to the custom space and (-39,-67) from it.

The implementation adds the NSObject-based protocol and UIView conformance
in a separate extension file; it reuses the already implemented view
conversion geometry. It does not add UIScreen/scene coordinate-space
objects or new multi-display/orientation behavior.
