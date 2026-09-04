import CoreFoundation
import Foundation

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
            cursor += 16
        }
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
        }
        if let hhea = tables[0x6868_6561], hhea.1 >= 8 { // hhea
            let o = hhea.0
            metrics.ascent = CGFloat(reader.i16(o + 4))
            metrics.descent = CGFloat(-reader.i16(o + 6))
            if hhea.1 >= 10 {
                metrics.leading = CGFloat(reader.i16(o + 8))
            }
        }
        if let maxp = tables[0x6D61_7870], maxp.1 >= 6 { // maxp
            metrics.glyphCount = Int(reader.u16(maxp.0 + 4))
        }
        if let os2 = tables[0x4F53_2F32], os2.1 >= 70 { // OS/2
            let o = os2.0
            metrics.xHeight = CGFloat(reader.i16(o + 86))
            if os2.1 >= 88 {
                metrics.capHeight = CGFloat(reader.i16(o + 88))
            }
        }
        if let post = tables[0x706F_7374], post.1 >= 12 { // post
            metrics.underlinePosition = CGFloat(reader.i16(post.0 + 8))
            metrics.underlineThickness = CGFloat(reader.i16(post.0 + 10))
        }
        if let name = tables[0x6E61_6D65] {
            let names = reader.nameTable(at: name.0, length: name.1)
            if let family = names[1] { metrics.familyName = family }
            if let style = names[2] { metrics.styleName = style }
            if let full = names[4] { metrics.fullName = full }
            if let ps = names[6] { metrics.postScriptName = ps }
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

    init(size: CGFloat, metrics: _SFNTMetrics, descriptor: CTFontDescriptor, data: Data?) {
        self.size = size > 0 ? size : 12
        self.metrics = metrics
        self.descriptor = descriptor
        self.data = data
    }

    public convenience init(_ name: CFString, size: CGFloat) {
        self.init(name: _ctString(name), size: size)
    }

    public convenience init(_ descriptor: CTFontDescriptor, size: CGFloat) {
        let resolved = _CTFontResolve(descriptor: descriptor, requestedSize: size)
        self.init(
            size: resolved.size,
            metrics: resolved.metrics,
            descriptor: resolved.descriptor,
            data: resolved.data
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
        var metrics = _PortableMetricsSnapshot()
        metrics.familyName = "OpenUIKit UI"
        metrics.postScriptName = "OpenUIKitUI-\(uiType)"
        metrics.fullName = "OpenUIKit UI \(uiType)"
        let descriptor = CTFontDescriptor(
            attributes: [
                _ctString(kCTFontNameAttribute): metrics.postScriptName,
                _ctString(kCTFontFamilyNameAttribute): metrics.familyName,
                _ctString(kCTFontSizeAttribute): resolvedSize,
            ]
        )
        self.init(size: resolvedSize, metrics: metrics, descriptor: descriptor, data: nil)
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
            data: currentFont.data
        )
    }

    convenience init(name: String, size: CGFloat) {
        let resolved = _CTFontResolve(name: name, size: size)
        self.init(
            size: resolved.size,
            metrics: resolved.metrics,
            descriptor: resolved.descriptor,
            data: resolved.data
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

private struct _ResolvedFont {
    var size: CGFloat
    var metrics: _SFNTMetrics
    var descriptor: CTFontDescriptor
    var data: Data?
}

private func _CTFontResolve(name: String, size: CGFloat) -> _ResolvedFont {
    let requested = size > 0 ? size : 12
    for data in _portableCopyRegisteredData() {
        let metrics = _SFNTMetrics.parse(data: data)
        if metrics.postScriptName == name
            || metrics.familyName == name
            || metrics.fullName == name
        {
            let descriptor = CTFontDescriptor(
                attributes: [
                    _ctString(kCTFontNameAttribute): metrics.postScriptName,
                    _ctString(kCTFontFamilyNameAttribute): metrics.familyName,
                    _ctString(kCTFontSizeAttribute): requested,
                ]
            )
            return _ResolvedFont(size: requested, metrics: metrics, descriptor: descriptor, data: data)
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
    return _ResolvedFont(size: requested, metrics: metrics, descriptor: descriptor, data: nil)
}

private func _CTFontResolve(descriptor: CTFontDescriptor, requestedSize: CGFloat) -> _ResolvedFont {
    let name = (descriptor.attributes[_ctString(kCTFontNameAttribute)] as? String)
        ?? (descriptor.attributes[_ctString(kCTFontFamilyNameAttribute)] as? String)
        ?? _PortableMetrics.postScriptName
    let sizeValue = descriptor.attributes[_ctString(kCTFontSizeAttribute)] as? CGFloat
    let size = requestedSize > 0 ? requestedSize : (sizeValue ?? 12)
    return _CTFontResolve(name: name, size: size)
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
    _ = (symTraitValue, symTraitMask)
    return original
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
    _ = mandatoryAttributes
    return descriptor
}

public func CTFontDescriptorCreateMatchingFontDescriptors(
    _ descriptor: CTFontDescriptor,
    _ mandatoryAttributes: CFSet?
) -> CFArray? {
    _ = mandatoryAttributes
    return _ctCFArray([descriptor] as NSArray)
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
    _ = font
    return []
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
    case _ctString(kCTFontStyleNameKey): return _ctCFString(font.metrics.styleName)
    case _ctString(kCTFontFullNameKey): return _ctCFString(font.metrics.fullName)
    case _ctString(kCTFontPostScriptNameKey): return _ctCFString(font.metrics.postScriptName)
    default: return nil
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
    CTFontDescriptorCopyAttribute(font.descriptor, attribute)
}
public func CTFontCopyTraits(_ font: CTFont) -> CFDictionary {
    _ = font
    return _ctEmptyCFDictionary()
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
    _ = font
    return _ctCFCharacterSet(NSCharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789") )
}
public func CTFontCopyAvailableTables(_ font: CTFont, _ options: CTFontTableOptions) -> CFArray? {
    _ = (font, options)
    return nil
}
public func CTFontCopyTable(
    _ font: CTFont,
    _ table: CTFontTableTag,
    _ options: CTFontTableOptions
) -> CFData? {
    _ = (font, table, options)
    return nil
}
public func CTFontHasTable(_ font: CTFont, _ tag: CTFontTableTag) -> Bool {
    _ = (font, tag)
    return false
}
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
