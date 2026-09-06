# SensitiveContentAnalysis (Linux starting point)

This directory is a fail-closed portable `SensitiveContentAnalysis` module for
the OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, TBD exports, and the read-only `dotnet/macios` binding.
It is not wired into the shared guest package; that integration is a later
central-review step.

## What is real

- `SCSensitivityAnalysisPolicy` raw values are `disabled=0`,
  `simpleInterventions=1`, `descriptiveInterventions=2`, matching the pinned
  macios enumeration. `init(rawValue:)` is nil outside `0...2`.
- `SCVideoStreamAnalyzer.StreamDirection` raw values are `outgoing=1` and
  `incoming=2`. Raw `0` is not a case.
- `SCSensitivityAnalyzer.analysisPolicy` is `.disabled` on Linux (no
  Communication Safety setting).
- `analyzeImage(at:)` invokes its completion handler once, synchronously,
  with `(nil, SCLinuxUnavailableError)` and never returns an
  `SCSensitivityAnalysis`.
- `videoAnalysis(forFileAt:)` constructs a `VideoAnalysisHandler` that
  stores the file URL and a `Progress(totalUnitCount: 1)` (assignable).
  `hasSensitiveContent()` cancels that progress and throws
  `SCLinuxUnavailableError`.
- `SCVideoStreamAnalyzer` stores `participantUUID` and `streamDirection`,
  keeps `analysis == nil`, counts `continueStream()` until `endAnalysis()`,
  and exposes `analysisChanges` as an empty `AsyncSequence` that never
  yields a detection.
- `SCSensitivityAnalysis` property accessors return stored Bools. Apple
  has no public initializer; host tests use `host_makeUnanalyzed`.

## Fail-closed boundaries

Linux has no Communication Safety policy store, on-device sensitive-content
classifier, analysis daemon, capture device, or decompression session.

- Image and video analysis never invent a sensitive or not-sensitive result.
- `analyzeImage(_: CGImage)`, `analyze(_: CVPixelBuffer)`, and both
  `beginAnalysis(of:)` overloads are not compiled: they need CoreGraphics,
  CoreVideo, AVFoundation, and VideoToolbox, which are not declared
  dependencies and must not be replaced with lookalike types.
- `SCLinuxUnavailableError` / `SCLinuxUnavailableErrorDomain` is a Linux
  overlay (code `1`). It is not one of the 38 Apple identifiers.

## Still deferred

See `oracle-questions.tsv` for Darwin policy defaults, NSError identity,
progress semantics, `analysisChanges` delivery, initializer validation, and
whether the four `SCSensitivityAnalysis` flags are independent.

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory.

## Depth pass 2026-09

Implemented: **34** / declared 0 / deferred 4 / unavailable 0 /
not-applicable 0 (38 exact IDs). Nondeferred 34 meets the leaf-full floor
of 31.

The four deferred identifiers are `analyzeImage(_: CGImage)`,
`analyze(_: CVPixelBuffer)`, `beginAnalysis(of: AVCaptureDeviceInput)`,
and `beginAnalysis(of: VTDecompressionSession)`. Those signatures need
real dependency types; they are not stubbed with
SensitiveContentAnalysis-owned lookalikes.

Top-5 evidence distribution (of 34 implemented rows; 40% cap on non-enum
tests of remaining rows = 11):

1. `SCSensitivityAnalysisPolicyTests.swift#testPolicyRawValues` — 5 rows (14.7%; enum/code table)
2. `SCVideoStreamAnalyzerStreamDirectionTests.swift#testStreamDirectionRawValues` — 4 rows (11.8%; enum/code table)
3. `SCSensitivityAnalyzerTests.swift#testAnalyzeImageAtFailsClosed` — 1 row (2.9%)
4. `SCVideoAnalysisHandlerTests.swift#testHasSensitiveContentFailsClosed` — 1 row (2.9%)
5. `SCVideoStreamAnalyzerTests.swift#testContinueStreamNoAnalysis` — 1 row (2.9%)
