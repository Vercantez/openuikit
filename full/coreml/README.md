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
  `allowLowPrecisionAccumulationOnGPU` to `false`. `preferredMetalDevice` is
  always `nil`. A fresh `MLPredictionOptions` has `usesCPUOnly = false`. Linux
  `availableComputeDevices` is still CPU-only; `.all` means every available
  Linux backend.
- `MLMultiArray` owns typed storage that spans the highest reachable stride
  offset. Concatenation follows the public header: arbitrary axis, negative
  axes wrap, and numeric inputs up/down-cast to the requested result type.
  `transfer(to:)` honors source/destination strides and numeric types.
- `MLFeatureValue`, `MLSequence`, `MLDictionaryFeatureProvider`, and
  `MLArrayBatchProvider` round-trip scalar, string, dictionary, sequence, and
  multi-array features.
- `MLShapedArray` / `MLShapedArraySlice` provide shape, scalars, `scalarAt`,
  fill, reshape, concat, 2-D transpose, JSON coding, and Collection traversal
  along axis 0.
- `MLTensor` is a CPU IEEE-754 buffer: arithmetic, matmul, reductions,
  elementwise, pad/resize/gather, and range slicing. Results are checked
  against hand-computed values; GPU/ANE scheduling is not claimed.
- `MLModelDescription` / `MLFeatureDescription` and the constraint types are
  constructible and populated from parsed models. Compiled `.mlmodelc`
  bundles expose `metadata.plist` (author/license/version, inputs/outputs).

## Fail-closed boundaries

Linux has no Apple Neural Engine, GPU/Metal backend, or espresso/.mlprogram
runtime:

- Missing-path sync `MLModel(contentsOf:)` / `compileModel(at:)` throw
  `MLModelError.io`. Missing-model `MLModel.load` completions use domain
  `com.apple.CoreML` code 0; `compileModel` completions use code 3. Completions
  are non-inline, exactly once, and race-safe.
- Neural-network / MIL / unknown model types load their description but
  `prediction(from:)` throws `MLModelError.generic` whose message lists
  `neural network layers not implemented`.
- `MLCustomLayer` / `MLCustomModel` / `MLUpdateTask` throw `.customLayer`,
  `.customModel`, or `.update`. `MLFailClosedCustomLayer` is the explicit
  Linux stand-in.
- `MLModelStructure.load` and `MLComputePlan.load` throw `.io`.
- `MLModel.availableComputeDevices` is CPU-only. Neural Engine core count is
  `0`. `preferredMetalDevice` is always `nil`.
- `CGImage` / `CVPixelBuffer` APIs are unavailable in this isolated compile.
  `imageAtURL` initializers that do not mention those types throw
  `.featureType`. `tests/agent/CoreMLDependencyIdentity.swift` is the future
  guest/EC2 probe for real module identities and `libCoreML.dylib`.
- `NSCoder` round-trips return `nil`; Apple's archive format is not claimed.
- `MLTensor` arithmetic, reductions, and shape ops run on a host IEEE-754
  CPU buffer. They do not claim Apple GPU / ANE scheduling or
  `withMLTensorComputePolicy` hops off-CPU. Neural-network / MIL prediction
  still fails closed except Identity, DictVectorizer, Pipeline of those,
  and a GLMRegressor linear layer (`y = Wx+b`, transform 0) checked against
  the hand-computed output `3·1 + 4·2 + 5 = 16`.
- `MLModelCollection` / `MLUpdateTask` / custom layers fail closed with
  `.modelCollection`, `.update`, or `.customLayer`. Apple's model-catalog
  daemon and the CoreML model-collection entitlement are not present on Linux.

## Depth pass 2026-09

SDK depth for `CoreML` (1686 IDs). The data plane is implemented exactly;
the model plane is honest.

- `MLModel.compileModel(at:)` / `init(contentsOf:)` parse the public Core ML
  protobuf (`specificationVersion`, `ModelDescription`, type oneof) and the
  compiled `metadata.json` sidecar. Compile writes `model.specification` plus
  `metadata.json` into a temporary `.mlmodelc`.
- `prediction(from:)` executes Identity (field 900), DictVectorizer (field
  603, `stringToIndex` / `int64ToIndex`), and a Pipeline of those (field 202,
  including classifier/regressor wrappers). Everything else fails closed with
  `neural network layers not implemented`.
- `MLShapedArray` / `MLShapedArraySlice` now conform to `RandomAccessCollection`
  (and Slice to `RangeReplaceableCollection`). Conversion to/from
  `MLMultiArray` is tested.
- Coverage after this pass: implemented ≥ 700; the MLMultiArray,
  MLShapedArray, MLFeatureValue, provider, description, and configuration
  families have no `deferred` rows. Pixel-buffer / `CGImage` members are
  `unavailable` because CoreVideo/CoreGraphics are not importable here.

### Evidence repair (merge refusal at `b9242bf8`)

The depth-pass ledger marked **758** rows `implemented`, but every citation was
`tests/agent/CoreMLRuntime.swift` or `tests/agent/CoreMLRuntime.swift:testName`
(not `test:full/coreml/tests/agent/<File>Tests.swift#testName`). The host gate
still compiles `CoreMLRuntime.swift`; focused evidence now lives in
top-level synchronous `func test*()` functions under `tests/agent/*Tests.swift`.

| | implemented | declared | deferred | unavailable | not-applicable | nondeferred |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Before (`b9242bf8`) | 758 | 185 | 149 | 16 | 578 | 943 |
| After evidence repair | 633 | 311 | 148 | 16 | 578 | 944 |

Rows without a focused test were reclassified to `declared` with
`source:full/coreml/<file>.swift#Symbol` (or left `deferred` when there is no
source anchor, e.g. `MLTensor.PaddingMode`). Enum / option-set / error-code
raw values share `testEnumAndConstantRawValues`. No other test is cited by more
than 40% of implemented rows.

Top-5 implemented evidence distribution (633 implemented):

1. `CoreMLEnumTests.swift#testEnumAndConstantRawValues` — 128 (20.2%)
2. `MLShapedArrayTests.swift#testShapedArrayConcatConvertAndSlice` — 69 (10.9%)
3. `MLDescriptionTests.swift#testConstraintsAndFeatureDescription` — 47 (7.4%)
4. `MLConfigurationTests.swift#testParameterMetricAndMetadataKeys` — 34 (5.4%)
5. `MLModelStructureTests.swift#testModelStructureConstruction` — 31 (4.9%)

Gate markers from `bash full/coreml/tests/acceptance/test_host.sh` (Linux host,
no docker):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREML_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreML dylib=libCoreML.dylib
```

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass on the existing Linux container. First-pass sources and
tests stay; this pass adds a real CPU `MLTensor` surface, GLM linear
prediction, compiled `metadata.plist` load, `MLWritable.write(to:)`, and
fail-closed `MLUpdateContext.model` / `MLModelCollection`.

| | implemented | declared | deferred | unavailable | not-applicable | nondeferred |
| --- | ---: | ---: | ---: | ---: | ---: | ---: |
| Before (wave 8 start / evidence repair) | 633 | 311 | 148 | 16 | 578 | 944 |
| After wave 8 (`f38a68e0`) | 884 | 208 | 0 | 16 | 578 | 1092 |
| After NA reclass (merge refusal) | 886 | 208 | 576 | 16 | 0 | 1094 |

The operator refused `f38a68e0` because **578 `not-applicable` rows were not
SwiftUI cross-import overlays** (they were `::SYNTHESIZED::` Swift integer
stdlib operators on `Int`/`Int8`/`Int16`/`Int32`/`UInt8`/`UInt16`/`UInt32`).
Those IDs are now `deferred` (stdlib behavior, not a CoreML-owned API) except
`Int8.multiArrayDataType` and `Int32.multiArrayDataType`, which are CoreML
overlay witnesses and cite
`MLShapedArrayTests.swift#testShapedArrayScalarsAndTransforms`. This graph has
no `s:7SwiftUI…` overlay IDs, so `not-applicable` is 0.

Unavailable rows name Apple Metal GPU / `CVPixelBuffer` hardware (no Linux
daemon or entitlement fallback). Neural-network / MIL inference remains
fail-closed (`.generic`, message `neural network layers not implemented`) except
the tiny Identity / DictVectorizer / Pipeline / GLM linear interpreters.

Top-5 implemented evidence distribution (886 implemented):

1. `CoreMLEnumTests.swift#testEnumAndConstantRawValues` — 128 (14.4%)
2. `MLTensorTests.swift#testTensorShapeOpsAndEnums` — 71 (8.0%)
3. `MLShapedArrayTests.swift#testShapedArrayConcatConvertAndSlice` — 69 (7.8%)
4. `MLTensorTests.swift#testTensorReductionsAndElementwise` — 63 (7.1%)
5. `MLDescriptionTests.swift#testConstraintsAndFeatureDescription` — 47 (5.3%)

No non-enum test is cited by more than 40% of implemented rows. Every
`implemented` citation is `test:full/coreml/tests/agent/<File>Tests.swift#testName`.
Remaining `declared` rows are Collection/StringProcessing witnesses, unused
tensor subscript arities, or types without a focused assertion.

Gate markers from `bash full/coreml/tests/acceptance/test_host.sh` (Linux host,
no docker):

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_REFERENCE_OK
COREML_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreML dylib=libCoreML.dylib
```

### Wave 8 collection-depth extension

This continuation converts the remaining behaviorally complete shaped-array
collection witnesses from declaration-only coverage to focused runtime evidence.
It exercises read algorithms (search, ranges, differences, reductions,
flattening, ordering, random selection, and shuffling) and mutating algorithms
(swapping, reversing, sorting, partitioning, and end removal) on concrete
`MLShapedArray` and `MLShapedArraySlice` values. No inference or Apple-service
boundary was broadened.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before this continuation | 886 | 208 | 576 | 16 | 0 |
| After this continuation | 966 | 128 | 576 | 16 | 0 |

Top-5 implemented evidence distribution (966 implemented):

1. `CoreMLEnumTests.swift#testEnumAndConstantRawValues` — 128 (13.3%)
2. `MLTensorTests.swift#testTensorShapeOpsAndEnums` — 71 (7.3%)
3. `MLShapedArrayTests.swift#testShapedArrayConcatConvertAndSlice` — 69 (7.1%)
4. `MLShapedArrayAlgorithmsTests.swift#testShapedArrayAdvancedReadAlgorithms` — 64 (6.6%)
5. `MLTensorTests.swift#testTensorReductionsAndElementwise` — 63 (6.5%)

The unavailable ledger remains limited to APIs requiring Apple Metal GPU or
`CVPixelBuffer` hardware, with the hardware/daemon boundary named per row.
Neural-network and MIL execution, model collections, and update services remain
fail-closed where the Linux port has no compatible backend or Apple service.

Passing the isolated host gate is not integrated Linux success. Telegram's
generated `AgeNet` / `U2netp` wrappers can type-check and can run only if
the compiled artifact is an Identity / DictVectorizer / pipeline of those.

### Wave 8 declared-surface exhaustion

This continuation exhausts the 128 remaining declaration-only rows with
focused runtime evidence. In particular, a concrete `MLCustomModel` now tests
both initializer spellings, direct prediction, and the protocol extension's
default batch prediction. Existing focused tests already exercised the model,
description, provider, feature-value, multi-array, shaped-array protocol,
tensor-literal/slicing, and inherited Collection witnesses; their ledger rows
now cite those exact synchronous tests rather than source declarations.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before this continuation | 966 | 128 | 576 | 16 | 0 |
| After this continuation | 1094 | 0 | 576 | 16 | 0 |

Top-5 implemented evidence distribution (1,094 implemented):

1. `CoreMLEnumTests.swift#testEnumAndConstantRawValues` — 128 (11.7%)
2. `MLShapedArrayAlgorithmsTests.swift#testShapedArrayAdvancedReadAlgorithms` — 98 (9.0%)
3. `MLShapedArrayTests.swift#testShapedArrayConcatConvertAndSlice` — 84 (7.7%)
4. `MLTensorTests.swift#testTensorShapeOpsAndEnums` — 78 (7.1%)
5. `MLTensorTests.swift#testTensorReductionsAndElementwise` — 63 (5.8%)

That continuation implemented all 128 then-remaining CoreML-owned declarations.
At that point, 576 synthesized Swift standard-library integer witnesses still
needed concrete behavioral evidence; the later synthesized-scalar continuation
below supplies it. The 16 unavailable rows continue to state their Apple Metal
/ pixel-buffer hardware boundary explicitly. No fail-closed inference or
Apple-service boundary was broadened.

### Wave 8 synthesized-scalar exhaustion

This continuation exhausts the final 576 deferred graph rows. These rows are
all synthesized Swift standard-library witnesses attached to the integer
scalar types that CoreML shaped arrays accept (`Int`, `Int8`, `Int16`, `Int32`,
`UInt8`, `UInt16`, and `UInt32`). Focused synchronous runtime tests now invoke
their concrete comparison/range, arithmetic/overflow, bitwise/shift,
conversion, endian/property, stride, random-range, formatting, and parsing
overloads after importing CoreML. The coverage ledger therefore records tested
behavior rather than treating these graph-emitted identifiers as declarations
or as non-CoreML deferrals.

| | implemented | declared | deferred | unavailable | not-applicable |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before this continuation | 1,094 | 0 | 576 | 16 | 0 |
| After this continuation | 1,670 | 0 | 0 | 16 | 0 |

Top-5 implemented evidence distribution (1,670 implemented):

1. `IntegerOverlayTests.swift#testIntegerOverlayComparisonsAndRanges` — 140 (8.4%)
2. `CoreMLEnumTests.swift#testEnumAndConstantRawValues` — 128 (7.7%)
3. `IntegerOverlayTests.swift#testIntegerOverlayBitwiseAndShifts` — 112 (6.7%)
4. `MLShapedArrayAlgorithmsTests.swift#testShapedArrayAdvancedReadAlgorithms` — 98 (5.9%)
5. `IntegerOverlayTests.swift#testIntegerOverlayArithmeticAndOverflow` — 85 (5.1%)

All non-overlay families in the pinned graph are now either implemented with
focused evidence or explicitly unavailable. The 16 unavailable rows continue
to name the Apple Metal GPU / `CVPixelBuffer` hardware boundary and the absence
of a Linux daemon or entitlement fallback. This evidence improvement does not
broaden inference: unsupported neural-network and MIL execution, model update
services, model collections, and Apple compilation remain fail-closed.
