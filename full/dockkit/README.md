# DockKit (Linux starting point)

This directory is a fail-closed portable `DockKit` module for the OpenUIKit
Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS Swift surface
from the sealed symbol graph. It is not wired into the shared guest package;
that integration is a separate central review step.

Coverage: **284 implemented / 65 declared / 0 not-applicable / 349 total**
(349 nondeferred, above the medium-full floor of 175).

## What is real

- `DockKitError` cases in API-digester order (`notSupported` …
  `frameRateTooHigh`), `Equatable` / `Hashable`, and `LocalizedError`
  descriptions. No integer raw values are invented.
- Nested enums (`FramingMode`, `Category`, `CameraOrientation`,
  `BatteryChargeState`, `Observation.ObservationType`, `State`, `Animation`,
  `AccessoryEvent`, `TrackedSubjectType`) with equality, hashing, and
  (where the graph records it) Codable round-trips of case names.
- Value types: `Identifier`, `Observation` (including the documented
  `faceYawAngle` default), `Limits` / `Limit`, `BatteryState`, `MotionState`,
  `TrackedObject`, `TrackedPerson`, `TrackingState`, `CameraInformation`,
  `StateChange`.
- `Limit.init(positionRange:maximumSpeed:)` stores a valid range and speed
  and throws `invalidParameter` for empty ranges, negative speeds, and
  non-finite numbers.
- `DockAccessoryManager.shared` identity, `isSystemTrackingEnabled == false`,
  and synchronous fail-closed getters/commands that need a dock.
- Empty `AsyncSequence` types (`AccessoryEvents`, `MotionStates`,
  `StateChanges`, `BatteryStates`, `TrackingStates`) so `makeAsyncIterator()`
  and the associated typealiases can be exercised without inventing hardware
  events.

## Fail-closed boundaries

Linux has no DockKit daemon, tracking stand, motor bus, camera TCC prompt,
or AVFoundation capture session.

- `DockAccessoryManager.accessoryStateChanges` and every live-accessory
  stream getter (`accessoryEvents`, `motionStates`, `batteryStates`,
  `trackingStates`, `limits`) throw `DockKitError.notSupported`.
- Synchronous `setLimits` and `setOrientation` (Vector3D / Rotation3D)
  throw `notSupported` and never return a `Progress` handle.
- Async hardware commands (`setSystemTrackingEnabled`, `selectSubject`,
  `selectSubjects`, `setFramingMode`, async `setOrientation`,
  `setAngularVelocity`, `setRegionOfInterest`, `track`, `animate`) are
  declared and throw `notSupported`; the sealed runner has no run loop and
  cannot await them.
- Camera `track` overloads never invent a tracked subject or consume a real
  `CVPixelBuffer`.
- Spatial / simd / AVFoundation / CoreVideo names used by the surface are
  isolated-host stand-ins in `DockKitLookalikes.swift`, not Darwin identity.

## Depth pass 2026-09

Fresh seed first revision at `0009a54b` was **219 implemented / 18 declared /
112 not-applicable**. The operator merge refused that ledger: those 112
rows are stdlib `AsyncSequence` / `AsyncIteratorProtocol` witnesses (for
example `s:ScI12_ConcurrencyE4next7ElementQzSgyYa7FailureQzYKF::SYNTHESIZED::s:7DockKit0A…`),
not SwiftUI cross-import overlay IDs, so they cannot be `not-applicable`.

After this repair: **284 implemented / 65 declared / 0 not-applicable**.

Synchronous `AsyncSequence` adapters (`map`, `compactMap`, `filter`,
`drop(while:)`, `dropFirst`, `prefix`, `prefix(while:)`, `flatMap`) are
implemented with focused tests in `DockKitSequenceAdapterTests.swift`.
Async consumers (`next`, `next(isolation:)`, `allSatisfy`, `first`, `max`,
`min`, `reduce`, `contains`) stay `declared` — the sealed runner cannot await.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 20 | `DockKitSequenceAdapterTests.swift#testAsyncSequenceFlatMap` |
| 13 | `DockKitEnumTests.swift#testCameraOrientationCases` |
| 10 | `DockKitSequenceAdapterTests.swift#testAsyncSequenceCompactMap` |
| 10 | `DockKitSequenceAdapterTests.swift#testAsyncSequenceMap` |
| 9 | `DockKitEnumTests.swift#testAccessoryEventCases` |

Enum/case identity tests may share a table-driven value test. The largest
non-enum citation is `testAsyncSequenceFlatMap` at 20 of 235 remaining
implemented rows (8.5%), under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/dockkit/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=DockKit lane=medium-full symbols=349
FRAMEWORK_FANOUT_REFERENCE_OK
DOCKKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=DockKit dylib=libDockKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` does not print
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` on this
snapshot (`scratch/ladder-corpus/focus-ios` is missing; Cursor Build
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs seed
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). That campaign token is
the host-inventory stamp; `swiftc` is 6.2.4 / linux and the sealed framework
gate compiles with a clean product tree (`products=clean`).
