# SharedWithYou

Linux starting point for Apple's public `SharedWithYou` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph (141 exact IDs). Isolated
host-gate success is not integrated Linux Messages / CloudKit success.

## Depth pass 2026-09

Implemented **126** identifiers, declared **2**, deferred **13** (128
nondeferred; floor 71). Enum / option-set members and `init(rawValue:)`
share one table-driven value test, which the seed contract allows.

Top-5 implemented evidence distribution:

| Rows | Share of implemented | Evidence |
| ---: | ---: | --- |
| 56 | 44.4% (enum family) | `SharedWithYouEnumTests.swift#testEnumRawValues` |
| 3 | 2.4% | `SWHighlightEventTests.swift#testChangeEventInit` |
| 3 | 2.4% | `SWHighlightEventTests.swift#testMembershipEventInit` |
| 3 | 2.4% | `SWHighlightEventTests.swift#testMentionEventHandleInit` |
| 3 | 2.4% | `SWHighlightEventTests.swift#testPersistenceEventInit` |

No non-enum test is cited by more than 3 of the remaining 70 implemented
rows (4.3%, under the 40% bulk-relabel cap).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit the campaign
`products=clean` line because `scratch/ladder-corpus/focus-ios` is absent
from this snapshot; the sealed framework gate does not require that
checkout. Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`a15391648a4fd5a92038c7465b26208c67eb87ed` matched.

### What is real

- Attribution / highlight-center / change / membership / persistence
  enumerations with macios-pinned raw values, including triggers that
  start at 1 (`edit` / `addedCollaborator` / `created`).
- `SWHighlightCenterErrorCode` bridged to `SWHighlightErrorDomain` with
  exact codes `0...3`. Lookups throw or complete with `accessDenied`.
- `SWHighlight` / `SWCollaborationHighlight` value storage, `NSCopying`,
  and `NSSecureCoding` round trips. Darwin default constructors stay
  unavailable; tests use host SPI fixtures.
- Event types retain the highlight URL and trigger / mention handle.
  `postNotice` / `clearNotices` maintain a process-local ledger and never
  contact Messages.
- Attribution and collaboration views store presentation fields.
  `highlightMenu` is empty. `dismissPopover` runs the completion and does
  not present UI.
- `isSystemCollaborationSupportAvailable` is `false`.
  `highlightCollectionTitle` is empty (no Messages catalog).

### Fail-closed boundaries

- No Messages Shared with You daemon, CloudKit sharing sheet, or
  collaboration identity service.
- `getHighlightFor`, `collaborationHighlight(forIdentifier:)`, and
  `getSignedIdentityProof` never fabricate highlights or signatures.
- `SWRemoveParticipantAlertController` constructs and never presents.
- Isolated-host UIKit / `UTType` / `NSItemProvider` lookalikes compile
  out when those modules are on the link line. They are not a UIKit port.

### Deferred

CoreTransferable `SWCollaborationMetadata` transfer APIs and SwiftUI
`setDetailViewListContent` overlays. Those modules are not declared
isolated-host dependencies.

### Gate

```
bash full/sharedwithyou/tests/acceptance/test_host.sh
```
