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


func testEnumAndOptionSetValues() {
    precondition(NSFileProviderError.Code.notAuthenticated.rawValue == -1000)
    precondition(NSFileProviderError.Code.filenameCollision.rawValue == -1001)
    precondition(NSFileProviderError.Code.syncAnchorExpired.rawValue == -1002)
    precondition(NSFileProviderError.Code.pageExpired == .syncAnchorExpired)
    precondition(NSFileProviderError.pageExpired == .syncAnchorExpired)
    precondition(NSFileProviderError.Code.insufficientQuota.rawValue == -1003)
    precondition(NSFileProviderError.Code.serverUnreachable.rawValue == -1004)
    precondition(NSFileProviderError.Code.noSuchItem.rawValue == -1005)
    precondition(NSFileProviderError.Code.deletionRejected.rawValue == -1006)
    precondition(NSFileProviderError.Code.directoryNotEmpty.rawValue == -1007)
    precondition(NSFileProviderError.Code.providerNotFound.rawValue == -1008)
    precondition(NSFileProviderError.Code.providerDomainNotFound.rawValue == -1009)
    precondition(NSFileProviderError.Code.cannotSynchronize.rawValue == -1010)
    precondition(NSFileProviderError.Code.nonEvictableChildren.rawValue == -1011)
    precondition(NSFileProviderError.Code.unsyncedEdits.rawValue == -1012)
    precondition(NSFileProviderError.Code.nonEvictable.rawValue == -1013)
    precondition(NSFileProviderError.Code.excludedFromSync.rawValue == -1015)
    precondition(NSFileProviderError.Code.domainDisabled.rawValue == -1016)
    precondition(NSFileProviderError.Code.providerDomainTemporarilyUnavailable.rawValue == -1017)
    precondition(NSFileProviderError.Code.localVersionConflictingWithServer.rawValue == -1018)
    precondition(NSFileProviderError.Code.applicationExtensionNotFound.rawValue == -1019)
    precondition(NSFileProviderError.notAuthenticated == .notAuthenticated)
    precondition(NSFileProviderError.filenameCollision == .filenameCollision)
    precondition(NSFileProviderError.syncAnchorExpired == .syncAnchorExpired)
    precondition(NSFileProviderError.insufficientQuota == .insufficientQuota)
    precondition(NSFileProviderError.serverUnreachable == .serverUnreachable)
    precondition(NSFileProviderError.noSuchItem == .noSuchItem)
    precondition(NSFileProviderError.deletionRejected == .deletionRejected)
    precondition(NSFileProviderError.directoryNotEmpty == .directoryNotEmpty)
    precondition(NSFileProviderError.providerNotFound == .providerNotFound)
    precondition(NSFileProviderError.providerDomainNotFound == .providerDomainNotFound)
    precondition(NSFileProviderError.cannotSynchronize == .cannotSynchronize)
    precondition(NSFileProviderError.nonEvictableChildren == .nonEvictableChildren)
    precondition(NSFileProviderError.unsyncedEdits == .unsyncedEdits)
    precondition(NSFileProviderError.nonEvictable == .nonEvictable)
    precondition(NSFileProviderError.excludedFromSync == .excludedFromSync)
    precondition(NSFileProviderError.domainDisabled == .domainDisabled)
    precondition(NSFileProviderError.providerDomainTemporarilyUnavailable == .providerDomainTemporarilyUnavailable)
    precondition(NSFileProviderError.localVersionConflictingWithServer == .localVersionConflictingWithServer)
    precondition(NSFileProviderError.applicationExtensionNotFound == .applicationExtensionNotFound)
    precondition(NSFileProviderErrorDomain == "NSFileProviderErrorDomain")
    precondition(NSFileProviderErrorCollidingItemKey == "NSFileProviderErrorCollidingItemKey")
    precondition(NSFileProviderErrorItemKey == "NSFileProviderErrorItemKey")
    precondition(NSFileProviderErrorNonExistentItemIdentifierKey == "NSFileProviderErrorNonExistentItemIdentifierKey")
    precondition(NSFileProviderFavoriteRankUnranked == UInt64.max)
    precondition(NSFileProviderContentPolicy.inherited.rawValue == 0)
    precondition(NSFileProviderContentPolicy.downloadLazilyAndEvictOnRemoteUpdate.rawValue == 2)
    _ = NSFileProviderContentPolicy(rawValue: 0)
    precondition(NSFileProviderCreateItemOptions.mayAlreadyExist.rawValue == 1)
    precondition(NSFileProviderCreateItemOptions.deletionConflicted.rawValue == 2)
    precondition(NSFileProviderDeleteItemOptions.recursive.rawValue == 1)
    precondition(NSFileProviderModifyItemOptions.mayAlreadyExist.rawValue == 1)
    precondition(NSFileProviderModifyItemOptions.failOnConflict.rawValue == 2)
    precondition(NSFileProviderModifyItemOptions.isImmediateUploadRequestByPresentingApplication.rawValue == 4)
    precondition(NSFileProviderFileSystemFlags.userExecutable.rawValue == 1)
    precondition(NSFileProviderFileSystemFlags.userReadable.rawValue == 2)
    precondition(NSFileProviderFileSystemFlags.userWritable.rawValue == 4)
    precondition(NSFileProviderFileSystemFlags.hidden.rawValue == 8)
    precondition(NSFileProviderFileSystemFlags.pathExtensionHidden.rawValue == 16)
    precondition(NSFileProviderItemCapabilities.allowsReading.rawValue == 1)
    precondition(NSFileProviderItemCapabilities.allowsWriting.rawValue == 2)
    precondition(NSFileProviderItemCapabilities.allowsRenaming.rawValue == 4)
    precondition(NSFileProviderItemCapabilities.allowsReparenting.rawValue == 8)
    precondition(NSFileProviderItemCapabilities.allowsTrashing.rawValue == 16)
    precondition(NSFileProviderItemCapabilities.allowsDeleting.rawValue == 32)
    precondition(NSFileProviderItemCapabilities.allowsEvicting.rawValue == 64)
    precondition(NSFileProviderItemCapabilities.allowsAddingSubItems == .allowsWriting)
    precondition(NSFileProviderItemCapabilities.allowsContentEnumerating == .allowsReading)
    precondition(NSFileProviderItemCapabilities.allowsAll.contains(.allowsDeleting))
    precondition(NSFileProviderItemFields.contents.rawValue == 1)
    precondition(NSFileProviderItemFields.filename.rawValue == 2)
    precondition(NSFileProviderItemFields.parentItemIdentifier.rawValue == 4)
    precondition(NSFileProviderItemFields.lastUsedDate.rawValue == 8)
    precondition(NSFileProviderItemFields.tagData.rawValue == 16)
    precondition(NSFileProviderItemFields.favoriteRank.rawValue == 32)
    precondition(NSFileProviderItemFields.creationDate.rawValue == 64)
    precondition(NSFileProviderItemFields.contentModificationDate.rawValue == 128)
    precondition(NSFileProviderItemFields.fileSystemFlags.rawValue == 256)
    precondition(NSFileProviderItemFields.extendedAttributes.rawValue == 512)
    precondition(NSFileProviderItemFields.typeAndCreator.rawValue == 1024)
    precondition(NSFileProviderDomain.TestingModes.alwaysEnabled.rawValue == 1)
    precondition(NSFileProviderDomain.TestingModes.interactive.rawValue == 2)
    precondition(NSFileProviderManager.DomainRemovalMode.removeAll.rawValue == 0)
    _ = NSFileProviderManager.DomainRemovalMode(rawValue: 0)
    precondition(NSFileProviderTestingOperationSide.disk.rawValue == 0)
    precondition(NSFileProviderTestingOperationSide.fileProvider.rawValue == 1)
    _ = NSFileProviderTestingOperationSide(rawValue: 0)
    precondition(NSFileProviderTestingOperationType.ingestion.rawValue == 0)
    precondition(NSFileProviderTestingOperationType.lookup.rawValue == 1)
    precondition(NSFileProviderTestingOperationType.creation.rawValue == 2)
    precondition(NSFileProviderTestingOperationType.modification.rawValue == 3)
    precondition(NSFileProviderTestingOperationType.deletion.rawValue == 4)
    precondition(NSFileProviderTestingOperationType.contentFetch.rawValue == 5)
    precondition(NSFileProviderTestingOperationType.childrenEnumeration.rawValue == 6)
    precondition(NSFileProviderTestingOperationType.collisionResolution.rawValue == 7)
    _ = NSFileProviderTestingOperationType(rawValue: 2)
    precondition(
        Notification.Name.fileProviderDomainDidChange.rawValue == "NSFileProviderDomainDidChange"
    )
    precondition(
        Notification.Name.fileProviderMaterializedSetDidChange.rawValue
            == "NSFileProviderMaterializedSetDidChange"
    )
    precondition(
        Notification.Name.fileProviderPendingSetDidChange.rawValue
            == "NSFileProviderPendingSetDidChange"
    )
}


func testIdentifierAndPageValues() {
    precondition(NSFileProviderItemIdentifier.rootContainer.rawValue == "NSFileProviderRootContainerItemIdentifier")
    precondition(NSFileProviderItemIdentifier.trashContainer.rawValue == "NSFileProviderTrashContainerItemIdentifier")
    precondition(NSFileProviderItemIdentifier.workingSet.rawValue == "NSFileProviderWorkingSetContainerItemIdentifier")
    precondition(NSFileProviderItemIdentifier("id").rawValue == "id")
    precondition(NSFileProviderItemIdentifier(rawValue: "id2").rawValue == "id2")
    precondition(NSFileProviderDomainIdentifier(rawValue: "domain").rawValue == "domain")
    precondition(NSFileProviderDomainIdentifier("domain2") != NSFileProviderDomainIdentifier("x"))
    precondition(NSFileProviderExtensionActionIdentifier("action").rawValue == "action")
    precondition(NSFileProviderExtensionActionIdentifier(rawValue: "a2").rawValue == "a2")
    precondition(NSFileProviderItemDecorationIdentifier("badge").rawValue == "badge")
    precondition(NSFileProviderItemDecorationIdentifier(rawValue: "b2").rawValue == "b2")
    precondition(NSFileProviderUserInfoKey.experimentID.rawValue == "NSFileProviderUserInfoExperimentIDKey")
    precondition(NSFileProviderUserInfoKey(rawValue: "k").rawValue == "k")
    precondition(NSFileProviderUserInfoKey("k2").rawValue == "k2")
    let pageName = NSFileProviderPage.sortedByName
    let pageDate = NSFileProviderPage.sortedByDate
    precondition(pageName != pageDate)
    precondition(NSFileProviderPage.initialPageSortedByName.length == Data("NSFileProviderInitialPageSortedByName".utf8).count)
    precondition(NSFileProviderPage.initialPageSortedByDate.length == Data("NSFileProviderInitialPageSortedByDate".utf8).count)
    let pageRaw = NSFileProviderPage(rawValue: Data("name:0".utf8))
    let pageAlt = NSFileProviderPage(Data("name:0".utf8))
    precondition(pageRaw == pageAlt)
    let anchor = NSFileProviderSyncAnchor(Data([0x01, 0x02]))
    precondition(anchor.rawValue.count == 2)
    precondition(NSFileProviderSyncAnchor(rawValue: Data([0x03])) != anchor)
    let typeCreator = NSFileProviderTypeAndCreator(type: 0x54455854, creator: 0x68656C6F)
    precondition(typeCreator.type == 0x54455854)
    precondition(typeCreator.creator == 0x68656C6F)
    _ = NSFileProviderTypeAndCreator()
    let version = NSFileProviderItemVersion(contentVersion: Data([1]), metadataVersion: Data([2]))
    precondition(NSFileProviderItemVersion.beforeFirstSyncComponent.isEmpty)
    precondition(version.contentVersion == Data([1]))
    precondition(version.metadataVersion == Data([2]))
    _ = NSFileProviderServiceName("svc")
}


func testHashableInequality() {
    precondition(NSFileProviderContentPolicy.inherited != .downloadLazilyAndEvictOnRemoteUpdate)
    precondition(NSFileProviderCreateItemOptions.mayAlreadyExist != .deletionConflicted)
    precondition(NSFileProviderDeleteItemOptions.recursive != NSFileProviderDeleteItemOptions())
    precondition(NSFileProviderManager.DomainRemovalMode.removeAll != NSFileProviderManager.DomainRemovalMode(rawValue: 1))
    precondition(!(NSFileProviderManager.DomainRemovalMode.removeAll != .removeAll))
    precondition(NSFileProviderDomain.TestingModes.alwaysEnabled != .interactive)
    precondition(NSFileProviderError(.filenameCollision) != NSFileProviderError(.noSuchItem))
    precondition(NSFileProviderFileSystemFlags.hidden != .userReadable)
    precondition(NSFileProviderItemCapabilities.allowsReading != .allowsWriting)
    precondition(NSFileProviderItemFields.contents != .filename)
    precondition(NSFileProviderModifyItemOptions.failOnConflict != .mayAlreadyExist)
    precondition(NSFileProviderTestingOperationSide.disk != .fileProvider)
    precondition(NSFileProviderTestingOperationType.ingestion != .lookup)
    precondition(NSFileProviderExtensionActionIdentifier("a") != NSFileProviderExtensionActionIdentifier("b"))
    precondition(NSFileProviderItemDecorationIdentifier("a") != NSFileProviderItemDecorationIdentifier("b"))
    precondition(NSFileProviderUserInfoKey("a") != NSFileProviderUserInfoKey("b"))
    var hasher = Hasher()
    NSFileProviderContentPolicy.inherited.hash(into: &hasher)
    NSFileProviderManager.DomainRemovalMode.removeAll.hash(into: &hasher)
    NSFileProviderError.Code.filenameCollision.hash(into: &hasher)
    NSFileProviderTestingOperationSide.disk.hash(into: &hasher)
    NSFileProviderTestingOperationType.creation.hash(into: &hasher)
    NSFileProviderDomainIdentifier("h").hash(into: &hasher)
    NSFileProviderExtensionActionIdentifier("h").hash(into: &hasher)
    NSFileProviderItemDecorationIdentifier("h").hash(into: &hasher)
    NSFileProviderItemIdentifier("h").hash(into: &hasher)
    NSFileProviderPage.sortedByName.hash(into: &hasher)
    NSFileProviderSyncAnchor(Data([1])).hash(into: &hasher)
    NSFileProviderUserInfoKey("h").hash(into: &hasher)
    _ = hasher.finalize()
    _ = NSFileProviderContentPolicy.inherited.hashValue
    _ = NSFileProviderManager.DomainRemovalMode.removeAll.hashValue
    _ = NSFileProviderError.Code.filenameCollision.hashValue
    _ = NSFileProviderTestingOperationSide.disk.hashValue
    _ = NSFileProviderTestingOperationType.lookup.hashValue
    _ = NSFileProviderDomainIdentifier("h").hashValue
    _ = NSFileProviderExtensionActionIdentifier("h").hashValue
    _ = NSFileProviderItemDecorationIdentifier("h").hashValue
    _ = NSFileProviderItemIdentifier("h").hashValue
    _ = NSFileProviderPage.sortedByName.hashValue
    _ = NSFileProviderSyncAnchor(Data([1])).hashValue
    _ = NSFileProviderUserInfoKey("h").hashValue
    _ = NSFileProviderError.Code(rawValue: -1000)
}

