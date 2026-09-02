# vendor/quartz — where these files come from

A **pristine** copy of the library half of `~/quartz`, the portable Quartz 2D +
Core Animation reimplementation this repository builds as
`/usr/lib/libquartz.dylib`. Nothing in this directory is modified. Everything a
Mach-O-on-Linux build needs lives in `patches-quartz/` and is applied to a copy
at build time (`scripts/build_quartz.sh`), so "how many patches?" stays a number
you can count instead of a diff you have to read.

**As of the staging below, `patches-quartz/` is empty. Zero patches.**
`docs/QUARTZ_MACHO.md` is the accounting.

## What was copied, and what was not

```
vendor/quartz/
  include/       30 public headers -- the QZ* C API
  src/           37 .cpp + 1 .hpp  -- the rasteriser, stroker, gstate, layer tree
  third_party/    3 stb single-header libraries
  CHECKSUMS.sha256
```

Upstream also carries `harness/`, `demo/`, `tests/`, `scenes/`, `tools/` and
`metrics/`. **None of it is here, on purpose.** Every one of those is macOS-only
by construction: the harness exists to render each scene through Apple's real
`CoreGraphics`/`QuartzCore` *and* through quartz and pixel-diff the two, so it
links `-framework CoreGraphics -framework QuartzCore -framework ImageIO`.
Vendoring it would import an Apple-framework dependency into a tree that has
none, and none of it is part of `libquartz` — upstream's own
`add_library(quartz STATIC …)` target is exactly `include/ + src/ +
third_party/`.

Upstream's own comparison suite therefore stays upstream, which is the right
place for it: it is the measurement that gives quartz its **97.46 / 100 against
Apple's frameworks**, and that number is about quartz, not about machorun.

## Pinning

`~/quartz` **is not a git repository** (checked: no `.git`). There is no commit
to pin, so provenance is pinned the only way it can be — the sha256 of every
file:

| | |
|---|---|
| upstream path | `/Users/miguelsalinas/quartz` |
| staged | 2026-08-26 |
| files | 71 |
| record | `vendor/quartz/CHECKSUMS.sha256` |
| restage | `scripts/vendor_quartz.sh` |
| check | `scripts/vendor_quartz.sh --verify` (committed record is read-only) |
| diff vs upstream | `scripts/vendor_quartz.sh --diff` |

`--verify` treats `CHECKSUMS.sha256` as the thing under test and dies with a
diff. That is deliberate and follows the correction recorded in
`sdk/PROVENANCE.md` §7: a verifier that rewrites the record it verifies cannot
fail.

## Licence

**`include/`, `src/` — the user's own code.** `~/quartz` carries no `LICENSE`
file and no per-file licence headers; it is original work by the owner of this
repository, written from scratch and with no Apple source in it. It is vendored
here with that owner's direction. If this repository is ever published, quartz
needs a licence chosen and stated upstream first — that is an upstream decision
and this file must not invent one.

**`third_party/` — three stb single-header libraries by Sean Barrett**, each
dual-licensed **MIT OR Public Domain (Unlicense)**, with the full text at the
bottom of each file:

| file | version | what it is used for here |
|---|---|---|
| `stb_image_write.h` | v1.16 | `QZContextWritePNG` — the PNG encoder the fixture's output comes out of |
| `stb_image.h` | (bundled) | image decode for `QZImage*` loading paths |
| `stb_truetype.h` | (bundled) | glyph outlines for `QZContextShowTextAtPoint` |

Both stb licence options permit redistribution and modification without
attribution requirements beyond keeping the notice, which is intact.

## Relationship to `vendor/objc4`

Same arrangement, different subject, and the contrast is the point:

| | `vendor/objc4` | `vendor/quartz` |
|---|---|---|
| origin | Apple, written for Mach-O | ours, written portable |
| licence | APSL 2.0 | see above |
| patches to build as Mach-O on Linux | **4** | **0** |
| what the patches say | "this is not a Mac" | — |

`docs/OBJC4_MACHO.md` argues that objc4's four are irreducible. quartz's zero is
the other half of the same argument: source that never assumed a platform does
not need to be told it changed platforms.
