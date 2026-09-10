// UITab / UITabPlacement (iOS 18). Owner: viewcontroller module (M10 chrome).
//
// MEASURED (iOS 26.1, iPhone 16 393×852 @3x and iPad (A16) 820×1180 @2x —
// Tools/oracle2/signallastrowsprobe, transcripts ios-26.1-iphone16.json /
// ios-26.1-ipad-a16.json, section `tabs`), identical on both devices unless
// noted:
//
//   * `UITab(title:image:identifier:viewControllerProvider:)`: the provider
//     is NOT called at init. It is called once, lazily, the first time
//     `viewController` is read — or when the tab is handed to
//     `UITabBarController.tabs` (all three providers ran at the `tabs =`
//     assignment, before the controller's view loaded). The argument is
//     the tab itself and the controller it returns reads `vc.tab === tab`
//     immediately. Replacing `tabs` with a subset and restoring it does
//     NOT call the provider again (`providerCalls` stayed 1 for every tab,
//     including one whose provider returns a fresh controller each time);
//     `tab.viewController` keeps the first controller.
//   * Defaults: `badgeValue` nil, `subtitle` nil, `preferredPlacement`
//     .automatic (0), `isHidden` false, `isEnabled` true, `allowsHiding`
//     false, `hasVisiblePlacement` false until attached (true once in
//     `tabs`), `parent` nil, `tabBarController` nil until attached and nil
//     again once dropped from `tabs`.
//   * Propagation is tab → item only: `badgeValue`/`title` written on the
//     tab appear on `tabBar.items[i]` AND on the controller's
//     `tabBarItem` (same object); writing `tabBarItem.badgeValue` does not
//     move the tab's value (tab "7" / item "9"). `tabBar.items[i].image`
//     is a different object from `tab.image`. The controller's own `title`
//     does not change when the tab's title does.
//   * `accessibilityValue` is settable and read back verbatim (UITab is an
//     NSObject; UIAccessibility's informal properties apply).
//
// Signal-iOS demand (3 uses, HomeTabBarController, iPad + iOS 18 only):
// the initializer with a persisted controller, `badgeValue`,
// `accessibilityValue`, `UITabBarController.tabs = …`, then
// `selectedIndex` and the legacy `UITabBarControllerDelegate` methods.

public enum UITabPlacement: Int, Sendable, Hashable {
    case automatic = 0
    case `default` = 1
    case optional = 2
    case movable = 3
    case pinned = 4
    case fixed = 5
    case sidebarOnly = 6
}

@preconcurrency @MainActor
open class UITab {
    public let identifier: String
    /// Forwarded to the bar item (measured tab → item, never item → tab).
    open var title: String {
        didSet { _item?.title = title; tabBarController?._tabChanged(self) }
    }
    open var image: UIImage? {
        didSet { _item?.image = image; tabBarController?._tabChanged(self) }
    }
    open var subtitle: String?
    open var badgeValue: String? {
        didSet { _item?.badgeValue = badgeValue }
    }
    open var preferredPlacement: UITabPlacement = .automatic
    open var userInfo: Any?
    open var isHidden = false
    open var isHiddenByDefault = false
    open var allowsHiding = false
    open var isEnabled = true
    /// Measured false until the tab is in a controller's `tabs`.
    open var hasVisiblePlacement: Bool { tabBarController != nil }
    /// UIAccessibility informal properties (an NSObject category in UIKit).
    open var accessibilityValue: String?
    open var accessibilityIdentifier: String?
    open var accessibilityLabel: String?

    /// The owning controller once the tab is in its `tabs`; nil after it is
    /// dropped from that array (measured `tabs.subset.t3`).
    public internal(set) weak var tabBarController: UITabBarController?

    private let provider: (UITab) -> UIViewController
    private var _viewController: UIViewController?
    /// The bar item that represents the tab; the controller installs the
    /// same object as `viewController.tabBarItem` (measured: one badge).
    var _item: UITabBarItem?

    public init(title: String, image: UIImage?, identifier: String,
                viewControllerProvider: @escaping (UITab) -> UIViewController) {
        self.title = title
        self.image = image
        self.identifier = identifier
        self.provider = viewControllerProvider
    }

    /// Lazily created by the provider, exactly once, and retained.
    open var viewController: UIViewController? {
        if let vc = _viewController { return vc }
        let vc = provider(self)
        vc._tab = self
        _viewController = vc
        return vc
    }

    /// The bar item mirrored from the tab (created once per tab).
    func _tabBarItem() -> UITabBarItem {
        if let item = _item { return item }
        let item = UITabBarItem(title: title, image: image, tag: 0)
        item.badgeValue = badgeValue
        _item = item
        return item
    }
}
