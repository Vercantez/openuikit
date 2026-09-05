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


func testManagerDomainRegistry() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("registry"),
        displayName: "Registry"
    )
    let domain2 = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("registry-path"),
        displayName: "Registry",
        pathRelativeToDocumentStorage: "Documents/Registry"
    )
    precondition(NSFileProviderManager(for: domain2) == nil)
    precondition(NSFileProviderManager(forDomain: domain2) == nil)
    let postedDomainChange = FileProviderAgentCounter()
    let postedMaterialized = FileProviderAgentCounter()
    let postedPending = FileProviderAgentCounter()
    let center = NotificationCenter.default
    let domainToken = center.addObserver(forName: .fileProviderDomainDidChange, object: nil, queue: nil) { _ in
        postedDomainChange.increment()
    }
    let materializedToken = center.addObserver(forName: .fileProviderMaterializedSetDidChange, object: nil, queue: nil) { _ in
        postedMaterialized.increment()
    }
    let pendingToken = center.addObserver(forName: .fileProviderPendingSetDidChange, object: nil, queue: nil) { _ in
        postedPending.increment()
    }
    defer {
        center.removeObserver(domainToken)
        center.removeObserver(materializedToken)
        center.removeObserver(pendingToken)
    }
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    var addCompletion: (any Error)? = NSFileProviderError(.cannotSynchronize)
    fileProviderWaitOnce { done in
        NSFileProviderManager.add(domain2) { error in
            addCompletion = error
            done()
        }
    }
    precondition(addCompletion == nil)
    let listed = fileProviderAwaitDomains()
    precondition(listed.contains { $0.identifier == domain.identifier })
    var listedHandler: [NSFileProviderDomain] = []
    fileProviderWaitOnce { done in
        NSFileProviderManager.getDomainsWithCompletionHandler { domains, error in
            precondition(error == nil)
            listedHandler = domains ?? []
            done()
        }
    }
    precondition(listedHandler.count >= 2)
    precondition(postedDomainChange.snapshot >= 1)
    precondition(postedMaterialized.snapshot == 0)
    precondition(postedPending.snapshot == 0)
    let manager = NSFileProviderManager(for: domain)!
    _ = NSFileProviderManager(forDomain: domain)
    precondition(manager.providerIdentifier == "org.openuikit.fileprovider.unhosted")
    let temp = try! manager.temporaryDirectoryURL()
    precondition(temp.path.contains("OpenUIKitFileProvider"))
    precondition(manager.documentStorageURL.path.contains("OpenUIKitFileProvider"))
    _ = NSFileProviderManager.default
    fileProviderAwait { try await NSFileProviderManager.remove(domain2) }
    let preserved = fileProviderAwaitRemoveMode(domain)
    _ = preserved
    var removeAllCount = 0
    fileProviderWaitOnce { done in
        NSFileProviderManager.removeAllDomains { error in
            removeAllCount += 1
            precondition(error == nil)
            done()
        }
    }
    precondition(removeAllCount == 1)
}

func fileProviderAwaitDomains() -> [NSFileProviderDomain] {
    var result: [NSFileProviderDomain] = []
    fileProviderWaitOnce { done in
        Task {
            result = try! await NSFileProviderManager.domains()
            done()
        }
    }
    return result
}

func fileProviderAwaitRemoveMode(_ domain: NSFileProviderDomain) -> URL? {
    var result: URL?
    fileProviderWaitOnce { done in
        Task {
            result = try! await NSFileProviderManager.remove(domain, mode: .removeAll)
            done()
        }
    }
    return result
}


func testManagerUserVisibleAndSignals() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("visible"),
        displayName: "Visible"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    let request = NSFileProviderRequest(domainVersion: provider.domainVersion, isSystemRequest: true)
    let notes = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("file-1"),
        parentItemIdentifier: .rootContainer,
        filename: "Notes.txt"
    )
    notes.capabilities = [.allowsReading, .allowsWriting, .allowsDeleting, .allowsEvicting, .allowsRenaming]
    let temp = try! manager.temporaryDirectoryURL()
    let contentsURL = temp.appendingPathComponent("Notes.txt")
    try! Data("hello notes".utf8).write(to: contentsURL)
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: notes,
            fields: [.filename, .parentItemIdentifier, .contents],
            contents: contentsURL,
            options: [],
            request: request
        ) { _, _, _, error in
            precondition(error == nil)
            done()
        }
    }
    var visible: URL?
    fileProviderWaitOnce { done in
        Task {
            visible = try! await manager.getUserVisibleURL(for: notes.itemIdentifier)
            done()
        }
    }
    precondition(visible!.path.contains("visible"))
    var lookedUpItem: NSFileProviderItemIdentifier?
    var lookedUpDomain: NSFileProviderDomainIdentifier?
    fileProviderWaitOnce { done in
        NSFileProviderManager.getIdentifierForUserVisibleFile(at: visible!) { item, domainID, error in
            precondition(error == nil)
            lookedUpItem = item
            lookedUpDomain = domainID
            done()
        }
    }
    precondition(lookedUpItem == notes.itemIdentifier)
    precondition(lookedUpDomain == domain.identifier)
    fileProviderAwait { try await manager.signalEnumerator(for: .rootContainer) }
    fileProviderAwait { try await manager.waitForChanges(below: .rootContainer) }
    var stabilizeError: (any Error)? = NSFileProviderError(.cannotSynchronize)
    fileProviderWaitOnce { done in
        manager.waitForStabilization { error in
            stabilizeError = error
            done()
        }
    }
    precondition(stabilizeError == nil)
    fileProviderAwait { try await NSFileProviderManager.removeAllDomainsWait() }
}

extension NSFileProviderManager {
    static func removeAllDomainsWait() async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, any Error>) in
            removeAllDomains { error in
                if let error { continuation.resume(throwing: error) }
                else { continuation.resume() }
            }
        }
    }
}


func testManagerPlaceholdersDownloadsAndImport() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("ops"),
        displayName: "Ops"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    let request = NSFileProviderRequest(domainVersion: provider.domainVersion, isSystemRequest: true)
    let notes = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("ops-file"),
        parentItemIdentifier: .rootContainer,
        filename: "Ops.txt"
    )
    notes.capabilities = [.allowsReading, .allowsWriting, .allowsDeleting, .allowsEvicting]
    let temp = try! manager.temporaryDirectoryURL()
    let contentsURL = temp.appendingPathComponent("Ops.txt")
    try! Data("ops".utf8).write(to: contentsURL)
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: notes,
            fields: [.filename, .parentItemIdentifier, .contents],
            contents: contentsURL,
            options: [],
            request: request
        ) { _, _, _, error in
            precondition(error == nil)
            done()
        }
    }
    let progress = manager.globalProgress(for: .downloading)
    precondition(progress.totalUnitCount == 1)
    fileProviderAwait { try await manager.reimportItems(below: .rootContainer) }
    fileProviderAwait {
        try await manager.requestModification(
            of: [.lastUsedDate],
            forItemWithIdentifier: notes.itemIdentifier,
            options: []
        )
    }
    fileProviderAwait { try await manager.evictItem(identifier: notes.itemIdentifier) }
    fileProviderAwait { try await manager.signalErrorResolved(NSFileProviderError(.serverUnreachable)) }
    let session = URLSession(configuration: .ephemeral)
    let task = session.dataTask(with: URL(string: "https://example.invalid")!)
    fileProviderAwait { try await manager.register(task, forItemWithIdentifier: notes.itemIdentifier) }
    var downloadError: (any Error)?
    fileProviderWaitOnce { done in
        manager.requestDownloadForItem(withIdentifier: notes.itemIdentifier) { error in
            downloadError = error
            done()
        }
    }
    _ = downloadError
    let missingError = fileProviderAwaitError {
        try await manager.requestDownloadForItem(
            withIdentifier: NSFileProviderItemIdentifier("missing-download"),
            requestedRange: NSRange(location: 0, length: 1)
        )
    }
    fileProviderRequireCode(missingError!, .noSuchItem)
    let placeholderURL = NSFileProviderManager.placeholderURL(for: temp.appendingPathComponent("Ops.txt"))
    precondition(placeholderURL.pathExtension == "placeholder")
    try! NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: notes)
    precondition(FileManager.default.fileExists(atPath: placeholderURL.path))
    try? FileManager.default.removeItem(at: placeholderURL)
    try! NSFileProviderManager._writeLinuxPlaceholderJSON(at: placeholderURL, withMetadata: notes)
    try? FileManager.default.removeItem(at: placeholderURL)
    let importDir = temp.appendingPathComponent("import", isDirectory: true)
    try! FileManager.default.createDirectory(at: importDir, withIntermediateDirectories: true)
    try! Data("imported".utf8).write(to: importDir.appendingPathComponent("Imported.txt"))
    let importDomain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("imported"),
        displayName: "Imported"
    )
    fileProviderAwait { try await NSFileProviderManager.import(importDomain, fromDirectoryAt: importDir) }
    var removeCompletion: (any Error)? = NSFileProviderError(.cannotSynchronize)
    fileProviderWaitOnce { done in
        NSFileProviderManager.remove(importDomain) { error in
            removeCompletion = error
            done()
        }
    }
    precondition(removeCompletion == nil)
}

