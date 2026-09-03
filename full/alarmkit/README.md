# AlarmKit

Linux starting point for Apple's public `AlarmKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. The legacy platform branch
`cursor/port-alarmkit-to-linux-cf82` (PR #47) was not fetchable with this
environment's GitHub App token, so this is not a byte copy of that 1,285-line
tree. A passing isolated host gate is not integrated Darwin alarm-service
success.

## Reference dossier

Kept the **newer monorepo** `full/alarmkit/reference/` already on main
(schema v1, generator `scripts/framework-fanout/generate_seed.py`, SHA
`2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`,
Xcode 26.1 / iPhoneOS 26.1, 262 precise IDs). The platform branch
`reference/` could not be compared (`unavailable`).

## What is real

Value types from the public surface compile and round-trip through a **local**
Codable layout:

- `Alarm`, `Alarm.State`, `Alarm.Schedule` (fixed and relative, including
  weekly `Locale.Weekday` recurrence), `Alarm.CountdownDuration`
- `AlarmButton`, `AlarmPresentation` (alert / countdown / paused),
  `AlarmPresentationState`
- `AlarmAttributes<Metadata>` where `Metadata: AlarmMetadata`
- `AlarmManager.AlarmConfiguration` factories `alarm` and `timer`
- `AlarmManager.AlarmError.maximumLimitReached` as a constructible `Error`
- Empty `AsyncSequence` streams `alarmUpdates` / `authorizationUpdates`
  (`next()` returns `nil` immediately)

`tests/agent/AlarmKitRuntime.swift` exercises those paths.

## Fail-closed boundaries

`AlarmManager.shared` never talks to an Apple alarm daemon:

- `authorizationState` starts `.notDetermined`
- `requestAuthorization()` records and returns `.denied` (no prompt)
- `schedule`, `alarms`, `stop`, `pause`, `cancel`, `resume`, and `countdown`
  throw `NSError(domain: AlarmKitLinuxErrorDomain, code: 1)`
- Linux never returns a scheduled `Alarm` from `schedule`
- Stored `LiveActivityIntent` values are never performed

## Stand-in types (not Darwin modules)

Isolated `swiftc` on this VM cannot `import SwiftUI`, `AppIntents`, or
`ActivityKit`. The graph still names `Color`, `LocalizedStringResource`,
`LiveActivityIntent`, and `AlertConfiguration.AlertSound`, so this module
defines Linux stand-ins. They are not Apple's types. Darwin Codable layouts
for `Color` and `LocalizedStringResource` are unobserved.

## Deferred / unobserved

- Apple entitlement prompt and authorized scheduling
- Default Darwin stop-button artwork for
  `AlarmPresentation.Alert.init(title:secondaryButton:secondaryButtonBehavior:)`
  (Linux uses a local `stop.circle` placeholder)
- Live Activity / App Intent execution
- SwiftUI presentation and `#Preview`
