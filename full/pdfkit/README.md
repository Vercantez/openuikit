# PDFKit (Linux starting point)

This is a clean-room Linux starting implementation of Apple's public `PDFKit`
surface for OpenUIKit. It is not Apple PDFKit and it does not claim rendering,
encryption, printing, OCR, or find-interaction parity.

## What is real

- **Documents and pages.** `PDFDocument` reads `%PDF-` files by scanning
  uncompressed indirect objects, the page tree, `MediaBox` and sibling boxes,
  Info attributes, and simple outline titles. Empty documents accept inserted
  `PDFPage` values. `write(to:)` / `dataRepresentation()` emit a classic PDF 1.4
  file for in-memory documents and round-trip the original bytes when a loaded
  file was not mutated.
- **Text.** Uncompressed content streams yield strings from PDF literal/hex
  string tokens (`Tj` / `TJ` / `'`); `findString` searches those strings with
  `NSString.CompareOptions`.
- **Model objects.** Actions, destinations, outlines, annotations, borders, and
  selections are in-process data objects with the public property surface.
- **View state.** `PDFView` keeps document assignment, page history, scale,
  selection, and a simple stacked layout for coordinate conversion. It does not
  rasterize pages.
- **Typed surface.** Public enumerations, option sets, notification names, and
  annotation/document key newtypes are present with pinned raw values.

## Fail-closed boundaries

- **Rendering.** `PDFPage.draw`, `PDFAnnotation.draw`, `PDFBorder.draw`, and
  `PDFView.draw` are no-ops. `thumbnail(of:for:)` returns an empty `UIImage` of
  the requested size rather than pretending to render PDF content.
- **Encryption.** A `/Encrypt` dictionary marks `isEncrypted` / `isLocked`.
  Page content is withheld and `unlock(withPassword:)` always returns `false`.
- **Write options.** Owner/user passwords, annotation burn-in, and OCR options
  refuse to write instead of emitting a forged encrypted or rasterized file.
- **Core Graphics refs.** `documentRef` and `pageRef` are `nil` on this host.
- **UI find / markup chrome.** `UIFindInteraction` is an inert stand-in;
  markup mode does not invoke Apple markup UI.
- **Host-gate UIKit/CoreGraphics types.** When UIKit and CoreGraphics are not
  importable, `PDFKitHostTypes.swift` provides stand-in `UIColor`, `UIImage`,
  `UIView`, `CGContext`, and related names so this module compiles in isolation.
  They are not Apple UIKit.

## Still deferred / unknown

FlateDecode and object-stream parsing, glyph-accurate selection bounds,
asynchronous `beginFindString` queue behavior, exact Apple notification
userInfo payloads, `kPDFDestinationUnspecifiedValue`'s published bit pattern,
and pixel layout of `PDFView` / `PDFThumbnailView` remain oracle questions.
See `oracle-questions.tsv`.
