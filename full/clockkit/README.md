# ClockKit (Linux starting point)

This directory is a fail-closed portable `ClockKit` module for the OpenUIKit
Linux platform. It implements the sealed Xcode 26.1 iPhoneOS public seed:
13 unique precise identifiers, all on `CLKWatchFaceLibrary`. It is not wired
into the shared guest package; that integration is a separate review step.

The platform fan-out branch `cursor/port-clockkit-to-linux-a363` (legacy PR
#36) was **unavailable** to this promotion (GitHub App token scoped to
`Vercantez/openuikit` only). This lane is reconstructed from the monorepo
seed, the in-repo PR #36 repair brief
(`full/framework-fanout/repairs-wave2-pr30-40.json`), public `CLKWatchFaceLibrary`
declarations, and the pinned Apple-oracle facts recorded there. It is not a
byte-copy of the 409 Swift lines on that inaccessible branch.

**Reference dossier:** this promotion keeps the monorepo
`full/clockkit/reference/` (generator `scripts/framework-fanout/generate_seed.py`,
SHA256 `2b8230ced5a3ed78f070607346f6a684d9e0fb74a8932b92bc0f5e38f46f0a8e`,
iPhoneOS 26.1 / Xcode 17B55). The platform branch `reference/` could not be
compared.

## What is real

- `CLKWatchFaceLibrary` is an `open` `NSObject` subclass.
- `CLKWatchFaceLibrary.ErrorDomain` is the string
  `CLKWatchFaceLibraryErrorDomain` (no extra public global of that name).
- `CLKWatchFaceLibrary.ErrorCode` is `notFileURL = 1`, `invalidFile = 2`,
  `permissionDenied = 3`, `faceNotAvailable = 4`, `noURL = 5`.
- `addWatchFace(at:completionHandler:)` with a **non-file** URL returns first,
  then delivers **exactly one** callback on
  `ClockKit.CLKWatchFaceLibrary.addWatchFace` with `NSError` domain
  `CLKWatchFaceLibraryErrorDomain` and **code 1**.
- `addWatchFace(at:) async throws` uses that same implementation path.
- Subclass overrides of the completion-handler method are visible to the
  async overlay.

## Fail-closed boundaries

- Linux has no Watch pairing UI, Watch app, or `.watchface` importer. Every
  call fail-closes; success is never invented.
- File-URL validation order, permission mapping, and Apple `NSError`
  descriptions are **unobserved**. File URLs still fail (Linux host policy
  uses `faceNotAvailable`); that code is not claimed as Apple's file-URL
  result.
- Callback **queue identity** beyond non-reentrancy is unobserved.
- Complication / timeline / widget surfaces listed in `reference/tbd-exports.tsv`
  are outside this 13-identifier seed and are not declared here.
- Declared dependency `UIKit` is not imported by the isolated module sources:
  this seed's types only need Foundation. `tests/agent/ClockKitDependencyIdentity.swift`
  imports UIKit for a future dependency-ready EC2 run.

## Tests

`tests/agent/ClockKitRuntime.swift` is the host-gate probe and prints
`CLOCKKIT_AGENT_RUNTIME_OK`.

`tests/agent/ClockKitDependencyIdentity.swift` is a future EC2 identity
probe (Foundation + UIKit + ClockKit, non-file URL NSError, codes 1...5,
non-inline exactly-once callback, subclass override). It prints
`CLOCKKIT_DEPENDENCY_IDENTITY_OK`. It does not claim an integrated Linux
product until that cold build uses real dependency modules.
