import Foundation

/// Linux host adapter for File Provider daemon operations. Public manager APIs
/// fail closed unless a host installs an adapter through
/// `NSFileProviderManager._installHostAdapter`.
@_spi(OpenUIKitHost)
public protocol FileProviderHostAdapter: AnyObject {
    func addDomain(_ domain: NSFileProviderDomain) async throws
    func domains() async throws -> [NSFileProviderDomain]
    func removeDomain(_ domain: NSFileProviderDomain) async throws
    func removeDomain(
        _ domain: NSFileProviderDomain,
        mode: NSFileProviderManager.DomainRemovalMode
    ) async throws -> URL?
    func removeAllDomains() async throws
    func writePlaceholder(at url: URL, metadata: NSFileProviderItem) throws
    func writePlaceholder(at url: URL, resourceValues: [URLResourceKey: Any]) throws
}

enum FileProviderHostRegistry {
    private static let lock = NSLock()
    nonisolated(unsafe) private static var adapter: FileProviderHostAdapter?

    static func currentAdapter() -> FileProviderHostAdapter? {
        lock.lock()
        defer { lock.unlock() }
        return adapter
    }

    static func install(_ adapter: FileProviderHostAdapter?) {
        lock.lock()
        FileProviderHostRegistry.adapter = adapter
        lock.unlock()
    }
}

extension NSFileProviderManager {
    /// Install or clear the Linux host adapter. Passing `nil` restores
    /// fail-closed public manager APIs.
    @_spi(OpenUIKitHost)
    public static func _installHostAdapter(_ adapter: FileProviderHostAdapter?) {
        FileProviderHostRegistry.install(adapter)
    }

    /// Linux-only JSON sidecar used by a host adapter. This is not Apple
    /// placeholder persistence and must not be called from public APIs.
    @_spi(OpenUIKitHost)
    public class func _writeLinuxPlaceholderJSON(
        at placeholderURL: URL,
        withMetadata metadata: NSFileProviderItem
    ) throws {
        let payload: [String: String] = [
            "itemIdentifier": metadata.itemIdentifier.rawValue,
            "parentItemIdentifier": metadata.parentItemIdentifier.rawValue,
            "filename": metadata.filename,
        ]
        let data = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
        )
        try data.write(to: placeholderURL, options: .atomic)
    }

    @_spi(OpenUIKitHost)
    public class func _writeLinuxPlaceholderJSON(
        at placeholderURL: URL,
        resourceValues: [URLResourceKey: Any]
    ) throws {
        let payload = Dictionary(
            uniqueKeysWithValues: resourceValues.map { key, value in
                (key.rawValue, String(describing: value))
            }
        )
        let data = try JSONSerialization.data(
            withJSONObject: payload,
            options: [.sortedKeys]
        )
        try data.write(to: placeholderURL, options: .atomic)
    }
}
