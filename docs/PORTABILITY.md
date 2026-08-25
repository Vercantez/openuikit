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
| All 134 fixture frames rendered on Linux | **80/80 scenes pass** vs the real-UIKit goldens |
| Linux frames vs the macOS frames, SHA-256 | **134/134 byte-identical** |

Byte-identical output across two operating systems and two C++ standard
libraries is the strongest form of the claim: the renderer is deterministic
and carries no host dependency.

## What made it work

- The library targets (`OpenUIKit`, `OpenCoreGraphics`) import **no**
  Foundation and no Apple framework — a rule enforced since day one. The
  audit finds zero violations and zero `#if os(...)` conditionals.
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

- **Fonts are the one host dependency.** Without `OPENUIKIT_FONT_DIR`, a Linux
  run still passes 80/80 and renders 122/134 frames byte-identically, but
  glyph combos outside the harvested table are missing. Fixes, in order of
  preference: extend the harvest (pure data, keeps the zero-dependency
  property), ship a metrically-compatible libre font, or supply SF.
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
