# MetalFX for Linux

This directory is a clean-room starting implementation of Apple's public
`MetalFX` module for OpenUIKit on Linux. Isolated host compilation produces
`libMetalFX.dylib` from toolchain Foundation plus module-local Metal/simd
lookalikes in `MetalFXLinuxSupport.swift`. That is not an integrated Linux GPU
product and it is not Apple MetalFX behavioral parity.

## Source of the starting point

Pinned Xcode 26.1 / iPhoneOS 26.1 seed (`reference/`, schema v2, 239 precise
IDs, floor 120 nondeferred). Enum raw values for
`MTLFXSpatialScalerColorProcessingMode` come from the read-only
`dotnet/macios` `src/metalfx.cs` binding (`Perceptual = 0`, `Linear = 1`,
`Hdr = 2`). Apple-derived graphs remain authority for the exact-ID census.

## What is real

- `MTLFXSpatialScalerColorProcessingMode` Int enum with those raw values,
  `init(rawValue:)`, `==` / `!=`, and `Hashable`.
- All four descriptor classes
  (`MTLFXSpatialScalerDescriptor`, `MTLFXTemporalScalerDescriptor`,
  `MTLFXTemporalDenoisedScalerDescriptor`, `MTLFXFrameInterpolatorDescriptor`)
  store every public property, copy independently via `NSCopying`, and expose
  fail-closed factory methods.
- Host software scalers / interpolators snapshot descriptor formats and sizes,
  store per-frame texture/fence/jitter/matrix bindings, and implement the
  Metal 3 and Metal 4 protocol surfaces. `host_makeSoftware*` is Linux-only
  construction; Apple's `make*` factories return `nil`.

## Fail-closed / deferred

- `supportsDevice` and `supportsMetal4FX` are `false` for every lookalike
  device. Linux is not an Apple GPU.
- `makeSpatialScaler`, `makeTemporalScaler`, `makeTemporalDenoisedScaler`,
  `makeFrameInterpolator`, and the Metal 4 `compiler:` overloads return `nil`.
- `supportedInputContentMinScale` / `MaxScale` report `1.0` (identity-only
  range) until a Darwin oracle records per-family values.
- Software `encode(commandBuffer:)` is inert: it does not upscale, denoise,
  interpolate, or write output texels. Texture usage masks stay
  `MTLTextureUsage.unknown`.
- Lookalike `MTLDevice` / `MTLTexture` / `MTLFence` / `MTLCommandBuffer` /
  `MTL4Compiler` / `simd_float4x4` types are not the Metal or simd modules.
  The later integration build must import real Metal and drop
  `MetalFXLinuxSupport.swift`.

See `oracle-questions.tsv` for Darwin probes. Run
`bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.

## Depth pass 2026-09

Implemented before: **0**. Implemented after: **239**. Declared: **0**.
Deferred: **0**.

This fresh seed implements descriptor state, documented enum raw values, and
fail-closed GPU factories for every public identifier, plus host software
objects so protocol property storage and inert `encode` can be tested without
inventing MetalFX image quality.

Top-5 evidence distribution (implemented rows citing each test):

| test | rows |
| --- | --- |
| `MTLFXTemporalDenoisedScalerHostTests.swift#testTemporalDenoisedScalerHostSnapshotsDescriptor` | 30 |
| `MTLFXTemporalDenoisedScalerHostTests.swift#testTemporalDenoisedScalerHostMutableState` | 23 |
| `MTLFXTemporalDenoisedScalerDescriptorTests.swift#testTemporalDenoisedScalerDescriptorPropertyRoundTrip` | 22 |
| `MTLFXFrameInterpolatorHostTests.swift#testFrameInterpolatorHostMutableState` | 19 |
| `MTLFXFrameInterpolatorHostTests.swift#testFrameInterpolatorHostSnapshotsDescriptor` | 16 |

No non-enum test is cited by more than 40% of the remaining implemented rows
(largest is 30 of 236, 12.7%). Enum members share
`testColorProcessingModeRawValues`.
