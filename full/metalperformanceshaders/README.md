# MetalPerformanceShaders (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`MetalPerformanceShaders` overlay, seeded from the pinned Xcode 26.1 iPhoneOS
symbol graph. It is not wired into the shared guest package; that integration
is a separate central review step.

## What is real

- Public enums, option sets, geometry structs, and data-type helpers used to
  describe kernels, images, and matrices (`MPSDataType`, `MPSKernelOptions`,
  `MPSOffset` / `MPSRegion`, histogram info, and related constants).
- Packed ray/intersection value types (`MPSPackedFloat3`,
  `MPSAxisAlignedBoundingBox`, `MPSRayOriginDirection` and the documented
  intersection payload structs).
- Host-backed `MPSImage` / `MPSImageDescriptor` construction, CPU
  `readBytes` / `writeBytes` round-trips, resource sizing, and batch helpers.
- Kernel objects used by the Telegram corpus (Gaussian blur, box/tent,
  histogram, scale, threshold, area max/min) can be constructed, copied, and
  queried. `sourceRegion(destinationSize:)` is offset/clip CPU geometry.
  `MPSImageGaussianBlur.copy(with:device:)` preserves `sigma`.
- CPU encode for unorm8 Gaussian (separable), box, convolution, transpose,
  arithmetic add/sub/mul/div, and a four-channel uint32 histogram into a host
  `MTLBuffer`.
- Matrix and vector descriptors plus host buffers. `MPSSizeofMPSDataType` and
  `MPSDataTypeBitsCount` follow the documented bit-field encoding.
- Host `float32` GEMM / GEMV (`MPSMatrixMultiplication`,
  `MPSMatrixVectorMultiplication`) and matrix/image copy helpers.
- `MPSNDArrayDescriptor` shape/slice/transpose/reshape math and host
  `MPSNDArray` byte I/O.
- Additional constructable image kernels (median, dilate/erode, integral,
  Laplacian/pyramid, reduce, statistics, Canny, keypoints) with documented
  properties; GPU encode stays fail-closed unless a CPU path exists.
- `MPSSupportsMTLDevice` is always `false` and `MPSGetPreferredDevice` is
  always `nil`. Linux has no Metal GPU in this environment.

Local `MTLDevice` / `MTLTexture` / `MTLCommandBuffer` stand-ins exist only so
MPS signatures compile. They are not the Apple Metal module and must be
replaced when `Metal` is integrated.

## Fail-closed boundaries

GPU `encode` methods that have no CPU implementation record
`MPSHostBoundary.lastRefusedAPI` and do not write fabricated filtered pixels.
In-place texture encodes return `false`. Command-buffer heap hints
(`MPSHintTemporaryMemoryHighWaterMark`, `MPSSetHeapCacheDuration`) are inert.
`NSCoder` kernel initializers return `nil`. Neural-network graphs, CNN layers,
and `MPSRayIntersector` remain deferred.

## Tests

`tests/agent/MetalPerformanceShadersRuntime.swift` exercises descriptor math,
image byte I/O, kernel construction, histogram sizing, host GEMM, and the
fail-closed device queries, then prints `METALPERFORMANCESHADERS_AGENT_RUNTIME_OK`.

Focused `tests/agent/*Tests.swift` probes are the coverage evidence for
`implemented` rows.

Run:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Coverage before this pass: **1206 implemented / 6 declared / 2170 deferred /
0 unavailable / 0 not-applicable**.

Coverage after this pass: **1501 implemented / 6 declared / 1875 deferred /
0 unavailable / 0 not-applicable**.

Telegram is the only 20-app corpus client (`BlurRenderPass`,
`HistogramCalculationPass`, call/camera Metal layers). Those identifiers were
raised first (Gaussian, histogram, image/matrix host objects), then the rest of
the documented value-type and host-arithmetic surface.

Top-5 `implemented` evidence distribution:

| citations | share | evidence |
| ---: | ---: | --- |
| 377 | 25.1% | `MPSTypesTests.swift#testMPSOptionSetAlgebra` (option-set members; shared table-driven test) |
| 343 | 22.9% | `MPSTypesTests.swift#testMPSEnumRawValues` (enum members; shared table-driven test) |
| 135 | 9.0% | `MPSGeometryTests.swift#testMPSGeometryStructs` |
| 104 | 6.9% | `MPSGeometryTests.swift#testMPSPackedAndRayStructs` |
| 81 | 5.4% | `MPSTypesTests.swift#testMPSConstantVars` |

No non-enum/option-set test cites more than 40% of the remaining implemented
rows (next highest is geometry structs at 17.3% of remaining).
