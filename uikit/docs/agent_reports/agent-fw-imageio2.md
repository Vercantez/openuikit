# ImageIO SDK depth, second pass (`agent/fw-imageio2`)

Base: `origin/agent/fw-imageio` (first pass, refused twice). Scope:
`full/imageio/` plus this report. No `uikit/Sources/ImageIO`, no
`uikit/Tests/ImageIOTests`, no `reference/` or `tests/acceptance/` edits,
no pin files. Main's uikit tree is untouched.

## What was refused

1. **Out of scope.** The first pass edited `uikit/Sources/ImageIO/*` and
   `uikit/Tests/ImageIOTests` (the corelibs-route sibling from wave 26).
   Those changes are dropped. If that sibling needs the guest's PNG pHYs /
   JPEG Exif / thumbnail-geometry rules, that is a later merge; this branch
   does not patch it.
2. **Coverage honesty.** `coverage.tsv` marked all **902** identifiers
   `implemented`, with **749** rows on one test
   (`tests/agent/ImageIOTests.swift#testPropertyKeyPayloads`). The merge
   path refuses a bulk relabel. Enum/option-set members may share a
   raw-value table; `kCGImageProperty*` CFString keys may share one payload
   table. CGImageSource / CGImageDestination / CGImageMetadata behaviour
   needs focused tests each.

## Coverage before / after

| | implemented | declared | deferred | nondeferred |
|---|---:|---:|---:|---:|
| main (seed) | 163 | 739 | 0 | 902 |
| first pass (refused) | **902** (749 on one test) | 0 | 0 | 902 |
| this pass | **902** (38 distinct tests) | 0 | 0 | 902 |

Public surface is still 902 precise IDs. The medium-full floor is 451
nondeferred; 902 remains above it.

The 902 implemented rows are kept because every identifier now has a
focused citation:

- `kCGImageProperty*` (652) → `testImagePropertyKeyPayloads` (allowed
  table of Darwin CFString payloads measured 2026-09-05).
- Source / destination / metadata / auxiliary / animation / `kIIO*` /
  misc keys → seven family tables, largest 24.
- Enums → five raw-value tables.
- CGImageSource / Destination / Metadata functions → focused tests named
  below.

### Evidence distribution (top tests by row count)

1. `testImagePropertyKeyPayloads` — **652** (`kCGImageProperty*` only)
2. `testDestinationOptionKeyPayloads` — 24
3. `testMetadataEnums` — 23
4. `testMetadataKeyPayloads` — 23
5. `testEqualityAndHash` — 20

38 distinct cited tests. Non-property, non-enum implemented: 175.
Largest of those is `testDestinationOptionKeyPayloads` at **24 / 175 =
13.7%**. No non-property test exceeds 150 rows or 40%.

First-pass top 1 (the refusal): `testPropertyKeyPayloads` **749**.

## Behaviour this pass actually tests

Cited Apple ImageIO 2026-09-05 (macOS 26.1) measurements from the first
pass, plus byte-level fixtures under `full/imageio/tests/fixtures/`.

1. **Source create (PNG/JPEG data and URL).** Fixture `sample-2x1.png`
   (stored-block RGBA, 77 bytes): `CreateWithData` → type `public.png`,
   count 1, `statusComplete`, image 2×1 with pixels (255,0,0) and
   (0,255,0). `CreateWithURL` of the same file matches. Encoded
   `public.jpeg` re-reads as `public.jpeg` with a 2×1 image.
2. **Type identification.** PNG signature is untyped at 8 bytes and
   `public.png` at 10 (measured). Empty/garbage `CreateWithData` still
   returns a source (`statusInvalidData`, count 0, type nil).
3. **Property dictionaries.** Fixture `probe-png-chunks.png`: pHYs 5669
   ppm → `DPIWidth/Height` **144** (`5669 * 0.0254 = 143.9926`, rounded);
   gAMA 45455 → `Gamma` **0.45455**; tEXt Title=Hello → `{PNG}.Title` and
   `{IPTC}.ObjectName`. Fixture `jfif-exif-orientation6.jpg`: SOF 8×4,
   JFIF density 72, Exif orientation **6**.
4. **Thumbnails.** Fixture `gradient-16x12.png`: max 8 → **8×6**, max 6 →
   **6×4**, max 17 → **16×12** (half-to-even, no upscale). JPEG orientation
   6 + `CreateThumbnailWithTransform` + max 8 → **6×8**.
5. **Incremental status.** Prefix 16 bytes of the PNG fixture:
   incremental `statusIncomplete`; the same prefix via `CreateWithData`
   (final) is `statusComplete` with no image. Full `UpdateData(..., true)`
   completes and yields the image.
6. **Destinations.** PNG write is byte-identical to
   `sample-2x1.png` / `gradient-16x12.png`; the source re-reads those
   bytes. JPEG destination writes baseline SOF0 4:4:4; the source
   re-reads type `public.jpeg` and an 8×8 red image stays red (R>200,
   G<40, B<40). Isolated-host destination types are PNG, JPEG, BMP.
7. **Metadata tag trees.** Register prefix, `TagCreate` / `SetTagWithPath`
   / `CopyStringValueWithPath`, matching-image-property, mutable copy,
   remove, enumerate stop-on-false, prefix-conflict `CFError`, XMP
   round-trip of `exif:UserComment`.

GIF NETSCAPE field 3 → `LoopCount` **4** (fixture `netscape-loop3.gif`).
No GIF pixel decode on the isolated host.

## Open (oracle-questions.tsv)

Animation queue/timing, HEIC primary index, incremental JPEG vs Darwin's
`public.mpo-image` sniffer, thumbnail resampling kernel. No parameter
search against comparison scores.

Sibling note: `uikit/Sources/ImageIO` still returns nil for garbage
`CreateWithData` and does not resample thumbnails. That is the
corelibs-route module; this branch does not edit it.

## Gate

Isolated Linux `swiftc -warnings-as-errors` of `libImageIO.dylib` plus 38
cited tests in `docker run swift:6.2-noble` (Swift 6.2.4):

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=ImageIO lane=medium-full symbols=902
FRAMEWORK_FANOUT_REFERENCE_OK
IMAGEIO_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=ImageIO dylib=libImageIO.dylib
```

No uikit sources changed, so Catalyst / iOS suite / real-app pixels are
unchanged.
