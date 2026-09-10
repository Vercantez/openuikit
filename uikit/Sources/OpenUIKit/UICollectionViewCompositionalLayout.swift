// UICollectionViewCompositionalLayout + NSCollectionLayout*. Owner:
// collection module (the M13 cluster tail — docs/KNOWN_GAPS.md).
//
// The abstract UICollectionViewLayout is the seam: this file answers
// prepare / collectionViewContentSize / layoutAttributesForElements(in:)
// for the NSCollectionLayoutSection tree a real app writes. Geometry is
// resolved from the section provider against the collection view's bounds;
// orthogonal sections keep their own content offset and clip to the
// section's box (UIKit hosts a nested collection view for that; the
// attributes here are the same frames that nested scroller would tile).
//
// Feed (Sources/ConformanceApps/Feed, iPhone SE 2x) is the first measured
// customer. Constants that came off that capture are cited next to the
// rule they encode; everything else is the documented compositional API
// (absolute / fractional sizes, contentInsets, interGroupSpacing,
// boundary supplementary items, orthogonal .continuous).

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

// MARK: - Orthogonal scrolling

public enum UICollectionLayoutSectionOrthogonalScrollingBehavior: Int, Sendable {
    case none = 0
    case continuous
    case continuousGroupLeadingBoundary
    case paging
    case groupPaging
    case groupPagingCentered
}

/// Alignment of a boundary supplementary item on its section.
public enum NSRectAlignment: Int, Sendable {
    case none = 0
    case top
    case topLeading
    case leading
    case bottomLeading
    case bottom
    case bottomTrailing
    case trailing
    case topTrailing
}

// MARK: - Dimension / size / spacing

@preconcurrency @MainActor
public final class NSCollectionLayoutDimension {
    public enum Kind: Sendable {
        case fractionalWidth, fractionalHeight, absolute, estimated
    }

    public let kind: Kind
    public let dimension: CGFloat

    public var isFractionalWidth: Bool { kind == .fractionalWidth }
    public var isFractionalHeight: Bool { kind == .fractionalHeight }
    public var isAbsolute: Bool { kind == .absolute }
    public var isEstimated: Bool { kind == .estimated }

    init(kind: Kind, dimension: CGFloat) {
        self.kind = kind
        self.dimension = dimension
    }

    public static func fractionalWidth(_ fractionalWidth: CGFloat) -> NSCollectionLayoutDimension {
        NSCollectionLayoutDimension(kind: .fractionalWidth, dimension: fractionalWidth)
    }
    public static func fractionalHeight(_ fractionalHeight: CGFloat) -> NSCollectionLayoutDimension {
        NSCollectionLayoutDimension(kind: .fractionalHeight, dimension: fractionalHeight)
    }
    public static func absolute(_ absoluteDimension: CGFloat) -> NSCollectionLayoutDimension {
        NSCollectionLayoutDimension(kind: .absolute, dimension: absoluteDimension)
    }
    public static func estimated(_ estimatedDimension: CGFloat) -> NSCollectionLayoutDimension {
        NSCollectionLayoutDimension(kind: .estimated, dimension: estimatedDimension)
    }
}

@preconcurrency @MainActor
public final class NSCollectionLayoutSize {
    public let widthDimension: NSCollectionLayoutDimension
    public let heightDimension: NSCollectionLayoutDimension

    public init(widthDimension: NSCollectionLayoutDimension,
                heightDimension: NSCollectionLayoutDimension) {
        self.widthDimension = widthDimension
        self.heightDimension = heightDimension
    }
}

@preconcurrency @MainActor
public final class NSCollectionLayoutSpacing {
    public let spacing: CGFloat
    public let isFlexible: Bool
    public var isFixed: Bool { !isFlexible }

    init(spacing: CGFloat, isFlexible: Bool) {
        self.spacing = spacing
        self.isFlexible = isFlexible
    }

    public static func flexible(_ flexibleSpacing: CGFloat) -> NSCollectionLayoutSpacing {
        NSCollectionLayoutSpacing(spacing: flexibleSpacing, isFlexible: true)
    }
    public static func fixed(_ fixedSpacing: CGFloat) -> NSCollectionLayoutSpacing {
        NSCollectionLayoutSpacing(spacing: fixedSpacing, isFlexible: false)
    }
}

// MARK: - Item / group / supplementary

@preconcurrency @MainActor
open class NSCollectionLayoutItem {
    public let layoutSize: NSCollectionLayoutSize
    public var contentInsets: NSDirectionalEdgeInsets = .zero
    /// Per-item supplementaries (badges, firefox's tab title). MEASURED
    /// firefoxrowsprobe: a plain item reads back 0, `supplementaryItems:`
    /// keeps the array as given.
    public private(set) var supplementaryItems: [NSCollectionLayoutSupplementaryItem] = []

    public init(layoutSize: NSCollectionLayoutSize) {
        self.layoutSize = layoutSize
    }

    public convenience init(layoutSize: NSCollectionLayoutSize,
                            supplementaryItems: [NSCollectionLayoutSupplementaryItem]) {
        self.init(layoutSize: layoutSize)
        self.supplementaryItems = supplementaryItems
    }
}

/// Where a supplementary sits relative to its container (the item's final,
/// inset frame) — MEASURED firefoxrowsprobe, iPhone 16 / iOS 26.1, item
/// [30, y, 125, 100], badge 20×20:
///
///   * edges `[.top, .trailing]` → `[135, y, 20, 20]`: the badge sits INSIDE
///     the container, flush with the named edges;
///   * `[]`, `.all`, `[.leading, .trailing]` → `[82.667, y+40, …]`: an axis
///     with neither or both of its edges is centred;
///   * `[.bottom]` full-width 30 pt (firefox) → `[30, y+70, 125, 30]`;
///   * `fractionalOffset (0.5, −0.5)` → `[145, y−10]` and `absoluteOffset
///     (10, −10)` → the same: a fractional offset is a fraction of the
///     SUPPLEMENTARY's own size, not the container's;
///   * item insets 10 → container is the inset frame (`[125, y]` for an item
///     at `[40, y, 105, 80]`);
///   * an `itemAnchor` picks which point of the supplementary lands on the
///     container point: container `[.top, .trailing]` + item `[.bottom,
///     .leading]` → `[155, y−20]`; item `[]` → the badge's centre, and the
///     item anchor's own offset is added (`absoluteOffset (3, 4)` → `[158,
///     y−16]`; item `fractionalOffset (0.5, 0.5)` → `[155, y]`).
///
/// Raw edge bits match `NSDirectionalRectEdge` (top 1, leading 2, bottom 4,
/// trailing 8). Readback: `edges`, `offset`, `isAbsoluteOffset`,
/// `isFractionalOffset`; the edges-only initializer reads back absolute
/// with a zero offset.
@preconcurrency @MainActor
public final class NSCollectionLayoutAnchor {
    public let edges: NSDirectionalRectEdge
    public let offset: CGPoint
    public let isAbsoluteOffset: Bool
    public var isFractionalOffset: Bool { !isAbsoluteOffset }

    public init(edges: NSDirectionalRectEdge) {
        self.edges = edges
        self.offset = .zero
        self.isAbsoluteOffset = true
    }

    public init(edges: NSDirectionalRectEdge, absoluteOffset: CGPoint) {
        self.edges = edges
        self.offset = absoluteOffset
        self.isAbsoluteOffset = true
    }

    public init(edges: NSDirectionalRectEdge, fractionalOffset: CGPoint) {
        self.edges = edges
        self.offset = fractionalOffset
        self.isAbsoluteOffset = false
    }

    /// The anchor point inside `rect`. `rtl` swaps which physical side
    /// `leading` names (unmeasured: the oracle's forced-RTL collection view
    /// mirrored nothing, items included; see the probe README).
    func point(in rect: CGRect, rtl: Bool) -> CGPoint {
        let hasLeading = edges.contains(.leading)
        let hasTrailing = edges.contains(.trailing)
        let left = rtl ? hasTrailing : hasLeading
        let right = rtl ? hasLeading : hasTrailing
        let x: CGFloat
        if left && !right { x = rect.minX }
        else if right && !left { x = rect.maxX }
        else { x = rect.midX }
        let top = edges.contains(.top)
        let bottom = edges.contains(.bottom)
        let y: CGFloat
        if top && !bottom { y = rect.minY }
        else if bottom && !top { y = rect.maxY }
        else { y = rect.midY }
        return CGPoint(x: x, y: y)
    }

    /// The offset in points for a supplementary of `size`.
    func resolvedOffset(for size: CGSize, rtl: Bool) -> CGPoint {
        let dx = isAbsoluteOffset ? offset.x : offset.x * size.width
        let dy = isAbsoluteOffset ? offset.y : offset.y * size.height
        return CGPoint(x: rtl ? -dx : dx, y: dy)
    }
}

@preconcurrency @MainActor
public final class NSCollectionLayoutGroup: NSCollectionLayoutItem {
    public enum Axis: Sendable { case horizontal, vertical }

    public private(set) var axis: Axis = .horizontal
    public private(set) var subitems: [NSCollectionLayoutItem] = []
    /// 0 means `subitems` is the group contents as written; >0 repeats
    /// `subitems[0]` that many times (`repeatingSubitem:count:`).
    var repeatCount: Int = 0
    public var interItemSpacing: NSCollectionLayoutSpacing?

    public static func horizontal(layoutSize: NSCollectionLayoutSize,
                                  subitems: [NSCollectionLayoutItem]) -> NSCollectionLayoutGroup {
        let g = NSCollectionLayoutGroup(layoutSize: layoutSize)
        g.axis = .horizontal
        g.subitems = subitems
        return g
    }

    public static func horizontal(layoutSize: NSCollectionLayoutSize,
                                  repeatingSubitem: NSCollectionLayoutItem,
                                  count: Int) -> NSCollectionLayoutGroup {
        let g = NSCollectionLayoutGroup(layoutSize: layoutSize)
        g.axis = .horizontal
        g.subitems = [repeatingSubitem]
        g.repeatCount = count
        return g
    }

    /// Deprecated UIKit spelling (`subitem:count:`); same as
    /// `repeatingSubitem:count:`.
    public static func horizontal(layoutSize: NSCollectionLayoutSize,
                                  subitem: NSCollectionLayoutItem,
                                  count: Int) -> NSCollectionLayoutGroup {
        horizontal(layoutSize: layoutSize, repeatingSubitem: subitem, count: count)
    }

    public static func vertical(layoutSize: NSCollectionLayoutSize,
                                subitems: [NSCollectionLayoutItem]) -> NSCollectionLayoutGroup {
        let g = NSCollectionLayoutGroup(layoutSize: layoutSize)
        g.axis = .vertical
        g.subitems = subitems
        return g
    }

    public static func vertical(layoutSize: NSCollectionLayoutSize,
                                repeatingSubitem: NSCollectionLayoutItem,
                                count: Int) -> NSCollectionLayoutGroup {
        let g = NSCollectionLayoutGroup(layoutSize: layoutSize)
        g.axis = .vertical
        g.subitems = [repeatingSubitem]
        g.repeatCount = count
        return g
    }

    public static func vertical(layoutSize: NSCollectionLayoutSize,
                                subitem: NSCollectionLayoutItem,
                                count: Int) -> NSCollectionLayoutGroup {
        vertical(layoutSize: layoutSize, repeatingSubitem: subitem, count: count)
    }

    func expandedSubitems() -> [NSCollectionLayoutItem] {
        if repeatCount > 0, let first = subitems.first {
            var out: [NSCollectionLayoutItem] = []
            out.reserveCapacity(repeatCount)
            for _ in 0..<repeatCount { out.append(first) }
            return out
        }
        return subitems
    }
}

@preconcurrency @MainActor
open class NSCollectionLayoutSupplementaryItem: NSCollectionLayoutItem {
    public let elementKind: String
    /// MEASURED firefoxrowsprobe: `containerAnchor` and `itemAnchor` read
    /// back the objects given (`itemAnchor` nil without one); `zIndex` 1;
    /// contentInsets zero. The boundary subclass keeps a centred anchor.
    public let containerAnchor: NSCollectionLayoutAnchor
    public let itemAnchor: NSCollectionLayoutAnchor?
    public var zIndex: Int = 1

    public init(layoutSize: NSCollectionLayoutSize, elementKind: String) {
        self.elementKind = elementKind
        self.containerAnchor = NSCollectionLayoutAnchor(edges: [])
        self.itemAnchor = nil
        super.init(layoutSize: layoutSize)
    }

    public init(layoutSize: NSCollectionLayoutSize, elementKind: String,
                containerAnchor: NSCollectionLayoutAnchor) {
        self.elementKind = elementKind
        self.containerAnchor = containerAnchor
        self.itemAnchor = nil
        super.init(layoutSize: layoutSize)
    }

    public init(layoutSize: NSCollectionLayoutSize, elementKind: String,
                containerAnchor: NSCollectionLayoutAnchor,
                itemAnchor: NSCollectionLayoutAnchor) {
        self.elementKind = elementKind
        self.containerAnchor = containerAnchor
        self.itemAnchor = itemAnchor
        super.init(layoutSize: layoutSize)
    }

    /// The supplementary's frame for a container (the item's inset frame).
    /// Origin = container point − supplementary point + both offsets; the
    /// supplementary point defaults to the container anchor's own edges.
    func frame(inContainer container: CGRect, size: CGSize, rtl: Bool) -> CGRect {
        let p = containerAnchor.point(in: container, rtl: rtl)
        let own = itemAnchor ?? NSCollectionLayoutAnchor(edges: containerAnchor.edges)
        let q = own.point(in: CGRect(origin: .zero, size: size), rtl: rtl)
        let c = containerAnchor.resolvedOffset(for: size, rtl: rtl)
        let i = itemAnchor?.resolvedOffset(for: size, rtl: rtl) ?? .zero
        return CGRect(x: p.x - q.x + c.x + i.x, y: p.y - q.y + c.y + i.y,
                      width: size.width, height: size.height)
    }
}

@preconcurrency @MainActor
public final class NSCollectionLayoutBoundarySupplementaryItem: NSCollectionLayoutSupplementaryItem {
    public let alignment: NSRectAlignment
    public var absoluteOffset: CGPoint = .zero
    public var pinToVisibleBounds = false

    public init(layoutSize: NSCollectionLayoutSize,
                elementKind: String,
                alignment: NSRectAlignment) {
        self.alignment = alignment
        super.init(layoutSize: layoutSize, elementKind: elementKind)
    }

    public convenience init(layoutSize: NSCollectionLayoutSize,
                            elementKind: String,
                            alignment: NSRectAlignment,
                            absoluteOffset: CGPoint) {
        self.init(layoutSize: layoutSize, elementKind: elementKind, alignment: alignment)
        self.absoluteOffset = absoluteOffset
    }
}

// MARK: - Section / environment / configuration

@preconcurrency @MainActor
public final class NSCollectionLayoutSection {
    public let group: NSCollectionLayoutGroup
    public var contentInsets: NSDirectionalEdgeInsets = .zero
    public var interGroupSpacing: CGFloat = 0
    public var orthogonalScrollingBehavior: UICollectionLayoutSectionOrthogonalScrollingBehavior = .none
    public var boundarySupplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []
    public var supplementariesFollowContentInsets = true

    public init(group: NSCollectionLayoutGroup) {
        self.group = group
    }
}

@preconcurrency @MainActor
public final class NSCollectionLayoutContainer {
    public let contentSize: CGSize
    public let contentInsets: NSDirectionalEdgeInsets

    public init(contentSize: CGSize,
                contentInsets: NSDirectionalEdgeInsets) {
        self.contentSize = contentSize
        self.contentInsets = contentInsets
    }

    public var effectiveContentSize: CGSize {
        CGSize(width: max(0, contentSize.width - contentInsets.leading - contentInsets.trailing),
               height: max(0, contentSize.height - contentInsets.top - contentInsets.bottom))
    }

    public var effectiveContentInsets: NSDirectionalEdgeInsets { contentInsets }
}

@preconcurrency @MainActor
public final class NSCollectionLayoutEnvironment {
    public let container: NSCollectionLayoutContainer
    public let traitCollection: UITraitCollection

    public init(container: NSCollectionLayoutContainer, traitCollection: UITraitCollection) {
        self.container = container
        self.traitCollection = traitCollection
    }
}

public typealias UICollectionViewCompositionalLayoutSectionProvider =
    (Int, NSCollectionLayoutEnvironment) -> NSCollectionLayoutSection?

@preconcurrency @MainActor
open class UICollectionViewCompositionalLayoutConfiguration {
    public var scrollDirection: UICollectionViewScrollDirection = .vertical
    public var interSectionSpacing: CGFloat = 0
    public var boundarySupplementaryItems: [NSCollectionLayoutBoundarySupplementaryItem] = []

    public init() {}
}

// MARK: - Layout

@preconcurrency @MainActor
open class UICollectionViewCompositionalLayout: UICollectionViewLayout {

    public var configuration: UICollectionViewCompositionalLayoutConfiguration {
        didSet { invalidateLayout() }
    }

    private let sectionProvider: UICollectionViewCompositionalLayoutSectionProvider

    public init(section: NSCollectionLayoutSection) {
        self.configuration = UICollectionViewCompositionalLayoutConfiguration()
        self.sectionProvider = { s, _ in s == 0 ? section : nil }
        super.init()
    }

    public init(section: NSCollectionLayoutSection,
                configuration: UICollectionViewCompositionalLayoutConfiguration) {
        self.configuration = configuration
        self.sectionProvider = { s, _ in s == 0 ? section : nil }
        super.init()
    }

    public init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider) {
        self.configuration = UICollectionViewCompositionalLayoutConfiguration()
        self.sectionProvider = sectionProvider
        super.init()
    }

    public init(sectionProvider: @escaping UICollectionViewCompositionalLayoutSectionProvider,
                configuration: UICollectionViewCompositionalLayoutConfiguration) {
        self.configuration = configuration
        self.sectionProvider = sectionProvider
        super.init()
    }

    // MARK: Cached geometry

    struct Placed {
        var indexPath: IndexPath
        var kind: String?
        /// Orthogonal sections: coordinates inside the nested content
        /// (x from 0, y from the section's local origin). Other sections:
        /// collection-view content coordinates.
        var localFrame: CGRect
        /// A per-item supplementary (badge): scrolls and clips with its
        /// item, unlike a boundary header. MEASURED zIndex 1 vs cell 0.
        var perItem = false
        var zIndex = 0
    }

    struct SectionCache {
        var frame: CGRect
        var orthogonal: Bool
        var orthogonalContentWidth: CGFloat
        var orthogonalOffset: CGFloat
        var items: [Placed]
        var supplementaries: [Placed]
    }

    private var sections: [SectionCache] = []
    private var contentSize: CGSize = .zero
    /// Cross-axis size `prepare()` last used. The collection view's bounds
    /// setter asks `shouldInvalidateLayout` AFTER applying the new size, so
    /// comparing to `cv.bounds` is always false (same trap flow layout
    /// avoids with `preparedCrossExtent`).
    private var preparedBoundsSize: CGSize = CGSize(width: -1, height: -1)

    private var fittedListHeights: [IndexPath: CGFloat] = [:]
    private var fittedListWidth: CGFloat = -1

    func _noteFittedListHeight(_ height: CGFloat, at indexPath: IndexPath) -> Bool {
        let h = snap(height)
        if fittedListHeights[indexPath] == h { return false }
        fittedListHeights[indexPath] = h
        return true
    }

    open override var collectionViewContentSize: CGSize { contentSize }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        // MEASURED Feed-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1:
        // collection view abs `[0, 138, 820, 1180]` both sides, cards
        // golden `[16, 298, 788, 533.5]` vs ours `[16, 298, 358, 291.5]`.
        // 358 = 390 − 32 (section insets); 390 is UIViewController.loadView
        // default. Phone / Catalyst keep the previous cv.bounds compare
        // (phone Feed already prepares at 375).
        if OpenUIKitRuntime.systemFontCut == .iOS {
            return newBounds.size != preparedBoundsSize
        }
        guard let cv = collectionView else { return false }
        return newBounds.size != cv.bounds.size
    }

    private func snap(_ v: CGFloat) -> CGFloat {
        let scale = collectionView?.traitCollection.displayScale ?? 2
        let s = scale > 0 ? scale : 2
        return (v * s).rounded() / s
    }

    private func resolve(_ dim: NSCollectionLayoutDimension,
                         containerWidth: CGFloat, containerHeight: CGFloat) -> CGFloat {
        if dim.isFractionalWidth { return dim.dimension * containerWidth }
        if dim.isFractionalHeight { return dim.dimension * containerHeight }
        return dim.dimension
    }

    private func resolveSize(_ size: NSCollectionLayoutSize,
                            containerWidth: CGFloat, containerHeight: CGFloat) -> CGSize {
        CGSize(width: snap(resolve(size.widthDimension,
                                     containerWidth: containerWidth, containerHeight: containerHeight)),
               height: snap(resolve(size.heightDimension,
                                    containerWidth: containerWidth, containerHeight: containerHeight)))
    }

    open override func prepare() {
        let oldOffsets: [CGFloat] = sections.map(\.orthogonalOffset)
        sections.removeAll()
        contentSize = .zero
        guard let cv = collectionView else { return }

        preparedBoundsSize = cv.bounds.size
        if cv.bounds.width != fittedListWidth {
            fittedListHeights.removeAll()
            fittedListWidth = cv.bounds.width
        }
        let container = NSCollectionLayoutContainer(contentSize: cv.bounds.size,
                                                      contentInsets: .zero)
        let env = NSCollectionLayoutEnvironment(container: container,
                                                traitCollection: cv.traitCollection)
        var y: CGFloat = 0
        let n = cv.numberOfSections
        for s in 0..<n {
            if s > 0 { y += configuration.interSectionSpacing }
            guard let spec = sectionProvider(s, env) else { continue }
            let kept = s < oldOffsets.count ? oldOffsets[s] : 0
            let cache = layoutSection(spec, index: s, originY: y, env: env,
                                       collectionView: cv, orthogonalOffset: kept)
            sections.append(cache)
            y = cache.frame.maxY
        }
        contentSize = CGSize(width: cv.bounds.width, height: y)
    }

    private func layoutSection(_ spec: NSCollectionLayoutSection, index: Int,
                               originY: CGFloat, env: NSCollectionLayoutEnvironment,
                               collectionView cv: UICollectionView,
                               orthogonalOffset: CGFloat) -> SectionCache {
        var insets = spec.contentInsets
        if index == 0,
           let list = spec._listConfiguration,
           list.appearance == .insetGrouped || list.appearance == .grouped {
            // MEASURED collection_list_inset (no bar): collection abs.y 0,
            // first cell y 35. MEASURED TableEditor t5800 (large-title
            // bar 10+106): collection abs.y 116, first cell y 116 — flush,
            // inter-section still 35 (Foxtrot 461 → Starred 496).
            let windowY = cv.convert(.zero, to: nil).y
            if windowY > 1 { insets.top = 0 }
        }
        let containerW = env.container.effectiveContentSize.width
        let contentW = max(0, containerW - insets.leading - insets.trailing)
        // MEASURED Feed t200.rtl, iPhone SE 2x / iOS 26.1: NSDirectionalEdgeInsets
        // resolve against the collection view's layout direction. Equal 16/16
        // leaves a 343 pt card at x 16 either way (375 − 16 − 343); unequal
        // leading/trailing would swap the physical left edge. Orthogonal
        // items stay packed in content-space from `leading` and are mirrored
        // in `parentFrame`.
        let rtl = cv._layoutIsRTL
        let physicalLeading = rtl ? insets.trailing : insets.leading
        let groupSize = resolveSize(spec.group.layoutSize,
                                     containerWidth: contentW,
                                     containerHeight: env.container.effectiveContentSize.height)
        let itemCount = cv.numberOfItems(inSection: index)
        let perGroup = max(1, spec.group.expandedSubitems().count)
        let groupCount = itemCount == 0 ? 0 : (itemCount + perGroup - 1) / perGroup
        let orthogonal = spec.orthogonalScrollingBehavior != .none

        // Header (alignment .top / .topLeading / .topTrailing).
        var headerHeight: CGFloat = 0
        var headerPlaced: Placed?
        if let header = spec.boundarySupplementaryItems.first(where: {
            $0.alignment == .top || $0.alignment == .topLeading || $0.alignment == .topTrailing
        }) {
            let hSize = resolveSize(header.layoutSize,
                                    containerWidth: spec.supplementariesFollowContentInsets ? contentW : containerW,
                                    containerHeight: env.container.effectiveContentSize.height)
            headerHeight = hSize.height
            let hx: CGFloat = spec.supplementariesFollowContentInsets ? physicalLeading : 0
            let hw = spec.supplementariesFollowContentInsets ? contentW : containerW
            headerPlaced = Placed(
                indexPath: IndexPath(item: 0, section: index),
                kind: header.elementKind,
                localFrame: CGRect(x: snap(hx + header.absoluteOffset.x),
                                    y: snap(header.absoluteOffset.y),
                                    width: hSize.width > 0 ? hSize.width : hw,
                                    height: headerHeight))
        }

        let groupsY = headerHeight + insets.top
        var items: [Placed] = []
        var itemSupplementaries: [Placed] = []
        var cursor: CGFloat = 0
        var nextItem = 0

        if let listCfg = spec._listConfiguration, !orthogonal {
            // MEASURED collection_list_plain / collection_list_inset, iPhone
            // SE 2x / iOS 26.1: list items are independently sized (52 /
            // 68.5 / first-plain 70.5). The estimated group height is only
            // the first guess; fittedListHeights is filled from
            // preferredLayoutAttributesFitting after the cell is configured.
            var y: CGFloat = 0
            for i in 0..<itemCount {
                let path = IndexPath(item: i, section: index)
                var h = fittedListHeights[path]
                    ?? UICollectionViewListCell.estimatedRowHeight(for: listCfg.appearance)
                if fittedListHeights[path] == nil, i == 0 {
                    h += UICollectionViewListCell.headerTopPadding(for: listCfg.appearance)
                }
                h = snap(h)
                items.append(Placed(
                    indexPath: path,
                    kind: nil,
                    localFrame: CGRect(x: snap(physicalLeading),
                                       y: snap(originY + groupsY + y),
                                       width: snap(contentW),
                                       height: h)))
                y += h
            }
            cursor = y
        } else {
        for g in 0..<groupCount {
            let origin: CGPoint
            if orthogonal {
                origin = CGPoint(x: insets.leading + cursor, y: groupsY)
            } else {
                origin = CGPoint(x: physicalLeading, y: originY + groupsY + cursor)
            }
            let placed = layoutGroup(spec.group, origin: origin, groupSize: groupSize,
                                      section: index, startItem: nextItem,
                                      itemCount: itemCount)
            items.append(contentsOf: placed.frames)
            itemSupplementaries.append(contentsOf: placed.supplementaries)
            nextItem = placed.nextItem
            if orthogonal {
                cursor += groupSize.width
                if g + 1 < groupCount { cursor += spec.interGroupSpacing }
            } else {
                cursor += groupSize.height
                if g + 1 < groupCount { cursor += spec.interGroupSpacing }
            }
        }
        }

        let groupsExtent: CGFloat
        if groupCount == 0 {
            groupsExtent = 0
        } else if orthogonal {
            groupsExtent = groupSize.height
        } else {
            groupsExtent = cursor
        }

        let orthogonalWidth: CGFloat
        if orthogonal {
            orthogonalWidth = insets.leading + cursor + insets.trailing
        } else {
            orthogonalWidth = containerW
        }

        let sectionHeight = headerHeight + insets.top + groupsExtent + insets.bottom
        var cache = SectionCache(
            frame: CGRect(x: 0, y: originY, width: containerW, height: sectionHeight),
            orthogonal: orthogonal,
            orthogonalContentWidth: orthogonalWidth,
            orthogonalOffset: 0,
            items: [],
            supplementaries: [])

        if let headerPlaced {
            var h = headerPlaced
            if !orthogonal {
                h.localFrame.origin.y += originY
            }
            cache.supplementaries.append(h)
        }
        cache.supplementaries.append(contentsOf: itemSupplementaries)

        if orthogonal {
            cache.items = items
        } else {
            cache.items = items
        }

        let maxOffset = max(0, orthogonalWidth - containerW)
        cache.orthogonalOffset = min(max(0, orthogonalOffset), maxOffset)
        return cache
    }

    /// Per-item supplementaries for one placed item. Sizes resolve against
    /// the item's inset frame (MEASURED: fractionalHeight(0.25) of a 100 pt
    /// item → 25). Origins snap to the pixel grid with the far edge kept:
    /// MEASURED at 3x, a 20 pt badge centred in a 125 pt item reads x
    /// 82.667 (82.5 → 248/3), and a fractionalWidth(0.5) badge trailing at
    /// 155 reads [92.667, 62.333] — 92.5 rounds up, maxX stays 155.
    private func placeSupplementaries(of item: NSCollectionLayoutItem,
                                      itemFrame: CGRect, indexPath: IndexPath,
                                      rtl: Bool) -> [Placed] {
        item.supplementaryItems.map { supp in
            let raw = CGSize(width: resolve(supp.layoutSize.widthDimension,
                                            containerWidth: itemFrame.width,
                                            containerHeight: itemFrame.height),
                             height: resolve(supp.layoutSize.heightDimension,
                                             containerWidth: itemFrame.width,
                                             containerHeight: itemFrame.height))
            let f = supp.frame(inContainer: itemFrame, size: raw, rtl: rtl)
            let x = snap(f.minX), y = snap(f.minY)
            return Placed(indexPath: indexPath, kind: supp.elementKind,
                          localFrame: CGRect(x: x, y: y,
                                             width: snap(f.maxX) - x,
                                             height: snap(f.maxY) - y),
                          perItem: true, zIndex: supp.zIndex)
        }
    }

    private func layoutGroup(_ group: NSCollectionLayoutGroup, origin: CGPoint,
                             groupSize: CGSize, section: Int, startItem: Int,
                             itemCount: Int)
        -> (frames: [Placed], supplementaries: [Placed], nextItem: Int) {
        let expanded = group.expandedSubitems()
        let spacing = group.interItemSpacing?.spacing ?? 0
        var frames: [Placed] = []
        var supplementaries: [Placed] = []
        var next = startItem
        let n = expanded.count
        let rtl = collectionView?._layoutIsRTL ?? false

        if group.axis == .horizontal {
            var x = origin.x
            // Equal-split when every subitem is fractional-width of the group
            // (repeatingSubitem:count: of a 1.0-wide item), or when the
            // group repeats one item `count` times: MEASURED firefoxrowsprobe,
            // `subitem:count: 2` of an absolute-100 item in a 270 pt group
            // with 20 pt spacing → two 125 pt items, the count overriding
            // the item's own width.
            let equalSplit = n > 1 && (group.repeatCount > 0 ||
                expanded.allSatisfy { $0.layoutSize.widthDimension.isFractionalWidth })
            let itemW: CGFloat? = equalSplit
                ? (groupSize.width - spacing * CGFloat(n - 1)) / CGFloat(n)
                : nil
            for (idx, item) in expanded.enumerated() {
                guard next < itemCount else { break }
                var sz = resolveSize(item.layoutSize,
                                      containerWidth: groupSize.width,
                                      containerHeight: groupSize.height)
                if let itemW { sz.width = itemW }
                if n == 1, item.layoutSize.widthDimension.isFractionalWidth,
                   item.layoutSize.widthDimension.dimension == 1 {
                    sz.width = groupSize.width
                }
                if n == 1, item.layoutSize.heightDimension.isFractionalHeight,
                   item.layoutSize.heightDimension.dimension == 1 {
                    sz.height = groupSize.height
                }
                let insets = item.contentInsets
                let frame = CGRect(
                    x: snap(x + insets.leading),
                    y: snap(origin.y + insets.top),
                    width: max(0, sz.width - insets.leading - insets.trailing),
                    height: max(0, sz.height - insets.top - insets.bottom))
                let path = IndexPath(item: next, section: section)
                frames.append(Placed(indexPath: path, kind: nil, localFrame: frame))
                supplementaries.append(contentsOf: placeSupplementaries(
                    of: item, itemFrame: frame, indexPath: path, rtl: rtl))
                x += sz.width
                if idx + 1 < n { x += spacing }
                next += 1
            }
        } else {
            var y = origin.y
            for (idx, item) in expanded.enumerated() {
                guard next < itemCount else { break }
                var sz = resolveSize(item.layoutSize,
                                      containerWidth: groupSize.width,
                                      containerHeight: groupSize.height)
                if n == 1, item.layoutSize.widthDimension.isFractionalWidth,
                   item.layoutSize.widthDimension.dimension == 1 {
                    sz.width = groupSize.width
                }
                if n == 1, item.layoutSize.heightDimension.isFractionalHeight,
                   item.layoutSize.heightDimension.dimension == 1 {
                    sz.height = groupSize.height
                }
                let insets = item.contentInsets
                let frame = CGRect(
                    x: snap(origin.x + insets.leading),
                    y: snap(y + insets.top),
                    width: max(0, sz.width - insets.leading - insets.trailing),
                    height: max(0, sz.height - insets.top - insets.bottom))
                let path = IndexPath(item: next, section: section)
                frames.append(Placed(indexPath: path, kind: nil, localFrame: frame))
                supplementaries.append(contentsOf: placeSupplementaries(
                    of: item, itemFrame: frame, indexPath: path, rtl: rtl))
                y += sz.height
                if idx + 1 < n { y += spacing }
                next += 1
            }
        }
        return (frames, supplementaries, next)
    }

    private func parentFrame(_ placed: Placed, in cache: SectionCache) -> CGRect {
        if cache.orthogonal {
            let scrolls = placed.kind == nil || placed.perItem
            let shift: CGFloat = scrolls ? cache.orthogonalOffset : 0
            // MEASURED Feed t200.rtl, iPhone SE 2x / iOS 26.1: stories A–D
            // interiors (58,154,128)/(196,101,95)/(127,92,183)/(67,118,205)
            // = palette 3,2,1,0. Item 0 ("A") sits at x 287 = 375 − 16 − 72
            // (16 pt leading inset on the right); item 4 ("E") clips at x −49
            // (23 pt of yellow from the left edge). Nested-scroller dumps
            // stay in content space (A abs.x 16) and do not include the
            // flip; pixels are the oracle. Mirror content-space frames about
            // the section width: screenX = W − (localMaxX − offset).
            let localX: CGFloat
            if collectionView?._layoutIsRTL == true, scrolls {
                localX = cache.frame.width - (placed.localFrame.maxX - shift)
            } else {
                localX = placed.localFrame.minX - shift
            }
            return CGRect(x: cache.frame.minX + localX,
                          y: cache.frame.minY + placed.localFrame.minY,
                          width: placed.localFrame.width,
                          height: placed.localFrame.height)
        }
        return placed.localFrame
    }

    private func makeAttributes(_ placed: Placed, in cache: SectionCache)
        -> UICollectionViewLayoutAttributes {
        let attrs: UICollectionViewLayoutAttributes
        if let kind = placed.kind {
            attrs = UICollectionViewLayoutAttributes(
                forSupplementaryViewOfKind: kind, with: placed.indexPath)
        } else {
            attrs = UICollectionViewLayoutAttributes(forCellWith: placed.indexPath)
        }
        attrs.frame = parentFrame(placed, in: cache)
        attrs.zIndex = placed.zIndex
        return attrs
    }

    open override func layoutAttributesForElements(in rect: CGRect)
        -> [UICollectionViewLayoutAttributes]? {
        var out: [UICollectionViewLayoutAttributes] = []
        for cache in sections {
            let clip = cache.orthogonal
                ? cache.frame
                : CGRect(x: cache.frame.minX, y: cache.frame.minY,
                         width: cache.frame.width, height: cache.frame.height)
            for p in cache.supplementaries {
                let a = makeAttributes(p, in: cache)
                if p.perItem, cache.orthogonal {
                    if a.frame.intersects(rect), a.frame.intersects(clip) { out.append(a) }
                } else if a.frame.intersects(rect) {
                    out.append(a)
                }
            }
            for p in cache.items {
                let a = makeAttributes(p, in: cache)
                if cache.orthogonal {
                    if a.frame.intersects(rect), a.frame.intersects(clip) { out.append(a) }
                } else if a.frame.intersects(rect) {
                    out.append(a)
                }
            }
        }
        return out
    }

    open override func layoutAttributesForItem(at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        guard indexPath.section >= 0, indexPath.section < sections.count else { return nil }
        let cache = sections[indexPath.section]
        guard let p = cache.items.first(where: { $0.indexPath == indexPath }) else { return nil }
        return makeAttributes(p, in: cache)
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                            at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        guard indexPath.section >= 0, indexPath.section < sections.count else { return nil }
        let cache = sections[indexPath.section]
        // Per-item supplementaries answer for their own index path; a
        // boundary header answers for any item of its section (unchanged).
        let p = cache.supplementaries.first(where: {
            $0.kind == elementKind && $0.perItem && $0.indexPath == indexPath
        }) ?? cache.supplementaries.first(where: { $0.kind == elementKind && !$0.perItem })
        guard let p else { return nil }
        return makeAttributes(p, in: cache)
    }

    override func handleScrollToItem(at indexPath: IndexPath,
                                     at position: UICollectionView.ScrollPosition) -> Bool {
        guard indexPath.section >= 0, indexPath.section < sections.count else { return false }
        var cache = sections[indexPath.section]
        guard cache.orthogonal else { return false }
        guard let item = cache.items.first(where: { $0.indexPath == indexPath }) else {
            return false
        }
        let visibleW = collectionView?.bounds.width ?? cache.frame.width
        var offset: CGFloat
        if position.contains(.centeredHorizontally) {
            offset = item.localFrame.midX - visibleW / 2
        } else if position.contains(.right) {
            offset = item.localFrame.maxX - visibleW
        } else {
            offset = item.localFrame.minX
        }
        let maxOffset = max(0, cache.orthogonalContentWidth - visibleW)
        cache.orthogonalOffset = min(max(0, offset), maxOffset)
        sections[indexPath.section] = cache
        return true
    }
}
