@_spi(OpenUIKitHost) import FileProvider
import Foundation
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

private func requireCode(_ error: any Error, _ code: NSFileProviderError.Code) {
    guard let typed = error as? NSFileProviderError else {
        fatalError("expected NSFileProviderError, got \(error)")
    }
    precondition(typed.code == code)
    precondition(typed.errorCode == code.rawValue)
    precondition(NSFileProviderError.errorDomain == NSFileProviderErrorDomain)
}

private func requireFailClosed(
    _ work: () async throws -> Void,
    _ code: NSFileProviderError.Code
) async {
    do {
        try await work()
        fatalError("expected fail-closed \(code)")
    } catch {
        requireCode(error, code)
    }
}

private func waitOnce(_ work: (@escaping () -> Void) -> Void) {
    let gate = DispatchSemaphore(value: 0)
    work { gate.signal() }
    gate.wait()
}

private func exerciseOptionSet<T: OptionSet & Hashable>(_ a: T, _ b: T)
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

private final class RuntimeCounter: @unchecked Sendable {
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

private final class RuntimeItem: NSObject, NSFileProviderItemProtocol, NSFileProviderItemDecorating {
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

private final class RuntimeObserver: NSObject, NSFileProviderEnumerationObserver,
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

private final class RuntimeEnumerator: NSObject, NSFileProviderEnumerator {
    let stored: [any NSFileProviderItemProtocol]
    var syncAnchor: NSFileProviderSyncAnchor?
    private var invalid = false

    init(items: [any NSFileProviderItemProtocol]) {
        self.stored = items
    }

    func invalidate() {
        invalid = true
    }

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

private final class RuntimeServiceSource: NSObject, NSFileProviderServiceSource {
    let serviceName: NSFileProviderServiceName
    let isRestricted: Bool

    init(serviceName: NSFileProviderServiceName, isRestricted: Bool = true) {
        self.serviceName = serviceName
        self.isRestricted = isRestricted
    }
}

enum FileProviderRuntime {
    static func main() async {
        print("CURSOR_SWIFT_ENVIRONMENT_OK swift=6.2.4 target=linux products=clean")
        NSFileProviderManager._resetLocalHostForTesting()

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
        precondition(NSFileProviderFavoriteRankUnranked == UInt64.max)
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
        precondition(
            NSFileProviderError.providerDomainTemporarilyUnavailable
                == .providerDomainTemporarilyUnavailable
        )
        precondition(
            NSFileProviderError.localVersionConflictingWithServer
                == .localVersionConflictingWithServer
        )
        precondition(
            NSFileProviderError.applicationExtensionNotFound == .applicationExtensionNotFound
        )
        precondition(NSFileProviderErrorDomain == "NSFileProviderErrorDomain")
        precondition(NSFileProviderErrorCollidingItemKey == "NSFileProviderErrorCollidingItemKey")
        precondition(NSFileProviderErrorItemKey == "NSFileProviderErrorItemKey")
        precondition(
            NSFileProviderErrorNonExistentItemIdentifierKey
                == "NSFileProviderErrorNonExistentItemIdentifierKey"
        )

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
        _ = NSFileProviderError.Code(rawValue: -1000)
        _ = NSFileProviderError.Code.notAuthenticated.hashValue

        exerciseOptionSet(
            NSFileProviderCreateItemOptions.mayAlreadyExist,
            .deletionConflicted
        )
        exerciseOptionSet(NSFileProviderDeleteItemOptions.recursive, .recursive)
        exerciseOptionSet(
            NSFileProviderDomain.TestingModes.alwaysEnabled,
            .interactive
        )
        exerciseOptionSet(
            NSFileProviderFileSystemFlags.userReadable,
            [.userWritable, .userExecutable, .hidden, .pathExtensionHidden]
        )
        exerciseOptionSet(
            NSFileProviderItemCapabilities.allowsReading,
            [
                .allowsWriting, .allowsRenaming, .allowsReparenting, .allowsTrashing,
                .allowsDeleting, .allowsEvicting, .allowsAddingSubItems,
                .allowsContentEnumerating,
            ]
        )
        exerciseOptionSet(
            NSFileProviderItemFields.contents,
            [
                .filename, .parentItemIdentifier, .lastUsedDate, .tagData, .favoriteRank,
                .creationDate, .contentModificationDate, .fileSystemFlags,
                .extendedAttributes, .typeAndCreator,
            ]
        )
        exerciseOptionSet(
            NSFileProviderModifyItemOptions.failOnConflict,
            [.mayAlreadyExist, .isImmediateUploadRequestByPresentingApplication]
        )
        precondition(NSFileProviderItemCapabilities.allowsAll.contains(.allowsDeleting))
        precondition(NSFileProviderContentPolicy.inherited != .downloadLazilyAndEvictOnRemoteUpdate)
        precondition(NSFileProviderContentPolicy(rawValue: 0) == .inherited)
        precondition(NSFileProviderManager.DomainRemovalMode(rawValue: 0) == .removeAll)
        precondition(NSFileProviderManager.DomainRemovalMode.removeAll == DomainRemovalAlias)
        precondition(
            !(NSFileProviderManager.DomainRemovalMode.removeAll
                != NSFileProviderManager.DomainRemovalMode.removeAll)
        )
        precondition(NSFileProviderTestingOperationSide(rawValue: 0) == .disk)
        precondition(NSFileProviderTestingOperationSide(rawValue: 1) == .fileProvider)
        precondition(NSFileProviderTestingOperationType(rawValue: 0) == .ingestion)
        precondition(NSFileProviderTestingOperationType(rawValue: 1) == .lookup)
        precondition(NSFileProviderTestingOperationType(rawValue: 2) == .creation)
        precondition(NSFileProviderTestingOperationType(rawValue: 3) == .modification)
        precondition(NSFileProviderTestingOperationType(rawValue: 4) == .deletion)
        precondition(NSFileProviderTestingOperationType(rawValue: 5) == .contentFetch)
        precondition(NSFileProviderTestingOperationType(rawValue: 6) == .childrenEnumeration)
        precondition(NSFileProviderTestingOperationType(rawValue: 7) == .collisionResolution)
        var sideHasher = Hasher()
        NSFileProviderTestingOperationSide.disk.hash(into: &sideHasher)
        NSFileProviderTestingOperationType.creation.hash(into: &sideHasher)
        NSFileProviderContentPolicy.inherited.hash(into: &sideHasher)
        NSFileProviderManager.DomainRemovalMode.removeAll.hash(into: &sideHasher)
        _ = sideHasher.finalize()
        _ = NSFileProviderTestingOperationSide.disk.hashValue
        _ = NSFileProviderTestingOperationType.lookup.hashValue
        _ = NSFileProviderContentPolicy.inherited.hashValue
        _ = NSFileProviderManager.DomainRemovalMode.removeAll.hashValue
        _ = NSFileProviderError.Code.filenameCollision.hashValue
        precondition(NSFileProviderTestingOperationSide.disk != .fileProvider)
        precondition(NSFileProviderTestingOperationType.ingestion != .lookup)

        let root = NSFileProviderItemIdentifier.rootContainer
        let trash = NSFileProviderItemIdentifier.trashContainer
        let working = NSFileProviderItemIdentifier.workingSet
        precondition(root.rawValue == "NSFileProviderRootContainerItemIdentifier")
        precondition(trash.rawValue == "NSFileProviderTrashContainerItemIdentifier")
        precondition(working.rawValue == "NSFileProviderWorkingSetContainerItemIdentifier")
        precondition(root != trash)
        precondition(NSFileProviderItemIdentifier("id").rawValue == "id")
        precondition(NSFileProviderItemIdentifier(rawValue: "id2").rawValue == "id2")
        precondition(NSFileProviderDomainIdentifier(rawValue: "domain").rawValue == "domain")
        precondition(NSFileProviderDomainIdentifier("domain2") != NSFileProviderDomainIdentifier("x"))
        precondition(NSFileProviderExtensionActionIdentifier("action").rawValue == "action")
        precondition(NSFileProviderExtensionActionIdentifier(rawValue: "a2").rawValue == "a2")
        precondition(NSFileProviderItemDecorationIdentifier("badge").rawValue == "badge")
        precondition(NSFileProviderItemDecorationIdentifier(rawValue: "b2").rawValue == "b2")
        precondition(
            NSFileProviderUserInfoKey.experimentID.rawValue
                == "NSFileProviderUserInfoExperimentIDKey"
        )
        precondition(NSFileProviderUserInfoKey(rawValue: "k").rawValue == "k")
        precondition(NSFileProviderUserInfoKey("k2").rawValue == "k2")
        let pageName = NSFileProviderPage.sortedByName
        let pageDate = NSFileProviderPage.sortedByDate
        precondition(pageName != pageDate)
        precondition(
            NSFileProviderPage.initialPageSortedByName.length
                == Data("NSFileProviderInitialPageSortedByName".utf8).count
        )
        precondition(
            NSFileProviderPage.initialPageSortedByDate.length
                == Data("NSFileProviderInitialPageSortedByDate".utf8).count
        )
        let pageRaw = NSFileProviderPage(rawValue: Data("name:0".utf8))
        let pageAlt = NSFileProviderPage(Data("name:0".utf8))
        precondition(pageRaw == pageAlt)
        let anchor = NSFileProviderSyncAnchor(Data([0x01, 0x02]))
        precondition(anchor.rawValue.count == 2)
        precondition(NSFileProviderSyncAnchor(rawValue: Data([0x03])) != anchor)
        for value in [
            NSFileProviderDomainIdentifier("h"),
            NSFileProviderItemIdentifier("h"),
        ] as [AnyHashable] {
            _ = value.hashValue
        }
        var idHasher = Hasher()
        NSFileProviderDomainIdentifier("h").hash(into: &idHasher)
        NSFileProviderExtensionActionIdentifier("h").hash(into: &idHasher)
        NSFileProviderItemDecorationIdentifier("h").hash(into: &idHasher)
        NSFileProviderItemIdentifier("h").hash(into: &idHasher)
        pageName.hash(into: &idHasher)
        anchor.hash(into: &idHasher)
        NSFileProviderUserInfoKey("h").hash(into: &idHasher)
        _ = idHasher.finalize()
        _ = NSFileProviderDomainIdentifier("h").hashValue
        _ = NSFileProviderExtensionActionIdentifier("h").hashValue
        _ = NSFileProviderItemDecorationIdentifier("h").hashValue
        _ = NSFileProviderItemIdentifier("h").hashValue
        _ = pageName.hashValue
        _ = anchor.hashValue
        _ = NSFileProviderUserInfoKey("h").hashValue
        precondition(NSFileProviderExtensionActionIdentifier("a") != NSFileProviderExtensionActionIdentifier("b"))
        precondition(NSFileProviderItemDecorationIdentifier("a") != NSFileProviderItemDecorationIdentifier("b"))
        precondition(NSFileProviderUserInfoKey("a") != NSFileProviderUserInfoKey("b"))

        let typeCreator = NSFileProviderTypeAndCreator(type: 0x54455854, creator: 0x68656C6F)
        precondition(typeCreator.type == 0x54455854)
        precondition(typeCreator.creator == 0x68656C6F)
        _ = NSFileProviderTypeAndCreator()
        let version = NSFileProviderItemVersion(
            contentVersion: Data([1]),
            metadataVersion: Data([2])
        )
        precondition(NSFileProviderItemVersion.beforeFirstSyncComponent.isEmpty)
        precondition(version.contentVersion == Data([1]))
        precondition(version.metadataVersion == Data([2]))

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

        let postedDomainChange = RuntimeCounter()
        let postedMaterialized = RuntimeCounter()
        let postedPending = RuntimeCounter()
        let center = NotificationCenter.default
        let domainToken = center.addObserver(
            forName: .fileProviderDomainDidChange,
            object: nil,
            queue: nil
        ) { _ in postedDomainChange.increment() }
        let materializedToken = center.addObserver(
            forName: .fileProviderMaterializedSetDidChange,
            object: nil,
            queue: nil
        ) { _ in postedMaterialized.increment() }
        let pendingToken = center.addObserver(
            forName: .fileProviderPendingSetDidChange,
            object: nil,
            queue: nil
        ) { _ in postedPending.increment() }
        defer {
            center.removeObserver(domainToken)
            center.removeObserver(materializedToken)
            center.removeObserver(pendingToken)
        }
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

        precondition(NSFileProviderManager(for: domain2) == nil)
        precondition(NSFileProviderManager(forDomain: domain2) == nil)

        try! await NSFileProviderManager.add(domain)
        var addCompletion: (any Error)? = NSFileProviderError(.cannotSynchronize)
        waitOnce { done in
            NSFileProviderManager.add(domain2) { error in
                addCompletion = error
                done()
            }
        }
        precondition(addCompletion == nil)
        let listed = try! await NSFileProviderManager.domains()
        precondition(listed.contains { $0.identifier == domain.identifier })
        var listedHandler: [NSFileProviderDomain] = []
        waitOnce { done in
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
        let progress = manager.globalProgress(for: .downloading)
        precondition(progress.totalUnitCount == 1)

        let defaultManager = NSFileProviderManager.default
        let unhostedMaterialized = defaultManager.enumeratorForMaterializedItems()
        let unhostedPending: any NSFileProviderPendingSetEnumerator =
            defaultManager.enumeratorForPendingItems()
        let unhostedObserver = RuntimeObserver()
        waitOnce { done in
            unhostedObserver.onFinish = done
            unhostedMaterialized.enumerateItems(for: unhostedObserver, startingAt: .sortedByName)
        }
        requireCode(unhostedObserver.error!, .providerNotFound)
        let pendingDefaultObserver = RuntimeObserver()
        waitOnce { done in
            pendingDefaultObserver.onFinish = done
            unhostedPending.enumerateItems(for: pendingDefaultObserver, startingAt: .sortedByName)
        }
        requireCode(pendingDefaultObserver.error!, .providerNotFound)
        _ = unhostedPending.domainVersion
        _ = unhostedPending.isMaximumSizeReached
        _ = unhostedPending.refreshInterval
        unhostedMaterialized.invalidate()
        unhostedPending.invalidate()

        let provider = manager._localReplicatedExtension() as! FileProviderLocalReplicatedExtension
        let request = NSFileProviderRequest(
            domainVersion: provider.domainVersion,
            isFileViewerRequest: false,
            isSystemRequest: true
        )
        precondition(request.isSystemRequest)
        precondition(!request.isFileViewerRequest)
        precondition(request.domainVersion != nil)
        _ = provider.domainVersion
        _ = provider.userInfo

        let notes = RuntimeItem(
            itemIdentifier: NSFileProviderItemIdentifier("file-1"),
            parentItemIdentifier: root,
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
        notes.typeAndCreator = typeCreator
        let contentsURL = temp.appendingPathComponent("Notes.txt")
        try! Data("hello notes".utf8).write(to: contentsURL)

        var created: NSFileProviderItem?
        var remaining = NSFileProviderItemFields()
        var shouldFetch = false
        var createError: (any Error)?
        waitOnce { done in
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
                createError = error
                done()
            }
        }
        precondition(createError == nil)
        precondition(created?.filename == "Notes.txt")
        precondition(remaining.isEmpty)
        precondition(!shouldFetch)

        var collisionItem: NSFileProviderItem?
        var collisionError: (any Error)?
        waitOnce { done in
            _ = provider.createItem(
                basedOn: notes,
                fields: [.filename, .parentItemIdentifier],
                contents: nil,
                options: [],
                request: request
            ) { item, _, _, error in
                collisionItem = item
                collisionError = error
                done()
            }
        }
        precondition(collisionItem == nil)
        requireCode(collisionError!, .filenameCollision)

        var reused: NSFileProviderItem?
        waitOnce { done in
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

        let folder = RuntimeItem(
            itemIdentifier: NSFileProviderItemIdentifier("folder-1"),
            parentItemIdentifier: root,
            filename: "Inbox"
        )
        folder.typeIdentifier = "public.folder"
        waitOnce { done in
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

        let child = RuntimeItem(
            itemIdentifier: NSFileProviderItemIdentifier("child-1"),
            parentItemIdentifier: folder.itemIdentifier,
            filename: "Child.txt"
        )
        waitOnce { done in
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

        var fetchedURL: URL?
        waitOnce { done in
            _ = provider.fetchContents(
                for: notes.itemIdentifier,
                version: version,
                request: request
            ) { url, item, error in
                precondition(error == nil)
                fetchedURL = url
                precondition(item?.filename == "Notes.txt")
                done()
            }
        }
        precondition(fetchedURL != nil)

        waitOnce { done in
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

        let renamed = RuntimeItem(
            itemIdentifier: notes.itemIdentifier,
            parentItemIdentifier: root,
            filename: "NotesRenamed.txt"
        )
        renamed.itemVersion = created?.itemVersion ?? version
        waitOnce { done in
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

        let conflicted = RuntimeItem(
            itemIdentifier: notes.itemIdentifier,
            parentItemIdentifier: root,
            filename: "NotesConflict.txt"
        )
        waitOnce { done in
            _ = provider.modifyItem(
                conflicted,
                baseVersion: NSFileProviderItemVersion(
                    contentVersion: Data([9]),
                    metadataVersion: Data([9])
                ),
                changedFields: [.filename],
                contents: nil,
                options: [.failOnConflict],
                request: request
            ) { _, _, _, error in
                requireCode(error!, .localVersionConflictingWithServer)
                done()
            }
        }

        waitOnce { done in
            _ = provider.deleteItem(
                identifier: folder.itemIdentifier,
                baseVersion: version,
                options: [],
                request: request
            ) { error in
                requireCode(error!, .directoryNotEmpty)
                done()
            }
        }
        waitOnce { done in
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

        let enumerator = try! provider.enumerator(for: .rootContainer, request: request)
        let pageObserver = RuntimeObserver()
        pageObserver.suggestedPageSize = 1
        waitOnce { done in
            pageObserver.onFinish = done
            enumerator.enumerateItems(for: pageObserver, startingAt: .sortedByName)
        }
        precondition(pageObserver.error == nil)
        precondition(!pageObserver.items.isEmpty)
        let dateObserver = RuntimeObserver()
        waitOnce { done in
            dateObserver.onFinish = done
            enumerator.enumerateItems(for: dateObserver, startingAt: .sortedByDate)
        }
        precondition(dateObserver.error == nil)
        var currentAnchor: NSFileProviderSyncAnchor?
        waitOnce { done in
            enumerator.currentSyncAnchor { anchor in
                currentAnchor = anchor
                done()
            }
        }
        let changeObserver = RuntimeObserver()
        waitOnce { done in
            changeObserver.onFinish = done
            enumerator.enumerateChanges(
                for: changeObserver,
                from: currentAnchor ?? NSFileProviderSyncAnchor(Data("0".utf8))
            )
        }
        precondition(changeObserver.finishedAnchor != nil)
        precondition(!changeObserver.moreComing)
        let expiredObserver = RuntimeObserver()
        waitOnce { done in
            expiredObserver.onFinish = done
            enumerator.enumerateChanges(for: expiredObserver, from: anchor)
        }
        requireCode(expiredObserver.error!, .syncAnchorExpired)

        try! await manager.signalEnumerator(for: .rootContainer)
        try! await manager.waitForChanges(below: .rootContainer)
        var stabilizeError: (any Error)? = NSFileProviderError(.cannotSynchronize)
        waitOnce { done in
            manager.waitForStabilization { error in
                stabilizeError = error
                done()
            }
        }
        precondition(stabilizeError == nil)

        let visible = try! await manager.getUserVisibleURL(for: notes.itemIdentifier)
        precondition(visible.path.contains("nextcloud"))
        var lookedUpItem: NSFileProviderItemIdentifier?
        var lookedUpDomain: NSFileProviderDomainIdentifier?
        waitOnce { done in
            NSFileProviderManager.getIdentifierForUserVisibleFile(at: visible) { item, domainID, error in
                precondition(error == nil)
                lookedUpItem = item
                lookedUpDomain = domainID
                done()
            }
        }
        precondition(lookedUpItem == notes.itemIdentifier)
        precondition(lookedUpDomain == domain.identifier)

        try! await manager.reimportItems(below: .rootContainer)
        try! await manager.requestModification(
            of: [.lastUsedDate],
            forItemWithIdentifier: notes.itemIdentifier,
            options: []
        )
        try! await manager.evictItem(identifier: notes.itemIdentifier)
        try! await manager.signalErrorResolved(NSFileProviderError(.serverUnreachable))
        let session = URLSession(configuration: .ephemeral)
        let task = session.dataTask(with: URL(string: "https://example.invalid")!)
        try! await manager.register(task, forItemWithIdentifier: notes.itemIdentifier)

        var downloadError: (any Error)? = NSFileProviderError(.cannotSynchronize)
        waitOnce { done in
            manager.requestDownloadForItem(withIdentifier: notes.itemIdentifier) { error in
                downloadError = error
                done()
            }
        }
        // Evicted item still has metadata; fetchContents succeeds with nil file or item.
        _ = downloadError
        do {
            try await manager.requestDownloadForItem(
                withIdentifier: NSFileProviderItemIdentifier("missing-download")
            )
            fatalError("missing download must fail")
        } catch {
            requireCode(error, .noSuchItem)
        }

        domain.testingModes = [.alwaysEnabled, .interactive]
        try! await NSFileProviderManager.add(domain)
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
        let runErrors = try! manager.run(testing)
        precondition(runErrors.isEmpty)

        let materialized: any NSFileProviderEnumerator = manager.enumeratorForMaterializedItems()
        let pending: any NSFileProviderPendingSetEnumerator = manager.enumeratorForPendingItems()
        let materializedObserver = RuntimeObserver()
        waitOnce { done in
            materializedObserver.onFinish = done
            materialized.enumerateItems(for: materializedObserver, startingAt: .sortedByName)
        }
        precondition(materializedObserver.error == nil)
        let pendingObserver = RuntimeObserver()
        waitOnce { done in
            pendingObserver.onFinish = done
            pending.enumerateItems(for: pendingObserver, startingAt: .sortedByName)
        }
        precondition(pendingObserver.error == nil)
        materialized.invalidate()
        pending.invalidate()

        let placeholderURL = NSFileProviderManager.placeholderURL(
            for: temp.appendingPathComponent("Notes.txt")
        )
        precondition(placeholderURL.pathExtension == "placeholder")
        try! NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: notes)
        precondition(FileManager.default.fileExists(atPath: placeholderURL.path))
        try? FileManager.default.removeItem(at: placeholderURL)
        try! NSFileProviderExtension.writePlaceholder(
            at: placeholderURL,
            withMetadata: [URLResourceKey.nameKey: "Notes.txt"]
        )
        precondition(FileManager.default.fileExists(atPath: placeholderURL.path))
        try? FileManager.default.removeItem(at: placeholderURL)
        try! NSFileProviderManager._writeLinuxPlaceholderJSON(
            at: placeholderURL,
            withMetadata: notes
        )
        try? FileManager.default.removeItem(at: placeholderURL)

        let asItem: any NSFileProviderItemProtocol = notes
        precondition(asItem.filename == "Notes.txt" || asItem.filename == "NotesRenamed.txt")
        precondition(asItem.parentItemIdentifier == root)
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

        let nsError = NSError.fileProviderErrorForCollision(with: asItem)
        precondition(nsError.domain == NSFileProviderErrorDomain)
        precondition(nsError.code == NSFileProviderError.Code.filenameCollision.rawValue)
        precondition(nsError.userInfo[NSFileProviderErrorCollidingItemKey] != nil)
        precondition(nsError.userInfo[NSFileProviderErrorItemKey] != nil)
        let missing = NSError.fileProviderErrorForNonExistentItem(
            withIdentifier: NSFileProviderItemIdentifier("missing")
        )
        precondition(missing.code == NSFileProviderError.Code.noSuchItem.rawValue)
        precondition(
            missing.userInfo[NSFileProviderErrorNonExistentItemIdentifierKey] as? String == "missing"
        )
        let rejected = NSError.fileProviderErrorForRejectedDeletion(of: asItem)
        precondition(rejected.code == NSFileProviderError.Code.deletionRejected.rawValue)
        precondition(rejected.userInfo[NSFileProviderErrorItemKey] != nil)

        let runtimeEnumerator: any NSFileProviderEnumerator = RuntimeEnumerator(items: [asItem])
        let observer = RuntimeObserver()
        runtimeEnumerator.enumerateItems(for: observer, startingAt: .sortedByName)
        precondition(observer.items.count == 1)
        let boxed = runtimeEnumerator as! RuntimeEnumerator
        boxed.syncAnchor = NSFileProviderSyncAnchor(Data("0".utf8))
        var runtimeAnchor: NSFileProviderSyncAnchor?
        boxed.currentSyncAnchor { current in
            runtimeAnchor = current
        }
        precondition(runtimeAnchor != nil)
        let protocolChangeObserver = RuntimeObserver()
        boxed.enumerateChanges(for: protocolChangeObserver, from: boxed.syncAnchor!)
        precondition(protocolChangeObserver.items.count == 1)
        boxed.invalidate()
        let dead = RuntimeObserver()
        boxed.enumerateItems(for: dead, startingAt: .sortedByName)
        requireCode(dead.error!, .cannotSynchronize)

        let extensionInstance = NSFileProviderExtension(domain: domain2)
        precondition(extensionInstance.providerIdentifier.contains("fileprovider"))
        precondition(extensionInstance.documentStorageURL.path.contains("Documents/Nextcloud"))
        precondition(extensionInstance.domain?.identifier == domain2.identifier)
        let mapped = extensionInstance.urlForItem(withPersistentIdentifier: notes.itemIdentifier)
        precondition(mapped != nil)
        precondition(
            extensionInstance.persistentIdentifierForItem(at: mapped!) == notes.itemIdentifier
        )
        do {
            _ = try extensionInstance.item(for: notes.itemIdentifier)
            fatalError("item(for:) must fail closed")
        } catch {
            requireCode(error, .noSuchItem)
        }
        do {
            _ = try extensionInstance.enumerator(for: root)
            fatalError("enumerator(for:) must fail closed")
        } catch {
            requireCode(error, .applicationExtensionNotFound)
        }
        await requireFailClosed({
            try await extensionInstance.providePlaceholder(
                at: temp.appendingPathComponent("Inbox.txt")
            )
        }, .providerNotFound)
        await requireFailClosed({
            try await extensionInstance.startProvidingItem(at: mapped!)
        }, .providerNotFound)
        extensionInstance.itemChanged(at: mapped!)
        extensionInstance.stopProvidingItem(at: mapped!)
        await requireFailClosed({
            _ = try await extensionInstance.importDocument(
                at: contentsURL,
                toParentItemIdentifier: root
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.createDirectory(
                withName: "Dir",
                inParentItemIdentifier: root
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.renameItem(
                withIdentifier: notes.itemIdentifier,
                toName: "X"
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.reparentItem(
                withIdentifier: notes.itemIdentifier,
                toParentItemWithIdentifier: root,
                newName: nil
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.trashItem(withIdentifier: notes.itemIdentifier)
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.untrashItem(
                withIdentifier: notes.itemIdentifier,
                toParentItemIdentifier: root
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            try await extensionInstance.deleteItem(withIdentifier: notes.itemIdentifier)
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.setFavoriteRank(
                1,
                forItemIdentifier: notes.itemIdentifier
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.setLastUsedDate(
                Date(),
                forItemIdentifier: notes.itemIdentifier
            )
        }, .applicationExtensionNotFound)
        await requireFailClosed({
            _ = try await extensionInstance.setTagData(
                Data(),
                forItemIdentifier: notes.itemIdentifier
            )
        }, .applicationExtensionNotFound)
        let services = try! extensionInstance.supportedServiceSources(for: notes.itemIdentifier)
        precondition(services.isEmpty)
        precondition(
            NSFileProviderExtension.placeholderURL(for: temp.appendingPathComponent("Inbox.txt"))
                .pathExtension == "placeholder"
        )

        var thumbItemCount = 0
        var thumbFinishCount = 0
        waitOnce { done in
            _ = extensionInstance.fetchThumbnails(
                for: [notes.itemIdentifier],
                requestedSize: CGSize(width: 32, height: 32),
                perThumbnailCompletionHandler: { _, data, error in
                    thumbItemCount += 1
                    precondition(data == nil)
                    requireCode(error!, .providerNotFound)
                },
                completionHandler: { error in
                    thumbFinishCount += 1
                    requireCode(error!, .providerNotFound)
                    done()
                }
            )
        }
        precondition(thumbItemCount == 1)
        precondition(thumbFinishCount == 1)

        waitOnce { done in
            _ = provider.fetchThumbnails(
                for: [notes.itemIdentifier],
                requestedSize: CGSize(width: 16, height: 16),
                perThumbnailCompletionHandler: { _, data, error in
                    precondition(data == nil)
                    requireCode(error!, .providerNotFound)
                },
                completionHandler: { error in
                    requireCode(error!, .providerNotFound)
                    done()
                }
            )
        }
        waitOnce { done in
            _ = provider.supportedServiceSources(for: notes.itemIdentifier) { sources, error in
                precondition(sources == nil)
                requireCode(error!, .providerNotFound)
                done()
            }
        }
        waitOnce { done in
            _ = provider.performAction(
                identifier: NSFileProviderExtensionActionIdentifier("ping"),
                onItemsWithIdentifiers: [notes.itemIdentifier]
            ) { error in
                requireCode(error!, .applicationExtensionNotFound)
                done()
            }
        }
        waitOnce { done in
            provider.importDidFinish {
                provider.materializedItemsDidChange {
                    provider.pendingItemsDidChange {
                        done()
                    }
                }
            }
        }
        provider.invalidate()

        let serviceSource = RuntimeServiceSource(
            serviceName: NSFileProviderServiceName("svc"),
            isRestricted: true
        )
        precondition(serviceSource.serviceName.rawValue == "svc")
        precondition(serviceSource.isRestricted)
        _ = NSFileProviderServiceName("svc")

        var serviceCount = 0
        waitOnce { done in
            manager.getService(
                named: NSFileProviderServiceName("svc"),
                for: root
            ) { service, error in
                serviceCount += 1
                precondition(service == nil)
                requireCode(error!, .providerNotFound)
                done()
            }
        }
        precondition(serviceCount == 1)

        let importDir = temp.appendingPathComponent("import", isDirectory: true)
        try! FileManager.default.createDirectory(at: importDir, withIntermediateDirectories: true)
        try! Data("imported".utf8).write(to: importDir.appendingPathComponent("Imported.txt"))
        let importDomain = NSFileProviderDomain(
            identifier: NSFileProviderDomainIdentifier("imported"),
            displayName: "Imported"
        )
        try! await NSFileProviderManager.import(importDomain, fromDirectoryAt: importDir)

        var removeCompletion: (any Error)? = NSFileProviderError(.cannotSynchronize)
        waitOnce { done in
            NSFileProviderManager.remove(importDomain) { error in
                removeCompletion = error
                done()
            }
        }
        precondition(removeCompletion == nil)
        try! await NSFileProviderManager.remove(domain2)
        let preserved = try! await NSFileProviderManager.remove(domain, mode: .removeAll)
        _ = preserved

        var removeAllCount = 0
        waitOnce { done in
            NSFileProviderManager.removeAllDomains { error in
                removeAllCount += 1
                precondition(error == nil)
                done()
            }
        }
        precondition(removeAllCount == 1)
        precondition(postedMaterialized.snapshot == 0)
        precondition(postedPending.snapshot == 0)

        print("FILEPROVIDER_AGENT_RUNTIME_OK")
    }
}

private let DomainRemovalAlias = NSFileProviderManager.DomainRemovalMode.removeAll

let fileProviderRuntimeGate = DispatchSemaphore(value: 0)
Task {
    await FileProviderRuntime.main()
    fileProviderRuntimeGate.signal()
}
fileProviderRuntimeGate.wait()
