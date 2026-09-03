import Foundation

/// A known Wi-Fi Aware device that an app can connect to.
///
/// Linux has no pairing store. `allDevices` vends one empty snapshot and then
/// finishes. Instances exist only through public `Codable` (or host SPI).
public struct WAPairedDevice: Sendable, Identifiable, Hashable, Codable,
    CustomStringConvertible
{
    public typealias ID = UInt64
    public typealias Devices = [ID: WAPairedDevice]

    public let id: ID
    public let name: String?
    public let pairingInfo: PairingInfo?

    public var description: String {
        var parts = ["id: \(id)"]
        if let name {
            parts.append("name: \(name)")
        }
        if pairingInfo != nil {
            parts.append("pairingInfo: present")
        }
        return "WAPairedDevice(\(parts.joined(separator: ", ")))"
    }

    enum CodingKeys: String, CodingKey {
        case id
        case name
        case pairingInfo
    }

    public init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(ID.self, forKey: .id)
        name = try container.decodeIfPresent(String.self, forKey: .name)
        pairingInfo = try container.decodeIfPresent(PairingInfo.self, forKey: .pairingInfo)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encodeIfPresent(name, forKey: .name)
        try container.encodeIfPresent(pairingInfo, forKey: .pairingInfo)
    }

    @_spi(OpenUIKitHost)
    public init(id: ID, name: String?, pairingInfo: PairingInfo?) {
        self.id = id
        self.name = name
        self.pairingInfo = pairingInfo
    }

    /// Empty because this host has no pairing daemon.
    public static var allDevices: DevicesSequence {
        DevicesSequence(predicate: nil)
    }

    public static func allDevices(matching: Predicate<WAPairedDevice>) -> DevicesSequence {
        DevicesSequence(predicate: matching)
    }

    /// Unauthenticated information received before first pairing.
    public struct PairingInfo: Sendable, Hashable, Codable, CustomStringConvertible {
        public let pairingName: String
        public let vendorName: String
        public let modelName: String

        public var description: String {
            "WAPairedDevice.PairingInfo(pairingName: \(pairingName), vendorName: \(vendorName), modelName: \(modelName))"
        }

        enum CodingKeys: String, CodingKey {
            case pairingName
            case vendorName
            case modelName
        }

        @_spi(OpenUIKitHost)
        public init(pairingName: String, vendorName: String, modelName: String) {
            self.pairingName = pairingName
            self.vendorName = vendorName
            self.modelName = modelName
        }
    }

    /// Asynchronous snapshots of the paired-device inventory.
    ///
    /// Linux vends one empty dictionary and then returns `nil`. There is no
    /// hardware event source that could produce a later nonempty snapshot.
    public struct DevicesSequence: AsyncSequence, Sendable {
        public typealias Element = Devices
        public typealias Failure = Error

        let predicate: Predicate<WAPairedDevice>?

        public func current() async throws -> Element? {
            [:]
        }

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator()
        }

        public final class AsyncIterator: AsyncIteratorProtocol {
            public typealias Element = Devices
            public typealias Failure = Error

            private var delivered = false

            public func next() async throws -> Element? {
                if delivered {
                    return nil
                }
                delivered = true
                return [:]
            }
        }
    }
}
