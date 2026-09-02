// AttributedTextLayout. Owner: text module (M12 — attributed text).
//
// Measurement, line breaking and drawing of an NSAttributedString, matching
// real UIKit. Every rule below was measured against Mac Catalyst UIKit
// (Tools/attrprobe/ methodology, results recorded in
// docs/KNOWN_GAPS.md "Attributed text"):
//
// WIDTH
//   width = Σ advance(c) + Σ pairKerning + Σ kern(c)
//   - the `.kern` attribute is added to EVERY character of its run,
//     including the last one (so "A" with kern 2 measures A + 2);
//   - `.kern == 0` explicitly present DISABLES the font's pair kerning for
//     that character (CoreText's documented behavior, verified: "AVATAR" is
//     61.974 pt naturally, 66.954 pt with kern 0);
//   - a pair whose two characters use DIFFERENT fonts is never kerned
//     (verified: A@17 + V@24 measures exactly the sum of the two runs);
//   - pair kerning DOES apply across a run boundary when both sides share a
//     font and neither disabled kerning.
//
// LINE BOX
//   per run:  A = floor(ascender + 0.5)                    (UILabel's rule)
//             D = FontEngine.labelLineHeight - A
//   ascent  = max over the line's runs of (A + max(0,  bo))
//   descent = max over the line's runs of (D + max(0, -bo))
//   height  = ascent + descent
//   A run's glyphs sit on `ascent - run.baselineOffset` below the box top.
//   Verified against every attrtext_* golden height plus a Catalyst sweep of
//   baselineOffset sets {0}, {+3}, {-3}, {+3,-3}, {+2,-5}, {0,+4} and mixed
//   font sizes 8...40 against 17.
//
// PARAGRAPH STYLE
//   height *= lineHeightMultiple (when non-zero), then clamped by
//   minimum/maximumLineHeight, then ceiled to the device pixel grid;
//   lineSpacing is added between line boxes (n-1 gaps), paragraphSpacing
//   after a hard break and paragraphSpacingBefore before every paragraph
//   but the first. Head/tail indents shrink each line's wrap width.

enum AttributedTextLayout {

    // MARK: - Flattened representation

    /// A maximal span of characters sharing every attribute we render.
    struct Style {
        var font: UIFont = .systemFont(ofSize: 17)
        var color: UIColor? = nil
        var backgroundColor: UIColor? = nil
        var kern: CGFloat = 0
        /// `.kern` was present (0 then means "kerning off", not "no kern").
        var kernSet: Bool = false
        var baselineOffset: CGFloat = 0
        var underline: NSUnderlineStyle = []
        var underlineColor: UIColor? = nil
        var strikethrough: NSUnderlineStyle = []
        var strikethroughColor: UIColor? = nil
    }

    /// Character-indexed view of an attributed string (unicode scalars, the
    /// unit the glyph pipeline works in).
    struct Text {
        var scalars: [Unicode.Scalar] = []
        /// Style index per scalar.
        var styleOf: [Int] = []
        var styles: [Style] = []
        var paragraph: NSParagraphStyle = .default
        /// UITextView lays lines out on the FONT's line height, not the
        /// (sometimes 1 pt taller) UILabel line box — see FontEngine
        /// .labelLineHeight. Set by UITextView so its attributed path stays
        /// identical to its plain path for a single-font string.
        var usesFontLineHeight = false

        var count: Int { scalars.count }
        func style(_ i: Int) -> Style { styles[styleOf[i]] }
    }

    /// Flatten `s`; `defaultFont` / `defaultColor` fill in runs that carry
    /// no `.font` / `.foregroundColor` (UILabel supplies its own).
    static func flatten(_ s: NSAttributedString, defaultFont: UIFont,
                        defaultColor: UIColor) -> Text {
        var out = Text()
        var styleCache: [Int] = []       // run index -> style index
        var runStart = 0
        let str = s.string
        var scalarUTF16: [Int] = []      // utf16 offset per scalar
        var off = 0
        for sc in str.unicodeScalars {
            out.scalars.append(sc)
            scalarUTF16.append(off)
            off += sc.value > 0xFFFF ? 2 : 1
        }
        // Build one Style per run.
        var runRanges: [(Int, Int)] = []
        for r in s.runs {
            runRanges.append((runStart, runStart + r.length))
            var st = Style()
            st.font = (r.attributes[.font] as? UIFont) ?? defaultFont
            st.color = (r.attributes[.foregroundColor] as? UIColor) ?? defaultColor
            st.backgroundColor = r.attributes[.backgroundColor] as? UIColor
            if let k = numberValue(r.attributes[.kern]) {
                st.kern = k
                st.kernSet = true
            } else if let t = numberValue(r.attributes[.tracking]) {
                st.kern = t
                st.kernSet = true
            }
            if let b = numberValue(r.attributes[.baselineOffset]) { st.baselineOffset = b }
            if let u = intValue(r.attributes[.underlineStyle]) {
                st.underline = NSUnderlineStyle(rawValue: u)
            }
            st.underlineColor = r.attributes[.underlineColor] as? UIColor
            if let u = intValue(r.attributes[.strikethroughStyle]) {
                st.strikethrough = NSUnderlineStyle(rawValue: u)
            }
            st.strikethroughColor = r.attributes[.strikethroughColor] as? UIColor
            out.styles.append(st)
            styleCache.append(out.styles.count - 1)
            runStart += r.length
        }
        if out.styles.isEmpty {
            var st = Style()
            st.font = defaultFont
            st.color = defaultColor
            out.styles.append(st)
            runRanges = [(0, Int.max)]
            styleCache = [0]
        }
        // Map each scalar to its run.
        out.styleOf = [Int](repeating: 0, count: out.scalars.count)
        var ri = 0
        for i in 0..<out.scalars.count {
            let u = scalarUTF16[i]
            while ri + 1 < runRanges.count && u >= runRanges[ri].1 { ri += 1 }
            out.styleOf[i] = styleCache[Swift.min(ri, styleCache.count - 1)]
        }
        if let ps = s.length > 0
            ? (s.attributes(at: 0, effectiveRange: nil)[.paragraphStyle] as? NSParagraphStyle)
            : nil {
            out.paragraph = ps
        }
        return out
    }

    static func numberValue(_ v: Any?) -> CGFloat? {
        if let d = v as? CGFloat { return d }
        if let d = v as? Double { return CGFloat(d) }
        if let i = v as? Int { return CGFloat(i) }
        if let f = v as? Float { return CGFloat(f) }
        return nil
    }
    static func intValue(_ v: Any?) -> Int? {
        if let i = v as? Int { return i }
        if let s = v as? NSUnderlineStyle { return s.rawValue }
        if let d = v as? Double { return Int(d) }
        return nil
    }

    // MARK: - Measurement

    /// Advance of scalar `i` including its run's `.kern`.
    static func advance(_ t: Text, _ i: Int) -> CGFloat {
        let st = t.style(i)
        return FontEngine.advance(of: t.scalars[i], font: st.font) + st.kern
    }

    /// Pair kerning between scalars `i` and `i+1`.
    static func kerning(_ t: Text, _ i: Int) -> CGFloat {
        guard i + 1 < t.count else { return 0 }
        let a = t.style(i), b = t.style(i + 1)
        if a.kernSet && a.kern == 0 { return 0 }
        if b.kernSet && b.kern == 0 { return 0 }
        guard a.font == b.font else { return 0 }
        return FontEngine.kerning(t.scalars[i], t.scalars[i + 1], font: a.font)
    }

    /// Width of scalars `[from, to)`.
    static func width(_ t: Text, from: Int, to: Int) -> CGFloat {
        guard to > from else { return 0 }
        var w: CGFloat = 0
        for i in from..<to {
            w += advance(t, i)
            if i + 1 < to { w += kerning(t, i) }
        }
        return w
    }

    // MARK: - Lines

    struct Line {
        /// Scalar range drawn on this line (excludes the break space).
        var range: Range<Int>
        /// Width used by sizeThatFits (includes a trailing break space).
        var measuredWidth: CGFloat
        /// Width of `range` only — used for alignment.
        var drawWidth: CGFloat
        var height: CGFloat
        var ascent: CGFloat
        /// Left inset from the paragraph style.
        var indent: CGFloat
        /// Width available to this line after both indents.
        var available: CGFloat
        /// Extra space added below this line (lineSpacing / paragraphSpacing).
        var spacingBelow: CGFloat
    }

    /// Natural (pre-paragraph-style) metrics of the scalars in `range`.
    ///
    /// Per run: A = floor(ascender + 0.5) (UILabel's integral baseline) and
    /// D = labelLineHeight − A. A run raised by `bo` pushes the line's ascent
    /// to A + bo; a run lowered pushes the descent to D + |bo|. The line box
    /// is the max of each side — verified against every golden height in the
    /// attrtext_* fixtures plus the Catalyst probe sweep (single- and
    /// multi-run, positive/negative/mixed offsets, mixed sizes).
    static func lineMetrics(_ t: Text, _ range: Range<Int>) -> (height: CGFloat, ascent: CGFloat) {
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var seen = false
        var indices = Array(range)
        if indices.isEmpty, range.lowerBound < t.count {
            indices = [range.lowerBound]     // empty line: use the style there
        }
        if indices.isEmpty && t.count > 0 { indices = [t.count - 1] }
        for i in indices {
            let st = t.style(Swift.min(i, t.count - 1))
            let a = (FontEngine.metrics(for: st.font).ascender + 0.5).rounded(.down)
            let box = t.usesFontLineHeight
                ? FontEngine.metrics(for: st.font).lineHeight
                : FontEngine.labelLineHeight(for: st.font)
            let d = box - a
            let bo = st.baselineOffset
            ascent = Swift.max(seen ? ascent : 0, a + Swift.max(0, bo))
            descent = Swift.max(seen ? descent : 0, d + Swift.max(0, -bo))
            seen = true
        }
        guard seen else { return (0, 0) }
        return (ascent + descent, ascent)
    }

    /// Apply the paragraph style's height rules to a natural line box.
    static func styledHeight(_ natural: CGFloat, _ p: NSParagraphStyle,
                             scale: CGFloat) -> CGFloat {
        var h = natural
        if p.lineHeightMultiple > 0 { h *= p.lineHeightMultiple }
        if p.minimumLineHeight > 0 { h = Swift.max(h, p.minimumLineHeight) }
        if p.maximumLineHeight > 0 { h = Swift.min(h, p.maximumLineHeight) }
        return FontEngine.ceilToPixel(h, scale: scale)
    }

    /// Greedy word wrap. `maxLines <= 0` is unlimited; when the cap is hit
    /// the last line holds only its own wrapped content (UILabel measures a
    /// capped label that way — drawing tail-truncates separately).
    static func wrap(_ t: Text, maxWidth: CGFloat, maxLines: Int,
                     scale: CGFloat) -> [Line] {
        let p = t.paragraph
        let unlimited = maxLines <= 0
        var lines: [Line] = []
        var i = 0
        var isFirstLineOfParagraph = true

        func indentFor(_ first: Bool) -> CGFloat {
            first ? p.firstLineHeadIndent : p.headIndent
        }
        func availableFor(_ indent: CGFloat) -> CGFloat {
            let right = p.tailIndent > 0 ? p.tailIndent : maxWidth + p.tailIndent
            return Swift.max(1, right - indent)
        }

        while i <= t.count {
            if !unlimited && lines.count == maxLines { break }
            let indent = indentFor(isFirstLineOfParagraph)
            let available = availableFor(indent)
            let isLastAllowed = !unlimited && lines.count == maxLines - 1
            let (lineEnd, next, hardBreak) = breakLine(t, from: i, maxWidth: available)
            let range = i..<lineEnd
            let (natH, asc) = lineMetrics(t, range)
            let h = styledHeight(natH, p, scale: scale)
            let extraAscent = h - natH
            let drawW = width(t, from: i, to: lineEnd)
            var measured = drawW
            // The break space stays on the line and counts toward the measured
            // width — except on the LAST line a capped label will lay out
            // (real UIKit measures that one without it; same rule as the
            // plain TextLayout path).
            if !hardBreak && next < t.count && next > lineEnd && !isLastAllowed {
                measured = width(t, from: i, to: next)
            }
            var spacing: CGFloat = 0
            if hardBreak { spacing += p.paragraphSpacing + p.paragraphSpacingBefore }
            lines.append(Line(range: range,
                              measuredWidth: indent + measured,
                              drawWidth: drawW,
                              height: h,
                              ascent: asc + Swift.max(0, extraAscent),
                              indent: indent,
                              available: available,
                              spacingBelow: spacing))
            if next > t.count || (next == i && lineEnd == i && !hardBreak) { break }
            isFirstLineOfParagraph = hardBreak
            i = next
            // A trailing newline leaves one more (empty) line to lay out; any
            // other exhaustion ends the loop.
            if i >= t.count, !(hardBreak && i == t.count) { break }
        }
        // lineSpacing separates line boxes (n-1 gaps).
        if p.lineSpacing != 0 {
            for k in 0..<Swift.max(0, lines.count - 1) {
                lines[k].spacingBelow += p.lineSpacing
            }
        }
        return lines
    }

    /// Break one line starting at `from`; returns (end of drawn text,
    /// start of the next line, whether the break was a hard newline).
    static func breakLine(_ t: Text, from: Int, maxWidth: CGFloat)
        -> (end: Int, next: Int, hardBreak: Bool) {
        let eps: CGFloat = 1e-6
        // Hard break first.
        var hardEnd = t.count
        var k = from
        while k < t.count {
            if t.scalars[k] == "\n" { hardEnd = k; break }
            k += 1
        }
        let limit = hardEnd
        if from >= limit {
            return (from, limit < t.count ? limit + 1 : t.count, limit < t.count)
        }
        var lineEnd = from
        var searched = from
        var any = false
        while searched < limit {
            var wordEnd = searched
            while wordEnd < limit && t.scalars[wordEnd] != " " { wordEnd += 1 }
            if width(t, from: from, to: wordEnd) <= maxWidth + eps {
                any = true
                lineEnd = wordEnd
                if wordEnd == limit {
                    return (limit, limit < t.count ? limit + 1 : t.count, limit < t.count)
                }
                searched = wordEnd + 1
            } else if !any && lineEnd == from {
                // First word alone does not fit: character-wrap it.
                var fitEnd = from
                var end = from
                while end < wordEnd {
                    if width(t, from: from, to: end + 1) <= maxWidth + eps {
                        fitEnd = end + 1
                        end += 1
                    } else { break }
                }
                if fitEnd == from { fitEnd = from + 1 }
                return (fitEnd, fitEnd, false)
            } else {
                break
            }
        }
        var next = lineEnd
        if next < limit && t.scalars[next] == " " { next += 1 }
        return (lineEnd, next, false)
    }

    /// Total block size for `lines`.
    static func blockSize(_ lines: [Line], scale: CGFloat) -> CGSize {
        var w: CGFloat = 0
        var h: CGFloat = 0
        for (i, l) in lines.enumerated() {
            w = Swift.max(w, l.measuredWidth)
            h += l.height
            if i < lines.count - 1 { h += l.spacingBelow }
        }
        return CGSize(width: FontEngine.ceilToPixel(w, scale: scale), height: h)
    }
}
