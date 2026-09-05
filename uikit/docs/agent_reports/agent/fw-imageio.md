# ImageIO SDK depth (`agent/fw-imageio`)

No scene family. This branch raises the Linux `ImageIO` guest and the
OpenUIKit ImageIO module so `CGImageSource` / `CGImageDestination` /
`kCGImageProperty*` are nondeferred.

## Before / after

| gate | before | after |
|---|---|---|
| Guest coverage | 163 implemented / 739 declared | **902 / 902 implemented** |
| Catalyst | 124/124 | **124/124** |
| iOS suite | 112/113 (`corner_radius`) | **112/113** |
| Real-app floors | 99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.511 / 82.170 / 99.760 / 99.689 / 85.393 | unchanged |
| PNG pixels vs Apple NSImage | identical RGBA8 (16×12 gradient) | identical |
| JPEG vs Apple NSImage | maxDelta=2 | maxDelta=2 |
| Linux `swift:6.2-noble` openrender | green | green (185.50 s) |
| Linux guest tests | — | 37/37, `IMAGEIO_AGENT_RUNTIME_OK` |

## What was measured (Apple ImageIO, macOS 26.1, 2026-09-05)

Oracle dump `/tmp/imageio-apple-oracle.txt` (not in the repo).

- **750** `kCG*` / `kIIO*` CFString payloads. Nested keys are short names
  (`PixelWidth`, `DateTimeOriginal`, `{Exif}`). Option keys keep the C
  identifier when that is the runtime string (`kCGImageSourceShouldCache`,
  `kCGImageSourceThumbnailMaxPixelSize`).
- PNG filter macros are Int32: NONE=8, SUB=16, UP=32, AVG=64, PAETH=128,
  NO_FILTERS=0; `IIO_HAS_IOSURFACE=1`.
- `CGImageSourceCreateWithData` of empty or garbage bytes still returns a
  **source** (`statusInvalidData`, count 0, type nil).
- PNG type appears at **10 bytes**, not 8. A truncated typed PNG blob that
  is final reports `statusComplete` with no image. Incremental of the same
  prefix is `statusIncomplete` until `UpdateData(..., true)`.
- Fixture `full/imageio/tests/fixtures/probe-png-chunks.png` (2×1 RGB):
  pHYs 5669 ppm → `DPIWidth/Height=144` because `5669 * 0.0254 = 143.9926`,
  rounded to 144. gAMA 45455 → `Gamma=0.45455`. tEXt Title=Hello →
  `{PNG}.Title` and `{IPTC}.ObjectName`. No `HasAlpha` for color type 2.
- Thumbnails: `newDim = round-half-to-even(dim * maxPixel / max(w,h))`,
  clamp ≥ 1, no upscale. 16×12 max 8 → 8×6; max 6 → 6×4; max 17 → 16×12.
  JPEG orientation 6 + `CreateThumbnailWithTransform` + max 8 → 6×8.
- GIF NETSCAPE loop field 3 → `LoopCount` 4 (field+1; 0 stays 0). No GIF
  pixel decode (`STBI_NO_GIF` in CQuartz).

## Rule

Guest (`full/imageio/`) and uikit (`Sources/ImageIO/`) parse PNG IHDR /
pHYs / tEXt / gAMA and JPEG SOF / APP0 JFIF / APP1 Exif (orientation,
Exif IFD, GPS IFD). Decode/encode PNG and JPEG pixels go through CQuartz
`QZImageDecodeRGBA` / `QZImageEncodePNG` / `QZImageEncodeJPEG` — no second
decoder. Destination types: uikit PNG+JPEG; isolated guest PNG+BMP (no
CQuartz). XMP round-trips a minimal RDF packet via `hasPrefix` / index
scan (no `_StringProcessing`).

## Open questions (`full/imageio/oracle-questions.tsv`)

- Incremental JPEG: Darwin sniffs truncated FF D8 as `public.mpo-image`;
  the port keeps `public.jpeg` from SOI.
- Thumbnail resampling kernel (geometry is measured; Apple's kernel is not).
- `CGAnimateImageDataWithBlock` queue / per-frame timing.
- HEIC primary image index.

The sealed `tests/acceptance/test_host.sh` still refuses on a pre-existing
`generate_seed_v2.py` provenance hash mismatch (`reference/` is immutable).
Linux typecheck + the 37 agent tests are the runtime evidence on this branch.
