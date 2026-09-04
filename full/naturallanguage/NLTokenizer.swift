import Foundation

public final class NLTokenizer: NSObject {
    public struct Attributes: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let numeric = Attributes(rawValue: 1 << 0)
        public static let symbolic = Attributes(rawValue: 1 << 1)
        public static let emoji = Attributes(rawValue: 1 << 2)
    }

    public let unit: NLTokenUnit
    public var string: String?
    private var language: NLLanguage = .undetermined

    public init(unit: NLTokenUnit) {
        self.unit = unit
        super.init()
    }

    public func setLanguage(_ language: NLLanguage) {
        self.language = language
    }

    public func tokenRange(at index: String.Index) -> Range<String.Index> {
        guard let string else {
            let empty = "".startIndex
            return empty..<empty
        }
        if string.isEmpty || index < string.startIndex || index >= string.endIndex {
            return string.endIndex..<string.endIndex
        }
        for token in tokens(for: string.startIndex..<string.endIndex) {
            if token.contains(index) {
                return token
            }
        }
        return string.endIndex..<string.endIndex
    }

    public func tokenRange(for range: Range<String.Index>) -> Range<String.Index> {
        guard let string else {
            let empty = "".startIndex
            return empty..<empty
        }
        let clamped = clamp(range, to: string)
        if clamped.isEmpty {
            return tokenRange(at: clamped.lowerBound)
        }
        let start = tokenRange(at: clamped.lowerBound)
        let lastIndex = string.index(before: clamped.upperBound)
        let end = tokenRange(at: lastIndex)
        return start.lowerBound..<end.upperBound
    }

    public func tokens(for range: Range<String.Index>) -> [Range<String.Index>] {
        enumeratedTokens(in: range).map(\.range)
    }

    public func enumerateTokens(
        in range: Range<String.Index>,
        using block: (Range<String.Index>, NLTokenizer.Attributes) -> Bool
    ) {
        for token in enumeratedTokens(in: range) {
            if !block(token.range, token.attributes) {
                return
            }
        }
    }

    fileprivate struct TokenRecord {
        let range: Range<String.Index>
        let attributes: Attributes
        let kind: TokenKind
    }

    fileprivate enum TokenKind {
        case word
        case whitespace
        case punctuation
        case other
    }

    fileprivate func enumeratedTokens(in range: Range<String.Index>) -> [TokenRecord] {
        guard let string else { return [] }
        _ = language
        let clamped = clamp(range, to: string)
        switch unit {
        case .word:
            return wordTokens(in: string, range: clamped)
        case .sentence:
            return sentenceTokens(in: string, range: clamped)
        case .paragraph:
            return paragraphTokens(in: string, range: clamped)
        case .document:
            if clamped.isEmpty { return [] }
            return [
                TokenRecord(range: clamped, attributes: [], kind: .other)
            ]
        }
    }

    private func clamp(
        _ range: Range<String.Index>,
        to string: String
    ) -> Range<String.Index> {
        let lower = min(max(range.lowerBound, string.startIndex), string.endIndex)
        let upper = min(max(range.upperBound, string.startIndex), string.endIndex)
        return lower < upper ? lower..<upper : lower..<lower
    }

    private func wordTokens(
        in string: String,
        range: Range<String.Index>
    ) -> [TokenRecord] {
        var tokens: [TokenRecord] = []
        var index = range.lowerBound
        while index < range.upperBound {
            let character = string[index]
            let kind = wordKind(character)
            var end = string.index(after: index)
            while end < range.upperBound {
                if wordKind(string[end]) != kind { break }
                end = string.index(after: end)
            }
            let slice = string[index..<end]
            tokens.append(
                TokenRecord(
                    range: index..<end,
                    attributes: attributes(for: slice, kind: kind),
                    kind: kind
                )
            )
            index = end
        }
        return tokens
    }

    private func wordKind(_ character: Character) -> TokenKind {
        if character.isWhitespace { return .whitespace }
        if character.isLetter || character.isNumber { return .word }
        if character.isPunctuation || character.isSymbol { return .punctuation }
        return .other
    }

    private func attributes(
        for slice: Substring,
        kind: TokenKind
    ) -> Attributes {
        var result: Attributes = []
        if !slice.isEmpty, slice.allSatisfy(\.isNumber) {
            result.insert(.numeric)
        }
        if kind == .punctuation {
            result.insert(.symbolic)
        }
        if slice.unicodeScalars.contains(where: { $0.properties.isEmojiPresentation }) {
            result.insert(.emoji)
        }
        return result
    }

    private func sentenceTokens(
        in string: String,
        range: Range<String.Index>
    ) -> [TokenRecord] {
        var tokens: [TokenRecord] = []
        var start = range.lowerBound
        var index = range.lowerBound
        while index < range.upperBound {
            let character = string[index]
            let next = string.index(after: index)
            let isTerminator = ".!?。！？".contains(character)
            let isNewline = character.isNewline
            if isTerminator || isNewline || next == range.upperBound {
                var end = isTerminator || isNewline ? next : next
                if isTerminator, end < range.upperBound, string[end].isWhitespace,
                   !string[end].isNewline
                {
                    end = string.index(after: end)
                }
                if start < end {
                    tokens.append(
                        TokenRecord(range: start..<end, attributes: [], kind: .other)
                    )
                }
                start = end
                index = end
                continue
            }
            index = next
        }
        if start < range.upperBound {
            tokens.append(
                TokenRecord(range: start..<range.upperBound, attributes: [], kind: .other)
            )
        }
        return tokens
    }

    private func paragraphTokens(
        in string: String,
        range: Range<String.Index>
    ) -> [TokenRecord] {
        var tokens: [TokenRecord] = []
        var start = range.lowerBound
        var index = range.lowerBound
        while index < range.upperBound {
            if string[index].isNewline {
                if start < index {
                    tokens.append(
                        TokenRecord(range: start..<index, attributes: [], kind: .other)
                    )
                }
                start = string.index(after: index)
                index = start
                continue
            }
            index = string.index(after: index)
        }
        if start < range.upperBound {
            tokens.append(
                TokenRecord(range: start..<range.upperBound, attributes: [], kind: .other)
            )
        }
        return tokens
    }
}
