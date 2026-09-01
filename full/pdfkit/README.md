# PDFKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `PDFKit`
surface for OpenUIKit. It is not Apple PDFKit. Isolated-host evidence covers
document I/O and in-process model/view state only. It does not claim integrated
Linux success against guest CoreGraphics or UIKit.

## What is real

- **Documents and pages.** `PDFDocument` parses `%PDF-` files from the classic
  `xref` table recorded by `startxref`. Indirect objects are loaded only at xref
  offsets, so `obj` tokens inside streams are not objects. Stream `/Length` may
  be a forward indirect reference. Page-tree `MediaBox`, `Resources`, and
  `Rotate` inherit from parent nodes. Empty documents accept inserted `PDFPage`
  values. `write(to:)` / `dataRepresentation()` emit a classic PDF 1.4 file with
  byte-accurate xref offsets; an unmutated loaded file round-trips original
  bytes.
- **Text.** Uncompressed content streams yield strings from PDF literal/hex
  tokens (`Tj` / `TJ` / `'`). `findString` searches those strings, including the
  next hit after a same-page selection.
- **Encryption detection.** A parsed trailer dictionary with `Encrypt` marks
  `isEncrypted` / `isLocked`. Page content is withheld, unlock always fails, and
  locked documents refuse to write. Catalog or stream bytes that merely contain
  the substring `/Encrypt` are not treated as encryption.
- **Fail-closed unsupported features.** Xref streams, object streams, and
  non-Identity filters fail the parse instead of returning a partial document.
  Recursion, object-count, byte, nesting, page-tree, and outline budgets reject
  oversized or cyclic input.
- **Model and view state.** Actions, destinations, outlines, annotations,
  borders, and selections are in-process objects. `PDFView` keeps document
  assignment, page history, scale, selection, and stacked layout math for
  `convert` without rasterizing.

## Fail-closed / not observed here

- **Rendering.** `PDFPage.draw`, `PDFAnnotation.draw`, `PDFBorder.draw`, and
  `PDFView.draw` are unavailable on the isolated Foundation host (they need
  `CGContext`). When UIKit is importable, `thumbnail(of:for:)` uses
  `UIGraphicsImageRenderer` and does not pretend to rasterize PDF content.
- **UIKit / CoreGraphics identities.** Production sources import those modules
  when present (`PDFKitDependencies.swift`) and do not define module-local
  `UIColor`, `UIImage`, `UIView`, `CGContext`, or `CGPDFDocument` stand-ins.
  Thumbnail and find-interaction paths use real `UIImage` /
  `UIFindInteraction(sessionDelegate:)` APIs. The isolated host gate does not
  compile or run those paths.
- **Write options.** Owner/user passwords, annotation burn-in, and OCR options
  refuse to write.

## Still deferred / unknown

FlateDecode and object-stream parsing, glyph-accurate selection bounds, Apple
find-interaction chrome, exact notification userInfo, the published bit pattern
of `kPDFDestinationUnspecifiedValue`, and pixel layout of `PDFView` /
`PDFThumbnailView` remain oracle questions. See `oracle-questions.tsv`.

A future EC2 run must build guest Foundation, CoreGraphics, and UIKit first,
build this module with their `-I`/`-L` paths, and run
`tests/agent/PDFKitDependencyIdentity.swift` with `LD_LIBRARY_PATH` so real
`CGRect`, `CGPDFDocument`/`CGPDFPage`, `UIImage`, `UIView`, and
`UIViewController` values cross the PDFKit ABI. The isolated host gate is not
that run.
