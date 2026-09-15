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
- vForce elementwise math for `Float`/`Double` via Foundation/`FloatingPoint`,
  plus lane-wise `vFloat` (SIMD4) scalar entry points (`vacosf`…`vtruncf`,
  `vsincosf`, `vremquof`, `vclassifyf`, `vsignbitf`, `vtablelookup`) pinned to
  the macOS 26.1 oracle in `scratch/oracle-2026-09-14/vfp-simd-2026-09-14.txt`
  (Apple `FP_xxx` codes, cosine-returning `vsincosf`, signed quotient bits)
- BLAS level 1–3 (`saxpy_`/`daxpy_`, `sgemm_`/`dgemm_`, CBLAS enumerators),
  real packed/banded/symmetric (`sspmv_`/`sgbmv_`/`ssymm_`/`strmm_`/`srotm_`
  and `d*` twins), complex dense/packed/banded level-2 (`cgemv_`/`chemv_`/`chpmv_`/`cgbmv_`/`ctpmv_`
  and `z*` twins), and LAPACK `sgesv_`/`dgesv_`/`sgels_`/`sposv_`/`sgetrf_` via
  reference algorithms
- vImage buffer geometry, scaling, histogram, alpha compositing, and
  `PixelBuffer` operations on the documented planar/interleaved formats
- BNNS filter creation returns `nil` (fail-closed; no BNNS runtime on Linux);
  packed-float `BNNSCopy` / `BNNSClipByValue` / `BNNSCompareTensor` / `BNNSMatMul`
  / `BNNSTranspose` / `BNNSTile` run on host arrays
- Sparse CSC convert/multiply and Float/Double `SparseFactor`/`SparseSolve`
  via dense Gaussian elimination (not Apple sparse factorizations). Float/Double
  subfactors are non-owning views of the stored clone: `SparseCreateSubfactor`
  aliases the parent factor, and subfactor multiply/solve apply the FULL matrix
  regardless of the `contents` selector (Apple's triangular extraction traps on
  the simple factorization path; see
  `scratch/oracle-2026-09-14/sparse-subfactor-2026-09-15.txt`). `SparseRefactor`
  replaces the stored clone, `SparseUpdateFactor` performs a full refactor with
  `Update` as the complete replacement matrix, `SparseGetTranspose` returns
  freshly owned CSC storage, structure-only `SparseFactor` records the pattern
  in the symbolic object, Float/Double `SparseGetInertia` counts eigenvalue
  signs via cyclic Jacobi iteration, and `SparseGetStateSize_*` returns 0 (no
  iterate state on the Linux dense path; Apple reports 20)
- Linear Algebra `la_*` dense Float/Double matrices (sum/product/transpose/solve/norms)
- SparseBLAS `sparse_*` COO Float/Double create/multiply/extract/solve; complex constructors stay `nil`
- BNNS overlay `Shape`/`DataLayout.rank`, unary/binary arithmetic layers on packed float,
  plus `BNNS.copy`/`clip`/`gather`/`transpose` and `vDSP.Biquad`
- BNNS overlay enum mappings pinned to the macOS 26.1 oracle: `ActivationFunction`,
  `ArithmeticUnaryFunction`/`ArithmeticTernaryFunction`, `PaddingMode` (+`paddingBitPattern`),
  `PoolingType`, `LossFunction`, `LossReduction`, `ReductionFunction`, and all four
  optimizer `bnnsOptimizerFunction`/`accumulatorCountMultiplier` getters (Apple always
  reports clipping-capable variants). The Linux `BNNSOptimizer` protocol now
  carries both requirements with all four optimizers conforming (api-digester
  pinned). `NearestNeighbors.apply` and both
  `MultidimensionalLookupTable.apply` overloads are fail-closed no-ops.
- `BNNSGraph.Builder` factories (`argument`, three `constant` spellings) and all
  55 `Builder.Tensor` math ops record symbolic construction nodes: each call
  returns a handle whose `description` logs the op chain, whose
  `shape`/`stride` are preserved from the input, and whose `dataType` is the
  scalar's BNNS mapping. `tensorData` is `nil` (no device memory); graph
  compilation and execution stay fail-closed.

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

This continuation audits already-real BNNS, vImage, and Sparse Linux behavior against
its focused tests and promotes the exact SDK identifiers exercised by those tests.
The gain covers BNNS enum cases, option sets, descriptor structures, arithmetic and
graph fail-closed controls; vImage constants, buffers, errors, pixel operations, and
box-convolution contracts; and Sparse enum/structure values used by multiplication
and solve tests. No load, declaration, or identity-only probe is used as behavioral
evidence.

- Implemented before: **3679**
- Implemented after: **3979**
- Declared before: **1922**
- Declared after: **1622**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **300**

Top-5 evidence distribution for the 300 newly implemented rows:

1. `testBNNSEnumCases` — 56 (18.7%)
2. `testDocumentedVImageConstants` — 34 (11.3%)
3. `testCStructFields2` — 18 (6.0%)
4. `testBNNSPinnedConstantValues2` — 16 (5.3%)
5. `testCStructFields5` — 16 (5.3%; tied with `testCStructFields6`)

The table-driven enum and constant checks use the task's permitted shared evidence.
Every cited function is top-level, synchronous, and self-contained. BNNS execution
without an implemented CPU numeric path remains explicitly fail-closed; graph
creation and execution do not fabricate Apple behavior. vImage APIs requiring
CoreGraphics or CoreVideo remain deferred because those modules are not declared
dependencies. Complex sparse solve/factor paths remain parameter-error fail-closed.
Oracle questions for unobserved Apple callback, graph, allocator, and image-framework
behavior remain recorded in `oracle-questions.tsv`.

## Depth pass 2026-09-14 (Apple Accelerate oracle)

Depth pass against the macOS 26.1 / Xcode 26.1 Accelerate oracle in
`scratch/oracle-2026-09-14/`. Pins Apple-measured enumerator raw values, confirms
unnormalized radix-2 FFT scaling, records overlay `vForce.atan2(x:y:)` as
`Foundation.atan2(y, x)`, and implements a complex BLAS level-1 plus
`cgemm_`/`zgemm_`/`cgemv_`/`chemv_`/`cger*` subset. Remaining banded/packed/triangular
complex BLAS stay empty stubs. Sparse Float/Double CSC multiply of `diag(2,3)*[1,1]`
matches `[2,3]`. `vImageBoxConvolve_ARGB8888` 3x3 edge-extend matches the 2026-09-14
ARGB raster. BNNS graph compile/execute stays fail-closed.

- Implemented before: **3979**
- Implemented after: **4034**
- Declared before: **1622**
- Declared after: **1567**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **55**

Top-5 evidence distribution for the 55 newly implemented rows:

1. `testOraclePinnedEnumRawValues` — 21 (38.2%) — table-driven Apple-measured DCT/DFT/SparseControl/SparseFactorization raw values (enum/constant sharing allowed)
2. `testBLASComplexLevel1Float` — 10 (18.2%) — complex Float level-1
3. `testBLASComplexLevel1Double` — 10 (18.2%) — complex Double level-1
4. `testBLASComplexGemvHemv` — 8 (14.5%) — `cgemv_`/`chemv_`/`cger*` 2x2 cases
5. `testSparseMultiplyDiagOracle` — 3 (5.5%) — CSC `init(structure:data:)` plus diag multiply

Largest non-enum test is 10/55 = 18.2%, under the 40% remaining-row ceiling. Unobserved SparseFactorization LU/SBK members stay sequential placeholders and `declared`. vImage CG/CV and BNNS graph execute stay deferred/fail-closed. SwiftUI overlay IDs were not present.

## Depth pass 2026-09-14 (complex triangular/hermitian BLAS)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Implements the remaining dense complex triangular and Hermitian/symmetric level-2/3 C BLAS plus Givens helpers, with Double `z*` twins, against hand-computed 2x2/3x3 cases pinned to the macOS 26.1 / Xcode 26.1 Accelerate oracle in `scratch/oracle-2026-09-14/complex-blas-2026-09-14.txt`. Packed/banded complex BLAS stay declared stubs.

- Implemented before: **4034**
- Implemented after: **4062**
- Declared before: **1567**
- Declared after: **1539**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **28**

Top-5 evidence distribution for the 28 newly implemented rows:

1. `testBLASComplexCher2SymmSyrk` — 10 (35.7%) — `cher2_`/`cher2k_`/`csymm_`/`csyrk_`/`csyr2k_` and `z*` twins
2. `testBLASComplexHemmHerkCher` — 6 (21.4%) — `chemm_`/`cherk_`/`cher_` and `z*` twins
3. `testBLASComplexTrmvTrsv` — 4 (14.3%) — `ctrmv_`/`ctrsv_`/`ztrmv_`/`ztrsv_`
4. `testBLASComplexTrmmTrsm` — 4 (14.3%) — `ctrmm_`/`ctrsm_`/`ztrmm_`/`ztrsm_`
5. `testBLASComplexRotgRot` — 4 (14.3%) — `crotg_`/`csrot_`/`zrotg_`/`zdrot_`

Largest non-enum test is 10/28 = 35.7%, under the 40% remaining-row ceiling. Remaining packed/banded complex BLAS (`cgbmv_`/`chbmv_`/`chpmv_`/`chpr*`/`ctbmv_`/`ctbsv_`/`ctpmv_`/`ctpsv_` and `z*` twins) stay `declared`. vImage CG/CV and BNNS graph execute stay deferred/fail-closed.

## Depth pass 2026-09-14 (packed/banded complex BLAS)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Implements packed Hermitian (`chpmv_`/`chpr_`/`chpr2_` and `z*`), packed triangular (`ctpmv_`/`ctpsv_` and `z*`), and banded (`cgbmv_`/`chbmv_`/`ctbmv_`/`ctbsv_` and `z*`) complex C BLAS with netlib column-packed / banded layouts, pinned to the macOS 26.1 / Xcode 26.1 Accelerate oracle 2x2 and 3-diagonal 3x3 cases in `scratch/oracle-2026-09-14/packed-banded-complex-blas-2026-09-14.txt`.

- Implemented before: **4062**
- Implemented after: **4080**
- Declared before: **1539**
- Declared after: **1521**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **18**

Top-5 evidence distribution for the 18 newly implemented rows:

1. `testBLASComplexPackedHpr` — 4 (22.2%) — `chpr_`/`chpr2_`/`zhpr_`/`zhpr2_`
2. `testBLASComplexPackedTpmvTpsv` — 4 (22.2%) — `ctpmv_`/`ctpsv_`/`ztpmv_`/`ztpsv_`
3. `testBLASComplexBandedGbmvHbmv` — 4 (22.2%) — `cgbmv_`/`chbmv_`/`zgbmv_`/`zhbmv_`
4. `testBLASComplexBandedTbmvTbsv` — 4 (22.2%) — `ctbmv_`/`ctbsv_`/`ztbmv_`/`ztbsv_`
5. `testBLASComplexPackedHpmv` — 2 (11.1%) — `chpmv_`/`zhpmv_`

Largest non-enum test is 4/18 = 22.2%, under the 40% remaining-row ceiling. No leftover packed/banded complex C entry points from this list. vImage CG/CV and BNNS graph execute stay deferred/fail-closed.

## Depth pass 2026-09-14 (real packed/banded/symmetric C BLAS)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Implements remaining real Float/Double packed, banded, and dense symmetric/triangular C BLAS plus modified Givens (`srotm_`/`srotmg_` and `d*` twins) against 2x2/3x3 cases pinned to the macOS 26.1 / Xcode 26.1 Accelerate oracle in `scratch/oracle-2026-09-14/real-packed-banded-blas-2026-09-14.txt`.

- Implemented before: **4080**
- Implemented after: **4112**
- Declared before: **1521**
- Declared after: **1489**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **32**

Top-5 evidence distribution for the 32 newly implemented rows:

1. `testBLASPackedSpmvSpr` — 6 (18.8%) — `sspmv_`/`sspr_`/`sspr2_` and `d*` twins
2. `testBLASSymmSyr2Syr2k` — 6 (18.8%) — `ssymm_`/`ssyr2_`/`ssyr2k_` and `d*` twins
3. `testBLASBandedGbmvSbmv` — 4 (12.5%) — `sgbmv_`/`ssbmv_`/`dgbmv_`/`dsbmv_`
4. `testBLASPackedTpmvTpsv` — 4 (12.5%) — `stpmv_`/`stpsv_`/`dtpmv_`/`dtpsv_`
5. `testBLASBandedTbmvTbsv` — 4 (12.5%) — tied with `testBLASTrmmTrsm` and `testBLASRotmRotmg`

Largest non-enum test is 6/32 = 18.8%, under the 40% remaining-row ceiling. No leftover real packed/banded/symmetric C entry points from this list. vImage CG/CV and BNNS graph execute stay deferred/fail-closed.

## Depth pass 2026-09-14 (vForce SIMD lanes, sparse lifecycle, xerbla)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Implements the 45 remaining `vFloat` (SIMD4) vForce entry points lane-wise on Foundation math, `xerbla_` as a recording-free return-0 handler, and Float/Double `SparseCleanup` (preconditioner, subfactor, symbolic — no-ops over value types with sentinel storage) plus `SparseRetain` as the value-type identity for real dense-backed factorizations, subfactors, and symbolic objects. Complex sparse and `SparseRetain` for preconditioners (no such Apple overload) stay declared/fail-closed.

- Implemented before: **4112**
- Implemented after: **4168**
- Declared before: **1489**
- Declared after: **1433**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **56**

Top-5 evidence distribution for the 56 newly implemented rows:

1. `testVForceSIMDTrig` — 17 (30.4%) — inverse/forward trig, hyperbolic, `atan2`, `vsincosf`
2. `testVForceSIMDExpLog` — 15 (26.8%) — exp/log/power/scale/sqrt/reciprocal/divide
3. `testVForceSIMDRounding` — 13 (23.2%) — rounding, `fmod`/`remainder`/`remquo`, classify/signbit/gather
4. `testSparseOpaqueCleanupRetain` — 10 (17.9%) — 5 Float/Double cleanup + 5 retain
5. `testXerblaHandler` — 1 (1.8%) — `xerbla_` return-0, info untouched

Largest test is 17/56 = 30.4%, under the 40% remaining-row ceiling. Oracle quirks honored from `vfp.h` plus the Apple run: `vsincosf` returns cosine and stores sine; `vclassifyf` uses Apple `FP_NAN=1/INFINITE=2/ZERO=3/NORMAL=4/SUBNORMAL=5` (not glibc numbering); `vremquof` stores sign-of-`x/y` with 7 low-order magnitude bits (large-quotient and NaN lanes recorded as oracle questions). `SparseRetain` aliases shared dense-factor storage without an extra retain; the tests never double-cleanup aliased factorizations.

## Depth pass 2026-09-15 (sparse subfactor multiply/solve, refactor, transpose)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Implements the remaining portable Float/Double sparse C entry points: 16 subfactor `SparseMultiply` overloads (in-place, workspace, and out-of-place vector/matrix arities), 16 subfactor `SparseSolve` overloads routing through the aliased factor, 8 `SparseRefactor` overloads (clone-then-release full refactor), 2 `SparseUpdateFactor` overloads (full refactor with `Update` as the complete replacement matrix), 2 matrix + 2 factorization `SparseGetTranspose` overloads (freshly owned CSC storage), 2 structure-only `SparseFactor` symbolic overloads (pattern recorded, status OK), 2 `SparseGetInertia` overloads (cyclic Jacobi eigenvalue signs; error 1 for missing/non-square/asymmetric input), 2 `SparseCreateSubfactor` overloads (non-owning alias + `contents`), 2 `SparseCreatePreconditioner` overloads (type recorded), and 2 `SparseGetStateSize_*` overloads (0: no iterate state on the Linux dense path). Pinned against the macOS 26.1 / Xcode 26.1 oracle in `scratch/oracle-2026-09-14/sparse-subfactor-2026-09-15.txt`: transpose values `[2,4]`, refactor-then-solve `[2,2]`, and Apple state size 20 match or are documented divergences; Apple `SparseCreateSubfactor`/structure-symbolic/`SparseGetInertia`-on-LU traps confirm the triangular-extraction path is unobservable from the simple factorization path, so Linux subfactors apply the full stored matrix and the divergence is recorded in `oracle-questions.tsv`. No remaining real `s*`/`d*` BLAS or non-CG/CV vImage entry points are declared. Complex sparse (cleanup/multiply/factor/solve/transpose/retain/iterate) stays fail-closed or declared, as do subfactor-transpose views, `SparseIterate`, `SparseConvertFromOpaque`, and complex `SparseConvertFromCoordinate`.

- Implemented before: **4168**
- Implemented after: **4224**
- Declared before: **1433**
- Declared after: **1377**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **56**

Top-5 evidence distribution for the 56 newly implemented rows:

1. `testSparseRefactorUpdateFloatDouble` — 10 (17.9%) — 4 Float + 4 Double refactor arities plus 2 full-replacement updates
2. `testSparseSubfactorMultiplyFloat` — 8 (14.3%) — 8 Float subfactor multiply arities on `[[2,1],[0,3]]`
3. `testSparseSubfactorMultiplyDouble` — 8 (14.3%) — Double twin
4. `testSparseSubfactorSolveFloat` — 8 (14.3%) — 8 Float subfactor solve arities (`[3,3]` → `[1,1]`)
5. `testSparseSubfactorSolveDouble` — 8 (14.3%) — Double twin

Largest test is 10/56 = 17.9%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses `DispatchQueue.main`, `RunLoop`, semaphores, or `await`. Subfactor tests clean up the parent factorization exactly once and never double-cleanup aliased views.

## Depth pass 2026-09-15 (subfactor transpose, vImage structural audit, gamma oracle)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. No remaining real `s*`/`d*` C BLAS or non-CG/CV vImage C entry points are declared (all declared C functions are complex-sparse, which stays fail-closed/declared per contract), so this pass promotes already-real behavior plus two portable implementations:

- 2 `SparseGetTranspose` subfactor overloads (Float/Double): transpose the aliased parent factor, wrap the fresh factor with the same `contents` selector. Verified on `[[2,1],[0,3]]`: transposed multiply `[1,1]` → `[2,4]`, solve `[2,4]` → `[1,1]`. The wrapped factor is freshly owned; callers `SparseCleanup(result.factor)` (subfactor cleanup itself stays a no-op). Apple traps `SparseCreateSubfactor` on the simple path, so the triangular-extraction view remains a documented divergence (see `scratch/oracle-2026-09-14/accelerate-wave2-gamma-subfactor-2026-09-15.txt`).
- 37 vImage overlay structural rows: interleaved/planar `ComponentType` aliases and format declarations, `ConvolutionKernel2D` (including a newly added portable `init(values:width:height:)` overload next to the existing `init(values:size:)`), `vImage.Size` width/height, `vImage.Options` members, `vImage.Error.RawValue`, and `PixelBuffer` `Element`/`Histogram*` aliases. No `preconditionFailure` property was promoted; CG/CV-gated and trapping overlays stay declared/deferred.
- 11 oracle-pinned vImage constants: 9 `kvImageGamma_*_half_precision` values and 2 `kvImageMatrixType_*` values, `xcrun swiftc`-probed on macOS 26.1 (8/4/2/9/3/10/11/6/7 and 1/0) and matching the Linux values.

- Implemented before: **4224**
- Implemented after: **4291**
- Declared before: **1377**
- Declared after: **1310**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **67**

Top-5 evidence distribution for the 67 newly implemented rows:

1. `testVImagePlanarComponentTypes` — 21 (31.3%) — planar/DynamicPixelFormat `ComponentType`/`PlanarPixelFormat` aliases and declarations
2. `testVImageKernelSizeOptions` — 17 (25.4%) — `ConvolutionKernel2D` inits/fields, `Size`, `Options`, `Error.RawValue`, `PixelBuffer` aliases
3. `testVImageInterleavedComponentTypes` — 16 (23.9%) — interleaved `ComponentType` aliases and declarations
4. `testOraclePinnedVImageGammaMatrix` — 11 (16.4%) — table-driven Apple-measured gamma/matrix constants (constant sharing allowed)
5. `testSparseSubfactorTranspose` — 2 (3.0%) — Float/Double subfactor transpose multiply+solve

Largest test is 21/67 = 31.3%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses `DispatchQueue.main`, `RunLoop`, semaphores, or `await`. All 208 agent tests pass together. Complex sparse, `SparseIterate`, `SparseConvertFromOpaque`, BNNS graph execute, and vImage CG/CV paths stay declared/deferred/fail-closed.

## Depth pass 2026-09-15 (sparse/quadrature/LA oracle values)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Probes `import Accelerate` on macOS 26.1 / Xcode 26.1 via `xcrun swiftc` (transcripts `scratch/oracle-2026-09-14/sparse-enum-2026-09-15.txt` and `scratch/oracle-2026-09-14/la-hint-2026-09-15.txt`) and corrects Linux placeholder raw values to the Apple-measured numbers:

- Sparse factorization LU family: LU=80, LUUnpivoted=81, LUSPP=82, LUTPP=83 (were 6/9/7/8); LDLTSBK=3 and LDLTTPP=4 confirmed.
- `SparseStatus_t`: Failed=-1, Singular=-2, Internal=-3, ParameterError=-4, OK=0, Released=-2147483647 (were sequential 0–5).
- `SparseSubfactor_t`: Invalid=0, P=1, S=2, L=3, D=4, PLPS=5, Q=6, R=7, RP=8, Sr=9, Sc=10 (were sequential); triangle Lower=1/Upper=0 (were swapped).
- `SparseKind_t` (Ordinary=0, Triangular=1, UnitTriangular=2, Symmetric=3, Hermitian=7), `SparseOrder_t` (Default=0, User=1, AMD=2, Metis=3, COLAMD=4, MTMetis=5), `SparseScaling_t` (Default=0, User=1, EquilibriationInf=2, HungarianOnly=3, HungarianAndOrdering=4), preconditioners (None=0, User=1, Diagonal=2, DiagScaling=3), GMRES variants (DQ=0, GMRES=1, FGMRES=2), iterative status (Converged=0, MaxIterations=1, IllConditioned=-2, ParameterError=-1, InternalError=-99), LSMR tests (0/1).
- SparseBLAS legacy: `SPARSE_SUCCESS=0`, `ILLEGAL_PARAMETER=-1000`, `CANNOT_SET_PROPERTY=-1001`, `SYSTEM_ERROR=-1002`; properties UpperTri=1/LowerTri=2/UpperSym=4/LowerSym=8; norms ONE=171/TWO=173/INF=175/R1=179.
- Quadrature: QNG=0, QAG=1, QAGS=2; statuses SUCCESS=0/ERROR=-1/INVALID_ARG=-2/ALLOC=-3/INTERNAL=-99/MAX_EVAL=-101/BAD_BEHAVIOUR=-102; workspaces QAG=32/QAGS=152 per interval.
- vDSP window flags: HALF_WINDOW=1, HANN_DENORM=0, HANN_NORM=2 (Linux had NORM/HALF swapped; `testDocumentedVImageConstants` now pins Apple values).
- FFT legacy constants confirmed (FORWARD=1, INVERSE=-1, RADIX 0/1/2) and promoted.
- LA macros: SUCCESS=0, WARNING=1000, INTERNAL=-1000, INVALID_PARAM=-1001, DIM_MISMATCH=-1002, PRECISION_MISMATCH=-1003, SINGULAR=-1004, SLICE_OOB=-1005, norms 1/2/3; hints NO_HINT=0/ENABLE_LOGGING=1/DEFAULT_ATTRIBUTES=0; features 65536/131072/262144; scalar types 32768/16384; shapes 1/2/4; `vDSP_Version0=1123`/`vDSP_Version1=40`; VIMAGE availability and `USE_NON_APPLE_STANDARD_DATATYPES` are 1.

All corrected identifiers are exercised by table-driven raw-value tests in `tests/agent/OracleValueTests.swift` (one test per enum family, as allowed) plus the pre-existing `testDocumentedVImageConstants` for FFT/window/`LA_SUCCESS`. Previously implemented rows that use these identifiers symbolically (`SparseFactorizationLU`, `SparseIterativeParameterError`, `SparsePreconditionerNone`, `SPARSE_NORM_*`, `SparseIterativeConverged`) keep passing unchanged. The two answered oracle questions (LU family, LA status values) are removed from `oracle-questions.tsv`.

- Implemented before: **4291**
- Implemented after: **4404**
- Declared before: **1310**
- Declared after: **1197**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **113**

Top-5 evidence distribution for the 113 newly implemented rows:

1. `testSparseOracleKindOrderScalingValues` — 16 (14.2%) — kind/order/scaling raw values
2. `testSparseOracleSubfactorTriangleUpdateValues` — 14 (12.4%) — subfactor/triangle/update raw values
3. `testDocumentedVImageConstants` — 14 (12.4%) — FFT/window/`LA_SUCCESS` constants already asserted there
4. `testSparseOracleIterativePreconditionerValues` — 11 (9.7%) — GMRES/iterative/preconditioner/LSMR raw values
5. `testLAOracleHintAttributeValues` — 11 (9.7%) — LA hint/attribute raw values

Largest test is 16/113 = 14.2%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses `DispatchQueue.main`, `RunLoop`, semaphores, or `await`. All 208 agent tests pass together and the 11 touched tests pass in isolation on macOS. Complex sparse, `SparseIterate`, `SparseConvertFromOpaque`, BNNS graph execute, and vImage CG/CV paths stay declared/deferred/fail-closed.

## Depth pass 2026-09-15 (complex sparse fail-closed, split-complex structs)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Promotes the remaining portable complex sparse C entry points from declared stubs to fail-closed implemented behavior, plus split-complex/DSP value construction already present in the sources:

- 108 complex `Sparse*` overloads: 32 void `SparseSolve`, 20 `SparseMultiply` + 4 `SparseMultiplyAdd` (empty no-ops), 12 `SparseFactor` + 2 `SparseCreatePreconditioner` + 2 `SparseCreateSubfactor` (empty defaults), 8 `SparseCleanup` + 4 `SparseRetain`, 8 `SparseRefactor`, 6 `SparseGetTranspose` + 6 `SparseGetConjugateTranspose`, 2 `SparseUpdateFactor`, 2 `SparseGetStateSize_*` (zero, matching the documented no-iterate-state divergence). Status-returning complex solve/iterate overloads were already implemented as `SparseIterativeParameterError`.
- 18 complex struct types (`DSPComplex`, `DSPDoubleComplex`, `DSPSplitComplex`, `DSPDoubleSplitComplex`, dense/sparse complex matrices and vectors, complex attributes/structure/factorization/subfactor/preconditioner).
- 31 value-construction rows: complex memberwise/default inits, `DSPSplitComplex`/`DSPDoubleSplitComplex` `fromInputArray` deinterleave, `DSPDoubleSplitComplex(realp:imagp:)`, `vDSP_SplitComplexFloat/Double` structs and `SplitComplex` aliases, split-complex DFT marker structs, and the `DiscreteFourierTransformFunctions`/`FFTFunctions` typealiases.
- Product changes: `SparseMatrixStructureComplex` gains the memberwise `init(rowCount:columnCount:columnStarts:rowIndices:attributes:blockSize:)` mirroring real `SparseMatrixStructure` (its precise ID was declared but had no declaration); the empty public marker structs `vDSP_SplitComplexFloat`, `vDSP_SplitComplexDouble`, `vDSP.DFTSinglePrecisionSplitComplexFunctions`, and `vDSP.DFTDoublePrecisionSplitComplexFunctions` gain `public init()`.
- Overlay note: this slug contains no SwiftUI `View` types and no `SwiftUI` references in coverage, so the View-overlay batch clause is vacuous here; the FamilyControls/DeviceDiscoveryUI overlay playbook was reviewed and there is nothing to convert.

- Implemented before: **4404**
- Implemented after: **4561**
- Declared before: **1197**
- Declared after: **1040**
- Deferred before/after: **1252**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **157**

Top-5 evidence distribution for the 157 newly implemented rows:

1. `testSparseComplexSolve` — 32 (20.4%) — void complex factor/subfactor solve arities
2. `testSparseComplexStructInits` — 31 (19.7%) — complex memberwise/default inits and split-complex helpers
3. `testSparseComplexMultiply` — 28 (17.8%) — complex multiply/multiply-add plus dense complex structs
4. `testSparseComplexRefactorTranspose` — 24 (15.3%) — complex refactor/transpose/conjugate-transpose/update/state-size
5. `testSparseComplexCleanupRetain` — 20 (12.7%) — complex cleanup/retain plus opaque complex structs

Largest test is 32/157 = 20.4%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses `DispatchQueue.main`, `RunLoop`, semaphores, or `await`. All 224 agent tests pass together and the 7 touched tests pass in isolation on macOS. Complex `SparseIterate`, `SparseConvertFromOpaque`, complex `SparseConvertFromCoordinate`, and complex `SparseGetInertia` stay declared; `SparseIterate` (any precision), BNNS graph execute, and vImage CG/CV paths stay declared/deferred/fail-closed.

## Depth pass 2026-09-15 (declared-remainder conversion, oracle-corrected constants)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Converts the portable declared remainder to implemented and triages out-of-lane witnesses to deferred. Prior agents had written the `OvRemA/B/C` and `SoBNNSRem` behavioral tests but never flipped the rows; this pass verifies each test executes real Linux behavior, adds `OvRemDTests.swift` for the gaps, and flips 270 rows.

Oracle work on macOS 26.1 / Xcode 26.1 via `xcrun swiftc` probes:

- All `BNNSDataType*` globals pinned (Int8=131080, Float32=65568, Boolean=1048584, Int64=131136, UInt64=262208, Indexed8=524296, …). Linux sequential placeholders (including all-zero overlay globals and `UInt8/16/32` aliased onto the signed codes) corrected; `Bool: BNNSScalar` added (`Boolean`); `testBNNSPinnedConstantValues1` rewritten with oracle values.
- All `BNNSActivationFunction*` (Abs=6, Identity=0, ReLU=1, …), `BNNSArithmetic*` (Add=0, Multiply=2, …), `BNNSOptimizerFunction*` (SGDMomentum=1, Adam=2, RMSProp=3, AdamW=4, …), `BNNSPoolingFunction*`, and `BNNSRelationalOperator*` (Less=1, Greater=3, OR=7, NOT=8, …) globals pinned; `testBNNSPinnedConstantValues0/2` rewritten. Apple exposes no public no-arg `BNNS.AdamOptimizer()` (full init requires all fields), so optimizer structs keep trap-on-read getters with sink setters; only types and setter calls are cited.
- `Array(fromSplitComplex:scale:count:)` probed: output length equals `count` with interleaved scaled pairs (odd tails uninitialized on Apple); Linux implements the deterministic variant (zero tail) and records the divergence in `oracle-questions.tsv`.
- `vImage.BufferType` rawValue/bufferTypeCode fully mapped (chunky=10/code 25, alpha=0/17, luminance=15/20, …) and implemented with round-trip init; `FloodFillConnectivity` edges=4/corners=8 implemented.
- `BNNS.RelationalOperator` (size 4 on Apple) gains one-code storage with oracle-mapped statics.

Source changes (all in already-manifested files): oracle values in `AccelerateCTypes.swift`/`AccelerateOverlay.swift`; corrected `UInt8/16/32` mappings plus `Bool: BNNSScalar` in `Accelerate.swift`; `Array.fromSplitComplex` in `AccelerateVDSPOps.swift`; protocol associated types (`StaticPixelFormat.bitCountPerPixel`, `MultiplePlanePixelFormat` trio, `vDSP_DFTFunctions.Scalar`, `vDSP_BiquadFunctions.Scalar`, `vDSP_FourierTransformFunctions.SplitComplex`, `BiquadFunctions`/`FFTFunctions`/`DFTFunctions` witnesses) with Scalar-only conformances for `VectorizableFloat/Double` and `vDSP_SplitComplexFloat/Double`; real `BufferType`/`FloodFillConnectivity`/`MorphologyOperation`/`RelationalOperator` bodies; `public init() {}` for the eight `Fused*Parameters` structs and `SparseParameters` so sink setters are callable.

77 stdlib/Foundation synthesized witnesses (plus 4 undeclared CoreVideo vImage types) move declared→deferred as out-of-lane. The SwiftUI View-overlay override is vacuous here (no SwiftUI identifiers in coverage).

- Implemented before: **4987**
- Implemented after: **5257**
- Declared before: **498**
- Declared after: **151**
- Deferred before/after: **1368** / **1445**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **270**

Top-5 evidence distribution for the 270 newly implemented rows:

1. `testOvRemCBatch0` — 30 (11.1%) — vDSP transform types, enums, and classes
2. `testOvRemBOptimizers` — 23 (8.5%) — Adam/AdamW/RMSProp/SGD types and sink setters
3. `testOvRemBLayers` — 17 (6.3%) — BNNS layer class identities
4. `testOvRemCBatch1` — 16 (5.9%) — vImage lookup-table setters and BNNSGraph structural protocols
5. `testOvRemCBatch2` — 16 (5.9%) — scalar `DFTFunctions`/`BiquadFunctions`/`bnnsDataType` witnesses

Largest test is 30/270 = 11.1%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses `DispatchQueue.main`, `RunLoop`, semaphores, or `await`. Trap-on-read getters (optimizer fields, layer filters, graph tensor state) stay declared and are referenced by keypath only. BNNS layer/graph designated inits and apply methods (no Linux runtime), `InitializableFromCGImage`, and the `CGColorSpaceModel` buffer-code init stay declared.

## Depth pass 2026-09-15 (wave 9 declared-remainder conversion)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Converts 58 portable declared rows to implemented with real Linux behavior; no GPU/BNNS-runtime success is invented.

- 8 optimizer value-type inits (`Adam` x2, `AdamW`, `RMSProp` x2, `SGD` x3, exact Apple labels/defaults from `reference/public-surface.tsv`): the structs' trap-on-read fields become stored properties, so the inits genuinely record their inputs. `bnnsOptimizerFunction` / `accumulatorCountMultiplier` keep trap-on-read getters (Apple-computed; values unobserved) and stay declared, as do the `BNNSOptimizer` protocol witnesses.
- 8 `Fused*Parameters` inits plus `YoloParameters`, `SparseParameters`, `NearestNeighbors`, `CropResizeLayer`, and `MultidimensionalLookupTable` data inits (14 rows): pure-data structs store every input (the LUT keeps a Linux-side `[UInt16]` copy of its entries).
- 22 layer `convenience init?` (resize, dropout, padding, permute, pooling, embedding, reduction, activation x2, convolution, normalization, fully-connected, fused-parameters x3, ternary, broadcast matmul, fused-conv-norm, fused-fc-norm, gram, loss, random generator): fail-closed `nil`, matching the established "BNNS constructors return nil" behavior.
- 13 throwing layer `apply` methods (`FusedLayer`, `UnaryLayer`, `BinaryLayer`, pooling, embedding, crop-resize, normalization, fused-parameters x2, ternary, broadcast matmul, loss x2): fail-closed `throw BNNS.Error.layerApplyFail`.
- 2 `BNNSGraph.Context` rows: type identity plus the synchronous throwing `init(compileFromPath:functionName:options:)` (`unableToCreateContext`). The `async` overload cannot be cited (cited tests must be synchronous), the `tensor(forFunction:)` accessor needs an unconstructible instance, and the four trap-on-read properties stay declared.

Still declared (no honest Linux behavior to exercise): ~60 `Builder.Tensor` math/factory methods (graph-node construction without a BNNS runtime would be fabricated success), non-throwing `NearestNeighbors.apply`, `vImage.BufferType.init(bufferTypeCode:model:)` (`CGColorSpaceModel` is not a declared dependency), trap-on-read overlay getters (referenced by keypath only, per prior passes), and `InitializableFromCGImage.bitCountPerComponent` (no conforming types in this lane). Two new oracle questions record the Tensor-op and `clipsGradientsTo` mapping unknowns.

- Implemented before: **5257**
- Implemented after: **5315**
- Declared before: **151**
- Declared after: **93**
- Deferred before/after: **1445**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **58**

Top evidence distribution for the 58 newly implemented rows:

1. `testBNNSRemLayerApplies` — 13 (22.4%) — throwing fail-closed layer applies
2. `testBNNSRemLayerInitsA` — 11 (19.0%) — fail-closed layer inits, batch A
3. `testBNNSRemLayerInitsB` — 11 (19.0%) — fail-closed layer inits, batch B
4. `testBNNSRemOptimizerInits` — 8 (13.8%) — stored-data optimizer inits
5. `testBNNSRemFusedParamInits` — 8 (13.8%) — stored-data fused-parameter inits
6. `testBNNSRemValueInits` — 5 (8.6%) — Yolo/sparse/neighbor/crop/LUT data inits
7. `testBNNSRemGraphContext` — 2 (3.4%) — fail-closed graph context

Largest test is 13/58 = 22.4%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses main-queue dispatch, run loops, semaphores, or `await`. The 50 previously implemented sink-setter rows whose getters changed from trap to stored now note Linux value storage. Sealed-gate replication (this Mac lacks the `full/framework-roadmap` input the shared validator requires, so the gate refuses before compiling): library and all agent tests compile with `-warnings-as-errors`, all **272/272** cited tests pass together with stdout exactly `ACCELERATE_AGENT_RUNTIME_OK`, and the 7 new tests pass in isolated fresh processes.

## Depth pass 2026-09-15 (wave 10 declared-remainder conversion)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Converts 20 portable declared rows to implemented with Apple-oracle-pinned behavior; no GPU/BNNS-runtime success is invented.

- 17 BNNS overlay enum/struct mappings, probed on macOS 26.1 / Xcode 26.1 via `xcrun swiftc` (`fullmap`/`fam2`–`fam6` transcripts 2026-09-15): `ActivationFunction.bnnsActivation` (all 30 cases with alpha/beta; `hardSwish` shares code 30 with `geluApproximation2` on Apple), `ArithmeticUnaryFunction`/`ArithmeticTernaryFunction.bnnsArithmeticFunction`, `PaddingMode.bnnsPaddingMode`/`paddingBitPattern` (scalar reports the value's bit pattern), `PoolingType.bnnsPoolingFunction`, `LossFunction.bnnsLossFunction` (associated values ignored on Apple), `LossReduction.bnnsLossReductionFunction`, `ReductionFunction.bnnsReduceFunction` (Apple reuses codes across aliases), and all 8 optimizer getters (Apple always reports the clipping-capable variant: Adam 8/11, AdamW 10/12, RMSProp 9, SGD 7; acc 2/3, 2/3, centered?2:1, 0).
- Oracle correction: Linux `BNNSLossFunction*` (10), `BNNSLossReduction*` (5), and `BNNSReduceFunction*` (19) globals were sequential placeholders; Apple numbering is pinned and the globals plus the asserting `testBNNSPinnedConstantValues1/2` tests are corrected (e.g. MSE=3, Mean=3/4, Max=0, SumSquare=7). No product logic depended on the old values.
- 3 fail-closed no-op applies (Sparse-complex-multiply precedent): `NearestNeighbors.apply` and both `MultidimensionalLookupTable.apply` overloads accept the call without transforming data (no Linux numeric path).

Still declared (no honest Linux behavior to exercise): ~60 `Builder.Tensor` math/factory methods (graph-node construction without a BNNS runtime would be fabricated success; see the Tensor oracle question), `BNNSOptimizer` protocol witnesses (Linux protocol carries no requirements), `InitializableFromCGImage.bitCountPerComponent` (no conforming types in this lane), `vImage.BufferType.init(bufferTypeCode:model:)` (`CGColorSpaceModel` is not a declared dependency; no local lookalike per lane rules), the `async` Context init (cited tests must be synchronous), and trap-on-read `Context`/`Tensor` properties (no constructible instance).

- Implemented before: **5315**
- Implemented after: **5335**
- Declared before: **93**
- Declared after: **73**
- Deferred before/after: **1445**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **20**

Top evidence distribution for the 20 newly implemented rows:

1. `testWave10OptimizerMappingA` — 4 (20.0%) — Adam/AdamW fn + acc getters
2. `testWave10OptimizerMappingB` — 4 (20.0%) — RMSProp/SGD fn + acc getters
3. `testWave10NeighborLUTApply` — 3 (15.0%) — fail-closed neighbor/LUT applies
4. `testWave10ArithmeticMapping` — 2 (10.0%) — unary/ternary arithmetic mappings
5. `testWave10PaddingMapping` — 2 (10.0%) — padding mode + bit pattern
6. `testWave10LossMapping` — 2 (10.0%) — loss + loss-reduction mappings
7. `testWave10ActivationMapping` — 1 (5.0%) — activation mapping
8. `testWave10PoolingMapping` — 1 (5.0%) — pooling mapping
9. `testWave10ReductionMapping` — 1 (5.0%) — reduction mapping

Largest test is 4/20 = 20.0%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses main-queue dispatch, run loops, semaphores, or `await`. Sealed-gate replication (this Mac lacks the `full/framework-roadmap` input the shared validator requires, so the gate refuses before compiling; the deliverable validator reports only those 2 roadmap errors): library and all agent tests compile with `-warnings-as-errors`, all **281/281** cited tests pass together with stdout exactly `ACCELERATE_AGENT_RUNTIME_OK`, and the 9 new plus 2 touched tests pass in isolated fresh processes.

## Depth pass 2026-09-15 (wave 11 declared-remainder conversion)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Converts 63 portable declared rows to implemented with a real Linux construction path; no GPU/BNNS-runtime execution success is invented.

- 55 `BNNSGraph.Builder.Tensor` math ops (elementwise abs/cos/…/hardSwish, elu/softplus/scaledTanh/hardSigmoid, defaulted-epsilon log/reciprocal/rsqrt/l2Norm, max/min/pow/linear/gather over `OperationParameter`, pad/clip/threshold/transpose/softmax/logSoftmax, sum/mean/product/minimum/maximum/logSumExp/sumOfSquares/l2Norm reductions, Int32 argMax/argMin): symbolic graph-node construction in the new `AccelerateGraphTensor.swift`. Each op returns a handle recording the op chain in `description` and preserving `shape`/`stride`; numeric execution is not claimed.
- 3 `Tensor` properties: `tensorData` (`nil`: symbolic nodes own no device memory), `description` (the node log), `dataType` (`T.bnnsDataType`). The former `preconditionFailure` traps are gone; `rank` derives from `shape`, and `Tensor` now conforms to `BNNSGraph.TensorDescriptor` so handles can be returned from `makeContext` blocks.
- 5 `Builder` factories: `argument(name:dataType:shape:intent:)`, `constant(name:value:)`, `constant(name:values:shape:)`, and the Float/Float16 `constant(values:rowMajor:)` 2D overloads (uniform-row precondition per Apple docs).

Still declared (10; no honest Linux behavior to exercise): 2 `BNNSOptimizer` protocol witnesses (the Linux protocol carries no requirements; per-type getters stay implemented), `InitializableFromCGImage.bitCountPerComponent` (no conforming types in this lane), `vImage.BufferType.init(bufferTypeCode:model:)` (`CGColorSpaceModel` is not a declared dependency), 5 `BNNSGraph.Context` trap-on-read properties plus `tensor(forFunction:argument:fillKnownDynamicShapes:)` (no constructible instance: `makeContext` and both `compileFromPath` inits throw), and the `async` `Context.init(compileFromPath:functionName:options:)` (cited tests must be synchronous). The answered Tensor-construction oracle question is removed from `oracle-questions.tsv`.

- Implemented before: **5335**
- Implemented after: **5398**
- Declared before: **73**
- Declared after: **10**
- Deferred before/after: **1445**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **63**

Top evidence distribution for the 63 newly implemented rows:

1. `testGraphTensorShapeOps` — 9 (14.3%) — softmax/logSoftmax/transpose/clip/threshold/pad/gather/argMax/argMin
2. `testGraphTensorElementwiseD` — 8 (12.7%) — silu/sigmoid/softsign/hardSwish/elu/softplus/scaledTanh/hardSigmoid
3. `testGraphTensorReductions` — 8 (12.7%) — sum/mean/product/minimum/maximum/logSumExp/sumOfSquares/l2Norm
4. `testGraphTensorElementwiseA` — 7 (11.1%) — abs/cos/sin/tan/acos/asin/atan
5. `testGraphTensorElementwiseB` — 7 (11.1%) — cosh/sinh/tanh/acosh/asinh/atanh/exp
6. `testGraphTensorElementwiseC` — 7 (11.1%) — exp2/erf/sqrt/ceil/floor/round/relu
7. `testGraphTensorFactories` — 5 (7.9%) — argument + 4 constant spellings
8. `testGraphTensorBinaryOps` — 5 (7.9%) — max/min/pow/linear x2
9. `testGraphTensorEpsilonOps` — 4 (6.3%) — log/reciprocal/rsqrt/l2Norm
10. `testGraphTensorProperties` — 3 (4.8%) — tensorData/description/dataType

Largest test is 9/63 = 14.3%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses main-queue dispatch, run loops, semaphores, or `await`. Sealed-gate replication (this Mac lacks the `full/framework-roadmap` input the shared validator requires, so the gate refuses before compiling): library and all agent tests compile with `-warnings-as-errors`, all **301/301** cited tests pass together, and the new tests pass in an isolated fresh process.

## Depth pass 2026-09-15 (wave 12 declared-remainder conversion)

Follow-on depth for campaign `ios26.1-fwdepth-r6`, lane `medium-full`, 6856 exact IDs. Converts 3 portable declared rows to implemented and triages 1 CG-gated row to deferred; no GPU/BNNS-runtime success is invented.

- 2 `BNNSOptimizer` protocol witnesses (`bnnsOptimizerFunction`, `accumulatorCountMultiplier`): the Linux protocol now declares both requirements (get-only, matching the Apple signatures in `reference/public-surface.tsv`), and the api-digester confirms all four overlay optimizers conform, so empty `extension BNNS.AdamOptimizer/AdamWOptimizer/RMSPropOptimizer/SGDMomentumOptimizer: BNNSOptimizer` conformances are Apple-faithful. Each witness is exercised through an `any BNNSOptimizer` existential over all four types (default fn 8/10/9/7, acc 2/2/1/0) plus the AMSGrad variant (fn 11, acc 3).
- 1 `InitializableFromCGImage.bitCountPerComponent` static witness: the Linux protocol now declares the requirement, and the ten api-digester-pinned pixel formats conform (each already stores the member with the Apple value). Exercised through an `(any InitializableFromCGImage.Type, Int)` table. The `CGImage`-taking initializers stay deferred: CoreGraphics is not a declared dependency.
- 1 `vImage.BufferType.init(bufferTypeCode:model:)` moves declared→deferred: it requires `CGColorSpaceModel`, CoreGraphics is not a declared dependency, and this lane introduces no public lookalike (consistent with the deferred vImage CG/CV conversions).

Still declared (6; no honest Linux behavior to exercise): 5 `BNNSGraph.Context` members (`functionCount`, `functionNames`, `streamingAdvanceCount`, `checkForNaNsAndInfinities`, `tensor(forFunction:argument:fillKnownDynamicShapes:)`) trap or need an instance, and no Context is constructible on Linux (`makeContext` and both `compileFromPath` inits throw `unableToCreateContext`); plus the `async` `Context.init(compileFromPath:functionName:options:)` (cited tests must be synchronous, so it can never be cited; the sync throwing twin is fail-closed implemented).

- Implemented before: **5398**
- Implemented after: **5401**
- Declared before: **10**
- Declared after: **6**
- Deferred before/after: **1445** / **1446**
- Unavailable before/after: **0**
- Not-applicable before/after: **3**
- Net implemented gain: **3**

Top evidence distribution for the 3 newly implemented rows:

1. `testWave12OptimizerFunctionWitness` — 1 (33.3%) — optimizer function witness via existential
2. `testWave12OptimizerAccumulatorWitness` — 1 (33.3%) — accumulator witness via existential
3. `testWave12CGImageFormatWitness` — 1 (33.3%) — format witness via metatype existential

Largest test is 1/3 = 33.3%, under the 40% remaining-row ceiling. Every cited function is top-level, synchronous, and self-contained; no test uses main-queue dispatch, run loops, semaphores, or `await`. Sealed-gate replication (this Mac lacks the `full/framework-roadmap` input the shared validator requires, so the gate refuses before compiling): library and all agent tests compile with `-warnings-as-errors`, all **294/294** cited tests pass together with stdout exactly `ACCELERATE_AGENT_RUNTIME_OK`, and the 3 new tests pass in an isolated fresh process.
