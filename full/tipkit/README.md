# TipKit

Linux starting point for Apple's public `TipKit` module, reconstructed from
the pinned Xcode 26.1 iPhoneOS symbol graph. Isolated host-gate success is not
integrated Linux / guest-SwiftUI success.

The legacy fan-out PR
(`openuikit-linux-platform` `cursor/port-tipkit-to-linux-1789`, PR #14) was
not readable from this agent's GitHub token (private repo, installation scoped
to `Vercantez/openuikit`). This tree keeps the monorepo `reference/` seed
(newer generator provenance on main) and implements the Foundation-only engine
described by that seed and the PR #14 repair notes: no `TipKit.Text` /
`Image` / `Edge` / `Binding` stand-ins, no claimed persistence.

## What is real

The public Foundation engine compiles to `libTipKit.dylib`.

- `Tips.configure` is once-per-process and in-memory. A second call throws
  `TipKitError.tipsDatastoreAlreadyConfigured`.
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

## Still open

See `oracle-questions.tsv` for Darwin datastore bytes, CloudKit, `#Rule`
expansion, and `DonationTimeRange` calendar versus elapsed-seconds mapping.

`tests/agent/TipKitRuntime.swift` is the isolated host probe
(`TIPKIT_AGENT_RUNTIME_OK`). `tests/agent/TipKitDependencyIdentity.swift` is
prepared for a future clean EC2 run that builds guest Foundation and SwiftUI
first and prints `TIPKIT_DEPENDENCY_IDENTITY_OK` only after proving
`SwiftUI.Text` / `Image` / `Edge` / `Binding` identities. Compiling that file
against toolchain Foundation is not guest-SwiftUI success.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep generated
products out of the tree.
