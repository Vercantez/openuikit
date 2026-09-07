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
  `featureChannelsxHeightxWidth` byte layouts, including four-channel texture
  slices, batch image indices, and padded row/plane transfers.
- Contiguous host `MPSNDArrayIdentity` reshape views/copies and byte-preserving
  `MPSNNReshape` for unorm8/float16/float32 images. Crop/resize configuration
  owns its data; neural sampling and gradient-state generation stay fail-closed.
- Host `float32` GEMM / GEMV with alpha/beta/transposes and exact row strides,
  plus `MPSMatrixSoftMax`, `MPSMatrixFindTopK`, and `MPSMatrixSum`.
- CNN / NN-graph / RNN descriptors (`MPSCNNConvolutionDescriptor`,
  `MPSNNNeuronDescriptor`, `MPSRNNDescriptor`, `MPSNNGraph`, pooling kernels,
  `MPSCNNBinaryKernel` / `MPSCNNMultiaryKernel`, YOLO/loss descriptors,
  LSTM/GRU descriptors, batch-norm data sources) are constructable validated
  data. Encode stays fail-closed except host Adam/SGD/RMSProp on vectors and
  matrices.
- Host float32 Adam, SGD, and RMSProp on `MPSVector` / `MPSMatrix`.
- Host float32 `MPSMatrixNeuron` (ReLU/linear/sigmoid and related activations
  with optional bias/alpha/PReLU), `MPSMatrixFullyConnected` (GEMM + bias +
  neuron) and its gradient, `MPSMatrixBatchNormalization` (per-channel
  population mean/var + gamma/beta) and its gradient, and
  `MPSMatrixSoftMaxGradient`. `MPSMatrixRandom` / MTGP32 / Philox fill
  float32 host buffers with a documented LCG (not Apple's generators).
- `MPSAccelerationStructure` and polygon/triangle/instance subclasses are
  constructable host objects; `rebuild` / `refit` stay unbuilt and refuse GPU
  work. `MPSCommandBuffer` wraps a host command buffer; `MPSKeyedUnarchiver`
  never fabricates decoded kernels.
- CNN convolution-gradient / arithmetic-gradient / dropout / instance and
  group-norm / RNN inference layers / EDLines / guided filter / SVGF denoiser
  are constructable validated data; encode stays fail-closed.
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
real host data. `MPSAccelerationStructure.rebuild` / `encodeRefit` leave
status `.unbuilt` and refuse GPU work. `MPSKeyedUnarchiver` returns nil.
RNN inference, EDLines, guided-filter, instance/group-norm, and SVGF
denoiser encode record `MPSHostBoundary.lastRefusedAPI`. `MPSHandle` and
`MPSHeapProvider` remain declared stubs.

## Tests

`tests/agent/MetalPerformanceShadersRuntime.swift` exercises descriptor math,
image byte I/O, identity convolution + clipRect, CHW/HWC layout, host GEMM,
softmax, CNN fail-closed encode, and ray fail-closed intersection, then prints
`METALPERFORMANCESHADERS_AGENT_RUNTIME_OK`.

Focused `tests/agent/*Tests.swift` probes are the coverage evidence for
`implemented` rows. Pixel-exact image kernels live in
`MPSImageKernelCPUTests.swift`. Depth-pass CNN/optimizer tests live in
`MPSDepthPassTests.swift`. Wave-9 matrix neuron/FC/BN and acceleration /
CNN-gradient / RNN inference probes live in `MPSWave9MatrixTests.swift`
and `MPSWave9SurfaceTests.swift`.

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

### Local continuation: `agent/fw-metalperformanceshaders-c`

This continuation starts on the existing wave-9 tree at `3e9bada0` and keeps
all earlier implementations and tests. Only `full/metalperformanceshaders/`
is changed. No Apple simulator, network service or GPU result was used as an
oracle; the measurements below are deterministic Linux CPU/byte-layout probes.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2795 | 2821 |
| declared | 2 | 2 |
| deferred | 585 | 559 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: **26 exact identifiers**, split among `MPSNDArrayIdentity`
(6), `MPSNNReshape` (7), `MPSNNCropAndResizeBilinear` (7), and
`MPSNNResizeBilinear` (6). Every promoted row cites the synchronous focused test
that exercises its identifier. The resize/crop classes provide validated,
owned configuration data with fail-closed encode; their pixels are not claimed.
No unavailable or not-applicable rows were added or reclassified.

| measurement | before | after / evidence |
| --- | --- | --- |
| `MPSImage`, unorm8, width 2, height 1, 5 channels, 2 images | 2 slices, 16 allocated bytes (insufficient for 20 logical bytes) | 4 slices, 32 bytes; all 32 physical bytes checked against hand-computed RGBA slices in `MPSImageSliceTests.swift#testMPSImageFeatureSlicesAndBatch` |
| Image batch/channel addressing | `imageIndex` ignored; channels addressed as an unpadded flat pixel stream | Independent image 0/1 payloads; C3/C4 transfers cross the slice boundary; row/plane padding remains unchanged in `testMPSImageFeatureSliceStrides` |
| NDArray reshape | Family absent | Four reshape overloads exercised; six float32 bit patterns (including signed zero, infinities and a NaN payload) preserved exactly; chained views observe writes both ways; explicit destinations copy independently |
| Packed image reshape | Family absent | 2x1x5 -> 1x5x2 preserves all 10/20/40 bytes for unorm8/float16/float32; both items in explicit and allocating batches checked |
| Crop descriptor storage | Family absent | Two finite, nontrivial regions survive mutation/release of the caller buffer and release of the original kernel after copying |
| Focused regression suite | 65/65 passing | 76/76 passing, including every earlier focused test |

`MPSNDArrayIdentity` shares mutable storage for contiguous reshape views and
copies bytes into an explicit destination when a host command buffer is
provided. Shape products must agree, be positive and fit in `Int`; fractional
NSNumber dimensions, incompatible destination shapes/types and non-nil compute
encoders refuse before modifying output. Views do not allocate another payload.
The existing general `arrayView`/strided NDArray APIs were not broadened.

`MPSNNReshape` supports one complete image per object, unchanged scalar type,
default offsets/clip and packed HWC order. It rejects unsupported parent images,
embedded image batches, non-default channel offsets/clip, invalid dimensions and
unsupported scalar formats. Explicit gradient-state overloads clear their output
state and record refusal; they do not fabricate a gradient state. Allocating
single-image refusal returns the unchanged source with the refusal marker;
allocating batch refusal returns an empty array. Temporary read-count semantics,
Apple alias/copy decisions and crop/resize sampling remain oracle questions.
The pre-existing local Metal stand-ins remain the sealed gate's device layer;
central integration with the separate Metal module is still outside this lane.

Top-5 implemented evidence distribution after this continuation:

| citations | share | evidence |
| ---: | ---: | --- |
| 377 | 13.4% | `MPSTypesTests.swift#testMPSOptionSetAlgebra` |
| 343 | 12.2% | `MPSTypesTests.swift#testMPSEnumRawValues` |
| 243 | 8.6% | `MPSWave9SurfaceTests.swift#testMPSCNNWave9Kernels` |
| 135 | 4.8% | `MPSGeometryTests.swift#testMPSGeometryStructs` |
| 104 | 3.7% | `MPSGeometryTests.swift#testMPSPackedAndRayStructs` |

All 2,821 implemented citations resolve to actual top-level synchronous,
no-argument functions in `tests/agent/*Tests.swift`. The largest non-table test
remains the earlier 243-row test; no bulk relabel was performed.

Validation in the operator's `uikit-linux` container, private checkout
`/work-fw-metalperformanceshaders-c`, Swift **6.2.4**, aarch64 Linux:

- Sealed `tests/acceptance/test_host.sh`: `FRAMEWORK_FANOUT_HOST_OK module=MetalPerformanceShaders`.
- New `tests/test_agent.sh` compiles with warnings as errors and executes every
  focused test: `MPS_FOCUSED_TESTS_OK count=76`. These are all shell tests present
  under this framework; temporary build products are removed on exit.
- `python3 -B full/framework-fanout/validate_seed.py --framework full/metalperformanceshaders --phase deliverable`:
  `FRAMEWORK_FANOUT_DELIVERABLE_OK`, both in the container and the local worktree
  (local invocation from `uikit/` uses `../full/` paths).
- A separate baseline compilation substituted the unmodified `HEAD` version
  of `MPSImage.swift` and safely queried allocation without oversized writes:
  `MPS_IMAGE_BASELINE images=2 channels=5 slices=2 bytes=16`.
- The sealed runtime now also exercises NDArray shared reshape and the
  five-channel image reshape. Immutable inputs and the sealed gate are untouched.

### Local next pass: strided CPU matrix batches

Baseline: `89291fae`, already carrying the preceding local reshape pass.
Changes remain exclusively in `full/metalperformanceshaders/`.

| status | before | after |
| --- | ---: | ---: |
| implemented | 2821 | 2827 |
| declared | 2 | 2 |
| deferred | 559 | 553 |
| unavailable | 0 | 0 |
| not-applicable | 0 | 0 |

Implemented gain: **6 exact identifiers** for `MPSMatrixBinaryKernel` and its
five configuration properties. The pinned graph establishes that softmax-gradient
inherits this base. Its batch settings now select actual CPU work; copies retain
all five properties. Each promoted row cites
`MPSMatrixBatchedCPUTests.swift#testMPSMatrixBinaryKernelBatchedSoftMaxGradient`,
which checks exact output, source preservation, copies, and refusal on each
nonzero origin. No rows were bulk relabeled, made unavailable or not-applicable.

The existing `MPSMatrixMultiplication` also now honors `batchStart` / `batchSize`.
Both encodes use each matrix's independent buffer offset, rowBytes and
matrixBytes, validating the entire selected batch before writing. Invalid ranges,
short backing buffers, misaligned/invalid strides, unsupported types and shared
result/input buffers refuse. No broadcasting or nonzero binary-origin convention
is invented; these remain explicit oracle questions. Only softmax-gradient is
newly connected to the binary base; other matrix subclasses are unchanged.

| Linux CPU measurement | before | after |
| --- | --- | --- |
| 1x1 GEMM batches A=[2,5,7], B=[3,11,13], C=[100,200,300], start=1, size=2, stride=8 bytes | [6,200,300]: wrong batch changed | [100,55,91]; all three padding floats remain -999 |
| GEMM beta=0, A=2, B=3, old C=NaN | NaN | 6 exactly |
| Rectangular GEMM, all four transpose combinations, alpha=2/beta=-1, two selected batches | batch controls ignored | [37,42;83,96] and [-3,8;13,30] exactly, with 80/96/112-byte matrix strides |
| Softmax gradient, y=[1/4,3/4], g=[2,6]; y=[1/2,1/2], g=[8,-4] | binary base/batch surface absent | [-3/4,3/4] and [3,-3] exactly, with 24/32/40-byte matrix strides |
| Entire-buffer checks | not carried for batched kernels | prefixes, suffixes, row/matrix padding and unselected batches retain -999; both sources unchanged |
| Focused synchronous regression tests | 76 | 80 passing, including all earlier tests |

The first two before/after measurements compile the unmodified baseline versions
of `MPSMatrixKernels.swift` and `MPSMatrixNN.swift` into a separate temporary
module, then run the same probe against baseline and updated modules. All other
numbers are hand-computed float32 oracles in the carried focused tests. This is
host numerical evidence, not an Apple GPU or default-configuration equivalence
claim. The pre-existing local Metal stand-ins remain the device layer; replacing
them with the separate Metal lane requires central integration outside this scope.

Top-5 implemented evidence distribution after this next pass:

| citations | share | evidence |
| ---: | ---: | --- |
| 377 | 13.3% | `MPSTypesTests.swift#testMPSOptionSetAlgebra` |
| 343 | 12.1% | `MPSTypesTests.swift#testMPSEnumRawValues` |
| 243 | 8.6% | `MPSWave9SurfaceTests.swift#testMPSCNNWave9Kernels` |
| 135 | 4.8% | `MPSGeometryTests.swift#testMPSGeometryStructs` |
| 104 | 3.7% | `MPSGeometryTests.swift#testMPSPackedAndRayStructs` |

All 2,827 implemented citations resolve to top-level synchronous no-argument
tests. The largest non-table test remains the existing 243-row test, below the
40% limit. No immutable files or acceptance scripts changed.

Validation: operator container `uikit-linux`, private tree
`/work-fw-metalperformanceshaders-c`, Swift 6.2.4 / aarch64 Linux:

- `tests/acceptance/test_host.sh`: `FRAMEWORK_FANOUT_HOST_OK module=MetalPerformanceShaders`.
  The runtime now also checks a selected softmax-gradient batch and untouched padding.
- `tests/test_agent.sh`: `MPS_FOCUSED_TESTS_OK count=80`. These two scripts are
  every shell test present in the framework; temporary products are removed.
- `validate_seed.py --framework full/metalperformanceshaders --phase deliverable`:
  `FRAMEWORK_FANOUT_DELIVERABLE_OK` in the container and locally (from `uikit/`
  the local paths use `../full/`).

## Depth pass 2026-09 (wave 9)

Coverage before this pass: **2282 implemented / 3 declared / 1097 deferred /
0 unavailable / 0 not-applicable**.

Coverage after this pass: **2795 implemented / 2 declared / 585 deferred /
0 unavailable / 0 not-applicable**.

This pass keeps the earlier host image/matrix/CNN kernels and extends the
largest remaining families: `MPSMatrixNeuron` / `MPSMatrixFullyConnected` /
`MPSMatrixBatchNormalization` (host float32 encode with hand-computed
oracles), `MPSMatrixSoftMaxGradient`, `MPSMatrixRandom` (LCG host fill),
`MPSAccelerationStructure` plus polygon/triangle/instance subclasses,
`MPSCommandBuffer`, `MPSKeyedUnarchiver`, `MPSCNNConvolutionGradient`,
`MPSNNArithmeticGradientNode`, instance/group-norm data sources,
`MPSRNNMatrixInferenceLayer` / `MPSRNNImageInferenceLayer`,
`MPSImageEDLines`, and `MPSSVGFDenoiser`.

Host ReLU/FC/BN numerics run against hand-computed float32 rasters. CNN /
RNN / EDLines / guided-filter / SVGF encode stays fail-closed. No
`unavailable` rows: remaining deferred identifiers still lack a host
oracle, not a hardware entitlement. Metal overlay methods on
`MTLCommandBuffer` (`useResidencySets`, `logs`, `completed()`,
`scheduled()`) stay deferred (no Apple Metal module). `MPSHandle` and
`MPSHeapProvider` stay declared stubs. No SwiftUI overlay IDs. No
`not-applicable` rows.

Top-5 `implemented` evidence distribution after this pass:

| citations | share | evidence |
| ---: | ---: | --- |
| 377 | 13.5% | `MPSTypesTests.swift#testMPSOptionSetAlgebra` (option-set members; shared table-driven test) |
| 343 | 12.3% | `MPSTypesTests.swift#testMPSEnumRawValues` (enum members; shared table-driven test) |
| 243 | 8.7% | `MPSWave9SurfaceTests.swift#testMPSCNNWave9Kernels` |
| 135 | 4.8% | `MPSGeometryTests.swift#testMPSGeometryStructs` |
| 104 | 3.7% | `MPSGeometryTests.swift#testMPSPackedAndRayStructs` |

No non-enum/option-set test cites more than 40% of the remaining implemented
rows (next highest is `testMPSCNNWave9Kernels` at 11.7% of remaining).
Implemented gain versus the previous ledger: **+513**.

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot
fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`).
`swiftc` is Swift 6.2.4 / linux and the sealed gate compiles with a clean
product tree (`products=clean`). Starting commit
`6bf18072f4bc9ca119f4b0ad49dd8478f92dd5f0` matched.