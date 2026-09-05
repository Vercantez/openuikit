#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
import Foundation

/// An archive of assets that the system would download together.
public struct AssetPack: Hashable, Sendable, Identifiable, CustomStringConvertible {
    public typealias ID = String
    public typealias DecodingConfiguration = AssetPackManifest.DecodingConfiguration

    public let id: String
    public let downloadSize: Int
    public let version: Int
    public let userInfo: Data?

    let downloadURL: URL?
    let appGroupID: String

    public var description: String {
        "AssetPack(id: \(id), version: \(version), downloadSize: \(downloadSize))"
    }

    @_spi(OpenUIKitHost)
    public init(
        id: String,
        downloadSize: Int,
        version: Int,
        userInfo: Data? = nil,
        downloadURL: URL? = nil,
        appGroupID: String = ""
    ) {
        self.id = id
        self.downloadSize = downloadSize
        self.version = version
        self.userInfo = userInfo
        self.downloadURL = downloadURL
        self.appGroupID = appGroupID
    }

    public init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        if let identifier = try container.decodeIfPresent(String.self, forKey: .id) {
            id = identifier
        } else if let identifier = try container.decodeIfPresent(String.self, forKey: .identifier) {
            id = identifier
        } else {
            id = try container.decode(String.self, forKey: .assetPackID)
        }
        downloadSize = try container.decodeIfPresent(Int.self, forKey: .downloadSize) ?? 0
        version = try container.decodeIfPresent(Int.self, forKey: .version) ?? 0
        if let data = try container.decodeIfPresent(Data.self, forKey: .userInfo) {
            userInfo = data
        } else if let encoded = try container.decodeIfPresent(String.self, forKey: .userInfo),
                  let data = Data(base64Encoded: encoded)
        {
            userInfo = data
        } else {
            userInfo = nil
        }
        if let urlString = try container.decodeIfPresent(String.self, forKey: .url) {
            downloadURL = URL(string: urlString)
        } else {
            downloadURL = nil
        }
        appGroupID = configuration.appGroupID
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(downloadSize, forKey: .downloadSize)
        try container.encode(version, forKey: .version)
        try container.encodeIfPresent(userInfo, forKey: .userInfo)
        try container.encodeIfPresent(downloadURL?.absoluteString, forKey: .url)
    }

    public func download(for contentRequest: BAContentRequest?) -> BADownload {
        _ = contentRequest
        let url = downloadURL ?? URL(string: "https://invalid.invalid/\(id)")!
        return BAURLDownload(
            identifier: id,
            request: URLRequest(url: url),
            essential: false,
            fileSize: downloadSize,
            applicationGroupIdentifier: appGroupID,
            priority: .default
        )
    }

    public static func == (lhs: AssetPack, rhs: AssetPack) -> Bool {
        lhs.id == rhs.id
            && lhs.downloadSize == rhs.downloadSize
            && lhs.version == rhs.version
            && lhs.userInfo == rhs.userInfo
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
        hasher.combine(downloadSize)
        hasher.combine(version)
        hasher.combine(userInfo)
    }

    enum CodingKeys: String, CodingKey {
        case id
        case identifier
        case assetPackID
        case downloadSize
        case version
        case userInfo
        case url
    }
}

extension AssetPack {
    /// Pinned `dotnet/macios` `BAAssetPackStatus` bits.
    public struct Status: OptionSet, Hashable, Sendable {
        public let rawValue: Int

        public init(rawValue: Int) {
            self.rawValue = rawValue
        }

        public static let downloadAvailable = Status(rawValue: 1 << 0)
        public static let updateAvailable = Status(rawValue: 1 << 1)
        public static let upToDate = Status(rawValue: 1 << 2)
        public static let outOfDate = Status(rawValue: 1 << 3)
        public static let obsolete = Status(rawValue: 1 << 4)
        public static let downloading = Status(rawValue: 1 << 5)
        public static let downloaded = Status(rawValue: 1 << 6)
    }
}

/// Unmanaged asset-pack manifest. JSON keys `id` / `identifier` / `assetPackID`,
/// `downloadSize`, `version`, and optional `userInfo` / `url` are accepted.
/// Apple's exact unmanaged-manifest schema is an oracle question.
public struct AssetPackManifest: Sendable, CustomStringConvertible {
    public struct DecodingConfiguration: Sendable, CustomStringConvertible {
        public let appGroupID: String

        public init(appGroupID: String) {
            self.appGroupID = appGroupID
        }

        public var description: String {
            "DecodingConfiguration(appGroupID: \(appGroupID))"
        }
    }

    public let assetPacks: Set<AssetPack>
    let appGroupID: String

    public var description: String {
        "AssetPackManifest(assetPacks: \(assetPacks.count))"
    }

    public init(from data: Data, appGroupID: String) throws {
        let configuration = DecodingConfiguration(appGroupID: appGroupID)
        self = try JSONDecoder().decode(
            AssetPackManifest.self,
            from: data,
            configuration: configuration
        )
    }

    public init(contentsOf url: URL, appGroupID: String) throws {
        let data = try Data(contentsOf: url)
        try self.init(from: data, appGroupID: appGroupID)
    }

    public init(from decoder: any Decoder, configuration: DecodingConfiguration) throws {
        let packs: [AssetPack]
        if var unkeyed = try? decoder.unkeyedContainer() {
            var parsed: [AssetPack] = []
            while !unkeyed.isAtEnd {
                parsed.append(try unkeyed.decode(AssetPack.self, configuration: configuration))
            }
            packs = parsed
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            packs = try container.decode([AssetPack].self, forKey: .assetPacks, configuration: configuration)
        }
        assetPacks = Set(packs)
        appGroupID = configuration.appGroupID
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(Array(assetPacks), forKey: .assetPacks)
    }

    public func allDownloads(for contentRequest: BAContentRequest?) -> Set<BADownload> {
        Set(assetPacks.map { $0.download(for: contentRequest) })
    }

    enum CodingKeys: String, CodingKey {
        case assetPacks
    }
}

extension AssetPackManifest: DecodableWithConfiguration {}
extension AssetPack: DecodableWithConfiguration {}
extension AssetPack: Encodable {}
extension AssetPackManifest: Encodable {}
