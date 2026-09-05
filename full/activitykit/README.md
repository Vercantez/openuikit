# ActivityKit

This directory is an isolated Linux starting point for Apple's public
`ActivityKit` module. It reconstructs the Xcode 26.1 iPhoneOS 26.1 public
surface from the pinned symbol graph. It is not wired into the shared guest
package; that integration is a later central-review step.

The isolated host gate compiles only against toolchain Foundation. Passing
`test_host.sh` is not integrated Linux success and does not load guest
Foundation, SwiftUI, or WidgetKit.

## What is real

The isolated module publishes the graph types that do not require guest
Foundation:

- `ActivityAttributes` and `Activity<Attributes>`
- `ActivityContent`, `ActivityState`, `ActivityStyle`
- `ActivityAuthorizationInfo` and `ActivityAuthorizationError`
- `ActivityUIDismissalPolicy`, `PushType`

`Activity.request` runs an in-process Live Activity registry. Attributes and
`ContentState` round-trip through `JSONEncoder`/`JSONDecoder`. Combined JSON
larger than 4 KB throws `attributesTooLarge`. A process may hold eight
non-dismissed activities; a ninth throws `targetMaximumExceeded`. Empty or
slash-containing identifiers throw `malformedActivityIdentifier`. Duplicate
explicit ids throw `reconnectNotPermitted`.

`ActivityAuthorizationInfo.areActivitiesEnabled` and `frequentPushesEnabled`
read a stored process-local setting (default: activities enabled, frequent
pushes disabled). Enablement `AsyncSequence`s emit the current value, then
later changes, in order.

`update` / `end` transition `activityState` (`.active`, `.stale`, `.ended`,
`.dismissed`). `.default` dismissal is four hours after end; `.immediate`
dismisses at end; `.after(date)` dismisses at `min(date, end + 4h)`. An
injectable host clock also auto-ends an activity after eight hours of active
life. `activityUpdates`, `contentUpdates`, `contentStateUpdates`,
`activityStateUpdates`, and `pushTokenUpdates` deliver values in order.
`pushToken` stays `nil` unless a host test hook assigns bytes.

## Fail-closed boundaries

Linux has no Live Activity daemon, Dynamic Island / Lock Screen presentation,
ActivityKit push token service, broadcast channel, or
`NSSupportsLiveActivities` entitlement check. This port does not fabricate:

- Lock Screen or Dynamic Island UI
- APNs / push-to-start tokens (`pushToStartToken` is always `nil`)
- Settings.app or TCC prompts
- WidgetKit `ActivityConfiguration` / `DynamicIsland` (those types live in
  the WidgetKit seed, not this ActivityKit graph)

`areActivitiesEnabled == false` throws `.denied`. A host hook can also fail
closed with `.unsupported`, `.unentitled`, `.visibility`, and the remaining
`ActivityAuthorizationError` cases.

`AlertConfiguration` is omitted from the isolated compile. Its public IDs
require `Foundation.LocalizedStringResource`. ActivityKit does not ship a
same-named fallback. A future EC2 guest build must pass `-D OPENUIKIT_GUEST`
and link real guest Foundation so title and body are
`Foundation.LocalizedStringResource`. Prove that with
`tests/agent/ActivityKitDependencyIdentity.swift`.

`ActivityAuthorizationError.errorDomain` is the Swift-shaped
`ActivityKit.ActivityAuthorizationError`. Numeric `errorCode` values are
Linux-local discriminators, not observed Apple NSError codes.

## Still deferred

`AlertConfiguration` (including `AlertSound` and the request/update overloads
that take it) stays deferred until the guest Foundation identity probe runs.
Five synthesized `AsyncSequence` members that require `Element == UInt8` or
`Comparable` `ContentState` are `not-applicable`. See `oracle-questions.tsv`.

## Depth pass 2026-09

Wave-1 was fail-closed: every `request` threw `.unsupported` and sequences
completed empty. This depth pass replaces that with the process-local
registry above.

The first registry revision at `fe1738b` marked **298** identifiers
`implemented`, **17** `deferred`, and **5** `not-applicable`, but every
implemented evidence path was `tests/agent/ActivityKitRuntime.swift` (a file
path, not `test:full/activitykit/tests/agent/<File>Tests.swift#testName`).
Central merge refused that ledger.

This coverage repair keeps the registry and rewrites the ledger:

| | implemented | declared | deferred | not-applicable | nondeferred |
| --- | ---: | ---: | ---: | ---: | ---: |
| Before (`fe1738b`) | 298 | 0 | 17 | 5 | 298 |
| After | 244 | 54 | 17 | 5 | 298 |

`implemented` rows now cite a real top-level `func test*()` that exercises
that identifier. Enum members share table-driven value tests
(`testActivityStateCases`, `testActivityStyleCases`). Request error cases
are 1:1 with the throw path that produces them. Synthesized
`AsyncSequence` overloads that would hang on an infinite stream (or that
this host does not call) are `declared` with
`source:full/activitykit/ActivityKit.swift#<SequenceType>`.
`AlertConfiguration` stays deferred on guest Foundation.

Top-5 implemented evidence (244 rows). No non-enum test exceeds 3.3%
(40% cap would be 98 rows):

| rows | share | evidence |
| ---: | ---: | --- |
| 8 | 3.3% | `ActivitySequenceTests.swift#testActivityStateUpdatesIteration` |
| 8 | 3.3% | `ActivitySequenceTests.swift#testActivityUpdatesIteration` |
| 8 | 3.3% | `ActivitySequenceTests.swift#testContentUpdatesIteration` |
| 8 | 3.3% | `ActivitySequenceTests.swift#testPushTokenUpdatesIteration` |
| 8 | 3.3% | `ActivitySequenceTests.swift#testContentStateUpdatesIteration` |

The isolated host cannot compile `AlertConfiguration`, so 300
`implemented` and a fully nondeferred table remain blocked on guest
Foundation rather than on registry work. SwiftUI `ActivityConfiguration` /
`DynamicIsland` / `LiveActivityIntent` are not in this seed's public
surface; they belong to WidgetKit / AppIntents.

Host SPI (`@_spi(OpenUIKitHost)` `OpenUIKitActivityKitTesting`) resets the
registry, writes enablement flags, freezes the clock, and assigns a test
push token. It does not claim Apple presentation.
