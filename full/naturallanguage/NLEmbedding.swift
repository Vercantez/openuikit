import Foundation

public final class NLEmbedding: NSObject {
    public let dimension: Int
    public let language: NLLanguage?
    public let revision: Int
    public let vocabularySize: Int
    private let vectors: [String: [Double]]

    public convenience init(contentsOf url: URL) throws {
        try self.init(contentsOfURL: url)
    }

    public convenience init(contentsOfURL url: URL) throws {
        let payload = try Data(contentsOf: url)
        let decoded = try NLEmbedding.decode(payload)
        self.init(
            vectors: decoded.vectors,
            language: decoded.language,
            revision: decoded.revision
        )
    }

    private init(
        vectors: [String: [Double]],
        language: NLLanguage?,
        revision: Int
    ) {
        self.vectors = vectors
        self.language = language
        self.revision = revision
        self.vocabularySize = vectors.count
        self.dimension = vectors.values.first?.count ?? 0
        super.init()
    }

    public class func wordEmbedding(for language: NLLanguage) -> NLEmbedding? {
        nil
    }

    public class func wordEmbedding(
        for language: NLLanguage,
        revision: Int
    ) -> NLEmbedding? {
        nil
    }

    public class func sentenceEmbedding(for language: NLLanguage) -> NLEmbedding? {
        nil
    }

    public class func sentenceEmbedding(
        for language: NLLanguage,
        revision: Int
    ) -> NLEmbedding? {
        nil
    }

    public class func currentRevision(for language: NLLanguage) -> Int {
        0
    }

    public class func currentSentenceEmbeddingRevision(for language: NLLanguage) -> Int {
        0
    }

    public class func supportedRevisions(for language: NLLanguage) -> IndexSet {
        IndexSet()
    }

    public class func supportedSentenceEmbeddingRevisions(
        for language: NLLanguage
    ) -> IndexSet {
        IndexSet()
    }

    public class func write(
        _ dictionary: [String: [Double]],
        language: NLLanguage?,
        revision: Int,
        to url: URL
    ) throws {
        guard let first = dictionary.values.first else {
            throw NLLinuxSupport.error("NLEmbedding dictionary is empty")
        }
        let dimension = first.count
        guard dimension > 0, dictionary.values.allSatisfy({ $0.count == dimension }) else {
            throw NLLinuxSupport.error("NLEmbedding vectors must share a positive dimension")
        }
        let object: [String: Any] = [
            "nlEmbeddingFormat": 1,
            "language": language.map(\.rawValue) as Any? ?? NSNull(),
            "revision": revision,
            "dimension": dimension,
            "vectors": dictionary,
        ]
        let payload = try JSONSerialization.data(
            withJSONObject: object,
            options: [.sortedKeys]
        )
        try payload.write(to: url, options: .atomic)
    }

    public func contains(_ string: String) -> Bool {
        vectors[string] != nil
    }

    public func vector(for string: String) -> [Double]? {
        vectors[string]
    }

    public func distance(
        between firstString: String,
        and secondString: String,
        distanceType: NLDistanceType = .cosine
    ) -> NLDistance {
        guard let lhs = vectors[firstString], let rhs = vectors[secondString] else {
            return 2
        }
        switch distanceType {
        case .cosine:
            return cosineDistance(lhs, rhs)
        }
    }

    public func neighbors(
        for string: String,
        maximumCount maxCount: Int,
        distanceType: NLDistanceType = .cosine
    ) -> [(String, NLDistance)] {
        guard let vector = vectors[string] else { return [] }
        return neighbors(for: vector, maximumCount: maxCount, distanceType: distanceType)
            .filter { $0.0 != string }
    }

    public func neighbors(
        for vector: [Double],
        maximumCount maxCount: Int,
        distanceType: NLDistanceType = .cosine
    ) -> [(String, NLDistance)] {
        guard maxCount > 0, vector.count == dimension else { return [] }
        var ranked: [(String, NLDistance)] = []
        ranked.reserveCapacity(vectors.count)
        for (word, candidate) in vectors {
            ranked.append((word, cosineDistance(vector, candidate)))
        }
        ranked.sort {
            $0.1 == $1.1 ? $0.0 < $1.0 : $0.1 < $1.1
        }
        return Array(ranked.prefix(maxCount))
    }

    public func enumerateNeighbors(
        for string: String,
        maximumCount maxCount: Int,
        distanceType: NLDistanceType = .cosine,
        using block: (String, NLDistance) -> Bool
    ) {
        for neighbor in neighbors(
            for: string,
            maximumCount: maxCount,
            distanceType: distanceType
        ) {
            if !block(neighbor.0, neighbor.1) { return }
        }
    }

    public func enumerateNeighbors(
        for vector: [Double],
        maximumCount maxCount: Int,
        distanceType: NLDistanceType = .cosine,
        using block: (String, NLDistance) -> Bool
    ) {
        for neighbor in neighbors(
            for: vector,
            maximumCount: maxCount,
            distanceType: distanceType
        ) {
            if !block(neighbor.0, neighbor.1) { return }
        }
    }

    private func cosineDistance(_ lhs: [Double], _ rhs: [Double]) -> Double {
        var dot = 0.0
        var lhsMagnitude = 0.0
        var rhsMagnitude = 0.0
        for index in lhs.indices {
            dot += lhs[index] * rhs[index]
            lhsMagnitude += lhs[index] * lhs[index]
            rhsMagnitude += rhs[index] * rhs[index]
        }
        guard lhsMagnitude > 0, rhsMagnitude > 0 else { return 2 }
        let similarity = dot / (lhsMagnitude.squareRoot() * rhsMagnitude.squareRoot())
        return max(0, min(2, 1 - similarity))
    }

    private static func decode(
        _ data: Data
    ) throws -> (
        vectors: [String: [Double]],
        language: NLLanguage?,
        revision: Int
    ) {
        let object = try JSONSerialization.jsonObject(with: data)
        guard
            let root = object as? [String: Any],
            root["nlEmbeddingFormat"] as? Int == 1,
            let rawVectors = root["vectors"] as? [String: [Any]]
        else {
            throw NLLinuxSupport.error(
                "NLEmbedding file is not the Linux JSON embedding format"
            )
        }
        var vectors: [String: [Double]] = [:]
        for (word, values) in rawVectors {
            let numbers = values.compactMap { value -> Double? in
                if let number = value as? Double { return number }
                if let number = value as? Int { return Double(number) }
                if let number = value as? NSNumber { return number.doubleValue }
                return nil
            }
            guard numbers.count == values.count else {
                throw NLLinuxSupport.error("NLEmbedding vector for \(word) is not numeric")
            }
            vectors[word] = numbers
        }
        let language = (root["language"] as? String).map(NLLanguage.init(rawValue:))
        let revision = root["revision"] as? Int ?? 0
        return (vectors, language, revision)
    }
}
