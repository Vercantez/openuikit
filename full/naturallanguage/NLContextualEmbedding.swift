import Foundation

public final class NLContextualEmbedding: NSObject {
    public enum AssetsResult: Int, Sendable, Hashable {
        case available = 0
        case notAvailable = 1
        case error = 2
    }

    public var dimension: Int { 0 }
    public var hasAvailableAssets: Bool { false }
    public var languages: [NLLanguage] { [] }
    public var maximumSequenceLength: Int { 0 }
    public var modelIdentifier: String { "" }
    public var revision: Int { 0 }
    public var scripts: [NLScript] { [] }

    private override init() {
        super.init()
    }

    public init?(language: NLLanguage) {
        return nil
    }

    public convenience init?(modelIdentifier: String) {
        return nil
    }

    public init?(script: NLScript) {
        return nil
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
        _ = string
        _ = language
        throw NLLinuxSupport.error(
            "NLContextualEmbedding Apple models are unavailable on this host"
        )
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
