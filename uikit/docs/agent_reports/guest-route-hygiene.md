# Guest library route hygiene

Worktree `agent/guest-route-hygiene`. Close the Foundation-hidden Mach-O
library compile that went red after the ladder-phase merges (values39e,
materials40c, textkit41c, pickers41c, transitions39).

## What was measured

x86 cycle `c4dce839` (`/tmp/x86_cycle_c4dce83958717c0e0f361ad631c330df22cf2587.log`):

```
RUNG_SCOREBOARD a=PASS/smoke 14/14  b=CANNOT/widget guest failed  c=CANNOT/scene guest failed
```

`build_focus_widget_guest.sh` / `build_and_run_reminder_scene_guest.sh` failed
while compiling OpenUIKit with no Foundation.swiftmodule. First errors:

| file | line | diagnostic |
|---|---|---|
| `UIImagePickerController.swift` | 119 | `cannot find type 'NSNumber' in scope` |
| `UIPrintInteractionController.swift` | 44, 52, 56, 146 | `cannot find type 'URL' in scope` |
| `UIPrintInteractionController.swift` | 147 | `cannot find type 'Data' in scope` |

NSObject (`#if canImport(Foundation) import class Foundation.NSObject #elseif canImport(ObjectiveC) import class ObjectiveC.NSObject`) and the `import Dispatch` + `canImport(Foundation)` gate were already on main. The remaining misses are Foundation-typed API that the pickers/print/TextKit ladder added without a portable `#else`.

Guest visibility (same as `full/foundation/foundationessentials_import_guard.swift`):

- `canImport(Foundation)` **false** (no Foundation module on `-I`)
- `canImport(FoundationEssentials)` **true** (`URL`, `Data`, `Date` live here)
- facade types in `full/foundation/foundation_guest_sources.txt` (`NSNumber`, `NSPredicate`, `Progress`, `NSError`) exist only **after** OpenUIKit is built — they must not be named in library sources unless `canImport(Foundation)`

## Rule (one per type family)

Sibling: `UIDatePicker.swift` (`Foundation` else `FoundationEssentials`), `UIApplication.swift` / `UIPasteboard.swift` / `UISceneActivationConditions` (hide Foundation-only members).

1. **`URL` / `Data`** — import `FoundationEssentials.URL` / `.Data` when Foundation is hidden. Public API stays. Measured: c4dce839 print controller lines 44 and 146–147.
2. **`NSNumber` / `NSPredicate` / `Progress`** — not in FoundationEssentials. Keep the Darwin spelling under `#if canImport(Foundation)`; guest else is `[Int]?` (capture-mode raw values) or the member is omitted (predicate / loadingProgress), matching `UISceneActivationConditions`.
3. **`NSError` construction** — `UIDocumentBrowserErrorCode` already conforms to `Error`. Darwin still wraps `NSError(domain:code:)`; guest returns the enum. Completions stay `Error?`.

## Files fixed

| file | before (guest) | after |
|---|---|---|
| `UIImagePickerController.swift` | `availableCaptureModes → [NSNumber]?` unguarded | `#if canImport(Foundation)` `[NSNumber]?` else `[Int]?` |
| `UIPrintInteractionController.swift` | `URL` / `Data` unguarded | `#elseif canImport(FoundationEssentials)` import both |
| `UIDocumentPickerViewController.swift` | `import struct Foundation.URL` only | same `#elseif` FE.URL |
| `UIDocumentBrowserViewController.swift` | `URL`, `NSError(…)`, `Progress?` | FE.URL; `unavailableError` branches; `loadingProgress` Foundation-only |
| `UIFontPickerViewController.swift` | `NSPredicate` unguarded | Foundation-only, like `UISceneActivationConditions` |
| `NSTextAttachment.swift` | `Data` imported only under Foundation | `#elseif` FE.Data (`contents` / `NSAdaptiveImageGlyph`) |

No CQuartz change. UIKit shim already re-exports FE when Foundation is hidden.

## Guest compile (Mac)

`clang-18` is not on this Mac; `full/scripts/build_full.sh` is the Linux-hosted Darwin cross. The OpenUIKit / UIKit / CQuartz slice of that recipe is `uikit/scripts/guest_route_check.sh`:

```
cd uikit
scripts/guest_route_check.sh
```

Binds `swift-macho-spike:python3-nosde-preflight-20260830` (Swift 6.2.4), Darwin sysroot `scratch/sysroot_fe4` (no `Foundation.swiftmodule`), staged FE at `scratch/fe4_out`. Same `swiftc -target arm64-apple-macos15.0 -sdk $SYS` flags as `build_full.sh` (`-disable-implicit-string-processing-module-import`, `-disable-objc-attr-requires-foundation-module`).

**Before:** x86 log errors above (OpenUIKit does not emit a module).

**After:**

```
== guard: Foundation hidden, FoundationEssentials required
   -> exact visibility holds
== CQuartz (37 TUs)
   -> CQuartz objects
== OpenCoreGraphics (12 files)
== OpenUIKit (131 files, Foundation hidden)
== UIKit shim (Foundation hidden)
GUEST_ROUTE_COMPILE_OK openuikit=131 opencoregraphics=12
GUEST_ROUTE_CHECK_OK elapsed=63s
```

Wired into `scripts/agent_merge.sh` immediately after the Catalyst gate (`==> guest library route`). 63 s ≪ 10 minute bar.

## Gates (this Mac, 2026-09-06)

| gate | result |
|---|---|
| Guest library compile | **GUEST_ROUTE_COMPILE_OK** 131/12 files, **63 s** |
| Catalyst | **124/124** |
| iOS suite `SKIP_CAPTURE=1` `/tmp/suite-guest-route-hygiene` | **112/113** (`corner_radius` 99.411) — main's count |
| Real-app floors scale 3 | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**; 14 PNGs including ledger + focus home |
| `swift test --filter SystemPickerTests\|TextKitTests\|DatePickerTests` | **42/42** |
| Linux `swift:6.2-noble` `openrender` | green (261.79 s) |
| `scripts/linux_verify.sh` | **124/124**, byte-identical **178/178**, `PORTABILITY VERIFIED` |
| `scripts/linux_realapp_verify.sh` | **14/14** headless, **10/10** live, `REAL-APP SCREEN VERIFIED ON LINUX` |
| `Package.resolved` | not committed |
