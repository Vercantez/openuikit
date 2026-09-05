# CoreText (Linux starting point)

This directory is a clean-room Linux starting point for Apple's public
`CoreText` module, seeded from the Xcode 26.1 iPhoneOS 26.1 symbol graph,
API digester, and TBD exports. It is not wired into the shared guest
package; that integration is a later central-review step.

## What is real

- Process-scope `CTFontManagerRegisterFontsForURL` / unregister, including
  the Apple-oracle error domain
  `com.apple.CoreText.CTFontManagerErrorDomain` and codes 101 / 103 / 105 /
  201 / 306 / 307. Persistent, session, and user scopes fail closed with
  `unsupportedScope`. Asset-catalog registration reports failure.
- Public enums, option sets, SFNT C structs, FourCC table tags, AAT feature
  selector integers parsed from pinned `dotnet/macios`, and `kCTVersionNumber*`
  values.
- Interned `kCT*` CFString payloads MEASURED 2026-09-05 on Darwin CoreText
  (`kCTFontAttributeName` is `"NSFont"`, not the C identifier;
  `kCTFontLicenseNameKey` is the Apple quirk `"CTFontLicenseNameName"`).
- Two faces:
  - **OpenUIKit Portable** (1000 UPM, ascent 800, descent 200). Metrics
    scale by `size / unitsPerEm`. Advance is `max(size * 0.5, 1)`.
    Registered TTF/OTF/TTC bytes contribute `head` / `hhea` / `maxp` /
    `name` / `OS/2` / `post` when those tables parse.
  - **SFUI** from `uikit/Sources/OpenUIKit/Resources/font_metrics_ios.json`
    (Tools/oracle2/fontprobe, iOS 26.1). 17 pt regular: UPEM 2048, ascent
    16.1865234375, descent 4.1005859375, leading 0, capHeight
    11.97802734375, xHeight 8.9482421875. `CTLine` width of `"Hello"` at
    17 pt is **38.814453125**, matching FontEngine.measure / UILabel on
    the iOS cut. Glyph IDs are Unicode BMP code units; Apple cmap indexes
    were not harvested (`macOS .SFNS` H was glyph 112).
- `CTFontCreateUIFontForLanguage` default sizes MEASURED on Apple:
  system/emphasized 13, small 11, mini 9, label 10.
- `CTFontCopyTraits` bold weight **0.4** MEASURED 2026-09-05 Darwin
  `CTFontCreateCopyWithSymbolicTraits(.traitBold)` at 17 pt.
- Typesetter / line / run / framesetter / frame use the same per-character
  advances (SFUI table or portable `max(size*0.5,1)`). `CTLineDraw` /
  `CTFrameDraw` / `CTRunDraw` record into the context (Linux lookalike
  counters; Darwin bitmap context is otherwise unused).
- Paragraph style, text tab, ruby annotation, glyph info (name / CID /
  `CTGlyphInfoCreateWithGlyph`), and run-delegate callbacks are
  process-local objects.
- `AttributedString.TextAlignment` / `LineHeight` and
  `AttributeScopes.CoreTextAttributes` compile against Linux Foundation.

Host-compiled sources import Foundation (and CoreFoundation). When
`canImport(CoreGraphics)` is true the module `@_exported import`s the real
module. Isolated Linux uses ImageIO-style lookalikes for `CGGlyph`,
`CGFontIndex`, `CGAffineTransform`, `CGPath`, `CGContext`, and `CGFont`
(not CoreGraphics identity).
`tests/agent/CoreTextDependencyIdentity.swift` imports `CoreText` and
`Foundation` for the later EC2 integration build.

## Fail-closed boundaries

- `CTFontManagerRegisterFontsWithAssetNames` always invokes the handler with
  failure; there is no asset catalog.
- Font matching progress reports only `.didBegin` / `.didFinish` and never
  invents downloads.
- `CTFontCopyTable` / `CTFontHasTable` return empty/false until table
  streaming is observed.
- `CTFontManagerRegisterGraphicsFont` / `UnregisterGraphicsFont` fail closed
  with `unsupportedScope` (no process-scope CGFont table was measured).
- `CTAdaptiveImageProviding.image(forProposedSize:...)` is omitted because
  it returns `CGImage`. Drawing via
  `CTFontDrawImageFromAdaptiveImageProviderAtPoint` is a no-op.

## Deferred

- Apple cmap glyph IDs, outline paths, and harvested underline / font-bbox
  for iOS `.SFUI` (macOS `.SFNS` numbers are not iOS facts).
- `AttributedString.AdaptiveImageGlyph` (needs `UTType`, not a seeded
  dependency).
- Shaping, kerning, ligatures, justification quality, and bidi.
- AAT `kFontEnglishLanguage` anon-enum language codes (no compiling
  declaration without inventing ABI).

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/coretext --phase deliverable
bash full/coretext/tests/acceptance/test_host.sh
```
