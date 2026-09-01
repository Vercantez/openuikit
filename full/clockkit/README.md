# ClockKit (Linux starting point)

This directory is an isolated clean-room port of the **public Swift overlay**
seeded from Xcode 26.1 / iPhoneOS 26.1. It is not Apple behavioral parity, it
is not wired into the shared guest package, and a passing isolated host gate
is not integrated Linux success.

The pinned Swift surface is 13 precise identifiers, all on
`CLKWatchFaceLibrary` and its `NS_ERROR_ENUM`. Complication templates,
timeline entries, `CLKComplicationServer`, widget migration, and
`CLKWidgetConstants` appear in TBD/header provenance and in the 20-app
corpus, but they are **not** in this overlay. They stay deferred rather than
being invented from symbol names.

## What is real

- `CLKWatchFaceLibrary` is an open `NSObject` subclass with a public
  initializer and subclass override dispatch.
- `CLKWatchFaceLibrary.ErrorDomain` as a class string property. The canonical
  Swift graph does not expose a second global `CLKWatchFaceLibraryErrorDomain`
  declaration; the Apple NSString payload is unverified.
- `CLKWatchFaceLibrary.ErrorCode` cases for source compatibility. Integer raw
  values are Swift sequential assignment, not a verified Apple ABI table.
- Synthesized `Equatable` / `Hashable` (`!=`, `hashValue`, `hash(into:)`).
- `addWatchFace(at:completionHandler:)` and the async `addWatchFace(at:)`
  overlay, which share one ObjC precise ID and one delivery path.

`addWatchFace` accepts a Foundation `URL` and touches portable
`FileManager.fileExists(atPath:isDirectory:)` with an `ObjCBool`
out-parameter. That probe does **not** choose among guessed Apple validation
codes. The public result is always fail-closed (`faceNotAvailable` as the
Linux sentinel that no watch-face library exists).

## Fail-closed boundary

`addWatchFace` **never succeeds**. Linux has no paired Apple Watch, no
watch-face consent UI, and no `CLKWatchFaceLibrary` Mach service. The
completion handler is scheduled off the caller and invoked exactly once with
a non-nil error. The async overlay waits on that same handler and always
throws. Localized Apple error descriptions and URL-validation ordering are
not fabricated.

UIKit is listed as a seed dependency for later package integration. This
overlay does not `import UIKit`: the 13-identifier Swift surface has no UI
types, and the isolated host compile has no UIKit module.
`tests/agent/ClockKitDependencyIdentity.swift` is a future clean EC2 client
that imports Foundation, UIKit, and ClockKit together. It is not compiled by
the isolated host gate.

## Deferred / declared

- Exact Apple `ErrorDomain` string and `ErrorCode` raw values.
- Apple's per-URL validation order and unpaired-watch error selection.
- Completion-queue identity and consent UI.
- Entire ObjC complication / timeline / image-provider surface from the
  remaining SDK headers.

Isolated gate (not an integrated guest-sysroot run):

```sh
bash tests/acceptance/test_host.sh
```
