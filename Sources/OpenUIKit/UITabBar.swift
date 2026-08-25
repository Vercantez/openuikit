// UITabBar. Owner: viewcontroller module (M10 chrome).
//
// iOS 26 "liquid glass" floating tab bar, metrics measured from the real-
// UIKit goldens (golden/tabbar_basic, golden/tabbar_tinted — oracle2 real
// window, compact width, 375 pt scene):
//   - The bar OWNS the bottom 72 pt of its controller's view and is
//     otherwise transparent (content shows through around the platter).
//   - Floating platter: height 62 pt, 10 pt bottom margin, width
//     n·85.75 + 16.75 for n items (274 pt at n = 3), centered; near-white
//     glass #FDFDFE with a soft drop shadow (no blur backdrop — the
//     platter is opaque enough that the golden shows flat color).
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
// KNOWN GAP: light-mode platter/capsule constants only (the M10 tab bar
// goldens are light); dark-mode glass material is not yet measured.

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


public class UITabBarItem {
    public var title: String?
    public var image: UIImage?
    public var tag: Int

    public init(title: String?, image: UIImage?, tag: Int) {
        self.title = title
        self.image = image
        self.tag = tag
    }
}

public protocol UITabBarDelegate: AnyObject {
    func tabBar(_ tabBar: UITabBar, didSelect item: UITabBarItem)
}

/// One item slot: tinted icon + title, tap → selection. All drawing state
/// (tint) is pushed in by the bar.
final class _UITabBarItemView: UIControl {
    let item: UITabBarItem
    let iconView = UIImageView()
    let titleLabel = UILabel()

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
    }

    /// Recolor icon + title. The icon is the item image's alpha channel
    /// flattened to `color` (template rendering).
    func apply(color: UIColor) {
        titleLabel.textColor = color
        iconView.image = item.image.map { UITabBar.templateImage($0, tint: color) }
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let size = iconView.image?.size ?? .zero
        iconView.frame = CGRect(x: (bounds.width - size.width) / 2,
                                y: UITabBar.iconCenterY - size.height / 2,
                                width: size.width, height: size.height)
        let t = titleLabel.intrinsicContentSize
        titleLabel.frame = CGRect(x: (bounds.width - t.width) / 2,
                                  y: UITabBar.titleCenterY - t.height / 2,
                                  width: t.width, height: t.height)
    }
}

public final class UITabBar: UIView {
    // MARK: Golden-measured metrics (see file header)

    /// Height of the bar's region at the bottom of the controller view.
    public static let barHeight: CGFloat = 72
    static let platterHeight: CGFloat = 62
    static let platterBottomMargin: CGFloat = 10
    /// Horizontal pitch between item centers.
    static let itemPitch: CGFloat = 85.75
    /// Platter width = itemPitch · n + 2 · platterSidePadding.
    static let platterSidePadding: CGFloat = 8.375
    static let capsuleHeight: CGFloat = 53.5
    /// Capsule width = itemPitch + 2 · capsuleOverhang.
    static let capsuleOverhang: CGFloat = 3.875
    /// Platter-local y of the icon center / title center.
    static let iconCenterY: CGFloat = 24
    static let titleCenterY: CGFloat = 44.5
    static let titleFontSize: CGFloat = 10

    static let platterColor = UIColor(red: 253 / 255, green: 253 / 255,
                                      blue: 254 / 255, alpha: 1)
    static let capsuleColor = UIColor(red: 235 / 255, green: 235 / 255,
                                      blue: 236 / 255, alpha: 1)
    static let unselectedColor = UIColor(red: 25 / 255, green: 25 / 255,
                                         blue: 25 / 255, alpha: 1)
    /// Measured default selected-item tint (iOS 26 tab bars do not use
    /// systemBlue).
    public static let defaultTint = UIColor(red: 52 / 255, green: 124 / 255,
                                            blue: 238 / 255, alpha: 1)
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

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        platter.backgroundColor = UITabBar.platterColor
        platter.layer.cornerRadius = UITabBar.platterHeight / 2
        platter.layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        platter.layer.shadowOpacity = UITabBar.shadowOpacity
        platter.layer.shadowRadius = UITabBar.shadowRadius
        platter.layer.shadowOffset = UITabBar.shadowOffset
        capsule.backgroundColor = UITabBar.capsuleColor
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
        for v in itemViews {
            v.apply(color: v.item === selectedItem ? tint
                                                   : UITabBar.unselectedColor)
        }
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
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
