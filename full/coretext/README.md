# CoreText (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreText` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, and TBD exports. It keeps the existing process-scope font
manager from the original lane and extends it to the wave-6 deliverable
gate. It is not wired into the shared guest package; that integration is a
later central-review step.

## What is real

- Process-scope `CTFontManagerRegisterFontsForURL` / unregister, including
  the Apple-oracle error domain
  `com.apple.CoreText.CTFontManagerErrorDomain` and codes 101 / 103 / 105 /
  201 / 306 / 307. Persistent, session, and user scopes fail closed with
  `unsupportedScope`. Asset-catalog registration reports failure.
- Public enums, option sets, SFNT C structs, FourCC table tags, AAT feature
  selector integers parsed from pinned `dotnet/macios`, and `kCTVersionNumber*`
  values.
- A portable fallback face named **OpenUIKit Portable** (1000 UPM, ascent
  800, descent 200). `CTFont` metrics scale by `size / unitsPerEm`. Registered
  TTF/OTF/TTC bytes contribute `head` / `hhea` / `maxp` / `name` / `OS/2` /
  `post` metrics when those tables parse.
- Typesetter / line / run / framesetter size suggestion use a deterministic
  LTR advance of `max(size * 0.5, 1)` and do not claim Apple shaping, bidi,
  or glyph IDs.
- Paragraph style, text tab, ruby annotation, glyph info (name / CID), and
  run-delegate callbacks are process-local objects.
- `AttributedString.TextAlignment` / `LineHeight` and
  `AttributeScopes.CoreTextAttributes` compile against Linux Foundation.

Host-compiled sources import Foundation (and CoreFoundation) only.
`tests/agent/CoreTextDependencyIdentity.swift` imports `CoreText` and
`Foundation` for the later EC2 integration build.

## Fail-closed boundaries

Linux has no CoreGraphics module, no Apple font daemon, and no UIKit text
system.

- APIs that take or return `CGContext`, `CGPath`, `CGFont`, `CGGlyph`, or
  `CGAffineTransform` are not declared on this host.
- `CTFontManagerRegisterFontsWithAssetNames` always invokes the handler with
  failure; there is no asset catalog.
- Font matching progress reports only `.didBegin` / `.didFinish` and never
  invents downloads.
- `CTFontCopyTable` / `CTFontHasTable` return empty/false until table
  streaming is observed.
- `CTAdaptiveImageProviding.image(forProposedSize:...)` is omitted because
  it returns `CGImage`.

## Deferred

- Drawing, glyph mapping, path outlines, and text matrices.
- `AttributedString.AdaptiveImageGlyph` (needs `UTType`, not a seeded
  dependency).
- Apple interned `CFString` payloads for `kCT*` keys other than the
  font-manager error domain (oracle-confirmed). Linux uses the C identifier
  as a stand-in.
- Shaping, kerning, ligatures, justification quality, and CTFrame path
  wrapping.

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/coretext --phase deliverable
bash full/coretext/tests/acceptance/test_host.sh
```
