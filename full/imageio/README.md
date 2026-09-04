# ImageIO (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`ImageIO` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, TBD exports, and the pinned `dotnet/macios` bindings as a
secondary numeric cross-check. It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

The original portable `CGImageSource` state model is preserved:

- Static `CGImageSourceCreateWithData` and incremental
  `CGImageSourceCreateIncremental` / `UpdateData` share one object.
- When CQuartz is present, PNG, JPEG, and composited GIF frames still
  decode through that backend into the OpenCoreGraphics bitmap type.
- On the isolated Linux host (Foundation only) the same APIs encode and
  decode **stored-block PNG** and **uncompressed 32-bit BMP**. Those
  round-trips are covered by focused agent tests.
- Header parsers for PNG IHDR, GIF screen size / NETSCAPE loop, JPEG SOF
  / Exif orientation, and BMP BITMAPINFOHEADER still run without a pixel
  decode.
- Property keys already shipped in the lane (`PixelWidth`, `{GIF}`,
  `ShouldCache`, …) keep those payloads. Dictionary wrappers such as
  `{TIFF}` / `{Exif}` follow the same published ImageIO naming pattern.
- Enum raw values come from the graph plus pinned macios
  (`CGImageSourceStatus`, orientation, metadata errors/types, TGA
  compression, animation OSStatus codes).
- In-memory `CGImageMetadata` / `CGImageMetadataTag` store, namespace
  prefix registration with a fail-closed prefix conflict, and destination
  finalize into `NSMutableData`, a file URL, or a lookalike
  `CGDataConsumer`.

## Fail-closed boundaries

Linux has no ImageIO.framework, ColorSync, or Apple thumbnail scaler.

- JPEG and GIF **pixel** decode remain CQuartz-only. Without that module,
  `CGImageSourceCreateWithData` returns nil for those types; incremental
  sources may still expose a UTI and GIF loop count from the bytes.
- `CGImageSourceCreateThumbnailAtIndex` returns the decoded image; it
  does not resample.
- Auxiliary/HDR/portrait mattes return nil and are not synthesized.
- `CGImageMetadataCreateFromXMPData` / `CreateXMPData` return nil rather
  than inventing an XMP packet.
- Destination types are `public.png` and `com.microsoft.bmp` only.
- `CGAnimateImageDataWithBlock` runs the block inline once for a decoded
  still; it does not schedule Apple frame delays.

On Darwin, `CGImage`, `CGDataProvider`, and `CGDataConsumer` come from
CoreGraphics. On the isolated Linux host those names are module-local
lookalikes so the existing source signatures still compile. They are not
CoreGraphics identity. Real dependency identity is the future EC2 probe
in `tests/agent/ImageIODependencyIdentity.swift`. CoreFoundation `CF*`
spellings are likewise host aliases (`String` / `[String: Any]` / `Data`
/ `URL` / `NSMutableData`).

## Still deferred

- Exact Darwin CFString payloads for keys that this lane stores as the C
  identifier.
- HEIC primary-image index, JPEG incremental-vs-nil CreateWithData, XMP
  parse errors, and animation callback timing (see
  `oracle-questions.tsv`).
- Thumbnail geometry, Gain Map / ISO HDR encode options, and WebP/AVIS
  pixel codecs.

Run `bash tests/acceptance/test_host.sh` from this directory. Keep
generated products out of the tree.
