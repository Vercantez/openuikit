#if os(macOS)
import Foundation
import AppKit


// MARK: - ResultsTableAnimations: Defines the Animations to be applied during Table Update(s)
//
public struct ResultsTableAnimations {

    /// TableViewRowAnimation to be applied during Delete OP's.
    ///
    public let delete: NSTableView.AnimationOptions = .effectFade

    /// TableViewRowAnimation to be applied during Insert OP's.
    ///
    public let insert: NSTableView.AnimationOptions = .effectFade

    /// TableViewRowAnimation to be applied during Update OP's.
    ///
    public let update: NSTableView.AnimationOptions = .effectFade

    /// Standard ResultsTableAnimations Settings
    ///
    public static let standard = ResultsTableAnimations()
}


// MARK: - NSTableView ResultsController Convenience Methods
//
extension NSTableView {

    /// This API applies Section and Object Changesets over the receiver. Based on WWDC 2020 @ Labs Recommendations
    /// - Important: While we process this batch, no `NSTableViewDelegate` events will be fired, in order to prevent potential reentrant flows
    ///
    public func performBatchChanges(objectsChangeset: ResultsObjectsChangeset) {
        beginUpdates()
        performChanges(objectsChangeset: objectsChangeset)
        endUpdates()
    }

    /// This API applies Section and Object Changesets over the receiver. Based on WWDC 2020 @ Labs Recommendations
    /// - Note: This should be done during onDidChangeContent so that we're never in the middle of a NSManagedObjectContext.save()
    ///
    private func performChanges(objectsChangeset: ResultsObjectsChangeset, animations: ResultsTableAnimations = .standard) {
        // [Step 1] Structural Changes: Delete OP(s)
        if !objectsChangeset.deleted.isEmpty {
            removeRows(at: objectsChangeset.deleted.toIndexSet, withAnimation: animations.delete)
        }

        if !objectsChangeset.inserted.isEmpty {
            insertRows(at: objectsChangeset.inserted.toIndexSet, withAnimation: animations.insert)
        }

        // [Step 2] Content Changes: Move OP(s)
        for (from, to) in objectsChangeset.moved {
            removeRows(at: IndexSet(integer: from.item), withAnimation: animations.delete)
            insertRows(at: IndexSet(integer: to.item), withAnimation: animations.insert)
        }

        // [Step 3] Content Changes: Update OP(s)
        if !objectsChangeset.updated.isEmpty {
            let allColumnIndexes = IndexSet(integersIn: Int.zero ..< numberOfColumns)
            reloadData(forRowIndexes: objectsChangeset.updated.toIndexSet, columnIndexes: allColumnIndexes)
        }
    }
}


// MARK: - Array / IndexPath Internal Helpers
//
extension Array where Element == IndexPath {

    var toIndexSet: IndexSet {
        var output = IndexSet()
        for indexPath in self {
            output.insert(indexPath.item)
        }

        return output
    }
}


#endif
