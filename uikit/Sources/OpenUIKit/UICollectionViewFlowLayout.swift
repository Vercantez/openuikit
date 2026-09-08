// UICollectionViewFlowLayout. Owner: collection module (M13).
//
// LINE-BASED grid layout, MEASURED against real UIKit (iOS 26 Mac Catalyst,
// `scripts/flow_probe.sh` — 20 configurations covering both scroll
// directions, uniform and delegate-supplied item sizes, section insets,
// headers/footers and empty sections). Every rule below reproduces those
// frames exactly:
//
//  1. Items are packed greedily into LINES across the cross axis (a row when
//     scrolling vertically, a column when scrolling horizontally). An item
//     joins the current line while
//         used + minimumInteritemSpacing + itemLength <= available
//     where `available` is the collection view's cross extent minus its
//     content inset and the section inset. A line always holds >= 1 item.
//
//  2. The line's actual spacing is NOT the minimum — it is the leftover
//     space DISTRIBUTED over the gaps, which is why UIKit's property is
//     called "minimum". Three measurably different cases:
//       * The line is FULL (a next item existed and did not fit):
//         spacing = (available - sum(lengths)) / (n - 1). The last item on
//         the line therefore ends flush with the content edge. True even
//         when the items differ in size (probes M, AD).
//       * The line is the LAST of its section AND every item on it has the
//         SAME SIZE: UIKit still spaces it as if the line were filled — it
//         appends PHANTOM items of that size while they fit and distributes
//         over the hypothetical full line. Measured: 4 items of 50 pt in
//         375 pt with a 10 pt minimum land 15 pt apart (a full line of 6),
//         not 10 pt apart and not spread across the width. Whether the
//         sizes come from `itemSize` or from the delegate makes no
//         difference (probes X/Y/Z).
//       * The line is the LAST and its items DIFFER in size (in either
//         dimension — one taller item is enough): the fill collapses to the
//         plain `minimumInteritemSpacing`, left-aligned (probes AA, AB).
//       * In the first two cases, if only ONE item fits per line the item is
//         CENTERED in `available` — including when it is wider than the
//         line, which is how UIKit produces the negative origin it warns
//         about.
//
//  3. Item origins are SNAPPED TO THE DEVICE PIXEL GRID (measured: a
//     10.333 pt spacing lands items at 12 / 102.5 / 192.5 at scale 2, i.e.
//     the exact position rounded to the nearest half point). Sizes are not
//     snapped.
//
//  4. Lines are separated by exactly `minimumLineSpacing` (the main axis is
//     never justified), and a line's main extent is the LARGEST item on it;
//     shorter items are CENTERED across the line.
//
//  5. Section chrome: the header spans the full cross extent of the
//     collection view (section insets do NOT apply to it), then
//     sectionInset.top, then the lines, then sectionInset.bottom, then the
//     footer. An EMPTY section still contributes its header, both insets and
//     its footer. A zero-length reference size means no supplementary view
//     at all.
//
// Not implemented: `sectionHeadersPinToVisibleBounds` (UIKit's default is
// false), self-sizing cells (`estimatedItemSize`), and decoration views —
// see docs/KNOWN_GAPS.md.

public enum UICollectionViewScrollDirection: Sendable {
    case vertical, horizontal
}

@preconcurrency @MainActor
open class UICollectionViewFlowLayout: UICollectionViewLayout {
    public typealias ScrollDirection = UICollectionViewScrollDirection

    open override class var invalidationContextClass: AnyClass {
        UICollectionViewFlowLayoutInvalidationContext.self
    }

    open override func invalidationContext(forBoundsChange newBounds: CGRect)
        -> UICollectionViewLayoutInvalidationContext {
        let context = super.invalidationContext(forBoundsChange: newBounds)
        if let flow = context as? UICollectionViewFlowLayoutInvalidationContext {
            // collectionblockingprobe flow.bounds.{same,origin,width}, iOS
            // 26.1 iPhone 16: attributes false/true/true; metrics always false.
            flow.invalidateFlowLayoutAttributes = collectionView?.bounds != newBounds
            flow.invalidateFlowLayoutDelegateMetrics = false
        }
        return context
    }


    // MARK: Configuration (UIKit defaults)

    public var itemSize = CGSize(width: 50, height: 50) {
        didSet { if itemSize != oldValue { invalidateLayout() } }
    }
    public var minimumLineSpacing: CGFloat = 10 {
        didSet { if minimumLineSpacing != oldValue { invalidateLayout() } }
    }
    public var minimumInteritemSpacing: CGFloat = 10 {
        didSet { if minimumInteritemSpacing != oldValue { invalidateLayout() } }
    }
    public var sectionInset: UIEdgeInsets = .zero {
        didSet { invalidateLayout() }
    }
    public var scrollDirection: ScrollDirection = .vertical {
        didSet { if scrollDirection != oldValue { invalidateLayout() } }
    }
    public var headerReferenceSize: CGSize = .zero {
        didSet { if headerReferenceSize != oldValue { invalidateLayout() } }
    }
    public var footerReferenceSize: CGSize = .zero {
        didSet { if footerReferenceSize != oldValue { invalidateLayout() } }
    }

    public override init() { super.init() }

    // MARK: Cached geometry

    struct Line {
        var start: CGFloat      // main-axis start
        var end: CGFloat        // main-axis end
        var first: Int          // first item index
        var count: Int
    }

    struct SectionGeometry {
        var start: CGFloat = 0  // main-axis start (the header's edge)
        var end: CGFloat = 0
        var header: CGRect?
        var footer: CGRect?
        var itemFrames: [CGRect] = []
        var lines: [Line] = []
    }

    private(set) var sections: [SectionGeometry] = []
    private var contentSize: CGSize = .zero
    /// Cross extent the cache was built for — a width change must relayout.
    private var preparedCrossExtent: CGFloat = -1

    private var isVertical: Bool { scrollDirection == .vertical }

    // MARK: Delegate plumbing
    //
    // Real UIKit asks the delegate with respondsToSelector and falls back to
    // its own properties. There is no ObjC runtime here, so the protocol's
    // DEFAULT implementations return the layout's property (UIReuse-style
    // sentinels would leak into app code) — see UICollectionView.swift.

    private var flowDelegate: UICollectionViewDelegateFlowLayout? {
        collectionView?.delegate as? UICollectionViewDelegateFlowLayout
    }

    func itemSize(at indexPath: IndexPath) -> CGSize {
        guard let cv = collectionView, let d = flowDelegate else { return itemSize }
        return d.collectionView(cv, layout: self, sizeForItemAt: indexPath)
    }

    func sectionInset(for section: Int) -> UIEdgeInsets {
        guard let cv = collectionView, let d = flowDelegate else { return sectionInset }
        return d.collectionView(cv, layout: self, insetForSectionAt: section)
    }

    func lineSpacing(for section: Int) -> CGFloat {
        guard let cv = collectionView, let d = flowDelegate else { return minimumLineSpacing }
        return d.collectionView(cv, layout: self, minimumLineSpacingForSectionAt: section)
    }

    func interitemSpacing(for section: Int) -> CGFloat {
        guard let cv = collectionView, let d = flowDelegate else { return minimumInteritemSpacing }
        return d.collectionView(cv, layout: self, minimumInteritemSpacingForSectionAt: section)
    }

    func headerSize(for section: Int) -> CGSize {
        guard let cv = collectionView, let d = flowDelegate else { return headerReferenceSize }
        return d.collectionView(cv, layout: self, referenceSizeForHeaderInSection: section)
    }

    func footerSize(for section: Int) -> CGSize {
        guard let cv = collectionView, let d = flowDelegate else { return footerReferenceSize }
        return d.collectionView(cv, layout: self, referenceSizeForFooterInSection: section)
    }

    // MARK: Preparation

    /// Round to the device pixel grid (rule 3).
    private func snap(_ v: CGFloat) -> CGFloat {
        let scale = collectionView.map { $0.traitCollection.displayScale } ?? 2
        let s = scale > 0 ? scale : 2
        return (v * s).rounded() / s
    }

    open override func prepare() {
        sections.removeAll()
        contentSize = .zero
        guard let cv = collectionView else { return }

        let inset = cv.contentInset
        let crossExtent = isVertical
            ? cv.bounds.width - inset.left - inset.right
            : cv.bounds.height - inset.top - inset.bottom
        preparedCrossExtent = crossExtent
        let fullCross = isVertical ? cv.bounds.width : cv.bounds.height

        /// Build a rect from (main, cross) coordinates.
        func rect(main: CGFloat, cross: CGFloat,
                  mainLen: CGFloat, crossLen: CGFloat) -> CGRect {
            isVertical
                ? CGRect(x: cross, y: main, width: crossLen, height: mainLen)
                : CGRect(x: main, y: cross, width: mainLen, height: crossLen)
        }

        let sectionCount = cv.numberOfSections
        var main: CGFloat = 0
        // 1e-6 absorbs the binary-representation error of exact fits (an
        // item grid that sums to the width to the last digit must not spill).
        let eps: CGFloat = 1e-6

        for s in 0..<sectionCount {
            var g = SectionGeometry()
            g.start = main

            let hSize = headerSize(for: s)
            let headerLen = isVertical ? hSize.height : hSize.width
            if headerLen > 0 {
                g.header = rect(main: main, cross: 0, mainLen: headerLen, crossLen: fullCross)
                main += headerLen
            }

            let si = sectionInset(for: s)
            let leading = isVertical ? si.left : si.top
            let trailing = isVertical ? si.right : si.bottom
            let mainLeading = isVertical ? si.top : si.left
            let mainTrailing = isVertical ? si.bottom : si.right
            let available = crossExtent - leading - trailing
            let interitem = interitemSpacing(for: s)
            let lineGap = lineSpacing(for: s)

            main += mainLeading

            let count = cv.numberOfItems(inSection: s)
            var sizes: [CGSize] = []
            sizes.reserveCapacity(count)
            for i in 0..<count {
                sizes.append(itemSize(at: IndexPath(item: i, section: s)))
            }
            func crossLen(_ i: Int) -> CGFloat {
                isVertical ? sizes[i].width : sizes[i].height
            }
            func mainLen(_ i: Int) -> CGFloat {
                isVertical ? sizes[i].height : sizes[i].width
            }

            g.itemFrames = Swift.Array(repeating: .zero, count: count)
            var i = 0
            var lineStart = main
            while i < count {
                // Rule 1: greedy pack.
                var n = 1
                var sum = crossLen(i)
                while i + n < count {
                    let next = crossLen(i + n)
                    if sum + interitem + next <= available + eps {
                        sum += interitem + next
                        n += 1
                    } else {
                        break
                    }
                }
                let full = (i + n) < count
                // Rule 2: a UNIFORM line (every item the same size, in BOTH
                // dimensions) is the only one UIKit phantom-fills.
                var uniform = true
                for k in 1..<Swift.max(n, 1) where sizes[i + k] != sizes[i] {
                    uniform = false
                }

                var spacing: CGFloat
                var centered = false
                if full {
                    // Justify across the items actually on the line.
                    spacing = n > 1 ? (available - sum + CGFloat(n - 1) * interitem)
                        / CGFloat(n - 1) : 0
                    centered = n == 1
                } else if uniform {
                    // Last line: fill it with phantoms of the same size and
                    // distribute over that hypothetical full line.
                    let len = crossLen(i)
                    var effN = n
                    var effSum = sum
                    // A zero-length item with zero spacing would fill the
                    // line forever; one phantom of nothing is enough.
                    while len + interitem > 0, effSum + interitem + len <= available + eps {
                        effSum += interitem + len
                        effN += 1
                    }
                    spacing = effN > 1
                        ? (available - CGFloat(effN) * len) / CGFloat(effN - 1)
                        : 0
                    centered = effN <= 1
                } else {
                    // Last line, mixed sizes: the minimum, left-aligned.
                    spacing = interitem
                }

                var lineMainLen: CGFloat = 0
                for k in 0..<n { lineMainLen = Swift.max(lineMainLen, mainLen(i + k)) }

                var cross = leading
                if centered {
                    cross = leading + (available - crossLen(i)) / 2
                }
                for k in 0..<n {
                    let idx = i + k
                    // Rule 4: shorter items centered across the line.
                    let m = lineStart + (lineMainLen - mainLen(idx)) / 2
                    g.itemFrames[idx] = rect(main: snap(m), cross: snap(cross),
                                             mainLen: mainLen(idx),
                                             crossLen: crossLen(idx))
                    cross += crossLen(idx) + spacing
                }
                g.lines.append(Line(start: lineStart, end: lineStart + lineMainLen,
                                    first: i, count: n))
                lineStart += lineMainLen
                i += n
                if i < count { lineStart += lineGap }
            }
            main = lineStart

            main += mainTrailing

            let fSize = footerSize(for: s)
            let footerLen = isVertical ? fSize.height : fSize.width
            if footerLen > 0 {
                g.footer = rect(main: main, cross: 0, mainLen: footerLen, crossLen: fullCross)
                main += footerLen
            }
            g.end = main
            sections.append(g)
        }

        contentSize = isVertical
            ? CGSize(width: crossExtent, height: main)
            : CGSize(width: main, height: crossExtent)
    }

    open override var collectionViewContentSize: CGSize { contentSize }

    /// A cross-axis resize (a width change when scrolling vertically) makes
    /// every line stale; scrolling alone does not.
    open override func shouldInvalidateLayout(forBoundsChange newBounds: CGRect) -> Bool {
        guard let cv = collectionView else { return false }
        let inset = cv.contentInset
        let cross = isVertical
            ? newBounds.width - inset.left - inset.right
            : newBounds.height - inset.top - inset.bottom
        return cross != preparedCrossExtent
    }

    // MARK: Queries

    open override func layoutAttributesForItem(at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        prepareIfNeeded()
        guard indexPath.section >= 0, indexPath.section < sections.count else { return nil }
        let g = sections[indexPath.section]
        guard indexPath.item >= 0, indexPath.item < g.itemFrames.count else { return nil }
        let a = UICollectionViewLayoutAttributes(forCellWith: indexPath)
        a.frame = g.itemFrames[indexPath.item]
        return a
    }

    open override func layoutAttributesForSupplementaryView(ofKind elementKind: String,
                                                            at indexPath: IndexPath)
        -> UICollectionViewLayoutAttributes? {
        prepareIfNeeded()
        guard indexPath.section >= 0, indexPath.section < sections.count else { return nil }
        let g = sections[indexPath.section]
        let frame: CGRect?
        switch elementKind {
        case UICollectionView.elementKindSectionHeader: frame = g.header
        case UICollectionView.elementKindSectionFooter: frame = g.footer
        default: frame = nil
        }
        guard let frame else { return nil }
        let a = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: elementKind,
                                                 with: IndexPath(item: 0,
                                                                 section: indexPath.section))
        a.frame = frame
        return a
    }

    /// O(visible + log sections + log lines): sections and lines are both
    /// sorted on the main axis, so the visible window is found by binary
    /// search rather than by walking every item (the invariant the 10k-item
    /// reuse test protects).
    open override func layoutAttributesForElements(in rect: CGRect)
        -> [UICollectionViewLayoutAttributes]? {
        prepareIfNeeded()
        let lo = isVertical ? rect.minY : rect.minX
        let hi = isVertical ? rect.maxY : rect.maxX
        var out: [UICollectionViewLayoutAttributes] = []

        // First section whose end is past the window start.
        var loS = 0, hiS = sections.count - 1, firstSection = sections.count
        while loS <= hiS {
            let mid = (loS + hiS) / 2
            if sections[mid].end > lo {
                firstSection = mid
                hiS = mid - 1
            } else {
                loS = mid + 1
            }
        }

        var s = firstSection
        while s < sections.count, sections[s].start < hi {
            let g = sections[s]
            if let h = g.header, intersects(h, lo: lo, hi: hi) {
                let a = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
                    with: IndexPath(item: 0, section: s))
                a.frame = h
                out.append(a)
            }
            if let f = g.footer, intersects(f, lo: lo, hi: hi) {
                let a = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: UICollectionView.elementKindSectionFooter,
                    with: IndexPath(item: 0, section: s))
                a.frame = f
                out.append(a)
            }
            // Lines intersecting the window (binary search on line ends).
            var loL = 0, hiL = g.lines.count - 1, firstLine = g.lines.count
            while loL <= hiL {
                let mid = (loL + hiL) / 2
                if g.lines[mid].end > lo {
                    firstLine = mid
                    hiL = mid - 1
                } else {
                    loL = mid + 1
                }
            }
            var l = firstLine
            while l < g.lines.count, g.lines[l].start < hi {
                let line = g.lines[l]
                for k in 0..<line.count {
                    let idx = line.first + k
                    let a = UICollectionViewLayoutAttributes(
                        forCellWith: IndexPath(item: idx, section: s))
                    a.frame = g.itemFrames[idx]
                    out.append(a)
                }
                l += 1
            }
            s += 1
        }
        return out
    }

    private func intersects(_ r: CGRect, lo: CGFloat, hi: CGFloat) -> Bool {
        let a = isVertical ? r.minY : r.minX
        let b = isVertical ? r.maxY : r.maxX
        return b > lo && a < hi
    }
}
