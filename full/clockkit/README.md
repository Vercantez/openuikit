# ClockKit (Linux starting point)

This directory is an isolated clean-room port of the **public Swift overlay**
seeded from Xcode 26.1 / iPhoneOS 26.1. It is not Apple behavioral parity and
it is not wired into the shared guest package.

The pinned Swift surface is 13 precise identifiers, all on
`CLKWatchFaceLibrary` and its `NS_ERROR_ENUM`. Complication templates,
timeline entries, `CLKComplicationServer`, widget migration, and
`CLKWidgetConstants` appear in TBD/header provenance and in the 20-app
corpus, but they are **not** in this overlay. They stay deferred rather than
being invented from symbol names.

## What is real

- `CLKWatchFaceLibrary` is an open `NSObject` subclass with a public
  initializer.
- `CLKWatchFaceLibrary.ErrorDomain` / `CLKWatchFaceLibraryErrorDomain`.
- `CLKWatchFaceLibrary.ErrorCode` with `notFileURL`, `invalidFile`,
  `permissionDenied`, `faceNotAvailable`, and `noURL`.
- Synthesized `Equatable` / `Hashable` (`!=`, `hashValue`, `hash(into:)`)
  and `init?(rawValue:)`.
- `addWatchFace(at:completionHandler:)` and the async `addWatchFace(at:)`
  overlay, which share one ObjC precise ID.

Local, deterministic checks that do not require Apple's daemon:

| Condition | Error |
| --- | --- |
| URL is not a file URL | `notFileURL` |
| File URL with an empty path | `noURL` |
| Missing path or a directory | `invalidFile` |
| Existing file that is not readable | `permissionDenied` |
| Readable regular file | `faceNotAvailable` (no watch-face library on Linux) |

## Fail-closed boundary

`addWatchFace` **never succeeds**. Linux has no paired Apple Watch, no
watch-face consent UI, and no `CLKWatchFaceLibrary` Mach service. A readable
`.watchface` file is not treated as an installed face. Completion handlers
run synchronously on the caller; Apple's queue and UI are not fabricated.

UIKit is listed as a seed dependency for later package integration. This
overlay does not `import UIKit`: the 13-identifier Swift surface has no UI
types, and the isolated host compile has no UIKit module.

## Deferred

- Entire ObjC complication / timeline / image-provider / gauge / text-provider
  surface from the remaining SDK headers.
- Watch-face file format parsing.
- Any claim that a face was added to a user's library.

Run the host gate:

```sh
bash full/clockkit/tests/acceptance/test_host.sh
```
