# EventKit (Linux local store)

Foundation + CoreFoundation Linux port of Apple's public `EventKit` overlay
from the Xcode 26.1 iPhoneOS seed. Isolated `tests/acceptance/test_host.sh`
compiles `libEventKit.dylib` on the host toolchain. Guest-Foundation identity
is a later EC2 step; see `tests/agent/EventKitDependencyIdentity.swift`.

## What is real

- Enumerations, option sets, and `EKError` / `EKErrorDomain` with documented
  raw values (`eventNotMutable = 0` … `last = 37`; `authorized` aliases
  `fullAccess`).
- On-disk local calendar/reminder store at Application Support
  **`OpenUIKit/EventKit/store.json`**. Override with
  `OPENUIKIT_EVENTKIT_STORE_DIRECTORY` or
  `EKEventStore.useIsolatedStoreDirectory(_:)` (tests). This is not
  Calendar.app, CalDAV, Exchange, or iCloud.
- `authorizationStatus(for:)` starts `.notDetermined`.
  `requestFullAccessToEvents` / `requestFullAccessToReminders` /
  `requestAccess(to:)` grant this sandbox (`.fullAccess`).
  `requestWriteOnlyAccessToEvents` grants `.writeOnly` (saves succeed;
  `events(matching:)` stays empty). `EKEventStore.denyAccessRequests`
  persists `.denied` and those same APIs return `(false, nil)` off the
  caller stack.
- Local `EKSource` (`On This Device`) plus default `Calendar` /
  `Reminders` calendars after grant. `saveCalendar` / `removeCalendar`,
  `save(_:span:commit:)` / `remove(_:span:commit:)`, `commit` / `reset` /
  `refreshSourcesIfNecessary`.
- `EKSpan.thisEvent` detaches one occurrence (EXDATE). `futureEvents`
  splits the series at that occurrence.
- `events(matching:)` expands `EKRecurrenceRule`
  (frequency/interval/daysOfTheWeek/daysOfTheMonth/monthsOfTheYear/
  weeksOfTheYear/daysOfTheYear/setPositions/end) over Foundation
  `Calendar`. Documented GMT samples in `tests/agent/EventKitRuntime.swift`:
  daily COUNT 3; daily interval 2; weekly Monday COUNT 4 from 2026-01-05;
  weekly MO/WE/FR COUNT 6; monthly BYMONTHDAY=15; monthly BYDAY=-1FR;
  yearly 1 Jan COUNT 3.
- Reminder predicates, `fetchReminders` (array after grant, `nil` if
  cancelled or unauthorized), `EKEventStoreChanged` after a successful
  commit.
- `EKReminder` priority 0–9 (0 none, 1–4 high, 5 medium, 6–9 low);
  `isCompleted` stamps/clears `completionDate`. Invalid priority throws
  `priorityIsInvalid`. Recurring reminders require a due date.
- `EKCalendar.cgColor` (CoreGraphics, default sRGB 0 / 0.478 / 1 / 1 —
  a port default, not Calendar.app's palette).
- `EKStructuredLocation.geoLocation` (`CLLocation`) and
  `init(mapItem:)` (`MKMapItem.location` / `name` on macOS 26).
- `EKRecurrenceDayOfWeek` weekNumber clamped to −53…53;
  `EKRecurrenceEnd(occurrenceCount:)` clamped to ≥ 0; interval ≥ 1.
- `ABAddressBook` / `ABRecord` are `CoreFoundation.CFTypeRef`.

`EKSource`, `EKParticipant`, `EKObject`, and `EKCalendarItem` have no public
constructors in the canonical graph. Host fixtures use
`@_spi(OpenUIKitHost)`.

## Fail-closed (headers)

- No TCC prompt and no host Calendar database. Granting access authorizes
  only this process-local store.
- `delegateSources` is empty unless a host `EKSource` is marked delegate.
- Virtual-conference *provider* fetches fail with `osNotSupported`,
  asynchronously (no NSExtension host).
- `EKParticipant.abRecord(with:)` returns `nil`.

`EKEventStore.EventStoreChanged` conforms to
`NotificationCenter.MainActorMessage` on Darwin. Linux compiles the same
struct without that protocol (host Foundation has no lookalike).

Objective-C/binary TBD coverage is accounted separately in
`tests/agent/EventKitTBDAccounting.swift`. SPI TBD classes are not part of the
511-identifier public overlay.

See `oracle-questions.tsv`.
