/// Portable Linux starting point for Apple's public `FileProvider` module.
///
/// Local value types, item metadata, enumerators, placeholder helpers, and a
/// process-local domain registry are real. Apple's File Provider daemon,
/// application-extension host, XPC services, and privacy-gated user-visible
/// URLs are fail-closed: they return typed `NSFileProviderError` values and
/// never fabricate a successful Apple Files.app or iCloud Desktop experience.
///
/// CoreGraphics is a declared seed dependency because thumbnail APIs take
/// `CGSize`. Linux Foundation already vends `CGSize`, so this module does not
/// import `CoreGraphics` (the host gate does not pass that product).
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
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
    /// Posted after the process-local domain registry changes.
    public static let fileProviderDomainDidChange = Notification.Name(
        "NSFileProviderDomainDidChange"
    )

    /// Posted when a materialized-set enumerator would have changed on Apple.
    /// Linux never hosts a materialized set, so this name exists for identity
    /// only and is not posted by the portable manager.
    public static let fileProviderMaterializedSetDidChange = Notification.Name(
        "NSFileProviderMaterializedSetDidChange"
    )

    /// Posted when a pending-set enumerator would have changed on Apple.
    /// Linux never hosts a pending set, so this name exists for identity only.
    public static let fileProviderPendingSetDidChange = Notification.Name(
        "NSFileProviderPendingSetDidChange"
    )
}

/// Name of an `NSFileProviderService` advertised by a provider.
public struct NSFileProviderServiceName: RawRepresentable, Hashable, Sendable {
    public let rawValue: String

    public init(rawValue: String) {
        self.rawValue = rawValue
    }

    public init(_ rawValue: String) {
        self.rawValue = rawValue
    }
}

/// Portable stand-in for Foundation's Apple-only `NSFileProviderService`.
open class NSFileProviderService: NSObject, @unchecked Sendable {
    public let name: NSFileProviderServiceName

    public init(name: NSFileProviderServiceName) {
        self.name = name
        super.init()
    }
}

/// Linux has no XPC listener runtime. Service-source signatures still compile
/// against this inert endpoint type and fail closed when asked to activate.
open class NSXPCListenerEndpoint: NSObject, NSSecureCoding, @unchecked Sendable {
    public static var supportsSecureCoding: Bool { true }

    public override init() {
        super.init()
    }

    public required init?(coder: NSCoder) {
        return nil
    }

    public func encode(with coder: NSCoder) {}
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
