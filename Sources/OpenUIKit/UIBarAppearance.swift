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
// `backgroundEffect` now has UIKit's UIBlurEffect type. Although the iOS SDK
// header spells the Objective-C property `copy`, iOS 26.1 runtime probes show
// strong identity storage with zero copy messages on assignment and appearance
// copy initialization. Pure Swift cannot retain @NSCopying declaration metadata
// while suppressing its generated copy, so runtime behavior wins here. The
// current bar compositor does not consume the descriptor yet; see
// docs/KNOWN_GAPS.md.

/// The height/style family used by legacy bar-background APIs.
///
/// Raw values are ABI-visible UIKit values, measured from the iOS 26.1 SDK
/// and confirmed at runtime. `defaultPrompt` / `compactPrompt` select the
/// artwork used when a bar has a prompt; the non-prompt metric is the visual
/// fallback when no prompt-specific image was installed.
public enum UIBarMetrics: Int, Sendable {
    case `default` = 0
    case compact = 1
    case defaultPrompt = 101
    case compactPrompt = 102

    /// Deprecated UIKit spellings retained as aliases. Swift enums cannot
    /// declare duplicate raw-value cases, so these are static properties just
    /// like the imported SDK surface.
    public static var landscapePhone: UIBarMetrics { .compact }
    public static var landscapePhonePrompt: UIBarMetrics { .compactPrompt }
}

/// Shared base of the three bar appearance objects.
@preconcurrency @MainActor
public class UIBarAppearance {
    /// How the background was configured.
    public enum _Configuration: Sendable { case `default`, opaque, transparent }

    public var backgroundColor: UIColor?
    /// The 1/3 pt hairline under the bar. `nil` = no hairline.
    public var shadowColor: UIColor?
    public var backgroundImage: UIImage?
    /// Runtime-measured strong storage. The SDK header carries Objective-C
    /// `copy` metadata, but UIKit 26.1 sends no copy message here; see the file
    /// header and docs/KNOWN_GAPS.md for the unavoidable declaration tradeoff.
    @available(iOS 13.0, *)
    public var backgroundEffect: UIBlurEffect?

    public internal(set) var _configuration: _Configuration = .default

    /// Measured default hairline: black at 0.30.
    public static let defaultShadowColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.30)
    /// Measured hairline thickness (`_UIBarBackgroundShadowView`).
    public static let shadowHeight: CGFloat = 1.0 / 3.0

    /// UIKit reuses one internal chrome effect for every default base,
    /// toolbar, and tab appearance, including later default resets. Ordinary
    /// public UIBlurEffect factories remain independent objects.
    static let _defaultChromeEffect = UIBlurEffect(
        style: .systemChromeMaterial)

    public required init() {
        // Base, toolbar, and tab appearances start with adaptive chrome on
        // iOS 26.1. UINavigationBarAppearance deliberately clears it in its
        // own initializer. The configure methods are full resets.
        backgroundEffect = UIBarAppearance._defaultChromeEffect
    }

    public init(barAppearance other: UIBarAppearance) {
        backgroundColor = other.backgroundColor
        shadowColor = other.shadowColor
        backgroundImage = other.backgroundImage
        // Measured UIKit retains this exact object and sends no copy message,
        // even for a hostile UIBlurEffect subclass.
        backgroundEffect = other.backgroundEffect
        _configuration = other._configuration
    }

    /// iOS 26's default: transparent until content scrolls under the bar.
    public func configureWithDefaultBackground() {
        _configuration = .default
        backgroundEffect = UIBarAppearance._defaultChromeEffect
        backgroundColor = nil
        backgroundImage = nil
        shadowColor = UIBarAppearance.defaultShadowColor
    }

    public func configureWithOpaqueBackground() {
        _configuration = .opaque
        backgroundEffect = nil
        backgroundColor = .systemBackground
        backgroundImage = nil
        shadowColor = UIBarAppearance.defaultShadowColor
    }

    public func configureWithTransparentBackground() {
        _configuration = .transparent
        backgroundEffect = nil
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

/// The position adjustment used by bar-item appearance state. UIKit exposes
/// this as a small value type rather than a CGPoint because the two fields are
/// semantic horizontal/vertical offsets.
public struct UIOffset: Codable, Equatable, Sendable {
    public var horizontal: CGFloat
    public var vertical: CGFloat

    public init(horizontal: CGFloat, vertical: CGFloat) {
        self.horizontal = horizontal
        self.vertical = vertical
    }

    public init() { self.init(horizontal: 0, vertical: 0) }

    public static let zero = UIOffset()
}

/// Appearance values for one control state of a bar button item.
@preconcurrency @MainActor
open class UIBarButtonItemStateAppearance {
    open var titleTextAttributes: [NSAttributedString.Key: Any] = [:]
    open var titlePositionAdjustment: UIOffset = .zero
    open var backgroundImage: UIImage?
    open var backgroundImagePositionAdjustment: UIOffset = .zero

    public init() {}

    fileprivate init(copying other: UIBarButtonItemStateAppearance) {
        titleTextAttributes = other.titleTextAttributes
        titlePositionAdjustment = other.titlePositionAdjustment
        backgroundImage = other.backgroundImage
        backgroundImagePositionAdjustment = other.backgroundImagePositionAdjustment
    }
}

/// State-specific styling used by navigation-bar back buttons and ordinary
/// bar button items. Rendering currently consumes the title color for the
/// navigation back control; the remaining values are retained faithfully so
/// callers can configure and inspect an appearance before fuller rendering
/// support lands.
@preconcurrency @MainActor
open class UIBarButtonItemAppearance {
    fileprivate var style: UIBarButtonItem.Style
    open private(set) var normal = UIBarButtonItemStateAppearance()
    open private(set) var highlighted = UIBarButtonItemStateAppearance()
    open private(set) var disabled = UIBarButtonItemStateAppearance()
    open private(set) var focused = UIBarButtonItemStateAppearance()

    public init(style: UIBarButtonItem.Style) {
        self.style = style
    }

    public convenience init() { self.init(style: .plain) }

    open func configureWithDefault(for style: UIBarButtonItem.Style) {
        self.style = style
        normal = UIBarButtonItemStateAppearance()
        highlighted = UIBarButtonItemStateAppearance()
        disabled = UIBarButtonItemStateAppearance()
        focused = UIBarButtonItemStateAppearance()
    }

    fileprivate init(copying other: UIBarButtonItemAppearance) {
        style = other.style
        normal = UIBarButtonItemStateAppearance(copying: other.normal)
        highlighted = UIBarButtonItemStateAppearance(copying: other.highlighted)
        disabled = UIBarButtonItemStateAppearance(copying: other.disabled)
        focused = UIBarButtonItemStateAppearance(copying: other.focused)
    }
}

@preconcurrency @MainActor
public final class UINavigationBarAppearance: UIBarAppearance {
    /// UIKit's exact source shape. Keeping these as dictionaries matters to
    /// unmodified apps: dictionary literals cannot be assigned to a wrapper
    /// struct without changing the app source.
    public var titleTextAttributes: [NSAttributedString.Key: Any] = [:]
    public var largeTitleTextAttributes: [NSAttributedString.Key: Any] = [:]
    public var backButtonAppearance = UIBarButtonItemAppearance()
    public private(set) var backIndicatorImage: UIImage?
    public private(set) var backIndicatorTransitionMaskImage: UIImage?

    public required init() {
        super.init()
        backgroundEffect = nil
    }

    public override init(barAppearance other: UIBarAppearance) {
        super.init(barAppearance: other)
        if let nav = other as? UINavigationBarAppearance {
            titleTextAttributes = nav.titleTextAttributes
            largeTitleTextAttributes = nav.largeTitleTextAttributes
            backButtonAppearance = UIBarButtonItemAppearance(copying: nav.backButtonAppearance)
            backIndicatorImage = nav.backIndicatorImage
            backIndicatorTransitionMaskImage = nav.backIndicatorTransitionMaskImage
        }
    }

    /// Unlike the base, toolbar, and tab families, navigation appearances
    /// reset their default background to no effect on iOS 26.1.
    public override func configureWithDefaultBackground() {
        super.configureWithDefaultBackground()
        backgroundEffect = nil
    }

    public func setBackIndicatorImage(_ backIndicatorImage: UIImage?,
                                      transitionMaskImage backIndicatorTransitionMaskImage: UIImage?) {
        self.backIndicatorImage = backIndicatorImage
        self.backIndicatorTransitionMaskImage = backIndicatorTransitionMaskImage
    }
}

@preconcurrency @MainActor
public final class UIToolbarAppearance: UIBarAppearance {
    public required init() { super.init() }
    public override init(barAppearance other: UIBarAppearance) {
        super.init(barAppearance: other)
    }
}

@preconcurrency @MainActor
public final class UITabBarAppearance: UIBarAppearance {
    public required init() { super.init() }
    public override init(barAppearance other: UIBarAppearance) {
        super.init(barAppearance: other)
    }
}
