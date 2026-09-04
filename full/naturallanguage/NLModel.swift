import Foundation

public final class NLModel: NSObject {
    public enum ModelType: Int, Sendable, Hashable {
        case classifier = 0
        case sequence = 1
    }

    public var configuration: NLModelConfiguration {
        storedConfiguration
    }

    private let storedConfiguration: NLModelConfiguration

    private init(configuration: NLModelConfiguration) {
        self.storedConfiguration = configuration
        super.init()
    }

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOfURL: url)
    }

    public convenience init(contentsOfURL url: URL) throws {
        throw NLLinuxSupport.error(
            "NLModel Apple Create ML packages are unavailable on this host"
        )
    }

    public func predictedLabel(for string: String) -> String? {
        _ = string
        return nil
    }

    public func predictedLabels(forTokens tokens: [String]) -> [String] {
        Array(repeating: "", count: tokens.count)
    }

    public func predictedLabelHypotheses(
        for string: String,
        maximumCount maxCount: Int
    ) -> [String: Double] {
        _ = string
        _ = maxCount
        return [:]
    }

    public func predictedLabelHypotheses(
        forTokens tokens: [String],
        maximumCount maxCount: Int
    ) -> [[String: Double]] {
        _ = maxCount
        return Array(repeating: [:], count: tokens.count)
    }
}

public final class NLModelConfiguration: NSObject, NSCopying, NSSecureCoding {
    public let type: NLModel.ModelType
    public let language: NLLanguage?
    public let revision: Int

    fileprivate init(type: NLModel.ModelType, language: NLLanguage?, revision: Int) {
        self.type = type
        self.language = language
        self.revision = revision
        super.init()
    }

    public func copy(with zone: NSZone? = nil) -> Any {
        NLModelConfiguration(type: type, language: language, revision: revision)
    }

    public static var supportsSecureCoding: Bool { true }

    public func encode(with coder: NSCoder) {
        coder.encode(type.rawValue, forKey: "type")
        coder.encode(revision, forKey: "revision")
        coder.encode(language?.rawValue, forKey: "language")
    }

    public init?(coder: NSCoder) {
        return nil
    }

    public class func currentRevision(for type: NLModel.ModelType) -> Int {
        _ = type
        return 0
    }

    public class func supportedRevisions(for type: NLModel.ModelType) -> IndexSet {
        _ = type
        return IndexSet()
    }
}
