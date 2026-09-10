// UITabBar. Owner: viewcontroller module (M10 chrome).
//
// iOS 26 "liquid glass" floating tab bar, metrics measured from the real-
// UIKit goldens (golden/tabbar_basic, golden/tabbar_tinted — oracle2 real
// window, compact width, 375 pt scene):
//   - The bar OWNS the bottom 72 pt of its controller's view and is
//     otherwise transparent (content shows through around the platter).
//   - Floating platter: height 62 pt, 10 pt bottom margin, width
//     n·85.75 + 16.75 for n items (274 pt at n = 3), centered. iOS-cut
//     light uses `_UIGlassMaterial` (σ=2.25, α=222/255 over the content).
//     Dark iOS uses the bar mix (σ=2.25, α=190/255, T=19/190; MEASURED
//     /tmp/glass-dark-out). Catalyst keeps the measured flats (249 light /
//     19 dark).
//   - Selected item: #EBEBEC capsule (height 53.5, item pitch + 7.75 wide,
//     4.25 pt vertical inset in the platter) behind icon + title, both
//     drawn in the bar's tint (measured default tint (52, 124, 238) — NOT
//     systemBlue; iOS 26 tab tint is its own color).
//   - Unselected items: near-black #191919 icon + title.
//   - Icon centered at platter-local y = 24; title ~10 pt semibold centered
//     at platter-local y = 44.5.
//
// Items carry template-style images: whatever pixels the UIImage has, only
// its alpha channel is used — the icon is flattened to the item's current
// color (selected tint / unselected near-black), like UIKit's
// .alwaysTemplate rendering in a tab bar.
//
// KNOWN GAP: dark-mode red chroma of the bar mix is outside the
// two-unknown gray fit (probe (157, 13, 16) vs pred (84, 33, 34)).

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
public class UITabBarItem {
    public var title: String? {
        didSet { _bar?.setNeedsLayout() }
    }
    public var image: UIImage?
    public var tag: Int
    /// Badge text drawn on the item's icon. `nil` / `""` hides it.
    /// The bar reads this from `_UITabBarItemView.layoutSubviews`.
    public var badgeValue: String? {
        didSet { _bar?.setNeedsLayout() }
    }
    weak var _bar: UITabBar?

    public init(title: String?, image: UIImage?, tag: Int) {
        self.title = title
        self.image = image
        self.tag = tag
    }
}

@preconcurrency @MainActor
public protocol UITabBarDelegate: AnyObject {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
}

/// One item slot: tinted icon + title, tap → selection. All drawing state
/// (tint) is pushed in by the bar.
@preconcurrency @MainActor
final class _UITabBarItemView: UIControl {
    let item: UITabBarItem
    let iconView = UIImageView()
    let titleLabel = UILabel()
    let badgeView = UIView()
    let badgeLabel = UILabel()

    init(item: UITabBarItem) {
        self.item = item
        super.init(frame: .zero)
        isOpaque = false
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: UITabBar.titleFontSize,
                                      weight: .semibold)
        titleLabel.textAlignment = .center
        addSubview(iconView)
        addSubview(titleLabel)
        badgeView.isHidden = true
        badgeView.clipsToBounds = true
        addSubview(badgeView)
        badgeLabel.textAlignment = .center
        badgeLabel.textColor = .white
        badgeView.addSubview(badgeLabel)
    }

    @available(*, unavailable, message: "tab-bar item views require a UITabBarItem")
    required init?(coder: NSCoder) {
        fatalError("tab-bar item views cannot be decoded")
    }

    /// Recolor icon + title. The icon is the item image's alpha channel
    /// flattened to `color` (template rendering).
    ///
    /// iOS 26 tab buttons dump `preferredSymbolConfiguration =
    /// pointSize=18, weight=Medium, scale=Large` (symbolinkprobe, SE 2x).
    /// Selected items keep the same symbol name — MEASURED t2000 golden
    /// clock crop vs harvested masks, SE 2x / iOS 26.1: outline `clock`
    /// coverage corr 0.999997, `clock.fill` 0.34. `calendar.fill` is nil
    /// on iOS 26.1. Catalyst keeps the raw item image.
    func apply(color: UIColor, selected: Bool) {
        titleLabel.textColor = color
        iconView.image = UITabBar.resolvedItemImage(item, selected: selected)
            .map { UITabBar.templateImage($0, tint: color) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Title can change after the item view is built. MEASURED
        // /tmp/tabs-t2000-probe + Tabs t2000, iPhone SE 2x / iOS 26.1:
        // `nav.tabBarItem = "Search"` at setViewControllers, then
        // `child.title = "Library"` in viewDidLoad; golden first-tab
        // label is "Library" `[84, 623, 36, 12]`, not "Search"
        // `[84.5, 623, 35, 12]`. Re-read every pass.
        titleLabel.text = item.title
        if UITabBar.isPad {
            // MEASURED Tabs-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1:
            // `_UIFloatingTabBar` items are title-only 36 pt pills (no
            // 18 pt SF Symbol), 17 pt body labels height 20.5 at local y 8.
            iconView.isHidden = true
            titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
            let t = titleLabel.intrinsicContentSize
            titleLabel.frame = CGRect(
                x: UITabBar.padItemTitleInset,
                y: (bounds.height - t.height) / 2,
                width: t.width, height: t.height)
            layoutBadge()
            return
        }
        if UITabBar.isCompactHeight {
            // MEASURED Tabs t200.landscape / t2000.landscape, iPhone SE 2x
            // / iOS 26.1: compact-height `_UITabButton` is icon+title
            // inline in a 36 pt pill. Selected title `.SFUI-Semibold` 12
            // (Library `[35, 11, 42, 14.5]`); unselected `.SFUI-Regular`
            // 12 (Scroll `[34.5, 11, 32, 14.5]`). Icon at x=6, title at
            // icon.maxX+8, both vertically centred in 36.
            iconView.isHidden = false
            titleLabel.textAlignment = .left
            let selected = item._bar?.selectedItem === item
            titleLabel.font = .systemFont(ofSize: UITabBar.compactTitleFontSize,
                                          weight: selected ? .semibold : .regular)
            let size = UITabBar.compactIconSize(for: iconView.image)
            let iconY = (bounds.height - size.height) / 2
            iconView.frame = CGRect(x: UITabBar.compactIconLeading, y: iconY,
                                    width: size.width, height: size.height)
            let t = titleLabel.intrinsicContentSize
            titleLabel.frame = CGRect(
                x: UITabBar.compactIconLeading + size.width
                    + UITabBar.compactIconTitleGap,
                y: UITabBar.compactTitleY,
                width: t.width, height: t.height)
            layoutBadge()
            return
        }
        iconView.isHidden = false
        titleLabel.textAlignment = .center
        titleLabel.font = .systemFont(ofSize: UITabBar.titleFontSize,
                                      weight: .semibold)
        let size = iconView.image?.size ?? .zero
        iconView.frame = CGRect(x: (bounds.width - size.width) / 2,
                                y: UITabBar.iconCenterY - size.height / 2,
                                width: size.width, height: size.height)
        let t = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(x: (bounds.width - t.width) / 2,
                                  y: UITabBar.titleCenterY - t.height / 2,
                                  width: t.width, height: t.height)
        layoutBadge()
    }

    /// MEASURED Tabs t200, iPhone SE 2x / iOS 26.1: `_UIBarBadgeView`
    /// `[196.5, 590, 20, 20]` (button-local `[55.5, 2]` on the 94×54
    /// Tools button at `[141, 588]`), cornerRadius 10, fill (255, 56, 60)
    /// = the captured `systemRed`. The "3" is 13 pt regular in a 12×16
    /// label at badge-local `[4, 2]`. Origin vs icon centre: x = iconCenterX
    /// + 8.5, y = 6 in the 62 pt platter item view.
    func layoutBadge() {
        let value = item.badgeValue ?? ""
        if value.isEmpty {
            badgeView.isHidden = true
            return
        }
        badgeView.isHidden = false
        badgeLabel.text = value
        if UITabBar.isPad {
            // MEASURED Tabs-ipad t200: badge `[436.5, 34, 18.5, 18.5]` on
            // the Tools cell `[378.5, 36, 73.5, 36]` — 18.5 square, origin
            // at the title's trailing edge, 2 pt above the cell (bar y 34
            // vs cell y 36). Digit 13 pt regular, same as the phone badge.
            let size = UITabBar.padBadgeSize
            badgeLabel.font = .systemFont(ofSize: UITabBar.badgeFontSizeIOS, weight: .regular)
            badgeView.backgroundColor = UITabBar.badgeColor
            badgeView.layer.cornerRadius = size / 2
            badgeView.frame = CGRect(x: titleLabel.frame.maxX, y: -2,
                                     width: size, height: size)
            badgeLabel.textAlignment = .center
            badgeLabel.frame = CGRect(x: 4, y: 2, width: 10.5, height: 14.5)
            return
        }
        if UITabBar.isCompactHeight {
            // MEASURED Tabs t200.landscape, iPhone SE 2x / iOS 26.1:
            // `_UIBarBadgeView [59.5, 0, 16, 16]` r=8 on the Tools button
            // `[94.5, 4, 76.5, 36]` → x = width − 16 − 1. Digit
            // `.SFUI-Medium` 10 in `[4, 2, 8, 12]` (label abs.x 363).
            let size = UITabBar.compactBadgeSize
            badgeLabel.font = .systemFont(ofSize: UITabBar.compactBadgeFontSize,
                                          weight: .medium)
            badgeView.backgroundColor = UITabBar.badgeColor
            badgeView.layer.cornerRadius = size / 2
            badgeView.frame = CGRect(x: bounds.width - size - 1, y: 0,
                                     width: size, height: size)
            badgeLabel.textAlignment = .center
            badgeLabel.frame = UITabBar.compactBadgeLabelFrame
            return
        }
        let size = UITabBar.isIOS ? UITabBar.badgeSizeIOS : UITabBar.badgeHeight
        let fontSize = UITabBar.isIOS ? UITabBar.badgeFontSizeIOS : UITabBar.badgeFontSize
        badgeLabel.font = .systemFont(ofSize: fontSize, weight: .regular)
        badgeView.backgroundColor = UITabBar.badgeColor
        badgeView.layer.cornerRadius = size / 2
        let iconCenterX = bounds.width / 2
        let x: CGFloat
        let y: CGFloat
        if UITabBar.isIOS {
            x = iconCenterX + UITabBar.badgeOriginXFromIconCenter
            y = UITabBar.badgeOriginYInPlatter
        } else {
            x = iconView.frame.maxX - size / 2
            y = iconView.frame.minY - size / 2
        }
        badgeView.frame = CGRect(x: x, y: y, width: size, height: size)
        if UITabBar.isIOS {
            // Tabs t200: the "3" label is `[200.5, 592, 12, 16]` inside
            // `_UIBarBadgeView` `[196.5, 590, 20, 20]` → badge-local
            // `[4, 2, 12, 16]`. Intrinsic of our 13 pt "3" is 8.5×16 —
            // the dump reports the label bounds, not the glyph ink.
            badgeLabel.textAlignment = .center
            badgeLabel.frame = CGRect(x: 4, y: 2, width: 12, height: 16)
        } else {
            let text = badgeLabel.intrinsicContentSize
            badgeLabel.frame = CGRect(x: (size - text.width) / 2,
                                      y: (size - text.height) / 2,
                                      width: text.width, height: text.height)
        }
    }
}

@preconcurrency @MainActor
public final class UITabBar: UIView {
    // MARK: Golden-measured metrics (see file header)

    /// Height of the bar's region at the bottom of the controller view.
    // The Catalyst-window numbers (file header) and, under the iOS cut, the
    // iPhone 16 / iOS 26.1 simulator's, MEASURED 2026-09-04
    // (scripts/ios_suite.sh tabbar_basic, post-layout dump + pixels, 375 pt,
    // 3 items): bar 83 tall (49 + the 34 pt home-indicator area), platter
    // [51, 0, 274, 62] at the bar's top, buttons 94 wide on an 86 pt pitch
    // starting 4 in, selection capsule = the button rect (94 x 54, y 4),
    // icon 24 x 24 at y 8, title 10 pt at y 35 (12 tall); platter
    // (249, 249, 249), capsule (230, 230, 230), unselected (25, 25, 25),
    // selected icon (0, 124, 243).
    static var isIOS: Bool { OpenUIKitRuntime.systemFontCut == .iOS }
    /// iOS cut AND pad idiom. Guard for the iPad (A16) top tab bar
    /// (Tabs-ipad t200, 820×1180 @2x). Phone goldens stay on the 83 pt
    /// bottom bar.
    static var isPad: Bool {
        isIOS && (UITraitCollection.current.userInterfaceIdiom == .pad
                  || UIDevice.current.userInterfaceIdiom == .pad)
    }
    /// iOS cut AND compact vertical size class on phone. MEASURED Tabs
    /// t200.landscape dump `screen.verticalSizeClass` = 1 on iPhone SE 2x
    /// / iOS 26.1. Pad keeps the 44 pt top strip; unspecified (portrait
    /// suite / Catalyst) does not count.
    static var isCompactHeight: Bool {
        isIOS && !isPad
            && UITraitCollection.current.verticalSizeClass == .compact
    }
    public static var barHeight: CGFloat {
        if isPad { return 44 }
        if isCompactHeight { return compactBarHeight }
        return isIOS ? 83 : 72
    }
    /// MEASURED Tabs t200.landscape, iPhone SE 2x / iOS 26.1: `UITabBar
    /// [0, 311, 667, 64]`, table `safeAreaInsets.bottom` **64**.
    static let compactBarHeight: CGFloat = 64
    /// Bottom `ScrollEdgeEffectView` overshoot above the bar.
    /// MEASURED Tabs t2000, iPhone SE 2x / iOS 26.1: pocket
    /// `[0, 519.2, 375, 147.8]` = bar 83 + **64.8**. Compact
    /// t2000.landscape `[0, 246.2, 667, 128.8]` = 64 + **64.8**.
    static let bottomEdgeOvershoot: CGFloat = 64.8
    /// Mix target T for the portrait-light pocket.
    /// MEASURED Tabs t2000 dump: BackdropView is white α=0.85. Painting
    /// that wash (T=255 or a T=247 invert of yellow at x=30) dropped
    /// Notes t5000 **98.818 → 97.237** (T=247) / **92.007** (T=255) —
    /// grouped cards are not 255, and no single T fits yellow scroll
    /// blocks and Notes cards. Light pocket paints nothing.
    static let bottomEdgeLightTint: CGFloat = 1.0
    /// Compact-height BackdropView. MEASURED t2000.landscape dump:
    /// `BackdropView` **alpha 0** / `popacity` 0.151. A T=82 mix
    /// inverted from red at x=30 is glass-over-content, not this
    /// pocket (painting it dropped t200.landscape 97.70 → 80.47).
    static let bottomEdgeCompactTint: CGFloat = 0
    /// Light pocket paints nothing (see `bottomEdgeLightTint`). Compact
    /// BackdropView α=0. Dark uses `bottomEdgeDarkStops`.
    static let bottomEdgeLightStops: [(CGFloat, CGFloat)] = [
        (0.00, 0), (1.00, 0)
    ]
    /// Dark portrait: multiply toward black. MEASURED t2000.dark x=30
    /// yellow → (97, 71, 26) at y=644, ratio 0.40 on all three
    /// channels (α=0.598). BackdropView `alpha` 0.6, bg white — the
    /// visible is LuminanceAdjustment, not that white fill.
    static let bottomEdgeDarkStops: [(CGFloat, CGFloat)] = [
        (0.00, 0), (0.20, 0.014), (0.30, 0.060), (0.41, 0.175),
        (0.52, 0.331), (0.63, 0.484), (0.74, 0.570), (0.84, 0.598),
        (1.00, 0.57)
    ]
    /// Compact pocket paints nothing. MEASURED t2000.landscape
    /// BackdropView α=0; the view still occupies `[0, 246.2, 667, 128.8]`.
    static let bottomEdgeCompactStops: [(CGFloat, CGFloat)] = [
        (0.00, 0), (1.00, 0)
    ]
    /// MEASURED Tabs t200.landscape: `_UITabBarPlatterView [205, 0, 257.5, 44]`.
    static let compactPlatterHeight: CGFloat = 44
    /// MEASURED Tabs t200.landscape: `_UITabButton [4, 4, 86.5, 36]`.
    static let compactItemHeight: CGFloat = 36
    static let compactItemY: CGFloat = 4
    /// 4 pt around and between packed items: 4+86.5+4+76.5+4+78.5+4 = 257.5.
    static let compactItemSidePad: CGFloat = 4
    static let compactIconLeading: CGFloat = 6
    static let compactIconTitleGap: CGFloat = 8
    /// Packing uses 12 pt **regular** intrinsic. MEASURED unselected
    /// Scroll: 6+20.5+8+32+12 = 78.5. Selected semibold does not widen
    /// the button (Library regular 39.5 → 86.5, semibold label 42 sits
    /// in the same pill).
    static let compactItemTrailing: CGFloat = 12
    static let compactTitleFontSize: CGFloat = 12
    static let compactTitleY: CGFloat = 11
    static let compactBadgeSize: CGFloat = 16
    static let compactBadgeFontSize: CGFloat = 10
    static let compactBadgeLabelFrame = CGRect(x: 4, y: 2, width: 8, height: 12)
    /// Gap below the 44 pt top bar for a child that is not inside a
    /// UINavigationController. MEASURED Tabs-ipad t1000 / t2000: Tools
    /// toolbar and Scroll view sit at y **96** = SA.top 32 + bar 44 + **20**.
    static let padContentGapBelowBar: CGFloat = 20
    /// Pad item pill height inside the 44 pt bar. MEASURED Tabs-ipad t200:
    /// `_UIFloatingTabBarItemCell [291.5, 36, 87, 36]` (bar-local y 4).
    static let padItemHeight: CGFloat = 36
    static let padItemYInBar: CGFloat = 4
    /// Horizontal title inset inside a pad item. MEASURED Tabs-ipad t200:
    /// Tools cell `[378.5, 36, 73.5, 36]`, title `[394.5, 44, 41.5, 20.5]`
    /// → inset **16**.
    static let padItemTitleInset: CGFloat = 16
    /// Pad badge. MEASURED Tabs-ipad t200: `_UIBarBadgeView [436.5, 34, 18.5, 18.5]`.
    static let padBadgeSize: CGFloat = 18.5
    static let platterHeight: CGFloat = 62
    static var platterBottomMargin: CGFloat { isIOS ? 21 : 10 }
    /// Horizontal pitch between item centers.
    static var itemPitch: CGFloat { isIOS ? 86 : 85.75 }
    /// Platter width = itemPitch · n + 2 · platterSidePadding.
    static var platterSidePadding: CGFloat { isIOS ? 8 : 8.375 }
    static var capsuleHeight: CGFloat { isIOS ? 54 : 53.5 }
    /// Capsule width = itemPitch + 2 · capsuleOverhang.
    static var capsuleOverhang: CGFloat { isIOS ? 4 : 3.875 }
    /// Platter-local y of the icon center / title center.
    static let iconCenterY: CGFloat = 24
    static var titleCenterY: CGFloat { isIOS ? 45 : 44.5 }
    static let titleFontSize: CGFloat = 10
    /// MEASURED Tabs t200, iPhone SE 2x / iOS 26.1: `_UIBarBadgeView` is
    /// 20×20, r=10, fill (255, 56, 60); the digit is 13 pt regular.
    static let badgeSizeIOS: CGFloat = 20
    static let badgeFontSizeIOS: CGFloat = 13
    static let badgeOriginXFromIconCenter: CGFloat = 8.5
    static let badgeOriginYInPlatter: CGFloat = 6
    static let badgeFontSize: CGFloat = 11
    static let badgeHeight: CGFloat = 16
    static let badgeSidePad: CGFloat = 8
    static var badgeColor: UIColor {
        if isIOS {
            // Same captured sRGB as the table delete-control fill
            // (editredprobe / Tabs t200 badge interior).
            return UIColor(red: 255 / 255, green: 56 / 255, blue: 60 / 255, alpha: 1)
        }
        return .systemRed
    }

    static var platterColor: UIColor {
        UIColor(dynamicProvider: { traits in
            if isIOS, traits.userInterfaceStyle == .dark {
                // tableview/tabbar_dark, SE 2x, 2026-09-04:
                // platter flat fill samples (19,19,19) in the untinted region.
                return UIColor(red: 19 / 255, green: 19 / 255, blue: 19 / 255, alpha: 1)
            }
            return isIOS
                ? UIColor(red: 249 / 255, green: 249 / 255, blue: 249 / 255, alpha: 1)
                : UIColor(red: 253 / 255, green: 253 / 255, blue: 254 / 255, alpha: 1)
        })
    }
    static var capsuleColor: UIColor {
        UIColor(dynamicProvider: { traits in
            if isIOS, traits.userInterfaceStyle == .dark {
                // MEASURED /tmp/glass-dark-out glass_tabbar_dark_black, SE 2x:
                // selected 19→53 is white-over-glass 34/236. Opaque 53 is
                // the same over black and the Catalyst/test fallback when
                // bar glass does not run.
                return UIColor(white: 1, alpha: _UIGlassMaterial.darkBarCapsuleOverlayAlpha)
            }
            if isIOS {
                // Black overlay on `_UIGlassMaterial`. MEASURED
                // glass_tabbar_se_white selected capsule 253→235: 18/253.
                // Over black: pred 204 vs meas 198 (residual 6) — reported,
                // not a third unknown.
                return UIColor(white: 0, alpha: _UIGlassMaterial.capsuleOverlayAlpha)
            }
            return UIColor(red: 235 / 255, green: 235 / 255, blue: 236 / 255, alpha: 1)
        })
    }
    static var unselectedColor: UIColor {
        UIColor(dynamicProvider: { traits in
            if isIOS, traits.userInterfaceStyle == .dark {
                // tabbar_dark, SE 2x, 2026-09-04:
                // unselected icon block at [90,409,24,24] is (243,243,243).
                return UIColor(red: 243 / 255, green: 243 / 255, blue: 243 / 255, alpha: 1)
            }
            return UIColor(red: 25 / 255, green: 25 / 255, blue: 25 / 255, alpha: 1)
        })
    }
    /// Measured default selected-item tint (iOS 26 tab bars do not use
    /// systemBlue).
    public static var defaultTint: UIColor {
        UIColor(dynamicProvider: { traits in
            if isIOS, traits.userInterfaceStyle == .dark {
                // tabbar_dark, SE 2x, 2026-09-04:
                // selected tint samples (27,172,255) in icon/title ink.
                return UIColor(red: 27 / 255, green: 172 / 255, blue: 1, alpha: 1)
            }
            return isIOS
                ? UIColor(red: 0, green: 124 / 255, blue: 243 / 255, alpha: 1)
                : UIColor(red: 52 / 255, green: 124 / 255, blue: 238 / 255, alpha: 1)
        })
    }
    // Platter drop shadow (fit to the golden's soft falloff).
    static let shadowOpacity: Float = 0.10
    static let shadowRadius: CGFloat = 7
    static let shadowOffset = CGSize(width: 0, height: 2.5)

    // MARK: State

    public var items: [UITabBarItem]? {
        didSet { rebuildItemViews() }
    }
    public var selectedItem: UITabBarItem? {
        didSet {
            if selectedItem !== oldValue {
                setNeedsLayout()
                applyItemColors()
            }
        }
    }
    public weak var delegate: UITabBarDelegate?

    let platter = UIView()
    let capsule = UIView()
    var itemViews: [_UITabBarItemView] = []
    /// iOS 26 bottom `ScrollEdgeEffectView`. Window frame equals the
    /// dump (`[0, bar.y − 64.8, W, barHeight + 64.8]`); parented here
    /// so table retile cannot cover it. Behind the platter; the platter
    /// AABB is punched out so `_UIGlassMaterial` still samples the
    /// unwashed scroll blocks (MEASURED t2000: x=30 washed (245,233,209),
    /// platter interior is glass (255,244,207), not that wash).
    var bottomEdgeEffect: _UITabBarScrollEdgeEffectView?

    public override init(frame: CGRect) {
        super.init(frame: frame)
        configureChrome()
    }

    public required init?(coder: NSCoder) {
        super.init(coder: coder)
        configureChrome()
    }

    private func configureChrome() {
        isOpaque = false
        platter.isOpaque = false
        platter._usesIOSGlass = true
        platter._usesIOSDarkBarGlass = true
        platter.backgroundColor = UITabBar.platterColor.resolvedColor(with: traitCollection)
        platter.layer.cornerRadius = UITabBar.platterHeight / 2
        platter.layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        platter.layer.shadowOpacity = UITabBar.shadowOpacity
        platter.layer.shadowRadius = UITabBar.shadowRadius
        platter.layer.shadowOffset = UITabBar.shadowOffset
        capsule.isOpaque = false
        capsule.backgroundColor = UITabBar.capsuleColor.resolvedColor(with: traitCollection)
        capsule.layer.cornerRadius = UITabBar.capsuleHeight / 2
        addSubview(platter)
        platter.addSubview(capsule)
    }

    /// The tab bar's default tint is the measured iOS 26 selection color,
    /// not the inherited systemBlue.
    public override var tintColor: UIColor! {
        get { _tintColor ?? UITabBar.defaultTint }
        set {
            _tintColor = newValue
            applyItemColors()
        }
    }

    func rebuildItemViews() {
        for v in itemViews { v.removeFromSuperview() }
        itemViews = (items ?? []).map { item in
            item._bar = self
            let v = _UITabBarItemView(item: item)
            v.addTarget(for: .touchUpInside) { [weak self] control, _ in
                guard let self, let iv = control as? _UITabBarItemView else { return }
                self.selectedItem = iv.item
                self.delegate?.tabBar(self, didSelect: iv.item)
            }
            platter.addSubview(v)
            return v
        }
        applyItemColors()
        setNeedsLayout()
    }

    func applyItemColors() {
        let tint = (tintColor ?? UITabBar.defaultTint)
            .resolvedColor(with: UITraitCollection.current)
        let unselected = UITabBar.unselectedColor
            .resolvedColor(with: UITraitCollection.current)
        for v in itemViews {
            v.apply(color: v.item === selectedItem ? tint
                                                   : unselected,
                    selected: v.item === selectedItem)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        if UITabBar.isPad {
            layoutPadItems()
            layoutBottomEdgeEffect()
            return
        }
        if UITabBar.isCompactHeight {
            layoutCompactHeightItems()
            layoutBottomEdgeEffect()
            return
        }
        platter.layer.cornerRadius = UITabBar.platterHeight / 2
        capsule.layer.cornerRadius = UITabBar.capsuleHeight / 2
        let n = CGFloat(max(itemViews.count, 1))
        let width = min(n * UITabBar.itemPitch + 2 * UITabBar.platterSidePadding,
                        bounds.width - 16)
        let x = ((bounds.width - width) / 2).rounded()
        platter.frame = CGRect(x: x, y: 0, width: width,
                               height: UITabBar.platterHeight)
        let pitch = (width - 2 * UITabBar.platterSidePadding) / n
        for (i, v) in itemViews.enumerated() {
            v.frame = CGRect(x: UITabBar.platterSidePadding + CGFloat(i) * pitch,
                             y: 0, width: pitch, height: UITabBar.platterHeight)
        }
        // MEASURED Tabs t200.rtl, iPhone SE 2x / iOS 26.1: items pack
        // leading-to-trailing. Library (index 0) title abs.x 256 vs LTR 84;
        // Scroll abs.x 88 vs LTR 259.5. Mirror LTR packing about the
        // platter width (same as nav-bar chrome). Badge slot is OPEN
        // (t200 pixels stay at LTR 196.5; t1000 paints RTL 159).
        if _layoutIsRTL {
            let span = width
            for v in itemViews {
                var f = v.frame
                f.origin.x = span - f.maxX
                v.frame = f
            }
        }
        if let sel = selectedItem,
           let idx = itemViews.firstIndex(where: { $0.item === sel }) {
            capsule.isHidden = false
            let item = itemViews[idx]
            let center = item.frame.midX
            let cw = pitch + 2 * UITabBar.capsuleOverhang
            capsule.frame = CGRect(x: center - cw / 2,
                                   y: (UITabBar.platterHeight - UITabBar.capsuleHeight) / 2,
                                   width: cw, height: UITabBar.capsuleHeight)
            platter.insertSubview(capsule, at: 0)
        } else {
            capsule.isHidden = true
        }
        layoutBottomEdgeEffect()
    }

    /// Pin the bottom `ScrollEdgeEffectView` so its window frame matches
    /// the dump. MEASURED Tabs t2000: `[0, 519.2, 375, 147.8]` = bar
    /// `[0, 584, 375, 83]` grown by `bottomEdgeOvershoot` **64.8** above.
    /// PocketBlur is hidden; BackdropView is white α=0.85 (light) / 0.6
    /// (dark) / popacity 0.151 (compact). Light and compact paint
    /// nothing (Notes t5000 / t200.landscape). Dark paints the
    /// measured black multiply (t2000.dark x=30, α plateau 0.598).
    func layoutBottomEdgeEffect() {
        guard UITabBar.isIOS, !UITabBar.isPad, bounds.width > 0,
              // MEASURED 2026-09-10, scrolledgeeffectprobe scroll.bottomHidden
              // / scroll.bottomHard (iPhone 16 / iOS 26.1): the bar's effect
              // is the content scroll view's `bottomEdgeEffect` — hidden
              // shows raw bands up to the bottom of the screen; `.hard` is
              // the white plate over the bar frame, painted by the scroll
              // view (UIScrollEdgeEffect.swift), not this gradient.
              !((delegate as? UITabBarController)?
                  ._resolvedContentScrollView(for: .bottom)?
                  ._edgeEffectSuppressesAutomaticPainter(.bottom) ?? false) else {
            bottomEdgeEffect?.isHidden = true
            return
        }
        let view: _UITabBarScrollEdgeEffectView
        if let existing = bottomEdgeEffect {
            view = existing
        } else {
            let created = _UITabBarScrollEdgeEffectView()
            created.isOpaque = false
            created.isUserInteractionEnabled = false
            created.backgroundColor = .clear
            created.accessibilityIdentifier = "ScrollEdgeEffectView"
            insertSubview(created, at: 0)
            bottomEdgeEffect = created
            view = created
        }
        view.isHidden = false
        insertSubview(view, at: 0)
        let overshoot = UITabBar.bottomEdgeOvershoot
        view.frame = CGRect(x: 0, y: -overshoot,
                            width: bounds.width,
                            height: bounds.height + overshoot)
        // Platter in overlay coords: bar-local y=0 → overlay y=overshoot.
        let pf = platter.frame
        view.platterHole = CGRect(x: pf.minX, y: pf.minY + overshoot,
                                  width: pf.width, height: pf.height)
        let dark = traitCollection.userInterfaceStyle == .dark
        let compact = UITabBar.isCompactHeight
        let tint: CGFloat
        let stops: [(CGFloat, CGFloat)]
        if compact {
            // BackdropView α=0 in the compact dump. Do not paint the
            // portrait pocket (or a T=82 invert of glass-over-red).
            tint = UITabBar.bottomEdgeCompactTint
            stops = UITabBar.bottomEdgeCompactStops
        } else if dark {
            tint = 0
            stops = UITabBar.bottomEdgeDarkStops
        } else {
            tint = UITabBar.bottomEdgeLightTint
            stops = UITabBar.bottomEdgeLightStops
        }
        view.colors = stops.map { _, alpha in
            UIColor(red: tint, green: tint, blue: tint, alpha: alpha)
        }
        view.locations = stops.map { $0.0 }
        view.startPoint = CGPoint(x: 0.5, y: 0)
        view.endPoint = CGPoint(x: 0.5, y: 1)
        view.setNeedsDisplay()
    }

    /// MEASURED Tabs t200.landscape / t2000.landscape, iPhone SE 2x /
    /// iOS 26.1: compact-height bar is a 44 pt floating platter of
    /// **packed** icon+title pills, not the portrait equal-pitch stack.
    /// Library/Tools/Scroll buttons **86.5 / 76.5 / 78.5** with 4 pt
    /// gaps; platter width 257.5, x = round((667−257.5)/2) = **205**.
    /// MEASURED Notes t200.landscape 2-up: platter `[240, 0, 187.5, 44]`,
    /// same 4 pt side pad / 4 pt gaps / 36 pt pills at y 4 (Notes + Settings).
    func layoutCompactHeightItems() {
        platter.backgroundColor = UITabBar.platterColor.resolvedColor(with: traitCollection)
        platter._usesIOSGlass = true
        platter.layer.cornerRadius = UITabBar.compactPlatterHeight / 2
        platter.layer.shadowOpacity = UITabBar.shadowOpacity
        var widths: [CGFloat] = []
        var total: CGFloat = 0
        for v in itemViews {
            widths.append(compactItemWidth(for: v))
            total += widths.last ?? 0
        }
        let n = CGFloat(itemViews.count)
        let pad = UITabBar.compactItemSidePad
        let width = n == 0 ? 0 : total + pad * (n + 1)
        let x = ((bounds.width - width) / 2).rounded()
        platter.frame = CGRect(x: x, y: 0, width: width,
                               height: UITabBar.compactPlatterHeight)
        var itemX = pad
        for (i, v) in itemViews.enumerated() {
            v.frame = CGRect(x: itemX, y: UITabBar.compactItemY,
                             width: widths[i], height: UITabBar.compactItemHeight)
            itemX += widths[i] + pad
        }
        if _layoutIsRTL {
            let span = width
            for v in itemViews {
                var f = v.frame
                f.origin.x = span - f.maxX
                v.frame = f
            }
        }
        if let sel = selectedItem,
           let idx = itemViews.firstIndex(where: { $0.item === sel }) {
            capsule.isHidden = false
            capsule.frame = itemViews[idx].frame
            capsule.layer.cornerRadius = UITabBar.compactItemHeight / 2
            platter.insertSubview(capsule, at: 0)
        } else {
            capsule.isHidden = true
        }
    }

    /// Button width from 12 pt regular title + compact icon size + the
    /// measured 6 / 8 / 12 paddings (see compactItemTrailing).
    func compactItemWidth(for v: _UITabBarItemView) -> CGFloat {
        v.titleLabel.text = v.item.title
        v.titleLabel.font = .systemFont(ofSize: UITabBar.compactTitleFontSize,
                                        weight: .regular)
        let titleW = v.titleLabel.intrinsicContentSize.width
        let iconW = UITabBar.compactIconSize(for: v.iconView.image).width
        return UITabBar.compactIconLeading + iconW
            + UITabBar.compactIconTitleGap + titleW
            + UITabBar.compactItemTrailing
    }

    /// MEASURED Tabs t200.landscape: calendar image view **21×18.5** vs
    /// portrait 18/medium/large **29×25**; clock / plus.circle.fill
    /// **20.5×20.5** vs **27.5×27.5**. Same harvested 18 pt masks, shown
    /// in the dump frames (UIImageView default scaleToFill).
    static func compactIconSize(for image: UIImage?) -> CGSize {
        guard let image else { return .zero }
        let w = image.size.width
        let h = image.size.height
        if abs(w - 29) < 0.01, abs(h - 25) < 0.01 {
            return CGSize(width: 21, height: 18.5)
        }
        if abs(w - 27.5) < 0.01, abs(h - 27.5) < 0.01 {
            return CGSize(width: 20.5, height: 20.5)
        }
        return CGSize(width: w * (20.5 / 27.5), height: h * (20.5 / 27.5))
    }

    /// MEASURED Tabs-ipad t200, iPad (A16) 820×1180 @2x / iOS 26.1:
    /// `_UIFloatingTabBar [0, 32, 820, 44]`. Items are title-only 36 pt
    /// pills packed by intrinsic width + 16 pt insets (Library 87 / Tools
    /// 73.5 / Scroll 76.5) and centred: x0 = (820 − 237) / 2 = **291.5**.
    func layoutPadItems() {
        // MEASURED Tabs-ipad t200: `_UIFloatingTabBarSelectionContainerView`
        // is **245×44** around the packed titles, not a full-width fill.
        // A full-width platter would paint over the trailing 240×44 search
        // field that lives in the nav bar underneath (same y = SA.top).
        platter.frame = bounds
        platter.backgroundColor = .clear
        platter._usesIOSGlass = false
        platter.layer.cornerRadius = 0
        platter.layer.shadowOpacity = 0
        capsule.isHidden = true
        var widths: [CGFloat] = []
        var total: CGFloat = 0
        for v in itemViews {
            v.titleLabel.text = v.item.title
            v.titleLabel.font = .systemFont(ofSize: 17, weight: .regular)
            let t = v.titleLabel.intrinsicContentSize
            let w = t.width + 2 * UITabBar.padItemTitleInset
            widths.append(w)
            total += w
        }
        var x = (bounds.width - total) / 2
        for (i, v) in itemViews.enumerated() {
            v.frame = CGRect(x: x, y: UITabBar.padItemYInBar,
                             width: widths[i], height: UITabBar.padItemHeight)
            x += widths[i]
        }
    }

    /// iOS tab-bar symbol at the measured preferred configuration.
    /// Selected and unselected use the same name (the fill sibling is
    /// NOT swapped — t2000 golden vs symbolinkprobe outline `clock`
    /// corr 0.999997). Catalyst returns the item image unchanged.
    static func resolvedItemImage(_ item: UITabBarItem, selected: Bool) -> UIImage? {
        guard isIOS,
              let image = item.image,
              image.isSymbolImage,
              let name = image._systemSymbolName else {
            return item.image
        }
        _ = selected
        // MEASURED Tabs probe + symbolinkprobe, iPhone SE 2x / iOS 26.1:
        // preferredSymbolConfiguration "pointSize=18, weight=Medium, scale=Large".
        let configuration = UIImage.SymbolConfiguration(
            pointSize: 18, weight: .medium, scale: .large)
        return UIImage(systemName: name, withConfiguration: configuration)
            ?? image
    }

    /// `clock.fill` exists in the portable set; `calendar.fill` is nil
    /// on iOS 26.1 (symbolinkprobe). The tab bar does not call this for
    /// the selected item (see resolvedItemImage).
    static func filledSymbolName(_ name: String) -> String {
        if name.hasSuffix(".fill") { return name }
        let filled = name + ".fill"
        if UIImage(systemName: filled) != nil { return filled }
        return name
    }

    /// Template rendering: `image`'s alpha channel flattened to `tint`.
    static func templateImage(_ image: UIImage, tint: UIColor) -> UIImage {
        let src = image.bitmap
        let out = Bitmap(width: src.width, height: src.height)
        let c = tint.cgColor
        let r = UInt8((max(0, min(1, c.red)) * 255).rounded())
        let g = UInt8((max(0, min(1, c.green)) * 255).rounded())
        let b = UInt8((max(0, min(1, c.blue)) * 255).rounded())
        let tintAlpha = max(0, min(1, c.alpha))
        var i = 0
        while i < src.pixels.count {
            out.pixels[i] = r
            out.pixels[i + 1] = g
            out.pixels[i + 2] = b
            out.pixels[i + 3] = UInt8((CGFloat(src.pixels[i + 3]) * tintAlpha).rounded())
            i += 4
        }
        return UIImage(bitmap: out, scale: image.scale)
    }
}

/// Bottom tab-bar `ScrollEdgeEffectView`. Not a `UIGradientView`: quartz
/// promotes those to `QZGradientLayer` and would skip `drawContent` (and
/// the platter hole). MEASURED Tabs t2000 x=30 vs platter interior, SE 2x.
@preconcurrency @MainActor
final class _UITabBarScrollEdgeEffectView: UIView {
    var colors: [UIColor] = []
    var locations: [CGFloat]?
    var startPoint = CGPoint(x: 0.5, y: 0)
    var endPoint = CGPoint(x: 0.5, y: 1)
    var platterHole = CGRect(x: 0, y: 0, width: 0, height: 0)

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard !bounds.isEmpty, colors.count >= 2 else { return }
        let hole = platterHole
        if hole.width < 1 || hole.height < 1 {
            drawGradient(in: canvas, bounds: bounds)
            return
        }
        let slices = [
            CGRect(x: bounds.minX, y: bounds.minY,
                   width: max(0, hole.minX - bounds.minX), height: bounds.height),
            CGRect(x: hole.maxX, y: bounds.minY,
                   width: max(0, bounds.maxX - hole.maxX), height: bounds.height),
            CGRect(x: hole.minX, y: bounds.minY,
                   width: hole.width, height: max(0, hole.minY - bounds.minY)),
            CGRect(x: hole.minX, y: hole.maxY,
                   width: hole.width, height: max(0, bounds.maxY - hole.maxY)),
        ]
        for r in slices where r.width > 0.5 && r.height > 0.5 {
            canvas.save()
            canvas.clip(to: r)
            drawGradient(in: canvas, bounds: bounds)
            canvas.restore()
        }
    }

    func drawGradient(in canvas: Canvas, bounds: CGRect) {
        let traits = traitCollection
        let resolved = colors.map { $0.resolvedCGColor(with: traits) }
        let n = resolved.count
        var locs: [CGFloat]
        if let l = locations, l.count == n {
            locs = l.map { min(max($0, 0), 1) }
        } else {
            locs = (0..<n).map { CGFloat($0) / CGFloat(n - 1) }
        }
        let (dColors, dLocs) = _CAGradientColorSpace.densify(colors: resolved,
                                                             locations: locs)
        canvas.save()
        canvas.translate(x: bounds.minX, y: bounds.minY)
        canvas.concatenate(CGAffineTransform(scaleX: bounds.width, y: bounds.height))
        canvas.drawLinearGradient(colors: dColors, locations: dLocs,
                                  start: startPoint, end: endPoint,
                                  in: CGRect(x: 0, y: 0, width: 1, height: 1))
        canvas.restore()
    }
}
