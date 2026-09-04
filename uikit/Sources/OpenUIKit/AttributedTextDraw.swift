// AttributedTextDraw. Owner: text module (M12 — attributed text).
//
// Draws the lines produced by AttributedTextLayout: per-run glyphs (each with
// its own font, color, kern and baseline offset), run background fills, and
// underline / strikethrough rules.
//
// Rules are pixel-aligned rects whose geometry comes from the vendored
// oracle table (FontEngine.decorations). Real UIKit runs them through the
// same 3-tap smoothing filter CG applies to glyphs — an edge row lands at
// exactly 31/255 of the plateau in every probe, i.e. a separable
// [k, 1-2k, k] kernel with k = 31/255 — so the rule is drawn as a blurred
// coverage mask rather than a hard fill.

extension AttributedTextLayout {

    /// CG's text-smoothing tap weight, read straight off the oracle renders
    /// (a 2 px rule profiles as 31, 224, 224, 31 on white).
    static let smoothingTap: CGFloat = 31.0 / 255.0

    struct DrawContext {
        var canvas: Canvas
        var traits: UITraitCollection
        var bounds: CGRect
        var alignment: NSTextAlignment
    }

    /// Draw `lines` of `t` inside `ctx.bounds`, block-centered vertically the
    /// way UILabel centers plain text (offset rounded half-up to whole
    /// points).
    static func draw(_ t: Text, lines: [Line], in ctx: DrawContext) {
        guard !lines.isEmpty else { return }
        let bounds = ctx.bounds
        var blockH: CGFloat = 0
        for (i, l) in lines.enumerated() {
            blockH += l.height
            if i < lines.count - 1 { blockH += l.spacingBelow }
        }
        var y0 = bounds.minY + ((bounds.height - blockH) / 2 + 0.5).rounded(.down)
        if GlyphInkTable.usesIOSTable {
            // iOS (MEASURED 2026-09-04, attrtext_paragraph's centred 15 pt
            // label on the 2x device): the block is its raw height rounded
            // UP to the device pixel (2 x 17.9 + 3 = 38.8 -> 39) and centred
            // exactly — line ink at 137.0 where Catalyst's whole-point
            // rounding puts it at 137.5.
            let bh = FontEngine.ceilToPixel(blockH, scale: ctx.canvas.scale)
            y0 = bounds.minY + (bounds.height - bh) / 2
        }
        let dark = ctx.traits.userInterfaceStyle == .dark

        var boxTop = y0
        for line in lines {
            drawLine(t, line, boxTop: boxTop, in: ctx, dark: dark)
            boxTop += line.height + line.spacingBelow
        }
    }

    static func drawLine(_ t: Text, _ line: Line, boxTop: CGFloat,
                         in ctx: DrawContext, dark: Bool) {
        let canvas = ctx.canvas
        let alignment = ctx.alignment
        var penX = ctx.bounds.minX + line.indent
        switch alignment {
        case .left, .natural, .justified:
            break
        case .center:
            penX += (line.available - line.drawWidth) / 2
        case .right:
            penX += line.available - line.drawWidth
        }
        let baseBaseline = boxTop + line.ascent

        // Split the line into style runs, remembering each run's x extent so
        // backgrounds and rules can be drawn per run.
        var i = line.range.lowerBound
        let end = line.range.upperBound
        var x = penX
        while i < end {
            let s = t.styleOf[i]
            var j = i
            while j < end && t.styleOf[j] == s { j += 1 }
            let runStart = x
            // Advance through the run, drawing glyphs.
            let st = t.styles[s]
            let baselineY = baseBaseline - st.baselineOffset
            let color = (st.color ?? .label).resolvedCGColor(with: ctx.traits)
            let glyphFont = GlyphRasterizer.font(for: st.font)
            let cm = canvas.ctm
            let inkEligible = GlyphInkTable.isAvailable
                && (canvas.scale == 2 || GlyphInkTable.hasIOSTable(scale: canvas.scale))
                && cm.a == canvas.scale && cm.b == 0 && cm.c == 0 && cm.d == canvas.scale
                && st.font.pointSize == st.font.pointSize.rounded(.down)
            let famKey = FontEngine.familyKey(for: st.font)
            let sizeKey = Int(st.font.pointSize)
            let devOX = Int(cm.tx.rounded())
            let devBaseY = Int((baselineY * canvas.scale + cm.ty).rounded())

            // Background fills the line box behind the run.
            if let bg = st.backgroundColor {
                var w: CGFloat = 0
                for k in i..<j {
                    w += advance(t, k)
                    if k + 1 < j { w += kerning(t, k) }
                }
                canvas.fill(rect: CGRect(x: runStart, y: boxTop, width: w, height: line.height),
                            color: bg.resolvedCGColor(with: ctx.traits))
            }

            var k = i
            while k < j {
                let ch = t.scalars[k]
                if ch != " " && ch != "\n" && color.alpha > 0 {
                    UILabel.drawGlyph(ch, penX: x, baselineY: baselineY, in: canvas,
                                      font: st.font, dark: dark, color: color,
                                      glyphFont: glyphFont, inkEligible: inkEligible,
                                      famKey: famKey, sizeKey: sizeKey,
                                      devOX: devOX, devBaseY: devBaseY)
                }
                x += advance(t, k)
                if k + 1 < end { x += kerning(t, k) }
                k += 1
            }

            // Decorations span the run's advance width. Real UIKit drops the
            // rule under LINE-FINAL whitespace (measured), but keeps it under
            // interior spaces.
            var ruleEnd = j
            if j == end {
                while ruleEnd > i && t.scalars[ruleEnd - 1] == " " { ruleEnd -= 1 }
            }
            if ruleEnd > i, !st.underline.isEmpty || !st.strikethrough.isEmpty {
                var w: CGFloat = 0
                for m in i..<ruleEnd {
                    w += advance(t, m)
                    if m + 1 < ruleEnd { w += kerning(t, m) }
                }
                let dec = FontEngine.decorations(for: st.font)
                if !st.underline.isEmpty {
                    let c = (st.underlineColor ?? st.color ?? .label)
                        .resolvedCGColor(with: ctx.traits)
                    fillRule(canvas, x: runStart, y: baselineY + dec.underlineTop,
                             width: w, height: dec.underlineThickness, color: c)
                }
                if !st.strikethrough.isEmpty {
                    let c = (st.strikethroughColor ?? st.color ?? .label)
                        .resolvedCGColor(with: ctx.traits)
                    fillRule(canvas, x: runStart, y: baselineY + dec.strikeTop,
                             width: w, height: dec.strikeThickness, color: c)
                }
            }
            i = j
        }
    }

    /// Fill a decoration rect through a smoothed coverage mask so the edges
    /// match CG's text filter (see `smoothingTap`).
    static func fillRule(_ canvas: Canvas, x: CGFloat, y: CGFloat,
                         width: CGFloat, height: CGFloat, color: CGColor) {
        guard width > 0, height > 0, color.alpha > 0 else { return }
        let ctm = canvas.ctm
        guard ctm.b == 0, ctm.c == 0, ctm.a > 0, ctm.d > 0 else {
            canvas.fill(rect: CGRect(x: x, y: y, width: width, height: height), color: color)
            return
        }
        let x0 = x * ctm.a + ctm.tx
        let x1 = (x + width) * ctm.a + ctm.tx
        let y0 = y * ctm.d + ctm.ty
        let y1 = (y + height) * ctm.d + ctm.ty
        if OpenUIKitRuntime.systemFontCut == .iOS {
            // iOS 26.1 (MEASURED, attrtext_underline_strike on the 2x
            // device): rules are HARD device-pixel rectangles — the 17 pt
            // underline is exactly two device rows of solid colour, the
            // strikethrough likewise — where Catalyst's are blurred by the
            // text filter. Snap the top edge to the pixel grid and keep the
            // thickness a whole number of pixels (at least one).
            let sy0 = y0.rounded(.toNearestOrAwayFromZero)
            let sy1 = Swift.max(sy0 + 1, y1.rounded(.toNearestOrAwayFromZero))
            let ux0 = (x0 - ctm.tx) / ctm.a, ux1 = (x1 - ctm.tx) / ctm.a
            let uy0 = (sy0 - ctm.ty) / ctm.d, uy1 = (sy1 - ctm.ty) / ctm.d
            canvas.fill(rect: CGRect(x: ux0, y: uy0, width: ux1 - ux0, height: uy1 - uy0), color: color)
            return
        }
        let px0 = Int(x0.rounded(.down)) - 1
        let px1 = Int(x1.rounded(.up)) + 1
        let py0 = Int(y0.rounded(.down)) - 1
        let py1 = Int(y1.rounded(.up)) + 1
        let w = px1 - px0, h = py1 - py0
        guard w > 0, h > 0, w * h < 1 << 22 else { return }
        // Exact-area coverage of the rect, then a separable 3-tap blur.
        var cov = Array<CGFloat>(repeating: 0, count: w * h)
        for row in 0..<h {
            let ry0 = CGFloat(py0 + row), ry1 = ry0 + 1
            let cy = Swift.max(0, Swift.min(y1, ry1) - Swift.max(y0, ry0))
            if cy <= 0 { continue }
            for col in 0..<w {
                let rx0 = CGFloat(px0 + col), rx1 = rx0 + 1
                let cx = Swift.max(0, Swift.min(x1, rx1) - Swift.max(x0, rx0))
                if cx > 0 { cov[row * w + col] = cx * cy }
            }
        }
        let k = smoothingTap
        let mid = 1 - 2 * k
        var tmp = Array<CGFloat>(repeating: 0, count: w * h)
        for row in 0..<h {
            for col in 0..<w {
                let l = col > 0 ? cov[row * w + col - 1] : 0
                let r = col + 1 < w ? cov[row * w + col + 1] : 0
                tmp[row * w + col] = k * l + mid * cov[row * w + col] + k * r
            }
        }
        var mask = [UInt8](repeating: 0, count: w * h)
        for row in 0..<h {
            for col in 0..<w {
                let a = row > 0 ? tmp[(row - 1) * w + col] : 0
                let b = row + 1 < h ? tmp[(row + 1) * w + col] : 0
                let v = k * a + mid * tmp[row * w + col] + k * b
                mask[row * w + col] = UInt8(Swift.max(0, Swift.min(255, (v * 255).rounded())))
            }
        }
        canvas.drawMask(mask, width: w, height: h, atPixelX: px0, pixelY: py0, color: color)
    }
}
