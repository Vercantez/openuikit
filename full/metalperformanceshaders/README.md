# MetalPerformanceShaders (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`MetalPerformanceShaders` overlay, seeded from the pinned Xcode 26.1 iPhoneOS
symbol graph. It is not wired into the shared guest package; that integration
is a separate central review step.

## What is real

- Public enums, option sets, geometry structs, and data-type helpers used to
  describe kernels, images, and matrices (`MPSDataType`, `MPSKernelOptions`,
  `MPSOffset` / `MPSRegion`, histogram info, and related constants).
- Host-backed `MPSImage` / `MPSImageDescriptor` construction, CPU
  `readBytes` / `writeBytes` round-trips, resource sizing, and batch helpers.
- Kernel objects used by the Telegram corpus (Gaussian blur, box/tent,
  histogram, scale, threshold, area max/min) can be constructed, copied, and
  queried. `sourceRegion(destinationSize:)` is offset/clip CPU geometry, not a
  GPU halo model.
- Matrix and vector descriptors plus host buffers. `MPSSizeofMPSDataType` and
  `MPSDataTypeBitsCount` follow the documented bit-field encoding.
- `MPSSupportsMTLDevice` is always `false` and `MPSGetPreferredDevice` is
  always `nil`. Linux has no Metal GPU in this environment.

Local `MTLDevice` / `MTLTexture` / `MTLCommandBuffer` stand-ins exist only so
MPS signatures compile. They are not the Apple Metal module and must be
replaced when `Metal` is integrated.

## Fail-closed boundaries

GPU `encode` methods trap through `MPSHostBoundary.refuseGPUEncode`. They do
not write fabricated filtered pixels. Command-buffer heap hints
(`MPSHintTemporaryMemoryHighWaterMark`, `MPSSetHeapCacheDuration`) are inert.
`NSCoder` kernel initializers return `nil`. Neural-network graphs, ray
intersectors, and most CNN layers remain deferred.

## Tests

`tests/agent/MetalPerformanceShadersRuntime.swift` exercises descriptor math,
image byte I/O, kernel construction, histogram sizing, and the fail-closed
device queries, then prints `METALPERFORMANCESHADERS_AGENT_RUNTIME_OK`.

Run:

```sh
bash tests/acceptance/test_host.sh
```
