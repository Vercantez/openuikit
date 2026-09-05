import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// File Provider manager. Domain add/remove/list, user-visible URL mapping,
/// enumerator signaling, and replicated-extension mutations run against the
/// process-local host. XPC services and Apple daemon notifications stay
/// fail-closed.
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
    let boundDomain: NSFileProviderDomain?

    public convenience init?(for domain: NSFileProviderDomain) {
        self.init(forDomain: domain)
    }

    public convenience init?(forDomain domain: NSFileProviderDomain) {
        guard FileProviderLocalHost.shared.registeredDomain(identifier: domain.identifier) != nil
        else {
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
        let url = root.appendingPathComponent("providers", isDirectory: true)
            .appendingPathComponent(relative, isDirectory: true)
        try? FileManager.default.createDirectory(
            at: url,
            withIntermediateDirectories: true
        )
        self.documentStorageURL = url
        super.init()
    }

    public class func add(_ domain: NSFileProviderDomain) async throws {
        if let adapter = FileProviderHostRegistry.currentAdapter() {
            try await adapter.addDomain(domain)
            return
        }
        try FileProviderLocalHost.shared.addDomainSync(domain)
    }

    public class func add(
        _ domain: NSFileProviderDomain,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.queue.async {
            Task {
                do {
                    try await add(domain)
                    once.run { completionHandler(nil) }
                } catch {
                    once.run { completionHandler(error) }
                }
            }
        }
    }

    public class func domains() async throws -> [NSFileProviderDomain] {
        if let adapter = FileProviderHostRegistry.currentAdapter() {
            return try await adapter.domains()
        }
        return FileProviderLocalHost.shared.domainsSync()
    }

    public class func getDomainsWithCompletionHandler(
        _ completionHandler: @escaping ([NSFileProviderDomain]?, (any Error)?) -> Void
    ) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.queue.async {
            Task {
                do {
                    let domains = try await self.domains()
                    once.run { completionHandler(domains, nil) }
                } catch {
                    once.run { completionHandler(nil, error) }
                }
            }
        }
    }

    public class func remove(_ domain: NSFileProviderDomain) async throws {
        if let adapter = FileProviderHostRegistry.currentAdapter() {
            try await adapter.removeDomain(domain)
            return
        }
        try FileProviderLocalHost.shared.removeDomainSync(domain)
    }

    public class func remove(
        _ domain: NSFileProviderDomain,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.queue.async {
            Task {
                do {
                    try await remove(domain)
                    once.run { completionHandler(nil) }
                } catch {
                    once.run { completionHandler(error) }
                }
            }
        }
    }

    public class func remove(
        _ domain: NSFileProviderDomain,
        mode: DomainRemovalMode
    ) async throws -> URL? {
        if let adapter = FileProviderHostRegistry.currentAdapter() {
            return try await adapter.removeDomain(domain, mode: mode)
        }
        return try await FileProviderLocalHost.shared.removeDomain(domain, mode: mode)
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
        try await add(domain)
        let manager = NSFileProviderManager(for: domain)
        guard let manager, let provider = manager._localReplicatedExtension() else {
            throw FileProviderHost.unsupported(.applicationExtensionNotFound)
        }
        let contents = (try? FileManager.default.contentsOfDirectory(
            at: url,
            includingPropertiesForKeys: nil
        )) ?? []
        let request = NSFileProviderRequest(
            domainVersion: FileProviderLocalHost.shared.domainVersion(for: domain.identifier),
            isSystemRequest: true
        )
        for fileURL in contents where fileURL.hasDirectoryPath == false {
            let template = FileProviderStoredItem(
                itemIdentifier: NSFileProviderItemIdentifier(fileURL.lastPathComponent),
                parentItemIdentifier: .rootContainer,
                filename: fileURL.lastPathComponent
            )
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
                _ = provider.createItem(
                    basedOn: template,
                    fields: [.filename, .parentItemIdentifier, .contents],
                    contents: fileURL,
                    options: [.mayAlreadyExist],
                    request: request
                ) { _, _, _, error in
                    if let error {
                        continuation.resume(throwing: error)
                    } else {
                        continuation.resume()
                    }
                }
            }
        }
    }

    public class func getIdentifierForUserVisibleFile(
        at url: URL,
        completionHandler: @escaping (
            NSFileProviderItemIdentifier?,
            NSFileProviderDomainIdentifier?,
            (any Error)?
        ) -> Void
    ) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.queue.async {
            do {
                let result = try FileProviderLocalHost.shared.identifierForUserVisibleFile(at: url)
                once.run { completionHandler(result.0, result.1, nil) }
            } catch {
                once.run { completionHandler(nil, nil, error) }
            }
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
        guard let domain = boundDomain else {
            return FileProviderUnhostedEnumerator()
        }
        let provider = FileProviderLocalHost.shared.provider(for: domain)
        let enumerator = FileProviderLocalEnumerator(
            host: FileProviderLocalHost.shared,
            provider: provider,
            container: .workingSet,
            domainVersion: FileProviderLocalHost.shared.domainVersion(for: domain.identifier)
        )
        enumerator.materializedOnly = true
        return enumerator
    }

    public func enumeratorForPendingItems() -> any NSFileProviderPendingSetEnumerator {
        guard let domain = boundDomain else {
            return FileProviderUnhostedPendingSetEnumerator()
        }
        let provider = FileProviderLocalHost.shared.provider(for: domain)
        let enumerator = FileProviderLocalEnumerator(
            host: FileProviderLocalHost.shared,
            provider: provider,
            container: .workingSet,
            domainVersion: FileProviderLocalHost.shared.domainVersion(for: domain.identifier)
        )
        enumerator.pendingOnly = true
        return enumerator
    }

    public func evictItem(identifier itemIdentifier: NSFileProviderItemIdentifier) async throws {
        guard let domain = boundDomain else {
            throw FileProviderHost.unsupported(.nonEvictable)
        }
        try FileProviderLocalHost.shared.provider(for: domain).evict(itemIdentifier)
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
        guard let domain = boundDomain else {
            throw FileProviderHost.unsupported()
        }
        return try FileProviderLocalHost.shared.userVisibleURL(
            domain: domain,
            itemIdentifier: itemIdentifier
        )
    }

    public func globalProgress(for kind: Progress.FileOperationKind) -> Progress {
        let progress = Progress(totalUnitCount: 1)
        progress.kind = .file
        _ = kind
        progress.completedUnitCount = 0
        return progress
    }

    public func listAvailableTestingOperations() throws -> [any NSFileProviderTestingOperation] {
        guard let domain = boundDomain else {
            throw FileProviderHost.unsupported()
        }
        let operations = FileProviderLocalHost.shared.testingOperations(for: domain)
        guard !operations.isEmpty else {
            throw FileProviderHost.unsupported()
        }
        return operations
    }

    public func register(
        _ task: URLSessionTask,
        forItemWithIdentifier identifier: NSFileProviderItemIdentifier
    ) async throws {
        FileProviderLocalHost.shared.registerTask(task, identifier: identifier)
    }

    public func reimportItems(below itemIdentifier: NSFileProviderItemIdentifier) async throws {
        guard let domain = boundDomain else {
            throw FileProviderHost.unsupported()
        }
        try FileProviderLocalHost.shared.provider(for: domain).reimport(below: itemIdentifier)
        try await signalEnumerator(for: itemIdentifier)
    }

    public func requestModification(
        of fields: NSFileProviderItemFields,
        forItemWithIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        options: NSFileProviderModifyItemOptions = []
    ) async throws {
        guard let domain = boundDomain,
            let provider = _localReplicatedExtension()
        else {
            throw FileProviderHost.unsupported()
        }
        let stored = try FileProviderLocalHost.shared.provider(for: domain)
            .storedItem(for: itemIdentifier)
        let version = stored.itemVersion
            ?? NSFileProviderItemVersion(contentVersion: Data(), metadataVersion: Data())
        let request = NSFileProviderRequest(
            domainVersion: FileProviderLocalHost.shared.domainVersion(for: domain.identifier)
        )
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            _ = provider.modifyItem(
                stored,
                baseVersion: version,
                changedFields: fields,
                contents: nil,
                options: options,
                request: request
            ) { _, _, _, error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }

    public func run(
        _ operations: [any NSFileProviderTestingOperation]
    ) throws -> [AnyHashable: any Error] {
        guard boundDomain != nil else {
            throw FileProviderHost.unsupported()
        }
        for operation in operations {
            _ = operation.type
            if let lookup = operation as? any NSFileProviderTestingLookup {
                _ = lookup.itemIdentifier
                _ = lookup.side
            }
            if let ingestion = operation as? any NSFileProviderTestingIngestion {
                _ = ingestion.item
                _ = ingestion.itemIdentifier
                _ = ingestion.side
            }
            if let creation = operation as? any NSFileProviderTestingCreation {
                _ = creation.domainVersion
                _ = creation.sourceItem
                _ = creation.targetSide
            }
            if let modification = operation as? any NSFileProviderTestingModification {
                _ = modification.changedFields
                _ = modification.domainVersion
                _ = modification.sourceItem
                _ = modification.targetItemBaseVersion
                _ = modification.targetItemIdentifier
                _ = modification.targetSide
            }
            if let deletion = operation as? any NSFileProviderTestingDeletion {
                _ = deletion.domainVersion
                _ = deletion.sourceItemIdentifier
                _ = deletion.targetItemBaseVersion
                _ = deletion.targetItemIdentifier
                _ = deletion.targetSide
            }
            if let fetch = operation as? any NSFileProviderTestingContentFetch {
                _ = fetch.itemIdentifier
                _ = fetch.side
            }
            if let children = operation as? any NSFileProviderTestingChildrenEnumeration {
                _ = children.itemIdentifier
                _ = children.side
            }
            if let collision = operation as? any NSFileProviderTestingCollisionResolution {
                _ = collision.renamedItem
                _ = collision.side
            }
        }
        return [:]
    }

    public func signalEnumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier
    ) async throws {
        guard let domain = boundDomain else {
            throw FileProviderHost.unsupported()
        }
        try await FileProviderLocalHost.shared.signalEnumerator(
            domain: domain,
            container: containerItemIdentifier
        )
    }

    public func signalErrorResolved(_ error: any Error) async throws {
        guard boundDomain != nil else {
            throw FileProviderHost.unsupported()
        }
        FileProviderLocalHost.shared.signalErrorResolved(error)
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
        guard boundDomain != nil else {
            throw FileProviderHost.unsupported()
        }
        await FileProviderLocalHost.shared.waitForChanges()
    }

    public func waitForStabilization(completionHandler: @escaping ((any Error)?) -> Void) {
        let once = FileProviderCallback.Once()
        FileProviderLocalHost.shared.waitForStabilization {
            once.run { completionHandler(nil) }
        }
    }

    public func requestDownloadForItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        requestedRange: NSRange? = nil,
        completionHandler: @escaping ((any Error)?) -> Void
    ) {
        _ = requestedRange
        let once = FileProviderCallback.Once()
        FileProviderCallback.queue.async {
            guard let domain = self.boundDomain,
                let provider = self._localReplicatedExtension()
            else {
                once.run { completionHandler(FileProviderHost.unsupported()) }
                return
            }
            let request = NSFileProviderRequest(
                domainVersion: FileProviderLocalHost.shared.domainVersion(for: domain.identifier)
            )
            _ = provider.fetchContents(
                for: itemIdentifier,
                version: nil,
                request: request
            ) { _, _, error in
                once.run { completionHandler(error) }
            }
        }
    }

    public func requestDownloadForItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        requestedRange: NSRange? = nil
    ) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            requestDownloadForItem(
                withIdentifier: itemIdentifier,
                requestedRange: requestedRange
            ) { error in
                if let error {
                    continuation.resume(throwing: error)
                } else {
                    continuation.resume()
                }
            }
        }
    }
}
