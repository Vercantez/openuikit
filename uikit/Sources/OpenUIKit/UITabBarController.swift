// UITabBarController. Owner: viewcontroller module (M10 chrome).
//
// Container layout (mirrors real UIKit's private tree, so scene layout
// dumps prune identically on both sides):
//   UILayoutContainerView            (controller view)
//     UITransitionView               (content area, FULL bounds — content
//       UIViewControllerWrapperView   underlaps the floating bar)
//         <selected child's view>
//     UITabBar                       (bottom 72 pt, transparent around the
//                                     floating platter)
//
// Tab switching swaps the selected child's view non-animated with the
// measured UIKit appearance order:
//   old.viewWillDisappear → new.viewWillAppear
//   → old.viewDidDisappear → new.viewDidAppear
// Children keep their loaded views while deselected — each tab's state
// (scroll positions, control values, view hierarchy) survives switching.
//
// iOS 18 `tabs` API — MEASURED (iOS 26.1, iPhone 16 and iPad (A16);
// Tools/oracle2/signallastrowsprobe, section `tabs`; UITab.swift carries
// the per-tab facts):
//   * `tabs = [t1, t2, t3]` before the view loads: every provider runs at
//     once, `tabBar.items` is filled from the tabs (title/badge mirrored,
//     tag 0, the image a different object), `selectedIndex` becomes 0,
//     `selectedTab` t1, `selectedViewController` t1's controller, and the
//     delegate gets `didSelectTab(t1, previousTab: nil)` synchronously.
//     `viewControllers` reads NIL while the tabs API is in use, on both
//     devices; nothing further fires when the view appears.
//   * Programmatic `selectedTab = …`, `selectedIndex = …` and
//     `selectedViewController = …` each fire only `didSelectTab(_:previousTab:)`
//     — no `shouldSelectTab`, and none of the legacy `shouldSelect` /
//     `didSelect` pair.
//   * A user tap (`_UITabButton.sendActions` on the phone) fires
//     `shouldSelectTab` then `didSelectTab`; a `false` leaves the selection
//     and fires nothing else; re-tapping the selected tab fires both again
//     with `previousTab` equal to the tab. The legacy pair is never
//     consulted under `tabs` (a `false` from `shouldSelect` changed
//     nothing). `UITabBarController` no longer responds to the
//     `UITabBarDelegate` entry `tabBar(_:didSelect:)` on iOS 26.
//   * Replacing `tabs` with a subset that drops the selected tab moves the
//     selection to the first tab with `didSelectTab(first, previousTab:
//     dropped)`; the dropped tab's `tabBarController` is nil and its
//     provider is not re-run when it is restored. `tabs = []` leaves
//     `selectedIndex` NSNotFound, `tabBar.items` `[]` (not nil) and the
//     stale `selectedTab` / `selectedViewController` in place.
//   * Legacy `viewControllers = …` after `tabs` empties `tabs` (`[]`),
//     detaches the tabs (`tabBarController` nil) and installs the legacy
//     children with their own items; `tabs = …` after that empties
//     `viewControllers` again and removes the legacy children
//     (`parent` nil). A controller fed only `viewControllers` reports
//     `tabs == []` and its children `tab == nil`; its `selectedTab` is a
//     private auto-generated tab (UUID identifier) that is NOT modelled —
//     the port answers nil there.
//   * iPad (A16), 820×1180: `mode` .automatic (0), `sidebar.isHidden`
//     TRUE, the tree shows `_UITabContainerView` > `_UIFloatingTabBar`
//     [0, 32, 820, 44] — the same floating bar the port already lays out
//     for pad; no sidebar is observable, and `_UITabButton` controls are
//     not in the phone-style tree there. On the phone `sidebar.isHidden`
//     reads false. `sidebar` itself is not modelled.
//
// Signal-iOS demand (HomeTabBarController, iPad + iOS 18): `tabs =
// tabs.map(uiTab(for:))`, `selectedIndex`, `delegate = self` with the
// legacy `shouldSelect`/`didSelect` pair, `UITab.badgeValue`.

/// Content container (same class name real UIKit dumps — compare.py prunes
/// this subtree on both sides).
@preconcurrency @MainActor
final class UITransitionView: UIView {}
@preconcurrency @MainActor
final class UIViewControllerWrapperView: UIView {}

@preconcurrency @MainActor
open class UITabBarController: UIViewController, UITabBarDelegate {
    public let tabBar = UITabBar()
    let transitionView = UITransitionView()

    /// iOS 18 `UITabBarController.Mode`. MEASURED `.automatic` (0) on both
    /// devices; the value is stored only.
    public enum Mode: Int, Sendable {
        case automatic = 0
        case tabBar = 1
        case tabSidebar = 2
    }
    public var mode: Mode = .automatic

    public init() {
        super.init()
    }

    /// MEASURED `tab.coder`: non-nil, unloaded, `viewControllers` nil.
    public required init?(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: Children

    /// Legacy children. Reads nil while the `tabs` API is in use (measured).
    public var viewControllers: [UIViewController]? {
        get { _usesTabs ? nil : _viewControllers }
        set { setViewControllers(newValue, animated: false) }
    }
    var _viewControllers: [UIViewController]?

    open func setViewControllers(_ viewControllers: [UIViewController]?,
                                 animated: Bool) {
        if _usesTabs {
            for t in _tabs { t.tabBarController = nil }
            _tabs = []
            _usesTabs = false
            _selectedTab = nil
        }
        _installChildren(viewControllers, itemFor: { vc, i in
            if vc.tabBarItem == nil {
                vc.tabBarItem = UITabBarItem(title: vc.title, image: nil, tag: i)
            }
            return vc.tabBarItem!
        })
        _selectedIndex = min(_selectedIndex,
                             max(0, (viewControllers ?? []).count - 1))
        if isViewLoaded { installSelected() }
    }

    /// Replace the child set (both APIs). `itemFor` supplies each child's
    /// bar item.
    private func _installChildren(_ viewControllers: [UIViewController]?,
                                  itemFor: (UIViewController, Int) -> UITabBarItem) {
        for vc in _viewControllers ?? [] {
            if vc.parent === self {
                if vc === _selectedViewController { deselectCurrent() }
                vc.willMove(toParent: nil)
                vc.viewIfLoaded?.removeFromSuperview()
                vc.removeFromParent()
            }
        }
        _viewControllers = viewControllers
        var items: [UITabBarItem] = []
        for (i, vc) in (viewControllers ?? []).enumerated() {
            addChild(vc)
            items.append(itemFor(vc, i))
            vc.didMove(toParent: self)
        }
        tabBar.items = items
    }

    // MARK: iOS 18 tabs

    var _tabs: [UITab] = []
    var _usesTabs = false
    /// The tab last selected under the `tabs` API; kept (stale) across
    /// `tabs = []` as measured.
    var _selectedTab: UITab?

    /// The iOS 18 tab set. Setting it runs every provider (once per tab,
    /// UITab.swift), mirrors the tabs into `tabBar.items`, empties
    /// `viewControllers`, and selects the first tab (or keeps the current
    /// one when it survives) with `didSelectTab(_:previousTab:)`.
    public var tabs: [UITab] {
        get { _tabs }
        set { setTabs(newValue, animated: false) }
    }

    public func setTabs(_ newTabs: [UITab], animated: Bool) {
        let previousSelection = _selectedTab
        for t in _tabs where !newTabs.contains(where: { $0 === t }) {
            t.tabBarController = nil
        }
        _tabs = newTabs
        _usesTabs = true
        for t in newTabs { t.tabBarController = self }
        let vcs = newTabs.compactMap { tab -> UIViewController? in
            guard let vc = tab.viewController else { return nil }
            vc.tabBarItem = tab._tabBarItem()
            return vc
        }
        _installChildren(vcs, itemFor: { vc, _ in vc.tabBarItem! })
        guard !newTabs.isEmpty else {
            // MEASURED `tabs.empty`: NSNotFound, items [], stale selection.
            _selectedIndex = Int.max
            return
        }
        if let previousSelection,
           let keep = newTabs.firstIndex(where: { $0 === previousSelection }) {
            _selectedIndex = keep
            if isViewLoaded { installSelected() }
            return
        }
        _selectedIndex = 0
        _selectTab(newTabs[0], previous: previousSelection)
    }

    /// The selected tab under the `tabs` API; nil for a legacy controller
    /// (UIKit answers a private auto-generated tab there — not modelled).
    public var selectedTab: UITab? {
        get { _usesTabs ? _selectedTab : nil }
        set {
            guard let newValue, _usesTabs,
                  let idx = _tabs.firstIndex(where: { $0 === newValue }) else { return }
            _selectedIndex = idx
            _selectTab(newValue, previous: _selectedTab)
        }
    }

    /// Commit a tabs-mode selection: install the child (when loaded) and
    /// report `didSelectTab` — the only callback for programmatic changes.
    private func _selectTab(_ tab: UITab, previous: UITab?) {
        _selectedTab = tab
        if isViewLoaded { installSelected(reportLegacyDidSelect: false) }
        delegate?.tabBarController(self, didSelectTab: tab, previousTab: previous)
    }

    /// Bookkeeping for a tab whose title/image changed (UITab.swift).
    func _tabChanged(_ tab: UITab) {
        tabBar.setNeedsLayout()
    }

    // MARK: Delegate (M13)

    /// UIKit's controller-level delegate. Legacy mode: `shouldSelect` gates
    /// a USER tap (UIKit does not consult it for a programmatic
    /// `selectedIndex =`), `didSelect` fires for both, as UIKit does. Tabs
    /// mode: the `Tab` pair instead (file header).
    public weak var delegate: UITabBarControllerDelegate?
    /// Earlier OpenUIKit spelling of `delegate`; kept as an alias.
    public var tabBarControllerDelegate: UITabBarControllerDelegate? {
        get { delegate }
        set { delegate = newValue }
    }

    // MARK: Selection

    var _selectedIndex = 0
    /// The child whose view is currently installed (nil before any install).
    /// Settable like UIKit's: selects the matching child (MEASURED
    /// `select.selectedViewController=chats`: `didSelectTab` only).
    public var selectedViewController: UIViewController? {
        get {
            // MEASURED `tbc.afterTabsSet.unloaded`: the tabs API answers the
            // selected tab's controller before the view loads.
            if _usesTabs, let vcs = _viewControllers, _selectedIndex < vcs.count {
                return vcs[_selectedIndex]
            }
            return _selectedViewController
        }
        set {
            guard let vc = newValue,
                  let idx = _viewControllers?.firstIndex(where: { $0 === vc }) else { return }
            selectedIndex = idx
        }
    }
    var _selectedViewController: UIViewController?

    public var selectedIndex: Int {
        get { _selectedIndex }
        set {
            guard let vcs = _viewControllers,
                  newValue >= 0, newValue < vcs.count else { return }
            let changed = newValue != _selectedIndex
                || selectedViewController !== vcs[newValue]
            _selectedIndex = newValue
            if _usesTabs {
                // MEASURED `select.selectedIndex=2`: didSelectTab only.
                _selectTab(_tabs[newValue], previous: _selectedTab)
                return
            }
            guard isViewLoaded, changed else { return }
            installSelected()
        }
    }

    // MARK: Container view

    open override func loadView() {
        let v = UILayoutContainerView(frame: CGRect(x: 0, y: 0,
                                                    width: 390, height: 844))
        v.backgroundColor = .systemBackground
        view = v

        transitionView.frame = v.bounds
        transitionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        v.addSubview(transitionView)

        tabBar.frame = CGRect(x: 0, y: v.bounds.height - UITabBar.barHeight,
                              width: v.bounds.width, height: UITabBar.barHeight)
        tabBar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        tabBar.delegate = self
        v.addSubview(tabBar)
        layoutTabBarFrame()
        applyTabBarSafeArea()
    }

    /// MEASURED Tabs-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// `_UIFloatingTabBar [0, 32, 820, 44]` at window SA.top, not the
    /// phone bottom bar `[0, 1097, 820, 83]`. Phone keeps the bottom 83.
    func layoutTabBarFrame() {
        guard isViewLoaded else { return }
        let b = view.bounds
        let h = UITabBar.barHeight
        if UITabBar.isPad {
            // MEASURED Tabs-ipad t4000: `_UIFloatingTabBar [0, -32, 820, 44]`
            // while the hosted search is active (y = −SA.top). Rest t200
            // keeps y = SA.top **32**.
            let y: CGFloat = padHostedSearchIsActive
                ? -view.safeAreaInsets.top : view.safeAreaInsets.top
            tabBar.frame = CGRect(x: 0, y: y, width: b.width, height: h)
            tabBar.autoresizingMask = [.flexibleWidth, .flexibleBottomMargin]
        } else {
            tabBar.frame = CGRect(x: 0, y: b.height - h,
                                  width: b.width, height: h)
            tabBar.autoresizingMask = [.flexibleWidth, .flexibleTopMargin]
        }
    }

    /// Hosted `UISearchController.isActive` on the selected nav child.
    var padHostedSearchIsActive: Bool {
        guard UITabBar.isPad else { return false }
        let nav = selectedViewController as? UINavigationController
        return nav?.topViewController?.navigationItem.searchController?.isActive == true
            || nav?.navigationBar.topItem?.searchController?.isActive == true
    }

    /// The child underlaps the floating platter but reports the bar's
    /// height as `safeAreaInsets.bottom`, so a table/scroll view can rest
    /// its last row above the chrome. MEASURED Tabs t200, iPhone SE 2x /
    /// iOS 26.1, window SA `[0,0,0,0]`: UITabBar `[0, 584, 375, 83]`,
    /// table `safeAreaInsets.bottom` **83** (no home-indicator extra).
    /// Compact-height (Tabs t200.landscape): bar `[0, 311, 667, 64]`,
    /// table bottom **64**. `UITabBar.barHeight` is 83 / 64 / 72.
    ///
    /// Pad: the bar is at the top and does **not** add to the child's
    /// bottom inset. MEASURED Tabs-ipad t200: transitionView SA
    /// `[32, 0, 25, 0]` (window SA); table bottom **25** not 83. A
    /// non-nav child gets extra top so content starts at **96**
    /// (32 + 44 + 20) — Tabs-ipad t1000 toolbar / t2000 scroll.
    func applyTabBarSafeArea() {
        guard isViewLoaded else { return }
        let inherited = view.safeAreaInsets
        if UITabBar.isPad {
            let top: CGFloat
            if selectedViewController is UINavigationController {
                top = inherited.top
            } else {
                top = inherited.top + UITabBar.barHeight + UITabBar.padContentGapBelowBar
            }
            transitionView._setSafeAreaInsets(UIEdgeInsets(
                top: top,
                left: inherited.left,
                bottom: inherited.bottom,
                right: inherited.right))
        } else {
            transitionView._setSafeAreaInsets(UIEdgeInsets(
                top: inherited.top,
                left: inherited.left,
                bottom: max(inherited.bottom, UITabBar.barHeight),
                right: inherited.right))
        }
    }

    open override func viewDidLoad() {
        super.viewDidLoad()
        applyTabBarSafeArea()
        // Tabs mode already reported its selection at `tabs =` (measured:
        // nothing fires when the view appears).
        installSelected(reportLegacyDidSelect: !_usesTabs)
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTabBarFrame()
        applyTabBarSafeArea()
    }

    /// Swap the installed child for the current selectedIndex (appearance
    /// order per file header). No-op when it is already installed.
    func installSelected(reportLegacyDidSelect: Bool = true) {
        guard let vcs = _viewControllers, !vcs.isEmpty,
              _selectedIndex < vcs.count else { return }
        let incoming = vcs[_selectedIndex]
        guard incoming !== selectedViewController else {
            tabBar.selectedItem = incoming.tabBarItem
            return
        }
        let outgoing = selectedViewController

        incoming.loadViewIfNeeded()
        outgoing?.beginAppearanceTransition(false, animated: false)
        incoming.beginAppearanceTransition(true, animated: false)

        if let out = outgoing {
            out.viewIfLoaded?.superview?.removeFromSuperview() // wrapper
        }
        let wrapper = UIViewControllerWrapperView(frame: transitionView.bounds)
        wrapper.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        let cv = incoming.view!
        cv.frame = wrapper.bounds
        cv.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        wrapper.addSubview(cv)
        transitionView.addSubview(wrapper)

        outgoing?.endAppearanceTransition()
        incoming.endAppearanceTransition()

        _selectedViewController = incoming
        tabBar.selectedItem = incoming.tabBarItem
        applyTabBarSafeArea()
        if reportLegacyDidSelect && !_usesTabs {
            delegate?.tabBarController(self, didSelect: incoming)
        }
    }

    /// Remove the current selection's view (used when children are replaced).
    func deselectCurrent() {
        guard let out = selectedViewController else { return }
        out.beginAppearanceTransition(false, animated: false)
        out.viewIfLoaded?.superview?.removeFromSuperview()
        out.endAppearanceTransition()
        _selectedViewController = nil
    }

    // MARK: UITabBarDelegate (user taps)

    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let vcs = _viewControllers,
              let idx = vcs.firstIndex(where: { $0.tabBarItem === item })
        else { return }
        if _usesTabs {
            // MEASURED `tap.*`: shouldSelectTab gates, didSelectTab reports
            // (also on a re-tap of the selected tab); the legacy pair is
            // never consulted.
            let tab = _tabs[idx]
            if let d = delegate, !d.tabBarController(self, shouldSelectTab: tab) { return }
            _selectedIndex = idx
            _selectTab(tab, previous: _selectedTab)
            return
        }
        if let d = delegate,
           !d.tabBarController(self, shouldSelect: vcs[idx]) { return }
        selectedIndex = idx
    }
}

// MARK: - UITabBarControllerDelegate (M13)

/// UIKit's protocol with UIKit's names. The two legacy members that mean
/// anything without an editable "More" tab or custom tab transitions are
/// wired, plus the iOS 18 `Tab` pair; `animationControllerForTransitionFrom`
/// and the interactive variant are declared but never consulted — tab
/// switches here are not animated (docs/KNOWN_GAPS.md).
@preconcurrency @MainActor
public protocol UITabBarControllerDelegate: AnyObject {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController)
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelectTab tab: UITab) -> Bool
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelectTab selectedTab: UITab, previousTab: UITab?)
    func tabBarController(_ tabBarController: UITabBarController,
                          animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning?
}

public extension UITabBarControllerDelegate {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool { true }
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController) {}
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelectTab tab: UITab) -> Bool { true }
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelectTab selectedTab: UITab, previousTab: UITab?) {}
    func tabBarController(_ tabBarController: UITabBarController,
                          animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
}
