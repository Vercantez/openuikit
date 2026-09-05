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


func testLocalEnumeratorPaging() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("pages"),
        displayName: "Pages"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    let request = NSFileProviderRequest(domainVersion: provider.domainVersion, isSystemRequest: true)
    let temp = try! manager.temporaryDirectoryURL()
    let contentsURL = temp.appendingPathComponent("A.txt")
    try! Data("a".utf8).write(to: contentsURL)
    for name in ["B.txt", "A.txt", "C.txt"] {
        let item = FileProviderAgentItem(
            itemIdentifier: NSFileProviderItemIdentifier(name),
            parentItemIdentifier: .rootContainer,
            filename: name
        )
        fileProviderWaitOnce { done in
            _ = provider.createItem(
                basedOn: item,
                fields: [.filename, .parentItemIdentifier, .contents],
                contents: contentsURL,
                options: [],
                request: request
            ) { _, _, _, error in
                precondition(error == nil)
                done()
            }
        }
    }
    let enumerator = try! provider.enumerator(for: .rootContainer, request: request)
    let pageObserver = FileProviderAgentObserver()
    pageObserver.suggestedPageSize = 1
    fileProviderWaitOnce { done in
        pageObserver.onFinish = done
        enumerator.enumerateItems(for: pageObserver, startingAt: .sortedByName)
    }
    precondition(pageObserver.error == nil)
    precondition(!pageObserver.items.isEmpty)
    let dateObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        dateObserver.onFinish = done
        enumerator.enumerateItems(for: dateObserver, startingAt: .sortedByDate)
    }
    precondition(dateObserver.error == nil)
    var currentAnchor: NSFileProviderSyncAnchor?
    fileProviderWaitOnce { done in
        enumerator.currentSyncAnchor { anchor in
            currentAnchor = anchor
            done()
        }
    }
    let changeObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        changeObserver.onFinish = done
        enumerator.enumerateChanges(
            for: changeObserver,
            from: currentAnchor ?? NSFileProviderSyncAnchor(Data("0".utf8))
        )
    }
    precondition(changeObserver.finishedAnchor != nil)
    precondition(!changeObserver.moreComing)
    let expiredObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        expiredObserver.onFinish = done
        enumerator.enumerateChanges(for: expiredObserver, from: NSFileProviderSyncAnchor(Data([0x01, 0x02])))
    }
    fileProviderRequireCode(expiredObserver.error!, .syncAnchorExpired)
    let materialized: any NSFileProviderEnumerator = manager.enumeratorForMaterializedItems()
    let pending: any NSFileProviderPendingSetEnumerator = manager.enumeratorForPendingItems()
    _ = pending.domainVersion
    _ = pending.isMaximumSizeReached
    _ = pending.refreshInterval
    let materializedObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        materializedObserver.onFinish = done
        materialized.enumerateItems(for: materializedObserver, startingAt: .sortedByName)
    }
    precondition(materializedObserver.error == nil)
    let pendingObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        pendingObserver.onFinish = done
        pending.enumerateItems(for: pendingObserver, startingAt: .sortedByName)
    }
    precondition(pendingObserver.error == nil)
    materialized.invalidate()
    pending.invalidate()
    enumerator.invalidate()
}


func testEnumeratorProtocolWitnesses() {
    let item = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("enum-1"),
        parentItemIdentifier: .rootContainer,
        filename: "Enum.txt"
    )
    let runtimeEnumerator: any NSFileProviderEnumerator = FileProviderAgentEnumerator(items: [item])
    let observer = FileProviderAgentObserver()
    runtimeEnumerator.enumerateItems(for: observer, startingAt: .sortedByName)
    precondition(observer.items.count == 1)
    let boxed = runtimeEnumerator as! FileProviderAgentEnumerator
    boxed.syncAnchor = NSFileProviderSyncAnchor(Data("0".utf8))
    var runtimeAnchor: NSFileProviderSyncAnchor?
    boxed.currentSyncAnchor { current in runtimeAnchor = current }
    precondition(runtimeAnchor != nil)
    let protocolChangeObserver = FileProviderAgentObserver()
    boxed.enumerateChanges(for: protocolChangeObserver, from: boxed.syncAnchor!)
    precondition(protocolChangeObserver.items.count == 1)
    protocolChangeObserver.didDeleteItems(withIdentifiers: [item.itemIdentifier])
    precondition(protocolChangeObserver.deleted.count == 1)
    boxed.invalidate()
    let dead = FileProviderAgentObserver()
    boxed.enumerateItems(for: dead, startingAt: .sortedByName)
    fileProviderRequireCode(dead.error!, .cannotSynchronize)
    let defaultManager = NSFileProviderManager.default
    let unhostedMaterialized = defaultManager.enumeratorForMaterializedItems()
    let unhostedPending: any NSFileProviderPendingSetEnumerator = defaultManager.enumeratorForPendingItems()
    let unhostedObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        unhostedObserver.onFinish = done
        unhostedMaterialized.enumerateItems(for: unhostedObserver, startingAt: .sortedByName)
    }
    fileProviderRequireCode(unhostedObserver.error!, .providerNotFound)
    let pendingDefaultObserver = FileProviderAgentObserver()
    fileProviderWaitOnce { done in
        pendingDefaultObserver.onFinish = done
        unhostedPending.enumerateItems(for: pendingDefaultObserver, startingAt: .sortedByName)
    }
    fileProviderRequireCode(pendingDefaultObserver.error!, .providerNotFound)
    _ = unhostedPending.domainVersion
    _ = unhostedPending.isMaximumSizeReached
    _ = unhostedPending.refreshInterval
    unhostedMaterialized.invalidate()
    unhostedPending.invalidate()
}

