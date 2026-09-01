# TipKit

Portable Linux starting point for Apple's public `TipKit` surface, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graphs. This directory is not wired
into the shared guest package. The isolated host gate does **not** prove
integrated Linux SwiftUI success.

## What is real on the isolated host

The Foundation-only eligibility and event engine compiles and runs in-process:

- `Tips.configure` with `displayFrequency` and
  `datastoreLocation(.applicationDefault)` enables a process-local eligibility
  store. A second configure call throws
  `TipKitError.tipsDatastoreAlreadyConfigured`.
- Invalidation, testing helpers (`showAllTipsForTesting` /
  `hideAllTipsForTesting`), `Tips.Event` donations, `Tips.Parameter` values,
  compound `Tips.Rule` evaluation, `DonationTimeRange`, and `DonationLimit`
  are process-local and exercised by `tests/agent/TipKitRuntime.swift`.

## SwiftUI surface

`Tip`, `AnyTip`, `Tips.Action`, `TipView`, `TipGroup`, and View modifiers use
**SwiftUI.Text, SwiftUI.Image, SwiftUI.Edge, SwiftUI.Binding, and SwiftUI.View**
when SwiftUI is importable. There are no TipKit-local stand-ins for those
nominal types. When SwiftUI is absent (isolated host `swiftc`), that surface is
gated out and classified `deferred`.

`tests/agent/TipKitDependencyIdentity.swift` is the future EC2 client: it
imports SwiftUI and TipKit, passes real SwiftUI values through public APIs, and
requires `TipView` to participate in `SwiftUI.View`. Isolated `test_host.sh`
does not compile or run that probe.

## Fail-closed boundaries

- **App Group datastores** throw `TipKitError.missingGroupContainerEntitlements`.
- **CloudKit containers** passed to `Tips.configure` throw a Linux-local
  unavailable error. The option type is constructible; iCloud sync is not
  implemented.
- **URL datastores** passed to `Tips.configure` throw a Linux-local unavailable
  error. Isolated Linux does not write an Apple on-disk store.
- **UIKit views** are unavailable (UIKit is not a declared dependency).
- **`#Rule` / `@Parameter` macros** are not implemented.

## Still deferred

Exact Apple localized `TipKitError` strings, Core Data on-disk layout, CloudKit
replication, SwiftUI popover chrome, and compiler-plugin macros need a central
Apple-oracle probe. See `oracle-questions.tsv`.
