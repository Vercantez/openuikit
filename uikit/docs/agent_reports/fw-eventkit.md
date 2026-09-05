# EventKit SDK depth — local on-disk store

Wave-1 starting point: **299 implemented / 199 declared / 13 deferred** (511 IDs).
After this branch: **511 implemented / 0 declared / 0 deferred**.

No iOS scene pixel rule. The named work is `full/eventkit/` plus this report
and one fidelity-table row.

## What was measured

Host gate `bash tests/acceptance/test_host.sh` (Darwin, warnings-as-errors):

| check | before | after |
|---|---|---|
| nondeferred (`implemented`+`declared`) | 498 / 511 | **511 / 511** |
| `implemented` | 299 | **511** |
| `deferred` | 13 | **0** |
| runtime marker | `EVENTKIT_AGENT_RUNTIME_OK` | same |

On-disk store directory: Application Support **`OpenUIKit/EventKit/store.json`**.
Tests isolate with `EKEventStore.useIsolatedStoreDirectory`.

Authorization (process-local sandbox, not TCC):

- starts `.notDetermined` (raw 0)
- `requestFullAccessToEvents` / `requestAccess(to: .event)` → `.fullAccess` (3), completion `(true, nil)` off the caller stack
- `requestWriteOnlyAccessToEvents` → `.writeOnly` (4); save succeeds; `events(matching:)` returns `[]`
- `EKEventStore.denyAccessRequests` → `.denied` (2), completion `(false, nil)` without throwing

Recurrence expansion, Gregorian, `TimeZone(secondsFromGMT: 0)`, DTSTART 09:00
(`EKRecurrenceExpansion` SPI, also `EKEventStore.events(matching:)`):

| rule | start | result |
|---|---|---|
| daily COUNT 3 | 2026-01-01 | 1, 2, 3 Jan |
| daily interval 2 COUNT 3 | 2026-01-01 | 1, 3, 5 Jan |
| weekly Monday COUNT 4 | 2026-01-05 (Monday) | 5, 12, 19, 26 Jan |
| weekly MO,WE,FR COUNT 6 | 2026-01-05 | 5, 7, 9, 12, 14, 16 Jan |
| monthly BYMONTHDAY=15 COUNT 3 | 2026-01-15 | 15 Jan, 15 Feb, 15 Mar |
| monthly BYDAY=-1FR COUNT 3 | 2026-01-30 | 30 Jan, 27 Feb, 27 Mar |
| yearly BYMONTH=1 BYMONTHDAY=1 COUNT 3 | 2026-01-01 | 2026, 2027, 2028 |

`EKSpan.thisEvent` on a daily COUNT 5 series: remove the third occurrence → 4
left in the window (EXDATE). `EKEventStoreChanged` posted once after
`save(_:span:commit: true)`.

macOS 26 MapKit probe (`MKMapItem(location:address:)`): `name = "Apple Park"`
round-trips to `EKStructuredLocation.title`; `location.coordinate.latitude`
37.3349 round-trips to `geoLocation`. `placemark` is deprecated (warnings-as-errors).

`CGColor(red: 0, green: 0.478, blue: 1, alpha: 1)` components
`[0.0, 0.478, 1.0, 1.0]` — port default for a new local calendar, **not**
measured from Calendar.app.

Reminder priority bands (documented mapping, save rejects 99 with
`priorityIsInvalid` raw 25): 0 none, 1–4 high, 5 medium, 6–9 low.

## Rule

Local store under `OpenUIKit/EventKit`, authorization
`.notDetermined → .fullAccess/.writeOnly/.denied`, recurrence expanded over
Foundation `Calendar` using the GMT samples above, `EKSpan` detach/split,
`EKEventStoreChanged` after disk commit. Darwin `EventStoreChanged` keeps
`NotificationCenter.MainActorMessage`; Linux compiles the struct without it.

## Open

See `full/eventkit/oracle-questions.tsv`: Darwin TCC persistence, fetchReminders
unauthorized `nil` vs `[]`, notification queue, Calendar.app default cgColor,
whether `thisEvent` on DTSTART updates the master.

## Gates

- Host `tests/acceptance/test_host.sh`: `EVENTKIT_AGENT_RUNTIME_OK`.
- Linux `swift:6.2-noble`: EventKit `swiftc` dylib OK (`NSPredicate` designated
  `init(value: true)` on Linux; Darwin `init()`). openrender release green
  (233.78 s).
- Catalyst / iOS suite / real-app: no OpenUIKit render change.
