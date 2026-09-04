import Foundation

public final class NLGazetteer: NSObject {
    public let language: NLLanguage?
    public let data: Data
    private let labelsByTerm: [String: String]
    private let dictionary: [String: [String]]

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOfURL: url)
    }

    public init(contentsOfURL url: URL) throws {
        let payload = try Data(contentsOf: url)
        let decoded = try NLGazetteer.decode(payload)
        self.language = decoded.language
        self.data = payload
        self.dictionary = decoded.dictionary
        self.labelsByTerm = NLGazetteer.index(decoded.dictionary)
        super.init()
    }

    public init(data: Data) throws {
        let decoded = try NLGazetteer.decode(data)
        self.language = decoded.language
        self.data = data
        self.dictionary = decoded.dictionary
        self.labelsByTerm = NLGazetteer.index(decoded.dictionary)
        super.init()
    }

    public init(dictionary: [String: [String]], language: NLLanguage?) throws {
        self.language = language
        self.dictionary = dictionary
        self.labelsByTerm = NLGazetteer.index(dictionary)
        self.data = try NLGazetteer.encode(dictionary, language: language)
        super.init()
    }

    public func label(for string: String) -> String? {
        labelsByTerm[string]
    }

    public class func write(
        _ dictionary: [String: [String]],
        language: NLLanguage?,
        to url: URL
    ) throws {
        let payload = try encode(dictionary, language: language)
        try payload.write(to: url, options: .atomic)
    }

    private static func index(_ dictionary: [String: [String]]) -> [String: String] {
        var result: [String: String] = [:]
        for (label, terms) in dictionary {
            for term in terms {
                if result[term] == nil {
                    result[term] = label
                }
            }
        }
        return result
    }

    private static func encode(
        _ dictionary: [String: [String]],
        language: NLLanguage?
    ) throws -> Data {
        let object: [String: Any] = [
            "nlGazetteerFormat": 1,
            "language": language.map(\.rawValue) as Any? ?? NSNull(),
            "labels": dictionary,
        ]
        return try JSONSerialization.data(withJSONObject: object, options: [.sortedKeys])
    }

    private static func decode(
        _ data: Data
    ) throws -> (dictionary: [String: [String]], language: NLLanguage?) {
        let object = try JSONSerialization.jsonObject(with: data)
        guard
            let root = object as? [String: Any],
            root["nlGazetteerFormat"] as? Int == 1,
            let labels = root["labels"] as? [String: [String]]
        else {
            throw NLLinuxSupport.error(
                "NLGazetteer file is not the Linux JSON gazetteer format"
            )
        }
        let language = (root["language"] as? String).map(NLLanguage.init(rawValue:))
        return (labels, language)
    }
}
