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
        struct DrawLine { var text: String; var width: CGFloat }
        var drawLines: [DrawLine] = []
        var needsClip = false
        if numberOfLines == 1 {
            let full = FontEngine.measure(text, font: font)
            if full <= bounds.width + 1e-6 {
                drawLines = [DrawLine(text: text, width: full)]
            } else {
                let t = TextLayout.truncate(text, font: font, maxWidth: bounds.width,
                                            mode: lineBreakMode)
                let w = FontEngine.measure(t, font: font)
                drawLines = [DrawLine(text: t, width: w)]
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
                    drawLines.append(DrawLine(text: t, width: FontEngine.measure(t, font: font)))
                } else {
                    drawLines.append(DrawLine(text: String(l.text), width: l.drawWidth))
                }
            }
        }
        guard !drawLines.isEmpty else { return }

        let blockH = CGFloat(drawLines.count) * lineH
        if blockH > bounds.height + 1e-6 { needsClip = true }
        if needsClip { canvas.save(); canvas.clip(to: bounds) }
        defer { if needsClip { canvas.restore() } }

        // Vertical centering of the text block, block origin snapped to pixels.
        let y0 = FontEngine.roundToPixel((bounds.height - blockH) / 2, scale: scale)
        let baselineInLine = FontEngine.roundToPixel(metrics.ascender, scale: scale)
        let color = textColor.resolvedCGColor(with: traitCollection)
        guard color.alpha > 0 else { return }
        let glyphFont = GlyphRasterizer.font(for: font)

        for (i, line) in drawLines.enumerated() {
            var penX: CGFloat
            switch textAlignment {
            case .left, .natural, .justified:
                penX = 0
            case .center:
                penX = FontEngine.roundToPixel((bounds.width - line.width) / 2, scale: scale)
            case .right:
                penX = bounds.width - line.width
            }
            let baselineY = y0 + CGFloat(i) * lineH + baselineInLine
            drawLineGlyphs(line.text, at: CGPoint(x: penX, y: baselineY),
                           in: canvas, color: color, glyphFont: glyphFont)
        }
    }

    private func drawLineGlyphs(_ line: String, at origin: CGPoint, in canvas: Canvas,
                                color: CGColor, glyphFont: GlyphFont?) {
        guard let gf = glyphFont else { return }
        let scale = canvas.scale
        var penX = origin.x
        var prev: Unicode.Scalar? = nil
        for ch in line.unicodeScalars {
            if let p = prev { penX += FontEngine.kerning(p, ch, font: font) }
            prev = ch
            let adv = FontEngine.advance(of: ch, font: font)
            defer { penX += adv }
            if ch == " " { continue }
            let g = gf.glyphIndex(of: ch)
            if g == 0 { continue }
            // Device-space pen position (CTM maps view points → device px).
            let dev = CGPoint(x: penX, y: origin.y).applying(canvas.ctm)
            let ix = dev.x.rounded(.down)
            let shift = dev.x - ix
            let iy = dev.y.rounded(.toNearestOrAwayFromZero)
            guard let bmp = gf.rasterize(glyph: g, pixelSize: font.pointSize * scale,
                                         shiftX: shift) else { continue }
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
