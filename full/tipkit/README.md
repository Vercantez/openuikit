# TipKit

Portable Linux starting point for Apple's public `TipKit` surface, reconstructed
from the pinned Xcode 26.1 iPhoneOS symbol graphs. This directory is not wired
into the shared guest package; that integration is a later central review step.

## What is real

The `Tip` protocol, `AnyTip` type eraser, and `Tips` namespace compile and run
in-process:

- `Tips.configure` records display frequency, datastore location, and CloudKit
  container options in process memory. A second configure call throws
  `TipKitError.tipsDatastoreAlreadyConfigured`.
- Eligibility is deterministic for the current process: empty rules pass, a tip
  is `.available` after configure, `.pending` before configure or when hidden
  for testing, and `.invalidated` after `invalidate(reason:)`.
- `resetEligibility()` and `Tips.resetDatastore()` clear in-process
  invalidations, display counts, donations, and parameters.
- Testing helpers (`showAllTipsForTesting`, `hideAllTipsForTesting`,
  `showTipsForTesting`, `hideTipsForTesting`) override eligibility without
  inventing Apple UI presentation.
- `Tips.Event` donations, `Tips.Parameter` values, `Tips.Action` metadata,
  `TipGroup` first-available / ordered selection, `DonationTimeRange`,
  `DonationLimit`, and the `Sequence` donation helpers are process-local and
  exercised by `tests/agent/TipKitRuntime.swift`.

When SwiftUI is not importable (the isolated host gate), `Text`, `Image`,
`Edge`, and `Binding` are portable stand-ins so `Tip.title` / `TipView`
type-check. When SwiftUI is on the module path, TipKit uses the real SwiftUI
types and `TipView` becomes a `View`.

## Fail-closed boundaries

- **App Group datastores** throw `TipKitError.missingGroupContainerEntitlements`.
  Linux has no App Group container.
- **CloudKit** options are stored and never synced. Configure does not claim
  that an iCloud container accepted the store.
- **On-disk Apple datastore format** is unknown. `datastoreLocation(.url(_:))`
  records the URL; persistence remains process-local memory.
- **UIKit views** (`TipUIView`, `TipUIPopoverViewController`,
  `TipUICollectionViewCell`, `TipUICollectionReusableView`) are unavailable.
  UIKit is not a declared dependency of this seed.
- **SwiftUI popover chrome** (`View.popoverTip`, `tipViewStyle`, image/background
  modifiers) is deferred until SwiftUI is on the compile path. Identity
  modifiers exist in the `#if canImport(SwiftUI)` sources and do not fabricate
  a presented popover.
- **`#Rule` / `@Parameter` macros** are not implemented. `Tips.Rule` exposes
  the TBD compound initializer plus an SPI portable predicate. `#Predicate`
  event/parameter rule initializers stay fail-closed.

## Still deferred

Exact Apple localized `TipKitError` strings, Core Data on-disk layout, CloudKit
replication, display-frequency wall-clock interaction with a real UI presenter,
and compiler-plugin macros need a central Apple-oracle probe. See
`oracle-questions.tsv`.
