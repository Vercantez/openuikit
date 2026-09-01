import Foundation
import NaturalLanguage

@main
private struct NaturalLanguageNativeOracle {
    private static func inspect(_ text: String) -> (NLLanguage?, Double) {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else {
            return (nil, 0)
        }
        return (
            language,
            recognizer.languageHypotheses(withMaximum: 1)[language] ?? 0
        )
    }

    static func main() {
        precondition(NLLanguage.undetermined.rawValue == "und")
        precondition(NLLanguage.mongolian.rawValue == "mn-Mong")
        precondition(NLLanguage.punjabi.rawValue == "pa-Guru")
        precondition(NLLanguage.simplifiedChinese.rawValue == "zh-Hans")
        precondition(NLLanguage.traditionalChinese.rawValue == "zh-Hant")
        precondition(NLLanguage("xx-Zzzz").rawValue == "xx-Zzzz")

        precondition(inspect("").0 == nil)
        precondition(inspect("... !!!").0 == nil)
        let short = inspect("Dark Mode")
        precondition(short.0 == .english && short.1 < 0.6)
        let english = inspect(
            "It would be great to have dark mode support in this application."
        )
        precondition(english.0 == .english && english.1 > 0.9)
        let german = inspect(
            "Es waere grossartig, wenn man den Dunkelmodus in dieser "
                + "Anwendung aktivieren koennte."
        )
        precondition(german.0 == .german && german.1 > 0.9)

        let state = NLLanguageRecognizer()
        state.processString("This is a clear English sentence about software.")
        let beforeEmpty = state.languageHypotheses(withMaximum: 1)
        state.processString("")
        precondition(state.languageHypotheses(withMaximum: 1) == beforeEmpty)
        state.processString("... !!!")
        precondition(state.dominantLanguage == nil)
        state.reset()
        precondition(state.languageHypotheses(withMaximum: 0).isEmpty)

        print(
            "NATURALLANGUAGE_APPLE_OK tags=extensible "
                + "empty=nil short=low-confidence clear=en,de "
                + "state=empty-noop,punctuation-clear,reset"
        )
    }
}
