import Foundation
import NaturalLanguage

func testNLContextualEmbeddingUnavailableProperties() {
    let languageEmbedding = NLContextualEmbedding(language: .english)
    precondition(languageEmbedding != nil)
    precondition(languageEmbedding!.dimension == 0)
    precondition(languageEmbedding!.hasAvailableAssets == false)
    precondition(languageEmbedding!.languages == [.english])
    precondition(languageEmbedding!.maximumSequenceLength == 0)
    precondition(languageEmbedding!.modelIdentifier.isEmpty)
    precondition(languageEmbedding!.revision == 0)
    precondition(languageEmbedding!.scripts.isEmpty)

    let scriptEmbedding = NLContextualEmbedding(script: .latin)
    precondition(scriptEmbedding != nil)
    precondition(scriptEmbedding!.scripts == [.latin])
    precondition(scriptEmbedding!.languages.isEmpty)
    precondition(scriptEmbedding!.hasAvailableAssets == false)

    let identified = NLContextualEmbedding(modelIdentifier: "nl.linux.unavailable")
    precondition(identified != nil)
    precondition(identified!.modelIdentifier == "nl.linux.unavailable")
    precondition(identified!.dimension == 0)
    precondition(identified!.revision == 0)
}

func testNLContextualEmbeddingUnavailableMethods() {
    let embedding = NLContextualEmbedding(language: .english)!
    do {
        try embedding.load()
        preconditionFailure("load must fail closed without Apple models")
    } catch {
        precondition((error as NSError).domain == "org.openuikit.NaturalLanguage.linux")
    }
    embedding.unload()

    var assets: NLContextualEmbedding.AssetsResult?
    var assetsError: (any Error)?
    embedding.requestAssets { result, error in
        assets = result
        assetsError = error
    }
    precondition(assets == .notAvailable)
    precondition(assetsError == nil)

    let result = try! embedding.embeddingResult(for: "Hello Linux", language: .english)
    precondition(result.string == "Hello Linux")
    precondition(result.language == .english)
    precondition(result.sequenceLength == 0)
}

func testNLContextualEmbeddingResultEmptyVectors() {
    let embedding = NLContextualEmbedding(language: .french)!
    let text = "Bonjour"
    let result = try! embedding.embeddingResult(for: text, language: nil)
    precondition(result.string == text)
    precondition(result.language == .french)
    precondition(result.sequenceLength == 0)
    precondition(result.tokenVector(at: text.startIndex) == nil)
    var invoked = false
    result.enumerateTokenVectors(in: text.startIndex..<text.endIndex) { _, _ in
        invoked = true
        return true
    }
    precondition(invoked == false)
    let explicit = try! embedding.embeddingResult(for: text, language: .spanish)
    precondition(explicit.language == .spanish)
}
