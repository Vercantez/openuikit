# NetNewsWire: the iOS target, separated from the whole-repo walk

Branch `agent/netnewswire-ios-target`, 2026-09-10. Task: APP_LADDER §9.6
lists NetNewsWire's top BLOCKING row as `NSToolbarItem` (48 uses) and says
"Catalyst/macOS-shaped demand included by the whole-repo walk. Separate the
iOS target before treating its 48 uses as a phone launch wall." This does
the separation as a reusable census mechanism, re-runs the unchanged
classifier under it, and proves a control app is untouched.

Corpus read from `~/openuikit/scratch/ladder-corpus/NetNewsWire` at the
pinned `3b378e72` (present, read-only). No app source, pin, bundle or
`Package.resolved` was changed.

## How an app's file set was enumerated before

`full/ladder/ladder_census.py` walks the whole repository of every corpus
app: `os.walk` from the clone root with apicensus's `SKIP_DIRS` for the
UIKit walk and the model census's skip set for the rest. `classify_gaps.py`
reads the census JSON's `uikit.missing` list and never sees a file. For a
repo that ships a Mac app and an iOS app from one tree, `Mac/` and every
`#if os(macOS)` body in a shared package land in the phone denominator.

## The target-scope mechanism

Three pieces, all under `full/ladder/`:

| file | what it does |
| --- | --- |
| `target_scope.py` (new) | Reads the `.xcodeproj` with the port's own parser (`uikit/Tools/ingest/xcodeproj_to_package.py: ProjectGraph`). Scope = the named target's `PBXSourcesBuildPhase` + `PBXFileSystemSynchronizedRootGroup` members − that target's membership exceptions, + `Sources/` of every local package reachable transitively through `.package(path:)` from the target's product dependencies, − files whose whole body sits under `#if os(macOS)` / `os(OSX)` / `canImport(AppKit)` / `targetEnvironment(macCatalyst)`. Writes `{"apps": {NAME: {"files": [...], provenance}}}`. |
| `ladder_census.py` (`--target-scope=FILE`) | For apps named in the file, every per-file walk (UIKit, model/SwiftUI/selector, language mix) is restricted to the list; `build` stays repo-wide. Apps not named are walked as before. The flag is stripped before positional args, so every existing invocation is unchanged. A scoped census carries `_scope` at the top level and per app. |
| `test_target_scope.py` (new) | 6 tests: the guard rule's accepted shapes and its refusals (early `#endif`, `#else` branch, `os(iOS)`, `!os(macOS)`), partial regions, a synthetic two-app corpus proving the control app is byte-identical with and without the flag and the scoped app loses exactly the out-of-scope file, and one test against the real clone (no `Mac/` file in scope, `NewsBlur` reached transitively via `Account`, no `NSToolbarItem` text in any in-scope file). |

Product-to-package resolution had to be done by scanning `Package.swift`
files: NetNewsWire's `Modules/` is a synchronized folder, not an
`XCLocalSwiftPackageReference`, and Xcode 16 omits `package =` on unique
product names, so the ingest parser's `local_package_infos()` is empty for
it. All 15 implicit products resolved; `Zip` (remote) and `Tidemark`
(RSParser's remote dep) are listed, not walked.

Stated blindness: a partial `#if os(macOS)` region inside an in-scope file
is still counted whole. Measured for this scope: 20 in-scope files carry a
partial guard and 0 SDK-type uses fall inside those regions, so the residual
over-count on the iOS side is zero here. It cannot hide a blocker, only
overstate demand.

## The scope, in numbers

| piece | files |
| --- | --- |
| `NetNewsWire-iOS` target sources (`iOS/` 86 + `Shared/` 65, Swift) | 150 (+1 `.h`) |
| local packages reachable (all 17 under `Modules/`) | 325 sources |
| excluded by whole-file macOS guard | 28 (22 `RSCore/AppKit/*`, `RSCore/{MemoryPressureMonitor,SendToBlogEditorApp}`, 2 `RSCoreResources/AppKit/*`, `RSTree/NSOutlineView+RSTree`, `RSWeb/MacWebBrowser`) |
| **in scope** | **429 Swift / 448 sources** |
| out of scope | `Mac/` 112 Swift, Mac app target (176), Widget extension (9), test targets (15), share extensions (0 own files) |

## Result: whole repo vs iOS target, same instrument, same inputs

Inputs: SDK alphabet `uikit_sdk_types-2026-09-16.txt` (737),
`openuikit_types-2026-09-10.txt` regenerated from `uikit/Sources/OpenUIKit`
at `5b2a7364` (435 names). Note on the ours list: the committed
`openuikit_types-2026-09-16.txt` has 411 names but
`ladder-census-2026-09-16.json` records `_meta.ours = 427` (regenerated on
2026-09-07, list not committed — the generator-not-in-the-gates shape).
NetNewsWire whole-repo is 2 blocking / 50 uses under 427 or 435; under 411
it would be §9.6's 6 / 71. Both runs here use the 435 list.

| NetNewsWire | whole repo | iOS target scope |
| --- | --- | --- |
| Swift files (UIKit walk) | 605 | 429 |
| UIKit uses / distinct types | 1,598 / 129 | 1,333 / 124 |
| missing after FREE/OOS | `NSToolbarItem` 48, `NSMenuToolbarItem` 2 | none |
| **BLOCKING types / uses** | **2 / 50** | **0 / 0** |
| stub-able types / uses | 0 / 0 | 0 / 0 |
| unclassified | 0 / 0 | 0 / 0 |
| top ≤3 BLOCKING | `NSToolbarItem` 48 · `NSMenuToolbarItem` 2 | none |
| `#selector` sites | 321 (Tests included) | 175 (Tests excluded by construction) |
| languages | 696 swift / 15 h / 10 m | 429 swift / 10 h / 9 m |

Where the 50 live: `Mac/MainWindow/MainWindowController.swift` 36 + 2,
`Mac/Preferences/PreferencesWindowController.swift` 9,
`Modules/RSCore/Sources/RSCore/AppKit/NSToolbar+RSCore.swift` 2,
`Modules/RSCore/Sources/RSCore/AppKit/RSToolbarItem.swift` 1. The two RSCore
files are whole-file `#if os(macOS)`.

So under its own target NetNewsWire has no blocking UIKit row, the same
standing §9.6 gives focus-ios, eidolon and simplenote-ios. What is left for
it is not a UIKit type: `DEP = ?` (Zip, Tidemark and the 17 local packages
are unmeasured by `dep_class.py`) and the route-(a) `#selector` count (175
in scope; still SEL = 3).

## Control and reproduction checks

- **Hackers** (not named in the scope file): census output byte-identical
  between the scoped and unscoped runs; classifier 0 / 0 in both.
- Both apps' `swiftui`, `model`, `languages`, `build`, `swift_lines` and
  `imports` fields equal `ladder-census-2026-09-16.json` exactly, so the
  refactored language walk and the flag parsing changed nothing for an
  unscoped app.
- The whole-repo NetNewsWire run regenerated alongside reproduces 1,598 uses
  / 129 distinct / 2 blocking / 50 uses.
- `python3 -m unittest full/ladder/test_target_scope.py` — 6 passed.
- `uikit/Tools/ingest/test_xcodeproj_to_package.py` — 23 passed, 24 skipped
  (unchanged; the parser was used, not modified).

Reproduce from the repo root, with `<corpus>` = `~/openuikit/scratch/ladder-corpus`:

```sh
python3 full/ladder/target_scope.py <corpus>/NetNewsWire <corpus>/NetNewsWire/NetNewsWire.xcodeproj \
    NetNewsWire-iOS target-scope-netnewswire-ios-2026-09-10.json
python3 full/ladder/ladder_census.py <corpus> full/ladder/uikit_sdk_types-2026-09-16.txt \
    full/ladder/openuikit_types-2026-09-10.txt census-ios.json \
    --target-scope=full/ladder/target-scope-netnewswire-ios-2026-09-10.json
python3 full/ladder/classify_gaps.py census-ios.json full/ladder/uikit-union-2026-09-16.json gap-ios.json
```

Artifacts: `full/ladder/target-scope-netnewswire-ios-2026-09-10.json`,
`full/ladder/gap-classes-netnewswire-ios-2026-09-10.json` (both scopes, the
diff, where the blockers live, the residual, the control),
`full/ladder/openuikit_types-2026-09-10.txt`, APP_LADDER §9.8.

## Walls and what was not done

- Only NetNewsWire is scoped. Every other §9 row is still whole-repo; a
  scope for another dual-platform app is one `target_scope.py` call.
- The classifier's inputs for the other 19 apps were not regenerated; the
  numbers here are for two apps from a two-symlink mini-corpus, with the
  control proving the mechanism is inert for unnamed apps.
- No simulator, no build, no pixel claim. `SIM_DEVICE_SUFFIX` was not needed.
- The 09-16 `ours` list mismatch (411 committed vs 427 recorded) is reported,
  not repaired; the operator's regeneration should commit the list it used.
