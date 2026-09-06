# MLCompute (Linux starting point)

This directory is a clean-room Linux port of Apple's public `MLCompute`
module, seeded from the iPhoneOS 26.1 SDK graphs. It produces module
`MLCompute` and `libMLCompute.dylib`.

The isolated host gate (`bash tests/acceptance/test_host.sh`) compiles
against the **toolchain** Foundation. It is not an integrated Linux/EC2
guest-Foundation result. A future EC2 run must build guest Foundation
first, build this module with those `-I/-L` paths, and execute
`tests/agent/MLComputeDependencyIdentity.swift`.

Environment marker used by this campaign:

`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`

`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`). `swiftc` is
Swift 6.2.4 / linux and the sealed gate compiles with a clean product tree.

## What is real

- Integer enums and option sets use the raw values corroborated by the
  pinned dotnet/macios bindings (`MLCActivationType`,
  `MLCArithmeticOperation`, `MLCComparisonOperation`, `MLCDataType` with
  its documented gaps, `MLCDeviceType`, `MLCExecutionOptions` bits,
  `MLCGraphCompilationOptions` bits, optimizer / loss / padding /
  reduction / sample / softmax enumerations).
- Swift overlays `MLCPoolingType` (associated `average(countIncludesPadding:)`)
  and `MLCPaddingPolicy` (associated `sized(y:x:)`).
- Tensor descriptors compute C-contiguous strides, NCHW packing for
  `width:height:featureChannelCount:batchSize` (`[N,C,H,W]`), convolution
  weight/bias shapes, and `tensorAllocationSizeInBytes`.
  `maxTensorDimensions` is 5.
- Host `MLCTensor` / `MLCTensorData` own or borrow CPU buffers, fill,
  copy, bind-and-write on `MLCDevice.cpu()`, and quantize/dequantize
  int8/uint8 with round-to-nearest saturation.
- Descriptors store hyperparameters (activation `a,b,c`, convolution
  geometry, pooling, loss, LSTM, embedding, matmul, multi-head,
  YOLO scales). Convolution / pooling output spatial size follows
  `floor((in + 2*pad - dilation*(k-1) - 1)/stride)+1`, with `.same`
  preserving size at stride 1.
- Graph topology: `node(with:)`, reshape (including a single `-1`),
  transpose, concat, split, gather/scatter placeholders, DOT summary,
  and bind-and-write of named inputs onto CPU tensors.
- CPU device construction (`cpu()`, `init(type: .cpu/.any)`). Platform
  RNG seed is stored and used by local Glorot/Xavier/uniform fills.

## Fail-closed boundaries

Linux has no Metal, Apple Neural Engine, or BNNS:

- `MLCDevice.gpu()`, `ane()`, `init(type: .gpu/.ane)` return `nil`.
- `init(gpuDevices:)` / `init(GPUDevices:)` / `gpuDevices` are
  **unavailable** (Metal `MTLDevice` is not a declared dependency).
- `compile(options:device:)` always returns `false`.
- `execute*` completion-handler variants return `false` and invoke the
  handler **synchronously** on the caller with
  `MLComputeError.executeFailed` (`org.openuikit.MLCompute.linux` code 4).
  Apple's queue choice is an oracle question; the sealed runner has no
  run loop.
- Async `execute*` overlays are **declared** only (cannot be awaited by
  the sync runner) and throw the same execute-failed error.

## Depth pass 2026-09

Exact public IDs: **787**. Nondeferred floor for `large-partitioned` is 79.

- After this seed: implemented **780** / declared **4** / unavailable **3**
  (Metal `MTLDevice` GPU device APIs) / deferred **0**.
- Top-5 implemented evidence distribution (780 rows):
  1. `MLComputeLayerTests.swift#testSimpleLayerConstruction` — 77
  2. `MLComputeLayerTests.swift#testWeightedLayerConstruction` — 62
  3. `MLComputeGraphTests.swift#testOptimizerHyperparameters` — 40
  4. `MLComputeEnumTests.swift#testArithmeticOperationRawValues` — 36
  5. `MLComputeLayerTests.swift#testActivationLayerFactories` — 31
- Enum/option-set members share table-driven tests. No other single test
  exceeds 40% of the remaining implemented rows (largest remaining
  citation is about 15%).
- Gate: `bash full/mlcompute/tests/acceptance/test_host.sh`.

Still not claimed: Apple-identical BNNS kernels, Metal GPU placement,
ANE fusion, callback queues, or bit-identical RNG / quantizer output.

See `oracle-questions.tsv`.
