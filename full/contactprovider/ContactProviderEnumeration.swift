import Foundation

/// A protocol to provide enumerators for collections of contact items.
public protocol ContactItemEnumerating {
    /// Provide an enumerator for the contact items collection.
    ///
    /// The collection represents all contacts for the domain
    /// (`ContactItem.Identifier.rootContainer`).
    func enumerator(for collection: ContactItem.Identifier) -> any ContactItemEnumerator
}

/// A protocol to provide enumerations of all contact items and changed contact
/// items.
///
/// Linux never talks to `contactsd`. Implementations of the async methods are
/// host-side; the sealed runner cannot `await` them, so those identifiers are
/// `declared` in coverage.
public protocol ContactItemEnumerator {
    /// Enumerates all items, batched in pages.
    func enumerateContent(
        in page: ContactItemPage,
        for observer: any ContactItemContentObserver
    ) async

    /// Enumerates items changed since the last sync.
    func enumerateChanges(
        startingAt syncAnchor: ContactItemSyncAnchor,
        for observer: any ContactItemChangeObserver
    ) async

    /// Invalidates the enumerator.
    func invalidate() async
}

/// A protocol that defines a system observer that receives a resumable
/// enumeration of all items.
///
/// Observer methods are synchronous. Linux recording observers store the
/// payloads they are given; they do not write a Contacts database.
public protocol ContactItemContentObserver {
    /// Provides an array of contact items to the observer.
    func didEnumerate(_ items: [ContactItem])

    /// Marks a page of items as completed.
    func didFinishEnumeratingPage(upTo nextPage: ContactItemPage)

    /// Finishes the content enumeration to the observer.
    func didFinishEnumeratingContent(upTo generationMarker: Data)

    /// Finishes the content enumeration with an error.
    func didFinishEnumeratingContentWithError(_ error: any Error)

    /// Retrieves the suggested number of items to include in a page.
    var suggestedPageSize: Int { get }
}

/// A protocol that defines a system observer that receives a resumable
/// enumeration of changed contact items.
public protocol ContactItemChangeObserver {
    /// Provides an array of new and updated contact items to the observer.
    func didUpdate(_ items: [ContactItem])

    /// Provides an array of deleted contact item identifiers to the observer.
    func didDelete(_ identifiers: [ContactItem.Identifier])

    /// Marks a sync anchor of changed contact items as completed.
    func didFinishEnumeratingChanges(upTo syncAnchor: ContactItemSyncAnchor, moreComing: Bool)

    /// Finishes the change enumeration with an error.
    func didFinishEnumeratingChangesWithError(_ error: any Error)

    /// Retrieves the suggested number of changed contact items to include in a
    /// batch.
    var suggestedBatchSize: Int { get }
}
