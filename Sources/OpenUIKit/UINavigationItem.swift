// UINavigationItem. Owner: viewcontroller module (M13 "bars & appearance").
//
// Every code-based UIKit app configures its bar through the pushed view
// controller's `navigationItem`, never by touching the bar directly. This is
// the object that makes `UIBarButtonItem` reachable.
//
// Measured behaviour reproduced (real iOS 26.1, iPhone 16 — see
// UIBarButtonItem.swift for the metric probe recipe):
//
//  * `title` drives the 17 pt semibold centered label; `titleView` replaces
//    it entirely and is centred the same way.
//  * `leftBarButtonItems` are laid out from the leading margin, `right...`
//    from the trailing margin, each item in its own 44 pt capsule platter
//    with a 12 pt gap.
//  * The centered title falls back to LEADING alignment (just past the left
//    group, `_UIBarMetrics.gap` away) when centring it would leave less than
//    `titleGroupClearance` between the label and either group — measured:
//    with a 155.67 pt right group and a 43.67 pt title on a 393 pt bar the
//    centred label would sit 3 pt from the group and UIKit moves it left
//    instead.
//  * `prompt` adds a single-line 12 pt secondary caption ABOVE the bar
//    content and grows the bar by `promptHeight`.
//  * `backBarButtonItem` set on a controller supplies the back button the
//    NEXT controller shows.

@MainActor
public class UINavigationItem {
    public var title: String? {
        didSet { if title != oldValue { _bar?._navigationItemChanged(self) } }
    }
    public var titleView: UIView? {
        didSet { if titleView !== oldValue { _bar?._navigationItemChanged(self) } }
    }
    public var prompt: String? {
        didSet { if prompt != oldValue { _bar?._navigationItemChanged(self) } }
    }
    /// Back button for the controller pushed ON TOP of this one.
    public var backBarButtonItem: UIBarButtonItem?
    /// Hide the automatically synthesized back button.
    public var hidesBackButton: Bool = false {
        didSet { if hidesBackButton != oldValue { _bar?._navigationItemChanged(self) } }
    }
    /// Custom title for the automatically synthesized back button
    /// (UIKit's `backButtonTitle`).
    public var backButtonTitle: String?

    public var largeTitleDisplayMode: LargeTitleDisplayMode = .automatic {
        didSet {
            if largeTitleDisplayMode != oldValue { _bar?._navigationItemChanged(self) }
        }
    }

    public enum LargeTitleDisplayMode: Int, Sendable {
        case automatic = 0, always = 1, never = 2
        /// iOS 17 alias for `.automatic`.
        public static var inline: LargeTitleDisplayMode { .never }
    }

    public var leftBarButtonItems: [UIBarButtonItem]? {
        didSet { _bar?._navigationItemChanged(self) }
    }
    public var rightBarButtonItems: [UIBarButtonItem]? {
        didSet { _bar?._navigationItemChanged(self) }
    }

    public var leftBarButtonItem: UIBarButtonItem? {
        get { leftBarButtonItems?.first }
        set { leftBarButtonItems = newValue.map { [$0] } }
    }
    public var rightBarButtonItem: UIBarButtonItem? {
        get { rightBarButtonItems?.first }
        set { rightBarButtonItems = newValue.map { [$0] } }
    }

    /// UIKit's animated setters (OpenUIKit applies them immediately —
    /// the bar has no item cross-fade, see docs/KNOWN_GAPS.md).
    public func setLeftBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        leftBarButtonItems = items
    }
    public func setRightBarButtonItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        rightBarButtonItems = items
    }
    public func setLeftBarButton(_ item: UIBarButtonItem?, animated: Bool) {
        leftBarButtonItem = item
    }
    public func setRightBarButton(_ item: UIBarButtonItem?, animated: Bool) {
        rightBarButtonItem = item
    }
    public func setHidesBackButton(_ hides: Bool, animated: Bool) {
        hidesBackButton = hides
    }

    /// Per-item appearance overrides (UIKit lets a single screen restyle the
    /// bar without touching the shared bar appearance).
    public var standardAppearance: UINavigationBarAppearance? {
        didSet { _bar?._navigationItemChanged(self) }
    }
    public var scrollEdgeAppearance: UINavigationBarAppearance? {
        didSet { _bar?._navigationItemChanged(self) }
    }
    public var compactAppearance: UINavigationBarAppearance? {
        didSet { _bar?._navigationItemChanged(self) }
    }

    /// The bar currently displaying this item (set by `UINavigationBar`).
    weak var _bar: UINavigationBar?

    public init(title: String? = nil) {
        self.title = title
    }
}
