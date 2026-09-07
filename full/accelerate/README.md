# Accelerate

Linux starting point for Apple's public `Accelerate` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. This directory is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

Host-compiled sources import **Foundation only**. The existing C
`vImageBoxConvolve_ARGB8888` implementation in `Accelerate.c` is kept for the
guest/C oracle; the host gate compiles the Swift port in
`AccelerateVImageBoxConvolve.swift`.

## What is real

Portable Swift implementations exercised by `tests/agent/*Tests.swift`:

- `vImageBoxConvolve_ARGB8888` with `kvImageEdgeExtend`, matching
  `tests/accelerate-box-convolve-apple-2026-09-01.txt` (pixels and the even-kernel /
  missing-edge / ROI error codes from that transcript plus `Accelerate.h`)
- vDSP vector/matrix arithmetic, statistics, windowing, convolution, conversions,
  and radix-2 FFT/DFT (packed layouts; FFT cross-checked against a direct DFT)
- vForce elementwise math for `Float`/`Double` via Foundation/`FloatingPoint`
- BLAS level 1–3 (`saxpy_`/`daxpy_`, `sgemm_`/`dgemm_`, CBLAS enumerators) and
  LAPACK `sgesv_`/`dgesv_`/`sgels_`/`sposv_`/`sgetrf_` via reference algorithms
- vImage buffer geometry, scaling, histogram, alpha compositing, and
  `PixelBuffer` operations on the documented planar/interleaved formats
- BNNS filter creation returns `nil` (fail-closed; no BNNS runtime on Linux);
  packed-float `BNNSCopy` / `BNNSClipByValue` / `BNNSCompareTensor` / `BNNSMatMul`
  / `BNNSTranspose` / `BNNSTile` run on host arrays
- Sparse CSC convert/multiply and Float/Double `SparseFactor`/`SparseSolve`
  via dense Gaussian elimination (not Apple sparse factorizations)
- Linear Algebra `la_*` dense Float/Double matrices (sum/product/transpose/solve/norms)
- SparseBLAS `sparse_*` COO Float/Double create/multiply/extract/solve; complex constructors stay `nil`
- BNNS overlay `Shape`/`DataLayout.rank`, unary/binary arithmetic layers on packed float,
  plus `BNNS.copy`/`clip`/`gather`/`transpose` and `vDSP.Biquad`

`libAccelerate.dylib` compiles with `-warnings-as-errors`.

Most remaining C entry points are **declared** source-compatible stubs: vImage
helpers that need Apple services return `kvImageInvalidParameter`, BNNS
constructors return `nil`, and Linear Algebra objects are inert
`_OpenUIKitLAObject` values unless a Linux numeric path is implemented. Those stubs are not Apple behavior.

## Fail-closed boundaries

- BNNS graph compile/execute has no Linux provider. `BNNSGraph.makeContext`
  throws `.unableToCreateContext`. Graph C execute/get APIs return
  `BNNSLinuxFailClosedStatus` (`-1`). Filter create APIs return `nil`.
- BNNS apply/backward APIs that need a BNNS runtime return
  `BNNSLinuxFailClosedStatus` rather than `0`. Packed-float `BNNSCopy`,
  `BNNSClipByValue`, `BNNSCompareTensor`, `BNNSMatMul`, `BNNSTranspose`, and
  `BNNSTile` are implemented on Linux.
- Complex sparse multiply/factor/solve stay empty or return
  `SparseIterativeParameterError`. Float/Double sparse iterative and
  factorization solve use dense Gaussian elimination on the CSC clone.
  SparseBLAS `sparse_*_complex` constructors return `nil` and ops return
  status `-1` (not the sequential `SPARSE_*` placeholders).
- vImage APIs that take `CGImage`, `CGColorSpace`, `CVPixelBuffer`, or
  `CGAffineTransform` are **deferred**: those types are not declared
  dependencies, and this lane does not introduce public lookalikes.
- Enumerators without a pinned numeric binding (Apple header, macios
  annotation, or standard CBLAS) use sequential placeholders and stay
  `declared`, never `implemented`.
- Affine warp without a usable transform returns `kvImageInvalidParameter`.
- Planar8/ARGB8888 affine identity, nearest/bilinear scale, centre rotate, channel permute, and tent convolve (edge-extend) are implemented on small rasters; remaining packed formats stay fail-closed.

## Deferred

Sparse subfactor objects, complex sparse factor/solve, BNNS Apply success,
CoreGraphics/CoreVideo conversion, and overlay properties that
`preconditionFailure` remain deferred until an Apple-runtime oracle or a real
Linux implementation exists.

## Tests

- `tests/agent/AccelerateLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/AccelerateTests.swift` — focused `test*` probes (no stdout)
- `tests/agent/AccelerateDependencyIdentity.swift` — Foundation `Data` through public APIs
- `tests/agent/AccelerateRuntime.swift` — optional schema-v1-style probe (not host-compiled)
- `tests/AccelerateGuestRuntime.swift` — existing C/guest box-convolve oracle
- Family tests under `tests/agent/` for vDSP, vForce, BLAS/LAPACK, vImage, and enums

## Depth pass 2026-09

Depth pass for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs.

- Implemented before: **26**
- Implemented after: **2534**
- Declared: 2901
- Deferred: 1421

Top-5 evidence distribution (share of remaining implemented rows = 2534 − 26):

1. `testBNNSEnumCases` — 312 (12.4%) — table-driven BNNS/vImage/Quadrature enum cases
2. `testPixelBufferOps` — 202 (8.1%) — `vImage.PixelBuffer` storage, geometry, and ops
3. `testVImageErrorAndOptions` — 99 (3.9%) — documented `kvImage*` / `vImage.Options` / format properties
4. `testCStructFields7` — 72 (2.9%) — C struct field reads
5. `testCStructFields5` — 70 (2.8%) — C struct field reads

No non-enum/constant test exceeds the 40% remaining-row bulk-relabel ceiling.

## Depth pass 2026-09 (wave 8, r16)

Next depth pass for campaign `ios26.1-fwdepth-r16`, lane `medium-full`, 6856 exact IDs. Earlier passes in this tree stay green (quadrature, CSC multiply, BLAS/LAPACK, vImage affine/rotate/tent). This pass adds packed-float BNNS tensor ops (`BNNSCopy` / `ClipByValue` / `CompareTensor` / `MatMul` / `Transpose` / `Tile`), fail-closed BNNS apply/graph execute (`BNNSLinuxFailClosedStatus = -1`), overlay `Equatable`/`Hashable` for BNNS/vDSP/vImage/BNNSGraph enums plus `BNNSGraph.CompileOptions` and `BLAS.threadingModel`, and Float/Double `SparseFactor` + `SparseSolve` via dense Gaussian elimination (including ApplyOperator column reconstruction). Complex sparse factor/solve stays parameter-error fail-closed.

- Implemented before: **2605**
- Implemented after: **3181**
- Declared: 2425 (was 2837)
- Deferred: 1250 (was 1414)
- Unavailable: 0
- Not-applicable: 0

Top-5 evidence distribution (share of remaining implemented rows = 3181 − 2605 = 576):

1. `testOverlayHashableBNNS0` — 56 (9.7%) — overlay BNNS enum `==`/`!=`/`hash`
2. `testOverlayHashableBNNSGraph` — 51 (8.9%) — BNNSGraph builder/compile-option `Hashable` plus `CompileOptions` fields
3. `testCEnumHashableBNNS0` — 51 (8.9%) — table-driven C BNNS enum `Hashable`/`!=`
4. `testCEnumHashableBNNS1` — 51 (8.9%) — table-driven C BNNS enum `Hashable`/`!=`
5. `testCEnumHashableSparse` — 48 (8.3%) — table-driven Sparse C enum `Hashable`/`!=`

No non-enum/constant test exceeds the 40% remaining-row bulk-relabel ceiling (largest overlay hash test is 56/576 = 9.7%). Enum/C-constant table-driven tests share one function per family as allowed. BNNS create stays fail-closed (`nil`). SwiftUI overlay IDs were not present. `s:s17FixedWidthI*` / Foundation `formatted` witnesses stay deferred (stdlib/Foundation, not this lane). vImage CV/CG stays deferred (no CoreVideo/CoreGraphics dependency).

Sealed gate (`bash full/accelerate/tests/acceptance/test_host.sh`) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Accelerate lane=medium-full symbols=6856
FRAMEWORK_FANOUT_REFERENCE_OK
ACCELERATE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Accelerate dylib=libAccelerate.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree. Starting commit `2de7152a12f3beb34a4c1e92dc0e849af9a1d88b` matched.

## Depth pass 2026-09 (wave 18, local repair)

Next depth pass for campaign `ios26.1-fwdepth-r18`, lane `medium-full`, 6856 exact IDs. Keeps earlier passes green and adds real Linear Algebra `la_*`, SparseBLAS `sparse_*` (Float/Double COO; complex fail-closed), BNNS overlay `Shape`/`DataLayout.rank`/arithmetic layers, packed-float `BNNS.gather`, and `vDSP.Biquad`.

- Implemented before: **3181**
- Implemented after: **3359**
- Declared: 2242 (was 2425 on main; 2247 on the refused cloud head)
- Deferred: 1252 (was 1250)
- Unavailable: 0
- Not-applicable: 3 (compiler-synthesized standard-library `zero` witnesses)

Top-5 evidence distribution (share of remaining implemented rows = 3359 − 3181 = 178):

1. `testSparseLegacyComplexFailClosed` — 36 (20.2%) — SparseBLAS complex constructors/`nil` and status `-1`
2. `testSparseLegacyFloatCreateMultiply` — 20 (11.2%) — COO create/insert/multiply/trace/norms
3. `testSparseLegacyExtractBlockSolve` — 18 (10.1%) — block extract and triangular solve
4. `testSparseLegacyVectorPackInner` — 14 (7.9%) — packed sparse vectors and inner products
5. `testSparseLegacyDoubleCreateMultiply` — 12 (6.7%) — Double COO insert/multiply
   (tied with `testBNNSShapeRankSizeStride` — 12)

No non-enum/constant test exceeds the 40% remaining-row bulk-relabel ceiling (largest is 36/178 = 20.2%). Sequential `LA_*` / `SPARSE_SUCCESS` macros stay `declared`. vImage CV/CG stays deferred. SwiftUI overlay IDs were not present. Starting commit `39dc25a2769fb88a50f0853964137a4f96d50322`.

### Local repair evidence

Merged current `origin/main` (`58292232`) into cloud head `291a1448` on
`agent/fw-accelerate-r`; no conflicts, and the delta against main is confined to
`full/accelerate/`. All **3181** implemented rows from main remain implemented;
the depth pass adds **178**, for **3359** total across **147** synchronous,
no-argument cited tests. The largest test accounts for 311/3359 rows (9.3%);
the largest non-table test accounts for 202/3359 (6.0%). Among the 178 added
rows, the largest test remains 36/178 (20.2%).

The operator log `/tmp/fw_merge_gate-accelerate.log` and the reproduced baseline
`/tmp/fw-accelerate-r-baseline.log` rejected five missing declaration anchors:
coverage lines 5650, 5800, 6802, 6806, and 6810. `BNNSLayerData.zero` and
`BNNSFilterParameters.deallocator` are absent, so they are now deferred rather
than backed by unrelated source tokens. The three `::SYNTHESIZED::` witnesses
for `Int.zero`, `Int64.zero`, and `UInt64.zero` are not applicable to this
framework. No implemented row was downgraded.

The Linux warnings-as-errors test compile also exposed mutable BNNS descriptors
that are only read. The tests now bind descriptors immutably inside nested
`withUnsafeMutableBufferPointer` scopes so their array pointers remain valid
throughout each operation. The sparse packed-vector test expected 180 for
`[2, 4]` at indices `[1, 3]` dotted with `[10, 20, 30, 40]`; its independently
computed expectation is **200** (`2 * 20 + 4 * 40`). The numeric implementation
is unchanged by the local repair.

Validation in the operator's `uikit-linux` container (Swift 6.2.4,
`aarch64-unknown-linux-gnu`):

- Sealed gate: **PASS**, log `/tmp/fw-accelerate-r-gate.log`; baseline was five
  missing-anchor errors. Both library and all agent tests compile with
  `-warnings-as-errors`.
- All **147/147** cited tests pass together and separately in fresh processes
  (10-second per-test timeout); log `/tmp/fw-accelerate-r-isolated.log` ends
  `ISOLATED_TESTS_OK count=147`. No test blocks.
- Immutable reference/acceptance hashes match; no `.build`, `build`, or `scratch`
  directory exists in the framework. No sealed files or shared gate code changed.

The sealed command was `timeout 3600 bash full/accelerate/tests/acceptance/test_host.sh`
from `/gate-codex-accelerate`, after copying the framework and shared gate inputs
into the operator container and initializing its Git snapshot. It ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Accelerate lane=medium-full symbols=6856
FRAMEWORK_FANOUT_REFERENCE_OK
ACCELERATE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Accelerate dylib=libAccelerate.dylib
```

## Depth pass 2026-09 (wave 8)

This pass extends the real Linux surface without changing prior numerics. It validates the
SDK-pinned raw values of 237 BNNS constants (activation, arithmetic, layouts, data types,
graph controls, optimization, padding, pooling, quantization, reduction, and related
families) and 83 vImage constants (rotation, buffer typing, conversion, gamma, and pixel
format families). The tests compare every named identifier to its pinned numeric
construction; they are not load, declaration, or identity-only probes.

- Implemented before: **3359**
- Implemented after: **3679**
- Declared before: **2242**
- Declared after: **1922**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **320**

Top-5 evidence distribution for this pass (320 newly implemented rows):

1. `testBNNSPinnedConstantValues0` — 79 (24.7%)
2. `testBNNSPinnedConstantValues1` — 79 (24.7%)
3. `testBNNSPinnedConstantValues2` — 79 (24.7%)
4. `testVImagePinnedConstantValues0` — 42 (13.1%)
5. `testVImagePinnedConstantValues1` — 41 (12.8%)

The distribution uses the task's table-driven exception for enum, option-set, `k…`, and
`err…` constants. Each cited function is top-level, synchronous, and self-contained.
BNNS execution that has no implemented CPU numeric path remains explicitly fail-closed;
graph creation/execution does not fabricate Apple behavior. vImage APIs requiring
CoreGraphics or CoreVideo remain deferred because those modules are not dependencies.
Complex sparse solve/factor paths remain parameter-error fail-closed. Oracle questions
for unobserved Apple callback, graph, allocator, and image-framework behavior remain
recorded in `oracle-questions.tsv`.
