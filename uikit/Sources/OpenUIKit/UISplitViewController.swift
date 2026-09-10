#if canImport(Foundation)
import Foundation
#endif

/// Programmatic split-view state, containment, column geometry and the
/// collapse/expand delegate contract. Measurements are carried in
/// Tools/oracle2/splitviewprobe (state, iPad A16 + SE), splitwidthprobe
/// (triple-column mode resolution vs width) and splitframesprobe (column
/// frames, safe areas and delegate order, iPad A16 820×1180 @2x regular and
/// iPhone 16 393×852 @3x compact, iOS 26.1). The floating sidebar material,
/// interactive column transitions, the display-mode button and the inspector
/// column remain unimplemented; this type does not claim pixel fidelity.
@preconcurrency @MainActor
open class UISplitViewController: UIViewController {
    // MEASURED splitviewprobe enum row: styles 0...2, modes 0...6, columns
    // 0...4, behaviors 0...3, edges/backgrounds 0...1, visibility 0...2.
    public enum Style: Int, Sendable { case unspecified, doubleColumn, tripleColumn }
    public enum DisplayMode: Int, Sendable {
        case automatic, secondaryOnly, oneBesideSecondary, oneOverSecondary
        case twoBesideSecondary, twoOverSecondary, twoDisplaceSecondary
        public static var primaryHidden: Self { .secondaryOnly }
        public static var allVisible: Self { .oneBesideSecondary }
        public static var primaryOverlay: Self { .oneOverSecondary }
    }
    public enum Column: Int, Sendable { case primary, supplementary, secondary, compact, inspector }
    public enum SplitBehavior: Int, Sendable { case automatic, tile, overlay, displace }
    public enum PrimaryEdge: Int, Sendable { case leading, trailing }
    public enum BackgroundStyle: Int, Sendable { case none, sidebar }
    public enum DisplayModeButtonVisibility: Int, Sendable { case automatic, never, always }

    // MEASURED splitviewprobe config: -3.4028234663852886e+38, the negative
    // greatest finite Float converted to CGFloat (not CGFloat's minimum).
    public static let automaticDimension = CGFloat(-Float.greatestFiniteMagnitude)

    // MEASURED splitframesprobe iPad A16 / iOS 26.1 (window safe area
    // [32, 0, 25, 0]): a `.sidebar` primary floats at x 10, y safe-top, height
    // 1180 − 32 − 15 = 1133 and reports safe-area bottom 10 (= 25 − 15). The
    // column beside it is full-frame with safe-area left = primary width + 10.
    // Tiled non-overlay neighbours are separated by 0.5 pt (secondary x
    // 320.5, width 499.5 at 820). The secondary keeps a 464 pt minimum: a
    // 0.5 fraction resolved 346 = 820 − 10 − 464 (double) and 355.5 =
    // 820 − 0.5 − 464 (triple supplementary).
    static let sidebarInset: CGFloat = 10
    static let sidebarBottomMargin: CGFloat = 15
    static let columnSeparator: CGFloat = 0.5
    static let defaultMinimumSecondaryWidth: CGFloat = 464

    public let style: Style
    public weak var delegate: UISplitViewControllerDelegate?

    public override init(nibName: String? = nil, bundle: Bundle? = nil) {
        style = .unspecified
        super.init(nibName: nibName, bundle: bundle)
    }
    public init(style: Style) {
        self.style = style
        super.init(nibName: nil, bundle: nil)
    }

    // MEASURED all three defaults rows: unloaded, not collapsed, secondaryOnly;
    // config rows: gesture=true, leading edge, sidebar background, no shortcut.
    public private(set) var isCollapsed = false
    public private(set) var displayMode: DisplayMode = .secondaryOnly
    public var presentsWithGesture = true
    public var showsSecondaryOnlyButton = false
    public var primaryEdge: PrimaryEdge = .leading
    public var primaryBackgroundStyle: BackgroundStyle = .sidebar {
        didSet { if _installed { _layoutColumns() } }
    }
    public var displayModeButtonVisibility: DisplayModeButtonVisibility = .automatic
    public var preferredSplitBehavior: SplitBehavior = .automatic
    public var splitBehavior: SplitBehavior {
        // MEASURED first iPad probe: the legacy getter raises
        // NSInvalidArgumentException, "requires ... -initWithStyle:".
        precondition(style != .unspecified, "splitBehavior requires init(style:)")
        if isCollapsed { return .tile }
        return _actualSplitBehavior
    }
    private var _actualSplitBehavior: SplitBehavior = .tile
    private var _implicitPreferredWrite = false
    public var preferredDisplayMode: DisplayMode = .automatic {
        didSet {
            // MEASURED transition.double/triple showSecondary while collapsed
            // with an automatic preference: iOS records oneBeside/twoBeside
            // as the preference without touching preferredSplitBehavior.
            if _implicitPreferredWrite { return }
            // MEASURED mode sweep: assigning a tiled/overlaid/displaced mode
            // also writes preferredSplitBehavior = 1/2/3, including on SE.
            if style != .unspecified {
                switch preferredDisplayMode {
                case .secondaryOnly, .oneBesideSecondary, .twoBesideSecondary: preferredSplitBehavior = .tile
                case .oneOverSecondary, .twoOverSecondary: preferredSplitBehavior = .overlay
                case .twoDisplaceSecondary: preferredSplitBehavior = .displace
                default: break
                }
            }
            guard _installed else { return }
            _applyExpandedModeChange(explicitRequest: true, columnCallbacks: !_columnCallbacksSuppressed)
        }
    }

    // MEASURED config rows: every supported dimension starts at automatic.
    // The mutatedWidths rows retain fraction .4, absolute 280, min 200/max 420
    // without loading the view or changing the current measured column width.
    public var preferredPrimaryColumnWidthFraction = automaticDimension { didSet { _relayout() } }
    public var preferredPrimaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var minimumPrimaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var maximumPrimaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var preferredSupplementaryColumnWidthFraction = automaticDimension { didSet { _relayout() } }
    public var preferredSupplementaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var minimumSupplementaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var maximumSupplementaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var preferredSecondaryColumnWidthFraction = automaticDimension { didSet { _relayout() } }
    public var preferredSecondaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var minimumSecondaryColumnWidth = automaticDimension { didSet { _relayout() } }
    public var preferredInspectorColumnWidthFraction = automaticDimension
    public var preferredInspectorColumnWidth = automaticDimension
    public var minimumInspectorColumnWidth = automaticDimension
    public var maximumInspectorColumnWidth = automaticDimension
    private func _relayout() { if _installed { _layoutColumns() } }

    private var _minimumSecondary: CGFloat {
        minimumSecondaryColumnWidth == Self.automaticDimension
            ? Self.defaultMinimumSecondaryWidth : minimumSecondaryColumnWidth
    }
    public var primaryColumnWidth: CGFloat {
        // MEASURED defaults: 320 pt legacy/double, 280 pt triple. Mounted
        // iPad absolute280=280, fraction0.4=328 (=820×.4).
        let fallback: CGFloat = style == .tripleColumn ? 280 : 320
        guard _installed else { return fallback }
        if isCollapsed { return view.bounds.width }
        // MEASURED splitframesprobe double fraction0.5 → 346, fraction0.5 +
        // max300 → 300, preferred320 + min375 + max400 → 375: the beside-
        // secondary cap (width − 10 − 464) applies before minimum/maximum.
        let cap = style == .tripleColumn ? nil
            : view.bounds.width - Self.sidebarInset - _minimumSecondary
        return _width(preferredPrimaryColumnWidth, preferredPrimaryColumnWidthFraction,
                      minimumPrimaryColumnWidth, maximumPrimaryColumnWidth, fallback, cap: cap)
    }
    public var supplementaryColumnWidth: CGFloat {
        // MEASURED probe: double-column getter raises NSInvalidArgumentException;
        // triple-column default is 320 pt.
        precondition(style == .tripleColumn, "supplementaryColumnWidth requires tripleColumn")
        guard _installed else { return 320 }
        if isCollapsed { return view.bounds.width }
        let base = _supplementaryContentWidth
        // MEASURED triple mode5 (explicit twoOverSecondary): the getter and
        // frame widen to 320 + 280 + 10 = 610 while the secondary stays full.
        return _twoOverExplicit ? base + primaryColumnWidth + Self.sidebarInset : base
    }
    private var _supplementaryContentWidth: CGFloat {
        // MEASURED suppFraction0.5 → 355.5 = 820 − 0.5 − 464.
        _width(preferredSupplementaryColumnWidth, preferredSupplementaryColumnWidthFraction,
               minimumSupplementaryColumnWidth, maximumSupplementaryColumnWidth, 320,
               cap: view.bounds.width - Self.columnSeparator - _minimumSecondary)
    }
    private func _width(_ absolute: CGFloat, _ fraction: CGFloat, _ minimum: CGFloat,
                        _ maximum: CGFloat, _ fallback: CGFloat, cap: CGFloat?) -> CGFloat {
        // MEASURED minimum400/maximum300 rows: .4×820=328 clamps to
        // 400 with min400/max500, and to 300 with automatic minimum/max300.
        var width = absolute != Self.automaticDimension ? absolute
            : fraction != Self.automaticDimension ? view.bounds.width * fraction : fallback
        // MEASURED iPhone 16 expanded at 393 pt: the getters keep their 320
        // defaults, so a cap that has gone non-positive does not apply.
        if let cap, cap > 0 { width = min(width, cap) }
        if minimum != Self.automaticDimension { width = max(width, minimum) }
        if maximum != Self.automaticDimension { width = min(width, maximum) }
        return width
    }
    private var _twoOverExplicit: Bool {
        style == .tripleColumn && displayMode == .twoOverSecondary && preferredDisplayMode == .twoOverSecondary
    }

    private var _columns: [Column: UIViewController] = [:]
    private var _containers: [Column: UIViewController] = [:]
    private var _installed = false
    private var _appeared = false
    private var _resolvedWidth: CGFloat?
    /// The column on top while collapsed; the stack below it sits on the
    /// primary navigation controller in `_collapsedStack` order.
    private var _collapsedTop: Column = .primary
    private var _collapsedStack: [Column] = []
    private var _columnCallbacksSuppressed = false
    private var _orderedColumns: [Column] {
        style == .tripleColumn ? [.primary, .supplementary, .secondary] : [.primary, .secondary]
    }

    public var viewControllers: [UIViewController] {
        get {
            // MEASURED SE defaultWindow: public array contains only primary,
            // while viewController(for: secondary) still returns its controller.
            // splitframesprobe compactC: the collapsed array is [compact].
            if isCollapsed {
                if _collapsedTop == .compact, let compact = _columns[.compact] { return [compact] }
                if style == .unspecified { return _containers[.primary].map { [$0] } ?? [] }
                return _columns[.primary].map { [$0] } ?? []
            }
            if style == .unspecified { return _orderedColumns.compactMap { _containers[$0] ?? _columns[$0] } }
            return _orderedColumns.compactMap { _columns[$0] }
        }
        set {
            let order = _orderedColumns
            precondition(newValue.count <= order.count, "Too many split-view controllers")
            var next: [Column: UIViewController] = [:]
            for (index, controller) in newValue.enumerated() { next[order[index]] = controller }
            for column in order { _replace(next[column], for: column) }
        }
    }
    public func setViewController(_ vc: UIViewController?, for column: Column) {
        precondition(style != .unspecified, "Column APIs require init(style:)")
        precondition(column != .supplementary || style == .tripleColumn,
                     "The supplementary column requires tripleColumn")
        _replace(vc, for: column)
    }
    public func viewController(for column: Column) -> UIViewController? {
        precondition(style != .unspecified, "Column APIs require init(style:)")
        return _columns[column]
    }
    private func _replace(_ vc: UIViewController?, for column: Column) {
        if _columns[column] === vc { return }
        if let vc {
            // MEASURED arrayAB -> [B] raises: B is already specified for the
            // secondary column. Clear its old slot before moving a controller.
            precondition(!_columns.contains { $0.key != column && $0.value === vc },
                         "A controller cannot occupy two split-view columns")
        }
        let wasOnStack = _collapsedStack.contains(column) || (_collapsedTop == column && isCollapsed)
        if let old = _containers.removeValue(forKey: column) {
            _detach(old)
            if isCollapsed, column != .primary, let nav = _containers[.primary] as? UINavigationController {
                _popContainer(old, from: nav)
            }
        }
        _columns[column] = vc
        guard _installed else { return }
        if isCollapsed {
            // MEASURED splitframesprobe setSecondary(F) while nav[A, nav[D]]:
            // the replacement is pushed in place with no delegate callbacks.
            if wasOnStack, column != .primary, column != .compact, vc != nil,
               let nav = _containers[.primary] as? UINavigationController {
                nav.pushViewController(_container(for: column)!, animated: false)
            } else if wasOnStack {
                _collapsedStack.removeAll { $0 == column }
                if _collapsedTop == column { _collapsedTop = _collapsedStack.last ?? .primary }
            }
            if column == .compact || column == .primary { _rebuildCollapsedContainment() }
            _layoutColumns()
        } else {
            _installExpandedContainers()
            _layoutColumns()
        }
    }

    /// The controller the split parents for a column: column styles wrap a
    /// plain controller in a navigation controller (MEASURED legacy keeps
    /// direct children), created lazily and retained across transitions.
    private func _container(for column: Column) -> UIViewController? {
        guard let controller = _columns[column] else { return nil }
        if let existing = _containers[column] { return existing }
        let container: UIViewController
        if style != .unspecified, column != .compact, !(controller is UINavigationController) {
            container = UINavigationController(rootViewController: controller)
        } else { container = controller }
        _containers[column] = container
        return container
    }
    private func _detach(_ container: UIViewController) {
        if container.parent === self {
            container.willMove(toParent: nil)
            if _appeared, container.viewIfLoaded?.superview != nil {
                container.beginAppearanceTransition(false, animated: false)
                container.viewIfLoaded?.removeFromSuperview()
                container.endAppearanceTransition()
            } else {
                container.viewIfLoaded?.removeFromSuperview()
            }
            container.removeFromParent()
        }
    }
    private func _popContainer(_ container: UIViewController, from nav: UINavigationController) {
        guard nav.viewControllers.contains(where: { $0 === container }) else { return }
        let remaining = nav.viewControllers.filter { $0 !== container }
        _setStack(nav, remaining)
    }
    /// Pops (non-animated) until the stack is a prefix of `desired`, then
    /// pushes the missing tail. The port's navigation controller has no
    /// setViewControllers; every stack the split builds is prefix-ordered.
    private func _setStack(_ nav: UINavigationController, _ desired: [UIViewController]) {
        while nav.viewControllers.count > 1 {
            let current = nav.viewControllers
            if current.count <= desired.count, zip(current, desired).allSatisfy({ $0 === $1 }) { break }
            _ = nav.popViewController(animated: false)
        }
        for vc in desired.dropFirst(nav.viewControllers.count) { nav.pushViewController(vc, animated: false) }
    }

    public override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let firstAppearance = !_installed
        _installed = true
        if firstAppearance {
            // MEASURED iPhone 16 mounted rows: every will* callback of the
            // initial collapse still observes isCollapsed == false.
            let compact = traitCollection.horizontalSizeClass == .compact
            _updateDisplayMode(initialAppearance: true, collapsed: compact)
            if compact { _collapseInitially() } else { _installExpandedInitially() }
        }
        _forEachShownContainer { $0.beginAppearanceTransition(true, animated: animated) }
    }
    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        _appeared = true
        _forEachShownContainer { $0.endAppearanceTransition() }
    }
    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        _forEachShownContainer { $0.beginAppearanceTransition(false, animated: animated) }
    }
    public override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        _appeared = false
        _forEachShownContainer { $0.endAppearanceTransition() }
    }
    private func _forEachShownContainer(_ body: (UIViewController) -> Void) {
        for child in children where child.viewIfLoaded?.superview === view { body(child) }
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard _installed else { return }
        if !isCollapsed, OpenUIKitRuntime.systemFontCut == .iOS, style == .tripleColumn,
           _resolvedWidth != view.bounds.width {
            _applyExpandedModeChange(explicitRequest: false, columnCallbacks: true)
        } else {
            _layoutColumns()
        }
    }

    /// MEASURED splitframesprobe: a host trait override that flips the
    /// horizontal size class collapses or expands a mounted split.
    open override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        guard _installed else { return }
        let compact = traitCollection.horizontalSizeClass == .compact
        guard compact != isCollapsed else { return }
        if compact { _collapse() } else { _expand() }
    }

    // MARK: - Display-mode resolution

    private func _resolveDisplayMode(initialAppearance: Bool, explicitRequest: Bool,
                                     collapsed: Bool? = nil) -> DisplayMode {
        let widthChanged = _resolvedWidth != view.bounds.width
        _resolvedWidth = view.bounds.width
        // MEASURED SE mode sweep: every requested mode still reports mode 2.
        if collapsed ?? isCollapsed { return .oneBesideSecondary }
        if OpenUIKitRuntime.systemFontCut == .iOS, style == .tripleColumn {
            // splitwidthprobe, iPad A16 / iOS 26.1 @2x, main and resize:
            // before appearance requests 3/5 resolve to 1, while a mounted
            // request shows 3/5. Narrow requests 4/6 resolve to 5; narrowing
            // an existing tiled layout resolves to 2. Wide 0/4/6 resolve to 4.
            // An ordinary same-width layout must not replay a mode request.
            if _tooNarrowForTwoColumns { return .secondaryOnly }
            if !initialAppearance && !explicitRequest && !widthChanged { return displayMode }
            switch preferredDisplayMode {
            case .automatic:
                return _canTileThreeColumns ? .twoBesideSecondary : .oneBesideSecondary
            case .twoBesideSecondary, .twoDisplaceSecondary:
                return _canTileThreeColumns ? .twoBesideSecondary
                    : explicitRequest ? .twoOverSecondary : .oneBesideSecondary
            case .oneOverSecondary, .twoOverSecondary:
                return initialAppearance ? .secondaryOnly
                    : explicitRequest ? preferredDisplayMode : displayMode
            default:
                return preferredDisplayMode
            }
        }
        if OpenUIKitRuntime.systemFontCut == .iOS, _tooNarrowForTwoColumns { return .secondaryOnly }
        switch preferredDisplayMode {
        case .automatic: return .oneBesideSecondary
        // Retain the previous non-iOS behavior. The iOS triple-column
        // resolver above replaces the original 820 pt probe special case.
        case .twoBesideSecondary, .twoDisplaceSecondary:
            return view.bounds.width == 820 ? .twoOverSecondary : preferredDisplayMode
        default: return preferredDisplayMode
        }
    }
    /// MEASURED splitframesprobe iPhone 16: expanding a 393 pt window
    /// (regular override) resolves secondaryOnly for double, triple and
    /// legacy splits; splitwidthprobe resolves oneBeside at 600. The exact
    /// boundary between 393 and 600 is not measured; the secondary minimum
    /// (464) is the bracketed guess.
    private var _tooNarrowForTwoColumns: Bool { view.bounds.width < _minimumSecondary }
    private func _updateDisplayMode(initialAppearance: Bool = false, explicitRequest: Bool = false,
                                    collapsed: Bool? = nil) {
        let next = _resolveDisplayMode(initialAppearance: initialAppearance, explicitRequest: explicitRequest,
                                       collapsed: collapsed)
        _actualSplitBehavior = next == .oneOverSecondary || next == .twoOverSecondary ? .overlay : .tile
        if next != displayMode {
            delegate?.splitViewController(self, willChangeTo: next)
            displayMode = next
        }
    }
    private var _canTileThreeColumns: Bool {
        // splitwidthprobe boundary, primary, supplementary, secondary profiles:
        // iPad A16 / iOS 26.1 @2x first tiled frames are primary [10,32,240,658],
        // supplementary [0,0,490,700] with safe-left 250, secondary
        // [490.5,0,464,700]. Thus minimum width = 240+240+10+0.5+464.
        // 954.249 fails, 954.25 fits after nearest-pixel rounding. Raising
        // either side minimum to 300 moves the boundary +60; secondary 500
        // moves it +36. These are frame/minimum measurements, not score fits.
        let primary = minimumPrimaryColumnWidth == Self.automaticDimension
            ? 240 : minimumPrimaryColumnWidth
        let supplementary = minimumSupplementaryColumnWidth == Self.automaticDimension
            ? 240 : minimumSupplementaryColumnWidth
        let secondary = _minimumSecondary
        let scale = traitCollection.displayScale > 0
            ? traitCollection.displayScale : UIScreen.main.scale
        let available = (view.bounds.width * scale).rounded() / scale
        let required = primary + supplementary + 10 + 1 / scale + secondary
        return available >= required
    }

    /// Which columns a resolved expanded mode shows.
    private func _shownColumns(for mode: DisplayMode) -> Set<Column> {
        var shown: Set<Column> = [.secondary]
        switch mode {
        case .oneBesideSecondary, .oneOverSecondary:
            shown.insert(style == .tripleColumn ? .supplementary : .primary)
        case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
            shown.insert(.primary); shown.insert(.supplementary)
        default: break
        }
        return shown.filter { _columns[$0] != nil || (style == .unspecified && _containers[$0] != nil) }
    }
    public func isShowing(_ column: Column) -> Bool {
        guard _installed, _columns[column] != nil || (style == .unspecified && _containers[column] != nil) else { return false }
        if isCollapsed { return column == _collapsedTop }
        return _shownColumns(for: displayMode).contains(column)
    }

    /// Expanded mode change (preferred-mode assignment, resize, show/hide):
    /// MEASURED splitframesprobe double/triple mode rows: willChangeTo,
    /// then willHide/willShow per changed column, child appearance, then
    /// didHide/didShow. hide(_:)/show(_:) fire willChangeTo only.
    private func _applyExpandedModeChange(explicitRequest: Bool, columnCallbacks: Bool) {
        guard !isCollapsed else { _layoutColumns(); return }
        let before = _shownColumns(for: displayMode)
        _updateDisplayMode(explicitRequest: explicitRequest)
        let after = _shownColumns(for: displayMode)
        let hidden = before.subtracting(after).sorted(by: Self._callbackOrder)
        let shown = after.subtracting(before).sorted(by: Self._callbackOrder)
        if columnCallbacks {
            for column in hidden { delegate?.splitViewController(self, willHide: column) }
            for column in shown { delegate?.splitViewController(self, willShow: column) }
        }
        _layoutColumns()
        if columnCallbacks {
            for column in hidden { delegate?.splitViewController(self, didHide: column) }
            for column in shown { delegate?.splitViewController(self, didShow: column) }
        }
    }

    // MARK: - Expanded containment

    private func _installExpandedContainers() {
        for column in _orderedColumns {
            guard let container = _container(for: column), container.parent !== self else { continue }
            addChild(container)
            container.didMove(toParent: self)
        }
    }
    private func _installExpandedInitially() {
        // MEASURED splitframesprobe mounted rows (iPad): willChangeTo, then
        // willShow for each shown column, appearance, didShow each.
        let shown = _shownColumns(for: displayMode).sorted(by: Self._callbackOrder)
        for column in shown { delegate?.splitViewController(self, willShow: column) }
        _installExpandedContainers()
        _layoutColumns()
        for column in shown { delegate?.splitViewController(self, didShow: column) }
    }
    /// MEASURED will* order across mount and mode rows: supplementary,
    /// primary, secondary (reset.primFraction0.3: willShow(1), willShow(0)).
    private static func _callbackOrder(_ a: Column, _ b: Column) -> Bool {
        func rank(_ c: Column) -> Int { c == .supplementary ? 0 : c == .primary ? 1 : 2 + c.rawValue }
        return rank(a) < rank(b)
    }

    // MARK: - Collapse / expand

    private var _proposedTopColumn: Column {
        if _columns[.compact] != nil { return .compact }
        if _columns[.secondary] != nil || (style == .unspecified && _containers[.secondary] != nil) { return .secondary }
        if _columns[.supplementary] != nil { return .supplementary }
        return .primary
    }
    /// Column-style stack below `top`, in push order after the primary.
    private func _stack(below top: Column) -> [Column] {
        switch top {
        case .secondary: return style == .tripleColumn && _columns[.supplementary] != nil ? [.supplementary, .secondary] : [.secondary]
        case .supplementary: return [.supplementary]
        default: return []
        }
    }
    private func _rebuildCollapsedContainment() {
        for column in [Column.primary, .supplementary, .secondary, .compact] {
            if let container = _containers[column], container.parent === self { _detach(container) }
        }
        if _collapsedTop == .compact, let compact = _container(for: .compact) {
            // MEASURED iPhone 16 compactC: no column navigation controller
            // exists while the compact column is the only child.
            _collapsedStack = []
            addChild(compact); compact.didMove(toParent: self)
            return
        }
        // MEASURED iPhone 16 topPrimary: every column keeps its navigation
        // wrapper even when the delegate leaves it off the stack.
        for column in _orderedColumns { _ = _container(for: column) }
        guard let primary = _container(for: .primary) else { _collapsedStack = []; return }
        addChild(primary); primary.didMove(toParent: self)
        _collapsedStack = _stack(below: _collapsedTop)
        if let nav = primary as? UINavigationController {
            var stack: [UIViewController] = [nav.viewControllers.first].compactMap { $0 }
            if stack.isEmpty, let root = _columns[.primary] { stack = [root] }
            for column in _collapsedStack { if let c = _container(for: column) { stack.append(c) } }
            _setStack(nav, stack)
        } else {
            _collapsedStack = []
            _collapsedTop = .primary
        }
    }
    private func _collapseInitially() {
        // MEASURED splitframesprobe iPhone 16 mounted rows.
        if style == .unspecified {
            _ = delegate?.primaryViewController(forCollapsing: self)
            let handled = _legacyCollapseHandled()
            delegate?.splitViewController(self, willShow: .primary)
            if !handled { delegate?.splitViewController(self, willHide: .primary); delegate?.splitViewController(self, willShow: .secondary) }
            _collapsedTop = handled ? .primary : .secondary
            isCollapsed = true
            _rebuildCollapsedContainment()
            _layoutColumns()
            if handled { delegate?.splitViewController(self, didShow: .primary); delegate?.splitViewControllerDidCollapse(self) }
            else { delegate?.splitViewControllerDidCollapse(self); delegate?.splitViewController(self, didShow: .secondary); delegate?.splitViewController(self, didHide: .primary) }
            return
        }
        let proposed = _proposedTopColumn
        let top = delegate?.splitViewController(self, topColumnForCollapsingToProposedTopColumn: proposed) ?? proposed
        if top == .compact {
            _collapsedTop = .compact
            _rebuildCollapsedContainment()
            delegate?.splitViewController(self, willShow: .compact)
            isCollapsed = true
            _layoutColumns()
            delegate?.splitViewController(self, didShow: .compact)
            delegate?.splitViewControllerDidCollapse(self)
            return
        }
        delegate?.splitViewController(self, willShow: .primary)
        if top != .primary { delegate?.splitViewController(self, willHide: .primary); delegate?.splitViewController(self, willShow: top) }
        _collapsedTop = top
        isCollapsed = true
        _rebuildCollapsedContainment()
        _layoutColumns()
        delegate?.splitViewControllerDidCollapse(self)
        delegate?.splitViewController(self, didShow: top)
        if top != .primary { delegate?.splitViewController(self, didHide: .primary) }
    }
    private func _legacyCollapseHandled() -> Bool {
        guard let secondary = _containers[.secondary] ?? _columns[.secondary],
              let primary = _containers[.primary] ?? _columns[.primary] else { return true }
        return delegate?.splitViewController(self, collapseSecondary: secondary, onto: primary) ?? false
    }
    private func _collapse() {
        // MEASURED splitframesprobe transition.* override.compact rows (iPad).
        let shownBefore = _shownColumns(for: displayMode)
        if style == .unspecified {
            _ = delegate?.primaryViewController(forCollapsing: self)
            let handled = _legacyCollapseHandled()
            delegate?.splitViewController(self, willHide: .secondary)
            if !handled { delegate?.splitViewController(self, willHide: .primary); delegate?.splitViewController(self, willShow: .secondary) }
            isCollapsed = true
            _collapsedTop = handled ? .primary : .secondary
            _rebuildCollapsedContainment()
            _layoutColumns()
            if handled { delegate?.splitViewControllerDidCollapse(self); delegate?.splitViewController(self, didHide: .secondary) }
            else { delegate?.splitViewController(self, didHide: .primary); delegate?.splitViewControllerDidCollapse(self); delegate?.splitViewController(self, didShow: .secondary) }
            return
        }
        // MEASURED iPhone 16 override.compact.2: willChangeTo precedes
        // topColumnForCollapsing when the mode changes on collapse.
        let next: DisplayMode = .oneBesideSecondary
        if displayMode != next { delegate?.splitViewController(self, willChangeTo: next); displayMode = next }
        let proposed = _proposedTopColumn
        let top = delegate?.splitViewController(self, topColumnForCollapsingToProposedTopColumn: proposed) ?? proposed
        var hidden: [Column] = []
        if shownBefore.contains(.supplementary) { delegate?.splitViewController(self, willHide: .supplementary); hidden.append(.supplementary) }
        if top == .compact {
            _collapsedTop = .compact
            _rebuildCollapsedContainment()
            delegate?.splitViewController(self, willShow: .compact)
            delegate?.splitViewController(self, willHide: .secondary); hidden.append(.secondary)
        } else {
            if !shownBefore.contains(.primary) { delegate?.splitViewController(self, willShow: .primary) }
            delegate?.splitViewController(self, willHide: .secondary)
            if top != .secondary { hidden.append(.secondary) }
            if top != .primary {
                delegate?.splitViewController(self, willHide: .primary); hidden.append(.primary)
                delegate?.splitViewController(self, willShow: top)
            }
            _collapsedTop = top
        }
        isCollapsed = true
        if top != .compact { _rebuildCollapsedContainment() }
        _layoutColumns()
        if top == .compact {
            if hidden.contains(.supplementary) { delegate?.splitViewController(self, didHide: .supplementary) }
            delegate?.splitViewControllerDidCollapse(self)
            delegate?.splitViewController(self, didShow: .compact)
            delegate?.splitViewController(self, didHide: .secondary)
        } else {
            delegate?.splitViewController(self, didShow: top)
            delegate?.splitViewControllerDidCollapse(self)
            for column in hidden.sorted(by: { $0.rawValue < $1.rawValue }) where column != top {
                delegate?.splitViewController(self, didHide: column)
            }
        }
    }
    private func _expand() {
        // MEASURED splitframesprobe transition.* override.regular rows.
        // MEASURED: every will* callback of an expansion still observes
        // isCollapsed == true and the collapsed public array.
        let currentTop = _collapsedTop
        let previousMode = displayMode
        isCollapsed = false
        let resolved = _resolveDisplayMode(initialAppearance: false, explicitRequest: false)
        isCollapsed = true
        if resolved != previousMode { delegate?.splitViewController(self, willChangeTo: resolved); displayMode = resolved }
        if style == .unspecified {
            _ = delegate?.primaryViewController(forExpanding: self)
            if let primary = _containers[.primary] {
                if let separated = delegate?.splitViewController(self, separateSecondaryFrom: primary) {
                    _containers[.secondary] = separated
                    _columns[.secondary] = separated
                } else if let nav = primary as? UINavigationController, nav.viewControllers.count > 1,
                          let top = nav.viewControllers.last {
                    _ = nav.popViewController(animated: false)
                    _containers[.secondary] = top
                    _columns[.secondary] = top
                }
            }
            _actualSplitBehavior = .tile
            let shown = _shownColumns(for: displayMode).sorted { $0.rawValue < $1.rawValue }
            for column in shown { delegate?.splitViewController(self, willShow: column) }
            isCollapsed = false
            _collapsedStack = []
            _installExpandedContainers()
            _layoutColumns()
            if shown.contains(.primary) { delegate?.splitViewController(self, didShow: .primary) }
            delegate?.splitViewControllerDidExpand(self)
            if shown.contains(.secondary) { delegate?.splitViewController(self, didShow: .secondary) }
            return
        }
        let mode = delegate?.splitViewController(self, displayModeForExpandingToProposedDisplayMode: displayMode) ?? displayMode
        if mode != displayMode, mode != .automatic { displayMode = mode }
        _actualSplitBehavior = displayMode == .oneOverSecondary || displayMode == .twoOverSecondary ? .overlay : .tile
        let after = _shownColumns(for: displayMode)
        var shown: [Column] = []
        if after.contains(.supplementary), currentTop != .supplementary { shown.append(.supplementary) }
        if style == .doubleColumn, after.contains(.primary), currentTop != .primary { shown.append(.primary) }
        let hidesTop = !after.contains(currentTop)
        for column in shown { delegate?.splitViewController(self, willShow: column) }
        if hidesTop { delegate?.splitViewController(self, willHide: currentTop) }
        if after.contains(.secondary), currentTop != .secondary {
            delegate?.splitViewController(self, willShow: .secondary); shown.append(.secondary)
        }
        // Restructure: pop the collapsed stack and re-parent every column.
        isCollapsed = false
        if let nav = _containers[.primary] as? UINavigationController, !_collapsedStack.isEmpty {
            let stacked = Set(_collapsedStack.compactMap { _containers[$0] }.map(ObjectIdentifier.init))
            _setStack(nav, nav.viewControllers.filter { !stacked.contains(ObjectIdentifier($0)) })
        }
        _collapsedStack = []
        if let compact = _containers[.compact], compact.parent === self { _detach(compact) }
        _installExpandedContainers()
        _layoutColumns()
        if hidesTop { delegate?.splitViewController(self, didHide: currentTop) }
        delegate?.splitViewControllerDidExpand(self)
        for column in shown.sorted(by: { $0.rawValue < $1.rawValue }) { delegate?.splitViewController(self, didShow: column) }
    }

    // MARK: - Layout

    private func _layoutColumns() {
        guard _installed else { return }
        let bounds = view.bounds
        let safe = view.safeAreaInsets
        if isCollapsed {
            let root = _collapsedTop == .compact ? _containers[.compact] : _containers[.primary]
            for child in children where child !== root { child.viewIfLoaded?.removeFromSuperview() }
            if let root, root.parent === self {
                _place(root, frame: bounds, safeArea: safe)
            }
            return
        }
        let shown = _shownColumns(for: displayMode)
        let sidebar = primaryBackgroundStyle == .sidebar
        let W = bounds.width, H = bounds.height
        let pw = primaryColumnWidth
        let inset = sidebar ? Self.sidebarInset : Self.columnSeparator
        // MEASURED bgNone rows: primary [0,0,320,1180] beside secondary
        // [320.5,0,499.5,1180]; twoBeside none keeps the 0.5 separator.
        let bottomMargin = max(Self.sidebarInset, safe.bottom - Self.sidebarInset)
        let primaryFrame = sidebar
            ? CGRect(x: Self.sidebarInset, y: safe.top, width: pw, height: H - safe.top - bottomMargin)
            : CGRect(x: 0, y: 0, width: pw, height: H)
        let primarySafe = sidebar
            ? UIEdgeInsets(top: 0, left: 0, bottom: max(safe.bottom - bottomMargin, 0), right: 0) : safe
        var placements: [(Column, CGRect, UIEdgeInsets)] = []
        if style == .tripleColumn {
            let primaryBeside = shown.contains(.primary) && (displayMode == .twoBesideSecondary || _twoOverExplicit)
            let sw = _supplementaryContentWidth + (primaryBeside ? pw + inset : 0)
            let supplementaryShown = shown.contains(.supplementary)
            let secondaryFull = !supplementaryShown || displayMode == .oneOverSecondary || _twoOverExplicit
            let secondaryFrame = secondaryFull ? bounds
                : CGRect(x: sw + Self.columnSeparator, y: 0, width: W - sw - Self.columnSeparator, height: H)
            placements.append((.secondary, secondaryFrame, safe))
            if supplementaryShown {
                var suppSafe = safe
                if primaryBeside { suppSafe.left = pw + inset }
                placements.append((.supplementary, CGRect(x: 0, y: 0, width: sw, height: H), suppSafe))
            }
            if shown.contains(.primary) { placements.append((.primary, primaryFrame, primarySafe)) }
        } else {
            let beside = shown.contains(.primary) && displayMode == .oneBesideSecondary
            var secondaryFrame = bounds, secondarySafe = safe
            if beside {
                if sidebar { secondarySafe.left = pw + Self.sidebarInset }
                else { secondaryFrame = CGRect(x: pw + Self.columnSeparator, y: 0, width: W - pw - Self.columnSeparator, height: H) }
            }
            placements.append((.secondary, secondaryFrame, secondarySafe))
            if shown.contains(.primary) { placements.append((.primary, primaryFrame, primarySafe)) }
        }
        let placed = Set(placements.map { $0.0 })
        for column in _orderedColumns where !placed.contains(column) {
            if let container = _containers[column], container.parent === self, container.viewIfLoaded?.superview != nil {
                if _appeared {
                    container.beginAppearanceTransition(false, animated: false)
                    container.view.removeFromSuperview()
                    container.endAppearanceTransition()
                } else { container.view.removeFromSuperview() }
            }
        }
        for (column, frame, safeArea) in placements {
            guard let container = _containers[column], container.parent === self else { continue }
            _place(container, frame: frame, safeArea: safeArea)
        }
    }
    private func _place(_ container: UIViewController, frame: CGRect, safeArea: UIEdgeInsets) {
        let appearing = container.view.superview !== view
        if appearing, _appeared { container.beginAppearanceTransition(true, animated: false) }
        if appearing { view.addSubview(container.view) } else { view.bringSubviewToFront(container.view) }
        container.view.frame = frame
        container.view._setSafeAreaInsets(safeArea)
        if appearing, _appeared { container.endAppearanceTransition() }
    }

    // MARK: - Column show / hide

    public func show(_ column: Column) {
        precondition(style != .unspecified && column != .compact,
                     "show(_:) requires a noncompact column-style column")
        guard _installed else { return }
        // MEASURED transition.* showSecondary (collapsed and expanded) with an
        // automatic preference: iOS records twoBeside (triple) / oneBeside
        // (double) as the preference, without a mode change, callbacks, or a
        // preferredSplitBehavior write.
        if preferredDisplayMode == .automatic {
            _implicitPreferredWrite = true
            preferredDisplayMode = style == .tripleColumn ? .twoBesideSecondary : .oneBesideSecondary
            _implicitPreferredWrite = false
        }
        if isCollapsed { _collapsedShow(column); return }
        // MEASURED splitframesprobe expanded show/hide rows: only
        // willChangeTo fires, no willShow/didShow column callbacks.
        let target: DisplayMode?
        switch column {
        case .primary: target = style == .tripleColumn ? .twoBesideSecondary
            : preferredSplitBehavior == .overlay ? .oneOverSecondary : .oneBesideSecondary
        case .supplementary: target = style == .tripleColumn && !isShowing(.supplementary) ? .oneBesideSecondary : nil
        default: target = nil
        }
        guard let target else { _layoutColumns(); return }
        _columnCallbacksSuppressed = true
        preferredDisplayMode = target
        _columnCallbacksSuppressed = false
    }
    public func hide(_ column: Column) {
        precondition(style != .unspecified && column != .compact,
                     "hide(_:) requires a noncompact column-style column")
        guard _installed else { return }
        if isCollapsed { _collapsedHide(column); return }
        let target: DisplayMode?
        switch column {
        case .primary: target = isShowing(.primary) ? (style == .tripleColumn ? .oneBesideSecondary : .secondaryOnly) : nil
        case .supplementary: target = style == .tripleColumn && isShowing(.supplementary) ? .secondaryOnly : nil
        default: target = nil
        }
        guard let target else { _layoutColumns(); return }
        _columnCallbacksSuppressed = true
        preferredDisplayMode = target
        _columnCallbacksSuppressed = false
    }
    private var _collapsedNav: UINavigationController? {
        _collapsedTop == .compact ? nil : _containers[.primary] as? UINavigationController
    }
    private func _collapsedShow(_ column: Column) {
        // MEASURED splitframesprobe iPhone 16: show(.primary) pops to the
        // root with willHide/didHide(top); show(.secondary) pushes the
        // intermediate columns (triple: willShow(1), willHide(0), willHide(1),
        // willShow(2)); double pushes with willHide(0) only.
        guard let nav = _collapsedNav, _columns[column] != nil, column != _collapsedTop else { return }
        let currentTop = _collapsedTop
        let currentIndex = _orderedColumns.firstIndex(of: currentTop) ?? 0
        let targetIndex = _orderedColumns.firstIndex(of: column) ?? 0
        if targetIndex < currentIndex {
            let popped = _collapsedStack.filter { (_orderedColumns.firstIndex(of: $0) ?? 0) > targetIndex }
            for c in popped.reversed() { delegate?.splitViewController(self, willHide: c) }
            _collapsedTop = column
            _collapsedStack = _stack(below: column)
            var stack = nav.viewControllers
            stack.removeAll { vc in popped.contains { _containers[$0] === vc } }
            _setStack(nav, stack)
            _layoutColumns()
            for c in popped.reversed() { delegate?.splitViewController(self, didHide: c) }
            return
        }
        let pushed = _orderedColumns[(currentIndex + 1)...targetIndex].filter { _columns[$0] != nil }
        var hidden: [Column] = []
        var top = currentTop
        for (index, c) in pushed.enumerated() {
            // MEASURED nnw.showSecondary from nav[A]: willShow(1), willHide(0),
            // willHide(1), willShow(2) — the first push announces the column
            // before hiding the top, later pushes after.
            let announces = c != .secondary || style == .tripleColumn
            if announces, index == 0 { delegate?.splitViewController(self, willShow: c) }
            delegate?.splitViewController(self, willHide: top); hidden.append(top)
            if announces, index > 0 { delegate?.splitViewController(self, willShow: c) }
            top = c
        }
        for c in pushed { if let container = _container(for: c) { nav.pushViewController(container, animated: false) } }
        _collapsedTop = column
        _collapsedStack = _stack(below: column)
        _layoutColumns()
        for c in hidden.dropFirst().sorted(by: { $0.rawValue < $1.rawValue }) { delegate?.splitViewController(self, didHide: c) }
        if column != .secondary || style == .tripleColumn { delegate?.splitViewController(self, didShow: column) }
        if let first = hidden.first { delegate?.splitViewController(self, didHide: first) }
    }
    private func _collapsedHide(_ column: Column) {
        // MEASURED SE hidePrimary: ignored even while secondary is on top.
        // splitframesprobe hideSecondary from nav[A, nav[B]]: pop with
        // willShow(0) / didShow(0).
        guard column != .primary, let nav = _collapsedNav, column == _collapsedTop else { return }
        let below = _orderedColumns[..<(_orderedColumns.firstIndex(of: column) ?? 0)].last { _columns[$0] != nil } ?? .primary
        delegate?.splitViewController(self, willShow: below)
        if let container = _containers[column] { _popContainer(container, from: nav) }
        _collapsedTop = below
        _collapsedStack = _stack(below: below)
        _layoutColumns()
        delegate?.splitViewController(self, didShow: below)
    }

    public override func show(_ vc: UIViewController, sender: Any?) {
        // MEASURED handled rows: legacy consults delegate; column styles bypass
        // these legacy hooks. Their show() loads the split view, but retains A.
        if style == .unspecified {
            if delegate?.splitViewController(self, show: vc, sender: sender) == true { return }
            super.show(vc, sender: sender)
        } else { loadViewIfNeeded() }
    }
    public override func showDetailViewController(_ vc: UIViewController, sender: Any?) {
        if style == .unspecified,
           delegate?.splitViewController(self, showDetail: vc, sender: sender) == true { return }
        if style != .unspecified { loadViewIfNeeded() }
        guard _installed, isCollapsed else { _replace(vc, for: .secondary); return }
        if style == .unspecified {
            // MEASURED splitframesprobe legacy showDetail while collapsed:
            // the raw controller is pushed onto the primary navigation stack
            // with willHide/didHide of the column on top.
            guard let nav = _containers[.primary] as? UINavigationController else { _replace(vc, for: .secondary); return }
            let top = _collapsedTop
            nav.pushViewController(vc, animated: false)
            _collapsedTop = .secondary
            _collapsedStack = [.secondary]
            delegate?.splitViewController(self, willHide: top)
            delegate?.splitViewController(self, didHide: top)
            return
        }
        // MEASURED column showDetail while collapsed: the secondary container
        // is replaced in place; when another column was on top it is pushed
        // with willHide(top), willShow(2) … didShow(2), didHide(top).
        let top = _collapsedTop
        if top == .secondary { _replace(vc, for: .secondary); return }
        _replace(vc, for: .secondary)
        guard let nav = _collapsedNav, let container = _container(for: .secondary) else { return }
        delegate?.splitViewController(self, willHide: top)
        delegate?.splitViewController(self, willShow: .secondary)
        for column in _stack(below: .secondary) where column != .secondary && !_collapsedStack.contains(column) {
            if let c = _container(for: column) { nav.pushViewController(c, animated: false) }
        }
        nav.pushViewController(container, animated: false)
        _collapsedTop = .secondary
        _collapsedStack = _stack(below: .secondary)
        _layoutColumns()
        delegate?.splitViewController(self, didShow: .secondary)
        delegate?.splitViewController(self, didHide: top)
    }
}

public extension UIViewController {
    /// MEASURED splitviewprobe ancestry: nil before containment; the split
    /// controller itself returns nil, and navigation-wrapped children find it.
    var splitViewController: UISplitViewController? {
        var ancestor = parent
        while let controller = ancestor {
            if let split = controller as? UISplitViewController { return split }
            ancestor = controller.parent
        }
        return nil
    }
}

@preconcurrency @MainActor
public protocol UISplitViewControllerDelegate: AnyObject {
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode)
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode
    func splitViewController(_ svc: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool
    func splitViewController(_ svc: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool
    func primaryViewController(forCollapsing svc: UISplitViewController) -> UIViewController?
    func primaryViewController(forExpanding svc: UISplitViewController) -> UIViewController?
    func splitViewController(_ svc: UISplitViewController, collapseSecondary secondary: UIViewController, onto primary: UIViewController) -> Bool
    func splitViewController(_ svc: UISplitViewController, separateSecondaryFrom primary: UIViewController) -> UIViewController?
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column
    func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode
    func splitViewControllerDidCollapse(_ svc: UISplitViewController)
    func splitViewControllerDidExpand(_ svc: UISplitViewController)
    func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column)
    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column)
    func splitViewController(_ svc: UISplitViewController, didShow column: UISplitViewController.Column)
    func splitViewController(_ svc: UISplitViewController, didHide column: UISplitViewController.Column)
}

public extension UISplitViewControllerDelegate {
    func splitViewController(_ svc: UISplitViewController, willChangeTo displayMode: UISplitViewController.DisplayMode) {}
    func targetDisplayModeForAction(in svc: UISplitViewController) -> UISplitViewController.DisplayMode { .automatic }
    func splitViewController(_ svc: UISplitViewController, show vc: UIViewController, sender: Any?) -> Bool { false }
    func splitViewController(_ svc: UISplitViewController, showDetail vc: UIViewController, sender: Any?) -> Bool { false }
    func primaryViewController(forCollapsing svc: UISplitViewController) -> UIViewController? { nil }
    func primaryViewController(forExpanding svc: UISplitViewController) -> UIViewController? { nil }
    func splitViewController(_ svc: UISplitViewController, collapseSecondary secondary: UIViewController, onto primary: UIViewController) -> Bool { false }
    func splitViewController(_ svc: UISplitViewController, separateSecondaryFrom primary: UIViewController) -> UIViewController? { nil }
    func splitViewController(_ svc: UISplitViewController, topColumnForCollapsingToProposedTopColumn proposedTopColumn: UISplitViewController.Column) -> UISplitViewController.Column { proposedTopColumn }
    func splitViewController(_ svc: UISplitViewController, displayModeForExpandingToProposedDisplayMode proposedDisplayMode: UISplitViewController.DisplayMode) -> UISplitViewController.DisplayMode { proposedDisplayMode }
    func splitViewControllerDidCollapse(_ svc: UISplitViewController) {}
    func splitViewControllerDidExpand(_ svc: UISplitViewController) {}
    func splitViewController(_ svc: UISplitViewController, willShow column: UISplitViewController.Column) {}
    func splitViewController(_ svc: UISplitViewController, willHide column: UISplitViewController.Column) {}
    func splitViewController(_ svc: UISplitViewController, didShow column: UISplitViewController.Column) {}
    func splitViewController(_ svc: UISplitViewController, didHide column: UISplitViewController.Column) {}
}
