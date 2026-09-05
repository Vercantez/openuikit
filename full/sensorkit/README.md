# SensorKit (Linux starting point)

Isolated clean-room port of Apple's public `SensorKit` module from the Xcode
26.1 iPhoneOS 26.1 seed. This directory is not wired into the shared guest
package. A passing isolated host gate is not integrated Linux success.

## What is real

The public Swift surface compiles to `libSensorKit.dylib`.

Implemented and exercised:

- `SRError.Code` raw values `0...4` (`invalidEntitlement` through `promptDeclined`)
  and domain string `SRErrorDomain`
- `SRAuthorizationStatus`, `SRDeletionReason`, acoustic nested enums,
  ECG/wrist/visit/notification/keyboard sentiment enums with documented integer
  raw values
- Option-set algebra for `SRElectrocardiogramData.Flags`,
  `SRFaceMetrics.Context`, `SRSpeechMetrics.SessionFlags`, and
  `SRWristTemperature.Condition`
- `SRSensor` and `SRDeviceUsageReport.CategoryKey` string wrappers using C
  export names as Linux-local payloads
- `SRAbsoluteTime` as a `TimeInterval` wrapper; `current()` uses the Foundation
  reference-date clock; `toCFAbsoluteTime()` is identity on Linux
- Sample and report classes with host `@_spi(OpenUIKitHost)` initializers for
  getter tests (ambient light chromaticity/lux, wrist, ECG, PPG noise terms,
  keyboard scalars and probability metrics, usage reports, visits)
- `SRSensorReader` fail-closed recording/fetch APIs
- `SRDevice.current` filled from `ProcessInfo` (Linux host, not an iPhone)

`tests/agent/SensorKitLoadSmoke.swift` is the sealed load marker.
`tests/agent/SensorKitDependencyIdentity.swift` passes Foundation
`TimeInterval`, `Date`, `NSError`, `Data`, and `ProcessInfo` values through
public SensorKit APIs for a future clean EC2 integration build.

## Fail-closed boundaries

Linux has no SensorKit daemon, Research app, or Apple Watch/iPhone sensors.

- `SRSensorReader.authorizationStatus` is always `.denied`
- `fetch`, `fetchDevices`, `startRecording`, and `stopRecording` invoke the
  delegate synchronously with `SRError` (`noAuthorization`,
  `fetchRequestInvalid`, `invalidEntitlement`, `dataInaccessible`) and never
  deliver samples
- `requestAuthorization(sensors:)` is declared `async throws` and throws
  `invalidEntitlement`; the isolated runner cannot await it
- `SR_ARKIT_SUPPORTED` is `0`
- Properties typed as `ARFaceAnchor`, `CMTimeRange`,
  `SNClassificationResult`, or `SFSpeechRecognitionResult` are
  **unavailable** (those modules are not SensorKit dependencies)

## Depth pass 2026-09

- Implemented: **699** of 705 exact IDs (plus 1 `declared`, 5 `unavailable`)
- Nondeferred: **700** (floor 353)
- Top-5 `implemented` evidence distribution:
  1. 53 × `tests/agent/SRAcousticSettingsTests.swift#testAcousticSettingsEnums`
  2. 49 × `tests/agent/SRKeyboardMetricsTests.swift#testKeyboardProbabilityMetrics`
  3. 48 × `tests/agent/SRSampleTests.swift#testECGEnumsAndFlags`
  4. 41 × `tests/agent/SREnumOptionSetTests.swift#testLocationAndTextInputEnums`
  5. 34 × `tests/agent/SRSensorTimeTests.swift#testCategoryKeys`

The first, third, fourth, and fifth rows are table-driven enum / option-set /
C-constant value tests. Keyboard probability metrics are split from scalar
counts and sentiment counts.

## Still open

See `oracle-questions.tsv`. Apple string payloads for `SRSensor`, mach-time
conversion, delegate queue, authorization completion code, and
`NSSecureCoding` coder keys remain unobserved.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
