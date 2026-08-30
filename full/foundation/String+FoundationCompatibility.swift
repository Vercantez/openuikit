// Legacy Foundation String overlay APIs that FoundationEssentials deliberately
// excludes when it is built outside the complete Foundation framework.
//
// This file is project-owned. It uses FoundationEssentials' public value types
// and Swift's first-party regex engine; it does not copy an implementation from
// Apple Foundation or swift-corelibs-foundation.

import FoundationEssentials
import _StringProcessing

/// The measured guest surface uses NSString only for its path conveniences,
/// comparison-option namespace, and casts of plist strings. A Swift String is
/// the single value identity at that boundary; Objective-C message dispatch is
/// outside this standalone facade.
public typealias NSString = String
public typealias NSLocale = Locale

public extension String {
    init(string aString: String) {
        self = aString
    }

    var lastPathComponent: String {
        URL(fileURLWithPath: self).lastPathComponent
    }

    func appendingPathComponent(_ component: String) -> String {
        URL(fileURLWithPath: self, isDirectory: true)
            .appendingPathComponent(component)
            .path
    }

    /// Reads a string while allowing FoundationEssentials to detect the BOM or
    /// fall back to its platform-independent encoding detector.
    init(contentsOfFile path: String) throws {
        var encoding = String.Encoding.utf8
        try self.init(contentsOfFile: path, usedEncoding: &encoding)
    }

    /// Reads a string while allowing FoundationEssentials to detect the BOM or
    /// fall back to its platform-independent encoding detector.
    init(contentsOf url: URL) throws {
        var encoding = String.Encoding.utf8
        try self.init(contentsOf: url, usedEncoding: &encoding)
    }

    /// Finds a string with the legacy Foundation search signature.
    ///
    /// Literal, backwards, anchored, case-insensitive, and regular-expression
    /// searches are implemented. The latter is intentionally backed by the
    /// Swift runtime's regex engine already shipped in the FoundationEssentials
    /// guest closure, rather than by an app-specific pattern matcher.
    func range(
        of aString: String,
        options mask: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil,
        locale: Locale? = nil
    ) -> Range<Index>? {
        _ = locale
        guard !aString.isEmpty else { return nil }
        let bounds = searchRange ?? startIndex..<endIndex
        guard bounds.lowerBound >= startIndex,
              bounds.upperBound <= endIndex,
              bounds.lowerBound <= bounds.upperBound else { return nil }
        let haystack = self[bounds]

        if mask.contains(.regularExpression) {
            var pattern = aString
            if mask.contains(.caseInsensitive) {
                pattern = "(?i:\(pattern))"
            }
            guard let regex = try? Regex<AnyRegexOutput>(pattern) else { return nil }
            let match: Regex<AnyRegexOutput>.Match?
            if mask.contains(.anchored) {
                match = haystack.prefixMatch(of: regex)
            } else {
                match = haystack.firstMatch(of: regex)
            }
            // This bounded overlay does not expose zero-width regular-
            // expression matches. Rejecting them is deterministic and keeps
            // replacement cursors strictly advancing instead of accepting an
            // anchor/a* match that could otherwise loop forever.
            guard let match, match.range.lowerBound != match.range.upperBound else {
                return nil
            }
            return match.range
        }

        let backwards = mask.contains(.backwards)
        let anchored = mask.contains(.anchored)
        let needleCount = aString.count
        guard needleCount <= haystack.count else { return nil }

        func matches(at lower: Index) -> Range<Index>? {
            guard let upper = index(lower, offsetBy: needleCount, limitedBy: bounds.upperBound)
            else { return nil }
            let candidate = self[lower..<upper]
            if _foundationGuestStringsEqual(candidate, aString, options: mask) {
                return lower..<upper
            }
            return nil
        }

        if anchored {
            if backwards {
                let lower = index(bounds.upperBound, offsetBy: -needleCount)
                return matches(at: lower)
            }
            return matches(at: bounds.lowerBound)
        }

        if backwards {
            var cursor = index(bounds.upperBound, offsetBy: -needleCount)
            while true {
                if let match = matches(at: cursor) { return match }
                if cursor == bounds.lowerBound { return nil }
                formIndex(before: &cursor)
            }
        }

        var cursor = bounds.lowerBound
        while let upper = index(cursor, offsetBy: needleCount, limitedBy: bounds.upperBound) {
            if let match = matches(at: cursor) { return match }
            if upper == bounds.upperBound { return nil }
            formIndex(after: &cursor)
        }
        return nil
    }

    /// Compares two strings using Foundation's result type.
    func compare(
        _ aString: String,
        options mask: String.CompareOptions = [],
        range compareRange: Range<Index>? = nil,
        locale: Locale? = nil
    ) -> ComparisonResult {
        _ = locale
        let bounds = compareRange ?? startIndex..<endIndex
        let lhs = String(self[bounds])
        let transformedLeft = _foundationGuestComparableString(lhs, options: mask)
        let transformedRight = _foundationGuestComparableString(aString, options: mask)
        if transformedLeft == transformedRight { return .orderedSame }
        return transformedLeft < transformedRight ? .orderedAscending : .orderedDescending
    }

    /// Returns a copy with all non-overlapping matches replaced.
    func replacingOccurrences(
        of target: String,
        with replacement: String,
        options: String.CompareOptions = [],
        range searchRange: Range<Index>? = nil
    ) -> String {
        guard !target.isEmpty else { return self }
        let bounds = searchRange ?? startIndex..<endIndex
        var matches: [Range<Index>] = []
        var cursor = bounds.lowerBound
        let backwards = options.contains(.backwards)

        if backwards {
            var upper = bounds.upperBound
            while upper >= bounds.lowerBound,
                  let match = range(
                      of: target,
                      options: options,
                      range: bounds.lowerBound..<upper,
                      locale: nil
                  ) {
                matches.append(match)
                guard match.lowerBound > bounds.lowerBound else { break }
                upper = match.lowerBound
                if options.contains(.anchored) { break }
            }
        } else {
            while cursor <= bounds.upperBound,
                  let match = range(
                      of: target,
                      options: options,
                      range: cursor..<bounds.upperBound,
                      locale: nil
                  ) {
                matches.append(match)
                cursor = match.upperBound
                if options.contains(.anchored) { break }
            }
        }

        guard !matches.isEmpty else { return self }
        matches.sort { $0.lowerBound < $1.lowerBound }
        var result = ""
        var copiedThrough = startIndex
        for match in matches {
            result += self[copiedThrough..<match.lowerBound]
            result += replacement
            copiedThrough = match.upperBound
        }
        result += self[copiedThrough..<endIndex]
        return result
    }

    /// Adds UTF-8 percent escapes for every scalar outside `allowedCharacters`.
    func addingPercentEncoding(
        withAllowedCharacters allowedCharacters: CharacterSet
    ) -> String? {
        let hex = Array("0123456789ABCDEF".utf8)
        var output: [UInt8] = []
        output.reserveCapacity(utf8.count)
        for scalar in unicodeScalars {
            if allowedCharacters.contains(scalar) {
                output.append(contentsOf: String(scalar).utf8)
            } else {
                for byte in String(scalar).utf8 {
                    output.append(0x25)
                    output.append(hex[Int(byte >> 4)])
                    output.append(hex[Int(byte & 0x0F)])
                }
            }
        }
        return String(decoding: output, as: UTF8.self)
    }

    /// Decodes well-formed UTF-8 percent escapes and fails closed on malformed
    /// escape sequences or byte sequences.
    var removingPercentEncoding: String? {
        let input = Array(utf8)
        var output: [UInt8] = []
        output.reserveCapacity(input.count)
        var index = 0
        while index < input.count {
            if input[index] == 0x25 {
                guard index + 2 < input.count,
                      let high = _foundationGuestHex(input[index + 1]),
                      let low = _foundationGuestHex(input[index + 2]) else { return nil }
                output.append((high << 4) | low)
                index += 3
            } else {
                output.append(input[index])
                index += 1
            }
        }
        return String(validating: output, as: UTF8.self)
    }

    /// Foundation's formatting initializer. The guest accepts `Any` arguments
    /// because the standalone Swift standard library does not give `String` a
    /// `CVarArg` conformance. This preserves unchanged Swift call sites and
    /// supports localized positional arguments, `%%`, object/string, signed
    /// and unsigned integer, hexadecimal, and floating-point conversions.
    init(format: String, _ arguments: Any...) {
        self = _foundationGuestFormat(format, arguments: arguments)
    }
}

public func NSLog(_ format: String, _ arguments: Any...) {
    print(_foundationGuestFormat(format, arguments: arguments))
}

private func _foundationGuestStringsEqual(
    _ lhs: Substring,
    _ rhs: String,
    options: String.CompareOptions
) -> Bool {
    _foundationGuestComparableString(String(lhs), options: options) ==
        _foundationGuestComparableString(rhs, options: options)
}

private func _foundationGuestComparableString(
    _ value: String,
    options: String.CompareOptions
) -> String {
    if options.contains(.caseInsensitive) {
        return value.lowercased()
    }
    return value
}

private func _foundationGuestHex(_ byte: UInt8) -> UInt8? {
    switch byte {
    case 0x30...0x39: return byte - 0x30
    case 0x41...0x46: return byte - 0x41 + 10
    case 0x61...0x66: return byte - 0x61 + 10
    default: return nil
    }
}

private func _foundationGuestFormat(_ format: String, arguments: [Any]) -> String {
    let characters = Array(format)
    var result = ""
    var cursor = 0
    var sequentialArgument = 0

    while cursor < characters.count {
        guard characters[cursor] == "%" else {
            result.append(characters[cursor])
            cursor += 1
            continue
        }
        let percentStart = cursor
        cursor += 1
        guard cursor < characters.count else {
            result.append("%")
            break
        }
        if characters[cursor] == "%" {
            result.append("%")
            cursor += 1
            continue
        }

        var explicitPosition: Int?
        let positionStart = cursor
        var positionDigits = ""
        while cursor < characters.count, characters[cursor].isNumber {
            positionDigits.append(characters[cursor])
            cursor += 1
        }
        if cursor < characters.count, characters[cursor] == "$",
           let oneBased = Int(positionDigits), oneBased > 0 {
            explicitPosition = oneBased - 1
            cursor += 1
        } else {
            cursor = positionStart
        }

        var flags = Set<Character>()
        while cursor < characters.count, "-+ 0#".contains(characters[cursor]) {
            flags.insert(characters[cursor])
            cursor += 1
        }
        var widthDigits = ""
        while cursor < characters.count, characters[cursor].isNumber {
            widthDigits.append(characters[cursor])
            cursor += 1
        }
        let width = Int(widthDigits)

        var precision: Int?
        if cursor < characters.count, characters[cursor] == "." {
            cursor += 1
            var digits = ""
            while cursor < characters.count, characters[cursor].isNumber {
                digits.append(characters[cursor])
                cursor += 1
            }
            precision = Int(digits) ?? 0
        }

        while cursor < characters.count, "hlLzjtq".contains(characters[cursor]) {
            cursor += 1
        }
        guard cursor < characters.count else {
            result += String(characters[percentStart...])
            break
        }
        let conversion = characters[cursor]
        cursor += 1
        let argumentIndex = explicitPosition ?? sequentialArgument
        if explicitPosition == nil { sequentialArgument += 1 }
        guard argumentIndex < arguments.count else {
            result += String(characters[percentStart..<cursor])
            continue
        }

        var rendered = _foundationGuestRenderArgument(
            arguments[argumentIndex],
            conversion: conversion,
            precision: precision,
            alternate: flags.contains("#")
        )
        if let width, rendered.count < width {
            let paddingCharacter: Character = flags.contains("0") && !flags.contains("-") ? "0" : " "
            let padding = String(repeating: String(paddingCharacter), count: width - rendered.count)
            rendered = flags.contains("-") ? rendered + padding : padding + rendered
        }
        if flags.contains("+"), conversion == "d" || conversion == "i" || conversion == "f",
           rendered.first != "-" {
            rendered = "+" + rendered
        }
        result += rendered
    }
    return result
}

private func _foundationGuestRenderArgument(
    _ argument: Any,
    conversion: Character,
    precision: Int?,
    alternate: Bool
) -> String {
    switch conversion {
    case "@", "s":
        let value = String(describing: argument)
        guard let precision else { return value }
        return String(value.prefix(precision))
    case "d", "i":
        return _foundationGuestSigned(argument).map(String.init) ?? String(describing: argument)
    case "u":
        return _foundationGuestUnsigned(argument).map(String.init) ?? String(describing: argument)
    case "x", "X":
        guard let value = _foundationGuestUnsigned(argument) else {
            return String(describing: argument)
        }
        let digits = String(value, radix: 16, uppercase: conversion == "X")
        if alternate { return conversion == "X" ? "0X" + digits : "0x" + digits }
        return digits
    case "o":
        guard let value = _foundationGuestUnsigned(argument) else {
            return String(describing: argument)
        }
        let digits = String(value, radix: 8)
        return alternate ? "0" + digits : digits
    case "f", "F", "e", "E", "g", "G":
        let value: Double?
        if let double = argument as? Double { value = double }
        else if let float = argument as? Float { value = Double(float) }
        else { value = nil }
        guard let value else { return String(describing: argument) }
        // Swift's stable description is locale-independent. Exact printf
        // precision/exponent rounding beyond this bounded facade remains a
        // named gap; integer precision and Focus's string formats are exact.
        if let precision, precision == 0 { return String(Int(value.rounded())) }
        return String(value)
    case "c":
        guard let value = _foundationGuestUnsigned(argument),
              let scalar = Unicode.Scalar(UInt32(truncatingIfNeeded: value)) else {
            return String(describing: argument)
        }
        return String(scalar)
    default:
        return "%" + String(conversion)
    }
}

private func _foundationGuestSigned(_ value: Any) -> Int64? {
    if let value = value as? Int { return Int64(value) }
    if let value = value as? Int8 { return Int64(value) }
    if let value = value as? Int16 { return Int64(value) }
    if let value = value as? Int32 { return Int64(value) }
    if let value = value as? Int64 { return value }
    if let value = value as? UInt { return Int64(exactly: value) }
    if let value = value as? UInt64 { return Int64(exactly: value) }
    return nil
}

private func _foundationGuestUnsigned(_ value: Any) -> UInt64? {
    if let value = value as? UInt { return UInt64(value) }
    if let value = value as? UInt8 { return UInt64(value) }
    if let value = value as? UInt16 { return UInt64(value) }
    if let value = value as? UInt32 { return UInt64(value) }
    if let value = value as? UInt64 { return value }
    if let value = value as? Int, value >= 0 { return UInt64(value) }
    if let value = value as? Int64, value >= 0 { return UInt64(value) }
    return nil
}
