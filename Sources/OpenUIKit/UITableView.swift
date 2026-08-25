// UITableView. Owner: tableview module (M10).
//
// A UIScrollView subclass with real cell reuse: only the rows intersecting
// the visible rect are instantiated; cells scrolling out are recycled into
// per-identifier pools and handed back by dequeueReusableCell(withIdentifier:).
// Layout is tiled on every contentOffset change (bounds.origin — the scroll
// model from UIScrollView.swift), so scrolling re-tiles incrementally in
// O(visible + log rows) using prefix-summed section metrics.
//
// Chrome MEASURED against real UIKit (iOS 26 Catalyst oracle, compact
// width — golden/tableview_*):
//   plain:        section header 40.5 pt (17 semibold at x=8, y=10,
//                 secondaryLabel), every header preceded by the 22 pt
//                 sectionHeaderTopPadding; separators inset 16 left / 8
//                 right; headers pin (stick) to the visible top, pushed out
//                 by the next section, and carry an opaque systemBackground.
//   insetGrouped: 8 pt side inset, one rounded "card" (radius 26,
//                 secondarySystemGroupedBackground) behind each section's
//                 rows; header 40.5 pt with the label at x=24; footer
//                 8 + text + 6 pt (30 for one 13 pt line); separators inset
//                 16 both sides, hidden on a section's last row; no
//                 top padding (the first header starts at y=0).
//   Separators adjacent to a selected/highlighted row are hidden (measured:
//   the selected row's own separator AND the previous row's).
//
// Row heights: delegate heightForRowAt → table rowHeight → the measured
// default 51.5 (subtitle cells are 70.5 — a data source/delegate that uses
// subtitle cells should return UITableViewCell.subtitleRowHeight, real
// self-sizing is out of scope, see docs/KNOWN_GAPS.md).

// MARK: - IndexPath

public struct IndexPath: Hashable, Comparable, Sendable {
    public var section: Int
    public var row: Int
    public init(row: Int, section: Int) {
        self.row = row
        self.section = section
    }
    public static func < (a: IndexPath, b: IndexPath) -> Bool {
        (a.section, a.row) < (b.section, b.row)
    }
}

// MARK: - Data source / delegate protocols

@MainActor
public protocol UITableViewDataSource: AnyObject {
    func numberOfSections(in tableView: UITableView) -> Int
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
}

public extension UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { nil }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { nil }
}

@MainActor
public protocol UITableViewDelegate: UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath)
}

public extension UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        UITableView.automaticDimension
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {}
}

// MARK: - Card view (inset-grouped section background)

/// The rounded card behind an inset-grouped section's rows. Private class
/// name: compare.py skips the subtree (real UIKit's internals differ).
@MainActor
final class UITableViewCardView: UIView {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .secondarySystemGroupedBackground
    }
}

extension UIColor {
    /// The card fill at alpha 0 — the fade-out endpoint for a cell that
    /// borrowed the fill to cross between sections (see performUpdates).
    static let clearCardFill = UIColor(dynamicProvider: { traits in
        let c = UIColor.secondarySystemGroupedBackground.resolvedCGColor(with: traits)
        return UIColor(red: c.red, green: c.green, blue: c.blue, alpha: 0)
    })
}

// MARK: - UITableView

@MainActor
open class UITableView: UIScrollView {
    public enum Style: Sendable {
        case plain, grouped, insetGrouped
    }

    /// Sentinel for "let the table compute it" (UIKit's is -1 too).
    public static let automaticDimension: CGFloat = -1

    // MARK: Measured chrome constants (file header)

    static let headerHeight: CGFloat = 40.5
    static let cardCornerRadius: CGFloat = 26
    static let plainSeparatorRightInset: CGFloat = 8
    static let groupedSeparatorRightInset: CGFloat = 16
    static let separatorLeftInset: CGFloat = 16
    static let plainHeaderLabelX: CGFloat = 8

    /// Side margin of the inset-grouped card. MEASURED 8 pt in the
    /// offscreen Catalyst oracle (golden/tableview_grouped) but 16 pt when
    /// the same table renders in a real UIWindow (golden/tableview_dark,
    /// oracle2) — real-device metrics use the 16 pt reading. Header/footer
    /// text indents by this + 16.
    public var insetGroupedSideInset: CGFloat = 8 {
        didSet { if insetGroupedSideInset != oldValue { setNeedsMetrics() } }
    }
    var groupedHeaderLabelX: CGFloat { insetGroupedSideInset + 16 }

    // MARK: Public configuration

    public let style: Style
    public weak var dataSource: UITableViewDataSource? {
        didSet { if dataSource !== oldValue { reloadData() } }
    }
    // NOTE: like UIKit, the table's delegate is the inherited scroll-view
    // `delegate`; assign a UITableViewDelegate to it (the protocol refines
    // UIScrollViewDelegate) — the table discovers the table conformance
    // dynamically.
    var tableDelegate: UITableViewDelegate? { delegate as? UITableViewDelegate }

    /// Row height used when the delegate does not provide one.
    /// automaticDimension resolves to the measured default (51.5).
    public var rowHeight: CGFloat = UITableView.automaticDimension {
        didSet { if rowHeight != oldValue { setNeedsMetrics() } }
    }
    /// Plain style: padding above each section header (measured 22).
    public var sectionHeaderTopPadding: CGFloat = 22 {
        didSet { if sectionHeaderTopPadding != oldValue { setNeedsMetrics() } }
    }
    public enum SeparatorStyle: Sendable { case none, singleLine }
    public var separatorStyle: SeparatorStyle = .singleLine {
        didSet { if separatorStyle != oldValue { retile() } }
    }
    public var allowsSelection = true

    public private(set) var indexPathForSelectedRow: IndexPath?

    // MARK: Init

    public init(frame: CGRect = .zero, style: Style = .plain) {
        self.style = style
        super.init(frame: frame)
        switch style {
        case .plain:
            backgroundColor = .systemBackground
        case .grouped, .insetGrouped:
            backgroundColor = .systemGroupedBackground
        }
        alwaysBounceVertical = true
    }

    public override convenience init(frame: CGRect = .zero) {
        self.init(frame: frame, style: .plain)
    }

    // MARK: Section metrics (prefix sums)

    struct SectionMetrics {
        var start: CGFloat = 0        // includes the plain top padding
        var headerY: CGFloat = 0      // natural (un-stuck) header origin
        var headerHeight: CGFloat = 0
        var rowsStart: CGFloat = 0
        /// Absolute END y of each row (prefix sums; row i spans
        /// [rowY(i), rowEnds[i]]).
        var rowEnds: [CGFloat] = []
        var footerHeight: CGFloat = 0
        var end: CGFloat = 0
        var headerTitle: String?
        var footerTitle: String?

        var rowsEnd: CGFloat { rowEnds.last ?? rowsStart }
        func rowY(_ i: Int) -> CGFloat { i == 0 ? rowsStart : rowEnds[i - 1] }
    }

    var metrics: [SectionMetrics] = []
    private var metricsDirty = true
    private var metricsWidth: CGFloat = -1

    func setNeedsMetrics() {
        metricsDirty = true
        setNeedsLayout()
    }

    /// Scratch label for footer text measurement.
    private let footerSizer: UILabel = {
        let l = UILabel()
        l.font = .systemFont(ofSize: 13)
        l.numberOfLines = 0
        return l
    }()

    private func resolveRowHeight(_ path: IndexPath) -> CGFloat {
        if let d = tableDelegate {
            let h = d.tableView(self, heightForRowAt: path)
            if h >= 0 { return h }
        }
        if rowHeight >= 0 { return rowHeight }
        return UITableViewCell.defaultRowHeight
    }

    private func rebuildMetrics() {
        metrics.removeAll()
        metricsDirty = false
        metricsWidth = bounds.width
        guard let ds = dataSource else {
            contentSize = .zero
            return
        }
        let sections = ds.numberOfSections(in: self)
        metrics.reserveCapacity(sections)
        var y: CGFloat = 0
        for s in 0..<sections {
            var m = SectionMetrics()
            m.headerTitle = ds.tableView(self, titleForHeaderInSection: s)
            m.footerTitle = ds.tableView(self, titleForFooterInSection: s)

            var headerH = tableDelegate?.tableView(self, heightForHeaderInSection: s)
                ?? UITableView.automaticDimension
            if headerH < 0 {
                headerH = m.headerTitle != nil ? UITableView.headerHeight : 0
            }
            if style == .plain, headerH > 0 {
                y += sectionHeaderTopPadding
            }
            m.start = y
            m.headerY = y
            m.headerHeight = headerH
            y += headerH
            m.rowsStart = y

            let rows = ds.tableView(self, numberOfRowsInSection: s)
            m.rowEnds.reserveCapacity(rows)
            for r in 0..<rows {
                y += resolveRowHeight(IndexPath(row: r, section: s))
                m.rowEnds.append(y)
            }

            var footerH = tableDelegate?.tableView(self, heightForFooterInSection: s)
                ?? UITableView.automaticDimension
            if footerH < 0 {
                if let t = m.footerTitle, style != .plain {
                    footerSizer.text = t
                    let maxW = bounds.width - 2 * groupedHeaderLabelX
                    let textH = footerSizer.sizeThatFits(
                        CGSize(width: max(1, maxW),
                               height: CGFloat.greatestFiniteMagnitude)).height
                    footerH = UITableViewHeaderFooterView.footerLabelY + textH
                        + UITableViewHeaderFooterView.footerBottomPadding
                } else if m.footerTitle != nil {
                    // Plain footers: header-like chrome (unmeasured — no
                    // plain-footer golden; see docs/KNOWN_GAPS.md).
                    footerH = UITableView.headerHeight
                } else {
                    footerH = 0
                }
            }
            m.footerHeight = footerH
            y += footerH
            m.end = y
            metrics.append(m)
        }
        contentSize = CGSize(width: bounds.width, height: y)
    }

    // MARK: Public geometry / lookup API

    public var numberOfSections: Int {
        metricsIfNeeded()
        return metrics.count
    }

    public func numberOfRows(inSection section: Int) -> Int {
        metricsIfNeeded()
        guard section >= 0, section < metrics.count else { return 0 }
        return metrics[section].rowEnds.count
    }

    public func rectForRow(at indexPath: IndexPath) -> CGRect {
        metricsIfNeeded()
        guard indexPath.section >= 0, indexPath.section < metrics.count else { return .zero }
        let m = metrics[indexPath.section]
        guard indexPath.row >= 0, indexPath.row < m.rowEnds.count else { return .zero }
        let y = m.rowY(indexPath.row)
        let inset = style == .insetGrouped ? insetGroupedSideInset : 0
        return CGRect(x: inset, y: y, width: bounds.width - 2 * inset,
                      height: m.rowEnds[indexPath.row] - y)
    }

    public func indexPathForRow(at point: CGPoint) -> IndexPath? {
        metricsIfNeeded()
        for (s, m) in metrics.enumerated() {
            guard point.y >= m.rowsStart, point.y < m.rowsEnd else { continue }
            for r in 0..<m.rowEnds.count where point.y < m.rowEnds[r] {
                return IndexPath(row: r, section: s)
            }
        }
        return nil
    }

    public func cellForRow(at indexPath: IndexPath) -> UITableViewCell? {
        visibleCellsByPath[indexPath]
    }

    public func indexPath(for cell: UITableViewCell) -> IndexPath? {
        visibleCellsByPath.first { $1 === cell }?.key
    }

    public var visibleCells: [UITableViewCell] {
        visibleCellsByPath.views.sorted { $0.key < $1.key }.map(\.value)
    }

    public var indexPathsForVisibleRows: [IndexPath]? {
        visibleCellsByPath.isEmpty ? nil : visibleCellsByPath.keys.sorted()
    }

    private func metricsIfNeeded() {
        if metricsDirty || metricsWidth != bounds.width { rebuildMetrics() }
    }

    // MARK: Reload

    public func reloadData() {
        visibleCellsByPath.removeAll { _, cell in
            cell.removeFromSuperview()
            recycle(cell)
        }
        headerViews.removeAll { $1.removeFromSuperview() }
        footerViews.removeAll { $1.removeFromSuperview() }
        cardViews.removeAll { $1.removeFromSuperview() }
        indexPathForSelectedRow = nil
        setNeedsMetrics()
    }

    // MARK: Animated updates (M10)

    /// Animate a data-source change.
    ///
    /// Rows are matched across the update by `identity`, so a row that moves —
    /// including between sections — KEEPS THE SAME CELL: any animation already
    /// running inside it (a checkbox spring, a control's press feedback)
    /// continues uninterrupted while the cell travels from its old slot to its
    /// new one. Section cards, headers, footers and every other visible row
    /// animate into place around it in the same block, so the whole relayout
    /// reads as one coordinated move. Rows with no counterpart before the
    /// update fade in; a row that moves between sections is raised above its
    /// neighbours for the flight.
    ///
    /// This is the portable stand-in for UIKit's `moveRow(at:to:)` /
    /// `insertRows(at:with:)` batch updates: instead of enumerating the
    /// individual moves, the caller mutates its model inside `updates` and
    /// supplies a stable identity per index path.
    ///
    /// `completion` runs on the host clock (`UIView.animate` semantics).
    public func performUpdates(withDuration duration: Double,
                               delay: Double = 0,
                               options: UIView.AnimationOptions = .curveEaseInOut,
                               identity: (IndexPath) -> AnyHashable,
                               updates: () -> Void,
                               completion: (() -> Void)? = nil) {
        guard dataSource != nil, bounds.width > 0, !inTile else {
            updates()
            reloadData()
            completion?()
            return
        }
        metricsIfNeeded()

        // Snapshot which cell and which frame currently represent each
        // identity, plus the section chrome.
        var oldCells: [AnyHashable: UITableViewCell] = [:]
        var oldFrames: [AnyHashable: CGRect] = [:]
        var oldSections: [AnyHashable: Int] = [:]
        for (path, cell) in visibleCellsByPath.views {
            let id = identity(path)
            oldCells[id] = cell
            oldFrames[id] = cell.frame
            oldSections[id] = path.section
        }
        let oldCards = cardViews.views.mapValues { $0.frame }
        let oldHeaders = headerViews.views.mapValues { $0.frame }
        let oldFooters = footerViews.views.mapValues { $0.frame }
        let selectedID = indexPathForSelectedRow.map(identity)

        // Apply the model change and re-key the live cells onto their new
        // index paths BEFORE tiling: a moved row must be re-tiled as "already
        // visible" rather than retired and re-dequeued (which would recycle
        // it and reset its state). inTile suppresses the retile that a
        // contentSize-driven offset clamp would otherwise trigger halfway
        // through the re-key.
        inTile = true
        updates()
        setNeedsMetrics()
        metricsIfNeeded()

        var rekeyed: [IndexPath: UITableViewCell] = [:]
        var kept = Set<ObjectIdentifier>()
        var movedBetweenSections: [UITableViewCell] = []
        let needed = neededViews().cells
        for path in needed {
            let id = identity(path)
            guard let cell = oldCells[id] else { continue }
            rekeyed[path] = cell
            kept.insert(ObjectIdentifier(cell))
            if oldSections[id] != path.section { movedBetweenSections.append(cell) }
        }
        for (_, cell) in visibleCellsByPath.views
        where !kept.contains(ObjectIdentifier(cell)) {
            cell.removeFromSuperview()
            recycle(cell)
        }
        visibleCellsByPath.replaceAll(with: rekeyed)
        if let selectedID {
            indexPathForSelectedRow = needed.first { identity($0) == selectedID }
        }
        inTile = false

        // Tile: creates the genuinely new cells, re-frames everything to the
        // post-update geometry, rebuilds the section chrome.
        retile()

        // Rewind to the pre-update geometry, then animate forward. Assigning
        // the model frame back and re-assigning it inside the block is exactly
        // what UIView.animate records (from → to); the model ends up correct
        // either way.
        var moves: [(view: UIView, target: CGRect)] = []
        var fadeIns: [UIView] = []
        for (path, cell) in visibleCellsByPath.views {
            let target = cell.frame
            if let old = oldFrames[identity(path)], old != target {
                cell.frame = old
                moves.append((cell, target))
            } else if oldFrames[identity(path)] == nil {
                cell.alpha = 0
                fadeIns.append(cell)
            }
        }
        func rewindChrome<V: UIView>(_ views: VisibleViewMap<Int, V>, _ old: [Int: CGRect]) {
            for (s, v) in views.views {
                guard let o = old[s], o != v.frame else { continue }
                let target = v.frame
                v.frame = o
                moves.append((v, target))
            }
        }
        rewindChrome(cardViews, oldCards)
        rewindChrome(headerViews, oldHeaders)
        rewindChrome(footerViews, oldFooters)

        // A row crossing between sections flies over the gap between two
        // cards, where nothing is behind it — and in a grouped table the
        // cell itself is transparent (the card draws the fill). Lend it the
        // card's fill for the flight, then dissolve it over the last beat,
        // once the cell is already sitting inside the destination card: a
        // hard restore would square off the card's 26 pt corners for the few
        // frames the cell spends landing on them.
        let travelFadeDuration = Swift.min(0.12, duration)
        var travellers: [UITableViewCell] = []
        for cell in movedBetweenSections {
            bringSubviewToFront(cell)
            guard style != .plain, cell.backgroundColor == nil else { continue }
            cell.backgroundColor = .secondarySystemGroupedBackground
            travellers.append(cell)
            // Fade to a CLEAR copy of the card fill, not to nil: a nil
            // endpoint interpolates as transparent BLACK, which drags the
            // dissolving row through grey. The completion restores nil.
            UIView.animate(withDuration: travelFadeDuration,
                           delay: delay + duration - travelFadeDuration,
                           options: .curveLinear,
                           animations: { cell.backgroundColor = .clearCardFill })
        }

        guard !moves.isEmpty || !fadeIns.isEmpty else {
            completion?()
            return
        }
        let animated = moves.map(\.view) + fadeIns
        UIView.animate(withDuration: duration, delay: delay, options: options,
                       animations: {
            for m in moves { m.view.frame = m.target }
            for v in fadeIns { v.alpha = 1 }
        }, completion: { _ in
            // The portable engine has no run loop to strip finished
            // animations, and a finished animation still pins the layer to
            // its recorded end value — which would override the frames the
            // next tiling pass assigns. Drop them here (see UIView).
            let now = OpenUIKitRuntime.animationTime
            for v in animated { v._removeFinishedAnimations(at: now) }
            for cell in travellers { cell.backgroundColor = nil }
            completion?()
        })
    }

    // MARK: Cell reuse
    //
    // The pools/factories live in the shared ReuseRegistry (UIReuse.swift) —
    // the same component UICollectionView drives for its cells and
    // supplementary views.

    private let cellRegistry = ReuseRegistry<UITableViewCell>()

    /// Recycled cells kept per identifier (shared cap — see UIReuse.swift).
    static var poolCapacityPerIdentifier: Int { reusePoolCapacityPerIdentifier }

    public func register(_ cellClass: UITableViewCell.Type,
                         forCellReuseIdentifier identifier: String) {
        cellRegistry.register(identifier: identifier) { id in
            cellClass.init(style: .default, reuseIdentifier: id)
        }
    }

    public func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        cellRegistry.dequeue(identifier)
    }

    public func dequeueReusableCell(withIdentifier identifier: String,
                                    for indexPath: IndexPath) -> UITableViewCell {
        guard let cell = dequeueReusableCell(withIdentifier: identifier) else {
            fatalError("dequeueReusableCell(withIdentifier:for:) requires a registered class for '\(identifier)'")
        }
        return cell
    }

    private func recycle(_ cell: UITableViewCell) {
        cell.tableView = nil
        cellRegistry.recycle(cell)
    }

    // MARK: Tiling

    // Slot -> live view bookkeeping (shared component, UIReuse.swift).
    var visibleCellsByPath = VisibleViewMap<IndexPath, UITableViewCell>()
    var headerViews = VisibleViewMap<Int, UITableViewHeaderFooterView>()
    var footerViews = VisibleViewMap<Int, UITableViewHeaderFooterView>()
    var cardViews = VisibleViewMap<Int, UITableViewCardView>()

    open override var bounds: CGRect {
        didSet {
            // Scrolling IS a bounds-origin change: re-tile immediately so
            // event-driven offset changes (drag, deceleration steps,
            // setContentOffset) bring rows in without waiting for a layout
            // pass.
            if bounds.origin != oldValue.origin, !inTile {
                retile()
            }
        }
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        retile()
    }

    /// Re-entrancy guard: tiling adds subviews (→ setNeedsLayout) and can
    /// clamp offsets; never recurse.
    private var inTile = false

    /// Rows and sections that intersect the visible rect at the current
    /// offset, in ascending order. Assumes metrics are up to date.
    func neededViews() -> (cells: [IndexPath], sections: [Int]) {
        let visTop = contentOffset.y
        let visBottom = visTop + bounds.height

        var neededCells: [IndexPath] = []
        var neededSections: [Int] = []
        for (s, m) in metrics.enumerated() {
            if m.start >= visBottom { break }
            guard m.end > visTop else { continue }
            neededSections.append(s)
            let rows = m.rowEnds.count
            guard rows > 0, m.rowsEnd > visTop, m.rowsStart < visBottom else { continue }
            // Binary search: first row whose end is below the visible top.
            var lo = 0, hi = rows - 1, first = rows
            while lo <= hi {
                let mid = (lo + hi) / 2
                if m.rowEnds[mid] > visTop {
                    first = mid
                    hi = mid - 1
                } else {
                    lo = mid + 1
                }
            }
            var r = first
            while r < rows, m.rowY(r) < visBottom {
                neededCells.append(IndexPath(row: r, section: s))
                r += 1
            }
        }
        return (neededCells, neededSections)
    }

    func retile() {
        guard !inTile else { return }
        inTile = true
        defer { inTile = false }

        guard dataSource != nil, bounds.width > 0 else { return }
        metricsIfNeeded()

        let (neededCells, neededSections) = neededViews()
        let visTop = contentOffset.y

        // Retire views that scrolled out.
        visibleCellsByPath.retire(keeping: Set(neededCells)) { _, cell in
            cell.removeFromSuperview()
            recycle(cell)
        }
        let sectionSet = Set(neededSections)
        headerViews.retire(keeping: sectionSet) { $1.removeFromSuperview() }
        footerViews.retire(keeping: sectionSet) { $1.removeFromSuperview() }
        cardViews.retire(keeping: sectionSet) { $1.removeFromSuperview() }

        // Section chrome.
        for s in neededSections {
            let m = metrics[s]
            if style == .insetGrouped, m.rowsEnd > m.rowsStart {
                let card = cardViews[s] ?? {
                    let c = UITableViewCardView()
                    cardViews[s] = c
                    insertSubview(c, at: 0)
                    return c
                }()
                card.frame = CGRect(x: insetGroupedSideInset, y: m.rowsStart,
                                    width: bounds.width - 2 * insetGroupedSideInset,
                                    height: m.rowsEnd - m.rowsStart)
                card.layer.cornerRadius = min(UITableView.cardCornerRadius,
                                              card.bounds.height / 2,
                                              card.bounds.width / 2)
            }
            if m.headerHeight > 0 {
                let header = headerViews[s] ?? {
                    let h = UITableViewHeaderFooterView()
                    headerViews[s] = h
                    addSubview(h)
                    return h
                }()
                header.configure(kind: .header, text: m.headerTitle,
                                 labelX: style == .plain
                                     ? UITableView.plainHeaderLabelX
                                     : groupedHeaderLabelX)
                header.backgroundColor = style == .plain ? .systemBackground : nil
                var y = m.headerY
                if style == .plain {
                    // Sticky: pin to the visible top within the section.
                    let maxY = max(m.headerY, m.rowsEnd - m.headerHeight)
                    y = min(max(m.headerY, visTop), maxY)
                }
                header.frame = CGRect(x: 0, y: y, width: bounds.width,
                                      height: m.headerHeight)
            }
            if m.footerHeight > 0 {
                let footer = footerViews[s] ?? {
                    let f = UITableViewHeaderFooterView()
                    footerViews[s] = f
                    addSubview(f)
                    return f
                }()
                footer.configure(kind: .footer, text: m.footerTitle,
                                 labelX: style == .plain
                                     ? UITableView.plainHeaderLabelX
                                     : groupedHeaderLabelX)
                footer.frame = CGRect(x: 0, y: m.rowsEnd, width: bounds.width,
                                      height: m.footerHeight)
            }
        }

        // Cells.
        for path in neededCells {
            let cell: UITableViewCell
            if let existing = visibleCellsByPath[path] {
                cell = existing
                cell.frame = rectForRow(at: path)
            } else {
                guard let ds = dataSource else { break }
                cell = ds.tableView(self, cellForRowAt: path)
                cell.tableView = self
                cell.frame = rectForRow(at: path)
                if style == .insetGrouped || style == .grouped {
                    // The section card draws the background.
                    cell.backgroundColor = nil
                } else if cell.backgroundColor == nil {
                    cell.backgroundColor = .systemBackground
                }
                cell.setSelected(path == indexPathForSelectedRow, animated: false)
                visibleCellsByPath[path] = cell
                addSubview(cell)
                tableDelegate?.tableView(self, willDisplay: cell, forRowAt: path)
            }
            cell.setNeedsLayout()
        }

        // Z-order: cards behind everything, plain headers above the rows
        // they pin over, indicators on top.
        for s in neededSections.reversed() {
            if let card = cardViews[s] { sendSubviewToBack(card) }
        }
        if style == .plain {
            for s in neededSections {
                if let h = headerViews[s] { bringSubviewToFront(h) }
            }
        }
        if let bar = verticalIndicator { bringSubviewToFront(bar) }
        if let bar = horizontalIndicator { bringSubviewToFront(bar) }

        updateSeparators()
    }

    // MARK: Separators

    /// Horizontal separator insets for `cell` (style-dependent, measured).
    func separatorDrawInsets(for cell: UITableViewCell) -> (left: CGFloat, right: CGFloat) {
        switch style {
        case .plain:
            return (UITableView.separatorLeftInset, UITableView.plainSeparatorRightInset)
        case .grouped, .insetGrouped:
            return (UITableView.separatorLeftInset, UITableView.groupedSeparatorRightInset)
        }
    }

    /// Apply the measured separator visibility rules across visible cells:
    /// no separator on an inset-grouped section's last row, none on a
    /// selected/highlighted row, none on the row directly above one.
    func updateSeparators() {
        for (path, cell) in visibleCellsByPath.views {
            var hidden = separatorStyle == .none
            if style != .plain,
               path.row == metrics[path.section].rowEnds.count - 1 {
                hidden = true
            }
            if cell.isSelected || cell.isHighlighted {
                hidden = true
            }
            if let below = visibleCellsByPath[IndexPath(row: path.row + 1,
                                                        section: path.section)],
               below.isSelected || below.isHighlighted {
                hidden = true
            }
            cell.separatorView.isHidden = hidden
        }
    }

    // MARK: Selection

    public enum ScrollPosition: Sendable { case none, top, middle, bottom }

    /// Programmatic selection (UIKit semantics: no delegate callbacks).
    public func selectRow(at indexPath: IndexPath?, animated: Bool,
                          scrollPosition: ScrollPosition = .none) {
        if let old = indexPathForSelectedRow, old != indexPath {
            visibleCellsByPath[old]?.setSelected(false, animated: animated)
        }
        indexPathForSelectedRow = indexPath
        guard let indexPath else {
            updateSeparators()
            return
        }
        visibleCellsByPath[indexPath]?.setSelected(true, animated: animated)
        if scrollPosition != .none {
            scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        }
        updateSeparators()
    }

    public func deselectRow(at indexPath: IndexPath, animated: Bool) {
        guard indexPathForSelectedRow == indexPath else { return }
        indexPathForSelectedRow = nil
        visibleCellsByPath[indexPath]?.setSelected(false, animated: animated)
        updateSeparators()
    }

    public func scrollToRow(at indexPath: IndexPath, at position: ScrollPosition,
                            animated: Bool) {
        let rect = rectForRow(at: indexPath)
        guard rect.height > 0 else { return }
        var targetY: CGFloat
        switch position {
        case .top:
            targetY = rect.minY
        case .middle:
            targetY = rect.midY - bounds.height / 2
        case .bottom:
            targetY = rect.maxY - bounds.height
        case .none:
            // Minimal scroll to reveal the row.
            if rect.minY < contentOffset.y {
                targetY = rect.minY
            } else if rect.maxY > contentOffset.y + bounds.height {
                targetY = rect.maxY - bounds.height
            } else {
                return
            }
        }
        targetY = min(max(targetY, minContentOffset.y), maxContentOffset.y)
        setContentOffset(CGPoint(x: contentOffset.x, y: targetY), animated: animated)
    }

    /// A bound cell finished a tap: select it and notify the delegate
    /// (highlight → selected is seamless; UIKit fires didSelect after the
    /// selection state is set).
    func commitRowTap(on cell: UITableViewCell) {
        guard allowsSelection, let path = indexPath(for: cell) else { return }
        if let old = indexPathForSelectedRow, old != path {
            visibleCellsByPath[old]?.setSelected(false, animated: false)
            tableDelegate?.tableView(self, didDeselectRowAt: old)
        }
        indexPathForSelectedRow = path
        cell.setSelected(true, animated: false)
        updateSeparators()
        tableDelegate?.tableView(self, didSelectRowAt: path)
    }
}
