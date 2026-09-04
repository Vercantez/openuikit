import Foundation

public final class NLTagger: NSObject {
    public enum AssetsResult: Int, Sendable, Hashable {
        case available = 0
        case notAvailable = 1
        case error = 2
    }

    public struct Options: OptionSet, Sendable, Hashable {
        public let rawValue: UInt

        public init(rawValue: UInt) {
            self.rawValue = rawValue
        }

        public static let omitWords = Options(rawValue: 1 << 0)
        public static let omitPunctuation = Options(rawValue: 1 << 1)
        public static let omitWhitespace = Options(rawValue: 1 << 2)
        public static let omitOther = Options(rawValue: 1 << 3)
        public static let joinNames = Options(rawValue: 1 << 4)
        public static let joinContractions = Options(rawValue: 1 << 5)
    }

    public let tagSchemes: [NLTagScheme]
    public var string: String?
    private var languageOverrides: [(range: Range<String.Index>, language: NLLanguage)] = []
    private var modelsByScheme: [NLTagScheme: [NLModel]] = [:]
    private var gazetteersByScheme: [NLTagScheme: [NLGazetteer]] = [:]

    public init(tagSchemes: [NLTagScheme]) {
        self.tagSchemes = tagSchemes
        super.init()
    }

    public var dominantLanguage: NLLanguage? {
        guard let string, !string.isEmpty else { return nil }
        return NLLanguageRecognizer.dominantLanguage(for: string)
    }

    public class func availableTagSchemes(
        for unit: NLTokenUnit,
        language: NLLanguage
    ) -> [NLTagScheme] {
        _ = unit
        _ = language
        return [.tokenType, .language, .script]
    }

    public class func requestAssets(
        for language: NLLanguage,
        tagScheme: NLTagScheme
    ) async throws -> NLTagger.AssetsResult {
        _ = language
        switch tagScheme {
        case .tokenType, .language, .script:
            return .available
        default:
            return .notAvailable
        }
    }

    public func gazetteers(for tagScheme: NLTagScheme) -> [NLGazetteer] {
        gazetteersByScheme[tagScheme] ?? []
    }

    public func setGazetteers(_ gazetteers: [NLGazetteer], for tagScheme: NLTagScheme) {
        gazetteersByScheme[tagScheme] = gazetteers
    }

    public func models(forTagScheme tagScheme: NLTagScheme) -> [NLModel] {
        modelsByScheme[tagScheme] ?? []
    }

    public func setModels(_ models: [NLModel], forTagScheme tagScheme: NLTagScheme) {
        modelsByScheme[tagScheme] = models
    }

    public func setLanguage(_ language: NLLanguage, range: Range<String.Index>) {
        languageOverrides.removeAll { $0.range == range }
        languageOverrides.append((range, language))
    }

    public func tokenRange(at index: String.Index, unit: NLTokenUnit) -> Range<String.Index> {
        tokenizer(unit).tokenRange(at: index)
    }

    public func tokenRange(
        for range: Range<String.Index>,
        unit: NLTokenUnit
    ) -> Range<String.Index> {
        tokenizer(unit).tokenRange(for: range)
    }

    public func tag(
        at index: String.Index,
        unit: NLTokenUnit,
        scheme: NLTagScheme
    ) -> (NLTag?, Range<String.Index>) {
        let range = tokenRange(at: index, unit: unit)
        return (tagValue(for: range, scheme: scheme), range)
    }

    public func tags(
        in range: Range<String.Index>,
        unit: NLTokenUnit,
        scheme: NLTagScheme,
        options: NLTagger.Options = []
    ) -> [(NLTag?, Range<String.Index>)] {
        var result: [(NLTag?, Range<String.Index>)] = []
        enumerateTags(in: range, unit: unit, scheme: scheme, options: options) {
            tag, tokenRange in
            result.append((tag, tokenRange))
            return true
        }
        return result
    }

    public func enumerateTags(
        in range: Range<String.Index>,
        unit: NLTokenUnit,
        scheme: NLTagScheme,
        options: NLTagger.Options = [],
        using block: (NLTag?, Range<String.Index>) -> Bool
    ) {
        let tokenizer = tokenizer(unit)
        tokenizer.enumerateTokens(in: range) { tokenRange, _ in
            let value = tagValue(for: tokenRange, scheme: scheme)
            if shouldOmit(value, options: options) {
                return true
            }
            return block(value, tokenRange)
        }
    }

    public func tagHypotheses(
        at index: String.Index,
        unit: NLTokenUnit,
        scheme: NLTagScheme,
        maximumCount: Int
    ) -> ([String: Double], Range<String.Index>) {
        let range = tokenRange(at: index, unit: unit)
        guard let string, maximumCount > 0 else { return ([:], range) }
        switch scheme {
        case .language:
            let recognizer = NLLanguageRecognizer()
            recognizer.processString(String(string[range]))
            let hypotheses = recognizer.languageHypotheses(withMaximum: maximumCount)
            let mapped = Dictionary(
                uniqueKeysWithValues: hypotheses.map { ($0.key.rawValue, $0.value) }
            )
            return (mapped, range)
        default:
            if let tag = tagValue(for: range, scheme: scheme) {
                return ([tag.rawValue: 1], range)
            }
            return ([:], range)
        }
    }

    private func tokenizer(_ unit: NLTokenUnit) -> NLTokenizer {
        let tokenizer = NLTokenizer(unit: unit)
        tokenizer.string = string
        return tokenizer
    }

    private func tagValue(for range: Range<String.Index>, scheme: NLTagScheme) -> NLTag? {
        guard let string, range.lowerBound < range.upperBound else { return nil }
        let token = String(string[range])
        if let gazetteerTag = gazetteerTag(for: token, scheme: scheme) {
            return gazetteerTag
        }
        switch scheme {
        case .tokenType:
            return tokenType(for: token)
        case .language:
            if let override = languageOverrides.last(where: {
                $0.range.lowerBound <= range.lowerBound
                    && range.upperBound <= $0.range.upperBound
            }) {
                return NLTag(rawValue: override.language.rawValue)
            }
            guard let language = NLLanguageRecognizer.dominantLanguage(for: token) else {
                return NLTag(rawValue: NLLanguage.undetermined.rawValue)
            }
            return NLTag(rawValue: language.rawValue)
        case .script:
            return NLTag(rawValue: NLScript.inferred(from: token).rawValue)
        default:
            return nil
        }
    }

    private func gazetteerTag(for token: String, scheme: NLTagScheme) -> NLTag? {
        for gazetteer in gazetteers(for: scheme) {
            if let label = gazetteer.label(for: token) {
                return NLTag(rawValue: label)
            }
        }
        return nil
    }

    private func tokenType(for token: String) -> NLTag {
        if token.isEmpty { return .other }
        if token.allSatisfy(\.isNewline) { return .paragraphBreak }
        if token.allSatisfy(\.isWhitespace) {
            return token.contains(where: \.isNewline) ? .otherWhitespace : .whitespace
        }
        if token.allSatisfy(\.isNumber) { return .number }
        if token.allSatisfy({ $0.isLetter || $0.isNumber }) { return .word }
        if token == "(" || token == "[" || token == "{" { return .openParenthesis }
        if token == ")" || token == "]" || token == "}" { return .closeParenthesis }
        if token == "\"" || token == "“" || token == "‘" { return .openQuote }
        if token == "”" || token == "’" { return .closeQuote }
        if token == "-" || token == "—" || token == "–" { return .dash }
        if ".!?。！？".contains(where: { token.contains($0) }) {
            return token.allSatisfy({ ".!?。！？".contains($0) })
                ? .sentenceTerminator : .otherPunctuation
        }
        if token.allSatisfy({ $0.isPunctuation || $0.isSymbol }) {
            return .otherPunctuation
        }
        return .other
    }

    private func shouldOmit(_ tag: NLTag?, options: Options) -> Bool {
        guard let tag else {
            return options.contains(.omitOther)
        }
        if options.contains(.omitWords), tag == .word || tag == .number || tag == .otherWord {
            return true
        }
        if options.contains(.omitPunctuation),
           tag == .punctuation
            || tag == .otherPunctuation
            || tag == .sentenceTerminator
            || tag == .openParenthesis
            || tag == .closeParenthesis
            || tag == .openQuote
            || tag == .closeQuote
            || tag == .dash
            || tag == .wordJoiner
        {
            return true
        }
        if options.contains(.omitWhitespace),
           tag == .whitespace || tag == .otherWhitespace || tag == .paragraphBreak
        {
            return true
        }
        if options.contains(.omitOther), tag == .other {
            return true
        }
        return false
    }
}
