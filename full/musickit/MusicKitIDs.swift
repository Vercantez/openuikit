import Foundation

@frozen public struct MusicItemID: Hashable, Sendable, Codable, RawRepresentable,
    ExpressibleByStringLiteral, CustomStringConvertible
{
    public typealias RawValue = String
    public typealias StringLiteralType = String
    public typealias UnicodeScalarLiteralType = String
    public typealias ExtendedGraphemeClusterLiteralType = String

    public let rawValue: String

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(stringLiteral value: String) {
        self.rawValue = value
    }

    public init(unicodeScalarLiteral value: String) {
        self.rawValue = value
    }

    public init(extendedGraphemeClusterLiteral value: String) {
        self.rawValue = value
    }

    public var description: String { rawValue }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let value = try? container.decode(String.self) {
            rawValue = value
            return
        }
        if let keyed = try? decoder.container(keyedBy: CodingKeys.self) {
            rawValue = try keyed.decode(String.self, forKey: .rawValue)
            return
        }
        throw DecodingError.dataCorruptedError(
            in: container,
            debugDescription: "MusicItemID expects a string"
        )
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(rawValue)
    }

    private enum CodingKeys: String, CodingKey { case rawValue }
}

public struct Artwork: Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
    public let maximumWidth: Int
    public let maximumHeight: Int
    public let alternateText: String?
    public let backgroundColor: CGColor?
    public let primaryTextColor: CGColor?
    public let secondaryTextColor: CGColor?
    public let tertiaryTextColor: CGColor?
    public let quaternaryTextColor: CGColor?

    let urlTemplate: String?

    public init(
        urlTemplate: String?,
        maximumWidth: Int,
        maximumHeight: Int,
        alternateText: String? = nil,
        backgroundColor: CGColor? = nil,
        primaryTextColor: CGColor? = nil,
        secondaryTextColor: CGColor? = nil,
        tertiaryTextColor: CGColor? = nil,
        quaternaryTextColor: CGColor? = nil
    ) {
        self.urlTemplate = urlTemplate
        self.maximumWidth = maximumWidth
        self.maximumHeight = maximumHeight
        self.alternateText = alternateText
        self.backgroundColor = backgroundColor
        self.primaryTextColor = primaryTextColor
        self.secondaryTextColor = secondaryTextColor
        self.tertiaryTextColor = tertiaryTextColor
        self.quaternaryTextColor = quaternaryTextColor
    }

    public func url(width: Int, height: Int) -> URL? {
        guard let urlTemplate, !urlTemplate.isEmpty else { return nil }
        let w = max(1, width)
        let h = max(1, height)
        var filled = urlTemplate
        filled = filled.replacingOccurrences(of: "{w}", with: String(w))
        filled = filled.replacingOccurrences(of: "{h}", with: String(h))
        filled = filled.replacingOccurrences(of: "{c}", with: "bb")
        filled = filled.replacingOccurrences(of: "{f}", with: "jpg")
        return URL(string: filled)
    }

    public var description: String {
        urlTemplate ?? "Artwork(\(maximumWidth)x\(maximumHeight))"
    }

    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        urlTemplate = try container.decodeIfPresent(String.self, forKey: .url)
        maximumWidth = try container.decodeIfPresent(Int.self, forKey: .width) ?? 0
        maximumHeight = try container.decodeIfPresent(Int.self, forKey: .height) ?? 0
        alternateText = try container.decodeIfPresent(String.self, forKey: .text)
            ?? container.decodeIfPresent(String.self, forKey: .altText)
        backgroundColor = MusicKitJSON.hexColor(try container.decodeIfPresent(String.self, forKey: .bgColor))
        primaryTextColor = MusicKitJSON.hexColor(try container.decodeIfPresent(String.self, forKey: .textColor1))
        secondaryTextColor = MusicKitJSON.hexColor(try container.decodeIfPresent(String.self, forKey: .textColor2))
        tertiaryTextColor = MusicKitJSON.hexColor(try container.decodeIfPresent(String.self, forKey: .textColor3))
        quaternaryTextColor = MusicKitJSON.hexColor(try container.decodeIfPresent(String.self, forKey: .textColor4))
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(urlTemplate, forKey: .url)
        try container.encode(maximumWidth, forKey: .width)
        try container.encode(maximumHeight, forKey: .height)
        try container.encodeIfPresent(alternateText, forKey: .text)
    }

    private enum CodingKeys: String, CodingKey {
        case url, width, height, text, altText
        case bgColor, textColor1, textColor2, textColor3, textColor4
    }
}

public enum ContentRating: Hashable, Sendable, Codable {
    case clean
    case explicit

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self))?.lowercased() ?? ""
        switch raw {
        case "explicit": self = .explicit
        case "clean": self = .clean
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "unknown ContentRating \(raw)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .clean: try container.encode("clean")
        case .explicit: try container.encode("explicit")
        }
    }
}

public enum AudioVariant: Hashable, Sendable, Codable, CaseIterable, CustomStringConvertible {
    case dolbyAudio
    case spatialAudio
    case dolbyAtmos
    case lossyStereo
    case highResolutionLossless
    case lossless

    public typealias AllCases = [AudioVariant]
    public static var allCases: [AudioVariant] {
        [.dolbyAudio, .spatialAudio, .dolbyAtmos, .lossyStereo, .highResolutionLossless, .lossless]
    }

    public var description: String { apiName }

    var apiName: String {
        switch self {
        case .dolbyAudio: return "dolby-audio"
        case .spatialAudio: return "spatial"
        case .dolbyAtmos: return "dolby-atmos"
        case .lossyStereo: return "lossy-stereo"
        case .highResolutionLossless: return "high-resolution-lossless"
        case .lossless: return "lossless"
        }
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.singleValueContainer()
        let raw = (try? container.decode(String.self)) ?? ""
        switch raw {
        case "dolby-audio", "dolbyAudio": self = .dolbyAudio
        case "spatial", "spatialAudio": self = .spatialAudio
        case "dolby-atmos", "dolbyAtmos": self = .dolbyAtmos
        case "lossy-stereo", "lossyStereo": self = .lossyStereo
        case "high-resolution-lossless", "highResolutionLossless", "highResLossless":
            self = .highResolutionLossless
        case "lossless": self = .lossless
        default:
            throw DecodingError.dataCorruptedError(
                in: container,
                debugDescription: "unknown AudioVariant \(raw)"
            )
        }
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(apiName)
    }
}

public enum MusicPropertySource: Hashable, Sendable, Codable, CaseIterable {
    case catalog
    case library

    public typealias AllCases = [MusicPropertySource]
    public static var allCases: [MusicPropertySource] { [.catalog, .library] }
}

public enum MusicCatalogChartKind: Hashable, Sendable, Codable, CaseIterable, CustomStringConvertible {
    case mostPlayed
    case dailyGlobalTop
    case cityTop

    public typealias AllCases = [MusicCatalogChartKind]
    public static var allCases: [MusicCatalogChartKind] {
        [.mostPlayed, .dailyGlobalTop, .cityTop]
    }

    public var description: String {
        switch self {
        case .mostPlayed: return "mostPlayed"
        case .dailyGlobalTop: return "dailyGlobalTop"
        case .cityTop: return "cityTop"
        }
    }
}

public struct EditorialNotes: Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
    public let name: String?
    public let short: String?
    public let tagline: String?
    public let standard: String?

    public init(name: String? = nil, short: String? = nil, tagline: String? = nil, standard: String? = nil) {
        self.name = name
        self.short = short
        self.tagline = tagline
        self.standard = standard
    }

    public var description: String { standard ?? short ?? name ?? tagline ?? "" }
    public var debugDescription: String { description }
}

public struct PreviewAsset: Hashable, Sendable, Codable, CustomStringConvertible, CustomDebugStringConvertible {
    public let url: URL?
    public let hlsURL: URL?
    public let artwork: Artwork?

    public init(url: URL? = nil, hlsURL: URL? = nil, artwork: Artwork? = nil) {
        self.url = url
        self.hlsURL = hlsURL
        self.artwork = artwork
    }

    public var description: String { url?.absoluteString ?? hlsURL?.absoluteString ?? "PreviewAsset" }
    public var debugDescription: String { description }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let raw = try container.decodeIfPresent(String.self, forKey: .url) {
            url = URL(string: raw)
        } else {
            url = nil
        }
        if let raw = try container.decodeIfPresent(String.self, forKey: .hlsURL) {
            hlsURL = URL(string: raw)
        } else {
            hlsURL = nil
        }
        artwork = try container.decodeIfPresent(Artwork.self, forKey: .artwork)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encodeIfPresent(url, forKey: .url)
        try container.encodeIfPresent(hlsURL, forKey: .hlsURL)
        try container.encodeIfPresent(artwork, forKey: .artwork)
    }

    private enum CodingKeys: String, CodingKey { case url, hlsURL, artwork }
}

public struct PlayParameters: Hashable, Sendable, Codable {
    let payload: [String: String]

    public init(id: MusicItemID? = nil, kind: String? = nil) {
        var payload: [String: String] = [:]
        if let id { payload["id"] = id.rawValue }
        if let kind { payload["kind"] = kind }
        self.payload = payload
    }

    public init(from decoder: any Decoder) throws {
        if let keyed = try? decoder.container(keyedBy: DynamicKey.self) {
            var payload: [String: String] = [:]
            for key in keyed.allKeys {
                if let value = try? keyed.decode(String.self, forKey: key) {
                    payload[key.stringValue] = value
                } else if let value = try? keyed.decode(Int.self, forKey: key) {
                    payload[key.stringValue] = String(value)
                } else if let value = try? keyed.decode(Bool.self, forKey: key) {
                    payload[key.stringValue] = value ? "true" : "false"
                }
            }
            self.payload = payload
            return
        }
        payload = [:]
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: DynamicKey.self)
        for (key, value) in payload {
            try container.encode(value, forKey: DynamicKey(stringValue: key)!)
        }
    }

    struct DynamicKey: CodingKey {
        var stringValue: String
        var intValue: Int? { nil }
        init?(stringValue: String) { self.stringValue = stringValue }
        init?(intValue: Int) { nil }
    }
}

public enum MusicAuthorization {
    public enum Status: String, Hashable, Sendable, CustomStringConvertible {
        case notDetermined
        case denied
        case restricted
        case authorized

        public typealias RawValue = String
        public var description: String { rawValue }
    }

    private static var _status: Status = .notDetermined

    public static var currentStatus: Status {
        _status
    }

    public static func request() async -> Status {
        _status = .denied
        return _status
    }

    /// OpenUIKit host SPI. Not an Apple API.
    public static func _openuikit_setCurrentStatus(_ status: Status) {
        _status = status
    }
}

public struct MusicTokenRequestOptions: OptionSet, Hashable, Sendable,
    ExpressibleByArrayLiteral
{
    public typealias RawValue = Int
    public typealias ArrayLiteralElement = MusicTokenRequestOptions
    public typealias Element = MusicTokenRequestOptions

    public let rawValue: Int

    public init(rawValue: Int) {
        self.rawValue = rawValue
    }

    public static let ignoreCache = MusicTokenRequestOptions(rawValue: 1 << 0)
}

public enum MusicTokenRequestError: String, Error, Sendable, LocalizedError, CustomStringConvertible {
    case userTokenRevoked
    case userTokenRequestFailed
    case developerTokenRequestFailed
    case userNotSignedIn
    case permissionDenied
    case privacyAcknowledgementRequired
    case unknown

    public typealias RawValue = String
    public var description: String { rawValue }
    public var errorDescription: String? { rawValue }
    public var failureReason: String? { rawValue }
    public var recoverySuggestion: String? { nil }
    public var helpAnchor: String? { nil }
}
