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
    private let labels: [String: String]

    private init(configuration: NLModelConfiguration, labels: [String: String]) {
        self.storedConfiguration = configuration
        self.labels = labels
        super.init()
    }

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOfURL: url)
    }

    public convenience init(contentsOfURL url: URL) throws {
        let payload: Data
        do {
            payload = try Data(contentsOf: url)
        } catch {
            throw NLLinuxSupport.error(
                "NLModel Apple Create ML packages are unavailable on this host"
            )
        }
        let decoded = try NLModel.decode(payload)
        self.init(configuration: decoded.configuration, labels: decoded.labels)
    }

    public func predictedLabel(for string: String) -> String? {
        labels[string]
    }

    public func predictedLabels(forTokens tokens: [String]) -> [String] {
        tokens.map { labels[$0] ?? "" }
    }

    public func predictedLabelHypotheses(
        for string: String,
        maximumCount maxCount: Int
    ) -> [String: Double] {
        guard maxCount > 0, let label = labels[string] else { return [:] }
        return [label: 1.0]
    }

    public func predictedLabelHypotheses(
        forTokens tokens: [String],
        maximumCount maxCount: Int
    ) -> [[String: Double]] {
        tokens.map { token in
            guard maxCount > 0, let label = labels[token] else { return [:] }
            return [label: 1.0]
        }
    }

    private static func decode(
        _ data: Data
    ) throws -> (configuration: NLModelConfiguration, labels: [String: String]) {
        let object: Any
        do {
            object = try JSONSerialization.jsonObject(with: data)
        } catch {
            throw NLLinuxSupport.error(
                "NLModel Apple Create ML packages are unavailable on this host"
            )
        }
        guard
            let root = object as? [String: Any],
            intValue(root["nlModelFormat"]) == 1,
            let type = ModelType(rawValue: intValue(root["type"]) ?? -1)
        else {
            throw NLLinuxSupport.error(
                "NLModel file is not the Linux JSON model format"
            )
        }
        var labels: [String: String] = [:]
        if let rawLabels = root["labels"] as? [String: String] {
            labels = rawLabels
        } else if let rawLabels = root["labels"] as? [String: Any] {
            for (key, value) in rawLabels {
                guard let text = value as? String else {
                    throw NLLinuxSupport.error("NLModel label for \(key) is not a string")
                }
                labels[key] = text
            }
        } else {
            throw NLLinuxSupport.error("NLModel labels dictionary is missing")
        }
        let language = (root["language"] as? String).map(NLLanguage.init(rawValue:))
        let revision = intValue(root["revision"]) ?? 0
        let configuration = NLModelConfiguration(
            type: type,
            language: language,
            revision: revision
        )
        return (configuration, labels)
    }

    private static func intValue(_ value: Any?) -> Int? {
        if let number = value as? Int { return number }
        if let number = value as? NSNumber { return number.intValue }
        return nil
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
