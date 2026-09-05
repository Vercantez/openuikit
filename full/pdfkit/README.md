# PDFKit (Linux starting point)

This is a clean-room Linux implementation of Apple's public `PDFKit` surface
for OpenUIKit. It is not Apple PDFKit. Isolated-host evidence covers document
I/O, standard-handler decryption, content-stream replay onto `CGContext` when
CoreGraphics is present, and in-process model/view state.

## What is real

- **Documents and pages.** `PDFDocument` parses `%PDF-` files from the classic
  `xref` table (`startxref`) and from ISO 32000-1 §7.5.8 xref streams (`/W`,
  `/Index`, `/Type /XRef`). Indirect objects are loaded only at xref offsets or
  from §7.5.7 object streams (`/Type /ObjStm`). Stream `/Length` may be a
  forward indirect reference. Page-tree `MediaBox` / `CropBox` / `BleedBox` /
  `TrimBox` / `ArtBox`, `Resources`, and `Rotate` inherit from parent nodes.
  Empty documents accept inserted `PDFPage` values. `write(to:)` /
  `dataRepresentation()` emit a classic PDF 1.4 file with byte-accurate xref
  offsets; an unmutated loaded file round-trips original bytes (measured on
  `tests/fixtures/minimal.pdf`).
- **Filters.** Stream `/Filter` values `FlateDecode` (zlib/RFC 1950 wrapping
  RFC 1951 stored, fixed, and dynamic Huffman), `ASCIIHexDecode`,
  `ASCII85Decode`, `RunLengthDecode`, and `Identity`, including `/DecodeParms`
  PNG/TIFF predictors (ISO 32000-1 §7.4). Unknown filters fail closed.
- **Text.** Content-stream `Tj` / `TJ` / `'` / `"` operands yield
  `PDFPage.string`. Character boxes use Helvetica-as-0.6×`Tf` (measured against
  the writer’s `Tf 12` stream: width 7.2). `findString` searches those strings.
- **Encryption.** Trailer `/Encrypt` with `/Filter /Standard` implements the
  PDF 1.7 (ISO 32000-1 §7.6) standard security handler: Algorithms 2–6 for
  R=2/3/4 (RC4 40/128 and AESV2), Algorithm 1 / 1a for object encryption, and
  the R=5 AES-256 U/O/UE/OE layout. `isEncrypted` / `isLocked` withhold pages
  until `unlock(withPassword:)` accepts the user or owner password. Catalog or
  stream bytes that merely contain the substring `/Encrypt` are not encryption.
- **Annotations and outlines.** Page `/Annots` become `PDFAnnotation` values
  (subtype, bounds, contents, URI actions, widget `T`/`V`, quad points). The
  catalog `/Outlines` tree becomes `PDFOutline` with destinations. The writer
  serializes both.
- **Drawing.** When CoreGraphics is importable, `PDFPage.draw(with:to:)`
  fills the display box white and replays path/fill/stroke/transform operators
  onto the port `CGContext`. Text glyphs are a documented best-effort (filled
  character boxes, not outlined Type1). `PDFView.autoScales` assigns
  `scaleFactorForSizeToFit` = view width / page box width.

## Fail-closed / not observed here

- **Write-time encryption.** `ownerPasswordOption` / `userPasswordOption` /
  annotation burn-in / OCR options still refuse to write. Encrypted fixtures
  are built through `PDFKitTesting.standardEncryptedHello` for the reader.
- **UIKit identities.** Guest builds import real UIKit (`UIColor`, `UIImage`,
  `UIView`, `UIFindInteraction`). The isolated Foundation host uses
  `PDFKitHost*` stand-ins behind `PDFKitColor` / `PDFKitImage` typealiases so
  those properties compile; they are not Apple types.
- **Apple Find chrome, exact `kPDFDestinationUnspecifiedValue` bits, and
  PDFView pixel layout** remain oracle questions.

## Coverage

679 / 679 public precise identifiers are `implemented` on the isolated host
gate (`tests/agent/PDFKitRuntime.swift`), including the PDFDocument, PDFPage,
PDFAnnotation, PDFOutline, PDFSelection, and PDFView families.

A future EC2 run must build guest Foundation, CoreGraphics, and UIKit first
and run `tests/agent/PDFKitDependencyIdentity.swift` so real `CGPDFDocument` /
`UIImage` / `UIView` values cross the PDFKit ABI. The isolated host gate is
not that run.
