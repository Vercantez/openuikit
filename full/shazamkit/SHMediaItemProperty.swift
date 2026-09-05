import Foundation

/// A typed media-item dictionary key. Raw values are the ObjC constant names
/// (`SHMediaItemTitle`, …). Apple's exact CFString bytes are unobserved.
public struct SHMediaItemProperty: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public static let shazamID = SHMediaItemProperty("SHMediaItemShazamID")
    public static let title = SHMediaItemProperty("SHMediaItemTitle")
    public static let subtitle = SHMediaItemProperty("SHMediaItemSubtitle")
    public static let artist = SHMediaItemProperty("SHMediaItemArtist")
    public static let webURL = SHMediaItemProperty("SHMediaItemWebURL")
    public static let appleMusicID = SHMediaItemProperty("SHMediaItemAppleMusicID")
    public static let appleMusicURL = SHMediaItemProperty("SHMediaItemAppleMusicURL")
    public static let artworkURL = SHMediaItemProperty("SHMediaItemArtworkURL")
    public static let videoURL = SHMediaItemProperty("SHMediaItemVideoURL")
    public static let explicitContent = SHMediaItemProperty("SHMediaItemExplicitContent")
    public static let genres = SHMediaItemProperty("SHMediaItemGenres")
    public static let ISRC = SHMediaItemProperty("SHMediaItemISRC")
    public static let matchOffset = SHMediaItemProperty("SHMediaItemMatchOffset")
    public static let frequencySkew = SHMediaItemProperty("SHMediaItemFrequencySkew")
    public static let timeRanges = SHMediaItemProperty("SHMediaItemTimeRanges")
    public static let frequencySkewRanges = SHMediaItemProperty("SHMediaItemFrequencySkewRanges")
    public static let creationDate = SHMediaItemProperty("SHMediaItemCreationDate")
    public static let confidence = SHMediaItemProperty("SHMediaItemConfidence")

    public static func != (lhs: SHMediaItemProperty, rhs: SHMediaItemProperty) -> Bool {
        lhs.rawValue != rhs.rawValue
    }
}
