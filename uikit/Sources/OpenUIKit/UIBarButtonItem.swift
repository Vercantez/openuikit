// UIBarButtonItem + the shared bar-button rendering. Owner: viewcontroller
// module (M13 "bars & appearance").
//
// `UIBarButtonItem` is the largest missing type in the app-compat census
// (270 uses across the four-app corpus, every app) and the reason
// `UINavigationItem` is worth anything: it is how every real code-based app
// puts controls in its bars.
//
// ============================================================================
// MEASURED GROUND TRUTH — real iOS 26.1, iPhone 16, compact width
// (Tools/oracle2/simscene through scripts/render_sim_scenes.sh; the probe
// trees are reproducible with SIMCTL_CHILD_SIMSCENE_DEBUG=1).
// ============================================================================
//
// iOS 26 redesigned bar buttons around "liquid glass": every item sits in its
// own capsule PLATTER floating over the bar's (usually transparent) backdrop.
// The measured layout, from `_UINavigationBarPlatterView` /
// `_UIModernBarButton` frames:
//
//   platter        height 44, corner radius 22 (a capsule), top-aligned in
//                  the 54 pt bar zone (bar-local y 0 ... 44)
//   side margin    16 pt from the bar's leading / trailing edge
//   gap            12 pt between two platters of the same group
//   content inset  16 pt each side  (platter width = content width + 32;
//                  measured as item-view inset 4 + button inset 12)
//   title          17 pt system MEDIUM, cap height box 20.333 pt, its top at
//                  platter-local y 12 (so its box is centred on the platter)
//   image          drawn at its own point size, centred in the platter
//   min platter    44 pt wide (an image-only item is a 44 x 44 circle)
//
// Colors (measured from the goldens, NOT from the model values — the glass
// material re-derives the foreground):
//
//   title / image   `label`. NOTE: this is NOT the tintColor. iOS 26 renders
//                   an untinted bar button monochrome even when the bar's
//                   tintColor is explicitly systemBlue (probed both ways).
//                   An item with its OWN `tintColor` set IS honored.
//   disabled        (60, 60, 67) at alpha 0.298 — `tertiaryLabel`.
//   prominent       tintColor-filled platter, white content (this is what
//                   iOS 26 renders `.done` / `UIBarButtonItem.Style.done`
//                   as; the style was literally renamed `.prominent`).
//
// iOS-cut light platters now route through `_UIGlassMaterial` (measured
// mix α=222/255, T=220/α, σ=2.25 pt, 1 pt inner ring — sample table on
// that type). Catalyst and dark iOS keep the measured FLAT fills: white
// in light Catalyst, (25, 25, 25) in dark, plus the measured soft shadow.
// `.done` / prominent platters stay tint-filled (not glass). Over a
// saturated backdrop the two-unknown mix's red residual is reported in
// the glass-material agent report; fixtures stay on white / black / #F2F2F7.
//
// DIVERGENCE (SF Symbols): several `barButtonSystemItem`s render as SF
// Symbols on iOS 26, and SF Symbols are not portable (no font, no license to
// vendor). MEASURED: exactly `.edit` and `.save` render as TEXT ("Edit" /
// "Save") and are therefore exact; every other symbol-backed system item
// draws a hand-fitted vector equivalent (see `_BarSymbol`). Those vectors
// are approximations and are NOT covered by a golden; the fixtures use the
// text-backed system items, custom titles and synthesized template images,
// all of which are exact.

/// A button (or a space) in a `UINavigationBar` / `UIToolbar`.
@preconcurrency @MainActor
public class UIBarButtonItem {
    /// UIKit's bar-button styles. iOS 26 renamed `.done` to `.prominent`
    /// (a tint-filled platter); both spellings are kept.
    public enum Style: Int, Sendable {
        case plain = 0
        case done = 2
        /// iOS 26's name for `.done`.
        public static var prominent: Style { .done }
    }

    /// The subset of `UIBarButtonItem.SystemItem` a portable renderer can
    /// serve. See the file header for which ones are text and which are
    /// approximated vectors.
    public enum SystemItem: Int, Sendable, CaseIterable {
        case done, cancel, edit, save, add, flexibleSpace, fixedSpace
        case compose, reply, action, organize, bookmarks, search, refresh
        case stop, camera, trash, play, pause, rewind, fastForward
        case undo, redo, close
    }

    public var title: String?
    public var image: UIImage?
    public var style: Style
    public var isEnabled: Bool = true
    /// Per-item tint. `nil` inherits the bar's, and an inherited tint is
    /// NOT applied to the content (measured — see the file header).
    public var tintColor: UIColor?
    /// Width for `.fixedSpace` (and a fixed width for a normal item when > 0).
    public var width: CGFloat = 0
    public var customView: UIView?
    public private(set) var systemItem: SystemItem?
    /// Stable identifier consumed by UIKit's accessibility tree and UI tests.
    /// OpenUIKit currently has no assistive-technology tree, so—as with the
    /// other accessibility properties—this is faithful round-trip storage.
    /// Real UIKit also keeps it on the UIBarItem rather than copying it onto
    /// the private descendant UIView (iOS 26.1 runtime probe).
    public var accessibilityIdentifier: String?
    /// Target-action, dispatched through the M12 selector machinery.
    public weak var target: AnyObject?
    public var action: Selector?
    /// UIKit's closure-shaped alternative to target/action (iOS 14+). The
    /// bars run it on `.touchUpInside` alongside `action`, and
    /// `init(primaryAction:)` seeds the item's title and image from it —
    /// which is what lets an app that must compile against BOTH real UIKit
    /// and OpenUIKit wire a bar button without `@objc`/`#selector`
    /// (Sources/ConformanceApps/NavFlow, docs/OBJC_RUNTIME.md).
    public var primaryAction: UIAction?

    /// SwiftUI-installed image items (Hackers settings / search) keep their
    /// own 44×44 platter. MEASURED realapp_hackers_feed_light, iPhone 16 @3x:
    /// settings `[277, 0, 44, 44]` and search `[333, 0, 44, 44]`, gap 12,
    /// trailing margin 16 — two platters, not one grouped run.
    public var _isolatesPlatter = false
    /// SwiftUI toolbar custom views (Hackers settings gear, Authentication
    /// xmark) still sit in a 44×44 glass platter. Arbitrary UIKit
    /// `init(customView:)` stays platter-free.
    public var _showsPlatterWithCustomView = false

    /// Set by the bar that owns the item so a mutation can trigger a relayout.
    weak var _bar: _UIBarItemContainer?
    /// UIKit permits one assistant/navigation customization group association
    /// per item. Managed by `UIBarButtonItemGroup`.
    weak var _buttonGroup: UIBarButtonItemGroup?
    public var buttonGroup: UIBarButtonItemGroup? { _buttonGroup }

    // MARK: Initializers (UIKit's own signatures)

    public init() {
        style = .plain
    }

    public init(title: String?, style: Style = .plain,
                target: AnyObject? = nil, action: Selector? = nil) {
        self.title = title
        self.style = style
        self.target = target
        self.action = action
    }

    public init(image: UIImage?, style: Style = .plain,
                target: AnyObject? = nil, action: Selector? = nil) {
        self.image = image
        self.style = style
        self.target = target
        self.action = action
    }

    /// UIKit's `init(primaryAction:)`: the action's title and image become
    /// the item's, and the action runs when the item is tapped.
    public init(primaryAction: UIAction?) {
        self.primaryAction = primaryAction
        self.title = primaryAction?.title
        self.image = primaryAction?.image
        style = .plain
    }

    public init(customView: UIView) {
        self.customView = customView
        style = .plain
    }

    public init(barButtonSystemItem systemItem: SystemItem,
                target: AnyObject? = nil, action: Selector? = nil) {
        self.systemItem = systemItem
        self.target = target
        self.action = action
        // Measured on iOS 26: only these two render as text; `.done` is a
        // PROMINENT checkmark, everything else a plain symbol.
        switch systemItem {
        case .edit: title = "Edit"
        case .save: title = "Save"
        case .done: style = .done
        default: break
        }
        self.style = systemItem == .done ? .done : .plain
    }

    /// True for `.flexibleSpace` / `.fixedSpace` — items that occupy width
    /// but draw nothing.
    public var _isSpace: Bool {
        systemItem == .flexibleSpace || systemItem == .fixedSpace
    }
    public var _isFlexibleSpace: Bool { systemItem == .flexibleSpace }

    /// The vector glyph this item draws, if any.
    var _symbol: _BarSymbol? {
        guard let systemItem, title == nil, image == nil else { return nil }
        return _BarSymbol.forSystemItem(systemItem)
    }
}

/// Anything that lays bar button items out and needs to hear about a
/// mutation (`isEnabled`, `title`, …).
@preconcurrency @MainActor
protocol _UIBarItemContainer: AnyObject {
    func _barItemsChanged()
}

// MARK: - Measured metrics

@preconcurrency @MainActor
public enum _UIBarMetrics {
    /// Capsule platter height in a NAVIGATION bar (measured: the
    /// `_UINavigationBarPlatterView` frames are 44 tall, top-aligned at the
    /// bar's own y = 0, corner radius 22).
    public static let platterHeight: CGFloat = 44
    /// Capsule platter height in a TOOLBAR. Measured separately and it is
    /// NOT the same number: the toolbar's `_UIPlatformGlassInteractionView`
    /// is 48 tall (radius 24), also top-aligned at the bar's y = 0 — fitted
    /// from the chord a red-backdrop probe shows at x = 24 pt
    /// (y 6.1 … 41.9 for a 48/24 capsule; a 44/22 one would give 1.5 … 42.5).
    public static let toolbarPlatterHeight: CGFloat = 48
    public static var platterRadius: CGFloat { platterHeight / 2 }
    /// Leading / trailing margin from the bar's edge.
    public static let sideMargin: CGFloat = 16
    /// Gap between adjacent platters.
    public static let gap: CGFloat = 12
    /// Horizontal inset from the platter edge to the content.
    public static let contentInset: CGFloat = 16
    /// A platter is never narrower than it is tall.
    public static var minPlatterWidth: CGFloat { platterHeight }
    /// IMAGE items are narrower than title items. MEASURED (iOS 26.1, a
    /// dark opaque bar, five solid images 10/18/24/30/40 pt wide): the
    /// `_UIModernBarButton` is `max(22, imageWidth)` wide, the
    /// `_UIButtonBarButton` adds 7 a side and the platter 4 a side, so an
    /// 18 pt image sits centred in a 44 pt platter (not 18 + 2 × 16 = 50,
    /// which pushed every item leading it 6 pt off in `navitem_dark`).
    public static let imageContentMinWidth: CGFloat = 22
    public static let imageContentInset: CGFloat = 11
    /// iOS 26 GROUPS adjacent image-only items into ONE platter (MEASURED
    /// with five images: platter [97, 30, 280, 44] = 16 pt between the
    /// 36-wide `_UIButtonBarButton`s plus 4 pt of platter padding at each
    /// end). In item-view terms — each view already carries 4 pt of
    /// platter on either side — that is an 8 pt gap between the views.
    public static let groupedImageGap: CGFloat = 8
    /// Gap accounting (measured, `toolbar_basic`): a 12 pt gap separates
    /// consecutive bar items, EXCEPT after a space item — a fixed space of
    /// 40 pt shows up as 12 + 40 before the next item, and the item after a
    /// flexible space gets no extra gap at all.
    /// Item title font.
    public static let titleFontSize: CGFloat = 17
    /// Measured platter shadow. Least-squares fit of (opacity, sigma,
    /// offset) to the golden's own falloff around the `navitem_buttons`
    /// leading platter (`python3 Tools/compare/fit_bar_shadow.py`):
    /// rms residual 2.3 counts over the whole ring around the capsule.
    /// The darkest pixel just outside a white platter on white is 244 (Δ11).
    public static let shadowOpacity: Float = 0.075
    public static let shadowRadius: CGFloat = 10
    public static let shadowOffset = CGSize(width: 0, height: 4)

    /// Flat fallback when `_UIGlassMaterial` does not apply (Catalyst, dark,
    /// `.done` tint fill): measured white over a light backdrop, (25, 25, 25)
    /// over a dark one.
    public static let platterFill = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(red: 25 / 255, green: 25 / 255, blue: 25 / 255, alpha: 1)
            : UIColor(red: 1, green: 1, blue: 1, alpha: 1)
    })
    /// White content on a prominent (tint-filled) platter.
    public static let prominentContent = UIColor(red: 1, green: 1, blue: 1, alpha: 1)

    /// The glass lens REFRACTS rather than frosts the top of a navigation-bar
    /// platter: measured on both `navitem_dark` (fill (25,25,25) only from
    /// scene y 24.5 down, pure black above) and `navbar_appearance` (bar
    /// colour above y 25, platter colour below), i.e. the top **14.5 pt** of
    /// the 44 pt capsule shows the BACKDROP unchanged. Reproduced by washing
    /// that band back to the bar's own background colour — which is only
    /// possible when the bar HAS a flat background; over a transparent bar
    /// the band is left frosted (there the backdrop is the content, and no
    /// portable renderer can sample it).
    ///
    /// The measurement is nav-bar-only: a standalone `UIToolbar` platter
    /// probed over a saturated backdrop shows a UNIFORM fill with no cut,
    /// so `UIToolbar` does not apply it.
    public static let platterRefractionHeight: CGFloat = 14.5
}

// MARK: - The item view

/// One laid-out bar button: platter + content (title label, image view or a
/// custom view). A `UIControl`, so `target`/`action` and the closure form
/// both work through the normal control path.
@preconcurrency @MainActor
final class _UIBarButtonItemView: UIControl {
    let item: UIBarButtonItem
    let platter = UIView()
    let titleLabel = UILabel()
    let imageView = UIImageView()
    let symbolView = _BarSymbolView()
    /// The bar-wide tint (used only for a prominent platter's fill).
    var barTintColor: UIColor = .systemBlue { didSet { applyColors() } }
    /// Bars whose appearance turns the platter off (a plain/legacy bar).
    var showsPlatter: Bool = true { didSet { platter.isHidden = !showsPlatter } }
    /// Platter height for the owning bar (nav bars 44, toolbars 48 —
    /// measured, see `_UIBarMetrics`).
    var platterHeight: CGFloat = _UIBarMetrics.platterHeight {
        didSet {
            platter.layer.cornerRadius = platterHeight / 2
            refractionHost.layer.cornerRadius = platterHeight / 2
        }
    }
    /// The bar's own flat background, used to wash the glass lens's
    /// refractive top band (`_UIBarMetrics.platterRefractionHeight`).
    /// `nil` (a transparent bar) leaves the band frosted.
    var backdropColor: UIColor? { didSet { setNeedsLayout() } }
    /// Clips the wash to the capsule; `clipsToBounds` suppresses its own
    /// shadow, so the platter underneath still casts the measured one.
    let refractionHost = UIView()
    let refractionBand = UIView()

    init(item: UIBarButtonItem) {
        self.item = item
        super.init(frame: .zero)
        isOpaque = false
        platter.isOpaque = false
        platter.layer.cornerRadius = _UIBarMetrics.platterRadius
        platter.layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        platter.layer.shadowOpacity = _UIBarMetrics.shadowOpacity
        platter.layer.shadowRadius = _UIBarMetrics.shadowRadius
        platter.layer.shadowOffset = _UIBarMetrics.shadowOffset
        platter.isUserInteractionEnabled = false
        addSubview(platter)
        refractionHost.isUserInteractionEnabled = false
        refractionHost.clipsToBounds = true
        refractionHost.layer.cornerRadius = _UIBarMetrics.platterRadius
        refractionHost.addSubview(refractionBand)
        platter.addSubview(refractionHost)
        titleLabel.text = item.title
        titleLabel.font = .systemFont(ofSize: _UIBarMetrics.titleFontSize,
                                      weight: .medium)
        titleLabel.textAlignment = .center
        platter.addSubview(titleLabel)
        platter.addSubview(imageView)
        platter.addSubview(symbolView)
        isEnabled = item.isEnabled
        applyColors()
    }

    @available(*, unavailable, message: "bar button item views require a UIBarButtonItem")
    required init?(coder: NSCoder) {
        fatalError("bar button item views cannot be decoded")
    }

    /// Foreground color: `label`, the item's own tint when it has one,
    /// `tertiaryLabel` when disabled, white on a prominent platter.
    var contentColor: UIColor {
        if !item.isEnabled { return .tertiaryLabel }
        if item.style == .done { return _UIBarMetrics.prominentContent }
        return item.tintColor ?? .label
    }

    func applyColors() {
        let color = contentColor
        titleLabel.textColor = color
        symbolView.color = color
        symbolView.symbol = item._symbol
        if let image = item.image {
            imageView.image = UITabBar.templateImage(
                image, tint: color.resolvedColor(with: UITraitCollection.current))
        }
        // The content is a subview of the platter, so a grouped item's own
        // platter goes transparent (fill, shadow, band) rather than hidden.
        platter.backgroundColor = _platterHiddenByGroup ? UIColor.clear
            : item.style == .done ? (item.tintColor ?? barTintColor)
            : _UIBarMetrics.platterFill
        // Glass samples the backdrop. `.done` is a tint fill (measured
        // prominent style); grouped items yield to `_UIBarSharedPlatterView`.
        platter._usesIOSGlass = !_platterHiddenByGroup && item.style != .done && showsPlatter
        // Toolbar platters (no refractive band) use the dark bar mix;
        // nav-bar platters keep the measured dark flats. MEASURED
        // /tmp/glass-dark-out glass_toolbar_dark_black: 19 over black,
        // same mix as the tab bar (Tabs t1000.dark Left interior 19 vs
        // the previous shared platterFill 25).
        platter._usesIOSDarkBarGlass = platter._usesIOSGlass && !appliesRefraction
        platter.layer.shadowOpacity = _platterHiddenByGroup ? 0 : _UIBarMetrics.shadowOpacity
        platter.isHidden = !showsPlatter
    }

    /// Only navigation-bar platters show the refractive band (measured —
    /// see `_UIBarMetrics.platterRefractionHeight`). Toolbar platters
    /// also use this to select the dark bar glass mix.
    var appliesRefraction = true {
        didSet { if appliesRefraction != oldValue { applyColors() } }
    }

    /// An item that shows only an image / symbol (no title, no custom
    /// view): iOS 26 merges runs of these into one platter.
    var isImageOnly: Bool {
        item.customView == nil && item.title == nil && !item._isSpace
            && (item.image != nil || item._symbol != nil)
    }
    /// Set by the bar for the members of a merged run (their platter is
    /// the bar's `_UIBarSharedPlatterView`).
    var _platterHiddenByGroup = false {
        didSet { if _platterHiddenByGroup != oldValue { applyColors(); setNeedsLayout() } }
    }

    /// Content size inside the platter.
    var contentSize: CGSize {
        if let cv = item.customView {
            let s = cv.bounds.size
            return s == .zero ? cv.sizeThatFits(.zero) : s
        }
        if item.title != nil { return titleLabel.intrinsicContentSize }
        if let image = item.image { return image.size }
        if let symbol = item._symbol { return symbol.size }
        return .zero
    }

    override func sizeThatFits(_ size: CGSize) -> CGSize {
        if item.customView != nil {
            return CGSize(width: contentSize.width, height: platterHeight)
        }
        if item.title == nil, item.image != nil || item._symbol != nil {
            // Image / symbol items: see `_UIBarMetrics.imageContentMinWidth`.
            let w = max(_UIBarMetrics.imageContentMinWidth, contentSize.width)
                + 2 * _UIBarMetrics.imageContentInset
            return CGSize(width: w, height: platterHeight)
        }
        let w = max(contentSize.width + 2 * _UIBarMetrics.contentInset,
                    platterHeight)
        return CGSize(width: w, height: platterHeight)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        platter.frame = bounds
        refractionHost.frame = platter.bounds
        let band = _UIBarMetrics.platterRefractionHeight
        refractionBand.frame = CGRect(x: 0, y: 0, width: bounds.width, height: band)
        refractionBand.backgroundColor = backdropColor
        refractionHost.isHidden = backdropColor == nil || item.style == .done
            || !showsPlatter || !appliesRefraction || _platterHiddenByGroup
        platter.sendSubviewToBack(refractionHost)   // under the content
        if let cv = item.customView {
            if cv.superview !== self { addSubview(cv) }
            let s = contentSize
            cv.frame = CGRect(x: (bounds.width - s.width) / 2,
                              y: (bounds.height - s.height) / 2,
                              width: s.width, height: s.height)
            // UIKit `init(customView:)` has no platter. SwiftUI toolbar
            // image items keep the measured 44×44 glass (Hackers settings).
            platter.isHidden = !(showsPlatter && item._showsPlatterWithCustomView)
            return
        }
        let s = contentSize
        let f = CGRect(x: ((bounds.width - s.width) / 2).rounded() ,
                       y: ((bounds.height - s.height) / 2).rounded(),
                       width: s.width, height: s.height)
        titleLabel.frame = f
        imageView.frame = f
        symbolView.frame = f
        titleLabel.isHidden = item.title == nil
        imageView.isHidden = item.image == nil
        symbolView.isHidden = item._symbol == nil
    }

    /// Pressed feedback: the same measured dimming plain system buttons use.
    override func stateDidChange() {
        super.stateDidChange()
        let a: CGFloat = isHighlighted ? UIButton.systemHighlightedTitleAlpha : 1
        titleLabel.alpha = a
        imageView.alpha = a
        symbolView.alpha = a
        item.customView?.alpha = a
    }
}

// MARK: - Shared platter (iOS 26 image-item runs)

/// The one platter behind a run of adjacent image-only items: the item
/// platter's flat fill, shadow and refractive top band, sized by the bar.
@preconcurrency @MainActor
final class _UIBarSharedPlatterView: UIView {
    let refractionHost = UIView()
    let refractionBand = UIView()
    var backdropColor: UIColor? { didSet { setNeedsLayout() } }

    override init(frame: CGRect) {
        super.init(frame: frame)
        isUserInteractionEnabled = false
        isOpaque = false
        _usesIOSGlass = true
        layer.cornerRadius = _UIBarMetrics.platterRadius
        layer.shadowColor = CGColor(red: 0, green: 0, blue: 0, alpha: 1)
        layer.shadowOpacity = _UIBarMetrics.shadowOpacity
        layer.shadowRadius = _UIBarMetrics.shadowRadius
        layer.shadowOffset = _UIBarMetrics.shadowOffset
        backgroundColor = _UIBarMetrics.platterFill
        refractionHost.isUserInteractionEnabled = false
        refractionHost.clipsToBounds = true
        refractionHost.layer.cornerRadius = _UIBarMetrics.platterRadius
        refractionHost.addSubview(refractionBand)
        addSubview(refractionHost)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("not decodable") }

    override func layoutSubviews() {
        super.layoutSubviews()
        refractionHost.frame = bounds
        refractionBand.frame = CGRect(x: 0, y: 0, width: bounds.width,
                                      height: _UIBarMetrics.platterRefractionHeight)
        refractionBand.backgroundColor = backdropColor
        refractionHost.isHidden = backdropColor == nil
    }
}

// MARK: - Shared bar item layout

/// Lays a row of `UIBarButtonItem`s out inside `bounds`, honoring flexible
/// and fixed spaces. Shared by `UINavigationBar` (leading / trailing groups)
/// and `UIToolbar` (one full-width row).
@preconcurrency @MainActor
enum _UIBarItemLayout {
    /// Natural width of one item view (0 for a flexible space).
    static func width(of view: _UIBarButtonItemView) -> CGFloat {
        let item = view.item
        if item._isFlexibleSpace { return 0 }
        if item.systemItem == .fixedSpace { return item.width }
        if item.width > 0 { return item.width }
        return view.sizeThatFits(.zero).width
    }

    /// Gap inserted BEFORE `views[i]`. Measured (`toolbar_basic`): the
    /// 12 pt separation appears between consecutive elements except when
    /// the previous element is a space — a fixed space contributes
    /// `12 + width`, and the item after a space gets no gap of its own.
    static func gapBefore(_ views: [_UIBarButtonItemView], _ i: Int) -> CGFloat {
        guard i > 0, !views[i - 1].item._isSpace else { return 0 }
        if OpenUIKitRuntime.systemFontCut == .iOS,
           views[i - 1].isImageOnly, views[i].isImageOnly,
           !views[i - 1].item._isolatesPlatter,
           !views[i].item._isolatesPlatter {
            return _UIBarMetrics.groupedImageGap
        }
        return _UIBarMetrics.gap
    }

    /// iOS 26: each run of two or more adjacent image-only views (in
    /// `views` order; a space breaks a run) shares ONE platter, a
    /// `_UIBarSharedPlatterView` the bar owns and keeps beneath the items.
    /// Returns the frames of the shared platters (bar coordinates) and
    /// hides the members' own platters.
    static func sharedPlatterFrames(_ views: [_UIBarButtonItemView]) -> [CGRect] {
        for v in views { v._platterHiddenByGroup = false }
        guard OpenUIKitRuntime.systemFontCut == .iOS else { return [] }
        var frames: [CGRect] = []
        var run: [_UIBarButtonItemView] = []
        func flush() {
            defer { run.removeAll() }
            guard run.count >= 2 else { return }
            frames.append(run.dropFirst().reduce(run[0].frame) { $0.union($1.frame) })
            for v in run { v._platterHiddenByGroup = true }
        }
        for v in views {
            if v.isImageOnly && !v.isHidden && !v.item._isolatesPlatter {
                run.append(v)
            } else {
                flush()
            }
        }
        flush()
        return frames
    }

    /// Lay `views` out across `totalWidth`, left to right, distributing slack
    /// across the flexible spaces. `y`/`height` place the platters.
    static func layout(_ views: [_UIBarButtonItemView], in totalWidth: CGFloat,
                       y: CGFloat, height: CGFloat, sideMargin: CGFloat) {
        let flexCount = views.filter { $0.item._isFlexibleSpace }.count
        var fixed: CGFloat = 0
        var gaps: CGFloat = 0
        for (i, v) in views.enumerated() {
            gaps += gapBefore(views, i)
            if v.item._isFlexibleSpace { continue }
            fixed += width(of: v)
        }
        let available = totalWidth - 2 * sideMargin
        let slack = max(0, available - fixed - gaps)
        let perFlex = flexCount > 0 ? slack / CGFloat(flexCount) : 0

        var x = sideMargin
        for (i, v) in views.enumerated() {
            x += gapBefore(views, i)
            if v.item._isSpace {
                x += v.item._isFlexibleSpace ? perFlex : v.item.width
                v.frame = .zero
                v.isHidden = true
                continue
            }
            let w = width(of: v)
            v.isHidden = false
            v.frame = CGRect(x: x, y: y, width: w, height: height)
            x += w
        }
    }

    /// Total natural width of a group (no flexible spaces), including gaps.
    static func naturalWidth(_ views: [_UIBarButtonItemView]) -> CGFloat {
        var total: CGFloat = 0
        for (i, v) in views.enumerated() {
            total += gapBefore(views, i)
            if v.item._isFlexibleSpace { continue }
            total += v.item.systemItem == .fixedSpace ? v.item.width : width(of: v)
        }
        return total
    }
}
