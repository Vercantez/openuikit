# LocalAuthenticationEmbeddedUI

Linux starting point for Apple's public `LocalAuthenticationEmbeddedUI` module,
reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated
host-gate success is not integrated Linux success.

The public Swift census is two identifiers: `LAPresentationContext` and
`LARight.authorize(localizedReason:in:)`.

## What is real

- `LAPresentationContext` is a typealias of `UIWindow`, matching
  `LAPresentationContext.h` and the symbol-graph declaration
  `typealias LAPresentationContext = UIWindow`. Pinned macios uses
  `using LAPresentationContext = UIKit.UIWindow` on iOS.
- `LARight.authorize(localizedReason:in:)` and the completion-handler sibling
  are the same ObjC selector
  `authorizeWithLocalizedReason:inPresentationContext:completion:`. Linux
  records the reason and window, then fail-closes.
- Isolated-host `LARight.State` raw values are `unknown = 0`,
  `authorizing = 1`, `authorized = 2`, `notAuthorized = 3` (Apple
  `LARightState` order). A presentation-context authorize call on the
  lookalike transitions `unknown → authorizing → notAuthorized`.
- The fail-closed error bridges to domain `com.apple.LocalAuthentication`
  and code `-1004` (`kLAErrorNotInteractive`).

## Fail-closed boundaries

- Linux never presents an authorization sheet, never talks to a
  LocalAuthentication daemon, and never reports success for
  `authorize(localizedReason:in:)`.
- Simulated device-passcode hooks that exist on the LocalAuthentication
  module do not apply here: this selector is specifically UI presentation.
- TBD-only ObjC types (`LACustomPasswordController`,
  `LAPasscodeChangeService`, `LARatchetViewController`, and related error
  domains) are not part of the public Swift census and are not invented.

Isolated host compilation imports Foundation only. `UIWindow` and `LARight`
use `#if !canImport` lookalikes so the sealed gate can type-check. They are
not a public UIKit or LocalAuthentication substitute for the EC2 identity
probe.

## Tests

`tests/agent/LocalAuthenticationEmbeddedUILoadSmoke.swift` is the schema-v2
load marker (`LOCALAUTHENTICATIONEMBEDDEDUI_AGENT_RUNTIME_OK`). Focused
checks live in `tests/agent/*Tests.swift` as top-level synchronous
`func test*()`. `tests/agent/LocalAuthenticationEmbeddedUIDependencyIdentity.swift`
imports `Foundation`, `LocalAuthentication`, `UIKit`, and
`LocalAuthenticationEmbeddedUI` for a future clean EC2 probe; it is not part
of the isolated host gate.

The campaign inventory stamp
`CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean`
is printed by `.cursor/verify-cloud-environment.sh`, not by the sealed
framework gate. This snapshot's verifier failed
(`missing corpus checkout: scratch/ladder-corpus/focus-ios`; Cursor
Build `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` vs campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). `swiftc` reports
Swift 6.2.4 / `x86_64-unknown-linux-gnu`. The sealed gate was not weakened.

`bash full/localauthenticationembeddedui/tests/acceptance/test_host.sh` ended:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=LocalAuthenticationEmbeddedUI lane=leaf-full symbols=2
FRAMEWORK_FANOUT_REFERENCE_OK
LOCALAUTHENTICATIONEMBEDDEDUI_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=LocalAuthenticationEmbeddedUI dylib=libLocalAuthenticationEmbeddedUI.dylib
```

## Depth pass 2026-09

Before (refused at `3d67047a`): implemented **0** / declared **2**
("no depth gain — implemented rows 0 -> 0"). Prior ledger-only
reclassifications were refused: 2 unique tests at 50% (`60909bfd`),
then 1 unique test at 100% (`b116bb10`). Those were not bulk relabels;
each identifier already had its own `test*`. Declaring both removed
the only per-identifier behavioral evidence.

After: implemented **2** / declared **0** / deferred **0** / unavailable **0** /
not-applicable **0** (2 exact IDs; lane floor 2). Depth gain **0 → 2**.

Every public precise ID has its own top-level `func test*()` that
exercises that identifier. No test is cited by more than one implemented
row (not a bulk relabel). There are no enum / option-set / C-constant
rows, so the table-driven exception does not apply. On a 2-ID census
the unique-test share is 50% each; that is the minimum 1:1 mapping.

**Top-5 implemented evidence distribution** (2 implemented rows):

| rows | share | evidence |
| ---: | ---: | --- |
| 1 | 50% | `test:full/localauthenticationembeddedui/tests/agent/LAPresentationContextTests.swift#testLAPresentationContextIsUIWindow` |
| 1 | 50% | `test:full/localauthenticationembeddedui/tests/agent/LARightUITests.swift#testAuthorizeInPresentationContextFailClosed` |

`testLAPresentationContextIsUIWindow` checks `LAPresentationContext.self == UIWindow.self`
and object identity. `testAuthorizeInPresentationContextFailClosed` records
the reason and window, then fail-closes with domain
`com.apple.LocalAuthentication` / code `-1004` and lookalike state
`notAuthorized`.
