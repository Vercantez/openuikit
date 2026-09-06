import CoreFoundation
import Foundation
#if canImport(CoreGraphics)
import CoreGraphics
#endif

enum _PortableMetrics {
    static let familyName = "OpenUIKit Portable"
    static let styleName = "Regular"
    static let fullName = "OpenUIKit Portable Regular"
    static let postScriptName = "OpenUIKitPortable-Regular"
    static let unitsPerEm: CGFloat = 1000
    static let ascent: CGFloat = 800
    static let descent: CGFloat = 200
    static let leading: CGFloat = 0
    static let capHeight: CGFloat = 700
    static let xHeight: CGFloat = 500
    static let underlinePosition: CGFloat = -100
    static let underlineThickness: CGFloat = 50
    static let glyphCount: Int = 1
    static let boundingBox = CGRect(x: -80, y: -200, width: 1080, height: 1000)
}

struct _SFNTMetrics {
    var familyName = _PortableMetrics.familyName
    var styleName = _PortableMetrics.styleName
    var fullName = _PortableMetrics.fullName
    var postScriptName = _PortableMetrics.postScriptName
    var unitsPerEm: CGFloat = _PortableMetrics.unitsPerEm
    var ascent: CGFloat = _PortableMetrics.ascent
    var descent: CGFloat = _PortableMetrics.descent
    var leading: CGFloat = _PortableMetrics.leading
    var capHeight: CGFloat = _PortableMetrics.capHeight
    var xHeight: CGFloat = _PortableMetrics.xHeight
    var underlinePosition: CGFloat = _PortableMetrics.underlinePosition
    var underlineThickness: CGFloat = _PortableMetrics.underlineThickness
    var glyphCount: Int = _PortableMetrics.glyphCount
    var boundingBox: CGRect = _PortableMetrics.boundingBox
    var format: CTFontFormat = .unrecognized
    var tableBytes: [UInt32: Data] = [:]
    var cmap: [UInt32: UInt16] = [:]
    var advanceWidths: [CGFloat] = []
    var glyphBounds: [CGRect] = []
    var nameIDs: [Int: String] = [:]
    var hasGSUB = false
    var hasGPOS = false

    static func parse(data: Data) -> _SFNTMetrics {
        var metrics = _SFNTMetrics()
        guard data.count >= 12 else { return metrics }
        let reader = _SFNTReader(data: data)
        var offset: Int = 0
        let tag = reader.u32(0)
        if tag == 0x7474_6366 { // ttcf
            guard data.count >= 16 else { return metrics }
            offset = Int(reader.u32(12))
        }
        guard offset + 12 <= data.count else { return metrics }
        let sfntTag = reader.u32(offset)
        if sfntTag == 0x4F54_544F {
            metrics.format = .openTypePostScript
        } else if sfntTag == 0x0001_0000 || sfntTag == 0x7472_7565 {
            metrics.format = .trueType
        }
        let numTables = Int(reader.u16(offset + 4))
        var tables: [UInt32: (Int, Int)] = [:]
        var cursor = offset + 12
        for _ in 0..<numTables {
            guard cursor + 16 <= data.count else { break }
            let tableTag = reader.u32(cursor)
            let tableOffset = Int(reader.u32(cursor + 8))
            let tableLength = Int(reader.u32(cursor + 12))
            tables[tableTag] = (tableOffset, tableLength)
            if tableOffset >= 0, tableLength > 0, tableOffset + tableLength <= data.count {
                metrics.tableBytes[tableTag] = data.subdata(in: tableOffset..<(tableOffset + tableLength))
            }
            cursor += 16
        }
        metrics.hasGSUB = tables[0x4753_5542] != nil
        metrics.hasGPOS = tables[0x4750_4F53] != nil
        var locaFormat: Int16 = 0
        if let head = tables[0x6865_6164], head.1 >= 54 { // head
            let o = head.0
            let upe = CGFloat(reader.u16(o + 18))
            if upe > 0 { metrics.unitsPerEm = upe }
            let xMin = CGFloat(reader.i16(o + 36))
            let yMin = CGFloat(reader.i16(o + 38))
            let xMax = CGFloat(reader.i16(o + 40))
            let yMax = CGFloat(reader.i16(o + 42))
            metrics.boundingBox = CGRect(
                origin: CGPoint(x: Double(xMin), y: Double(yMin)),
                size: CGSize(width: Double(xMax - xMin), height: Double(yMax - yMin))
            )
            locaFormat = reader.i16(o + 50)
        }
        var numberOfHMetrics = 0
        if let hhea = tables[0x6868_6561], hhea.1 >= 8 { // hhea
            let o = hhea.0
            metrics.ascent = CGFloat(reader.i16(o + 4))
            metrics.descent = CGFloat(-reader.i16(o + 6))
            if hhea.1 >= 10 {
                metrics.leading = CGFloat(reader.i16(o + 8))
            }
            if hhea.1 >= 36 {
                numberOfHMetrics = Int(reader.u16(o + 34))
            }
        }
        if let maxp = tables[0x6D61_7870], maxp.1 >= 6 { // maxp
            metrics.glyphCount = Int(reader.u16(maxp.0 + 4))
        }
        if let os2 = tables[0x4F53_2F32], os2.1 >= 70 { // OS/2
            let o = os2.0
            if os2.1 >= 88 {
                metrics.xHeight = CGFloat(reader.i16(o + 86))
                metrics.capHeight = CGFloat(reader.i16(o + 88))
            }
        }
        if let post = tables[0x706F_7374], post.1 >= 12 { // post
            metrics.underlinePosition = CGFloat(reader.i16(post.0 + 8))
            metrics.underlineThickness = CGFloat(reader.i16(post.0 + 10))
        }
        if let name = tables[0x6E61_6D65] {
            let names = reader.nameTable(at: name.0, length: name.1)
            metrics.nameIDs = names
            if let family = names[1] { metrics.familyName = family }
            if let style = names[2] { metrics.styleName = style }
            if let full = names[4] { metrics.fullName = full }
            if let ps = names[6] { metrics.postScriptName = ps }
        }
        if let hmtx = tables[0x686D_7478] {
            metrics.advanceWidths = reader.hmtx(
                at: hmtx.0,
                length: hmtx.1,
                glyphCount: metrics.glyphCount,
                numberOfHMetrics: numberOfHMetrics
            )
        }
        if let cmap = tables[0x636D_6170] {
            metrics.cmap = reader.cmap(at: cmap.0, length: cmap.1)
        }
        if let loca = tables[0x6C6F_6361], let glyf = tables[0x676C_7966] {
            metrics.glyphBounds = reader.glyphBounds(
                locaOffset: loca.0,
                locaLength: loca.1,
                glyfOffset: glyf.0,
                glyfLength: glyf.1,
                glyphCount: metrics.glyphCount,
                longOffsets: locaFormat == 1
            )
        }
        return metrics
    }
}

private struct _SFNTReader {
    let data: Data

    func u16(_ offset: Int) -> UInt16 {
        guard offset + 2 <= data.count else { return 0 }
        return UInt16(data[offset]) << 8 | UInt16(data[offset + 1])
    }

    func i16(_ offset: Int) -> Int16 {
        Int16(bitPattern: u16(offset))
    }

    func u32(_ offset: Int) -> UInt32 {
        guard offset + 4 <= data.count else { return 0 }
        return (UInt32(data[offset]) << 24) | (UInt32(data[offset + 1]) << 16)
            | (UInt32(data[offset + 2]) << 8) | UInt32(data[offset + 3])
    }

    func nameTable(at offset: Int, length: Int) -> [Int: String] {
        guard offset + 6 <= data.count else { return [:] }
        let count = Int(u16(offset + 2))
        let stringOffset = offset + Int(u16(offset + 4))
        var result: [Int: String] = [:]
        var cursor = offset + 6
        for _ in 0..<count {
            guard cursor + 12 <= data.count else { break }
            let platform = u16(cursor)
            let encoding = u16(cursor + 2)
            let nameID = Int(u16(cursor + 6))
            let nameLength = Int(u16(cursor + 8))
            let nameRel = Int(u16(cursor + 10))
            cursor += 12
            let start = stringOffset + nameRel
            guard start + nameLength <= data.count, start >= 0 else { continue }
            let slice = data[start..<(start + nameLength)]
            let decoded: String?
            if platform == 0 || (platform == 3 && encoding == 1) {
                decoded = String(bytes: slice, encoding: .utf16BigEndian)
            } else if platform == 1 {
                decoded = String(bytes: slice, encoding: .macOSRoman) ?? String(bytes: slice, encoding: .ascii)
            } else {
                decoded = String(bytes: slice, encoding: .ascii)
            }
            if let decoded, !decoded.isEmpty, result[nameID] == nil {
                result[nameID] = decoded
            }
        }
        _ = length
        return result
    }

    func hmtx(at offset: Int, length: Int, glyphCount: Int, numberOfHMetrics: Int) -> [CGFloat] {
        guard glyphCount > 0 else { return [] }
        let metricsCount = numberOfHMetrics > 0 ? min(numberOfHMetrics, glyphCount) : glyphCount
        var widths = Array(repeating: CGFloat(0), count: glyphCount)
        var last: CGFloat = 0
        for i in 0..<metricsCount {
            let entry = offset + i * 4
            guard entry + 2 <= data.count, entry + 2 <= offset + length else { break }
            last = CGFloat(u16(entry))
            widths[i] = last
        }
        if metricsCount < glyphCount {
            for i in metricsCount..<glyphCount {
                widths[i] = last
            }
        }
        return widths
    }

    func cmap(at offset: Int, length: Int) -> [UInt32: UInt16] {
        guard offset + 4 <= data.count else { return [:] }
        let numTables = Int(u16(offset + 2))
        var mapping: [UInt32: UInt16] = [:]
        var records: [(UInt16, UInt16, Int)] = []
        var cursor = offset + 4
        for _ in 0..<numTables {
            guard cursor + 8 <= data.count else { break }
            records.append((u16(cursor), u16(cursor + 2), Int(u32(cursor + 4))))
            cursor += 8
        }
        // Apply format 4 first, then format 12 so supplementary-plane groups win.
        let ordered = records.sorted { left, right in
            let lfmt = u16(offset + left.2)
            let rfmt = u16(offset + right.2)
            if lfmt == rfmt { return left.2 < right.2 }
            return lfmt < rfmt
        }
        for record in ordered {
            let sub = offset + record.2
            guard sub + 2 <= data.count else { continue }
            let format = u16(sub)
            if format == 4 {
                parseCmapFormat4(at: sub, into: &mapping)
            } else if format == 12 {
                parseCmapFormat12(at: sub, into: &mapping)
            }
        }
        _ = length
        return mapping
    }

    private func parseCmapFormat4(at sub: Int, into mapping: inout [UInt32: UInt16]) {
        guard sub + 14 <= data.count else { return }
        let length = Int(u16(sub + 2))
        let segCount = Int(u16(sub + 6)) / 2
        guard segCount > 0 else { return }
        let endOff = sub + 14
        let reserved = endOff + 2 * segCount
        let startOff = reserved + 2
        let deltaOff = startOff + 2 * segCount
        let rangeOff = deltaOff + 2 * segCount
        guard rangeOff + 2 * segCount <= sub + length, rangeOff + 2 * segCount <= data.count else { return }
        for i in 0..<segCount {
            let endCode = UInt32(u16(endOff + 2 * i))
            let startCode = UInt32(u16(startOff + 2 * i))
            let idDelta = i16(deltaOff + 2 * i)
            let idRangeOffset = u16(rangeOff + 2 * i)
            if startCode == 0xFFFF && endCode == 0xFFFF { continue }
            if idRangeOffset == 0 {
                var cp = startCode
                while cp <= endCode {
                    mapping[cp] = UInt16(truncatingIfNeeded: Int(cp) + Int(idDelta))
                    if cp == endCode { break }
                    cp += 1
                }
            } else {
                var cp = startCode
                while cp <= endCode {
                    let glyphOff = Int(rangeOff + 2 * i)
                        + Int(idRangeOffset)
                        + Int(cp - startCode) * 2
                    if glyphOff + 2 <= data.count {
                        let glyph = u16(glyphOff)
                        if glyph != 0 {
                            mapping[cp] = UInt16(truncatingIfNeeded: Int(glyph) + Int(idDelta))
                        }
                    }
                    if cp == endCode { break }
                    cp += 1
                }
            }
        }
    }

    private func parseCmapFormat12(at sub: Int, into mapping: inout [UInt32: UInt16]) {
        guard sub + 16 <= data.count else { return }
        let nGroups = Int(u32(sub + 12))
        var cursor = sub + 16
        for _ in 0..<nGroups {
            guard cursor + 12 <= data.count else { break }
            let start = u32(cursor)
            let end = u32(cursor + 4)
            let startGlyph = u32(cursor + 8)
            var cp = start
            var gid = startGlyph
            while cp <= end {
                mapping[cp] = UInt16(truncatingIfNeeded: gid)
                if cp == end { break }
                cp += 1
                gid += 1
            }
            cursor += 12
        }
    }

    func glyphBounds(
        locaOffset: Int,
        locaLength: Int,
        glyfOffset: Int,
        glyfLength: Int,
        glyphCount: Int,
        longOffsets: Bool
    ) -> [CGRect] {
        guard glyphCount > 0 else { return [] }
        var offsets: [Int] = []
        offsets.reserveCapacity(glyphCount + 1)
        if longOffsets {
            let need = (glyphCount + 1) * 4
            guard locaLength >= need else { return [] }
            for i in 0...glyphCount {
                offsets.append(Int(u32(locaOffset + i * 4)))
            }
        } else {
            let need = (glyphCount + 1) * 2
            guard locaLength >= need else { return [] }
            for i in 0...glyphCount {
                offsets.append(Int(u16(locaOffset + i * 2)) * 2)
            }
        }
        var boxes = Array(repeating: CGRect.zero, count: glyphCount)
        for i in 0..<glyphCount {
            let start = offsets[i]
            let end = offsets[i + 1]
            let span = end - start
            guard span >= 10, start >= 0, start + 10 <= glyfLength else { continue }
            let o = glyfOffset + start
            let xMin = CGFloat(i16(o + 2))
            let yMin = CGFloat(i16(o + 4))
            let xMax = CGFloat(i16(o + 6))
            let yMax = CGFloat(i16(o + 8))
            boxes[i] = CGRect(
                origin: CGPoint(x: Double(xMin), y: Double(yMin)),
                size: CGSize(width: Double(xMax - xMin), height: Double(yMax - yMin))
            )
        }
        return boxes
    }
}

public final class CTFontDescriptor: Hashable, @unchecked Sendable {
    let attributes: [String: Any]

    init(attributes: [String: Any]) {
        self.attributes = attributes
    }

    public static func == (left: CTFontDescriptor, right: CTFontDescriptor) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

}

public final class CTFont: Hashable, @unchecked Sendable {
    let size: CGFloat
    let metrics: _SFNTMetrics
    let descriptor: CTFontDescriptor
    let data: Data?
    let matrix: CGAffineTransform
    let sfui: _SFUIFace?
    let symbolicTraits: CTFontSymbolicTraits

    init(
        size: CGFloat,
        metrics: _SFNTMetrics,
        descriptor: CTFontDescriptor,
        data: Data?,
        matrix: CGAffineTransform = _ctIdentityTransform(),
        sfui: _SFUIFace? = nil,
        symbolicTraits: CTFontSymbolicTraits = []
    ) {
        self.size = size > 0 ? size : 12
        self.metrics = metrics
        self.descriptor = descriptor
        self.data = data
        self.matrix = matrix
        self.sfui = sfui
        self.symbolicTraits = symbolicTraits
    }

    public convenience init(_ name: CFString, size: CGFloat) {
        self.init(name: _ctString(name), size: size)
    }

    public convenience init(_ descriptor: CTFontDescriptor, size: CGFloat) {
        self.init(descriptor, transform: _ctIdentityTransform(), requestedSize: size)
    }

    public convenience init(_ descriptor: CTFontDescriptor, transform matrix: CGAffineTransform) {
        self.init(descriptor, transform: matrix, requestedSize: 0)
    }

    convenience init(_ descriptor: CTFontDescriptor, transform matrix: CGAffineTransform, requestedSize: CGFloat) {
        let resolved = _CTFontResolve(descriptor: descriptor, requestedSize: requestedSize)
        self.init(
            size: resolved.size,
            metrics: resolved.metrics,
            descriptor: resolved.descriptor,
            data: resolved.data,
            matrix: matrix,
            sfui: resolved.sfui,
            symbolicTraits: resolved.symbolicTraits
        )
    }

    public convenience init(_ uiType: CTFontUIFontType, size: CGFloat) {
        self.init(uiType, size: size, language: nil)
    }

    public convenience init(_ uiType: CTFontUIFontType, size: CGFloat, language: CFString?) {
        _ = language
        let resolvedSize: CGFloat
        if size > 0 {
            resolvedSize = size
        } else {
            resolvedSize = _CTFontUISize(uiType)
        }
        let bold = _CTFontUIBold(uiType)
        let resolved = _CTFontResolveSFUI(size: resolvedSize, bold: bold)
        self.init(
            size: resolved.size,
            metrics: resolved.metrics,
            descriptor: resolved.descriptor,
            data: nil,
            sfui: resolved.sfui,
            symbolicTraits: bold ? .boldTrait : []
        )
    }

    public convenience init(font currentFont: CTFont, string: CFString, range: CFRange) {
        self.init(font: currentFont, string: string, range: range, language: nil)
    }

    public convenience init(
        font currentFont: CTFont,
        string: CFString,
        range: CFRange,
        language: CFString?
    ) {
        _ = (string, range, language)
        self.init(
            size: currentFont.size,
            metrics: currentFont.metrics,
            descriptor: currentFont.descriptor,
            data: currentFont.data,
            matrix: currentFont.matrix,
            sfui: currentFont.sfui,
            symbolicTraits: currentFont.symbolicTraits
        )
    }

    public convenience init(_ name: CFString, transform matrix: CGAffineTransform) {
        self.init(name: _ctString(name), size: 0, matrix: matrix)
    }

    convenience init(name: String, size: CGFloat, matrix: CGAffineTransform = _ctIdentityTransform()) {
        let resolved = _CTFontResolve(name: name, size: size)
        self.init(
            size: resolved.size,
            metrics: resolved.metrics,
            descriptor: resolved.descriptor,
            data: resolved.data,
            matrix: matrix,
            sfui: resolved.sfui,
            symbolicTraits: resolved.symbolicTraits
        )
    }

    public static func == (left: CTFont, right: CTFont) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

}

open class CTFontCollection: Hashable, @unchecked Sendable {
    let descriptors: [CTFontDescriptor]
    let options: [String: Any]

    init(descriptors: [CTFontDescriptor], options: [String: Any]) {
        self.descriptors = descriptors
        self.options = options
    }

    public static func == (left: CTFontCollection, right: CTFontCollection) -> Bool {
        left === right
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(ObjectIdentifier(self))
    }

}

public class CTMutableFontCollection: CTFontCollection, @unchecked Sendable {}

private func _PortableMetricsSnapshot() -> _SFNTMetrics {
    _SFNTMetrics()
}

private func _CTFontUISize(_ uiType: CTFontUIFontType) -> CGFloat {
    switch uiType {
    case .miniSystem, .miniEmphasizedSystem: return 9
    case .smallSystem, .smallEmphasizedSystem, .smallToolbar: return 11
    case .label, .toolTip: return 10
    default: return 13
    }
}

private func _CTFontUIBold(_ uiType: CTFontUIFontType) -> Bool {
    switch uiType {
    case .emphasizedSystem, .smallEmphasizedSystem, .miniEmphasizedSystem, .emphasizedSystemDetail:
        return true
    default:
        return false
    }
}

private struct _ResolvedFont {
    var size: CGFloat
    var metrics: _SFNTMetrics
    var descriptor: CTFontDescriptor
    var data: Data?
    var sfui: _SFUIFace?
    var symbolicTraits: CTFontSymbolicTraits
}

private func _CTFontMetricsFromSFUI(_ face: _SFUIFace, bold: Bool) -> _SFNTMetrics {
    let upe = CGFloat(_SFUITable.unitsPerEm)
    let s = face.pointSize > 0 ? face.pointSize : 17
    var metrics = _SFNTMetrics()
    metrics.familyName = _SFUITable.familyName
    metrics.styleName = bold ? _SFUITable.styleBold : _SFUITable.styleRegular
    metrics.fullName = bold ? _SFUITable.boldFullName : _SFUITable.regularFullName
    metrics.postScriptName = bold ? _SFUITable.boldPostScript : _SFUITable.regularPostScript
    metrics.unitsPerEm = upe
    metrics.ascent = face.ascender * upe / s
    metrics.descent = (-face.descender) * upe / s
    metrics.leading = face.leading * upe / s
    metrics.capHeight = face.capHeight * upe / s
    metrics.xHeight = face.xHeight * upe / s
    metrics.glyphCount = 95
    metrics.format = .trueType
    metrics.boundingBox = CGRect(
        x: 0,
        y: face.descender * upe / s,
        width: _SFUITable.advance(face, scalar: 77) * upe / s,
        height: (face.ascender - face.descender) * upe / s
    )
    return metrics
}

private func _CTFontResolveSFUI(size: CGFloat, bold: Bool) -> _ResolvedFont {
    let requested = size > 0 ? size : 12
    let face = _SFUITable.face(size: requested, bold: bold)
    let metrics = _CTFontMetricsFromSFUI(face, bold: bold)
    let descriptor = CTFontDescriptor(
        attributes: [
            _ctString(kCTFontNameAttribute): metrics.postScriptName,
            _ctString(kCTFontFamilyNameAttribute): metrics.familyName,
            _ctString(kCTFontDisplayNameAttribute): metrics.fullName,
            _ctString(kCTFontSizeAttribute): requested,
            _ctString(kCTFontStyleNameAttribute): metrics.styleName,
        ]
    )
    return _ResolvedFont(
        size: requested,
        metrics: metrics,
        descriptor: descriptor,
        data: nil,
        sfui: face,
        symbolicTraits: bold ? .boldTrait : []
    )
}

private func _CTFontResolve(name: String, size: CGFloat) -> _ResolvedFont {
    let requested = size > 0 ? size : 12
    if _SFUITable.isSystemName(name) {
        return _CTFontResolveSFUI(size: requested, bold: _SFUITable.isBoldName(name))
    }
    for (url, data) in _portableCopyRegisteredRecords() {
        let metrics = _SFNTMetrics.parse(data: data)
        if metrics.postScriptName == name
            || metrics.familyName == name
            || metrics.fullName == name
        {
            let descriptor = CTFontDescriptor(
                attributes: [
                    _ctString(kCTFontNameAttribute): metrics.postScriptName,
                    _ctString(kCTFontFamilyNameAttribute): metrics.familyName,
                    _ctString(kCTFontDisplayNameAttribute): metrics.fullName,
                    _ctString(kCTFontStyleNameAttribute): metrics.styleName,
                    _ctString(kCTFontSizeAttribute): requested,
                    _ctString(kCTFontURLAttribute): url,
                ]
            )
            return _ResolvedFont(
                size: requested,
                metrics: metrics,
                descriptor: descriptor,
                data: data,
                sfui: nil,
                symbolicTraits: []
            )
        }
    }
    var metrics = _PortableMetricsSnapshot()
    if !name.isEmpty
        && name != _PortableMetrics.postScriptName
        && name != _PortableMetrics.familyName
        && name != _PortableMetrics.fullName
    {
        metrics.postScriptName = name
        metrics.familyName = name
        metrics.fullName = name
    }
    let descriptor = CTFontDescriptor(
        attributes: [
            _ctString(kCTFontNameAttribute): metrics.postScriptName,
            _ctString(kCTFontFamilyNameAttribute): metrics.familyName,
            _ctString(kCTFontSizeAttribute): requested,
        ]
    )
    return _ResolvedFont(
        size: requested,
        metrics: metrics,
        descriptor: descriptor,
        data: nil,
        sfui: nil,
        symbolicTraits: []
    )
}

private func _CTFontResolve(descriptor: CTFontDescriptor, requestedSize: CGFloat) -> _ResolvedFont {
    let name = (descriptor.attributes[_ctString(kCTFontNameAttribute)] as? String)
        ?? (descriptor.attributes[_ctString(kCTFontFamilyNameAttribute)] as? String)
        ?? _PortableMetrics.postScriptName
    let sizeValue = descriptor.attributes[_ctString(kCTFontSizeAttribute)] as? CGFloat
        ?? (descriptor.attributes[_ctString(kCTFontSizeAttribute)] as? Double).map { CGFloat($0) }
        ?? (descriptor.attributes[_ctString(kCTFontSizeAttribute)] as? NSNumber).map { CGFloat($0.doubleValue) }
    let size = requestedSize > 0 ? requestedSize : (sizeValue ?? 12)
    var traits: CTFontSymbolicTraits = []
    if let traitsDict = descriptor.attributes[_ctString(kCTFontTraitsAttribute)] as? [String: Any],
       let raw = traitsDict[_ctString(kCTFontSymbolicTrait)] as? NSNumber {
        traits = CTFontSymbolicTraits(rawValue: raw.uint32Value)
    }
    var resolved = _CTFontResolve(name: name, size: size)
    if traits.contains(.boldTrait), resolved.sfui != nil {
        resolved = _CTFontResolveSFUI(size: size, bold: true)
    }
    resolved.symbolicTraits = traits.union(resolved.symbolicTraits)
    return resolved
}

private func _scale(_ font: CTFont, _ units: CGFloat) -> CGFloat {
    guard font.metrics.unitsPerEm > 0 else { return 0 }
    return units * font.size / font.metrics.unitsPerEm
}

public func CTFontDescriptorCreateWithNameAndSize(_ name: CFString, _ size: CGFloat) -> CTFontDescriptor {
    CTFontDescriptor(
        attributes: [
            _ctString(kCTFontNameAttribute): _ctString(name),
            _ctString(kCTFontSizeAttribute): size,
        ]
    )
}

public func CTFontDescriptorCreateWithAttributes(_ attributes: CFDictionary) -> CTFontDescriptor {
    var mapped: [String: Any] = [:]
    let ns = _ctNSDictionary(attributes)
    for (key, value) in ns {
        mapped["\(key)"] = value
    }
    return CTFontDescriptor(attributes: mapped)
}

public func CTFontDescriptorCopyAttributes(_ descriptor: CTFontDescriptor) -> CFDictionary {
    _ctCFDictionary(descriptor.attributes as NSDictionary)
}

public func CTFontDescriptorCopyAttribute(
    _ descriptor: CTFontDescriptor,
    _ attribute: CFString
) -> CFTypeRef? {
    descriptor.attributes[_ctString(attribute)] as CFTypeRef?
}

public func CTFontDescriptorCopyLocalizedAttribute(
    _ descriptor: CTFontDescriptor,
    _ attribute: CFString,
    _ language: UnsafeMutablePointer<Unmanaged<CFString>?>?
) -> CFTypeRef? {
    language?.pointee = nil
    return CTFontDescriptorCopyAttribute(descriptor, attribute)
}

public func CTFontDescriptorCreateCopyWithAttributes(
    _ original: CTFontDescriptor,
    _ attributes: CFDictionary
) -> CTFontDescriptor {
    var merged = original.attributes
    if let dict = attributes as? [String: Any] {
        for (key, value) in dict {
            merged[key] = value
        }
    } else {
        let ns = _ctNSDictionary(attributes)
        for (key, value) in ns {
            merged["\(key)"] = value
        }
    }
    return CTFontDescriptor(attributes: merged)
}

public func CTFontDescriptorCreateCopyWithFamily(
    _ original: CTFontDescriptor,
    _ family: CFString
) -> CTFontDescriptor {
    var merged = original.attributes
    merged[_ctString(kCTFontFamilyNameAttribute)] = _ctString(family)
    return CTFontDescriptor(attributes: merged)
}

public func CTFontDescriptorCreateCopyWithSymbolicTraits(
    _ original: CTFontDescriptor,
    _ symTraitValue: CTFontSymbolicTraits,
    _ symTraitMask: CTFontSymbolicTraits
) -> CTFontDescriptor {
    var merged = original.attributes
    let current: CTFontSymbolicTraits
    if let traits = merged[_ctString(kCTFontTraitsAttribute)] as? [String: Any],
       let raw = traits[_ctString(kCTFontSymbolicTrait)] as? NSNumber {
        current = CTFontSymbolicTraits(rawValue: raw.uint32Value)
    } else {
        current = []
    }
    let updated = CTFontSymbolicTraits(rawValue: (current.rawValue & ~symTraitMask.rawValue) | (symTraitValue.rawValue & symTraitMask.rawValue))
    var traitsDict: [String: Any] = [:]
    if let existing = merged[_ctString(kCTFontTraitsAttribute)] as? [String: Any] {
        traitsDict = existing
    }
    traitsDict[_ctString(kCTFontSymbolicTrait)] = NSNumber(value: updated.rawValue)
    merged[_ctString(kCTFontTraitsAttribute)] = traitsDict
    return CTFontDescriptor(attributes: merged)
}

public func CTFontDescriptorCreateCopyWithVariation(
    _ original: CTFontDescriptor,
    _ variationIdentifier: CFNumber,
    _ variationValue: CGFloat
) -> CTFontDescriptor {
    _ = (variationIdentifier, variationValue)
    return original
}

public func CTFontDescriptorCreateCopyWithFeature(
    _ original: CTFontDescriptor,
    _ featureTypeIdentifier: CFNumber,
    _ featureSelectorIdentifier: CFNumber
) -> CTFontDescriptor {
    _ = (featureTypeIdentifier, featureSelectorIdentifier)
    return original
}

public func CTFontDescriptorCreateMatchingFontDescriptor(
    _ descriptor: CTFontDescriptor,
    _ mandatoryAttributes: CFSet?
) -> CTFontDescriptor? {
    _ctMatchFontDescriptors(descriptor, mandatoryAttributes).first
}

public func CTFontDescriptorCreateMatchingFontDescriptors(
    _ descriptor: CTFontDescriptor,
    _ mandatoryAttributes: CFSet?
) -> CFArray? {
    let matches = _ctMatchFontDescriptors(descriptor, mandatoryAttributes)
    return _ctCFArray(matches as NSArray)
}

private func _ctMatchFontDescriptors(
    _ descriptor: CTFontDescriptor,
    _ mandatoryAttributes: CFSet?
) -> [CTFontDescriptor] {
    _ = mandatoryAttributes
    let name = descriptor.attributes[_ctString(kCTFontNameAttribute)] as? String
    let family = descriptor.attributes[_ctString(kCTFontFamilyNameAttribute)] as? String
    var matches: [CTFontDescriptor] = []
    for candidate in _portableRegisteredDescriptors() {
        let candidateName = candidate.attributes[_ctString(kCTFontNameAttribute)] as? String
        let candidateFamily = candidate.attributes[_ctString(kCTFontFamilyNameAttribute)] as? String
        if let name, candidateName == name || candidateFamily == name {
            matches.append(candidate)
            continue
        }
        if let family, candidateFamily == family || candidateName == family {
            matches.append(candidate)
        }
    }
    if matches.isEmpty {
        return [descriptor]
    }
    return matches
}

public func CTFontDescriptorGetTypeID() -> CFTypeID { 0x4354_4445 }

public func CTFontDescriptorMatchFontDescriptorsWithProgressHandler(
    _ descriptors: CFArray,
    _ mandatoryAttributes: CFSet?,
    _ progressBlock: CTFontDescriptorProgressHandler?
) -> Bool {
    _ = mandatoryAttributes
    if let progressBlock {
        _ = progressBlock(.didBegin, _ctEmptyCFDictionary())
        _ = progressBlock(.didFinish, _ctEmptyCFDictionary())
    }
    return (_ctNSArray(descriptors)).count > 0
}

public func CTFontGetSize(_ font: CTFont) -> CGFloat { font.size }
public func CTFontGetAscent(_ font: CTFont) -> CGFloat { _scale(font, font.metrics.ascent) }
public func CTFontGetDescent(_ font: CTFont) -> CGFloat { _scale(font, font.metrics.descent) }
public func CTFontGetLeading(_ font: CTFont) -> CGFloat { _scale(font, font.metrics.leading) }
public func CTFontGetCapHeight(_ font: CTFont) -> CGFloat { _scale(font, font.metrics.capHeight) }
public func CTFontGetXHeight(_ font: CTFont) -> CGFloat { _scale(font, font.metrics.xHeight) }
public func CTFontGetUnderlinePosition(_ font: CTFont) -> CGFloat {
    _scale(font, font.metrics.underlinePosition)
}
public func CTFontGetUnderlineThickness(_ font: CTFont) -> CGFloat {
    _scale(font, font.metrics.underlineThickness)
}
public func CTFontGetSlantAngle(_ font: CTFont) -> CGFloat { 0 }
public func CTFontGetUnitsPerEm(_ font: CTFont) -> UInt32 { UInt32(font.metrics.unitsPerEm) }
public func CTFontGetGlyphCount(_ font: CTFont) -> CFIndex { font.metrics.glyphCount }
public func CTFontGetBoundingBox(_ font: CTFont) -> CGRect {
    let box = font.metrics.boundingBox
    let s = font.size / font.metrics.unitsPerEm
    return CGRect(
        x: box.origin.x * s,
        y: box.origin.y * s,
        width: box.size.width * s,
        height: box.size.height * s
    )
}
public func CTFontGetSymbolicTraits(_ font: CTFont) -> CTFontSymbolicTraits {
    font.symbolicTraits
}
public func CTFontGetStringEncoding(_ font: CTFont) -> CFStringEncoding {
    _ = font
    return CFStringBuiltInEncodings.UTF16.rawValue
}
public func CTFontGetTypeID() -> CFTypeID { 0x4354_464E }

public func CTFontCopyPostScriptName(_ font: CTFont) -> CFString {
    _ctCFString(font.metrics.postScriptName)
}
public func CTFontCopyFamilyName(_ font: CTFont) -> CFString {
    _ctCFString(font.metrics.familyName)
}
public func CTFontCopyFullName(_ font: CTFont) -> CFString {
    _ctCFString(font.metrics.fullName)
}
public func CTFontCopyDisplayName(_ font: CTFont) -> CFString {
    _ctCFString(font.metrics.fullName)
}
public func CTFontCopyName(_ font: CTFont, _ nameKey: CFString) -> CFString? {
    switch _ctString(nameKey) {
    case _ctString(kCTFontFamilyNameKey): return _ctCFString(font.metrics.familyName)
    case _ctString(kCTFontStyleNameKey), _ctString(kCTFontSubFamilyNameKey):
        return _ctCFString(font.metrics.styleName)
    case _ctString(kCTFontFullNameKey): return _ctCFString(font.metrics.fullName)
    case _ctString(kCTFontPostScriptNameKey): return _ctCFString(font.metrics.postScriptName)
    default:
        if let value = font.metrics.nameIDs[_ctNameID(for: nameKey)] {
            return _ctCFString(value)
        }
        return nil
    }
}

private func _ctNameID(for key: CFString) -> Int {
    switch _ctString(key) {
    case _ctString(kCTFontCopyrightNameKey): return 0
    case _ctString(kCTFontFamilyNameKey): return 1
    case _ctString(kCTFontSubFamilyNameKey), _ctString(kCTFontStyleNameKey): return 2
    case _ctString(kCTFontUniqueNameKey): return 3
    case _ctString(kCTFontFullNameKey): return 4
    case _ctString(kCTFontVersionNameKey): return 5
    case _ctString(kCTFontPostScriptNameKey): return 6
    case _ctString(kCTFontTrademarkNameKey): return 7
    case _ctString(kCTFontManufacturerNameKey): return 8
    case _ctString(kCTFontDesignerNameKey): return 9
    case _ctString(kCTFontDescriptionNameKey): return 10
    case _ctString(kCTFontVendorURLNameKey): return 11
    case _ctString(kCTFontDesignerURLNameKey): return 12
    case _ctString(kCTFontLicenseNameKey): return 13
    case _ctString(kCTFontLicenseURLNameKey): return 14
    default: return -1
    }
}
public func CTFontCopyLocalizedName(
    _ font: CTFont,
    _ nameKey: CFString,
    _ actualLanguage: UnsafeMutablePointer<Unmanaged<CFString>?>?
) -> CFString? {
    actualLanguage?.pointee = nil
    return CTFontCopyName(font, nameKey)
}
public func CTFontCopyFontDescriptor(_ font: CTFont) -> CTFontDescriptor { font.descriptor }
public func CTFontCopyAttribute(_ font: CTFont, _ attribute: CFString) -> CFTypeRef? {
    if _ctString(attribute) == _ctString(kCTFontSizeAttribute) {
        return NSNumber(value: Double(font.size))
    }
    if let value = CTFontDescriptorCopyAttribute(font.descriptor, attribute) {
        return value
    }
    switch _ctString(attribute) {
    case _ctString(kCTFontNameAttribute):
        return _ctCFString(font.metrics.postScriptName)
    case _ctString(kCTFontFamilyNameAttribute):
        return _ctCFString(font.metrics.familyName)
    case _ctString(kCTFontDisplayNameAttribute):
        return _ctCFString(font.metrics.fullName)
    case _ctString(kCTFontStyleNameAttribute):
        return _ctCFString(font.metrics.styleName)
    default:
        return nil
    }
}
public func CTFontCopyTraits(_ font: CTFont) -> CFDictionary {
    // Bold weight 0.4 MEASURED 2026-09-05 Darwin CTFontCopyTraits on
    // CTFontCreateCopyWithSymbolicTraits(.traitBold) at 17 pt. Regular is 0.
    let weight: CGFloat = font.symbolicTraits.contains(.boldTrait) ? 0.4 : 0
    let traits: [String: Any] = [
        _ctString(kCTFontSymbolicTrait): NSNumber(value: font.symbolicTraits.rawValue),
        _ctString(kCTFontWeightTrait): NSNumber(value: Double(weight)),
        _ctString(kCTFontSlantTrait): NSNumber(value: 0.0),
        _ctString(kCTFontWidthTrait): NSNumber(value: 0.0),
    ]
    return _ctCFDictionary(traits as NSDictionary)
}
public func CTFontCopyVariation(_ font: CTFont) -> CFDictionary? {
    _ = font
    return nil
}
public func CTFontCopyVariationAxes(_ font: CTFont) -> CFArray? {
    _ = font
    return nil
}
public func CTFontCopyFeatures(_ font: CTFont) -> CFArray? {
    _ = font
    return nil
}
public func CTFontCopyFeatureSettings(_ font: CTFont) -> CFArray? {
    _ = font
    return nil
}
public func CTFontCopySupportedLanguages(_ font: CTFont) -> CFArray {
    _ = font
    return _ctEmptyCFArray()
}
public func CTFontCopyCharacterSet(_ font: CTFont) -> CFCharacterSet {
    if !font.metrics.cmap.isEmpty {
        var scalars: [Unicode.Scalar] = []
        for code in font.metrics.cmap.keys.sorted() {
            if let scalar = Unicode.Scalar(code) {
                scalars.append(scalar)
            }
        }
        return _ctCFCharacterSet(NSCharacterSet(charactersIn: String(String.UnicodeScalarView(scalars))))
    }
    return _ctCFCharacterSet(NSCharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") )
}
public func CTFontCopyAvailableTables(_ font: CTFont, _ options: CTFontTableOptions) -> CFArray? {
    _ = options
    let tags = font.metrics.tableBytes.keys.sorted().map { NSNumber(value: $0) }
    if tags.isEmpty { return nil }
    return _ctCFArray(tags as NSArray)
}
public func CTFontCopyTable(
    _ font: CTFont,
    _ table: CTFontTableTag,
    _ options: CTFontTableOptions
) -> CFData? {
    _ = options
    guard let bytes = font.metrics.tableBytes[table] else { return nil }
    return _ctCFData(bytes)
}
public func CTFontHasTable(_ font: CTFont, _ tag: CTFontTableTag) -> Bool {
    font.metrics.tableBytes[tableTagValue(tag)] != nil
}

private func tableTagValue(_ tag: CTFontTableTag) -> UInt32 { tag }
public func CTFontCopyDefaultCascadeListForLanguages(
    _ font: CTFont,
    _ languagePrefList: CFArray?
) -> CFArray? {
    _ = (font, languagePrefList)
    return nil
}

public func CTFontCreateForString(
    _ currentFont: CTFont,
    _ string: CFString,
    _ range: CFRange
) -> CTFont {
    CTFont(font: currentFont, string: string, range: range)
}

public func CTFontCreateForStringWithLanguage(
    _ currentFont: CTFont,
    _ string: CFString,
    _ range: CFRange,
    _ language: CFString?
) -> CTFont {
    CTFont(font: currentFont, string: string, range: range, language: language)
}

public func CTFontCreateUIFontForLanguage(
    _ uiType: CTFontUIFontType,
    _ size: CGFloat,
    _ language: CFString?
) -> CTFont? {
    if uiType == .none { return nil }
    return CTFont(uiType, size: size, language: language)
}

public func CTFontCollectionGetTypeID() -> CFTypeID { 0x4354_434C }

public func CTFontCollectionCreateWithFontDescriptors(
    _ queryDescriptors: CFArray?,
    _ options: CFDictionary?
) -> CTFontCollection {
    let descriptors: [CTFontDescriptor]
    if let queryDescriptors {
        descriptors = _ctNSArray(queryDescriptors).compactMap { $0 as? CTFontDescriptor }
    } else {
        descriptors = []
    }
    var mapped: [String: Any] = [:]
    if let options {
        let ns = _ctNSDictionary(options)
        for (key, value) in ns {
            mapped["\(key)"] = value
        }
    }
    return CTFontCollection(descriptors: descriptors, options: mapped)
}

public func CTFontCollectionCreateFromAvailableFonts(_ options: CFDictionary?) -> CTFontCollection {
    let names = _portableAvailablePostScriptNames()
    let descriptors = names.map { CTFontDescriptorCreateWithNameAndSize(_ctCFString($0), 0) }
    return CTFontCollectionCreateWithFontDescriptors(_ctCFArray(descriptors as NSArray), options)
}

public func CTFontCollectionCreateCopyWithFontDescriptors(
    _ original: CTFontCollection,
    _ queryDescriptors: CFArray?,
    _ options: CFDictionary?
) -> CTFontCollection {
    let extra: [CTFontDescriptor]
    if let queryDescriptors {
        extra = _ctNSArray(queryDescriptors).compactMap { $0 as? CTFontDescriptor }
    } else {
        extra = []
    }
    var mapped = original.options
    if let options {
        let ns = _ctNSDictionary(options)
        for (key, value) in ns {
            mapped["\(key)"] = value
        }
    }
    return CTFontCollection(descriptors: original.descriptors + extra, options: mapped)
}

public func CTFontCollectionCreateMatchingFontDescriptors(_ collection: CTFontCollection) -> CFArray? {
    _ctCFArray(collection.descriptors as NSArray)
}

public func CTFontCollectionCreateMatchingFontDescriptorsWithOptions(
    _ collection: CTFontCollection,
    _ options: CFDictionary?
) -> CFArray? {
    _ = options
    return _ctCFArray(collection.descriptors as NSArray)
}

public func CTFontCollectionCreateMatchingFontDescriptorsSortedWithCallback(
    _ collection: CTFontCollection,
    _ sortCallback: CTFontCollectionSortDescriptorsCallback?,
    _ refCon: UnsafeMutableRawPointer?
) -> CFArray? {
    var descriptors = collection.descriptors
    if let sortCallback {
        descriptors.sort { a, b in
            sortCallback(a, b, refCon ?? UnsafeMutableRawPointer(bitPattern: 1)!) == .compareLessThan
        }
    }
    return _ctCFArray(descriptors as NSArray)
}

public func CTFontCollectionCopyFontAttribute(
    _ collection: CTFontCollection,
    _ attributeName: CFString,
    _ options: CTFontCollectionCopyOptions
) -> CFArray {
    _ = options
    let values = collection.descriptors.compactMap {
        CTFontDescriptorCopyAttribute($0, attributeName)
    }
    return _ctCFArray(values as NSArray)
}

public func CTFontCollectionCopyFontAttributes(
    _ collection: CTFontCollection,
    _ attributeNames: CFSet,
    _ options: CTFontCollectionCopyOptions
) -> CFArray {
    _ = (attributeNames, options)
    let values = collection.descriptors.map { CTFontDescriptorCopyAttributes($0) }
    return _ctCFArray(values as NSArray)
}

func _ctGlyphForCharacter(_ font: CTFont, _ scalar: UInt32) -> CGGlyph {
    if font.sfui != nil {
        return CGGlyph(truncatingIfNeeded: scalar)
    }
    if !font.metrics.cmap.isEmpty {
        return CGGlyph(font.metrics.cmap[scalar] ?? 0)
    }
    return CGGlyph(truncatingIfNeeded: scalar)
}

func _ctApplyFontMatrix(_ font: CTFont, width: CGFloat) -> CGFloat {
    width * font.matrix.a
}

func _ctAdvance(for font: CTFont, glyph: CGGlyph) -> CGFloat {
    let width: CGFloat
    if font.sfui != nil {
        width = _SFUITable.advance(font.sfui!, scalar: UInt32(glyph))
    } else {
        let index = Int(glyph)
        if index >= 0, index < font.metrics.advanceWidths.count {
            width = _scale(font, font.metrics.advanceWidths[index])
        } else {
            width = max(font.size * 0.5, 1)
        }
    }
    return _ctApplyFontMatrix(font, width: width)
}

func _ctGlyphBounds(for font: CTFont, glyph: CGGlyph) -> CGRect {
    let index = Int(glyph)
    if index >= 0, index < font.metrics.glyphBounds.count {
        let box = font.metrics.glyphBounds[index]
        let s = font.metrics.unitsPerEm > 0 ? font.size / font.metrics.unitsPerEm : 0
        return CGRect(
            x: box.origin.x * s * font.matrix.a,
            y: box.origin.y * s * font.matrix.d,
            width: box.size.width * s * font.matrix.a,
            height: box.size.height * s * font.matrix.d
        )
    }
    let width = _ctAdvance(for: font, glyph: glyph)
    return CGRect(x: 0, y: -CTFontGetDescent(font), width: width, height: CTFontGetAscent(font) + CTFontGetDescent(font))
}

func _ctCharAdvance(_ font: CTFont, scalar: UInt32) -> CGFloat {
    if let face = font.sfui {
        return _SFUITable.advance(face, scalar: scalar)
    }
    return _ctAdvance(for: font, glyph: _ctGlyphForCharacter(font, scalar))
}

func _ctGlyphForCharacter(_ scalar: UniChar) -> CGGlyph {
    CGGlyph(scalar)
}

public func CTFontCreateWithName(
    _ name: CFString,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?
) -> CTFont {
    CTFont(name: _ctString(name), size: size, matrix: matrix?.pointee ?? _ctIdentityTransform())
}

public func CTFontCreateWithNameAndOptions(
    _ name: CFString,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?,
    _ options: CTFontOptions
) -> CTFont {
    _ = options
    return CTFontCreateWithName(name, size, matrix)
}

public func CTFontCreateWithFontDescriptor(
    _ descriptor: CTFontDescriptor,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?
) -> CTFont {
    CTFont(descriptor, transform: matrix?.pointee ?? _ctIdentityTransform(), requestedSize: size)
}

public func CTFontCreateWithFontDescriptorAndOptions(
    _ descriptor: CTFontDescriptor,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?,
    _ options: CTFontOptions
) -> CTFont {
    _ = options
    return CTFontCreateWithFontDescriptor(descriptor, size, matrix)
}

public func CTFontCreateCopyWithAttributes(
    _ font: CTFont,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?,
    _ attributes: CTFontDescriptor?
) -> CTFont {
    let base: CTFontDescriptor
    if let attributes {
        base = CTFontDescriptorCreateCopyWithAttributes(
            font.descriptor,
            CTFontDescriptorCopyAttributes(attributes)
        )
    } else {
        base = font.descriptor
    }
    let resolvedSize = size > 0 ? size : font.size
    var transform = matrix?.pointee ?? font.matrix
    return withUnsafePointer(to: &transform) { pointer in
        CTFontCreateWithFontDescriptor(base, resolvedSize, pointer)
    }
}

public func CTFontCreateCopyWithFamily(
    _ font: CTFont,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?,
    _ family: CFString
) -> CTFont? {
    let copied = CTFontDescriptorCreateCopyWithFamily(font.descriptor, family)
    let resolvedSize = size > 0 ? size : font.size
    return CTFontCreateWithFontDescriptor(copied, resolvedSize, matrix)
}

public func CTFontCreateCopyWithSymbolicTraits(
    _ font: CTFont,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?,
    _ symTraitValue: CTFontSymbolicTraits,
    _ symTraitMask: CTFontSymbolicTraits
) -> CTFont? {
    let copied = CTFontDescriptorCreateCopyWithSymbolicTraits(font.descriptor, symTraitValue, symTraitMask)
    let resolvedSize = size > 0 ? size : font.size
    let created = CTFontCreateWithFontDescriptor(copied, resolvedSize, matrix)
    let traits = CTFontSymbolicTraits(
        rawValue: (font.symbolicTraits.rawValue & ~symTraitMask.rawValue)
            | (symTraitValue.rawValue & symTraitMask.rawValue)
    )
    let bold = traits.contains(.boldTrait)
    if font.sfui != nil || _SFUITable.isSystemName(font.metrics.postScriptName) {
        let resolved = _CTFontResolveSFUI(size: resolvedSize, bold: bold)
        return CTFont(
            size: resolved.size,
            metrics: resolved.metrics,
            descriptor: resolved.descriptor,
            data: nil,
            matrix: matrix?.pointee ?? font.matrix,
            sfui: resolved.sfui,
            symbolicTraits: traits
        )
    }
    return CTFont(
        size: created.size,
        metrics: created.metrics,
        descriptor: created.descriptor,
        data: created.data,
        matrix: matrix?.pointee ?? font.matrix,
        sfui: created.sfui,
        symbolicTraits: traits
    )
}

public func CTFontGetMatrix(_ font: CTFont) -> CGAffineTransform {
    font.matrix
}

public func CTFontGetGlyphsForCharacters(
    _ font: CTFont,
    _ characters: UnsafePointer<UniChar>,
    _ glyphs: UnsafeMutablePointer<CGGlyph>,
    _ count: CFIndex
) -> Bool {
    guard count > 0 else { return true }
    var missing = false
    for i in 0..<count {
        let ch = characters[i]
        if ch == 0 {
            glyphs[i] = 0
            missing = true
            continue
        }
        let mapped = _ctGlyphForCharacter(font, UInt32(ch))
        glyphs[i] = mapped
        if mapped == 0, font.data != nil, font.metrics.cmap[UInt32(ch)] == nil {
            missing = true
        }
    }
    return !missing
}

public func CTFontGetAdvancesForGlyphs(
    _ font: CTFont,
    _ orientation: CTFontOrientation,
    _ glyphs: UnsafePointer<CGGlyph>,
    _ advances: UnsafeMutablePointer<CGSize>?,
    _ count: CFIndex
) -> Double {
    _ = orientation
    var total: Double = 0
    for i in 0..<count {
        let width = _ctAdvance(for: font, glyph: glyphs[i])
        total += Double(width)
        advances?[i] = CGSize(width: width, height: 0)
    }
    return total
}

public func CTFontGetBoundingRectsForGlyphs(
    _ font: CTFont,
    _ orientation: CTFontOrientation,
    _ glyphs: UnsafePointer<CGGlyph>,
    _ boundingRects: UnsafeMutablePointer<CGRect>?,
    _ count: CFIndex
) -> CGRect {
    _ = orientation
    var unionRect = CGRect.zero
    var haveUnion = false
    for i in 0..<count {
        let box = _ctGlyphBounds(for: font, glyph: glyphs[i])
        boundingRects?[i] = box
        if !haveUnion {
            unionRect = box
            haveUnion = true
        } else {
            unionRect = unionRect.union(box)
        }
    }
    return haveUnion ? unionRect : .zero
}

public func CTFontGetOpticalBoundsForGlyphs(
    _ font: CTFont,
    _ glyphs: UnsafePointer<CGGlyph>,
    _ boundingRects: UnsafeMutablePointer<CGRect>?,
    _ count: CFIndex,
    _ options: CFOptionFlags
) -> CGRect {
    _ = options
    return CTFontGetBoundingRectsForGlyphs(font, .horizontal, glyphs, boundingRects, count)
}

public func CTFontGetVerticalTranslationsForGlyphs(
    _ font: CTFont,
    _ glyphs: UnsafePointer<CGGlyph>,
    _ translations: UnsafeMutablePointer<CGSize>,
    _ count: CFIndex
) {
    _ = (font, glyphs)
    for i in 0..<count {
        translations[i] = .zero
    }
}

public func CTFontGetLigatureCaretPositions(
    _ font: CTFont,
    _ glyph: CGGlyph,
    _ positions: UnsafeMutablePointer<CGFloat>?,
    _ maxPositions: CFIndex
) -> CFIndex {
    _ = (font, glyph, positions, maxPositions)
    return 0
}

public func CTFontGetGlyphWithName(_ font: CTFont, _ glyphName: CFString) -> CGGlyph {
    let name = _ctString(glyphName)
    if name.count == 1, let scalar = name.unicodeScalars.first {
        let mapped = _ctGlyphForCharacter(font, scalar.value)
        if mapped != 0 || font.metrics.cmap[scalar.value] != nil {
            return mapped
        }
        return CGGlyph(truncatingIfNeeded: scalar.value)
    }
    if name == "space" {
        let mapped = _ctGlyphForCharacter(font, 0x20)
        return mapped != 0 ? mapped : 32
    }
    return 0
}

public func CTFontCopyNameForGlyph(_ font: CTFont, _ glyph: CGGlyph) -> CFString? {
    _ = font
    if glyph >= 32 && glyph <= 126, let scalar = Unicode.Scalar(UInt32(glyph)) {
        return _ctCFString(String(scalar))
    }
    return nil
}

public func CTFontCreatePathForGlyph(
    _ font: CTFont,
    _ glyph: CGGlyph,
    _ matrix: UnsafePointer<CGAffineTransform>?
) -> CGPath? {
    let box = _ctGlyphBounds(for: font, glyph: glyph)
    return CGPath(rect: box, transform: matrix)
}

public func CTFontDrawGlyphs(
    _ font: CTFont,
    _ glyphs: UnsafePointer<CGGlyph>,
    _ positions: UnsafePointer<CGPoint>,
    _ count: Int,
    _ context: CGContext
) {
    _ = (font, glyphs, positions, count)
    _ctRecordLineDraw(context)
}

public func CTFontCopyGraphicsFont(
    _ font: CTFont,
    _ attributes: UnsafeMutablePointer<Unmanaged<CTFontDescriptor>?>?
) -> CGFont {
    attributes?.pointee = Unmanaged.passRetained(font.descriptor)
    return _ctMakeGraphicsFont(named: font.metrics.postScriptName)
}

public func CTFontCreateWithGraphicsFont(
    _ graphicsFont: CGFont,
    _ size: CGFloat,
    _ matrix: UnsafePointer<CGAffineTransform>?,
    _ attributes: CTFontDescriptor?
) -> CTFont {
    _ = attributes
    return CTFontCreateWithName(
        _ctCFString(_ctGraphicsFontName(graphicsFont)),
        size,
        matrix
    )
}

public func CTFontDrawImageFromAdaptiveImageProviderAtPoint(
    _ font: CTFont,
    _ provider: any CTAdaptiveImageProviding,
    _ point: CGPoint,
    _ context: CGContext
) {
    _ = (font, provider, point)
    _ctRecordLineDraw(context)
}

public func CTFontManagerRegisterGraphicsFont(
    _ font: CGFont,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    _ = font
    if let error {
        let value = NSError(
            domain: _ctString(kCTFontManagerErrorDomain),
            code: CTFontManagerError.unsupportedScope.rawValue,
            userInfo: nil
        )
        error.pointee = Unmanaged.passRetained(_ctCFError(value))
    }
    return false
}

public func CTFontManagerUnregisterGraphicsFont(
    _ font: CGFont,
    _ error: UnsafeMutablePointer<Unmanaged<CFError>?>?
) -> Bool {
    return CTFontManagerRegisterGraphicsFont(font, error)
}
