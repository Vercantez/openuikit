#if os(iOS)
import Foundation
import UIKit


// MARK: - ResultsTableAnimations: Defines the Animations to be applied during Table Update(s)
//
public struct ResultsTableAnimations {

    /// TableViewRowAnimation to be applied during Delete OP's.
    ///
    public let delete: UITableView.RowAnimation

    /// TableViewRowAnimation to be applied during Insert OP's.
    ///
    public let insert: UITableView.RowAnimation

    /// TableViewRowAnimation to be applied during Move OP's.
    ///
    public let move: UITableView.RowAnimation

    /// TableViewRowAnimation to be applied during Update OP's.
    ///
    public let update: UITableView.RowAnimation

    /// Standard ResultsTableAnimations Settings
    ///
    public static let standard = ResultsTableAnimations()

    /// Constructor
    /// - Parameters:
    ///     - delete: delete animation
    ///     - insert: insert animation
    ///     - move: move animation
    ///     - update: update animation
    ///
    public init(delete: UITableView.RowAnimation = .fade,
                insert: UITableView.RowAnimation = .fade,
                move: UITableView.RowAnimation = .fade,
                update: UITableView.RowAnimation = .fade) {
        self.delete = delete
        self.insert = insert
        self.move = move
        self.update = update
    }
}


// MARK: - UITableView ResultsController Convenience Methods
//
extension UITableView {

    public func performBatchChanges(sectionsChangeset: ResultsSectionsChangeset, objectsChangeset: ResultsObjectsChangeset, onCompletion: ((Bool) -> Void)? = nil) {
        performBatchUpdates({
            self.performChanges(sectionsChangeset: sectionsChangeset, objectsChangeset: objectsChangeset)
        }, completion: onCompletion)
    }

    /// This API applies Section and Object Changesets over the receiver. Based on WWDC 2020 @ Labs Recommendations
    /// - Note: This should be done during onDidChangeContent so that we're never in the middle of a NSManagedObjectContext.save()
    ///
    public func performChanges(sectionsChangeset: ResultsSectionsChangeset, objectsChangeset: ResultsObjectsChangeset, animations: ResultsTableAnimations = .standard) {
        // [Step 1] Structural Changes: Delete OP(s)
        if !objectsChangeset.deleted.isEmpty {
            deleteRows(at: objectsChangeset.deleted, with: animations.delete)
        }

        if !sectionsChangeset.deleted.isEmpty {
            deleteSections(sectionsChangeset.deleted, with: animations.delete)
        }

        // [Step 2] Structural Changes: Insert OP(s)
        if !sectionsChangeset.inserted.isEmpty {
            insertSections(sectionsChangeset.inserted, with: animations.insert)
        }

        if !objectsChangeset.inserted.isEmpty {
            insertRows(at: objectsChangeset.inserted, with: animations.insert)
        }

        // [Step 3] Content Changes: Move OP(s)
        for (from, to) in objectsChangeset.moved {
            deleteRows(at: [from], with: animations.move)
            insertRows(at: [to], with: animations.move)
        }

        // [Step 4] Content Changes: Update OP(s)
        if !objectsChangeset.updated.isEmpty {
            reloadRows(at: objectsChangeset.updated, with: animations.update)
        }
    }
}

#endif
