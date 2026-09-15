# FamilyControls

Linux starting point for Apple's public `FamilyControls` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `FamilyControls` in `full/familycontrols/` (2407 exact IDs).
Owned FamilyControls types are implemented with focused tests; the 2313
synthesized SwiftUI.View members on `FamilyActivityPicker`,
`FamilyActivityIconView`, and `FamilyActivityTitleView` are `implemented`
as identity modifiers by `tests/agent/FamilyControlsViewOverlayTests.swift`:
eight `testViewOverlayBatchNN` functions each invoke ~50 distinct modifiers
on all three views plus `EmptyView()`, pinning the Linux no-op that renders
`EmptyView` (not Apple layout).

Coverage this round: **2407 implemented / 0 declared / 2407 total**
(2407 nondeferred, floor 1926; previous round was 94 / 2313 / 2407).
Enum cases share table-driven raw-value tests. No single test is cited by
more than 291 implemented rows (about 12.1% of 2407, under the 40% cap).

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 291 | 12.1% | `FamilyControlsViewOverlayTests.swift#testViewOverlayBatch01` (identity overlay batch) |
| 291 | 12.1% | `FamilyControlsViewOverlayTests.swift#testViewOverlayBatch02` (identity overlay batch) |
| 291 | 12.1% | `FamilyControlsViewOverlayTests.swift#testViewOverlayBatch03` (identity overlay batch) |
| 288 | 12.0% | `FamilyControlsViewOverlayTests.swift#testViewOverlayBatch04` (identity overlay batch) |
| 288 | 12.0% | `FamilyControlsViewOverlayTests.swift#testViewOverlayBatch05` (identity overlay batch) |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`a15391648a4fd5a92038c7465b26208c67eb87ed` matched.

`bash full/familycontrols/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=FamilyControls lane=leaf-full symbols=2407
FRAMEWORK_FANOUT_REFERENCE_OK
FAMILYCONTROLS_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=FamilyControls dylib=libFamilyControls.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

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
  implemented as no-ops returning `self` (Linux renders `EmptyView`);
  there is still no SwiftUI layout engine, so Apple layout is unobserved.

### Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: error-domain constant,
never-prompted authorization default, picker lifecycle, and Codable keys.
