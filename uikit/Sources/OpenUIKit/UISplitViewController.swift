#if canImport(Foundation)
import Foundation
#endif

/// Programmatic split-view state and containment. Measurements are carried in
/// Tools/oracle2/splitviewprobe: iOS 26.1, iPad A16 (820×1180 @2x) and SE.
/// The floating sidebar material, interactive column transitions, and inspector
/// presentation remain unimplemented; this type does not claim pixel fidelity.
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
    public var primaryBackgroundStyle: BackgroundStyle = .sidebar
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
    public var preferredDisplayMode: DisplayMode = .automatic {
        didSet {
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
            _updateDisplayMode()
            _layoutColumns()
        }
    }

    // MEASURED config rows: every supported dimension starts at automatic.
    // The mutatedWidths rows retain fraction .4, absolute 280, min 200/max 420
    // without loading the view or changing the current measured column width.
    public var preferredPrimaryColumnWidthFraction = automaticDimension
    public var preferredPrimaryColumnWidth = automaticDimension
    public var minimumPrimaryColumnWidth = automaticDimension
    public var maximumPrimaryColumnWidth = automaticDimension
    public var preferredSupplementaryColumnWidthFraction = automaticDimension
    public var preferredSupplementaryColumnWidth = automaticDimension
    public var minimumSupplementaryColumnWidth = automaticDimension
    public var maximumSupplementaryColumnWidth = automaticDimension
    public var preferredSecondaryColumnWidthFraction = automaticDimension
    public var preferredSecondaryColumnWidth = automaticDimension
    public var minimumSecondaryColumnWidth = automaticDimension
    public var preferredInspectorColumnWidthFraction = automaticDimension
    public var preferredInspectorColumnWidth = automaticDimension
    public var minimumInspectorColumnWidth = automaticDimension
    public var maximumInspectorColumnWidth = automaticDimension

    public var primaryColumnWidth: CGFloat {
        // MEASURED defaults: 320 pt legacy/double, 280 pt triple. Mounted
        // iPad absolute280=280, fraction0.4=328 (=820×.4).
        let fallback: CGFloat = style == .tripleColumn ? 280 : 320
        guard _installed else { return fallback }
        if isCollapsed { return view.bounds.width }
        return _width(preferredPrimaryColumnWidth, preferredPrimaryColumnWidthFraction,
                      minimumPrimaryColumnWidth, maximumPrimaryColumnWidth, fallback)
    }
    public var supplementaryColumnWidth: CGFloat {
        // MEASURED probe: double-column getter raises NSInvalidArgumentException;
        // triple-column default is 320 pt.
        precondition(style == .tripleColumn, "supplementaryColumnWidth requires tripleColumn")
        guard _installed else { return 320 }
        if isCollapsed { return view.bounds.width }
        return _width(preferredSupplementaryColumnWidth, preferredSupplementaryColumnWidthFraction,
                      minimumSupplementaryColumnWidth, maximumSupplementaryColumnWidth, 320)
    }
    private func _width(_ absolute: CGFloat, _ fraction: CGFloat, _ minimum: CGFloat,
                        _ maximum: CGFloat, _ fallback: CGFloat) -> CGFloat {
        // MEASURED minimum400/maximum300 rows: .4×820=328 clamps to
        // 400 with min400/max500, and to 300 with automatic minimum/max300.
        var width = absolute != Self.automaticDimension ? absolute
            : fraction != Self.automaticDimension ? view.bounds.width * fraction : fallback
        if minimum != Self.automaticDimension { width = max(width, minimum) }
        if maximum != Self.automaticDimension { width = min(width, maximum) }
        return width
    }

    private var _columns: [Column: UIViewController] = [:]
    private var _containers: [Column: UIViewController] = [:]
    private var _installed = false
    private var _collapsedColumn: Column = .primary
    private var _orderedColumns: [Column] {
        style == .tripleColumn ? [.primary, .supplementary, .secondary] : [.primary, .secondary]
    }

    public var viewControllers: [UIViewController] {
        get {
            // MEASURED SE defaultWindow: public array contains only primary,
            // while viewController(for: secondary) still returns its controller.
            if isCollapsed { return _columns[.primary].map { [$0] } ?? [] }
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
        if let old = _containers.removeValue(forKey: column) {
            old.willMove(toParent: nil)
            old.viewIfLoaded?.removeFromSuperview()
            old.removeFromParent()
        }
        _columns[column] = vc
        if _installed { _installColumns() }
    }

    public override func loadView() {
        view = UIView(frame: UIScreen.main.bounds)
    }
    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let firstAppearance = !_installed
        _installed = true
        _updateDisplayMode()
        _installColumns()
        if firstAppearance, isCollapsed { delegate?.splitViewControllerDidCollapse(self) }
    }
    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        if _installed { _layoutColumns() }
    }
    private func _installColumns() {
        // MEASURED pre-window setPrimary/setSecondary: children=[], parent=nil;
        // appearing legacy keeps direct children, column styles create navs.
        let columns: [Column]
        if isCollapsed, style == .unspecified { columns = [.primary] }
        else if isCollapsed, _columns[.compact] != nil { columns = [.compact] }
        else { columns = _orderedColumns }
        for column in columns {
            guard let controller = _columns[column], _containers[column] == nil else { continue }
            let container: UIViewController
            if style != .unspecified, column != .compact,
               !(controller is UINavigationController) {
                container = UINavigationController(rootViewController: controller)
            } else { container = controller }
            _containers[column] = container
            if isCollapsed, column != .primary, column != .compact,
               let primary = _containers[.primary] as? UINavigationController {
                // MEASURED SE: nav[A, nav[S], nav[secondary]], with only the
                // outer primary navigation controller parented by the split.
                primary.pushViewController(container, animated: false)
            } else {
                addChild(container)
                container.didMove(toParent: self)
            }
        }
        if isCollapsed {
            _collapsedColumn = columns.last(where: { _columns[$0] != nil }) ?? .primary
        }
        _layoutColumns()
    }
    private func _updateDisplayMode() {
        let next: DisplayMode
        isCollapsed = traitCollection.horizontalSizeClass == .compact
        // MEASURED SE mode sweep: every requested mode still reports mode 2.
        if isCollapsed { next = .oneBesideSecondary }
        else {
            switch preferredDisplayMode {
            case .automatic: next = .oneBesideSecondary
            // iPad A16 triple requests 4 and 6 resolve to mode 5 at 820 pt.
            // Wider bucket boundaries remain an open oracle question.
            case .twoBesideSecondary, .twoDisplaceSecondary:
                next = view.bounds.width == 820 ? .twoOverSecondary : preferredDisplayMode
            default: next = preferredDisplayMode
            }
        }
        _actualSplitBehavior = next == .oneOverSecondary || next == .twoOverSecondary
            ? .overlay : .tile
        if next != displayMode {
            delegate?.splitViewController(self, willChangeTo: next)
            displayMode = next
        }
    }
    private func _layoutColumns() {
        // Only the measured public containment/state contract is reproduced.
        // Floating iOS 26 sidebar insets and chrome require a separate pixel
        // oracle; views are retained without fabricating those decorations.
        for (column, controller) in _containers where controller.parent === self {
            let visible = isCollapsed
                ? column == (_columns[.compact] == nil ? .primary : .compact)
                : isShowing(column)
            if visible {
                if controller.view.superview !== view { view.addSubview(controller.view) }
                controller.view.frame = view.bounds
            } else { controller.viewIfLoaded?.removeFromSuperview() }
        }
    }
    public func isShowing(_ column: Column) -> Bool {
        guard _installed, _columns[column] != nil else { return false }
        if isCollapsed { return column == (_columns[.compact] == nil ? _collapsedColumn : .compact) }
        if column == .secondary { return true }
        switch displayMode {
        case .oneBesideSecondary, .oneOverSecondary:
            return column == (style == .tripleColumn ? .supplementary : .primary)
        case .twoBesideSecondary, .twoOverSecondary, .twoDisplaceSecondary:
            return column == .primary || column == .supplementary
        default: return false
        }
    }

    public func show(_ column: Column) {
        precondition(style != .unspecified && column != .compact,
                     "show(_:) requires a noncompact column-style column")
        guard _installed else { return }
        if isCollapsed {
            guard column == .primary, let nav = _containers[.primary] as? UINavigationController else { return }
            while nav.viewControllers.count > 1 { _ = nav.popViewController(animated: false) }
            _collapsedColumn = .primary
        } else if style == .doubleColumn, column == .primary {
            preferredDisplayMode = preferredSplitBehavior == .overlay ? .oneOverSecondary : .oneBesideSecondary
        }
        _layoutColumns()
    }
    public func hide(_ column: Column) {
        precondition(style != .unspecified && column != .compact,
                     "hide(_:) requires a noncompact column-style column")
        guard _installed else { return }
        // MEASURED SE hidePrimary: ignored even while secondary is on top.
        if isCollapsed { return }
        if style == .doubleColumn, column == .primary { preferredDisplayMode = .secondaryOnly }
        _layoutColumns()
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
        _replace(vc, for: .secondary)
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
