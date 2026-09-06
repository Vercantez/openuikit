// NSLayoutManager. Owner: text module (TextKit-1).
//
// Glyph / line-fragment / bounding-rect queries over AttributedTextLayout
// results. `UITextView.layoutManager` is one of these. Glyph index equals
// UTF-16 index for BMP text (attachments are U+FFFC, one unit).
//
// Attachment geometry MEASURED iPhone SE 2x / iOS 26.1, attach_probe
// UITextView path 7 (24×24 default) and path 11 (bounds.origin.y = −24):
//   usedRect height 28.101 / 40.187
//   firstGlyph location.y = 24 / 16.187 (baseline)
//   attachment location = (16.023, 24) / (25.304, 40.187)
//   glyphRect height = the full line-fragment height

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#endif

public protocol NSLayoutManagerDelegate: AnyObject {
    func layoutManager(_ layoutManager: NSLayoutManager,
                       didCompleteLayoutFor textContainer: NSTextContainer?,
                       atEnd layoutFinishedFlag: Bool)
    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldGenerateGlyphs glyphs: UnsafePointer<UInt16>?,
                       properties props: UnsafePointer<Int>?,
                       characterIndexes charIndexes: UnsafePointer<Int>?,
                       font aFont: UIFont?,
                       forGlyphRange glyphRange: NSRange) -> Int
    func layoutManager(_ layoutManager: NSLayoutManager,
                       lineSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat
    func layoutManager(_ layoutManager: NSLayoutManager,
                       paragraphSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat
    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool
}

public extension NSLayoutManagerDelegate {
    func layoutManager(_ layoutManager: NSLayoutManager,
                       didCompleteLayoutFor textContainer: NSTextContainer?,
                       atEnd layoutFinishedFlag: Bool) {}
    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldGenerateGlyphs glyphs: UnsafePointer<UInt16>?,
                       properties props: UnsafePointer<Int>?,
                       characterIndexes charIndexes: UnsafePointer<Int>?,
                       font aFont: UIFont?,
                       forGlyphRange glyphRange: NSRange) -> Int { 0 }
    func layoutManager(_ layoutManager: NSLayoutManager,
                       lineSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat { 0 }
    func layoutManager(_ layoutManager: NSLayoutManager,
                       paragraphSpacingAfterGlyphAt glyphIndex: Int,
                       withProposedLineFragmentRect rect: CGRect) -> CGFloat { 0 }
    func layoutManager(_ layoutManager: NSLayoutManager,
                       shouldBreakLineByWordBeforeCharacterAt charIndex: Int) -> Bool { true }
}

open class NSLayoutManager: NSObject {

    public struct LineFragment {
        var glyphRange: NSRange
        var fragment: CGRect
        var used: CGRect
        var baseline: CGFloat
        var ascent: CGFloat
    }

    open weak var delegate: NSLayoutManagerDelegate?
    open private(set) weak var textStorage: NSTextStorage?

    private var _textContainers: [NSTextContainer] = []
    open var textContainers: [NSTextContainer] { _textContainers }

    private var fragments: [LineFragment] = []
    private var glyphXs: [CGFloat] = []
    private var valid = false
    private var _usedRect = CGRect(x: 0, y: 0, width: 0, height: 0)
    var layoutText: AttributedTextLayout.Text?
    var layoutLines: [AttributedTextLayout.Line] = []

    public override init() {
        super.init()
    }

    func bindTextStorage(_ storage: NSTextStorage?) {
        textStorage = storage
        valid = false
    }

    open func addTextContainer(_ container: NSTextContainer) {
        if _textContainers.contains(where: { $0 === container }) { return }
        _textContainers.append(container)
        container.layoutManager = self
        valid = false
    }

    open func removeTextContainer(at index: Int) {
        guard index >= 0, index < _textContainers.count else { return }
        _textContainers[index].layoutManager = nil
        _textContainers.remove(at: index)
        valid = false
    }

    open func invalidateLayout(forCharacterRange charRange: NSRange,
                               actualCharacterRange actualRange: NSRangePointer?) {
        valid = false
        actualRange?.pointee = charRange
    }

    open func invalidateDisplay(forCharacterRange charRange: NSRange) {
        valid = false
    }

    func invalidateContainer() {
        valid = false
    }

    open var numberOfGlyphs: Int {
        ensureLayout()
        return glyphXs.count
    }

    open func glyphRange(for container: NSTextContainer) -> NSRange {
        ensureLayout()
        return NSRange(location: 0, length: glyphXs.count)
    }

    open func glyphIndexForCharacter(at charIndex: Int) -> Int {
        ensureLayout()
        if glyphXs.isEmpty { return 0 }
        return Swift.max(0, Swift.min(charIndex, glyphXs.count - 1))
    }

    open func characterIndexForGlyph(at glyphIndex: Int) -> Int {
        glyphIndexForCharacter(at: glyphIndex)
    }

    open func usedRect(for container: NSTextContainer) -> CGRect {
        ensureLayout()
        return _usedRect
    }

    open func lineFragmentRect(forGlyphAt glyphIndex: Int,
                               effectiveRange: NSRangePointer?) -> CGRect {
        ensureLayout()
        guard let frag = fragment(containing: glyphIndex) else {
            effectiveRange?.pointee = NSRange(location: 0, length: 0)
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        effectiveRange?.pointee = frag.glyphRange
        return frag.fragment
    }

    open func lineFragmentUsedRect(forGlyphAt glyphIndex: Int,
                                   effectiveRange: NSRangePointer?) -> CGRect {
        ensureLayout()
        guard let frag = fragment(containing: glyphIndex) else {
            effectiveRange?.pointee = NSRange(location: 0, length: 0)
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        effectiveRange?.pointee = frag.glyphRange
        return frag.used
    }

    /// MEASURED attach_probe UITextView path 7: first glyph (5, 24) —
    /// x = lineFragmentPadding, y = baseline in the fragment. Attachment
    /// at char 1 is (16.023, 24). Path 11 (origin.y = −24): text glyph
    /// y = 16.187 (ascender), attachment y = 40.187 (fragment height).
    open func location(forGlyphAt glyphIndex: Int) -> CGPoint {
        ensureLayout()
        guard glyphIndex >= 0, glyphIndex < glyphXs.count else {
            return CGPoint(x: 0, y: 0)
        }
        let x = glyphXs[glyphIndex]
        guard let frag = fragment(containing: glyphIndex) else {
            return CGPoint(x: x, y: 0)
        }
        if isAttachmentGlyph(glyphIndex) {
            // Sitting-on-baseline (origin.y ≥ 0): location.y is the baseline.
            // Hanging below (origin.y < 0): location.y is the fragment bottom
            // (the UIKit y of the attachment's CoreText origin).
            if let b = attachmentBounds(atUTF16: glyphIndex), b.origin.y < 0 {
                return CGPoint(x: x, y: frag.fragment.height)
            }
            return CGPoint(x: x, y: frag.baseline)
        }
        return CGPoint(x: x, y: frag.baseline)
    }

    open func boundingRect(forGlyphRange glyphRange: NSRange,
                           in container: NSTextContainer) -> CGRect {
        ensureLayout()
        guard glyphRange.length > 0, !fragments.isEmpty else {
            return CGRect(x: 0, y: 0, width: 0, height: 0)
        }
        var union: CGRect?
        let end = glyphRange.location + glyphRange.length
        for g in glyphRange.location..<end {
            guard let frag = fragment(containing: g), g < glyphXs.count else { continue }
            let x = glyphXs[g]
            var w: CGFloat = 0
            if g + 1 < glyphXs.count, g + 1 < frag.glyphRange.location + frag.glyphRange.length {
                w = glyphXs[g + 1] - x
            } else {
                w = frag.used.maxX - x
            }
            if isAttachmentGlyph(g) {
                w = attachmentBounds(atUTF16: g)?.width ?? w
            }
            let r = CGRect(x: x, y: frag.fragment.minY, width: Swift.max(0, w),
                           height: frag.fragment.height)
            union = union.map { $0.union(r) } ?? r
        }
        return union ?? CGRect(x: 0, y: 0, width: 0, height: 0)
    }

    open func enumerateLineFragments(
        forGlyphRange glyphRange: NSRange,
        using block: (CGRect, CGRect, UnsafeMutablePointer<CGFloat>?, NSRange, UnsafeMutablePointer<Bool>) -> Void
    ) {
        ensureLayout()
        var stop = false
        for frag in fragments {
            if stop { return }
            let lo = Swift.max(frag.glyphRange.location, glyphRange.location)
            let hi = Swift.min(frag.glyphRange.location + frag.glyphRange.length,
                               glyphRange.location + glyphRange.length)
            if hi <= lo { continue }
            var baseline = frag.baseline
            block(frag.fragment, frag.used, &baseline,
                  NSRange(location: lo, length: hi - lo), &stop)
        }
    }

    open func characterIndex(for point: CGPoint, in container: NSTextContainer,
                             fractionOfDistanceBetweenInsertionPoints fraction: UnsafeMutablePointer<CGFloat>?) -> Int {
        ensureLayout()
        fraction?.pointee = 0
        guard !fragments.isEmpty else { return 0 }
        var chosen = fragments[0]
        for frag in fragments {
            if point.y < frag.fragment.maxY {
                chosen = frag
                break
            }
            chosen = frag
        }
        let lo = chosen.glyphRange.location
        let hi = lo + chosen.glyphRange.length
        if hi <= lo { return lo }
        var i = lo
        while i < hi {
            let x0 = i < glyphXs.count ? glyphXs[i] : chosen.used.maxX
            let x1: CGFloat
            if i + 1 < hi, i + 1 < glyphXs.count {
                x1 = glyphXs[i + 1]
            } else {
                x1 = chosen.used.maxX
            }
            if point.x < (x0 + x1) / 2 {
                let span = x1 - x0
                if span > 0 { fraction?.pointee = Swift.max(0, Swift.min(1, (point.x - x0) / span)) }
                return i
            }
            i += 1
        }
        return hi
    }

    open func glyphIndex(for point: CGPoint, in container: NSTextContainer) -> Int {
        var frac: CGFloat = 0
        return characterIndex(for: point, in: container,
                              fractionOfDistanceBetweenInsertionPoints: &frac)
    }

    open func drawGlyphs(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        // UITextView draws through AttributedTextLayout; this entry point
        // exists so app code that calls it compiles.
    }

    open func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {}

    open func ensureLayout(forCharacterRange charRange: NSRange) {
        ensureLayout()
    }

    open func ensureLayout(for container: NSTextContainer) {
        ensureLayout()
    }

    // MARK: - Layout

    func ensureLayout() {
        if valid { return }
        rebuild()
        valid = true
        delegate?.layoutManager(self, didCompleteLayoutFor: _textContainers.first, atEnd: true)
    }

    private func rebuild() {
        fragments = []
        glyphXs = []
        layoutLines = []
        layoutText = nil
        _usedRect = CGRect(x: 0, y: 0, width: 0, height: 0)
        guard let storage = textStorage else { return }
        let container = _textContainers.first
        let padding = container?.lineFragmentPadding ?? 5
        let maxW = Swift.max(0, (container?.size.width ?? 0) - 2 * padding)
        let wrapW = maxW > 0 ? maxW : CGFloat.greatestFiniteMagnitude / 4
        let maxLines = container?.maximumNumberOfLines ?? 0
        var t = AttributedTextLayout.flatten(storage, defaultFont: .systemFont(ofSize: 12),
                                             defaultColor: .label)
        t.usesFontLineHeight = true
        layoutText = t
        let scale: CGFloat = 2
        let lines = AttributedTextLayout.wrap(t, maxWidth: wrapW, maxLines: maxLines, scale: scale)
        layoutLines = lines

        // Map UTF-16 index → glyph x. Our layout is scalar-indexed; for BMP
        // (including U+FFFC) that is 1:1 with UTF-16.
        let utf16Count = storage.length
        glyphXs = Array<CGFloat>(repeating: padding, count: utf16Count)
        var y: CGFloat = 0
        var utf16 = 0
        var scalar = 0
        let str = storage.string
        var maxUsedW: CGFloat = 0
        for line in lines {
            let fragH = line.height
            let baseline = line.ascent
            let frag = CGRect(x: 0, y: y, width: container?.size.width ?? (padding + line.measuredWidth + padding),
                              height: fragH)
            let used = CGRect(x: 0, y: y, width: padding + line.drawWidth, height: fragH)
            let glyphStart = utf16
            var x = padding + line.indent
            let endScalar = line.range.upperBound
            while scalar < endScalar, utf16 < utf16Count {
                if utf16 < glyphXs.count { glyphXs[utf16] = x }
                x += AttributedTextLayout.advance(t, scalar)
                if scalar + 1 < endScalar {
                    x += AttributedTextLayout.kerning(t, scalar)
                }
                let ch = str.unicodeScalars[str.unicodeScalars.index(str.unicodeScalars.startIndex, offsetBy: scalar)]
                utf16 += ch.value > 0xFFFF ? 2 : 1
                scalar += 1
            }
            let glyphEnd = utf16
            fragments.append(LineFragment(
                glyphRange: NSRange(location: glyphStart, length: Swift.max(0, glyphEnd - glyphStart)),
                fragment: frag, used: used, baseline: baseline, ascent: line.ascent))
            maxUsedW = Swift.max(maxUsedW, used.width)
            y += fragH + line.spacingBelow
        }
        // Trailing scalars (a final newline's empty line is already in `lines`).
        _usedRect = CGRect(x: 0, y: 0, width: maxUsedW, height: y)
    }

    private func fragment(containing glyphIndex: Int) -> LineFragment? {
        for f in fragments {
            if glyphIndex >= f.glyphRange.location
                && glyphIndex < f.glyphRange.location + f.glyphRange.length {
                return f
            }
        }
        return fragments.last
    }

    private func isAttachmentGlyph(_ glyphIndex: Int) -> Bool {
        guard let storage = textStorage, glyphIndex >= 0, glyphIndex < storage.length else {
            return false
        }
        return storage.attribute(.attachment, at: glyphIndex, effectiveRange: nil) != nil
    }

    private func attachmentBounds(atUTF16 i: Int) -> CGRect? {
        guard let storage = textStorage, i >= 0, i < storage.length,
              let att = storage.attribute(.attachment, at: i, effectiveRange: nil)
                as? NSTextAttachment else { return nil }
        return att.attachmentBounds(for: _textContainers.first,
                                    proposedLineFragment: CGRect(x: 0, y: 0, width: 0, height: 0),
                                    glyphPosition: CGPoint(x: 0, y: 0),
                                    characterIndex: i)
    }
}
