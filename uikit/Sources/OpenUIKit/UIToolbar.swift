// UIToolbar. Owner: viewcontroller module (M13 "bars & appearance").
//
// MEASURED (real iOS 26.1, iPhone 16 — probe recipe in UIBarButtonItem.swift,
// golden/toolbar_basic): a toolbar is a row of glass capsule platters, laid
// out inside the bar's bounds with a 16 pt side margin and the shared 12 pt
// gap rule, with flexible spaces absorbing the slack. Two numbers differ
// from the navigation bar and were measured separately:
//
//   * the platters are **48 pt** tall (radius 24), not 44,
//   * and they are TOP-ALIGNED at the bar's own y = 0, not centred.
//
// MEASURED 2026-09-10, Tools/oracle2/toolbarheightprobe (iPhone 16, iPhone
// SE 3rd gen, iPad A16 / iOS 26.1, both orientations, `.default` and
// `.black`, with and without items — none of which changes a number):
//
//   * intrinsicContentSize.height == sizeThatFits.height == the platter
//     height: **48** on a phone, **44** on a pad. A bar pinned to a
//     controller's bottom by Auto Layout with no height constraint lays
//     out 48 (phone) / 44 (pad) high. The port used to carry 54, which was
//     never a measurement: fixtures/scenes/toolbar_basic.json HANDS each
//     bar a 54 pt frame and the golden echoes it back.
//   * Compact height (phone landscape): a hosted bar answers 44 to a
//     direct intrinsicContentSize / sizeThatFits read, but Auto Layout
//     keeps the 48 it cached when the bar entered the hierarchy (before
//     traits arrived) — even from viewDidLoad — until the app calls
//     invalidateIntrinsicContentSize. The port reports the laid-out 48.
//   * Platters: top-aligned at y = 0 once the bar is at least platter-high
//     (54 and 64 pt frames both read y 0); a SHORTER bar centres them
//     (44 pt frame → `[16, -2, 361, 48]`).
//
// The bar itself paints nothing unless its appearance was configured with a
// background (iOS 26 default = transparent, like every other bar).
//
// `isTranslucent` has no blur to be translucent WITH (docs/KNOWN_GAPS.md):
// it is stored, and a translucent bar simply keeps whatever flat background
// its appearance supplies — the measured flat equivalent.

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
public final class UIToolbar: UIView, _UIBarItemContainer, UIBarPositioning {
    /// Measured intrinsic bar height (see the file header): the platter
    /// height, 48 on a phone and 44 on a pad. NOT trait-driven at compact
    /// height on purpose — that is the frame iOS lays out.
    public static var defaultHeight: CGFloat { UINavigationBar.isPad ? 44 : 48 }

    /// Where the platter row sits inside the bar; a UINavigationController
    /// sets these for the bottom slot it manages (platters 10 pt below the
    /// slot's top, 28 pt from its side on a phone). A free-standing bar
    /// keeps 0 / the trait side margin.
    var _platterTopInset: CGFloat = 0 { didSet { setNeedsLayout() } }
    var _platterSideInset: CGFloat? { didSet { setNeedsLayout() } }

    public var items: [UIBarButtonItem]? {
        didSet { rebuildItemViews() }
    }

    /// MEASURED (UIBarPositioning.swift): `position(for:)` is asked once,
    /// when the bar joins a superview; setting the delegate, reading
    /// `barPosition`, and later layout passes ask nothing. An `.any` answer
    /// leaves the bar at `.bottom`, and the position paints nothing
    /// different on iOS 26.
    public weak var delegate: UIToolbarDelegate?

    private var resolvedPosition: UIBarPosition = .bottom
    public var barPosition: UIBarPosition { resolvedPosition }

    public override func didMoveToSuperview() {
        super.didMoveToSuperview()
        guard superview != nil, let delegate else { return }
        let answer = delegate.position(for: self)
        resolvedPosition = answer == .any ? .bottom : answer
    }

    /// Bar-wide tint. Only a `.prominent` item's platter fill uses it —
    /// iOS 26 renders untinted bar buttons monochrome (measured; see
    /// UIBarButtonItem.swift).
    public var barTintColor: UIColor? {
        didSet { applyAppearance() }
    }
    public var isTranslucent: Bool = true

    public var standardAppearance = UIToolbarAppearance() {
        didSet { applyAppearance() }
    }
    public var scrollEdgeAppearance: UIToolbarAppearance? {
        didSet { applyAppearance() }
    }
    public var compactAppearance: UIToolbarAppearance?

    let background = UIView()
    let hairline = UIView()
    var itemViews: [_UIBarButtonItemView] = []

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
        background.isUserInteractionEnabled = false
        hairline.isUserInteractionEnabled = false
        addSubview(background)
        addSubview(hairline)
        applyAppearance()
    }

    public func setItems(_ items: [UIBarButtonItem]?, animated: Bool) {
        self.items = items
    }

    func _view(for item: UIBarButtonItem) -> UIView? {
        itemViews.first { $0.item === item }
    }

    func _barItemsChanged() {
        for v in itemViews { v.applyColors() }
        setNeedsLayout()
    }

    func rebuildItemViews() {
        for v in itemViews { v.removeFromSuperview() }
        itemViews = (items ?? []).map { item in
            item._bar = self
            let v = _UIBarButtonItemView(item: item)
            v.platterHeight = _UIBarMetrics.toolbarPlatterHeightForCurrentTraits
            v.appliesRefraction = false     // measured: toolbars have no band
            v.barTintColor = barTintColor ?? tintColor ?? .systemBlue
            v.addTarget(for: .touchUpInside) { [weak item] control, event in
                guard let item else { return }
                item.primaryAction?.performWithSender(item, target: nil)
                guard let action = item.action else { return }
                SelectorDispatch.send(action, to: item.target, sender: item,
                                      event: event)
                _ = control
            }
            addSubview(v)
            return v
        }
        applyAppearance()
        setNeedsLayout()
    }

    func applyAppearance() {
        let a = standardAppearance
        background.backgroundColor = a._resolvedBackgroundColor
        hairline.backgroundColor = a.shadowColor
        hairline.isHidden = a.shadowColor == nil || a._resolvedBackgroundColor == nil
        for v in itemViews { v.barTintColor = barTintColor ?? tintColor ?? .systemBlue }
        setNeedsLayout()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        background.frame = bounds
        hairline.frame = CGRect(x: 0, y: bounds.height - UIBarAppearance.shadowHeight,
                                width: bounds.width, height: UIBarAppearance.shadowHeight)
        // MEASURED (file header): platters 48 tall on a phone at regular
        // height, 44 on a pad or at compact height; top-aligned at y = 0
        // when the bar is at least platter-high, centred when it is shorter
        // (a 44 pt frame puts the 48 pt row at y −2). A nav-managed slot
        // adds its own top / side insets.
        let h = _UIBarMetrics.toolbarPlatterHeightForCurrentTraits
        for v in itemViews { v.platterHeight = h }
        let y = _platterTopInset + min(0, (bounds.height - h) / 2)
        _UIBarItemLayout.layout(itemViews, in: bounds.width, y: y, height: h,
                                sideMargin: _platterSideInset
                                    ?? _UIBarMetrics.toolbarSideMarginForCurrentTraits)
    }

    public override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: UIToolbar.defaultHeight)
    }

    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        CGSize(width: size.width, height: UIToolbar.defaultHeight)
    }
}
