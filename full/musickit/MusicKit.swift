import Foundation

/// Linux starting point for Apple's public `MusicKit` module (iPhoneOS 26.1).
///
/// Catalog, library, subscription, token, and hardware playback paths are
/// fail-closed. Value types, request builders, artwork URL templating, JSON
/// resource parsing, and the in-process player state machine are real.
public enum MusicKitPortableError: Error, Equatable, Sendable, CustomStringConvertible {
    case catalogUnavailable
    case libraryUnavailable
    case subscriptionUnavailable
    case playbackUnavailable
    case tokenUnavailable
    case authorizationDenied

    public var description: String {
        switch self {
        case .catalogUnavailable:
            return "Apple Music catalog is unavailable on this host"
        case .libraryUnavailable:
            return "Apple Music library is unavailable on this host"
        case .subscriptionUnavailable:
            return "Apple Music subscription is unavailable on this host"
        case .playbackUnavailable:
            return "Apple Music playback hardware is unavailable on this host"
        case .tokenUnavailable:
            return "Apple Music developer/user tokens are unavailable on this host"
        case .authorizationDenied:
            return "Music library authorization is denied on this host"
        }
    }
}

enum MusicKitJSON {
    struct FlexibleKey: CodingKey {
        var stringValue: String
        var intValue: Int?
        init(_ string: String) {
            stringValue = string
            intValue = nil
        }
        init?(stringValue: String) {
            self.stringValue = stringValue
            intValue = nil
        }
        init?(intValue: Int) {
            self.stringValue = String(intValue)
            self.intValue = intValue
        }
    }

    static func decodeDate(_ raw: String?) -> Date? {
        guard let raw, !raw.isEmpty else { return nil }
        if let t = ISO8601DateFormatter().date(from: raw) {
            return t
        }
        let day = DateFormatter()
        day.locale = Locale(identifier: "en_US_POSIX")
        day.timeZone = TimeZone(secondsFromGMT: 0)
        day.dateFormat = "yyyy-MM-dd"
        return day.date(from: raw)
    }

    static func hexColor(_ hex: String?) -> CGColor? {
        guard var hex, !hex.isEmpty else { return nil }
        if hex.hasPrefix("#") { hex.removeFirst() }
        guard hex.count == 6, let value = Int(hex, radix: 16) else { return nil }
        let r = CGFloat((value >> 16) & 0xFF) / 255
        let g = CGFloat((value >> 8) & 0xFF) / 255
        let b = CGFloat(value & 0xFF) / 255
        return CGColor(red: r, green: g, blue: b, alpha: 1)
    }

    static func resultsContainer(from decoder: any Decoder) throws -> KeyedDecodingContainer<FlexibleKey> {
        let root = try decoder.container(keyedBy: FlexibleKey.self)
        if root.contains(FlexibleKey("results")) {
            return try root.nestedContainer(keyedBy: FlexibleKey.self, forKey: FlexibleKey("results"))
        }
        return root
    }

    static func decodeCollection<T: Decodable & MusicItem & Hashable>(
        _ container: KeyedDecodingContainer<FlexibleKey>,
        keys: String...
    ) -> MusicItemCollection<T> {
        for key in keys {
            if let value = try? container.decode(MusicItemCollection<T>.self, forKey: FlexibleKey(key)) {
                return value
            }
        }
        return MusicItemCollection([])
    }

    static func encodeCollection<T: Encodable & MusicItem & Hashable>(
        _ collection: MusicItemCollection<T>,
        into container: inout KeyedEncodingContainer<FlexibleKey>,
        key: String
    ) throws {
        try container.encode(collection, forKey: FlexibleKey(key))
    }
}
