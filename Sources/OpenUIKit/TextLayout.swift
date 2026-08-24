// TextLayout. Owner: text module.
//
// Line breaking / truncation matching real UIKit label behavior:
// - Word wrap breaks at spaces; a word longer than the wrap width is
//   character-wrapped.
// - A line that breaks at a space KEEPS that trailing space, and — as in
//   real UIKit (verified against golden label_multiline) — the trailing
//   space IS included in the measured line width for sizeThatFits. The last
//   laid-out line is measured without a trailing break space.
// - numberOfLines caps the line count; the surplus text collapses onto the
//   last line (truncated with U+2026 when drawn).

public enum TextLayout {

    public struct Line {
        /// Text drawn for this line (no trailing break space).
        public var text: Substring
        /// Width used for sizeThatFits (includes the trailing break space).
        public var measuredWidth: CGFloat
        /// Width of `text` only — used for alignment when drawing.
        public var drawWidth: CGFloat
    }

    static let ellipsis: Unicode.Scalar = Unicode.Scalar(0x2026)!

    /// Greedy word wrap of `text` at `maxWidth` points.
    /// `maxLines` <= 0 means unlimited. When the cap is hit, the final line
    /// contains the remainder of its wrapped content only (UIKit measures the
    /// capped label that way; drawing applies tail truncation separately).
    public static func wrap(_ text: String, font: UIFont, maxWidth: CGFloat,
                            maxLines: Int) -> [Line] {
        var lines: [Line] = []
        let unlimited = maxLines <= 0
        for para in text.split(separator: "\n", omittingEmptySubsequences: false) {
            var rest = para
            while !rest.isEmpty {
                if !unlimited && lines.count == maxLines { return lines }
                let isLastAllowed = !unlimited && lines.count == maxLines - 1
                let (line, remainder) = breakLine(rest, font: font, maxWidth: maxWidth)
                if isLastAllowed && !remainder.isEmpty {
                    // Capped: this is the final line; measure without the
                    // trailing break space.
                    lines.append(Line(text: line,
                                      measuredWidth: FontEngine.measure(String(line), font: font),
                                      drawWidth: FontEngine.measure(String(line), font: font)))
                    return lines
                }
                let drawW = FontEngine.measure(String(line), font: font)
                var measured = drawW
                if !remainder.isEmpty {
                    // The break space stays on this line and counts.
                    let withSpace = String(line) + " "
                    measured = FontEngine.measure(withSpace, font: font)
                }
                lines.append(Line(text: line, measuredWidth: measured, drawWidth: drawW))
                rest = remainder
            }
            if para.isEmpty {
                lines.append(Line(text: para, measuredWidth: 0, drawWidth: 0))
            }
            if !unlimited && lines.count >= maxLines { return lines }
        }
        return lines
    }

    /// Break one line off the front of `s`; returns (line, remainder).
    /// The break space (if any) is consumed and belongs to neither.
    static func breakLine(_ s: Substring, font: UIFont, maxWidth: CGFloat)
        -> (Substring, Substring) {
        let eps: CGFloat = 1e-6
        var lineEnd = s.startIndex        // end of the last fitting candidate
        var searched = s.startIndex       // scan position
        var any = false
        while searched < s.endIndex {
            // Extend candidate to the end of the next word.
            var wordEnd = searched
            while wordEnd < s.endIndex && s[wordEnd] != " " { wordEnd = s.index(after: wordEnd) }
            let cand = s[s.startIndex..<wordEnd]
            if FontEngine.measure(String(cand), font: font) <= maxWidth + eps {
                any = true
                lineEnd = wordEnd
                if wordEnd == s.endIndex { return (cand, s[s.endIndex...]) }
                searched = s.index(after: wordEnd) // skip the space
            } else if !any && lineEnd == s.startIndex {
                // First word alone does not fit: character-wrap it.
                var end = s.startIndex
                var fitEnd = s.startIndex
                while end < wordEnd {
                    let next = s.index(after: end)
                    if FontEngine.measure(String(s[s.startIndex..<next]), font: font) <= maxWidth + eps {
                        fitEnd = next
                        end = next
                    } else { break }
                }
                if fitEnd == s.startIndex {
                    // Not even one character fits; force one to guarantee progress.
                    fitEnd = s.index(after: s.startIndex)
                }
                return (s[s.startIndex..<fitEnd], s[fitEnd...])
            } else {
                break
            }
        }
        // Remainder starts after the break space.
        var remStart = lineEnd
        if remStart < s.endIndex && s[remStart] == " " { remStart = s.index(after: remStart) }
        return (s[s.startIndex..<lineEnd], s[remStart...])
    }

    /// Truncate a single line to `maxWidth` with the given mode, returning the
    /// string to draw (with U+2026 inserted for the truncating modes).
    public static func truncate(_ text: String, font: UIFont, maxWidth: CGFloat,
                                mode: NSLineBreakMode) -> String {
        let eps: CGFloat = 1e-6
        if FontEngine.measure(text, font: font) <= maxWidth + eps { return text }
        let ell = String(Character(ellipsis))
        let ellW = FontEngine.measure(ell, font: font)
        let scalars = Array(text.unicodeScalars)
        func width(_ slice: ArraySlice<Unicode.Scalar>) -> CGFloat {
            var s = ""
            s.unicodeScalars.append(contentsOf: slice)
            return FontEngine.measure(s, font: font)
        }
        switch mode {
        case .byClipping, .byWordWrapping, .byCharWrapping:
            return text  // drawn clipped by the caller
        case .byTruncatingTail:
            var n = scalars.count - 1
            while n > 0 && width(scalars[0..<n]) + ellW > maxWidth + eps { n -= 1 }
            var out = ""
            out.unicodeScalars.append(contentsOf: scalars[0..<n])
            // UIKit drops a bare trailing space before the ellipsis.
            while out.hasSuffix(" ") { out.removeLast() }
            return out + ell
        case .byTruncatingHead:
            var start = 1
            while start < scalars.count && ellW + width(scalars[start...]) > maxWidth + eps { start += 1 }
            var out = ell
            out.unicodeScalars.append(contentsOf: scalars[start...])
            return out
        case .byTruncatingMiddle:
            // Keep a balanced head and tail.
            var head = 0, tail = 0
            var takeHead = true
            while head + tail < scalars.count {
                let h = takeHead ? head + 1 : head
                let t = takeHead ? tail : tail + 1
                if h + t >= scalars.count { break }
                let w = width(scalars[0..<h]) + ellW + width(scalars[(scalars.count - t)...])
                if w > maxWidth + eps { break }
                head = h; tail = t
                takeHead.toggle()
            }
            var out = ""
            out.unicodeScalars.append(contentsOf: scalars[0..<head])
            out += ell
            out.unicodeScalars.append(contentsOf: scalars[(scalars.count - tail)...])
            return out
        }
    }
}
