# SecurityUI

Linux starting point for Apple's public `SecurityUI` module, reconstructed
from the pinned Xcode 26.1 iPhoneOS 26.1 symbol graph, API digester, TBD
exports, and the read-only `dotnet/macios` `securityui.cs` binding. This
directory is not wired into the shared guest package. A passing isolated
host gate is not integrated Linux success with guest UIKit, SwiftUI, or
Security.

## Depth pass 2026-09

This is a fresh seed: 9 exact public identifiers, floor 8 nondeferred.

Coverage after this pass: **9 implemented / 0 declared / 0 deferred /
0 unavailable / 0 not-applicable**.

Top-5 evidence distribution (share of the 9 implemented rows):

1. `SFCertificatePresentationTests.swift#testSFCertificatePresentationClass` — 1 (11.1%)
2. `SFCertificatePresentationTests.swift#testDismissSheet` — 1 (11.1%)
3. `SFCertificatePresentationTests.swift#testInitWithTrust` — 1 (11.1%)
4. `SFCertificatePresentationTests.swift#testPresentSheet` — 1 (11.1%)
5. `SFCertificatePresentationTests.swift#testHelpURLProperty` — 1 (11.1%)

The remaining four implemented rows each cite a distinct test
(`testMessageProperty`, `testTitleProperty`, `testTrustProperty`,
`testCertificateSheet`). No non-enum test is cited by more than 40% of
the remaining implemented rows (largest citation is 1 of 9).

Environment: `swiftc` reports Swift 6.2.4, target `x86_64-unknown-linux-gnu`.
`.cursor/verify-cloud-environment.sh` did not emit
`CURSOR_SWIFT_ENVIRONMENT_OK` because `scratch/ladder-corpus/focus-ios` is
absent on this VM. The sealed gate compiles with a clean product tree
(`products=clean`). Active Cursor Build observed on this run was
`bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21` (campaign expected
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Starting commit
`26f5086c5b31ba816742f18d3096152cd32280f4` matched.

`origin/agent/fw-securityui` did not exist; this pass publishes that
branch from the Cursor-created work branch.

## What is real

- `SFCertificatePresentation` is an `NSObject` subclass with designated
  `init(trust:)`. `trust` is get-only and identity-equal to the argument.
- `title`, `message`, and `helpURL` default to `nil` and round-trip.
  Setting one field does not change the others.
- `presentSheet(in:dismissHandler:)` records the presenter and optional
  handler, moves the phase to `.requested`, and returns. It does not
  show UI and does not call the handler. A second present while
  `.requested` increments the present count and is otherwise ignored.
- `dismissSheet()` from `.requested` clears presenter state, moves to
  `.dismissed`, and invokes the stored handler once, synchronously.
  `dismissSheet()` from `.idle` or `.dismissed` is a counted no-op.
- `View.certificateSheet(trust:title:message:help:)` returns an identity
  wrapper that stores the chrome fields and reads the binding. Nil
  title/message/help stay nil. The wrapper never presents and never
  writes the binding.

## Fail-closed boundaries

Linux has no SecurityUI certificate chrome, no SecurityUI daemon, and no
Apple trust-evaluation UI.

- `presentSheet` never evaluates `SecTrust` and never displays
  certificates.
- The SwiftUI modifier never presents and never invents Apple's default
  title, message, or Learn More URL.
- Isolated-host `SecTrust` / `UIViewController` / `View` / `Binding` in
  `SecurityUILookalikes.swift` compile out when Security, UIKit, or
  SwiftUI is imported. They are not Linux ports of those modules.
- Linux retains the `SecTrust` next to the `unowned(unsafe)` getter so
  host tests cannot dangle. Darwin assign/unowned lifetime is unobserved.

Private TBD types (`SFCertificatePresentationController`,
`SFCertificatePresentationRequest`, and the other `_OBJC_CLASS_$_SF*`
exports) are not part of this module.

## Still open

See `oracle-questions.tsv` for Darwin second-present stacking, dismiss
handler queue/animation, nil-chrome default copy, SecTrust assign
lifetime, SwiftUI binding-write-on-dismiss, and whether present
evaluates the trust before showing chrome.
