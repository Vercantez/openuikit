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
- BNNS filter creation returns `nil` (fail-closed; no BNNS runtime on Linux)

`libAccelerate.dylib` compiles with `-warnings-as-errors`.

Most remaining C entry points are **declared** source-compatible stubs: vImage
helpers that need Apple services return `kvImageInvalidParameter`, BNNS
constructors return `nil`, and Linear Algebra objects are inert
`_OpenUIKitLAObject` values. Those stubs are not Apple behavior.

## Fail-closed boundaries

- BNNS graph compile/execute, sparse solvers, and Quadrature callbacks have no
  Linux provider. Create APIs return `nil`; throwing overlay inits throw
  `AccelerateLinuxError.failClosed`. Apply APIs that return `0` are not treated
  as success and stay `declared`.
- vImage APIs that take `CGImage`, `CGColorSpace`, `CVPixelBuffer`, or
  `CGAffineTransform` are **deferred**: those types are not declared
  dependencies, and this lane does not introduce public lookalikes.
- Enumerators without a pinned numeric binding (Apple header, macios
  annotation, or standard CBLAS) use sequential placeholders and stay
  `declared`, never `implemented`.
- Affine warp without a usable transform returns `kvImageInvalidParameter`.
- Planar8/ARGB8888 affine identity, nearest/bilinear scale, centre rotate, channel permute, and tent convolve (edge-extend) are implemented on small rasters; remaining packed formats stay fail-closed.

## Deferred

Sparse factorization, BNNS Apply success, CoreGraphics/CoreVideo conversion,
and overlay properties that `preconditionFailure` remain deferred until an
Apple-runtime oracle or a real Linux implementation exists.

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

## Depth pass 2026-09 (wave 8)

Second depth pass for campaign `ios26.1-fwdepth-r15`, lane `medium-full`, 6856 exact IDs. The first-pass Linux sources and tests stay in tree; this pass adds real quadrature, sparse CSC multiply, extra BLAS/LAPACK, biquad DF2T, interleaved double DFT, and pixel-exact vImage affine/rotate/tent/permute.

- Implemented before: **2534**
- Implemented after: **2605**
- Declared: 2837 (was 2901)
- Deferred: 1414 (was 1421)
- Unavailable: 0
- Not-applicable: 0

Top-5 evidence distribution (share of remaining implemented rows = 2605 − 2534 = 71):

1. `testQuadratureOverlaySurface` — 19 (26.8%) — QAG points, adaptive integrators, Error `==`/`hash`/`localizedDescription`
2. `testSparseMultiplyDoubleAndMatrix` — 18 (25.4%) — CSC convert/multiply/add for Double plus Float/Double dense matrix
3. `testSparseMultiplyKnownMatrix` — 8 (11.3%) — Float CSC vector multiply/add/cleanup and `DenseVector_Float` init
4. `testBLASRotSymvTrsvSyrk` — 8 (11.3%) — `srot_`/`drot_`/`strsv_`/`dtrsv_`/`ssymv_`/`dsymv_`/`ssyrk_`/`dsyrk_`
5. `testBLASRotgSyrTrmv` — 6 (8.5%) — `srotg_`/`drotg_`/`ssyr_`/`dsyr_`/`strmv_`/`dtrmv_`

No non-enum/constant test exceeds the 40% remaining-row bulk-relabel ceiling. BNNS create stays fail-closed (`nil`). Complex sparse multiply, sparse subfactor/solve, and placeholder `QUADRATURE_*` C enumerator values stay declared or deferred.

Sealed gate (`bash full/accelerate/tests/acceptance/test_host.sh`) ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=Accelerate lane=medium-full symbols=6856
FRAMEWORK_FANOUT_REFERENCE_OK
ACCELERATE_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=Accelerate dylib=libAccelerate.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token. `.cursor/verify-cloud-environment.sh` on this snapshot fails earlier (`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` is Swift 6.2.4 / linux and the sealed gate compiled with a clean product tree. Starting commit `bff8535c68425cc39fb45cb00d447b0981b57242` matched.
