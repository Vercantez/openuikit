# CoreLocationUI

Linux starting point for Apple's public `CoreLocationUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09

SDK depth for `CoreLocationUI` in `full/corelocationui/` (805 exact IDs).
This is a fresh seed: owned CoreLocationUI types are implemented with focused
tests; 773 synthesized SwiftUI.View members on `LocationButton` are
`declared` as identity modifiers (a bulk identity walk is not evidence of
Apple layout).

Coverage this round: **32 implemented / 773 declared / 805 total**
(805 nondeferred, floor 644). No non-enum test is cited by more than 2
implemented rows (6.3% of the 16 non-enum-member implemented rows). Enum
cases share table-driven raw-value tests.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 7 | 21.9% | `CoreLocationUILabelTests.swift#testLabelCases` (table-driven label enum / raw values) |
| 4 | 12.5% | `CoreLocationUIIconTests.swift#testIconCases` (table-driven icon enum / raw values) |
| 2 | 6.3% | `LocationButtonTests.swift#testSwiftLocationButtonBody` |
| 1 | 3.1% | 19 other focused tests, one identifier each |

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`e76572cf95a4cd2c803c340a1867409c4fc4c6a6` matched.

`origin/agent/fw-corelocationui` did not exist; this pass publishes that
branch from the Cursor-created work branch.

`bash full/corelocationui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreLocationUI lane=leaf-full symbols=805
FRAMEWORK_FANOUT_REFERENCE_OK
CORELOCATIONUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreLocationUI dylib=libCoreLocationUI.dylib
```

The campaign inventory stamp `CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean` is a host-inventory token, not printed by the sealed framework gate. `swiftc` is Swift 6.2.4 / linux and the gate compiled with a clean product tree.

### What is real

- `CLLocationButtonIcon` is `.none` (0), `.arrowFilled` (1), `.arrowOutline`
  (2), matching pinned macios `CLLocationButtonIcon`.
- `CLLocationButtonLabel` is `.none` (0), `.currentLocation` (1),
  `.sendCurrentLocation` (2), `.sendMyCurrentLocation` (3),
  `.shareCurrentLocation` (4), `.shareMyCurrentLocation` (5), matching
  pinned macios declaration order.
- `CLLocationButton` stores `icon`, `label`, `fontSize`, and `cornerRadius`,
  implements `NSSecureCoding` for those four properties, and accepts
  `init(frame:)`. Linux defaults: `icon == .none`, `label == .currentLocation`
  (WWDC21 default look), `fontSize == 0`, `cornerRadius == 0`.
- `LocationButton.Title` is a `Hashable` catalog of the five Darwin statics,
  equal when their `CLLocationButtonLabel` matches.
- `LocationButton.init(_:action:)` defaults the title to `.currentLocation`,
  stores `nil` when passed, and retains the action closure.
- `LocationButton.body` is `EmptyView`. `LocationButton.Body` is `EmptyView`.

### Fail-closed boundaries

- `CoreLocationUIHostControl.requestOneTimeAuthorization` and `activate`
  return `CoreLocationUIUnavailable.linuxHost`. They do not call Core
  Location, do not change authorization, and do not invoke `LocationButton`'s
  action (Apple's action runs after a location is determined).
- `CLLocationButton.sendActions(for:)` increments the host attempt counter
  and does not dispatch UIControl targets as a successful location grant.
- Linux identity `View` modifiers on `LocationButton` compile as `Self`
  no-ops (`CoreLocationUIViewSurface.swift`). They are **declared**, not
  implemented: there is no SwiftUI layout engine.

### Still deferred / unobserved

See `oracle-questions.tsv` for Apple-oracle probes: fresh-instance defaults,
action queue/timing, version-number bytes, and undersized-button failure
identity.
