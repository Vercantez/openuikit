# MetricKit (Linux starting point)

This directory is a fail-closed portable `MetricKit` framework tranche seeded
from the Xcode 26.1 iPhoneOS 26.1 public Swift surface. It is not wired into
the shared guest package; that integration is a separate central review step.

## What is real

- Typed public surface for metric, diagnostic, histogram, unit, payload, and
  error types compiled as module `MetricKit` / `libMetricKit.dylib`.
- `MXErrorDomain`, `MXError`, `MXError.Code`, and `MXLaunchTaskID` including
  `CustomNSError`, hashing, and equality.
- `MXMetricManager.shared` identity, subscriber add/remove (weak, idempotent),
  and empty `pastPayloads` / `pastDiagnosticPayloads`.
- Linux-local `dictionaryRepresentation()` / `jsonRepresentation()` of
  host-constructed objects. This is a property dump, not Apple's payload schema.
- `MXUnitAveragePixelLuminance.apl` and `MXUnitSignalBars.bars` as `Dimension`
  base units.

Host-only `@_spi(OpenUIKitHost)` initializers exist so tests can construct
payloads without claiming those inits are Apple API.

## Fail-closed boundaries

Linux has no MetricKit daemon, launch-measurement OS service, or `OSLog` /
`OSSignpost` stack:

- Subscribers are never invoked and past payloads stay empty. The
  implementation does not fabricate telemetry.
- `extendLaunchMeasurement(forTaskID:)` throws
  `MXError.launchTaskInternalFailure`.
- `finishExtendedLaunchMeasurement(forTaskID:)` throws
  `MXError.launchTaskUnknown`.
- `init(coder:)` always returns `nil`; `encode(with:)` is a no-op. Apple's
  NSCoder layout is not in the pinned inputs.
- `makeLogHandle(category:)`, `mxSignpost`, and
  `mxSignpostAnimationIntervalBegin` are **unavailable** (they require
  `OSLog` / `OSSignpost` types that Linux Foundation does not provide).

Default metadata strings, process id `0`, and zero measurements are empty
local values, not device identity.

## Still deferred / oracle

See `oracle-questions.tsv` for Apple-runtime questions: the exact error-domain
string, launch-task error mapping, JSON schema, subscriber queue, and
histogram unit identity.
