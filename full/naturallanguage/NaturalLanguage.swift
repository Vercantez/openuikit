//===----------------------------------------------------------------------===//
// Portable NaturalLanguage language identification
//
// This is a local, deterministic language recognizer for platforms where
// Apple's private NaturalLanguage models are unavailable. It combines Unicode
// script identification with a compact character-trigram/marker-word model for
// Latin-script languages. The recognizer keeps the public incremental, hint,
// constraint, and hypothesis semantics used by applications; it does not claim
// to expose Apple's private model or token/tag/embedding services.
//===----------------------------------------------------------------------===//

@_exported import Foundation

public struct NLLanguage: RawRepresentable, Hashable, Sendable, Codable,
    CustomStringConvertible
{
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public var description: String { rawValue }

    public static let undetermined = Self(rawValue: "und")
    public static let amharic = Self(rawValue: "am")
    public static let arabic = Self(rawValue: "ar")
    public static let armenian = Self(rawValue: "hy")
    public static let bengali = Self(rawValue: "bn")
    public static let bulgarian = Self(rawValue: "bg")
    public static let burmese = Self(rawValue: "my")
    public static let catalan = Self(rawValue: "ca")
    public static let cherokee = Self(rawValue: "chr")
    public static let croatian = Self(rawValue: "hr")
    public static let czech = Self(rawValue: "cs")
    public static let danish = Self(rawValue: "da")
    public static let dutch = Self(rawValue: "nl")
    public static let english = Self(rawValue: "en")
    public static let finnish = Self(rawValue: "fi")
    public static let french = Self(rawValue: "fr")
    public static let georgian = Self(rawValue: "ka")
    public static let german = Self(rawValue: "de")
    public static let greek = Self(rawValue: "el")
    public static let gujarati = Self(rawValue: "gu")
    public static let hebrew = Self(rawValue: "he")
    public static let hindi = Self(rawValue: "hi")
    public static let hungarian = Self(rawValue: "hu")
    public static let icelandic = Self(rawValue: "is")
    public static let indonesian = Self(rawValue: "id")
    public static let italian = Self(rawValue: "it")
    public static let japanese = Self(rawValue: "ja")
    public static let kannada = Self(rawValue: "kn")
    public static let khmer = Self(rawValue: "km")
    public static let korean = Self(rawValue: "ko")
    public static let lao = Self(rawValue: "lo")
    public static let malay = Self(rawValue: "ms")
    public static let malayalam = Self(rawValue: "ml")
    public static let marathi = Self(rawValue: "mr")
    public static let mongolian = Self(rawValue: "mn")
    public static let norwegian = Self(rawValue: "nb")
    public static let oriya = Self(rawValue: "or")
    public static let persian = Self(rawValue: "fa")
    public static let polish = Self(rawValue: "pl")
    public static let portuguese = Self(rawValue: "pt")
    public static let punjabi = Self(rawValue: "pa")
    public static let romanian = Self(rawValue: "ro")
    public static let russian = Self(rawValue: "ru")
    public static let simplifiedChinese = Self(rawValue: "zh-Hans")
    public static let sinhalese = Self(rawValue: "si")
    public static let slovak = Self(rawValue: "sk")
    public static let spanish = Self(rawValue: "es")
    public static let swedish = Self(rawValue: "sv")
    public static let tamil = Self(rawValue: "ta")
    public static let telugu = Self(rawValue: "te")
    public static let thai = Self(rawValue: "th")
    public static let tibetan = Self(rawValue: "bo")
    public static let traditionalChinese = Self(rawValue: "zh-Hant")
    public static let turkish = Self(rawValue: "tr")
    public static let ukrainian = Self(rawValue: "uk")
    public static let urdu = Self(rawValue: "ur")
    public static let vietnamese = Self(rawValue: "vi")
    public static let kazakh = Self(rawValue: "kk")
}

public final class NLLanguageRecognizer: NSObject {
    public var languageHints: [NLLanguage: Double] = [:]
    public var languageConstraints: [NLLanguage] = []

    private var processedText = ""

    public override init() {
        super.init()
    }

    public class func dominantLanguage(for string: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        return recognizer.dominantLanguage
    }

    public func processString(_ string: String) {
        if !processedText.isEmpty, !string.isEmpty {
            processedText.append(" ")
        }
        processedText.append(string)
    }

    public func reset() {
        processedText.removeAll(keepingCapacity: true)
    }

    public var dominantLanguage: NLLanguage? {
        rankedHypotheses().first?.language
    }

    public func languageHypotheses(
        withMaximum maxHypotheses: Int
    ) -> [NLLanguage: Double] {
        guard maxHypotheses > 0 else { return [:] }
        let ranked = rankedHypotheses()
        guard !ranked.isEmpty else { return [:] }
        return Dictionary(
            uniqueKeysWithValues: ranked.prefix(maxHypotheses).map {
                ($0.language, $0.probability)
            }
        )
    }

    private struct Hypothesis {
        let language: NLLanguage
        let score: Double
        var probability: Double
    }

    private struct Profile {
        let language: NLLanguage
        let markers: Set<String>
        let trigrams: [String: Int]

        init(_ language: NLLanguage, markers: String, training: String) {
            self.language = language
            self.markers = Set(markers.split(separator: " ").map(String.init))
            trigrams = NLLanguageRecognizer.trigramCounts(
                NLLanguageRecognizer.words(in: training)
            )
        }
    }

    private func rankedHypotheses() -> [Hypothesis] {
        let inputWords = Self.words(in: processedText)
        let letters = inputWords.reduce(0) { $0 + $1.unicodeScalars.count }
        guard letters >= 2 else { return [] }

        let allowed = languageConstraints.isEmpty
            ? nil : Set(languageConstraints)
        if let script = Self.scriptLanguage(in: processedText),
           allowed == nil || allowed!.contains(script)
        {
            let confidence = letters < 4 ? 0.60 : min(0.99, 0.90 + Double(letters) / 500.0)
            return [Hypothesis(language: script, score: 1, probability: confidence)]
        }

        let inputTrigrams = Self.trigramCounts(inputWords)
        var hypotheses: [Hypothesis] = []
        for profile in Self.latinProfiles {
            if let allowed, !allowed.contains(profile.language) { continue }
            let cosine = Self.cosine(inputTrigrams, profile.trigrams)
            let markerHits = inputWords.reduce(into: 0) { count, word in
                if profile.markers.contains(word) { count += 1 }
            }
            var score = cosine + min(0.50, Double(markerHits) * 0.085)
            if let hint = languageHints[profile.language], hint > 0 {
                score += min(0.35, hint * 0.35)
            }
            if score > 0 {
                hypotheses.append(
                    Hypothesis(language: profile.language, score: score, probability: 0)
                )
            }
        }
        hypotheses.sort {
            $0.score == $1.score
                ? $0.language.rawValue < $1.language.rawValue
                : $0.score > $1.score
        }
        guard let best = hypotheses.first else { return [] }
        let runnerUp = hypotheses.dropFirst().first?.score ?? 0
        let margin = max(0, best.score - runnerUp)
        let lengthEvidence = min(0.16, Double(max(0, letters - 12)) / 260.0)
        let confidence: Double
        if letters < 5 {
            confidence = min(0.60, 0.32 + best.score * 0.25)
        } else {
            confidence = min(
                0.99,
                0.56 + best.score * 0.24 + margin * 1.45 + lengthEvidence
            )
        }

        hypotheses[0].probability = confidence
        guard hypotheses.count > 1 else { return hypotheses }
        let remainder = max(0, 1 - confidence)
        let otherTotal = hypotheses.dropFirst().reduce(0) { $0 + $1.score }
        for index in hypotheses.indices.dropFirst() {
            hypotheses[index].probability = otherTotal > 0
                ? remainder * hypotheses[index].score / otherTotal : 0
        }
        return hypotheses
    }

    private static func words(in text: String) -> [String] {
        var result: [String] = []
        var current = ""
        for scalar in text.lowercased().unicodeScalars {
            if scalar.properties.isAlphabetic {
                current.unicodeScalars.append(scalar)
            } else if !current.isEmpty {
                result.append(current)
                current.removeAll(keepingCapacity: true)
            }
        }
        if !current.isEmpty { result.append(current) }
        return result
    }

    private static func trigramCounts(_ words: [String]) -> [String: Int] {
        var result: [String: Int] = [:]
        for word in words where !word.isEmpty {
            let scalars = Array(("^" + word + "$").unicodeScalars)
            guard scalars.count >= 3 else { continue }
            for index in 0...(scalars.count - 3) {
                let gram = String(String.UnicodeScalarView(scalars[index...(index + 2)]))
                result[gram, default: 0] += 1
            }
        }
        return result
    }

    private static func cosine(
        _ lhs: [String: Int], _ rhs: [String: Int]
    ) -> Double {
        guard !lhs.isEmpty, !rhs.isEmpty else { return 0 }
        var dot = 0.0
        var lhsMagnitude = 0.0
        var rhsMagnitude = 0.0
        for (gram, count) in lhs {
            let value = Double(count)
            lhsMagnitude += value * value
            dot += value * Double(rhs[gram] ?? 0)
        }
        for count in rhs.values {
            let value = Double(count)
            rhsMagnitude += value * value
        }
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 0 }
        return dot / (lhsMagnitude.squareRoot() * rhsMagnitude.squareRoot())
    }

    private static func scriptLanguage(in text: String) -> NLLanguage? {
        var counts: [NLLanguage: Int] = [:]
        var hasKana = false
        var hasHan = false
        var hasTraditionalHan = false
        var hasUkrainian = false
        var hasPersian = false
        var hasUrdu = false
        for scalar in text.unicodeScalars {
            let value = scalar.value
            switch value {
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
                counts[.russian, default: 0] += 1
                if "іїєґІЇЄҐ".unicodeScalars.contains(scalar) { hasUkrainian = true }
            case 0x0370...0x03FF:
                counts[.greek, default: 0] += 1
            case 0x0590...0x05FF:
                counts[.hebrew, default: 0] += 1
            case 0x0600...0x06FF:
                counts[.arabic, default: 0] += 1
                if "پچژگک".unicodeScalars.contains(scalar) { hasPersian = true }
                if "ٹڈڑںھۓ".unicodeScalars.contains(scalar) { hasUrdu = true }
            case 0x0900...0x097F:
                counts[.hindi, default: 0] += 1
            case 0x0980...0x09FF:
                counts[.bengali, default: 0] += 1
            case 0x0A00...0x0A7F:
                counts[.punjabi, default: 0] += 1
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
                counts[.sinhalese, default: 0] += 1
            case 0x0E00...0x0E7F:
                counts[.thai, default: 0] += 1
            case 0x0E80...0x0EFF:
                counts[.lao, default: 0] += 1
            case 0x0F00...0x0FFF:
                counts[.tibetan, default: 0] += 1
            case 0x1000...0x109F:
                counts[.burmese, default: 0] += 1
            case 0x10A0...0x10FF:
                counts[.georgian, default: 0] += 1
            case 0x0530...0x058F:
                counts[.armenian, default: 0] += 1
            case 0x1200...0x137F:
                counts[.amharic, default: 0] += 1
            case 0x1780...0x17FF:
                counts[.khmer, default: 0] += 1
            case 0x13A0...0x13FF:
                counts[.cherokee, default: 0] += 1
            default:
                break
            }
        }
        if hasKana { return .japanese }
        if hasHan {
            return hasTraditionalHan ? .traditionalChinese : .simplifiedChinese
        }
        if hasUkrainian { return .ukrainian }
        if hasUrdu { return .urdu }
        if hasPersian { return .persian }
        return counts.max {
            $0.value == $1.value
                ? $0.key.rawValue > $1.key.rawValue : $0.value < $1.value
        }?.key
    }

    private static let latinProfiles: [Profile] = [
        Profile(
            .english,
            markers: "the and this that with for from are is was were have has thank sharing wonderful everyone together better about into your you we our open social network community",
            training: "The people in our open community are working together to build a better social network. Thank you for sharing this thoughtful update with everyone today."
        ),
        Profile(
            .french,
            markers: "le la les un une des et est sont je tu nous vous avec pour dans que qui bonjour monde très heureux aujourd hui retrouver communauté ouverte ensemble",
            training: "Bonjour à toutes et à tous. Nous construisons ensemble une communauté ouverte, accueillante et respectueuse pour partager les nouvelles du monde."
        ),
        Profile(
            .spanish,
            markers: "el la los las un una y es son estoy estamos con para por que quien hola todos comunidad abierta amable juntos construyendo gracias compartir",
            training: "Hola a todas y todos. Estamos construyendo juntos una comunidad abierta y amable para compartir noticias y conversar con respeto."
        ),
        Profile(
            .german,
            markers: "der die das ein eine und ist sind ich wir ihr mit für von zu dass guten morgen gemeinsam einer besseren offene gemeinschaft arbeiten heute",
            training: "Guten Morgen. Wir arbeiten heute gemeinsam an einer besseren offenen Gemeinschaft, in der die Menschen freundlich miteinander sprechen."
        ),
        Profile(
            .italian,
            markers: "il lo la gli le un una e è sono io noi voi con per che buongiorno tutti stiamo costruendo insieme comunità aperta gentile grazie",
            training: "Buongiorno a tutte e tutti. Stiamo costruendo insieme una comunità aperta e gentile per condividere notizie e conversazioni."
        ),
        Profile(
            .portuguese,
            markers: "o a os as um uma e é são eu nós vocês com para que olá todos estamos construindo juntos comunidade aberta acolhedora obrigado compartilhar",
            training: "Olá a todas e todos. Estamos construindo juntos uma comunidade aberta e acolhedora para compartilhar notícias e conversar com respeito."
        ),
        Profile(
            .dutch,
            markers: "de het een en is zijn ik wij met voor van dat deze samen gemeenschap open vriendelijk vandaag bedankt",
            training: "Wij bouwen samen aan een open en vriendelijke gemeenschap waar mensen nieuws delen en met elkaar praten."
        ),
        Profile(
            .catalan,
            markers: "el la els les un una i és som amb per que hola tots comunitat oberta junts gràcies compartir",
            training: "Hola a tothom. Estem construint junts una comunitat oberta i amable per compartir notícies i conversar."
        ),
        Profile(
            .swedish,
            markers: "den det en ett och är jag vi med för från att tillsammans öppen gemenskap vänlig tack idag morgon tar tåget staden träffa våra vänner",
            training: "Vi bygger tillsammans en öppen och vänlig gemenskap där människor delar nyheter och pratar med varandra. I morgon tar vi tåget till staden för att träffa våra vänner."
        ),
        Profile(
            .danish,
            markers: "den det en et og er jeg vi med for fra at sammen åbent fællesskab venlig tak i dag morgen tager toget byen besøge vores venner",
            training: "Vi bygger sammen et åbent og venligt fællesskab hvor mennesker deler nyheder og taler med hinanden. I morgen tager vi toget til byen for at besøge vores venner."
        ),
        Profile(
            .norwegian,
            markers: "den det en et og er jeg vi med for fra at sammen åpent fellesskap vennlig takk dag morgen tar toget byen besøke vennene våre",
            training: "Vi bygger sammen et åpent og vennlig fellesskap der mennesker deler nyheter og snakker med hverandre. I morgen tar vi toget til byen for å besøke vennene våre."
        ),
        Profile(
            .finnish,
            markers: "ja on minä me kanssa varten että yhdessä avoin yhteisö ystävällinen kiitos tänään ihmiset huomenna menemme junalla kaupunkiin tapaamaan ystäviämme",
            training: "Rakennamme yhdessä avointa ja ystävällistä yhteisöä jossa ihmiset jakavat uutisia ja keskustelevat. Huomenna menemme junalla kaupunkiin tapaamaan ystäviämme."
        ),
        Profile(
            .polish,
            markers: "i jest są ja my z dla że razem otwarta społeczność przyjazna dziękuję dzisiaj ludzie jutro pojedziemy pociągiem miasta odwiedzić naszych przyjaciół",
            training: "Razem budujemy otwartą i przyjazną społeczność, w której ludzie dzielą się wiadomościami i rozmawiają. Jutro pojedziemy pociągiem do miasta, aby odwiedzić naszych przyjaciół."
        ),
        Profile(
            .czech,
            markers: "a je jsou já my s pro že společně otevřená komunita přátelská děkuji dnes lidé zítra pojedeme vlakem města navštívit naše přátele",
            training: "Společně budujeme otevřenou a přátelskou komunitu kde lidé sdílejí zprávy a mluví spolu. Zítra pojedeme vlakem do města navštívit naše přátele."
        ),
        Profile(
            .croatian,
            markers: "i je su ja mi s za da zajedno otvorena zajednica prijateljska hvala danas ljudi sutra ćemo vlakom otići grad posjetiti naše prijatelje",
            training: "Zajedno gradimo otvorenu i prijateljsku zajednicu u kojoj ljudi dijele vijesti i razgovaraju. Sutra ćemo vlakom otići u grad posjetiti naše prijatelje."
        ),
        Profile(
            .romanian,
            markers: "și este sunt eu noi cu pentru că împreună deschisă comunitate prietenoasă mulțumesc astăzi oameni",
            training: "Construim împreună o comunitate deschisă și prietenoasă unde oamenii împărtășesc știri și discută."
        ),
        Profile(
            .turkish,
            markers: "ve bir bu için ile biz birlikte açık topluluk dostça teşekkür bugün insanlar haber",
            training: "İnsanların haber paylaştığı ve konuştuğu açık ve dostça bir topluluğu birlikte kuruyoruz."
        ),
        Profile(
            .indonesian,
            markers: "dan yang ini untuk dengan kami kita bersama komunitas terbuka ramah terima kasih hari orang berita",
            training: "Kita membangun komunitas yang terbuka dan ramah bersama, tempat orang berbagi berita dan berbicara."
        ),
        Profile(
            .vietnamese,
            markers: "và là một chúng tôi với cho cùng cộng đồng mở thân thiện cảm ơn hôm nay mọi người tin tức",
            training: "Chúng tôi cùng xây dựng một cộng đồng cởi mở và thân thiện nơi mọi người chia sẻ tin tức và trò chuyện."
        ),
    ]
}
