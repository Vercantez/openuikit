# EventKit (Linux starting point)

Foundation + CoreFoundation Linux port of Apple's public `EventKit` overlay
from the Xcode 26.1 iPhoneOS seed. Isolated `tests/acceptance/test_host.sh`
does **not** prove integrated guest-Foundation success. A future EC2 run
must build guest Foundation and CoreFoundation first; see
`tests/agent/EventKitDependencyIdentity.swift`.

## What is real (Swift source overlay)

- Enumerations, option sets, and `EKError` / `EKErrorDomain` with documented
  raw values (`eventNotMutable = 0` … `last = 37`; `authorized` aliases
  `fullAccess`).
- In-memory `EKEvent`, `EKReminder`, `EKCalendar`, `EKAlarm`, recurrence
  (including `NSSecureCoding`), structured-location title/radius, and
  virtual-conference *descriptors*.
- Predicate builders: `calendars == nil` means every calendar; `calendars == []`
  matches nothing. Reminder due-date windows use the components' calendar and
  time zone.
- `EKAlarm` absolute/relative fields clear each other. Completing a reminder
  stamps `completionDate`.
- `ABAddressBook` / `ABRecord` are `CoreFoundation.CFTypeRef`, not EventKit-local
  stand-in types.

`EKSource`, `EKParticipant`, `EKObject`, and `EKCalendarItem` have no public
constructors in the canonical graph. Host fixtures use
`@_spi(OpenUIKitHost)`.

## Fail-closed (headers)

Linux has no TCC prompt and no Calendar database.

- `authorizationStatus(for:)` is `.denied`.
- `requestAccess(to:)` returns `false` without throwing (denied: granted NO,
  error nil). Full/write-only request completions deliver `(false, nil)` on a
  global Dispatch queue, not the caller stack.
- `save` / `remove` / `commit` throw `eventStoreNotAuthorized`.
- Queries return empty. `fetchReminders` returns a token immediately and
  completes asynchronously with `nil` (unauthorized or cancelled).
- `delegateSources` is empty (no host accounts).
- `EKEventStoreChanged` is never posted.
- Virtual-conference *provider* fetches fail with `osNotSupported`, also
  asynchronously (no NSExtension host).
- `EKParticipant.abRecord(with:)` returns `nil`.

## Deferred

- `EKCalendar.cgColor` (CoreGraphics)
- `EKStructuredLocation.geoLocation` / `init(mapItem:)` (Core Location / MapKit)
- `EKEventStore.EventStoreChanged` as `NotificationCenter.MainActorMessage`
  and `NotificationCenter.MessageIdentifier.changed` — compiled only when
  Foundation provides that contract (Darwin). Linux does not ship a lookalike.

Objective-C/binary TBD coverage is accounted separately in
`tests/agent/EventKitTBDAccounting.swift`. SPI TBD classes are not part of the
511-identifier public overlay.

See `oracle-questions.tsv`.
