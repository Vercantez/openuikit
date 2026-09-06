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

Before (refused at `60909bfd`): implemented **2** / declared **0**.
Top evidence 1 of 2 (50%) for `testLAPresentationContextIsUIWindow`.

Before (refused at `b116bb10`): implemented **1** / declared **1**.
Top evidence 1 of 1 (100%) for `testAuthorizeInPresentationContextFailClosed`,
again over the 40% cap.

There are no enum / option-set / C-constant rows, so no table-driven
exception applies. On a 2-ID non-enum census, every unique `implemented`
test exceeds 40% of remaining implemented rows (50% with two rows, 100%
with one).

After: implemented **0** / declared **2** / deferred **0** / unavailable **0** /
not-applicable **0** (2 exact IDs; lane floor 2).

- `LAPresentationContext` → `declared`
  `source:full/localauthenticationembeddedui/LocalAuthenticationEmbeddedUI.swift#LAPresentationContext`
- `LARight.authorize(localizedReason:in:)` → `declared`
  `source:full/localauthenticationembeddedui/LocalAuthenticationEmbeddedUI.swift#authorize`

**Top-5 implemented evidence distribution** (0 implemented rows): none.

Product sources still fail-close authorize with domain
`com.apple.LocalAuthentication` / code `-1004`. Focused
`tests/agent/*Tests.swift` functions remain and compile; they are not
cited as `implemented` evidence because each would exceed the 40% cap.
