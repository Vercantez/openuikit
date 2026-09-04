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

Portable Swift implementations exercised by `tests/agent/AccelerateTests.swift`:

- `vImageBoxConvolve_ARGB8888` with `kvImageEdgeExtend`, matching
  `tests/accelerate-box-convolve-apple-2026-09-01.txt` (pixels and the even-kernel /
  missing-edge / ROI error codes from that transcript plus `Accelerate.h`)
- vDSP vector `add` / `dot` / `sum` for `Float`
- vForce `exp` / `sqrt` for `Float` via Foundation/`FloatingPoint`
- BLAS `saxpy_` / `sdot_` and `BLASGetThreading` / `BLASSetThreading`
- CBLAS order/transpose enumerator values 101 / 102 / 111 (standard CBLAS, not
  Apple-specific)
- BNNS filter creation returns `nil` (fail-closed; no BNNS runtime on Linux)

`libAccelerate.dylib` compiles with `-warnings-as-errors`.

Most other C entry points are **declared** source-compatible stubs: vImage
helpers return `kvImageInvalidParameter`, BNNS constructors return `nil`, and
Linear Algebra objects are inert `_OpenUIKitLAObject` values. Those stubs are
not Apple behavior.

## Fail-closed boundaries

- BNNS graph compile/execute, sparse solvers, and Quadrature callbacks have no
  Linux provider. Create APIs return `nil`; throwing overlay inits throw
  `AccelerateLinuxError.failClosed`.
- vImage APIs that take `CGImage`, `CGColorSpace`, `CVPixelBuffer`, or
  `CGAffineTransform` are **deferred**: those types are not declared
  dependencies, and this lane does not introduce public lookalikes.
- Enumerators without a pinned numeric binding (Apple header, macios
  annotation, or standard CBLAS) use sequential placeholders and stay
  `declared`, never `implemented`.

## Deferred

Swift overlay methods on `vDSP` / `vImage` / `BNNS` beyond the handwritten
kernels above, FFT/DFT setup objects, sparse factorization, and anything
requiring CoreGraphics or CoreVideo remain deferred until an Apple-runtime
oracle or a real Linux implementation exists.

## Tests

- `tests/agent/AccelerateLoadSmoke.swift` — canonical schema-v2 marker
- `tests/agent/AccelerateTests.swift` — focused `test*` probes (no stdout)
- `tests/agent/AccelerateDependencyIdentity.swift` — Foundation `Data` through public APIs
- `tests/agent/AccelerateRuntime.swift` — optional schema-v1-style probe (not host-compiled)
- `tests/AccelerateGuestRuntime.swift` — existing C/guest box-convolve oracle
