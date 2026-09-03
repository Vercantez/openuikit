import Foundation

/// Observer for a paged children enumeration.
public protocol NSFileProviderEnumerationObserver: NSObjectProtocol {
    func didEnumerate(_ updatedItems: [any NSFileProviderItemProtocol])
    func finishEnumerating(upTo nextPage: NSFileProviderPage?)
    func finishEnumeratingWithError(_ error: any Error)
    var suggestedPageSize: Int { get }
}

extension NSFileProviderEnumerationObserver {
    public var suggestedPageSize: Int { 100 }
}

/// Observer for a sync-anchor change enumeration.
public protocol NSFileProviderChangeObserver: NSObjectProtocol {
    func didDeleteItems(withIdentifiers deletedItemIdentifiers: [NSFileProviderItemIdentifier])
    func didUpdate(_ updatedItems: [any NSFileProviderItemProtocol])
    func finishEnumeratingChanges(upTo anchor: NSFileProviderSyncAnchor, moreComing: Bool)
    func finishEnumeratingWithError(_ error: any Error)
    var suggestedBatchSize: Int { get }
}

extension NSFileProviderChangeObserver {
    public var suggestedBatchSize: Int { 100 }
}

/// Enumerator of items or changes under a container.
public protocol NSFileProviderEnumerator: NSObjectProtocol {
    func invalidate()
    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    )
    func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    )
    func currentSyncAnchor(completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void)
}

extension NSFileProviderEnumerator {
    public func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        observer.finishEnumeratingWithError(NSFileProviderError(.syncAnchorExpired))
    }

    public func currentSyncAnchor(
        completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void
    ) {
        completionHandler(nil)
    }
}

/// Enumerator of the pending (not yet uploaded) set.
public protocol NSFileProviderPendingSetEnumerator: NSFileProviderEnumerator {
    var domainVersion: NSFileProviderDomainVersion? { get }
    var isMaximumSizeReached: Bool { get }
    var refreshInterval: TimeInterval { get }
}

/// Provider that can vend enumerators for containers.
public protocol NSFileProviderEnumerating: NSObjectProtocol {
    func enumerator(
        for containerItemIdentifier: NSFileProviderItemIdentifier,
        request: NSFileProviderRequest
    ) throws -> any NSFileProviderEnumerator
}

/// Daemon materialized/pending enumerators fail closed when no host adapter exists.
/// They never report an empty successful system set.
final class FileProviderUnhostedEnumerator: NSObject, NSFileProviderEnumerator {
    func invalidate() {}

    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        FileProviderCallback.queue.async {
            observer.finishEnumeratingWithError(FileProviderHost.unsupported())
        }
    }

    func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        _ = syncAnchor
        FileProviderCallback.queue.async {
            observer.finishEnumeratingWithError(FileProviderHost.unsupported())
        }
    }

    func currentSyncAnchor(
        completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void
    ) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(nil)
        }
    }
}

final class FileProviderUnhostedPendingSetEnumerator: NSObject, NSFileProviderPendingSetEnumerator {
    let domainVersion: NSFileProviderDomainVersion? = nil
    let isMaximumSizeReached = false
    let refreshInterval: TimeInterval = 1

    func invalidate() {}

    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        FileProviderCallback.queue.async {
            observer.finishEnumeratingWithError(FileProviderHost.unsupported())
        }
    }

    func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        _ = syncAnchor
        FileProviderCallback.queue.async {
            observer.finishEnumeratingWithError(FileProviderHost.unsupported())
        }
    }

    func currentSyncAnchor(
        completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void
    ) {
        let once = FileProviderCallback.Once()
        FileProviderCallback.asyncOnce(once) {
            completionHandler(nil)
        }
    }
}
