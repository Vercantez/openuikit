import Foundation

/// The process-local Shazam library. Linux has no iCloud/media-library
/// daemon, so `items` is empty and mutations throw
/// ``SHError/Code-swift.enum/mediaLibrarySyncFailed``.
public final class SHLibrary: @unchecked Sendable {
    public static let `default` = SHLibrary()

    public var items: [SHMediaItem] { [] }

    private init() {}

    public func addItems(_ items: [SHMediaItem]) async throws {
        _ = items
        throw SHError(.mediaLibrarySyncFailed)
    }

    public func removeItems(_ items: [SHMediaItem]) async throws {
        _ = items
        throw SHError(.mediaLibrarySyncFailed)
    }
}

/// Deprecated Apple library surface. Mutations fail closed with the same
/// library-sync error. Prefer ``SHLibrary``.
public class SHMediaLibrary: NSObject {
    public static let `default`: SHMediaLibrary = SHMediaLibrary()

    private override init() {
        super.init()
    }

    public func add(_ mediaItems: [SHMediaItem]) async throws {
        _ = mediaItems
        throw SHError(.mediaLibrarySyncFailed)
    }
}

extension SHMediaItem {
    /// Apple's catalog lookup. Linux has no Shazam network service.
    public class func fetch(shazamID: String) async throws -> SHMediaItem {
        _ = shazamID
        throw SHError(.mediaItemFetchFailed)
    }
}
