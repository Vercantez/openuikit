# Simplenote launch rung 2, pass 2

**Date:** 2026-09-07  
**Route:** (b), Apple toolchain → Mach-O guest → `machorun`  
**Corpus:** Automattic/simplenote-ios `9b1bb17d8ec224a709d306e0ec34cee38bc7d933`  
**Status:** first screen not reached; all scores are N/A.

This pass stops at measured build and ABI walls. It does not claim a launch,
account, sync, analytics, crash-report, or network success, and it does not
modify `full/scripts/build_full.sh` or guest pin wiring.

## Measurements and changes

| step | measurement | result |
|---|---|---|
| Mixed build graph | 228 present Swift + 50 Objective-C + 12 C; 59 discovered headers; `Simplenote-Swift.h` is imported by 27 ObjC units | `Tools/ingest/xcodeproj_to_package.py` now emits a regenerable Swift target, Clang target, generated umbrella, and compatibility Swift header. The generated Swift-header build order remains a wall. Fixture coverage is in `Tools/ingest/test_xcodeproj_to_package.py`. |
| Objective-C UIKit facade | 50 files referenced 70 unique missing declarations before this pass; 31 were pure declarations; 39 remain interface/behavior walls | Added the measured pure declarations for application/window/navigation, containment/lifecycle, scroll/table/cell, and text interfaces. Full list and census are in `simplenote-launch2-objc-facade.json`; no behavioral member was fabricated. |
| Simperium | Import probe was missing; pinned source is a binary XCFramework (`5561a15a4836efe5d068a366b60599b7b794af70`). The app calls authentication, buckets, `SPUser`, `SPManagedObject`, and local-change status. | Added the exact app-called ObjC declarations and a Darwin Clang target. Every authentication/save/sync operation fails closed or no-ops and logs once; no account or network success is fabricated. `swift build --target Simperium` completes with one Apple nullability warning. |
| AutomatticTracks | Import probe was missing; pinned split package requires Sentry/Sodium/UIDeviceIdentifier. The app calls `TracksService` identity/event selectors and `CrashLogging`/`TracksUser` Swift APIs. | Added `AutomatticTracksModelObjC` and `AutomatticTracks` Darwin targets with exact measured signatures. Event and crash logging entry points return failure/no-op and log once; no analytics, crash report, or network success is fabricated. Both target builds complete. |
| MobileCoreServices | Two Swift imports; only `UTType.data` is referenced. macOS 26.1 SDK: `no such module 'MobileCoreServices'`; iOS simulator SDK: module available | Added a package `MobileCoreServices` module that aliases `OpenUIKit.UTType`; `swift build --target MobileCoreServices` completes. This is a host package port, not silent SDK use. |

## Updated blocker table

| blocker | measured state after pass 2 |
|---|---|
| Mixed language graph | Split emission is implemented and regression-tested. Generated `-Swift.h` consumers still require a staged build order/driver; no hand-written package was used. |
| ObjC UIKit ABI | 31/70 pure declarations added. The remaining 39 are behavioral or otherwise not pure declarations over existing OpenUIKit API; they remain measured walls. |
| Services | Simperium and AutomatticTracks package targets compile on Darwin with fail-closed shims. Guest package integration and any real service behavior remain out of scope for this pass. |
| MobileCoreServices | The host SDK cannot provide the module; the package port supplies the measured `UTType.data` surface. |
| Dependency/platform branches | SimplenoteFoundation remains CoreData/AppKit-backed on the Apple route; no guest Foundation claim is made. |
| Generated app material | Credentials, generated Swift header ordering, intent classes, CoreData model compilation, and NIB runtime instantiation remain open. |
| Guest wiring | `full/scripts/build_full.sh` and pin files are intentionally untouched; later wiring must add the new service/module targets to the guest route. |
| Oracle/first screen | No valid first-screen capture exists. Score: **N/A**, not a comparison score. |

## Validation

Target checks completed before the final proof:

```text
swift build --target AutomatticTracksModelObjC  # complete
swift build --target AutomatticTracks              # complete
swift build --target Simperium                     # complete; 1 nullability warning
swift build --target MobileCoreServices             # complete
```

The final required merge proof was run from the monorepo root. Its exact tail
will be appended after the proof completes; the script is expected to exit
128 in its cleanup path after a successful `CHECK_ONLY` run, and the printed
lines—not that cleanup status—are the criterion.
