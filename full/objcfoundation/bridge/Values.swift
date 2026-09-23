// NSNumber, NSData, NSError, NSNull, NSValue and NSLock selectors on the
// facade's classes; NSDate, NSLocale, NSTimeZone, NSDateFormatter and
// NSAssertionHandler as FoundationObjCBridge classes.

import Foundation
import ObjectiveC
#if canImport(OpenCoreGraphics)
import OpenCoreGraphics
#endif

// MARK: - NSNumber

/// The Objective-C type a number was created with (its -objCType). The facade
/// keeps only signed / unsigned / floating / boolean storage, so the type code
/// the SDK reports rides along as an associated value; numbers made by Swift
/// report the code their storage implies.
private final class _OFTypeCode: NSObject {
    let code: UInt8
    init(_ code: UInt8) { self.code = code; super.init() }
}

private let _ofTypeStrings: [UInt8: UnsafePointer<CChar>] = {
    var table: [UInt8: UnsafePointer<CChar>] = [:]
    for code in "cCsSiIlLqQfdB".utf8 {
        let buffer = UnsafeMutablePointer<CChar>.allocate(capacity: 2)
        buffer[0] = CChar(bitPattern: code)
        buffer[1] = 0
        table[code] = UnsafePointer(buffer)
    }
    return table
}()

extension NSNumber {
    fileprivate func _of_tag(_ code: Character) -> NSNumber {
        objc_setAssociatedObject(self, _OFKeys.numberType, _OFTypeCode(code.asciiValue!), .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return self
    }

    /// The SDK's type code: explicit when an Objective-C constructor set one;
    /// otherwise 'd' for a non-integral value and 'q'/'Q' for an integral one.
    var _of_typeCode: UInt8 {
        if let tagged = objc_getAssociatedObject(self, _OFKeys.numberType) as? _OFTypeCode { return tagged.code }
        let value = doubleValue
        if !value.isFinite || value != value.rounded(.towardZero) { return UInt8(ascii: "d") }
        return int64Value < 0 || uint64Value <= UInt64(Int64.max) ? UInt8(ascii: "q") : UInt8(ascii: "Q")
    }

    /// -description / -stringValue as the SDK prints each type.
    var _of_text: String {
        switch _of_typeCode {
        case UInt8(ascii: "f"): return _ofShortest(Double(floatValue), digits: 7, max: 9) { Double(Float($0)) }
        case UInt8(ascii: "d"): return _ofShortest(doubleValue, digits: 16, max: 17) { $0 }
        case UInt8(ascii: "Q"): return String(uint64Value)
        default: return String(int64Value)
        }
    }

    @objc(charValue) public var _of_charValue: Int8 { Int8(truncatingIfNeeded: int64Value) }
    @objc(unsignedCharValue) public var _of_unsignedCharValue: UInt8 { UInt8(truncatingIfNeeded: int64Value) }
    @objc(shortValue) public var _of_shortValue: Int16 { Int16(truncatingIfNeeded: int64Value) }
    @objc(unsignedShortValue) public var _of_unsignedShortValue: UInt16 { UInt16(truncatingIfNeeded: int64Value) }
    @objc(intValue) public var _of_intValue: Int32 { Int32(truncatingIfNeeded: int64Value) }
    @objc(unsignedIntValue) public var _of_unsignedIntValue: UInt32 { UInt32(truncatingIfNeeded: uint64Value) }
    @objc(longValue) public var _of_longValue: Int { Int(int64Value) }
    @objc(unsignedLongValue) public var _of_unsignedLongValue: UInt { UInt(uint64Value) }
    @objc(longLongValue) public var _of_longLongValue: Int64 { int64Value }
    @objc(unsignedLongLongValue) public var _of_unsignedLongLongValue: UInt64 { uint64Value }
    @objc(integerValue) public var _of_integerValue: Int { Int(int64Value) }
    @objc(unsignedIntegerValue) public var _of_unsignedIntegerValue: UInt { UInt(uint64Value) }
    @objc(floatValue) public var _of_floatValue: Float { floatValue }
    @objc(doubleValue) public var _of_doubleValue: Double { doubleValue }
    @objc(boolValue) public var _of_boolValue: Bool { boolValue }
    @objc(stringValue) public var _of_stringValue: NSString { NSString(string: _of_text) }
    @objc(description) public var _of_description: NSString { NSString(string: _of_text) }
    @objc(objCType) public var _of_objCType: UnsafePointer<CChar> { _ofTypeStrings[_of_typeCode]! }
    @objc(compare:) public func _of_compare(_ other: NSNumber) -> Int { compare(other).rawValue }
    @objc(isEqualToNumber:) public func _of_isEqualToNumber(_ other: NSNumber) -> Bool { isEqual(to: other) }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { self }

    // The SDK's promotions (CFNumber): unsigned types widen to the next signed
    // type, BOOL and char are 'c'.
    @objc(initWithChar:) public convenience init(_of_char v: Int8) { self.init(value: Int64(v)); _ = _of_tag("c") }
    @objc(initWithUnsignedChar:) public convenience init(_of_unsignedChar v: UInt8) { self.init(value: Int64(v)); _ = _of_tag("s") }
    @objc(initWithShort:) public convenience init(_of_short v: Int16) { self.init(value: Int64(v)); _ = _of_tag("s") }
    @objc(initWithUnsignedShort:) public convenience init(_of_unsignedShort v: UInt16) { self.init(value: Int64(v)); _ = _of_tag("i") }
    @objc(initWithInt:) public convenience init(_of_int v: Int32) { self.init(value: Int64(v)); _ = _of_tag("i") }
    @objc(initWithUnsignedInt:) public convenience init(_of_unsignedInt v: UInt32) { self.init(value: Int64(v)); _ = _of_tag("q") }
    @objc(initWithLong:) public convenience init(_of_long v: Int) { self.init(value: Int64(v)); _ = _of_tag("q") }
    @objc(initWithUnsignedLong:) public convenience init(_of_unsignedLong v: UInt) {
        if v > UInt(Int64.max) { self.init(value: UInt64(v)); _ = _of_tag("Q") } else { self.init(value: Int64(v)); _ = _of_tag("q") }
    }
    @objc(initWithLongLong:) public convenience init(_of_longLong v: Int64) { self.init(value: v); _ = _of_tag("q") }
    @objc(initWithUnsignedLongLong:) public convenience init(_of_unsignedLongLong v: UInt64) {
        if v > UInt64(Int64.max) { self.init(value: v); _ = _of_tag("Q") } else { self.init(value: Int64(v)); _ = _of_tag("q") }
    }
    @objc(initWithFloat:) public convenience init(_of_float v: Float) { self.init(value: Double(v)); _ = _of_tag("f") }
    @objc(initWithDouble:) public convenience init(_of_double v: Double) { self.init(value: v); _ = _of_tag("d") }
    @objc(initWithBool:) public convenience init(_of_bool v: Bool) { self.init(value: v); _ = _of_tag("c") }
    @objc(initWithInteger:) public convenience init(_of_integer v: Int) { self.init(value: Int64(v)); _ = _of_tag("q") }
    @objc(initWithUnsignedInteger:) public convenience init(_of_unsignedInteger v: UInt) { self.init(_of_unsignedLong: v) }
}

/// The shortest of %.<digits>g .. %.<max>g that reads back to the same value,
/// which is how CFNumber prints floats and doubles.
private func _ofShortest(_ value: Double, digits: Int, max: Int, roundTrip: (Double) -> Double) -> String {
    var buffer = [CChar](repeating: 0, count: 64)
    for precision in digits...max {
        _ = withVaList([Int32(precision), value]) { vsnprintf(&buffer, buffer.count, "%.*g", $0) }
        let text = String(cString: buffer)
        if precision == max || roundTrip(strtod(text, nil)) == roundTrip(value) { return text }
    }
    return String(value)
}

/// The two shared NSNumbers behind +numberWithBool: (and so @YES / @NO).
@_cdecl("OFMakeBooleanNumber")
public func OFMakeBooleanNumber(_ value: Bool) -> Unmanaged<NSNumber> {
    Unmanaged.passRetained(NSNumber(value: value)._of_tag("c"))
}

// MARK: - NSData

private final class _OFDataBytes: NSObject {
    let pointer: UnsafeMutableRawPointer
    let count: Int
    init(_ bytes: [UInt8]) {
        let storage = UnsafeMutableRawPointer.allocate(byteCount: max(bytes.count, 1), alignment: 16)
        if !bytes.isEmpty { bytes.withUnsafeBytes { storage.copyMemory(from: $0.baseAddress!, byteCount: bytes.count) } }
        count = bytes.count
        pointer = storage
        super.init()
    }
    deinit { pointer.deallocate() }
}

extension NSData {
    @objc(length) public var _of_length: Int { length }
    /// -bytes: a copy owned by the object, kept until the contents change.
    @objc(bytes) public var _of_bytes: UnsafeRawPointer {
        let bytes = [UInt8](Data(self))
        if let cached = objc_getAssociatedObject(self, _OFKeys.dataBytes) as? _OFDataBytes, cached.count == bytes.count,
           bytes.withUnsafeBytes({ memcmp($0.baseAddress!, cached.pointer, bytes.count) == 0 }) || bytes.isEmpty {
            return UnsafeRawPointer(cached.pointer)
        }
        let fresh = _OFDataBytes(bytes)
        objc_setAssociatedObject(self, _OFKeys.dataBytes, fresh, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        return UnsafeRawPointer(fresh.pointer)
    }
    @objc(getBytes:length:) public func _of_getBytes(_ buffer: UnsafeMutableRawPointer, length: Int) {
        getBytes(buffer, length: length)
    }
    @objc(_of_getBytes:location:length:) public func _of_getBytes(_ buffer: UnsafeMutableRawPointer, location: Int, length: Int) {
        let bytes = [UInt8](Data(self))
        precondition(location >= 0 && length >= 0 && location + length <= bytes.count, "NSData getBytes:range: out of bounds")
        bytes[location..<(location + length)].withUnsafeBytes { buffer.copyMemory(from: $0.baseAddress!, byteCount: length) }
    }
    @objc(isEqualToData:) public func _of_isEqualToData(_ other: NSData) -> Bool { Data(self) == Data(other) }
    @objc(_of_subdataWithLocation:length:) public func _of_subdata(location: Int, length: Int) -> NSData {
        let bytes = [UInt8](Data(self))
        precondition(location >= 0 && length >= 0 && location + length <= bytes.count, "NSData subdataWithRange: out of bounds")
        return NSData(data: Data(bytes[location..<(location + length)]))
    }
    /// The SDK's form: {length = N, bytes = 0x...}, all bytes up to 24, then
    /// the first and last eight with " ... " between (the long form is
    /// Apple's documented layout, not measured here).
    @objc(description) public var _of_description: NSString {
        let bytes = [UInt8](Data(self))
        func hex(_ slice: ArraySlice<UInt8>) -> String {
            var text = ""
            for (offset, byte) in slice.enumerated() {
                if offset > 0 && offset % 4 == 0 { text += " " }
                text += String(byte, radix: 16).leftPadded(to: 2)
            }
            return text
        }
        let body = bytes.count <= 24 ? hex(bytes[...]) : hex(bytes[0..<8]) + " ... " + hex(bytes[(bytes.count - 8)...])
        return NSString(string: "{length = \(bytes.count), bytes = 0x\(body)}")
    }
    @objc(initWithBytes:length:) public convenience init(_of_bytes bytes: UnsafeRawPointer?, length: Int) {
        self.init(bytes: bytes, length: length)
    }
    @objc(initWithBytesNoCopy:length:freeWhenDone:)
    public convenience init(_of_bytesNoCopy bytes: UnsafeMutableRawPointer, length: Int, freeWhenDone: Bool) {
        // Copied, then released as the caller asked: the facade owns its storage.
        self.init(bytes: bytes, length: length)
        if freeWhenDone { free(bytes) }
    }
    @objc(initWithData:) public convenience init(_of_data other: NSData) { self.init(data: Data(other)) }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { copy() as AnyObject }
    @objc(mutableCopyWithZone:) public func _of_mutableCopyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject {
        mutableCopy() as AnyObject
    }
}

extension NSMutableData {
    @objc(appendBytes:length:) public func _of_append(_ bytes: UnsafeRawPointer, length: Int) { append(bytes, length: length) }
    @objc(appendData:) public func _of_append(_ other: NSData) {
        let bytes = [UInt8](Data(other))
        bytes.withUnsafeBytes { if let base = $0.baseAddress { append(base, length: bytes.count) } }
    }
    @objc(initWithCapacity:) public convenience init(_of_capacity capacity: Int) {
        _ = capacity
        self.init(data: Data())
    }
}

// MARK: - NSError

extension NSError {
    @objc(initWithDomain:code:userInfo:) public convenience init(_of_domain domain: NSString, code: Int, userInfo: NSDictionary?) {
        self.init(domain: String(domain), code: code, userInfo: userInfo.map { [String: Any]._unconditionallyBridgeFromObjectiveC($0) })
    }
    @objc(errorWithDomain:code:userInfo:) public class func _of_error(domain: NSString, code: Int, userInfo: NSDictionary?) -> NSError {
        NSError(_of_domain: domain, code: code, userInfo: userInfo)
    }
    @objc(domain) public var _of_domain: NSString { NSString(string: domain) }
    @objc(code) public var _of_code: Int { code }
    @objc(userInfo) public var _of_userInfo: NSDictionary { userInfo._bridgeToObjectiveC() }
    @objc(localizedDescription) public var _of_localizedDescription: NSString { NSString(string: localizedDescription) }
    @objc(localizedFailureReason) public var _of_localizedFailureReason: NSString? {
        localizedFailureReason.map { NSString(string: $0) }
    }
    /// The SDK's -description, measured on iOS 26.1:
    /// Error Domain=D Code=N "reason" UserInfo={Key=value, ...}. (The facade's
    /// Swift `description` spells the user info as {Key = value;}; its
    /// Objective-C face follows the measurement.)
    @objc(description) public var _of_description: NSString {
        let quoted = (userInfo[NSLocalizedDescriptionKey] as? String).map { "\"\($0)\"" } ?? "\"(null)\""
        var text = "Error Domain=\(domain) Code=\(code) \(quoted)"
        if !userInfo.isEmpty {
            let pairs = userInfo.keys.sorted().map { key in "\(key)=\(_ofDescription(_ofBox(userInfo[key]!)))" }
            text += " UserInfo={\(pairs.joined(separator: ", "))}"
        }
        return NSString(string: text)
    }
}

// MARK: - NSNull

private let _ofNull = NSNull()

extension NSNull {
    @objc(null) public class func _of_null() -> NSNull { _ofNull }
    @objc(description) public var _of_description: NSString { NSString(string: "<null>") }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { self }
}

// MARK: - NSValue (pointers and non-retained objects)

final class _OFPointerValue: NSValue, @unchecked Sendable {
    let pointer: UnsafeRawPointer?
    init(pointer: UnsafeRawPointer?) {
        self.pointer = pointer
        super.init(cgRect: .zero)
    }
    override func isEqual(_ object: Any?) -> Bool {
        (object as? _OFPointerValue)?.pointer == pointer
    }
    override var hash: Int { Int(bitPattern: pointer) }
}

extension NSValue {
    @objc(valueWithNonretainedObject:) public class func _of_value(nonretainedObject object: AnyObject?) -> NSValue {
        _OFPointerValue(pointer: object.map { UnsafeRawPointer(Unmanaged.passUnretained($0).toOpaque()) })
    }
    @objc(valueWithPointer:) public class func _of_value(pointer: UnsafeRawPointer?) -> NSValue {
        _OFPointerValue(pointer: pointer)
    }
    @objc(nonretainedObjectValue) public var _of_nonretainedObjectValue: AnyObject? {
        (self as? _OFPointerValue)?.pointer.map { Unmanaged<AnyObject>.fromOpaque($0).takeUnretainedValue() }
    }
    @objc(pointerValue) public var _of_pointerValue: UnsafeMutableRawPointer? {
        (self as? _OFPointerValue)?.pointer.map { UnsafeMutableRawPointer(mutating: $0) }
    }
    @objc(isEqualToValue:) public func _of_isEqualToValue(_ other: NSValue) -> Bool { isEqual(other) }
}

// MARK: - NSLock

extension NSLock {
    @objc(lock) public func _of_lock() { lock() }
    @objc(unlock) public func _of_unlock() { unlock() }
    @objc(tryLock) public func _of_tryLock() -> Bool { self.try() }
    @objc(lockBeforeDate:) public func _of_lock(before limit: NSDate) -> Bool { lock(before: limit.date) }
    @objc(name) public var _of_name: NSString? {
        get { name.map { NSString(string: $0) } }
        set { name = newValue.map { String($0) } }
    }
}

// MARK: - NSDate

open class NSDate: NSObject, @unchecked Sendable {
    public let timeIntervalSinceReferenceDate: Double

    @objc(initWithTimeIntervalSinceReferenceDate:) public init(timeIntervalSinceReferenceDate: Double) {
        self.timeIntervalSinceReferenceDate = timeIntervalSinceReferenceDate
        super.init()
    }
    @objc public override convenience init() {
        self.init(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate)
    }
    @objc(initWithTimeIntervalSince1970:) public convenience init(timeIntervalSince1970 secs: Double) {
        self.init(timeIntervalSinceReferenceDate: secs - 978_307_200)
    }
    @objc(initWithTimeIntervalSinceNow:) public convenience init(timeIntervalSinceNow secs: Double) {
        self.init(timeIntervalSinceReferenceDate: Date().timeIntervalSinceReferenceDate + secs)
    }
    public convenience init(_ date: Date) { self.init(timeIntervalSinceReferenceDate: date.timeIntervalSinceReferenceDate) }

    public var date: Date { Date(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate) }

    @objc(timeIntervalSinceReferenceDate) public var _of_timeIntervalSinceReferenceDate: Double { timeIntervalSinceReferenceDate }
    @objc(timeIntervalSince1970) public var timeIntervalSince1970: Double { timeIntervalSinceReferenceDate + 978_307_200 }
    @objc(timeIntervalSinceNow) public var timeIntervalSinceNow: Double {
        timeIntervalSinceReferenceDate - Date().timeIntervalSinceReferenceDate
    }
    @objc(timeIntervalSinceDate:) public func timeIntervalSince(_ other: NSDate) -> Double {
        timeIntervalSinceReferenceDate - other.timeIntervalSinceReferenceDate
    }
    @objc(dateByAddingTimeInterval:) public func addingTimeInterval(_ interval: Double) -> NSDate {
        NSDate(timeIntervalSinceReferenceDate: timeIntervalSinceReferenceDate + interval)
    }
    @objc(earlierDate:) public func earlierDate(_ other: NSDate) -> NSDate {
        timeIntervalSinceReferenceDate <= other.timeIntervalSinceReferenceDate ? self : other
    }
    @objc(laterDate:) public func laterDate(_ other: NSDate) -> NSDate {
        timeIntervalSinceReferenceDate >= other.timeIntervalSinceReferenceDate ? self : other
    }
    @objc(compare:) public func compare(_ other: NSDate) -> Int {
        timeIntervalSinceReferenceDate < other.timeIntervalSinceReferenceDate ? -1
            : timeIntervalSinceReferenceDate > other.timeIntervalSinceReferenceDate ? 1 : 0
    }
    @objc(isEqualToDate:) public func isEqual(to other: NSDate) -> Bool {
        timeIntervalSinceReferenceDate == other.timeIntervalSinceReferenceDate
    }
    open override func isEqual(_ object: Any?) -> Bool {
        guard let other = object as? NSDate else { return false }
        return isEqual(to: other)
    }
    open override var hash: Int { Int(timeIntervalSinceReferenceDate) }

    /// "2001-01-01 00:00:00 +0000": UTC, whole seconds rounded down.
    @objc(description) open var _of_description: NSString { NSString(string: _ofUTCText(timeIntervalSince1970)) }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { self }

    @objc(date) public class func _of_date() -> NSDate { NSDate() }
    @objc(timeIntervalSinceReferenceDate) public class var _of_now: Double { Date().timeIntervalSinceReferenceDate }
    @objc(dateWithTimeIntervalSinceNow:) public class func _of_date(sinceNow secs: Double) -> NSDate {
        NSDate(timeIntervalSinceNow: secs)
    }
    @objc(dateWithTimeIntervalSinceReferenceDate:) public class func _of_date(sinceReferenceDate ti: Double) -> NSDate {
        NSDate(timeIntervalSinceReferenceDate: ti)
    }
    @objc(dateWithTimeIntervalSince1970:) public class func _of_date(since1970 secs: Double) -> NSDate {
        NSDate(timeIntervalSince1970: secs)
    }
    @objc(distantFuture) public class var distantFuture: NSDate { NSDate(timeIntervalSinceReferenceDate: 63_113_904_000) }
    @objc(distantPast) public class var distantPast: NSDate { NSDate(timeIntervalSinceReferenceDate: -63_114_076_800) }
    @objc(now) public class var now: NSDate { NSDate() }
}

func _ofUTCText(_ since1970: Double, offset: Int = 0, format: String = "yyyy-MM-dd HH:mm:ss Z") -> String {
    var seconds = time_t(floor(since1970)) + offset
    var parts = tm()
    gmtime_r(&seconds, &parts)
    let millis = Int((since1970 - floor(since1970)) * 1000)
    var out = ""
    var chars = Array(format)
    var index = 0
    func take(_ c: Character) -> Int {
        var n = 0
        while index < chars.count && chars[index] == c { n += 1; index += 1 }
        return n
    }
    while index < chars.count {
        let c = chars[index]
        switch c {
        case "y": let n = take("y"); out += String(Int(parts.tm_year) + 1900).leftPadded(to: n == 2 ? 2 : 4)
        case "M": let n = take("M"); out += String(Int(parts.tm_mon) + 1).leftPadded(to: n)
        case "d": let n = take("d"); out += String(Int(parts.tm_mday)).leftPadded(to: n)
        case "H": let n = take("H"); out += String(Int(parts.tm_hour)).leftPadded(to: n)
        case "m": let n = take("m"); out += String(Int(parts.tm_min)).leftPadded(to: n)
        case "s": let n = take("s"); out += String(Int(parts.tm_sec)).leftPadded(to: n)
        case "S": let n = take("S"); out += String(String(millis).leftPadded(to: 3).prefix(n))
        case "Z":
            _ = take("Z")
            let sign = offset < 0 ? "-" : "+"
            let magnitude = abs(offset) / 60
            out += sign + String(magnitude / 60).leftPadded(to: 2) + String(magnitude % 60).leftPadded(to: 2)
        case "'":
            index += 1
            while index < chars.count && chars[index] != "'" { out.append(chars[index]); index += 1 }
            index += 1
        default:
            out.append(c)
            index += 1
        }
    }
    chars.removeAll()
    return out
}

extension Date: @retroactive _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSDate
    public func _bridgeToObjectiveC() -> NSDate { NSDate(self) }
    public static func _forceBridgeFromObjectiveC(_ source: NSDate, result: inout Date?) { result = source.date }
    public static func _conditionallyBridgeFromObjectiveC(_ source: NSDate, result: inout Date?) -> Bool {
        result = source.date
        return true
    }
    public static func _unconditionallyBridgeFromObjectiveC(_ source: NSDate?) -> Date { source?.date ?? Date() }
}

// MARK: - NSLocale, NSTimeZone, NSDateFormatter (FMDB's fixed formats)

open class NSLocale: NSObject, @unchecked Sendable {
    @objc(localeIdentifier) public let localeIdentifier: NSString
    @objc(initWithLocaleIdentifier:) public init(localeIdentifier: NSString) {
        self.localeIdentifier = localeIdentifier
        super.init()
    }
    @objc(localeWithLocaleIdentifier:) public class func _of_locale(identifier: NSString) -> NSLocale {
        NSLocale(localeIdentifier: identifier)
    }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { self }
}

open class NSTimeZone: NSObject, @unchecked Sendable {
    @objc(secondsFromGMT) public let secondsFromGMT: Int
    @objc(name) public let name: NSString
    public init(secondsFromGMT: Int, name: String) {
        self.secondsFromGMT = secondsFromGMT
        self.name = NSString(string: name)
        super.init()
    }
    @objc(timeZoneForSecondsFromGMT:) public class func _of_timeZone(secondsFromGMT seconds: Int) -> NSTimeZone? {
        let magnitude = abs(seconds) / 60
        let name = seconds == 0 ? "GMT" : "GMT" + (seconds < 0 ? "-" : "+")
            + String(magnitude / 60).leftPadded(to: 2) + String(magnitude % 60).leftPadded(to: 2)
        return NSTimeZone(secondsFromGMT: seconds, name: name)
    }
    @objc(timeZoneWithName:) public class func _of_timeZone(name: NSString) -> NSTimeZone? {
        switch String(name) {
        case "GMT", "UTC", "Etc/UTC", "Etc/GMT": return NSTimeZone(secondsFromGMT: 0, name: String(name))
        default: return nil   // no tz database behind this guest class
        }
    }
    @objc(copyWithZone:) public func _of_copyWithZone(_ zone: UnsafeMutableRawPointer?) -> AnyObject { self }
}

/// Fixed-format, Gregorian, offset-timezone formatting only: the patterns FMDB
/// builds (yyyy MM dd HH mm ss SSS Z and quoted literals). Other locales or
/// named zones stop with a message instead of formatting by invented rules.
open class NSDateFormatter: NSObject, @unchecked Sendable {
    private var format = ""
    private var zone: NSTimeZone?
    private var localeValue: NSLocale?

    @objc public override init() { super.init() }

    @objc(dateFormat) public var dateFormat: NSString {
        get { NSString(string: format) }
        set { format = String(newValue) }
    }
    @objc(locale) public var locale: NSLocale? {
        get { localeValue }
        set { localeValue = newValue }
    }
    @objc(timeZone) public var timeZone: NSTimeZone? {
        get { zone }
        set { zone = newValue }
    }
    private func checkSupported() {
        let identifier = localeValue.map { String($0.localeIdentifier) } ?? "en_US_POSIX"
        precondition(["en_US", "en_US_POSIX", "en"].contains(identifier),
                     "FoundationObjCBridge.NSDateFormatter: locale \(identifier) is not implemented in the guest")
        var quoted = false
        for c in format {
            if c == "'" { quoted.toggle(); continue }
            precondition(quoted || !c.isLetter || "yMdHmsSZ".contains(c),
                         "FoundationObjCBridge.NSDateFormatter: pattern letter \(c) in \(format) is not implemented in the guest")
        }
    }
    @objc(stringFromDate:) public func string(from date: NSDate) -> NSString {
        checkSupported()
        return NSString(string: _ofUTCText(date.timeIntervalSince1970, offset: zone?.secondsFromGMT ?? 0, format: format))
    }
    @objc(dateFromString:) public func date(from text: NSString) -> NSDate? {
        checkSupported()
        // Parse by the same fixed pattern: numeric fields in order.
        var fields: [Character: Int] = [:]
        let chars = Array(format), input = Array(String(text))
        var f = 0, i = 0
        while f < chars.count {
            let c = chars[f]
            if "yMdHmsS".contains(c) {
                var n = 0
                while f < chars.count && chars[f] == c { n += 1; f += 1 }
                var digits = ""
                while i < input.count && input[i].isNumber && digits.count < max(n, c == "y" ? 4 : 2) { digits.append(input[i]); i += 1 }
                guard let value = Int(digits) else { return nil }
                fields[c] = value
            } else {
                guard i < input.count, input[i] == c else { return nil }
                f += 1; i += 1
            }
        }
        guard i == input.count else { return nil }
        var parts = tm()
        parts.tm_year = Int32((fields["y"] ?? 1970) - 1900)
        parts.tm_mon = Int32((fields["M"] ?? 1) - 1)
        parts.tm_mday = Int32(fields["d"] ?? 1)
        parts.tm_hour = Int32(fields["H"] ?? 0)
        parts.tm_min = Int32(fields["m"] ?? 0)
        parts.tm_sec = Int32(fields["s"] ?? 0)
        let seconds = Double(timegm(&parts)) - Double(zone?.secondsFromGMT ?? 0) + Double(fields["S"] ?? 0) / 1000
        return NSDate(timeIntervalSince1970: seconds)
    }
}

// MARK: - NSAssertionHandler (the variadic methods are in ../src)

open class NSAssertionHandler: NSObject, @unchecked Sendable {
    private static let shared = NSAssertionHandler()
    @objc(currentHandler) public class var currentHandler: NSAssertionHandler { shared }
}
