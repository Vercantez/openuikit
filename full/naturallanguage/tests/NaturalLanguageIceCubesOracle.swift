import Foundation
import NaturalLanguage

@main
struct NaturalLanguageIceCubesOracle {
    private static let samples: [(String, String)] = [
        (
            "english",
            "This is a thoughtful message about building a better social network together."
        ),
        (
            "french",
            "Bonjour tout le monde, je suis très heureux de vous retrouver aujourd'hui."
        ),
        (
            "spanish",
            "Hola a todos, estamos construyendo una comunidad abierta y amable."
        ),
        (
            "german",
            "Guten Morgen, wir arbeiten gemeinsam an einer besseren offenen Gemeinschaft."
        ),
        (
            "italian",
            "Buongiorno a tutti, stiamo costruendo insieme una comunità aperta e gentile."
        ),
        (
            "portuguese",
            "Olá a todos, estamos construindo juntos uma comunidade aberta e acolhedora."
        ),
        (
            "japanese",
            "今日はみんなで、より良いオープンなコミュニティを一緒に作っています。"
        ),
        (
            "chinese",
            "大家好，我们正在一起建设一个更加开放友好的社区。"
        ),
        (
            "russian",
            "Доброе утро, мы вместе создаём открытое и дружелюбное сообщество."
        ),
        (
            "decorated-english",
            "@friend #Swift :wave: Thank you for sharing this wonderful update with everyone."
        ),
        ("short", "ok"),
        ("symbols", "#Swift @friend :wave:")
    ]

    static func main() {
        for (label, text) in samples {
            print("\(label)=\(detectLanguage(text: text) ?? "nil")")
        }

        print(
            "direct=\(NLLanguageRecognizer.dominantLanguage(for: samples[0].1)?.rawValue ?? "nil")"
        )

        let incremental = NLLanguageRecognizer()
        incremental.processString("This community is open")
        incremental.processString("and everyone is welcome here today.")
        print("incremental=\(incremental.dominantLanguage?.rawValue ?? "nil")")
        incremental.reset()
        incremental.processString(samples[1].1)
        print("reset=\(incremental.dominantLanguage?.rawValue ?? "nil")")

        let constrained = NLLanguageRecognizer()
        constrained.languageConstraints = [.french, .spanish]
        constrained.processString(samples[2].1)
        print("constrained=\(constrained.dominantLanguage?.rawValue ?? "nil")")

        let hinted = NLLanguageRecognizer()
        hinted.languageHints = [.english: 0.99, .french: 0.01]
        hinted.processString("hello bonjour")
        print("hinted=\(hinted.dominantLanguage?.rawValue ?? "nil")")
    }
}
