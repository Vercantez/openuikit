# CoreLocationUI

Linux starting point for Apple's public `CoreLocationUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success
is not integrated Linux success.

## Depth pass 2026-09 (wave 8)

SDK depth for `CoreLocationUI` in `full/corelocationui/` (805 exact IDs).
This wave completed the two remaining owned, non-overlay identifiers by adding
focused tests for the `Hashable.hash(into:)` requirements. The other 771 rows
are synthesized SwiftUI.View members on `LocationButton` and remain
`declared` as identity modifiers (a bulk identity walk is not evidence of
Apple layout).

Coverage before: **32 implemented / 773 declared / 0 deferred / 0 unavailable /
0 not-applicable**. Coverage after: **34 implemented / 771 declared /
0 deferred / 0 unavailable / 0 not-applicable** (805 nondeferred, floor 644).
Every owned, non-overlay row is now implemented. Enum cases share table-driven
raw-value tests; each newly implemented hashing row has its own focused test.

Top-5 implemented evidence:

| Rows | Share | Evidence |
| ---: | ---: | --- |
| 7 | 20.6% | `CoreLocationUILabelTests.swift#testLabelCases` (table-driven label enum / raw values) |
| 4 | 11.8% | `CoreLocationUIIconTests.swift#testIconCases` (table-driven icon enum / raw values) |
| 2 | 5.9% | `LocationButtonTests.swift#testSwiftLocationButtonBody` |
| 1 | 2.9% | `CoreLocationUIIconTests.swift#testIconHashInto` |
| 1 | 2.9% | `CoreLocationUILabelTests.swift#testLabelHashInto` |

The run started at the required commit
`bb6dc91c7e2e71dcedb4f664316cb8318df1720a`. Environment verification emitted
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=scratch-corpus evidence=dotnet-macios`.

`bash full/corelocationui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreLocationUI lane=leaf-full symbols=805
FRAMEWORK_FANOUT_REFERENCE_OK
CORELOCATIONUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreLocationUI dylib=libCoreLocationUI.dylib
```

### What is real

- `CLLocationButtonIcon` is `.none` (0), `.arrowFilled` (1), `.arrowOutline`
  (2), matching pinned macios `CLLocationButtonIcon`.
- `CLLocationButtonLabel` is `.none` (0), `.currentLocation` (1),
  `.sendCurrentLocation` (2), `.sendMyCurrentLocation` (3),
  `.shareCurrentLocation` (4), `.shareMyCurrentLocation` (5), matching
  pinned macios declaration order.
- Both raw-value enums provide and behaviorally exercise deterministic
  same-value `Hashable.hash(into:)` behavior within a process.
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
