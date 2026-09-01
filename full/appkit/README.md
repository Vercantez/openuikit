# Portable AppKit RevenueCat tranche

This directory owns the first real AppKit compatibility boundary required by
the untouched RevenueCat `purchases-ios` tree at commit
`57043e7e0173c48d64e171944ac76a34d2467fa1` (tree
`72a2e1e9b6986fadca9b863d235c4a52aab38fb4`). The production target contains
530 of its 531 tracked `Sources/**/*.swift` files; only the receipt-parser-only
file excluded by the package manifest is omitted. No RevenueCat source is
patched or shadowed.

The tranche implements the complete AppKit surface selected by those sources:
application lifecycle notification names and modal responses, headless alerts,
windows, workspace URL/Finder operations, font lookup/inventory, component
colors, SwiftUI `Color` conversion, and StoreKit purchase confirmation with an
`NSWindow`. This is a functional compatibility boundary rather than a module
that merely makes `import AppKit` succeed.

Linux has no WindowServer, Finder, App Store UI, or native AppKit font database.
Those operations fail closed: workspace methods return `false`; unknown fonts
return `nil` and inventories are empty; StoreKit throws its existing
`paymentsUnavailable` error; and a headless alert selects an explicit Cancel
button or returns `.abort`. Component colors and Apple's public constants are
fully represented.

The Apple oracle is pinned to Xcode 26.1 / macOS SDK 26.1. Its AppKit TBD and
the seven headers governing this surface are hashed in
`tests/appkit-apple-sdk-contract.tsv`; the ten-row native transcript is tracked
in `tests/appkit-interface-apple-xcode-26.1.txt`. The canonical framework
install identity is
`/System/Library/Frameworks/AppKit.framework/Versions/C/AppKit`.

The Linux publication gate must produce a versioned `AppKit.framework`, a
Swift module consumable through `-F`, an ARM64 Mach-O dylib with that exact
identity, a byte-identical runtime-root copy, an exhaustive tracked export
contract, no unexpected imports or load commands, cold AppKit and SwiftUI color
runtime transcripts, and the exact untouched 530-source RevenueCat frontier.
`tests/test_revenuecat_appkit_frontier_guest.sh` consumes only a completed
package and the clean pinned checkout. It accepts either a complete typecheck
or a later compiler wall, but refuses the old AppKit import error, missing
surface diagnostics, source drift, package drift, or any non-versioned runtime
identity.

`tests/build_appkit_focused_guest.sh` is the isolated publication proof used
before merging AppKit into the monolithic platform builder. It consumes a
completed portable core package without changing it, normalizes every
relocatable compile path to one absolute package identity, and emits the
versioned framework, module, runtime-root copy, two Mach-O consumer probes,
and attestations into a new narrowly named output. The current pinned contract
is 198 exact exports, an exact undefined-import hash, and the 16 load
identities in `tests/appkit-load-identities.txt`.

`tests/validate_appkit_focused_guest.sh` independently regenerates the binary
exports, imports, and load closure; checks framework symlinks, install name,
ARM64 Mach-O kinds, byte identity, module/interface presence, probe load
commands, Apple transcript, cold runtime marker, and every completion-record
hash. `tests/test_validate_appkit_focused_guest_mutations.sh` proves rejection
of ten independent corruptions, including framework/runtime bytes, missing
module, export/load attestations, Apple transcript, completion record,
framework link, install identity, and binary load closure. Its temporary
copies are removed exactly after the proof.

The same contract is now part of the production core package builder rather
than remaining a focused sidecar. Production emits the six target-qualified
module artifacts and canonical three-symlink versioned framework, installs a
byte-identical copy into the machorun root, links SwiftUI and StoreKit through
that identity, and cold-runs all four AppKit/SwiftUI/StoreKit probes before
publication. Both the creation-time and canonical consumer validators require
the AppKit source attestation, versioned artifact family, exact symlinks,
compile/runtime hash identity, and `-framework AppKit`; a flat
`libAppKit.dylib` is explicitly refused.
