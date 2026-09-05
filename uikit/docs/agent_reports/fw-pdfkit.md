# PDFKit SDK depth (`agent/fw-pdfkit`)

Wave-1 starting point was 244 implemented / 396 declared / 39 deferred
(679 public IDs). This branch is a real PDF reader/writer on the isolated
Foundation host, using the Swift object model already in
`full/pdfkit/PDFKitPDFIO.swift` (CQuartz `pkg_pdf.cpp` stays the asset-catalog
rasterizer; the host gate cannot link it).

## Measurements

| check | before | after |
|---|---|---|
| `coverage.tsv` implemented | 244 | **679** |
| declared / deferred | 396 / 39 | 0 / 0 |
| `tests/acceptance/test_host.sh` | `PDFKIT_AGENT_RUNTIME_OK` | same |
| unmutated `tests/fixtures/minimal.pdf` `dataRepresentation()` | n/a | byte-identical to the file |
| writer emit → parse → emit | n/a | byte-identical |
| FlateDecode hello stream | `unsupportedFilter` | extracted `"Hello PDFKit"` |
| ASCIIHex / ASCII85 / RunLength | unsupported | extracted `"Hello PDFKit"` |
| xref stream (W=[1 2 1], Index [1 5]) | `unsupportedXrefStream` | extracted `"Hello PDFKit"` |
| R=2 `/Filter /Standard` `unlock(withPassword:)` | always false, pageCount 0 | `"user"` → pageCount 1, text `"Hello PDFKit"`; `"wrong"` stays locked |
| `PDFPage.characterBounds(at: 0)` on writer `Tf 12` | `.zero` | width **7.2** (0.6 × 12) |
| `PDFView.autoScales` | flag only | assigns `scaleFactorForSizeToFit` = view width / page box width |

Encryption cites ISO 32000-1 §7.6.3 Algorithms 2–6 (file key / U / O) and
§7.6.2 Algorithm 1 (RC4 object key = MD5(fileKey ∥ n ∥ g)). AESV2 / R=5
paths are implemented from the same spec sections and Adobe ExtensionLevel 3
layout; the runtime fixture is R=2 RC4 so those AES numbers are not in the
table.

## Open

- Exact `kPDFDestinationUnspecifiedValue` bit pattern
- `beginFindString` queue timing vs Apple
- `scaleFactorForSizeToFit` vs pageBreakMargins on iOS 26.1 PDFView
- Type1/TrueType glyph outlines (text is character-box fills)
- Guest `PDFKitDependencyIdentity` against real UIKit / CGPDFDocument
