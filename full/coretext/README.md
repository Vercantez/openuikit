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
- Two faces plus a bundle TrueType fixture:
  - **OpenUIKit Portable** (1000 UPM, ascent 800, descent 200). Metrics
    scale by `size / unitsPerEm`. Advance is `max(size * 0.5, 1)` when
    the face has no `hmtx`. Registered TTF/OTF/TTC bytes contribute `head` /
    `hhea` / `hmtx` / `cmap` (formats 4 and 12) / `maxp` / `name` /
    `OS/2` / `post` / `glyf`/`loca` bounds, plus GSUB/GPOS presence.
  - **OpenUIKitFixture-Regular** under `tests/agent/fixtures/` (hand-built
    8-glyph TrueType). At 10 pt, `"Hello"` maps to glyphs `[3,4,5,5,6]`
    with advances `7+5+2.5+2.5+5.5=22.5`. U+1F600 is cmap format 12 →
    glyph 7. Process-scope `CTFontManager` registration feeds descriptor
    matching and `CTFontCollection`.
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
- `CTFontCopyTable` / `CTFontHasTable` / `CTFontCopyAvailableTables` return
  the parsed SFNT tables of a registered TTF. The portable face has none.
- Typesetter / line / run / framesetter / frame use the same per-glyph
  advances (cmap+hmtx on a registered TTF, SFUI harvest, or portable
  `max(size*0.5,1)`).   `CTLineCreateJustifiedLine` distributes leftover
  width across glyph advances. `CTFramesetterCreateFrame` wraps with
  `CTTypesetterSuggestLineBreak` inside a `CGPath` rectangle.
  Per-character fonts split `CTRun`s; `kCTRunDelegateAttributeName` width /
  ascent / descent participate in line width and breaking; additive
  `kCTKernAttributeName` is applied to advances. `CTLineDraw` / `CTFrameDraw` /
  `CTRunDraw` record into the context
  (Linux lookalike counters; Darwin bitmap context is otherwise unused).
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
- `CTFontGetLigatureCaretPositions` is fail-closed: it always returns 0
  and never writes the out-buffer (no `lcar` / GDEF caret harvest).
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
- Shaping, kerning quality beyond additive `kCTKernAttributeName`, ligatures,
  justification quality, and bidi.
- AAT `kFontEnglishLanguage` / Macintosh script codes / `kMORT*` coverage
  bits / `kPROP*` direction classes (numeric ABI is not in the pinned graph,
  api-digester, or macios; OpenType name IDs, platform IDs, and FourCC table
  tags *are* implemented).

## Depth pass 2026-09 (wave 8)

Second SDK-depth pass. The first pass labelled 326 `implemented` rows with
`testClassHashableAndInequality`; that bulk hashing dump is refused. This
pass keeps the first-pass portable + SFUI tests green, adds a real
TrueType fixture, and recites those hashing rows onto family tests.

| | before (pass 1) | after (pass 2) |
|---|---|---|
| `implemented` | 1444 | 1450 |
| `declared` | 774 | 768 |
| `deferred` | 426 | 426 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

### Third pass (behaviour + SFNT tables)

Third SDK-depth pass on the same wave-8 heading. Keeps pass-1/pass-2 tests
green. Adds per-character fonts, `CTRunDelegate` width/ascent in line
breaking, additive `kCTKernAttributeName`, multi-run `CTLineGetGlyphRuns`,
optical/glyf bounds, collection attribute copy, and OpenType name/platform
IDs plus FourCC `kMORTTag`/`kPROPTag`/… aliases. SFNT C structs that already
compiled move `declared` → `implemented` via per-table memberwise init and
property round-trips (split across eight tests). No SwiftUI overlay IDs
exist on this surface; none were labelled `not-applicable`.

| | before (pass 2) | after (pass 3) |
|---|---|---|
| `implemented` | 1450 | 2274 |
| `declared` | 768 | 0 |
| `deferred` | 426 | 370 |
| `unavailable` | 0 | 0 |
| `not-applicable` | 0 | 0 |

Top-5 `implemented` evidence distribution (table-driven enum/option-set and
C `k…` integer catalogs may share a value test; no other single test exceeds
40% of the remaining implemented rows):

| citations | test |
|---|---|
| 439 | `testCatalogEnumAndOptionSetRawValues` (enums / option-set members / `init(rawValue:)`) |
| 380 | `testCatalogIntegerConstants` (C `kCT*` / feature selector integers) |
| 153 | `testSFNTCmapNamePropAndDirectoryTables` |
| 133 | `testSFNTLookupStateAndTrackTables` |
| 108 | `testDeclaredStringKeyPayloads` (`kCT*` CFString payloads) |

Remaining after the two catalogs: 1455 rows. Largest non-catalog test is
`testSFNTCmapNamePropAndDirectoryTables` at 153 (10.5%). C FourCC / OpenType
name-ID constants share `testSFNTNamePlatformAndTableTagConstants` (56).

Environment: `git rev-parse HEAD` matched
`bff8535c68425cc39fb45cb00d447b0981b57242`.
`.cursor/verify-cloud-environment.sh` failed with
`missing corpus checkout: scratch/ladder-corpus/focus-ios` (this pod
booted `bld-20260906-253cd433-7a30-4d11-aad2-8b209b7b2d21`, not campaign
`bld-20260901-d3266600-d87b-438f-94c1-d1aa48036e87`). Host `swiftc` is
Swift 6.2.4 / `x86_64-unknown-linux-gnu`. The isolated host gate does not
need the ladder corpus.

Sealed host gate on this pass printed:

```
FRAMEWORK_FANOUT_DELIVERABLE_OK module=CoreText lane=medium-full symbols=2644
FRAMEWORK_FANOUT_REFERENCE_OK
CORETEXT_AGENT_RUNTIME_OK
FRAMEWORK_FANOUT_HOST_OK module=CoreText dylib=libCoreText.dylib
```

Run the sealed host gate with:

```sh
python3 -B full/framework-fanout/validate_seed.py --framework full/coretext --phase deliverable
bash full/coretext/tests/acceptance/test_host.sh
```
