import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// File Provider manager. Domain add/remove/list and daemon operations fail
/// closed unless a Linux `FileProviderHostAdapter` is installed. Public APIs
/// never post system-style success notifications on the unhosted path.
open class NSFileProviderManager: NSObject, @unchecked Sendable {
    public enum DomainRemovalMode: Int, Hashable, Sendable {
        case removeAll = 0
    }

    private static let defaultManagerStorage = NSFileProviderManager(
        providerIdentifier: FileProviderHost.unhostedProviderIdentifier,
        domain: nil
    )

    public class var `default`: NSFileProviderManager {
        defaultManagerStorage
    }

    public let providerIdentifier: String
    public let documentStorageURL: URL
    private let boundDomain: NSFileProviderDomain?

    public convenience init?(for domain: NSFileProviderDomain) {
        self.init(forDomain: domain)
    }

    public convenience init?(forDomain domain: NSFileProviderDomain) {
        guard FileProviderHostRegistry.currentAdapter() != nil else {
            return nil
        }
        self.init(
            providerIdentifier: FileProviderHost.unhostedProviderIdentifier,
            domain: domain
        )
    }

    private init(providerIdentifier: String, domain: NSFileProviderDomain?) {
        self.providerIdentifier = providerIdentifier
        self.boundDomain = domain
        let root = FileProviderHost.storageRoot()
        let relative = domain?.pathRelativeToDocumentStorage ?? "_default"
        let url = root.appendingPathComponent(relative, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        self.documentStorageURL = url
        super.init()
    }

    public class func add(_ domain: NSFileProviderDomain) async throws {
        guard let adapter = FileProviderHostRegistry.currentAdapter() else {
            throw FileProviderHost.unsupported(.providerNotFound)
        }
        try await adapter.addDomain(domain)
    }

    public class func domains() async throws -> [NSFileProviderDomain] {
        guard let adapter = FileProviderHostRegistry.currentAdapter() else {
            throw FileProviderHost.unsupported(.providerNotFound)
        }
        return try await adapter.domains()
    }

    public class func remove(_ domain: NSFileProviderDomain) async throws {
        guard let adapter = FileProviderHostRegistry.currentAdapter() else {
            throw FileProviderHost.unsupported(.providerNotFound)
        }
        try await adapter.removeDomain(domain)
    }

    public class func remove(
        _ domain: NSFileProviderDomain,
        mode: DomainRemovalMode
    ) async throws -> URL? {
        guard let adapter = FileProviderHostRegistry.currentAdapter() else {
            throw FileProviderHost.unsupported(.providerNotFound)
        }
        return try await adapter.removeDomain(domain, mode: mode)
    }

    public class func removeAllDomains(completionHandler: @escaping ((any Error)?) -> Void) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.queue.async {
            guard let adapter = FileProviderHostRegistry.currentAdapter() else {
                once.run {
                    completionHandler(FileProviderHost.unsupported(.providerNotFound))
                }
                return
            }
            Task {
                do {
                    try await adapter.removeAllDomains()
                    once.run { completionHandler(nil) }
                } catch {
                    once.run { completionHandler(error) }
                }
            }
        }
    }

    public class func `import`(
        _ domain: NSFileProviderDomain,
        fromDirectoryAt url: URL
    ) async throws {
        _ = domain
        _ = url
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    public class func getIdentifierForUserVisibleFile(
        at url: URL,
        completionHandler: @escaping (
            NSFileProviderItemIdentifier?,
            NSFileProviderDomainIdentifier?,
            (any Error)?
        ) -> Void
    ) {
        _ = url
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(nil, nil, FileProviderHost.unsupported())
        }
    }

    public class func placeholderURL(for url: URL) -> URL {
        url.appendingPathExtension("placeholder")
    }

    public class func writePlaceholder(
        at placeholderURL: URL,
        withMetadata metadata: NSFileProviderItem
    ) throws {
        guard let adapter = FileProviderHostRegistry.currentAdapter() else {
            throw FileProviderHost.unsupported(.providerNotFound)
        }
        try adapter.writePlaceholder(at: placeholderURL, metadata: metadata)
    }

    public func enumeratorForMaterializedItems() -> any NSFileProviderEnumerator {
        FileProviderUnhostedEnumerator()
    }

    public func enumeratorForPendingItems() -> any NSFileProviderPendingSetEnumerator {
        FileProviderUnhostedPendingSetEnumerator()
    }

    public func evictItem(identifier itemIdentifier: NSFileProviderItemIdentifier) async throws {
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.nonEvictable)
    }

#if canImport(UniformTypeIdentifiers)
    public func getService(
        named serviceName: NSFileProviderServiceName,
        for itemIdentifier: NSFileProviderItemIdentifier,
        completionHandler: @escaping (Foundation.NSFileProviderService?, (any Error)?) -> Void
    ) {
        _ = serviceName
        _ = itemIdentifier
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(nil, FileProviderHost.unsupported())
        }
    }
#else
    public func getService(
        named serviceName: NSFileProviderServiceName,
        for itemIdentifier: NSFileProviderItemIdentifier,
        completionHandler: @escaping (AnyObject?, (any Error)?) -> Void
    ) {
        _ = serviceName
        _ = itemIdentifier
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(nil, FileProviderHost.unsupported())
        }
    }
#endif

    public func getUserVisibleURL(
        for itemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> URL {
        _ = itemIdentifier
        throw FileProviderHost.unsupported()
    }

    public func globalProgress(for kind: Progress.FileOperationKind) -> Progress {
        let progress = Progress(totalUnitCount: 0)
        progress.kind = .file
        _ = kind
        progress.completedUnitCount = 0
        return progress
    }

    public func listAvailableTestingOperations() throws -> [any NSFileProviderTestingOperation] {
        throw FileProviderHost.unsupported()
    }

    public func register(
        _ task: URLSessionTask,
        forItemWithIdentifier identifier: NSFileProviderItemIdentifier
    ) async throws {
        _ = task
        _ = identifier
        throw FileProviderHost.unsupported()
    }

    public func reimportItems(below itemIdentifier: NSFileProviderItemIdentifier) async throws {
        _ = itemIdentifier
        throw FileProviderHost.unsupported()
    }

    public func requestModification(
        of fields: NSFileProviderItemFields,
        forItemWithIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        options: NSFileProviderModifyItemOptions = []
    ) async throws {
        _ = fields
        _ = itemIdentifier
        _ = options
        throw FileProviderHost.unsupported()
    }

    public func run(
        _ operations: [any NSFileProviderTestingOperation]
    ) throws -> [AnyHashable: any Error] {
        _ = operations
        throw FileProviderHost.unsupported()
    }

    public func signalEnumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier
    ) async throws {
        _ = containerItemIdentifier
        throw FileProviderHost.unsupported()
    }

    public func signalErrorResolved(_ error: any Error) async throws {
        _ = error
        throw FileProviderHost.unsupported()
    }

    public func temporaryDirectoryURL() throws -> URL {
        let url = documentStorageURL.appendingPathComponent("tmp", isDirectory: true)
        try FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        return url
    }

    public func waitForChanges(below itemIdentifier: NSFileProviderItemIdentifier) async throws {
        _ = itemIdentifier
        throw FileProviderHost.unsupported()
    }

    public func waitForStabilization(completionHandler: @escaping ((any Error)?) -> Void) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(FileProviderHost.unsupported())
        }
    }

    public func requestDownloadForItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        requestedRange: NSRange? = nil,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = itemIdentifier
        _ = requestedRange
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(FileProviderHost.unsupported())
        }
    }

    public func requestDownloadForItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        requestedRange: NSRange? = nil
    ) async throws {
        _ = itemIdentifier
        _ = requestedRange
        throw FileProviderHost.unsupported()
    }
}
