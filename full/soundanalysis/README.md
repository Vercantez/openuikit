# SoundAnalysis (Linux starting point)

This directory is a fail-closed portable `SoundAnalysis` module for the
OpenUIKit Linux platform, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol
graph, API digester, and TBD exports. It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

- `SNError.Code` raw values are `unknownError=1`, `operationFailed=2`,
  `invalidFormat=3`, `invalidModel=4`, `invalidFile=5`, matching the pinned
  dotnet/macios `SNErrorCode` enumeration. `SNError` is a `CustomNSError`
  whose equality and hash follow `code` only.
- `SNClassifierIdentifier` is a string newtype. `version1` uses the exported
  C symbol name as its raw value.
- `SNClassifySoundRequest(classifierIdentifier: .version1)` constructs a
  configuration object. `overlapFactor` clamps to the documented `0...1`
  range. `knownClassifications` is empty. Unknown identifiers throw
  `invalidModel`.
- `SNTimeDurationConstraint` is a Swift enum over isolated-host `CMTime` /
  `CMTimeRange` stand-ins (used only when the real CoreMedia module is
  absent).
- `SNAudioFileAnalyzer` constructs for an existing regular file, tracks
  requests by object identity, and fails closed synchronously on `analyze()`.
- `SNClassification` / `SNClassificationResult` lookup is real for host-SPI
  snapshots. Analysis never invents labels.

## Fail-closed boundaries

Linux has no Apple sound classifier, audio decoder, or Core ML runtime.

- `analyze()` / `analyze(completionHandler:)` report `invalidFile` (or
  `operationFailed` after `cancelAnalysis()`) on the caller and never call
  `didProduce`.
- The completion handler runs synchronously with `false`.
- `init(mlModel:)` / `init(MLModel:)` are not compiled (no CoreML module).
- `SNAudioStreamAnalyzer.init(format:)` and
  `analyze(_:atAudioFramePosition:)` are not compiled (no AVFAudio module;
  no public lookalike types).
- Host tests construct a stream analyzer through `@_spi(OpenUIKitHost)`.

## Still deferred

See `oracle-questions.tsv` for the `SNErrorDomain` CFString, the version1
classifier identifier payload, Apple overlap/window defaults, analyze
callback sequencing, and whether Darwin `init(classifierIdentifier:)`
succeeds before the classifier asset is present.

Keep generated products out of the tree. Run
`bash tests/acceptance/test_host.sh` from this directory.

## Depth pass 2026-09

Implemented: **73** / declared 0 / deferred 4 / unavailable 0 /
not-applicable 0 (77 exact IDs). Nondeferred 73 meets the leaf-full floor
of 62.

The four deferred identifiers are the CoreML `init(mlModel:)` /
`init(MLModel:)` pair and the AVFAudio `init(format:)` /
`analyze(_:atAudioFramePosition:)` pair. Those signatures need real
dependency types; they are not stubbed with SoundAnalysis-owned lookalikes.

Top-5 evidence distribution (of 73 implemented rows; 40% cap on non-enum
tests of remaining rows = 24):

1. `SNErrorTests.swift#testErrorCodeRawValues` — 12 rows (16.4%; enum/code table)
2. `SNErrorTests.swift#testErrorUserInfo` — 8 rows (11.0%)
3. `SNAudioStreamAnalyzerTests.swift#testAudioStreamAnalyzerHostRegistry` — 4 rows (5.5%)
4. `SNErrorTests.swift#testErrorHashableEquatable` — 4 rows (5.5%)
5. `SNClassifierIdentifierTests.swift#testClassifierIdentifierVersion1` — 3 rows (4.1%)
