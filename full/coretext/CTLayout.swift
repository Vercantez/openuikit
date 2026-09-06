import CoreFoundation
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

struct _CTGlyphUnit {
    var scalar: UInt32
    var glyph: CGGlyph
    var advance: CGFloat
}

public final class CTTypesetter: Hashable, @unchecked Sendable {
    let string: NSAttributedString
    let breakWidth: CGFloat?

    init(string: NSAttributedString, breakWidth: CGFloat? = nil) {
        self.string = string
        self.breakWidth = breakWidth
    }

    public static func == (left: CTTypesetter, right: CTTypesetter) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTLine: Hashable, @unchecked Sendable {
    let string: NSAttributedString
    let range: NSRange
    let width: CGFloat
    let ascent: CGFloat
    let descent: CGFloat
    let leading: CGFloat
    let font: CTFont
    let units: [_CTGlyphUnit]

    init(
        string: NSAttributedString,
        range: NSRange,
        width: CGFloat,
        ascent: CGFloat,
        descent: CGFloat,
        leading: CGFloat,
        font: CTFont,
        units: [_CTGlyphUnit]
    ) {
        self.string = string
        self.range = range
        self.width = width
        self.ascent = ascent
        self.descent = descent
        self.leading = leading
        self.font = font
        self.units = units
    }

    public static func == (left: CTLine, right: CTLine) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTRun: Hashable, @unchecked Sendable {
    let line: CTLine
    let range: NSRange

    init(line: CTLine, range: NSRange) {
        self.line = line
        self.range = range
    }

    public static func == (left: CTRun, right: CTRun) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTFramesetter: Hashable, @unchecked Sendable {
    let typesetter: CTTypesetter

    init(typesetter: CTTypesetter) {
        self.typesetter = typesetter
    }

    public static func == (left: CTFramesetter, right: CTFramesetter) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTFrame: Hashable, @unchecked Sendable {
    let string: NSAttributedString
    let lines: [CTLine]
    let visibleRange: NSRange
    let pathBounds: CGRect
    let attributes: [String: Any]
    let path: CGPath

    init(
        string: NSAttributedString,
        lines: [CTLine],
        visibleRange: NSRange,
        pathBounds: CGRect,
        attributes: [String: Any],
        path: CGPath
    ) {
        self.string = string
        self.lines = lines
        self.visibleRange = visibleRange
        self.pathBounds = pathBounds
        self.attributes = attributes
        self.path = path
    }

    public static func == (left: CTFrame, right: CTFrame) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTParagraphStyle: Hashable, @unchecked Sendable {
    let alignment: CTTextAlignment
    let lineBreakMode: CTLineBreakMode
    let baseWritingDirection: CTWritingDirection
    let values: [CTParagraphStyleSpecifier: Data]

    init(
        alignment: CTTextAlignment,
        lineBreakMode: CTLineBreakMode,
        baseWritingDirection: CTWritingDirection,
        values: [CTParagraphStyleSpecifier: Data]
    ) {
        self.alignment = alignment
        self.lineBreakMode = lineBreakMode
        self.baseWritingDirection = baseWritingDirection
        self.values = values
    }

    public static func == (left: CTParagraphStyle, right: CTParagraphStyle) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTTextTab: Hashable, @unchecked Sendable {
    let alignment: CTTextAlignment
    let location: Double
    let options: CFDictionary?

    init(alignment: CTTextAlignment, location: Double, options: CFDictionary?) {
        self.alignment = alignment
        self.location = location
        self.options = options
    }

    public static func == (left: CTTextTab, right: CTTextTab) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTRubyAnnotation: Hashable, @unchecked Sendable {
    let alignment: CTRubyAlignment
    let overhang: CTRubyOverhang
    let sizeFactor: CGFloat
    let text: [CTRubyPosition: String]

    init(
        alignment: CTRubyAlignment,
        overhang: CTRubyOverhang,
        sizeFactor: CGFloat,
        text: [CTRubyPosition: String]
    ) {
        self.alignment = alignment
        self.overhang = overhang
        self.sizeFactor = sizeFactor
        self.text = text
    }

    public static func == (left: CTRubyAnnotation, right: CTRubyAnnotation) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTGlyphInfo: Hashable, @unchecked Sendable {
    let glyphName: String?
    let collection: CTCharacterCollection
    let characterIdentifier: CGFontIndex
    let baseString: String
    let glyph: CGGlyph

    init(
        glyphName: String?,
        collection: CTCharacterCollection,
        characterIdentifier: CGFontIndex,
        baseString: String,
        glyph: CGGlyph = 0
    ) {
        self.glyphName = glyphName
        self.collection = collection
        self.characterIdentifier = characterIdentifier
        self.baseString = baseString
        self.glyph = glyph
    }

    public static func == (left: CTGlyphInfo, right: CTGlyphInfo) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

public final class CTRunDelegate: Hashable, @unchecked Sendable {
    let callbacks: CTRunDelegateCallbacks
    let refCon: UnsafeMutableRawPointer?

    init(callbacks: CTRunDelegateCallbacks, refCon: UnsafeMutableRawPointer?) {
        self.callbacks = callbacks
        self.refCon = refCon
    }

    deinit {
        if let refCon {
            callbacks.dealloc(refCon)
        }
    }

    public static func == (left: CTRunDelegate, right: CTRunDelegate) -> Bool { left === right }
    public func hash(into hasher: inout Hasher) { hasher.combine(ObjectIdentifier(self)) }
}

private func _attrString(_ value: CFAttributedString) -> NSAttributedString {
    value as NSAttributedString
}

private func _fontFromAttributedString(_ string: NSAttributedString) -> CTFont {
    if string.length > 0 {
        let attrs = string.attributes(at: 0, effectiveRange: nil)
        if let font = attrs[NSAttributedString.Key(_ctString(kCTFontAttributeName))] as? CTFont {
            return font
        }
    }
    return CTFont(_ctCFString(_PortableMetrics.postScriptName), size: 12)
}

private func _advance(for font: CTFont) -> CGFloat {
    _ctCharAdvance(font, scalar: 65)
}

private func _units(in string: NSAttributedString, range: NSRange, font: CTFont) -> [_CTGlyphUnit] {
    let ns = string.string as NSString
    let substring = ns.substring(with: range)
    var units: [_CTGlyphUnit] = []
    units.reserveCapacity(substring.utf16.count)
    for scalar in substring.unicodeScalars {
        let glyph = _ctGlyphForCharacter(font, scalar.value)
        let advance = _ctCharAdvance(font, scalar: scalar.value)
        units.append(
            _CTGlyphUnit(
                scalar: scalar.value,
                glyph: glyph,
                advance: advance
            )
        )
    }
    return units
}

private func _width(_ units: [_CTGlyphUnit]) -> CGFloat {
    var total: CGFloat = 0
    for unit in units { total += unit.advance }
    return total
}

private func _makeLine(
    string: NSAttributedString,
    range: NSRange,
    font: CTFont
) -> CTLine {
    let units = _units(in: string, range: range, font: font)
    return CTLine(
        string: string,
        range: range,
        width: _width(units),
        ascent: CTFontGetAscent(font),
        descent: CTFontGetDescent(font),
        leading: CTFontGetLeading(font),
        font: font,
        units: units
    )
}

public func CTTypesetterCreateWithAttributedString(_ string: CFAttributedString) -> CTTypesetter {
    CTTypesetter(string: _attrString(string))
}

public func CTTypesetterCreateWithAttributedStringAndOptions(
    _ string: CFAttributedString,
    _ options: CFDictionary?
) -> CTTypesetter? {
    _ = options
    return CTTypesetter(string: _attrString(string))
}

public func CTTypesetterGetTypeID() -> CFTypeID { 0x4354_5453 }

public func CTTypesetterSuggestLineBreak(
    _ typesetter: CTTypesetter,
    _ startIndex: CFIndex,
    _ width: Double
) -> CFIndex {
    CTTypesetterSuggestLineBreakWithOffset(typesetter, startIndex, width, 0)
}

public func CTTypesetterSuggestLineBreakWithOffset(
    _ typesetter: CTTypesetter,
    _ startIndex: CFIndex,
    _ width: Double,
    _ offset: Double
) -> CFIndex {
    _ = offset
    let string = typesetter.string.string as NSString
    let length = string.length
    guard startIndex < length else { return startIndex }
    let font = _fontFromAttributedString(typesetter.string)
    let available = max(width, 1)
    var used: CGFloat = 0
    var end = startIndex
    var lastBreak = startIndex
    while end < length {
        let ch = string.character(at: end)
        let advance = _ctCharAdvance(font, scalar: UInt32(ch))
        if end > startIndex && used + advance > available {
            break
        }
        used += advance
        end += 1
        if ch == 32 || ch == 9 || ch == 10 {
            lastBreak = end
        }
    }
    if lastBreak > startIndex && end < length {
        return lastBreak
    }
    if end == startIndex {
        return min(length, startIndex + 1)
    }
    return end
}

public func CTTypesetterSuggestClusterBreak(
    _ typesetter: CTTypesetter,
    _ startIndex: CFIndex,
    _ width: Double
) -> CFIndex {
    CTTypesetterSuggestLineBreak(typesetter, startIndex, width)
}

public func CTTypesetterSuggestClusterBreakWithOffset(
    _ typesetter: CTTypesetter,
    _ startIndex: CFIndex,
    _ width: Double,
    _ offset: Double
) -> CFIndex {
    CTTypesetterSuggestLineBreakWithOffset(typesetter, startIndex, width, offset)
}

public func CTTypesetterCreateLine(_ typesetter: CTTypesetter, _ stringRange: CFRange) -> CTLine {
    CTTypesetterCreateLineWithOffset(typesetter, stringRange, 0)
}

public func CTTypesetterCreateLineWithOffset(
    _ typesetter: CTTypesetter,
    _ stringRange: CFRange,
    _ offset: Double
) -> CTLine {
    _ = offset
    let ns = typesetter.string
    let start = max(0, stringRange.location)
    let length = stringRange.length < 0 ? ns.length - start : min(stringRange.length, ns.length - start)
    let range = NSRange(location: start, length: max(0, length))
    let font = _fontFromAttributedString(ns)
    return _makeLine(string: ns, range: range, font: font)
}

public func CTLineCreateWithAttributedString(_ attrString: CFAttributedString) -> CTLine {
    let ns = _attrString(attrString)
    let typesetter = CTTypesetter(string: ns)
    return CTTypesetterCreateLine(
        typesetter,
        CFRange(location: 0, length: ns.length)
    )
}

public func CTLineGetTypeID() -> CFTypeID { 0x4354_4C4E }
public func CTLineGetGlyphCount(_ line: CTLine) -> CFIndex { line.units.count }
public func CTLineGetStringRange(_ line: CTLine) -> CFRange {
    CFRange(location: line.range.location, length: line.range.length)
}
public func CTLineGetTrailingWhitespaceWidth(_ line: CTLine) -> Double {
    let ns = line.string.string as NSString
    guard line.range.length > 0 else { return 0 }
    let last = ns.substring(with: NSRange(location: line.range.location + line.range.length - 1, length: 1))
    if last == " " || last == "\t" {
        if let unit = line.units.last {
            return Double(unit.advance)
        }
        return Double(_advance(for: line.font))
    }
    return 0
}
public func CTLineGetTypographicBounds(
    _ line: CTLine,
    _ ascent: UnsafeMutablePointer<CGFloat>?,
    _ descent: UnsafeMutablePointer<CGFloat>?,
    _ leading: UnsafeMutablePointer<CGFloat>?
) -> Double {
    ascent?.pointee = line.ascent
    descent?.pointee = line.descent
    leading?.pointee = line.leading
    return Double(line.width)
}
public func CTLineGetBoundsWithOptions(_ line: CTLine, _ options: CTLineBoundsOptions) -> CGRect {
    _ = options
    return CGRect(x: 0, y: -line.descent, width: line.width, height: line.ascent + line.descent)
}
public func CTLineGetOffsetForStringIndex(
    _ line: CTLine,
    _ charIndex: CFIndex,
    _ secondaryOffset: UnsafeMutablePointer<CGFloat>?
) -> CGFloat {
    secondaryOffset?.pointee = 0
    let local = max(0, min(charIndex, line.range.location + line.range.length) - line.range.location)
    var offset: CGFloat = 0
    let limit = min(local, line.units.count)
    for i in 0..<limit {
        offset += line.units[i].advance
    }
    return offset
}
public func CTLineGetStringIndexForPosition(_ line: CTLine, _ position: CGPoint) -> CFIndex {
    guard !line.units.isEmpty else { return line.range.location }
    var x: CGFloat = 0
    for (i, unit) in line.units.enumerated() {
        if position.x < x + unit.advance * 0.5 {
            return line.range.location + i
        }
        x += unit.advance
    }
    return line.range.location + line.units.count
}
public func CTLineGetPenOffsetForFlush(_ line: CTLine, _ flushFactor: CGFloat, _ flushWidth: Double) -> Double {
    let extra = flushWidth - Double(line.width)
    return extra * Double(flushFactor)
}
public func CTLineGetGlyphRuns(_ line: CTLine) -> CFArray {
    _ctCFArray([CTRun(line: line, range: line.range)] as NSArray)
}
public func CTLineCreateJustifiedLine(
    _ line: CTLine,
    _ justificationFactor: CGFloat,
    _ justificationWidth: Double
) -> CTLine? {
    let extra = CGFloat(justificationWidth) - line.width
    var units = line.units
    if extra != 0, !units.isEmpty, justificationFactor != 0 {
        let per = extra * justificationFactor / CGFloat(units.count)
        for i in units.indices {
            units[i].advance += per
        }
    }
    return CTLine(
        string: line.string,
        range: line.range,
        width: _width(units),
        ascent: line.ascent,
        descent: line.descent,
        leading: line.leading,
        font: line.font,
        units: units
    )
}
public func CTLineCreateTruncatedLine(
    _ line: CTLine,
    _ width: Double,
    _ truncationType: CTLineTruncationType,
    _ truncationToken: CTLine?
) -> CTLine? {
    _ = (truncationType, truncationToken)
    var used: CGFloat = 0
    var count = 0
    for unit in line.units {
        if count > 0 && used + unit.advance > CGFloat(width) { break }
        used += unit.advance
        count += 1
    }
    if count < 1 && !line.units.isEmpty { count = 1 }
    let length = min(line.range.length, count)
    let units = Array(line.units.prefix(length))
    return CTLine(
        string: line.string,
        range: NSRange(location: line.range.location, length: length),
        width: _width(units),
        ascent: line.ascent,
        descent: line.descent,
        leading: line.leading,
        font: line.font,
        units: units
    )
}
public func CTLineEnumerateCaretOffsets(
    _ line: CTLine,
    _ block: (Double, CFIndex, Bool, UnsafeMutablePointer<Bool>) -> Void
) {
    var x: Double = 0
    for i in 0...line.units.count {
        var stop = false
        block(x, line.range.location + i, true, &stop)
        if stop { return }
        if i < line.units.count {
            x += Double(line.units[i].advance)
        }
    }
}

public func CTLineDraw(_ line: CTLine, _ context: CGContext) {
    _ = line
    _ctRecordLineDraw(context)
}

public func CTLineGetImageBounds(_ line: CTLine, _ context: CGContext?) -> CGRect {
    _ = context
    return CTLineGetBoundsWithOptions(line, [])
}

public func CTRunGetTypeID() -> CFTypeID { 0x4354_5255 }
public func CTRunGetGlyphCount(_ run: CTRun) -> CFIndex { run.line.units.count }
public func CTRunGetStringRange(_ run: CTRun) -> CFRange {
    CFRange(location: run.range.location, length: run.range.length)
}
public func CTRunGetStatus(_ run: CTRun) -> CTRunStatus {
    _ = run
    return []
}
public func CTRunGetAttributes(_ run: CTRun) -> CFDictionary {
    if run.line.string.length == 0 { return _ctEmptyCFDictionary() }
    let loc = min(run.range.location, max(0, run.line.string.length - 1))
    return _ctCFDictionary(run.line.string.attributes(at: loc, effectiveRange: nil) as NSDictionary)
}
public func CTRunGetTypographicBounds(
    _ run: CTRun,
    _ range: CFRange,
    _ ascent: UnsafeMutablePointer<CGFloat>?,
    _ descent: UnsafeMutablePointer<CGFloat>?,
    _ leading: UnsafeMutablePointer<CGFloat>?
) -> Double {
    _ = range
    ascent?.pointee = run.line.ascent
    descent?.pointee = run.line.descent
    leading?.pointee = run.line.leading
    return Double(run.line.width)
}
public func CTRunGetAdvances(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGSize>?) {
    let units = run.line.units
    let count = range.length > 0 ? range.length : units.count
    let start = range.length > 0 ? max(0, range.location - run.range.location) : 0
    guard let buffer else { return }
    for i in 0..<count {
        let idx = start + i
        let width = (idx >= 0 && idx < units.count) ? units[idx].advance : 0
        buffer[i] = CGSize(width: width, height: 0)
    }
}
public func CTRunGetAdvancesPtr(_ run: CTRun) -> UnsafePointer<CGSize>? {
    _ = run
    return nil
}
public func CTRunGetPositions(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGPoint>?) {
    let units = run.line.units
    let count = range.length > 0 ? range.length : units.count
    let start = range.length > 0 ? max(0, range.location - run.range.location) : 0
    guard let buffer else { return }
    var x: CGFloat = 0
    for j in 0..<start where j < units.count {
        x += units[j].advance
    }
    for i in 0..<count {
        buffer[i] = CGPoint(x: x, y: 0)
        let idx = start + i
        if idx >= 0 && idx < units.count {
            x += units[idx].advance
        }
    }
}
public func CTRunGetPositionsPtr(_ run: CTRun) -> UnsafePointer<CGPoint>? {
    _ = run
    return nil
}
public func CTRunGetGlyphs(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CGGlyph>) {
    let units = run.line.units
    let count = range.length > 0 ? range.length : units.count
    let start = range.length > 0 ? max(0, range.location - run.range.location) : 0
    for i in 0..<count {
        let idx = start + i
        buffer[i] = (idx >= 0 && idx < units.count) ? units[idx].glyph : 0
    }
}
public func CTRunGetGlyphsPtr(_ run: CTRun) -> UnsafePointer<CGGlyph>? {
    _ = run
    return nil
}
public func CTRunGetStringIndices(_ run: CTRun, _ range: CFRange, _ buffer: UnsafeMutablePointer<CFIndex>?) {
    let count = range.length > 0 ? range.length : run.range.length
    let start = range.length > 0 ? range.location : run.range.location
    guard let buffer else { return }
    for i in 0..<count {
        buffer[i] = start + i
    }
}
public func CTRunGetStringIndicesPtr(_ run: CTRun) -> UnsafePointer<CFIndex>? {
    _ = run
    return nil
}
public func CTRunGetBaseAdvancesAndOrigins(
    _ runRef: CTRun,
    _ range: CFRange,
    _ advancesBuffer: UnsafeMutablePointer<CGSize>?,
    _ originsBuffer: UnsafeMutablePointer<CGPoint>?
) {
    CTRunGetAdvances(runRef, range, advancesBuffer)
    CTRunGetPositions(runRef, range, originsBuffer)
}
public func CTRunGetTextMatrix(_ run: CTRun) -> CGAffineTransform {
    run.line.font.matrix
}
public func CTRunGetImageBounds(_ run: CTRun, _ context: CGContext?, _ range: CFRange) -> CGRect {
    _ = (context, range)
    return CGRect(x: 0, y: -run.line.descent, width: run.line.width, height: run.line.ascent + run.line.descent)
}
public func CTRunDraw(_ run: CTRun, _ context: CGContext, _ range: CFRange) {
    _ = (run, range)
    _ctRecordRunDraw(context)
}

public func CTFramesetterCreateWithAttributedString(_ attrString: CFAttributedString) -> CTFramesetter {
    CTFramesetter(typesetter: CTTypesetterCreateWithAttributedString(attrString))
}

public func CTFramesetterCreateWithTypesetter(_ typesetter: CTTypesetter) -> CTFramesetter {
    CTFramesetter(typesetter: typesetter)
}

public func CTFramesetterGetTypeID() -> CFTypeID { 0x4354_4653 }
public func CTFramesetterGetTypesetter(_ framesetter: CTFramesetter) -> CTTypesetter {
    framesetter.typesetter
}

public func CTFramesetterSuggestFrameSizeWithConstraints(
    _ framesetter: CTFramesetter,
    _ stringRange: CFRange,
    _ frameAttributes: CFDictionary?,
    _ constraints: CGSize,
    _ fitRange: UnsafeMutablePointer<CFRange>?
) -> CGSize {
    _ = frameAttributes
    let ns = framesetter.typesetter.string
    var start = stringRange.location
    if start < 0 { start = 0 }
    let endLimit = stringRange.length < 0 ? ns.length : min(ns.length, start + stringRange.length)
    var cursor = start
    var lines = 0
    var maxWidth: CGFloat = 0
    while cursor < endLimit {
        let next = CTTypesetterSuggestLineBreak(framesetter.typesetter, cursor, Double(constraints.width))
        if next <= cursor { break }
        let line = CTTypesetterCreateLine(
            framesetter.typesetter,
            CFRange(location: cursor, length: next - cursor)
        )
        maxWidth = max(maxWidth, line.width)
        lines += 1
        cursor = next
        if constraints.height > 0 {
            let height = CGFloat(lines) * (line.ascent + line.descent + line.leading)
            if height > constraints.height { break }
        }
    }
    fitRange?.pointee = CFRange(location: start, length: cursor - start)
    let font = _fontFromAttributedString(ns)
    let lineHeight = CTFontGetAscent(font) + CTFontGetDescent(font) + CTFontGetLeading(font)
    return CGSize(width: maxWidth, height: CGFloat(max(lines, 1)) * lineHeight)
}

public func CTFramesetterCreateFrame(
    _ framesetter: CTFramesetter,
    _ stringRange: CFRange,
    _ path: CGPath,
    _ frameAttributes: CFDictionary?
) -> CTFrame {
    let bounds = _ctPathBounds(path)
    var mapped: [String: Any] = [:]
    if let frameAttributes {
        let ns = _ctNSDictionary(frameAttributes)
        for (key, value) in ns {
            mapped["\(key)"] = value
        }
    }
    let ns = framesetter.typesetter.string
    var start = stringRange.location
    if start < 0 { start = 0 }
    let endLimit = stringRange.length < 0 ? ns.length : min(ns.length, start + stringRange.length)
    var cursor = start
    var lines: [CTLine] = []
    var usedHeight: CGFloat = 0
    while cursor < endLimit {
        let next = CTTypesetterSuggestLineBreak(framesetter.typesetter, cursor, Double(bounds.width))
        if next <= cursor { break }
        let line = CTTypesetterCreateLine(
            framesetter.typesetter,
            CFRange(location: cursor, length: next - cursor)
        )
        let lineHeight = line.ascent + line.descent + line.leading
        if bounds.height > 0 && usedHeight + lineHeight > bounds.height && !lines.isEmpty {
            break
        }
        lines.append(line)
        usedHeight += lineHeight
        cursor = next
    }
    return CTFrame(
        string: ns,
        lines: lines,
        visibleRange: NSRange(location: start, length: cursor - start),
        pathBounds: bounds,
        attributes: mapped,
        path: path
    )
}

public func CTFrameGetPath(_ frame: CTFrame) -> CGPath {
    frame.path
}

public func CTFrameDraw(_ frame: CTFrame, _ context: CGContext) {
    for line in frame.lines {
        CTLineDraw(line, context)
    }
}

public func CTFrameGetTypeID() -> CFTypeID { 0x4354_4652 }
public func CTFrameGetLines(_ frame: CTFrame) -> CFArray { _ctCFArray(frame.lines as NSArray) }
public func CTFrameGetStringRange(_ frame: CTFrame) -> CFRange {
    CFRange(location: 0, length: frame.string.length)
}
public func CTFrameGetVisibleStringRange(_ frame: CTFrame) -> CFRange {
    CFRange(location: frame.visibleRange.location, length: frame.visibleRange.length)
}
public func CTFrameGetFrameAttributes(_ frame: CTFrame) -> CFDictionary? {
    _ctCFDictionary(frame.attributes as NSDictionary)
}
public func CTFrameGetLineOrigins(_ frame: CTFrame, _ range: CFRange, _ origins: UnsafeMutablePointer<CGPoint>) {
    let start = range.location
    let count = range.length > 0 ? range.length : frame.lines.count
    var y = frame.pathBounds.maxY
    for (index, line) in frame.lines.enumerated() {
        y -= line.ascent
        if index >= start && index < start + count {
            origins[index - start] = CGPoint(x: frame.pathBounds.minX, y: y)
        }
        y -= line.descent + line.leading
    }
}

public func CTParagraphStyleGetTypeID() -> CFTypeID { 0x4354_5053 }

public func CTParagraphStyleCreate(
    _ settings: UnsafePointer<CTParagraphStyleSetting>?,
    _ settingCount: Int
) -> CTParagraphStyle {
    var alignment = CTTextAlignment.natural
    var lineBreak = CTLineBreakMode.byWordWrapping
    var direction = CTWritingDirection.natural
    var values: [CTParagraphStyleSpecifier: Data] = [:]
    if let settings {
        for i in 0..<settingCount {
            let setting = settings[i]
            let bytes = Data(bytes: setting.value, count: setting.valueSize)
            values[setting.spec] = bytes
            if setting.spec == .alignment, setting.valueSize >= 1 {
                let raw = setting.value.load(as: UInt8.self)
                if let value = CTTextAlignment(rawValue: raw) {
                    alignment = value
                }
            }
            if setting.spec == .lineBreakMode, setting.valueSize >= 1 {
                let raw = setting.value.load(as: UInt8.self)
                if let value = CTLineBreakMode(rawValue: raw) {
                    lineBreak = value
                }
            }
            if setting.spec == .baseWritingDirection, setting.valueSize >= 1 {
                let raw = setting.value.load(as: Int8.self)
                if let value = CTWritingDirection(rawValue: raw) {
                    direction = value
                }
            }
        }
    }
    return CTParagraphStyle(
        alignment: alignment,
        lineBreakMode: lineBreak,
        baseWritingDirection: direction,
        values: values
    )
}

public func CTParagraphStyleCreateCopy(_ paragraphStyle: CTParagraphStyle) -> CTParagraphStyle {
    CTParagraphStyle(
        alignment: paragraphStyle.alignment,
        lineBreakMode: paragraphStyle.lineBreakMode,
        baseWritingDirection: paragraphStyle.baseWritingDirection,
        values: paragraphStyle.values
    )
}

public func CTParagraphStyleGetValueForSpecifier(
    _ paragraphStyle: CTParagraphStyle,
    _ spec: CTParagraphStyleSpecifier,
    _ valueBufferSize: Int,
    _ valueBuffer: UnsafeMutableRawPointer
) -> Bool {
    if spec == .alignment, valueBufferSize >= 1 {
        valueBuffer.storeBytes(of: paragraphStyle.alignment.rawValue, as: UInt8.self)
        return true
    }
    if spec == .lineBreakMode, valueBufferSize >= 1 {
        valueBuffer.storeBytes(of: paragraphStyle.lineBreakMode.rawValue, as: UInt8.self)
        return true
    }
    if spec == .baseWritingDirection, valueBufferSize >= 1 {
        valueBuffer.storeBytes(of: paragraphStyle.baseWritingDirection.rawValue, as: Int8.self)
        return true
    }
    guard let data = paragraphStyle.values[spec], data.count <= valueBufferSize else {
        return false
    }
    data.withUnsafeBytes { raw in
        if let base = raw.baseAddress {
            valueBuffer.copyMemory(from: base, byteCount: data.count)
        }
    }
    return true
}

public func CTTextTabGetTypeID() -> CFTypeID { 0x4354_5442 }
public func CTTextTabCreate(
    _ alignment: CTTextAlignment,
    _ location: Double,
    _ options: CFDictionary?
) -> CTTextTab {
    CTTextTab(alignment: alignment, location: location, options: options)
}
public func CTTextTabGetAlignment(_ tab: CTTextTab) -> CTTextAlignment { tab.alignment }
public func CTTextTabGetLocation(_ tab: CTTextTab) -> Double { tab.location }
public func CTTextTabGetOptions(_ tab: CTTextTab) -> CFDictionary? { tab.options }

public func CTRubyAnnotationGetTypeID() -> CFTypeID { 0x4354_5259 }
public func CTRubyAnnotationCreate(
    _ alignment: CTRubyAlignment,
    _ overhang: CTRubyOverhang,
    _ sizeFactor: CGFloat,
    _ text: UnsafeMutablePointer<Unmanaged<CFString>?>
) -> CTRubyAnnotation? {
    var mapped: [CTRubyPosition: String] = [:]
    for position in [CTRubyPosition.before, .after, .interCharacter, .inline] {
        if Int(position.rawValue) < 4, let value = text[Int(position.rawValue)]?.takeUnretainedValue() {
            mapped[position] = _ctString(value)
        }
    }
    return CTRubyAnnotation(
        alignment: alignment,
        overhang: overhang,
        sizeFactor: sizeFactor,
        text: mapped
    )
}
public func CTRubyAnnotationCreateCopy(_ rubyAnnotation: CTRubyAnnotation) -> CTRubyAnnotation {
    CTRubyAnnotation(
        alignment: rubyAnnotation.alignment,
        overhang: rubyAnnotation.overhang,
        sizeFactor: rubyAnnotation.sizeFactor,
        text: rubyAnnotation.text
    )
}
public func CTRubyAnnotationCreateWithAttributes(
    _ alignment: CTRubyAlignment,
    _ overhang: CTRubyOverhang,
    _ position: CTRubyPosition,
    _ string: CFString,
    _ attributes: CFDictionary?
) -> CTRubyAnnotation {
    _ = attributes
    return CTRubyAnnotation(
        alignment: alignment,
        overhang: overhang,
        sizeFactor: 0.5,
        text: [position: _ctString(string)]
    )
}
public func CTRubyAnnotationGetAlignment(_ rubyAnnotation: CTRubyAnnotation) -> CTRubyAlignment {
    rubyAnnotation.alignment
}
public func CTRubyAnnotationGetOverhang(_ rubyAnnotation: CTRubyAnnotation) -> CTRubyOverhang {
    rubyAnnotation.overhang
}
public func CTRubyAnnotationGetSizeFactor(_ rubyAnnotation: CTRubyAnnotation) -> CGFloat {
    rubyAnnotation.sizeFactor
}
public func CTRubyAnnotationGetTextForPosition(
    _ rubyAnnotation: CTRubyAnnotation,
    _ position: CTRubyPosition
) -> CFString? {
    rubyAnnotation.text[position].map { _ctCFString($0) }
}

public func CTGlyphInfoGetTypeID() -> CFTypeID { 0x4354_4749 }
public func CTGlyphInfoCreateWithGlyphName(
    _ glyphName: CFString,
    _ font: CTFont,
    _ baseString: CFString
) -> CTGlyphInfo? {
    _ = font
    return CTGlyphInfo(
        glyphName: _ctString(glyphName),
        collection: .identityMapping,
        characterIdentifier: 0,
        baseString: _ctString(baseString)
    )
}
public func CTGlyphInfoCreateWithCharacterIdentifier(
    _ cid: CGFontIndex,
    _ collection: CTCharacterCollection,
    _ baseString: CFString
) -> CTGlyphInfo? {
    CTGlyphInfo(
        glyphName: nil,
        collection: collection,
        characterIdentifier: cid,
        baseString: _ctString(baseString),
        glyph: CGGlyph(cid)
    )
}
public func CTGlyphInfoCreateWithGlyph(
    _ glyph: CGGlyph,
    _ font: CTFont,
    _ baseString: CFString
) -> CTGlyphInfo? {
    _ = font
    return CTGlyphInfo(
        glyphName: nil,
        collection: .identityMapping,
        characterIdentifier: glyph,
        baseString: _ctString(baseString),
        glyph: glyph
    )
}
public func CTGlyphInfoGetGlyphName(_ glyphInfo: CTGlyphInfo) -> CFString? {
    glyphInfo.glyphName.map { _ctCFString($0) }
}
public func CTGlyphInfoGetCharacterCollection(_ glyphInfo: CTGlyphInfo) -> CTCharacterCollection {
    glyphInfo.collection
}
public func CTGlyphInfoGetCharacterIdentifier(_ glyphInfo: CTGlyphInfo) -> CGFontIndex {
    glyphInfo.characterIdentifier
}
public func CTGlyphInfoGetGlyph(_ glyphInfo: CTGlyphInfo) -> CGGlyph {
    glyphInfo.glyph
}

public func CTRunDelegateGetTypeID() -> CFTypeID { 0x4354_5244 }
public func CTRunDelegateCreate(
    _ callbacks: UnsafePointer<CTRunDelegateCallbacks>,
    _ refCon: UnsafeMutableRawPointer?
) -> CTRunDelegate? {
    CTRunDelegate(callbacks: callbacks.pointee, refCon: refCon)
}
public func CTRunDelegateGetRefCon(_ runDelegate: CTRunDelegate) -> UnsafeMutableRawPointer {
    runDelegate.refCon ?? UnsafeMutableRawPointer(bitPattern: 1)!
}

public func CTFontGetTypographicBoundsForAdaptiveImageProvider(
    _ font: CTFont,
    _ provider: (any CTAdaptiveImageProviding)?
) -> CGRect {
    _ = provider
    return CGRect(x: 0, y: 0, width: font.size, height: CTFontGetAscent(font) + CTFontGetDescent(font))
}

public protocol CTAdaptiveImageProviding {}
