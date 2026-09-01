# AlarmKit (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AlarmKit` module, reconstructed from the pinned Xcode 26.1 iPhoneOS 26.1
symbol graph (262 precise identifiers). It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

Value types compile and behave deterministically in-process:

- `Alarm`, `Alarm.State`, `Alarm.Schedule` (fixed and relative/weekly),
  `Alarm.CountdownDuration`
- `AlarmButton`, `AlarmPresentation` (alert / countdown / paused)
- `AlarmAttributes`, `AlarmMetadata`, `AlarmPresentationState`
- `AlarmManager.AlarmConfiguration` factories (`.alarm`, `.timer`, countdown
  initializer)
- Codable / Hashable / Equatable / Identifiable conformances from the graph
- `AlarmManager.shared`, `authorizationState`, `requestAuthorization()`,
  fail-closed scheduler methods, and one-shot async sequences

Isolated `swiftc` has no SwiftUI, ActivityKit, or AppIntents. The module
therefore ships named stand-ins for `Color`, `LocalizedStringResource`,
`AlertConfiguration.AlertSound`, `LiveActivityIntent`, and
`ActivityAttributes` so the AlarmKit surface can compile.

## Fail-closed boundaries

Linux has no AlarmKit entitlement, `NSAlarmKitUsageDescription` prompt, alarm
daemon, Lock Screen UI, Dynamic Island, or system sound playback.

- `authorizationState` starts as `.notDetermined`
- `requestAuthorization()` records `.denied` and never returns `.authorized`
- `schedule`, `alarms`, `pause`, `resume`, `stop`, `cancel`, and `countdown`
  throw `AlarmKitUnavailableError`
- `alarmUpdates` yields one empty snapshot and finishes
- `authorizationUpdates` yields the current denied/not-determined state once

The implementation does not claim that an Apple scheduler accepted an alarm
or that a live activity appeared.

## Still deferred / unknown

- Exact `NSError` domain and codes for unauthorized or malformed schedules
- Apple's default stop-button appearance for
  `AlarmPresentation.Alert.init(title:secondaryButton:secondaryButtonBehavior:)`
- Codable representation of `SwiftUI.Color` inside `AlarmAttributes`
- Whether `AlarmManager.AlarmConfiguration.timer` maps duration onto
  `preAlert` only
- Live Activity / WidgetKit presentation of `AlarmAttributes`

See `oracle-questions.tsv`.
