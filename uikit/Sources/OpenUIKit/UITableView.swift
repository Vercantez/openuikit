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

// `IndexPath` used to be declared here. It is Foundation's now (M15) — see
// Sources/OpenUIKit/FoundationTypes.swift, which also adds UIKit's
// `init(row:section:)` / `.row` / `.section` / `.item`.

// MARK: - Data source / delegate protocols

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own. One knock-on, measured: in a file where the name is
// visible twice, `[CGFloat](repeating:count:)` array sugar stops parsing as a
// type; spell it `Array<CGFloat>(...)`.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif

@preconcurrency @MainActor
public protocol UITableViewDataSource: AnyObject {
    func numberOfSections(in tableView: UITableView) -> Int
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String?
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String?
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool
    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath)
}

public extension UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int { 1 }
    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? { nil }
    func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? { nil }
    func tableView(_ tableView: UITableView, canEditRowAt indexPath: IndexPath) -> Bool { true }
    func tableView(_ tableView: UITableView,
                   editingStyleForRowAt indexPath: IndexPath) -> UITableViewCell.EditingStyle {
        .delete
    }
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCell.EditingStyle,
                   forRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, canMoveRowAt indexPath: IndexPath) -> Bool { false }
    func tableView(_ tableView: UITableView, moveRowAt sourceIndexPath: IndexPath,
                   to destinationIndexPath: IndexPath) {}
}

@preconcurrency @MainActor
public protocol UITableViewDelegate: UIScrollViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell,
                   forRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView?
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView?
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath)
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath)
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
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? { nil }
    func tableView(_ tableView: UITableView, didHighlightRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, didUnhighlightRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {}
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {}
}

// MARK: - Card view (inset-grouped section background)

/// The rounded card behind an inset-grouped section's rows. Private class
/// name: compare.py skips the subtree (real UIKit's internals differ).
@preconcurrency @MainActor
final class UITableViewCardView: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        backgroundColor = .secondarySystemGroupedBackground
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
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

@preconcurrency @MainActor
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

    // iOS 26.1 chrome, MEASURED 2026-09-04 on the iPhone 16 simulator
    // (scripts/ios_suite.sh tableview_grouped / tableview_plain, post-layout
    // dumps + pixels; a 375 pt table). Everything sits on 20 pt margins:
    //   plain:        header 28 pt (17 semibold at x 20, y 4, 21 pt box),
    //                 rows 53, text at x 20, separators inset 20 / 20,
    //                 chevron 10.333 x 14 with its right edge 20 in.
    //   insetGrouped: card inset 20 per side (radius 26 as on Catalyst),
    //                 the first section's header 55.333 (label y 28.667),
    //                 later headers 45.333 (label y 18.667), footer
    //                 7.667 + text + 6.667; rows 53 with the FIRST row of a
    //                 section 2 pt taller (its content 2 pt lower); text at
    //                 16 inside the card; detail right edge 16 in; chevron
    //                 right edge 20 in; separators inset 16 / 16.
    static var isIOSChrome: Bool { OpenUIKitRuntime.systemFontCut == .iOS }
    static func headerHeight(style: Style, firstSection: Bool,
                             compact: Bool = false) -> CGFloat {
        guard isIOSChrome else { return headerHeight }
        switch style {
        case .plain: return 28
        // Full headers (tableview_grouped, no large title, text footers):
        // 35 (first) / 25 (later) above the 17 pt semibold label, whose
        // height is the line height rounded up to the DEVICE pixel:
        // 55.333 / 45.333 on the iPhone 16 (3x), 55.5 / 45.5 on the SE (2x).
        // Compact 38 pt (label y = 12): MEASURED 2026-09-04, headerprobe on
        // iPhone SE 2x / iOS 26.1 — first section under a large-title bar
        // (safeArea.top 116, NavFlow t200) and any later section after an
        // untitled 17.5 pt footer (noNav and navLarge alike). 12 + label
        // + 5.5 bottom = 38 on 2x; the same 5.5 bottom the full headers
        // already carry (29.5+20.5+5.5 / 19.5+20.5+5.5).
        case .grouped, .insetGrouped:
            if compact { return 12 + iOSLabelHeight17 + 5.5 }
            return (firstSection ? 35 : 25) + iOSLabelHeight17
        }
    }
    /// Untitled grouped/insetGrouped footer. MEASURED 2026-09-04, headerprobe
    /// + NavFlow t200, iPhone SE 2x / iOS 26.1: `rectForFooter` is 17.5 pt
    /// with no `UITableViewHeaderFooterView` when `titleForFooterInSection`
    /// is nil. Catalyst and `.plain` keep 0.
    static let untitledGroupedFooterHeight: CGFloat = 17.5
    /// The 17 pt label height under the iOS cut on the current screen
    /// (20.333 at 3x, 20.5 at 2x — FontEngine.labelLineHeight).
    static var iOSLabelHeight17: CGFloat {
        FontEngine.labelLineHeight(for: .systemFont(ofSize: 17))
    }
    /// One device pixel in points under the iOS cut.
    static var iOSPixel: CGFloat { 1 / max(1, UIScreen.main.scale) }
    static func iOSCeilToPixel(_ v: CGFloat) -> CGFloat { (v / iOSPixel).rounded(.up) * iOSPixel }
    static func iOSFloorToPixel(_ v: CGFloat) -> CGFloat { (v / iOSPixel).rounded(.down) * iOSPixel }
    /// iOS's system layout margin for a window of `width` points: 20 on the
    /// 390+ pt phones (iPhone 16: real app, window scenes), 16 on the 375 pt
    /// iPhone SE (MEASURED 2026-09-04 on both oracle devices — inset-grouped
    /// cards, plain text insets, separator insets and accessory margins all
    /// move by the same 4 pt).
    static func iOSSystemMargin(width: CGFloat) -> CGFloat { width >= 390 ? 20 : 16 }
    /// This table's margin (window width; its own width without a window).
    var iOSMargin: CGFloat { UITableView.iOSSystemMargin(width: window?.bounds.width ?? bounds.width) }
    /// Plain cells' text inset (Catalyst 16; iOS: the system margin) and
    /// plain header label x (Catalyst 8; iOS: the system margin).
    var plainTextInset: CGFloat { UITableView.isIOSChrome ? iOSMargin : UITableViewCell.labelX }
    var plainHeaderTextX: CGFloat { UITableView.isIOSChrome ? iOSMargin : UITableView.plainHeaderLabelX }
    var plainSeparatorInsets: (left: CGFloat, right: CGFloat) {
        UITableView.isIOSChrome ? (iOSMargin, iOSMargin)
            : (UITableView.separatorLeftInset, UITableView.plainSeparatorRightInset)
    }
    /// Extra height iOS 26 gives a value1/value2 cell that has NO accessory
    /// (its content shifts down by it). MEASURED: "Name / Miguel" is 55 tall
    /// while "Plan / Pro >" and "Theme / Dark >" are 53 (tableview_grouped,
    /// tableview_dark); default and subtitle cells are unaffected.
    /// Only on the 3x device: the same cells measure 53 on the iPhone SE
    /// (2x, tableview_grouped 2026-09-04), so the padding is a rounding
    /// artefact of the thirds grid, not a metric.
    static var valueCellPadding: CGFloat { isIOSChrome && UIScreen.main.scale >= 3 ? 2 : 0 }

    /// Side margin of the inset-grouped card. MEASURED 8 pt in the
    /// offscreen Catalyst oracle (golden/tableview_grouped) but 16 pt when
    /// the same table renders in a real UIWindow (golden/tableview_dark,
    /// oracle2) — real-device metrics use the 16 pt reading. Header/footer
    /// text indents by this + 16.
    ///
    /// iOS 26.1 (MEASURED 2026-09-04 on both oracle devices): the margin is
    /// the window's system layout margin — 20 pt on the iPhone 16 (393 pt
    /// wide: real app, window scenes) and 16 pt on the iPhone SE (375 pt:
    /// tableview_grouped cards at x = 16, header text at 32). Modelled on
    /// the host window's width (the table's own when it has no window):
    /// 20 from 390 pt, 16 below. Assigning the property pins a value.
    public var insetGroupedSideInset: CGFloat {
        get {
            if let pinned = _insetGroupedSideInsetOverride { return pinned }
            return UITableView.isIOSChrome ? iOSMargin : 8
        }
        set {
            let old = insetGroupedSideInset
            _insetGroupedSideInsetOverride = newValue
            if newValue != old { setNeedsMetrics() }
        }
    }
    var _insetGroupedSideInsetOverride: CGFloat?

    open override func didMoveToWindow() {
        super.didMoveToWindow()
        // The iOS margin above depends on the window's width.
        if UITableView.isIOSChrome, _insetGroupedSideInsetOverride == nil { setNeedsMetrics() }
    }
    var groupedHeaderLabelX: CGFloat { insetGroupedSideInset + 16 }

    // MARK: Public configuration

    /// UIKit declares this read-only, and it is fixed at init for every
    /// programmatic table. A nib-loaded table is constructed by
    /// `UINibClassRegistry`'s zero-argument factory and then told its archived
    /// style (`UITableViewStyle` in the archive), which is the one path that
    /// needs to write it — see `_setArchivedStyle`.
    public private(set) var style: Style
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
    /// Colour of the hairline under each row. `nil` restores the system
    /// `.separator`, which is what the cell paints itself with when the table
    /// has no opinion (UITableViewCell.setUp).
    public var separatorColor: UIColor? = .separator {
        didSet { applySeparatorColor() }
    }
    public var allowsSelection = true
    public var allowsMultipleSelection = false
    public var allowsSelectionDuringEditing = false
    public var allowsMultipleSelectionDuringEditing = false
    public var cellLayoutMarginsFollowReadableWidth = true

    /// Estimates affect UIKit's pre-layout bookkeeping, not final geometry.
    /// OpenUIKit already computes exact visible metrics eagerly, but retains
    /// these values because applications commonly configure them.
    public var estimatedRowHeight: CGFloat = UITableView.automaticDimension
    public var estimatedSectionHeaderHeight: CGFloat = UITableView.automaticDimension
    public var estimatedSectionFooterHeight: CGFloat = UITableView.automaticDimension
    /// Height for a section header the delegate supplies no height for.
    /// `automaticDimension` means "size the header view by its own
    /// constraints", which every pocket-casts settings screen relies on.
    public var sectionHeaderHeight: CGFloat = UITableView.automaticDimension {
        didSet { if sectionHeaderHeight != oldValue { setNeedsMetrics() } }
    }
    public var sectionFooterHeight: CGFloat = UITableView.automaticDimension {
        didSet { if sectionFooterHeight != oldValue { setNeedsMetrics() } }
    }

    public var backgroundView: UIView? {
        didSet {
            guard backgroundView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let view = backgroundView {
                view.isUserInteractionEnabled = false
                insertSubview(view, at: 0)
            }
            setNeedsLayout()
        }
    }

    public var tableHeaderView: UIView? {
        didSet {
            guard tableHeaderView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let view = tableHeaderView { addSubview(view) }
            setNeedsMetrics()
        }
    }

    public var tableFooterView: UIView? {
        didSet {
            guard tableFooterView !== oldValue else { return }
            oldValue?.removeFromSuperview()
            if let view = tableFooterView { addSubview(view) }
            setNeedsMetrics()
        }
    }

    public private(set) var isEditing = false

    public private(set) var indexPathForSelectedRow: IndexPath?
    private var additionalSelectedRows: Set<IndexPath> = []
    public var indexPathsForSelectedRows: [IndexPath]? {
        var paths = additionalSelectedRows
        if let indexPathForSelectedRow { paths.insert(indexPathForSelectedRow) }
        return paths.isEmpty ? nil : paths.sorted()
    }

    // MARK: Init

    public init(frame: CGRect, style: Style) {
        self.style = style
        super.init(frame: frame)
        configureStyle(style)
    }

    public override convenience init(frame: CGRect) {
        self.init(frame: frame, style: .plain)
    }

    public convenience init() {
        self.init(frame: .zero, style: .plain)
    }

    public required init?(coder: NSCoder) {
        style = .plain
        super.init(coder: coder)
        configureStyle(.plain)
    }

    /// Adopt the style a nib archived (UINib.swift). Real UIKit decodes the
    /// style inside `initWithCoder:`, before any of the table's own state
    /// exists; the portable loader constructs first and configures after, so
    /// this re-runs the style's own setup.
    func _setArchivedStyle(_ style: Style) {
        guard style != self.style else { return }
        self.style = style
        configureStyle(style)
        setNeedsMetrics()
    }

    private func configureStyle(_ style: Style) {
        switch style {
        case .plain:
            backgroundColor = .systemBackground
        case .grouped, .insetGrouped:
            backgroundColor = .systemGroupedBackground
        }
        alwaysBounceVertical = true
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
        /// Compact 38 pt header (label y 12). See `headerHeight(compact:)`.
        var compactHeader = false
        /// False for the untitled 17.5 pt grouped gap (spacing, no view).
        var footerHasView = false

        var rowsEnd: CGFloat { rowEnds.last ?? rowsStart }
        func rowY(_ i: Int) -> CGFloat { i == 0 ? rowsStart : rowEnds[i - 1] }
    }

    var metrics: [SectionMetrics] = []
    private var metricsDirty = true
    private var metricsWidth: CGFloat = -1

    func setNeedsMetrics() {
        valueCellPaddingCache.removeAll()
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
        // `automaticDimension`: the row is as tall as its cell's content
        // demands, but a row whose cell does not exist yet cannot be measured
        // — so metrics use the ESTIMATE and `refineSelfSizedRows` replaces it
        // once tiling has built the cell. UIKit's own two-step, and the reason
        // `estimatedRowHeight` exists at all: building every row's cell here
        // instead defeats reuse, MEASURED as 10013 cells instantiated for the
        // 13-row viewport of Tests/…/TableViewTests' 10k-row table.
        if let measured = selfSizedRowHeights[path] { return measured }
        if estimatedRowHeight >= 0 { return estimatedRowHeight }
        return UITableViewCell.defaultRowHeight
    }

    /// Measure the cells tiling has actually built and record any height that
    /// differs from the estimate metrics used. Returns true when something
    /// moved, i.e. when the metrics have to be redone.
    ///
    /// MEASURED (realapp_storage_light, iPhone 16 / iOS 26.1): both nib cells
    /// come out 65 pt from their xib's own label constraints; the port had
    /// them at `defaultRowHeight` (53), which put every view below them 24 pt
    /// too high.
    private func refineSelfSizedRows() -> Bool {
        guard rowHeight < 0 else { return false }
        var changed = false
        for (path, cell) in visibleCellsByPath.views {
            if let d = tableDelegate, d.tableView(self, heightForRowAt: path) >= 0 {
                continue
            }
            var height: CGFloat?
            if UITableView.isIOSChrome, style == .plain,
               cell.style == .subtitle {
                // MEASURED 2026-09-04, TableEditor t200, iPhone SE 2x,
                // iOS 26.1: a plain subtitle cell is 62 pt (Alpha abs
                // [0, 116, 375, 62], Bravo [0, 178, 375, 62]). Checked
                // before the constraint fitter so a navigation bar's
                // Auto Layout (which raises `installedConstraintCount`)
                // cannot size a stock cell by its labels' intrinsic
                // height. Grouped subtitle stays `subtitleRowHeight`;
                // Catalyst automaticDimension stays `defaultRowHeight`.
                height = UITableViewCell.plainSubtitleRowHeight
            } else if LayoutEngine.installedConstraintCount > 0,
               let fitted = constraintFittingHeight(of: cell.contentView) {
                // Plus the separator. MEASURED (realapp_storage_light): the
                // xib gives SwitchCell's label a height of exactly 64, the
                // golden row is 65, and the golden's own
                // `_UITableViewCellSeparatorView` sits at y = 64 with height
                // 1 — the content owns 0..64 and the separator the point
                // after it. A row drawing no separator has no such point to
                // give away.
                let separator = separatorStyle == .none
                    ? 0 : UITableViewCell.separatorThickness
                height = fitted + separator
            }
            guard let height else { continue }
            if selfSizedRowHeights[path] != height {
                selfSizedRowHeights[path] = height
                changed = true
            }
        }
        return changed
    }

    /// Heights `refineSelfSizedRows` has measured, by path. Survives a metrics
    /// rebuild — that is the whole point, the rebuild is what consumes them —
    /// and is dropped when the data source is reloaded.
    var selfSizedRowHeights: [IndexPath: CGFloat] = [:]
    /// Refinement passes spent on the current `retile`, so a cell whose
    /// measured height never settles cannot spin.
    private var selfSizingPass = 0

    /// The delegate's own header view for `s`, created once and cached.
    ///
    /// Metrics need it before tiling does, because a self-sizing header's
    /// height IS a property of the view, and the delegate builds a fresh one
    /// per call (pocket-casts' storage screen returns
    /// `SettingsTableHeader(frame:title:)`), so it has to be the same object
    /// both passes see. Returns nil when the delegate supplies no view, which
    /// leaves the title-driven chrome path untouched.
    private func delegateHeaderView(for s: Int) -> UIView? {
        if let cached = headerViews[s] { return cached }
        guard let view = tableDelegate?.tableView(self, viewForHeaderInSection: s)
        else { return nil }
        headerViews[s] = view
        addSubview(view)
        return view
    }

    private func delegateFooterView(for s: Int) -> UIView? {
        if let cached = footerViews[s] { return cached }
        guard let view = tableDelegate?.tableView(self, viewForFooterInSection: s)
        else { return nil }
        footerViews[s] = view
        addSubview(view)
        return view
    }

    /// Height a view asks for at the table's width, or nil when its subtree
    /// installs no constraints and it therefore has no opinion. Used for a
    /// self-sizing row and for a delegate-supplied section header/footer.
    private func constraintFittingHeight(of view: UIView) -> CGFloat? {
        let width = bounds.width > 0 ? bounds.width : metricsWidth
        guard width > 0 else { return nil }
        guard let fitted = view.constraintFittingSize(
            CGSize(width: width, height: 0),
            withHorizontalFittingPriority: .required,
            verticalFittingPriority: .fittingSizeLevel),
            fitted.height > 0 else { return nil }
        return fitted.height
    }

    private func rebuildMetrics() {
        metrics.removeAll()
        metricsDirty = false
        metricsWidth = bounds.width
        let headerHeight = max(0, tableHeaderView?.frame.height ?? 0)
        let footerHeight = max(0, tableFooterView?.frame.height ?? 0)
        guard let ds = dataSource else {
            contentSize = CGSize(width: bounds.width,
                                 height: headerHeight + footerHeight)
            return
        }
        let sections = ds.numberOfSections(in: self)
        metrics.reserveCapacity(sections)
        var y: CGFloat = headerHeight
        for s in 0..<sections {
            var m = SectionMetrics()
            m.headerTitle = ds.tableView(self, titleForHeaderInSection: s)
            m.footerTitle = ds.tableView(self, titleForFooterInSection: s)

            var headerH = tableDelegate?.tableView(self, heightForHeaderInSection: s)
                ?? UITableView.automaticDimension
            if headerH < 0 {
                if let view = delegateHeaderView(for: s),
                   let selfSized = sectionHeaderHeight >= 0
                       ? sectionHeaderHeight : constraintFittingHeight(of: view) {
                    // A delegate-supplied VIEW with no delegate height: UIKit
                    // falls back to `sectionHeaderHeight`, and
                    // `automaticDimension` there means "size the view by its
                    // own constraints". MEASURED (realapp_storage_light,
                    // iPhone 16 / iOS 26.1): the screen sets
                    // sectionHeaderHeight = automaticDimension and implements
                    // no heightForHeaderInSection, and both of its
                    // SettingsTableHeaders come out 38 pt — the
                    // `heightAnchor >= 38` the header itself installs.
                    headerH = selfSized
                } else {
                    // Compact when the first section underlaps a large-title
                    // bar, or a later section follows an untitled grouped
                    // footer. MEASURED headerprobe 2026-09-04, SE 2x:
                    // noNav first 55.5 / later 38; navLarge first 38 / later
                    // 38; navLargeWithFooters later 45.5 (previous footer
                    // has text, so not compact).
                    let underlapsLargeTitle = UITableView.isIOSChrome
                        && safeAreaInsets.top >= UINavigationBar.largeTitleExpandedInset
                    let afterUntitledFooter = s > 0 && !metrics[s - 1].footerHasView
                        && metrics[s - 1].footerHeight > 0
                    let compact = UITableView.isIOSChrome && style != .plain
                        && ((s == 0 && underlapsLargeTitle) || afterUntitledFooter)
                    m.compactHeader = compact
                    headerH = m.headerTitle != nil
                        ? UITableView.headerHeight(style: style, firstSection: s == 0,
                                                   compact: compact) : 0
                }
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
                y += valueCellPadding(IndexPath(row: r, section: s))
                m.rowEnds.append(y)
            }

            var footerH = tableDelegate?.tableView(self, heightForFooterInSection: s)
                ?? UITableView.automaticDimension
            if footerH < 0, let view = delegateFooterView(for: s),
               let selfSized = sectionFooterHeight >= 0
                   ? sectionFooterHeight : constraintFittingHeight(of: view) {
                // Same rule as the header. MEASURED (same golden): the usage
                // section's footer is 70.667 pt — its label's three wrapped
                // lines (46.667) inside the 12 pt insets the screen installs.
                footerH = selfSized
                m.footerHasView = true
            } else if footerH < 0 {
                if let t = m.footerTitle, style != .plain {
                    footerSizer.text = t
                    let maxW = bounds.width - 2 * groupedHeaderLabelX
                    let textH = footerSizer.sizeThatFits(
                        CGSize(width: max(1, maxW),
                               height: CGFloat.greatestFiniteMagnitude)).height
                    footerH = UITableViewHeaderFooterView.footerLabelY + textH
                        + UITableViewHeaderFooterView.footerBottomPadding
                    m.footerHasView = true
                } else if m.footerTitle != nil {
                    // Plain footers: header-like chrome (unmeasured — no
                    // plain-footer golden; see docs/KNOWN_GAPS.md).
                    footerH = UITableView.headerHeight(style: style, firstSection: false)
                    m.footerHasView = true
                } else if UITableView.isIOSChrome, style != .plain {
                    // Untitled grouped footer is 17.5 pt of spacing and
                    // installs no view. MEASURED headerprobe / NavFlow t200,
                    // SE 2x: rectForFooter 17.5, headerView(forSection) nil.
                    footerH = UITableView.untitledGroupedFooterHeight
                    m.footerHasView = false
                } else {
                    footerH = 0
                }
            } else {
                m.footerHasView = footerH > 0
            }
            m.footerHeight = footerH
            y += footerH
            m.end = y
            metrics.append(m)
        }
        contentSize = CGSize(width: bounds.width, height: y + footerHeight)
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

    /// iOS 26's extra 2 pt for an accessory-less value1/value2 cell (needs
    /// the cell, so the data source is asked; nil when it cannot be built).
    private var valueCellPaddingCache: [IndexPath: CGFloat] = [:]
    func valueCellPadding(_ path: IndexPath) -> CGFloat {
        guard UITableView.valueCellPadding > 0, style != .plain else { return 0 }
        if let c = valueCellPaddingCache[path] { return c }
        var pad: CGFloat = 0
        if let cell = visibleCellsByPath[path] ?? dataSource?.tableView(self, cellForRowAt: path),
           cell.style == .value1 || cell.style == .value2,
           cell.accessoryView == nil, cell.accessoryType == .none {
            pad = UITableView.valueCellPadding
        }
        valueCellPaddingCache[path] = pad
        return pad
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

    /// Editing style the data source reports for this bound cell.
    func _editingStyle(for cell: UITableViewCell) -> UITableViewCell.EditingStyle {
        guard let path = indexPath(for: cell), let ds = dataSource else { return .delete }
        if !ds.tableView(self, canEditRowAt: path) { return .none }
        return ds.tableView(self, editingStyleForRowAt: path)
    }

    func _canMove(_ cell: UITableViewCell) -> Bool {
        guard let path = indexPath(for: cell), let ds = dataSource else { return false }
        return ds.tableView(self, canMoveRowAt: path)
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
        discardVisibleData(clearSelection: true)
        setNeedsMetrics()
        if updateNesting > 0 {
            // A reload inside a structural batch retains reloadData's
            // immediate selection clearing, but the final presentation is a
            // coherent rebuild rather than the single-move identity path.
            structuralUpdatePending = true
            pendingStructuralUpdateIncludesNonMove = true
        }
    }

    private func discardVisibleData(clearSelection: Bool) {
        // Measured row heights are keyed by path and the paths are about to
        // mean something else.
        selfSizedRowHeights.removeAll()
        visibleCellsByPath.removeAll { _, cell in
            cell.removeFromSuperview()
            recycle(cell)
        }
        headerViews.removeAll { _, view in
            view.removeFromSuperview()
            recycleHeaderFooter(view)
        }
        footerViews.removeAll { _, view in
            view.removeFromSuperview()
            recycleHeaderFooter(view)
        }
        cardViews.removeAll { $1.removeFromSuperview() }
        if clearSelection {
            indexPathForSelectedRow = nil
            additionalSelectedRows.removeAll()
        }
    }

    // MARK: Editing and structural updates

    public enum RowAnimation: Sendable {
        case fade, right, left, top, bottom, none, middle, automatic
    }

    public func setEditing(_ editing: Bool, animated: Bool) {
        guard isEditing != editing else { return }
        isEditing = editing
        for cell in visibleCells { cell.setEditing(editing, animated: animated) }
        if editing && !allowsSelectionDuringEditing {
            selectRow(at: nil, animated: animated)
        }
        if !editing, UITableView.isIOSChrome {
            // MEASURED TableEditor t4800, iPhone SE 2x, iOS 26.1: after
            // "done" the row selected in edit mode (Delta, t3800 fill
            // (209, 209, 214) = systemGray4) is white again (~252). iOS
            // drops the editing-time selection when leaving edit mode.
            selectRow(at: nil, animated: animated)
        }
    }

    private var updateNesting = 0
    private var structuralUpdatePending = false
    private var pendingRowMoves: [(source: IndexPath, destination: IndexPath)] = []
    private var pendingStructuralUpdateIncludesNonMove = false

    public func beginUpdates() { updateNesting += 1 }

    public func endUpdates() {
        guard updateNesting > 0 else { return }
        updateNesting -= 1
        if updateNesting == 0, structuralUpdatePending {
            commitPendingStructuralUpdate()
        }
    }

    private func noteStructuralUpdate() {
        structuralUpdatePending = true
        pendingStructuralUpdateIncludesNonMove = true
        if updateNesting == 0 { commitPendingStructuralUpdate() }
    }

    private func commitPendingStructuralUpdate() {
        if !pendingStructuralUpdateIncludesNonMove, pendingRowMoves.count == 1,
           let move = pendingRowMoves.first {
            structuralUpdatePending = false
            pendingRowMoves.removeAll()
            applyRowMove(from: move.source, to: move.destination)
            return
        }
        applyStructuralUpdate()
    }

    private func applyStructuralUpdate() {
        structuralUpdatePending = false
        pendingRowMoves.removeAll()
        pendingStructuralUpdateIncludesNonMove = false
        // The data source is authoritative after an insert/delete call.  Drop
        // only the visible presentation, preserve programmatic selection, and
        // tile the new model immediately.  This is coherent UIKit behavior;
        // RowAnimation is currently a visual hint rather than a different
        // data-update algorithm.
        discardVisibleData(clearSelection: false)
        setNeedsMetrics()
        retile()
    }

    public func insertRows(at indexPaths: [IndexPath], with animation: RowAnimation) {
        noteStructuralUpdate()
    }

    public func deleteRows(at indexPaths: [IndexPath], with animation: RowAnimation) {
        if let selected = indexPathForSelectedRow, indexPaths.contains(selected) {
            indexPathForSelectedRow = nil
        }
        noteStructuralUpdate()
    }

    /// Re-key one data-source move without discarding visible cells. UIKit's
    /// contract requires the data source to describe the destination ordering
    /// when this method is called. The affected index paths therefore form a
    /// deterministic permutation: the moved cell and every shifted neighbour
    /// keep their identity, and selection follows the same permutation.
    @available(iOS 5.0, *)
    open func moveRow(at indexPath: IndexPath, to newIndexPath: IndexPath) {
        if updateNesting > 0 {
            structuralUpdatePending = true
            pendingRowMoves.append((indexPath, newIndexPath))
            return
        }
        applyRowMove(from: indexPath, to: newIndexPath)
    }

    public func reloadRows(at indexPaths: [IndexPath], with animation: RowAnimation) {
        noteStructuralUpdate()
    }

    public func insertSections(_ sections: IndexSet, with animation: RowAnimation) {
        noteStructuralUpdate()
    }

    public func deleteSections(_ sections: IndexSet, with animation: RowAnimation) {
        if let selected = indexPathForSelectedRow,
           sections.contains(selected.section) {
            indexPathForSelectedRow = nil
        }
        noteStructuralUpdate()
    }

    public func reloadSections(_ sections: IndexSet, with animation: RowAnimation) {
        noteStructuralUpdate()
    }

    /// Map a slot in the pre-move table to its slot in the post-move table.
    /// This is a bijection for a valid single move, both within and between
    /// sections.
    private func remappedIndexPath(_ path: IndexPath, movingFrom source: IndexPath,
                                   to destination: IndexPath) -> IndexPath {
        if path == source { return destination }

        if source.section == destination.section {
            guard path.section == source.section else { return path }
            if source.row < destination.row,
               path.row > source.row, path.row <= destination.row {
                return IndexPath(row: path.row - 1, section: path.section)
            }
            if destination.row < source.row,
               path.row >= destination.row, path.row < source.row {
                return IndexPath(row: path.row + 1, section: path.section)
            }
            return path
        }

        if path.section == source.section, path.row > source.row {
            return IndexPath(row: path.row - 1, section: path.section)
        }
        if path.section == destination.section, path.row >= destination.row {
            return IndexPath(row: path.row + 1, section: path.section)
        }
        return path
    }

    /// Apply one already-committed data-source move. Only cells which remain
    /// visible are retained; cells leaving the viewport return to the reuse
    /// pool and newly visible slots are filled by the ordinary tiler.
    private func applyRowMove(from source: IndexPath, to destination: IndexPath) {
        guard source.section >= 0, source.row >= 0,
              destination.section >= 0, destination.row >= 0 else {
            applyStructuralUpdate()
            return
        }

        // The data source already describes the destination ordering here,
        // so only the cached pre-update metrics can validate the source slot.
        // If layout was dirty or never built, rebuild coherently rather than
        // guessing from post-move row counts.
        guard !metricsDirty, metricsWidth == bounds.width,
              source.section < metrics.count,
              source.row < metrics[source.section].rowEnds.count else {
            applyStructuralUpdate()
            return
        }

        let oldViews = visibleCellsByPath.views
        let remap: (IndexPath) -> IndexPath = {
            self.remappedIndexPath($0, movingFrom: source, to: destination)
        }
        let remappedPrimarySelection = indexPathForSelectedRow.map(remap)
        let remappedAdditionalSelections = Set(additionalSelectedRows.map(remap))

        // contentSize can clamp contentOffset and therefore try to re-tile
        // while metrics are rebuilding. Keep the old visible map stable until
        // every destination key and the new viewport are known.
        inTile = true
        setNeedsMetrics()
        metricsIfNeeded()

        guard source.section < metrics.count,
              destination.section < metrics.count,
              destination.row < metrics[destination.section].rowEnds.count else {
            inTile = false
            applyStructuralUpdate()
            return
        }
        let newSourceCount = metrics[source.section].rowEnds.count
        let sourceFitsNewCounts = source.section == destination.section
            ? source.row < newSourceCount
            : source.row <= newSourceCount
        guard sourceFitsNewCounts else {
            inTile = false
            applyStructuralUpdate()
            return
        }

        let needed = Set(neededViews().cells)
        var rekeyed: [IndexPath: UITableViewCell] = [:]
        var kept = Set<ObjectIdentifier>()
        var collision = false
        for (oldPath, cell) in oldViews {
            let newPath = remap(oldPath)
            guard needed.contains(newPath) else { continue }
            if rekeyed[newPath] != nil {
                collision = true
                break
            }
            rekeyed[newPath] = cell
            kept.insert(ObjectIdentifier(cell))
        }

        guard !collision else {
            inTile = false
            applyStructuralUpdate()
            return
        }

        for (_, cell) in oldViews where !kept.contains(ObjectIdentifier(cell)) {
            cell.removeFromSuperview()
            recycle(cell)
        }
        visibleCellsByPath.replaceAll(with: rekeyed)
        indexPathForSelectedRow = remappedPrimarySelection
        additionalSelectedRows = remappedAdditionalSelections
        inTile = false
        retile()
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
    private let headerFooterRegistry = ReuseRegistry<UITableViewHeaderFooterView>()

    /// Recycled cells kept per identifier (shared cap — see UIReuse.swift).
    static var poolCapacityPerIdentifier: Int { reusePoolCapacityPerIdentifier }

    public func register(_ cellClass: UITableViewCell.Type,
                         forCellReuseIdentifier identifier: String) {
        cellRegistry.register(identifier: identifier) { id in
            let constructor = unsafeBitCast(
                cellClass,
                to: _UITableViewCellDynamicConstructor.Type.self)
            return constructor.init(style: .default, reuseIdentifier: id)
        }
    }

    /// `register(_ nib: UINib, forCellReuseIdentifier:)` — the registration
    /// every small pocket-casts settings screen uses (see UINib.swift). Each
    /// dequeue instantiates the archive afresh, as UIKit's does, and the
    /// identifier is stamped onto the cell the nib produced (a nib cell has
    /// no `init(style:reuseIdentifier:)` to carry it).
    public func register(_ nib: UINib, forCellReuseIdentifier identifier: String) {
        cellRegistry.register(identifier: identifier) { id in
            let objects = nib.instantiate(withOwner: nil, options: nil)
            guard let cell = objects.compactMap({ $0 as? UITableViewCell }).first else {
                fatalError("UINib '\(nib.nibName)' registered for cell identifier "
                           + "'\(id)' contains no UITableViewCell")
            }
            cell._setNibReuseIdentifier(id)
            return cell
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

    public func register(_ viewClass: UITableViewHeaderFooterView.Type,
                         forHeaderFooterViewReuseIdentifier identifier: String) {
        headerFooterRegistry.register(identifier: identifier) { id in
            let constructor = unsafeBitCast(
                viewClass,
                to: _UITableViewHeaderFooterDynamicConstructor.Type.self)
            return constructor.init(reuseIdentifier: id)
        }
    }

    public func dequeueReusableHeaderFooterView(
        withIdentifier identifier: String
    ) -> UITableViewHeaderFooterView? {
        headerFooterRegistry.dequeue(identifier)
    }

    private func recycle(_ cell: UITableViewCell) {
        cell.tableView = nil
        cellRegistry.recycle(cell)
    }

    private func recycleHeaderFooter(_ view: UIView) {
        guard let reusable = view as? UITableViewHeaderFooterView else { return }
        headerFooterRegistry.recycle(reusable)
    }

    // MARK: Tiling

    // Slot -> live view bookkeeping (shared component, UIReuse.swift).
    var visibleCellsByPath = VisibleViewMap<IndexPath, UITableViewCell>()
    var headerViews = VisibleViewMap<Int, UIView>()
    var footerViews = VisibleViewMap<Int, UIView>()
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

    open override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        // First-section compact headers depend on underlapping a large-title
        // bar (safeArea.top 116). MEASURED headerprobe navLarge vs noNav.
        if UITableView.isIOSChrome, style != .plain { setNeedsMetrics() }
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
        // The data source may already expose post-update rows while the live
        // cells still use pre-update keys. Wait for the outer structural
        // commit; ordinary open batches with no queued structural work still
        // re-tile on scroll and layout.
        guard !(updateNesting > 0 && structuralUpdatePending) else { return }
        guard !inTile else { return }
        inTile = true
        defer { inTile = false }

        guard bounds.width > 0 else { return }
        metricsIfNeeded()

        backgroundView?.frame = bounds
        if let header = tableHeaderView {
            header.frame = CGRect(x: 0, y: 0, width: bounds.width,
                                  height: max(0, header.frame.height))
        }
        if let footer = tableFooterView {
            footer.frame = CGRect(x: 0,
                                  y: contentSize.height - max(0, footer.frame.height),
                                  width: bounds.width,
                                  height: max(0, footer.frame.height))
        }
        guard dataSource != nil else {
            if let backgroundView { sendSubviewToBack(backgroundView) }
            return
        }

        let (neededCells, neededSections) = neededViews()
        let visTop = contentOffset.y

        // Retire views that scrolled out.
        visibleCellsByPath.retire(keeping: Set(neededCells)) { _, cell in
            cell.removeFromSuperview()
            recycle(cell)
        }
        let sectionSet = Set(neededSections)
        headerViews.retire(keeping: sectionSet) { _, view in
            view.removeFromSuperview()
            recycleHeaderFooter(view)
        }
        let footerSet = Set(neededSections.filter { metrics[$0].footerHasView })
        footerViews.retire(keeping: footerSet) { _, view in
            view.removeFromSuperview()
            recycleHeaderFooter(view)
        }
        cardViews.retire(keeping: sectionSet) { $1.removeFromSuperview() }

        // Section chrome. Only `.insetGrouped` gets a card — a `.grouped`
        // section's rows run edge to edge and paint their own background,
        // which is why the branch below leaves their `backgroundColor` alone.
        //
        // MEASURED (realapp_storage_light, iPhone 16 / iOS 26.1): the golden's
        // rows are white to both edges. The port cleared every grouped cell's
        // background for a card that is never built for this style, so the 91
        // pt of SwitchCell outside its (accessory-shortened) content view
        // showed the table's grey through.
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
                let header = delegateHeaderView(for: s) ?? {
                    let h = UITableViewHeaderFooterView()
                    headerViews[s] = h
                    addSubview(h)
                    return h
                }()
                (header as? UITableViewHeaderFooterView)?.configure(
                    kind: .header, text: m.headerTitle,
                    labelX: style == .plain
                        ? plainHeaderTextX
                        : groupedHeaderLabelX,
                    style: style, firstSection: s == 0,
                    compact: m.compactHeader)
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
            if m.footerHeight > 0, m.footerHasView {
                let footer = delegateFooterView(for: s) ?? {
                    let f = UITableViewHeaderFooterView()
                    footerViews[s] = f
                    addSubview(f)
                    return f
                }()
                (footer as? UITableViewHeaderFooterView)?.configure(
                    kind: .footer, text: m.footerTitle,
                    labelX: style == .plain
                        ? plainHeaderTextX
                        : groupedHeaderLabelX,
                    style: style, firstSection: s == 0)
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
                cell._textInset = style == .plain ? plainTextInset : UITableViewCell.labelX
            } else {
                guard let ds = dataSource else { break }
                cell = ds.tableView(self, cellForRowAt: path)
                cell.tableView = self
                cell._textInset = style == .plain ? plainTextInset : UITableViewCell.labelX
                cell._leadingPadding = valueCellPadding(path)
                cell.frame = rectForRow(at: path)
                if style == .insetGrouped {
                    // The section card draws the background.
                    cell.backgroundColor = nil
                } else if cell.backgroundColor == nil {
                    cell.backgroundColor = .systemBackground
                }
                cell.setSelected(path == indexPathForSelectedRow
                    || additionalSelectedRows.contains(path), animated: false)
                cell.setEditing(isEditing, animated: false)
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
        if let backgroundView { sendSubviewToBack(backgroundView) }
        if style == .plain {
            for s in neededSections {
                if let h = headerViews[s] { bringSubviewToFront(h) }
            }
        }
        if let bar = verticalIndicator { bringSubviewToFront(bar) }
        if let bar = horizontalIndicator { bringSubviewToFront(bar) }

        updateSeparators()

        // Self-sizing rows, step two: the cells exist now, so measure them
        // and redo the pass if metrics guessed wrong. The second pass reuses
        // the very cells the first one built, which is what keeps this off the
        // reuse gate.
        if selfSizingPass < 2, refineSelfSizedRows() {
            selfSizingPass += 1
            metricsDirty = true
            inTile = false
            retile()
            return
        }
        selfSizingPass = 0
    }

    // MARK: Separators

    /// UIKit's `UITableView.SeparatorInsetReference`. `fromCellEdges` reads
    /// ``separatorInset`` as an absolute inset from the cell's own edges;
    /// `fromAutomaticInsets` adds it to the style's automatic inset.
    public enum SeparatorInsetReference: Int, Sendable {
        case fromCellEdges = 0, fromAutomaticInsets = 1
    }

    /// Table-wide separator inset. Untouched, the style's measured default
    /// applies; assigning any value (including `.zero`) makes it explicit,
    /// the same contract ``UITableViewCell/separatorInset`` has.
    public var separatorInset: UIEdgeInsets = .zero {
        didSet {
            _hasExplicitSeparatorInset = true
            setNeedsLayout()
        }
    }
    var _hasExplicitSeparatorInset = false
    public var separatorInsetReference: SeparatorInsetReference = .fromCellEdges {
        didSet { setNeedsLayout() }
    }

    /// Horizontal separator insets for `cell` (style-dependent, measured).
    func separatorDrawInsets(for cell: UITableViewCell) -> (left: CGFloat, right: CGFloat) {
        var defaults: (left: CGFloat, right: CGFloat)
        switch style {
        case .plain:
            defaults = plainSeparatorInsets
        case .grouped, .insetGrouped:
            defaults = (UITableView.separatorLeftInset,
                        UITableView.groupedSeparatorRightInset)
        }
        // A table-wide inset displaces the style default. `fromCellEdges`
        // replaces it outright; `fromAutomaticInsets` adds to it.
        //
        // MEASURED (realapp_storage_light, iPhone 16 / iOS 26.1): the screen's
        // xib archives `UISeparatorInsetReference = 0` with no
        // `UISeparatorInset`, and every separator in the golden runs the full
        // 393 pt — [0, 64, 393, 1] and [0, 0, 393, 1] per cell — where the
        // grouped style's own default would inset it 16 pt on each side.
        if _hasExplicitSeparatorInset {
            switch separatorInsetReference {
            case .fromCellEdges:
                defaults = (separatorInset.left, separatorInset.right)
            case .fromAutomaticInsets:
                defaults = (defaults.left + separatorInset.left,
                            defaults.right + separatorInset.right)
            }
        }
        guard cell._hasExplicitSeparatorInset else { return defaults }
        return (cell.separatorInset.left, cell.separatorInset.right)
    }

    /// Apply the measured separator visibility rules across visible cells:
    /// no separator on an inset-grouped section's last row, none on a
    /// selected/highlighted row, none on the row directly above one.
    func updateSeparators() {
        for (path, cell) in visibleCellsByPath.views {
            var hidden = separatorStyle == .none
            // The card style closes its own bottom edge, so its last row
            // draws no line. `.grouped` has no card: MEASURED
            // (realapp_storage_light, iPhone 16 / iOS 26.1) each of the two
            // single-row sections carries a line at BOTH edges of the block —
            // `_UITableViewCellSeparatorView` at cell-relative y = 0 and
            // y = 64 — so the last row keeps its separator and the first row
            // gains one above it.
            if style == .insetGrouped,
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
            cell.topSeparatorView.isHidden = separatorStyle == .none
                || style != .grouped || path.row != 0
        }
        applySeparatorColor()
    }

    private func applySeparatorColor() {
        let color = separatorColor ?? .separator
        for (_, cell) in visibleCellsByPath.views {
            cell.separatorView.backgroundColor = color
            cell.topSeparatorView.backgroundColor = color
        }
    }

    // MARK: Selection

    public enum ScrollPosition: Sendable { case none, top, middle, bottom }

    /// Programmatic selection (UIKit semantics: no delegate callbacks).
    public func selectRow(at indexPath: IndexPath?, animated: Bool,
                          scrollPosition: ScrollPosition = .none) {
        let permitsMultiple = isEditing
            ? allowsMultipleSelectionDuringEditing
            : allowsMultipleSelection
        guard let indexPath else {
            if let old = indexPathForSelectedRow {
                visibleCellsByPath[old]?.setSelected(false, animated: animated)
            }
            for old in additionalSelectedRows {
                visibleCellsByPath[old]?.setSelected(false, animated: animated)
            }
            indexPathForSelectedRow = nil
            additionalSelectedRows.removeAll()
            updateSeparators()
            return
        }
        if permitsMultiple {
            if let primary = indexPathForSelectedRow, primary != indexPath {
                additionalSelectedRows.insert(indexPath)
            } else {
                indexPathForSelectedRow = indexPath
            }
            visibleCellsByPath[indexPath]?.setSelected(true, animated: animated)
            if scrollPosition != .none {
                scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
            }
            updateSeparators()
            return
        }
        if let old = indexPathForSelectedRow, old != indexPath {
            visibleCellsByPath[old]?.setSelected(false, animated: animated)
        }
        for old in additionalSelectedRows {
            visibleCellsByPath[old]?.setSelected(false, animated: animated)
        }
        additionalSelectedRows.removeAll()
        indexPathForSelectedRow = indexPath
        visibleCellsByPath[indexPath]?.setSelected(true, animated: animated)
        if scrollPosition != .none {
            scrollToRow(at: indexPath, at: scrollPosition, animated: animated)
        }
        updateSeparators()
    }

    public func deselectRow(at indexPath: IndexPath, animated: Bool) {
        if indexPathForSelectedRow == indexPath {
            indexPathForSelectedRow = additionalSelectedRows.sorted().first
            if let promoted = indexPathForSelectedRow {
                additionalSelectedRows.remove(promoted)
            }
        } else if additionalSelectedRows.remove(indexPath) == nil {
            return
        }
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
    func cellHighlightDidChange(_ cell: UITableViewCell, highlighted: Bool) {
        guard let path = indexPath(for: cell) else { return }
        if highlighted {
            tableDelegate?.tableView(self, didHighlightRowAt: path)
        } else {
            tableDelegate?.tableView(self, didUnhighlightRowAt: path)
        }
    }

    func commitRowTap(on cell: UITableViewCell) {
        guard allowsSelection, let path = indexPath(for: cell) else { return }
        if isEditing && !allowsSelectionDuringEditing && !allowsMultipleSelectionDuringEditing {
            return
        }
        let permitsMultiple = isEditing
            ? allowsMultipleSelectionDuringEditing
            : allowsMultipleSelection
        if permitsMultiple {
            if indexPathForSelectedRow == path || additionalSelectedRows.contains(path) {
                deselectRow(at: path, animated: false)
                tableDelegate?.tableView(self, didDeselectRowAt: path)
            } else {
                if indexPathForSelectedRow == nil {
                    indexPathForSelectedRow = path
                } else {
                    additionalSelectedRows.insert(path)
                }
                cell.setSelected(true, animated: false)
                updateSeparators()
                tableDelegate?.tableView(self, didSelectRowAt: path)
            }
            return
        }
        if let old = indexPathForSelectedRow, old != path {
            visibleCellsByPath[old]?.setSelected(false, animated: false)
            tableDelegate?.tableView(self, didDeselectRowAt: old)
        }
        additionalSelectedRows.removeAll()
        indexPathForSelectedRow = path
        cell.setSelected(true, animated: false)
        updateSeparators()
        tableDelegate?.tableView(self, didSelectRowAt: path)
    }
}
