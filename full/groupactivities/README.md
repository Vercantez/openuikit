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
