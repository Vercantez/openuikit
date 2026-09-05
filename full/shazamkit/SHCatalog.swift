import Foundation

/// A catalog of reference signatures.
///
/// The Apple Shazam catalog is not available on Linux. Base duration bounds
/// are both `0` (no query window is accepted against the remote catalog).
/// ``SHCustomCatalog`` overrides the maximum so locally stored signatures
/// can be compared by exact `dataRepresentation`.
public class SHCatalog: NSObject {
    public var minimumQuerySignatureDuration: TimeInterval { 0 }
    public var maximumQuerySignatureDuration: TimeInterval { 0 }

    internal override init() {
        super.init()
    }

    internal func match(query: SHSignature) -> SHMatch? {
        nil
    }

    internal var usesRemoteShazamService: Bool { true }
}

/// An in-process catalog of caller-supplied signatures and media items.
///
/// Serialization uses a host-local property-list envelope
/// (`OpenUIKit.SHCustomCatalog.v1`), not Apple's `.shazamcatalog` bytes.
public class SHCustomCatalog: SHCatalog {
    public static let hostFormatIdentifier = "OpenUIKit.SHCustomCatalog.v1"

    private struct Entry {
        var signatureData: Data
        var items: [SHMediaItem]
    }

    private var entries: [Entry] = []

    public override var maximumQuerySignatureDuration: TimeInterval {
        TimeInterval.greatestFiniteMagnitude
    }

    public override init() {
        super.init()
    }

    public init(dataRepresentation: Data) throws {
        super.init()
        try merge(serialized: dataRepresentation, replacing: true)
    }

    public var dataRepresentation: Data {
        let payload: [String: Any] = [
            "format": SHCustomCatalog.hostFormatIdentifier,
            "entries": entries.map { entry -> [String: Any] in
                [
                    "signature": entry.signatureData,
                    "items": entry.items.map { item in
                        SHCustomCatalog.plistItems(from: item.propertyMap())
                    },
                ]
            },
        ]
        do {
            return try PropertyListSerialization.data(
                fromPropertyList: payload,
                format: .binary,
                options: 0
            )
        } catch {
            return Data()
        }
    }

    public func addReferenceSignature(
        _ signature: SHSignature,
        representing mediaItems: [SHMediaItem]
    ) throws {
        guard !signature.dataRepresentation.isEmpty else {
            throw SHError(.signatureInvalid)
        }
        if let index = entries.firstIndex(where: { $0.signatureData == signature.dataRepresentation }) {
            entries[index].items.append(contentsOf: mediaItems)
        } else {
            entries.append(Entry(signatureData: signature.dataRepresentation, items: mediaItems))
        }
    }

    public func add(from customCatalogURL: URL) throws {
        guard customCatalogURL.isFileURL else {
            throw SHError(.customCatalogInvalidURL)
        }
        let data: Data
        do {
            data = try Data(contentsOf: customCatalogURL)
        } catch {
            throw SHError(.customCatalogInvalidURL)
        }
        try merge(serialized: data, replacing: false)
    }

    public func write(to destinationURL: URL) throws {
        guard destinationURL.isFileURL else {
            throw SHError(.customCatalogInvalidURL)
        }
        let data = dataRepresentation
        guard !data.isEmpty else {
            throw SHError(.customCatalogInvalid)
        }
        do {
            try data.write(to: destinationURL, options: .atomic)
        } catch {
            throw SHError(.customCatalogInvalidURL)
        }
    }

    override func match(query: SHSignature) -> SHMatch? {
        guard let entry = entries.first(where: { $0.signatureData == query.dataRepresentation }) else {
            return nil
        }
        let matched = entry.items.map { SHMatchedMediaItem(from: $0) }
        return SHMatch(mediaItems: matched, querySignature: query)
    }

    override var usesRemoteShazamService: Bool { false }

    private func merge(serialized data: Data, replacing: Bool) throws {
        guard !data.isEmpty else {
            throw SHError(.customCatalogInvalid)
        }
        let object: Any
        do {
            object = try PropertyListSerialization.propertyList(from: data, options: [], format: nil)
        } catch {
            throw SHError(.customCatalogInvalid)
        }
        guard
            let root = object as? [String: Any],
            let format = root["format"] as? String,
            format == SHCustomCatalog.hostFormatIdentifier,
            let rawEntries = root["entries"] as? [[String: Any]]
        else {
            throw SHError(.customCatalogInvalid)
        }
        if replacing {
            entries.removeAll()
        }
        for raw in rawEntries {
            guard let signatureData = raw["signature"] as? Data else {
                throw SHError(.customCatalogInvalid)
            }
            let itemMaps = raw["items"] as? [[String: Any]] ?? []
            let items = itemMaps.map { SHCustomCatalog.mediaItem(fromPlist: $0) }
            entries.append(Entry(signatureData: signatureData, items: items))
        }
    }

    private static func plistItems(from properties: [SHMediaItemProperty: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        for (key, value) in properties {
            if let boxed = boxPropertyValue(value) {
                result[key.rawValue] = boxed
            }
        }
        return result
    }

    private static func mediaItem(fromPlist dictionary: [String: Any]) -> SHMediaItem {
        var properties: [SHMediaItemProperty: Any] = [:]
        for (rawKey, value) in dictionary {
            let key = SHMediaItemProperty(rawValue: rawKey)
            properties[key] = unboxPropertyValue(key: key, value: value)
        }
        return SHMediaItem(properties: properties)
    }

    private static func boxPropertyValue(_ value: Any) -> Any? {
        switch value {
        case let url as URL:
            return url.absoluteString
        case let ranges as [Range<TimeInterval>]:
            return ranges.map { [$0.lowerBound, $0.upperBound] }
        case let ranges as [Range<Float>]:
            return ranges.map { [Double($0.lowerBound), Double($0.upperBound)] }
        case let string as String:
            return string
        case let flag as Bool:
            return flag
        case let date as Date:
            return date
        case let number as NSNumber:
            return number
        case let strings as [String]:
            return strings
        case let data as Data:
            return data
        default:
            return nil
        }
    }

    private static func unboxPropertyValue(key: SHMediaItemProperty, value: Any) -> Any {
        if key == .webURL || key == .appleMusicURL || key == .artworkURL || key == .videoURL {
            if let url = value as? URL {
                return url
            }
            if let text = value as? String, let url = URL(string: text) {
                return url
            }
        }
        if key == .timeRanges, let pairs = value as? [[Double]], pairs.allSatisfy({ $0.count == 2 }) {
            return pairs.map { $0[0]..<$0[1] }
        }
        if key == .frequencySkewRanges, let pairs = value as? [[Double]], pairs.allSatisfy({ $0.count == 2 }) {
            return pairs.map { Float($0[0])..<Float($0[1]) }
        }
        return value
    }
}
