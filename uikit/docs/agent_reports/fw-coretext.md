# CoreText SDK depth (`agent/fw-coretext`)

Close the CoreText guest module against the measured iOS SFUI tables the
UIKit port already carries, not a second shaper.

## Before → after

| | implemented | declared | deferred |
|---|---|---|---|
| start | 341 | 1840 | 463 |
| end | **1444** | 774 | 426 |

Target was implemented ≥ 1200 with CTFont / CTFontDescriptor / CTLine /
CTRun / CTTypesetter / CTFramesetter / CTFrame / CTParagraphStyle
nondeferred. Those C families are implemented.

## What was measured (not searched)

- **kCT\* CFString payloads**, Darwin CoreText, 2026-09-05. `kCTFontAttributeName`
  is `"NSFont"`; `kCTForegroundColorAttributeName` is `"CTForegroundColor"`;
  `kCTKernAttributeName` is `"NSKern"`; `kCTParagraphStyleAttributeName` is
  `"NSParagraphStyle"`; `kCTUnderlineStyleAttributeName` is `"NSUnderline"`;
  `kCTFontNameAttribute` is `"NSFontNameAttribute"`;
  `kCTFontFamilyNameAttribute` is `"NSFontFamilyAttribute"`;
  `kCTFontSizeAttribute` is `"NSFontSizeAttribute"`;
  `kCTFontLicenseNameKey` is Apple's `"CTFontLicenseNameName"`;
  `kCTFontManagerRegisteredFontsChangedNotification` is
  `"CTFontManagerFontChangedNotification"`.
- **iOS 17 pt system-regular** from
  `uikit/Sources/OpenUIKit/Resources/font_metrics_ios.json`
  (`system-regular-17.0`, `.SFUI-Regular`, Tools/oracle2/fontprobe, iOS 26.1):
  ascender 16.1865234375, descender −4.1005859375, leading 0, capHeight
  11.97802734375, xHeight 8.9482421875, UPEM 2048. `"Hello"` advances
  12.185546875 + 9.2802734375 + 3.8681640625 + 3.8681640625 + 9.6123046875
  = **38.814453125**. Equals FontEngine iOS-cut `macAdvance − 5×cutDelta`
  and UILabel.
- **UI font default sizes** (Apple): system/emphasized 13, small 11, mini 9,
  label 10.
- **CTFontCopyTraits** (Darwin, 17 pt): regular weight 0; bold copy weight
  **0.4**.

Glyph IDs are Unicode BMP because the harvest is per-character. macOS
`.SFNS` Hello cmap (112, 676, 772, 772, 815) is **not** applied to iOS SFUI.

## Rule

`CTFontCreateUIFontForLanguage` / system names (`.SFUI-*`,
`.AppleSystemUIFont`, `System Font Regular/Bold`) resolve through
`_SFUITable` (faces at 12/13/17 regular + 17 bold, lerp/scale otherwise).
Unknown and registered TTF stay on the portable face so
`OpenUIKitPortable-Regular` at 12 pt keeps UPEM 1000, ascent 9.6, advance
`max(size*0.5, 1)`. `CTLine` / `CTRun` / `CTTypesetter` / `CTFrame` consume
those same advances. Isolated Linux uses ImageIO-style CG lookalikes;
Darwin `@_exported import CoreGraphics`.

## Verify

- Darwin: `swiftc` dylib + 18 `test*` functions, including Hello width
  38.814453125 and portable width 30. **OK**.
- Linux `swift:6.2-noble`: same sources and tests **OK** (`CGFloat(truncating:
  NSNumber)` replaced with `doubleValue`; traits stored as `NSNumber`).
- `bash tests/acceptance/test_host.sh`: deliverable validator currently
  refuses this worktree because
  `scripts/framework-fanout/generate_seed_v2.py` hashes
  `e56ee6e70b…` against the seed pin `e44f6bde16e7…` (operator generator
  advance; not this branch). Compile + tests that the sealed runner would
  invoke are green on Linux.
- No uikit render rule. Catalyst / iOS suite / real-app pixels unchanged
  (112/113). No `Package.resolved`.

## Open (in `oracle-questions.tsv`)

- iOS SFUI cmap glyph IDs
- iOS SFUI glyphCount / underline / font bbox
- iOS interned payload of `kCTFontRegistrationUserInfoAttribute`
  (macOS-unavailable; Linux uses the NSCT sibling pattern)
- `RegisterGraphicsFont` success path
- `CTAdaptiveImageProviding.image(forProposedSize:)` (`CGImage`)
- non-rect `CTFramesetterCreateFrame` origins
