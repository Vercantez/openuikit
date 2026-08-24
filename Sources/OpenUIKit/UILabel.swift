// UILabel. Owner: text module.
// sizeThatFits / intrinsicContentSize / line breaking / truncation /
// alignment match real UIKit (validated against golden/label_*).

public enum NSTextAlignment: Sendable {
    case left, center, right, justified, natural
}

public enum NSLineBreakMode: Sendable {
    case byWordWrapping, byCharWrapping, byClipping
    case byTruncatingHead, byTruncatingTail, byTruncatingMiddle
}

open class UILabel: UIView {
    public var text: String? { didSet { setNeedsLayout() } }
    public var font: UIFont = .systemFont(ofSize: 17)
    public var textColor: UIColor = .label
    public var textAlignment: NSTextAlignment = .natural
    public var numberOfLines: Int = 1
    public var lineBreakMode: NSLineBreakMode = .byTruncatingTail

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        // UIKit: labels do not receive touches by default.
        isUserInteractionEnabled = false
    }

    var layoutScale: CGFloat {
        let s = traitCollection.displayScale
        return s > 0 ? s : 2
    }

    /// Single-line label height (real UIKit rounding; see FontEngine).
    var lineBoxHeight: CGFloat { FontEngine.labelLineHeight(for: font) }

    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        guard let text, !text.isEmpty else { return .zero }
        let scale = layoutScale
        let lineH = lineBoxHeight
        // Single-line labels ignore the constraint entirely (real UIKit:
        // sizeThatFits of a 1-line label reports the full text width).
        if numberOfLines == 1 {
            let w = FontEngine.ceilToPixel(FontEngine.measure(text, font: font), scale: scale)
            return CGSize(width: w, height: lineH)
        }
        let unbounded = !(size.width > 0) || size.width >= CGFloat.greatestFiniteMagnitude / 2
        if unbounded {
            let w = FontEngine.ceilToPixel(FontEngine.measure(text, font: font), scale: scale)
            return CGSize(width: w, height: lineH)
        }
        let lines = TextLayout.wrap(text, font: font, maxWidth: size.width,
                                    maxLines: numberOfLines)
        guard !lines.isEmpty else { return .zero }
        var maxW: CGFloat = 0
        for l in lines { maxW = Swift.max(maxW, l.measuredWidth) }
        return CGSize(width: FontEngine.ceilToPixel(maxW, scale: scale),
                      height: CGFloat(lines.count) * lineH)
    }

    open override var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize(width: .greatestFiniteMagnitude, height: .greatestFiniteMagnitude))
    }

    // MARK: - Drawing

    open override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard let text, !text.isEmpty else { return }
        let scale = canvas.scale
        let lineH = lineBoxHeight
        let metrics = FontEngine.metrics(for: font)

        // Lay out lines for drawing.
        struct DrawLine { var text: String; var width: CGFloat; var delta: CGFloat }
        var drawLines: [DrawLine] = []
        var needsClip = false
        func measureWith(_ s: String, delta: CGFloat) -> CGFloat {
            FontEngine.measure(s, font: font) + delta * CGFloat(s.unicodeScalars.count)
        }
        if numberOfLines == 1 {
            let full = FontEngine.measure(text, font: font)
            if full <= bounds.width + 1e-6 {
                drawLines = [DrawLine(text: text, width: full, delta: 0)]
            } else {
                let t = TextLayout.truncate(text, font: font, maxWidth: bounds.width,
                                            mode: lineBreakMode)
                let w = measureWith(t.text, delta: t.delta)
                drawLines = [DrawLine(text: t.text, width: w, delta: t.delta)]
                needsClip = w > bounds.width + 1e-6
            }
        } else {
            let wrapped = TextLayout.wrap(text, font: font, maxWidth: bounds.width,
                                          maxLines: numberOfLines)
            for (i, l) in wrapped.enumerated() {
                if i == wrapped.count - 1, l.text.endIndex < text.endIndex {
                    // Text remains beyond the last line: tail-truncate the
                    // remainder into it (what UIKit draws for a capped label).
                    let remainder = String(text[l.text.startIndex...]).replacingNewlines()
                    let t = TextLayout.truncate(remainder, font: font,
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
        let blockH = CGFloat(drawLines.count) * lineH
        canvas.save()
        canvas.clip(to: bounds)
        defer { canvas.restore() }

        // Vertical layout (validated against Catalyst pixel probes):
        // the text block is centered with the offset rounded HALF-UP to
        // whole POINTS, and the first baseline sits at the ascender
        // rounded half-up to whole points below the block origin.
        let y0 = ((bounds.height - blockH) / 2 + 0.5).rounded(.down)
        let baselineInLine = (metrics.ascender + 0.5).rounded(.down)
        let color = textColor.resolvedCGColor(with: traitCollection)
        guard color.alpha > 0 else { return }
        let glyphFont = GlyphRasterizer.font(for: font)

        for (i, line) in drawLines.enumerated() {
            var penX: CGFloat
            switch textAlignment {
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
            let baselineY = y0 + CGFloat(i) * lineH + baselineInLine
            drawLineGlyphs(line.text, at: CGPoint(x: penX, y: baselineY),
                           in: canvas, color: color, glyphFont: glyphFont,
                           extraAdvance: line.delta)
        }
    }

    private func drawLineGlyphs(_ line: String, at origin: CGPoint, in canvas: Canvas,
                                color: CGColor, glyphFont: InstancedGlyphFont?,
                                extraAdvance: CGFloat = 0) {
        let scale = canvas.scale
        // Harvested-ink fast path: exact real-UIKit glyph masks, valid for
        // scale-2 translation-only canvases and integer point sizes (see
        // GlyphInkTable). Falls through per-glyph when a mask is missing.
        let ctm = canvas.ctm
        let inkEligible = GlyphInkTable.isAvailable && scale == 2
            && ctm.a == 2 && ctm.b == 0 && ctm.c == 0 && ctm.d == 2
            && font.pointSize == font.pointSize.rounded(.down)
        let famKey = FontEngine.familyKey(for: font)
        let sizeKey = Int(font.pointSize)
        let dark = traitCollection.userInterfaceStyle == .dark
        // Device-pixel anchor of the text-space origin (x: pen 0).
        let devOX = Int((ctm.tx).rounded())
        let devBaseY = Int((origin.y * 2 + ctm.ty).rounded())

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
            if ch == " " { continue }
            if inkEligible {
                let penFloor = penX.rounded(.down)
                let frac = penX - penFloor
                let (tag, anchor) = GlyphInkTable.phase(size: font.pointSize, frac: frac)
                if let m = GlyphInkTable.maskLinear(familyKey: famKey, sizeKey: sizeKey,
                                                    dark: dark, tag: tag, scalar: ch) {
                    canvas.drawMask(m.mask, width: m.width, height: m.height,
                                    atPixelX: devOX + 2 * Int(penFloor) + anchor + m.ox,
                                    pixelY: devBaseY + m.oy,
                                    color: color,
                                    blendGamma: GlyphInkTable.blendGamma,
                                    darkCalibration: dark)
                    continue
                }
            }
            guard let gf = glyphFont else { continue }
            let g = gf.glyphIndex(of: ch)
            if g == 0 { continue }
            // CoreText quantizes each glyph's pen position to quarter POINTS
            // with a +1/16pt bias (measured from Catalyst UILabel renders:
            // pos = floor(4x + 0.25)/4 in points), then CoreGraphics
            // quantizes the device-space origin to quarter device pixels
            // (floor). With integer view offsets and scale 2 the CT step
            // dominates; both are modeled here.
            let penQ = (penX * 4 + 0.25).rounded(.down) / 4
            let dev = CGPoint(x: penQ, y: origin.y).applying(canvas.ctm)
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
                    continue
                }
            }
            guard let bmp = gf.rasterize(glyph: g, pixelSize: font.pointSize * scale,
                                         shiftX: qx - ix, shiftY: phaseY) else { continue }
            canvas.drawMask(bmp.mask, width: bmp.width, height: bmp.height,
                            atPixelX: Int(ix) + bmp.offsetX,
                            pixelY: Int(iy) + bmp.offsetY,
                            color: color)
        }
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
