import Foundation
import NaturalLanguage

func testNLLanguageConstants() {
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
        (.marathi, "mr"), (.mongolian, "mn"), (.norwegian, "nb"),
        (.oriya, "or"), (.persian, "fa"), (.polish, "pl"),
        (.portuguese, "pt"), (.punjabi, "pa"), (.romanian, "ro"),
        (.russian, "ru"), (.simplifiedChinese, "zh-Hans"),
        (.sinhalese, "si"), (.slovak, "sk"), (.spanish, "es"),
        (.swedish, "sv"), (.tamil, "ta"), (.telugu, "te"),
        (.thai, "th"), (.tibetan, "bo"), (.traditionalChinese, "zh-Hant"),
        (.turkish, "tr"), (.ukrainian, "uk"), (.urdu, "ur"),
        (.vietnamese, "vi"), (.kazakh, "kk"),
    ]
    precondition(constants.count == 58)
    for (language, tag) in constants {
        precondition(language.rawValue == tag)
        precondition(language.description == tag)
        precondition(NLLanguage(rawValue: tag) == language)
        precondition(NLLanguage(tag) == language)
    }
    let unknown = NLLanguage("xx-Zzzz")
    precondition(unknown != .english)
    precondition(unknown.hashValue == NLLanguage(rawValue: "xx-Zzzz").hashValue)
    var hasher = Hasher()
    unknown.hash(into: &hasher)
    let encoded = try! JSONEncoder().encode(NLLanguage.english)
    let decoded = try! JSONDecoder().decode(NLLanguage.self, from: encoded)
    precondition(decoded == .english)
}

func testNLLanguageRecognizerEnglish() {
    let text =
        "It would be great to have dark mode support in the application."
    precondition(NLLanguageRecognizer.dominantLanguage(for: text) == .english)
    let recognizer = NLLanguageRecognizer()
    precondition(recognizer.dominantLanguage == nil)
    recognizer.processString(text)
    precondition(recognizer.dominantLanguage == .english)
    let top = recognizer.languageHypotheses(withMaximum: 1)
    precondition(top[.english, default: 0] >= 0.85)
    precondition(recognizer.languageHypotheses(withMaximum: 0).isEmpty)
}

func testNLLanguageRecognizerScriptsAndLowEvidence() {
    func top(_ text: String) -> (NLLanguage, Double)? {
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        guard let language = recognizer.dominantLanguage else { return nil }
        guard let confidence = recognizer.languageHypotheses(withMaximum: 1)[language]
        else { return nil }
        return (language, confidence)
    }
    precondition(top("このアプリケーションでダークモードを有効にできると素晴らしいです。")?.0 == .japanese)
    precondition(top("如果可以在这个应用程序中启用深色模式，那就太好了。")?.0 == .simplifiedChinese)
    precondition(
        top("سيكون من الرائع أن نتمكن من تفعيل الوضع الداكن في هذا التطبيق.")?.0 == .arabic
    )
    let short = top("Dark Mode")
    precondition(short != nil)
    precondition((short?.1 ?? 1) < 0.6)
    precondition(top("𒀀𒂗𒆠 𒄑𒉋 𒈗𒆠") == nil)
}

func testNLLanguageRecognizerIncrementalConstraintsHints() {
    let incremental = NLLanguageRecognizer()
    incremental.processString("This community is open")
    incremental.processString("and everyone is welcome here today.")
    precondition(incremental.dominantLanguage == .english)
    incremental.reset()
    incremental.processString(
        "Bonjour tout le monde, je suis très heureux de vous retrouver aujourd'hui."
    )
    precondition(incremental.dominantLanguage == .french)

    let constrained = NLLanguageRecognizer()
    constrained.languageConstraints = [.french, .spanish]
    constrained.processString(
        "Hola a todos, estamos construyendo una comunidad abierta y amable."
    )
    precondition(constrained.dominantLanguage == .spanish)

    let hinted = NLLanguageRecognizer()
    hinted.languageHints = [.english: 0.99, .french: 0.01]
    hinted.processString("hello bonjour")
    precondition(hinted.dominantLanguage == .english)
}

func testNLScriptConstants() {
    let scripts: [(NLScript, String)] = [
        (.undetermined, "Zyyy"), (.arabic, "Arab"), (.armenian, "Armn"),
        (.bengali, "Beng"), (.canadianAboriginalSyllabics, "Cans"),
        (.cherokee, "Cher"), (.cyrillic, "Cyrl"), (.devanagari, "Deva"),
        (.ethiopic, "Ethi"), (.georgian, "Geor"), (.greek, "Grek"),
        (.gujarati, "Gujr"), (.gurmukhi, "Guru"), (.hebrew, "Hebr"),
        (.japanese, "Jpan"), (.kannada, "Knda"), (.khmer, "Khmr"),
        (.korean, "Kore"), (.lao, "Laoo"), (.latin, "Latn"),
        (.malayalam, "Mlym"), (.mongolian, "Mong"), (.myanmar, "Mymr"),
        (.oriya, "Orya"), (.simplifiedChinese, "Hans"), (.sinhala, "Sinh"),
        (.tamil, "Taml"), (.telugu, "Telu"), (.thai, "Thai"),
        (.tibetan, "Tibt"), (.traditionalChinese, "Hant"),
    ]
    for (script, tag) in scripts {
        precondition(script.rawValue == tag)
        precondition(NLScript(tag) == script)
        precondition(script != .undetermined || tag == "Zyyy")
    }
    let tagger = NLTagger(tagSchemes: [.script])
    tagger.string = "Hello"
    precondition(
        tagger.tag(at: tagger.string!.startIndex, unit: .document, scheme: .script).0?.rawValue
            == "Latn"
    )
    tagger.string = "Привет"
    precondition(
        tagger.tag(at: tagger.string!.startIndex, unit: .document, scheme: .script).0?.rawValue
            == "Cyrl"
    )
    tagger.string = "こんにちは"
    precondition(
        tagger.tag(at: tagger.string!.startIndex, unit: .document, scheme: .script).0?.rawValue
            == "Jpan"
    )
    precondition(NLScript.latin.hashValue == NLScript(rawValue: "Latn").hashValue)
    var hasher = Hasher()
    NLScript.cyrillic.hash(into: &hasher)
}

func testNLTagAndSchemeConstants() {
    let tags: [(NLTag, String)] = [
        (.word, "Word"), (.punctuation, "Punctuation"),
        (.whitespace, "Whitespace"), (.other, "Other"),
        (.noun, "Noun"), (.verb, "Verb"), (.adjective, "Adjective"),
        (.adverb, "Adverb"), (.pronoun, "Pronoun"),
        (.determiner, "Determiner"), (.particle, "Particle"),
        (.preposition, "Preposition"), (.number, "Number"),
        (.conjunction, "Conjunction"), (.interjection, "Interjection"),
        (.classifier, "Classifier"), (.idiom, "Idiom"),
        (.otherWord, "OtherWord"), (.sentenceTerminator, "SentenceTerminator"),
        (.openQuote, "OpenQuote"), (.closeQuote, "CloseQuote"),
        (.openParenthesis, "OpenParenthesis"),
        (.closeParenthesis, "CloseParenthesis"), (.wordJoiner, "WordJoiner"),
        (.dash, "Dash"), (.otherPunctuation, "OtherPunctuation"),
        (.paragraphBreak, "ParagraphBreak"),
        (.otherWhitespace, "OtherWhitespace"),
        (.personalName, "PersonalName"), (.placeName, "PlaceName"),
        (.organizationName, "OrganizationName"),
    ]
    for (tag, raw) in tags {
        precondition(tag.rawValue == raw)
        precondition(NLTag(raw) == tag)
    }
    let schemes: [(NLTagScheme, String)] = [
        (.tokenType, "TokenType"), (.lexicalClass, "LexicalClass"),
        (.nameType, "NameType"),
        (.nameTypeOrLexicalClass, "NameTypeOrLexicalClass"),
        (.lemma, "Lemma"), (.language, "Language"), (.script, "Script"),
        (.sentimentScore, "SentimentScore"),
    ]
    for (scheme, raw) in schemes {
        precondition(scheme.rawValue == raw)
        precondition(NLTagScheme(rawValue: raw) == scheme)
    }
    precondition(NLContextualEmbeddingKey.languages.rawValue == "NLContextualEmbeddingKeyLanguages")
    precondition(NLContextualEmbeddingKey.scripts.rawValue == "NLContextualEmbeddingKeyScripts")
    precondition(NLContextualEmbeddingKey.revision.rawValue == "NLContextualEmbeddingKeyRevision")
    precondition(NLContextualEmbeddingKey("NLContextualEmbeddingKeyLanguages") == .languages)
    var hasher = Hasher()
    NLTag.word.hash(into: &hasher)
    NLTagScheme.tokenType.hash(into: &hasher)
    NLContextualEmbeddingKey.languages.hash(into: &hasher)
    precondition(NLTag.word.hashValue == NLTag("Word").hashValue)
}

func testNLTokenUnitAndDistanceType() {
    precondition(NLTokenUnit.word.rawValue == 0)
    precondition(NLTokenUnit.sentence.rawValue == 1)
    precondition(NLTokenUnit.paragraph.rawValue == 2)
    precondition(NLTokenUnit.document.rawValue == 3)
    precondition(NLTokenUnit(rawValue: 0) == .word)
    precondition(NLTokenUnit(rawValue: 99) == nil)
    precondition(NLDistanceType.cosine.rawValue == 0)
    precondition(NLDistanceType(rawValue: 0) == .cosine)
    precondition(NLModel.ModelType.classifier.rawValue == 0)
    precondition(NLModel.ModelType.sequence.rawValue == 1)
    precondition(NLModel.ModelType(rawValue: 1) == .sequence)
    precondition(NLTagger.AssetsResult.available.rawValue == 0)
    precondition(NLTagger.AssetsResult.notAvailable.rawValue == 1)
    precondition(NLTagger.AssetsResult.error.rawValue == 2)
    precondition(NLContextualEmbedding.AssetsResult.available.rawValue == 0)
    precondition(NLContextualEmbedding.AssetsResult.notAvailable.rawValue == 1)
    precondition(NLContextualEmbedding.AssetsResult.error.rawValue == 2)
    var hasher = Hasher()
    NLTokenUnit.word.hash(into: &hasher)
    NLDistanceType.cosine.hash(into: &hasher)
    NLModel.ModelType.classifier.hash(into: &hasher)
    NLTagger.AssetsResult.available.hash(into: &hasher)
    NLContextualEmbedding.AssetsResult.notAvailable.hash(into: &hasher)
    precondition(NLTokenUnit.word.hashValue == NLTokenUnit(rawValue: 0)!.hashValue)
}

func testNLTaggerOptionsAndTokenizerAttributes() {
    var options: NLTagger.Options = []
    precondition(options.isEmpty)
    options.insert(.omitWords)
    precondition(options.contains(.omitWords))
    precondition(!options.contains(.omitPunctuation))
    let union = NLTagger.Options.omitWords.union(.omitPunctuation)
    precondition(union.contains(.omitWords) && union.contains(.omitPunctuation))
    let intersection = union.intersection(.omitWords)
    precondition(intersection == .omitWords)
    var mutable = union
    mutable.formUnion(.omitWhitespace)
    precondition(mutable.contains(.omitWhitespace))
    mutable.formIntersection(.omitWords)
    precondition(mutable == .omitWords)
    mutable.formSymmetricDifference(.omitPunctuation)
    precondition(mutable.contains(.omitPunctuation))
    precondition(mutable.contains(.omitWords))
    mutable.subtract(.omitWords)
    mutable.subtract(.omitPunctuation)
    precondition(mutable.isEmpty)
    precondition(NLTagger.Options.omitOther.rawValue == 1 << 3)
    precondition(NLTagger.Options.joinNames.rawValue == 1 << 4)
    precondition(NLTagger.Options.joinContractions.rawValue == 1 << 5)
    precondition(NLTagger.Options([.omitWords, .omitOther]).contains(.omitOther))
    precondition(NLTagger.Options.omitWords.isSubset(of: union))
    precondition(union.isSuperset(of: .omitWords))
    precondition(!NLTagger.Options.omitWords.isDisjoint(with: union))
    precondition(NLTagger.Options.omitWords.isDisjoint(with: .omitOther))
    precondition(union.subtracting(.omitWords) == .omitPunctuation)
    precondition(NLTagger.Options.omitWords.isStrictSubset(of: union))
    precondition(union.isStrictSuperset(of: .omitWords))
    _ = mutable.update(with: .omitWords)
    _ = mutable.remove(.omitWords)
    precondition(NLTagger.Options.omitWords.hashValue == NLTagger.Options(rawValue: 1).hashValue)
    var optHasher = Hasher()
    NLTagger.Options.omitWhitespace.hash(into: &optHasher)

    var attributes: NLTokenizer.Attributes = []
    precondition(attributes.isEmpty)
    attributes.insert(.numeric)
    precondition(attributes.contains(.numeric))
    let combined = NLTokenizer.Attributes.numeric.union(.symbolic).union(.emoji)
    precondition(combined.contains(.emoji))
    precondition(NLTokenizer.Attributes.numeric.rawValue == 1 << 0)
    precondition(NLTokenizer.Attributes.symbolic.rawValue == 1 << 1)
    precondition(NLTokenizer.Attributes.emoji.rawValue == 1 << 2)
    precondition(combined.isSuperset(of: .numeric))
    var attrCopy = combined
    attrCopy.formIntersection(.numeric)
    precondition(attrCopy == .numeric)
    attrCopy.formSymmetricDifference(.symbolic)
    precondition(attrCopy.contains(.symbolic))
    attrCopy.subtract(.symbolic)
    _ = attrCopy.update(with: .emoji)
    _ = attrCopy.remove(.emoji)
    precondition(
        NLTokenizer.Attributes.numeric.hashValue
            == NLTokenizer.Attributes(rawValue: 1).hashValue
    )
}

func testNLTokenizerWords() {
    let tokenizer = NLTokenizer(unit: .word)
    tokenizer.setLanguage(.english)
    tokenizer.string = "Hello, 42 👋"
    let full = tokenizer.string!.startIndex..<tokenizer.string!.endIndex
    let tokens = tokenizer.tokens(for: full)
    let pieces = tokens.map { String(tokenizer.string![$0]) }
    precondition(pieces.contains("Hello"))
    precondition(pieces.contains(","))
    precondition(pieces.contains("42"))
    var sawNumeric = false
    var sawSymbolic = false
    var sawEmoji = false
    tokenizer.enumerateTokens(in: full) { range, attributes in
        let token = String(tokenizer.string![range])
        if token == "42" {
            precondition(attributes.contains(.numeric))
            sawNumeric = true
        }
        if token == "," {
            precondition(attributes.contains(.symbolic))
            sawSymbolic = true
        }
        if attributes.contains(.emoji) {
            sawEmoji = true
        }
        return true
    }
    precondition(sawNumeric && sawSymbolic && sawEmoji)
    let hello = tokenizer.string!.range(of: "Hello")!
    precondition(tokenizer.tokenRange(at: hello.lowerBound) == hello)
    let spanning = tokenizer.tokenRange(for: hello)
    precondition(spanning == hello)
    precondition(tokenizer.unit == .word)
}

func testNLTokenizerSentencesParagraphsDocument() {
    let text = "Hello world. How are you?\n\nSecond paragraph"
    let sentences = NLTokenizer(unit: .sentence)
    sentences.string = text
    let sentenceRanges = sentences.tokens(for: text.startIndex..<text.endIndex)
    precondition(sentenceRanges.count >= 2)
    precondition(String(text[sentenceRanges[0]]).contains("Hello"))

    let paragraphs = NLTokenizer(unit: .paragraph)
    paragraphs.string = text
    let paragraphRanges = paragraphs.tokens(for: text.startIndex..<text.endIndex)
    precondition(paragraphRanges.count >= 2)
    precondition(String(text[paragraphRanges.last!]).contains("Second"))

    let document = NLTokenizer(unit: .document)
    document.string = text
    let docs = document.tokens(for: text.startIndex..<text.endIndex)
    precondition(docs.count == 1)
    precondition(String(text[docs[0]]) == text)
}

func testNLTaggerTokenTypeLanguageScript() {
    let tagger = NLTagger(tagSchemes: [.tokenType, .language, .script])
    tagger.string = "Hello, world."
    precondition(tagger.tagSchemes.contains(.tokenType))
    let full = tagger.string!.startIndex..<tagger.string!.endIndex
    let tokenTags = tagger.tags(in: full, unit: .word, scheme: .tokenType)
    let values = tokenTags.compactMap { $0.0 }
    precondition(values.contains(.word))
    precondition(values.contains(.otherPunctuation) || values.contains(.sentenceTerminator))
    let (helloTag, helloRange) = tagger.tag(
        at: tagger.string!.startIndex,
        unit: .word,
        scheme: .tokenType
    )
    precondition(helloTag == .word)
    precondition(String(tagger.string![helloRange]) == "Hello")

    let english = "This is a thoughtful message about building a better social network together."
    tagger.string = english
    let languageTag = tagger.tag(
        at: english.startIndex,
        unit: .document,
        scheme: .language
    ).0
    precondition(languageTag?.rawValue == "en")
    let scriptTag = tagger.tag(
        at: english.startIndex,
        unit: .document,
        scheme: .script
    ).0
    precondition(scriptTag?.rawValue == "Latn")
    precondition(tagger.dominantLanguage == .english)
    tagger.setLanguage(.french, range: english.startIndex..<english.endIndex)
    let overridden = tagger.tag(
        at: english.startIndex,
        unit: .document,
        scheme: .language
    ).0
    precondition(overridden?.rawValue == "fr")
    let hypotheses = tagger.tagHypotheses(
        at: english.startIndex,
        unit: .document,
        scheme: .language,
        maximumCount: 3
    )
    precondition(!hypotheses.0.isEmpty)
    precondition(
        NLTagger.availableTagSchemes(for: .word, language: .english)
            == [.tokenType, .language, .script]
    )
}

func testNLTaggerOptionsFilteringAndGazetteer() {
    let tagger = NLTagger(tagSchemes: [.tokenType, .nameType])
    tagger.string = "Hello, world."
    let full = tagger.string!.startIndex..<tagger.string!.endIndex
    let omitted = tagger.tags(
        in: full,
        unit: .word,
        scheme: .tokenType,
        options: [.omitPunctuation, .omitWhitespace]
    )
    precondition(omitted.allSatisfy { $0.0 == .word })
    let gazetteer = try! NLGazetteer(
        dictionary: ["organizationName": ["OpenUIKit"]],
        language: .english
    )
    tagger.setGazetteers([gazetteer], for: .nameType)
    precondition(tagger.gazetteers(for: .nameType).count == 1)
    tagger.string = "OpenUIKit"
    let named = tagger.tag(
        at: tagger.string!.startIndex,
        unit: .word,
        scheme: .nameType
    ).0
    precondition(named?.rawValue == "organizationName")
    tagger.setModels([], forTagScheme: .tokenType)
    precondition(tagger.models(forTagScheme: .tokenType).isEmpty)
}

func testNLGazetteerRoundTrip() {
    let dictionary = ["org": ["OpenUIKit", "NaturalLanguage"], "place": ["Cupertino"]]
    let gazetteer = try! NLGazetteer(dictionary: dictionary, language: .english)
    precondition(gazetteer.language == .english)
    precondition(gazetteer.label(for: "OpenUIKit") == "org")
    precondition(gazetteer.label(for: "Cupertino") == "place")
    precondition(gazetteer.label(for: "missing") == nil)
    let fromData = try! NLGazetteer(data: gazetteer.data)
    precondition(fromData.label(for: "NaturalLanguage") == "org")
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("nl-gazetteer-\(UUID().uuidString).json")
    try! NLGazetteer.write(dictionary, language: .english, to: url)
    let loaded = try! NLGazetteer(contentsOf: url)
    precondition(loaded.label(for: "OpenUIKit") == "org")
    let loadedURL = try! NLGazetteer(contentsOfURL: url)
    precondition(loadedURL.language == .english)
    try? FileManager.default.removeItem(at: url)
}

func testNLEmbeddingCustomVectors() {
    let url = FileManager.default.temporaryDirectory
        .appendingPathComponent("nl-embed-\(UUID().uuidString).json")
    try! NLEmbedding.write(
        ["cat": [1, 0], "dog": [0.9, 0.1], "car": [0, 1]],
        language: .english,
        revision: 1,
        to: url
    )
    let embedding = try! NLEmbedding(contentsOf: url)
    precondition(embedding.dimension == 2)
    precondition(embedding.vocabularySize == 3)
    precondition(embedding.language == .english)
    precondition(embedding.revision == 1)
    precondition(embedding.contains("cat"))
    precondition(!embedding.contains("missing"))
    precondition(embedding.vector(for: "cat") == [1, 0])
    let distance = embedding.distance(between: "cat", and: "dog")
    precondition(distance < embedding.distance(between: "cat", and: "car"))
    let neighbors = embedding.neighbors(for: "cat", maximumCount: 2)
    precondition(neighbors.first?.0 == "dog")
    var enumerated: [String] = []
    embedding.enumerateNeighbors(for: "cat", maximumCount: 2) { word, _ in
        enumerated.append(word)
        return true
    }
    precondition(enumerated.first == "dog")
    let fromVector = embedding.neighbors(for: [1, 0], maximumCount: 1)
    precondition(fromVector.first?.0 == "cat")
    var vectorNames: [String] = []
    embedding.enumerateNeighbors(for: [1, 0], maximumCount: 1) { word, _ in
        vectorNames.append(word)
        return false
    }
    precondition(vectorNames == ["cat"])
    let alias = try! NLEmbedding(contentsOfURL: url)
    precondition(alias.contains("dog"))
    try? FileManager.default.removeItem(at: url)
}

func testNLEmbeddingAndModelAppleAssetsUnavailable() {
    precondition(NLEmbedding.wordEmbedding(for: .english) == nil)
    precondition(NLEmbedding.wordEmbedding(for: .english, revision: 1) == nil)
    precondition(NLEmbedding.sentenceEmbedding(for: .english) == nil)
    precondition(NLEmbedding.sentenceEmbedding(for: .english, revision: 1) == nil)
    precondition(NLEmbedding.currentRevision(for: .english) == 0)
    precondition(NLEmbedding.currentSentenceEmbeddingRevision(for: .english) == 0)
    precondition(NLEmbedding.supportedRevisions(for: .english).isEmpty)
    precondition(NLEmbedding.supportedSentenceEmbeddingRevisions(for: .english).isEmpty)
    do {
        _ = try NLModel(contentsOf: URL(fileURLWithPath: "/tmp/missing-nl-model"))
        preconditionFailure("NLModel should fail closed")
    } catch {
        precondition((error as NSError).domain == "org.openuikit.NaturalLanguage.linux")
    }
    do {
        _ = try NLModel(contentsOfURL: URL(fileURLWithPath: "/tmp/missing-nl-model"))
        preconditionFailure("NLModel should fail closed")
    } catch {
        precondition((error as NSError).domain == "org.openuikit.NaturalLanguage.linux")
    }
    precondition(NLModelConfiguration.currentRevision(for: .classifier) == 0)
    precondition(NLModelConfiguration.supportedRevisions(for: .sequence).isEmpty)
    precondition(NLModelConfiguration.supportsSecureCoding)
    precondition(NLModelConfiguration(coder: NSCoder()) == nil)
}

func testNLContextualEmbeddingUnavailable() {
    precondition(NLContextualEmbedding(language: .english) == nil)
    precondition(NLContextualEmbedding(script: .latin) == nil)
    precondition(NLContextualEmbedding(modelIdentifier: "missing") == nil)
    precondition(
        NLContextualEmbedding.contextualEmbeddings(forValues: [
            .languages: [NLLanguage.english]
        ]).isEmpty
    )
}

func testNLTaggerTokenRangeHelpers() {
    let tagger = NLTagger(tagSchemes: [.tokenType])
    let text = "Hello world"
    tagger.string = text
    let hello = text.range(of: "Hello")!
    precondition(tagger.tokenRange(at: hello.lowerBound, unit: .word) == hello)
    precondition(tagger.tokenRange(for: hello, unit: .word) == hello)
}

func testNLTaggerRequestAssetsFailClosed() {
    let semaphore = DispatchSemaphore(value: 0)
    var local: NLTagger.AssetsResult?
    var remote: NLTagger.AssetsResult?
    Task {
        local = try await NLTagger.requestAssets(for: .english, tagScheme: .tokenType)
        remote = try await NLTagger.requestAssets(for: .english, tagScheme: .lemma)
        semaphore.signal()
    }
    precondition(semaphore.wait(timeout: .now() + 5) == .success)
    precondition(local == .available)
    precondition(remote == .notAvailable)
}

func testNLDistanceAliasAndInequality() {
    let distance: NLDistance = 0.25
    precondition(distance == 0.25)
    precondition(NLLanguage.english != .french)
    precondition(NLScript.latin != .cyrillic)
    precondition(NLTag.word != .punctuation)
    precondition(NLTagScheme.tokenType != .lemma)
    precondition(NLTokenUnit.word != .sentence)
    precondition(NLDistanceType.cosine == NLDistanceType.cosine)
    precondition(NLTagger.Options.omitWords != .omitPunctuation)
    precondition(NLTokenizer.Attributes.numeric != .emoji)
}
