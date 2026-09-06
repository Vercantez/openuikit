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
  `MPSNNNeuronDescriptor`, `MPSRNNDescriptor`, `MPSNNGraph`, pooling kernels,
  `MPSCNNBinaryKernel` / `MPSCNNMultiaryKernel`, YOLO/loss descriptors,
  LSTM/GRU descriptors, batch-norm data sources) are constructable validated
  data. Encode stays fail-closed except host Adam/SGD/RMSProp on vectors and
  matrices.
- Host float32 Adam, SGD, and RMSProp on `MPSVector` / `MPSMatrix`.
- `MPSRayIntersector` is constructable; every `encodeIntersection` is
  fail-closed. `MPSSVGF` stores filter parameters and refuses every encode.
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
encode, `MPSCNNBinaryKernel` / `MPSCNNMultiaryKernel`, `MPSSVGF`,
`MPSCNNBatchNormalization` encode, NDArray kernel encode, RNN sequence encode,
and `MPSRayIntersector.encodeIntersection` record
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
`MPSImageKernelCPUTests.swift`. Depth-pass CNN/optimizer tests live in
`MPSDepthPassTests.swift`.

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

Coverage before this pass: **1763 implemented / 3 declared / 1616 deferred /
0 unavailable / 0 not-applicable**.

Coverage after this pass: **2282 implemented / 3 declared / 1097 deferred /
0 unavailable / 0 not-applicable**.

This pass keeps the earlier host image/matrix kernels and extends the
CNN / NN / NDArray / optimizer surface. Newly implemented families include
`MPSCNNBinaryKernel`, `MPSCNNMultiaryKernel`, `MPSSVGF` (fail-closed encode),
`MPSCNNConvolutionTranspose`, `MPSCNNYOLOLoss` plus descriptor, `MPSLSTMDescriptor`
/ `MPSGRUDescriptor`, `MPSNNForwardLossNode`, `MPSRNNMatrixTrainingLayer`,
`MPSCNNBatchNormalization` plus data source/state, `MPSNDArrayBinaryKernel` /
unary / multiary, `MPSNNBinaryArithmeticNode`, `MPSCNNLoss` / labels /
forward and gradient, and `MPSNNOptimizer` / Adam / SGD / RMSProp.

Host float32 Adam, SGD, and RMSProp on `MPSVector` / `MPSMatrix` run against
hand-computed updates (bias-corrected Adam, vanilla SGD, RMSProp with decay).
CNN / SVGF / NDArray / RNN-sequence encode stays fail-closed. No `unavailable`
rows: remaining deferred identifiers still lack a host oracle, not a hardware
entitlement. `MPSAccelerationStructure`, `MPSHandle`, and `MPSHeapProvider`
stay declared stubs. No SwiftUI overlay IDs.

Top-5 `implemented` evidence distribution after this pass:

| citations | share | evidence |
| ---: | ---: | --- |
| 377 | 16.5% | `MPSTypesTests.swift#testMPSOptionSetAlgebra` (option-set members; shared table-driven test) |
| 343 | 15.0% | `MPSTypesTests.swift#testMPSEnumRawValues` (enum members; shared table-driven test) |
| 135 | 5.9% | `MPSGeometryTests.swift#testMPSGeometryStructs` |
| 104 | 4.6% | `MPSGeometryTests.swift#testMPSPackedAndRayStructs` |
| 81 | 3.5% | `MPSTypesTests.swift#testMPSConstantVars` |

No non-enum/option-set test cites more than 40% of the remaining implemented
rows (next highest is geometry structs at 8.6% of remaining). New evidence is
split across `MPSDepthPassTests.swift` (binary/multiary, SVGF, transpose, YOLO,
LSTM/GRU, batch-norm, NDArray kernels, Adam/SGD/RMSProp).

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot
fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`).
`swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean
product tree (`products=clean`). Starting commit
`2de7152a12f3beb34a4c1e92dc0e849af9a1d88b` matched.