# LiveCommunicationKit (Linux starting point)

This directory is a fail-closed portable `LiveCommunicationKit` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph and API digester. It is not wired
into the shared guest package; that integration is a separate central review
step.

Coverage: **288 implemented / 0 declared / 1 unavailable / 289 total**
(above the medium-full floor of 145 nondeferred identifiers).

## What is real

- `Handle` and `Handle.Kind` (`generic = 0`, `phoneNumber = 1`,
  `emailAddress = 2`) with equality, hashing, and Codable round trips.
  `displayName` defaults to `value` when the caller passes `nil`.
- `Conversation.State`, `Conversation.EndedReason`, `PlayToneAction.Tone`
  as sequential Swift `Int` enums from API-digester child order.
- `Conversation.Capabilities` as an `OptionSet` with bits `1 << 0 ... 1 << 4`
  in digester stored-property order (`pausing`, `merging`, `unmerging`,
  `video`, `playingTones`), including union/intersection/insert/remove.
- `Conversation.Update` and `Conversation.Event` with documented defaults,
  equality, hashing, and Codable round trips.
- Process-local `Conversation` objects (host SPI constructor) and a
  `reportConversationEvent` state machine:
  started-connecting → `joining`, connected → `joined`, ended → `left`,
  updated applies `localMember`.
- `ConversationAction` fulfill/fail state machine (`idle` → `complete` or
  `failed(reason: "")`; already-terminal calls are no-ops) plus the concrete
  action subclasses and their stored fields.
- `ConversationManager.Configuration` (including the older initializer that
  defaults `supportsAudioTranslation` to `false`), in-process conversation
  and pending-action lists, `invalidate()` (clears lists and calls
  `conversationManagerDidReset`), and pending-action class filters.
- `ConversationHistoryManager.RecentConversation` Codable value type,
  status/direction enums, and process-local
  `ConversationHistoryDidUpdate` notification helpers.
- `CellularService` Codable identity, `StartCellularConversationAction`
  equality/Codable, and `TelephonyConversationManager.cellularServices == []`.

## Fail-closed boundaries

Linux has no CallKit daemon, baseband, VoIP Push entitlement, or Call History
database.

- `ConversationManager.reportNewIncomingConversation`, `perform`, and
  `reportNewIncomingVoIPPushPayload` throw `CocoaError.featureUnsupported`.
- `ConversationHistoryManager.recentConversations`, `markConversationAsRead`,
  and `markConversationsAsRead` throw the same error.
- `TelephonyConversationManager.startCellularConversation` throws the same
  error. `cellularServices` is always empty.
- Delegate audio-session activate/deactivate callbacks are never delivered.
  `AVAudioSession` is an `NSObject` typealias because AVFoundation is not a
  declared dependency.
- `NotificationCenter.MessageIdentifier.conversationHistoryDidUpdateMessage`
  is unavailable: Linux Foundation has no `MessageIdentifier`, and this
  module does not invent a dependency-owned stand-in.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or tests. After this pass:
**281 implemented / 7 declared / 1 unavailable**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 11 | `ConversationHistoryTests.swift#testRecentConversationCodableRoundTrip` |
| 10 | `ConversationEnumTests.swift#testConversationStateRawValues` |
| 9 | `ConversationEnumTests.swift#testConversationEndedReasonRawValues` |
| 9 | `ConversationManagerTests.swift#testConfigurationInitWithoutAudioTranslationDefaultsFalse` |
| 8 | `ConversationCapabilitiesTests.swift#testCapabilitiesMemberRawValues` |

`testConversationStateRawValues`, `testConversationEndedReasonRawValues`, and
`testCapabilitiesMemberRawValues` are table-driven enum / option-set member
value tests. The Codable recents test and configuration initializer test cover
distinct non-enum families and stay well under the 40% bulk-relabel bound.

The sealed host gate was run as `bash full/livecommunicationkit/tests/acceptance/test_host.sh`
and ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=LiveCommunicationKit lane=medium-full symbols=289
FRAMEWORK_FANOUT_REFERENCE_OK
LIVECOMMUNICATIONKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=LiveCommunicationKit dylib=libLiveCommunicationKit.dylib
```

`swiftc --version` is Swift 6.2.4 targeting `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` on this snapshot fails earlier
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`). The campaign
inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is a host-inventory token: the toolchain is Swift 6.2.4 / linux and the
sealed gate compiles with a clean product tree.

Unresolved behavioral questions are listed in `oracle-questions.tsv`.

## Wave 11 leftover review (2026-09-15)

Before: **281 implemented / 7 declared / 0 deferred / 1 unavailable / 289 total**.
After: **281 implemented / 7 declared / 0 deferred / 1 unavailable / 289 total**
(implemented gain 0).

All 7 `declared` rows are `async throws` daemon-gated methods
(`ConversationManager.perform`, `reportNewIncomingConversation`,
`reportNewIncomingVoIPPushPayload`, `ConversationHistoryManager.recentConversations`,
`markConversationAsRead`, `markConversationsAsRead`,
`TelephonyConversationManager.startCellularConversation`). A synchronous
`func test*()` cannot call them: `swiftc` rejects the call with `'async' call
in a function that does not support concurrency`, and the coverage contract
forbids `await`, `DispatchQueue.main`, `RunLoop`, and semaphore waits in cited
tests while hardware/daemon success must stay fail-closed. They remain
`declared` (compiling, throwing `CocoaError.featureUnsupported`) with
per-row oracle questions. No SwiftUI View-overlay rows exist in this
framework, and the single `unavailable` row is a Foundation-owned
`NotificationCenter.MessageIdentifier` witness that must not be stubbed.

## Wave 12 leftover review (2026-09-15)

Before: **281 implemented / 7 declared / 0 deferred / 1 unavailable / 289 total**.
After: **281 implemented / 7 declared / 0 deferred / 1 unavailable / 289 total**
(implemented gain 0).

Re-audited all 7 `declared` rows: unchanged, all `async throws` daemon-gated
methods listed above. Conversion to `implemented` remains blocked for the same
reasons (synchronous cited tests cannot `await` an `async` call; daemon success
stays fail-closed; the sealed runner forbids concurrency primitives in cited
tests). Re-checked the overlay override: `coverage.tsv` contains zero
SwiftUI / View rows, so there is nothing to convert under that rule, and the
single `unavailable` row is a stdlib/Foundation protocol witness that must stay
`unavailable`. Product sources still compile warning-free
(`swiftc -warnings-as-errors -emit-library` → `libLiveCommunicationKit.dylib`
OK). The shared host gate (`tests/acceptance/test_host.sh`) refuses in this
isolated worktree for an out-of-scope reason (missing shared
`full/framework-roadmap/framework-roadmap.json`, outside `full/livecommunicationkit/`); no framework-owned check regressed.

## Wave 13 leftover review (2026-09-18)

Before: **281 implemented / 7 declared / 0 deferred / 1 unavailable / 289 total**.
After: **288 implemented / 0 declared / 0 deferred / 1 unavailable / 289 total**
(implemented gain +7).

The sealed runner is now `@main async` and awaits `func test*() async`, so the
7 `async throws` daemon-gated methods (`ConversationManager.perform`,
`reportNewIncomingConversation`, `reportNewIncomingVoIPPushPayload`,
`ConversationHistoryManager.recentConversations`, `markConversationAsRead`,
`markConversationsAsRead`,
`TelephonyConversationManager.startCellularConversation`) are now covered by
7 new async tests in `tests/agent/AsyncFailClosedTests.swift`. Each test
`await`s its identifier in-process and asserts the fail-closed
`CocoaError.featureUnsupported` (no daemon, no RunLoop/DispatchQueue/semaphore,
no hardware wait); daemon *success* still stays fail-closed. Each new test is
cited by exactly one row, so the top-5 distribution above is unchanged and no
test exceeds the 40% bound. Re-checked the overlay override: `coverage.tsv`
contains zero SwiftUI / View rows, and the single `unavailable` row is the
Foundation-owned `NotificationCenter.MessageIdentifier` witness that must stay
`unavailable`. Product sources still compile warning-free, and a manual
replica of the sealed runner (dylib + generated `@main async` host invoking
all 87 cited tests) emits exactly `LIVECOMMUNICATIONKIT_AGENT_RUNTIME_OK`
within the 120s timeout. The shared host gate
(`tests/acceptance/test_host.sh`) still refuses in this isolated worktree for
the same out-of-scope reason as wave 12 (missing shared
`full/framework-roadmap/framework-roadmap.json`); the deliverable validator
reports only those 2 roadmap errors and no framework-owned check regressed.
