import Foundation
import NaturalLanguage

@main
private struct NaturalLanguageHostRuntime {
    private static func top(
        _ text: String
    ) -> (NLLanguage, Double)? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        guard let confidence = recognizer
            .languageHypotheses(withMaximum: 1)[language] else { return nil }
        return (language, confidence)
    }

    private static func require(
        _ text: String,
        language: NLLanguage,
        minimumConfidence: Double
    ) {
        guard let result = top(text) else {
            preconditionFailure("no language for \(text)")
        }
        precondition(result.0 == language)
        precondition(result.1 >= minimumConfidence)
    }

    static func main() {
        let constants: [(NLLanguage, String)] = [
            (.undetermined, "und"), (.amharic, "am"), (.arabic, "ar"),
            (.armenian, "hy"), (.bengali, "bn"), (.bulgarian, "bg"),
            (.burmese, "my"), (.catalan, "ca"), (.cherokee, "chr"),
            (.croatian, "hr"), (.czech, "cs"), (.danish, "da"),
            (.dutch, "nl"), (.english, "en"), (.finnish, "fi"),
            (.french, "fr"), (.georgian, "ka"), (.german, "de"),
            (.greek, "el"), (.gujarati, "gu"), (.hebrew, "he"),
            (.hindi, "hi"), (.hungarian, "hu"), (.icelandic, "is"),
            (.indonesian, "id"), (.italian, "it"), (.japanese, "ja"),
            (.kannada, "kn"), (.khmer, "km"), (.korean, "ko"),
            (.lao, "lo"), (.malay, "ms"), (.malayalam, "ml"),
            (.marathi, "mr"), (.mongolian, "mn-Mong"),
            (.norwegian, "nb"), (.oriya, "or"), (.persian, "fa"),
            (.polish, "pl"), (.portuguese, "pt"), (.punjabi, "pa-Guru"),
            (.romanian, "ro"), (.russian, "ru"),
            (.simplifiedChinese, "zh-Hans"), (.sinhalese, "si"),
            (.slovak, "sk"), (.spanish, "es"), (.swedish, "sv"),
            (.tamil, "ta"), (.telugu, "te"), (.thai, "th"),
            (.tibetan, "bo"), (.traditionalChinese, "zh-Hant"),
            (.turkish, "tr"), (.ukrainian, "uk"), (.urdu, "ur"),
            (.vietnamese, "vi"), (.kazakh, "kk"),
        ]
        precondition(constants.count == 58)
        precondition(constants.allSatisfy { $0.0.rawValue == $0.1 })
        let unknown = NLLanguage("xx-Zzzz")
        precondition(unknown.rawValue == "xx-Zzzz")
        precondition(unknown == NLLanguage(rawValue: "xx-Zzzz"))

        let recognizer = NLLanguageRecognizer()
        precondition(recognizer.dominantLanguage == nil)
        precondition(recognizer.languageHypotheses(withMaximum: 0).isEmpty)
        recognizer.processString("")
        precondition(recognizer.dominantLanguage == nil)

        let english =
            "It would be great to have dark mode support in the application."
        recognizer.processString(english)
        precondition(recognizer.dominantLanguage == .english)
        let englishTop = recognizer.languageHypotheses(withMaximum: 1)
        precondition(englishTop[.english, default: 0] >= 0.85)
        let allEnglish = recognizer.languageHypotheses(withMaximum: 0)
        precondition(allEnglish.count == 22)
        precondition(englishTop.count == 1)
        precondition(englishTop[.english] == allEnglish[.english])

        recognizer.processString("")
        precondition(recognizer.dominantLanguage == .english)
        recognizer.processString("... !!! ???")
        precondition(recognizer.dominantLanguage == nil)
        recognizer.processString(english)
        recognizer.reset()
        precondition(recognizer.dominantLanguage == nil)

        precondition(
            NLLanguageRecognizer.dominantLanguage(for: english) == .english
        )
        require(
            "Es waere grossartig, wenn man den Dunkelmodus in dieser "
                + "Anwendung aktivieren koennte.",
            language: .german,
            minimumConfidence: 0.85
        )
        require(
            "Ce serait formidable de pouvoir activer le mode sombre dans "
                + "cette application.",
            language: .french,
            minimumConfidence: 0.85
        )
        require(
            "Ce serait génial de pouvoir activer le mode sombre dans "
                + "cette application très utile.",
            language: .french,
            minimumConfidence: 0.85
        )
        require(
            "Seria estupendo poder activar el modo oscuro en esta aplicacion.",
            language: .spanish,
            minimumConfidence: 0.85
        )
        require(
            "このアプリケーションでダークモードを有効にできると素晴らしいです。",
            language: .japanese,
            minimumConfidence: 0.9
        )
        require(
            "如果可以在这个应用程序中启用深色模式，那就太好了。",
            language: .simplifiedChinese,
            minimumConfidence: 0.9
        )
        require(
            "如果可以在這個應用程式中啟用深色模式，那就太好了。",
            language: .traditionalChinese,
            minimumConfidence: 0.9
        )
        require(
            "سيكون من الرائع أن نتمكن من تفعيل الوضع الداكن في هذا التطبيق.",
            language: .arabic,
            minimumConfidence: 0.9
        )
        require(
            "Ứng dụng này có thể bật chế độ tối và không làm mất dữ liệu.",
            language: .vietnamese,
            minimumConfidence: 0.85
        )

        let short = top("Dark Mode")
        precondition(short?.0 == .english)
        precondition((short?.1 ?? 1) < 0.6)
        precondition((top("Modus")?.1 ?? 1) < 0.6)
        precondition(top("𒀀𒂗𒆠 𒄑𒉋 𒈗𒆠") == nil)
        precondition(
            (top("qxzv jkjk blorp snth grzzl qqqq")?.1 ?? 1) < 0.6
        )

        let constrained = NLLanguageRecognizer()
        constrained.languageConstraints = [.english, .german]
        constrained.processString(
            "Ce texte est clairement ecrit en francais et contient "
                + "plusieurs mots faciles a reconnaitre."
        )
        let constrainedHypotheses = constrained
            .languageHypotheses(withMaximum: 0)
        precondition(constrainedHypotheses.count == 2)
        precondition(constrainedHypotheses.keys.allSatisfy {
            $0 == .english || $0 == .german
        })

        let unknownConstraint = NLLanguageRecognizer()
        unknownConstraint.languageConstraints = [NLLanguage("xx-Zzzz")]
        unknownConstraint.processString(english)
        precondition(unknownConstraint.dominantLanguage == nil)

        let mixedConstraint = NLLanguageRecognizer()
        mixedConstraint.languageConstraints = [.german, NLLanguage("xx")]
        mixedConstraint.processString(english)
        precondition(mixedConstraint.dominantLanguage == .german)
        precondition(
            mixedConstraint.languageHypotheses(withMaximum: 1)[.german] == 1
        )

        let hinted = NLLanguageRecognizer()
        hinted.languageHints = [.german: 0.99]
        hinted.processString(english)
        precondition(hinted.dominantLanguage == .english)
        let unknownHint = NLLanguageRecognizer()
        unknownHint.languageHints = [NLLanguage("xx-Zzzz"): 1]
        unknownHint.processString(english)
        precondition(unknownHint.dominantLanguage == .english)

        let multilingual =
            "This application should have a useful dark mode. "
                + "Das ist eine deutsche Anwendung mit einem Dunkelmodus."
        let first = top(multilingual)
        for _ in 0..<20 {
            let next = top(multilingual)
            precondition(next?.0 == first?.0)
            precondition(next?.1 == first?.1)
        }

        print(
            "NATURALLANGUAGE_HOST_OK constants=58 raw-tags=extensible "
                + "state=replace,empty-noop,reset max=zero-unbounded "
                + "corpus=en,de,fr,es,ja,zh-Hans,zh-Hant,ar "
                + "confidence=conservative constraints=closed hints=prior"
        )
    }
}
