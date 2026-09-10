// UINavigationBar. Owner: viewcontroller module (M7.5 navigation,
// M10 large titles, M13 navigation items + appearance).
//
// Visuals per docs/APP_FEEL.md "Navigation transitions" and the M13
// measurements in UIBarButtonItem.swift:
//   - 54pt content bar below a 10pt top padding (MEASURED on real iOS 26.1;
//     M7.5's guessed 20 + 44 split is gone, the 64pt total is unchanged).
//     Background + hairline come from `standardAppearance`. Catalyst's
//     default is the opaque configuration; iOS 26's default is
//     `configureWithDefaultBackground` (transparent at rest — MEASURED
//     Forms t200, iPhone SE 2x: the 64 pt bar zone reads the grouped
//     table's (242, 242, 247), not opaque white).
//   - `topItem` (a pushed controller's `navigationItem`) drives the title,
//     title view, prompt and the leading/trailing bar-button platters.
//   - Title label centered, semibold 17, .label color.
//   - Back button: "‹" chevron + the previous VC's title, both in tintColor,
//     dimming to alpha 0.2 while pressed (the same measured highlight factor
//     as plain system buttons — golden/button_highlighted).
//   - During push/pop the titles crossfade/slide: the incoming title slides
//     in from the incoming side while the outgoing title slides toward the
//     back-button position and fades; back buttons crossfade in place (the
//     chevron visually stays put). Driven by setTransitionProgress(0 -> 1),
//     so the SAME code path serves UIView.animate-driven pushes (property
//     sets inside the animate block record animations) and interactive
//     back-swipe scrubbing (direct model sets, no animation context).
//
// The bar is driven by UINavigationController: it keeps the UIKit item stack
// (`setItems`/`pushItem`/`popItem`), and the controller additionally pushes
// title/backTitle through `setState` because those two take part in the
// push/pop cross-fade.

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


/// The back control: chevron + previous title, standard pressed dimming.
@preconcurrency @MainActor
final class _UINavigationBarBackButton: UIControl {
    let chevron = UILabel()
    let backLabel = UILabel()

    /// Layout metrics (feel-tuned to iOS): chevron leading 8pt, 6pt gap to
    /// the title, 12pt trailing slop kept tappable.
    static let leading: CGFloat = 8
    static let gap: CGFloat = 6
    static let trailing: CGFloat = 12

    init(title: String, tintColor: UIColor) {
        super.init(frame: .zero)
        isOpaque = false
        // Chevron: the harvested "‹" glyph path (UILabel falls back to the
        // stb_truetype rasterizer for sizes without an ink-table entry).
        chevron.text = "\u{2039}" // ‹
        chevron.font = .systemFont(ofSize: 23, weight: .semibold)
        chevron.textColor = tintColor
        backLabel.text = title
        backLabel.font = .systemFont(ofSize: 17)
        backLabel.textColor = tintColor
        addSubview(chevron)
        addSubview(backLabel)
    }

    @available(*, unavailable, message: "navigation-bar back buttons require a title and tint color")
    required init?(coder: NSCoder) {
        fatalError("navigation-bar back buttons cannot be decoded")
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        let c = chevron.intrinsicContentSize
        let t = backLabel.intrinsicContentSize
        return CGSize(width: Self.leading + c.width + Self.gap + t.width
                        + Self.trailing,
                      height: UINavigationBar.contentHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let c = chevron.intrinsicContentSize
        let t = backLabel.intrinsicContentSize
        let midY = bounds.height / 2
        // Optical nudge: the "‹" glyph's ink sits slightly high in its line
        // box at 23pt; +1pt centers it against the 17pt title.
        chevron.frame = CGRect(x: Self.leading, y: midY - c.height / 2 + 1,
                               width: c.width, height: c.height)
        backLabel.frame = CGRect(x: Self.leading + c.width + Self.gap,
                                 y: midY - t.height / 2,
                                 width: t.width, height: t.height)
    }

    /// Standard system-button pressed feedback: content dims to alpha 0.2
    /// (UIButton.systemHighlightedTitleAlpha, golden-exact for buttons).
    override func stateDidChange() {
        super.stateDidChange()
        let a: CGFloat = isHighlighted ? UIButton.systemHighlightedTitleAlpha : 1
        chevron.alpha = a
        backLabel.alpha = a
    }

    /// Center x of the back TITLE label, in the bar's coordinates, for the
    /// bar's title-slide target (assumes the button sits at its static
    /// position x = 0).
    var backTitleCenterX: CGFloat {
        let c = chevron.intrinsicContentSize
        let t = backLabel.intrinsicContentSize
        return Self.leading + c.width + Self.gap + t.width / 2
    }
}

@preconcurrency @MainActor
public final class UINavigationBar: UIView, _UIBarItemContainer, UIBarPositioning {
    /// Process-wide proxy for UIKit's `UINavigationBar.appearance()` spelling.
    /// New bars inherit the proxy's objects. This is the useful subset for a
    /// single-process portable host; containment- and trait-scoped proxies are
    /// deliberately outside this compatibility step.
    private static var _appearanceProxy: UINavigationBar?

    public override class func appearance() -> Self {
        if let proxy = _appearanceProxy { return proxy as! Self }
        let proxy = UINavigationBar(frame: .zero)
        _appearanceProxy = proxy
        return proxy as! Self
    }

    // MARK: Bar-zone metrics
    //
    // MEASURED, real iOS 26.1 / iPhone 16 / compact width, no safe-area top
    // (Tools/oracle2/simscene; probe recipe in UIBarButtonItem.swift): the
    // bar's own frame is (0, 10, w, 54) inside its container and its
    // `_UIBarBackground` covers (0, -10, w, 64) — i.e. an opaque appearance
    // paints the WHOLE 64 pt zone, top padding included. That is exactly the
    // 10 + 54 split M10 measured for the large-title bar's inline zone, so
    // both modes now share one set of constants (and `barHeight` is still
    // 64, unchanged since M7.5).
    //
    // Before M13 the inline bar used a guessed 20 pt "status inset" + a 44 pt
    // content bar (same 64 pt total, title centre 42). The measured centre is
    // 32; the guess is gone.

    /// Content bar height (below the top padding).
    public static let contentHeight: CGFloat = 54
    /// Padding above the content bar inside the 64 pt overlay (measured).
    /// On the iOS cut this padding is OUTSIDE the bar's own frame: the bar
    /// sits at y = max(safeArea.top, iOSMinimumBarTop) with height 54 (see
    /// UINavigationController.updateContainerLayout).
    public static let barTopPadding: CGFloat = 10
    /// iOS 26.1 (MEASURED 2026-09-04, navprobe.barorigin, SE 2x and iPhone 16):
    /// `bar.frame.y = max(nav.view.safeAreaInsets.top, 10)`. Window SA 0
    /// (SE, status bar hidden) still yields y 10 — the 10 is a floor, not a
    /// status-bar addend. A 20 pt status bar and a 59 pt notch set y to that
    /// inset; additionalSafeAreaInsets 20/59 on a zero-SA window match.
    public static let iOSMinimumBarTop: CGFloat = 10
    /// Compact-height bar origin. MEASURED NavFlow t200.landscape,
    /// iPhone SE 2x / iOS 26.1: window 667×375, vSizeClass compact,
    /// `UINavigationBar [0, 24, 667, 54]`, table `safeAreaInsets.top` **78**
    /// (= 24+54). Portrait floor stays 10 (navprobe.barorigin).
    public static let iOSCompactHeightBarTop: CGFloat = 24
    /// Height of the bar's own frame on the iOS cut (the 54 pt content bar).
    /// MEASURED same probe: inline [0, 10, W, 54]; collapsed large-title
    /// the same; expanded large-title [0, 10, W, 106] = 54 + 52.
    public static let iOSBarContentHeight: CGFloat = 54
    public static let iOSLargeTitleBarHeight: CGFloat = 106
    /// Phone expanded overlay at `.large`: 10 + 54 + 52. Grows with the
    /// large-title font under a window content-size override — see
    /// `effectiveLargeTitleBarHeight`.
    public static let iOSLargeTitleZoneHeightDefault: CGFloat = 52
    /// Height of the expanded large-title bar under the iOS cut when
    /// traits scale the large-title face.
    /// MEASURED navbar_large / NavFlow t200: **106** = 54 + 52 at `.large`.
    /// MEASURED NavFlow t200.ax1 / TableEditor t200.ax1, iPhone SE 2x /
    /// iOS 26.1: **115.5** = 54 + 61.5 when the 48 pt large-title line box
    /// is 57.5 (zone = max(52, 57.5+4)). Pad-idiom 138 inset is unchanged.
    static func iOSLargeTitleBarHeight(compatibleWith traits: UITraitCollection) -> CGFloat {
        iOSBarContentHeight + largeTitleVisualZoneHeight(compatibleWith: traits)
    }
    /// Deprecated name for `barTopPadding` (M7.5 called it a status inset).
    public static var statusBarInset: CGFloat { barTopPadding }
    /// Total bar height.
    public static var barHeight: CGFloat { barTopPadding + contentHeight }
    /// Bar-local y of the item platters (they top-align in the content bar).
    public static var platterY: CGFloat { barTopPadding }
    /// Extra height a `prompt` adds above the bar content (measured).
    public static let promptHeight: CGFloat = 32
    public static let promptFontSize: CGFloat = 12
    /// Minimum clearance the centred title keeps from either item group
    /// before it falls back to leading alignment (measured: at 3 pt UIKit
    /// had already given up).
    public static let titleGroupClearance: CGFloat = 8

    // MARK: Large-title metrics (M10 — measured from golden/navbar_*)
    //
    // iOS 26 bars are TRANSPARENT at rest; the expanded state reserves
    // 116 pt of content inset: 10 (top padding) + 54 (inline bar zone) +
    // 52 (large-title zone). The 34 pt-bold large title sits at x = 16
    // (iOS) / 20 (Catalyst) and scrolls away 1:1 with the content.
    // Catalyst fades both titles through the zone (smoothstep). iOS 26.1
    // (MEASURED, navprobe scroll): titles stay fully on/off and swap at
    // d = 52; the bar overlay shrinks 116 → 64; a release snaps at 36/37
    // (not half the zone). Content that slides under the collapsed bar
    // gets the scroll-edge-effect "pocket" (see updatePocket).

    /// Expanded adjusted content inset (the rest offset is −this).
    /// Phone iOS: **116** = 10 + 54 + 52 (SE / zero-SA floor).
    /// Pad iOS: **138** = 32 + 54 + 52.
    /// MEASURED NavFlow-ipad t200 / TableEditor-ipad t200, iPad (A16)
    /// 820×1180 @2x / iOS 26.1: window SA `[32, 0, 25, 0]`, bar
    /// `[0, 32, 820, 106]`, table `safeAreaInsets.top` **138**, large-title
    /// label abs y **89.5** (= 32 + 54 + 3.5). The phone 116 rest offset
    /// on this window yields collapseDistance −22 and label y 111.5
    /// (TableEditor blob 561.8 at `[22, 98, 19, 46]`; NavFlow t4800
    /// contentOffset −116 vs −138). Phone SE stays 116.
    public static var largeTitleExpandedInset: CGFloat {
        largeTitleExpandedInset(compatibleWith: .current)
    }
    static func largeTitleExpandedInset(compatibleWith traits: UITraitCollection) -> CGFloat {
        if isPad { return 138 }
        if isIOS { return largeInlineZoneTop + iOSLargeTitleBarHeight(compatibleWith: traits) }
        return 116
    }
    static let largeInlineZoneTop: CGFloat = 10
    static let largeInlineZoneHeight: CGFloat = 54
    static let largeTitleZoneHeight: CGFloat = 52
    /// Visual large-title zone. Collapse still swaps at `largeTitleZoneHeight`
    /// (52) — unmeasured at ax1. Rest height grows with the line box:
    /// max(52, labelHeight+4) → 52 at `.large`, 61.5 at ax1 (57.5+4).
    static func largeTitleVisualZoneHeight(compatibleWith traits: UITraitCollection) -> CGFloat {
        let grown = largeTitleLabelHeight(compatibleWith: traits) + 4
        // MEASURED NavFlow t200.xxxl: bar **108** = 54 content + **54**
        // zone (40 pt Bold box 48). `max(52, 48+4)` is 52 and sat the
        // bar at 106 (t200.xxxl 94.29 → 94.21). ax1 stays 57.5+4=61.5.
        if traits.preferredContentSizeCategory == .extraExtraExtraLarge {
            return max(largeInlineZoneHeight, grown)
        }
        return max(largeTitleZoneHeight, grown)
    }
    /// Catalyst: label [20, 3, w, 40.5] inside the zone. iOS 26.1 (MEASURED
    /// 2026-09-04, `navbar_dark`/`navbar_large` on the iPhone SE 3rd gen and
    /// the iPhone 16 alike, confirmed navprobe.barorigin): the large-title
    /// label is [16, 3.5, textWidth, 41] inside `NavigationBarLargeTitleView`
    /// at bar-local y 54. On the iOS cut the bar frame starts AFTER the
    /// 10 pt floor, so the label's bar-local y is 54 + 3.5 = 57.5 (abs 67.5
    /// when pad is 10). Catalyst's bar still includes the padding (y 0,
    /// height 116) so the label stays at 67.
    /// Phone iOS: 16 (navbar_large / navprobe). Pad iOS: 20.
    /// MEASURED realapp_storage_light_ipad, iPad (A16) 820×1180 @2x /
    /// iOS 26.1: the large-title UILabel is `[20, 3.5, 306.5, 41]` inside
    /// `NavigationBarLargeTitleView` (abs `[20, 89.5]`); the bar's own
    /// `layoutMargins.left` is 20. Catalyst stays 20.
    static var largeTitleX: CGFloat { isIOS && !isPad ? 16 : 20 }
    static var largeTitleLabelY: CGFloat { largeTitleLabelY(compatibleWith: .current) }
    static var largeTitleLabelHeight: CGFloat { largeTitleLabelHeight(compatibleWith: .current) }
    /// MEASURED navbar_large: zone 52, bar-local y **57.5**. NavFlow t200.ax1:
    /// zone 61.5, label abs y **64** = bar y 10 + **54** (flush with the
    /// content-bar bottom). Collapse distance is still 52 (unmeasured at ax1).
    static func largeTitleLabelY(compatibleWith traits: UITraitCollection) -> CGFloat {
        guard isIOS else { return 67 }
        return largeTitleVisualZoneHeight(compatibleWith: traits) > largeTitleZoneHeight
            ? iOSBarContentHeight : 57.5
    }
    /// MEASURED navbar_large / navprobe on SE 2x and iPhone 16: 34 pt Bold
    /// box is **41** (not the 3x pixel-ceil of lineHeight 40.574). NavFlow
    /// t200.ax1: 48 pt Bold box **57.5** = `FontEngine.labelLineHeight`.
    static func largeTitleLabelHeight(compatibleWith traits: UITraitCollection) -> CGFloat {
        guard isIOS else { return 40.5 }
        let font = largeTitleFont(compatibleWith: traits)
        if font.pointSize == largeTitleFontSize { return 41 }
        return FontEngine.labelLineHeight(for: font)
    }
    /// MEASURED NavFlow t200.ax1 / TableEditor t200.ax1: the large-title
    /// UILabel is **48 pt Bold** = `preferredFont(.largeTitle)` point size
    /// with weight `.bold` (the Dynamic Type table's `bold=false` is the
    /// descriptor; the bar still paints Bold). `.large` stays 34 Bold.
    static func largeTitleFont(compatibleWith traits: UITraitCollection) -> UIFont {
        iOSLargeTitleFont(compatibleWith: traits)
    }
    static var isIOS: Bool { OpenUIKitRuntime.systemFontCut == .iOS }

    /// Size from `preferredFont(.largeTitle)` (48 at ax1, 34 at `.large`);
    /// weight **bold**, matching the bar's pre-ax1 face and the golden
    /// TableEditor t200.ax1 "Reminders" width **238.5** (regular 48 was
    /// 219.5). `dynamic_type.json` marks largeTitle `bold: false`; the
    /// nav bar still paints the bold display face (main used 34 bold).
    static func iOSLargeTitleFont(compatibleWith traits: UITraitCollection) -> UIFont {
        let size = UIFont.preferredFont(forTextStyle: .largeTitle,
                                        compatibleWith: traits).pointSize
        return .systemFont(ofSize: size, weight: .bold)
    }

    /// MEASURED TableEditor t200.ax1 / Feed t200.ax1, iPhone SE 2x /
    /// iOS 26.1: window `traitOverrides` `.accessibilityLarge` makes the
    /// large-title UILabel **48 pt** (uncapped `.largeTitle`), intrinsic
    /// height **57.5** (lineHeight 57.281 ceiled to the 2x pixel). The
    /// large-title zone grows `max(52, 57.5+4) = 61.5`; the bar frame is
    /// `[0, 10, 375, 115.5]` = 54+61.5; rest inset **125.5** = 10+54+61.5
    /// (table/collection abs y 125.5). `.large` stays 52 / 106 / 116.
    /// Pad idiom unmeasured at ax1 — keep 52.
    var effectiveLargeTitleLabelHeight: CGFloat {
        guard UINavigationBar.isIOS, !UINavigationBar.isPad else {
            return UINavigationBar.largeTitleLabelHeight
        }
        let font = UIFont.preferredFont(forTextStyle: .largeTitle,
                                        compatibleWith: traitCollection)
        return FontEngine.labelLineHeight(for: .systemFont(ofSize: font.pointSize, weight: .bold))
    }
    var effectiveLargeTitleZoneHeight: CGFloat {
        guard UINavigationBar.isIOS, !UINavigationBar.isPad else {
            return UINavigationBar.largeTitleZoneHeight
        }
        // Same rule as `largeTitleVisualZoneHeight` (xxxl floor 54).
        return UINavigationBar.largeTitleVisualZoneHeight(
            compatibleWith: traitCollection)
    }
    var effectiveLargeTitleExpandedInset: CGFloat {
        if UINavigationBar.isPad { return 138 }
        guard UINavigationBar.isIOS else { return UINavigationBar.largeTitleExpandedInset }
        return UINavigationBar.iOSMinimumBarTop
            + UINavigationBar.iOSBarContentHeight
            + effectiveLargeTitleZoneHeight
    }
    var effectiveLargeTitleBarHeight: CGFloat {
        guard UINavigationBar.isIOS else { return UINavigationBar.iOSLargeTitleBarHeight }
        return UINavigationBar.iOSBarContentHeight + effectiveLargeTitleZoneHeight
    }
    var effectiveLargeTitleLabelY: CGFloat {
        guard UINavigationBar.isIOS else { return UINavigationBar.largeTitleLabelY }
        // `.large`: 54 + 3.5 = 57.5 inside the 52 pt zone (41 pt label).
        // ax1: 57.5 pt label in a 61.5 pt zone sits at the zone origin
        // (abs y 64 = bar y 10 + 54).
        let zoneTop = UINavigationBar.iOSBarContentHeight
        // `.large`: 41 + 3.5 + 4 = 48.5 sits in the 52 pt zone, so the
        // 3.5 inset stays. ax1: zone is labelH+4 (61.5), so 3.5 on top
        // would leave only 0.5 under the 57.5 pt label; iOS pins to the
        // zone origin (abs y 64) and keeps the 4 pt below.
        if effectiveLargeTitleLabelHeight + 3.5 + 4 > effectiveLargeTitleZoneHeight {
            return zoneTop
        }
        return zoneTop + 3.5
    }
    /// iOS cut AND pad idiom. MEASURED ipadprobe navLargeTable / inline,
    /// iPad (A16) 820×1180 @2x / iOS 26.1: the content bar is still 54 pt
    /// (`[0, 32, 820, 54]` inline, `[0, 32, 820, 106]` large = 54+52),
    /// not the pre-iOS-26 regular-width 50. Unspecified idiom does not
    /// count, so phone goldens stay on the phone numbers.
    static var isPad: Bool {
        isIOS && (UITraitCollection.current.userInterfaceIdiom == .pad
                  || UIDevice.current.userInterfaceIdiom == .pad)
    }
    /// iOS cut AND compact vertical size class. MEASURED NavFlow
    /// t200.landscape dump `screen.verticalSizeClass` = 1 (compact) on
    /// iPhone SE 2x / iOS 26.1. Unspecified (portrait suite / Catalyst)
    /// does not count.
    static var isCompactHeight: Bool {
        isIOS && UITraitCollection.current.verticalSizeClass == .compact
    }
    /// `prefersLargeTitles` is still true in landscape (NavFlow sets it);
    /// compact height displays the 54 pt inline chrome instead of the
    /// 106 pt large-title overlay. MEASURED NavFlow t200.landscape: one
    /// `"Library"` at `[305, 35.5]` (inline), no 41 pt large-title label;
    /// t3000.landscape bar stays `[0, 24, 667, 54]`.
    var displaysLargeTitles: Bool {
        prefersLargeTitles && !UINavigationBar.isCompactHeight
    }
    static let largeTitleFontSize: CGFloat = 34
    static let largeInlineTitleCenterY: CGFloat = 32
    /// iOS 26.1 (MEASURED 2026-09-04, navprobe.barorigin, SE 2x): in the
    /// 54 pt content bar the inline title's HostedViewWrapper is y 11.5
    /// (center 22) when the large title is off, and y 26.5 (center 37,
    /// alpha 0) while the large title shows. Same numbers at SA top 0 / 20
    /// / 59 — they are bar-local.
    static let iOSInlineTitleCenterY: CGFloat = 22
    static let iOSLargeHiddenInlineTitleCenterY: CGFloat = 37
    /// iOS 26.1 (MEASURED 2026-09-04, `Tools/oracle2/navprobe` scroll pass,
    /// iPhone 16): a zero-velocity release at collapse distance 36 snaps
    /// back to the expanded rest; at 37 it snaps collapsed. Catalyst keeps
    /// the half-zone snap (26).
    static let iOSSnapCollapseDistance: CGFloat = 36
    /// Collapsed bar-frame height on the iOS cut: 54 (the 10 pt floor sits
    /// outside the frame). Overlay / child safe area is pad + 54 = 64 when
    /// pad is 10. MEASURED navprobe.barorigin / scroll: bar [0, 10, W, 106]
    /// → [0, 10, W, 54] at d = 52; `_UIBarBackground` 116 → 64.
    static let iOSCollapsedBarHeight: CGFloat = 54

    /// Set by UINavigationController; fired on back-button touchUpInside.
    var onBackTapped: (() -> Void)?

    /// iOS 26 large-title mode: transparent bar, 34 pt large title that
    /// collapses to the inline title as the tracked scroll view scrolls up.
    public var prefersLargeTitles: Bool = false {
        didSet {
            guard prefersLargeTitles != oldValue else { return }
            configureLargeTitleAppearance()
            _controller?._largeTitlesModeChanged()
        }
    }
    weak var _controller: UINavigationController?

    /// UIKit's bar delegate (UINavigationBarDelegate, this file). MEASURED
    /// (Tools/oracle2/signallastrowsprobe, section `nav`, iOS 26.1): nil on
    /// a standalone bar; the navigation controller installs itself on the
    /// bar it manages (`barDelegateIsNav` true — a subclass that conforms
    /// receives the calls, UINavigationController.swift).
    public weak var delegate: UINavigationBarDelegate?
    private var resolvedPosition: UIBarPosition = .top
    /// MEASURED: `.top` (2) detached, with or without a delegate; a
    /// delegate answering `.topAttached` is read once the bar joins a
    /// superview (3), `position(for:)` asked exactly once then, with the
    /// bar itself as the argument. An `.any` answer keeps `.top` (the
    /// toolbar's measured rule with the nav bar's default; not measured
    /// for the nav bar itself).
    public var barPosition: UIBarPosition { resolvedPosition }
    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil, let delegate else { return }
        let answer = delegate.position(for: self)
        resolvedPosition = answer == .any ? .top : answer
    }

    /// The content scroll view driving expansion/collapse (bound by
    /// UINavigationController from the top VC's setContentScrollView).
    weak var trackedScrollView: UIScrollView? {
        didSet { if trackedScrollView !== oldValue { setNeedsLayout() } }
    }

    /// Extra height the search bar adds below the 54 pt content bar.
    /// MEASURED Tabs t200 / t4000, iPhone SE 2x / iOS 26.1: at rest the
    /// hosted UISearchBar is **0 pt** tall (`[0, 64, 375, 0]`) and the
    /// navigation bar stays `[0, 10, 375, 54]`; when `isActive` the bar
    /// grows to `[0, 10, 375, 60]` (6 pt) and the search field occupies it.
    static let searchActiveExtraHeight: CGFloat = 6
    var searchHiddenByScroll = false
    /// True after the hosted search controller has been `isActive` at least
    /// once. MEASURED Notes t200 vs t6000 / Tabs t200 vs t6000, iPhone SE
    /// 2x / iOS 26.1: first rest is bar 54 / search height 0; after cancel
    /// inside a tab-bar nav the inactive slot stays **60** below the 54 pt
    /// content (bar `[0, 10, 375, 114]`, inset 124, field `[16, 1, 343, 44]`)
    /// until `hidesSearchBarWhenScrolling` hides it (Tabs t7000 offset 260,
    /// bar 54 again). Ledger (window-root nav, no tab bar) restores 54.
    var searchSlotRevealed = false
    var hostedSearchBar: UISearchBar?

    var largeTitleLabel: UILabel?
    let pocketView = UIImageView()
    /// Fingerprint of the last computed pocket image (offset/size/style).
    var pocketKey: (offsetY: CGFloat, width: CGFloat, engagement: CGFloat)?

    // Current (settled) elements.
    var titleLabel: UILabel
    var backButton: _UINavigationBarBackButton?
    let hairline: UIView
    /// Legacy and modern background images share these rendering surfaces.
    /// A zero-sized `UIImage()` deliberately draws nothing; UIKit apps use
    /// that sentinel to suppress the default background and shadow artwork.
    let backgroundImageView = UIImageView()
    let shadowImageView = UIImageView()

    // MARK: Navigation items (M13)

    /// The item stack, as in UIKit. `topItem` drives everything the bar
    /// shows; `backItem` supplies the back button's title.
    public private(set) var items: [UINavigationItem] = []
    public var topItem: UINavigationItem? { items.last }
    public var backItem: UINavigationItem? {
        items.count > 1 ? items[items.count - 2] : nil
    }

    var leftItemViews: [_UIBarButtonItemView] = []
    var rightItemViews: [_UIBarButtonItemView] = []
    /// iOS 26 shared platters behind runs of image-only items (layoutBarItems).
    var sharedPlatterViews: [_UIBarSharedPlatterView] = []
    var titleViewHost: UIView?
    var promptLabel: UILabel?

    // MARK: Appearance (M13)

    /// UIKit's bar appearance objects. Catalyst keeps the opaque
    /// configuration the inline bar has drawn since M7.5. iOS 26's default
    /// is `configureWithDefaultBackground` (transparent at rest, material
    /// from the scroll-edge effect once content passes under the bar).
    /// MEASURED Forms t200, iPhone SE 2x, iOS 26.1: an inline bar with no
    /// explicit appearance over a grouped table reads (242, 242, 247) —
    /// `systemGroupedBackground` — through the whole 64 pt zone, PIXEL_TOL 6
    /// so the port's previous opaque white (255, 255, 255) failed every
    /// navbar pixel (mae 13.53, 99.6 % of the 64 pt strip).
    var _standardAppearance: UINavigationBarAppearance = {
        let a = UINavigationBarAppearance()
        if UINavigationBar.isIOS {
            a.configureWithDefaultBackground()
        } else {
            a.configureWithOpaqueBackground()
        }
        return a
    }()
    /// UIKit synthesizes its initial `standardAppearance` from legacy state,
    /// but an appearance explicitly assigned by the app becomes authoritative
    /// as a WHOLE. The distinction is observable: legacy getters still retain
    /// later values while the explicit modern appearance keeps rendering.
    var _standardAppearanceIsExplicit = false
    public var standardAppearance: UINavigationBarAppearance {
        get { _standardAppearance }
        set {
            _standardAppearance = newValue
            _standardAppearanceIsExplicit = true
            applyAppearance()
        }
    }
    public var scrollEdgeAppearance: UINavigationBarAppearance? {
        didSet { applyAppearance() }
    }
    public var compactAppearance: UINavigationBarAppearance? {
        didSet { applyAppearance() }
    }
    /// Legacy values remain independent of `standardAppearance`. Real UIKit
    /// reports them through their legacy getters even when a modern appearance
    /// wins rendering (measured on iOS 26.1, both setter orders).
    var _legacyBackgroundImages: [UIBarMetrics: UIImage] = [:]
    public var shadowImage: UIImage? {
        didSet { if shadowImage !== oldValue { applyAppearance() } }
    }
    public var titleTextAttributes: [NSAttributedString.Key: Any]? {
        didSet {
            applyTitleAttributes()
            setNeedsLayout()
        }
    }
    public var largeTitleTextAttributes: [NSAttributedString.Key: Any]? {
        didSet {
            applyTitleAttributes()
            setNeedsLayout()
        }
    }
    /// Legacy `barTintColor`, folded into the standard appearance's
    /// background color (UIKit's own documented equivalence).
    public var barTintColor: UIColor? {
        didSet {
            if !_standardAppearanceIsExplicit {
                // The implicit standard appearance is synthesized from the
                // legacy value. Clearing that value must synthesize the
                // default again rather than retaining the previous tint.
                _standardAppearance.configureWithOpaqueBackground()
                if let barTintColor {
                    _standardAppearance.backgroundColor = barTintColor
                }
            }
            applyAppearance()
        }
    }
    public var isTranslucent: Bool = true {
        didSet {
            guard isTranslucent != oldValue else { return }
            _controller?.updateContainerLayout()
        }
    }

    /// The appearance in force right now and whether it was explicitly
    /// supplied by the app. Per-item objects win over bar objects. An explicit
    /// modern appearance is used in whole, so legacy properties remain
    /// inspectable but do not leak into its rendering.
    var effectiveAppearanceSelection: (appearance: UINavigationBarAppearance,
                                       isExplicit: Bool) {
        let atEdge = trackedScrollView.map {
            $0.contentOffset.y <= -$0.contentInset.top + 0.5
        } ?? true
        if atEdge {
            if let a = topItem?.scrollEdgeAppearance { return (a, true) }
            if let a = scrollEdgeAppearance { return (a, true) }
        }
        if let a = topItem?.standardAppearance { return (a, true) }
        return (_standardAppearance, _standardAppearanceIsExplicit)
    }

    var effectiveAppearance: UINavigationBarAppearance {
        effectiveAppearanceSelection.appearance
    }

    public override init(frame: CGRect) {
        titleLabel = UINavigationBar.makeTitleLabel(nil)
        hairline = UIView()
        super.init(frame: frame)
        configureBar()
    }

    public required init?(coder: NSCoder) {
        titleLabel = UINavigationBar.makeTitleLabel(nil)
        hairline = UIView()
        super.init(coder: coder)
        configureBar()
    }

    private func configureBar() {
        if let proxy = Self._appearanceProxy {
            _standardAppearance = proxy._standardAppearance
            _standardAppearanceIsExplicit = proxy._standardAppearanceIsExplicit
            scrollEdgeAppearance = proxy.scrollEdgeAppearance
            compactAppearance = proxy.compactAppearance
            _legacyBackgroundImages = proxy._legacyBackgroundImages
            shadowImage = proxy.shadowImage
            titleTextAttributes = proxy.titleTextAttributes
            largeTitleTextAttributes = proxy.largeTitleTextAttributes
            isTranslucent = proxy.isTranslucent
        }
        backgroundImageView.isUserInteractionEnabled = false
        backgroundImageView.contentMode = .scaleToFill
        shadowImageView.isUserInteractionEnabled = false
        shadowImageView.contentMode = .scaleToFill
        hairline.isUserInteractionEnabled = false
        addSubview(backgroundImageView)
        addSubview(shadowImageView)
        addSubview(hairline)
        addSubview(titleLabel)
        applyAppearance()
    }

    /// UIKit's legacy, metric-keyed background API. The getter reports only
    /// the exact installed metric (no fallback); visual fallback is applied
    /// separately when a prompt is present.
    public func setBackgroundImage(_ backgroundImage: UIImage?,
                                   for barMetrics: UIBarMetrics) {
        if let backgroundImage {
            _legacyBackgroundImages[barMetrics] = backgroundImage
        } else {
            _legacyBackgroundImages.removeValue(forKey: barMetrics)
        }
        applyAppearance()
    }

    public func backgroundImage(for barMetrics: UIBarMetrics) -> UIImage? {
        _legacyBackgroundImages[barMetrics]
    }

    /// OpenUIKit currently has one physical navigation-bar height. A prompt
    /// selects its prompt artwork when present, with `.default` as UIKit's
    /// documented fallback. Compact values still round-trip for source/API
    /// parity and become renderable when compact bars land.
    var legacyBackgroundImageForCurrentMetrics: UIImage? {
        if promptLabel != nil, let prompt = _legacyBackgroundImages[.defaultPrompt] {
            return prompt
        }
        return _legacyBackgroundImages[.default]
    }

    /// Push the appearance's background + hairline onto the bar.
    func applyAppearance() {
        let selection = effectiveAppearanceSelection
        let a = selection.appearance
        // Large-title mode is transparent at rest by measurement (iOS 26);
        // its material comes from the scroll-edge pocket.
        guard !prefersLargeTitles else {
            backgroundColor = nil
            backgroundImageView.image = nil
            backgroundImageView.isHidden = true
            shadowImageView.image = nil
            shadowImageView.isHidden = true
            hairline.isHidden = true
            for v in leftItemViews + rightItemViews { v.backdropColor = nil }
            applyTitleAttributes()
            setNeedsLayout()
            return
        }

        let legacyBackground = selection.isExplicit
            ? nil : legacyBackgroundImageForCurrentMetrics
        let renderedBackground: UIImage?
        if let legacyBackground {
            // A custom legacy image replaces the system background, including
            // the zero-sized UIImage() sentinel used to make a bar clear.
            backgroundColor = nil
            renderedBackground = legacyBackground
        } else {
            backgroundColor = a._resolvedBackgroundColor
            renderedBackground = a.backgroundImage
        }
        backgroundImageView.image = renderedBackground
        if UINavigationBar.isIOS {
            // MEASURED navprobe.barorigin: `_UIBarBackground` covers
            // [0, −bar.y, W, bar.y+height], including the 10 pt floor
            // above the bar's own frame. The bar's backgroundColor only
            // fills bounds, so the color rides on this view.
            backgroundImageView.backgroundColor = backgroundColor
            backgroundImageView.isHidden = false
        } else {
            backgroundImageView.isHidden = renderedBackground == nil
        }

        if legacyBackground != nil, let shadowImage {
            // UIKit consults a custom shadow only when a custom legacy
            // background exists. UIImage() therefore suppresses the hairline.
            shadowImageView.image = shadowImage
            shadowImageView.isHidden = false
            hairline.isHidden = true
        } else {
            shadowImageView.image = nil
            shadowImageView.isHidden = true
            hairline.backgroundColor = a.shadowColor
            hairline.isHidden = a.shadowColor == nil
                || (backgroundColor == nil && renderedBackground == nil)
        }
        for v in leftItemViews + rightItemViews { v.backdropColor = backgroundColor }
        applyTitleAttributes()
        setNeedsLayout()
    }

    func applyTitleAttributes() {
        let selection = effectiveAppearanceSelection
        let a = selection.appearance
        let inlineAttributes = !selection.isExplicit
            ? (titleTextAttributes ?? a.titleTextAttributes) : a.titleTextAttributes
        let largeAttributes = !selection.isExplicit
            ? (largeTitleTextAttributes ?? a.largeTitleTextAttributes)
            : a.largeTitleTextAttributes
        titleLabel.font = inlineAttributes[.font] as? UIFont
            ?? (UINavigationBar.isIOS
                ? UIFont.preferredFont(forTextStyle: .headline,
                                       compatibleWith: UITraitCollection(
                                        preferredContentSizeCategory:
                                            traitCollection.preferredContentSizeCategory.iOSBarCapped))
                : .systemFont(ofSize: 17, weight: .semibold))
        titleLabel.textColor = inlineAttributes[.foregroundColor] as? UIColor ?? .label
        if let l = largeTitleLabel {
            l.font = largeAttributes[.font] as? UIFont
                ?? (UINavigationBar.isIOS
                    ? UINavigationBar.iOSLargeTitleFont(compatibleWith: traitCollection)
                    : .systemFont(ofSize: UINavigationBar.largeTitleFontSize, weight: .bold))
            l.textColor = largeAttributes[.foregroundColor] as? UIColor ?? .label
        }
        let backColor = a.backButtonAppearance.normal.titleTextAttributes[.foregroundColor]
            as? UIColor ?? tintColor ?? .systemBlue
        backButton?.chevron.textColor = backColor
        backButton?.backLabel.textColor = backColor
    }

    static func makeTitleLabel(_ text: String?) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = .systemFont(ofSize: 17, weight: .semibold)
        l.textColor = .label
        return l
    }

    func makeBackButton(_ title: String?) -> _UINavigationBarBackButton? {
        guard let title else { return nil }
        let appearanceColor = effectiveAppearance.backButtonAppearance.normal
            .titleTextAttributes[.foregroundColor] as? UIColor
        let b = _UINavigationBarBackButton(title: title,
                                           tintColor: appearanceColor ?? tintColor)
        b.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?.onBackTapped?()
        }
        return b
    }

    // MARK: Static state

    /// Set the bar's content instantly (no transition). `backTitle == nil`
    /// hides the back button (root of the stack).
    public func setState(title: String?, backTitle: String?) {
        if transition != nil { endTransition() }
        titleLabel.removeFromSuperview()
        backButton?.removeFromSuperview()
        titleLabel = UINavigationBar.makeTitleLabel(title)
        addSubview(titleLabel)
        backButton = makeBackButton(backTitle)
        if let b = backButton { addSubview(b) }
        if displaysLargeTitles {
            largeTitleLabel?.text = title
            largeTitleLabel?.setNeedsDisplay()
        }
        applyTitleAttributes()
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: Navigation-item driven state (M13)

    /// Display `item` (a pushed controller's `navigationItem`). This is the
    /// path every real app takes; `setState(title:backTitle:)` is the
    /// title-only shorthand the M7.5 controller still uses internally.
    ///
    /// MEASURED (signallastrowsprobe `nav`, standalone bar): `setItems`
    /// asks no `should*` question. Animated, it simulates a push or a pop:
    /// `didPush(newTop)` when the new top was not in the old stack,
    /// `didPop(oldTop)` when it was (both synchronous, nothing later);
    /// non-animated it reports nothing. A vetoing `shouldPop` does not
    /// apply to it. `setItems(nil)` leaves `items` `[]`, not nil.
    public func setItems(_ newItems: [UINavigationItem]?, animated: Bool = false) {
        let oldItems = items
        let oldTop = items.last
        _installItems(newItems ?? [])
        guard animated, let delegate, let newTop = items.last, newTop !== oldTop else { return }
        if let oldTop, oldItems.contains(where: { $0 === newTop }) {
            delegate.navigationBar(self, didPop: oldTop)
        } else {
            delegate.navigationBar(self, didPush: newTop)
        }
    }

    private func _installItems(_ newItems: [UINavigationItem]) {
        for i in items { i._bar = nil }
        items = newItems
        for i in items { i._bar = self }
        _rebuildItemViews()
    }

    /// MEASURED: `shouldPush(item)` with the stack unchanged (`items` and
    /// `topItem` still the old ones); `false` leaves the stack; otherwise
    /// the item is on the stack and `didPush(item)` follows synchronously,
    /// even when animated (nothing fires later).
    public func pushItem(_ item: UINavigationItem, animated: Bool = false) {
        if let delegate, !delegate.navigationBar(self, shouldPush: item) { return }
        _installItems(items + [item])
        delegate?.navigationBar(self, didPush: item)
    }

    /// MEASURED: `shouldPop(top)` with the stack unchanged; a `false`
    /// keeps the stack AND still returns the top item; otherwise the item
    /// leaves the stack and `didPop(item)` follows synchronously. UIKit
    /// also asks with a nil item on an empty bar (ObjC); the Swift
    /// signature cannot pass nil, so an empty bar answers nil silently.
    @discardableResult
    public func popItem(animated: Bool = false) -> UINavigationItem? {
        guard let last = items.last else { return nil }
        if let delegate, !delegate.navigationBar(self, shouldPop: last) { return last }
        _installItems(Array(items.dropLast()))
        delegate?.navigationBar(self, didPop: last)
        return last
    }

    /// A displayed `UINavigationItem` mutated.
    func _navigationItemChanged(_ item: UINavigationItem) {
        guard item === topItem else { return }
        _rebuildItemViews()
    }

    func _view(for item: UIBarButtonItem) -> UIView? {
        (leftItemViews + rightItemViews).first { $0.item === item }
    }

    func _barItemsChanged() { setNeedsLayout() }

    /// Rebuild the title + item platter views from `topItem`.
    func _rebuildItemViews() {
        for v in leftItemViews + rightItemViews { v.removeFromSuperview() }
        leftItemViews = []
        rightItemViews = []
        titleViewHost?.removeFromSuperview()
        titleViewHost = nil
        promptLabel?.removeFromSuperview()
        promptLabel = nil

        guard let item = topItem else {
            hostedSearchBar?.removeFromSuperview()
            hostedSearchBar = nil
            setNeedsLayout()
            return
        }
        titleLabel.text = item.title
        largeTitleLabel?.text = item.title
        largeTitleLabel?.setNeedsDisplay()
        if let tv = item.titleView {
            titleViewHost = tv
            addSubview(tv)
        }
        if let prompt = item.prompt {
            let l = UILabel()
            l.text = prompt
            l.font = .systemFont(ofSize: UINavigationBar.promptFontSize)
            l.textColor = .secondaryLabel
            l.textAlignment = .center
            promptLabel = l
            addSubview(l)
        }
        leftItemViews = (item.leftBarButtonItems ?? []).map { makeItemView($0) }
        rightItemViews = (item.rightBarButtonItems ?? []).map { makeItemView($0) }
        installSearchBar(from: item)
        applyAppearance()
        setNeedsLayout()
    }

    /// Host the item's search bar as a subview. The slot height is
    /// `searchSlotHeight` when the bar is visible and inactive.
    /// Phone + no tab bar: the nav controller hosts it at the bottom
    /// (Ledger t200); this bar keeps only a reference.
    func installSearchBar(from item: UINavigationItem) {
        if let old = hostedSearchBar, old !== item.searchController?.searchBar {
            old.removeFromSuperview()
            hostedSearchBar = nil
        }
        guard let bar = item.searchController?.searchBar else {
            _controller?.layoutFloatingSearch()
            return
        }
        hostedSearchBar = bar
        if usesBottomSearch {
            if bar.superview === self { bar.removeFromSuperview() }
            _controller?.layoutFloatingSearch()
            return
        }
        bar._bottomFloating = false
        if bar.superview !== self { addSubview(bar) }
    }

    /// Phone, iOS cut, no tab bar, and this bar is attached to a
    /// UINavigationController. Detached bars (Tabs unit tests) keep the
    /// overlay. Pad keeps trailing chrome.
    ///
    /// MEASURED Ledger t200 vs Tabs t200 vs Ledger-ipad t200, iPhone SE 2x
    /// / iPad (A16) / iOS 26.1.
    var usesBottomSearch: Bool {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return false }
        guard !UINavigationBar.isPad else { return false }
        guard _controller != nil, _controller?.tabBarController == nil else { return false }
        return topItem?.searchController != nil
    }

    /// `isActive` flipped on the hosted search controller: cancel appears
    /// and the search field moves into the 54 pt content bar. Bottom-docked
    /// search (Ledger) instead collapses the bar to height 0 and keeps the
    /// field at the bottom — settle the table's rest offset to the new
    /// `adjustedContentInset.top` (t3000: −64 → −10).
    func _searchPresentationChanged() {
        updateSearchFromScroll()
        setNeedsLayout()
        let scroll = trackedScrollView
        let wasAtRest = scroll.map {
            abs($0.contentOffset.y + $0.adjustedContentInset.top) < 0.5
        } ?? false
        _controller?.updateContainerLayout()
        if wasAtRest, let scroll, usesBottomSearch {
            scroll.contentOffset.y = -scroll.adjustedContentInset.top
        }
        // Pad: the floating tab bar hides to y = −SA.top while search is
        // active (Tabs-ipad t4000). Phone keeps the bottom bar.
        if UITabBar.isPad {
            _controller?.tabBarController?.layoutTabBarFrame()
        }
    }

    /// Hide-on-scroll for `hidesSearchBarWhenScrolling` (UIKit default true).
    /// At rest (offset == -adjustedContentInset.top) the slot is visible;
    /// once the table has moved up by more than 8 pt it hides. Tabs
    /// scroll-200 is that hide.
    func updateSearchFromScroll() {
        let item = topItem
        let sc = item?.searchController
        var hidden = false
        if let item, let sc, !sc.isActive, item.hidesSearchBarWhenScrolling,
           let s = trackedScrollView {
            let rest = -s.adjustedContentInset.top
            hidden = s.contentOffset.y > rest + 8
        }
        if hidden != searchHiddenByScroll {
            searchHiddenByScroll = hidden
            _controller?.updateContainerLayout()
        }
        setNeedsLayout()
    }

    /// Extra contentOffset.y to add to a programmatic
    /// `setContentOffset` when `hidesSearchBarWhenScrolling` will hide
    /// the slot. MEASURED Tabs t7000 / t7000.xxxl / t7000.ax1, iPhone
    /// SE 2x / iOS 26.1: script `setContentOffset(200)` lands at
    /// **260 / 274 / 296** = 200 + active search-bar height
    /// (`8 + scaledField(44) + 8` → 60 / 74 / 96). `.large` 52 pt rows
    /// at offset 200 scored 92.53 against 260; ax1 80 pt rows at 200
    /// dropped t7000.ax1 92.06 → 91.42 against 296.
    /// `!isActive` is required: Notes t5000 types into an already-active
    /// search (reload / offset) and must not pick up the hide-on-scroll
    /// bump (round-15 t5000 98.70; the merge without this guard dropped
    /// it to 92.52).
    /// Pad has no overlay slot to hide — search is a trailing 240×44
    /// field in the 54 pt bar (`searchOverlayHeight` is 0). MEASURED
    /// Tabs-ipad t7000, iPad (A16) 820×1180 @2x / iOS 26.1: golden
    /// `contentOffset [0, 200]` (same as the script); adding the phone
    /// 60 pt bump scored 94.333 against 98.355.
    func hideOnScrollContentBump(requestedY: CGFloat) -> CGFloat {
        guard OpenUIKitRuntime.systemFontCut == .iOS,
              !UINavigationBar.isPad,
              !usesBottomSearch,
              let item = topItem, item.hidesSearchBarWhenScrolling,
              let sc = item.searchController, !sc.isActive,
              requestedY > 8 else { return 0 }
        // MEASURED Notes t6000 → Tabs t7000, iPhone SE 2x / iOS 26.1:
        // after cancel the inactive slot is showing (inset 124). A
        // programmatic 200 then hides the slot; `safeAreaInsetsDidChange`
        // rebases offset by the 60 pt shrink (200 → 260). Adding the
        // bump on top of that would land 320. When the slot is already
        // collapsed (never revealed, or already hidden) there is no
        // rebase and the bump alone lands 260 (Tabs t7000 golden).
        if showsInactiveSearchSlot { return 0 }
        let field = UIFontMetrics(forTextStyle: .body).scaledValue(
            for: 44, compatibleWith: traitCollection)
        return max(UINavigationBar.iOSBarContentHeight
                    + UINavigationBar.searchActiveExtraHeight,
                   8 + field + 8)
    }

    /// Full inactive-slot height (`8 + scaledField(44) + 8`). MEASURED
    /// Notes t6000 / t6000.xxxl / t6000.ax1, iPhone SE 2x / iOS 26.1:
    /// **60 / 74 / 96** below the 54 pt content (bar 114 / 128 / 150,
    /// inset 124 / 138 / 160). Landscape compact-height bar origin 24
    /// keeps the same 60 pt slot (Notes t6000.landscape bar 114, inset 138).
    func searchInactiveSlotHeight() -> CGFloat {
        let field = UIFontMetrics(forTextStyle: .body).scaledValue(
            for: 44, compatibleWith: traitCollection)
        return 8 + field + 8
    }

    /// Inactive slot under the 54 pt content bar. Phone + tab-bar nav only.
    /// MEASURED Notes t6000 / Tabs t6000 (tab-bar nav) vs Ledger t6000
    /// (window-root nav, bar 54) vs Notes-ipad t6000 (bar 54, trailing field).
    var showsInactiveSearchSlot: Bool {
        guard OpenUIKitRuntime.systemFontCut == .iOS,
              !UINavigationBar.isPad,
              searchSlotRevealed,
              !searchHiddenByScroll,
              topItem?.searchController != nil,
              topItem?.searchController?.isActive != true,
              _controller?.tabBarController != nil else { return false }
        return true
    }

    /// Extra height the navigation controller should add to the bar frame
    /// for hosted search. Active inline: +6 (Tabs t4000 bar 60). Inactive
    /// slot after a tab-bar presentation: +60 (Notes t6000 bar 114).
    /// First rest and Ledger cancel stay 0 (Tabs t200 / Ledger t6000).
    /// Pad: MEASURED Tabs-ipad t4000, the bar stays **54** (search is a
    /// trailing 240/280 × 44 field in the 44 pt top chrome, not +6).
    var searchOverlayHeight: CGFloat {
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return 0 }
        if UINavigationBar.isPad { return 0 }
        // Ledger docks search at the bottom (usesBottomSearch); overlay 0.
        if usesBottomSearch { return 0 }
        guard topItem?.searchController != nil else { return 0 }
        if topItem?.searchController?.isActive == true {
            // MEASURED Tabs t4000: extra 6 → bar 60 = 8+44+8. Tabs t4000.ax1 /
            // Notes t4000.ax1, SE 2x / iOS 26.1: field 80
            // (`UIFontMetrics.body.scaledValue(44)` table hit), extra 42 → bar 96
            // = 8+80+8. Floor stays 6 so `.large` is unchanged.
            let field = UIFontMetrics(forTextStyle: .body).scaledValue(
                for: 44, compatibleWith: traitCollection)
            return max(UINavigationBar.searchActiveExtraHeight,
                       8 + field + 8 - UINavigationBar.iOSBarContentHeight)
        }
        if showsInactiveSearchSlot {
            return searchInactiveSlotHeight()
        }
        return 0
    }

    func makeItemView(_ item: UIBarButtonItem) -> _UIBarButtonItemView {
        item._bar = self
        let v = _UIBarButtonItemView(item: item)
        v.barTintColor = tintColor ?? .systemBlue
        v.backdropColor = backgroundColor
        v.addTarget(for: .touchUpInside) { [weak item] _, event in
            guard let item else { return }
            item.primaryAction?.performWithSender(item, target: nil)
            guard let action = item.action else { return }
            SelectorDispatch.send(action, to: item.target, sender: item, event: event)
        }
        addSubview(v)
        return v
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        // MEASURED TableEditor t200.ax1 / Feed t200.ax1 / Forms t200.ax1,
        // iPhone SE 2x / iOS 26.1: `makeRoot()` builds the bar before it
        // joins the window, so construction-time `preferredFont` still
        // reads process `.large` (17 / 34). Layout runs after
        // `rootViewController =` and must restyle from window
        // `traitOverrides` — inline **21 pt** (bar-capped headline),
        // large title **48 pt** (uncapped). `.large` stays 17 / 34.
        if UINavigationBar.isIOS { applyTitleAttributes() }
        if UINavigationBar.isIOS, frame.minY > 0.5 {
            // MEASURED navprobe.barorigin: `_UIBarBackground` is
            // [0, −bar.y, W, bar.y+bar.height] — it paints from the
            // container top down to the bar's bottom edge.
            backgroundImageView.frame = CGRect(x: 0, y: -frame.minY,
                                               width: bounds.width,
                                               height: bounds.height + frame.minY)
        } else {
            backgroundImageView.frame = bounds
        }
        if let image = shadowImageView.image {
            shadowImageView.frame = CGRect(x: 0, y: bounds.height,
                                           width: bounds.width, height: image.size.height)
        } else {
            shadowImageView.frame = .zero
        }
        // Measured: the golden's `_UIBarBackgroundShadowView` sits just
        // BELOW the bar zone (bar-local y 54 inside a background that starts
        // at -10), i.e. flush against the content, not inside the bar.
        hairline.frame = CGRect(x: 0, y: bounds.height,
                                width: bounds.width, height: UIBarAppearance.shadowHeight)
        layoutBarItems()
        // While a transition drives element centers, keep hands off.
        guard transition == nil else { return }
        place(title: titleLabel, centerX: titleCenterX, alpha: titleViewHost == nil ? 1 : 0)
        if let tv = titleViewHost {
            let s = tv.bounds.size == .zero ? tv.sizeThatFits(bounds.size) : tv.bounds.size
            tv.bounds = CGRect(x: 0, y: 0, width: s.width, height: s.height)
            tv.center = CGPoint(x: titleCenterX, y: contentMidY)
        }
        if let b = backButton { place(back: b, alpha: 1) }
        if displaysLargeTitles { updateFromScroll() }
        layoutSearchBar()
        applyCollapsedBarChrome()
    }

    /// MEASURED Ledger t3000, iPhone SE 2x / iOS 26.1: active bottom search
    /// collapses the bar to height 0 at y = iOSBarTop; title "Ledger" /
    /// "Export" dump as 0. Must run after layoutSearchBar, which would
    /// otherwise unhide the title.
    func applyCollapsedBarChrome() {
        let collapsed = bounds.height < 1
        if collapsed {
            titleLabel.isHidden = true
            titleLabel.alpha = 0
            for v in leftItemViews + rightItemViews {
                v.isHidden = true
                v.alpha = 0
            }
            backButton?.isHidden = true
            largeTitleLabel?.isHidden = true
            promptLabel?.isHidden = true
        } else {
            // Pad trailing search already hid the title in layoutSearchBar
            // (Tabs-ipad t200 / t4000). Don't undo that — Ledger's
            // collapsed-bar restore is phone bottom-dock only.
            if !(UINavigationBar.isPad && hostedSearchBar != nil) {
                titleLabel.isHidden = titleViewHost != nil
            }
            for v in leftItemViews + rightItemViews {
                v.isHidden = false
                v.alpha = 1
            }
            backButton?.isHidden = false
            largeTitleLabel?.isHidden = !displaysLargeTitles
        }
    }

    /// Place the hosted search bar. MEASURED Tabs t200 / t4000, iPhone SE
    /// 2x / iOS 26.1:
    ///   * rest: UISearchBar `[0, 64, 375, 0]` (hidden; bar stays 54 pt)
    ///   * active: search fills the 60 pt bar; field `[16, 18, 288, 44]`
    ///     (bar-local y 8); dismiss `[315, 18, 44, 44]` r=17 (not "Cancel").
    func layoutSearchBar() {
        guard let bar = hostedSearchBar else {
            titleLabel.isHidden = false
            return
        }
        if usesBottomSearch {
            titleLabel.isHidden = false
            titleLabel.alpha = 1
            return
        }
        let active = topItem?.searchController?.isActive == true
            && OpenUIKitRuntime.systemFontCut == .iOS
        bar._navInlineActive = active
        bar._navInactiveSlot = false
        if UINavigationBar.isPad {
            // MEASURED Tabs-ipad t200 / t4000, iPad (A16) 820×1180 @2x /
            // iOS 26.1: rest UISearchBar `[564.969, 31.817, 240, 44]`
            // (trailing inset 15 = 820 − 240 − 565); active **280** wide
            // at `[524.802, 31.817, 280, 44]` (same trailing 15). The
            // inline title is gone — the floating tab bar carries it.
            // Not the phone inline-nav 60 pt overlay (no +6, no dismiss).
            bar._navInlineActive = false
            bar._padTrailingChrome = true
            bar.isHidden = false
            titleLabel.isHidden = true
            titleLabel.alpha = 0
            let w: CGFloat = active ? 280 : 240
            let trailing: CGFloat = 15
            bar.frame = CGRect(x: bounds.width - trailing - w, y: 0,
                               width: w, height: 44)
            bar.setShowsCancelButton(false, animated: false)
            bar.setNeedsLayout()
            bar.layoutIfNeeded()
            return
        }
        if showsInactiveSearchSlot {
            // MEASURED Notes t6000 / Tabs t6000, iPhone SE 2x / iOS 26.1:
            // UISearchBar `[0, 54, 375, 60]` under the 54 pt content
            // (bar 114); field `[16, 1, 343, 44]`, no dismiss. Title stays.
            bar._padTrailingChrome = false
            bar._navInactiveSlot = true
            bar.isHidden = false
            titleLabel.alpha = titleViewHost == nil ? 1 : 0
            let slotH = searchInactiveSlotHeight()
            bar.frame = CGRect(x: 0, y: UINavigationBar.iOSBarContentHeight,
                               width: bounds.width, height: slotH)
            bar.setShowsCancelButton(false, animated: false)
            bar.setNeedsLayout()
            bar.layoutIfNeeded()
            return
        }
        if !active {
            // Tabs t200: UISearchBar `[0, 64, 375, 0]` — height 0 at the
            // bar's bottom edge, not isHidden (the placeholder still dumps).
            bar._padTrailingChrome = false
            bar.isHidden = false
            titleLabel.alpha = titleViewHost == nil ? 1 : 0
            bar.frame = CGRect(x: 0, y: bounds.height, width: bounds.width, height: 0)
            return
        }
        bar.isHidden = false
        bar._padTrailingChrome = false
        titleLabel.alpha = 0
        bar.frame = bounds
        bar.setShowsCancelButton(true, animated: false)
        bar.setNeedsLayout()
        bar.layoutIfNeeded()
    }

    /// Lay the leading / trailing platter groups out at the measured
    /// margins, and place the prompt caption above them.
    func layoutBarItems() {
        // Font before width: `_UIBarItemLayout.width` reads the title
        // label's intrinsic size. MEASURED TableEditor t200.ax1: Edit is
        // **21 pt** `[306.215, 18.817, 36.5, 25.5]` inside a still-44 pt
        // platter, not 17 pt. Set from the bar's traits (window override)
        // so a detached construction layout cannot freeze `.large`.
        if UINavigationBar.isIOS {
            let font = _UIBarMetrics.iOSTitleFont(compatibleWith: traitCollection)
            for v in leftItemViews + rightItemViews {
                v.titleLabel.font = font
            }
        }
        let h = _UIBarMetrics.platterHeight
        let y = itemPlatterY + promptOffset
        var x = _UIBarMetrics.itemSideMargin + backButtonWidth
        for (i, v) in leftItemViews.enumerated() where !v.item._isSpace {
            let w = _UIBarItemLayout.width(of: v)
            x += _UIBarItemLayout.gapBefore(leftItemViews, i)
            v.frame = CGRect(x: x, y: y, width: w, height: h)
            x += w
        }
        // UIKit's order: `rightBarButtonItems[0]` is the TRAILING-most item
        // (measured — a [.edit, "Add"] pair renders "Add" then "Edit").
        var right = bounds.width - _UIBarMetrics.itemSideMargin
        for (i, v) in rightItemViews.enumerated() where !v.item._isSpace {
            let w = _UIBarItemLayout.width(of: v)
            right -= _UIBarItemLayout.gapBefore(rightItemViews, i)
            right -= w
            v.frame = CGRect(x: right, y: y, width: w, height: h)
        }
        // MEASURED NavFlow t200.rtl / TableEditor t200.rtl, iPhone SE 2x /
        // iOS 26.1: leftBarButtonItems are the leading group (Filter at
        // abs.x 31.703, Edit at 31.74 — physical left = trailing). Mirror
        // the LTR packing about the bar width; shared platters follow.
        if _layoutIsRTL {
            let span = bounds.width
            for v in leftItemViews + rightItemViews {
                var f = v.frame
                f.origin.x = span - f.maxX
                v.frame = f
            }
        }
        // iOS 26: runs of adjacent image-only items share one platter.
        let shared = _UIBarItemLayout.sharedPlatterFrames(leftItemViews)
            + _UIBarItemLayout.sharedPlatterFrames(rightItemViews)
        while sharedPlatterViews.count > shared.count { sharedPlatterViews.removeLast().removeFromSuperview() }
        while sharedPlatterViews.count < shared.count {
            let p = _UIBarSharedPlatterView(frame: .zero)
            if let first = (leftItemViews + rightItemViews).first(where: { $0.superview === self }) {
                insertSubview(p, belowSubview: first)
            } else {
                addSubview(p)
            }
            sharedPlatterViews.append(p)
        }
        for (p, f) in zip(sharedPlatterViews, shared) {
            p.frame = f
            p.backdropColor = leftItemViews.first?.backdropColor ?? rightItemViews.first?.backdropColor
            p.isHidden = !(leftItemViews.first?.showsPlatter ?? rightItemViews.first?.showsPlatter ?? true)
        }
        if let l = promptLabel {
            let s = l.intrinsicContentSize
            l.frame = CGRect(x: (bounds.width - s.width) / 2,
                             y: itemPlatterY
                                + (UINavigationBar.promptHeight - s.height) / 2,
                             width: s.width, height: s.height)
        }
    }

    /// Extra top offset the prompt pushes the bar content down by.
    var promptOffset: CGFloat { promptLabel == nil ? 0 : UINavigationBar.promptHeight }

    /// Width the back button reserves at the leading edge.
    var backButtonWidth: CGFloat {
        guard let b = backButton, !b.isHidden else { return 0 }
        return b.sizeThatFits(bounds.size).width
    }

    /// Trailing edge of the leading group (bar coordinates).
    var leadingGroupMaxX: CGFloat {
        _UIBarMetrics.itemSideMargin + backButtonWidth + _UIBarItemLayout.naturalWidth(leftItemViews)
    }

    /// Leading edge of the trailing group.
    var trailingGroupMinX: CGFloat {
        let w = _UIBarItemLayout.naturalWidth(rightItemViews)
        return w == 0 ? bounds.width : bounds.width - _UIBarMetrics.itemSideMargin - w
    }

    /// Centre x for the title: centred, unless centring it would leave less
    /// than `titleGroupClearance` next to either group — then it aligns just
    /// past the leading group (measured; see UINavigationItem.swift).
    var titleCenterX: CGFloat {
        let width = titleViewHost.map {
            $0.bounds.size == .zero ? $0.sizeThatFits(bounds.size).width : $0.bounds.width
        } ?? titleLabel.intrinsicContentSize.width
        let centered = bounds.width / 2
        guard !leftItemViews.isEmpty || !rightItemViews.isEmpty || backButton != nil else {
            return centered
        }
        let clearance = UINavigationBar.titleGroupClearance
        if _layoutIsRTL {
            let leadInner = bounds.width
                - (_UIBarMetrics.itemSideMargin + backButtonWidth
                   + _UIBarItemLayout.naturalWidth(leftItemViews))
            let trailW = _UIBarItemLayout.naturalWidth(rightItemViews)
            let trailOuter = trailW == 0 ? 0 : _UIBarMetrics.itemSideMargin + trailW
            if centered - width / 2 >= trailOuter + clearance,
               centered + width / 2 <= leadInner - clearance {
                return centered
            }
            let leadingIsEmpty = backButton == nil
                && !leftItemViews.contains { !$0.item._isSpace }
            return (leadingIsEmpty ? leadInner : leadInner - _UIBarMetrics.gap)
                - width / 2
        }
        let lead = leadingGroupMaxX
        let trail = trailingGroupMinX
        if centered - width / 2 >= lead + clearance,
           centered + width / 2 <= trail - clearance {
            return centered
        }
        // MEASURED (iOS 26.1, a title beside a wide trailing group and no
        // leading item): the title sits at the side margin itself, x = 16;
        // with a leading group it sits 12 past that group.
        let leadingIsEmpty = backButton == nil && !leftItemViews.contains { !$0.item._isSpace }
        return (leadingIsEmpty ? lead : lead + _UIBarMetrics.gap) + width / 2
    }

    /// Bar-local y of the item platters. Catalyst: 10, inside a 64 pt bar
    /// that includes the top padding. iOS: 0, because the 10 pt floor is
    /// already outside the bar frame (abs y still 10 when pad is 10).
    var itemPlatterY: CGFloat { UINavigationBar.isIOS ? 0 : UINavigationBar.barTopPadding }

    private var contentMidY: CGFloat {
        let base: CGFloat
        if UINavigationBar.isIOS {
            let largeShowing = displaysLargeTitles
                && collapseDistance < effectiveLargeTitleZoneHeight
            base = largeShowing
                ? UINavigationBar.iOSLargeHiddenInlineTitleCenterY
                : UINavigationBar.iOSInlineTitleCenterY
        } else {
            base = UINavigationBar.largeInlineTitleCenterY
        }
        return base + promptOffset
    }

    private func place(title l: UILabel, centerX: CGFloat, alpha: CGFloat) {
        var s = l.intrinsicContentSize
        // iOS 26.1 (MEASURED, navitem_imgw / navitem_dark): the inline title
        // label is a WHOLE-point 21 tall for the 17 pt semibold font (like
        // a plain table header), centred in the 44 pt zone -> y 21.5.
        if UINavigationBar.isIOS { s.height = l.font.lineHeight.rounded(.up) }
        l.bounds = CGRect(x: 0, y: 0, width: s.width, height: s.height)
        l.center = CGPoint(x: centerX, y: contentMidY)
        l.alpha = alpha
    }

    private func place(back b: _UINavigationBarBackButton, alpha: CGFloat,
                       dx: CGFloat = 0) {
        let s = b.sizeThatFits(bounds.size)
        b.bounds = CGRect(x: 0, y: 0, width: s.width, height: s.height)
        // MEASURED NavFlow t3000.rtl, iPhone SE 2x / iOS 26.1: the back
        // control sits on the leading (right) edge. `dx` is the LTR
        // transition slide and is left unflipped (unmeasured in RTL).
        let cx = _layoutIsRTL ? bounds.width - s.width / 2 + dx : s.width / 2 + dx
        b.center = CGPoint(x: cx, y: contentMidY)
        b.alpha = alpha
    }

    // MARK: Transitions (driven by UINavigationController)

    struct BarTransition {
        var push: Bool
        var oldTitle: UILabel
        var oldBack: _UINavigationBarBackButton?
        var newTitle: UILabel
        var newBack: _UINavigationBarBackButton?
        /// iOS cut only: the two translating title groups (see
        /// `setTransitionProgress`). Nil on Catalyst, which keeps the
        /// cross-fade.
        var oldGroup: UIView?
        var newGroup: UIView?
        /// The outgoing / incoming large titles, parented to those groups.
        var oldLarge: UILabel?
        var newLarge: UILabel?
    }
    var transition: BarTransition?

    /// Fraction of the bar width the incoming/outgoing titles slide.
    static let titleSlide: CGFloat = 0.35

    /// Install the incoming elements at progress 0. Call
    /// setTransitionProgress(1) (inside a UIView.animate block for an
    /// animated transition, or repeatedly with intermediate values for
    /// scrubbing), then endTransition().
    func beginTransition(title: String?, backTitle: String?, push: Bool) {
        if transition != nil { endTransition() }
        let newTitle = UINavigationBar.makeTitleLabel(title)
        let newBack = makeBackButton(backTitle)
        var t = BarTransition(push: push, oldTitle: titleLabel,
                              oldBack: backButton, newTitle: newTitle,
                              newBack: newBack)
        if UINavigationBar.isIOS {
            // iOS 26 moves the bar's TITLE CONTENT with its view controller
            // (see setTransitionProgress), so each side needs a container of
            // its own: the outgoing one clips, the incoming one does not.
            let oldGroup = UIView(frame: bounds)
            oldGroup.clipsToBounds = true
            let newGroup = UIView(frame: bounds)
            titleLabel.removeFromSuperview()
            oldGroup.addSubview(titleLabel)
            newGroup.addSubview(newTitle)
            if displaysLargeTitles {
                if let old = largeTitleLabel {
                    old.removeFromSuperview()
                    oldGroup.addSubview(old)
                    t.oldLarge = old
                }
                let l = makeLargeTitleLabel(title)
                // The incoming controller arrives at ITS OWN rest offset, so
                // the new large title starts fully expanded. (A push made
                // while the outgoing controller is scrolled into its
                // large-title zone is not measured — docs/KNOWN_GAPS.md.)
                l.frame = largeTitleFrame(for: l, collapsedBy: 0)
                newGroup.addSubview(l)
                t.newLarge = l
                largeTitleLabel = l
            }
            addSubview(oldGroup)
            addSubview(newGroup)
            t.oldGroup = oldGroup
            t.newGroup = newGroup
            // The back button is NOT in either group: measured (navprobe,
            // both variants, push and pop) the platter's x stays 16.0 at
            // every recorded frame while the titles translate.
            if let b = t.oldBack { bringSubviewToFront(b) }
            if let b = newBack { addSubview(b) }
        } else {
            addSubview(newTitle)
            if let b = newBack { addSubview(b) }
        }
        transition = t
        titleLabel = newTitle
        backButton = newBack
        setTransitionProgress(0)
    }

    /// Position every transition element for progress `p` (0 = old state,
    /// 1 = new state). Pure property sets — records animations when called
    /// inside a UIView.animate block, scrubs the model otherwise.
    func setTransitionProgress(_ p: CGFloat) {
        guard let t = transition else { return }
        if let oldGroup = t.oldGroup, let newGroup = t.newGroup {
            setIOSTransitionProgress(p, t, oldGroup: oldGroup, newGroup: newGroup)
            return
        }
        let w = bounds.width
        let mid = w / 2
        let slide = UINavigationBar.titleSlide * w
        // Where the old title slides to on push: the new back label's center
        // (the old title visually "becomes" the back button).
        let backX: CGFloat = t.newBack?.backTitleCenterX
            ?? t.oldBack?.backTitleCenterX ?? (mid - slide)
        if t.push {
            // Old title: center -> back position, fading out.
            place(title: t.oldTitle, centerX: mid + (backX - mid) * p,
                  alpha: 1 - p)
            // New title: slides in from the incoming (right) side.
            place(title: t.newTitle, centerX: mid + slide * (1 - p), alpha: p)
            // Old back slides a little left and fades out FAST (iOS drops
            // the old back label in the first part of the transition); new
            // back fades in.
            if let b = t.oldBack {
                place(back: b, alpha: Swift.max(0, 1 - 2.5 * p), dx: -0.2 * w * p)
            }
            if let b = t.newBack { place(back: b, alpha: p) }
        } else {
            // Pop: old title slides out right, new title arrives from the
            // back-button position (reverse of the push morph).
            place(title: t.oldTitle, centerX: mid + slide * p, alpha: 1 - p)
            place(title: t.newTitle, centerX: backX + (mid - backX) * p,
                  alpha: p)
            if let b = t.oldBack { place(back: b, alpha: Swift.max(0, 1 - 2.5 * p)) }
            if let b = t.newBack { place(back: b, alpha: p) }
        }
    }

    /// iOS 26's bar transition, MEASURED with Tools/oracle2/navprobe on the
    /// iPhone 16 / iOS 26.1 (390 x 700 container, no top safe area, push at
    /// recorder t 0.50 and pop at 1.50, presentation geometry every display
    /// tick; the numbers below are from `navprobe.large.frames.json` and
    /// `navprobe.inline.frames.json`, which agree):
    ///
    /// The bar does NOT cross-fade its titles. UIKit builds one
    /// `ViewControllerMatchingView` per side and TRANSLATES each with its own
    /// view controller's content view, at opacity 1 throughout:
    ///
    ///   front (the controller on top — incoming on push, outgoing on pop)
    ///       x = w * (1 - q),  width w, unclipped
    ///   back  (the controller underneath, carrying the parallax)
    ///       x = -0.3 * w * q, width w * (1 - 0.7 q), CLIPPED
    ///
    /// where q is the coverage the content views already use. The back side's
    /// width is exactly "up to the front side's leading edge": at q = 0.4587
    /// the recording has the outgoing group at x -53.67 w 264.76 and the
    /// incoming at 211.09, and -53.67 + 264.76 = 211.09. The pop is the same
    /// relation with the roles swapped (q 0.6994: outgoing x 117.25 w 390,
    /// incoming x -81.83 w 199.08 -> right edge 117.25).
    ///
    /// The large title rides along inside the group; it neither fades
    /// (`_UIReplicantView` / `_UIPortalView` opacity 1.000 at every frame)
    /// nor moves vertically (abs y 123.00 at every frame).
    private func setIOSTransitionProgress(_ p: CGFloat, _ t: BarTransition,
                                          oldGroup: UIView, newGroup: UIView) {
        let w = bounds.width
        let h = bounds.height
        // Coverage of the FRONT controller, the same q the content views use.
        let q = t.push ? p : 1 - p
        let frontX = w * (1 - q)
        let backX = -UINavigationController.parallaxFraction * w * q
        let (frontGroup, backGroup) = t.push ? (newGroup, oldGroup) : (oldGroup, newGroup)
        frontGroup.frame = CGRect(x: frontX, y: 0, width: w, height: h)
        backGroup.frame = CGRect(x: backX, y: 0, width: frontX - backX, height: h)
        // Fixed leading position for both back buttons; only the alpha moves.
        if let b = t.oldBack { place(back: b, alpha: Swift.max(0, 1 - 2.5 * p)) }
        if let b = t.newBack { place(back: b, alpha: p) }
    }

    /// Animated transitions: re-record the outgoing back button's fade over
    /// the FIRST 40% of the transition (the piecewise alpha in
    /// setTransitionProgress only shapes interactive scrubs; a UIView.animate
    /// block records a single full-duration lerp). Call right after the main
    /// animation block.
    func accelerateOutgoingBackFade(duration: Double) {
        guard let b = transition?.oldBack else { return }
        b.alpha = 1 // reset the model so the fast fade records 1 -> 0
        UIView.animate(withDuration: duration * 0.4, delay: 0,
                       options: .curveEaseOut, animations: { b.alpha = 0 })
    }

    /// Remove the outgoing elements. `cancelled` keeps the OLD state instead
    /// (interactive pop that snapped back).
    func endTransition(cancelled: Bool = false) {
        guard let t = transition else { return }
        transition = nil
        let (keepTitle, keepBack, dropTitle, dropBack) = cancelled
            ? (t.oldTitle, t.oldBack, t.newTitle, t.newBack)
            : (t.newTitle, t.newBack, t.oldTitle, t.oldBack)
        if let oldGroup = t.oldGroup, let newGroup = t.newGroup {
            // Re-parent the surviving title (and large title) to the bar and
            // drop both translating groups.
            if let large = cancelled ? t.oldLarge : t.newLarge {
                large.removeFromSuperview()
                large.removeAllAnimations()
                largeTitleLabel = large
                addSubview(large)
            }
            keepTitle.removeFromSuperview()
            addSubview(keepTitle)
            oldGroup.removeFromSuperview()
            newGroup.removeFromSuperview()
        }
        dropTitle.removeFromSuperview()
        dropBack?.removeFromSuperview()
        titleLabel = keepTitle
        backButton = keepBack
        keepTitle.removeAllAnimations()
        keepBack?.removeAllAnimations()
        setNeedsLayout()
        layoutIfNeeded()
    }

    // MARK: Large titles (M10)

    /// A large-title label carrying `text`, styled from the effective
    /// appearance (`applyTitleAttributes` re-styles the installed one).
    func makeLargeTitleLabel(_ text: String?) -> UILabel {
        let l = UILabel()
        l.text = text
        l.font = UINavigationBar.isIOS
            ? UINavigationBar.iOSLargeTitleFont(compatibleWith: traitCollection)
            : .systemFont(ofSize: UINavigationBar.largeTitleFontSize, weight: .bold)
        l.textColor = .label
        return l
    }

    /// Where `label` sits as the large title for a collapse distance of `d`.
    func largeTitleFrame(for label: UILabel, collapsedBy d: CGFloat) -> CGRect {
        let w = Swift.min(label.intrinsicContentSize.width,
                           bounds.width - 2 * UINavigationBar.largeTitleX)
        // MEASURED NavFlow t200.rtl / TableEditor t200.rtl, iPhone SE 2x /
        // iOS 26.1: "Library" abs.x 247.5 = 375 − 16 − 111.5; "Reminders"
        // 189 = 375 − 16 − 170.
        let x = _layoutIsRTL
            ? bounds.width - UINavigationBar.largeTitleX - w
            : UINavigationBar.largeTitleX
        return CGRect(x: x,
                      y: effectiveLargeTitleLabelY - d,
                      width: w,
                      height: effectiveLargeTitleLabelHeight)
    }

    func configureLargeTitleAppearance() {
        if displaysLargeTitles {
            backgroundColor = nil            // iOS 26: transparent at rest
            hairline.isHidden = true
            let l = makeLargeTitleLabel(titleLabel.text)
            largeTitleLabel?.removeFromSuperview()
            largeTitleLabel = l
            addSubview(l)
            pocketView.isHidden = true
            insertSubview(pocketView, at: 0)   // beneath both titles
        } else {
            largeTitleLabel?.removeFromSuperview()
            largeTitleLabel = nil
            pocketView.removeFromSuperview()
            trackedScrollView = nil
        }
        applyAppearance()
        setNeedsLayout()
    }

    /// Collapse progress: how far the tracked offset has moved past the
    /// expanded rest offset (0 = fully expanded; >= largeTitleZoneHeight =
    /// collapsed, inline title showing).
    var collapseDistance: CGFloat {
        guard let s = trackedScrollView else { return 0 }
        return s.contentOffset.y + effectiveLargeTitleExpandedInset
    }

    /// Overlay height the navigation controller should give this bar in
    /// large-title mode. iOS shrinks the BAR FRAME at the zone boundary
    /// (106 → 54); Catalyst keeps the 116 pt overlay for the whole collapse.
    var largeTitleOverlayHeight: CGFloat {
        guard UINavigationBar.isIOS else {
            return UINavigationBar.largeTitleExpandedInset(compatibleWith: traitCollection)
        }
        if UINavigationBar.isCompactHeight {
            return UINavigationBar.iOSBarContentHeight
        }
        if collapseDistance >= effectiveLargeTitleZoneHeight {
            return UINavigationBar.iOSCollapsedBarHeight
        }
        var h = effectiveLargeTitleBarHeight
        // MEASURED Feed t700, iPhone SE 2x / iOS 26.1: programmatic
        // beginRefreshing while overscrolled stretches the large-title bar
        // 106 → 166 (the refresh control's 60 pt). contentInset stays
        // [0,0,0,0]; adjustedContentInset.top 116 → 176.
        if let rc = trackedScrollView?._refreshControl, rc.isRefreshing,
           collapseDistance < 0 {
            h += UIRefreshControl.controlHeight
        }
        return h
    }

    /// Position/fade the large + inline titles for the current tracked
    /// offset, and refresh the scroll-edge pocket. Called from
    /// layoutSubviews and from every observed scroll.
    func updateFromScroll() {
        // A bar mid-transition is driven by setTransitionProgress: the two
        // large titles belong to their groups, and the tracked scroll view is
        // still the OUTGOING controller's, so a scroll event arriving during
        // the transition would move the INCOMING title by the outgoing
        // offset. `layoutSubviews` already stands back for the same reason.
        guard displaysLargeTitles, transition == nil else { return }
        // MEASURED NavFlow t200.ax1, iPhone SE 2x / iOS 26.1: "Library"
        // large title `[16, 64, 156, 57.5]` at 48 pt Bold. The label is
        // created in `configureLargeTitleAppearance` before the bar joins
        // the window (NavFlow sets `prefersLargeTitles` in `makeRoot`), so
        // construction-time `traitCollection` is `.large` (34 pt, width
        // 111.5). Re-style from the inherited window `traitOverrides`.
        applyTitleAttributes()
        let d = collapseDistance
        let collapsed = d >= effectiveLargeTitleZoneHeight
        if let l = largeTitleLabel {
            l.frame = largeTitleFrame(for: l, collapsedBy: d)
            if UINavigationBar.isIOS {
                // MEASURED 2026-09-04, Tools/oracle2/navprobe scroll pass
                // (variant "scroll"), iPhone 16 / iOS 26.1, rest samples at
                // d = 0, 10, 12, …, 51, 52, 80, 200:
                //   * large-title wrapper y = 67.667 − d (1:1 with offset)
                //   * font stays .SFUI-Bold 34, identity transform
                //   * `_UINavigationBarLargeTitleView` opacity = 1 through
                //     d = 51, then 0 at d = 52
                //   * inline `HostedViewWrapper` opacity = 0 through d = 51,
                //     then 1 at d = 52
                // Catalyst keeps the smoothstep cross-fade (d−20)/32 and
                // (d−30)/26 measured off the Mac oracle.
                l.alpha = collapsed ? 0 : 1
            } else {
                l.alpha = 1 - smoothstep01((d - 20) / 32)
            }
        }
        if UINavigationBar.isIOS {
            titleLabel.alpha = collapsed ? 1 : 0
        } else {
            titleLabel.alpha = smoothstep01((d - 30) / 26)
        }
        if UINavigationBar.isIOS {
            let h = largeTitleOverlayHeight
            if abs(bounds.height - h) > 0.5 {
                _controller?.updateContainerLayout()
            }
        }
        updatePocket()
    }

    /// In large-title mode the bar is transparent chrome floating over the
    /// content — only its interactive elements (back button) take touches;
    /// everything else falls through to the content below.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard displaysLargeTitles else { return super.hitTest(point, with: event) }
        if let b = backButton, !b.isHidden,
           let hit = b.hitTest(b.convert(point, from: self), with: event) {
            return hit
        }
        return nil
    }

    // MARK: Scroll-edge-effect pocket (iOS 26)
    //
    // When content slides under the bar region, iOS 26 renders it inside a
    // progressive-blur "pocket": heavily blurred, washed toward the
    // background color (strongest at the top edge), fading out below the
    // inline bar zone. Reproduced by snapshotting the content container
    // (UIRenderer on the scroll view's superview — the bar is NOT part of
    // that subtree), then blur + wash + vertical alpha ramp, tuned against
    // golden/navbar_inline.

    /// Pocket region height (bar zone 64 pt + soft falloff).
    static let pocketHeight: CGFloat = 72
    /// Gaussian sigma for the pocket blur, in points.
    /// Catalyst keeps 8 (tuned against golden/navbar_inline).
    /// iOS 26.1 (MEASURED 2026-09-04, probe_scroll_edge_white, iPhone SE 2x):
    /// a red|green column edge under the collapsed bar has a 5 pt 10–90 %
    /// mix at y = 8…20 (the inline-title band); erf fit σ = 1.85
    /// (rms 1.1). Feed t2800's 8 pt kernel turned "Morning briefing" into a
    /// 245 cloud vs iOS 233 and spread the 1 pt card sliver 12 pt down.
    static var pocketBlurSigma: CGFloat { isIOS ? 1.85 : 8 }
    /// Background wash: plateau strength, plateau end and wash end (pt).
    static let pocketWashTop: CGFloat = 0.82
    static let pocketWashPlateau: CGFloat = 24
    static let pocketWashEnd: CGFloat = 64
    static let pocketWashBottom: CGFloat = 0.10
    /// Alpha ramp: fully opaque until `pocketFadeStart`, 0 at pocketHeight.
    static let pocketFadeStart: CGFloat = 56

    func updatePocket() {
        guard displaysLargeTitles, let scroll = trackedScrollView,
              let content = scroll.superview, bounds.width > 0 else {
            pocketView.isHidden = true
            pocketKey = nil
            return
        }
        // Engagement: nothing to blur until content actually reaches under
        // the bar zone (d = 52 puts the content top exactly at the zone's
        // bottom edge); ramp in over the next 28 pt.
        // iOS 26.1 (MEASURED, navprobe scroll): `ScrollEdgeEffectView`
        // opacity flips 0 → 1 at d = 12, but that is a glass material
        // whose fill over grouped background is 242/247 — not this
        // content-blur pocket. Turning the pocket on at 12 would sit on
        // the still-visible 34 pt title (alpha 1 through d = 51).
        let e = clamp01((collapseDistance - effectiveLargeTitleZoneHeight) / 28)
        guard e > 0 else {
            pocketView.isHidden = true
            pocketKey = nil
            return
        }
        let key = (offsetY: scroll.contentOffset.y, width: bounds.width,
                   engagement: e)
        if let k = pocketKey, k == key {
            pocketView.isHidden = false
            layoutPocketView()
            return
        }
        pocketKey = key
        let scale = max(UITraitCollection.current.displayScale, 1)
        content.layoutIfNeeded()
        let snapshot = UIRenderer.render(content, scale: scale)
        // MEASURED Feed t2800.dark, SE 2x / iOS 26.1: the iOS nav container
        // is `backgroundColor = nil`, so the ancestor walk misses and the
        // previous `.white` fallback washed the collapsed large-title strip
        // to (209–230) against a golden near-black (0, 0, 0) pocket.
        // `.systemBackground` is white in light (navbar_inline / Feed t2800
        // unchanged) and black in dark.
        let bg = (backgroundColorForPocket ?? .systemBackground).cgColor
        let bitmap = UINavigationBar.pocketBitmap(from: snapshot, scale: scale,
                                                 background: bg)
        pocketView.image = UIImage(bitmap: bitmap, scale: scale)
        layoutPocketView()
        pocketView.alpha = e
        pocketView.isHidden = false
    }

    /// Place the 72 pt pocket so it covers from the container origin.
    ///
    /// MEASURED 2026-09-04, suite golden `navbar_inline` (SE 2x / iOS 26.1,
    /// large title collapsed at contentOffset 160): `ScrollEdgeEffectView`
    /// is `[0, 0, 375, 118.8]` in the scroll view — it starts at the
    /// container origin, not at `bar.frame.minY`. The port's pocket is a
    /// bar subview; on the iOS cut the bar sits at
    /// `y = max(SA.top, 10)`, so the pocket is offset by `-bar.y` to keep
    /// covering window `[0, 72]` (the coverage the scene scored before the
    /// origin rule). Catalyst's bar is still at y 0, so the offset is 0.
    func layoutPocketView() {
        let y = UINavigationBar.isIOS ? -frame.minY : 0
        pocketView.frame = CGRect(x: 0, y: y, width: bounds.width,
                                  height: UINavigationBar.pocketHeight)
    }

    /// The color the pocket washes toward: the nearest opaque ancestor
    /// background (the navigation container view), resolved for the
    /// current style. On the iOS cut the container is nil, so the
    /// caller falls back to `.systemBackground` (Feed t2800.dark).
    var backgroundColorForPocket: UIColor? {
        var v: UIView? = superview
        while let cur = v {
            if let c = cur.backgroundColor, c.cgColor.alpha >= 1 {
                return c.resolvedColor(with: UITraitCollection.current)
            }
            v = cur.superview
        }
        return nil
    }

    /// Blur + wash + fade the top of `src` into the pocket bitmap.
    static func pocketBitmap(from src: Bitmap, scale: CGFloat,
                             background: CGColor) -> Bitmap {
        let w = src.width
        let outH = min(Int((pocketHeight * scale).rounded()), src.height)
        let sigma = pocketBlurSigma * scale
        let radius = max(1, Int((sigma * 2.5).rounded()))
        // Gaussian taps.
        var taps = Array<CGFloat>(repeating: 0, count: 2 * radius + 1)
        var sum: CGFloat = 0
        for i in -radius...radius {
            let t = CGFloat(i) / sigma
            let v = CGFloat(_expApprox(-0.5 * Double(t * t)))
            taps[i + radius] = v
            sum += v
        }
        for i in taps.indices { taps[i] /= sum }

        func b8(_ v: CGFloat) -> CGFloat { max(0, min(255, v)) }
        let bgR = background.red * 255, bgG = background.green * 255,
            bgB = background.blue * 255

        // Composite the (straight-alpha) snapshot over the background color
        // so the blur operates on opaque RGB.
        let workH = min(outH + radius, src.height)
        var flat = Array<CGFloat>(repeating: 0, count: w * workH * 3)
        src.pixels.withUnsafeBufferPointer { px in
            for y in 0..<workH {
                for x in 0..<w {
                    let o = (y * w + x) * 4
                    let a = CGFloat(px[o + 3]) / 255
                    let f = (y * w + x) * 3
                    flat[f] = CGFloat(px[o]) * a + bgR * (1 - a)
                    flat[f + 1] = CGFloat(px[o + 1]) * a + bgG * (1 - a)
                    flat[f + 2] = CGFloat(px[o + 2]) * a + bgB * (1 - a)
                }
            }
        }
        // Horizontal pass (clamped edges).
        var hpass = Array<CGFloat>(repeating: 0, count: w * workH * 3)
        for y in 0..<workH {
            for x in 0..<w {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                for i in -radius...radius {
                    let sx = min(max(x + i, 0), w - 1)
                    let f = (y * w + sx) * 3
                    let t = taps[i + radius]
                    r += flat[f] * t; g += flat[f + 1] * t; b += flat[f + 2] * t
                }
                let o = (y * w + x) * 3
                hpass[o] = r; hpass[o + 1] = g; hpass[o + 2] = b
            }
        }
        // Vertical pass + wash + alpha ramp into the output bitmap.
        let out = Bitmap(width: w, height: outH)
        for y in 0..<outH {
            let yPt = CGFloat(y) / scale
            // Wash weight: plateau, then linear falloff.
            let wash: CGFloat
            if yPt <= pocketWashPlateau {
                wash = pocketWashTop
            } else if yPt >= pocketWashEnd {
                wash = pocketWashBottom
            } else {
                let t = (yPt - pocketWashPlateau) / (pocketWashEnd - pocketWashPlateau)
                wash = pocketWashTop + (pocketWashBottom - pocketWashTop) * t
            }
            let alpha = 1 - clamp01((yPt - pocketFadeStart)
                                    / (pocketHeight - pocketFadeStart))
            for x in 0..<w {
                var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0
                for i in -radius...radius {
                    let sy = min(max(y + i, 0), workH - 1)
                    let f = (sy * w + x) * 3
                    let t = taps[i + radius]
                    r += hpass[f] * t; g += hpass[f + 1] * t; b += hpass[f + 2] * t
                }
                r += (bgR - r) * wash
                g += (bgG - g) * wash
                b += (bgB - b) * wash
                let o = (y * w + x) * 4
                out.pixels[o] = UInt8(b8(r).rounded())
                out.pixels[o + 1] = UInt8(b8(g).rounded())
                out.pixels[o + 2] = UInt8(b8(b).rounded())
                out.pixels[o + 3] = UInt8((alpha * 255).rounded())
            }
        }
        return out
    }
}

/// exp() without Foundation: e^x via the standard library's power series is
/// unavailable, so use repeated squaring of e^(x / 2^k) with a short series.
/// Accurate to ~1e-6 over the pocket-kernel range (x in [-8, 0]).
func _expApprox(_ x: Double) -> Double {
    if x < -30 { return 0 }
    // e^x = (e^(x/16))^16; |x/16| <= ~0.5 -> 7-term Taylor is plenty.
    let t = x / 16
    var term = 1.0, sum = 1.0
    for i in 1...7 {
        term *= t / Double(i)
        sum += term
    }
    var r = sum
    for _ in 0..<4 { r *= r }
    return r
}

func smoothstep01(_ t: CGFloat) -> CGFloat {
    let c = clamp01(t)
    return c * c * (3 - 2 * c)
}

// MARK: - UINavigationBarDelegate

/// UIKit's protocol (all members optional there; defaults here answer
/// `true` / do nothing). Delivery order and veto semantics are measured
/// above `UINavigationBar.pushItem` / `popItem` / `setItems`; the
/// controller-managed bar's delivery is in UINavigationController.swift.
///
/// Signal-iOS demand (2 uses): `OWSNavigationController` (a
/// `UINavigationController` subclass) implements `navigationBar(_:shouldPop:)`
/// to cancel back presses; `MediaPageViewController` implements
/// `shouldPop` (dismisses, returns false) and `didPop`.
@preconcurrency @MainActor
public protocol UINavigationBarDelegate: UIBarPositioningDelegate {
    func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool
    func navigationBar(_ navigationBar: UINavigationBar, didPush item: UINavigationItem)
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool
    func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem)
}

public extension UINavigationBarDelegate {
    func navigationBar(_ navigationBar: UINavigationBar, shouldPush item: UINavigationItem) -> Bool { true }
    func navigationBar(_ navigationBar: UINavigationBar, didPush item: UINavigationItem) {}
    func navigationBar(_ navigationBar: UINavigationBar, shouldPop item: UINavigationItem) -> Bool { true }
    func navigationBar(_ navigationBar: UINavigationBar, didPop item: UINavigationItem) {}
}
