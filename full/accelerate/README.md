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
