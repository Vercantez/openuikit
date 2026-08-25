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
final class UITableViewCardView: UIView {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .secondarySystemGroupedBackground
    }
}

// MARK: - UITableView

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
        visibleCellsByPath.first { $0.value === cell }?.key
    }

    public var visibleCells: [UITableViewCell] {
        visibleCellsByPath.sorted { $0.key < $1.key }.map(\.value)
    }

    public var indexPathsForVisibleRows: [IndexPath]? {
        visibleCellsByPath.isEmpty ? nil : visibleCellsByPath.keys.sorted()
    }

    private func metricsIfNeeded() {
        if metricsDirty || metricsWidth != bounds.width { rebuildMetrics() }
    }

    // MARK: Reload

    public func reloadData() {
        for (_, cell) in visibleCellsByPath {
            cell.removeFromSuperview()
            recycle(cell)
        }
        visibleCellsByPath.removeAll()
        for v in headerViews.values { v.removeFromSuperview() }
        headerViews.removeAll()
        for v in footerViews.values { v.removeFromSuperview() }
        footerViews.removeAll()
        for v in cardViews.values { v.removeFromSuperview() }
        cardViews.removeAll()
        indexPathForSelectedRow = nil
        setNeedsMetrics()
    }

    // MARK: Cell reuse

    private var cellPool: [String: [UITableViewCell]] = [:]
    private var registeredCellTypes: [String: UITableViewCell.Type] = [:]
    /// Recycled cells kept per identifier. Must hold at least a screenful:
    /// a far setContentOffset jump retires EVERY visible cell and re-tiles
    /// the same count from the pool (a smaller cap would allocate on every
    /// jump; steady scrolling only ever pools one or two).
    static let poolCapacityPerIdentifier = 64

    public func register(_ cellClass: UITableViewCell.Type,
                         forCellReuseIdentifier identifier: String) {
        registeredCellTypes[identifier] = cellClass
    }

    public func dequeueReusableCell(withIdentifier identifier: String) -> UITableViewCell? {
        if var pool = cellPool[identifier], !pool.isEmpty {
            let cell = pool.removeLast()
            cellPool[identifier] = pool
            cell.prepareForReuse()
            return cell
        }
        if let type = registeredCellTypes[identifier] {
            return type.init(style: .default, reuseIdentifier: identifier)
        }
        return nil
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
        guard let id = cell.reuseIdentifier else { return }
        var pool = cellPool[id] ?? []
        guard pool.count < UITableView.poolCapacityPerIdentifier else { return }
        pool.append(cell)
        cellPool[id] = pool
    }

    // MARK: Tiling

    var visibleCellsByPath: [IndexPath: UITableViewCell] = [:]
    var headerViews: [Int: UITableViewHeaderFooterView] = [:]
    var footerViews: [Int: UITableViewHeaderFooterView] = [:]
    var cardViews: [Int: UITableViewCardView] = [:]

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

    func retile() {
        guard !inTile else { return }
        inTile = true
        defer { inTile = false }

        guard dataSource != nil, bounds.width > 0 else { return }
        metricsIfNeeded()

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

        // Retire views that scrolled out.
        let neededCellSet = Set(neededCells)
        for (path, cell) in visibleCellsByPath where !neededCellSet.contains(path) {
            visibleCellsByPath[path] = nil
            cell.removeFromSuperview()
            recycle(cell)
        }
        let sectionSet = Set(neededSections)
        for (s, v) in headerViews where !sectionSet.contains(s) {
            headerViews[s] = nil
            v.removeFromSuperview()
        }
        for (s, v) in footerViews where !sectionSet.contains(s) {
            footerViews[s] = nil
            v.removeFromSuperview()
        }
        for (s, v) in cardViews where !sectionSet.contains(s) {
            cardViews[s] = nil
            v.removeFromSuperview()
        }

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
        for (path, cell) in visibleCellsByPath {
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
