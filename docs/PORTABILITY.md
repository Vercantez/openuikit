# Portability — verified, not asserted

OpenUIKit claims to be a *portable* UIKit. This document records what was
actually tested, on 2026-08-25, rather than what the architecture intends.

Reproduce any time with `scripts/linux_verify.sh` (renderer) and
`scripts/linux_selector_verify.sh` (the app-facing selector API). Both need
Docker.

## Result

Built inside a stock `swift:6.2-noble` container (`aarch64-unknown-linux-gnu`,
Swift 6.2.4) — no Apple frameworks present at all:

| check | result |
|---|---|
| `swift build -c release --product openrender` | **clean** (library + quartz + CLI) |
| All 150 fixture frames rendered on Linux | **81/81 scenes pass** vs the real-UIKit goldens |
| Linux frames vs the macOS frames, SHA-256 | **150/150 byte-identical** |

Re-verified 2026-08-25 after M12 (the frame count is 150, not the 135 this
table used to quote) with the structural diff gate active (below).

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
- Text **metrics** come from a vendored data table (`font_metrics.json`)
  and text **ink** from harvested masks (`glyph_ink.json`) — both are data,
  so layout and most glyph rendering need no font files and no system text
  engine.

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
  letters — that is the blind spot the structural gate was built for.
  Re-measured 2026-08-25 with the structural gates active: the same no-font
  run now **fails 11 of 81 scenes**, every one of them on the structural
  gates alone (zero layout issues, percentage scores 97.4–99.4, i.e. all
  still above their category thresholds):

  | scene | score | caught by |
  |---|---|---|
  | `navbar_large` | 99.35 | blob 260.8 pt² — the missing 34 pt `b` of "Library" |
  | `navbar_dark` | 98.23 | blob 258.2 pt² |
  | `constraints_baseline` | 97.48 | blob 137.2 pt² |
  | `modal_sheet` / `modal_sheet_grabber` | 99.40 / 99.39 | blob 108.0 pt² |
  | `tabbar_basic` / `tabbar_tinted` | 99.22 / 98.80 | blob 94.5 / 90.8 pt² |
  | `tableview_dark` | 97.86 | **content absence** (blob 54.2, under the cap) |
  | `navbar_inline` | 98.74 | **content absence** (blob 50.2) |
  | `tableview_grouped` | 98.11 | **content absence** (blob 29.8) |
  | `constraints_compression` | 97.42 | **content absence** (blob 21.8) |

  The last four are missing **body text** rather than display-size glyphs.
  Their stems are ~2 device pixels wide, so they never form a blob large
  enough to trip the size cap — they are caught only by the content-absence
  check (docs/SCENE_SPEC.md "Why two checks"), which is exactly why that
  second check exists.

  Fixes for the underlying dependency, in order of preference: extend the
  harvest (pure data, keeps the zero-dependency property), ship a
  metrically-compatible libre font, or supply SF.
- ~~**The thresholds have a blind spot this exposed.**~~ **FIXED 2026-08-25.**
  `navbar_large` passed at its category threshold while visibly missing two
  letters, because the affected pixels were a small fraction of a large
  canvas. compare.py now runs a **structural gate** alongside the percentage:
  connected components of the severe-diff mask (delta > 150 counts), failing
  any frame with a contiguous wrong region over 80 pt². The exact corruption
  that slipped through measures 248.8 pt² and now fails, while all 80 scenes
  still pass (worst legitimate component 33.2 pt²). Design, calibration table
  and the one case it still cannot see: docs/SCENE_SPEC.md "Structural diff
  gate".
- ~~**`openhost` was not built on Linux**~~ **FIXED 2026-08-25.**
  `scripts/linux_selector_verify.sh` installs `libsdl2-dev`, builds `openhost`
  on Linux and runs a scripted capture headlessly under
  `SDL_VIDEODRIVER=dummy`; the frames match macOS byte for byte. Only the
  `--app selectors` script is replayed there so far — extending it to the
  other apps and to `--nav-demo` is mechanical.
- x86-64 Linux is untested (this ran on arm64). No reason to expect trouble;
  no evidence either.
