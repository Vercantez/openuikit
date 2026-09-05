import Foundation

/// Metadata that describes a reference or matched track.
///
/// Properties are stored locally. Remote fetch always throws
/// ``SHError/Code-swift.enum/mediaItemFetchFailed``. `songs` requires MusicKit
/// and is not part of this Foundation-only seed.
public class SHMediaItem: NSObject, NSSecureCoding, Identifiable {
    public typealias ID = UUID

    public static var supportsSecureCoding: Bool { false }

    public let id: UUID
    internal let storedProperties: [SHMediaItemProperty: Any]

    public convenience init(properties: [SHMediaItemProperty: Any]) {
        self.init(identifier: UUID(), properties: properties)
    }

    internal init(identifier: UUID, properties: [SHMediaItemProperty: Any]) {
        self.id = identifier
        self.storedProperties = properties
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}

    public subscript(key: SHMediaItemProperty) -> Any {
        storedProperties[key] ?? NSNull()
    }

    public var shazamID: String? { stringValue(.shazamID) }
    public var title: String? { stringValue(.title) }
    public var subtitle: String? { stringValue(.subtitle) }
    public var artist: String? { stringValue(.artist) }
    public var appleMusicID: String? { stringValue(.appleMusicID) }
    public var isrc: String? { stringValue(.ISRC) }

    public var webURL: URL? { urlValue(.webURL) }
    public var appleMusicURL: URL? { urlValue(.appleMusicURL) }
    public var artworkURL: URL? { urlValue(.artworkURL) }
    public var videoURL: URL? { urlValue(.videoURL) }

    public var creationDate: Date? {
        storedProperties[.creationDate] as? Date
    }

    public var explicitContent: Bool {
        if let flag = storedProperties[.explicitContent] as? Bool {
            return flag
        }
        if let number = storedProperties[.explicitContent] as? NSNumber {
            return number.boolValue
        }
        return false
    }

    public var genres: [String] {
        if let values = storedProperties[.genres] as? [String] {
            return values
        }
        if let value = storedProperties[.genres] as? String {
            return [value]
        }
        return []
    }

    public var timeRanges: [Range<TimeInterval>] {
        storedProperties[.timeRanges] as? [Range<TimeInterval>] ?? []
    }

    public var frequencySkewRanges: [Range<Float>] {
        storedProperties[.frequencySkewRanges] as? [Range<Float>] ?? []
    }

    private func stringValue(_ key: SHMediaItemProperty) -> String? {
        if let value = storedProperties[key] as? String {
            return value
        }
        return nil
    }

    private func urlValue(_ key: SHMediaItemProperty) -> URL? {
        if let url = storedProperties[key] as? URL {
            return url
        }
        if let text = storedProperties[key] as? String {
            return URL(string: text)
        }
        return nil
    }

    internal func propertyMap() -> [SHMediaItemProperty: Any] {
        storedProperties
    }
}

/// A media item produced by a match, with alignment metrics.
public class SHMatchedMediaItem: SHMediaItem {
    private let storedFrequencySkew: Float
    private let storedMatchOffset: TimeInterval
    private let storedConfidence: Float
    private let matchDate: Date

    public var frequencySkew: Float { storedFrequencySkew }
    public var matchOffset: TimeInterval { storedMatchOffset }
    public var confidence: Float { storedConfidence }

    /// `matchOffset` plus elapsed time since the match was recorded.
    public var predictedCurrentMatchOffset: TimeInterval {
        storedMatchOffset + Date().timeIntervalSince(matchDate)
    }

    internal init(
        identifier: UUID = UUID(),
        properties: [SHMediaItemProperty: Any],
        frequencySkew: Float,
        matchOffset: TimeInterval,
        confidence: Float,
        matchDate: Date = Date()
    ) {
        self.storedFrequencySkew = frequencySkew
        self.storedMatchOffset = matchOffset
        self.storedConfidence = confidence
        self.matchDate = matchDate
        super.init(identifier: identifier, properties: properties)
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    internal convenience init(from item: SHMediaItem) {
        let properties = item.propertyMap()
        let skew = SHMatchedMediaItem.floatValue(properties[.frequencySkew])
        let offset = SHMatchedMediaItem.timeValue(properties[.matchOffset])
        let confidence = SHMatchedMediaItem.floatValue(properties[.confidence])
        self.init(
            identifier: item.id,
            properties: properties,
            frequencySkew: skew,
            matchOffset: offset,
            confidence: confidence
        )
    }

    private static func floatValue(_ value: Any?) -> Float {
        if let number = value as? Float { return number }
        if let number = value as? Double { return Float(number) }
        if let number = value as? NSNumber { return number.floatValue }
        return 0
    }

    private static func timeValue(_ value: Any?) -> TimeInterval {
        if let number = value as? TimeInterval { return number }
        if let number = value as? Float { return TimeInterval(number) }
        if let number = value as? NSNumber { return number.doubleValue }
        return 0
    }
}

/// A catalog match: the query signature plus aligned media items.
public class SHMatch: NSObject, NSSecureCoding {
    public static var supportsSecureCoding: Bool { false }

    public let mediaItems: [SHMatchedMediaItem]
    public let querySignature: SHSignature

    internal init(mediaItems: [SHMatchedMediaItem], querySignature: SHSignature) {
        self.mediaItems = mediaItems
        self.querySignature = querySignature
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}
}
