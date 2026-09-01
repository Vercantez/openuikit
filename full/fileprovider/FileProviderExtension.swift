import Foundation

/// Non-replicated File Provider extension base class. Linux has no appex host:
/// overridable action methods fail closed unless a subclass implements them.
/// Public placeholder writes do not persist Apple-compatible placeholder files.
open class NSFileProviderExtension: NSObject, @unchecked Sendable {
    public private(set) var domain: NSFileProviderDomain?
    open var providerIdentifier: String { FileProviderHost.unhostedProviderIdentifier }
    open var documentStorageURL: URL {
        if let domain {
            return FileProviderHost.storageRoot()
                .appendingPathComponent(domain.pathRelativeToDocumentStorage, isDirectory: true)
        }
        return FileProviderHost.storageRoot().appendingPathComponent(
            "_extension",
            isDirectory: true
        )
    }

    public override init() {
        super.init()
    }

    public init(domain: NSFileProviderDomain?) {
        self.domain = domain
        super.init()
        try? FileManager.default.createDirectory(
            at: documentStorageURL,
            withIntermediateDirectories: true
        )
    }

    open class func placeholderURL(for url: URL) -> URL {
        NSFileProviderManager.placeholderURL(for: url)
    }

    open class func writePlaceholder(
        at placeholderURL: URL,
        withMetadata metadata: [URLResourceKey: Any]
    ) throws {
        guard let adapter = FileProviderHostRegistry.currentAdapter() else {
            throw FileProviderHost.unsupported(.providerNotFound)
        }
        try adapter.writePlaceholder(at: placeholderURL, resourceValues: metadata)
    }

    open func urlForItem(
        withPersistentIdentifier identifier: NSFileProviderItemIdentifier
    ) -> URL? {
        documentStorageURL.appendingPathComponent(identifier.rawValue)
    }

    open func persistentIdentifierForItem(at url: URL) -> NSFileProviderItemIdentifier? {
        NSFileProviderItemIdentifier(url.lastPathComponent)
    }

    open func item(for identifier: NSFileProviderItemIdentifier) throws -> NSFileProviderItem {
        _ = identifier
        throw FileProviderHost.unsupported(.noSuchItem)
    }

    open func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier
    ) throws -> any NSFileProviderEnumerator {
        _ = containerItemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func providePlaceholder(at url: URL) async throws {
        _ = url
        throw FileProviderHost.unsupported(.providerNotFound)
    }

    open func startProvidingItem(at url: URL) async throws {
        _ = url
        throw FileProviderHost.unsupported()
    }

    open func stopProvidingItem(at url: URL) {
        _ = url
    }

    open func itemChanged(at url: URL) {
        _ = url
    }

    open func importDocument(
        at fileURL: URL,
        toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> NSFileProviderItem {
        _ = fileURL
        _ = parentItemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func createDirectory(
        withName directoryName: String,
        inParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> NSFileProviderItem {
        _ = directoryName
        _ = parentItemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func renameItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        toName itemName: String
    ) async throws -> NSFileProviderItem {
        _ = itemIdentifier
        _ = itemName
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func reparentItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        toParentItemWithIdentifier parentItemIdentifier: NSFileProviderItemIdentifier,
        newName: String?
    ) async throws -> NSFileProviderItem {
        _ = itemIdentifier
        _ = parentItemIdentifier
        _ = newName
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func trashItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> NSFileProviderItem {
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func untrashItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier,
        toParentItemIdentifier parentItemIdentifier: NSFileProviderItemIdentifier?
    ) async throws -> NSFileProviderItem {
        _ = itemIdentifier
        _ = parentItemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func deleteItem(
        withIdentifier itemIdentifier: NSFileProviderItemIdentifier
    ) async throws {
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func setFavoriteRank(
        _ favoriteRank: NSNumber?,
        forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> NSFileProviderItem {
        _ = favoriteRank
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func setLastUsedDate(
        _ lastUsedDate: Date?,
        forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> NSFileProviderItem {
        _ = lastUsedDate
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func setTagData(
        _ tagData: Data?,
        forItemIdentifier itemIdentifier: NSFileProviderItemIdentifier
    ) async throws -> NSFileProviderItem {
        _ = tagData
        _ = itemIdentifier
        throw FileProviderHost.unsupported(.applicationExtensionNotFound)
    }

    open func supportedServiceSources(
        for itemIdentifier: NSFileProviderItemIdentifier
    ) throws -> [any NSFileProviderServiceSource] {
        _ = itemIdentifier
        return []
    }

    open func fetchThumbnails(
        for itemIdentifiers: [NSFileProviderItemIdentifier],
        requestedSize size: CGSize,
        perThumbnailCompletionHandler: @escaping (
            NSFileProviderItemIdentifier,
            Data?,
            (any Error)?
        ) -> Void,
        completionHandler: @escaping ((any Error)?) -> Void
    ) -> Progress {
        _ = size
        let progress = Progress(totalUnitCount: Int64(max(itemIdentifiers.count, 1)))
        let progressLock = NSLock()
        let finishOnce = FileProviderCallback.Once()
        for identifier in itemIdentifiers {
            let itemOnce = FileProviderCallback.Once()
            FileProviderCallback.asyncOnce(itemOnce) {
                perThumbnailCompletionHandler(
                    identifier,
                    nil,
                    FileProviderHost.unsupported()
                )
                progressLock.lock()
                progress.completedUnitCount += 1
                progressLock.unlock()
            }
        }
        FileProviderCallback.asyncOnce(finishOnce) {
            completionHandler(FileProviderHost.unsupported())
            if itemIdentifiers.isEmpty {
                progressLock.lock()
                progress.completedUnitCount = progress.totalUnitCount
                progressLock.unlock()
            }
        }
        return progress
    }
}
