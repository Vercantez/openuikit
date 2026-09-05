// Project-owned NSRegularExpression facade backed by Swift's first-party
// _StringProcessing engine. The implementation preserves Foundation's UTF-16
// NSRange boundary while keeping the regex engine in the shipped Swift runtime.

#if FOUNDATION_GUEST_SERVICES_HOST
import Foundation
#else
import FoundationEssentials
import ObjectiveC
import _StringProcessing
#endif

open class NSTextCheckingResult: NSObject, @unchecked Sendable {
    public struct CheckingType: OptionSet, Sendable {
        public let rawValue: UInt64
        public init(rawValue: UInt64) { self.rawValue = rawValue }

        public static let orthography = CheckingType(rawValue: 1 << 0)
        public static let spelling = CheckingType(rawValue: 1 << 1)
        public static let grammar = CheckingType(rawValue: 1 << 2)
        public static let date = CheckingType(rawValue: 1 << 3)
        public static let address = CheckingType(rawValue: 1 << 4)
        public static let link = CheckingType(rawValue: 1 << 5)
        public static let quote = CheckingType(rawValue: 1 << 6)
        public static let dash = CheckingType(rawValue: 1 << 7)
        public static let replacement = CheckingType(rawValue: 1 << 8)
        public static let correction = CheckingType(rawValue: 1 << 9)
        public static let regularExpression = CheckingType(rawValue: 1 << 10)
        public static let phoneNumber = CheckingType(rawValue: 1 << 11)
        public static let transitInformation = CheckingType(rawValue: 1 << 12)
    }

    private let captureRanges: [NSRange]
    private let namedCaptureIndexes: [String: Int]
    private let expression: NSRegularExpression?

    internal init(
        ranges: [NSRange],
        names: [String: Int],
        regularExpression: NSRegularExpression?
    ) {
        captureRanges = ranges
        namedCaptureIndexes = names
        expression = regularExpression
        super.init()
    }

    open var range: NSRange {
        captureRanges.first ?? NSRange(location: NSNotFound, length: 0)
    }

    open var numberOfRanges: Int { captureRanges.count }
    open var resultType: CheckingType { .regularExpression }

    open func range(at idx: Int) -> NSRange {
        guard captureRanges.indices.contains(idx) else {
            return NSRange(location: NSNotFound, length: 0)
        }
        return captureRanges[idx]
    }

    open func range(withName name: String) -> NSRange {
        guard let index = namedCaptureIndexes[name] else {
            return NSRange(location: NSNotFound, length: 0)
        }
        return range(at: index)
    }

    open var regularExpression: NSRegularExpression? { expression }
}

open class NSRegularExpression: NSObject, @unchecked Sendable {
    public struct Options: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let caseInsensitive = Options(rawValue: 1 << 0)
        public static let allowCommentsAndWhitespace = Options(rawValue: 1 << 1)
        public static let ignoreMetacharacters = Options(rawValue: 1 << 2)
        public static let dotMatchesLineSeparators = Options(rawValue: 1 << 3)
        public static let anchorsMatchLines = Options(rawValue: 1 << 4)
        public static let useUnixLineSeparators = Options(rawValue: 1 << 5)
        public static let useUnicodeWordBoundaries = Options(rawValue: 1 << 6)
    }

    public struct MatchingOptions: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let reportProgress = MatchingOptions(rawValue: 1 << 0)
        public static let reportCompletion = MatchingOptions(rawValue: 1 << 1)
        public static let anchored = MatchingOptions(rawValue: 1 << 2)
        public static let withTransparentBounds = MatchingOptions(rawValue: 1 << 3)
        public static let withoutAnchoringBounds = MatchingOptions(rawValue: 1 << 4)
    }

    public struct MatchingFlags: OptionSet, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }

        public static let progress = MatchingFlags(rawValue: 1 << 0)
        public static let completed = MatchingFlags(rawValue: 1 << 1)
        public static let hitEnd = MatchingFlags(rawValue: 1 << 2)
        public static let requiredEnd = MatchingFlags(rawValue: 1 << 3)
        public static let internalError = MatchingFlags(rawValue: 1 << 4)
    }

    public let pattern: String
    public let options: Options
    public let numberOfCaptureGroups: Int

    private let regex: Regex<AnyRegexOutput>

    public init(pattern: String, options: Options = []) throws {
        let known: Options = [
            .caseInsensitive,
            .allowCommentsAndWhitespace,
            .ignoreMetacharacters,
            .dotMatchesLineSeparators,
            .anchorsMatchLines,
        ]
        guard options.subtracting(known).isEmpty else {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: 2048,
                userInfo: [NSDebugDescriptionErrorKey: "Unsupported regular-expression option"]
            )
        }

        self.pattern = pattern
        self.options = options
        let effective = Self._effectivePattern(pattern, options: options)
        do {
            regex = try Regex<AnyRegexOutput>(effective)
        } catch {
            throw NSError(
                domain: NSCocoaErrorDomain,
                code: 2048,
                userInfo: ["NSInvalidValue": pattern, NSUnderlyingErrorKey: error]
            )
        }
        numberOfCaptureGroups = Self._captureGroupCount(pattern)
        super.init()
    }

    open func enumerateMatches(
        in string: String,
        options: MatchingOptions = [],
        range: NSRange,
        using block: (NSTextCheckingResult?, MatchingFlags, UnsafeMutablePointer<ObjCBool>) -> Void
    ) {
        var stop: ObjCBool = false
        if options.contains(.reportProgress) {
            block(nil, .progress, &stop)
        }
        if !stop.boolValue {
            for result in _results(in: string, options: options, range: range) {
                block(result, [], &stop)
                if stop.boolValue { break }
            }
        }
        if options.contains(.reportCompletion) {
            if !stop.boolValue { block(nil, .completed, &stop) }
        }
    }

    open func matches(
        in string: String,
        options: MatchingOptions = [],
        range: NSRange
    ) -> [NSTextCheckingResult] {
        _results(in: string, options: options, range: range)
    }

    open func numberOfMatches(
        in string: String,
        options: MatchingOptions = [],
        range: NSRange
    ) -> Int {
        _results(in: string, options: options, range: range).count
    }

    open func firstMatch(
        in string: String,
        options: MatchingOptions = [],
        range: NSRange
    ) -> NSTextCheckingResult? {
        _results(in: string, options: options, range: range).first
    }

    open func rangeOfFirstMatch(
        in string: String,
        options: MatchingOptions = [],
        range: NSRange
    ) -> NSRange {
        firstMatch(in: string, options: options, range: range)?.range
            ?? NSRange(location: NSNotFound, length: 0)
    }

    open func stringByReplacingMatches(
        in string: String,
        options: MatchingOptions = [],
        range: NSRange,
        withTemplate templ: String
    ) -> String {
        let results = _results(in: string, options: options, range: range)
        guard !results.isEmpty else { return string }

        var output = ""
        var cursor = string.startIndex
        for result in results {
            guard let matchRange = _foundationGuestStringRange(result.range, in: string),
                  matchRange.lowerBound >= cursor else { continue }
            output += string[cursor..<matchRange.lowerBound]
            output += replacementString(for: result, in: string, offset: 0, template: templ)
            cursor = matchRange.upperBound
        }
        output += string[cursor..<string.endIndex]
        return output
    }

    open func replacementString(
        for result: NSTextCheckingResult,
        in string: String,
        offset: Int,
        template templ: String
    ) -> String {
        var output = ""
        var index = templ.startIndex
        while index < templ.endIndex {
            let character = templ[index]
            if character == "\\" {
                let next = templ.index(after: index)
                if next < templ.endIndex {
                    output.append(templ[next])
                    index = templ.index(after: next)
                } else {
                    output.append(character)
                    index = next
                }
                continue
            }
            if character == "$" {
                var end = templ.index(after: index)
                let digitStart = end
                while end < templ.endIndex, templ[end].isNumber { templ.formIndex(after: &end) }
                if digitStart != end,
                   let capture = Int(templ[digitStart..<end]),
                   capture < result.numberOfRanges {
                    var captureRange = result.range(at: capture)
                    if captureRange.location != NSNotFound {
                        captureRange.location += offset
                        if let bounds = _foundationGuestStringRange(captureRange, in: string) {
                            output += string[bounds]
                        }
                    }
                    index = end
                    continue
                }
            }
            output.append(character)
            templ.formIndex(after: &index)
        }
        return output
    }

    open class func escapedPattern(for string: String) -> String {
        let metacharacters = "\\.*+?[](){}^$|/"
        var result = ""
        for character in string {
            if metacharacters.contains(character) { result.append("\\") }
            result.append(character)
        }
        return result
    }

    open class func escapedTemplate(for string: String) -> String {
        var result = ""
        for character in string {
            if character == "\\" || character == "$" { result.append("\\") }
            result.append(character)
        }
        return result
    }

    private func _results(
        in string: String,
        options matchingOptions: MatchingOptions,
        range: NSRange
    ) -> [NSTextCheckingResult] {
        guard let requested = _foundationGuestStringRange(range, in: string) else { return [] }
        let useWholeStringBounds = matchingOptions.contains(.withTransparentBounds)
            || matchingOptions.contains(.withoutAnchoringBounds)
        let scope = useWholeStringBounds ? string[string.startIndex..<string.endIndex] : string[requested]
        let rawMatches: [Regex<AnyRegexOutput>.Match]
        if matchingOptions.contains(.anchored) {
            if let match = scope.prefixMatch(of: regex), match.range.lowerBound == requested.lowerBound {
                rawMatches = [match]
            } else {
                rawMatches = []
            }
        } else {
            rawMatches = scope.matches(of: regex)
        }

        return rawMatches.compactMap { match in
            guard match.range.lowerBound >= requested.lowerBound,
                  match.range.upperBound <= requested.upperBound else { return nil }
            var ranges: [NSRange] = []
            var names: [String: Int] = [:]
            ranges.reserveCapacity(match.output.count)
            for (captureIndex, element) in match.output.enumerated() {
                if let name = element.name { names[name] = captureIndex }
                if let bounds = element.range {
                    ranges.append(_foundationGuestNSRange(bounds, in: string))
                } else {
                    ranges.append(NSRange(location: NSNotFound, length: 0))
                }
            }
            return NSTextCheckingResult(
                ranges: ranges,
                names: names,
                regularExpression: self
            )
        }
    }

    private static func _effectivePattern(_ pattern: String, options: Options) -> String {
        var body = options.contains(.ignoreMetacharacters)
            ? escapedPattern(for: pattern)
            : pattern
        var modifiers = ""
        if options.contains(.caseInsensitive) { modifiers.append("i") }
        if options.contains(.allowCommentsAndWhitespace) { modifiers.append("x") }
        if options.contains(.dotMatchesLineSeparators) { modifiers.append("s") }
        if options.contains(.anchorsMatchLines) { modifiers.append("m") }
        if !modifiers.isEmpty { body = "(?\(modifiers):\(body))" }
        return body
    }

    private static func _captureGroupCount(_ pattern: String) -> Int {
        var count = 0
        var escaped = false
        var inCharacterClass = false
        let characters = Array(pattern)
        var index = 0
        while index < characters.count {
            let character = characters[index]
            if escaped { escaped = false; index += 1; continue }
            if character == "\\" { escaped = true; index += 1; continue }
            if character == "[" { inCharacterClass = true; index += 1; continue }
            if character == "]" { inCharacterClass = false; index += 1; continue }
            if character == "(" && !inCharacterClass {
                if index + 1 >= characters.count || characters[index + 1] != "?" {
                    count += 1
                } else if index + 2 < characters.count,
                          characters[index + 2] == "<",
                          index + 3 < characters.count,
                          characters[index + 3] != "=" && characters[index + 3] != "!" {
                    count += 1
                } else if index + 2 < characters.count, characters[index + 2] == "'" {
                    count += 1
                }
            }
            index += 1
        }
        return count
    }
}

private func _foundationGuestNSRange(
    _ range: Range<String.Index>,
    in string: String
) -> NSRange {
    guard let lower = range.lowerBound.samePosition(in: string.utf16),
          let upper = range.upperBound.samePosition(in: string.utf16) else {
        return NSRange(location: NSNotFound, length: 0)
    }
    let location = string.utf16.distance(from: string.utf16.startIndex, to: lower)
    let length = string.utf16.distance(from: lower, to: upper)
    return NSRange(location: location, length: length)
}

private func _foundationGuestStringRange(
    _ range: NSRange,
    in string: String
) -> Range<String.Index>? {
    guard range.location != NSNotFound,
          range.location >= 0,
          range.length >= 0,
          range.location <= string.utf16.count,
          range.length <= string.utf16.count - range.location else { return nil }
    let lowerUTF16 = string.utf16.index(
        string.utf16.startIndex,
        offsetBy: range.location
    )
    let upperUTF16 = string.utf16.index(lowerUTF16, offsetBy: range.length)
    guard let lower = String.Index(lowerUTF16, within: string),
          let upper = String.Index(upperUTF16, within: string) else { return nil }
    return lower..<upper
}
