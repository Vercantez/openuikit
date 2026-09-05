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
func testCreateItemOptionsAlgebra() {
    fileProviderExerciseOptionSet(
        NSFileProviderCreateItemOptions.mayAlreadyExist,
        .deletionConflicted
    )
}
func testDeleteItemOptionsAlgebra() {
    fileProviderExerciseOptionSet(NSFileProviderDeleteItemOptions.recursive, .recursive)
}
func testModifyItemOptionsAlgebra() {
    fileProviderExerciseOptionSet(
        NSFileProviderModifyItemOptions.failOnConflict,
        [.mayAlreadyExist, .isImmediateUploadRequestByPresentingApplication]
    )
}
func testFileSystemFlagsAlgebra() {
    fileProviderExerciseOptionSet(
        NSFileProviderFileSystemFlags.userReadable,
        [.userWritable, .userExecutable, .hidden, .pathExtensionHidden]
    )
}
func testItemCapabilitiesAlgebra() {
    fileProviderExerciseOptionSet(
        NSFileProviderItemCapabilities.allowsReading,
        [
            .allowsWriting, .allowsRenaming, .allowsReparenting, .allowsTrashing,
            .allowsDeleting, .allowsEvicting, .allowsAddingSubItems,
            .allowsContentEnumerating,
        ]
    )
}
func testItemFieldsAlgebra() {
    fileProviderExerciseOptionSet(
        NSFileProviderItemFields.contents,
        [
            .filename, .parentItemIdentifier, .lastUsedDate, .tagData, .favoriteRank,
            .creationDate, .contentModificationDate, .fileSystemFlags,
            .extendedAttributes, .typeAndCreator,
        ]
    )
}
func testDomainTestingModesAlgebra() {
    fileProviderExerciseOptionSet(
        NSFileProviderDomain.TestingModes.alwaysEnabled,
        .interactive
    )
}
func testErrorBridgingAndFactories() {
    let collision = NSFileProviderError.Code.filenameCollision
    let typedCollision = NSFileProviderError(collision, userInfo: ["path": "/tmp/a"])
    precondition(collision ~= typedCollision)
    precondition(typedCollision == NSFileProviderError(.filenameCollision, userInfo: ["path": "/tmp/a"]))
    precondition(typedCollision != NSFileProviderError(.filenameCollision, userInfo: ["path": "/tmp/b"]))
    var hasher = Hasher()
    typedCollision.hash(into: &hasher)
    _ = hasher.finalize()
    _ = typedCollision.hashValue
    _ = typedCollision.localizedDescription
    precondition(!typedCollision.errorUserInfo.isEmpty)
    precondition(typedCollision.code == .filenameCollision)
    precondition(typedCollision.errorCode == -1001)
    precondition(typedCollision.userInfo["path"] as? String == "/tmp/a")
    precondition(NSFileProviderError.errorDomain == NSFileProviderErrorDomain)
    let item = FileProviderAgentItem(
        itemIdentifier: NSFileProviderItemIdentifier("missing"),
        parentItemIdentifier: .rootContainer,
        filename: "Gone.txt"
    )
    let asItem: NSFileProviderItem = item
    let nsError = NSError.fileProviderErrorForCollision(with: asItem)
    precondition(nsError.domain == NSFileProviderErrorDomain)
    precondition(nsError.code == NSFileProviderError.Code.filenameCollision.rawValue)
    precondition(nsError.userInfo[NSFileProviderErrorCollidingItemKey] != nil)
    precondition(nsError.userInfo[NSFileProviderErrorItemKey] != nil)
    let missing = NSError.fileProviderErrorForNonExistentItem(
        withIdentifier: NSFileProviderItemIdentifier("missing")
    )
    precondition(missing.code == NSFileProviderError.Code.noSuchItem.rawValue)
    precondition(missing.userInfo[NSFileProviderErrorNonExistentItemIdentifierKey] as? String == "missing")
    let rejected = NSError.fileProviderErrorForRejectedDeletion(of: asItem)
    precondition(rejected.code == NSFileProviderError.Code.deletionRejected.rawValue)
    precondition(rejected.userInfo[NSFileProviderErrorItemKey] != nil)
}
func testDomainValueSemantics() {
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("nextcloud"),
        displayName: "Nextcloud"
    )
    precondition(domain.userEnabled)
    precondition(domain.supportsSyncingTrash)
    domain.testingModes = [.alwaysEnabled]
    precondition(domain.testingModes.contains(.alwaysEnabled))
    let domain2 = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("nextcloud-path"),
        displayName: "Nextcloud",
        pathRelativeToDocumentStorage: "Documents/Nextcloud"
    )
    precondition(domain2.pathRelativeToDocumentStorage == "Documents/Nextcloud")
    precondition(domain.identifier.rawValue == "nextcloud")
    precondition(domain.displayName == "Nextcloud")
    domain.backingStoreIdentity = Data("store".utf8)
    precondition(domain.backingStoreIdentity != nil)
    domain.isReplicated = true
    precondition(domain.isReplicated)
    let domainCopy = NSFileProviderDomain(
        identifier: domain.identifier,
        displayName: domain.displayName
    )
    precondition(domain.isEqual(domainCopy))
    _ = domain.hash
}
func testDomainVersionComparable() {
    let v0 = NSFileProviderDomainVersion()
    let v1 = v0.next()
    precondition(v0 < v1)
    precondition(v1 > v0)
    precondition(v0 <= v1)
    precondition(v1 >= v0)
    _ = v0..<v1
    _ = v0...v1
    _ = v0...
    _ = ...v1
    _ = ..<v1
    precondition(v0 != v1)
    let archived = try! NSKeyedArchiver.archivedData(
        withRootObject: v1,
        requiringSecureCoding: true
    )
    let decoded = try! NSKeyedUnarchiver.unarchivedObject(
        ofClass: NSFileProviderDomainVersion.self,
        from: archived
    )
    precondition(decoded == v1)
    let request = NSFileProviderRequest(
        domainVersion: v1,
        isFileViewerRequest: false,
        isSystemRequest: true
    )
    precondition(request.isSystemRequest)
    precondition(!request.isFileViewerRequest)
    precondition(request.domainVersion != nil)
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
func testItemProtocolProperties() {
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
    notes.itemVersion = NSFileProviderItemVersion(contentVersion: Data([1]), metadataVersion: Data([2]))
    notes.contentPolicy = .downloadLazilyAndEvictOnRemoteUpdate
    notes.fileSystemFlags = [.userReadable, .userWritable]
    notes.tagData = Data("red".utf8)
    notes.favoriteRank = 1
    notes.extendedAttributes = ["com.example": Data([1])]
    notes.typeAndCreator = NSFileProviderTypeAndCreator(type: 0x54455854, creator: 0x68656C6F)
    let asItem: any NSFileProviderItemProtocol = notes
    let aliased: NSFileProviderItem = notes
    _ = aliased
    precondition(asItem.filename == "Notes.txt")
    precondition(asItem.parentItemIdentifier == .rootContainer)
    precondition(asItem.capabilities.contains(.allowsWriting))
    precondition(asItem.itemIdentifier.rawValue == "file-1")
    precondition(asItem.documentSize?.intValue == 12)
    precondition(asItem.typeIdentifier == "public.plain-text")
    precondition(asItem.itemVersion?.contentVersion == Data([1]))
    precondition(asItem.contentPolicy == .downloadLazilyAndEvictOnRemoteUpdate)
    precondition(asItem.childItemCount?.intValue == 0)
    precondition(asItem.contentModificationDate != nil)
    precondition(asItem.creationDate != nil)
    precondition(asItem.isDownloaded)
    precondition(!asItem.isDownloading)
    precondition(asItem.downloadingError == nil)
    precondition(asItem.extendedAttributes["com.example"] == Data([1]))
    precondition(asItem.favoriteRank?.intValue == 1)
    precondition(asItem.fileSystemFlags.contains(.userReadable))
    precondition(asItem.lastUsedDate != nil)
    precondition(asItem.mostRecentEditorNameComponents != nil)
    precondition(asItem.isMostRecentVersionDownloaded)
    precondition(asItem.ownerNameComponents != nil)
    precondition(!asItem.isShared)
    precondition(!asItem.isSharedByCurrentUser)
    precondition(asItem.symlinkTargetPath == nil)
    precondition(asItem.tagData == Data("red".utf8))
    precondition(!asItem.isTrashed)
    precondition(asItem.typeAndCreator.type == 0x54455854)
    precondition(asItem.isUploaded)
    precondition(!asItem.isUploading)
    precondition(asItem.uploadingError == nil)
    precondition(asItem.userInfo?["k"] as? String == "v")
    precondition(asItem.versionIdentifier == Data([0]))
    let decorating: any NSFileProviderItemDecorating = notes
    precondition(decorating.decorations?.first?.rawValue == "badge")
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
func testTestingOperations() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("testing"),
        displayName: "Testing"
    )
    domain.testingModes = [.alwaysEnabled, .interactive]
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let testing = try! manager.listAvailableTestingOperations()
    precondition(!testing.isEmpty)
    precondition(testing.contains { $0.type == .lookup })
    precondition(testing.contains { $0.type == .ingestion })
    precondition(testing.contains { $0.type == .creation })
    precondition(testing.contains { $0.type == .modification })
    precondition(testing.contains { $0.type == .deletion })
    precondition(testing.contains { $0.type == .contentFetch })
    precondition(testing.contains { $0.type == .childrenEnumeration })
    precondition(testing.contains { $0.type == .collisionResolution })
    for operation in testing {
        switch operation.type {
        case .lookup:
            let lookup = operation as! NSFileProviderTestingLookup
            _ = lookup.itemIdentifier
            _ = lookup.side
        case .ingestion:
            let ingestion = operation as! NSFileProviderTestingIngestion
            _ = ingestion.item
            _ = ingestion.itemIdentifier
            _ = ingestion.side
        case .creation:
            let creation = operation as! NSFileProviderTestingCreation
            _ = creation.domainVersion
            _ = creation.sourceItem
            _ = creation.targetSide
        case .modification:
            let modification = operation as! NSFileProviderTestingModification
            _ = modification.changedFields
            _ = modification.domainVersion
            _ = modification.sourceItem
            _ = modification.targetItemBaseVersion
            _ = modification.targetItemIdentifier
            _ = modification.targetSide
        case .deletion:
            let deletion = operation as! NSFileProviderTestingDeletion
            _ = deletion.domainVersion
            _ = deletion.sourceItemIdentifier
            _ = deletion.targetItemBaseVersion
            _ = deletion.targetItemIdentifier
            _ = deletion.targetSide
        case .contentFetch:
            let fetch = operation as! NSFileProviderTestingContentFetch
            _ = fetch.itemIdentifier
            _ = fetch.side
        case .childrenEnumeration:
            let children = operation as! NSFileProviderTestingChildrenEnumeration
            _ = children.itemIdentifier
            _ = children.side
        case .collisionResolution:
            let collision = operation as! NSFileProviderTestingCollisionResolution
            _ = collision.renamedItem
            _ = collision.side
        @unknown default:
            break
        }
    }
    let runErrors = try! manager.run(testing)
    precondition(runErrors.isEmpty)
}
func testServiceFailClosed() {
    NSFileProviderManager._resetLocalHostForTesting()
    let domain = NSFileProviderDomain(
        identifier: NSFileProviderDomainIdentifier("svc"),
        displayName: "Service"
    )
    fileProviderAwait { try await NSFileProviderManager.add(domain) }
    let manager = NSFileProviderManager(for: domain)!
    let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
    let notesID = NSFileProviderItemIdentifier("file-1")
    let serviceSource = FileProviderAgentServiceSource(
        serviceName: NSFileProviderServiceName("svc"),
        isRestricted: true
    )
    precondition(serviceSource.serviceName.rawValue == "svc")
    precondition(serviceSource.isRestricted)
    var serviceCount = 0
    fileProviderWaitOnce { done in
        manager.getService(named: NSFileProviderServiceName("svc"), for: .rootContainer) { service, error in
            serviceCount += 1
            precondition(service == nil)
            fileProviderRequireCode(error!, .providerNotFound)
            done()
        }
    }
    precondition(serviceCount == 1)
    fileProviderWaitOnce { done in
        _ = provider.supportedServiceSources(for: notesID) { sources, error in
            precondition(sources == nil)
            fileProviderRequireCode(error!, .providerNotFound)
            done()
        }
    }
}
print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
NSFileProviderManager._resetLocalHostForTesting()
testEnumAndOptionSetValues()
testIdentifierAndPageValues()
testHashableInequality()
testCreateItemOptionsAlgebra()
testDeleteItemOptionsAlgebra()
testModifyItemOptionsAlgebra()
testFileSystemFlagsAlgebra()
testItemCapabilitiesAlgebra()
testItemFieldsAlgebra()
testDomainTestingModesAlgebra()
testErrorBridgingAndFactories()
testDomainValueSemantics()
testDomainVersionComparable()
testManagerDomainRegistry()
testManagerUserVisibleAndSignals()
testManagerPlaceholdersDownloadsAndImport()
testReplicatedCreateModifyDelete()
testReplicatedFetchAndLifecycle()
testLocalEnumeratorPaging()
testEnumeratorProtocolWitnesses()
testItemProtocolProperties()
testExtensionFailClosedActions()
testThumbnailAndCustomActionFailClosed()
testTestingOperations()
testServiceFailClosed()
print("FILEPROVIDER_AGENT_RUNTIME_OK")
