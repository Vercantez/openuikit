// UIButton. Owner: button module.
//
// Plain legacy layout (UIButton(type: .system), no UIButtonConfiguration),
// matching the Mac Catalyst oracle (iOS 26.1 UIKit). All rules below were
// derived from oracle probes (see golden/button_basic.* and the layout
// probe results reproduced in UIButtonTests):
//
//   - Default title font: system regular 15pt.
//   - titleLabel intrinsic = UILabel intrinsic for the title/font
//     (width ceiled to pixel, height = FontEngine.labelLineHeight).
//   - Button sizeThatFits/intrinsicContentSize IGNORES the constraint:
//     (ceil(labelWidth to whole points), labelHeight + 12) — i.e. vertical
//     content insets of 6pt each side, no horizontal insets.
//     Verified sizes 11...34pt, regular + semibold: height is always
//     labelHeight + 12; width is always the whole-point ceil of the label
//     width (105.5 -> 106, 138.5 -> 139, integers unchanged).
//     Once `contentEdgeInsets` is nonzero, those explicit values replace the
//     built-in vertical padding: the height is the legacy minimum line box
//     (or taller content) plus top+bottom, and the width is content plus
//     left+right. Each inset component is first rounded half-up to a display
//     pixel; negative totals are preserved. On this explicit path an exactly
//     zero fitted axis becomes `noIntrinsicMetric` only in intrinsic sizing.
//   - `.fill` rounds each title/image inset edge independently to the display
//     pixel grid and keeps the resulting SIGNED interval. Crossed edges can
//     therefore produce negative hook sizes. UIKit standardizes those raw
//     hook rectangles only when assigning the title/image subview frames.
//   - Title rect: label frame is (ceil(labelWidth), labelHeight) centered
//     in the bounds, offsets rounded half-up to the pixel grid. When the
//     title does not fit (oracle width sweep, 14pt long title, widths
//     80..320):
//       * if the title fits at TIGHT tracking (UILabel squeeze), the
//         label gets the FULL bounds width at x = 0 and the text draws
//         squeezed to exactly floor(width) points (oracle: 300pt button,
//         309.16pt title -> label (0, 6.5, 300, 17), ink 598px @2x);
//       * otherwise the title truncates in the MIDDLE (real UIButton
//         titles use byTruncatingMiddle: oracle renders "Very…width")
//         and the label hugs the truncated line, width ceiled to whole
//         points, centered (oracle sweep: W=80 -> 75, 150 -> 146,
//         200 -> 199, 280 -> 276, 284..286 -> 283).
//   - Title color: explicit .normal color wins in EVERY state (oracle:
//     a disabled button with explicit titleColor renders that color).
//     Default enabled = tintColor; default disabled = a private gray,
//     light rgba(0.52 0.52 0.52 / 0.45), dark rgba(0.55 0.55 0.55 / 0.45)
//     (measured from oracle renders at 80pt: peak text pixels
//     light (133,133,133,115) / dark (140,140,140,115)).

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


/// The title label subclass real UIKit uses; the layout dump prints the
/// dynamic class name, so the oracle's "UIButtonLabel" entries match.
@preconcurrency @MainActor
public final class UIButtonLabel: UILabel {}

extension UIColor {
    /// The color with its alpha multiplied by `factor` (dynamic-safe).
    func withMultipliedAlpha(_ factor: CGFloat) -> UIColor {
        UIColor(.dynamic { t in
            var c = self.resolvedCGColor(with: t)
            c.alpha *= factor
            return c
        })
    }
}

@preconcurrency @MainActor
open class UIButton: UIControl {
    public enum ButtonType: Sendable {
        case custom, system
    }

    /// UIButton.State is UIControl.State (nested types are not inherited
    /// in Swift, so re-export the name).
    public typealias State = UIControl.State

    public private(set) var buttonType: ButtonType
    private let _titleLabel: UIButtonLabel
    private let _imageView: UIImageView

    /// Real UIKit exposes `titleLabel` as optional UILabel.
    public var titleLabel: UILabel? { _titleLabel }

    /// Real UIKit exposes a persistent image view even before an image has
    /// been assigned. It is optional in the API for Objective-C history, but
    /// a live UIButton owns the same view for its lifetime.
    public var imageView: UIImageView? { installImageViewIfNeeded(); return _imageView }

    private var titles: [UInt: String] = [:]
    private var attributedTitles: [UInt: NSAttributedString] = [:]
    private var titleColors: [UInt: UIColor] = [:]
    private var images: [UInt: UIImage] = [:]

    /// MEASURED (Tools/oracle2/buttonconfigprobe, `updateHandler` section):
    /// assigning `configuration` does NOT request a configuration update —
    /// the handler fires zero times for `configuration = newValue`. That is
    /// what makes KDS's handler safe: it assigns `self.configuration` from
    /// inside `configurationUpdateHandler` and the oracle never re-enters
    /// (the reentrancy probe logs `depth=1` both times).
    open var configuration: Configuration? {
        didSet { applyConfiguration() }
    }

    /// UIKit's per-state configuration hook. MEASURED firing:
    ///
    /// | trigger | handler calls |
    /// |---|---|
    /// | assigning the handler, then a layout | 1 |
    /// | `setNeedsUpdateConfiguration()` then layout | 1 |
    /// | two `setNeedsUpdateConfiguration()` then layout | 1 (coalesced) |
    /// | a layout with nothing dirty | 0 |
    /// | `isHighlighted` / `isEnabled` / `isSelected` change | 1 each |
    /// | `tintColor` change | 1 |
    /// | `configuration = newValue` | 0 |
    /// | a frame change | 0 |
    ///
    /// and it is asynchronous: `setNeedsUpdateConfiguration()` fires nothing
    /// before the next layout pass (the probe's `syncCheck/immediate` row
    /// reads 0).
    open var configurationUpdateHandler: ((UIButton) -> Void)? {
        didSet { setNeedsUpdateConfiguration() }
    }

    private var needsConfigurationUpdate = false

    /// Marks the configuration dirty. The handler runs at the next layout.
    open func setNeedsUpdateConfiguration() {
        needsConfigurationUpdate = true
        setNeedsLayout()
    }

    /// UIKit's overridable update point. The base implementation calls
    /// `configurationUpdateHandler`.
    open func updateConfiguration() {
        configurationUpdateHandler?(self)
    }

    private func performConfigurationUpdateIfNeeded() {
        guard needsConfigurationUpdate else { return }
        // Cleared BEFORE the handler runs: the handler assigns `configuration`
        // (KDS's `updateColors`), and clearing afterwards would leave the
        // button permanently dirty and relayout forever.
        needsConfigurationUpdate = false
        updateConfiguration()
    }

    /// A tint change re-runs the configuration update (measured: 1 call).
    open override var tintColor: UIColor! {
        get { super.tintColor }
        set {
            super.tintColor = newValue
            if configuration != nil || configurationUpdateHandler != nil {
                setNeedsUpdateConfiguration()
            }
        }
    }

    /// Legacy layout insets. They are physical left/right values, as on
    /// UIKit; semantic direction changes content order and leading/trailing
    /// alignment, not the meaning of these stored fields.
    open var contentEdgeInsets: UIEdgeInsets = .zero {
        didSet { if contentEdgeInsets != oldValue { setNeedsLayout() } }
    }
    open var titleEdgeInsets: UIEdgeInsets = .zero {
        didSet { if titleEdgeInsets != oldValue { setNeedsLayout() } }
    }
    open var imageEdgeInsets: UIEdgeInsets = .zero {
        didSet { if imageEdgeInsets != oldValue { setNeedsLayout() } }
    }
    private var configurationImagePadding: CGFloat = 0

    /// Default disabled title color of a plain .system button (measured
    /// from the oracle; see file header).
    static let systemDisabledTitleColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.55, alpha: 0.45)
            : UIColor(white: 0.52, alpha: 0.45)
    })

    public override init(frame: CGRect) {
        buttonType = .custom
        _titleLabel = UIButtonLabel()
        _imageView = UIImageView()
        super.init(frame: frame)
        configureButtonViews()
    }

    public required init?(coder: NSCoder) {
        buttonType = .custom
        _titleLabel = UIButtonLabel()
        _imageView = UIImageView()
        super.init(coder: coder)
        configureButtonViews()
    }

    private func configureButtonViews() {
        isOpaque = false
        _titleLabel.font = .systemFont(ofSize: 15)
        // Real UIButton titles truncate in the middle (oracle-verified).
        _titleLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(_titleLabel)
        // The image view is installed lazily (see `installImageViewIfNeeded`):
        // real UIKit creates a button's imageView on first use, and the
        // Catalyst goldens (button_basic/dark/highlighted/states,
        // demo_settings) list NO UIImageView under an image-less button —
        // the unconditional subview here was the suite's only failure
        // (5 scenes, "extra view (UIImageView)", 2026-09-04).
        updateTitleView()
        updateImageView()
    }

    /// UIKit adds the image view as a subview when an image is first set or
    /// `imageView` is first read; until then the button has one subview.
    private func installImageViewIfNeeded() {
        guard _imageView.superview == nil else { return }
        // Real UIKit inserts the image view before the title label, so a
        // button with both reports UIImageView at path *.0 in layout dumps
        // (oracle_flow button_image_title_2x, iPhone SE 2x, 2026-09-04).
        insertSubview(_imageView, at: 0)
    }

    public convenience init(type: ButtonType) {
        self.init(frame: .zero)
        buttonType = type
    }

    /// `UIButton(configuration:)` — Kickstarter's `AlertBanner` writes
    /// `UIButton(configuration: .plain())`.
    public convenience init(configuration: Configuration) {
        self.init(frame: .zero)
        buttonType = .system
        self.configuration = configuration
    }

    /// `UIButton(configuration:primaryAction:)`. MEASURED: the action's title
    /// lands in `configuration.title` (the probe reads back "Action Title"
    /// from `configuration.title`, `currentTitle` AND the label), and the
    /// action fires on `.touchUpInside`.
    public convenience init(configuration: Configuration, primaryAction: UIAction?) {
        self.init(frame: .zero)
        buttonType = .system
        var configuration = configuration
        if let primaryAction {
            configuration.title = primaryAction.title
        }
        self.configuration = configuration
        if let primaryAction {
            addAction(primaryAction, for: .touchUpInside)
        }
    }

    // MARK: - Configuration subviews

    /// The subtitle label, installed only when a configuration carries a
    /// subtitle — UIKit adds no second label otherwise, and the port's
    /// layout dumps are scored against the oracle's subview list.
    private var _subtitleLabel: UIButtonLabel?

    /// The spinner `showsActivityIndicator` installs, in the leading slot.
    private var _activityIndicator: UIActivityIndicatorView?

    private func installSubtitleLabelIfNeeded() -> UIButtonLabel {
        if let existing = _subtitleLabel { return existing }
        let label = UIButtonLabel()
        // Measured: 13 pt regular (transcript `titles.titleAndSubtitle`).
        label.font = .systemFont(ofSize: Configuration.subtitleFontSize)
        _subtitleLabel = label
        addSubview(label)
        return label
    }

    private func removeSubtitleLabelIfPresent() {
        _subtitleLabel?.removeFromSuperview()
        _subtitleLabel = nil
    }

    private func installActivityIndicatorIfNeeded() -> UIActivityIndicatorView {
        if let existing = _activityIndicator { return existing }
        let indicator = UIActivityIndicatorView(style: .medium)
        indicator.hidesWhenStopped = false
        indicator.startAnimating()
        _activityIndicator = indicator
        insertSubview(indicator, at: 0)
        return indicator
    }

    private func removeActivityIndicatorIfPresent() {
        _activityIndicator?.removeFromSuperview()
        _activityIndicator = nil
    }

    // MARK: - Menus & primary action (M13)

    /// UIKit's `UIButton(primaryAction:)`: the action's title becomes the
    /// button's title and the action runs on `.touchUpInside`.
    public convenience init(type: ButtonType = .system, primaryAction: UIAction?) {
        self.init(type: type)
        if let primaryAction {
            setTitle(primaryAction.title, for: .normal)
            addAction(primaryAction, for: .touchUpInside)
        }
    }

    /// The menu this button shows. With `showsMenuAsPrimaryAction` true a
    /// tap presents it instead of firing `.touchUpInside` — UIKit's own
    /// rule, and the shape the census's `UIMenu` uses are written in.
    public var menu: UIMenu?
    public var showsMenuAsPrimaryAction = false

    /// Whether the button opts into the system pointer treatment. The value
    /// is stateful and matches UIKit's default (`false`); OpenUIKit does not
    /// yet have a host cursor renderer to consume it.
    public var isPointerInteractionEnabled = false

    /// UIKit's `performPrimaryAction()` (iOS 17+): presents the menu when
    /// `showsMenuAsPrimaryAction` is set, otherwise sends
    /// `.primaryActionTriggered` + `.touchUpInside`.
    public func performPrimaryAction() {
        if showsMenuAsPrimaryAction, let menu {
            _UIMenuPresentation.present(menu, from: self)
            return
        }
        sendActions(for: [.primaryActionTriggered, .touchUpInside])
    }

    /// UIKit: when the menu IS the primary action, a tap presents it and no
    /// `.touchUpInside` is sent — so this replaces UIControl's tap handling
    /// rather than adding to it.
    open override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard showsMenuAsPrimaryAction, let menu, isTracking,
              let touch = touches.first,
              point(inside: touch.location(in: self), with: event)
        else {
            super.touchesEnded(touches, with: event)
            return
        }
        endTracking(touch, with: event)
        isTracking = false
        isHighlighted = false
        isTouchInside = false
        _UIMenuPresentation.present(menu, from: self)
    }

    // MARK: - Title / color state

    public func setTitle(_ title: String?, for state: State) {
        titles[state.rawValue] = title
        updateTitleView()
        setNeedsLayout()
    }

    public func title(for state: State) -> String? {
        titles[state.rawValue] ?? titles[State.normal.rawValue]
    }

    /// MEASURED: a configuration's title drives `currentTitle` and the label
    /// (`UIButton(configuration:primaryAction:)` reads back "Action Title"
    /// from all three), while a legacy `setTitle(_:for:)` on a configured
    /// button leaves `configuration.title` nil and still shows — so the
    /// configuration wins when it has a title and the legacy store is the
    /// fallback, not a merge.
    public var currentTitle: String? {
        if let configured = configuration?.title { return configured }
        return title(for: state)
    }

    open func setAttributedTitle(_ title: NSAttributedString?, for state: State) {
        attributedTitles[state.rawValue] = title
        updateTitleView()
        setNeedsLayout()
    }

    open func attributedTitle(for state: State) -> NSAttributedString? {
        attributedTitles[state.rawValue]
            ?? attributedTitles[State.normal.rawValue]
    }

    open var currentAttributedTitle: NSAttributedString? {
        attributedTitle(for: state)
    }

    // MARK: Image state

    public func setImage(_ image: UIImage?, for state: State) {
        images[state.rawValue] = image
        updateImageView()
        setNeedsLayout()
    }

    /// UIKit's state lookup is exact-state then `.normal`. In particular,
    /// a button in `[.highlighted, .selected]` does not fall back to the
    /// separately assigned highlighted or selected image (iOS 26 oracle:
    /// Tools/oracle2/uihelpersprobe).
    public func image(for state: State) -> UIImage? {
        images[state.rawValue] ?? images[State.normal.rawValue]
    }

    public var currentImage: UIImage? { image(for: state) }

    public func setTitleColor(_ color: UIColor?, for state: State) {
        titleColors[state.rawValue] = color
        updateTitleView()
    }

    public func titleColor(for state: State) -> UIColor? {
        titleColors[state.rawValue] ?? titleColors[State.normal.rawValue]
    }

    public var currentTitleColor: UIColor {
        if let configuration {
            return resolvedConfigurationTitleColor(configuration)
        }
        // Explicit color for the exact highlighted state wins outright.
        if state.contains(.highlighted),
           let c = titleColors[State.highlighted.rawValue] {
            return c
        }
        // Explicit color (any-state fallback to .normal) wins even when
        // disabled; otherwise tint when enabled, system gray when disabled.
        let base: UIColor
        if let c = titleColor(for: state) {
            base = c
        } else if !isEnabled {
            base = UIButton.systemDisabledTitleColor
        } else {
            base = tintColor
        }
        if state.contains(.highlighted), isEnabled {
            // Plain .system buttons dim the title while highlighted
            // (alpha fitted against golden/button_highlighted).
            return base.withMultipliedAlpha(UIButton.systemHighlightedTitleAlpha)
        }
        return base
    }

    /// Highlight dim factor of a plain .system button's title. Measured
    /// from golden/button_highlighted: over white, the highlighted title
    /// ink is EXACTLY base·0.2 + white·0.8 per channel (tint (0,136,255) →
    /// (204,231,255); explicit systemGreen (52,199,89) → (214,243,222)) —
    /// i.e. the base title color at alpha 0.2, for default AND explicit
    /// .normal colors alike.
    static let systemHighlightedTitleAlpha: CGFloat = 0.2
    static let configurationHighlightedAlpha: CGFloat = 0.75

    // MARK: - Configuration resolution
    //
    // Every rule below is a row of Tools/oracle2/buttonconfigprobe's
    // ios-26.1-iphone16.json, measured on an iPhone 16 / iOS 26.1.

    /// The fill a `.bordered()` / `.gray()` button draws: (120, 120, 128) at
    /// alpha 0.16 light / 0.32 dark. Both halves are confirmed by the port's
    /// own golden — button_configurations_2x's bordered row samples
    /// (233, 233, 235) over white and the dark golden (38, 38, 41) over
    /// black, which are exactly those two alphas.
    static func configurationGrayFill(dark: Bool) -> UIColor {
        UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0, blue: 128.0 / 255.0,
                alpha: dark ? 0.32 : 0.16)
    }

    /// The fill EVERY configured button takes when disabled, whatever its
    /// style and whatever its `baseBackgroundColor`: (120, 120, 128) at alpha
    /// 0.12. Measured for `.filled()`, `.filled()` with a red
    /// `baseBackgroundColor`, and `.bordered()` alike. Styles with no fill at
    /// all (`.plain`, `.borderless`) stay clear when disabled.
    static let configurationDisabledFillAlpha: CGFloat = 0.12

    /// A selected button whose configuration opts into selection takes a tint
    /// fill at alpha 0.18 (measured for `.plain`, `.borderless`, `.bordered`;
    /// `.filled` has `automaticallyUpdateForSelection` false and keeps its
    /// own fill).
    static let configurationSelectedFillAlpha: CGFloat = 0.18

    /// Tint alpha of a `.tinted()` / `.borderedTinted()` fill: 0.18 light,
    /// 0.25 dark (golden-confirmed the same way as the gray fill).
    static func configurationTintedFillAlpha(dark: Bool) -> CGFloat {
        dark ? 0.25 : 0.18
    }

    /// The foreground a style uses when the configuration names none.
    /// MEASURED title colours for a fresh factory, light / dark:
    ///   filled, borderedProminent  white / white
    ///   plain, borderless, tinted, borderedTinted  tint / tint
    ///   bordered, gray, glass  black / white — i.e. `.label`
    /// The `.bordered` row is the one that corrects earlier port behaviour:
    /// the port resolved it to tint, while its OWN golden
    /// (button_configurations_2x) draws black ink in light and white in dark.
    private func configurationBaseTitleColor(_ configuration: Configuration) -> UIColor {
        switch configuration.style {
        case .filled, .borderedProminent:
            return .white
        case .plain, .borderless, .tinted, .borderedTinted:
            return tintColor
        case .bordered, .gray, .glass:
            return .label
        }
    }

    /// The fill a style derives when `background.backgroundColor` is nil.
    private func configurationStyleFill(_ configuration: Configuration) -> UIColor? {
        let dark = traitCollection.userInterfaceStyle == .dark
        let base: UIColor = configuration.baseBackgroundColor ?? tintColor
        switch configuration.style {
        case .filled, .borderedProminent:
            return base
        case .tinted, .borderedTinted:
            return base.withMultipliedAlpha(UIButton.configurationTintedFillAlpha(dark: dark))
        case .bordered, .gray:
            // The gray fill is the style's own; `baseBackgroundColor`, when
            // named, replaces the hue and keeps the measured alpha.
            guard let named = configuration.baseBackgroundColor else {
                return UIButton.configurationGrayFill(dark: dark)
            }
            return named.withMultipliedAlpha(dark ? 0.32 : 0.16)
        case .plain, .borderless, .glass:
            // No fill unless the app names one.
            return configuration.baseBackgroundColor
        }
    }

    /// The fill actually drawn, for the button's current state. This is also
    /// what `UIButton.Configuration.updated(for:)` writes into
    /// `background.backgroundColor`.
    func resolvedConfigurationBackgroundColor(_ configuration: Configuration) -> UIColor? {
        // MEASURED: an explicit `background.backgroundColor` is used VERBATIM
        // in every state — no highlight dim, no disabled substitution. A
        // `.filled()` with an explicit red renders that red when normal,
        // highlighted AND disabled. That is exactly why KDS's
        // `updateColors(with:)` and AlertBanner's handler assign a different
        // colour per state themselves.
        if let explicit = configuration.background.backgroundColor {
            return explicit
        }
        guard let base = configurationStyleFill(configuration) else {
            // A style with no fill still gains one when selected.
            if state.contains(.selected), configuration.automaticallyUpdateForSelection {
                return tintColor.withMultipliedAlpha(UIButton.configurationSelectedFillAlpha)
            }
            return nil
        }
        if !isEnabled {
            let dark = traitCollection.userInterfaceStyle == .dark
            _ = dark
            return UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0, blue: 128.0 / 255.0,
                           alpha: UIButton.configurationDisabledFillAlpha)
        }
        if state.contains(.selected), configuration.automaticallyUpdateForSelection {
            return tintColor.withMultipliedAlpha(UIButton.configurationSelectedFillAlpha)
        }
        if state.contains(.highlighted) {
            // MEASURED: the pressed fill is the normal fill with alpha times
            // 0.75 — filled 1.00 -> 0.75, bordered 0.16 -> 0.12.
            return base.withMultipliedAlpha(UIButton.configurationHighlightedAlpha)
        }
        return base
    }

    /// The title font a configuration resolves to. Measured: 15 pt for
    /// `.mini` / `.small`, 17 pt for `.medium` / `.large`; an attributed
    /// title's own font wins over that; and a `titleTextAttributesTransformer`
    /// that returns a font wins over both.
    private func resolvedConfigurationTitleFont(_ configuration: Configuration) -> UIFont {
        var font = UIFont.systemFont(
            ofSize: Configuration.titleFontSize(for: configuration.buttonSize))
        if let named = configurationAttributedFont(configuration) { font = named }
        let transformed = configurationTransformedTextAttributes(
            configuration, font: font,
            color: configurationUntreatedTitleColor(configuration))
        if let named = transformed.font { font = named }
        return font
    }

    /// The base colour before any state treatment: what the oracle hands a
    /// title transformer, and the starting point of the state rules.
    private func configurationUntreatedTitleColor(_ configuration: Configuration) -> UIColor {
        if let named = configuration.baseForegroundColor { return named }
        if let named = configurationAttributedColor(configuration) { return named }
        return configurationBaseTitleColor(configuration)
    }

    private func resolvedConfigurationTitleColor(_ configuration: Configuration) -> UIColor {
        // A legacy `setTitleColor` still wins outright, as it does without a
        // configuration (the port's established rule; not re-measured here).
        if let named = titleColor(for: state) { return named }

        let base = configurationUntreatedTitleColor(configuration)

        do {
            let transformed = configurationTransformedTextAttributes(
                configuration,
                font: UIFont.systemFont(
                    ofSize: Configuration.titleFontSize(for: configuration.buttonSize)),
                color: base)
            if let forced = transformed.color {
                    // MEASURED: a transformer's colour is final, in every
                    // state and at full alpha. A `.filled()` whose
                    // transformer forces systemGreen renders systemGreen when
                    // normal, highlighted AND disabled — where the same
                    // configuration without one renders systemGreen, then
                    // systemGreen at 0.75, then tertiaryLabel. KDS relies on
                    // exactly this to colour its disabled buttons; its source
                    // comment says the base colour "does not actually get
                    // used when determining text color for disabled buttons".
                    return forced
            }
        }

        // MEASURED: disabled ignores `baseForegroundColor` and every style
        // default, and draws `tertiaryLabel` — (60, 60, 67) at alpha 0.298,
        // identical across `.filled`, `.bordered`, `.borderless` and
        // `.plain`, and unchanged by an explicit green base colour.
        if !isEnabled { return .tertiaryLabel }
        if state.contains(.highlighted) {
            return base.withMultipliedAlpha(UIButton.configurationHighlightedAlpha)
        }
        return base
    }

    private func applyConfiguration() {
        guard let configuration else {
            configurationImagePadding = 0
            layer.borderWidth = 0
            layer.borderColor = nil
            layer.cornerRadius = 0
            backgroundColor = nil
            contentEdgeInsets = .zero
            // MEASURED: clearing a configuration returns the button to the
            // legacy path — a titleless button reports intrinsic 30 x 30, the
            // port's own legacy floor for the 15 pt default.
            _titleLabel.font = .systemFont(ofSize: 15)
            _titleLabel.lineBreakMode = .byTruncatingMiddle
            _titleLabel.numberOfLines = 1
            removeSubtitleLabelIfPresent()
            removeActivityIndicatorIfPresent()
            updateTitleView()
            updateImageView()
            setNeedsLayout()
            return
        }
        // A configuration title does NOT become a legacy `.normal` title:
        // measured, `setTitle(_:for:)` on a configured button leaves
        // `configuration.title` nil while still driving the label, so the two
        // stores stay separate and the configuration wins when it has a title.
        if let image = configuration.image {
            images[State.normal.rawValue] = image.withRenderingMode(.alwaysTemplate)
        }
        _titleLabel.font = resolvedConfigurationTitleFont(configuration)
        // MEASURED: the default `.byWordWrapping` gives the label
        // `numberOfLines = 0`; a truncating mode gives it 1. In a 140 pt wide
        // button a long title wraps to three lines (60.33333 tall) under
        // `.byWordWrapping` and stays on one (20.33333) under
        // `.byTruncatingTail`.
        _titleLabel.lineBreakMode = configuration.titleLineBreakMode
        _titleLabel.numberOfLines =
            UIButton.isWrapping(configuration.titleLineBreakMode) ? 0 : 1
        _titleLabel.textAlignment = UIButton.textAlignment(for: configuration.titleAlignment)
        configurationImagePadding = configuration.imagePadding
        contentEdgeInsets = physicalInsets(configuration.contentInsets)

        if configurationSubtitleIsPresent(configuration) {
            let label = installSubtitleLabelIfNeeded()
            label.font = .systemFont(ofSize: Configuration.subtitleFontSize)
            label.lineBreakMode = configuration.subtitleLineBreakMode
            label.numberOfLines =
                UIButton.isWrapping(configuration.subtitleLineBreakMode) ? 0 : 1
            label.textAlignment = UIButton.textAlignment(for: configuration.titleAlignment)
        } else {
            removeSubtitleLabelIfPresent()
        }

        if configuration.showsActivityIndicator {
            _ = installActivityIndicatorIfNeeded()
        } else {
            removeActivityIndicatorIfPresent()
        }

        updateTitleView()
        updateImageView()
        setNeedsLayout()
    }

    private func configurationSubtitleIsPresent(_ configuration: Configuration) -> Bool {
        if let subtitle = configuration.subtitle, !subtitle.isEmpty { return true }
        return false
    }

    /// `NSDirectionalEdgeInsets` are leading/trailing; the port's legacy
    /// layout stores physical left/right, so resolve once here.
    private func physicalInsets(_ insets: NSDirectionalEdgeInsets) -> UIEdgeInsets {
        let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
        return UIEdgeInsets(top: insets.top,
                            left: rtl ? insets.trailing : insets.leading,
                            bottom: insets.bottom,
                            right: rtl ? insets.leading : insets.trailing)
    }

    static func isWrapping(_ mode: NSLineBreakMode) -> Bool {
        switch mode {
        case .byWordWrapping, .byCharWrapping: return true
        case .byClipping, .byTruncatingHead, .byTruncatingTail, .byTruncatingMiddle:
            return false
        }
    }

    /// MEASURED label `textAlignment` per title alignment, on a 260 pt wide
    /// title+subtitle button: `.automatic` gives natural, `.leading` left,
    /// `.center` centre, `.trailing` right — and the subtitle's x moves with
    /// it inside the title block while the title's own x does not.
    static func textAlignment(for alignment: Configuration.TitleAlignment)
        -> NSTextAlignment {
        switch alignment {
        case .automatic: return .natural
        case .leading: return .left
        case .center: return .center
        case .trailing: return .right
        }
    }

    private func updateConfigurationAppearance() {
        guard let configuration else { return }
        let traits = traitCollection
        backgroundColor = resolvedConfigurationBackgroundColor(configuration)?
            .resolvedColor(with: traits)
        // MEASURED: UIKit inserts a `_UISystemBackgroundStrokeView` whose
        // layer carries `borderWidth = background.strokeWidth` and
        // `borderColor = background.strokeColor`, drawn INSIDE the bounds (a
        // 2 pt red stroke paints rows 0-1 and the last two rows of a 44 pt
        // button). The port draws the same border on the button's own layer;
        // the extra view is not modelled.
        if let stroke = configuration.background.strokeColor,
           configuration.background.strokeWidth > 0 {
            layer.borderWidth = configuration.background.strokeWidth
            layer.borderColor = stroke.resolvedCGColor(with: traits)
        } else {
            layer.borderWidth = 0
            layer.borderColor = nil
        }
        _activityIndicator?.color = resolvedConfigurationTitleColor(configuration)
        if let transformer = configuration.imageColorTransformer {
            _imageView.tintColor = transformer(resolvedConfigurationTitleColor(configuration))
        }
    }

    /// The corner radius a configuration resolves to at a given height.
    /// MEASURED across heights 20 / 28 / 34 / 44 / 60 at width 160:
    ///
    /// | style | radius |
    /// |---|---|
    /// | `.fixed` | `background.cornerRadius` |
    /// | `.dynamic` | `min(height / 2, background.cornerRadius)` |
    /// | `.small` | `height * 0.125` |
    /// | `.medium` | `height * 0.175` |
    /// | `.large` | `height * 0.25` |
    /// | `.capsule` | `height / 2` |
    ///
    /// The four proportional styles ignore `background.cornerRadius`: with it
    /// set to 6, a 44 pt button still measures 5.5 / 7.7 / 11.
    static func configurationCornerRadius(_ configuration: Configuration,
                                          height: CGFloat) -> CGFloat {
        let height = Swift.max(0, height)
        switch configuration.cornerStyle {
        case .fixed:
            return configuration.background.cornerRadius
        case .dynamic:
            return Swift.min(height / 2, configuration.background.cornerRadius)
        case .small:
            return height * 0.125
        case .medium:
            return height * 0.175
        case .large:
            return height * 0.25
        case .capsule:
            return height / 2
        }
    }

    private func updateTitleView() {
        _titleLabel.textColor = currentTitleColor
        if let configuration {
            _titleLabel.font = resolvedConfigurationTitleFont(configuration)
            if let attributed = configurationAttributedText(
                configuration, defaultFont: _titleLabel.font,
                defaultColor: currentTitleColor) {
                _titleLabel.attributedText = attributed
            } else {
                _titleLabel.text = currentTitle
            }
            if let subtitleLabel = _subtitleLabel {
                subtitleLabel.text = configuration.subtitle
                subtitleLabel.textColor = currentTitleColor
            }
            return
        }
        if let title = currentAttributedTitle {
            _titleLabel.attributedText = title
        } else {
            _titleLabel.text = currentTitle
        }
    }

    private func updateImageView() {
        if currentImage != nil { installImageViewIfNeeded() }
        _imageView.image = currentImage
        _imageView.isHidden = currentImage == nil
    }

    open override func stateDidChange() {
        super.stateDidChange()
        // MEASURED: every state change requests a configuration update, and
        // the handler runs at the next layout — 1 call each for
        // `isHighlighted`, `isEnabled` and `isSelected`.
        if configuration != nil || configurationUpdateHandler != nil {
            setNeedsUpdateConfiguration()
        }
        updateConfigurationAppearance()
        updateTitleView()
        updateImageView()
    }



    // MARK: - Sizing

    /// Legacy plain buttons ignore the constraint entirely (oracle:
    /// sizeThatFits(200) of a 211pt title reports 211).
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        if let configuration {
            return configurationSizeThatFits(configuration)
        }
        var title = _titleLabel.intrinsicContentSize
        // iOS cut, MEASURED 2026-09-04 (scripts/ios_suite.sh button_states,
        // iOS 26.1): a legacy button's title box is the font's lineHeight
        // rounded up to a WHOLE point (11 pt -> 14, 13 -> 16, 17 -> 21,
        // 24 -> 29), unlike a UILabel's pixel-grid ceiling (20.333 for 17).
        if OpenUIKitRuntime.systemFontCut == .iOS {
            title.height = _titleLabel.font.lineHeight.rounded(.up)
        }
        let titleSize = (_titleLabel.text?.isEmpty == false) ? title : .zero
        let imageSize = currentImage?.size ?? .zero
        let spacing = (imageSize.width > 0 && titleSize.width > 0)
            ? configurationImagePadding : 0
        // The image+title rect oracle floors the title's half-point
        // intrinsic width ("Go": 20.5 -> 20), while the established
        // title-only UIButton rule continues to ceil it.
        let titleWidth = imageSize.width > 0 && titleSize.width > 0
            ? titleSize.width.rounded(.down) : titleSize.width.rounded(.up)
        let contentWidth = titleWidth + imageSize.width + spacing
        let contentHeight = Swift.max(titleSize.height, imageSize.height)
        if contentEdgeInsets == .zero {
            if imageSize.width > 0, titleSize.width > 0, currentImage?._usesTemplateTint == true {
                // Measured (button_image_title_2x): a template-image+title
                // system button uses tight content height (no legacy +12).
                return CGSize(width: contentWidth, height: contentHeight)
            }
            if OpenUIKitRuntime.systemFontCut == .iOS, imageSize.width == 0 {
                // iOS cut, MEASURED 2026-09-07 tableprobe (iPhone 16 3x
                // and SE 2x, iOS 26.1), legacy `.system` / `.custom`
                // buttons with no image: the box is never narrower than
                // **30** and an EMPTY title still gets the one-line height
                // — no title / "" / "I" / "." / "ab" / "abcd" at 12 pt are
                // all 30 × 27, "abcdef" 40 × 27, "Learn more." 68 × 27;
                // no title at 17 pt 30 × 33, at the 15 pt default 30 × 30,
                // "Done" 37 × 30. Focus's `ActionFooterView` keeps an
                // untitled `detailTextButton` in its stack: the golden
                // footer is 71.667 = 8 + 28.667 + **27** + 8 where the
                // port's 0 × 12 box gave 56.667.
                let lineBox = _titleLabel.font.lineHeight.rounded(.up)
                return CGSize(width: Swift.max(30, contentWidth),
                              height: Swift.max(contentHeight, lineBox) + 12)
            }
            return CGSize(width: contentWidth, height: contentHeight + 12)
        }
        let scale = _titleLabel.layoutScale
        func pixelRound(_ value: CGFloat) -> CGFloat {
            (value * scale + 0.5).rounded(.down) / scale
        }
        // A nonzero legacy inset assignment switches UIKit from its built-in
        // padding to an explicit-inset path. That path retains a one-line
        // minimum even for an image-only or empty button. OpenUIKit's
        // Catalyst-derived line box is 19pt rather than iOS's 18pt, so this
        // intentionally preserves the local font metric while matching the
        // measured relationship. UIKit rounds the four inset components
        // independently, rather than rounding their sums or the final size.
        return CGSize(
            width: contentWidth + pixelRound(contentEdgeInsets.left)
                + pixelRound(contentEdgeInsets.right),
            height: Swift.max(contentHeight, _titleLabel.lineBoxHeight)
                + pixelRound(contentEdgeInsets.top)
                + pixelRound(contentEdgeInsets.bottom))
    }

    // MARK: Configuration sizing

    /// The title block: title, plus `titlePadding` and the subtitle when one
    /// is present. MEASURED: a `.filled()` with title "Configure" and
    /// subtitle "Subtitle" is 51 pt tall — 7 + 20.33333 + 1 + 15.66667 + 7 —
    /// and the subtitle sits at y 28.33333, i.e. directly under the title
    /// plus the 1 pt default `titlePadding`.
    private func configurationTitleBlockSize(_ configuration: Configuration) -> CGSize {
        var size = (currentTitle?.isEmpty == false
                        || _titleLabel.attributedText != nil)
            ? _titleLabel.intrinsicContentSize : .zero
        if let subtitleLabel = _subtitleLabel, subtitleLabel.text?.isEmpty == false {
            let subtitle = subtitleLabel.intrinsicContentSize
            size.width = Swift.max(size.width, subtitle.width)
            size.height += configuration.titlePadding + subtitle.height
        }
        return size
    }

    /// The leading/trailing/top/bottom companion: the image, or the activity
    /// indicator when `showsActivityIndicator` is set. MEASURED for the
    /// indicator: a `.filled()` with title "Configure" and the spinner on is
    /// 119.33333 wide = 12 + 20.33333 + 75 + 12, so the spinner is a square
    /// of the title's own line height and `imagePadding` (0 by default) is
    /// what separates it from the title.
    private func configurationCompanionSize(_ configuration: Configuration) -> CGSize {
        if configuration.showsActivityIndicator {
            let side = _titleLabel.intrinsicContentSize.height
            return CGSize(width: side, height: side)
        }
        return currentImage?.size ?? .zero
    }

    private func configurationSizeThatFits(_ configuration: Configuration) -> CGSize {
        let title = configurationTitleBlockSize(configuration)
        let companion = configurationCompanionSize(configuration)
        let hasCompanion = companion.width > 0 || companion.height > 0
        let hasTitle = title.width > 0 || title.height > 0
        let padding = (hasCompanion && hasTitle) ? configuration.imagePadding : 0

        var content = CGSize.zero
        switch configuration.imagePlacement {
        case .top, .bottom:
            // MEASURED (title "Go" + `star.fill`, top/bottom): the box is
            // 52 pt wide and 54.66667 / 60.66667 / 74.66667 tall at padding
            // 0 / 6 / 20 — the two blocks stack and the padding adds once.
            content.width = Swift.max(title.width, companion.width)
            content.height = title.height + companion.height + padding
        default:
            // `.leading` / `.trailing`: 74 / 80 / 94 pt wide at padding
            // 0 / 6 / 20, height unchanged at 34.33333.
            content.width = title.width + companion.width + padding
            content.height = Swift.max(title.height, companion.height)
        }

        let insets = configuration.contentInsets
        return CGSize(width: content.width + insets.leading + insets.trailing,
                      height: content.height + insets.top + insets.bottom)
    }

    open override var intrinsicContentSize: CGSize {
        if let configuration {
            // MEASURED: a configured button's intrinsic size and its
            // unbounded `sizeThatFits` agree exactly, in every factory, and
            // neither collapses to `noIntrinsicMetric` — a zero-inset
            // configuration reports the bare title box, 75 x 20.33333.
            return configurationSizeThatFits(configuration)
        }
        var fitted = sizeThatFits(
            CGSize(width: CGFloat.greatestFiniteMagnitude,
                   height: CGFloat.greatestFiniteMagnitude))
        if contentEdgeInsets != .zero {
            // Measured for empty, title-only, image-only, and combined
            // buttons: sizeThatFits keeps an exact zero, while intrinsic
            // sizing reports that axis as unconstrained. Negative nonzero
            // dimensions remain negative.
            if fitted.width == 0 { fitted.width = UIView.noIntrinsicMetric }
            if fitted.height == 0 { fitted.height = UIView.noIntrinsicMetric }
        }
        return fitted
    }

    // MARK: - Layout

    /// UIKit's legacy overridable rect hooks. `contentEdgeInsets` contracts
    /// the bounds; title/image insets are applied by the two content hooks.
    open func backgroundRect(forBounds bounds: CGRect) -> CGRect { bounds }

    open func contentRect(forBounds bounds: CGRect) -> CGRect {
        inset(bounds, by: contentEdgeInsets)
    }

    open func titleRect(forContentRect contentRect: CGRect) -> CGRect {
        layoutRects(in: contentRect).title
    }

    open func imageRect(forContentRect contentRect: CGRect) -> CGRect {
        layoutRects(in: contentRect).image
    }

    open override func layoutSubviews() {
        super.layoutSubviews()
        performConfigurationUpdateIfNeeded()
        updateTitleView()
        updateImageView()
        if let configuration {
            updateConfigurationAppearance()
            layer.cornerRadius = Swift.max(
                0, UIButton.configurationCornerRadius(configuration, height: bounds.height))
            layoutConfigurationSubviews(configuration)
            return
        }
        let content = contentRect(forBounds: bounds)
        // The public rect hooks expose UIKit's raw signed `.fill` geometry.
        // UIView frame assignment standardizes it before the subviews observe
        // their frames (the local UIView implementation does not do that for
        // us).
        _imageView.frame = imageRect(forContentRect: content).standardized
        _titleLabel.frame = titleRect(forContentRect: content).standardized
    }

    /// Lays out a configured button's title, subtitle and companion.
    ///
    /// MEASURED anchors: with title "Configure" the label sits at the inset
    /// origin (12, 7) in a 99 x 34.33333 button, and in a 260 x 60 button the
    /// title block is CENTRED — x 92.33333, which is (260 - 75) / 2 = 92.5
    /// rounded down to the 3x pixel grid. Vertically the block is centred the
    /// same way. `titleAlignment` moves the SUBTITLE inside the block, not
    /// the title: at `.center` the 23.66667 pt subtitle sits at 118
    /// (92.33333 + (75 - 23.66667) / 2), at `.trailing` at 143.66667
    /// (92.33333 + 75 - 23.66667), and at `.leading` / `.automatic` at
    /// 92.33333.
    private func layoutConfigurationSubviews(_ configuration: Configuration) {
        let content = inset(bounds, by: contentEdgeInsets)
        let scale = _titleLabel.layoutScale
        func pixelRound(_ value: CGFloat) -> CGFloat {
            (value * scale + 0.5).rounded(.down) / scale
        }

        let titleBlock = configurationTitleBlockSize(configuration)
        let companion = configurationCompanionSize(configuration)
        let hasCompanion = companion.width > 0 || companion.height > 0
        let hasTitle = titleBlock.width > 0 || titleBlock.height > 0
        let padding = (hasCompanion && hasTitle) ? configuration.imagePadding : 0

        var titleOrigin = CGPoint.zero
        var companionOrigin = CGPoint.zero
        let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
        // `.leading` / `.trailing` are semantic; resolve to physical here.
        var placement = configuration.imagePlacement
        if rtl {
            if placement == .leading { placement = .trailing }
            else if placement == .trailing { placement = .leading }
        }

        switch placement {
        case .top, .bottom:
            let total = titleBlock.height + companion.height + padding
            let top = pixelRound(content.midY - total / 2)
            let (first, second): (CGSize, CGSize) = placement == .top
                ? (companion, titleBlock) : (titleBlock, companion)
            let firstY = top
            let secondY = top + first.height + padding
            let firstX = pixelRound(content.midX - first.width / 2)
            let secondX = pixelRound(content.midX - second.width / 2)
            if placement == .top {
                companionOrigin = CGPoint(x: firstX, y: firstY)
                titleOrigin = CGPoint(x: secondX, y: secondY)
            } else {
                titleOrigin = CGPoint(x: firstX, y: firstY)
                companionOrigin = CGPoint(x: secondX, y: secondY)
            }
            _ = second
        default:
            let total = titleBlock.width + companion.width + padding
            let left = pixelRound(content.midX - total / 2)
            let titleY = pixelRound(content.midY - titleBlock.height / 2)
            let companionY = pixelRound(content.midY - companion.height / 2)
            if placement == .trailing {
                titleOrigin = CGPoint(x: left, y: titleY)
                companionOrigin = CGPoint(x: left + titleBlock.width + padding,
                                          y: companionY)
            } else {
                companionOrigin = CGPoint(x: left, y: companionY)
                titleOrigin = CGPoint(x: left + companion.width + padding, y: titleY)
            }
        }

        let titleSize = (currentTitle?.isEmpty == false || _titleLabel.attributedText != nil)
            ? _titleLabel.intrinsicContentSize : .zero
        _titleLabel.frame = CGRect(x: titleOrigin.x, y: titleOrigin.y,
                                   width: Swift.min(titleSize.width, titleBlock.width),
                                   height: titleSize.height).standardized

        if let subtitleLabel = _subtitleLabel, subtitleLabel.text?.isEmpty == false {
            let subtitle = subtitleLabel.intrinsicContentSize
            let slack = titleBlock.width - subtitle.width
            let offset: CGFloat
            switch configuration.titleAlignment {
            case .center: offset = slack / 2
            case .trailing: offset = slack
            case .leading, .automatic: offset = 0
            }
            subtitleLabel.frame = CGRect(
                x: pixelRound(titleOrigin.x + offset),
                y: titleOrigin.y + titleSize.height + configuration.titlePadding,
                width: subtitle.width, height: subtitle.height).standardized
        }

        if configuration.showsActivityIndicator, let indicator = _activityIndicator {
            indicator.frame = CGRect(origin: companionOrigin, size: companion).standardized
            _imageView.frame = .zero
        } else if currentImage != nil {
            _imageView.frame = CGRect(origin: companionOrigin, size: companion).standardized
        } else {
            _imageView.frame = .zero
        }
    }

    private func layoutRects(in content: CGRect) -> (title: CGRect, image: CGRect) {
        let scale = _titleLabel.layoutScale
        let intr = _titleLabel.intrinsicContentSize
        let imageSize = currentImage?.size ?? .zero
        let hasTitle = _titleLabel.text?.isEmpty == false
        let spacing = (imageSize.width > 0 && hasTitle) ? configurationImagePadding : 0
        let availableTitleWidth = Swift.max(0, content.width - imageSize.width - spacing)
        var w = hasTitle
            ? (imageSize.width > 0 ? intr.width.rounded(.down) : intr.width.rounded(.up))
            : 0
        // Overflowing titles (see file header): squeeze case gets the full
        // bounds width; true truncation hugs the truncated middle line.
        if w > availableTitleWidth {
            if currentAttributedTitle != nil {
                // AttributedTextLayout handles its own run metrics and
                // truncation inside the assigned label width.
                w = availableTitleWidth
            } else {
                let title = _titleLabel.text ?? ""
                let font = _titleLabel.font
                if FontEngine.measureTight(title, font: font)
                    <= availableTitleWidth.rounded(.down) + 1e-6 {
                    w = availableTitleWidth
                } else {
                    let t = TextLayout.truncate(title, font: font,
                                                maxWidth: availableTitleWidth,
                                                mode: .byTruncatingMiddle)
                    // Drawn advance: tight delta applies to every glyph except
                    // the ellipsis (same rule as UILabel's glyph run).
                    var count = 0
                    for u in t.text.unicodeScalars where u.value != 0x2026 {
                        count += 1
                    }
                    let drawn = FontEngine.measure(t.text, font: font)
                        + t.delta * CGFloat(count)
                    w = Swift.min(availableTitleWidth,
                                  Swift.max(0, drawn.rounded(.up)))
                }
            }
        }
        let h = hasTitle ? Swift.min(intr.height, content.height) : 0
        // Center, offsets rounded half-up to the pixel grid (same rounding
        // the label uses for its text block).
        func pixelRound(_ value: CGFloat) -> CGFloat {
            (value * scale + 0.5).rounded(.down) / scale
        }

        // Unlike contentRect(forBounds:), the title/image `.fill` paths do
        // not collapse crossed edges or expand them outward. UIKit rounds
        // each requested endpoint to the nearest display pixel and preserves
        // the signed difference verbatim.
        func itemInsetRect(_ insets: UIEdgeInsets) -> CGRect {
            let x = pixelRound(content.origin.x + insets.left)
            let y = pixelRound(content.origin.y + insets.top)
            let endX = pixelRound(content.origin.x + content.size.width
                - insets.right)
            let endY = pixelRound(content.origin.y + content.size.height
                - insets.bottom)
            return CGRect(x: x, y: y, width: endX - x, height: endY - y)
        }

        let hasImage = currentImage != nil
        let iw = hasImage ? Swift.min(imageSize.width, content.width) : 0
        let ih = hasImage ? Swift.min(imageSize.height, content.height) : 0
        let totalWidth = iw + w + spacing
        let rtl = effectiveUserInterfaceLayoutDirection == .rightToLeft
        var imageX: CGFloat = 0
        var titleX: CGFloat = 0
        var imageWidth = iw
        var titleWidth = w

        switch effectiveContentHorizontalAlignment {
        case .center, .leading, .trailing:
            // leading/trailing were resolved to physical values above.
            let base = pixelRound(content.midX - totalWidth / 2)
            if rtl {
                titleX = pixelRound(base
                    + (titleEdgeInsets.left - titleEdgeInsets.right) / 2)
                imageX = pixelRound(base + w
                    + spacing
                    + (imageEdgeInsets.left - imageEdgeInsets.right) / 2)
            } else {
                imageX = pixelRound(base
                    + (imageEdgeInsets.left - imageEdgeInsets.right) / 2)
                titleX = pixelRound(base + iw
                    + spacing
                    + (titleEdgeInsets.left - titleEdgeInsets.right) / 2)
            }
        case .left:
            if rtl {
                titleX = pixelRound(content.minX + titleEdgeInsets.left)
                imageX = pixelRound(content.minX + w + spacing + imageEdgeInsets.left)
            } else {
                imageX = pixelRound(content.minX + imageEdgeInsets.left)
                titleX = pixelRound(content.minX + iw + spacing + titleEdgeInsets.left)
            }
        case .right:
            if rtl {
                imageX = pixelRound(content.maxX - imageEdgeInsets.right - iw)
                titleX = pixelRound(content.maxX - iw
                    - spacing
                    - titleEdgeInsets.right - w)
            } else {
                titleX = pixelRound(content.maxX - titleEdgeInsets.right - w)
                imageX = pixelRound(content.maxX - w
                    - spacing
                    - imageEdgeInsets.right - iw)
            }
        case .fill:
            if hasImage || hasTitle {
                let imageArea = itemInsetRect(imageEdgeInsets)
                let titleArea = itemInsetRect(titleEdgeInsets)
                // The two items share one proportional denominator, but each
                // numerator uses its own signed available interval. Image
                // basis is allowed to go negative; title basis floors at
                // zero. At the exact cancellation point UIKit substitutes 1
                // for the zero denominator (iOS 26.1 oracle: -20 + 20 gives
                // 400pt and 4000pt regions, not infinities).
                let imageBasis = hasImage
                    ? Swift.min(imageSize.width, imageArea.size.width) : 0
                let titleBasis = hasTitle
                    ? Swift.max(0, Swift.min(w, titleArea.size.width)) : 0
                let sum = imageBasis + titleBasis
                let denominator: CGFloat = sum == 0 ? 1 : sum
                imageWidth = imageArea.size.width * imageBasis / denominator
                titleWidth = titleArea.size.width * titleBasis / denominator
                // UIKit keeps fill's proportional physical regions stable in
                // RTL; unlike center/left/right, it does not reverse them.
                imageX = imageArea.origin.x
                titleX = pixelRound(titleArea.origin.x
                    + titleArea.size.width - titleWidth)
            }
        }

        func verticalRect(x: CGFloat, width: CGFloat, height: CGFloat,
                          insets: UIEdgeInsets, present: Bool) -> CGRect {
            guard present else { return .zero }
            let y: CGFloat
            let resolvedHeight: CGFloat
            switch contentVerticalAlignment {
            case .center:
                y = pixelRound(content.midY - height / 2
                    + (insets.top - insets.bottom) / 2)
                resolvedHeight = height
            case .top:
                y = pixelRound(content.minY + insets.top)
                resolvedHeight = height
            case .bottom:
                y = pixelRound(content.maxY - insets.bottom - height)
                resolvedHeight = height
            case .fill:
                let area = itemInsetRect(insets)
                y = area.origin.y
                resolvedHeight = area.size.height
            }
            return CGRect(x: x, y: y, width: width, height: resolvedHeight)
        }

        return (
            title: verticalRect(x: titleX, width: titleWidth, height: h,
                                insets: titleEdgeInsets, present: hasTitle),
            image: verticalRect(x: imageX, width: imageWidth, height: ih,
                                insets: imageEdgeInsets, present: hasImage)
        )
    }

    /// UIKit resolves legacy inset rectangles in display pixels. When the
    /// requested leading/trailing edges cross, they first collapse to their
    /// midpoint; the resulting interval is then expanded outward to the
    /// pixel grid. Thus a half-pixel midpoint at 3x becomes a one-pixel rect,
    /// while a midpoint already on the grid remains zero-sized.
    private func insetInterval(minimum: CGFloat, maximum: CGFloat,
                               leading: CGFloat, trailing: CGFloat)
        -> (minimum: CGFloat, maximum: CGFloat) {
        var a = minimum + leading
        var b = maximum - trailing
        if a > b {
            let midpoint = (a + b) / 2
            a = midpoint
            b = midpoint
        }
        let scale = _titleLabel.layoutScale
        return ((a * scale).rounded(.down) / scale,
                (b * scale).rounded(.up) / scale)
    }

    private func inset(_ rect: CGRect, by insets: UIEdgeInsets) -> CGRect {
        let x = insetInterval(minimum: rect.minX, maximum: rect.maxX,
                              leading: insets.left, trailing: insets.right)
        let y = insetInterval(minimum: rect.minY, maximum: rect.maxY,
                              leading: insets.top, trailing: insets.bottom)
        return CGRect(x: x.minimum, y: y.minimum,
                      width: x.maximum - x.minimum,
                      height: y.maximum - y.minimum)
    }
}
