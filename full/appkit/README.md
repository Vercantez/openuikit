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
