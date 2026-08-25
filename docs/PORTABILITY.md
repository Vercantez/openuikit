# Portability — verified, not asserted

OpenUIKit claims to be a *portable* UIKit. This document records what was
actually tested, on 2026-08-25, rather than what the architecture intends.

Reproduce any time with `scripts/linux_verify.sh` (renderer),
`scripts/linux_selector_verify.sh` (the app-facing selector API) and
`scripts/linux_realapp_verify.sh` (a REAL app's screen — M14). All need
Docker.

## M14: a real app's source compiles and renders identically on Linux

The strongest portability statement to date, because the source under test is
not ours. `scripts/linux_realapp_verify.sh` builds the library, `openrender`,
`openhost` **and `Sources/RealAppProbe`** — four UNMODIFIED source files from
Automattic/pocket-casts-ios (docs/REAL_APP_TEST.md) — inside the same stock
container, then renders and replays them:

| check | result |
|---|---|
| `swift build -c release` with the vendored app source | **clean** — the app's own code compiles off Darwin |
| `openrender realapp` (3 headless configurations) | **3/3 byte-identical** to the macOS render |
| `openhost --app pocketcasts --script …` (10 recorded frames, SDL dummy driver) | **10/10 byte-identical** |

Run 2026-08-25: `REAL-APP SCREEN VERIFIED ON LINUX`, 13/13. The live replay
matters as much as the headless one: it drives real touches through the app's
`touchesBegan`, its `UISwitch` target-action and its tap-to-dismiss, so
identical bytes mean identical *behaviour*, not just identical drawing.

## Result

Built inside a stock `swift:6.2-noble` container (`aarch64-unknown-linux-gnu`,
Swift 6.2.4) — no Apple frameworks present at all:

| check | result |
|---|---|
| `swift build -c release --product openrender` | **clean** (library + quartz + CLI) |
| All 162 fixture frames rendered on Linux | **108/108 scenes pass** vs the real-UIKit goldens |
| Linux frames vs the macOS frames, SHA-256 | **162/162 byte-identical** |

**Re-verified 2026-08-25 at the M13 wrap-up commit on `master`**
(`scripts/linux_verify.sh`), i.e. at the M14 tip with all four M13
app-compat clusters *and* M14 merged: Swift 6.2.4,
`aarch64-unknown-linux-gnu`, **24.73 s** clean build, 162 frames rendered,
**108/108 scenes pass**, **162/162 byte-identical** to the macOS render,
`PORTABILITY VERIFIED`. This is the run that clears the wrap-up gate — no
cluster broke portability and nothing had to be fixed to make it pass.

The M14 additions carried one specific risk worth naming, because it is the
kind that would show up here and nowhere else: **Dynamic Type is driven by a
vendored JSON table** (`Resources/dynamic_type.json`, the verbatim
`Tools/oracle2/dyntypeprobe` dump) rather than by querying a host text system,
so `UIFontMetrics` and `UIFont.preferredFont(forTextStyle:)` resolve to the
same numbers off Darwin as on it. Byte-identical output across all 162 frames
is the proof that no host lookup crept in.

Earlier runs: M13 merge (108/108, 162/162, 23.6 s), M12 (96/96, 150/150),
M11 (81/81, 135/135), M10 (80/80, 134/135).

The M13 clusters were each verified on their own branch too, but the merge is
the run that matters: `UICollectionView`, the bar-item platters, the menu
machinery and `NotificationCenter`/`Timer` had never been compiled together
off Darwin before this. The portability risks they each carried —
`NotificationCenter` and `Timer` SHADOW Foundation types (the library still
imports no Foundation, so they are declarations, not re-exports), and the
menu/bar clusters lean on the M12 selector dispatch that already had a Linux
path — all held.

### How each M12 cluster kept the property

| cluster | the portability risk | what was done |
|---|---|---|
| Attributed text | `NSAttributedString`/`NSParagraphStyle` are Foundation types | Declared in OpenUIKit instead — see below. Underline/strikethrough rects are a vendored measured table (`text_decorations.json`), so the decoration path needs no text engine. |
| Image codecs | PNG/JPEG decoding is a system service on Darwin | Routed to the `stb_image` copy already inside the vendored CQuartz, via an additive C API (`patches/quartz/005-image-io-memory.patch`). No decoding code in OpenUIKit, no platform image framework, and `UIImage(named:)` resolves against `OpenUIKitRuntime.imageSearchPaths` — empty by default, so the library hardcodes no host paths. |
| App lifecycle | `UIApplication`/`UIDevice`/`UIScreen` are inherently host-facing | No run loop and no wall clock enter the core: `UIApplicationMain` returns and the host drives five `_host…` methods. `UIScreen` is fed by the host's real surface; `UIDevice`'s values are *declared constants*, and its header says so, precisely because the process may be on Linux. |
| Alerts | measured metrics could have been read from a live UIKit | They are vendored constants from a Simulator probe, not a runtime query. `UIScreenMetrics`' safe-area insets are likewise hardcoded measurements (a real gap — docs/KNOWN_GAPS.md — but a portable one). |
| Two-cut font fix | a second font *file* would have been a host dependency | `OpenUIKitRuntime.systemFontCut` subtracts a measured per-size constant from the existing vendored table. Pure data; no `.SFUI` file is loaded or needed for metrics. |

Byte-identical output across two operating systems and two C++ standard
libraries is the strongest form of the claim: the renderer is deterministic
and carries no host dependency.

## Selector target-action, verified on Linux (M12)

`scripts/linux_selector_verify.sh` proves the app-facing API of
docs/OBJC_RUNTIME.md is portable, not just the renderer. Inside the same
`swift:6.2-noble` container (plus `libsdl2-dev`):

| check | result |
|---|---|
| library + `openrender` + **`openhost`** build | **clean** |
| selector dispatch tests (the portable 23 of the 27) | **23/23 pass** |
| `openhost --app selectors --script …` replayed headlessly | **10 frames** |
| those frames vs the macOS frames, SHA-256 | **10/10 byte-identical** |

The replayed screen (`Sources/DemoApp/SelectorApp.swift`) is wired *entirely*
with `addTarget(_:action:for:)` and `UITapGestureRecognizer(target:action:)`
— no closures — and it renders a live counter, so a selector that failed to
fire would change the pixels. Byte-identical frames therefore prove the
actions dispatched identically on both operating systems.

This also closes the "`openhost` was not built on Linux" gap below. Building it
there took two fixes, both real portability bugs that only a Linux host run
could expose:

1. **`SDLHost` demanded an accelerated renderer**, which the headless dummy
   video driver cannot provide, so `openhost` died in `SDL_CreateRenderer`.
   It now falls back to a software renderer. Captured frames come from the
   `Bitmap`, not from SDL, so the fallback cannot change output.
2. **`openhost` never read `OPENUIKIT_FONT_DIR`** — only `openrender` did.
   That went unnoticed while `openhost` was a macOS-only tool with the system
   SF available. On Linux the first run dropped every glyph outside the
   harvested ink table: "Target-Action" rendered as "Target tion",
   "Increment" as "n re ent", and the counter digits vanished entirely. The
   same env-var block openrender has now lives in `openhost` too.

The second one is worth dwelling on: it is the "fonts are the one host
dependency" gap below, in a new place, and it was invisible until something
other than `openrender` ran off Darwin.

### Two Linux XCTest quirks found on the way — neither is ours

Both matter to anyone wiring `swift test` into Linux CI, and both were
confirmed against **untouched** suites, so neither is a property of the
selector work:

1. **`swift test` hangs outright** in this container. Its harness blocks in
   `poll()` with no TTY while the XCTest child sits idle — indefinitely
   (killed after 27 minutes; the same tests run in 5 ms when invoked
   directly). The script therefore does `swift build --build-tests` and runs
   the `OpenUIKitPackageTests.xctest` bundle itself.
2. **The bundle hangs mid-run roughly one launch in five**, at a different
   test each time, sleeping in `poll()` with a second thread in
   `epoll_wait`. Measured over 10 launches each: `UIControlTests` 3/10 hung,
   `GeometryTests`+`ColorTests` — *purely computational, no window, no
   touches, no selectors* — 2/10 hung. So it is the Swift 6.2.4 Linux XCTest
   runtime in this image, not the library. The script runs the bundle under
   `timeout` and retries, and requires a real
   "Executed N tests, with 0 failures" line before passing.

Neither reproduces on macOS, where the full 427-test suite runs green every
time.

## What made it work

- The library targets (`OpenUIKit`, `OpenCoreGraphics`) import **no**
  Foundation and no Apple framework — a rule enforced since day one. The
  audit finds zero violations and zero `#if os(...)` conditionals. There is
  now exactly **one** `#if canImport(ObjectiveC)`, in `UISelector.swift`: on
  Darwin `Selector` is the platform's real ObjC selector, elsewhere it is
  OpenUIKit's own name-carrying struct. That conditional is the seam the
  whole selector feature rests on, and nothing above it is conditional.
- `CQuartz` (the vendored Quartz 2D + CoreAnimation implementation) is
  portable C++17 and compiled unmodified on Linux.
- Text **metrics** come from a vendored data table (`font_metrics.json` —
  the macOS `.SFNS` cut of San Francisco; `OpenUIKitRuntime.systemFontCut`
  switches to the measured iOS `.SFUI` advances, see docs/KNOWN_GAPS.md),
  text **ink** from harvested masks (`glyph_ink.json`) and
  underline/strikethrough **rects** from a measured table
  (`text_decorations.json`, M12) — all data, so layout and most glyph
  rendering need no font files and no system text engine.
- Attributed text (M12) keeps the rule: `NSAttributedString` and
  `NSParagraphStyle` are OpenUIKit's own types, not Foundation's, precisely
  so the attributed path stays Foundation-free off Darwin. The cost is name
  shadowing for apps that import both — docs/KNOWN_GAPS.md.
- The controls2 cluster (2026-08-25) extended the same tradeoff to three more
  families, and for the same reason: **`NotificationCenter` / `Notification`
  / `Notification.Name` / `OperationQueue`** and **`Timer` / `RunLoop`** are
  declared in OpenUIKit. Two portability consequences beyond the shadowing:
  the notification `queue:` argument is accepted and IGNORED (there is no run
  loop and no threads in the core), and `Timer` fires from
  `UIWindow.tick(timestamp:)` rather than from a wall clock — the same
  host-clock discipline that already drives scroll physics, transitions and
  animation completions, and the reason a timer can never make a golden
  non-reproducible.

## Two fixes this exercise required

1. `Sources/openrender/SceneIO.swift` used `CFGetTypeID`/`CFBooleanGetTypeID`
   (CoreFoundation, Darwin-only) to tell a JSON `true` from a `1` coming back
   from `JSONSerialization`. Replaced by parsing with OpenUIKit's own MiniJSON,
   which distinguishes the two natively — portable *and* less ambiguous.
2. Glyphs **not** covered by the harvested ink table fall back to rasterizing
   from a font file, and the built-in search paths were macOS-only. Off Darwin
   there is no system SF, so those glyphs silently did not draw (`"Library"`
   rendered as `"Li rar"` — the 34pt bold `b` and `y` were missing while
   everything else was pixel-perfect). Added `OPENUIKIT_FONT_DIR=<dir>`, which
   registers `SFNS.ttf` / `SFNSMono.ttf` / `SFNSItalic.ttf` from a directory
   the user supplies. Apple's fonts are not redistributable, so shipping them
   is not an option; pointing at a copy is.

## Honest gaps

- **Fonts are the one host dependency.** Glyphs outside the harvested ink
  table fall back to rasterizing from a font file, and off Darwin there is no
  system SF. At M10 a Linux run without `OPENUIKIT_FONT_DIR` rendered
  122/134 frames byte-identically and **still passed 80/80** while dropping
  letters — that is the blind spot the structural gates were built for.

  Re-measured at the M12 tip (2026-08-25) with both structural checks active:
  the same no-font run now **fails 22 of 96 scenes**. Every failure is on the
  structural gates alone — **zero** layout issues anywhere, and every
  percentage score is 97.4–99.9, i.e. all 22 are still above their category
  thresholds and would all have passed on the percentage:

  | caught by | scenes | worst / best score |
  |---|---|---|
  | content absence **and** the blob cap | 11 — `navbar_large` (blob 260.8 pt², the missing 34 pt `b` of "Library"), `navbar_dark` (258.2), `constraints_baseline` (137.2), `attrtext_runs` (136.2), `modal_sheet` / `modal_sheet_grabber` (108.0), `tabbar_basic` / `tabbar_tinted` (94.5 / 90.8), `alert_basic` / `alert_destructive` / `alert_actionsheet` (83.2) | 97.48 / 99.42 |
  | **content absence only** (blob under the 80 pt² cap) | 11 — `attrtext_fields` (59.8), `tableview_dark` (54.2), `navbar_inline` (50.2), `alert_dark` (48.5), `control_segmented` (39.0), `attrtext_underline_strike` (34.0), `control_dark` (33.8), `tableview_grouped` (29.8), `attrtext_paragraph` (22.5), `constraints_compression` (21.8), `attrtext_dark` (12.8) | 97.42 / **99.89** |

  The second row is the whole argument for having two checks. Those scenes are
  missing **body text** rather than display-size glyphs; their stems are ~2
  device pixels wide, so they never form a blob large enough to trip the size
  cap. `attrtext_dark` is the extreme case: a 4.0 × 8.5 pt hole where the
  golden has ink, on a frame scoring **99.892 %** — invisible to both the
  percentage and the blob cap, caught by absence alone. The check added in M12
  therefore doubled the catch rate on this exact failure mode (11 → 22),
  and every scene it caught it caught correctly.

  Fixes for the underlying dependency, in order of preference: extend the
  harvest (pure data, keeps the zero-dependency property), ship a
  metrically-compatible libre font, or supply SF. Reproduce the no-font run by
  dropping `OPENUIKIT_FONT_DIR` from `linux_verify.sh`'s inner script.
- ~~**The thresholds have a blind spot this exposed.**~~ **FIXED 2026-08-25.**
  `navbar_large` passed at its category threshold while visibly missing two
  letters, because the affected pixels were a small fraction of a large
  canvas. compare.py now runs a **structural gate** alongside the percentage:
  connected components of the severe-diff mask (delta > 150 counts), failing
  any frame with a contiguous wrong region over 80 pt². The exact corruption
  that slipped through measures 248.8 pt² and now fails, while all 96 scenes
  still pass. M12 added the **content-absence** check beside it, after the
  same class of failure proved able to hide body text under the size cap (see
  the font gap above). Design, calibration table and the one case neither
  check can see: docs/SCENE_SPEC.md "Structural diff gate".

  Note for whoever tunes this next: the 80 pt² cap was calibrated on a "worst
  legitimate component 33.2 pt²" that turned out to be the two-cuts-of-SF bug,
  not a rasterization limit. With that fixed the worst legitimate component
  over all 96 passing scenes is **20.0 pt²** (`stack_alignment`,
  `anim_concurrent`), so the cap could be tightened considerably — the calibration
  comment in compare.py is stale (docs/KNOWN_GAPS.md).
- ~~**`openhost` was not built on Linux**~~ **FIXED 2026-08-25.**
  `scripts/linux_selector_verify.sh` installs `libsdl2-dev`, builds `openhost`
  on Linux and runs a scripted capture headlessly under
  `SDL_VIDEODRIVER=dummy`; the frames match macOS byte for byte. Only the
  `--app selectors` script is replayed there so far — extending it to the
  other apps and to `--nav-demo` is mechanical.
- x86-64 Linux is untested (this ran on arm64). No reason to expect trouble;
  no evidence either.
