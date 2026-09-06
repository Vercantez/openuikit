# MetalPerformanceShadersGraph (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`MetalPerformanceShadersGraph` overlay, seeded from the pinned Xcode 26.1
iPhoneOS symbol graph. It is not wired into the shared guest package; that
integration is a separate central review step.

## What is real

- Public enums, option sets, and handler typealiases with documented raw
  values (`MPSGraphOptions.default` is `.synchronizeResults`, NMS `explicit`
  is C `CornersHeightFirst` / raw 0, `MPSGraphLossReductionType.axis` aliases
  `.none`).
- Host graph IR: placeholders, constants, variables, assign/read, control
  flow (`if` / `for` / `while` invoke their blocks at construction), and
  compile to `MPSGraphExecutable`.
- Host `MPSGraphTensorData` buffers and CPU `run` / `runAsync` for arithmetic,
  comparisons, logical ops, unaries, activations, reshape/broadcast/concat,
  reductions, softmax, 2-D matmul, and bitwise ops.
- Convolution, pooling, RNN, FFT, resize, quantize, scatter/gather, and
  related ops record graph tensors with the public signatures. CPU eval is
  only claimed where a numeric path exists.
- Descriptor objects keep documented defaults (strides 1, NCHW/OIHW layouts,
  LSTM tanh/sigmoid gates, GRU `resetAfter == true`).

`MPSDataType` is a local bridging enum matching the documented MPS bit-field.
Replace it with `MetalPerformanceShaders.MPSDataType` at guest integration.

## Fail-closed boundaries

Metal/MPS-typed APIs (`MTLDevice`, `MTLCommandQueue`, `MTLBuffer`,
`MTLSharedEvent`, `MPSCommandBuffer`, `MPSImage` / `MPSMatrix` / `MPSNDArray`
/ `MPSVector`) are **deferred**: the isolated host gate has no Metal module,
and this port does not invent public stand-ins.

`MPSGraphDevice.type` is always `.metal` (the only enumerator).
`hostDevice()` is a Linux helper, not a GPU.

Package load (`init(package:)`, Core ML package inits) and
`serialize(package:)` record `MPSGraphHostBoundary` and do not produce a
runnable Apple executable. GPU-only ops omitted from CPU eval leave those
targets out of `run` results instead of filling zeros.

`runAsync` without Metal runs CPU eval then invokes scheduled/completion
handlers inline so tests can return without a run loop. Queue/timing remains
an oracle question.

## Tests

Focused `tests/agent/*Tests.swift` probes are the coverage evidence for
`implemented` rows. `MetalPerformanceShadersGraphLoadSmoke.swift` only prints
the sealed runtime marker. `MetalPerformanceShadersGraphDependencyIdentity.swift`
imports Foundation and Metal for a future clean EC2 client.

Run:

```sh
bash tests/acceptance/test_host.sh
```

## Depth pass 2026-09

Coverage after this pass: **842 implemented / 0 declared / 35 deferred /
0 unavailable / 0 not-applicable**.

Top-5 `implemented` evidence distribution:

| citations | share | evidence |
| ---: | ---: | --- |
| 116 | 13.8% | `MPSGraphTypesTests.swift#testEnumRawValues` (enum/option-set members; shared table-driven test) |
| 38 | 4.5% | `MPSGraphNNTests.swift#testResizeQuantizeNormalize` |
| 33 | 3.9% | `MPSGraphNNTests.swift#testSortGatherScatter` |
| 24 | 2.9% | `MPSGraphNNTests.swift#testConvolutionConstruction` |
| 23 | 2.7% | `MPSGraphShapeTests.swift#testReductionsAndSoftmax` |

No non-enum/option-set test cites more than 40% of the remaining implemented
rows (next highest is resize/quantize/normalize at 5.2% of remaining).
