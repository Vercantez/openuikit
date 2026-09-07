import Foundation


// MARK: - Changeset: Sections
//
public struct ResultsSectionsChangeset {
    private(set) public var deleted = IndexSet()
    private(set) public var inserted = IndexSet()
}


// MARK: - Convenience Initializers
//
extension ResultsSectionsChangeset {

    mutating func deletedSection(at index: Int) {
        deleted.insert(index)
    }

    mutating func insertedSection(at index: Int) {
        inserted.insert(index)
    }
}


// MARK: - ResultsSectionChange: Transposing
//
extension ResultsSectionsChangeset {

    /// Why? Because displaying data coming from multiple ResultsController onScreen... just requires us to adjust sectionIndexes
    ///
    public func transposed(toSection section: Int) -> ResultsSectionsChangeset {
        let newDeleted = deleted.map { _ in section }
        let newInserted = inserted.map { _ in section }

        return ResultsSectionsChangeset(deleted: IndexSet(newDeleted), inserted: IndexSet(newInserted))
    }
}
