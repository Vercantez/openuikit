# GroupActivities

This directory is an isolated Linux starting point for Apple's public
`GroupActivities` module, reconstructed from the Xcode 26.1 iPhoneOS 26.1
symbol graph. It is not wired into the shared guest package; that integration is
a later central-review step.

The isolated host gate compiles only against toolchain Foundation. Passing
`test_host.sh` is not integrated Linux success and does not load guest
Foundation, Combine, UIKit, AVFoundation, or CoreTransferable.

## What is real

Value types and process-local state machines that do not require Apple services:

- `GroupActivityMetadata`, `ActivityType`, `Experience` (raw 0/1), `LifetimePolicy`
- `BroadcastOptions` (`mirroredVideo = 1 << 0`) and full `OptionSet` arithmetic
- `SceneAssociationBehavior`, `GroupActivityActivationResult`, `GroupActivitySharingResult`
- `Participant`, `Participants`, `GroupSessionEvent` and queue-change actions
- `GroupSession` join / leave / end (`waiting` → `joined` → `invalidated`)
- `GroupSessionMessenger` completion-based `send` (inline fail-closed)
- `GroupSessionJournal` attachments sequence (empty; no Transferable pipeline)
- `GroupStateObserver.isEligibleForGroupSession` (always `false`)
- `GroupActivity.activityIdentifier` default and empty `sessions()`

`GroupSession` has no public Apple initializer. Host tests construct sessions
through `@_spi(OpenUIKitHost) GroupSession.makeHostSession`.

## Fail-closed boundaries

Linux has no SharePlay / FaceTime / Messages daemon, Nearby Interaction,
`CoreTransferable` journal, or UIKit sharing sheet. This port does not
fabricate:

- A successful `activate()` (throws `GroupActivitiesHostError.sharePlayUnavailable`)
- Eligibility (`isEligibleForGroupSession` is always false;
  `prepareForActivation()` returns `.activationDisabled`)
- Incoming `sessions()`, messenger `messages(of:)`, or journal attachments
- Nearby presence (`isNearbyWithLocalParticipant` is always false)
- Foreground presentation or system notices (calls are recorded, not shown)
- `NSItemProvider` registration (type missing on Linux Foundation)
- `AVPlaybackCoordinator.coordinateWithSession` (AVFoundation not linked)
- `GroupActivitySharingController` (UIKit)

`GroupActivitiesHostError` is a Linux-local `CustomNSError`. Codes are host
discriminators, not observed Apple values.

## Still deferred

- Combine `$` publishers and `objectWillChange` (Combine is not a declared dependency)
- `GroupActivityMetadata.previewImage` (`CGImage`)
- `GroupActivityTransferRepresentation` and `transferRepresentation`
- Journal `add` / `Attachment.load` Transferable overloads
- Swift.AsyncSequence protocol extensions (`map`, `filter`, …) are
  `not-applicable`: they are stdlib-owned

See `oracle-questions.tsv`.

## Wave 13 2026-09-18

Recount: **216 implemented / 0 declared / 21 deferred / 66 not-applicable /
10 unavailable** of 313 (216 nondeferred). Before: 206 implemented / 10 declared.
Implemented gain: **+10** (declared is now empty).

The sealed host runner now awaits top-level `func test*() async`, so all 10
leftover declared async witnesses converted to `implemented` with focused
in-process async tests in `tests/agent/GroupActivitiesAsyncTests.swift` —
each cited exactly once, so the worst implemented-evidence share stays
`testGroupSessionEventActions` at 8.3% (18/216), well under the 40% cap:

- `Attachment.loadMetadata(of:)` throws `journalUnavailable` →
  `testJournalAttachmentLoadMetadataAsync`
- `Attachments.Iterator.next()` returns `nil` (empty) →
  `testJournalAttachmentsIteratorNextAsync`
- `Journal.remove(attachment:)` throws `journalUnavailable` →
  `testJournalRemoveAttachmentAsync`
- Async `Messenger.send(Data)` / `send(Message)` throw `messengerUnavailable` →
  `testMessengerSendDataAsync` / `testMessengerSendMessageAsync`
- `Messages.Iterator.next()` returns `nil` (empty) →
  `testMessengerMessagesIteratorNextAsync`
- `Sessions.Iterator.next()` returns `nil` (empty) →
  `testSessionsIteratorNextAsync`
- Async `metadata` getter returns the probe's default metadata →
  `testActivityMetadataGetterAsync`
- `prepareForActivation()` returns `.activationDisabled` →
  `testPrepareForActivationAsync`
- `activate()` throws `sharePlayUnavailable` → `testActivateAsync`

No `DispatchQueue.main` / `RunLoop` / semaphore waits; every awaited call
completes in-process (immediate throw or empty-sequence `nil`). The 21
deferred rows still require `Combine`, `CoreTransferable`, or `CoreGraphics`,
none a declared isolated-host dependency. The 66 `not-applicable` rows are
stdlib `AsyncSequence` / `AsyncIteratorProtocol` witnesses the contract
excludes from conversion; the 10 `unavailable` rows are UIKit /
`NSItemProvider` / `AVFoundation` overlays. This slug has no SwiftUI identity
View-modifier rows, so the overlay override is not applicable.

Validation on macOS: product sources compile under
`swiftc -warnings-as-errors`, the dylib links, and a Darwin runner invoking
all 75 top-level `test*()` functions (65 sync + 10 async, awaiting the
async ones) exits 0 with sole stdout
`GROUPACTIVITIES_AGENT_RUNTIME_OK` and empty stderr.

## Wave 12 2026-09-15

Recount: **206 implemented / 10 declared / 21 deferred / 66 not-applicable /
10 unavailable** of 313 (216 nondeferred). Before: identical counts.
Implemented gain: **0**.

Re-examined all 31 leftover rows for in-process conversion; none qualifies:

- All 10 declared rows are `async` witnesses, re-verified `async` in product
  sources via grep (`Attachment.loadMetadata`, `Attachments.Iterator.next`,
  `Journal.remove`, two messenger `send` overloads, `Messages.Iterator.next`,
  `Sessions.Iterator.next`, async `metadata` getter, `prepareForActivation`,
  `activate`). Calling one from a top-level synchronous no-argument `test*()`
  is a compile error, and the sealed runner forbids `await` /
  `DispatchQueue.main` / `RunLoop` / semaphore waits. A `Task { await ... }`
  fire-and-forget wrapper would still place the banned `await` token in the
  cited test, so no declared row can convert without weakening the gate.
- All 21 deferred rows require `Combine`, `CoreTransferable`, or
  `CoreGraphics`, none a declared isolated-host dependency; AGENTS.md
  forbids framework-local substitutes for dependency-owned types.
- The 66 `not-applicable` rows are stdlib `AsyncSequence` /
  `AsyncIteratorProtocol` witnesses the contract explicitly excludes from
  conversion (stdlib/Foundation protocol witnesses stay n/a); the 10
  `unavailable` rows are UIKit / `NSItemProvider` / `AVFoundation` overlays.
  This slug has no SwiftUI identity View-modifier rows, so the overlay
  override is not applicable.

Validation on macOS: product sources compile under
`swiftc -warnings-as-errors`, the dylib links, and a Darwin runner invoking
all 65 top-level `test*()` functions (61 cited by implemented evidence)
exits 0 with sole stdout `GROUPACTIVITIES_AGENT_RUNTIME_OK`. Evidence audit:
no banned constructs in test files, worst implemented-evidence share
`testGroupSessionEventActions` at 8.7% (18/206), well under the 40% cap.

## Wave 11 2026-09-15

Recount: **206 implemented / 10 declared / 21 deferred / 66 not-applicable /
10 unavailable** of 313 (216 nondeferred). Before: identical counts.
Implemented gain: **0**.

Re-examined all 31 leftover rows for in-process conversion; none qualifies:

- All 10 declared rows are `async` witnesses (`Attachment.loadMetadata`,
  `Attachments.Iterator.next`, `Journal.remove`, two messenger `send`
  overloads, `Messages.Iterator.next`, `Sessions.Iterator.next`, async
  `metadata` getter, `prepareForActivation`, `activate`). Product sources
  re-verified `async` via grep; calling one from a top-level synchronous
  no-argument `test*()` is a compile error, and the sealed runner forbids
  `await` / `DispatchQueue.main` / `RunLoop` / semaphore waits.
- All 21 deferred rows require `Combine`, `CoreTransferable`, or
  `CoreGraphics`, none a declared isolated-host dependency; AGENTS.md
  forbids framework-local substitutes for dependency-owned types.
- The 66 `not-applicable` rows are stdlib `AsyncSequence` /
  `AsyncIteratorProtocol` witnesses the contract explicitly excludes from
  conversion; the 10 `unavailable` rows are UIKit / `NSItemProvider` /
  `AVFoundation` overlays. This slug has no SwiftUI identity View-modifier
  rows, so the overlay override is not applicable.

Validation on macOS: product sources compile under
`swiftc -warnings-as-errors`, the dylib links, and a Darwin runner invoking
all 61 cited `test*()` functions exits 0 with sole stdout
`GROUPACTIVITIES_AGENT_RUNTIME_OK`. Evidence audit: 0 malformed citations,
no banned constructs in test files, worst implemented-evidence share
`testGroupSessionEventActions` at 8.7% (18/206), well under the 40% cap.

## Wave 10 2026-09-15

Recount: **206 implemented / 10 declared / 21 deferred / 66 not-applicable /
10 unavailable** of 313 (216 nondeferred). Before: identical counts.
Implemented gain: **0**.

Re-examined all 31 leftover rows for in-process conversion; none qualifies:

- All 10 declared rows are `async` witnesses (`Attachment.loadMetadata`,
  `Attachments.Iterator.next`, `Journal.remove`, two messenger `send`
  overloads, `Messages.Iterator.next`, `Sessions.Iterator.next`, async
  `metadata` getter, `prepareForActivation`, `activate`). Calling one from a
  top-level synchronous no-argument `test*()` is a compile error, and the
  sealed runner forbids `await` / `DispatchQueue.main` / `RunLoop` /
  semaphore waits — so none can convert to `implemented` without weakening
  the gate.
- All 21 deferred rows require `Combine`, `CoreTransferable`, or
  `CoreGraphics`, none a declared isolated-host dependency; AGENTS.md
  forbids framework-local substitutes for dependency-owned types.
- The 66 `not-applicable` rows are stdlib `AsyncSequence` /
  `AsyncIteratorProtocol` witnesses the contract explicitly excludes from
  conversion; the 10 `unavailable` rows are UIKit / `NSItemProvider` /
  `AVFoundation` overlays. This slug has no SwiftUI identity View-modifier
  rows, so the overlay override is not applicable.

Manual host-equivalent validation on macOS (the in-worktree
`tests/acceptance/test_host.sh` additionally demands a
`full/framework-roadmap/framework-roadmap.json` file that does not exist in
this isolated worktree, outside this slug's editable scope): product sources
compile under `swiftc -warnings-as-errors`, the dylib links, and a
Darwin-based equivalent runner invokes all 61 cited `test*()` functions
with sole stdout `GROUPACTIVITIES_AGENT_RUNTIME_OK` and empty stderr.
Worst implemented-evidence share: `testGroupSessionEventActions` at 8.7%
(18/206), well under the 40% cap.

## Wave 9 2026-09-15

Recount: **206 implemented / 10 declared / 21 deferred / 66 not-applicable /
10 unavailable** of 313 (216 nondeferred). Before: identical counts.
Implemented gain: **0**.

All 10 declared rows are async witnesses (`Attachment.loadMetadata`,
`Attachments.Iterator.next`, `Journal.remove`, two messenger `send` overloads,
`Messages.Iterator.next`, `Sessions.Iterator.next`, async `metadata` getter,
`prepareForActivation`, `activate`). The sealed runner only invokes top-level
synchronous no-argument `test*()` with no `await` (and no
`DispatchQueue.main` / `RunLoop` / semaphore waits), and calling an `async`
witness from a synchronous context is a compile error — so none can convert
to `implemented` without weakening the gate. All 21 deferred rows require
`Combine`, `CoreTransferable`, or `CoreGraphics`, none a declared
isolated-host dependency. This slug has no SwiftUI View-modifier overlay rows,
so the identity-overlay override is not applicable; the 66 `not-applicable`
rows are stdlib/ synthesized witnesses owned outside GroupActivities.

Manual host-equivalent validation on macOS (the shared
`test_host.sh` validator in this worktree additionally demands a
`full/framework-roadmap/framework-roadmap.json` file that does not exist
here, and its runner template targets Linux `Glibc`): product sources compile
under `swiftc -warnings-as-errors`, the dylib links, and a Darwin-based
equivalent runner invokes all 61 cited `test*()` functions with sole stdout
`GROUPACTIVITIES_AGENT_RUNTIME_OK`.

## Depth pass 2026-09

Implemented count: **206** of 313 public identifiers (216 nondeferred with
10 declared async witnesses). Top-5 implemented evidence distribution:

1. `testGroupSessionEventActions` — 18
2. `testActivityTypeCatalog` — 14
3. `testMetadataMutationAndEquality` — 13
4. `testJournalAttachmentsSequence` — 9
5. `testExperienceRawValues` / `testParticipantIdentity` — 9 each

Enum and option-set members share table-driven value tests. Remaining rows
use focused per-family tests; no single non-member test exceeds 40% of
implemented evidence.
