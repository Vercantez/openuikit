/// Portable Linux starting point for Apple's public `FileProvider` module.
///
/// Value types, errors, item/enumerator protocols, and fail-closed manager
/// and extension APIs are real. Apple's File Provider daemon, Files.app,
/// application-extension host, and XPC services are not hosted here: public
/// registration and daemon APIs throw typed `NSFileProviderError` unless a
/// Linux host installs `@_spi(OpenUIKitHost)` `FileProviderHostAdapter`.
///
/// `NSXPCListenerEndpoint` and `NSFileProviderService` are not FileProvider-owned
/// in the canonical graph. This module never vends a local type of those names.
/// When the guest Foundation / UniformTypeIdentifiers configuration is on the
/// compile path, service-source and item APIs use
/// `Foundation.NSXPCListenerEndpoint` and `UniformTypeIdentifiers.UTType`
/// directly.
#if canImport(CoreGraphics)
import CoreGraphics
#endif
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(UniformTypeIdentifiers)
import UniformTypeIdentifiers
#endif

/// Four-character Mac OS type code used by `NSFileProviderTypeAndCreator`.
public typealias OSType = UInt32

/// Apple's public File Provider error domain constant.
public let NSFileProviderErrorDomain = "NSFileProviderErrorDomain"

/// User-info key for the colliding item in a filename-collision error.
public let NSFileProviderErrorCollidingItemKey = "NSFileProviderErrorCollidingItemKey"

/// User-info key for the item attached to a File Provider error.
public let NSFileProviderErrorItemKey = "NSFileProviderErrorItemKey"

/// User-info key for a missing item identifier.
public let NSFileProviderErrorNonExistentItemIdentifierKey =
    "NSFileProviderErrorNonExistentItemIdentifierKey"

/// Sentinel favorite rank meaning the item is not ranked.
public let NSFileProviderFavoriteRankUnranked = UInt64.max

extension Notification.Name {
    /// Posted by an installed Linux host adapter after a domain registry change.
    /// Public manager APIs do not post this name on the fail-closed path.
    public static let fileProviderDomainDidChange = Notification.Name(
        "NSFileProviderDomainDidChange"
    )

    /// Identity of Apple's materialized-set notification. Linux never posts it.
    public static let fileProviderMaterializedSetDidChange = Notification.Name(
        "NSFileProviderMaterializedSetDidChange"
    )

    /// Identity of Apple's pending-set notification. Linux never posts it.
    public static let fileProviderPendingSetDidChange = Notification.Name(
        "NSFileProviderPendingSetDidChange"
    )
}

/// Name of a File Provider service advertised by a provider.
public struct NSFileProviderServiceName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

enum FileProviderHost {
    static let unhostedProviderIdentifier = "org.openuikit.fileprovider.unhosted"

    static func unsupported(
        _ code: NSFileProviderError.Code = .providerNotFound,
        userInfo: [String: Any] = [:]
    ) -> NSFileProviderError {
        NSFileProviderError(code, userInfo: userInfo)
    }

    static func storageRoot() -> URL {
        let base = FileManager.default.temporaryDirectory
            .appendingPathComponent("OpenUIKitFileProvider", isDirectory: true)
        try? FileManager.default.createDirectory(
            at: base,
            withIntermediateDirectories: true
        )
        return base
    }
}

enum FileProviderCallback {
    static let queue = DispatchQueue(
        label: "org.openuikit.fileprovider.callback",
        qos: .userInitiated,
        attributes: .concurrent
    )

    final class Once: @unchecked Sendable {
        private let lock = NSLock()
        private var finished = false

        func run(_ body: () -> Void) {
            lock.lock()
            let shouldRun = !finished
            if shouldRun {
                finished = true
            }
            lock.unlock()
            if shouldRun {
                body()
            }
        }
    }

    static func asyncOnce(_ once: Once, _ body: @escaping () -> Void) {
        queue.async {
            once.run(body)
        }
    }
}
