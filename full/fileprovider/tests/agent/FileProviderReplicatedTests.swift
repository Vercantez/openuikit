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


func testReplicatedCreateModifyDelete() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("replicated"),
        displayName: "Replicated"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    _ = provider.domainVersion
    _ = provider.userInfo
    let request = NSFileProviderRequest(domainVersion: provider.domainVersion, isSystemRequest: true)
    let version = NSFileProviderItemVersion(contentVersion: Data([1]), metadataVersion: Data([2]))
    let notes = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("file-1"),
        parentItemIdentifier: .rootContainer,
        filename: "Notes.txt"
    )
    notes.documentSize = 12
    notes.capabilities = [
        .allowsReading, .allowsWriting, .allowsDeleting, .allowsEvicting, .allowsRenaming,
        .allowsReparenting, .allowsTrashing, .allowsAddingSubItems, .allowsContentEnumerating,
    ]
    notes.typeIdentifier = "public.plain-text"
    notes.itemVersion = version
    notes.contentPolicy = .downloadLazilyAndEvictOnRemoteUpdate
    notes.fileSystemFlags = [.userReadable, .userWritable, .userExecutable, .hidden]
    notes.tagData = Data("red".utf8)
    notes.favoriteRank = 1
    notes.extendedAttributes = ["com.example": Data([1])]
    notes.typeAndCreator = NSFileProviderTypeAndCreator(type: 0x54455854, creator: 0x68656C6F)
    let temp = try! manager.temporaryDirectoryURL()
    let contentsURL = temp.appendingPathComponent("Notes.txt")
    try! Data("hello notes".utf8).write(to: contentsURL)
    var created: NSFileProviderItem?
    var remaining = NSFileProviderItemFields()
    var shouldFetch = false
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: notes,
            fields: [
                .filename, .parentItemIdentifier, .contents, .tagData, .favoriteRank,
                .creationDate, .contentModificationDate, .fileSystemFlags,
                .extendedAttributes, .typeAndCreator, .lastUsedDate,
            ],
            contents: contentsURL,
            options: [],
            request: request
        ) { item, fields, fetch, error in
            created = item
            remaining = fields
            shouldFetch = fetch
            precondition(error == nil)
            done()
        }
    }
    precondition(created?.filename == "Notes.txt")
    precondition(remaining.isEmpty)
    precondition(!shouldFetch)
    var collisionError: (any Error)?
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: notes,
            fields: [.filename, .parentItemIdentifier],
            contents: nil,
            options: [],
            request: request
        ) { item, _, _, error in
            precondition(item == nil)
            collisionError = error
            done()
        }
    }
    fileProviderRequireCode(collisionError!, .filenameCollision)
    var reused: NSFileProviderItem?
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: notes,
            fields: [.filename, .parentItemIdentifier],
            contents: nil,
            options: [.mayAlreadyExist],
            request: request
        ) { item, _, _, error in
            reused = item
            precondition(error == nil)
            done()
        }
    }
    precondition(reused?.itemIdentifier == notes.itemIdentifier)
    let folder = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("folder-1"),
        parentItemIdentifier: .rootContainer,
        filename: "Inbox"
    )
    folder.typeIdentifier = "public.folder"
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: folder,
            fields: [.filename, .parentItemIdentifier],
            contents: nil,
            options: [],
            request: request
        ) { _, _, _, error in
            precondition(error == nil)
            done()
        }
    }
    let child = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("child-1"),
        parentItemIdentifier: folder.itemIdentifier,
        filename: "Child.txt"
    )
    fileProviderWaitOnce { done in
        _ = provider.createItem(
            basedOn: child,
            fields: [.filename, .parentItemIdentifier],
            contents: contentsURL,
            options: [.deletionConflicted],
            request: request
        ) { _, _, _, error in
            precondition(error == nil)
            done()
        }
    }
    let renamed = FileProviderAgentItem(
        itemIdentifier: notes.itemIdentifier,
        parentItemIdentifier: .rootContainer,
        filename: "NotesRenamed.txt"
    )
    renamed.itemVersion = created?.itemVersion ?? version
    fileProviderWaitOnce { done in
        _ = provider.modifyItem(
            renamed,
            baseVersion: renamed.itemVersion!,
            changedFields: [.filename],
            contents: nil,
            options: [.mayAlreadyExist, .isImmediateUploadRequestByPresentingApplication],
            request: request
        ) { item, _, _, error in
            precondition(error == nil)
            precondition(item?.filename == "NotesRenamed.txt")
            done()
        }
    }
    let conflicted = FileProviderAgentItem(
        itemIdentifier: notes.itemIdentifier,
        parentItemIdentifier: .rootContainer,
        filename: "NotesConflict.txt"
    )
    fileProviderWaitOnce { done in
        _ = provider.modifyItem(
            conflicted,
            baseVersion: NSFileProviderItemVersion(contentVersion: Data([9]), metadataVersion: Data([9])),
            changedFields: [.filename],
            contents: nil,
            options: [.failOnConflict],
            request: request
        ) { _, _, _, error in
            fileProviderRequireCode(error!, .localVersionConflictingWithServer)
            done()
        }
    }
    fileProviderWaitOnce { done in
        _ = provider.deleteItem(
            identifier: folder.itemIdentifier,
            baseVersion: version,
            options: [],
            request: request
        ) { error in
            fileProviderRequireCode(error!, .directoryNotEmpty)
            done()
        }
    }
    fileProviderWaitOnce { done in
        _ = provider.deleteItem(
            identifier: folder.itemIdentifier,
            baseVersion: version,
            options: [.recursive],
            request: request
        ) { error in
            precondition(error == nil)
            done()
        }
    }
}


func testReplicatedFetchAndLifecycle() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("fetch"),
        displayName: "Fetch"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    let request = NSFileProviderRequest(domainVersion: provider.domainVersion, isSystemRequest: true)
    let version = NSFileProviderItemVersion(contentVersion: Data([1]), metadataVersion: Data([2]))
    let notes = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("fetch-1"),
        parentItemIdentifier: .rootContainer,
        filename: "Fetch.txt"
    )
    let temp = try! manager.temporaryDirectoryURL()
    let contentsURL = temp.appendingPathComponent("Fetch.txt")
    try! Data("fetch-body".utf8).write(to: contentsURL)
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
    var fetchedURL: URL?
    fileProviderWaitOnce { done in
        _ = provider.fetchContents(for: notes.itemIdentifier, version: version, request: request) { url, item, error in
            precondition(error == nil)
            fetchedURL = url
            precondition(item?.filename == "Fetch.txt")
            done()
        }
    }
    precondition(fetchedURL != nil)
    fileProviderWaitOnce { done in
        _ = provider.fetchContents(
            for: notes.itemIdentifier,
            version: version,
            usingExistingContentsAt: contentsURL,
            existingVersion: version,
            request: request
        ) { url, _, error in
            precondition(error == nil)
            precondition(url != nil)
            done()
        }
    }
    fileProviderWaitOnce { done in
        _ = provider.item(for: notes.itemIdentifier, request: request) { item, error in
            precondition(error == nil)
            precondition(item?.itemIdentifier == notes.itemIdentifier)
            done()
        }
    }
    fileProviderWaitOnce { done in
        provider.importDidFinish {
            provider.materializedItemsDidChange {
                provider.pendingItemsDidChange {
                    done()
                }
            }
        }
    }
    provider.invalidate()
}

