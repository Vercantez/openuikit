/// A value-semantic set of Unicode scalar values.
///
/// This is the first portable `Foundation.CharacterSet` surface. It deliberately
/// stores scalars rather than grapheme clusters: that is the unit used by
/// Foundation's membership and string-trimming APIs. Additional named sets and
/// set algebra can be added without changing this representation.
public struct CharacterSet: Hashable, Sendable {
    private var scalarValues: Set<UInt32>

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
}
