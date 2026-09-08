// Measured by Tools/oracle2/collectionblockingprobe on iPhone 16, iOS 26.1.
// collection.json context.default/items/itemsAgain/changed: false flags,
// nil lists, zero adjustments; [1:2,0:0,1:2] becomes [1:2,0:0], with later
// insertions appended. These are state contracts, independent of chrome cut.
#if canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
open class UICollectionViewLayoutInvalidationContext {
    public required init() {}

    open var invalidateEverything: Bool { false }
    open var invalidateDataSourceCounts: Bool { false }
    open private(set) var invalidatedItemIndexPaths: [IndexPath]?
    open private(set) var invalidatedSupplementaryIndexPaths: [String: [IndexPath]]?
    open private(set) var invalidatedDecorationIndexPaths: [String: [IndexPath]]?
    open var contentOffsetAdjustment: CGPoint = .zero
    open var contentSizeAdjustment: CGSize = .zero

    open func invalidateItems(at indexPaths: [IndexPath]) {
        // context.emptyItems: an empty call leaves the optional item list nil.
        guard !indexPaths.isEmpty else { return }
        invalidatedItemIndexPaths = merging(invalidatedItemIndexPaths ?? [], indexPaths)
    }

    open func invalidateSupplementaryElements(ofKind elementKind: String,
                                             at indexPaths: [IndexPath]) {
        // context.changed: even an empty call creates the kind's empty entry.
        var entries = invalidatedSupplementaryIndexPaths ?? [:]
        entries[elementKind] = merging(entries[elementKind] ?? [], indexPaths)
        invalidatedSupplementaryIndexPaths = entries
    }

    open func invalidateDecorationElements(ofKind elementKind: String,
                                          at indexPaths: [IndexPath]) {
        var entries = invalidatedDecorationIndexPaths ?? [:]
        entries[elementKind] = merging(entries[elementKind] ?? [], indexPaths)
        invalidatedDecorationIndexPaths = entries
    }

    private func merging(_ old: [IndexPath], _ added: [IndexPath]) -> [IndexPath] {
        var result = old
        for path in added where !result.contains(path) { result.append(path) }
        return result
    }
}

@preconcurrency @MainActor
open class UICollectionViewFlowLayoutInvalidationContext: UICollectionViewLayoutInvalidationContext {
    // collection.json flowcontext.default: both flow-specific flags are true;
    // the inherited invalidateEverything and invalidateDataSourceCounts are false.
    open var invalidateFlowLayoutAttributes = true
    open var invalidateFlowLayoutDelegateMetrics = true
}
