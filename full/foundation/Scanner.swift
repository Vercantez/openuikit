/// A forward-only scanner over a Swift string.
///
/// The initial surface is intentionally bounded to hexadecimal integers, but
/// the implementation maintains a real cursor and an arbitrary scalar skip set
/// so additional scan operations can share the same state machine.
public final class Scanner {
    public let string: String
    public var currentIndex: String.Index
    public var charactersToBeSkipped: CharacterSet?

    public init(string: String) {
        self.string = string
        currentIndex = string.startIndex
        charactersToBeSkipped = .whitespacesAndNewlines
    }

    /// Returns true when only skipped characters remain. Inspecting this value
    /// does not advance `currentIndex`.
    public var isAtEnd: Bool {
        skippingCharacters(from: currentIndex) == string.endIndex
    }

    /// Scans an unsigned hexadecimal integer, saturating at `UInt64.max` on
    /// overflow while still consuming the complete run of hexadecimal digits.
    ///
    /// An optional `0x`/`0X` prefix is recognized only when followed by a hex
    /// digit. On failure neither the cursor nor `result` is changed.
    @discardableResult
    public func scanHexInt64(_ result: UnsafeMutablePointer<UInt64>?) -> Bool {
        let original = currentIndex
        var cursor = skippingCharacters(from: original)
        var value: UInt64 = 0
        var sawDigit = false

        if scalar(at: cursor) == Unicode.Scalar("0") {
            let afterZero = index(after: cursor)
            if let marker = scalar(at: afterZero),
               marker == Unicode.Scalar("x") || marker == Unicode.Scalar("X") {
                let afterMarker = index(after: afterZero)
                if hexadecimalValue(at: afterMarker) != nil {
                    cursor = afterMarker
                }
            }
        }

        while let digit = hexadecimalValue(at: cursor) {
            sawDigit = true
            let (multiplied, multiplyOverflow) = value.multipliedReportingOverflow(by: 16)
            let (added, addOverflow) = multiplied.addingReportingOverflow(UInt64(digit))
            value = multiplyOverflow || addOverflow ? UInt64.max : added
            cursor = index(after: cursor)
        }

        guard sawDigit else {
            currentIndex = original
            return false
        }

        currentIndex = cursor
        result?.pointee = value
        return true
    }

    private func skippingCharacters(from start: String.Index) -> String.Index {
        guard let charactersToBeSkipped else {
            return start
        }

        var cursor = start
        while let value = scalar(at: cursor), charactersToBeSkipped.contains(value) {
            cursor = index(after: cursor)
        }
        return cursor
    }

    private func scalar(at index: String.Index) -> Unicode.Scalar? {
        guard index < string.endIndex else {
            return nil
        }
        return string.unicodeScalars[index]
    }

    private func index(after index: String.Index) -> String.Index {
        string.unicodeScalars.index(after: index)
    }

    private func hexadecimalValue(at index: String.Index) -> UInt8? {
        guard let value = scalar(at: index)?.value else {
            return nil
        }

        switch value {
        case 0x30...0x39:
            return UInt8(value - 0x30)
        case 0x41...0x46:
            return UInt8(value - 0x41 + 10)
        case 0x61...0x66:
            return UInt8(value - 0x61 + 10)
        default:
            return nil
        }
    }
}
