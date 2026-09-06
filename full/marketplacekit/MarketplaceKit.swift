@_exported import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Portable Linux starting point for Apple's public `MarketplaceKit` module.
///
/// Isolated host compilation imports Foundation (and `FoundationNetworking`
/// where Swift splits `HTTPURLResponse`). Value types, error cases, URI-scheme
/// identity, in-process `AppLibrary` state, and Codable round-trips are real.
/// Apple marketplace installation, license, transaction-reporting, age-exception
/// UI, and ExtensionKit hosts never report success: those paths throw a
/// documented `MarketplaceKitError` or return empty/inert results.
///
/// UIKit overlay types (`ActionButton`, scene delegate, confirmation results)
/// compile against module-local stand-ins when UIKit / LocalAuthentication are
/// absent. Those stand-ins are not Apple UIKit types.

/// Apple item identifier. Graph / digester alias of `UInt64`.
public typealias AppleItemID = UInt64

/// Apple version identifier. Graph / digester alias of `UInt64`.
public typealias AppleVersionID = UInt64

/// URI scheme for alternative-distribution install links.
///
/// Apple's public documentation uses `marketplace-kit://install?...` as the
/// install-link example, so the scheme string is `marketplace-kit`.
public let MarketplaceKitURIScheme: String = "marketplace-kit"

enum MarketplaceKitLinux {
    static func httpRequestFailed(_ response: HTTPURLResponse) -> Bool {
        response.statusCode >= 400
    }

    static func volumeAvailableBytes() -> UInt64? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let values = try? home.resourceValues(forKeys: [.volumeAvailableCapacityKey])
        guard let capacity = values?.volumeAvailableCapacity, capacity >= 0 else {
            return nil
        }
        return UInt64(capacity)
    }
}
