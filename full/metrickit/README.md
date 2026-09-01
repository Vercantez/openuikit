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

`jsonRepresentation()` / `dictionaryRepresentation()` are Linux-local property
dumps. They are **declared**, not Apple's JSON schema. `init(coder:)` returns
`nil` and `encode(with:)` is a no-op; that is **declared**, not an archive
round trip.

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
