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
        precondition(root != trash)
        precondition(working.rawValue.contains("WorkingSet"))
        precondition(NSFileProviderItemIdentifier("id").rawValue == "id")
        precondition(NSFileProviderDomainIdentifier(rawValue: "domain").rawValue == "domain")
        _ = NSFileProviderExtensionActionIdentifier("action")
        _ = NSFileProviderItemDecorationIdentifier("badge")
        _ = NSFileProviderUserInfoKey.experimentID
        _ = NSFileProviderPage.sortedByName
        _ = NSFileProviderPage.sortedByDate
        precondition(
            NSFileProviderPage.initialPageSortedByName.length
                == Data("NSFileProviderInitialPageSortedByName".utf8).count
        )
        let anchor = NSFileProviderSyncAnchor(Data([0x01, 0x02]))
        precondition(anchor.rawValue.count == 2)

        let typeCreator = NSFileProviderTypeAndCreator(type: 0x54455854, creator: 0)
        precondition(typeCreator.type != 0)
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
        _ = domain.identifier
        _ = domain.displayName

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

        precondition(NSFileProviderManager(for: domain2) == nil)
        precondition(NSFileProviderManager(forDomain: domain2) == nil)

        let manager = NSFileProviderManager.default
        precondition(manager.providerIdentifier == "org.openuikit.fileprovider.unhosted")
        let temp = try! manager.temporaryDirectoryURL()
        precondition(temp.path.contains("OpenUIKitFileProvider"))
        _ = manager.documentStorageURL
        _ = manager.globalProgress(for: .downloading)
        let materialized: any NSFileProviderEnumerator = manager.enumeratorForMaterializedItems()
        let pending: any NSFileProviderPendingSetEnumerator = manager.enumeratorForPendingItems()
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

        let item = NSFileProviderEnumeratedItem(
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
        precondition(asItem.capabilities.contains(.allowsWriting))
        precondition(asItem.itemIdentifier.rawValue == "file-1")

        let placeholderURL = NSFileProviderManager.placeholderURL(
            for: temp.appendingPathComponent("Notes.txt")
        )
        precondition(placeholderURL.pathExtension == "placeholder")
        do {
            try NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: asItem)
            fatalError("public writePlaceholder must fail closed without a host adapter")
        } catch {
            requireCode(error, .providerNotFound)
        }
        precondition(!FileManager.default.fileExists(atPath: placeholderURL.path))

        let nsError = NSError.fileProviderErrorForCollision(with: asItem)
        precondition(nsError.domain == NSFileProviderErrorDomain)
        precondition(nsError.code == NSFileProviderError.Code.filenameCollision.rawValue)
        let missing = NSError.fileProviderErrorForNonExistentItem(
            withIdentifier: NSFileProviderItemIdentifier("missing")
        )
        precondition(missing.code == NSFileProviderError.Code.noSuchItem.rawValue)
        let rejected = NSError.fileProviderErrorForRejectedDeletion(of: asItem)
        precondition(rejected.code == NSFileProviderError.Code.deletionRejected.rawValue)

        let enumerator = NSFileProviderMemoryEnumerator(items: [asItem])
        enumerator.syncAnchor = anchor
        let observer = NSFileProviderCollectingObserver()
        enumerator.enumerateItems(for: observer, startingAt: .sortedByName)
        precondition(observer.items.count == 1)
        precondition(observer.items[0].filename == "Notes.txt")
        precondition(observer.error == nil)
        enumerator.currentSyncAnchor { current in
            precondition(current == anchor)
        }
        let changeObserver = NSFileProviderCollectingObserver()
        enumerator.enumerateChanges(for: changeObserver, from: anchor)
        precondition(changeObserver.finishedAnchor == anchor)
        enumerator.invalidate()
        let dead = NSFileProviderCollectingObserver()
        enumerator.enumerateItems(for: dead, startingAt: .sortedByName)
        requireCode(dead.error!, .cannotSynchronize)

        let extensionInstance = NSFileProviderExtension(domain: domain2)
        precondition(extensionInstance.providerIdentifier.contains("fileprovider"))
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
        waitOnce { done in
            let thumbProgress = extensionInstance.fetchThumbnails(
                for: [item.itemIdentifier],
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
            _ = thumbProgress
        }
        precondition(thumbItemCount == 1)
        precondition(thumbFinishCount == 1)

        _ = Notification.Name.fileProviderDomainDidChange
        _ = Notification.Name.fileProviderMaterializedSetDidChange
        _ = Notification.Name.fileProviderPendingSetDidChange
        let request = NSFileProviderRequest(isSystemRequest: true)
        precondition(request.isSystemRequest)
        precondition(!request.isFileViewerRequest)
        _ = NSFileProviderServiceName("svc")

        print("FILEPROVIDER_AGENT_RUNTIME_OK")
    }
}

let fileProviderRuntimeGate = DispatchSemaphore(value: 0)
Task {
    await FileProviderRuntime.main()
    fileProviderRuntimeGate.signal()
}
fileProviderRuntimeGate.wait()
