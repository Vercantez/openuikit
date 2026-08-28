# Asset catalogs — a source-form `.xcassets` reader, proved against `actool`

Rung 2 of the union punch list. Asset catalogs appear in **20 of 20** ladder
apps (1–42 catalogs each), they are self-contained, and — unlike most of the
UIKit surface — they can be proved without a pixel oracle.

    ./census_xcassets.py <corpus> census.json      # measure first
    ./xcassets_tool.py index <app-or-.xcassets> --out <dir>
    ./xcassets_tool.py resolve <index.json> <name> --scale 2 --appearance dark
    ./reconcile.py census.json <index-dir> <corpus>    # accounting gate
    ./roundtrip.py <index-dir> <corpus>                # byte gate
    ./spot_oracle.py <corpus> <fresh-work-dir>         # differential vs actool
    ./teeth.sh <corpus> <fresh-work-dir>               # prove the gates can fail
    ./build_fixture.py <corpus> <index-dir> <fixture>  # the resolution oracle (#82)
    ./run_resolution_oracle.sh <fixture> <fresh-out>   #   real UIImage(named:)
    ./score_resolution.py <fixture> <out>
    ./teeth_resolution.sh <fixture> <out> <fresh-work>

`INDEX_FORMAT.md` is the handover document for the OpenUIKit side.
`EXPECTED.md` is the pre-registration, committed in `24e624a` before
`spot_oracle.py` existed.

---

## Scope, stated before any number

**Input is SOURCE FORM only** — directories, `Contents.json`, and the png / pdf
/ jpg / svg payloads beside them. The compiled `.car` is proprietary and
**out of scope as an input**, deliberately: this project recompiles apps from
source, so source form is the input we actually have. `actool` and `assetutil`
appear here only as the **oracle**, never as a dependency of the tool.

**Covered types**: `.imageset`, `.colorset`, `.appiconset`, `.dataset`,
`.symbolset`, namespace folders, catalog roots. Everything else —
`.sticker`, `.imagestack`, `.brandassets`, `.complicationset`, `.launchimage`,
… — is **recorded, not resolved**: it is in the index with its type and its
payload bytes, and a lookup that lands on one **refuses, naming the type**.
15 such roots, 97 nested inside them.

**`.symbolset` is record-not-resolve too**, and the measurement is the reason:
27 symbolsets in 9 of 20 apps, all `.svg`, all needing a symbol engine this
project does not have. The bytes are kept; the resolution is not claimed.

---

## Measurement first — the `~171` move

`xcassets-census-2026-08-27.json`: every `Contents.json` key in the 20 pinned
apps. **176 catalogs, 8,216 `Contents.json`, 0 unparsable.** The reader's key
tables are that census transcribed, each key carrying its (uses / apps-of-20),
and **an unknown key or an unknown value refuses, naming the file**.

Six things the census established that no amount of reading the docs would
have:

| | |
|---|---|
| **4,758 image entries carry a filename and NO `scale`** | 43% of all image entries — the single largest shape. A reader that required `scale` would drop nearly half the corpus |
| **1,828 entries declare a slot and provide no file** | Xcode leaves these behind. Not missing files, not an error: skipped and **counted** |
| **colour components come in four encodings** | decimal `"0.5"` (449 triples / 11 apps), hex `"0xB4"` (366 / 9), integer `"189"` (~32 / 4), and nine values ambiguous in isolation |
| **`resizing` appears with two spellings** | `cap-insets` and `capInsets`, in the same corpus. A reader keyed on one drops the other in silence |
| **`appearance` values are `dark` / `light` / `tinted`** | 793 / 11 / 58. An entry with no `appearances` is `any`, and **`any` is not `light`** |
| **colour spaces are four, not one** | srgb 797, display-p3 39, extended-srgb 14, gray-gamma-22 2 |

### The nine ambiguous colour components, and how they were settled

`{"red":"1","green":"123","blue":"199","alpha":"1.000"}` — NetNewsWire's
account-icon colours. `"1"` could be 1.0 or 1/255, and **`alpha` in the same
dictionary is a float while the RGB triple is integers**, which rules out any
per-dictionary rule. The reader's rule is per value: `.` → float 0..1, `0x` →
hex/255, otherwise integer/255.

Apple's compiler agrees. That exact shape resolves to
`[0.00392156…, 0.48235…, 0.78039…]` = `1/255, 123/255, 199/255`.

---

## Proof 1 — the accounting gate (`reconcile.py`)

An identity against an **independent** walk of the corpus. `>=` is not good
enough and "close" is not a result.

```
catalogs: on disk 176   walked 176   with root Contents.json 170   without 6

ASSET DIRECTORIES
  on disk (independent count)      7536
    indexed under a unique name    6800
    lost to a name collision        624
    unresolved roots                 15
    nested inside an unresolved      97
  accounted                        7536

FOLDERS
  on disk                           512
    namespace (provides-namespace)  143
    plain                           367
    without a Contents.json           2
  accounted                         512

VERDICT: every asset directory and folder on disk is accounted for.
```

Plus a per-type table, all 16 types tying exactly.

**This gate earned its place twice.** The first full run indexed all twenty
apps with zero refusals — and was **46 assets short**, because the walker
stopped at every non-covered asset directory and 46 covered assets live inside
one. The second was **3 short**: `.imageset` directories nested inside another
`.imageset`, all three in firefox-ios
(`globeLarge.imageset/privateModeLarge.imageset` and two under
`lightningFillLarge.imageset`), which look like an editor accident. Nothing in
the tool's own output could have shown either, because the tool was the thing
that was wrong.

## Proof 2 — the byte gate (`roundtrip.py`), in BOTH directions

```
corpus payload files           10219   (8875 distinct by content)
index payload references       10276
distinct payloads checked       9065
byte-identical to the corpus    9065 of 9065
corpus payloads referenced      8875 of 8875
VERDICT: every payload byte round-trips.
```

The flat directory is content-addressed, so "the name is the hash of the
contents" is checkable by anyone. That is deliberately **not** the whole check —
it is circular, since the tool chose both the name and the bytes. Each payload
is also matched against a file re-walked from the corpus itself.

**The second direction is what found the bug.** The first version checked only
"everything the index references exists" and passed, while **167 files sat in
the flat directory referenced by nothing**: the variants of 624 collided assets,
dropped on the floor, plus loose files in folders that were never recorded at
all (vlc-ios ships a `Contents 2.json` in a folder, presumably a merge
leftover). Both are fixed; collided assets now keep their full record.

## Proof 3 — the differential (`spot_oracle.py`) against `actool`

    actool --compile … --platform iphoneos --target-device iphone --target-device ipad
    assetutil --info Assets.car

`assetutil` reports every rendition's `Name`, `Scale`, `Idiom`, `Appearance`
and **`RenditionName` — the source file basename** — and, for colours, the
resolved `Color components`. Both sides reduce to sets of tuples.

**This is a stronger provenance than the JSON oracle had.** There, macOS's
`JSONDecoder` turned out to be the same swift-foundation source the port
compiles, which made that comparison a build differential. `actool` is
closed-source, written by the vendor of the format, and shares nothing with
this reader.

```
catalogs found                   176
compiled by actool and scored    158
actool compiled to nothing        18   (no renditions for this platform)
actool or the reader FAILED        0

IMAGE variants
  agree with actool              3868 of 8900
    of which scaleless            198
  vector expanded by actool      5032   (a compiler property, not a divergence)
  scale differs                     0   (must be 0)
  only in the tool                  0   (must be 0)
  only in actool                    0   (must be 0)
DATASETS  (no RenditionName from actool; compared on byte length)
  agree with actool                 2 of 2
COLOUR variants
  agree with actool               852 of 852
  components differ                 0   (must be 0)
  colour space differs              0   (must be 0)
  only in the tool                  0   (must be 0)
  only in actool                    0   (must be 0)
EXCLUDED by pre-registration (EXPECTED.md), not scored
  appiconset_variants              805
  colorset_system_reference         13
  non_ios_idiom                    201
  symbolset_variants                23

VERDICT: the reader and actool agree on every compared tuple.
```

**852 of 852 colours is the cleanest line here**: every colorset in twenty
shipping apps, across all four component encodings and all four colour spaces,
resolving to the same numbers Apple's compiler produces.

### The scoreboard went 208 → 14 → 0, and every step was the COMPARATOR

This has to be said plainly, because a scoreboard that improves three times is
exactly the shape of a test being bent until it passes. **The reader's parsing
and resolution code was not changed to make any of these go away.** The four
edits it did receive were: accept a `.xcassets` path directly (the oracle
pointed at one and got a silent empty index), refuse an empty index, and record
two extra fields the comparison needs (`filename`, `native`). None of them
changed how a variant is read or chosen.

| run | divergences | cause |
|---|---|---|
| 1 | 99 + 109 images | **`assetutil` spells idioms `phone`/`pad`; the source says `iphone`/`ipad`.** Same idiom, two vocabularies — the same rows counted as a divergence on both sides at once |
| 1 | (same rows) | **`assetutil` truncates `RenditionName` at exactly 127 characters.** Telegram generates 130-character filenames; the dump cuts them mid-hash, extension and all. Both sides are now clipped to 127 |
| 2 | 12 images | **`car` was in my non-iOS idiom exclusion list and does not belong there.** CarPlay is an iOS feature: `actool` emits `car` renditions for `iphoneos`, so excluding them on one side invented 12 phantom rows from pocket-casts' `Carplay.xcassets`. This is #72's lesson exactly — a pre-registered exclusion is a number like any other and has to be re-derived |
| 2 | 2 images | **datasets carry no `RenditionName`.** `actool` keeps a dataset's bytes and drops its source filename, so the corpus's only two datasets could never match by filename. They are now compared on `Data Length` — and both agree |

An earlier version also reported all 18 empty catalogs as "refused" with a
message that was a file path. `actool` exiting 0 and emitting no `Assets.car`
is a catalog with nothing to build for this platform, not a failure, and the
two are now separate lines.

### Findings about `actool` itself, kept because they are the reason the numbers look the way they do

* **`actool` GENERATES, the source DECLARES.** One PDF entry comes back as
  renditions at 1x, 2x, 3x and a scaleless vector one — 5,032 of 8,900 image
  variants are in this class. A reader of source form cannot and should not
  reproduce it, so it is counted separately and never folded into "agree",
  which would have been the easy way to make the scoreboard green.
* **`actool` resolves system-colour references and we cannot.** 13 colour
  variants name `systemBackgroundColor`, `labelColor` and friends; the palette
  is not in the catalog. Excluded on **both** sides and reported.
* **Three colorsets are MIXED** — a real gray-gamma-22 dark variant beside an
  `any` variant that is a system reference. The exclusion had to become
  per-variant, not per-asset.
* **`actool` stores `display-p3` components unconverted**, under
  `Colorspace: "p3"`. So the index's `native` field is what Apple agrees with,
  and its `srgb` field is this tool's own conversion — a convenience the oracle
  **cannot** corroborate, labelled as such in `INDEX_FORMAT.md`.

### What proof 3 does NOT establish — closed by proof 5

`assetutil` dumps a catalog; it does not perform a lookup. So proof 3 measures
the **variant table** and says nothing about **steps 1–4 of the resolution
algorithm**. That gap was named rather than filed as done, and #82 closed it —
see below.

## Proof 5 — the resolution algorithm, against `UIImage(named:)` (#82)

    ./build_fixture.py <corpus> <index-dir> <fixture>
    ./run_resolution_oracle.sh <fixture> <fresh-out>
    ./score_resolution.py <fixture> <out>
    ./teeth_resolution.sh <fixture> <out> <fresh-work>

Pre-registration: `EXPECTED_RESOLUTION.md`, committed in `1f70b91` before the
probe or the scorer existed.

**The vehicle is the simulator, and that is a measured conclusion.** Mac
Catalyst is this project's established oracle vehicle and **cannot express the
scale axis**; neither can a `simctl spawn`ed process. Five routes, all pinned
to 2.0 — `UIImage(named:in:compatibleWith:)`, `imageAsset.image(with:)`,
`traits.performAsCurrent`, and spawns on a 2x and a 3x device. `displayScale`
in a `UITraitCollection` does not drive catalog scale selection: UIKit takes it
from the **screen**, and neither vehicle has one. So the probe is a real `.app`
installed and launched in three simulators.

```
devices        scale 2 idiom ipad · scale 2 idiom iphone · scale 3 idiom iphone
               1x is unreachable: no 1x simulator device exists

INSTRUMENT CHECKS, before any scoreboard
   closest same-size candidate pair    49.500   (must exceed 10.0)
   assets ruled undecidable                 0
   image rows identified                  234 of 234
     of which byte-exact                    91   (the rest actool re-encoded)

IMAGES    agree with UIKit    234 of 234    chose differently 0 · index found none 0
COLOURS   agree with UIKit     90 of 90     differ 0
          display-p3 24 · extended-srgb 18 · gray-gamma-22 6 · srgb 42
          system references     6   (excluded: the palette is not in the catalog)
COLLISION rows recorded         6   (no prediction registered)
EXCLUDED  ask .unspecified     36   (not a state an app can be in)

VERDICT: the index chooses what UIKit chooses on every decidable row.
```

### The pre-registered prediction FAILED, and that is what the run bought

`EXPECTED_RESOLUTION.md` P2 named step 4 as the likeliest divergence: *"smallest
scale above, then largest below"* was a choice made from reasoning —
downscaling beats upscaling — that no oracle had ever checked.

**UIKit disagrees.** An asset carrying only 1x and 3x, asked at 2x on both an
iPhone and an iPad, returns the **1x** payload; the index returned 3x. Four
rows, one rule. `resolve()` and `INDEX_FORMAT.md` step 4 are corrected to
*largest below, then smallest above*, with the scope of the evidence stated:
the only observable fall-**up** case is `{1x,3x}` at 2x, so "smallest above"
is now a last resort that remains unobserved.

**The scoreboard above is from re-scoring the same probe data after the fix —
no re-measurement.** The probe does not know the algorithm and does not compare
anything, so the specification can be corrected without touching the evidence.

### Identification had to be measured, not assumed

Exact hashing identified only 33 of 92 rows: `actool` re-encodes payloads, so
UIKit's returned image is not byte-identical to the source file for most real
assets. Measured over 276 rows and 69 same-size candidate pairs, in mean
absolute difference per byte:

| | |
|---|---|
| UIKit vs the nearest candidate | max **0.2817**, median 0.0075 |
| any two same-size candidates | min **49.5**, median 117.6 |

A **176× margin**. Thresholds are set from that data (`IDENTIFY_MAX 2.0`,
`MARGIN_MIN 10.0`) rather than chosen, and both instrument checks run and are
printed *before* the scoreboard, per #78's `renderDiscriminates`: candidates of
one asset must be far apart, and every scored row's returned image must match
some candidate. 0 undecidable, 0 unidentified.

### Three findings the run produced beyond its own scoreboard

* **The `srgb` field IS corroborable, and #79 said it was not.** `UIColor`'s
  `getRed:green:blue:alpha:` converts out of Display P3 (while
  `cgColor.colorSpace` still reports DisplayP3) and agrees with this index's
  P3→sRGB matrix to **~3e-5** on every P3 colour in the corpus. That is a
  correction to this oracle's own pre-registration (P4).
* **`gray-gamma-22` is the exception.** UIKit does not gamma-convert: for
  `white = 0.9` it reports `0.9, 0.9, 0.9`, while the index's conversion gives
  `0.902873`. Neither is wrong — one is colour-managed conversion, the other is
  component reporting — but a consumer matching UIKit must use `native`.
* **The name collision is decided at BUILD time.** Two catalogs defining one
  name, compiled together: `actool` emits a single rendition, from the catalog
  listed **first**, and `UIImage(named:)` returns it. The index records both
  and picks neither; `INDEX_FORMAT.md` now tells the consumer to apply catalog
  order and take the first.

And one exclusion worth naming: asked with `userInterfaceIdiom = .unspecified`,
UIKit substitutes the **device's** idiom rather than falling back to
`universal`. 36 rows. A real app's traits always carry phone/pad/mac, so this
is not a state to plan for — excluded, counted, and recorded rather than scored
as 24 divergences that were one artefact of the question.

### Teeth (`teeth_resolution.sh`), 4 of 4

```
TOOTH 1  a planted wrong PAYLOAD, end to end through the device   PASS  named SynLightDark
TOOTH 2  an index-side light/dark swap, no device run needed      PASS  25 rows differ
TOOTH 3  no result files                                          PASS  exit 2, refused
TOOTH 3b zero decidable rows                                      PASS  exit 2, refused
```

Tooth 1 was **vacuous first** and said so: it planted into ProtonMail's
`AppIcon-calculator-preview`, an asset the oracle already excludes as
unidentified, so the scoreboard stayed 234 of 234 and the tooth reported FAIL
while the oracle was fine. It now targets a row that is definitely scored and
asserts that the oracle names **that** asset, not merely that something failed.

## Proof 4 — the teeth (`teeth.sh`)

Every gate above passed on its first corpus run, which is exactly when a gate
is least trustworthy. Each tooth plants a defect and requires the matching gate
to catch it **by name**:

```
TOOTH 1  a corrupted Contents.json      PASS  exit 2, refused and named appTintColor.colorset
TOOTH 2  an unknown key                 PASS  exit 2, refused on 'wibble' by name
TOOTH 3  an unknown value               PASS  exit 2, refused on 'toaster' by name
TOOTH 4  an entry naming a missing file  PASS  exit 2, refused naming the payload
TOOTH 5  a PLANTED WRONG VARIANT        PASS  the oracle FAILED (exit 1) and named the swapped rows
teeth passed 5, failed 0
```

Tooth 5 is the load-bearing one: swapping the light and dark filenames inside
one imageset leaves the document parsing, every file present, the accounting
identity holding and the round trip byte-perfect. **Only the oracle can see it.**

The teeth harness was itself wrong first: it copied the catalog to a directory
without the `.xcassets` suffix, so four teeth "passed the refusal check" because
the reader could not find a catalog at all. A tooth that fires on the harness
instead of on the planted defect is worse than no tooth.

---

## Pins

| | |
|---|---|
| corpus | `scratch/ladder-corpus`, 20 apps at the SHAs in `../ladder/corpus-pins-2026-08-27.tsv`; **verified at all 20 pins, 0 drift**, before and after |
| census | `xcassets-census-2026-08-27.json` — 176 catalogs, 8,216 `Contents.json` |
| oracle | Xcode **26.1 (17B55)**, `/usr/bin/actool`, `/usr/bin/assetutil`, `--platform iphoneos --minimum-deployment-target 15.0 --target-device iphone --target-device ipad` |
| pre-registration commit | `24e624a` (census + reader + both gates + `EXPECTED.md`, before `spot_oracle.py` existed) |
| corpus written to | never — every planted defect is applied to a copy in a work directory |

`spot_oracle.py` and `teeth.sh` **refuse a non-empty work directory rather than
clearing it.** The obvious `shutil.rmtree(work)` was written and then removed:
the first path it was pointed at already held a 64 KB executable another agent
had left in the shared scratchpad two days earlier. A tool that clears its own
workspace clears whatever it is pointed at.
