// NSAttributedString. Owner: text module (M12 — attributed text).
//
// PORTABLE REIMPLEMENTATION, NOT A BRIDGE. OpenUIKit imports no Foundation
// (docs/PORTABILITY.md), so `NSAttributedString`, `NSMutableAttributedString`,
// `NSRange` and `NSAttributedString.Key` are declared HERE and SHADOW
// Foundation's types of the same name. An app that imports both OpenUIKit and
// Foundation must disambiguate (`OpenUIKit.NSAttributedString`) — the
// tradeoff is written up in docs/KNOWN_GAPS.md.
//
// Storage model: the backing `string` plus a run list. Run lengths — and
// every public offset/range — are in UTF-16 code units, exactly like
// Foundation's `NSRange`, so `length`, `attributes(at:effectiveRange:)` and
// friends agree with real UIKit for any string an app hands us.
//
// Runs are always normalized: no empty runs, and adjacent runs never carry
// equal attribute dictionaries (Foundation coalesces the same way, which is
// what `effectiveRange` reports).

// `NSRange`, `NSRangePointer` and `NSMakeRange` used to be declared here.
// They are Foundation's now (M15) — see FoundationTypes.swift. The storage
// model below is unchanged: run lengths and every public offset are UTF-16
// code units, which is exactly what Foundation's NSRange means.

// MARK: - Underline / strikethrough style

public struct NSUnderlineStyle: OptionSet, Hashable, Sendable {
    public let rawValue: Int
    public init(rawValue: Int) { self.rawValue = rawValue }

    public static let single = NSUnderlineStyle(rawValue: 0x01)
    public static let thick = NSUnderlineStyle(rawValue: 0x02)
    public static let double = NSUnderlineStyle(rawValue: 0x09)
    public static let patternSolid: NSUnderlineStyle = []
    public static let patternDot = NSUnderlineStyle(rawValue: 0x0100)
    public static let patternDash = NSUnderlineStyle(rawValue: 0x0200)
    public static let patternDashDot = NSUnderlineStyle(rawValue: 0x0300)
    public static let patternDashDotDot = NSUnderlineStyle(rawValue: 0x0400)
    public static let byWord = NSUnderlineStyle(rawValue: 0x8000)
}

// MARK: - NSAttributedString

open class NSAttributedString {

    public struct Key: Hashable, RawRepresentable, Sendable, ExpressibleByStringLiteral {
        public let rawValue: String
        public init(rawValue: String) { self.rawValue = rawValue }
        public init(_ rawValue: String) { self.rawValue = rawValue }
        public init(stringLiteral value: String) { self.rawValue = value }

        /// `UIFont`.
        public static let font = Key("NSFont")
        /// `UIColor`.
        public static let foregroundColor = Key("NSColor")
        /// `UIColor` filling the run's line-box rect.
        public static let backgroundColor = Key("NSBackgroundColor")
        /// `NSParagraphStyle`.
        public static let paragraphStyle = Key("NSParagraphStyle")
        /// `CGFloat` — points added to every character's advance. A value of
        /// 0 DISABLES the font's pair kerning (real CoreText semantics,
        /// measured; see AttributedTextLayout).
        public static let kern = Key("NSKern")
        /// `Int` (`NSUnderlineStyle.rawValue`).
        public static let underlineStyle = Key("NSUnderline")
        /// `UIColor`; defaults to the run's foreground color.
        public static let underlineColor = Key("NSUnderlineColor")
        /// `Int` (`NSUnderlineStyle.rawValue`).
        public static let strikethroughStyle = Key("NSStrikethrough")
        /// `UIColor`; defaults to the run's foreground color.
        public static let strikethroughColor = Key("NSStrikethroughColor")
        /// `CGFloat` — points the run's glyphs are raised above the baseline.
        public static let baselineOffset = Key("NSBaselineOffset")
        /// `UIColor` (stroke color; stroking itself is not implemented).
        public static let strokeColor = Key("NSStrokeColor")
        /// `CGFloat` (stroke width; stroking itself is not implemented).
        public static let strokeWidth = Key("NSStrokeWidth")
        /// Any value; carried through untouched (link handling is app-side).
        public static let link = Key("NSLink")
        /// `CGFloat` — points of extra tracking, an alias apps sometimes use.
        public static let tracking = Key("NSTracking")
    }

    /// One maximal span of equal attributes. `length` is in UTF-16 units.
    struct Run {
        var length: Int
        var attributes: [Key: Any]
    }

    public internal(set) var string: String
    var runs: [Run]

    /// Length in UTF-16 code units (Foundation semantics).
    public var length: Int { string.utf16.count }

    public init(string: String, attributes: [Key: Any]? = nil) {
        self.string = string
        let n = string.utf16.count
        self.runs = n > 0 ? [Run(length: n, attributes: attributes ?? [:])] : []
    }

    public convenience init(string: String) {
        self.init(string: string, attributes: nil)
    }

    public init(attributedString: NSAttributedString) {
        self.string = attributedString.string
        self.runs = attributedString.runs
    }

    init(string: String, runs: [Run]) {
        self.string = string
        self.runs = runs
    }

    // MARK: Attribute lookup

    /// Index of the run containing `location`, plus that run's start offset.
    func runIndex(at location: Int) -> (index: Int, start: Int)? {
        guard location >= 0 else { return nil }
        var start = 0
        for (i, r) in runs.enumerated() {
            if location < start + r.length { return (i, start) }
            start += r.length
        }
        return nil
    }

    open func attributes(at location: Int,
                         effectiveRange range: NSRangePointer?) -> [Key: Any] {
        guard let (i, start) = runIndex(at: location) else {
            range?.pointee = NSRange(location: location, length: 0)
            return [:]
        }
        range?.pointee = NSRange(location: start, length: runs[i].length)
        return runs[i].attributes
    }

    open func attribute(_ key: Key, at location: Int,
                        effectiveRange range: NSRangePointer?) -> Any? {
        attributes(at: location, effectiveRange: range)[key]
    }

    /// Longest range around `location` (clipped to `rangeLimit`) over which
    /// `key`'s value does not change. Foundation's `longestEffectiveRange`
    /// variant, restricted to the equality test we can do without `NSObject`
    /// identity: values are compared with `attributeValuesEqual`.
    open func attribute(_ key: Key, at location: Int,
                        longestEffectiveRange range: NSRangePointer?,
                        in rangeLimit: NSRange) -> Any? {
        guard let (i, start) = runIndex(at: location) else {
            range?.pointee = NSRange(location: location, length: 0)
            return nil
        }
        let value = runs[i].attributes[key]
        var lo = start, hi = start + runs[i].length
        var j = i
        var s = start
        while j > 0 {
            s -= runs[j - 1].length
            guard attributeValuesEqual(runs[j - 1].attributes[key], value) else { break }
            lo = s
            j -= 1
        }
        j = i
        var e = start + runs[i].length
        while j + 1 < runs.count {
            guard attributeValuesEqual(runs[j + 1].attributes[key], value) else { break }
            e += runs[j + 1].length
            hi = e
            j += 1
        }
        lo = Swift.max(lo, rangeLimit.location)
        hi = Swift.min(hi, rangeLimit.upperBound)
        range?.pointee = NSRange(location: lo, length: Swift.max(0, hi - lo))
        return value
    }

    // MARK: Enumeration

    /// Calls `block` once per maximal run of equal `key` values in `range`.
    /// `stop` set to true ends the enumeration (Foundation semantics).
    open func enumerateAttribute(_ key: Key, in range: NSRange,
                                 using block: (Any?, NSRange, inout Bool) -> Void) {
        var stop = false
        var start = 0
        var i = 0
        while i < runs.count {
            let runStart = start
            let value = runs[i].attributes[key]
            var end = runStart + runs[i].length
            var j = i + 1
            while j < runs.count, attributeValuesEqual(runs[j].attributes[key], value) {
                end += runs[j].length
                j += 1
            }
            let lo = Swift.max(runStart, range.location)
            let hi = Swift.min(end, range.upperBound)
            if hi > lo {
                block(value, NSRange(location: lo, length: hi - lo), &stop)
                if stop { return }
            }
            start = end
            i = j
            if start >= range.upperBound { return }
        }
    }

    open func enumerateAttributes(in range: NSRange,
                                  using block: ([Key: Any], NSRange, inout Bool) -> Void) {
        var stop = false
        var start = 0
        for r in runs {
            let lo = Swift.max(start, range.location)
            let hi = Swift.min(start + r.length, range.upperBound)
            if hi > lo {
                block(r.attributes, NSRange(location: lo, length: hi - lo), &stop)
                if stop { return }
            }
            start += r.length
            if start >= range.upperBound { return }
        }
    }

    // MARK: Substrings

    open func attributedSubstring(from range: NSRange) -> NSAttributedString {
        let (sub, subRuns) = slice(range)
        return NSAttributedString(string: sub, runs: subRuns)
    }

    func slice(_ range: NSRange) -> (String, [Run]) {
        let n = length
        let lo = Swift.max(0, Swift.min(range.location, n))
        let hi = Swift.max(lo, Swift.min(range.upperBound, n))
        guard hi > lo else { return ("", []) }
        let a = String.Index(utf16Offset: lo, in: string)
        let b = String.Index(utf16Offset: hi, in: string)
        var out: [Run] = []
        var start = 0
        for r in runs {
            let s = Swift.max(start, lo), e = Swift.min(start + r.length, hi)
            if e > s { out.append(Run(length: e - s, attributes: r.attributes)) }
            start += r.length
            if start >= hi { break }
        }
        return (String(string[a..<b]), out)
    }

    /// Structural equality (string + per-character attribute dictionaries).
    open func isEqual(to other: NSAttributedString) -> Bool {
        guard string == other.string, runs.count == other.runs.count else { return false }
        for (a, b) in zip(runs, other.runs) {
            guard a.length == b.length, attributeDictionariesEqual(a.attributes, b.attributes)
            else { return false }
        }
        return true
    }

    /// Whole-string range, the argument apps write most often.
    public var fullRange: NSRange { NSRange(location: 0, length: length) }

    // MARK: Normalization

    static func normalized(_ runs: [Run]) -> [Run] {
        var out: [Run] = []
        for r in runs {
            guard r.length > 0 else { continue }
            if var last = out.last,
               attributeDictionariesEqual(last.attributes, r.attributes) {
                last.length += r.length
                out[out.count - 1] = last
            } else {
                out.append(r)
            }
        }
        return out
    }
}

// MARK: - NSMutableAttributedString

open class NSMutableAttributedString: NSAttributedString {

    public override init(string: String, attributes: [Key: Any]? = nil) {
        super.init(string: string, attributes: attributes)
    }
    public override init(attributedString: NSAttributedString) {
        super.init(attributedString: attributedString)
    }
    public convenience init() { self.init(string: "", attributes: nil) }

    open func addAttribute(_ key: Key, value: Any, range: NSRange) {
        addAttributes([key: value], range: range)
    }

    open func addAttributes(_ attrs: [Key: Any], range: NSRange) {
        editAttributes(range) { d in
            for (k, v) in attrs { d[k] = v }
        }
    }

    open func setAttributes(_ attrs: [Key: Any]?, range: NSRange) {
        editAttributes(range) { d in d = attrs ?? [:] }
    }

    open func removeAttribute(_ key: Key, range: NSRange) {
        editAttributes(range) { d in d[key] = nil }
    }

    private func editAttributes(_ range: NSRange, _ edit: (inout [Key: Any]) -> Void) {
        let n = length
        let lo = Swift.max(0, Swift.min(range.location, n))
        let hi = Swift.max(lo, Swift.min(range.upperBound, n))
        guard hi > lo else { return }
        var out: [Run] = []
        var start = 0
        for r in runs {
            let end = start + r.length
            let s = Swift.max(start, lo), e = Swift.min(end, hi)
            if e <= s {
                out.append(r)
            } else {
                if s > start { out.append(Run(length: s - start, attributes: r.attributes)) }
                var d = r.attributes
                edit(&d)
                out.append(Run(length: e - s, attributes: d))
                if end > e { out.append(Run(length: end - e, attributes: r.attributes)) }
            }
            start = end
        }
        runs = NSAttributedString.normalized(out)
    }

    open func append(_ attrString: NSAttributedString) {
        replaceCharacters(in: NSRange(location: length, length: 0), with: attrString)
    }

    open func insert(_ attrString: NSAttributedString, at loc: Int) {
        replaceCharacters(in: NSRange(location: loc, length: 0), with: attrString)
    }

    open func deleteCharacters(in range: NSRange) {
        replaceCharacters(in: range, with: NSAttributedString(string: "", attributes: nil))
    }

    open func replaceCharacters(in range: NSRange, with str: String) {
        // Foundation keeps the attributes of the first replaced character
        // (or of the character before the insertion point).
        let attrs = attributesForReplacement(at: range)
        replaceCharacters(in: range,
                          with: NSAttributedString(string: str, attributes: attrs))
    }

    open func replaceCharacters(in range: NSRange, with attrString: NSAttributedString) {
        let n = length
        let lo = Swift.max(0, Swift.min(range.location, n))
        let hi = Swift.max(lo, Swift.min(range.upperBound, n))
        let (headStr, headRuns) = slice(NSRange(location: 0, length: lo))
        let (tailStr, tailRuns) = slice(NSRange(location: hi, length: n - hi))
        string = headStr + attrString.string + tailStr
        runs = NSAttributedString.normalized(headRuns + attrString.runs + tailRuns)
    }

    private func attributesForReplacement(at range: NSRange) -> [Key: Any]? {
        let n = length
        guard n > 0 else { return nil }
        if range.length > 0, range.location < n {
            return attributes(at: range.location, effectiveRange: nil)
        }
        if range.location > 0 {
            return attributes(at: Swift.min(range.location - 1, n - 1), effectiveRange: nil)
        }
        return nil
    }

    /// Foundation exposes `mutableString`; the portable stand-in is the
    /// plain backing string (no live-editing proxy).
    open var mutableString: String {
        get { string }
        set { replaceCharacters(in: fullRange, with: newValue) }
    }
}

// MARK: - Attribute value comparison
//
// Attribute values are `Any` (Foundation's shape). Without `NSObject` we
// compare the concrete types the text engine understands; anything else is
// treated as "not equal" so runs never merge across values we cannot
// inspect (conservative — it only costs an extra run).

func attributeValuesEqual(_ a: Any?, _ b: Any?) -> Bool {
    switch (a, b) {
    case (nil, nil): return true
    case (nil, _), (_, nil): return false
    default: break
    }
    if let x = a as? UIFont, let y = b as? UIFont { return x == y }
    if let x = a as? UIColor, let y = b as? UIColor { return x == y }
    if let x = a as? CGFloat, let y = b as? CGFloat { return x == y }
    if let x = a as? Double, let y = b as? Double { return x == y }
    if let x = a as? Int, let y = b as? Int { return x == y }
    if let x = a as? String, let y = b as? String { return x == y }
    if let x = a as? Bool, let y = b as? Bool { return x == y }
    if let x = a as? NSParagraphStyle, let y = b as? NSParagraphStyle { return x == y }
    return false
}

func attributeDictionariesEqual(_ a: [NSAttributedString.Key: Any],
                                _ b: [NSAttributedString.Key: Any]) -> Bool {
    guard a.count == b.count else { return false }
    for (k, v) in a {
        guard let w = b[k], attributeValuesEqual(v, w) else { return false }
    }
    return true
}
