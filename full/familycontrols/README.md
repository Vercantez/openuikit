# FamilyControls

Linux starting point for Apple's public `FamilyControls` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `FamilyControls` in `full/familycontrols/` (2407 exact IDs).
This is a fresh seed: owned FamilyControls types are implemented with focused
tests; 2313 synthesized SwiftUI.View members on `FamilyActivityPicker`,
`FamilyActivityIconView`, and `FamilyActivityTitleView` are `declared` as
identity modifiers (a bulk identity walk is not evidence of Apple layout).

Coverage this round: **94 implemented / 2313 declared / 2407 total**
(2407 nondeferred, floor 1926). Enum cases share table-driven raw-value
tests. No non-enum test is cited by more than 4 implemented rows
(about 5% of the 81 non-enum-member implemented rows).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 11 | 11.7% | `FamilyControlsErrorTests.swift#testErrorCases` (table-driven error enum / raw values) |
| 6 | 6.4% | `AuthorizationStatusTests.swift#testStatusCases` (table-driven status enum / raw values) |
| 5 | 5.3% | `FamilyControlsMemberTests.swift#testMemberCases` (table-driven member enum / raw values) |
| 4 | 4.3% | `FamilyControlsErrorTests.swift#testErrorNSErrorSurface` |
| 3 | 3.2% | `FamilyControlsErrorTests.swift#testErrorLocalizedDefaults` |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`a15391648a4fd5a92038c7465b26208c67eb87ed` matched.

`bash full/familycontrols/tests/acceptance/test_host.sh` is the sealed gate.

### What is real

- `FamilyControlsError` is an `Int` enum in api-digester order: `.restricted`
  (0), `.unavailable` (1), `.invalidAccountType` (2), `.invalidArgument` (3),
  `.authorizationConflict` (4), `.authorizationCanceled` (5), `.networkError`
  (6), `.authenticationMethodUnavailable` (7). Linux `errorDomain` is
  `FamilyControls.FamilyControlsError`.
- `FamilyControlsMember` is `.child` (0), `.individual` (1).
- `AuthorizationStatus` is `.notDetermined` (0), `.denied` (1), `.approved` (2).
- `AuthorizationCenter.shared.authorizationStatus` is always `.denied`.
  `requestAuthorization` and `revokeAuthorization` always fail with
  `.unavailable`.
- `FamilyActivitySelection` stores tokens and `includeEntireCategory`,
  round-trips those fields through `Codable`, and keeps resolved
  `applications` / `categories` / `webDomains` empty.
- `FamilyActivityPicker`, `FamilyActivityIconView`, and
  `FamilyActivityTitleView` render `EmptyView`. Label token inits compile.
  `familyActivityPicker` modifiers return `self`.

### Fail-closed boundaries

- Linux never grants FamilyControls, never presents the picker, and never
  resolves tokens to apps, categories, or web domains.
- Completions run inline so tests without a run loop can observe
  `.unavailable`. Apple's callback queue is unobserved.
- Identity `View` modifiers in `FamilyControlsViewSurface.swift` are
  **declared**, not implemented: there is no SwiftUI layout engine.

### Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: error-domain constant,
never-prompted authorization default, picker lifecycle, and Codable keys.
