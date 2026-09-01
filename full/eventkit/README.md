# EventKit (Linux starting point)

This directory is a Foundation-only Linux port of Apple's public `EventKit`
surface from the Xcode 26.1 iPhoneOS SDK seed. It is not wired into a shared
guest package; that integration is a separate review step.

## What is real

- Enumerations, option sets, and `EKError`/`EKErrorDomain` match the public
  overlay names and documented raw values (`EKError.eventNotMutable = 0`
  through `EKError.last = 37`, `EKAuthorizationStatus.authorized` as an alias
  of `fullAccess`, ICS weekday numbering, reminder priority bands).
- In-memory model objects compile and behave locally: `EKEvent`, `EKReminder`,
  `EKCalendar`, `EKSource`, `EKAlarm`, `EKCalendarItem`, `EKObject` dirty
  state, recurrence (`EKRecurrenceRule` / `EKRecurrenceDayOfWeek` /
  `EKRecurrenceEnd`, including `NSSecureCoding` round-trip), structured
  location title/radius, and virtual-conference *descriptors*.
- Predicate builders return `NSPredicate` blocks that can be evaluated against
  constructed events and reminders (date range, calendar membership,
  completed vs incomplete).
- `EKAlarm` absolute dates and relative offsets clear each other, matching the
  public header contract. Completing a reminder stamps `completionDate`;
  clearing completion clears the date.

## Fail-closed boundaries

Linux has no TCC Calendar/Reminders prompt and no Apple Calendar database.

- `EKEventStore.authorizationStatus(for:)` is always `.denied`.
- `requestAccess(to:)`, `requestFullAccessToEvents`,
  `requestFullAccessToReminders`, and `requestWriteOnlyAccessToEvents` fail
  with `EKError.osNotSupported` (async throws or `(false, error)`).
- `save` / `remove` / `commit` throw `EKError.eventStoreNotAuthorized`.
- Store queries return empty collections. `fetchReminders` completes with
  `nil`. `EKEventStoreChanged` is never posted.
- `EKVirtualConferenceProvider` fetch APIs fail with `osNotSupported`.
- `EKParticipant.abRecord(with:)` returns `nil`; `contactPredicate` matches
  nothing.

This module does not invent a granted privacy state, iCloud/CalDAV sync, or a
host calendar write.

## Deferred / unavailable

- `EKCalendar.cgColor` needs CoreGraphics, which is not a declared dependency.
- `EKStructuredLocation.geoLocation` and `init(mapItem:)` need Core Location
  and MapKit.
- `NotificationCenter.MessageIdentifier.changed` needs
  `NotificationCenter.BaseMessageIdentifier` / `MainActorMessage`, which this
  Linux Foundation overlay does not provide. `EKEventStore.EventStoreChanged`
  still exists as a standalone typed payload.

See `oracle-questions.tsv` for Apple-oracle probes.
