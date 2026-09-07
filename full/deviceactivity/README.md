# DeviceActivity

This directory is an isolated Linux starting point for Apple's public
`DeviceActivity` module. It reconstructs the Xcode 26.1 iPhoneOS 26.1 public
surface from the pinned symbol graph. It is not wired into the shared guest
package; that integration is a later central-review step.

The isolated host gate compiles only against toolchain Foundation. Passing
`test_host.sh` is not integrated Linux success and does not load guest
Foundation, SwiftUI, ManagedSettings, or FamilyControls.

## What is real

Value types and process-local monitoring:

- `DeviceActivityName` and `DeviceActivityEvent.Name` (`RawRepresentable` `String`)
- `DeviceActivitySchedule` including `nextInterval` using
  `Calendar.MatchingPolicy.nextTimePreservingSmallerComponents`
- `DeviceActivityEvent` with `threshold`, `includesPastActivity`, and
  `includesAllActivity` (`true` when token sets are empty)
- `DeviceActivityFilter` (`Users`, `Devices`, `SegmentInterval`)
- `DeviceActivityData` records (`Device`, `User`, `ActivitySegment`,
  `ApplicationActivity`, `CategoryActivity`, `WebDomainActivity`)
- `DeviceActivityCenter` process-local registry
- `DeviceActivityCenter.MonitoringError` with documented interval and cap checks
- `DeviceActivityAuthorization` / `DeviceActivityAuthorizing` (fail-closed)
- `DeviceActivityMonitor` inert extension principal class
- `DeviceActivityReport.Context` and `DeviceActivityResults` in-memory sequence
- `DeviceActivityReportBuilder.buildBlock` returning the first scene

`DeviceActivityCenter.startMonitoring` records a name, schedule, and events in
process memory. Documented Apple limits are enforced:

- interval duration &lt; 15 minutes → `.intervalTooShort`
- interval duration &gt; one week → `.intervalTooLong`
- unmatched date components → `.invalidDateComponents`
- more than twenty distinct names → `.excessiveActivities`
- without authorization (and without `isOverridden`) → `.unauthorized`

`Device.Model` raw values follow api-digester child order: `iPhone = 0`,
`iPod = 1`, `iPad = 2`, `mac = 3`. `FamilyRole` is `individual = 0`,
`child = 1`.

## Fail-closed boundaries

Linux has no Screen Time daemon, FamilyControls entitlement prompt, ManagedSettings
token service, or DeviceActivityMonitor extension host. This port does not
fabricate:

- usage minutes, pickups, or notifications from the OS
- FamilyControls authorization success (`isAuthorized` is `false`)
- monitor extension callbacks (`intervalDidStart` / threshold warnings)
- SwiftUI report UI (`DeviceActivityReport.body` does not present a `View`)
- `ManagedSettings.Token` selections

`DeviceActivityAuthorization.isOverridden` is an isolated-host hook so schedule
validation can be tested without inventing Screen Time authorization. Even when
overridden, no extension callbacks fire and report results stay empty unless a
test constructs `DeviceActivityData` by hand.

## Still deferred

Token-typed `DeviceActivityEvent` / `DeviceActivityFilter` members that require
`ApplicationToken`, `ActivityCategoryToken`, and `WebDomainToken` stay deferred
until ManagedSettings is a real module dependency. SwiftUI `View` modifiers
synthesized onto `DeviceActivityReport` are declared as inert identifier stubs
so the isolated Foundation compile can name them; they are not SwiftUI
behavior. Three Foundation `AsyncSequence` overlays (`characters`, `lines`, and
`unicodeScalars`) are conditionally declared for `DeviceActivityResults<UInt8>`;
ordinary report-record element types do not meet that constraint.

See `oracle-questions.tsv`.

## Depth pass 2026-09

Fresh seed, then merge-repair of the coverage ledger.

Coverage before repair: **240 implemented / 780 declared / 13 deferred / 0 unavailable / 3 not-applicable**.

Coverage after: **216 implemented / 804 declared / 13 deferred / 3 unavailable / 0 not-applicable** (1020 nondeferred, floor 829).

The three `not-applicable` rows were Foundation `UInt8` AsyncSequence overlays on `DeviceActivityResults`, not `_DeviceActivity_SwiftUI` View modifiers; they are now `unavailable`. Twenty-four synthesized AsyncSequence operators that `testDeviceActivityResultsIteration` never called were reclassified to `declared`. Data-record rows were split onto per-family tests.

Top-5 implemented evidence distribution:

| citations | test |
| --- | --- |
| 21 | `testDeviceActivityReportBuilderBuildBlock` |
| 15 | `testDeviceActivityDataDeviceAndUser` |
| 11 | `testDeviceActivityActivitySegment` |
| 11 | `testDeviceActivityDeviceModelRawValues` |
| 10 | `testDeviceActivityMonitoringErrorSurface` |

No non-enum test exceeds 40% of the remaining implemented rows (largest is 21/216 ≈ 9.7%). SwiftUI View-modifier precise IDs stay `declared` against `DeviceActivityViewStubs.swift`.

## Depth pass 2026-09 (wave 8)

Coverage before wave 8: **216 implemented / 804 declared / 13 deferred / 3 unavailable / 0 not-applicable**.

Coverage after wave 8: **240 implemented / 783 declared / 13 deferred / 0 unavailable / 0 not-applicable** (1023 nondeferred, floor 829).

This wave exhausts the behaviorally testable, non-SwiftUI declared surface. All 24 inherited `AsyncSequence` operators are now exercised with bounded, synchronous top-level probes over in-memory results. The three Foundation byte-sequence overlays were corrected from unconditional `unavailable` to conditional declarations: they exist when `Element == UInt8`. The 780 `_DeviceActivity_SwiftUI` declarations remain non-implemented; the 13 ManagedSettings-token rows remain deferred because this lane declares Foundation as its sole dependency.

Top-5 implemented evidence distribution:

| citations | test |
| --- | --- |
| 21 | `testDeviceActivityReportBuilderBuildBlock` |
| 15 | `testDeviceActivityDataDeviceAndUser` |
| 11 | `testDeviceActivityActivitySegment` |
| 11 | `testDeviceActivityDeviceModelRawValues` |
| 10 | `testDeviceActivityMonitoringErrorSurface` |

No test supplies more than 40% of implemented evidence. Async probes use a detached cooperative-executor task plus a bounded lock-protected poll; they do not depend on `DispatchQueue.main`, a semaphore, or a run loop.
