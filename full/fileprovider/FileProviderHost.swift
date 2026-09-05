import Foundation

/// Optional override for domain registry and placeholder writes. The
/// process-local host is installed by default; passing `nil` to
/// `NSFileProviderManager._installHostAdapter` restores it.
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
    nonisolated(unsafe) private static var adapter: FileProviderHostAdapter? =
        FileProviderLocalHost.shared

    static func currentAdapter() -> FileProviderHostAdapter? {
        lock.lock()
        defer { lock.unlock() }
        return adapter
    }

    static func install(_ adapter: FileProviderHostAdapter?) {
        lock.lock()
        FileProviderHostRegistry.adapter = adapter ?? FileProviderLocalHost.shared
        lock.unlock()
    }
}

extension NSFileProviderManager {
    /// Install a host adapter, or pass `nil` to restore the process-local host.
    @_spi(OpenUIKitHost)
    public static func _installHostAdapter(_ adapter: FileProviderHostAdapter?) {
        FileProviderHostRegistry.install(adapter)
    }

    /// Reset the process-local domain registry, item store, and documents tree.
    @_spi(OpenUIKitHost)
    public static func _resetLocalHostForTesting() {
        FileProviderHostRegistry.install(nil)
        FileProviderLocalHost.shared.resetForTesting()
    }

    /// The in-process replicated extension bound to this manager's domain.
    @_spi(OpenUIKitHost)
    public func _localReplicatedExtension() -> (any NSFileProviderReplicatedExtension)? {
        guard let domain = boundDomain else { return nil }
        return FileProviderLocalHost.shared.provider(for: domain)
    }

    /// Register an enumerator so `signalEnumerator(for:)` can deliver changes.
    @_spi(OpenUIKitHost)
    public func _registerWorkingEnumerator(
        _ enumerator: any NSFileProviderEnumerator,
        for containerItemIdentifier: NSFileProviderItemIdentifier
    ) {
        guard let domain = boundDomain,
            let local = enumerator as? FileProviderLocalEnumerator
        else {
            return
        }
        FileProviderLocalHost.shared.registerEnumerator(
            local,
            domain: domain,
            container: containerItemIdentifier
        )
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
