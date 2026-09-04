import Foundation

public typealias NLDistance = Double

enum NLLinuxSupport {
    static let errorDomain = "org.openuikit.NaturalLanguage.linux"

    static func error(_ message: String, code: Int = 1) -> NSError {
        NSError(
            domain: errorDomain,
            code: code,
            userInfo: [NSLocalizedDescriptionKey: message]
        )
    }
}

public struct NLScript: RawRepresentable, Hashable, Sendable, Codable,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }

    public static let undetermined = Self(rawValue: "Zyyy")
    public static let arabic = Self(rawValue: "Arab")
    public static let armenian = Self(rawValue: "Armn")
    public static let bengali = Self(rawValue: "Beng")
    public static let canadianAboriginalSyllabics = Self(rawValue: "Cans")
    public static let cherokee = Self(rawValue: "Cher")
    public static let cyrillic = Self(rawValue: "Cyrl")
    public static let devanagari = Self(rawValue: "Deva")
    public static let ethiopic = Self(rawValue: "Ethi")
    public static let georgian = Self(rawValue: "Geor")
    public static let greek = Self(rawValue: "Grek")
    public static let gujarati = Self(rawValue: "Gujr")
    public static let gurmukhi = Self(rawValue: "Guru")
    public static let hebrew = Self(rawValue: "Hebr")
    public static let japanese = Self(rawValue: "Jpan")
    public static let kannada = Self(rawValue: "Knda")
    public static let khmer = Self(rawValue: "Khmr")
    public static let korean = Self(rawValue: "Kore")
    public static let lao = Self(rawValue: "Laoo")
    public static let latin = Self(rawValue: "Latn")
    public static let malayalam = Self(rawValue: "Mlym")
    public static let mongolian = Self(rawValue: "Mong")
    public static let myanmar = Self(rawValue: "Mymr")
    public static let oriya = Self(rawValue: "Orya")
    public static let simplifiedChinese = Self(rawValue: "Hans")
    public static let sinhala = Self(rawValue: "Sinh")
    public static let tamil = Self(rawValue: "Taml")
    public static let telugu = Self(rawValue: "Telu")
    public static let thai = Self(rawValue: "Thai")
    public static let tibetan = Self(rawValue: "Tibt")
    public static let traditionalChinese = Self(rawValue: "Hant")

    static func inferred(from text: String) -> NLScript {
        var counts: [NLScript: Int] = [:]
        var hasKana = false
        var hasHan = false
        var hasTraditionalHan = false
        for scalar in text.unicodeScalars {
            let value = scalar.value
            switch value {
            case 0x0041...0x007A, 0x00C0...0x024F, 0x1E00...0x1EFF:
                counts[.latin, default: 0] += 1
            case 0x3040...0x30FF:
                hasKana = true
            case 0x3400...0x9FFF, 0xF900...0xFAFF:
                hasHan = true
                if "體國學會來這個們說與時為開關廣東臺灣".unicodeScalars.contains(scalar) {
                    hasTraditionalHan = true
                }
            case 0xAC00...0xD7AF:
                counts[.korean, default: 0] += 1
            case 0x0400...0x052F:
                counts[.cyrillic, default: 0] += 1
            case 0x0370...0x03FF:
                counts[.greek, default: 0] += 1
            case 0x0590...0x05FF:
                counts[.hebrew, default: 0] += 1
            case 0x0600...0x06FF:
                counts[.arabic, default: 0] += 1
            case 0x0900...0x097F:
                counts[.devanagari, default: 0] += 1
            case 0x0980...0x09FF:
                counts[.bengali, default: 0] += 1
            case 0x0A00...0x0A7F:
                counts[.gurmukhi, default: 0] += 1
            case 0x0A80...0x0AFF:
                counts[.gujarati, default: 0] += 1
            case 0x0B00...0x0B7F:
                counts[.oriya, default: 0] += 1
            case 0x0B80...0x0BFF:
                counts[.tamil, default: 0] += 1
            case 0x0C00...0x0C7F:
                counts[.telugu, default: 0] += 1
            case 0x0C80...0x0CFF:
                counts[.kannada, default: 0] += 1
            case 0x0D00...0x0D7F:
                counts[.malayalam, default: 0] += 1
            case 0x0D80...0x0DFF:
                counts[.sinhala, default: 0] += 1
            case 0x0E00...0x0E7F:
                counts[.thai, default: 0] += 1
            case 0x0E80...0x0EFF:
                counts[.lao, default: 0] += 1
            case 0x0F00...0x0FFF:
                counts[.tibetan, default: 0] += 1
            case 0x1000...0x109F:
                counts[.myanmar, default: 0] += 1
            case 0x10A0...0x10FF:
                counts[.georgian, default: 0] += 1
            case 0x0530...0x058F:
                counts[.armenian, default: 0] += 1
            case 0x1200...0x137F:
                counts[.ethiopic, default: 0] += 1
            case 0x1780...0x17FF:
                counts[.khmer, default: 0] += 1
            case 0x13A0...0x13FF:
                counts[.cherokee, default: 0] += 1
            case 0x1400...0x167F:
                counts[.canadianAboriginalSyllabics, default: 0] += 1
            case 0x1800...0x18AF:
                counts[.mongolian, default: 0] += 1
            default:
                break
            }
        }
        if hasKana { return .japanese }
        if hasHan {
            return hasTraditionalHan ? .traditionalChinese : .simplifiedChinese
        }
        return counts.max {
            $0.value == $1.value
                ? $0.key.rawValue > $1.key.rawValue : $0.value < $1.value
        }?.key ?? .undetermined
    }
}

public struct NLTag: RawRepresentable, Hashable, Sendable, Codable,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }

    public static let word = Self(rawValue: "Word")
    public static let punctuation = Self(rawValue: "Punctuation")
    public static let whitespace = Self(rawValue: "Whitespace")
    public static let other = Self(rawValue: "Other")
    public static let noun = Self(rawValue: "Noun")
    public static let verb = Self(rawValue: "Verb")
    public static let adjective = Self(rawValue: "Adjective")
    public static let adverb = Self(rawValue: "Adverb")
    public static let pronoun = Self(rawValue: "Pronoun")
    public static let determiner = Self(rawValue: "Determiner")
    public static let particle = Self(rawValue: "Particle")
    public static let preposition = Self(rawValue: "Preposition")
    public static let number = Self(rawValue: "Number")
    public static let conjunction = Self(rawValue: "Conjunction")
    public static let interjection = Self(rawValue: "Interjection")
    public static let classifier = Self(rawValue: "Classifier")
    public static let idiom = Self(rawValue: "Idiom")
    public static let otherWord = Self(rawValue: "OtherWord")
    public static let sentenceTerminator = Self(rawValue: "SentenceTerminator")
    public static let openQuote = Self(rawValue: "OpenQuote")
    public static let closeQuote = Self(rawValue: "CloseQuote")
    public static let openParenthesis = Self(rawValue: "OpenParenthesis")
    public static let closeParenthesis = Self(rawValue: "CloseParenthesis")
    public static let wordJoiner = Self(rawValue: "WordJoiner")
    public static let dash = Self(rawValue: "Dash")
    public static let otherPunctuation = Self(rawValue: "OtherPunctuation")
    public static let paragraphBreak = Self(rawValue: "ParagraphBreak")
    public static let otherWhitespace = Self(rawValue: "OtherWhitespace")
    public static let personalName = Self(rawValue: "PersonalName")
    public static let placeName = Self(rawValue: "PlaceName")
    public static let organizationName = Self(rawValue: "OrganizationName")
}

public struct NLTagScheme: RawRepresentable, Hashable, Sendable, Codable,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }

    public static let tokenType = Self(rawValue: "TokenType")
    public static let lexicalClass = Self(rawValue: "LexicalClass")
    public static let nameType = Self(rawValue: "NameType")
    public static let nameTypeOrLexicalClass = Self(rawValue: "NameTypeOrLexicalClass")
    public static let lemma = Self(rawValue: "Lemma")
    public static let language = Self(rawValue: "Language")
    public static let script = Self(rawValue: "Script")
    public static let sentimentScore = Self(rawValue: "SentimentScore")
}

public struct NLContextualEmbeddingKey: RawRepresentable, Hashable, Sendable,
    Codable, CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }

    public static let languages = Self(rawValue: "NLContextualEmbeddingKeyLanguages")
    public static let scripts = Self(rawValue: "NLContextualEmbeddingKeyScripts")
    public static let revision = Self(rawValue: "NLContextualEmbeddingKeyRevision")
}

public enum NLTokenUnit: Int, Sendable, Hashable {
    case word = 0
    case sentence = 1
    case paragraph = 2
    case document = 3
}

public enum NLDistanceType: Int, Sendable, Hashable {
    case cosine = 0
}
