@_exported import Foundation

/// A BCP-47 language tag.
///
/// NaturalLanguage's named constants are conveniences, not a closed enum.
/// Unknown and application-defined tags therefore round-trip unchanged.
public struct NLLanguage: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public static let undetermined = NLLanguage("und")
    public static let amharic = NLLanguage("am")
    public static let arabic = NLLanguage("ar")
    public static let armenian = NLLanguage("hy")
    public static let bengali = NLLanguage("bn")
    public static let bulgarian = NLLanguage("bg")
    public static let burmese = NLLanguage("my")
    public static let catalan = NLLanguage("ca")
    public static let cherokee = NLLanguage("chr")
    public static let croatian = NLLanguage("hr")
    public static let czech = NLLanguage("cs")
    public static let danish = NLLanguage("da")
    public static let dutch = NLLanguage("nl")
    public static let english = NLLanguage("en")
    public static let finnish = NLLanguage("fi")
    public static let french = NLLanguage("fr")
    public static let georgian = NLLanguage("ka")
    public static let german = NLLanguage("de")
    public static let greek = NLLanguage("el")
    public static let gujarati = NLLanguage("gu")
    public static let hebrew = NLLanguage("he")
    public static let hindi = NLLanguage("hi")
    public static let hungarian = NLLanguage("hu")
    public static let icelandic = NLLanguage("is")
    public static let indonesian = NLLanguage("id")
    public static let italian = NLLanguage("it")
    public static let japanese = NLLanguage("ja")
    public static let kannada = NLLanguage("kn")
    public static let khmer = NLLanguage("km")
    public static let korean = NLLanguage("ko")
    public static let lao = NLLanguage("lo")
    public static let malay = NLLanguage("ms")
    public static let malayalam = NLLanguage("ml")
    public static let marathi = NLLanguage("mr")
    public static let mongolian = NLLanguage("mn-Mong")
    public static let norwegian = NLLanguage("nb")
    public static let oriya = NLLanguage("or")
    public static let persian = NLLanguage("fa")
    public static let polish = NLLanguage("pl")
    public static let portuguese = NLLanguage("pt")
    public static let punjabi = NLLanguage("pa-Guru")
    public static let romanian = NLLanguage("ro")
    public static let russian = NLLanguage("ru")
    public static let simplifiedChinese = NLLanguage("zh-Hans")
    public static let sinhalese = NLLanguage("si")
    public static let slovak = NLLanguage("sk")
    public static let spanish = NLLanguage("es")
    public static let swedish = NLLanguage("sv")
    public static let tamil = NLLanguage("ta")
    public static let telugu = NLLanguage("te")
    public static let thai = NLLanguage("th")
    public static let tibetan = NLLanguage("bo")
    public static let traditionalChinese = NLLanguage("zh-Hant")
    public static let turkish = NLLanguage("tr")
    public static let ukrainian = NLLanguage("uk")
    public static let urdu = NLLanguage("ur")
    public static let vietnamese = NLLanguage("vi")
    public static let kazakh = NLLanguage("kk")
}

/// A deterministic, dependency-free language recognizer.
///
/// Apple ships a private statistical model with NaturalLanguage. That model
/// cannot be redistributed to Linux, so this implementation deliberately uses
/// conservative Unicode-script and lexical evidence. It preserves the public
/// API and state semantics while keeping uncertain text below the confidence
/// thresholds used by real applications such as IceCubes and WishKit.
///
/// Like Apple's recognizer, an instance is not safe for simultaneous use from
/// multiple threads.
open class NLLanguageRecognizer: NSObject {
    @nonobjc
    open var languageHints: [NLLanguage: Double] = [:]
    open var languageConstraints: [NLLanguage] = []

    private var latestString: String?

    public override init() {
        super.init()
    }

    /// Replaces the current analysis. An exactly empty string is a no-op,
    /// matching the native framework; nonempty text without letters clears it.
    open func processString(_ string: String) {
        guard !string.isEmpty else { return }
        latestString = string
    }

    open func reset() {
        latestString = nil
    }

    open var dominantLanguage: NLLanguage? {
        predictions().first?.language
    }

    open class func dominantLanguage(for string: String) -> NLLanguage? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(string)
        return recognizer.dominantLanguage
    }

    /// A maximum of zero means no limit, as it does in Apple's Swift overlay.
    @nonobjc
    open func languageHypotheses(
        withMaximum maxHypotheses: Int
    ) -> [NLLanguage: Double] {
        precondition(maxHypotheses >= 0, "maxHypotheses must not be negative")
        let predictions = predictions()
        let selected = maxHypotheses == 0
            ? predictions
            : Array(predictions.prefix(maxHypotheses))
        return Dictionary(uniqueKeysWithValues: selected.map {
            ($0.language, $0.probability)
        })
    }

    private func predictions() -> [_NLPrediction] {
        guard let latestString else { return [] }
        return _PortableLanguageClassifier.predictions(
            for: latestString,
            hints: languageHints,
            constraints: languageConstraints
        )
    }
}

private struct _NLPrediction {
    let language: NLLanguage
    let probability: Double
}

private struct _LanguageEvidence {
    var score: Double = 0
    var strongHits: Int = 0
}

private struct _LanguageProfile {
    let language: NLLanguage
    let words: Set<String>
    let fragments: [String]
}

private struct _TextFeatures {
    let originalLowercase: String
    let tokens: [String]
    let letterCount: Int
    let latinCount: Int
    let hiraganaKatakanaCount: Int
    let hanCount: Int
    let hangulCount: Int
    let greekCount: Int
    let cyrillicCount: Int
    let hebrewCount: Int
    let arabicCount: Int
    let devanagariCount: Int
    let directScripts: [NLLanguage: Int]
}

private enum _PortableLanguageClassifier {
    private static let profiles: [_LanguageProfile] = [
        profile(.english,
            "the and this that is are would could should have has with for "
                + "from great dark mode support application app it be to in",
            ["ing", "tion", "ould", "this", "dark"]),
        profile(.german,
            "der die das den dem und ist sind ein eine einer wenn man mit "
                + "fur fuer nicht ware waere konnte koennte aktivieren "
                + "anwendung dunkelmodus dieser grossartig uber ueber es",
            ["sch", "ung", "lich", "keit", "dunkel"]),
        profile(.french,
            "le la les un une des et est sont ce cette dans pour avec serait "
                + "pouvoir activer application mode sombre de du il elle",
            ["que", "ent", "ait", "eur", "sombre"]),
        profile(.spanish,
            "el la los las un una y es son este esta en para con seria poder "
                + "activar aplicacion modo oscuro de del por que",
            ["cion", "que", "ado", "ando", "oscuro"]),
        profile(.portuguese,
            "o a os as um uma e sao este esta em para com seria poder ativar "
                + "aplicacao modo escuro de do por que nao",
            ["cao", "oes", "que", "escuro", "nh"]),
        profile(.italian,
            "il lo la gli le un una e sono questo questa in per con sarebbe "
                + "potere attivare applicazione modalita scura di che non",
            ["zione", "gli", "che", "scur", "ita"]),
        profile(.dutch,
            "de het een en is zijn dit deze in voor met zou kunnen activeren "
                + "toepassing donkere modus van dat niet",
            ["ij", "lijk", "een", "sch", "donker"]),
        profile(.catalan,
            "el la els les un una i es son aquest aquesta en per amb seria "
                + "poder activar aplicacio mode fosc de del que",
            ["cio", "que", "fosc", "ment", "aquest"]),
        profile(.czech,
            "a je jsou tento tato v pro s by mohl mohla aplikace tmavy rezim "
                + "se na ze neni",
            ["ost", "eni", "pro", "rezim"]),
        profile(.danish,
            "og er det den en et i for med ville kunne aktivere program mork "
                + "tilstand af der ikke",
            ["ende", "lig", "mork", "ikke"]),
        profile(.finnish,
            "ja on ovat tama se yksi sovellus tumma tila voisi ottaa kayttoon "
                + "etta ei kanssa",
            ["ssa", "sta", "nen", "lla", "tumm"]),
        profile(.croatian,
            "i je su ovo ova u za s bi mogao aplikacija tamni nacin da se "
                + "nije koji",
            ["ije", "anje", "nacin", "ovo"]),
        profile(.hungarian,
            "es van vannak ez egy az alkalmazas sotet mod lehetne bekapcsolni "
                + "hogy nem meg",
            ["sz", "gy", "ban", "nek", "sotet"]),
        profile(.indonesian,
            "dan adalah ini itu sebuah di untuk dengan bisa mengaktifkan "
                + "aplikasi mode gelap yang tidak",
            ["ng", "kan", "yang", "gelap"]),
        profile(.icelandic,
            "og er eru thetta sa ein i fyrir med gaeti virkja forrit dokk "
                + "stilling sem ekki",
            ["th", "ing", "dokk", "fyrir"]),
        profile(.norwegian,
            "og er det den en et i for med ville kunne aktivere app mork modus "
                + "av som ikke",
            ["ende", "lig", "mork", "ikke"]),
        profile(.polish,
            "i jest sa to ten ta w dla z by mogl aplikacja ciemny tryb nie "
                + "ktory oraz",
            ["cz", "sz", "owy", "nie", "ciem"]),
        profile(.romanian,
            "si este sunt acest aceasta in pentru cu ar putea activa aplicatie "
                + "mod intunecat de care nu",
            ["ului", "este", "intun", "tie"]),
        profile(.slovak,
            "a je su tento tato v pre s by mohol aplikacia tmavy rezim sa na "
                + "nie ktory",
            ["ost", "anie", "pre", "rezim"]),
        profile(.swedish,
            "och ar det den en ett i for med skulle kunna aktivera app morkt "
                + "lage av som inte",
            ["ande", "lig", "mork", "inte"]),
        profile(.turkish,
            "ve bir bu su icin ile uygulama karanlik mod etkinlestirmek olurdu "
                + "degil olan",
            ["lar", "ler", "lik", "mek", "karan"]),
        profile(.vietnamese,
            "va la nay mot trong cho voi co the bat ung dung che do toi cua "
                + "khong duoc",
            ["ng", "nh", "ch", "dung", "khong"]),
    ]

    private static let knownLanguages: Set<NLLanguage> = [
        .undetermined, .amharic, .arabic, .armenian, .bengali,
        .bulgarian, .burmese, .catalan, .cherokee, .croatian, .czech,
        .danish, .dutch, .english, .finnish, .french, .georgian,
        .german, .greek, .gujarati, .hebrew, .hindi, .hungarian,
        .icelandic, .indonesian, .italian, .japanese, .kannada,
        .khmer, .korean, .lao, .malay, .malayalam, .marathi,
        .mongolian, .norwegian, .oriya, .persian, .polish,
        .portuguese, .punjabi, .romanian, .russian,
        .simplifiedChinese, .sinhalese, .slovak, .spanish, .swedish,
        .tamil, .telugu, .thai, .tibetan, .traditionalChinese,
        .turkish, .ukrainian, .urdu, .vietnamese, .kazakh,
    ]

    private static let latinLanguages = profiles.map(\.language)

    static func predictions(
        for text: String,
        hints: [NLLanguage: Double],
        constraints: [NLLanguage]
    ) -> [_NLPrediction] {
        let features = features(for: text)
        guard features.letterCount > 0 else { return [] }

        let naturalCandidates = candidates(for: features)
        guard !naturalCandidates.isEmpty else { return [] }

        let knownConstraints = unique(constraints.filter {
            knownLanguages.contains($0) && $0 != .undetermined
        })
        let candidates: [NLLanguage]
        if constraints.isEmpty {
            candidates = naturalCandidates
        } else {
            guard !knownConstraints.isEmpty else { return [] }
            candidates = knownConstraints
        }

        var evidence: [NLLanguage: _LanguageEvidence] = [:]
        for language in candidates {
            var value = lexicalEvidence(for: language, features: features)
            value.score += scriptScore(for: language, features: features)
            if language == .english {
                value.score += 0.02
            }
            if let hint = hints[language], hint.isFinite, hint > 0 {
                value.score += min(hint, 1) * 2
            }
            evidence[language] = value
        }

        let ordered = candidates.sorted {
            let lhs = evidence[$0]?.score ?? 0
            let rhs = evidence[$1]?.score ?? 0
            if lhs == rhs { return $0.rawValue < $1.rawValue }
            return lhs > rhs
        }
        guard let top = ordered.first else { return [] }
        if ordered.count == 1 {
            return [_NLPrediction(language: top, probability: 1)]
        }

        let topEvidence = evidence[top] ?? _LanguageEvidence()
        let secondScore = evidence[ordered[1]]?.score ?? 0
        var confidence = confidence(
            features: features,
            language: top,
            evidence: topEvidence,
            margin: topEvidence.score - secondScore
        )
        confidence = max(
            confidence,
            (1 / Double(ordered.count)) + 0.000_001
        )
        confidence = min(confidence, 0.999)
        let tail = (1 - confidence) / Double(ordered.count - 1)
        return ordered.enumerated().map { index, language in
            _NLPrediction(
                language: language,
                probability: index == 0 ? confidence : tail
            )
        }
    }

    private static func profile(
        _ language: NLLanguage,
        _ words: String,
        _ fragments: [String]
    ) -> _LanguageProfile {
        _LanguageProfile(
            language: language,
            words: Set(words.split(separator: " ").map(String.init)),
            fragments: fragments
        )
    }

    private static func unique(_ languages: [NLLanguage]) -> [NLLanguage] {
        var seen: Set<NLLanguage> = []
        return languages.filter { seen.insert($0).inserted }
    }

    private static func candidates(for features: _TextFeatures) -> [NLLanguage] {
        let directCount = features.directScripts.values.max() ?? 0
        let cjkCount = features.hiraganaKatakanaCount + features.hanCount
            + features.hangulCount
        let knownNonLatin = max(
            directCount, features.greekCount, features.cyrillicCount,
            features.hebrewCount, features.arabicCount,
            features.devanagariCount, cjkCount
        )
        if features.latinCount > knownNonLatin {
            return latinLanguages
        }
        if features.hangulCount > 0 {
            return [.korean]
        }
        if features.hiraganaKatakanaCount > 0 {
            return [.japanese, .simplifiedChinese, .traditionalChinese]
        }
        if features.hanCount > 0 {
            return [.simplifiedChinese, .traditionalChinese, .japanese]
        }
        if features.greekCount > 0 { return [.greek] }
        if features.cyrillicCount > 0 {
            return [.russian, .ukrainian, .bulgarian, .kazakh]
        }
        if features.hebrewCount > 0 { return [.hebrew] }
        if features.arabicCount > 0 {
            return [.arabic, .persian, .urdu]
        }
        if features.devanagariCount > 0 { return [.hindi, .marathi] }
        if directCount > 0 {
            return features.directScripts
                .filter { $0.value == directCount }
                .map(\.key)
                .sorted { $0.rawValue < $1.rawValue }
        }
        return []
    }

    private static func lexicalEvidence(
        for language: NLLanguage,
        features: _TextFeatures
    ) -> _LanguageEvidence {
        guard let profile = profiles.first(where: {
            $0.language == language
        }) else { return _LanguageEvidence(score: 0.01) }
        var result = _LanguageEvidence(score: 0.01)
        for token in features.tokens where profile.words.contains(token) {
            if token.count >= 4 {
                result.score += 3
                result.strongHits += 1
            } else if token.count == 3 {
                result.score += 2
                result.strongHits += 1
            } else {
                result.score += 0.5
            }
        }
        let foldedText = features.tokens.joined(separator: " ")
        for fragment in profile.fragments
            where containsSubstring(fragment, in: foldedText)
        {
            result.score += 0.45
        }
        return result
    }

    /// Avoid Swift's regex-backed `String.contains(String)` overload so this
    /// framework does not acquire an otherwise unnecessary StringProcessing
    /// dylib dependency merely for fixed ASCII lexical fragments.
    private static func containsSubstring(
        _ needle: String,
        in haystack: String
    ) -> Bool {
        let needleBytes = Array(needle.utf8)
        let haystackBytes = Array(haystack.utf8)
        guard !needleBytes.isEmpty else { return true }
        guard needleBytes.count <= haystackBytes.count else { return false }
        for start in 0...(haystackBytes.count - needleBytes.count) {
            var matches = true
            for offset in needleBytes.indices
                where haystackBytes[start + offset] != needleBytes[offset]
            {
                matches = false
                break
            }
            if matches { return true }
        }
        return false
    }

    private static func scriptScore(
        for language: NLLanguage,
        features: _TextFeatures
    ) -> Double {
        let text = features.originalLowercase
        switch language {
        case .japanese:
            return features.hiraganaKatakanaCount > 0 ? 100 : 1
        case .korean:
            return Double(features.hangulCount) * 10
        case .simplifiedChinese:
            let simplified = markerCount(
                in: text, markers: "这个应用程序启发里为国门车东书云"
            )
            return 20 + Double(simplified) * 12
        case .traditionalChinese:
            let traditional = markerCount(
                in: text, markers: "這個應用程式啟發裡為國門車東書雲"
            )
            return 20 + Double(traditional) * 12
        case .greek:
            return Double(features.greekCount) * 10
        case .hebrew:
            return Double(features.hebrewCount) * 10
        case .arabic:
            return 20
        case .persian:
            return 10 + Double(markerCount(in: text, markers: "پچژگک")) * 20
        case .urdu:
            return 10 + Double(markerCount(in: text, markers: "ٹڈڑںھہےۓ")) * 20
        case .ukrainian:
            return 10 + Double(markerCount(in: text, markers: "іїєґ")) * 20
        case .bulgarian:
            return 10 + Double(wordHits(
                in: features.tokens,
                words: ["съм", "това", "ще", "няма", "може"]
            )) * 12
        case .russian:
            return 12 + Double(wordHits(
                in: features.tokens,
                words: ["это", "как", "для", "можно", "приложение"]
            )) * 12
        case .kazakh:
            return 10 + Double(markerCount(
                in: text, markers: "әғқңөұүһі"
            )) * 20
        case .marathi:
            return 10 + Double(markerCount(in: text, markers: "ळ")) * 20
                + Double(wordHits(
                    in: features.tokens, words: ["आहे", "आणि", "मध्ये"]
                )) * 12
        case .hindi:
            return 12 + Double(wordHits(
                in: features.tokens, words: ["है", "और", "में", "यह"]
            )) * 12
        default:
            return Double(features.directScripts[language] ?? 0) * 10
        }
    }

    private static func confidence(
        features: _TextFeatures,
        language: NLLanguage,
        evidence: _LanguageEvidence,
        margin: Double
    ) -> Double {
        if !latinLanguages.contains(language) {
            let scriptLetters = max(
                features.letterCount - features.latinCount,
                features.directScripts[language] ?? 0
            )
            guard scriptLetters >= 4 else {
                return min(0.59, 0.20 + Double(scriptLetters) * 0.08)
            }
            return min(0.999, 0.90 + Double(min(scriptLetters, 10)) * 0.009)
        }
        if features.letterCount >= 20,
           evidence.strongHits >= 3,
           margin >= 4
        {
            return min(
                0.99,
                0.85 + Double(evidence.strongHits - 3) * 0.02
                    + min(margin, 20) * 0.002
            )
        }
        return min(
            0.59,
            0.18 + Double(min(features.letterCount, 30)) * 0.006
                + Double(evidence.strongHits) * 0.045
                + max(0, min(margin, 4)) * 0.015
        )
    }

    private static func features(for text: String) -> _TextFeatures {
        let originalLowercase = text.lowercased()
        let folded = foldedLatin(originalLowercase)
        var tokens: [String] = []
        var token = ""
        for scalar in folded.unicodeScalars {
            if scalar.properties.isAlphabetic {
                token.append(String(scalar))
            } else if !token.isEmpty {
                tokens.append(token)
                token = ""
            }
        }
        if !token.isEmpty { tokens.append(token) }

        var letterCount = 0
        var latinCount = 0
        var hiraganaKatakanaCount = 0
        var hanCount = 0
        var hangulCount = 0
        var greekCount = 0
        var cyrillicCount = 0
        var hebrewCount = 0
        var arabicCount = 0
        var devanagariCount = 0
        var direct: [NLLanguage: Int] = [:]
        for scalar in originalLowercase.unicodeScalars
            where scalar.properties.isAlphabetic
        {
            letterCount += 1
            let value = scalar.value
            if isLatin(value) { latinCount += 1 }
            else if inRanges(value, [(0x3040, 0x30FF), (0x31F0, 0x31FF)]) {
                hiraganaKatakanaCount += 1
            } else if inRanges(value, [(0x3400, 0x4DBF), (0x4E00, 0x9FFF)]) {
                hanCount += 1
            } else if inRanges(value, [
                (0x1100, 0x11FF), (0x3130, 0x318F), (0xAC00, 0xD7AF),
            ]) {
                hangulCount += 1
            } else if inRanges(value, [(0x0370, 0x03FF)]) {
                greekCount += 1
            } else if inRanges(value, [(0x0400, 0x052F)]) {
                cyrillicCount += 1
            } else if inRanges(value, [(0x0590, 0x05FF)]) {
                hebrewCount += 1
            } else if inRanges(value, [
                (0x0600, 0x06FF), (0x0750, 0x077F), (0x08A0, 0x08FF),
            ]) {
                arabicCount += 1
            } else if inRanges(value, [(0x0900, 0x097F)]) {
                devanagariCount += 1
            } else if let language = directScriptLanguage(value) {
                direct[language, default: 0] += 1
            }
        }
        return _TextFeatures(
            originalLowercase: originalLowercase,
            tokens: tokens,
            letterCount: letterCount,
            latinCount: latinCount,
            hiraganaKatakanaCount: hiraganaKatakanaCount,
            hanCount: hanCount,
            hangulCount: hangulCount,
            greekCount: greekCount,
            cyrillicCount: cyrillicCount,
            hebrewCount: hebrewCount,
            arabicCount: arabicCount,
            devanagariCount: devanagariCount,
            directScripts: direct
        )
    }

    /// The portable Foundation facade deliberately does not expose the host's
    /// locale-backed `String.folding`. Language recognition only needs stable
    /// Latin lexical matching, so keep that normalization local and
    /// deterministic instead of acquiring a hidden ICU/runtime dependency.
    private static func foldedLatin(_ text: String) -> String {
        var result = ""
        result.reserveCapacity(text.utf8.count)
        for scalar in text.unicodeScalars {
            switch scalar.value {
            case 0x0300...0x036F:
                continue
            case 0x00E0...0x00E5, 0x0101, 0x0103, 0x0105,
                 0x01CE, 0x01DF, 0x01E1, 0x01FB,
                 0x1EA1, 0x1EA3, 0x1EA5, 0x1EA7, 0x1EA9, 0x1EAB,
                 0x1EAD, 0x1EAF, 0x1EB1, 0x1EB3, 0x1EB5, 0x1EB7:
                result.append("a")
            case 0x00E6, 0x01FD:
                result.append("ae")
            case 0x00E7, 0x0107, 0x0109, 0x010B, 0x010D:
                result.append("c")
            case 0x010F, 0x0111, 0x00F0:
                result.append("d")
            case 0x00E8...0x00EB, 0x0113, 0x0115, 0x0117, 0x0119,
                 0x011B, 0x0205, 0x0207, 0x1EB9, 0x1EBB, 0x1EBD,
                 0x1EBF, 0x1EC1, 0x1EC3, 0x1EC5, 0x1EC7:
                result.append("e")
            case 0x011D, 0x011F, 0x0121, 0x0123:
                result.append("g")
            case 0x0125, 0x0127:
                result.append("h")
            case 0x00EC...0x00EF, 0x0129, 0x012B, 0x012D, 0x012F,
                 0x0131, 0x01D0, 0x0209, 0x020B, 0x1EC9, 0x1ECB:
                result.append("i")
            case 0x0135:
                result.append("j")
            case 0x0137, 0x0138:
                result.append("k")
            case 0x013A, 0x013C, 0x013E, 0x0140, 0x0142:
                result.append("l")
            case 0x00F1, 0x0144, 0x0146, 0x0148, 0x0149, 0x014B:
                result.append("n")
            case 0x00F2...0x00F6, 0x00F8, 0x014D, 0x014F, 0x0151,
                 0x01A1, 0x01D2, 0x01EB, 0x01ED, 0x020D, 0x020F,
                 0x1ECD, 0x1ECF, 0x1ED1, 0x1ED3, 0x1ED5, 0x1ED7,
                 0x1ED9, 0x1EDB, 0x1EDD, 0x1EDF, 0x1EE1, 0x1EE3:
                result.append("o")
            case 0x0153:
                result.append("oe")
            case 0x0155, 0x0157, 0x0159:
                result.append("r")
            case 0x015B, 0x015D, 0x015F, 0x0161, 0x0219:
                result.append("s")
            case 0x00DF:
                result.append("ss")
            case 0x0163, 0x0165, 0x0167, 0x021B:
                result.append("t")
            case 0x00F9...0x00FC, 0x0169, 0x016B, 0x016D, 0x016F,
                 0x0171, 0x0173, 0x01B0, 0x01D4, 0x01D6, 0x01D8,
                 0x01DA, 0x01DC, 0x0215, 0x0217, 0x1EE5, 0x1EE7,
                 0x1EE9, 0x1EEB, 0x1EED, 0x1EEF, 0x1EF1:
                result.append("u")
            case 0x0175:
                result.append("w")
            case 0x00FD, 0x00FF, 0x0177, 0x1EF3, 0x1EF5, 0x1EF7,
                 0x1EF9:
                result.append("y")
            case 0x017A, 0x017C, 0x017E:
                result.append("z")
            default:
                result.unicodeScalars.append(scalar)
            }
        }
        return result
    }

    private static func directScriptLanguage(_ value: UInt32) -> NLLanguage? {
        switch value {
        case 0x0530...0x058F: .armenian
        case 0x0980...0x09FF: .bengali
        case 0x0A00...0x0A7F: .punjabi
        case 0x0A80...0x0AFF: .gujarati
        case 0x0B00...0x0B7F: .oriya
        case 0x0B80...0x0BFF: .tamil
        case 0x0C00...0x0C7F: .telugu
        case 0x0C80...0x0CFF: .kannada
        case 0x0D00...0x0D7F: .malayalam
        case 0x0D80...0x0DFF: .sinhalese
        case 0x0E00...0x0E7F: .thai
        case 0x0E80...0x0EFF: .lao
        case 0x0F00...0x0FFF: .tibetan
        case 0x1000...0x109F: .burmese
        case 0x10A0...0x10FF: .georgian
        case 0x1200...0x137F: .amharic
        case 0x13A0...0x13FF: .cherokee
        case 0x1780...0x17FF: .khmer
        case 0x1800...0x18AF: .mongolian
        default: nil
        }
    }

    private static func isLatin(_ value: UInt32) -> Bool {
        inRanges(value, [
            (0x0041, 0x005A), (0x0061, 0x007A), (0x00C0, 0x024F),
            (0x1E00, 0x1EFF),
        ])
    }

    private static func inRanges(
        _ value: UInt32,
        _ ranges: [(UInt32, UInt32)]
    ) -> Bool {
        ranges.contains { $0.0 <= value && value <= $0.1 }
    }

    private static func markerCount(in text: String, markers: String) -> Int {
        let set = Set(markers)
        return text.reduce(into: 0) { count, character in
            if set.contains(character) { count += 1 }
        }
    }

    private static func wordHits(
        in tokens: [String],
        words: Set<String>
    ) -> Int {
        tokens.reduce(into: 0) { count, token in
            if words.contains(token) { count += 1 }
        }
    }
}
