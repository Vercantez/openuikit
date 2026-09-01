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

/// In-memory enumerator used by Linux host tests. Not part of Apple's graph.
@_spi(OpenUIKitHost)
open class NSFileProviderMemoryEnumerator: NSObject, NSFileProviderEnumerator, @unchecked Sendable {
    public private(set) var items: [NSFileProviderItem]
    public var syncAnchor: NSFileProviderSyncAnchor?
    private var invalid = false

    public init(items: [NSFileProviderItem] = []) {
        self.items = items
        super.init()
    }

    public func invalidate() {
        invalid = true
    }

    public func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        if invalid {
            observer.finishEnumeratingWithError(NSFileProviderError(.cannotSynchronize))
            return
        }
        observer.didEnumerate(items)
        observer.finishEnumerating(upTo: nil)
    }

    public func enumerateChanges(
        for observer: any NSFileProviderChangeObserver,
        from syncAnchor: NSFileProviderSyncAnchor
    ) {
        if invalid {
            observer.finishEnumeratingWithError(NSFileProviderError(.cannotSynchronize))
            return
        }
        let next = self.syncAnchor ?? syncAnchor
        observer.didUpdate(items)
        observer.finishEnumeratingChanges(upTo: next, moreComing: false)
    }

    public func currentSyncAnchor(
        completionHandler: @escaping (NSFileProviderSyncAnchor?) -> Void
    ) {
        completionHandler(syncAnchor)
    }
}

final class FileProviderEmptyEnumerator: NSObject, NSFileProviderEnumerator {
    func invalidate() {}

    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        observer.didEnumerate([])
        observer.finishEnumerating(upTo: nil)
    }
}

final class FileProviderEmptyPendingSetEnumerator: NSObject, NSFileProviderPendingSetEnumerator {
    let domainVersion: NSFileProviderDomainVersion? = nil
    let isMaximumSizeReached = false
    let refreshInterval: TimeInterval = 1

    func invalidate() {}

    func enumerateItems(
        for observer: any NSFileProviderEnumerationObserver,
        startingAt page: NSFileProviderPage
    ) {
        _ = page
        observer.didEnumerate([])
        observer.finishEnumerating(upTo: nil)
    }
}

/// Collecting observer used by Linux host tests. Not part of Apple's graph.
@_spi(OpenUIKitHost)
public final class NSFileProviderCollectingObserver: NSObject, NSFileProviderEnumerationObserver,
    NSFileProviderChangeObserver, @unchecked Sendable
{
    public private(set) var items: [NSFileProviderItem] = []
    public private(set) var deleted: [NSFileProviderItemIdentifier] = []
    public private(set) var finishedPage: NSFileProviderPage?
    public private(set) var finishedAnchor: NSFileProviderSyncAnchor?
    public private(set) var error: (any Error)?
    public var suggestedPageSize: Int = 100
    public var suggestedBatchSize: Int = 100

    public func didEnumerate(_ updatedItems: [any NSFileProviderItemProtocol]) {
        items.append(contentsOf: updatedItems)
    }

    public func finishEnumerating(upTo nextPage: NSFileProviderPage?) {
        finishedPage = nextPage
    }

    public func finishEnumeratingWithError(_ error: any Error) {
        self.error = error
    }

    public func didDeleteItems(withIdentifiers deletedItemIdentifiers: [NSFileProviderItemIdentifier]) {
        deleted.append(contentsOf: deletedItemIdentifiers)
    }

    public func didUpdate(_ updatedItems: [any NSFileProviderItemProtocol]) {
        items.append(contentsOf: updatedItems)
    }

    public func finishEnumeratingChanges(upTo anchor: NSFileProviderSyncAnchor, moreComing: Bool) {
        _ = moreComing
        finishedAnchor = anchor
    }
}
