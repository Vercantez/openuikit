# Guest app path: core-guest Foundation / SwiftUI / Combine

## What was measured

`full/scripts/build_full.sh` compiled RealAppProbe from

```
Sources/RealAppProbe/*.swift
Sources/RealAppProbe/Vendored/*.swift
```

against a 49-line Foundation identity module (`full/appshim/Foundation.swift`:
NSCoder + Bundle aliases). Focus/Hackers sat behind
`#if canImport(Onboarding)` / `#if canImport(Domain)`, so the guest `realapp`
path emitted **10** Pocket Casts screens. SwiftPM (macOS + Linux corelibs)
already compiled the stub modules and the `Focus/` / `Hackers/` /
`Vendored/{Focus,Hackers}/` trees, so those routes already rendered **12**.

The 38-file facade (`full/foundation/foundation_guest_sources.txt`) and the
widget-gate Combine/SwiftUI sources already existed. This branch makes the
guest app compile consume them **without** putting a module named Foundation
on OpenUIKit's or UIKit's include path (the umbrella-shadows-reexport hazard
in `full/appshim/Foundation.swift`: 33 `canImport(Foundation)` guards).

## Rule

1. Keep the tiny APPINC Foundation for DeveloperToolsSupport; compile UIKit
   without `-I APPINC` (unchanged; `test_core_guest_package.py` /
   `test_true_ios_full_build.py` / `test_notification_guest_aliases.py`).
2. After that boundary, emit Combine / OpenCombine / Symbols / SwiftUI
   (Foundation **hidden**, widget-gate order) and Dispatch / CoreFoundation /
   FoundationInternationalization into `appmods/`, then **overwrite**
   `APPINC/Foundation.swiftmodule` with the 38-file FoundationGuest facade.
3. Compile each `Sources/RealAppProbe/{Focus,Hackers}Modules/<M>/` as module
   `<M>` in import-dependency order, then the harness from
   `*.swift` + `Vendored/*.swift` + `Vendored/*/*.swift` + `Focus/` +
   `Hackers/` with those modules and Foundation/SwiftUI/Combine on `-I`.
4. Link the objects and the FI / OpenCombine / Dispatch / C-bridge dylibs
   into `render_full`.

## Before / after (guest `realapp`)

| route | screens before | screens after |
|---|---|---|
| guest `render_full realapp` (this branch) | 10 Pocket Casts | **12** (Pocket Casts + Focus Settings + Hackers feed) |
| SwiftPM macOS / Linux corelibs | 12 | 12 (canImport guards removed; no-op) |

Pixel floors unchanged: 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 /
97.516 / 99.511 / 82.192 / 99.760 / 99.689 / 84.582.

## Module map

Which `import` resolves to which module on each route.

### Library compile (OpenUIKit, OpenCoreGraphics, UIKit shim)

Unchanged. Search path is `$OUT` + FoundationEssentials (`FEMODULES`).
**No** APPINC. `import Foundation` is false (`canImport(Foundation)` stays
off). `import FoundationEssentials` is the production FE module.

### DTS (standalone)

Sees the tiny APPINC Foundation (`typealias Bundle = OpenUIKit.Bundle`) so
`DeveloperToolsSupport` names OpenUIKit's exact bundle identity.

### App modules (APPINC + APPMODS, after the overwrite)

| import | guest (`render_full`) | SwiftPM macOS | SwiftPM Linux corelibs |
|---|---|---|---|
| `Foundation` | `FoundationGuest` 38-file facade (`APPINC`, overwrites the DTS shim) | Apple Foundation | corelibs-foundation |
| `FoundationEssentials` | production FE (`FEMODULES`) re-exported by the facade | Apple (re-export) | corelibs |
| `FoundationInternationalization` | pinned FI + ICU (`appmods`, core-guest builder) | Apple | corelibs |
| `Combine` | `full/oracle-opencombine/Combine.swift` → OpenCombine | Apple Combine | `OpenCombine` target (Package.swift) |
| `Dispatch` | `full/dispatch/Dispatch.swift` | Apple | corelibs |
| `SwiftUI` | `Sources/SwiftUI` (Foundation-hidden, widget-gate sources) | first-party `Sources/SwiftUI` | same |
| `Observation` | Darwin SDK overlay + host `ObservationMacros` plugin | toolchain Observation | toolchain Observation |
| `OpenUIKit` | Foundation-hidden OpenUIKit (`$OUT`) | OpenUIKit | OpenUIKit |
| `UIKit` | `Sources/UIKitShim/UIKit.swift` (`UIKITINC`, Foundation-hidden re-export) | UIKitShim | UIKitShim |
| `Onboarding` / `Glean` / `Intents` / `IntentsUI` / `Licenses` | `FocusModules/<M>` | same SPM targets | same |
| `Domain` / `Shared` / `DesignSystem` | `HackersModules/<M>` (Hackers `DesignSystem` also satisfies Focus's `import DesignSystem`) | same | same |

`Intents` / `IntentsUI` on APPINC are the **Focus stubs**, not the core-guest
production Intents modules (those would collide).

### What stays Foundation-hidden

OpenUIKit, OpenCoreGraphics, the UIKit shim, SwiftUI (widget-gate compile:
`UIHostingController` is not behind `canImport(Foundation)`). A module named
Foundation on those invocations' `-I` is the measured hazard.

## Verify attempts

Recorded as this branch is pushed and `queue_box.sh` is graded by the
script's own lines (`build_full rc=0`, `TBD_CHECK_OK`, `difftest rc=0`,
`GATE_B_PASS`, plus `GUEST_REALAPP_SCREENS=12`), then the x86 cycle
(`RUNG_SCOREBOARD a=PASS b=PASS c=PASS`).

Attempt 1: `13db41e08f27875872e84e204a32772872a295c1`.
`TBD_CHECK_OK`, `difftest rc=0`. `build_full rc=2`:
`OpenUIKit in-repo tree cb130cad… expected f2b69151… (git rev-parse HEAD:uikit)` —
agent uikit/ edits (RealAppProbe Focus/Hackers) change HEAD:uikit; the pin
advances after merge. `GATE_B_FAIL rc=2` (widget guest asserts the same pin).
`guest_realapp` SIGTRAP on a stale `render_full`.

Attempt 2: `2c2958924b90ccfea8cdcb3124ff11677e978278`.
`TBD_CHECK_OK`, `difftest rc=0`. `build_full rc=2`:
`ObservationMacros plugin missing (Shared @Observable)` after
`FOUNDATION_INTERNATIONALIZATION_BUILD_OK swift=61 icu-cpp=474 icu-headers=205`.
Pin override worked. `GATE_B_FAIL rc=2` (nested build_full same miss).
`GUEST_REALAPP_SCREENS=0` skipped.

Attempt 3: `6080bbc1c7d4c06ee460b645c700cebfbfd79ac6`.
`TBD_CHECK_OK`, `difftest rc=0`. `build_full rc=1` (not `die`'s 2) after
FI OK — likely `-load-plugin-library` of a toolchain plugin without its
SwiftSyntax host libs. Log grep missed the swiftc line (`tail -8` of OK).

Attempt 4: stage ObservationMacros next to SwiftSyntax host libs like the
core guest package; `-plugin-path` + `-load-plugin-library`; print the last
40 lines of `build_full.log`.
