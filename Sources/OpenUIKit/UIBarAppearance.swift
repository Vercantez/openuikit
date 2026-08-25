// UIBarAppearance and its three concrete bars. Owner: viewcontroller module
// (M13 "bars & appearance"). 33 uses of `UINavigationBarAppearance` in the
// four-app census; it is how every modern app colors a bar.
//
// MEASURED (real iOS 26.1, iPhone 16 — `probe/p6` recipe in
// UIBarButtonItem.swift):
//
//  * `configureWithOpaqueBackground()` + `backgroundColor` paints the whole
//    bar region (bar zone height, i.e. the bar's own 54 pt PLUS the 10 pt
//    top padding above it — the `_UIBarBackground` frame is (0, -10, w, 64))
//    and adds a shadow hairline exactly 1/3 pt tall at the bar's bottom
//    edge, black at alpha 0.30.
//  * `configureWithTransparentBackground()` clears both.
//  * `configureWithDefaultBackground()` is iOS 26's DEFAULT: fully
//    transparent at rest, with the scroll-edge effect providing the material
//    once content passes under the bar (docs/SCENE_SPEC.md "UINavigationStack").
//    OpenUIKit therefore treats default and transparent identically for a
//    static, unscrolled bar — the divergence lives in the edge effect, which
//    UINavigationBar already models (`updatePocket`).
//  * `titleTextAttributes` / `largeTitleTextAttributes` override the label's
//    font and color; anything unset keeps the measured default (17 pt
//    semibold `label` inline, 34 pt bold `label` large).
//
// DIVERGENCE: there is no `UIVisualEffectView`, so `backgroundEffect` is
// accepted and ignored; a translucent bar renders as its flat equivalent.
// Same class of gap as the alert card and the tab-bar platter — see
// docs/KNOWN_GAPS.md.

/// Shared base of the three bar appearance objects.
public class UIBarAppearance {
    /// How the background was configured.
    public enum _Configuration: Sendable { case `default`, opaque, transparent }

    public var backgroundColor: UIColor?
    /// The 1/3 pt hairline under the bar. `nil` = no hairline.
    public var shadowColor: UIColor?
    public var backgroundImage: UIImage?
    /// Accepted and ignored — no UIVisualEffectView (see the file header).
    public var backgroundEffect: AnyObject?

    public internal(set) var _configuration: _Configuration = .default

    /// Measured default hairline: black at 0.30.
    public static let defaultShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.30)
    /// Measured hairline thickness (`_UIBarBackgroundShadowView`).
    public static let shadowHeight: CGFloat = 1.0 / 3.0

    public required init() {}

    public init(barAppearance other: UIBarAppearance) {
        backgroundColor = other.backgroundColor
        shadowColor = other.shadowColor
        backgroundImage = other.backgroundImage
        _configuration = other._configuration
    }

    /// iOS 26's default: transparent until content scrolls under the bar.
    public func configureWithDefaultBackground() {
        _configuration = .default
        backgroundColor = nil
        backgroundImage = nil
        shadowColor = UIBarAppearance.defaultShadowColor
    }

    public func configureWithOpaqueBackground() {
        _configuration = .opaque
        backgroundColor = .systemBackground
        backgroundImage = nil
        shadowColor = UIBarAppearance.defaultShadowColor
    }

    public func configureWithTransparentBackground() {
        _configuration = .transparent
        backgroundColor = nil
        backgroundImage = nil
        shadowColor = nil
    }

    /// The flat color this appearance paints the bar region with, or nil.
    var _resolvedBackgroundColor: UIColor? {
        switch _configuration {
        case .transparent: return backgroundColor   // usually nil
        case .default: return backgroundColor       // nil unless the app set one
        case .opaque: return backgroundColor ?? .systemBackground
        }
    }
}

/// Text attributes a bar appearance can override. Mirrors the subset of
/// `[NSAttributedString.Key: Any]` UIKit reads for bar titles; OpenUIKit
/// keeps it typed because the library has no Foundation `Any` bridging.
public struct UIBarTitleTextAttributes {
    public var font: UIFont?
    public var foregroundColor: UIColor?
    public init(font: UIFont? = nil, foregroundColor: UIColor? = nil) {
        self.font = font
        self.foregroundColor = foregroundColor
    }

    /// UIKit spelling: `appearance.titleTextAttributes = [.font: f,
    /// .foregroundColor: c]`. The dictionary form is accepted through the
    /// attributed-string keys OpenUIKit already declares.
    public init(_ attributes: [NSAttributedString.Key: Any]) {
        font = attributes[.font] as? UIFont
        foregroundColor = attributes[.foregroundColor] as? UIColor
    }
}

public final class UINavigationBarAppearance: UIBarAppearance {
    public var titleTextAttributes = UIBarTitleTextAttributes()
    public var largeTitleTextAttributes = UIBarTitleTextAttributes()

    public required init() { super.init() }
    public override init(barAppearance other: UIBarAppearance) {
        super.init(barAppearance: other)
        if let nav = other as? UINavigationBarAppearance {
            titleTextAttributes = nav.titleTextAttributes
            largeTitleTextAttributes = nav.largeTitleTextAttributes
        }
    }
}

public final class UIToolbarAppearance: UIBarAppearance {
    public required init() { super.init() }
}

public final class UITabBarAppearance: UIBarAppearance {
    public required init() { super.init() }
}
