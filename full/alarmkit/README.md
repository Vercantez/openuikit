# AlarmKit (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`AlarmKit` module from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph.
It is not an integrated platform framework. Isolated `swiftc` here has
Foundation only; SwiftUI, ActivityKit, and AppIntents are absent.

## What compiles in this isolated gate

- `Alarm`, `Alarm.State`, `Alarm.Schedule`, `Alarm.CountdownDuration`
- `AlarmPresentationState`
- `AlarmMetadata`
- `AlarmManager.shared`, `authorizationState`, fail-closed
  `requestAuthorization()` (state unchanged), fail-closed scheduler
  accessors, and ongoing `alarmUpdates` / `authorizationUpdates`

Enums match the graph: no extra `String` raw values. Codable is the
synthesized contract.

## Dependency-correct omissions

This module does **not** define lookalike `SwiftUI.Color`,
`Foundation.LocalizedStringResource`, `ActivityKit.ActivityAttributes`,
`ActivityKit.AlertConfiguration`, or `AppIntents.LiveActivityIntent`
types. Declarations that need those nominal types are compiled only when the
real module imports **and** the platform actually vends the type
(`os(iOS) || os(watchOS) || os(visionOS) || os(Linux)`). `canImport`
alone is not evidence: macOS can import ActivityKit and AppIntents while
`ActivityAttributes`, `AlertConfiguration`, and `LiveActivityIntent`
stay unavailable. Those rows stay `deferred`. No fallback types.

When those real types are available on iOS or a Linux-staged cold build:

- `AlarmButton`, `AlarmPresentation`, `AlarmAttributes` use SwiftUI.Color
  and Foundation.LocalizedStringResource
- `AlarmAttributes` conforms to ActivityKit.ActivityAttributes
- `AlarmManager.AlarmConfiguration` uses LiveActivityIntent and
  AlertConfiguration.AlertSound
- `timer(duration:)` and `Alert.init(title:secondaryButton:…)` remain
  omitted until their unobserved defaults/mappings are known
- Color Codable on presentation types fails closed

`tests/agent/AlarmKitDependencyIdentity.swift` is the future probe for
that iOS/Linux-staged build. It is not compiled by
`tests/acceptance/test_host.sh`. On macOS the guest sources still produce
a loadable reduced module: live-activity types are omitted rather than
replaced.

## Fail-closed host behavior

- No entitlement prompt: `requestAuthorization()` throws
  `AlarmKitHostBoundary.authorizationPromptUnavailable` (SPI) and leaves
  `.notDetermined`
- No daemon: `alarms`, `pause`, `resume`, `stop`, `cancel`, `countdown`
  throw `systemSchedulerUnavailable`
- Observation sequences yield the current snapshot, then stay open until
  cancelled or the manager is deallocated. They are independently
  iterable and race-safe. They are not one-value streams that finish.

Host-only sequence injection lives under `@_spi(OpenUIKitHost)` and is
not Apple scheduler success.

This isolated host gate is not integrated Linux success. That claim
waits on a future EC2 cold build with real ActivityKit, AppIntents,
Foundation `LocalizedStringResource`, and SwiftUI modules, plus
`libAlarmKit.dylib` load and `AlarmKitDependencyIdentity.swift`.

See `oracle-questions.tsv`.
