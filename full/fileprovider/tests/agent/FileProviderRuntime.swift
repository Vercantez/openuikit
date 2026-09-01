import Foundation
import FileProvider

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

enum FileProviderRuntime {
    static func main() async {
        precondition(NSFileProviderError.Code.notAuthenticated.rawValue == -1000)
        precondition(NSFileProviderError.Code.filenameCollision.rawValue == -1001)
        precondition(NSFileProviderError.Code.syncAnchorExpired.rawValue == -1002)
        precondition(NSFileProviderError.Code.pageExpired == .syncAnchorExpired)
        precondition(NSFileProviderError.pageExpired == .syncAnchorExpired)
        precondition(NSFileProviderError.Code.applicationExtensionNotFound.rawValue == -1019)
        precondition(NSFileProviderFavoriteRankUnranked == UInt64.max)

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
            NSFileProviderModifyItemOptions.failOnConflict.isDisjoint(
                with: .mayAlreadyExist
            )
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
        precondition(
            NSFileProviderDomainIdentifier(rawValue: "domain").rawValue == "domain"
        )
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

        NSFileProviderManager.removeAllDomains { error in
            precondition(error == nil)
        }
        try! await NSFileProviderManager.add(domain)
        let domains = try! await NSFileProviderManager.domains()
        precondition(domains.contains(where: { $0.identifier == domain.identifier }))
        try! await NSFileProviderManager.remove(domain)
        let afterRemove = try! await NSFileProviderManager.domains()
        precondition(afterRemove.isEmpty)

        let manager = NSFileProviderManager(for: domain2)
        precondition(manager != nil)
        precondition(manager?.providerIdentifier == "org.openuikit.fileprovider.unhosted")
        let temp = try! manager!.temporaryDirectoryURL()
        precondition(temp.path.contains("OpenUIKitFileProvider"))
        _ = manager!.documentStorageURL
        _ = NSFileProviderManager.default
        _ = manager!.globalProgress(for: .downloading)
        _ = manager!.enumeratorForMaterializedItems()
        _ = manager!.enumeratorForPendingItems()

        await requireFailClosed({
            _ = try await manager!.getUserVisibleURL(for: root)
        }, .providerNotFound)
        await requireFailClosed({
            try await manager!.evictItem(identifier: root)
        }, .nonEvictable)
        await requireFailClosed({
            try await manager!.signalEnumerator(for: root)
        }, .providerNotFound)
        await requireFailClosed({
            try await NSFileProviderManager.import(domain, fromDirectoryAt: temp)
        }, .applicationExtensionNotFound)

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
        precondition(item.filename == "Notes.txt")
        precondition(item.capabilities.contains(.allowsWriting))

        let placeholderURL = NSFileProviderManager.placeholderURL(
            for: temp.appendingPathComponent("Notes.txt")
        )
        try! NSFileProviderManager.writePlaceholder(at: placeholderURL, withMetadata: item)
        precondition(FileManager.default.fileExists(atPath: placeholderURL.path))

        let nsError = NSError.fileProviderErrorForCollision(with: item)
        precondition(nsError.domain == NSFileProviderErrorDomain)
        precondition(nsError.code == NSFileProviderError.Code.filenameCollision.rawValue)
        let missing = NSError.fileProviderErrorForNonExistentItem(
            withIdentifier: NSFileProviderItemIdentifier("missing")
        )
        precondition(missing.code == NSFileProviderError.Code.noSuchItem.rawValue)
        let rejected = NSError.fileProviderErrorForRejectedDeletion(of: item)
        precondition(rejected.code == NSFileProviderError.Code.deletionRejected.rawValue)

        let enumerator = NSFileProviderMemoryEnumerator(items: [item])
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
        try! await extensionInstance.providePlaceholder(
            at: temp.appendingPathComponent("Inbox.txt")
        )
        await requireFailClosed({
            try await extensionInstance.startProvidingItem(at: mapped!)
        }, .providerNotFound)
        extensionInstance.itemChanged(at: mapped!)
        extensionInstance.stopProvidingItem(at: mapped!)
        let services = try! extensionInstance.supportedServiceSources(for: item.itemIdentifier)
        precondition(services.isEmpty)

        let thumbProgress = extensionInstance.fetchThumbnails(
            for: [item.itemIdentifier],
            requestedSize: CGSize(width: 32, height: 32),
            perThumbnailCompletionHandler: { _, data, error in
                precondition(data == nil)
                requireCode(error!, .providerNotFound)
            },
            completionHandler: { error in
                requireCode(error!, .providerNotFound)
            }
        )
        precondition(thumbProgress.isFinished)

        _ = Notification.Name.fileProviderDomainDidChange
        _ = Notification.Name.fileProviderMaterializedSetDidChange
        _ = Notification.Name.fileProviderPendingSetDidChange
        _ = NSFileProviderRequest(isSystemRequest: true)
        _ = NSFileProviderService(name: NSFileProviderServiceName("svc"))
        _ = NSXPCListenerEndpoint()

        print("FILEPROVIDER_AGENT_RUNTIME_OK")
    }
}

let fileProviderRuntimeGate = DispatchSemaphore(value: 0)
Task {
    await FileProviderRuntime.main()
    fileProviderRuntimeGate.signal()
}
fileProviderRuntimeGate.wait()
