@_spi(OpenUIKitHost) import FileProvider
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif
#if canImport(CoreGraphics)
import CoreGraphics
#endif


func fileProviderRequireCode(_ error: any Error, _ code: NSFileProviderError.Code) {
    guard let typed = error as? NSFileProviderError else {
        fatalError("expected NSFileProviderError, got \(error)")
    }
    precondition(typed.code == code)
    precondition(typed.errorCode == code.rawValue)
}

func fileProviderWaitOnce(_ work: (@escaping () -> Void) -> Void) {
    let gate = DispatchSemaphore(value: 0)
    work { gate.signal() }
    gate.wait()
}

func fileProviderAwait(_ work: @escaping @Sendable () async throws -> Void) {
    let gate = DispatchSemaphore(value: 0)
    var caught: (any Error)?
    Task {
        do {
            try await work()
        } catch {
            caught = error
        }
        gate.signal()
    }
    gate.wait()
    if let caught {
        fatalError("unexpected error \(caught)")
    }
}

func fileProviderAwaitError(_ work: @escaping @Sendable () async throws -> Void) -> (any Error)? {
    let gate = DispatchSemaphore(value: 0)
    var caught: (any Error)?
    Task {
        do {
            try await work()
        } catch {
            caught = error
        }
        gate.signal()
    }
    gate.wait()
    return caught
}

func fileProviderExerciseOptionSet<T: OptionSet & Hashable>(_ a: T, _ b: T)
where T.Element == T {
    var set = T()
    precondition(set.isEmpty)
    set = T([a, b])
    precondition(set.contains(a))
    _ = set.insert(a)
    _ = set.remove(b)
    _ = set.update(with: b)
    precondition(a.union(b).contains(a))
    _ = set.intersection(a)
    _ = set.symmetricDifference(b)
    _ = set.subtracting(a)
    var mutating = a.union(b)
    mutating.formUnion(a)
    mutating.formIntersection(a)
    mutating.formSymmetricDifference(b)
    mutating.subtract(a)
    precondition(a.isSubset(of: a.union(b)))
    precondition(a.union(b).isSuperset(of: a))
    _ = a.isDisjoint(with: T())
    if a != b {
        _ = a.isStrictSubset(of: a.union(b))
        _ = a.union(b).isStrictSuperset(of: a)
    }
    _ = T.init([a, b])
    _ = T([a])
    precondition(a != T())
    var hasher = Hasher()
    a.hash(into: &hasher)
    _ = hasher.finalize()
    _ = a.hashValue
    _ = T(rawValue: a.rawValue)
}

final class FileProviderAgentCounter: @unchecked Sendable {
    private let lock = NSLock()
    private var value = 0
    func increment() {
        lock.lock()
        value += 1
        lock.unlock()
    }
    var snapshot: Int {
        lock.lock()
        defer { lock.unlock() }
        return value
    }
}

final class FileProviderAgentItem: NSObject, NSFileProviderItemProtocol, NSFileProviderItemDecorating {
    let itemIdentifier: NSFileProviderItemIdentifier
    var parentItemIdentifier: NSFileProviderItemIdentifier
    var filename: String
    var documentSize: NSNumber?
    var capabilities: NSFileProviderItemCapabilities
    var typeIdentifier: String?
    var itemVersion: NSFileProviderItemVersion?
    var contentPolicy: NSFileProviderContentPolicy
    var childItemCount: NSNumber?
    var contentModificationDate: Date?
    var creationDate: Date?
    var isDownloaded: Bool
    var isDownloading: Bool
    var downloadingError: (any Error)?
    var extendedAttributes: [String: Data]
    var favoriteRank: NSNumber?
    var fileSystemFlags: NSFileProviderFileSystemFlags
    var lastUsedDate: Date?
    var mostRecentEditorNameComponents: PersonNameComponents?
    var isMostRecentVersionDownloaded: Bool
    var ownerNameComponents: PersonNameComponents?
    var isShared: Bool
    var isSharedByCurrentUser: Bool
    var symlinkTargetPath: String?
    var tagData: Data?
    var isTrashed: Bool
    var typeAndCreator: NSFileProviderTypeAndCreator
    var isUploaded: Bool
    var isUploading: Bool
    var uploadingError: (any Error)?
    var userInfo: [AnyHashable: Any]?
    var versionIdentifier: Data?
    var decorations: [NSFileProviderItemDecorationIdentifier]?

    init(
        itemIdentifier: NSFileProviderItemIdentifier,
        parentItemIdentifier: NSFileProviderItemIdentifier,
        filename: String
    ) {
        self.itemIdentifier = itemIdentifier
        self.parentItemIdentifier = parentItemIdentifier
        self.filename = filename
        self.documentSize = nil
        self.capabilities = .allowsReading
        self.typeIdentifier = nil
        self.itemVersion = nil
        self.contentPolicy = .inherited
        self.childItemCount = 0
        self.contentModificationDate = Date()
        self.creationDate = Date()
        self.isDownloaded = true
        self.isDownloading = false
        self.downloadingError = nil
        self.extendedAttributes = [:]
        self.favoriteRank = NSNumber(value: NSFileProviderFavoriteRankUnranked)
        self.fileSystemFlags = [.userReadable]
        self.lastUsedDate = Date()
        self.mostRecentEditorNameComponents = PersonNameComponents()
        self.isMostRecentVersionDownloaded = true
        self.ownerNameComponents = PersonNameComponents()
        self.isShared = false
        self.isSharedByCurrentUser = false
        self.symlinkTargetPath = nil
        self.tagData = nil
        self.isTrashed = false
        self.typeAndCreator = NSFileProviderTypeAndCreator()
        self.isUploaded = true
        self.isUploading = false
        self.uploadingError = nil
        self.userInfo = ["k": "v"]
        self.versionIdentifier = Data([0])
        self.decorations = [NSFileProviderItemDecorationIdentifier("badge")]
    }
}

final class FileProviderAgentObserver: NSObject, NSFileProviderEnumerationObserver,
    NSFileProviderChangeObserver
{
    var items: [any NSFileProviderItemProtocol] = []
    var deleted: [NSFileProviderItemIdentifier] = []
    var finishedPage: NSFileProviderPage?
    var finishedAnchor: NSFileProviderSyncAnchor?
    var error: (any Error)?
    var suggestedPageSize: Int = 100
    var suggestedBatchSize: Int = 100
    var moreComing = false
    var onFinish: (() -> Void)?

    func didEnumerate(_ updatedItems: [any NSFileProviderItemProtocol]) {
        items.append(contentsOf: updatedItems)
    }
    func finishEnumerating(upTo nextPage: NSFileProviderPage?) {
        finishedPage = nextPage
        onFinish?()
    }
    func finishEnumeratingWithError(_ error: any Error) {
        self.error = error
        onFinish?()
    }
    func didDeleteItems(withIdentifiers deletedItemIdentifiers: [NSFileProviderItemIdentifier]) {
        deleted.append(contentsOf: deletedItemIdentifiers)
    }
    func didUpdate(_ updatedItems: [any NSFileProviderItemProtocol]) {
        items.append(contentsOf: updatedItems)
    }
    func finishEnumeratingChanges(upTo anchor: NSFileProviderSyncAnchor, moreComing: Bool) {
        self.moreComing = moreComing
        finishedAnchor = anchor
        onFinish?()
    }
}

final class FileProviderAgentEnumerator: NSObject, NSFileProviderEnumerator {
    let stored: [any NSFileProviderItemProtocol]
    var syncAnchor: NSFileProviderSyncAnchor?
    private var invalid = false
    init(items: [any NSFileProviderItemProtocol]) { self.stored = items }
    func invalidate() { invalid = true }
    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        if invalid {
            observer.finishEnumeratingWithError(NSFileProviderError(.cannotSynchronize))
            return
        }
        observer.didEnumerate(stored)
        observer.finishEnumerating(upTo: nil)
    }
    func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        if invalid {
            observer.finishEnumeratingWithError(NSFileProviderError(.cannotSynchronize))
            return
        }
        observer.didUpdate(stored)
        observer.finishEnumeratingChanges(upTo: self.syncAnchor ?? syncAnchor, moreComing: false)
    }
    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void) {
        completionHandler(syncAnchor)
    }
}

final class FileProviderAgentServiceSource: NSObject, NSFileProviderServiceSource {
    let serviceName: NSFileProviderServiceName
    let isRestricted: Bool
    init(serviceName: NSFileProviderServiceName, isRestricted: Bool = true) {
        self.serviceName = serviceName
        self.isRestricted = isRestricted
    }
}


func testExtensionFailClosedActions() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain2 = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("appex"),
        displayName: "Appex",
        pathRelativeToDocumentStorage: "Documents/Appex"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain2) }
    let extensionInstance = NSFileProviderExtension(domain: domain2)
    precondition(extensionInstance.providerIdentifier.contains("fileprovider"))
    precondition(extensionInstance.documentStorageURL.path.contains("Documents/Appex"))
    precondition(extensionInstance.domain?.identifier == domain2.identifier)
    let notesID = NSFileProviderItemIdentifier("file-1")
    let mapped = extensionInstance.urlForItem(withPersistentIdentifier: notesID)
    precondition(mapped != nil)
    precondition(extensionInstance.persistentIdentifierForItem(at: mapped!) == notesID)
    do {
        _ = try extensionInstance.item(for: notesID)
        fatalError("item(for:) must fail closed")
    } catch {
        fileProviderRequireCode(error, .noSuchItem)
    }
    do {
        _ = try extensionInstance.enumerator(for: .rootContainer)
        fatalError("enumerator(for:) must fail closed")
    } catch {
        fileProviderRequireCode(error, .applicationExtensionNotFound)
    }
    let temp = FileManager.default.temporaryDirectory
    let missing = fileProviderAwaitError {
        try await extensionInstance.providePlaceholder(at: temp.appendingPathComponent("Inbox.txt"))
    }
    fileProviderRequireCode(missing!, .providerNotFound)
    let startErr = fileProviderAwaitError { try await extensionInstance.startProvidingItem(at: mapped!) }
    fileProviderRequireCode(startErr!, .providerNotFound)
    extensionInstance.itemChanged(at: mapped!)
    extensionInstance.stopProvidingItem(at: mapped!)
    let contentsURL = temp.appendingPathComponent("import-doc.txt")
    try! Data("x".utf8).write(to: contentsURL)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.importDocument(at: contentsURL, toParentItemIdentifier: .rootContainer)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.createDirectory(withName: "Dir", inParentItemIdentifier: .rootContainer)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.renameItem(withIdentifier: notesID, toName: "X")
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.reparentItem(
            withIdentifier: notesID,
            toParentItemWithIdentifier: .rootContainer,
            newName: nil
        )
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.trashItem(withIdentifier: notesID)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.untrashItem(withIdentifier: notesID, toParentItemIdentifier: .rootContainer)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        try await extensionInstance.deleteItem(withIdentifier: notesID)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.setFavoriteRank(1, forItemIdentifier: notesID)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.setLastUsedDate(Date(), forItemIdentifier: notesID)
    }!, .applicationExtensionNotFound)
    fileProviderRequireCode(fileProviderAwaitError {
        _ = try await extensionInstance.setTagData(Data(), forItemIdentifier: notesID)
    }!, .applicationExtensionNotFound)
    let services = try! extensionInstance.supportedServiceSources(for: notesID)
    precondition(services.isEmpty)
    precondition(
        NSFileProviderExtension.placeholderURL(for: temp.appendingPathComponent("Inbox.txt")).pathExtension
            == "placeholder"
    )
    let placeholderURL = NSFileProviderExtension.placeholderURL(for: temp.appendingPathComponent("ph.txt"))
    try! NSFileProviderExtension.writePlaceholder(
        at: placeholderURL,
        withMetadata: [URLResourceKey.nameKey: "Notes.txt"]
    )
    precondition(FileManager.default.fileExists(atPath: placeholderURL.path))
    try? FileManager.default.removeItem(at: placeholderURL)
    _ = NSFileProviderExtension()
}


func testThumbnailAndCustomActionFailClosed() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("thumbs"),
        displayName: "Thumbs"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    let notesID = NSFileProviderItemIdentifier("file-1")
    let extensionInstance = NSFileProviderExtension(domain: domain)
    var thumbItemCount = 0
    var thumbFinishCount = 0
    fileProviderWaitOnce { done in
        _ = extensionInstance.fetchThumbnails(
            for: [notesID],
            requestedSize: CGSize(width: 32, height: 32),
            perThumbnailCompletionHandler: { _, data, error in
                thumbItemCount += 1
                precondition(data == nil)
                fileProviderRequireCode(error!, .providerNotFound)
            },
            completionHandler: { error in
                thumbFinishCount += 1
                fileProviderRequireCode(error!, .providerNotFound)
                done()
            }
        )
    }
    precondition(thumbItemCount == 1)
    precondition(thumbFinishCount == 1)
    fileProviderWaitOnce { done in
        _ = provider.fetchThumbnails(
            for: [notesID],
            requestedSize: CGSize(width: 16, height: 16),
            perThumbnailCompletionHandler: { _, data, error in
                precondition(data == nil)
                fileProviderRequireCode(error!, .providerNotFound)
            },
            completionHandler: { error in
                fileProviderRequireCode(error!, .providerNotFound)
                done()
            }
        )
    }
    fileProviderWaitOnce { done in
        _ = provider.performAction(
            identifier: NSFileProviderExtensionActionIdentifier("ping"),
            onItemsWithIdentifiers: [notesID]
        ) { error in
            fileProviderRequireCode(error!, .applicationExtensionNotFound)
            done()
        }
    }
}

