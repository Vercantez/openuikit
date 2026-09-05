# ExtensionKit

Linux starting point for Apple's public `ExtensionKit` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph. Isolated host-gate
success is not integrated Linux success with guest UIKit, SwiftUI,
ExtensionFoundation, or Foundation XPC.

## Depth pass 2026-09

This is a fresh seed: 40 exact public identifiers, floor 32 nondeferred.

Coverage after this pass: **36 implemented / 4 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 evidence distribution (share of the 36 implemented rows):

1. `ExtensionKitHostingTests.swift#testHostViewControllerConfigurationInit` — 2 (5.6%)
2. `ExtensionKitSceneTests.swift#testAppExtensionSceneProtocolConformance` — 2 (5.6%)
3. `ExtensionKitSceneTests.swift#testPrimitiveAppExtensionSceneInit` — 1 (2.8%)
4. `ExtensionKitBuilderTests.swift#testSceneBuilderBuildBlockOne` — 1 (2.8%)
5. `ExtensionKitHostingTests.swift#testHostViewControllerMakeXPCConnectionThrows` — 1 (2.8%)

No non-enum test is cited by more than 40% of implemented rows. The four
uninhabited `body` getters (`PrimitiveAppExtensionScene.body`, `Array.body`,
`Never.body`, and the protocol `Body` associatedtype) stay `declared`
because accessing a `Never` getter traps and the runner has no recovery.

## What is real

- `PrimitiveAppExtensionScene` stores the scene `id`, the `@ViewBuilder`
  content closure, and `onConnection`. The documented default
  `onConnection` is `{ _ in false }`.
- `AppExtensionSceneBuilder.buildBlock` passthrough (one scene) and
  composition (two through ten scenes) harvest primitive identifiers in
  source order.
- `AppExtensionSceneConfiguration.accept(connection:)` is nonisolated.
  It returns `false` unless every nested `AppExtensionConfiguration.accept`
  (when present) returns `true` and at least one scene `onConnection`
  returns `true`.
- `EXHostViewController.Configuration` is a mutable value type holding
  `AppExtensionIdentity` and `sceneID`.
- `EXHostViewController` stores `configuration`, `placeholderView`, and a
  weak `delegate`. Setting configuration does not start an extension.
- `AppExtension.main()` exists for `Configuration == AppExtensionSceneConfiguration`.

## Fail-closed boundaries

- `makeXPCConnection()` always throws `ExtensionKitHostError.xpcUnavailable`
  (`ExtensionKit.Linux` / code 1), even when `configuration` is set.
- `AppExtension.main()` always throws
  `ExtensionKitHostError.extensionProcessUnavailable` (code 2).
- `EXAppExtensionBrowserViewController` reports no catalog
  (`host_isExtensionCatalogAvailable == false`, code 3).
- Delegate `didActivate` / `willDeactivate` fire only through
  `@_spi(OpenUIKitHost)` host SPI. They are not Apple extension lifecycle.
- Isolated-host `NSXPCConnection`, `UIView`, `View`, `AppExtension`, and
  `AppExtensionIdentity` in `ExtensionKitLookalikes.swift` compile out when
  those modules are imported. They are not Linux ports of those types.

## Still open

See `oracle-questions.tsv` for Darwin XPC error codes, placeholder defaults,
`accept` composition with a nested configuration, `debugDescription` bytes,
and `main()` blocking versus returning.

Focused checks live in `tests/agent/*Tests.swift` as top-level `func test*()`.
The sealed gate prints `EXTENSIONKIT_AGENT_RUNTIME_OK` after calling each
cited test once.

```
CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ExtensionKit lane=leaf-full symbols=40
FRAMEWORK_FANOUT_REFERENCE_OK
EXTENSIONKIT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ExtensionKit dylib=libExtensionKit.dylib
```

Run `bash full/extensionkit/tests/acceptance/test_host.sh` from the repo
root. Keep generated products out of the tree.
