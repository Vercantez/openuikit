@_spi(OpenUIKitHost) import FileProvider
import Foundation

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

private final class RuntimeItem: NSObject, NSFileProviderItemProtocol {
    let itemIdentifier: NSFileProviderItemIdentifier
    let parentItemIdentifier: NSFileProviderItemIdentifier
    let filename: String
    var documentSize: NSNumber?
    var capabilities: NSFileProviderItemCapabilities
    var typeIdentifier: String?
    var itemVersion: NSFileProviderItemVersion?
    var contentPolicy: NSFileProviderContentPolicy

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
        _ = moreComing
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

enum FileProviderRuntime {
    static func main() async {
        NSFileProviderManager._installHostAdapter(nil)

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
        precondition(NSFileProviderError.noSuchItem == .noSuchItem)
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
        _ = typedCollision.localizedDescription
        precondition(!typedCollision.errorUserInfo.isEmpty)
        precondition(typedCollision.code == .filenameCollision)
        precondition(typedCollision.errorCode == -1001)
        precondition(typedCollision.userInfo["path"] as? String == "/tmp/a")

        let capabilities: NSFileProviderItemCapabilities = [.allowsReading, .allowsWriting]
        precondition(capabilities.contains(.allowsReading))
        precondition(capabilities.contains(.allowsAddingSubItems))
        precondition(NSFileProviderItemCapabilities.allowsAll.contains(.allowsDeleting))
        precondition(!NSFileProviderCreateItemOptions().contains(.mayAlreadyExist))
        var fields: NSFileProviderItemFields = [.filename, .contents]
        fields.insert(.tagData)
        precondition(fields.contains(.filename))
        fields.remove(.contents)
        precondition(!fields.contains(.contents))
        precondition(
            NSFileProviderFileSystemFlags.userReadable.union(.userWritable).contains(.userReadable)
        )
        precondition(
            NSFileProviderModifyItemOptions.failOnConflict.isDisjoint(with: .mayAlreadyExist)
        )
        precondition(NSFileProviderContentPolicy.inherited != .downloadLazilyAndEvictOnRemoteUpdate)
        precondition(NSFileProviderContentPolicy(rawValue: 0) == .inherited)
        precondition(NSFileProviderManager.DomainRemovalMode(rawValue: 0) == .removeAll)
        precondition(NSFileProviderTestingOperationSide(rawValue: 1) == .fileProvider)
        precondition(NSFileProviderTestingOperationType(rawValue: 6) == .childrenEnumeration)

        let root = NSFileProviderItemIdentifier.rootContainer
        let trash = NSFileProviderItemIdentifier.trashContainer
        let working = NSFileProviderItemIdentifier.workingSet
        precondition(root.rawValue == "NSFileProviderRootContainerItemIdentifier")
        precondition(trash.rawValue == "NSFileProviderTrashContainerItemIdentifier")
        precondition(working.rawValue == "NSFileProviderWorkingSetContainerItemIdentifier")
        precondition(root != trash)
        precondition(NSFileProviderItemIdentifier("id").rawValue == "id")
        precondition(NSFileProviderDomainIdentifier(rawValue: "domain").rawValue == "domain")
        precondition(NSFileProviderExtensionActionIdentifier("action").rawValue == "action")
        precondition(NSFileProviderItemDecorationIdentifier("badge").rawValue == "badge")
        precondition(
            NSFileProviderUserInfoKey.experimentID.rawValue
                == "NSFileProviderUserInfoExperimentIDKey"
        )
        _ = NSFileProviderPage.sortedByName
        _ = NSFileProviderPage.sortedByDate
        precondition(
            NSFileProviderPage.initialPageSortedByName.length
                == Data("NSFileProviderInitialPageSortedByName".utf8).count
        )
        let anchor = NSFileProviderSyncAnchor(Data([0x01, 0x02]))
        precondition(anchor.rawValue.count == 2)

        let typeCreator = NSFileProviderTypeAndCreator(type: 0x54455854, creator: 0)
        precondition(typeCreator.type == 0x54455854)
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

        var postedDomainChange = 0
        var postedMaterialized = 0
        var postedPending = 0
        let center = NotificationCenter.default
        let domainToken = center.addObserver(
            forName: .fileProviderDomainDidChange,
            object: nil,
            queue: nil
        ) { _ in postedDomainChange += 1 }
        let materializedToken = center.addObserver(
            forName: .fileProviderMaterializedSetDidChange,
            object: nil,
            queue: nil
        ) { _ in postedMaterialized += 1 }
        let pendingToken = center.addObserver(
            forName: .fileProviderPendingSetDidChange,
            object: nil,
            queue: nil
        ) { _ in postedPending += 1 }
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

        await requireFailClosed({
            try await NSFileProviderManager.add(domain)
        }, .providerNotFound)
        await requireFailClosed({
            _ = try await NSFileProviderManager.domains()
        }, .providerNotFound)
        await requireFailClosed({
            try await NSFileProviderManager.remove(domain)
        }, .providerNotFound)
        await requireFailClosed({
            _ = try await NSFileProviderManager.remove(domain, mode: .removeAll)
        }, .providerNotFound)
        precondition(postedDomainChange == 0)
        precondition(postedMaterialized == 0)
        precondition(postedPending == 0)

        precondition(NSFileProviderManager(for: domain2) == nil)
        precondition(NSFileProviderManager(forDomain: domain2) == nil)

        let manager = NSFileProviderManager.default
        precondition(manager.providerIdentifier == "org.openuikit.fileprovider.unhosted")
        let temp = try! manager.temporaryDirectoryURL()
        precondition(temp.path.contains("OpenUIKitFileProvider"))
        precondition(manager.documentStorageURL.path.contains("OpenUIKitFileProvider"))
        let progress = manager.globalProgress(for: .downloading)
        precondition(progress.totalUnitCount == 0)
        precondition(progress.completedUnitCount == 0)

        let materialized: any NSFileProviderEnumerator = manager.enumeratorForMaterializedItems()
        let pending: any NSFileProviderPendingSetEnumerator = manager.enumeratorForPendingItems()
        let materializedObserver = RuntimeObserver()
        waitOnce { done in
            materializedObserver.onFinish = done
            materialized.enumerateItems(for: materializedObserver, startingAt: .sortedByName)
        }
        requireCode(materializedObserver.error!, .providerNotFound)
        let pendingObserver = RuntimeObserver()
        waitOnce { done in
            pendingObserver.onFinish = done
            pending.enumerateItems(for: pendingObserver, startingAt: .sortedByName)
        }
        requireCode(pendingObserver.error!, .providerNotFound)
        let changeObserver = RuntimeObserver()
        waitOnce { done in
            changeObserver.onFinish = done
            materialized.enumerateChanges(for: changeObserver, from: anchor)
        }
        requireCode(changeObserver.error!, .providerNotFound)
        var materializedAnchorCalls = 0
        waitOnce { done in
            materialized.currentSyncAnchor { current in
                materializedAnchorCalls += 1
                precondition(current == nil)
                done()
            }
        }
        precondition(materializedAnchorCalls == 1)
        materialized.invalidate()
        pending.invalidate()

        await requireFailClosed({
            _ = try await manager.getUserVisibleURL(for: root)
        }, .providerNotFound)
        await requireFailClosed({
            try await manager.evictItem(identifier: root)
        }, .nonEvictable)
        await requireFailClosed({
            try await manager.signalEnumerator(for: root)
        }, .providerNotFound)
        await requireFailClosed({
            try await NSFileProviderManager.import(domain, fromDirectoryAt: temp)
        }, .applicationExtensionNotFound)

        var removeAllCount = 0
        var removeAllSawSyncNested = false
        waitOnce { done in
            NSFileProviderManager.removeAllDomains { error in
                removeAllCount += 1
                requireCode(error!, .providerNotFound)
                var nestedCount = 0
                let nested = DispatchSemaphore(value: 0)
                NSFileProviderManager.removeAllDomains { nestedError in
                    nestedCount += 1
                    requireCode(nestedError!, .providerNotFound)
                    nested.signal()
                }
                if nestedCount != 0 {
                    removeAllSawSyncNested = true
                }
                nested.wait()
                precondition(nestedCount == 1)
                done()
            }
        }
        precondition(removeAllCount == 1)
        precondition(!removeAllSawSyncNested)

        var identityCount = 0
        waitOnce { done in
            NSFileProviderManager.getIdentifierForUserVisibleFile(at: temp) { item, domainID, error in
                identityCount += 1
                precondition(item == nil)
                precondition(domainID == nil)
                requireCode(error!, .providerNotFound)
                done()
            }
        }
        precondition(identityCount == 1)

        var serviceCount = 0
        var serviceSawSyncNested = false
        waitOnce { done in
            manager.getService(
                named: NSFileProviderServiceName("svc"),
                for: root
            ) { service, error in
                serviceCount += 1
                precondition(service == nil)
                requireCode(error!, .providerNotFound)
                var nestedCount = 0
                let nested = DispatchSemaphore(value: 0)
                manager.getService(
                    named: NSFileProviderServiceName("svc"),
                    for: root
                ) { _, nestedError in
                    nestedCount += 1
                    requireCode(nestedError!, .providerNotFound)
                    nested.signal()
                }
                if nestedCount != 0 {
                    serviceSawSyncNested = true
                }
                nested.wait()
                precondition(nestedCount == 1)
                done()
            }
        }
        precondition(serviceCount == 1)
        precondition(!serviceSawSyncNested)

        var stabilizeCount = 0
        waitOnce { done in
            manager.waitForStabilization { error in
                stabilizeCount += 1
                requireCode(error!, .providerNotFound)
                done()
            }
        }
        precondition(stabilizeCount == 1)

        var downloadCount = 0
        waitOnce { done in
            manager.requestDownloadForItem(withIdentifier: root) { error in
                downloadCount += 1
                requireCode(error!, .providerNotFound)
                done()
            }
        }
        precondition(downloadCount == 1)
        await requireFailClosed({
            try await manager.requestDownloadForItem(withIdentifier: root)
        }, .providerNotFound)

        let item = RuntimeItem(
            itemIdentifier: NSFileProviderItemIdentifier("file-1"),
            parentItemIdentifier: root,
            filename: "Notes.txt"
        )
        item.documentSize = 12
        item.capabilities = [.allowsReading, .allowsWriting, .allowsDeleting]
        item.typeIdentifier = "public.plain-text"
        item.itemVersion = version
        item.contentPolicy = .downloadLazilyAndEvictOnRemoteUpdate
        let asItem: any NSFileProviderItemProtocol = item
        precondition(asItem.filename == "Notes.txt")
        precondition(asItem.parentItemIdentifier == root)
        precondition(asItem.capabilities.contains(.allowsWriting))
        precondition(asItem.itemIdentifier.rawValue == "file-1")
        precondition(asItem.documentSize?.intValue == 12)
        precondition(asItem.typeIdentifier == "public.plain-text")
        precondition(asItem.itemVersion?.contentVersion == Data([1]))
        precondition(asItem.contentPolicy == .downloadLazilyAndEvictOnRemoteUpdate)

        let placeholderURL = NSFileProviderManager.placeholderURL(
            for: temp.appendingPathComponent("Notes.txt")
        )
        precondition(placeholderURL.pathExtension == "placeholder")
        precondition(
            NSFileProviderExtension.placeholderURL(for: temp.appendingPathComponent("Inbox.txt"))
                .pathExtension == "placeholder"
        )
        do {
            try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: asItem)
            fatalError("public writePlaceholder must fail closed without a host adapter")
        } catch {
            requireCode(error, .providerNotFound)
        }
        do {
            try NSFileProviderExtension.writePlaceholder(
                at: placeholderURL,
                withMetadata: [:]
            )
            fatalError("extension writePlaceholder must fail closed without a host adapter")
        } catch {
            requireCode(error, .providerNotFound)
        }
        precondition(!FileManager.default.fileExists(atPath: placeholderURL.path))

        try! NSFileProviderManager._writeLinuxPlaceholderJSON(
            at: placeholderURL,
            withMetadata: asItem
        )
        precondition(FileManager.default.fileExists(atPath: placeholderURL.path))
        try? FileManager.default.removeItem(at: placeholderURL)

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

        let enumerator: any NSFileProviderEnumerator = RuntimeEnumerator(items: [asItem])
        let observer = RuntimeObserver()
        enumerator.enumerateItems(for: observer, startingAt: .sortedByName)
        precondition(observer.items.count == 1)
        precondition(observer.items[0].filename == "Notes.txt")
        precondition(observer.error == nil)
        let runtimeEnumerator = enumerator as! RuntimeEnumerator
        runtimeEnumerator.syncAnchor = anchor
        var currentAnchor: NSFileProviderSyncAnchor?
        runtimeEnumerator.currentSyncAnchor { current in
            currentAnchor = current
        }
        precondition(currentAnchor == anchor)
        let protocolChangeObserver = RuntimeObserver()
        runtimeEnumerator.enumerateChanges(for: protocolChangeObserver, from: anchor)
        precondition(protocolChangeObserver.items.count == 1)
        precondition(protocolChangeObserver.finishedAnchor == anchor)
        runtimeEnumerator.invalidate()
        let dead = RuntimeObserver()
        runtimeEnumerator.enumerateItems(for: dead, startingAt: .sortedByName)
        requireCode(dead.error!, .cannotSynchronize)

        let extensionInstance = NSFileProviderExtension(domain: domain2)
        precondition(extensionInstance.providerIdentifier.contains("fileprovider"))
        precondition(extensionInstance.documentStorageURL.path.contains("Documents/Nextcloud"))
        let mapped = extensionInstance.urlForItem(withPersistentIdentifier: item.itemIdentifier)
        precondition(mapped != nil)
        precondition(
            extensionInstance.persistentIdentifierForItem(at: mapped!) == item.itemIdentifier
        )
        do {
            _ = try extensionInstance.item(for: item.itemIdentifier)
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
        let services = try! extensionInstance.supportedServiceSources(for: item.itemIdentifier)
        precondition(services.isEmpty)

        var thumbItemCount = 0
        var thumbFinishCount = 0
        var thumbSawSync = false
        waitOnce { done in
            let thumbProgress = extensionInstance.fetchThumbnails(
                for: [item.itemIdentifier],
                requestedSize: CGSize(width: 32, height: 32),
                perThumbnailCompletionHandler: { _, data, error in
                    thumbItemCount += 1
                    precondition(data == nil)
                    requireCode(error!, .providerNotFound)
                    precondition(thumbFinishCount == 0)
                },
                completionHandler: { error in
                    thumbFinishCount += 1
                    requireCode(error!, .providerNotFound)
                    precondition(thumbItemCount == 1)
                    done()
                }
            )
            _ = thumbProgress
            if thumbItemCount != 0 || thumbFinishCount != 0 {
                thumbSawSync = true
            }
        }
        precondition(thumbItemCount == 1)
        precondition(thumbFinishCount == 1)
        precondition(!thumbSawSync)

        let request = NSFileProviderRequest(isSystemRequest: true)
        precondition(request.isSystemRequest)
        precondition(!request.isFileViewerRequest)
        _ = NSFileProviderServiceName("svc")
        precondition(postedDomainChange == 0)
        precondition(postedMaterialized == 0)
        precondition(postedPending == 0)

        print("FILEPROVIDER_AGENT_RUNTIME_OK")
    }
}

let fileProviderRuntimeGate = DispatchSemaphore(value: 0)
Task {
    await FileProviderRuntime.main()
    fileProviderRuntimeGate.signal()
}
fileProviderRuntimeGate.wait()
