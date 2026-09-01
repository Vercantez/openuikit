# CoreML

Linux starting implementation of Apple's public `CoreML` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graphs. This directory is not wired
into the shared guest package; that integration is a separate central review
step.

## What is real

The in-memory feature and array surface used by generated model wrappers is
implemented and exercised:

- `MLMultiArray` owns contiguous typed storage, C-contiguous strides, linear
  and dimensional subscripts, concatenation along axis 0, `transfer(to:)`, and
  unsafe buffer access.
- `MLFeatureValue`, `MLSequence`, `MLDictionaryFeatureProvider`, and
  `MLArrayBatchProvider` round-trip scalar, string, dictionary, sequence, and
  multi-array features.
- `MLShapedArray` / `MLShapedArraySlice` provide shape, scalars, `scalarAt`,
  fill, reshape, 2-D transpose, and JSON coding.
- `MLModelConfiguration`, `MLPredictionOptions`, `MLOptimizationHints`,
  parameter/metric keys, and CPU-only `MLComputeDevice` listing are local
  values with no Apple service.

## Fail-closed boundaries

Linux has no Apple compiled-model runtime, Neural Engine, GPU/Metal backend,
or `.mlmodel` / `.mlmodelc` deserializer:

- `MLModel` load, compile, prediction, batch prediction, and parameter lookup
  throw `MLModelError.io` or `.generic`.
- `MLModelAsset`, `MLModelStructure.load`, and `MLComputePlan.load` throw
  `.io`.
- `MLUpdateTask` initializers throw `.update`.
- `MLModel.availableComputeDevices` is CPU-only. Neural Engine core count is
  `0`. GPU/Metal properties are not declared because Metal is not linked by
  this isolated compile.
- Image/`CVPixelBuffer`/`CGImage` feature conversion is deferred until
  CoreGraphics and CoreVideo are linked into this gate.
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
model until a real backend exists.
