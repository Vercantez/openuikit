// UINavigationBar. Owner: viewcontroller module (M7.5 navigation,
// M10 large titles, M13 navigation items + appearance).
//
// Visuals per docs/APP_FEEL.md "Navigation transitions" and the M13
// measurements in UIBarButtonItem.swift:
//   - 54pt content bar below a 10pt top padding (MEASURED on real iOS 26.1;
//     M7.5's guessed 20 + 44 split is gone, the 64pt total is unchanged).
//     Background + hairline come from `standardAppearance`, whose default is
//     the opaque configuration.
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

public final class UINavigationBar: UIView, _UIBarItemContainer {
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
    /// Padding above the content bar inside the bar zone (measured).
    public static let barTopPadding: CGFloat = 10
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
    // 52 (large-title zone). The 34 pt-bold large title sits at x = 20
    // (label frame [20, 3, w, 40.5] inside the large-title zone) and
    // scrolls away 1:1 with the content; the centered 17 pt inline title
    // (center y = 32) fades in as the large title leaves. Content that
    // slides under the bar region gets the scroll-edge-effect "pocket":
    // a blurred, background-washed copy of the content (see updatePocket).

    /// Expanded adjusted content inset (the rest offset is -116).
    public static let largeTitleExpandedInset: CGFloat = 116
    static let largeInlineZoneTop: CGFloat = 10
    static let largeInlineZoneHeight: CGFloat = 54
    static let largeTitleZoneHeight: CGFloat = 52
    static let largeTitleX: CGFloat = 20
    static let largeTitleLabelY: CGFloat = 67       // 10 + 54 + 3
    static let largeTitleLabelHeight: CGFloat = 40.5
    static let largeTitleFontSize: CGFloat = 34
    static let largeInlineTitleCenterY: CGFloat = 32

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

    /// The content scroll view driving expansion/collapse (bound by
    /// UINavigationController from the top VC's setContentScrollView).
    weak var trackedScrollView: UIScrollView? {
        didSet { if trackedScrollView !== oldValue { setNeedsLayout() } }
    }

    var largeTitleLabel: UILabel?
    let pocketView = UIImageView()
    /// Fingerprint of the last computed pocket image (offset/size/style).
    var pocketKey: (offsetY: CGFloat, width: CGFloat, engagement: CGFloat)?

    // Current (settled) elements.
    var titleLabel: UILabel
    var backButton: _UINavigationBarBackButton?
    let hairline: UIView

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
    var titleViewHost: UIView?
    var promptLabel: UILabel?

    // MARK: Appearance (M13)

    /// UIKit's bar appearance objects. The default is the measured OPAQUE
    /// configuration — that is what OpenUIKit's inline bar has drawn since
    /// M7.5, and iOS 26's own default (transparent + scroll-edge effect) is
    /// what `prefersLargeTitles` already models.
    public var standardAppearance: UINavigationBarAppearance = {
        let a = UINavigationBarAppearance()
        a.configureWithOpaqueBackground()
        return a
    }() {
        didSet { applyAppearance() }
    }
    public var scrollEdgeAppearance: UINavigationBarAppearance? {
        didSet { applyAppearance() }
    }
    public var compactAppearance: UINavigationBarAppearance? {
        didSet { applyAppearance() }
    }
    /// Legacy `barTintColor`, folded into the standard appearance's
    /// background color (UIKit's own documented equivalence).
    public var barTintColor: UIColor? {
        didSet {
            if let barTintColor {
                standardAppearance.configureWithOpaqueBackground()
                standardAppearance.backgroundColor = barTintColor
            }
            applyAppearance()
        }
    }
    public var isTranslucent: Bool = true

    /// The appearance in force right now: `scrollEdgeAppearance` while the
    /// tracked scroll view sits at (or above) its top edge, otherwise
    /// `standardAppearance`. Per-item overrides win over both, exactly as in
    /// UIKit.
    var effectiveAppearance: UINavigationBarAppearance {
        let atEdge = trackedScrollView.map {
            $0.contentOffset.y <= -$0.contentInset.top + 0.5
        } ?? true
        if atEdge, let a = topItem?.scrollEdgeAppearance ?? scrollEdgeAppearance {
            return a
        }
        return topItem?.standardAppearance ?? standardAppearance
    }

    public override init(frame: CGRect = .zero) {
        titleLabel = UINavigationBar.makeTitleLabel(nil)
        hairline = UIView()
        super.init(frame: frame)
        hairline.isUserInteractionEnabled = false
        addSubview(hairline)
        addSubview(titleLabel)
        applyAppearance()
    }

    /// Push the appearance's background + hairline onto the bar.
    func applyAppearance() {
        // Large-title mode is transparent at rest by measurement (iOS 26);
        // its material comes from the scroll-edge pocket.
        guard !prefersLargeTitles else {
            backgroundColor = nil
            hairline.isHidden = true
            return
        }
        let a = effectiveAppearance
        backgroundColor = a._resolvedBackgroundColor
        hairline.backgroundColor = a.shadowColor
        hairline.isHidden = a.shadowColor == nil || backgroundColor == nil
        for v in leftItemViews + rightItemViews { v.backdropColor = backgroundColor }
        applyTitleAttributes()
        setNeedsLayout()
    }

    func applyTitleAttributes() {
        let a = effectiveAppearance
        titleLabel.font = a.titleTextAttributes.font
            ?? .systemFont(ofSize: 17, weight: .semibold)
        titleLabel.textColor = a.titleTextAttributes.foregroundColor ?? .label
        if let l = largeTitleLabel {
            l.font = a.largeTitleTextAttributes.font
                ?? .systemFont(ofSize: UINavigationBar.largeTitleFontSize, weight: .bold)
            l.textColor = a.largeTitleTextAttributes.foregroundColor ?? .label
        }
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
        let b = _UINavigationBarBackButton(title: title, tintColor: tintColor)
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
        if prefersLargeTitles {
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
    public func setItems(_ newItems: [UINavigationItem], animated: Bool = false) {
        for i in items { i._bar = nil }
        items = newItems
        for i in items { i._bar = self }
        _rebuildItemViews()
    }

    public func pushItem(_ item: UINavigationItem, animated: Bool = false) {
        setItems(items + [item], animated: animated)
    }

    @discardableResult
    public func popItem(animated: Bool = false) -> UINavigationItem? {
        guard let last = items.last else { return nil }
        setItems(Array(items.dropLast()), animated: animated)
        return last
    }

    /// A displayed `UINavigationItem` mutated.
    func _navigationItemChanged(_ item: UINavigationItem) {
        guard item === topItem else { return }
        _rebuildItemViews()
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
        applyAppearance()
        setNeedsLayout()
    }

    func makeItemView(_ item: UIBarButtonItem) -> _UIBarButtonItemView {
        item._bar = self
        let v = _UIBarButtonItemView(item: item)
        v.barTintColor = tintColor ?? .systemBlue
        v.backdropColor = backgroundColor
        v.addTarget(for: .touchUpInside) { [weak item] _, event in
            guard let item, let action = item.action else { return }
            SelectorDispatch.send(action, to: item.target, sender: item, event: event)
        }
        addSubview(v)
        return v
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
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
        if prefersLargeTitles { updateFromScroll() }
    }

    /// Lay the leading / trailing platter groups out at the measured
    /// margins, and place the prompt caption above them.
    func layoutBarItems() {
        let h = _UIBarMetrics.platterHeight
        let y = UINavigationBar.platterY + promptOffset
        var x = _UIBarMetrics.sideMargin + backButtonWidth
        for v in leftItemViews where !v.item._isSpace {
            let w = _UIBarItemLayout.width(of: v)
            v.frame = CGRect(x: x, y: y, width: w, height: h)
            x += w + _UIBarMetrics.gap
        }
        // UIKit's order: `rightBarButtonItems[0]` is the TRAILING-most item
        // (measured — a [.edit, "Add"] pair renders "Add" then "Edit").
        var right = bounds.width - _UIBarMetrics.sideMargin
        for v in rightItemViews where !v.item._isSpace {
            let w = _UIBarItemLayout.width(of: v)
            right -= w
            v.frame = CGRect(x: right, y: y, width: w, height: h)
            right -= _UIBarMetrics.gap
        }
        if let l = promptLabel {
            let s = l.intrinsicContentSize
            l.frame = CGRect(x: (bounds.width - s.width) / 2,
                             y: UINavigationBar.platterY
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
        var x = _UIBarMetrics.sideMargin + backButtonWidth
        var drawn = 0
        for v in leftItemViews where !v.item._isSpace {
            x += _UIBarItemLayout.width(of: v)
            drawn += 1
        }
        return x + CGFloat(max(0, drawn - 1)) * _UIBarMetrics.gap
    }

    /// Leading edge of the trailing group.
    var trailingGroupMinX: CGFloat {
        let w = _UIBarItemLayout.naturalWidth(rightItemViews)
        return w == 0 ? bounds.width : bounds.width - _UIBarMetrics.sideMargin - w
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
        let lead = leadingGroupMaxX
        let trail = trailingGroupMinX
        let clearance = UINavigationBar.titleGroupClearance
        if centered - width / 2 >= lead + clearance,
           centered + width / 2 <= trail - clearance {
            return centered
        }
        return lead + _UIBarMetrics.gap + width / 2
    }

    private var contentMidY: CGFloat {
        UINavigationBar.largeInlineTitleCenterY + promptOffset
    }

    private func place(title l: UILabel, centerX: CGFloat, alpha: CGFloat) {
        let s = l.intrinsicContentSize
        l.bounds = CGRect(x: 0, y: 0, width: s.width, height: s.height)
        l.center = CGPoint(x: centerX, y: contentMidY)
        l.alpha = alpha
    }

    private func place(back b: _UINavigationBarBackButton, alpha: CGFloat,
                       dx: CGFloat = 0) {
        let s = b.sizeThatFits(bounds.size)
        b.bounds = CGRect(x: 0, y: 0, width: s.width, height: s.height)
        b.center = CGPoint(x: s.width / 2 + dx, y: contentMidY)
        b.alpha = alpha
    }

    // MARK: Transitions (driven by UINavigationController)

    struct BarTransition {
        var push: Bool
        var oldTitle: UILabel
        var oldBack: _UINavigationBarBackButton?
        var newTitle: UILabel
        var newBack: _UINavigationBarBackButton?
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
        addSubview(newTitle)
        let newBack = makeBackButton(backTitle)
        if let b = newBack { addSubview(b) }
        transition = BarTransition(push: push, oldTitle: titleLabel,
                                   oldBack: backButton, newTitle: newTitle,
                                   newBack: newBack)
        titleLabel = newTitle
        backButton = newBack
        setTransitionProgress(0)
    }

    /// Position every transition element for progress `p` (0 = old state,
    /// 1 = new state). Pure property sets — records animations when called
    /// inside a UIView.animate block, scrubs the model otherwise.
    func setTransitionProgress(_ p: CGFloat) {
        guard let t = transition else { return }
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

    func configureLargeTitleAppearance() {
        if prefersLargeTitles {
            backgroundColor = nil            // iOS 26: transparent at rest
            hairline.isHidden = true
            let l = UILabel()
            l.text = titleLabel.text
            l.font = .systemFont(ofSize: UINavigationBar.largeTitleFontSize,
                                 weight: .bold)
            l.textColor = .label
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
        return s.contentOffset.y + UINavigationBar.largeTitleExpandedInset
    }

    /// Position/fade the large + inline titles for the current tracked
    /// offset, and refresh the scroll-edge pocket. Called from
    /// layoutSubviews and from every observed scroll.
    func updateFromScroll() {
        guard prefersLargeTitles else { return }
        let d = collapseDistance
        if let l = largeTitleLabel {
            let s = l.intrinsicContentSize
            l.frame = CGRect(x: UINavigationBar.largeTitleX,
                             y: UINavigationBar.largeTitleLabelY - d,
                             width: min(s.width, bounds.width
                                        - 2 * UINavigationBar.largeTitleX),
                             height: UINavigationBar.largeTitleLabelHeight)
            l.alpha = 1 - smoothstep01((d - 20) / 32)
        }
        // Inline title fades in as the large title leaves its zone.
        titleLabel.alpha = smoothstep01((d - 30) / 26)
        updatePocket()
    }

    /// In large-title mode the bar is transparent chrome floating over the
    /// content — only its interactive elements (back button) take touches;
    /// everything else falls through to the content below.
    public override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        guard prefersLargeTitles else { return super.hitTest(point, with: event) }
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
    static let pocketBlurSigma: CGFloat = 8
    /// Background wash: plateau strength, plateau end and wash end (pt).
    static let pocketWashTop: CGFloat = 0.82
    static let pocketWashPlateau: CGFloat = 24
    static let pocketWashEnd: CGFloat = 64
    static let pocketWashBottom: CGFloat = 0.10
    /// Alpha ramp: fully opaque until `pocketFadeStart`, 0 at pocketHeight.
    static let pocketFadeStart: CGFloat = 56

    func updatePocket() {
        guard prefersLargeTitles, let scroll = trackedScrollView,
              let content = scroll.superview, bounds.width > 0 else {
            pocketView.isHidden = true
            pocketKey = nil
            return
        }
        // Engagement: nothing to blur until content actually reaches under
        // the bar zone (d = 52 puts the content top exactly at the zone's
        // bottom edge); ramp in over the next 28 pt.
        let e = clamp01((collapseDistance - UINavigationBar.largeTitleZoneHeight) / 28)
        guard e > 0 else {
            pocketView.isHidden = true
            pocketKey = nil
            return
        }
        let key = (offsetY: scroll.contentOffset.y, width: bounds.width,
                   engagement: e)
        if let k = pocketKey, k == key {
            pocketView.isHidden = false
            return
        }
        pocketKey = key
        let scale = max(UITraitCollection.current.displayScale, 1)
        content.layoutIfNeeded()
        let snapshot = UIRenderer.render(content, scale: scale)
        let bg = (backgroundColorForPocket ?? .white).cgColor
        let bitmap = UINavigationBar.pocketBitmap(from: snapshot, scale: scale,
                                                 background: bg)
        pocketView.image = UIImage(bitmap: bitmap, scale: scale)
        pocketView.frame = CGRect(x: 0, y: 0, width: bounds.width,
                                  height: UINavigationBar.pocketHeight)
        pocketView.alpha = e
        pocketView.isHidden = false
    }

    /// The color the pocket washes toward: the nearest opaque ancestor
    /// background (the navigation container view), resolved for the
    /// current style.
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
