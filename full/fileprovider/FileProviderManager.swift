import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Process-local File Provider manager. Domain add/remove/list and placeholder
/// helpers are real. Daemon, Files.app, and testing-harness calls fail closed.
open class NSFileProviderManager: NSObject, @unchecked Sendable {
    public enum DomainRemovalMode: Int, Hashable, Sendable {
        case removeAll = 0
    }

    private static let registryLock = NSLock()
    nonisolated(unsafe) private static var registeredDomains: [String: NSFileProviderDomain] = [:]
    private static let defaultManagerStorage = NSFileProviderManager(
        providerIdentifier: FileProviderHost.unhostedProviderIdentifier,
        domain: nil
    )

    private static func withRegistry<T>(_ body: () -> T) -> T {
        registryLock.lock()
        defer { registryLock.unlock() }
        return body()
    }

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
        withRegistry { registeredDomains[domain.identifier.rawValue] = domain }
        NotificationCenter.default.post(name: .fileProviderDomainDidChange, object: domain)
    }

    public class func domains() async throws -> [NSFileProviderDomain] {
        withRegistry { Array(registeredDomains.values) }
    }

    public class func remove(_ domain: NSFileProviderDomain) async throws {
        withRegistry { _ = registeredDomains.removeValue(forKey: domain.identifier.rawValue) }
        NotificationCenter.default.post(name: .fileProviderDomainDidChange, object: domain)
    }

    public class func remove(
        _ domain: NSFileProviderDomain,
        mode: DomainRemovalMode
    ) async throws -> URL? {
        _ = mode
        try await remove(domain)
        return nil
    }

    public class func removeAllDomains(completionHandler: @escaping ((any Error)?) -> Void) {
        withRegistry { registeredDomains.removeAll() }
        NotificationCenter.default.post(name: .fileProviderDomainDidChange, object: nil)
        completionHandler(nil)
    }

    public class func `import`(
        _ domain: NSFileProviderDomain,
        fromDirectoryAt url: URL
    ) async throws {
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
        completionHandler(nil, nil, FileProviderHost.unsupported())
    }

    public class func placeholderURL(for url: URL) -> URL {
        url.appendingPathExtension("placeholder")
    }

    public class func writePlaceholder(
        at placeholderURL: URL,
        withMetadata metadata: NSFileProviderItem
    ) throws {
        let payload: [String: String] = [
            "itemIdentifier": metadata.itemIdentifier.rawValue,
            "parentItemIdentifier": metadata.parentItemIdentifier.rawValue,
            "filename": metadata.filename,
        ]
        let data = try JSONSerialization.data(withJSONObject: payload, options: [.sortedKeys])
        try data.write(to: placeholderURL, options: .atomic)
    }

    public func enumeratorForMaterializedItems() -> any NSFileProviderEnumerator {
        FileProviderEmptyEnumerator()
    }

    public func enumeratorForPendingItems() -> any NSFileProviderPendingSetEnumerator {
        FileProviderEmptyPendingSetEnumerator()
    }

    public func evictItem(identifier itemIdentifier: NSFileProviderItemIdentifier) async throws {
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.nonEvictable)
    }

    public func getService(
        named serviceName: NSFileProviderServiceName,
        for itemIdentifier: NSFileProviderItemIdentifier,
        completionHandler: @escaping (NSFileProviderService?, (any Error)?) -> Void
    ) {
        _ = serviceName
        _ = itemIdentifier
        completionHandler(nil, FileProviderHost.unsupported())
    }

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
        completionHandler(FileProviderHost.unsupported())
    }

    public func requestDownloadForItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        requestedRange: NSRange? = nil,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = itemIdentifier
        _ = requestedRange
        completionHandler(FileProviderHost.unsupported())
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
