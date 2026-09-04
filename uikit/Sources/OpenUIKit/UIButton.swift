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
    open var configuration: Configuration? {
        didSet { applyConfiguration() }
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

    public var currentTitle: String? { title(for: state) }

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
        if configuration != nil {
            if let c = titleColor(for: state) { return c }
            let base = configurationBaseTitleColor()
            if !isEnabled { return base.withMultipliedAlpha(0.4) }
            if state.contains(.highlighted) {
                return base.withMultipliedAlpha(UIButton.configurationHighlightedAlpha)
            }
            return base
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

    private func applyConfiguration() {
        guard let configuration else {
            configurationImagePadding = 0
            layer.borderWidth = 0
            layer.borderColor = nil
            backgroundColor = nil
            contentEdgeInsets = .zero
            _titleLabel.font = .systemFont(ofSize: 15)
            setNeedsLayout()
            return
        }
        if let title = configuration.title { titles[State.normal.rawValue] = title }
        if let image = configuration.image {
            images[State.normal.rawValue] = image.withRenderingMode(.alwaysTemplate)
        }
        // Measured (oracle_flow button_configurations_2x, iPhone SE 2x):
        // configuration titles use 17 pt regular and size to 75 x 20.5.
        _titleLabel.font = .systemFont(ofSize: 17)
        configurationImagePadding = configuration.imagePadding
        // Same measurement: all four styles resolve to intrinsic 99 x 34.5
        // for "Configure" (75 x 20.5 title plus 12/12 horizontal, 7/7 vertical insets).
        contentEdgeInsets = UIEdgeInsets(top: 7, left: 12, bottom: 7, right: 12)
        updateConfigurationAppearance()
        updateTitleView()
        updateImageView()
        setNeedsLayout()
    }

    private func configurationBaseTitleColor() -> UIColor {
        switch configuration?.style ?? .plain {
        case .filled:
            return .white
        case .plain, .bordered, .tinted:
            return tintColor
        }
    }

    private func updateConfigurationAppearance() {
        guard let configuration else { return }
        let traits = traitCollection
        let tint = tintColor.resolvedColor(with: traits)
        layer.borderWidth = 0
        layer.borderColor = nil
        switch configuration.style {
        case .plain:
            backgroundColor = .clear
        case .filled:
            backgroundColor = isEnabled ? tint : tint.withMultipliedAlpha(0.35)
        case .tinted:
            // Measured background alpha (button_configurations_2x family):
            // light 0.18, dark 0.25.
            let a: CGFloat = traits.userInterfaceStyle == .dark ? 0.25 : 0.18
            backgroundColor = isEnabled ? tint.withMultipliedAlpha(a)
                : tint.withMultipliedAlpha(a * 0.5)
        case .bordered:
            // Measured fill (button_configurations_2x family): rgba
            // (120,120,128) at alpha 0.16 (light) / 0.32 (dark).
            let alpha: CGFloat = traits.userInterfaceStyle == .dark ? 0.32 : 0.16
            backgroundColor = UIColor(red: 120.0 / 255.0, green: 120.0 / 255.0,
                                      blue: 128.0 / 255.0, alpha: alpha)
        }
        if state.contains(.highlighted), isEnabled, configuration.style != .plain {
            backgroundColor = backgroundColor?.withMultipliedAlpha(
                UIButton.configurationHighlightedAlpha
            )
        }
    }

    private func updateTitleView() {
        _titleLabel.textColor = currentTitleColor
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
        updateConfigurationAppearance()
        updateTitleView()
        updateImageView()
    }


    // MARK: - Sizing

    /// Legacy plain buttons ignore the constraint entirely (oracle:
    /// sizeThatFits(200) of a 211pt title reports 211).
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
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

    open override var intrinsicContentSize: CGSize {
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
        updateTitleView()
        updateImageView()
        let content = contentRect(forBounds: bounds)
        if configuration != nil {
            // Measured (oracle_flow button_configurations_2x, iPhone SE 2x):
            // every 170 x 36 configured button resolves to cornerRadius 17.
            layer.cornerRadius = Swift.max(0, (bounds.height - 2) / 2)
        }
        // The public rect hooks expose UIKit's raw signed `.fill` geometry.
        // UIView frame assignment standardizes it before the subviews observe
        // their frames (the local UIView implementation does not do that for
        // us).
        _imageView.frame = imageRect(forContentRect: content).standardized
        _titleLabel.frame = titleRect(forContentRect: content).standardized
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
