// Project-owned NSString compatibility for the standalone Foundation guest.
//
// NSString is an immutable Objective-C reference identity, not a typealias for
// Swift.String.  This bounded implementation stores one canonical Swift value,
// provides UTF-16 indexing like Darwin Foundation, and participates in the
// Swift runtime's normal _ObjectiveCBridgeable conversions.  It deliberately
// fails closed for byte encodings other than UTF-8 until those encoders are
// implemented and differentially tested.

import FoundationEssentials
import ObjectiveC

public typealias unichar = UInt16

/// The sentinel used by Foundation range-returning APIs.
public let NSNotFound = Int.max

/// Portable shape of Foundation's immutable-copying protocol.
///
/// ObjectiveC already supplies the canonical `NSZone` pointer identity.  The
/// guest protocol keeps the source-level contract without claiming mutable-copy
/// support or an Objective-C protocol object that the standalone runtime does
/// not currently publish.
public protocol NSCopying: AnyObject {
    func copy(with zone: NSZone?) -> Any
}

open class NSString: NSObject, NSCopying, CustomStringConvertible,
    CustomDebugStringConvertible, ExpressibleByStringLiteral,
    @unchecked Sendable {
    public typealias CompareOptions = String.CompareOptions

    internal let _foundationGuestString: String
    private let _utf8Storage: UnsafeMutablePointer<CChar>

    public init(string aString: String) {
        _foundationGuestString = aString
        let bytes = Array(aString.utf8)
        _utf8Storage = .allocate(capacity: bytes.count + 1)
        _utf8Storage.initialize(repeating: 0, count: bytes.count + 1)
        for (index, byte) in bytes.enumerated() {
            _utf8Storage[index] = CChar(bitPattern: byte)
        }
        super.init()
    }

    public convenience override init() {
        self.init(string: "")
    }

    public convenience init(_ aString: String) {
        self.init(string: aString)
    }

    public required convenience init(stringLiteral value: String) {
        self.init(string: value)
    }

    public convenience init?(utf8String bytes: UnsafePointer<CChar>?) {
        guard let bytes,
              let value = String(validatingCString: bytes) else {
            return nil
        }
        self.init(string: value)
    }

    public convenience init(
        characters: UnsafePointer<unichar>,
        length: Int
    ) {
        precondition(length >= 0, "NSString character length must be nonnegative")
        let units = UnsafeBufferPointer(start: characters, count: length)
        self.init(string: String(decoding: units, as: UTF16.self))
    }

    /// UTF-8 is the first production byte encoding. Unknown or currently
    /// unsupported encodings return nil rather than silently decoding bytes
    /// with the wrong codec.
    public convenience init?(
        bytes: UnsafeRawPointer?,
        length: Int,
        encoding: UInt
    ) {
        guard length >= 0,
              encoding == String.Encoding.utf8.rawValue else { return nil }
        if length == 0 {
            self.init(string: "")
            return
        }
        guard let bytes else { return nil }
        let typed = bytes.assumingMemoryBound(to: UInt8.self)
        let buffer = UnsafeBufferPointer(start: typed, count: length)
        guard let value = String(validating: buffer, as: UTF8.self) else {
            return nil
        }
        self.init(string: value)
    }

    public convenience init?(data: Data, encoding: UInt) {
        guard encoding == String.Encoding.utf8.rawValue,
              let value = String(data: data, encoding: .utf8) else { return nil }
        self.init(string: value)
    }

    public convenience init(format: String, _ arguments: Any...) {
        self.init(string: _foundationGuestFormat(format, arguments: arguments))
    }

    deinit {
        _utf8Storage.deinitialize(count: _foundationGuestString.utf8.count + 1)
        _utf8Storage.deallocate()
    }

    /// UTF-16 code-unit count, matching NSString's indexing coordinate space.
    open var length: Int { _foundationGuestString.utf16.count }

    open func character(at index: Int) -> unichar {
        let units = Array(_foundationGuestString.utf16)
        precondition(units.indices.contains(index), "NSString index out of bounds")
        return units[index]
    }

    open func substring(from index: Int) -> String {
        _substring(NSRange(location: index, length: length - index))
    }

    open func substring(to index: Int) -> String {
        _substring(NSRange(location: 0, length: index))
    }

    open func substring(with range: NSRange) -> String {
        _substring(range)
    }

    open func compare(_ string: String) -> ComparisonResult {
        _foundationGuestString.compare(string)
    }

    open func compare(
        _ string: String,
        options mask: CompareOptions
    ) -> ComparisonResult {
        _foundationGuestString.compare(string, options: mask)
    }

    open func compare(
        _ string: String,
        options mask: CompareOptions,
        range compareRange: NSRange,
        locale: Any?
    ) -> ComparisonResult {
        _ = locale
        return substring(with: compareRange).compare(string, options: mask)
    }

    open func caseInsensitiveCompare(_ string: String) -> ComparisonResult {
        compare(string, options: .caseInsensitive)
    }

    open func localizedCaseInsensitiveCompare(
        _ string: String
    ) -> ComparisonResult {
        compare(string, options: .caseInsensitive)
    }

    open func isEqual(to aString: String) -> Bool {
        _foundationGuestString == aString
    }

    open override func isEqual(_ object: Any?) -> Bool {
        if let string = object as? NSString {
            return _foundationGuestString == string._foundationGuestString
        }
        if let string = object as? String {
            return _foundationGuestString == string
        }
        return false
    }

    open override var hash: Int { _foundationGuestString.hashValue }

    open var description: String { _foundationGuestString }
    open var debugDescription: String { _foundationGuestString }

    open var utf8String: UnsafePointer<CChar>? {
        UnsafePointer(_utf8Storage)
    }

    open func data(using encoding: UInt) -> Data? {
        guard encoding == String.Encoding.utf8.rawValue else { return nil }
        return Data(_foundationGuestString.utf8)
    }

    open func copy(with zone: NSZone? = nil) -> Any {
        _ = zone
        return self
    }

    open override func copy() -> Any { copy(with: nil) }

    open func hasPrefix(_ str: String) -> Bool {
        _foundationGuestString.hasPrefix(str)
    }

    open func hasSuffix(_ str: String) -> Bool {
        _foundationGuestString.hasSuffix(str)
    }

    open func range(
        of searchString: String,
        options mask: CompareOptions = []
    ) -> NSRange {
        guard let range = _foundationGuestString.range(
            of: searchString,
            options: mask
        ) else {
            return NSRange(location: NSNotFound, length: 0)
        }
        return NSRange(
            location: range.lowerBound.utf16Offset(in: _foundationGuestString),
            length: _foundationGuestString.utf16.distance(
                from: range.lowerBound,
                to: range.upperBound
            )
        )
    }

    open var lastPathComponent: String {
        _foundationGuestString.lastPathComponent
    }

    open var pathExtension: String {
        URL(fileURLWithPath: _foundationGuestString).pathExtension
    }

    open var deletingPathExtension: String {
        URL(fileURLWithPath: _foundationGuestString)
            .deletingPathExtension()
            .path
    }

    open var deletingLastPathComponent: String {
        URL(fileURLWithPath: _foundationGuestString)
            .deletingLastPathComponent()
            .path
    }

    open func appendingPathComponent(_ str: String) -> String {
        _foundationGuestString.appendingPathComponent(str)
    }

    private func _substring(_ range: NSRange) -> String {
        precondition(
            range.location >= 0 && range.length >= 0 &&
                range.location <= length && range.length <= length - range.location,
            "NSString range out of bounds"
        )
        let units = Array(_foundationGuestString.utf16)
        let lower = range.location
        let upper = lower + range.length
        return String(decoding: units[lower..<upper], as: UTF16.self)
    }
}

public extension String {
    init(_ aString: NSString) {
        self = aString._foundationGuestString
    }
}

extension String: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSString

    @_semantics("convertToObjectiveC")
    public func _bridgeToObjectiveC() -> NSString {
        NSString(string: self)
    }

    public static func _forceBridgeFromObjectiveC(
        _ source: NSString,
        result: inout String?
    ) {
        result = source._foundationGuestString
    }

    public static func _conditionallyBridgeFromObjectiveC(
        _ source: NSString,
        result: inout String?
    ) -> Bool {
        result = source._foundationGuestString
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSString?
    ) -> String {
        source?._foundationGuestString ?? ""
    }
}
