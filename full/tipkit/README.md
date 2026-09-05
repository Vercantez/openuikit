# TipKit

Linux starting point for Apple's public `TipKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success is not
integrated Linux / guest-SwiftUI success.

The legacy fan-out PR
(`openuikit-linux-platform` `cursor/port-tipkit-to-linux-1789`, PR #14) was
not readable from this agent's GitHub token (private repo, installation scoped
to `Vercantez/openuikit`). This tree keeps the monorepo `reference/` seed
(newer generator provenance on main) and implements the Foundation-only engine
described by that seed: no `TipKit.Text` / `Image` / `Edge` / `Binding`
stand-ins, no claimed persistence.

## Depth pass 2026-09

Coverage of the 1035 exact public identifiers:

- **before:** 136 implemented / 1 declared / 47 deferred / 851 unavailable
- **after:** 178 implemented / 1 declared / 5 deferred / 851 unavailable

The 20-app corpus (WordPress-iOS, duckduckgo-ios, firefox-ios, wikipedia-ios)
exercises `Tips.configure`, `Tip` conformances, `invalidate(reason:)`,
`Tips.resetDatastore`, `MaxDisplayCount`, and SwiftUI `popoverTip` /
`TipView`. This pass implemented the Foundation eligibility engine those apps
need (`Tip` / `AnyTip` / `TipGroup.currentTip` / testing overrides) and left
SwiftUI `Text` / `Image` / `TipView` / UIKit `TipUI*` unavailable.

Top-5 evidence distribution (share of the 178 implemented rows):

1. `testAnyTipErasure` — 17 (9.6%)
2. `testConfigurationCloudKitAndFrequency` — 16 (9.0%)
3. `testTipKitErrorIdentities` — 15 (8.4%)
4. `testDonationTimeRangeValues` — 15 (8.4%, table-driven named ranges)
5. `testEventDonateAndQuery` — 14 (7.9%)

No non-enum test is cited by more than 40% of implemented rows. Enum and
named-range catalogs share table-driven value tests.

## What is real

The public Foundation engine compiles to `libTipKit.dylib`.

- `Tips.configure` is once-per-process and in-memory. A second call throws
  `TipKitError.tipsDatastoreAlreadyConfigured`.
- `Tip` (without SwiftUI `title` / `message` / `image`), `AnyTip`,
  `invalidate(reason:)`, `resetEligibility()`, `status`, `shouldDisplay`,
  `statusUpdates`, and `shouldDisplayUpdates` are an in-memory state machine.
  Rules that fail keep a tip `.pending`. `invalidate` stores a reason.
  `Tips.resetDatastore()` clears donations and invalidations.
- `Tips.showAllTipsForTesting` / `hideAllTipsForTesting` and the typed
  `showTipsForTesting` / `hideTipsForTesting` overrides force or suppress
  `shouldDisplay`. `showAll` also reports `.available` so tests can present
  invalidated tips; Darwin's status split is queued in `oracle-questions.tsv`.
- `TipGroup.currentTip` is the first grouped tip with `shouldDisplay == true`.
  `.firstAvailable` and `.ordered` share that scan until a display-history
  oracle exists.
- `Tips.Event` donate / `sendDonation` / `donations` / `deleteDonations` and
  `DonationLimit` trimming are a process-local store.
- `Sequence.donatedWithin`, `largestSubset(groupedBy:)`, and
  `smallestSubset(groupedBy:)` run against that store. `DonationTimeRange`
  uses elapsed seconds (60 / 3_600 / 86_400 / 604_800), which is Linux-local
  until an Apple-oracle calendar observation exists.
- `Tips.Status`, `Tips.InvalidationReason`, `TipKitError` (three named cases),
  `Tips.Action` `StringProtocol` titles, `TipOption` values
  (`MaxDisplayCount`, `MaxDisplayDuration`, `IgnoresDisplayFrequency`),
  `Tips.Parameter`, and `TipGroup.Priority` are constructible.
- Host-driven `@_spi(OpenUIKitHost) recordDisplayForHost()` increments a
  display count and invalidates with `.displayCountExceeded` when
  `MaxDisplayCount` is present. There is no TipView, so the framework never
  invents a display.
- `DatastoreLocation.groupContainer(identifier:)` throws
  `TipKitError.missingGroupContainerEntitlements`.
- `sendDonation` completions hop once onto serial queue
  `TipKit.Tips.completion` (same fail-closed once-async pattern as Accounts).

## Fail-closed boundaries

- No SwiftUI `Text` / `Image` / `Edge` / `Binding` types are declared in this
  module. `Tip.title` / `message` / `image`, `TipView`, `TipViewStyle`,
  `View.popoverTip`, and `Tips.Action.label` stay out of the isolated compile.
- No UIKit `TipUIView` / `TipUIPopoverViewController` / collection cells.
- `datastoreLocation(.url)` and `cloudKitContainer` record the requested
  option and do **not** create a file, CloudKit container, or synchronized
  store. Remembering those options is not persistence.
- Apple's `#Rule` macro is unobserved. `Tips.Rule` has no public constructor;
  host tests use `@_spi(OpenUIKitHost)`.
- `MaxDisplayDuration` is stored as an option value and does not expire a tip
  without a real displayed-duration clock.

## Still open

See `oracle-questions.tsv` for Darwin datastore bytes, CloudKit, `#Rule`
expansion, default `Tip.id` bytes, `showAllTipsForTesting` versus invalidated
status, `TipGroup.Priority.firstAvailable` ranking, and `DonationTimeRange`
calendar versus elapsed-seconds mapping.

`tests/agent/TipKitRuntime.swift` is the isolated host probe
(`TIPKIT_AGENT_RUNTIME_OK`). Focused checks live in
`tests/agent/*Tests.swift`. `tests/agent/TipKitDependencyIdentity.swift` is
prepared for a future clean EC2 run that builds guest Foundation and SwiftUI
first and prints `TIPKIT_DEPENDENCY_IDENTITY_OK` only after proving
`SwiftUI.Text` / `Image` / `Edge` / `Binding` identities. Compiling that file
against toolchain Foundation is not guest-SwiftUI success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
