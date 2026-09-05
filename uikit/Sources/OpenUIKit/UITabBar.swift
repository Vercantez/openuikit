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
        iconView.isHidden = false
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
    public static var barHeight: CGFloat {
        if isPad { return 44 }
        return isIOS ? 83 : 72
    }
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
            return
        }
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
        if let sel = selectedItem,
           let idx = itemViews.firstIndex(where: { $0.item === sel }) {
            capsule.isHidden = false
            let center = UITabBar.platterSidePadding + (CGFloat(idx) + 0.5) * pitch
            let cw = pitch + 2 * UITabBar.capsuleOverhang
            capsule.frame = CGRect(x: center - cw / 2,
                                   y: (UITabBar.platterHeight - UITabBar.capsuleHeight) / 2,
                                   width: cw, height: UITabBar.capsuleHeight)
            platter.insertSubview(capsule, at: 0)
        } else {
            capsule.isHidden = true
        }
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
