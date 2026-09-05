import Foundation

public final class NLContextualEmbedding: NSObject {
    public enum AssetsResult: Int, Sendable, Hashable {
        case available = 0
        case notAvailable = 1
        case error = 2
    }

    public let dimension: Int
    public let hasAvailableAssets: Bool
    public let languages: [NLLanguage]
    public let maximumSequenceLength: Int
    public let modelIdentifier: String
    public let revision: Int
    public let scripts: [NLScript]

    private init(
        languages: [NLLanguage],
        scripts: [NLScript],
        modelIdentifier: String
    ) {
        self.dimension = 0
        self.hasAvailableAssets = false
        self.languages = languages
        self.maximumSequenceLength = 0
        self.modelIdentifier = modelIdentifier
        self.revision = 0
        self.scripts = scripts
        super.init()
    }

    public convenience init?(language: NLLanguage) {
        self.init(languages: [language], scripts: [], modelIdentifier: "")
    }

    public convenience init?(modelIdentifier: String) {
        guard !modelIdentifier.isEmpty else { return nil }
        self.init(languages: [], scripts: [], modelIdentifier: modelIdentifier)
    }

    public convenience init?(script: NLScript) {
        self.init(languages: [], scripts: [script], modelIdentifier: "")
    }

    public class func contextualEmbeddings(
        forValues valuesDictionary: [NLContextualEmbeddingKey: Any]
    ) -> [NLContextualEmbedding] {
        _ = valuesDictionary
        return []
    }

    public func embeddingResult(
        for string: String,
        language: NLLanguage?
    ) throws -> NLContextualEmbeddingResult {
        let resolved = language ?? languages.first ?? .undetermined
        return NLContextualEmbeddingResult(string: string, language: resolved)
    }

    public func load() throws {
        throw NLLinuxSupport.error(
            "NLContextualEmbedding Apple models are unavailable on this host"
        )
    }

    public func requestAssets(
        completionHandler: @escaping (NLContextualEmbedding.AssetsResult, (any Error)?) -> Void
    ) {
        completionHandler(.notAvailable, nil)
    }

    public func unload() {}
}

public final class NLContextualEmbeddingResult: NSObject {
    public var language: NLLanguage { storedLanguage }
    public var sequenceLength: Int { 0 }
    public var string: String { storedString }

    private let storedLanguage: NLLanguage
    private let storedString: String

    fileprivate init(string: String, language: NLLanguage) {
        self.storedString = string
        self.storedLanguage = language
        super.init()
    }

    public func tokenVector(at index: String.Index) -> ([Double], Range<String.Index>)? {
        _ = index
        return nil
    }

    public func enumerateTokenVectors(
        in range: Range<String.Index>,
        using block: ([Double], Range<String.Index>) -> Bool
    ) {
        _ = range
        _ = block
    }
}
