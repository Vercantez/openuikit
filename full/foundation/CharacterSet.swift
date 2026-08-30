/// A value-semantic set of Unicode scalar values.
///
/// This is the first portable `Foundation.CharacterSet` surface. It deliberately
/// stores scalars rather than grapheme clusters: that is the unit used by
/// Foundation's membership and string-trimming APIs. Additional named sets and
/// set algebra can be added without changing this representation.
public struct CharacterSet: Hashable, Sendable {
    fileprivate var scalarValues: Set<UInt32>

    /// Creates an empty character set.
    public init() {
        scalarValues = []
    }

    /// Creates a character set containing every Unicode scalar in `aString`.
    public init(charactersIn aString: String) {
        scalarValues = Set(aString.unicodeScalars.lazy.map(\.value))
    }

    private init(scalarValues: Set<UInt32>) {
        self.scalarValues = scalarValues
    }

    /// Returns whether `member` belongs to the set.
    public func contains(_ member: Unicode.Scalar) -> Bool {
        scalarValues.contains(member.value)
    }

    /// Inserts every scalar from `other` into this set.
    public mutating func formUnion(_ other: CharacterSet) {
        scalarValues.formUnion(other.scalarValues)
    }

    /// Returns a set containing the scalars from both operands.
    public func union(_ other: CharacterSet) -> CharacterSet {
        CharacterSet(scalarValues: scalarValues.union(other.scalarValues))
    }

    /// Removes every Unicode scalar present in `aString`.
    public mutating func remove(charactersIn aString: String) {
        for scalar in aString.unicodeScalars {
            scalarValues.remove(scalar.value)
        }
    }

    /// The horizontal and non-line-breaking whitespace set exposed by
    /// Darwin Foundation.
    public static let whitespaces = CharacterSet(
        scalarValues: [
            0x0009, 0x0020, 0x00A0, 0x1680,
            0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005,
            0x2006, 0x2007, 0x2008, 0x2009, 0x200A, 0x200B,
            0x202F, 0x205F, 0x3000,
        ]
    )

    /// The whitespace-and-newline set exposed by Darwin Foundation.
    ///
    /// The explicit scalar inventory is intentional. Swift's Unicode
    /// `isWhitespace` property is almost, but not quite, the same contract:
    /// Darwin Foundation additionally includes U+200B for compatibility.
    public static let whitespacesAndNewlines = CharacterSet(
        scalarValues: [
            0x0009, 0x000A, 0x000B, 0x000C, 0x000D, 0x0020,
            0x0085, 0x00A0, 0x1680,
            0x2000, 0x2001, 0x2002, 0x2003, 0x2004, 0x2005,
            0x2006, 0x2007, 0x2008, 0x2009, 0x200A, 0x200B,
            0x2028, 0x2029, 0x202F, 0x205F, 0x3000,
        ]
    )

    // These inventories are the RFC 3986 character groups used by Darwin
    // Foundation's URL component sets. They are intentionally explicit: the
    // encoder below operates on Unicode scalars and must not inherit a host
    // locale or a URL parser's context-sensitive rules.
    private static let urlUnreserved =
        CharacterSet(charactersIn: "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789-._~")
    private static let urlSubDelimiters = CharacterSet(charactersIn: "!$&'()*+,;=")

    public static let urlUserAllowed = urlUnreserved.union(urlSubDelimiters)
    public static let urlPasswordAllowed = urlUserAllowed
    public static let urlHostAllowed = urlUserAllowed.union(CharacterSet(charactersIn: ":[]"))
    public static let urlPathAllowed = urlUserAllowed.union(CharacterSet(charactersIn: ":@/"))
    public static let urlQueryAllowed = urlPathAllowed.union(CharacterSet(charactersIn: "?"))
    public static let urlFragmentAllowed = urlQueryAllowed
}

/// Mutable reference-semantic counterpart of `CharacterSet`.
///
/// The bridge conformance on `CharacterSet` makes unchanged source such as
/// `mutable as CharacterSet` take a value snapshot, matching the Foundation
/// API boundary without making the value type itself reference-semantic.
public final class NSMutableCharacterSet: @unchecked Sendable {
    fileprivate var value: CharacterSet

    public init() {
        value = CharacterSet()
    }

    public init(charactersIn aString: String) {
        value = CharacterSet(charactersIn: aString)
    }

    public func formUnion(with other: CharacterSet) {
        value.formUnion(other)
    }

    public func removeCharacters(in aString: String) {
        value.remove(charactersIn: aString)
    }
}

extension CharacterSet: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSMutableCharacterSet

    public func _bridgeToObjectiveC() -> NSMutableCharacterSet {
        let result = NSMutableCharacterSet()
        result.value = self
        return result
    }

    public static func _forceBridgeFromObjectiveC(
        _ source: NSMutableCharacterSet,
        result: inout CharacterSet?
    ) {
        result = source.value
    }

    public static func _conditionallyBridgeFromObjectiveC(
        _ source: NSMutableCharacterSet,
        result: inout CharacterSet?
    ) -> Bool {
        result = source.value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSMutableCharacterSet?
    ) -> CharacterSet {
        source?.value ?? CharacterSet()
    }
}
