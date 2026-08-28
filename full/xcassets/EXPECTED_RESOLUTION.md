# Pre-registered expectations — the resolution-algorithm oracle (#82)

Committed **before `ResolutionProbe` and `score_resolution.py` exist**, so the
ordering is checkable in `git log`. Same discipline as
`full/oracle-json/EXPECTED.md` and this directory's `EXPECTED.md`.

## The claim

#79 measured the **variant table** against `actool`/`assetutil` and explicitly
did *not* measure the **lookup**. This closes that: for a pre-registered grid of
(asset, idiom, appearance, device-scale), **the variant `xcassets_tool.py
resolve` selects is the variant real UIKit's `UIImage(named:in:compatibleWith:)`
selects.**

---

## The vehicle, and why it is the simulator rather than Mac Catalyst

Mac Catalyst is this project's established oracle vehicle (`~/uikit/Tools/oracle`,
platform 6). **Measured, it cannot express the scale axis**, and neither can a
`simctl spawn`ed command-line process:

| route | idiom | appearance | scale |
|---|---|---|---|
| Catalyst, `UIImage(named:in:compatibleWith:)` | honoured | honoured | **ignored — always 2.0** |
| Catalyst, `imageAsset.image(with:)` | honoured | honoured | **ignored** |
| Catalyst, `traits.performAsCurrent { … }` | honoured | honoured | **ignored** |
| `simctl spawn` on an iPhone SE (2x) | honoured | honoured | **ignored — 2.0** |
| `simctl spawn` on an iPhone 16 Pro (3x) | honoured | honoured | **ignored — 2.0** |

`displayScale` in a `UITraitCollection` does not drive catalog scale selection:
UIKit takes the scale from the **screen**, and a spawned process has no screen.
So the vehicle is a real `.app` installed and launched in the simulator — the
`Tools/oracle2` precedent — run once per device scale.

**1x is unreachable and is recorded as such**: no 1x simulator device exists.
Scale coverage is `{2x, 3x}` and the grid is built so those two discriminate.

## The identification method, and its instrument check

`UIImage` does not name the file it loaded, so the probe **decodes** the
returned image and every candidate payload through **one pipeline** — CGImage
into an sRGB premultiplied-last bitmap at the image's own pixel size, SHA-256 of
the bytes — and reports which candidate the returned image matched.

Measured on a synthetic probe catalog before this file was written: UIKit's
returned bytes are **exactly equal** to the source file's decoded bytes
(`s2d.png` → `577c18e7087501cb` on both sides). `actool`'s recompression is
lossless, so identification is exact equality and needs no threshold.

**INSTRUMENT CHECK, run and reported BEFORE any scoreboard** — the
`renderDiscriminates` precedent from #78, where a renderer that folded `true`
into `1` made four rows pass while the instrument was wrong:

1. **Within-asset discrimination.** Every candidate of an asset must hash
   differently from every other. Two identical candidates make every comparison
   on that asset pass vacuously. Such rows are **UNDECIDABLE**: excluded,
   counted, and named.
2. **Identification rate.** Every scored row's returned image must match *some*
   candidate. A row matching none means the pipeline failed, not that the
   reader is wrong; recorded separately, never scored as a pass.

## The grid — 50 assets, real and synthetic denominated separately

Built by `build_fixture.py` from the pinned corpus and the #79 index.

| | |
|---|---|
| image assets | **33** (31 real, **2 synthetic**) |
| colour assets | **16**, covering all four colour spaces (`srgb`, `display-p3`, `extended-srgb`, `gray-gamma-22`) and the encodings `float`, `float+hex`, `float+int255` |
| collision | **1** (two catalogs, one shared name) |
| candidate payloads | 92 |
| shapes covered | `scale-all-three` 9, `scale-gap` 8, `scale-1-2-only` 5, `scaleless` 8, `appearance-dark` 9, `idiom-specific` 6 |

**RASTER ONLY, by construction.** `actool` rasterises `.pdf`/`.svg` at every
scale (5,032 of 8,900 image variants in #79), so what UIKit returns for a vector
asset is not the source file and cannot hash-equal it. Vector assets are
excluded when the fixture is built *and* would be caught by check 1 — two
defences, because this is the easy mistake.

### The two synthetic rows, and why the corpus cannot supply them

Measured on the selection, not assumed: the corpus's 11 explicit `light`
entries (3 apps) all sit on assets that raster-only selection excludes, and **no
raster imageset in twenty apps ships `{1x, 3x}` with 2x absent.** Both matter —
`light` is the whole of step 3, and a 1x/3x gap is the only way to watch step 4
fall **up**. They are constructed, labelled `synthetic`, and never counted with
the real rows.

---

## Predictions

### P1 — images: the index's choice equals UIKit's choice, on every decidable row

Zero divergences. A divergence is a defect in the resolution algorithm as
specified in `INDEX_FORMAT.md`, and the fix is that document, not the oracle.

### P2 — the scale rule is the one under test, and it can fail

`INDEX_FORMAT.md` step 4 says: exact, else **smallest scale above**, else
largest below, else scaleless. The "above before below" half is a **choice made
from reasoning** — downscaling beats upscaling — and it has never been checked
against UIKit. `SynScaleGap13` on a 2x device is the row that decides it: the
index says 3x, and if UIKit says 1x then the specification is wrong and gets
corrected. **This is the single most likely divergence in the run.**

### P3 — appearance never substitutes across light/dark

`any` fills in for a missing `light` or `dark`; `light` and `dark` never
substitute for each other. Expected to hold; `SynLightDark` is the row that
would show otherwise.

### P4 — colours compare on NATIVE components, not the sRGB conversion

Per #79: `actool` stores `display-p3` unconverted. `UIColor(named:)` resolves in
its own space, so the probe reports the resolved components **and** the space,
and the comparison is against the index's `native` when the spaces agree. **The
`srgb` field remains unchecked by any oracle** — same statement as #79's README,
repeated because it would be easy to let a green colour scoreboard imply
otherwise.

Tolerance `1e-5` on components, because `UIColor` round-trips through CGColor.

### P5 — the collision: a finding, not a pass/fail

Two catalogs define `Collide`; the index records **both and picks neither**.
Compiled together, `assetutil` shows **one** rendition, `collidea.png` — the
first catalog on the command line. The probe records what UIKit returns.

**No prediction is registered**, because the index deliberately has no answer.
Whatever UIKit does becomes guidance in `INDEX_FORMAT.md` for the consumer that
must choose a bundle order. Scored in its own line, not in P1's denominator.

### P6 — `appearance: tinted` is out of scope

58 entries in 7 apps. It needs an iOS 18 tinted-icon trait the probe does not
set. Excluded, counted, named — not silently absent.

---

## Teeth, to be demonstrated

1. **A planted wrong variant fails.** Swap two payload files' bytes in the
   fixture's `Candidates/` — the index's choice then hashes to the wrong thing
   and the row must fail.
2. **An index-side mis-resolution fails.** Swap `light`/`dark` in the *index*
   only, leaving the catalog untouched, and the affected rows must fail.
3. **The vacuous case refuses.** Zero rows loaded, or zero rows decidable, must
   **refuse** with a non-zero exit — not print a clean scoreboard over an empty
   set.
