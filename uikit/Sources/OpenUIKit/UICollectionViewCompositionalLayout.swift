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

    public init(layoutSize: NSCollectionLayoutSize) {
        self.layoutSize = layoutSize
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

    public init(layoutSize: NSCollectionLayoutSize, elementKind: String) {
        self.elementKind = elementKind
        super.init(layoutSize: layoutSize)
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

    open override var collectionViewContentSize: CGSize { contentSize }

    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
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
        let insets = spec.contentInsets
        let containerW = env.container.effectiveContentSize.width
        let contentW = max(0, containerW - insets.leading - insets.trailing)
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
            let hx: CGFloat = spec.supplementariesFollowContentInsets ? insets.leading : 0
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
        var cursor: CGFloat = 0
        var nextItem = 0

        for g in 0..<groupCount {
            let origin: CGPoint
            if orthogonal {
                origin = CGPoint(x: insets.leading + cursor, y: groupsY)
            } else {
                origin = CGPoint(x: insets.leading, y: originY + groupsY + cursor)
            }
            let placed = layoutGroup(spec.group, origin: origin, groupSize: groupSize,
                                      section: index, startItem: nextItem,
                                      itemCount: itemCount)
            items.append(contentsOf: placed.frames)
            nextItem = placed.nextItem
            if orthogonal {
                cursor += groupSize.width
                if g + 1 < groupCount { cursor += spec.interGroupSpacing }
            } else {
                cursor += groupSize.height
                if g + 1 < groupCount { cursor += spec.interGroupSpacing }
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

        if orthogonal {
            cache.items = items
        } else {
            cache.items = items
        }

        let maxOffset = max(0, orthogonalWidth - containerW)
        cache.orthogonalOffset = min(max(0, orthogonalOffset), maxOffset)
        return cache
    }

    private func layoutGroup(_ group: NSCollectionLayoutGroup, origin: CGPoint,
                             groupSize: CGSize, section: Int, startItem: Int,
                             itemCount: Int)
        -> (frames: [Placed], nextItem: Int) {
        let expanded = group.expandedSubitems()
        let spacing = group.interItemSpacing?.spacing ?? 0
        var frames: [Placed] = []
        var next = startItem
        let n = expanded.count

        if group.axis == .horizontal {
            var x = origin.x
            // Equal-split when every subitem is fractional-width of the group
            // (repeatingSubitem:count: of a 1.0-wide item).
            let equalSplit = n > 1 && expanded.allSatisfy { $0.layoutSize.widthDimension.isFractionalWidth }
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
                frames.append(Placed(indexPath: IndexPath(item: next, section: section),
                                      kind: nil, localFrame: frame))
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
                frames.append(Placed(indexPath: IndexPath(item: next, section: section),
                                      kind: nil, localFrame: frame))
                y += sz.height
                if idx + 1 < n { y += spacing }
                next += 1
            }
        }
        return (frames, next)
    }

    private func parentFrame(_ placed: Placed, in cache: SectionCache) -> CGRect {
        if cache.orthogonal {
            let shift: CGFloat = placed.kind == nil ? cache.orthogonalOffset : 0
            return CGRect(x: cache.frame.minX + placed.localFrame.minX - shift,
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
                if a.frame.intersects(rect) { out.append(a) }
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
        guard let p = cache.supplementaries.first(where: { $0.kind == elementKind }) else {
            return nil
        }
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
