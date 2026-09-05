# ImageIO (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ImageIO` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and a 2026-09-05 Apple ImageIO runtime dump
(macOS 26.1) for CFString payloads and PNG/JPEG property dictionaries.

## What is real

- **902 / 902** public precise IDs are `implemented`, each cited to a
  focused `test*` (second pass). `kCGImageProperty*` CFString keys share
  one table test of the Darwin payloads measured 2026-09-05 (short names
  such as `PixelWidth` / `DateTimeOriginal` / `{Exif}`). Source, destination,
  metadata, auxiliary, animation, and `kIIO*` keys have their own tables.
  Option keys keep the C identifier when that is the runtime string
  (`kCGImageSourceShouldCache`). PNG filter macros are Int32 (`NONE=8`,
  `SUB=16`, `UP=32`, `AVG=64`, `PAETH=128`, `NO_FILTERS=0`).
- `CGImageSourceCreateWithData` returns a source for empty and garbage
  bytes (`statusInvalidData`, count 0). A 10-byte PNG prefix is typed
  `public.png` with `statusComplete` and no image (the blob is final).
  Incremental of the same prefix is `statusIncomplete` until
  `UpdateData(..., true)`.
- Property dictionaries parse real PNG chunks (IHDR, pHYs, tEXt, gAMA)
  and JPEG markers (SOF, APP0 JFIF, APP1 Exif including orientation).
  Measured: pHYs 5669 ppm → `DPIWidth` 144; gAMA 45455 → `Gamma` 0.45455;
  tEXt Title → `{PNG}.Title` and `{IPTC}.ObjectName`. Fixtures live under
  `tests/fixtures/`.
- Thumbnails honour `ThumbnailMaxPixelSize` with round-half-to-even
  geometry (16×12 max 8 → 8×6, max 6 → 6×4) and
  `CreateThumbnailWithTransform` orientation (JPEG orientation 6 + max 8
  → 6×8). Nearest-neighbour resample; Apple's kernel is still open.
- GIF NETSCAPE loop field 3 → `LoopCount` 4. No GIF pixel decode on the
  isolated host (CQuartz compiles `STBI_NO_GIF`).
- Destinations write `public.png`, `public.jpeg`, and `com.microsoft.bmp`.
  PNG encode is stored-block zlib and is byte-identical to
  `tests/fixtures/sample-2x1.png` / `gradient-16x12.png`. JPEG is portable
  baseline SOF0 4:4:4 (ITU-T T.81 Annex K tables, quality 90); the source
  re-reads the bytes this encoder writes. Arbitrary 4:2:0 JPEG pixel
  decode remains CQuartz-only.
- `CGImageMetadataCreateXMPData` / `CreateFromXMPData` round-trip a
  minimal RDF packet for in-memory tags.

## Fail-closed boundaries

- GIF **pixel** decode needs CQuartz. JPEG pixels on the isolated host are
  the 4:4:4 baseline codec above, not Apple's decoder.
- Auxiliary/HDR/portrait mattes return nil.
- HEIC/WebP/AVIS codecs are absent. `CopyTypeIdentifiers` lists the
  types this lane actually sniffs (PNG, JPEG, GIF, BMP).
- `CGAnimateImageDataWithBlock` runs the block inline once for a decoded
  still.

## Still deferred

See `oracle-questions.tsv`: animation queue/timing, HEIC primary index,
incremental JPEG vs MPO sniffer, thumbnail kernel.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep
generated products out of the tree.
