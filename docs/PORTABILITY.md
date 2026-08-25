# Portability — verified, not asserted

OpenUIKit claims to be a *portable* UIKit. This document records what was
actually tested, on 2026-08-25, rather than what the architecture intends.

Reproduce any time with `scripts/linux_verify.sh` (needs Docker).

## Result

Built inside a stock `swift:6.2-noble` container (`aarch64-unknown-linux-gnu`,
Swift 6.2.4) — no Apple frameworks present at all:

| check | result |
|---|---|
| `swift build -c release --product openrender` | **clean** (library + quartz + CLI) |
| All 135 fixture frames rendered on Linux | **81/81 scenes pass** vs the real-UIKit goldens |
| Linux frames vs the macOS frames, SHA-256 | **135/135 byte-identical** |

Re-verified 2026-08-25 after M11 with the new structural diff gate active
(below) and the `modal_sheet_grabber` fixture added.

Byte-identical output across two operating systems and two C++ standard
libraries is the strongest form of the claim: the renderer is deterministic
and carries no host dependency.

## What made it work

- The library targets (`OpenUIKit`, `OpenCoreGraphics`) import **no**
  Foundation and no Apple framework — a rule enforced since day one. The
  audit finds zero violations and zero `#if os(...)` conditionals.
- `CQuartz` (the vendored Quartz 2D + CoreAnimation implementation) is
  portable C++17 and compiled unmodified on Linux.
- Text **metrics** come from a vendored data table (`font_metrics.json`),
  text **ink** from harvested masks (`glyph_ink.json`) and
  underline/strikethrough **rects** from a measured table
  (`text_decorations.json`, M12) — all data, so layout and most glyph
  rendering need no font files and no system text engine.
- Attributed text (M12) keeps the rule: `NSAttributedString` and
  `NSParagraphStyle` are OpenUIKit's own types, not Foundation's, precisely
  so the attributed path stays Foundation-free off Darwin. The cost is name
  shadowing for apps that import both — docs/KNOWN_GAPS.md.

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
  Re-measured 2026-08-25 with the gate active: the same no-font run now
  **fails 7 of 81 scenes**, every one of them on the structural gate alone
  (zero layout issues, percentage scores 97.5–99.4, i.e. all still above
  their category thresholds):

  | scene | score | largest wrong region |
  |---|---|---|
  | `navbar_large` | 99.35 | 260.8 pt² — the missing 34 pt `b` of "Library" |
  | `navbar_dark` | 98.23 | 258.2 pt² |
  | `constraints_baseline` | 97.48 | 137.2 pt² |
  | `modal_sheet` / `modal_sheet_grabber` | 99.40 / 99.39 | 108.0 pt² |
  | `tabbar_basic` / `tabbar_tinted` | 99.22 / 98.80 | 94.5 / 90.8 pt² |

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
- **`openhost` was not built on Linux** — it needs `libsdl2-dev` in the
  image. The SDL2 target is standard and expected to work; it is simply not
  yet proven. Extend `linux_verify.sh` to install SDL2 and build it.
- x86-64 Linux is untested (this ran on arm64). No reason to expect trouble;
  no evidence either.
