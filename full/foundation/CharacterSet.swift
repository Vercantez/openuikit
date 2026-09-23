import ObjectiveC

/// A value-semantic set of Unicode scalar values.
///
/// This is the first portable `Foundation.CharacterSet` surface. It deliberately
/// stores scalars rather than grapheme clusters: that is the unit used by
/// Foundation's membership and string-trimming APIs. Additional named sets and
/// set algebra can be added without changing this representation.
public struct CharacterSet: Hashable, Sendable {
    fileprivate var scalarValues: Set<UInt32>
    /// `inverted` without enumerating 1.1M scalars: membership is
    /// `scalarValues.contains(v) != isInverted`.
    fileprivate var isInverted = false

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
        scalarValues.contains(member.value) != isInverted
    }

    /// Inserts every scalar from `other` into this set.
    public mutating func formUnion(_ other: CharacterSet) {
        self = union(other)
    }

    /// Returns a set containing the scalars from both operands.
    public func union(_ other: CharacterSet) -> CharacterSet {
        switch (isInverted, other.isInverted) {
        case (false, false):
            return CharacterSet(scalarValues: scalarValues.union(other.scalarValues))
        case (true, true):
            var result = CharacterSet(scalarValues: scalarValues.intersection(other.scalarValues))
            result.isInverted = true
            return result
        case (true, false):
            var result = CharacterSet(scalarValues: scalarValues.subtracting(other.scalarValues))
            result.isInverted = true
            return result
        case (false, true):
            var result = CharacterSet(scalarValues: other.scalarValues.subtracting(scalarValues))
            result.isInverted = true
            return result
        }
    }

    /// The complement of this set over all Unicode scalars.
    public var inverted: CharacterSet {
        var result = self
        result.isInverted.toggle()
        return result
    }

    /// Mutating complement.
    public mutating func invert() {
        isInverted.toggle()
    }

    /// Inserts every Unicode scalar present in `aString`.
    public mutating func insert(charactersIn aString: String) {
        for scalar in aString.unicodeScalars {
            if isInverted { scalarValues.remove(scalar.value) } else { scalarValues.insert(scalar.value) }
        }
    }

    /// Removes every Unicode scalar present in `aString`.
    public mutating func remove(charactersIn aString: String) {
        for scalar in aString.unicodeScalars {
            if isInverted { scalarValues.insert(scalar.value) } else { scalarValues.remove(scalar.value) }
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

    private struct NamedCategorySets {
        var uppercase = Set<UInt32>()
        var lowercase = Set<UInt32>()
        var letters = Set<UInt32>()
        var alphanumerics = Set<UInt32>()
        var symbols = Set<UInt32>()
        var decimalDigits = Set<UInt32>()
    }

    private static let namedCategorySets: NamedCategorySets = {
        var result = NamedCategorySets()
        for value in UInt32(0)...0x10FFFF {
            guard let scalar = Unicode.Scalar(value) else { continue }
            switch scalar.properties.generalCategory {
            case .uppercaseLetter:
                result.uppercase.insert(value)
                result.letters.insert(value)
                result.alphanumerics.insert(value)
            case .titlecaseLetter:
                result.uppercase.insert(value)
                result.letters.insert(value)
                result.alphanumerics.insert(value)
            case .lowercaseLetter:
                result.lowercase.insert(value)
                result.letters.insert(value)
                result.alphanumerics.insert(value)
            case .modifierLetter, .otherLetter,
                 .nonspacingMark, .spacingMark, .enclosingMark:
                result.letters.insert(value)
                result.alphanumerics.insert(value)
            case .decimalNumber:
                result.decimalDigits.insert(value)
                result.alphanumerics.insert(value)
            case .letterNumber, .otherNumber:
                result.alphanumerics.insert(value)
            case .mathSymbol, .currencySymbol, .modifierSymbol, .otherSymbol:
                result.symbols.insert(value)
            default:
                break
            }
        }
        return result
    }()

    public static var uppercaseLetters: CharacterSet {
        CharacterSet(scalarValues: namedCategorySets.uppercase)
    }

    public static var lowercaseLetters: CharacterSet {
        CharacterSet(scalarValues: namedCategorySets.lowercase)
    }

    public static var letters: CharacterSet {
        CharacterSet(scalarValues: namedCategorySets.letters)
    }

    public static var alphanumerics: CharacterSet {
        CharacterSet(scalarValues: namedCategorySets.alphanumerics)
    }

    public static var symbols: CharacterSet {
        CharacterSet(scalarValues: namedCategorySets.symbols)
    }

    public static var decimalDigits: CharacterSet {
        CharacterSet(scalarValues: namedCategorySets.decimalDigits)
    }

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

/// Reference-semantic counterpart of `CharacterSet` (NSCharacterSet). Its
/// class properties (`NSCharacterSet.whitespacesAndNewlines`, ...) are the
/// CharacterSet values, as in Apple's Swift overlay
/// (full/foundation/FoundationObjCNames.swift).
///
/// The bridge conformance on `CharacterSet` makes unchanged source such as
/// `mutable as CharacterSet` take a value snapshot, matching the Foundation
/// API boundary without making the value type itself reference-semantic.
open class NSCharacterSet: NSObject, @unchecked Sendable {
    fileprivate var value: CharacterSet

    public override init() {
        value = CharacterSet()
        super.init()
    }

    public init(charactersIn aString: String) {
        value = CharacterSet(charactersIn: aString)
        super.init()
    }

    open func characterIsMember(_ aCharacter: unichar) -> Bool {
        guard let scalar = Unicode.Scalar(UInt32(aCharacter)) else { return false }
        return value.contains(scalar)
    }

    open func longCharacterIsMember(_ theLongChar: UInt32) -> Bool {
        guard let scalar = Unicode.Scalar(theLongChar) else { return false }
        return value.contains(scalar)
    }

    open var inverted: CharacterSet { value.inverted }

    open override func isEqual(_ object: Any?) -> Bool {
        (object as? NSCharacterSet)?.value == value
    }

    open override var hash: Int { value.hashValue }
}

/// Mutable reference-semantic counterpart of `CharacterSet`.
open class NSMutableCharacterSet: NSCharacterSet, @unchecked Sendable {
    public override init() {
        super.init()
    }

    public override init(charactersIn aString: String) {
        super.init(charactersIn: aString)
    }

    open func formUnion(with other: CharacterSet) {
        value.formUnion(other)
    }

    open func addCharacters(in aString: String) {
        value.insert(charactersIn: aString)
    }

    open func removeCharacters(in aString: String) {
        value.remove(charactersIn: aString)
    }

    open func invert() {
        value.invert()
    }
}

extension CharacterSet: _ObjectiveCBridgeable {
    public typealias _ObjectiveCType = NSCharacterSet

    public func _bridgeToObjectiveC() -> NSCharacterSet {
        let result = NSCharacterSet()
        result.value = self
        return result
    }

    public static func _forceBridgeFromObjectiveC(
        _ source: NSCharacterSet,
        result: inout CharacterSet?
    ) {
        result = source.value
    }

    public static func _conditionallyBridgeFromObjectiveC(
        _ source: NSCharacterSet,
        result: inout CharacterSet?
    ) -> Bool {
        result = source.value
        return true
    }

    public static func _unconditionallyBridgeFromObjectiveC(
        _ source: NSCharacterSet?
    ) -> CharacterSet {
        source?.value ?? CharacterSet()
    }
}
