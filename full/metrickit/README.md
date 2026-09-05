# MetricKit (Linux starting point)

This directory is a fail-closed portable `MetricKit` framework tranche seeded
from the Xcode 26.1 iPhoneOS 26.1 public Swift surface. It is not wired into
the shared guest package. A passing isolated host gate is not integrated Linux
success.

## What is real

- Typed public surface for metric, diagnostic, histogram, unit, payload, and
  error types compiled as module `MetricKit` / `libMetricKit.dylib`.
- `MXErrorDomain` is the string `MXErrorDomain`, matching the pinned Apple
  iOS 26.1 oracle.
- `MXError.Code` raw values match that oracle exactly: `launchTaskUnknown=4`,
  `launchTaskInvalidID=0`, `launchTaskDuplicated=3`,
  `launchTaskInternalFailure=5`, `launchTaskMaxCount=1`,
  `launchTaskPastDeadline=2`. Table-driven tests cover every mapping.
- `MXLaunchTaskID` hashing and equality.
- `MXMetricManager.shared` identity. `add(_:)` retains strongly and
  identity-deduplicates; `remove(_:)` releases. Concurrent add/remove is
  lock-protected. Subscribers are never invoked and past payloads stay empty.
- `MXUnitAveragePixelLuminance.apl` and `MXUnitSignalBars.bars` keep symbols
  `apl` / `bars`.
- Host-only `@_spi(OpenUIKitHost)` initializers for getter tests. Those inits
  are not Apple API.
- `MXCrashDiagnosticObjectiveCExceptionReason.className` keeps the public
  `String` getter and `_className` storage. It is `override` only when
  Objective-C Foundation is imported, because Apple `NSObject` already
  exposes `className` and swift-corelibs-Foundation does not.

`jsonRepresentation()` / `dictionaryRepresentation()` are Linux-local property
dumps. They are **implemented** as that dump (keys, Measurement `{value,unit}`
encoding, empty `MXCallStackTree` `{}`) and are **not** Apple's JSON schema.
`init(coder:)` returns `nil` and `encode(with:)` is a no-op; that fail-closed
path is **implemented**, not an Apple archive round trip. Protocol-default
`MXMetricManagerSubscriber.didReceive` methods are empty and the manager never
invokes them.

## Fail-closed boundaries

Linux has no MetricKit daemon, launch-measurement OS service, or `OSLog` /
`OSSignpost` stack:

- Telemetry is never fabricated. Subscribers receive no payloads.
- Launch measurement stays fail-closed. On the pinned simulator, extend of an
  empty task ID returned success, while an immediate finish of that ID and of
  a never-started ID threw domain `MXErrorDomain` code 5. That finite
  observation is not a universal daemon contract. Linux throws
  `MXError.launchTaskInternalFailure` (raw value 5) for both extend and finish
  rather than inventing extend success.
- `makeLogHandle(category:)`, `mxSignpost`, and
  `mxSignpostAnimationIntervalBegin` are **unavailable**.

## Tests

`tests/agent/MetricKitRuntime.swift` is the isolated host-gate probe.
`tests/agent/MetricKitDependencyIdentity.swift` is a future clean-EC2 probe
that links `libMetricKit.dylib` and uses guest Foundation `NSObject`,
`NSError`, `Date`, `Data`, `Measurement`, `Unit`, `NSNumber`, `NSCoder`, and
collections through MetricKit APIs.

Remaining Apple-runtime questions are in `oracle-questions.tsv`.

## Depth pass 2026-09

Coverage before this pass: **226 implemented / 31 declared / 0 deferred /
3 unavailable / 0 not-applicable**.

Coverage after this pass: **257 implemented / 0 declared / 0 deferred /
3 unavailable / 0 not-applicable**.

Raised to `implemented` with focused tests: Linux JSON/dictionary property
dumps, fail-closed `init(coder:)=nil`, and empty subscriber `didReceive`
defaults. Left `unavailable`: `makeLogHandle(category:)`, `mxSignpost`, and
`mxSignpostAnimationIntervalBegin` (OSLog / OSSignpost / Apple telemetry).

Top-5 evidence distribution among implemented rows:

| test | rows | share |
| --- | ---: | ---: |
| `testAppExitMetricGetters` | 21 | 8.2% |
| `testMetricPayloadGetters` | 21 | 8.2% |
| `testMXErrorCodeRawValues` | 18 | 7.0% |
| `testMXErrorDomainAndBridging` | 15 | 5.8% |
| `testHistogramAndAverageGetters` | 11 | 4.3% |

No non-enum test exceeds 40% of implemented rows. Enum/error-code members
share the table-driven `testMXErrorCodeRawValues`.
