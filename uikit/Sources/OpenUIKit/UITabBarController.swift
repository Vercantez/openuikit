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

    public init() {
        super.init()
    }

    // MARK: Children

    public var viewControllers: [UIViewController]? {
        get { _viewControllers }
        set { setViewControllers(newValue, animated: false) }
    }
    var _viewControllers: [UIViewController]?

    open func setViewControllers(_ viewControllers: [UIViewController]?,
                                 animated: Bool) {
        for vc in _viewControllers ?? [] {
            if vc.parent === self {
                if vc === selectedViewController { deselectCurrent() }
                vc.willMove(toParent: nil)
                vc.viewIfLoaded?.removeFromSuperview()
                vc.removeFromParent()
            }
        }
        _viewControllers = viewControllers
        for (i, vc) in (viewControllers ?? []).enumerated() {
            addChild(vc)
            if vc.tabBarItem == nil {
                vc.tabBarItem = UITabBarItem(title: vc.title, image: nil, tag: i)
            }
            vc.didMove(toParent: self)
        }
        tabBar.items = (viewControllers ?? []).map { $0.tabBarItem! }
        _selectedIndex = min(_selectedIndex,
                             max(0, (viewControllers ?? []).count - 1))
        if isViewLoaded { installSelected() }
    }

    // MARK: Delegate (M13)

    /// UIKit's controller-level delegate. `shouldSelect` gates a USER tap
    /// (UIKit does not consult it for a programmatic `selectedIndex =`),
    /// `didSelect` fires for both, as UIKit does.
    public weak var tabBarControllerDelegate: UITabBarControllerDelegate?

    // MARK: Selection

    var _selectedIndex = 0
    /// The child whose view is currently installed (nil before any install).
    public private(set) var selectedViewController: UIViewController?

    public var selectedIndex: Int {
        get { _selectedIndex }
        set {
            guard let vcs = _viewControllers,
                  newValue >= 0, newValue < vcs.count else { return }
            let changed = newValue != _selectedIndex
                || selectedViewController !== vcs[newValue]
            _selectedIndex = newValue
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
        installSelected()
    }

    open override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        layoutTabBarFrame()
        applyTabBarSafeArea()
    }

    /// Swap the installed child for the current selectedIndex (appearance
    /// order per file header). No-op when it is already installed.
    func installSelected() {
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

        selectedViewController = incoming
        tabBar.selectedItem = incoming.tabBarItem
        applyTabBarSafeArea()
        tabBarControllerDelegate?.tabBarController(self, didSelect: incoming)
    }

    /// Remove the current selection's view (used when children are replaced).
    func deselectCurrent() {
        guard let out = selectedViewController else { return }
        out.beginAppearanceTransition(false, animated: false)
        out.viewIfLoaded?.superview?.removeFromSuperview()
        out.endAppearanceTransition()
        selectedViewController = nil
    }

    // MARK: UITabBarDelegate (user taps)

    public func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem) {
        guard let vcs = _viewControllers,
              let idx = vcs.firstIndex(where: { $0.tabBarItem === item })
        else { return }
        if let d = tabBarControllerDelegate,
           !d.tabBarController(self, shouldSelect: vcs[idx]) { return }
        selectedIndex = idx
    }
}

// MARK: - UITabBarControllerDelegate (M13)

/// UIKit's protocol with UIKit's names. The two members that mean anything
/// without an editable "More" tab or custom tab transitions are wired;
/// `animationControllerForTransitionFrom` and the interactive variant are
/// declared but never consulted — tab switches here are not animated
/// (docs/KNOWN_GAPS.md).
@preconcurrency @MainActor
public protocol UITabBarControllerDelegate: AnyObject {
    func tabBarController(_ tabBarController: UITabBarController,
                          shouldSelect viewController: UIViewController) -> Bool
    func tabBarController(_ tabBarController: UITabBarController,
                          didSelect viewController: UIViewController)
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
                          animationControllerForTransitionFrom fromVC: UIViewController,
                          to toVC: UIViewController) -> UIViewControllerAnimatedTransitioning? { nil }
}
