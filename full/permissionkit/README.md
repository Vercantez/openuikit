# PermissionKit (Linux starting point)

This directory is a fail-closed portable `PermissionKit` module for the
OpenUIKit Linux platform. It reconstructs the public Xcode 26.1 iPhoneOS
Swift surface from the sealed symbol graph and API digester. It is not wired
into the shared guest package; that integration is a separate central review
step.

Coverage: **109 implemented / 772 declared / 881 total**
(above the leaf-full floor of 705 nondeferred identifiers).

## What is real

- `PermissionChoice` and `PermissionChoice.Answer` (`approval`, `denial`)
  with equality, hashing, Codable round trips, title/answer mutation, and
  static `approve` / `decline` (Linux ids `approve`/`decline`).
- `CommunicationHandle` and `CommunicationHandle.Kind` (`phoneNumber`,
  `emailAddress`, `custom`) with equality, hashing, and Codable round trips.
- `CommunicationTopic.Action` in API-digester child order (`friend`,
  `follow`, `beFollowed`, `call`, `message`, `videoCall`, `audioCall`,
  `communicate`, `chat`, `connect`) with hashing and Codable round trips.
- `CommunicationTopic.PersonInformation` stores handle / name components;
  `avatarImage` defaults to `nil` and is omitted from Codable (no CoreGraphics
  image coder on this host). `init(personInformation:)` defaults `actions`
  to `[]`.
- `PermissionQuestion` convenience inits (`communicationTopic:`, `handle:`,
  `handles:`) with default choices `[.approve, .decline]`, `defaultChoice`
  `.approve`, and `expirationDate == nil`. Codable round-trips id, topic,
  choices, and TBD `title`/`subtitle`.
- `PermissionResponse` stores the question and chosen `PermissionChoice`.
- `AskError` cases in digester order, `errorDescription` strings, and
  LocalizedError defaults (`helpAnchor` / `failureReason` /
  `recoverySuggestion` are `nil`).
- `CommunicationLimits.current` is a process-local singleton.
- `CommunicationLimitsButton` stores the question and returns `label` as
  `body` without presenting a permission sheet.

## Fail-closed boundaries

Linux has no Screen Time daemon, Communication Limits entitlement, contact
sync, or system permission UI.

- `CommunicationLimits.ask` (UIKit overlay and the TBD question-only overload)
  throws `AskError.communicationLimitsNotEnabled`.
- `isKnownHandle` returns `false`; `knownHandles(in:)` returns `[]`.
- `updates` is an empty finished `AsyncStream`.
- SwiftUI `View` modifiers on `CommunicationLimitsButton` are identity
  no-ops declared for the overlay census. They do not layout or present UI.
- `CGImage` and `UIViewController` are module-local lookalikes when those
  modules are absent. They are not declared dependencies.

## Depth pass 2026-09

Fresh seed: no prior sources, coverage, or tests. After this pass:
**109 implemented / 772 declared**.

Top-5 implemented evidence distribution:

| Citations | Evidence |
| ---: | --- |
| 11 | `CommunicationTopicTests.swift#testCommunicationTopicActionCases` |
| 5 | `AskErrorTests.swift#testAskErrorCases` |
| 4 | `CommunicationHandleTests.swift#testCommunicationHandleKindCases` |
| 3 | `AskErrorTests.swift#testAskErrorLocalizedErrorDefaults` |
| 3 | `PermissionChoiceTests.swift#testPermissionChoiceApproveStatic` |

`testCommunicationTopicActionCases`, `testAskErrorCases`, and
`testCommunicationHandleKindCases` are table-driven enum member value tests.
No non-enum test exceeds the 40% bulk-relabel bound of the remaining
implemented rows.

The sealed host gate was run as `bash full/permissionkit/tests/acceptance/test_host.sh`.

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
missing from this snapshot; HEAD was the expected seed commit
`cbb368eeea236bbc0479fefa599190972ac8cfca`.
