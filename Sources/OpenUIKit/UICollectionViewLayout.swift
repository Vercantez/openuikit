// UICollectionViewLayout + UICollectionViewLayoutAttributes. Owner:
// collection module (M13, docs/APP_COMPAT.md cluster #1).
//
// The abstract half of the collection-view contract: a layout object answers
// "what is at this index path" and "what is inside this rect", and the
// collection view tiles whatever comes back. UICollectionViewFlowLayout (the
// measured one) lives in its own file; a custom app layout only has to
// override the four methods below, exactly like UIKit.

/// Geometry (and a little presentation state) for one element of a
/// collection view: a cell, or a supplementary/decoration view.
open class UICollectionViewLayoutAttributes {
    public enum Category: Sendable {
        case cell, supplementaryView, decorationView
    }

    public var frame: CGRect = .zero
    public var zIndex: Int = 0
    public var alpha: CGFloat = 1
    public var isHidden = false
    public var transform: CGAffineTransform = .identity
    public let indexPath: IndexPath
    public let representedElementCategory: Category
    /// nil for cells; the supplementary/decoration kind otherwise.
    public let representedElementKind: String?

    public var size: CGSize {
        get { frame.size }
        set { frame = CGRect(origin: frame.origin, size: newValue) }
    }
    public var center: CGPoint {
        get { CGPoint(x: frame.midX, y: frame.midY) }
        set {
            frame = CGRect(x: newValue.x - frame.width / 2,
                           y: newValue.y - frame.height / 2,
                           width: frame.width, height: frame.height)
        }
    }
    public var bounds: CGRect { CGRect(origin: .zero, size: frame.size) }

    public init(forCellWith indexPath: IndexPath) {
        self.indexPath = indexPath
        representedElementCategory = .cell
        representedElementKind = nil
    }

    public init(forSupplementaryViewOfKind elementKind: String,
                with indexPath: IndexPath) {
        self.indexPath = indexPath
        representedElementCategory = .supplementaryView
        representedElementKind = elementKind
    }

    public init(forDecorationViewOfKind elementKind: String,
                with indexPath: IndexPath) {
        self.indexPath = indexPath
        representedElementCategory = .decorationView
        representedElementKind = elementKind
    }

    /// Identity of the slot these attributes describe (the collection view's
    /// tiling key).
    var elementKey: UICollectionView.ElementKey {
        UICollectionView.ElementKey(kind: representedElementKind, indexPath: indexPath)
    }
}

/// Abstract layout. Subclasses answer for their own geometry; the base class
/// deliberately returns "nothing", like UIKit's.
open class UICollectionViewLayout {
    /// Set by the collection view when the layout is installed.
    public internal(set) weak var collectionView: UICollectionView?

    public init() {}

    /// Recompute whatever the layout caches. Called before the first query
    /// after an invalidation.
    open func prepare() {}

    /// Scrollable extent of the laid-out content.
    open var collectionViewContentSize: CGSize { .zero }

    /// Every element intersecting `rect`. The collection view tiles exactly
    /// what this returns, so a layout that answers in O(visible) keeps
    /// scrolling O(visible) — see UICollectionViewFlowLayout's line index.
    open func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        nil
    }

    open func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        nil
    }

    open func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                   at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        nil
    }

    /// Whether a bounds change (scrolling, or a resize) invalidates the
    /// layout. UIKit's default is false — scrolling alone must not force a
    /// relayout.
    open func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { false }

    /// Marks the cached geometry stale; the next query re-runs `prepare()`.
    open func invalidateLayout() {
        isPrepared = false
        collectionView?._layoutInvalidated()
    }

    // MARK: Internal driving

    var isPrepared = false

    func prepareIfNeeded() {
        guard !isPrepared else { return }
        isPrepared = true
        prepare()
    }
}
