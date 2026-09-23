// UICollectionViewLayout + UICollectionViewLayoutAttributes. Owner:
// collection module (M13, docs/APP_COMPAT.md cluster #1).
//
// The abstract half of the collection-view contract: a layout object answers
// "what is at this index path" and "what is inside this rect", and the
// collection view tiles whatever comes back. UICollectionViewFlowLayout (the
// measured one) lives in its own file; a custom app layout only has to
// override the four methods below, exactly like UIKit.
//
// Objective-C (eidolon-flowlayout): both classes derive from NSObject, as
// UIKit's do (MEASURED Tools/oracle2/flowlayoutprobe section 1:
// UICollectionViewLayout:NSObject, UICollectionViewLayoutAttributes:NSObject),
// and under OPENUIKIT_OBJC_SUBCLASSING carry UIKit's runtime names and are
// vtable-free (ObjCSubclassing.swift): every UIKit override point is
// `@objc(<iOS 26.1 SDK selector>) dynamic`, everything else `final`, so an
// Objective-C subclass such as Eidolon's ARCollectionViewMasonryLayout
// (`: UICollectionViewFlowLayout`) is dispatched to.

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif
#if OPENUIKIT_OBJC_SUBCLASSING
import ObjectiveC
#endif

/// Geometry (and a little presentation state) for one element of a
/// collection view: a cell, or a supplementary/decoration view.
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UICollectionViewLayoutAttributes)
#endif
@preconcurrency @MainActor
open class UICollectionViewLayoutAttributes: NSObject {
    public enum Category: Sendable {
        case cell, supplementaryView, decorationView
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(frame)
#endif
    public dynamic var frame: CGRect = .zero
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(zIndex)
#endif
    public dynamic var zIndex: Int = 0
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(alpha)
#endif
    public dynamic var alpha: CGFloat = 1
    /// UIKit: `@property (nonatomic, getter=isHidden) BOOL hidden`.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(hidden)
    public dynamic var isHidden: Bool {
        @objc(isHidden) get { _isHidden }
        @objc(setHidden:) set { _isHidden = newValue }
    }
#else
    public dynamic var isHidden: Bool {
        get { _isHidden }
        set { _isHidden = newValue }
    }
#endif
    final var _isHidden = false
    // CGAffineTransform is OpenCoreGraphics' Swift struct here (CA/CG type
    // unification is cg-unify's area), so it has no Objective-C spelling.
    public final var transform: CGAffineTransform = .identity
    /// UIKit's `indexPath` is readwrite; a bare `-init` leaves it empty.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(indexPath)
#endif
    public dynamic var indexPath: IndexPath {
        get { _indexPath }
        set { _indexPath = newValue }
    }
    final var _indexPath = IndexPath()
    public final private(set) var representedElementCategory: Category = .cell
    /// nil for cells; the supplementary/decoration kind otherwise.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(representedElementKind)
#endif
    public final private(set) var representedElementKind: String?

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(size)
#endif
    public dynamic var size: CGSize {
        get { frame.size }
        // MEASURED flowlayoutprobe section 2: setting the size keeps the
        // CENTER (a zero frame sized to 100x61 reads {{-50, -30.5}, ...}).
        set {
            let c = center
            frame = CGRect(x: c.x - newValue.width / 2, y: c.y - newValue.height / 2,
                           width: newValue.width, height: newValue.height)
        }
    }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(center)
#endif
    public dynamic var center: CGPoint {
        get { CGPoint(x: frame.midX, y: frame.midY) }
        set {
            frame = CGRect(x: newValue.x - frame.width / 2,
                           y: newValue.y - frame.height / 2,
                           width: frame.width, height: frame.height)
        }
    }
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(bounds)
#endif
    public dynamic var bounds: CGRect { CGRect(origin: .zero, size: frame.size) }

    /// `-init`: a cell's attributes with an empty index path. `dynamic` so
    /// the class factories below reach an Objective-C subclass's `-init`.
    public dynamic override init() {
        super.init()
    }

    public convenience init(forCellWith indexPath: IndexPath) {
        self.init()
        _indexPath = indexPath
        representedElementCategory = .cell
        representedElementKind = nil
    }

    public convenience init(forSupplementaryViewOfKind elementKind: String,
                            with indexPath: IndexPath) {
        self.init()
        _indexPath = indexPath
        representedElementCategory = .supplementaryView
        representedElementKind = elementKind
    }

    public convenience init(forDecorationViewOfKind elementKind: String,
                            with indexPath: IndexPath) {
        self.init()
        _indexPath = indexPath
        representedElementCategory = .decorationView
        representedElementKind = elementKind
    }

    /// Identity of the slot these attributes describe (the collection view's
    /// tiling key).
    final var elementKey: UICollectionView.ElementKey {
        UICollectionView.ElementKey(kind: representedElementKind, indexPath: indexPath)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    /// UICollectionElementCategory (UICollectionViewLayout.h): Cell 0,
    /// SupplementaryView 1, DecorationView 2 (MEASURED flowlayoutprobe
    /// section 2: a cell reads 0, a header 1).
    @objc(representedElementCategory)
    public final var __objc_representedElementCategory: UInt {
        switch representedElementCategory {
        case .cell: return 0
        case .supplementaryView: return 1
        case .decorationView: return 2
        }
    }

    /// `[[self alloc] init]` on the receiver's real class, so
    /// `+[OUKGridAttributes layoutAttributesForCellWithIndexPath:]` returns
    /// an OUKGridAttributes (MEASURED flowlayoutprobe section 2). `self` may
    /// be the Swift wrapper metadata of an Objective-C class; see
    /// CALayer.__objc_layer for why the metatype is reinterpreted.
    private static func _objcMake(_ cls: UICollectionViewLayoutAttributes.Type) -> UICollectionViewLayoutAttributes {
        let object = unsafeBitCast(cls, to: NSObject.Type.self).init()
        return unsafeBitCast(object, to: UICollectionViewLayoutAttributes.self)
    }

    @objc(layoutAttributesForCellWithIndexPath:)
    public static func __objc_layoutAttributesForCell(with indexPath: IndexPath) -> Self {
        let a = _objcMake(self)
        a._indexPath = indexPath
        a.representedElementCategory = .cell
        a.representedElementKind = nil
        return unsafeBitCast(a, to: Self.self)
    }

    @objc(layoutAttributesForSupplementaryViewOfKind:withIndexPath:)
    public static func __objc_layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                                   with indexPath: IndexPath) -> Self {
        let a = _objcMake(self)
        a._indexPath = indexPath
        a.representedElementCategory = .supplementaryView
        a.representedElementKind = elementKind
        return unsafeBitCast(a, to: Self.self)
    }

    @objc(layoutAttributesForDecorationViewOfKind:withIndexPath:)
    public static func __objc_layoutAttributesForDecorationView(ofKind elementKind: String,
                                                                with indexPath: IndexPath) -> Self {
        let a = _objcMake(self)
        a._indexPath = indexPath
        a.representedElementCategory = .decorationView
        a.representedElementKind = elementKind
        return unsafeBitCast(a, to: Self.self)
    }
#endif
}

/// Abstract layout. Subclasses answer for their own geometry; the base class
/// deliberately returns "nothing", like UIKit's.
#if OPENUIKIT_OBJC_SUBCLASSING
@objc(UICollectionViewLayout)
#endif
@preconcurrency @MainActor
open class UICollectionViewLayout: NSObject {
    /// Set by the collection view when the layout is installed.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(collectionView)
#endif
    public final internal(set) weak var collectionView: UICollectionView?

    public dynamic override init() { super.init() }

    /// Recompute whatever the layout caches. Called before the first query
    /// after an invalidation.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(prepareLayout)
#endif
    open dynamic func prepare() {}

    /// Scrollable extent of the laid-out content.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(collectionViewContentSize)
#endif
    open dynamic var collectionViewContentSize: CGSize { .zero }

    /// Every element intersecting `rect`. The collection view tiles exactly
    /// what this returns, so a layout that answers in O(visible) keeps
    /// scrolling O(visible) — see UICollectionViewFlowLayout's line index.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(layoutAttributesForElementsInRect:)
#endif
    open dynamic func layoutAttributesForElements(in rect: CGRect) -> [UICollectionViewLayoutAttributes]? {
        nil
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(layoutAttributesForItemAtIndexPath:)
#endif
    open dynamic func layoutAttributesForItem(at indexPath: IndexPath) -> UICollectionViewLayoutAttributes? {
        nil
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(layoutAttributesForSupplementaryViewOfKind:atIndexPath:)
#endif
    open dynamic func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                           at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        nil
    }

    /// Whether a bounds change (scrolling, or a resize) invalidates the
    /// layout. UIKit's default is false — scrolling alone must not force a
    /// relayout.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(shouldInvalidateLayoutForBoundsChange:)
#endif
    open dynamic func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool { false }

    // collectionblockingprobe, iPhone 16 / iOS 26.1, base.invalidate.*:
    // invalidateLayout() dispatches once to invalidateLayout(with:), even
    // unattached, with both invalidateEverything/counts flags false.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(invalidationContextClass)
#endif
    open dynamic class var invalidationContextClass: AnyClass {
        UICollectionViewLayoutInvalidationContext.self
    }

    private final func makeInvalidationContext() -> UICollectionViewLayoutInvalidationContext {
#if OPENUIKIT_OBJC_SUBCLASSING
        // `type(of: self)` of an Objective-C subclass instance is a wrapper
        // metadata; message the real class object (`_objcMessageable`), and
        // allocate the context class with `[[cls alloc] init]`.
        let contextClass: AnyClass = _objcMessageable(type(of: self)).invalidationContextClass
        guard contextClass is UICollectionViewLayoutInvalidationContext.Type else {
            return UICollectionViewLayoutInvalidationContext()
        }
        let object = unsafeBitCast(contextClass, to: NSObject.Type.self).init()
        return unsafeBitCast(object, to: UICollectionViewLayoutInvalidationContext.self)
#else
        let contextType = type(of: self).invalidationContextClass as? UICollectionViewLayoutInvalidationContext.Type
        return (contextType ?? UICollectionViewLayoutInvalidationContext.self).init()
#endif
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(invalidationContextForBoundsChange:)
#endif
    open dynamic func invalidationContext(forBoundsChange newBounds: CGRect)
        -> UICollectionViewLayoutInvalidationContext {
        makeInvalidationContext()
    }

    /// Set by the collection view between `invalidationContext(forBoundsChange:)`
    /// and the `invalidateLayout()` it then issues, so that call reaches
    /// `invalidateLayout(with:)` with the SAME context object (measured
    /// signalrowsprobe invalidate.*: `fromBoundsContext` true on every
    /// bounds-driven invalidation). An app's `invalidateLayout()` override
    /// that calls super (Signal's ConversationViewLayout) sees the chain
    /// UIKit gives it.
    final var _pendingBoundsContext: UICollectionViewLayoutInvalidationContext?

    /// Marks the cached geometry stale; the next query re-runs `prepare()`.
#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(invalidateLayout)
#endif
    open dynamic func invalidateLayout() {
        let context = _pendingBoundsContext ?? makeInvalidationContext()
        _pendingBoundsContext = nil
        invalidateLayout(with: context)
    }

#if OPENUIKIT_OBJC_SUBCLASSING
    @objc(invalidateLayoutWithContext:)
#endif
    open dynamic func invalidateLayout(with context: UICollectionViewLayoutInvalidationContext) {
        isPrepared = false
        collectionView?._applyInvalidationAdjustments(context)
        collectionView?._layoutInvalidated()
    }

    /// Orthogonal compositional sections scroll inside the section, not
    /// the parent. Returns true when the layout handled the scroll (the
    /// collection view then retiles without changing `contentOffset`).
    /// `final` (ScrollPosition has no Objective-C spelling): the one layout
    /// that handles it is reached by type.
    final func handleScrollToItem(at indexPath: IndexPath,
                                  at position: UICollectionView.ScrollPosition) -> Bool {
        if let compositional = self as? UICollectionViewCompositionalLayout {
            return compositional._handleScrollToItem(at: indexPath, at: position)
        }
        return false
    }

    // MARK: Internal driving

    final var isPrepared = false

    /// Runs `prepare()` if the cache is stale; true when it ran.
    @discardableResult
    final func prepareIfNeeded() -> Bool {
        guard !isPrepared else { return false }
        isPrepared = true
        prepare()
        return true
    }
}
