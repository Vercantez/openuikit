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

    /// Result of truncating a single line. `tight` = the drawn line uses
    /// tight tracking (UIKit condenses truncated lines with the font's
    /// tight trak track); `delta` = the per-glyph advance adjustment to
    /// apply when drawing (0 for natural lines).
    public struct Truncated {
        public var text: String
        public var delta: CGFloat
    }

    /// Truncate a single line to `maxWidth` with the given mode, matching
    /// real UIKit (validated against Catalyst threshold sweeps at 17pt):
    /// - The available width is floor(maxWidth) in points.
    /// - Candidate widths are measured at TIGHT tracking (advance + dTight
    ///   per glyph, spaces included, kerning kept).
    /// - The ellipsis contributes a decision width slightly smaller than
    ///   its drawn advance (FontEngine.ellipsisDecisionWidth).
    /// - If the whole text fits at tight tracking, UIKit draws it squeezed
    ///   to exactly the available width instead of truncating.
    public static func truncate(_ text: String, font: UIFont, maxWidth: CGFloat,
                                mode: NSLineBreakMode) -> Truncated {
        let eps: CGFloat = 1e-6
        let natural = FontEngine.measure(text, font: font)
        if natural <= maxWidth + eps { return Truncated(text: text, delta: 0) }
        switch mode {
        case .byClipping, .byWordWrapping, .byCharWrapping:
            return Truncated(text: text, delta: 0)  // drawn clipped by the caller
        default:
            break
        }
        let B = maxWidth.rounded(.down)
        let d = FontEngine.tightDelta(for: font)
        let scalars = Array(text.unicodeScalars)
        let n = scalars.count
        func str(_ slice: ArraySlice<Unicode.Scalar>) -> String {
            var s = ""
            s.unicodeScalars.append(contentsOf: slice)
            return s
        }
        func tightW(_ s: String) -> CGFloat { FontEngine.measureTight(s, font: font) }

        // Whole text fits when tightened: squeeze to exactly B, no ellipsis.
        let tightFull = tightW(text)
        if tightFull <= B + eps {
            let delta = n > 0 ? (B - natural) / CGFloat(n) : 0
            return Truncated(text: text, delta: Swift.max(delta, d))
        }

        let ell = String(Character(ellipsis))
        let ellTail = FontEngine.ellipsisDecisionWidth(for: font, head: false)
        let ellHead = FontEngine.ellipsisDecisionWidth(for: font, head: true)

        switch mode {
        case .byTruncatingTail:
            var kept = 0
            for k in stride(from: n - 1, through: 1, by: -1) {
                var s = str(scalars[0..<k])
                while s.hasSuffix(" ") { s.removeLast() }
                if tightW(s) + ellTail <= B + eps { kept = k; break }
            }
            var out = str(scalars[0..<kept])
            while out.hasSuffix(" ") { out.removeLast() }
            return Truncated(text: out + ell, delta: d)
        case .byTruncatingHead:
            var kept = 0
            for k in stride(from: n - 1, through: 1, by: -1) {
                var s = str(scalars[(n - k)...])
                while s.hasPrefix(" ") { s.removeFirst() }
                if ellHead + tightW(s) <= B + eps { kept = k; break }
            }
            var out = str(scalars[(n - kept)...])
            while out.hasPrefix(" ") { out.removeFirst() }
            return Truncated(text: ell + out, delta: d)
        case .byTruncatingMiddle:
            // Head: largest prefix whose tight width + half the ellipsis
            // fits in half the available width (unstripped). Tail: largest
            // suffix fitting the remainder.
            var head = 0
            for h in stride(from: n - 1, through: 0, by: -1) {
                if tightW(str(scalars[0..<h])) + ellTail / 2 <= B / 2 + eps { head = h; break }
            }
            let headW = tightW(str(scalars[0..<head]))
            var tail = 0
            for t in stride(from: n - head - 1, through: 0, by: -1) {
                if headW + ellTail + tightW(str(scalars[(n - t)...])) <= B + eps { tail = t; break }
            }
            var pre = str(scalars[0..<head])
            while pre.hasSuffix(" ") { pre.removeLast() }
            var suf = str(scalars[(n - tail)...])
            while suf.hasPrefix(" ") { suf.removeFirst() }
            return Truncated(text: pre + ell + suf, delta: d)
        default:
            return Truncated(text: text, delta: 0)
        }
    }
}
