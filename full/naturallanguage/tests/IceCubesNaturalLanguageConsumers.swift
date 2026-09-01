import Foundation
import NaturalLanguage

// Literal StatusKit surface from LanguageDetection.swift
// SHA-256 f5d2ed281604303d5e3323b322c0490d1676134d50b2bb350141d9029f9f96f8
private func stripToPureLanguage(inText: String) -> String {
    let hashtagRegex = try! Regex("#[\\w]*")
    let emojiRegex = try! Regex(":\\w*:")
    let atRegex = try! Regex("@\\w*")
    var resultStr = inText
    for regex in [hashtagRegex, emojiRegex, atRegex] {
        let splitArray = resultStr.split(
            separator: regex,
            omittingEmptySubsequences: true
        )
        resultStr = splitArray.joined() as String
    }
    return resultStr.trimmingCharacters(in: .whitespacesAndNewlines)
}

func detectLanguage(text: String) -> String? {
    let recognizer = NLLanguageRecognizer()
    recognizer.processString(stripToPureLanguage(inText: text))
    let hypotheses = recognizer.languageHypotheses(withMaximum: 1)
    if let (language, confidence) = hypotheses.first, confidence >= 0.85 {
        return language.rawValue
    }
    return nil
}

// Literal WishKit API surface from FeedbackLanguage.swift
// SHA-256 30fe69ffc2d7e02af05fd66efe896d8361a6a8c3704a5af1a0fbe2a5e90f40de
enum IceCubesWishKitFeedbackLanguage {
    private static let minimumTextLength = 10
    private static let minimumConfidence = 0.6

    static func dominantLanguage(of text: String) -> Locale.Language? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.count >= minimumTextLength else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(trimmed)
        guard let language = recognizer.dominantLanguage else { return nil }
        let confidence = recognizer
            .languageHypotheses(withMaximum: 1)[language] ?? 0
        guard confidence >= minimumConfidence else { return nil }
        return Locale.Language(identifier: language.rawValue)
    }
}

@main
private struct IceCubesNaturalLanguageConsumers {
    static func main() {
        precondition(
            detectLanguage(
                text: "It would be great to have dark mode support "
                    + "#feature @icecubes :rocket: in this application."
            ) == "en"
        )
        precondition(
            detectLanguage(
                text: "Es waere grossartig, wenn man den Dunkelmodus "
                    + "aktivieren koennte."
            ) == "de"
        )
        precondition(detectLanguage(text: "Dark Mode") == nil)
        precondition(
            IceCubesWishKitFeedbackLanguage.dominantLanguage(
                of: "It would be great to have dark mode support in the app."
            )?.languageCode?.identifier == "en"
        )
        precondition(
            IceCubesWishKitFeedbackLanguage.dominantLanguage(
                of: "Es wäre großartig, wenn man den Dunkelmodus "
                    + "aktivieren könnte."
            )?.languageCode?.identifier == "de"
        )
        precondition(
            IceCubesWishKitFeedbackLanguage.dominantLanguage(of: "Modus")
                == nil
        )
        print(
            "ICECUBES_NATURALLANGUAGE_CONSUMER_OK "
                + "statuskit=sha-f5d2ed2 wishkit=sha-30fe69f"
        )
    }
}
