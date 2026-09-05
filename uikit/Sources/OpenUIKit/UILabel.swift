// UILabel. Owner: text module.
// sizeThatFits / intrinsicContentSize / line breaking / truncation /
// alignment match real UIKit (validated against golden/label_*).

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


public enum NSTextAlignment: Sendable {
    case left, center, right, justified, natural
}

public enum NSLineBreakMode: Sendable {
    case byWordWrapping, byCharWrapping, byClipping
    case byTruncatingHead, byTruncatingTail, byTruncatingMiddle
}

@preconcurrency @MainActor
open class UILabel: UIView {
    /// Plain text. Real UIKit keeps one storage: setting `text` drops any
    /// attributed string, and setting `attributedText` makes `text` report
    /// the attributed string's characters.
    public var text: String? {
        get { _text }
        set {
            _text = newValue
            _attributed = nil
            setNeedsLayout()
        }
    }
    var _text: String?
    public var font: UIFont = .systemFont(ofSize: 17)
    public var textColor: UIColor = .label
    public var textAlignment: NSTextAlignment = .natural
    /// `.natural` follows `effectiveUserInterfaceLayoutDirection`.
    /// MEASURED Forms t200.rtl / NavFlow t200.rtl, iPhone SE 2x / iOS 26.1:
    /// full-width default-style cell labels and form fields pin their ink
    /// to the leading (right) edge when the frame itself is not tight.
    var _resolvedTextAlignment: NSTextAlignment {
        if textAlignment == .natural {
            return _layoutIsRTL ? .right : .left
        }
        return textAlignment
    }
    public var numberOfLines: Int = 1
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail
    /// Shrink single-line plain text to fit the label's width. UIKit keeps
    /// `font` and intrinsic size unchanged; the smaller font exists only for
    /// layout/drawing, which is also OpenUIKit's model below.
    public var adjustsFontSizeToFitWidth: Bool = false {
        didSet {
            if adjustsFontSizeToFitWidth != oldValue { setNeedsDisplay() }
        }
    }
    /// Lowest permitted drawing-size ratio when automatic shrinking is on.
    /// Stored verbatim like UIKit; the draw calculation clamps it to 0...1.
    public var minimumScaleFactor: CGFloat = 0 {
        didSet {
            if minimumScaleFactor != oldValue { setNeedsDisplay() }
        }
    }
    /// Permit UIKit's bounded negative tracking before a single-line label is
    /// truncated. The public property is retained independently from font
    /// shrinking; drawing uses at most five percent of the point size per
    /// inter-glyph advance and never changes intrinsic measurement.
    public var allowsDefaultTighteningForTruncation: Bool = false {
        didSet {
            if allowsDefaultTighteningForTruncation != oldValue {
                setNeedsDisplay()
            }
        }
    }
    /// Dynamic Type opt-in (M14). Stored so real app source compiles and so a
    /// host that changes `UITraitCollection.current.preferredContentSizeCategory`
    /// can tell which labels asked to follow it. OpenUIKit never changes the
    /// category on its own — there is no Settings app — so at the default
    /// `.large` this flag is inert, which is exactly what real UIKit does at
    /// the default category too (UIFontMetrics.swift).
    public var adjustsFontForContentSizeCategory: Bool = false

    /// Attributed content (M12). Setting it replaces `text` (the getter still
    /// reports the plain string, like real UIKit) and — matching measured
    /// UIKit — ADOPTS the paragraph style's alignment and line-break mode
    /// into the label's own properties.
    public var attributedText: NSAttributedString? {
        get {
            if let a = _attributed { return a }
            guard let text else { return nil }
            return NSAttributedString(string: text,
                                      attributes: [.font: font, .foregroundColor: textColor])
        }
        set {
            _attributed = newValue
            _setTextStorageFromAttributed(newValue)
            setNeedsLayout()
        }
    }
    var _attributed: NSAttributedString?

    func _setTextStorageFromAttributed(_ a: NSAttributedString?) {
        _text = a?.string
        guard let a, a.length > 0,
              let ps = a.attributes(at: 0, effectiveRange: nil)[.paragraphStyle]
                as? NSParagraphStyle else { return }
        textAlignment = ps.alignment
        lineBreakMode = ps.lineBreakMode
    }

    /// Flattened attributed content, or nil when the label holds plain text.
    var attributedLayoutText: AttributedTextLayout.Text? {
        guard let a = _attributed, a.length > 0 else { return nil }
        return AttributedTextLayout.flatten(a, defaultFont: font, defaultColor: textColor)
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureDefaults()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureDefaults()
    }

    private func configureDefaults() {
        isOpaque = false
        // UIKit: labels do not receive touches by default.
        isUserInteractionEnabled = false
        // UIKit default: label VERTICAL content hugging is 251 (horizontal
        // stays at the standard 250) — see docs/SCENE_SPEC.md v4.3.
        setContentHuggingPriority(UILayoutPriority(rawValue: 251), for: .vertical)
    }

    /// Auto Layout baseline attributes (M9). The first baseline sits at the
    /// ascender rounded half-up to whole points below the top — the same
    /// rounding the draw path uses (`baselineInLine` in drawContent); the
    /// last baseline of a single-line label is measured back from the
    /// line-box bottom. Verified against golden/constraints_baseline.
    override func _constraintBaselines() -> (firstFromTop: CGFloat, lastFromBottom: CGFloat)? {
        let ascender = FontEngine.metrics(for: font).ascender
        var first: CGFloat = (ascender + 0.5).rounded(.down)
        if let s = LayoutEngine.iOSPixelScale {
            // iOS (MEASURED 2026-09-04, constraints_baseline on the 2x
            // device): the baseline anchor is the ascender rounded to the
            // nearest DEVICE pixel — 26.66 -> 26.5, 12.38 -> 12.5, 20.95 ->
            // 21, 10.47 -> 10.5 — not to the whole point.
            first = (ascender * s).rounded(.toNearestOrAwayFromZero) / s
        }
        return (first, lineBoxHeight - first)
    }

    var layoutScale: CGFloat {
        let s = traitCollection.displayScale
        return s > 0 ? s : 2
    }

    /// Single-line label height (real UIKit rounding; see FontEngine).
    var lineBoxHeight: CGFloat { FontEngine.labelLineHeight(for: font) }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let t = attributedLayoutText { return attributedSizeThatFits(t, size) }
        guard let text, !text.isEmpty else { return .zero }
        let scale = layoutScale
        let lineH = lineBoxHeight
        // Single-line labels ignore the constraint entirely (real UIKit:
        // sizeThatFits of a 1-line label reports the full text width).
        if numberOfLines == 1 {
            let w = FontEngine.ceilToPixel(FontEngine.measure(text, font: font), scale: scale)
            return CGSize(width: w, height: lineH)
        }
        let halfMax: CGFloat = CGFloat.greatestFiniteMagnitude / CGFloat(2)
        let unbounded = !(size.width > 0) || size.width >= halfMax
        if unbounded {
            let w = FontEngine.ceilToPixel(FontEngine.measure(text, font: font), scale: scale)
            return CGSize(width: w, height: lineH)
        }
        let lines = TextLayout.wrap(text, font: font, maxWidth: size.width,
                                    maxLines: numberOfLines)
        guard !lines.isEmpty else { return .zero }
        var maxW: CGFloat = 0
        for (i, l) in lines.enumerated() {
            if i == lines.count - 1, l.text.endIndex < text.endIndex,
               OpenUIKitRuntime.systemFontCut == .iOS {
                // iOS: a capped label reports the width of the line it
                // DRAWS — the remainder tail-truncated into the last line
                // (iOS 26.1, label_multiline: 196 for a 200 pt fit whose
                // last whole-word line measures 185). Catalyst reports 192
                // there — neither the whole-word line nor the squeezed draw
                // width — so it keeps the whole-word measure (within the
                // golden's tolerance).
                let remainder = String(text[l.text.startIndex...]).replacingNewlines()
                let t = TextLayout.truncate(remainder, font: font, maxWidth: size.width,
                                            mode: .byTruncatingTail)
                maxW = Swift.max(maxW, FontEngine.measure(t.text, font: font)
                                 + t.delta * CGFloat(t.text.unicodeScalars.count))
            } else {
                maxW = Swift.max(maxW, l.measuredWidth)
            }
            // iOS 26.1 (MEASURED 2026-09-04, attrtext_paragraph path 2
            // on the SE 2x): right-aligned wrap counts the break space
            // as a leading space on the continuation line — see
            // AttributedTextLayout.wrap. Same number on a PLAIN
            // UILabel (probe_space_trail path 8: 197.5).
            if i > 0, OpenUIKitRuntime.systemFontCut == .iOS,
               textAlignment == .right {
                maxW = Swift.max(maxW, FontEngine.measure(" " + String(l.text), font: font))
            }
        }
        return CGSize(width: FontEngine.ceilToPixel(maxW, scale: scale),
                      height: FontEngine.labelBlockHeight(for: font, lines: lines.count))
    }

    open override var intrinsicContentSize: CGSize {
        // Explicit CGFloat: CGSize has Int/Double/CGFloat initialisers, so an
        // implicit-member `.greatestFiniteMagnitude` is ambiguous now that
        // CGFloat is a distinct type from Double (M15).
        sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                            height: CGFloat.greatestFiniteMagnitude))
    }

    // MARK: - Attributed measurement (M12)

    func attributedSizeThatFits(_ t: AttributedTextLayout.Text, _ size: CGSize) -> CGSize {
        let scale = layoutScale
        let halfMax: CGFloat = CGFloat.greatestFiniteMagnitude / CGFloat(2)
        let unbounded = !(size.width > 0) || size.width >= halfMax
        // A single-line label ignores the width constraint entirely, exactly
        // like the plain path (real UIKit reports the full text width).
        let maxWidth = (numberOfLines == 1 || unbounded)
            ? CGFloat.greatestFiniteMagnitude / 4 : size.width
        let lines = AttributedTextLayout.wrap(t, maxWidth: maxWidth,
                                              maxLines: numberOfLines, scale: scale)
        guard !lines.isEmpty else { return .zero }
        return AttributedTextLayout.blockSize(lines, scale: scale)
    }

    /// Line layout used for drawing (bounded by the label's own width).
    func attributedDrawLines(_ t: AttributedTextLayout.Text,
                             width: CGFloat) -> [AttributedTextLayout.Line] {
        AttributedTextLayout.wrap(t, maxWidth: width, maxLines: numberOfLines,
                                  scale: layoutScale)
    }

    // MARK: - Drawing

    /// Effective font for single-line PLAIN text in `width`. This deliberately
    /// does not mutate `font`: UIKit's public font, intrinsic size and baseline
    /// metrics continue to describe the requested font after a shrink draw.
    /// Attributed and multiline shrinking remain outside this focused surface.
    func effectiveDrawingFont(for text: String, width: CGFloat) -> UIFont {
        guard adjustsFontSizeToFitWidth, numberOfLines == 1,
              _attributed == nil, width > 0, font.pointSize > 0 else {
            return font
        }
        let natural = FontEngine.measure(text, font: font)
        guard natural > width + 1e-6 else { return font }

        let minimum = Swift.min(Swift.max(minimumScaleFactor, 0), 1)
        var lower = Swift.max(font.pointSize * minimum, 0.1)
        var upper = font.pointSize
        var candidate = font
        candidate.pointSize = lower

        // If even the minimum is too wide, use it and let the existing
        // truncation/clip path handle the remaining overflow.
        if FontEngine.measure(text, font: candidate) > width + 1e-6 {
            return candidate
        }

        // Font metrics are table-interpolated rather than assumed perfectly
        // linear. Solve for the largest fitting point size so a string whose
        // required scale is above the minimum is never needlessly ellipsized.
        for _ in 0..<28 {
            let mid = (lower + upper) / 2
            var probe = font
            probe.pointSize = mid
            if FontEngine.measure(text, font: probe) <= width + 1e-6 {
                lower = mid
            } else {
                upper = mid
            }
        }
        candidate.pointSize = lower
        return candidate
    }

    open override func drawContent(in canvas: Canvas, bounds: CGRect) {
        if let t = attributedLayoutText {
            let lines = attributedDrawLines(t, width: bounds.width)
            canvas.save()
            canvas.clip(to: bounds)
            AttributedTextLayout.draw(t, lines: lines,
                                      in: AttributedTextLayout.DrawContext(
                                        canvas: canvas, traits: traitCollection,
                                        bounds: bounds, alignment: _resolvedTextAlignment))
            canvas.restore()
            return
        }
        guard let text, !text.isEmpty else { return }
        let drawingFont = effectiveDrawingFont(for: text, width: bounds.width)
        let lineH = FontEngine.labelLineHeight(for: drawingFont)
        let metrics = FontEngine.metrics(for: drawingFont)

        // Lay out lines for drawing.
        struct DrawLine { var text: String; var width: CGFloat; var delta: CGFloat }
        var drawLines: [DrawLine] = []
        var needsClip = false
        func measureWith(_ s: String, delta: CGFloat) -> CGFloat {
            FontEngine.measure(s, font: drawingFont)
                + delta * CGFloat(s.unicodeScalars.count)
        }
        if numberOfLines == 1 {
            let full = FontEngine.measure(text, font: drawingFont)
            if full <= bounds.width + 1e-6 {
                drawLines = [DrawLine(text: text, width: full, delta: 0)]
            } else if allowsDefaultTighteningForTruncation,
                      text.unicodeScalars.count > 1 {
                let advances = CGFloat(text.unicodeScalars.count - 1)
                let required = (bounds.width - full) / advances
                let minimum = -drawingFont.pointSize * 0.05
                if required >= minimum {
                    drawLines = [
                        DrawLine(
                            text: text,
                            width: full + required * advances,
                            delta: required
                        )
                    ]
                } else {
                    let t = TextLayout.truncate(
                        text,
                        font: drawingFont,
                        maxWidth: bounds.width,
                        mode: lineBreakMode
                    )
                    let w = measureWith(t.text, delta: t.delta)
                    drawLines = [DrawLine(text: t.text, width: w, delta: t.delta)]
                    needsClip = w > bounds.width + 1e-6
                }
            } else {
                let t = TextLayout.truncate(text, font: drawingFont,
                                            maxWidth: bounds.width,
                                            mode: lineBreakMode)
                let w = measureWith(t.text, delta: t.delta)
                drawLines = [DrawLine(text: t.text, width: w, delta: t.delta)]
                needsClip = w > bounds.width + 1e-6
            }
        } else {
            let wrapped = TextLayout.wrap(text, font: drawingFont,
                                          maxWidth: bounds.width,
                                          maxLines: numberOfLines)
            for (i, l) in wrapped.enumerated() {
                if i == wrapped.count - 1, l.text.endIndex < text.endIndex {
                    // Text remains beyond the last line: tail-truncate the
                    // remainder into it (what UIKit draws for a capped label).
                    let remainder = String(text[l.text.startIndex...]).replacingNewlines()
                    let t = TextLayout.truncate(remainder, font: drawingFont,
                                                maxWidth: bounds.width,
                                                mode: .byTruncatingTail)
                    drawLines.append(DrawLine(text: t.text,
                                              width: measureWith(t.text, delta: t.delta),
                                              delta: t.delta))
                } else {
                    drawLines.append(DrawLine(text: String(l.text), width: l.drawWidth,
                                              delta: 0))
                }
            }
        }
        guard !drawLines.isEmpty else { return }

        // Real UIKit always clips label text to the label bounds (verified
        // against the oracle: an italic 'l' overhanging its advance is cut
        // exactly at the label's right edge).
        _ = needsClip
        let blockH = FontEngine.labelBlockHeight(for: drawingFont, lines: drawLines.count)
        let lineStep: CGFloat
        if drawLines.count > 1 {
            lineStep = (blockH - lineH) / CGFloat(drawLines.count - 1)
        } else {
            lineStep = lineH
        }
        canvas.save()
        canvas.clip(to: bounds)
        defer { canvas.restore() }

        // Vertical layout (validated against Catalyst pixel probes):
        // the text block is centered with the offset rounded HALF-UP to
        // whole POINTS, and the first baseline sits at the ascender
        // rounded half-up to whole points below the block origin.
        var y0 = ((bounds.height - blockH) / 2 + 0.5).rounded(.down)
        var baselineInLine = (metrics.ascender + 0.5).rounded(.down)
        if GlyphInkTable.usesIOSTable {
            // iOS cut: the harvested iOS masks are anchored to the row
            // round(2 * (top + (height - font.lineHeight) / 2 + ascender)),
            // i.e. the exact centred block and the exact ascender, no
            // whole-point rounding (Tools/oracle2/inkprobe).
            y0 = (bounds.height - blockH) / 2 + (lineH - metrics.lineHeight) / 2
            baselineInLine = metrics.ascender
        }
        let color = textColor.resolvedCGColor(with: traitCollection)
        guard color.alpha > 0 else { return }
        let glyphFont = GlyphRasterizer.font(for: drawingFont)

        for (i, line) in drawLines.enumerated() {
            var penX: CGFloat
            switch _resolvedTextAlignment {
            case .left, .natural, .justified:
                penX = 0
            case .center:
                // Real UIKit does NOT snap the centered pen: the exact
                // fractional origin feeds the per-glyph text-space phase
                // quantization (verified against golden/label_align.png).
                penX = (bounds.width - line.width) / 2
            case .right:
                penX = bounds.width - line.width
            }
            let baselineY = y0 + CGFloat(i) * lineStep + baselineInLine
            drawLineGlyphs(line.text, at: CGPoint(x: penX, y: baselineY),
                           in: canvas, font: drawingFont, color: color,
                           glyphFont: glyphFont,
                           extraAdvance: line.delta)
        }
    }

    private func drawLineGlyphs(_ line: String, at origin: CGPoint, in canvas: Canvas,
                                font: UIFont, color: CGColor,
                                glyphFont: InstancedGlyphFont?,
                                extraAdvance: CGFloat = 0) {
        UILabel.drawGlyphLine(line, at: origin, in: canvas, font: font,
                              dark: traitCollection.userInterfaceStyle == .dark,
                              color: color, glyphFont: glyphFont,
                              extraAdvance: extraAdvance)
    }

    /// Shared single-line glyph run renderer (ink-table fast path + stb
    /// fallback). Used by UILabel and the text-input views (UITextField /
    /// UITextView), so their glyph output is byte-identical to labels.
    nonisolated static func drawGlyphLine(_ line: String, at origin: CGPoint, in canvas: Canvas,
                              font: UIFont, dark: Bool,
                              color: CGColor, glyphFont: InstancedGlyphFont?,
                              extraAdvance: CGFloat = 0) {
        let scale = canvas.scale
        // Harvested-ink fast path: exact real-UIKit glyph masks, valid for
        // scale-2 translation-only canvases and integer point sizes (see
        // GlyphInkTable). Falls through per-glyph when a mask is missing
        // AND an outline font is loaded. The iOS table is selected by
        // hasIOSTable even when the Catalyst glyph_ink.json is absent.
        let ctm = canvas.ctm
        // Catalyst tables are 2x; the iOS tables exist per device scale.
        let iosInk = GlyphInkTable.hasIOSTable(scale: scale)
        let inkEligible = (iosInk || (GlyphInkTable.isAvailable && scale == 2))
            && ctm.a == scale && ctm.b == 0 && ctm.c == 0 && ctm.d == scale
            && font.pointSize == font.pointSize.rounded(.down)
        let famKey = FontEngine.familyKey(for: font)
        let sizeKey = Int(font.pointSize)
        // Device-pixel anchor of the text-space origin (x: pen 0).
        let devOX = Int((ctm.tx).rounded())
        // Nearest device row on both platforms. (A CTLineDraw sweep on iOS
        // snaps UP, but UILabel's own drawing — what the goldens and the
        // ink harvest see — lands 0.36 px higher than CTLineDraw at the same
        // geometry; measured 2026-09-04, Tools/oracle2/textprobe diag renders.)
        let devBaseY = Int((origin.y * scale + ctm.ty).rounded())

        var penX = origin.x
        var prev: Unicode.Scalar? = nil
        for ch in line.unicodeScalars {
            if let p = prev { penX += FontEngine.kerning(p, ch, font: font) }
            prev = ch
            // Tight (truncated-line) tracking applies to every glyph except
            // the ellipsis (verified against golden truncate pen positions).
            let adv = FontEngine.advance(of: ch, font: font)
                + (ch.value == 0x2026 ? 0 : extraAdvance)
            defer { penX += adv }
            // MEASURED inkprobe SE 2x / iOS 26.1, guest-trial2: de_DE
            // NumberFormatter currency is `4,50` + U+00A0 + `€`; harvest of
            // `system-regular|13|light|F0.0|160` is "no ink". Same skip as
            // SPACE so a guest without SFNS does not OPENUIKIT_IOS_INK_MISS
            // on the Ledger subtitle NBSP.
            if ch == " " || ch.value == 0x00A0 { continue }
            drawGlyph(ch, penX: penX, baselineY: origin.y, in: canvas, font: font,
                      dark: dark, color: color, glyphFont: glyphFont,
                      inkEligible: inkEligible, famKey: famKey, sizeKey: sizeKey,
                      devOX: devOX, devBaseY: devBaseY)
        }
    }

    /// Draw ONE glyph at pen position `penX` on baseline `baselineY` (both in
    /// user space). Split out of `drawGlyphLine` unchanged so the attributed
    /// path (per-run fonts, colors and baseline offsets) produces byte-
    /// identical ink to the plain path.
    nonisolated static func drawGlyph(_ ch: Unicode.Scalar, penX: CGFloat, baselineY: CGFloat,
                          in canvas: Canvas, font: UIFont, dark: Bool, color: CGColor,
                          glyphFont: InstancedGlyphFont?,
                          inkEligible: Bool, famKey: String, sizeKey: Int,
                          devOX: Int, devBaseY: Int) {
        let scale = canvas.scale
        if inkEligible {
            let penFloor = penX.rounded(.down)
            let frac = penX - penFloor
            let (tag, anchor) = GlyphInkTable.phase(size: font.pointSize, frac: frac)
            if GlyphInkTable.usesIOSTable {
                // Real-iOS masks are true coverage of an opaque colour:
                // plain alpha compositing, no calibration LUT; 1/8-pt phases.
                // MEASURED Linux trial 2026-09-05: with no SFNS.ttf the
                // previous TTF fallback drew nothing (blank labels). A hit
                // here needs no outline font; a miss without one is
                // OPENUIKIT_IOS_INK_MISS plus the exact harvest key.
                let (itag, ianchor) = GlyphInkTable.phaseIOS(size: font.pointSize, frac: frac, scale: scale)
                if let m = GlyphInkTable.maskIOS(familyKey: famKey, sizeKey: sizeKey,
                                                 dark: dark, tag: itag, scalar: ch, scale: scale) {
                    canvas.drawMask(m.mask, width: m.width, height: m.height,
                                    atPixelX: devOX + Int(scale) * Int(penFloor) + ianchor + m.ox,
                                    pixelY: devBaseY + m.oy, color: color)
                    return
                }
                if glyphFont == nil {
                    let key = GlyphInkTable.iosMaskKey(familyKey: famKey, sizeKey: sizeKey,
                                                       dark: dark, tag: itag, scalar: ch,
                                                       scale: scale)
                    if GlyphInkTable.logMisses { return }
                    GlyphInkTable.missingIOSInk(key)
                }
            } else if let m = GlyphInkTable.maskLinear(familyKey: famKey, sizeKey: sizeKey,
                                                dark: dark, tag: tag, scalar: ch) {
                canvas.drawMask(m.mask, width: m.width, height: m.height,
                                atPixelX: devOX + Int(scale) * Int(penFloor) + anchor + m.ox,
                                pixelY: devBaseY + m.oy,
                                color: color,
                                blendGamma: GlyphInkTable.blendGamma,
                                darkCalibration: dark)
                return
            }
        }
        if GlyphInkTable.usesIOSTable, glyphFont == nil {
            // Rotated/scaled CTM and fractional point sizes are not in the
            // harvested tables (Linux trial 2026-09-05): those still need
            // an outline font. Fail with the would-be key so a harvest
            // knows what was asked for.
            let penFloor = penX.rounded(.down)
            let frac = penX - penFloor
            let (itag, _) = GlyphInkTable.phaseIOS(size: font.pointSize, frac: frac, scale: scale)
            let key = GlyphInkTable.iosMaskKey(familyKey: famKey, sizeKey: sizeKey,
                                               dark: dark, tag: itag, scalar: ch,
                                               scale: scale)
            if GlyphInkTable.logMisses { return }
            fatalError("OPENUIKIT_IOS_INK_MISS: \(key) — iOS ink path ineligible (non-integer size or non-axis-aligned CTM); this still requires an outline font file")
        }
        guard let gf = glyphFont else { return }
        let g = gf.glyphIndex(of: ch)
        if g == 0 { return }
        // CoreText quantizes each glyph's pen position to quarter POINTS
        // with a +1/16pt bias (measured from Catalyst UILabel renders:
        // pos = floor(4x + 0.25)/4 in points), then CoreGraphics
        // quantizes the device-space origin to quarter device pixels
        // (floor). With integer view offsets and scale 2 the CT step
        // dominates; both are modeled here.
        let penQ = (penX * 4 + 0.25).rounded(.down) / 4
        let dev = CGPoint(x: penQ, y: baselineY).applying(canvas.ctm)
        let q = 8 / scale
        let qx = (dev.x * q).rounded(.down) / q
        let qy = (dev.y * q).rounded(.down) / q
        let ix = qx.rounded(.down)
        let iy = qy.rounded(.down)
        let phaseX = Int(((qx - ix) * 4).rounded())
        let phaseY = qy - iy
        if phaseY == 0 {
            // Common case (label baselines land on whole device pixels):
            // CG-smoothed rendering via the fitted per-phase kernels.
            if let bmp = gf.rasterizeSmoothed(glyph: g,
                                              devicePixelSize: font.pointSize * scale,
                                              phaseX: phaseX) {
                canvas.drawMask(bmp.mask, width: bmp.width, height: bmp.height,
                                atPixelX: Int(ix) + bmp.offsetX,
                                pixelY: Int(iy) + bmp.offsetY,
                                color: color)
                return
            }
        }
        guard let bmp = gf.rasterize(glyph: g, pixelSize: font.pointSize * scale,
                                     shiftX: qx - ix, shiftY: phaseY) else { return }
        canvas.drawMask(bmp.mask, width: bmp.width, height: bmp.height,
                        atPixelX: Int(ix) + bmp.offsetX,
                        pixelY: Int(iy) + bmp.offsetY,
                        color: color)
    }
}

extension String {
    /// Newlines become spaces when surplus text is pulled onto one line.
    func replacingNewlines() -> String {
        var out = ""
        out.reserveCapacity(count)
        for c in self { out.append(c == "\n" ? " " : c) }
        return out
    }
}
