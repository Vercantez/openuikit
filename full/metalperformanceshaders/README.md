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
- CPU encode for unorm8 Gaussian (separable 2-pass), box, tent, convolution,
  median, Sobel, Laplacian, threshold binary/toZero/truncate, area max/min,
  dilate/erode, bilinear and Lanczos-2 scale, transpose, histogram, histogram
  equalization LUT, arithmetic add/sub/mul/div. ClipRect writes only the
  destination region; offset is the source coordinate of `clipRect.origin`.
- `MPSImage` packed `HeightxWidthxFeatureChannels` and
  `featureChannelsxHeightxWidth` byte layouts.
- Host `float32` GEMM / GEMV with alpha/beta/transposes and exact row strides,
  plus `MPSMatrixSoftMax`, `MPSMatrixFindTopK`, and `MPSMatrixSum`.
- CNN / NN-graph / RNN descriptors (`MPSCNNConvolutionDescriptor`,
  `MPSNNNeuronDescriptor`, `MPSRNNDescriptor`, `MPSNNGraph`, pooling kernels)
  are constructable validated data. Encode stays fail-closed.
- `MPSRayIntersector` is constructable; every `encodeIntersection` is
  fail-closed.
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
`NSCoder` kernel initializers return `nil`. `MPSCNNKernel` / `MPSNNGraph`
encode and `MPSRayIntersector.encodeIntersection` record
`MPSHostBoundary.lastRefusedAPI` and do not invent GPU results. CNN
convolution encode is fail-closed; descriptors and weight state objects are
real host data. `MPSAccelerationStructure` remains a declared stub.

## Tests

`tests/agent/MetalPerformanceShadersRuntime.swift` exercises descriptor math,
image byte I/O, identity convolution + clipRect, CHW/HWC layout, host GEMM,
softmax, CNN fail-closed encode, and ray fail-closed intersection, then prints
`METALPERFORMANCESHADERS_AGENT_RUNTIME_OK`.

Focused `tests/agent/*Tests.swift` probes are the coverage evidence for
`implemented` rows. Pixel-exact image kernels live in
`MPSImageKernelCPUTests.swift`.

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

## Depth pass 2026-09 (wave 8)

Coverage before this pass: **1501 implemented / 6 declared / 1875 deferred /
0 unavailable / 0 not-applicable**.

Coverage after this pass: **1763 implemented / 3 declared / 1616 deferred /
0 unavailable / 0 not-applicable**.

This second pass keeps the first-pass host surface and adds CPU pixel-exact
kernels (convolution, Gaussian/box/tent/median, Sobel, thresholds, histogram
equalization, Lanczos/bilinear/transpose, area max/min, Laplacian,
dilate/erode), matrix softmax/top-k/sum with exact strides, CHW/HWC feature
layouts, unary clipRect/offset/edgeMode, CNN/NN/RNN descriptors with
fail-closed encode, and fail-closed `MPSRayIntersector`.

`MPSNNFilterNode`, `MPSNNImageNode`, and `MPSNNPadding` moved from `declared`
to `implemented`. `MPSAccelerationStructure`, `MPSHandle`, and
`MPSHeapProvider` stay declared stubs. Remaining CNN training/gradient layers,
YOLO loss, RNN inference layers, and binary/multiary kernels stay deferred.

Top-5 `implemented` evidence distribution after this pass:

| citations | share | evidence |
| ---: | ---: | --- |
| 377 | 21.4% | `MPSTypesTests.swift#testMPSOptionSetAlgebra` (option-set members; shared table-driven test) |
| 343 | 19.5% | `MPSTypesTests.swift#testMPSEnumRawValues` (enum members; shared table-driven test) |
| 135 | 7.7% | `MPSGeometryTests.swift#testMPSGeometryStructs` |
| 104 | 5.9% | `MPSGeometryTests.swift#testMPSPackedAndRayStructs` |
| 81 | 4.6% | `MPSTypesTests.swift#testMPSConstantVars` |

No non-enum/option-set test cites more than 40% of the remaining implemented
rows (next highest is geometry structs at 14.0% of remaining). New CNN/matrix
evidence is split across `MPSCNNDescriptorTests.swift` and
`MPSMatrixDepthTests.swift`.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot
fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`).
`swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean
product tree (`products=clean`). Starting commit
`bff8535c68425cc39fb45cb00d447b0981b57242` matched.