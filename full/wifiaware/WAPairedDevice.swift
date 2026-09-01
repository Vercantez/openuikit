import Foundation

/// A known Wi-Fi Aware device that an app can connect to.
///
/// Linux has no pairing store. ``allDevices`` and ``allDevices(matching:)``
/// still return sequences, but ``DevicesSequence/current()`` and iteration
/// throw ``WAError/wifiAwareUnsupported(_:)``. Devices themselves are
/// system-produced; the public constructor in the exact graph is `init(from:)`.
public struct WAPairedDevice: Sendable, Hashable, Identifiable, Codable, CustomStringConvertible {
    public typealias ID = UInt64
    public typealias Devices = [ID: WAPairedDevice]

    public let id: ID
    public let name: String?
    public let pairingInfo: PairingInfo?

    public var description: String {
        let displayName = name ?? "unnamed"
        return "WAPairedDevice(\(id), \(displayName))"
    }

    public static var allDevices: DevicesSequence {
        DevicesSequence(matching: nil)
    }

    public static func allDevices(matching: Predicate<WAPairedDevice>) -> DevicesSequence {
        DevicesSequence(matching: matching)
    }

    public struct PairingInfo: Sendable, Hashable, Codable, CustomStringConvertible {
        public let pairingName: String
        public let vendorName: String
        public let modelName: String

        public var description: String {
            "WAPairedDevice.PairingInfo(\(pairingName), \(vendorName), \(modelName))"
        }
    }

    /// A sequence that would vend pairing-store snapshots on Apple platforms.
    ///
    /// On Linux the sequence never yields a snapshot: reading it reports that
    /// Wi-Fi Aware is unsupported rather than fabricating an empty pairing
    /// database that could be mistaken for a successful query.
    public struct DevicesSequence: AsyncSequence, Sendable {
        public typealias Element = Devices
        public typealias Failure = Error

        let matching: Predicate<WAPairedDevice>?

        public func makeAsyncIterator() -> AsyncIterator {
            AsyncIterator()
        }

        public func current() async throws -> Element? {
            throw wiFiAwareUnsupportedError()
        }

        public final class AsyncIterator: AsyncIteratorProtocol, @unchecked Sendable {
            public typealias Element = Devices
            public typealias Failure = Error

            public func next() async throws -> Element? {
                throw wiFiAwareUnsupportedError()
            }
        }
    }
}
