# Linux trial — build and run a new iOS app with Linux only

Eighth conformance app `Sources/ConformanceApps/Notes/`. Same UIKit source
as the others (one `import UIKit`, Foundation via UIKit's re-export). This
round did **not** close an iOS-oracle pixel gap: it asked whether a new
app can be written, compiled, and recorded without Mac Swift.

Window 375×667 scale 2 (iPhone SE point size, the conformance default).
Script `Sources/ConformanceApps/Notes/script.json`. Linux captures:
`docs/agent_reports/linux-trial/*.png`.

## What was measured (Linux ELF, not the iOS simulator)

Container `uikit-linux` = `swift:6.2-noble`, Swift **6.2.4**,
`aarch64-unknown-linux-gnu`. Every `swift` / `openhost` / `openrender` /
`compare.py` invocation was `docker exec uikit-linux bash -c '...'`.
`/src` is a **read-only mount of a different tree** (the main
`openuikit/uikit` checkout); the worktree was tar-copied to `/work`
(`tar --exclude=.build --exclude=Package.resolved`). No Mac `swift`,
`xcrun`, `simctl`, or `openrender`.

`openhost --app Notes --script Sources/ConformanceApps/Notes/script.json
--record /tmp/notes-linux` with `SDL_VIDEODRIVER=dummy
OPENUIKIT_FONT_DIR=/work/fonts OPENUIKIT_BACKEND=quartz`. 13/13 captures
in 1.9 s. Layout dumps (not pixels) are the measurements below.

| capture | action just before | layout fact |
|---|---|---|
| t200 | (rest) | 8 notes; first title "Meeting notes"; timestamp **"Sep 4, 2026 at 10:30 AM"** (U+202F before AM) |
| t1200 | push | UITextView body + timestamp; Done bar button; title "Meeting notes" |
| t2100 | focus-body | **byte-identical to t1200** — no keyboard chrome in the window |
| t3000 | done | pop; 8 notes again (sha256 = t200) |
| t4000 | focus-search | search active |
| t5000 | type-search "Meet" | one row, "Meeting notes"; field text "Meet" |
| t6000 | cancel-search | 8 notes again (sha256 = t200) |
| t7000 | select-tab-settings | UISwitch `isOn=false`, segment `0` (Date) |
| t8000 | toggle | UISwitch `isOn=true`, segment still `0` |
| t9000 | segment-1 | UISwitch `isOn=true`, segment `1` (Title) |
| t10000 | select-tab-notes | 8 notes (sha256 = t200) |
| t11000 | delete | alert title `Delete "Meeting notes"?`, Cancel + Delete |
| t12000 | confirm-delete | first row is **Grocery list**; Meeting notes gone |

Nine unique PNGs of 13 (the four list-rest frames hash together; the two
detail frames hash together). Catalyst gate on the same container:
`openrender render` + `Tools/compare/compare.py --out /tmp/gate-linux-trial`
→ **124/124 scenes pass**.

DateFormatter was **not** missing on this path. corelibs-foundation
`DateFormatter.dateStyle = .medium; timeStyle = .short`, locale `en_US`,
GMT, pinned `DateComponents` for 2026-09-04 10:30, produced
`Sep 4, 2026 at 10:30\u202fAM`. That is a guest-vs-corelibs fact, not a
compile failure: the arm64-apple-macos guest Foundation still has no
DateFormatter (docs/AGENT_BRIEF_ORACLE.md). The operator's iOS capture
should check whether real UIKit uses U+202F or a regular space.

UserDefaults: `register(defaults:)`, `bool(forKey:)`, `integer(forKey:)`,
`set(_:forKey:)` all ran. Settings state in t8000/t9000 is the proof.

Search used `hasPrefix` only (GATE_B / `libswift_StringProcessing`).

## Failure log (every miss, and how it was passed)

1. **`scripts/gen_conformance_registry.sh` is zsh.** `bash` dies at line 19
   (`*(/N)`). `zsh` is not on the image (`command not found`). Passed by
   writing `Registry.swift` by hand to match the generator's format
   (Notes inserted in sorted order) and re-scanning the directory with
   Python inside the container. ConformanceRegistryTests could not be
   run (see 5).

2. **`/src` is not this worktree.** The container bind-mounts
   `/Users/miguelsalinas/openuikit/uikit`. Building there would have
   compiled main, not Notes. Passed exactly as the brief says: tar the
   worktree to `/work`.

3. **No SFNS fonts in the image.** `linux_verify.sh` copies
   `/System/Library/Fonts/SFNS*.ttf` from the Mac. This step only exists
   on Darwin. Passed by `docker cp` of those three files into
   `/work/fonts` and `OPENUIKIT_FONT_DIR`. Without them, labels would
   have no outlines. **This is a Mac-only dependency**, not a Swift
   workaround.

4. **`compare.py` needs PIL + numpy.** The image had neither
   (`ModuleNotFoundError: No module named 'PIL'`). Passed by
   `apt-get install python3-pil python3-numpy` inside the container
   (PIL 10.2.0, numpy 1.26.4). Then the Catalyst gate ran.

5. **`swift build --build-tests` does not link.** Linux Swift 6.2.4
   errors in pre-existing `CoreAnimationCompatibilityTests`: `@MainActor`
   XCTestCase vs nonisolated `setUp`/`tearDown` referencing
   `savedTime`. Not caused by Notes. `linux_selector_verify.sh`'s
   "build the tests and run the bundle" recipe cannot currently build
   the full suite. Registry correctness was checked with the Python
   directory scan instead.

6. **`UIImage(systemName: "note.text")` is nil.** Harvested
   `symbol_ink_ios.json` has 10 names (`calendar`, `clock`,
   `clock.fill`, `gear`, `house`, `house.fill`, `magnifyingglass`,
   `person`, `person.fill`, `plus.circle.fill`). `gear` is in the table
   (Settings tab). `note.text` is not, and `_UISystemImageRenderer` has
   no case for it, so the failable init returns nil. Compile succeeded;
   the Notes tab is title-only. Not patched — that would have been
   modelling from memory.

7. **`focus-body` is a no-op in the recorded window.** t1200 and t2100
   are byte-identical. OpenUIKit has no `UITextEffectsWindow`; the
   keyboard does not appear in `openhost --record` output. Logged, not
   faked.

8. **DateFormatter on the guest is still missing.** It compiled here
   because ELF Linux links corelibs-foundation. A Notes app that calls
   `DateFormatter()` will not compile on the arm64-apple-macos guest
   (UIDatePicker already spells medium dates with Calendar components
   for that reason). No DateFormatter was added to the port.

Nothing else failed. `openhost` linked in 180 s from a cold `/work`;
the Notes sources compiled on the first try, including DateFormatter
and UserDefaults. Headless record worked on the first try with
`SDL_VIDEODRIVER=dummy` (libsdl2-dev was already on the image).

## What worked with zero Mac Swift

- Cold `swift build -c release --product openhost` and `--product openrender`
- DateFormatter `.medium` + `.short` (corelibs)
- UserDefaults round-trip on the settings screen
- UITabBarController, UINavigationController push/pop, inset-grouped
  UITableView, UISearchController, UITextView, UISwitch,
  UISegmentedControl, UIAlertController
- `openhost --app Notes --script --record` (13 captures)
- Catalyst `openrender render` + `compare.py` **124/124**

## What did not (Mac-only or still broken)

- iOS-simulator goldens / `confprobe` / `xcrun simctl` — Mac only, by
  design. The operator grades this app on the simulator afterwards.
- SFNS font files — must be copied from macOS; not in the Linux image
  and not redistributable in the repo.
- `gen_conformance_registry.sh` — zsh, not on the image.
- Full `swift test` / `--build-tests` — MainActor XCTest isolation on
  6.2.4.
- Guest DateFormatter — still absent; this container hides that gap.
- Keyboard window — not in the recorded PNG.
- `note.text` SF Symbol — not harvested.

## Ranked list of what the environment needs next

1. **Mount the agent's worktree at `/src`, or document `/work` as the
   only writable tree.** Today's `/src` is main. An agent that `cd /src`
   builds the wrong bits.
2. **zsh, or a POSIX/Python `gen_conformance_registry.sh`.** Adding an
   app on Linux currently means hand-editing a GENERATED file.
3. **Bake `python3-pil` and `python3-numpy` into `uikit-linux`.** The
   Catalyst gate cannot run until apt-get.
4. **A documented font injection that is not a Mac `docker cp`.** Either
   a licensed-or-metric-only path that the image already has, or a
   well-known volume the operator mounts. Without SFNS, Linux captures
   are not comparable.
5. **A DateFormatter story that matches the guest.** ELF Linux accepts
   `DateFormatter()`; the guest Foundation does not. Apps written in
   this container will fail GATE_B / guest compile unless the port
   grows a measured subset or apps are taught the Calendar spelling
   UIDatePicker already uses.
6. **`@MainActor` XCTest on Linux 6.2.4.** `swift build --build-tests`
   is red before Notes exists. linux_selector_verify's retry loop
   cannot start.
7. **Keyboard / `UITextEffectsWindow` in `openhost --record`.** First
   responder on a UITextView did not change a pixel.
8. **Harvest `note.text` (and other app-typical symbols) into
   `symbol_ink_ios.json`.** `gear` is there; a Notes tab is not.

## Files

- `Sources/ConformanceApps/Notes/NotesApp.swift`
- `Sources/ConformanceApps/Notes/NotesListViewController.swift`
- `Sources/ConformanceApps/Notes/script.json`
- `Sources/ConformanceApps/Registry.swift` (Notes in sorted names /
  `loadRegistry`)
- `docs/agent_reports/linux-trial/*.png` (13 frames)
- this report
