// NSString's Objective-C selectors, NSMutableString, and constant strings.

import Foundation
import ObjectiveC

// MARK: - The facade NSString's storage, located at run time

/// The facade stores one Swift String and a NUL-terminated UTF-8 copy
/// (`_foundationGuestString`, `_utf8Storage`). NSMutableString and the
/// constant-string fix-up must write them, so their offsets are read from the
/// Objective-C ivar list and checked, never assumed.
struct _OFStringLayout {
    let string: Int
    let utf8: Int
    let instanceSize: Int

    static let current: _OFStringLayout = {
        guard let string = class_getInstanceVariable(NSString.self, "_foundationGuestString"),
              let utf8 = class_getInstanceVariable(NSString.self, "_utf8Storage") else {
            fatalError("FoundationObjCBridge: Foundation.NSString no longer has _foundationGuestString/_utf8Storage")
        }
        let layout = _OFStringLayout(string: ivar_getOffset(string), utf8: ivar_getOffset(utf8),
                                     instanceSize: class_getInstanceSize(NSString.self))
        // A clang constant CFString record is 32 bytes: the facade instance must fit it.
        precondition(layout.string == 8 && layout.utf8 == 24 && layout.instanceSize == 32,
                     "FoundationObjCBridge: Foundation.NSString layout changed (\(layout))")
        return layout
    }()
}

func _ofUTF8Buffer(_ value: String) -> UnsafeMutablePointer<CChar> {
    let bytes = Array(value.utf8)
    let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count + 1)
    buffer.initialize(repeating: 0, count: bytes.count + 1)
    for (index, byte) in bytes.enumerated() { buffer[index] = CChar(bitPattern: byte) }
    return buffer
}

/// Replaces an initialized facade NSString's contents in place, keeping the
/// facade's invariant (the UTF-8 buffer holds utf8.count + 1 bytes).
func _ofReplaceStorage(_ object: NSString, with value: String) {
    let layout = _OFStringLayout.current
    let base = Unmanaged.passUnretained(object).toOpaque()
    let stringSlot = (base + layout.string).assumingMemoryBound(to: String.self)
    let utf8Slot = (base + layout.utf8).assumingMemoryBound(to: UnsafeMutablePointer<CChar>.self)
    let oldCount = stringSlot.pointee.utf8.count
    let oldBuffer = utf8Slot.pointee
    stringSlot.pointee = value
    utf8Slot.pointee = _ofUTF8Buffer(value)
    oldBuffer.deinitialize(count: oldCount + 1)
    oldBuffer.deallocate()
}

extension NSString {
    var _of_string: String { String(self) }
}

// MARK: - Numeric values, as -intValue & co. read them

private func _ofLeadingInteger(_ text: String) -> Int64 {
    text.withCString { strtoll($0, nil, 10) }
}

private func _ofLeadingDouble(_ text: String) -> Double {
    text.withCString { strtod($0, nil) }
}

private func _ofBoolValue(_ text: String) -> Bool {
    var scalars = Substring(text).unicodeScalars.drop { $0 == " " || $0 == "\t" || $0 == "\n" }
    if let first = scalars.first, first == "+" || first == "-" { scalars = scalars.dropFirst() }
    scalars = scalars.drop { $0 == "0" }
    guard let first = scalars.first else { return false }
    return "YyTt123456789".unicodeScalars.contains(first)
}

// MARK: - Encodings: UTF-8 and ASCII only (others fail closed, returning nil)

private func _ofEncode(_ text: String, _ encoding: UInt, lossy: Bool) -> [UInt8]? {
    switch encoding {
    case 4: return Array(text.utf8)                                   // NSUTF8StringEncoding
    case 1:                                                             // NSASCIIStringEncoding
        var bytes: [UInt8] = []
        for scalar in text.unicodeScalars {
            if scalar.isASCII { bytes.append(UInt8(scalar.value)) }
            else if lossy { bytes.append(UInt8(ascii: "?")) }
            else { return nil }
        }
        return bytes
    default: return nil
    }
}

private func _ofDecode(_ bytes: UnsafeRawBufferPointer, _ encoding: UInt) -> String? {
    switch encoding {
    case 4: return String(validating: bytes.bindMemory(to: UInt8.self), as: UTF8.self)
    case 1:
        guard bytes.allSatisfy({ $0 < 0x80 }) else { return nil }
        return String(decoding: bytes.bindMemory(to: UInt8.self), as: UTF8.self)
    default: return nil
    }
}

func _ofComponents(_ text: String, _ separator: String) -> [String] {
    guard !separator.isEmpty else { return [text] }
    var result: [String] = []
    var start = text.startIndex
    while let range = text.range(of: separator, options: .literal, range: start..<text.endIndex) {
        result.append(String(text[start..<range.lowerBound]))
        start = range.upperBound
    }
    result.append(String(text[start...]))
    return result
}

private func _ofUTF16Range(_ text: String, _ location: Int, _ length: Int) -> Range<String.Index> {
    let utf16 = text.utf16
    precondition(location >= 0 && length >= 0 && location + length <= utf16.count,
                 "NSString range {\(location), \(length)} out of bounds; string length \(utf16.count)")
    let lower = utf16.index(utf16.startIndex, offsetBy: location)
    let upper = utf16.index(lower, offsetBy: length)
    return lower..<upper
}

private func _ofCompare(_ lhs: String, _ rhs: String, options: UInt) -> Int {
    var left = lhs
    var right = rhs
    if options & 1 != 0 { left = left.lowercased(); right = right.lowercased() }   // NSCaseInsensitiveSearch
    if options & 64 != 0 {                                                          // NSNumericSearch
        return left.compare(right, options: .numeric).rawValue
    }
    let a = Array(left.utf16), b = Array(right.utf16)
    for (x, y) in zip(a, b) where x != y { return x < y ? -1 : 1 }
    return a.count == b.count ? 0 : (a.count < b.count ? -1 : 1)
}

private func _ofFind(_ text: String, _ target: String, options: UInt, within: Range<String.Index>? = nil) -> Range<String.Index>? {
    guard !target.isEmpty else { return nil }
    var compareOptions: String.CompareOptions = []
    if options & 1 != 0 { compareOptions.insert(.caseInsensitive) }
    if options & 4 != 0 { compareOptions.insert(.backwards) }
    if options & 8 != 0 { compareOptions.insert(.anchored) }
    if options & 2 != 0 { compareOptions.insert(.literal) }
    return text.range(of: target, options: compareOptions, range: within)
}

// MARK: - NSString's Objective-C surface

extension NSString {
    @objc(length) public var _of_length: Int { length }
    @objc(characterAtIndex:) public func _of_characterAtIndex(_ index: Int) -> UInt16 { character(at: index) }
    @objc(_of_getCharacters:location:length:) public func _of_getCharacters(_ buffer: UnsafeMutablePointer<UInt16>, location: Int, length: Int) {
        let units = Array(_of_string.utf16)
        precondition(location >= 0 && length >= 0 && location + length <= units.count, "NSString getCharacters:range: out of bounds")
        for index in 0..<length { buffer[index] = units[location + index] }
    }
    @objc(substringFromIndex:) public func _of_substringFromIndex(_ from: Int) -> NSString { NSString(string: substring(from: from)) }
    @objc(substringToIndex:) public func _of_substringToIndex(_ to: Int) -> NSString { NSString(string: substring(to: to)) }
    @objc(_of_substringWithLocation:length:) public func _of_substring(location: Int, length: Int) -> NSString {
        NSString(string: String(_of_string[_ofUTF16Range(_of_string, location, length)]))
    }
    @objc(compare:) public func _of_compare(_ other: NSString) -> Int { _ofCompare(_of_string, other._of_string, options: 0) }
    @objc(compare:options:) public func _of_compare(_ other: NSString, options: UInt) -> Int {
        _ofCompare(_of_string, other._of_string, options: options)
    }
    @objc(caseInsensitiveCompare:) public func _of_caseInsensitiveCompare(_ other: NSString) -> Int {
        _ofCompare(_of_string, other._of_string, options: 1)
    }
    @objc(localizedCompare:) public func _of_localizedCompare(_ other: NSString) -> Int { _of_compare(other) }
    @objc(localizedCaseInsensitiveCompare:) public func _of_localizedCaseInsensitiveCompare(_ other: NSString) -> Int {
        _of_caseInsensitiveCompare(other)
    }
    @objc(isEqualToString:) public func _of_isEqualToString(_ other: NSString?) -> Bool {
        guard let other else { return false }
        return _of_string == other._of_string
    }
    @objc(hasPrefix:) public func _of_hasPrefix(_ prefix: NSString) -> Bool {
        let p = prefix._of_string
        return !p.isEmpty && Array(_of_string.utf16).starts(with: p.utf16)
    }
    @objc(hasSuffix:) public func _of_hasSuffix(_ suffix: NSString) -> Bool {
        let s = suffix._of_string
        return !s.isEmpty && Array(_of_string.utf16).reversed().starts(with: Array(s.utf16).reversed())
    }
    @objc(containsString:) public func _of_containsString(_ other: NSString) -> Bool {
        _ofFind(_of_string, other._of_string, options: 2) != nil
    }
    /// -rangeOfString:options:range: through its location/length; NSNotFound
    /// location when absent. The NSRange-taking selectors are in ../src.
    @objc(_of_rangeOfString:options:location:length:outLength:)
    public func _of_rangeOfString(_ target: NSString, options: UInt, location: Int, length: Int,
                                  outLength: UnsafeMutablePointer<Int>) -> Int {
        let text = _of_string
        guard let found = _ofFind(text, target._of_string, options: options, within: _ofUTF16Range(text, location, length)) else {
            outLength.pointee = 0
            return Int.max
        }
        let utf16 = text.utf16
        outLength.pointee = utf16.distance(from: found.lowerBound, to: found.upperBound)
        return utf16.distance(from: utf16.startIndex, to: found.lowerBound)
    }
    @objc(stringByAppendingString:) public func _of_appending(_ other: NSString) -> NSString {
        NSString(string: _of_string + other._of_string)
    }
    @objc(doubleValue) public var _of_doubleValue: Double { _ofLeadingDouble(_of_string) }
    @objc(floatValue) public var _of_floatValue: Float { Float(_ofLeadingDouble(_of_string)) }
    @objc(intValue) public var _of_intValue: Int32 { Int32(clamping: _ofLeadingInteger(_of_string)) }
    @objc(integerValue) public var _of_integerValue: Int { Int(_ofLeadingInteger(_of_string)) }
    @objc(longLongValue) public var _of_longLongValue: Int64 { _ofLeadingInteger(_of_string) }
    @objc(boolValue) public var _of_boolValue: Bool { _ofBoolValue(_of_string) }
    @objc(uppercaseString) public var _of_uppercaseString: NSString { NSString(string: _of_string.uppercased()) }
    @objc(lowercaseString) public var _of_lowercaseString: NSString { NSString(string: _of_string.lowercased()) }
    @objc(capitalizedString) public var _of_capitalizedString: NSString {
        var result = ""
        var atWordStart = true
        for character in _of_string {
            if character.isLetter || character.isNumber {
                result += atWordStart ? character.uppercased() : character.lowercased()
                atWordStart = false
            } else {
                result.append(character)
                atWordStart = true
            }
        }
        return NSString(string: result)
    }
    @objc(UTF8String) public var _of_UTF8String: UnsafePointer<CChar>? { utf8String }
    @objc(fileSystemRepresentation) public var _of_fileSystemRepresentation: UnsafePointer<CChar>? { utf8String }
    @objc(description) public var _of_description: NSString { self }
    @objc(dataUsingEncoding:) public func _of_data(_ encoding: UInt) -> NSData? { _of_data(encoding, lossy: false) }
    @objc(dataUsingEncoding:allowLossyConversion:) public func _of_data(_ encoding: UInt, lossy: Bool) -> NSData? {
        guard let bytes = _ofEncode(_of_string, encoding, lossy: lossy) else { return nil }
        return NSData(data: Data(bytes))
    }
    @objc(cStringUsingEncoding:) public func _of_cString(_ encoding: UInt) -> UnsafePointer<CChar>? {
        guard var bytes = _ofEncode(_of_string, encoding, lossy: false) else { return nil }
        if encoding == 4 { return utf8String }
        bytes.append(0)
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: bytes.count)
        for (index, byte) in bytes.enumerated() { buffer[index] = CChar(bitPattern: byte) }
        // Lives as long as the string, like the SDK's inner pointer.
        _ofAssociate(self, _OFKeys.cString, _OFOwnedBuffer(buffer))
        return UnsafePointer(buffer)
    }
    @objc(lengthOfBytesUsingEncoding:) public func _of_lengthOfBytes(_ encoding: UInt) -> Int {
        _ofEncode(_of_string, encoding, lossy: false)?.count ?? 0
    }
    @objc(componentsSeparatedByString:) public func _of_components(_ separator: NSString) -> NSArray {
        NSArray(array: _ofComponents(_of_string, separator._of_string).map { NSString(string: $0) })
    }
    @objc(stringByReplacingOccurrencesOfString:withString:)
    public func _of_replacing(_ target: NSString, with replacement: NSString) -> NSString {
        _of_replacing(target, with: replacement, options: 0, location: 0, length: length)
    }
    @objc(_of_stringByReplacingOccurrencesOfString:withString:options:location:length:)
    public func _of_replacing(_ target: NSString, with replacement: NSString, options: UInt, location: Int, length: Int) -> NSString {
        NSString(string: _ofReplaceAll(_of_string, target._of_string, replacement._of_string, options, location, length).0)
    }
    @objc(_of_stringByReplacingCharactersInLocation:length:withString:)
    public func _of_replacingCharacters(location: Int, length: Int, with replacement: NSString) -> NSString {
        var text = _of_string
        text.replaceSubrange(_ofUTF16Range(text, location, length), with: replacement._of_string)
        return NSString(string: text)
    }
    @objc(lastPathComponent) public var _of_lastPathComponent: NSString { NSString(string: lastPathComponent) }
    @objc(pathExtension) public var _of_pathExtension: NSString { NSString(string: pathExtension) }
    @objc(stringByDeletingLastPathComponent) public var _of_deletingLastPathComponent: NSString {
        NSString(string: deletingLastPathComponent)
    }
    @objc(stringByDeletingPathExtension) public var _of_deletingPathExtension: NSString {
        NSString(string: deletingPathExtension)
    }
    @objc(stringByAppendingPathComponent:) public func _of_appendingPathComponent(_ component: NSString) -> NSString {
        NSString(string: appendingPathComponent(component._of_string))
    }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { copy() as AnyObject }
    @objc(mutableCopyWithZone:) public func _of_mutableCopyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject {
        NSMutableString(string: _of_string)
    }

    // Initializers: Objective-C's [[NSString alloc] initWith...] runs these on
    // the allocated instance; they delegate to the facade's designated init.
    @objc(initWithCharacters:length:) public convenience init(_of_characters characters: UnsafePointer<UInt16>, length: Int) {
        self.init(characters: characters, length: length)
    }
    @objc(initWithUTF8String:) public convenience init?(_of_utf8String bytes: UnsafePointer<CChar>?) {
        guard let bytes, let value = String(validatingCString: bytes) else { return nil }
        self.init(string: value)
    }
    @objc(initWithString:) public convenience init(_of_string other: NSString) {
        self.init(string: other._of_string)
    }
    @objc(_of_initWithUTF8Bytes:length:) public convenience init(_of_utf8Bytes bytes: UnsafePointer<CChar>, length: Int) {
        let buffer = UnsafeRawBufferPointer(start: bytes, count: length)
        self.init(string: String(decoding: buffer.bindMemory(to: UInt8.self), as: UTF8.self))
    }
    @objc(initWithData:encoding:) public convenience init?(_of_data data: NSData, encoding: UInt) {
        let bytes = [UInt8](Data(data))
        guard let value = bytes.withUnsafeBytes({ _ofDecode($0, encoding) }) else { return nil }
        self.init(string: value)
    }
    @objc(initWithBytes:length:encoding:) public convenience init?(_of_bytes bytes: UnsafeRawPointer?, length: Int, encoding: UInt) {
        let buffer = UnsafeRawBufferPointer(start: bytes, count: length)
        guard let value = _ofDecode(buffer, encoding) else { return nil }
        self.init(string: value)
    }
    @objc(initWithCString:encoding:) public convenience init?(_of_cString bytes: UnsafePointer<CChar>, encoding: UInt) {
        let buffer = UnsafeRawBufferPointer(start: bytes, count: strlen(bytes))
        guard let value = _ofDecode(buffer, encoding) else { return nil }
        self.init(string: value)
    }
}

final class _OFOwnedBuffer: NSObject {
    let pointer: UnsafeMutablePointer<CChar>
    init(_ pointer: UnsafeMutablePointer<CChar>) { self.pointer = pointer; super.init() }
    deinit { pointer.deallocate() }
}

/// Replaces every match of `target` inside the UTF-16 range; returns the new
/// text and the number of replacements.
func _ofReplaceAll(_ text: String, _ target: String, _ replacement: String, _ options: UInt,
                   _ location: Int, _ length: Int) -> (String, Int) {
    guard !target.isEmpty else { return (text, 0) }
    var result = text
    var searchRange = _ofUTF16Range(result, location, length)
    var count = 0
    while let found = _ofFind(result, target, options: options & ~UInt(4), within: searchRange) {
        let utf16 = result.utf16
        let offset = utf16.distance(from: utf16.startIndex, to: found.lowerBound) + replacement.utf16.count
        let end = utf16.distance(from: utf16.startIndex, to: searchRange.upperBound)
            - utf16.distance(from: found.lowerBound, to: found.upperBound) + replacement.utf16.count
        result.replaceSubrange(found, with: replacement)
        count += 1
        let newUTF16 = result.utf16
        let lower = newUTF16.index(newUTF16.startIndex, offsetBy: offset)
        let upper = newUTF16.index(newUTF16.startIndex, offsetBy: end)
        searchRange = lower..<upper
        if options & 8 != 0 { break }   // NSAnchoredSearch: one match at most
    }
    return (result, count)
}

// MARK: - NSMutableString

/// FoundationObjCBridge.NSMutableString: a facade NSString whose contents
/// change in place, so Swift's String bridging (which reads the facade's
/// storage directly) always sees the current value.
open class NSMutableString: NSString, @unchecked Sendable {
    @objc(initWithCapacity:) public convenience init(capacity: Int) {
        _ = capacity
        self.init(string: "")
    }

    @objc(_of_replaceCharactersInLocation:length:withString:)
    public func _of_replaceCharacters(location: Int, length: Int, with replacement: NSString) {
        var text = _of_string
        text.replaceSubrange(_ofUTF16Range(text, location, length), with: replacement._of_string)
        _ofReplaceStorage(self, with: text)
    }
    @objc(insertString:atIndex:) public func _of_insert(_ string: NSString, at index: Int) {
        _of_replaceCharacters(location: index, length: 0, with: string)
    }
    @objc(_of_deleteCharactersInLocation:length:) public func _of_delete(location: Int, length: Int) {
        _of_replaceCharacters(location: location, length: length, with: NSString(string: ""))
    }
    @objc(appendString:) public func _of_append(_ string: NSString) {
        _ofReplaceStorage(self, with: _of_string + string._of_string)
    }
    @objc(setString:) public func _of_set(_ string: NSString) {
        _ofReplaceStorage(self, with: string._of_string)
    }
    @objc(_of_replaceOccurrencesOfString:withString:options:location:length:)
    public func _of_replaceOccurrences(_ target: NSString, with replacement: NSString, options: UInt,
                                       location: Int, length: Int) -> Int {
        let (text, count) = _ofReplaceAll(_of_string, target._of_string, replacement._of_string, options, location, length)
        if count > 0 { _ofReplaceStorage(self, with: text) }
        return count
    }

    open override func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return NSString(string: _of_string)
    }
    open override func copy() -> Any { copy(with: nil) }
}

// MARK: - Constant strings (@"..." and CFSTR)

/// Every clang constant string record is rewritten, before main, into an
/// instance of this facade subclass (no ivars of its own), so Objective-C
/// literals are the facade's NSString and bridge to String like any other.
@objc(__NSCFConstantString)
public final class _OFConstantString: NSString, @unchecked Sendable {
    // A constant lives in its image's __DATA segment and ../src makes its
    // retain/release no-ops; reaching dealloc would mean that failed, and
    // freeing __DATA would corrupt the heap.
    deinit { fatalError("FoundationObjCBridge: constant string \"\(String(self))\" was over-released") }
}

/// Rewrites `count` 32-byte `__cfstring` records whose isa is `marker`
/// (___CFConstantStringClassReference). Record layout, measured on macOS
/// (foundation-macho/docs/NSCF_DESIGN.md): {isa, flags, bytes, length};
/// flags 0x7c8 = 8-bit bytes, 0x7d0 = UTF-16 units. Returns records fixed.
@_cdecl("OFFixConstantStrings")
public func OFFixConstantStrings(_ records: UnsafeMutableRawPointer, _ count: Int, _ marker: UnsafeRawPointer) -> Int {
    let layout = _OFStringLayout.current
    let isa = unsafeBitCast(_OFConstantString.self as AnyClass, to: UnsafeRawPointer.self)
    var fixed = 0
    for index in 0..<count {
        let record = records + 32 * index
        guard record.load(as: UnsafeRawPointer.self) == marker else { continue }
        let flags = record.load(fromByteOffset: 8, as: UInt64.self) & 0xffff_ffff
        let characters = record.load(fromByteOffset: 16, as: UnsafeRawPointer.self)
        let length = record.load(fromByteOffset: 24, as: Int.self)
        let value: String
        switch flags {
        case 0x7c8:
            value = String(decoding: UnsafeBufferPointer(start: characters.assumingMemoryBound(to: UInt8.self), count: length),
                           as: UTF8.self)
        case 0x7d0:
            value = String(decoding: UnsafeBufferPointer(start: characters.assumingMemoryBound(to: UInt16.self), count: length),
                           as: UTF16.self)
        default:
            fatalError("FoundationObjCBridge: constant string record with unknown flags 0x\(String(flags, radix: 16))")
        }
        (record + layout.string).bindMemory(to: String.self, capacity: 1).initialize(to: value)
        (record + layout.utf8).storeBytes(of: _ofUTF8Buffer(value), as: UnsafeMutablePointer<CChar>.self)
        record.storeBytes(of: isa, as: UnsafeRawPointer.self)
        fixed += 1
    }
    return fixed
}
