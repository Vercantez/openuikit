# AppTrackingTransparency

Linux starting point for Apple's public `AppTrackingTransparency` module,
reconstructed from the pinned Xcode 26.1 iPhoneOS symbol graph, the in-repo
fan-out repair spec (`full/framework-fanout/repairs-wave2-pr30-40.json`
PR #35), and Apple public documentation. This directory is not wired into the
shared guest package. A passing isolated host gate is not integrated Linux
success.

## What is real

The public Swift surface compiles to `libAppTrackingTransparency.dylib`.

- `ATTrackingManager` is an `open` `NSObject` subclass.
- `ATTrackingManager.AuthorizationStatus` is a `UInt` `RawRepresentable`
  enum: `notDetermined = 0`, `restricted = 1`, `denied = 2`,
  `authorized = 3`. Those raw values match the public sequential `NS_ENUM`
  in `ATTrackingManager.h` (SDK input hash in `reference/sdk-inputs.tsv`;
  header bytes are not vendored). Unknown raw values fail the failable
  initializer.
- `Equatable.!=` and `Hashable.hash(into:)` are synthesized and exercised.
- `Hashable.hashValue` is stable per case and consistent with the
  raw-value initializer (`tests/agent/AppTrackingTransparencyTests.swift#testStatusHashValue`).
  It compiles cleanly under `-warnings-as-errors` on this toolchain.
- `trackingAuthorizationStatus` is always `.denied`.
- `requestTrackingAuthorization(completionHandler:)` returns first, then
  delivers `.denied` exactly once on the private serial queue
  `AppTrackingTransparency.ATTrackingManager.completion` (`async`, never
  `sync`). Nested calls enqueue behind the running handler.
- The Swift `async` overload waits on that same completion path and returns
  `.denied` without deadlock or double completion.

## Fail-closed boundaries

Linux has no ATT system prompt, IDFA, advertising identifier, or Settings
privacy toggle. Tracking is never authorized.

- `.authorized` is constructible as an enum case and is never returned by
  the manager.
- `.notDetermined` and `.restricted` are constructible; the manager does not
  report them. There is no pending prompt and no parental-control signal.
- Completions are never invoked inline. Delivery is exactly-once per call.
- `ATTrackingEnforcementManager` appears only in the TBD export list, not in
  the sealed public Swift graph. It is not declared here.

`hashValue` is exercised alongside the other Hashable witnesses. There are
no deferred rows.

## Coverage (wave 14)

Before: 11 implemented / 1 declared / 0 deferred of 12.
After: 12 implemented / 0 declared / 0 deferred of 12.

The remaining declared row (`AuthorizationStatus.hashValue`) was converted to
`implemented` with `testStatusHashValue`; every row is now cited by a
top-level `func test*()` in `tests/agent/AppTrackingTransparencyTests.swift`
that calls that identifier.

## Still open

See `oracle-questions.tsv` for Darwin completion-queue identity,
missing-usage-description status mapping, nested-request reentrancy, and
whether `ATTrackingEnforcementManager` is ever a public Swift type.

`tests/agent/AppTrackingTransparencyRuntime.swift` is the isolated host probe
(`APPTRACKINGTRANSPARENCY_AGENT_RUNTIME_OK`).
`tests/agent/AppTrackingTransparencyDependencyIdentity.swift` is prepared for
a future clean EC2 run that builds guest Foundation first and prints
`APPTRACKINGTRANSPARENCY_DEPENDENCY_IDENTITY_OK` only after assertions pass.
Compiling that file against toolchain Foundation is not guest-Foundation
success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
