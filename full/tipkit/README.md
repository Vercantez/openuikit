# TipKit

Linux starting point for Apple's public `TipKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success is not
integrated Linux / guest-SwiftUI success.

The legacy fan-out PR
(`openuikit-linux-platform` `cursor/port-tipkit-to-linux-1789`, PR #14) was
not readable from this agent's GitHub token (private repo, installation scoped
to `Vercantez/openuikit`). This tree keeps the monorepo `reference/` seed
(newer generator provenance on main) and implements the Foundation engine
described by that seed: no `TipKit.Text` / `Image` / `Edge` / `Binding`
stand-ins.

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

## Depth pass 2026-09 (wave 8)

Coverage of the 1035 exact public identifiers:

- **before:** 178 implemented / 1 declared / 5 deferred / 851 unavailable / 0 not-applicable
- **after:** 213 implemented / 0 declared / 5 deferred / 25 unavailable / 792 not-applicable

This second pass keeps the first-pass Foundation engine and tests. It adds a
real JSON datastore, public `Tips.Rule(parameter/event, predicate)` evaluation,
display-frequency arithmetic against a fixed clock, persisted
`Tips.Parameter` values, and `TipView` / `TipViewStyle` / `TipUI*`
configuration models. SwiftUI `View` overlay re-exports (`s:7SwiftUI4View…`)
are `not-applicable` (owned by the SwiftUI lane). Only members that need
`UIColor`, `Edge`, `ShapeStyle`, `Binding`, or a `View` body stay
`unavailable`. `#Rule` / `@Event` macros are not separate public-surface rows;
the expanded Rule spelling is implemented.

Top-5 evidence distribution (share of the 213 implemented rows):

1. `testAnyTipErasure` — 17 (8.0%)
2. `testTipKitErrorIdentities` — 15 (7.0%)
3. `testDonationTimeRangeValues` — 15 (7.0%, table-driven named ranges)
4. `testEventDonateAndQuery` — 14 (6.6%)
5. `testTipProtocolIdentityAndDefaults` — 13 (6.1%)

No non-enum test is cited by more than 40% of implemented rows. Display
frequency cases share `testDisplayFrequencyHourlyWeeklyMonthlyImmediate`.

Environment: `git rev-parse HEAD` was `dd4c8bca7e8735289928bbd1abd44f4b35815308`.
`swiftc` is Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit the campaign
`products=clean` line because `scratch/ladder-corpus/focus-ios` is absent from
this snapshot; the sealed framework gate does not require that checkout. The
pod booted from `bld-20260905-9aa65d65-b87d-46a7-b154-e2f1440dbba3` rather than
campaign `bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`.

## What is real

The public Foundation engine compiles to `libTipKit.dylib`.

- `Tips.configure` is once-per-process. `datastoreLocation(.applicationDefault)`
  writes `Application Support/TipKit/datastore.json`. `datastoreLocation(.url)`
  writes that file. A second call throws
  `TipKitError.tipsDatastoreAlreadyConfigured`.
- `Tips.Parameter` values with a nonempty id persist in that store.
  `.transient` stays process-local. `Tips.resetDatastore()` clears donations,
  invalidations, parameters, and last-display time on disk.
- `Tips.Rule(parameter, predicate)` and `Tips.Rule(event, predicate)` are the
  non-macro `#Rule` expansion. Event predicates use `event.donations.count`.
- Display frequency (`immediate` / `hourly` / `daily` / `weekly` / `monthly`)
  throttles `shouldDisplay` using elapsed seconds against an injectable clock.
  `monthly` is 30 days. `IgnoresDisplayFrequency` bypasses the throttle.
  Status stays `.available` during a cooldown; `MaxDisplayCount` still
  invalidates via host `recordDisplayForHost()`.
- `Tip` (without SwiftUI `title` / `message` / `image`), `AnyTip`,
  `invalidate(reason:)`, `resetEligibility()`, `status`, `shouldDisplay`,
  `statusUpdates`, and `shouldDisplayUpdates` remain the eligibility engine.
  Rules that fail keep a tip `.pending`.
- `Tips.showAllTipsForTesting` / `hideAllTipsForTesting` and the typed
  `showTipsForTesting` / `hideTipsForTesting` overrides force or suppress
  `shouldDisplay`. `showAll` also reports `.available`.
- `TipGroup.currentTip` is the first grouped tip whose `shouldDisplay` is true.
- `Tips.Event` donate / `sendDonation` / `donations` / `deleteDonations` and
  `DonationLimit` trimming persist when a datastore is configured.
- `TipView`, `TipViewStyle`, `MiniTipViewStyle`, `TipViewStyleConfiguration`,
  `TipUIView`, `TipUIPopoverViewController`, `TipUICollectionViewCell`, and
  `TipUICollectionReusableView` are configuration models (tip, actions, style,
  `CGFloat` / `CGSize` / `CGRect`). They do not render UI.
- `DatastoreLocation.groupContainer(identifier:)` throws
  `TipKitError.missingGroupContainerEntitlements`.
- `sendDonation` completions hop once onto serial queue
  `TipKit.Tips.completion`.

## Fail-closed boundaries

- No SwiftUI `Text` / `Image` / `Edge` / `Binding` / `View` types are declared
  in this module. `Tip.title` / `message` / `image`, `Tips.Action.label`,
  `TipView.body`, and Edge/Binding inits stay deferred or unavailable.
- `TipUI*` is not UIKit: `backgroundColor` (`UIColor`), `imageStyle` /
  `backgroundStyle` (`ShapeStyle`), popover `sourceItem`, and Edge-taking
  `configureTip` stay unavailable. `init(coder:)` returns nil.
- `cloudKitContainer` is recorded and never synchronized.
- Apple's `#Rule` macro is unavailable; the expanded
  `Tips.Rule(parameter/event, predicate)` spelling is implemented.
- `MaxDisplayDuration` is stored and does not expire a tip without a displayed-
  duration clock.
- SwiftUI `View` modifiers (`popoverTip`, `tipViewStyle`, and the synthesized
  `View` overlay) are not-applicable; they belong to the SwiftUI lane.

## Still open

See `oracle-questions.tsv` for Darwin datastore bytes, CloudKit, `#Rule`
macro expansion, default `Tip.id` bytes, `showAllTipsForTesting` versus
invalidated status, `TipGroup.Priority.firstAvailable` ranking,
`DonationTimeRange` calendar mapping, and whether `DisplayFrequency.monthly`
is a calendar month.

`tests/agent/TipKitRuntime.swift` is the isolated host probe
(`TIPKIT_AGENT_RUNTIME_OK`). Focused checks live in
`tests/agent/*Tests.swift`. `tests/agent/TipKitDependencyIdentity.swift` is
prepared for a future clean EC2 run that builds guest Foundation and SwiftUI
first and prints `TIPKIT_DEPENDENCY_IDENTITY_OK` only after proving
`SwiftUI.Text` / `Image` / `Edge` / `Binding` identities. Compiling that file
against toolchain Foundation is not guest-SwiftUI success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
