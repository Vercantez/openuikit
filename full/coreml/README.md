# CoreML

Linux starting implementation of Apple's public `CoreML` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graphs. This directory is not wired
into the shared guest package; that integration is a separate central review
step.

## What is real

The in-memory feature and array surface used by generated model wrappers is
implemented and exercised:

- `MLModelErrorDomain` is `com.apple.CoreML`. Error, compute-unit, feature-type,
  and multi-array raw values match the Xcode 26.1 overlay.
- A fresh `MLModelConfiguration` defaults `computeUnits` to `.all` (raw 2) and
  `allowLowPrecisionAccumulationOnGPU` to `false`. A fresh `MLPredictionOptions`
  has `usesCPUOnly = false`. Linux `availableComputeDevices` is still CPU-only;
  `.all` means every available Linux backend.
- `MLMultiArray` owns typed storage that spans the highest reachable stride
  offset. Concatenation follows the public header: arbitrary axis, negative
  axes wrap, and numeric inputs up/down-cast to the requested result type.
  `transfer(to:)` honors source/destination strides and numeric types.
- `MLFeatureValue`, `MLSequence`, `MLDictionaryFeatureProvider`, and
  `MLArrayBatchProvider` round-trip scalar, string, dictionary, sequence, and
  multi-array features.
- `MLShapedArray` / `MLShapedArraySlice` provide shape, scalars, `scalarAt`,
  fill, reshape, 2-D transpose, and JSON coding.

## Fail-closed boundaries

Linux has no Apple compiled-model runtime, Neural Engine, GPU/Metal backend,
or `.mlmodel` / `.mlmodelc` deserializer:

- Sync `MLModel(contentsOf:)` / `compileModel(at:)` throw `MLModelError.io`.
- Missing-model `MLModel.load` completions use domain `com.apple.CoreML`
  code 0; `compileModel` completions use code 3. Every `MLModel` and
  `MLModelAsset` completion-handler fail-closed path is non-inline, exactly
  once, and race-safe. Async overlays share that hop and do not deadlock.
- `MLModelStructure.load` and `MLComputePlan.load` throw `.io`.
- `MLUpdateTask` initializers throw `.update`.
- `MLModel.availableComputeDevices` is CPU-only. Neural Engine core count is
  `0`. GPU/Metal properties are not declared because Metal is not linked by
  this isolated compile.
- Image/`CVPixelBuffer`/`CGImage` feature conversion is deferred until
  CoreGraphics and CoreVideo are linked into this gate. There are no local
  lookalike types. `tests/agent/CoreMLDependencyIdentity.swift` is the future
  guest/EC2 probe for real module identities and `libCoreML.dylib`.
- `NSCoder` round-trips return `nil`; Apple's archive format is not claimed.
- `MLTensor` exposes shape metadata and a CPU buffer constructor. Arithmetic,
  GPU compute, and the rest of the tensor operator surface remain deferred
  rather than returning fabricated activations.

## Still deferred

The compact public surface has 1686 exact identifiers. Collection/Sequence
witnesses synthesized onto `MLShapedArray`, Combine publishers, most
`MLTensor` operators, image conversion, and Metal device selection stay
deferred. Telegram's generated `AgeNet` / `U2netp` wrappers can type-check
against the feature/array/`MLModel` surface, but they cannot run a compiled
model until a real backend exists. Passing the isolated host gate is not
integrated Linux success.
