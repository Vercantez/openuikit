# TextKit attachments (`agent/uikit-textkit`)

Close the APP LADDER TextKit row: `NSTextAttachment` (12 apps / 168 uses;
WordPress-iOS 37) plus `NSTextContainer` (8), `NSTextStorage` (5),
`NSLayoutManager`, `NSTextAttachmentContainer`, `NSTextAttachmentViewProvider`,
`NSAdaptiveImageGlyph`.

Oracle: iPhone SE 2x / iOS 26.1, `SIM_DEVICE=2x`, probes in
`/tmp/probe-uikit-textkit` (not committed). Device suffix `-uikit-textkit`.

## Measured attachment table (SE 2x / iOS 26.1)

17 pt SFUI regular: ascender **16.187**, descender **−4.101**, lineHeight **20.287**.
`attachmentBounds.origin.y` is CoreText (positive **UP** from the baseline).

Default `bounds == .zero` → `attachmentBounds` is `(0, 0, image.w, image.h)` —
the image sits on the baseline. Explicit `(0,0,24,24)` matches. Dark frames
identical to light.

Line metrics:

```
ascent  = max(font.ascender, max(0, origin.y + height))
descent = max(−font.descender, max(0, −origin.y))
height  = ascent + descent; UILabel 2x then ceils to the device pixel
```

| probe | origin.y | font | box | sizeThatFits / usedRect |
|---|---|---|---|---|
| path 0 default 24×24 | 0 | 17 | sits on baseline | UILabel **46×28.5** (A≈11 + 24 + B≈11; 28.101 → 28.5) |
| path 1 bounds (0,0,24,24) | 0 | 17 | same | **46×28.5** |
| origin.y −4 | −4 | 17 | | **24.5** |
| origin.y −6 | −6 | 17 | | **24.0** |
| origin.y −24 | −24 | 17 | hangs below | **40.5** (ascent 16.187, descent 24) |
| 28 pt + 24×24 | 0 | 28 | image shorter than ascender | **33.5** (font line) |
| solo 32×32 | 0 | 17 | | **36.5** (32 + 4.101) |
| path 5 padding 4 | 0 | 17 | drawn inset both edges | size stays **46×28.5**; red box **23…39** (was 19…43) |
| UITextView path 7 | 0 | 17 | padding 5, inset (8,0,8,0) | usedRect h **28.101**; first glyph **(5, 24)**; attachment **(16.023, 24)**; pixel box view-relative **(16, 8)** |

UIKit draw: `imageTop = baselineY − (origin.y + height)`.
`lineLayoutPadding` is a drawing inset of both leading and trailing edges of
the advance box, not an advance (path 5).

Trailing wrap-space on a non-final attributed line is clipped to the wrap
width: `"Hello ￼ world that wraps over two lines here"` at 200 → drawWidth
198.292, with-space 202.641, sizeThatFits **200×48.5**.

## Before / after (named probes)

`SKIP_CAPTURE=1 scripts/oracle_flow.sh /tmp/flow-uikit-textkit` against the
SE 2x captures in `/tmp/probe-uikit-textkit/out`.

| scene | before (no engine) | after |
|---|---|---|
| `attach_probe` | no attachment box (empty U+FFFC) | **99.178** blob **12.0**; leftover layout: golden UITextView private `UIView` at path 7.1 / 11.1 (`_UITextLayoutView` sibling, frame = container). Not modelled — adding a public sibling on every UITextView would move `textview_basic`. |
| `attach_probe_dark` | same | **99.714** blob **0.0**; same two dump paths |
| `attach_bounds_sweep` | empty | **PASS 98.998** blob **4.8** layout 0 |

Padding both-edge inset dropped attach_probe blob **166.5 → 12.0**. Wrap-width
clip dropped path 6 sizeThatFits200 **203 → 200**.

## What landed

- `NSTextAttachment`: `image` / `contents` / `fileType` / `bounds` /
  `lineLayoutPadding` / `allowsTextAttachmentView` / `usesTextAttachmentView`,
  `attachmentBounds(for:proposedLineFragment:glyphPosition:characterIndex:)`,
  `image(forBounds:textContainer:characterIndex:)`, registry
  `textAttachmentViewProviderClass(forFileType:)`.
- `NSAttributedString(attachment:)` inserts U+FFFC (`NSAttachmentCharacter`).
- `NSTextStorage` / `NSTextContainer` / `NSLayoutManager` over
  `AttributedTextLayout`; `UITextView.textStorage` / `layoutManager` /
  `textContainer` are those objects.
- `NSTextAttachmentViewProvider` hosts a `UIView` inline in `UITextView`
  (default `UIImageView`; custom class via the UTI registry). UITextView
  paints image attachments via the hosted view; UILabel paints through the
  canvas (no hosted view).
- Scene spec v5.4 `runs[].attachment` (openrender + oracle SceneKit).
- Conformance app `Sources/ConformanceApps/TextKit/` (UILabel + UITextView +
  hanging bounds + custom provider). Capture with
  `scripts/conformance_flow.sh /tmp/conf-TextKit TextKit`.

## Use-site counts unblocked (full/ladder/APP_LADDER.md §8)

| type | apps | uses | top blocker |
|---|---|---|---|
| `NSTextAttachment` | 12 | 168 | WordPress-iOS **37** |
| `NSTextContainer` | 8 | 40 | |
| `NSTextStorage` | 5 | 45 | |
| `NSLayoutManager` | 4 | 30 | |
| `NSTextAttachmentContainer` / `NSTextAttachmentViewProvider` / `NSAdaptiveImageGlyph` | compiling surface | | |

## Gates

- Catalyst **124/124**
- iOS suite **112/113** (`corner_radius` only; no drops)
- Real-app floors held **99.137 / 98.535 / 98.548 / 99.469 / 98.639 / 98.133 / 97.516 / 99.65 / 82.170 / 99.86 / 99.734 / 85.393**
- Linux `swift:6.2-noble` openrender green (**192.79 s**)
- Unit tests: `TextKitTests`, `AttributedStringTests`, `AttrtextParagraphProbeTests`
- Conformance TextKit (SE 2x / iOS 26.1): t200 **99.932**, t1200 **99.920**, t2200 **99.577** (all ≥ 97.5). t2200 leftover is the 24×24 custom-provider chip at `[32, 113]` (blob 576) — score still above bar.
- No `Package.resolved`; no pin / env edits

## Open

- UITextView dump still lacks the private full-size `UIView` at path `*.1`
  (compare.py public-class walk). Pixels hold the text view (dark blob 0).
- `fileWrapper` was not in the brief; omitted.
- Notes editor was not modified (would move every Notes row).
