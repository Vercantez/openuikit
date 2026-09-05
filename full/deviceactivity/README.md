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
behavior. Three `AsyncSequence` members constrained to `Element == UInt8`
are `not-applicable`.

See `oracle-questions.tsv`.

## Depth pass 2026-09

Fresh seed. Implemented **240** of 1036 precise IDs (declared 780, deferred 13, not-applicable 3; 1020 nondeferred, floor 829).

Top-5 implemented evidence distribution:

| citations | test |
| --- | --- |
| 43 | `testDeviceActivityDataSegmentAndActivities` |
| 30 | `testDeviceActivityResultsIteration` |
| 21 | `testDeviceActivityReportBuilderBuildBlock` |
| 15 | `testDeviceActivityDataDeviceAndUser` |
| 11 | `testDeviceActivityDeviceModelRawValues` |

No non-enum test exceeds 40% of the remaining implemented rows. SwiftUI View-modifier precise IDs are `declared` against `DeviceActivityViewStubs.swift`, never `implemented`.
