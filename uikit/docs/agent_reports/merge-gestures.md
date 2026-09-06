# Merge `origin/agent/uikit-gestures-dnd` onto main (tail-values NSItemProvider)

MERGE TASK, no new rules. `origin/agent/uikit-gestures-dnd` (`69e883e8`,
report `uikit-gestures-dnd.md`) was written on main `e08c83a5` /
merge-base `988e756d`. Main has since landed `agent/values39e-merged`
(report `uikit-tail-values.md`): OpenUIKit's own `NSItemProvider.swift`,
reworked `UIPasteboard.swift`, `UIAccessibilityCustomAction`, haptics,
shortcut items, scene types.

The operator's checked merge compiled on macOS and was LINUX BUILD RED
(`docker exec uikit-linux swift build`):
`Sources/OpenUIKit/UIPasteboard.swift:466` `'nil' requires a contextual
type` and `instance member 'items' cannot be used on type 'Self'` — keep-both
of the two branches' UIPasteboard / NSItemProvider edits, which only
type-checks with Darwin Foundation.

This merge keeps **one** `NSItemProvider`: tail-values is the base; drag
items use it. Never keep-both on Swift. Pin files stay main's.
`scripts/vendor_pins.sh`, `env/`, `scripts/env/` untouched. Nothing
outside `uikit/`. No `Package.resolved`.

## File resolutions

| file | how it was resolved |
|---|---|
| `Sources/OpenUIKit/FoundationTypes.swift` | **Conflict-free auto-merge** added the gestures Linux class + Darwin `typealias NSItemProvider = Foundation.NSItemProvider`. **Dropped.** That duplicate is what made Linux see two types (or Darwin's missing type) and broke `UIPasteboard.Self.items(from:)`. Bundle / NSCoder aliases stay main's. |
| `Sources/OpenUIKit/NSItemProvider.swift` | **Main's tail-values file is the base.** Linux class + Darwin UIImage/UIColor helpers unchanged. Added only what drag needs: `_canLoad` / `_load` (process-local typed getters; Darwin tests set `UIDragItem.localObject` because Foundation does not expose one) and Linux `init(contentsOf:)` (`public.file-url` + `suggestedName`), the census spelling gestures had. MEASURED GestureProbe / ValuesProbe citations stay on the existing methods. |
| `Sources/OpenUIKit/UIPasteboard.swift` | **Main's, unconflicted.** `itemProviders` / `Self.items(from:)` / Linux `any NSItemProviderWriting` vs Darwin `NSString` stay. No keep-both. |
| `Sources/OpenUIKit/UIViewCompat.swift` | **Main's, unconflicted.** Tail-values `accessibilityCustomActions` / rotors kept. Gestures did not uniquely edit this file. |
| `Sources/OpenUIKit/UIView.swift` | Auto-merged: `_pasteConfiguration` from gestures next to `_interactions`. |
| `Sources/OpenUIKit/UIDragDrop.swift` | Incoming as-is. `UIDragItem.itemProvider` is the tail-values / Foundation type; Linux session load calls `_canLoad`/`_load` on that class. |
| `Sources/OpenUIKit/UIGestureRecognizer.swift` | Incoming pinch / rotation / hover / top-bottom screen-edge (MEASURED GestureProbe, SE 2x / iOS 26.1: pinch 10 pt + 8 pt hysteresis, rotation 10° + 5° hysteresis, lift 0.325 s / 10 pt). |
| `UITableView.swift` / `UICollectionView.swift` / `UIEvent.swift` / `UIContextMenu.swift` / `UINavigationController.swift` | Auto-merged; dragDelegate / dropDelegate / lift press from gestures. |
| `docs/REAL_APP_TEST.md` | **Only git conflict.** Both sides' rows kept. This merge newest; then pickers / TextKit / materials / tail-values / transitions / URLSession; then the incoming gestures-dnd row; then the rest of main. |
| tests + `uikit-gestures-dnd.md` | Incoming as-is (`PinchRotationHoverTests`, `UIDragDropTests`). |

## What the Linux red was

Gestures declared `NSItemProvider` in `FoundationTypes.swift` (`#if os(Linux)`
class, else Darwin typealias). Tail-values put the measured class in
`NSItemProvider.swift` (`#if os(Linux)` class, Darwin extensions on
Foundation's type). Keep-both left both declarations. On Linux corelibs
that is either a duplicate type or a Darwin-only `NSItemProvider` with no
`items(from:)` helper, so `setItemProviders` / `expirationDate: nil` lose
their contextual type.

Rule: **one identity**. Darwin / guest Foundation already vends the type;
Linux uses the tail-values class. Drag does not grow a second provider.

## Guest library route

No unguarded `import Foundation` / `import Dispatch` in library sources
(`agent_merge.sh` awk on `main...HEAD`; UIDragDrop's Foundation import sits
under `#if canImport(Foundation)`). Callback queue stays inside
`#if os(Linux)` and uses Foundation-re-exported `DispatchQueue` (same as
tail-values on main) — not a file-level `import Dispatch` the x86 guest
sysroot cannot build from its swiftinterface.

## Proof (this merge)

Mac (`SIM_DEVICE_SUFFIX=-merge-gestures`):

- `swift test --filter 'PinchGestureTests|RotationGestureTests|HoverGestureTests|ScreenEdge|UIDragDropTests|ValueTypeTailTests|PasteboardTests'`:
  **42 tests, 0 failures** (Pinch 5, Rotation 1, Hover 1, ScreenEdge 2,
  DragDrop 8, ValueTypeTail 15, Pasteboard 10).
- Catalyst **124/124** (`/tmp/gate-merge-gestures`).
- iOS suite **112/113**, miss `corner_radius` 99.411
  (`SKIP_CAPTURE=1` `/tmp/suite-merge-gestures`). Same as main.
- Real-app floors held vs `/tmp/golden_realapp_ios`:
  **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 /
  99.65 / 82.17 / 99.86 / 99.734 / 85.393**.
  `realapp_focus_home_light` and `realapp_ledger_light` missing goldens
  (same as sibling reports). `/tmp/app-merge-gestures`.

`docker exec -w /work-merge-gestures uikit-linux` (`swift:6.2-noble`;
tree tarred excluding `.build` / `Package.resolved`):

- `swift build -c release --product openrender`: **Build of product
  'openrender' complete! (198.08s)**
- `swift build --target ConformanceApps`: **Build of target
  'ConformanceApps' complete! (18.20s)**

No pixel rule changed. Catalyst paths stay behind the existing iOS cut.
Incoming measurements (pinch 110/108, rotation 0.087266465 at 10°, drag
lift 0.325 s / 10 pt) are unchanged and still cited next to the rules.

## Guest library route (2026-09-06, `agent/gestures-guest-route`)

Main (≥ `a4ea6caa`) runs `uikit/scripts/guest_route_check.sh` in the
checked merge. The operator's merge of merge-gestures was **RED**
(`~/openuikit/scratch/merge_gestures47-merged.log`):

```
UIDragDrop.swift:109/113/905/906/910 cannot find type 'NSItemProvider' in scope
UIDragDrop.swift:192/202 cannot find 'URL' in scope
```

Guest compile is `arm64-apple-macos` with Foundation hidden, so
`canImport(Foundation)` is false and `os(Linux)` is false. Tail-values
`NSItemProvider.swift` only vended the class under `#if os(Linux)`; Darwin
Foundation's type is not on the `-I` path. `UIDragDrop.swift` named both
types unguarded. No behaviour change on Darwin or corelibs.

### Rule

Sibling: `NSStringDrawing.swift` (`os(Linux) || !canImport(Foundation)`),
`UIPrintInteractionController.swift` (FE.URL when Foundation is hidden),
`UIGestureRecognizer.swift` (`Foundation.NSObject` else `ObjectiveC.NSObject`).
Progress / NSError / NSLock / DispatchQueue are not named on the guest
path — those facade types exist only after OpenUIKit is built
(docs/agent_reports/guest-route-hygiene.md).

| file | before (guest) | after |
|---|---|---|
| `NSItemProvider.swift` | class only `#if os(Linux)` | `#elseif !canImport(Foundation)` process-local class (`hasItemConformingToTypeIdentifier`, `registeredTypeIdentifiers`, `_canLoad`/`_load`, `init(contentsOf:)`). NSObject import form + FE.URL. |
| `UIDragDrop.swift` | `NSItemProvider` / `URL.self` unguarded | OpenUIKit's `NSItemProvider` spelling; `URL.self` via FE.URL; `_canLoad` when Foundation is hidden; NSObject import form. `loadObjects` → `Progress` stays `#if canImport(Foundation)`. |

### Proof (this Mac, `SIM_DEVICE_SUFFIX=-gestures-guest-route`)

**Before:** merge_gestures47-merged.log errors above (OpenUIKit does not emit a module).

**After:**

```
GUEST_ROUTE_COMPILE_OK openuikit=138 opencoregraphics=12
GUEST_ROUTE_CHECK_OK elapsed=55s
```

| gate | result |
|---|---|
| Guest library compile | **GUEST_ROUTE_COMPILE_OK** 138/12 files, **55 s** |
| `swift build --build-tests` (Mac) | Build complete (43.92 s) |
| `swift test --filter 'PinchGestureTests\|RotationGestureTests\|HoverGestureTests\|ScreenEdge\|UIDragDropTests\|ValueTypeTailTests\|PasteboardTests'` | **42 tests, 0 failures** |
| Catalyst | **124/124** (`/tmp/gate-gestures-guest-route`) |
| iOS suite `SKIP_CAPTURE=1` `/tmp/suite-gestures-guest-route` | **112/113** (`corner_radius` 99.411) — main's count |
| Real-app floors scale 3 | **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.17 / 99.86 / 99.734 / 85.393**; `realapp_focus_home_light` and `realapp_ledger_light` missing goldens (same as sibling reports) |
| Linux `swift:6.2-noble` `--target OpenUIKitTests` | **Build of target complete (45.82 s)** |
| Linux `swift:6.2-noble` `openrender` | green (**220.02 s**) |
| `Package.resolved` | not committed |

No pixel rule changed. `scripts/vendor_pins.sh`, `env/`, `scripts/env/` untouched.
