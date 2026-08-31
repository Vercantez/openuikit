// Foundation value identities that must remain identical to the declarations
// used when OpenUIKit was compiled with the Foundation umbrella hidden.

@_exported import ObjectiveC
import OpenUIKit

public typealias NSObject = ObjectiveC.NSObject
public typealias NSObjectProtocol = ObjectiveC.NSObjectProtocol

public typealias NSRange = OpenUIKit.NSRange
public typealias NSRangePointer = OpenUIKit.NSRangePointer

public func NSMakeRange(_ location: Int, _ length: Int) -> NSRange {
    NSRange(location: location, length: length)
}

/// Returns the first location beyond `range`.
///
/// Darwin's inline `NSMaxRange` performs unsigned addition. `NSRange` uses
/// signed `Int` storage in the portable value substrate, so wrapping addition
/// preserves the imported C operation at the integer boundary as well as for
/// ordinary ranges.
public func NSMaxRange(_ range: NSRange) -> Int {
    range.location &+ range.length
}

/// Tests a location against the half-open interval represented by `range`.
public func NSLocationInRange(_ location: Int, _ range: NSRange) -> Bool {
    location >= range.location && (location &- range.location) < range.length
}

/// Compares two ranges by value.
public func NSEqualRanges(_ lhs: NSRange, _ rhs: NSRange) -> Bool {
    lhs.location == rhs.location && lhs.length == rhs.length
}

/// Returns the smallest half-open range containing both inputs.
public func NSUnionRange(_ lhs: NSRange, _ rhs: NSRange) -> NSRange {
    let lowerBound = min(lhs.location, rhs.location)
    let upperBound = max(NSMaxRange(lhs), NSMaxRange(rhs))
    return NSRange(location: lowerBound, length: upperBound &- lowerBound)
}

/// Returns the overlap between two half-open ranges. Foundation canonicalizes
/// an empty intersection to `{0, 0}` even when the inputs merely touch.
public func NSIntersectionRange(_ lhs: NSRange, _ rhs: NSRange) -> NSRange {
    let lowerBound = max(lhs.location, rhs.location)
    let upperBound = min(NSMaxRange(lhs), NSMaxRange(rhs))
    guard upperBound > lowerBound else {
        return NSRange(location: 0, length: 0)
    }
    return NSRange(location: lowerBound, length: upperBound - lowerBound)
}

/// Markdown inline semantics that Apple exposes from Foundation's
/// `AttributedString` scope. swift-foundation intentionally compiles these
/// only for its Apple framework build, so the portable Foundation facade owns
/// the equivalent public value and attribute key.
public struct InlinePresentationIntent: OptionSet, Codable, Hashable, Sendable {
    public let rawValue: UInt

    public init(rawValue: UInt) {
        self.rawValue = rawValue
    }

    public static let emphasized = Self(rawValue: 1 << 0)
    public static let stronglyEmphasized = Self(rawValue: 1 << 1)
    public static let code = Self(rawValue: 1 << 2)
    public static let strikethrough = Self(rawValue: 1 << 5)
    public static let softBreak = Self(rawValue: 1 << 6)
    public static let lineBreak = Self(rawValue: 1 << 7)
    public static let inlineHTML = Self(rawValue: 1 << 8)
}

public extension AttributeScopes.FoundationAttributes {
    enum InlinePresentationIntentAttribute: CodableAttributedStringKey {
        public typealias Value = InlinePresentationIntent
        public static let name = "NSInlinePresentationIntent"
    }

    /// The value is used only to form a key path for dynamic-member lookup;
    /// AttributeScope metadata never evaluates this accessor.
    var inlinePresentationIntent: InlinePresentationIntentAttribute {
        preconditionFailure("AttributeScope key metadata has no runtime value")
    }
}

public extension NSRange {
    /// Creates an NSRange from an integer half-open range.
    init(_ range: Range<Int>) {
        self.init(
            location: range.lowerBound,
            length: range.upperBound - range.lowerBound
        )
    }
}
