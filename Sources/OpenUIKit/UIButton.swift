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

    public let buttonType: ButtonType
    private let _titleLabel: UIButtonLabel
    private let _imageView: UIImageView

    /// Real UIKit exposes `titleLabel` as optional UILabel.
    public var titleLabel: UILabel? { _titleLabel }

    /// Real UIKit exposes a persistent image view even before an image has
    /// been assigned. It is optional in the API for Objective-C history, but
    /// a live UIButton owns the same view for its lifetime.
    public var imageView: UIImageView? { _imageView }

    private var titles: [UInt: String] = [:]
    private var titleColors: [UInt: UIColor] = [:]
    private var images: [UInt: UIImage] = [:]

    /// Default disabled title color of a plain .system button (measured
    /// from the oracle; see file header).
    static let systemDisabledTitleColor = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.55, alpha: 0.45)
            : UIColor(white: 0.52, alpha: 0.45)
    })

    public init(type: ButtonType = .custom) {
        buttonType = type
        _titleLabel = UIButtonLabel()
        _imageView = UIImageView()
        super.init(frame: .zero)
        isOpaque = false
        _titleLabel.font = .systemFont(ofSize: 15)
        // Real UIButton titles truncate in the middle (oracle-verified).
        _titleLabel.lineBreakMode = .byTruncatingMiddle
        addSubview(_titleLabel)
        // Keep the long-standing OpenUIKit title-label ordering stable for
        // layout dumps/tests; UIKit does not promise a public subview order.
        addSubview(_imageView)
        updateTitleView()
        updateImageView()
    }

    public convenience override init(frame: CGRect = .zero) {
        self.init(type: .custom)
        self.frame = frame
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

    private func updateTitleView() {
        _titleLabel.text = currentTitle
        _titleLabel.textColor = currentTitleColor
    }

    private func updateImageView() {
        _imageView.image = currentImage
        _imageView.isHidden = currentImage == nil
    }

    open override func stateDidChange() {
        super.stateDidChange()
        updateTitleView()
        updateImageView()
    }

    // MARK: - Sizing

    /// Legacy plain buttons ignore the constraint entirely (oracle:
    /// sizeThatFits(200) of a 211pt title reports 211).
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let title = _titleLabel.intrinsicContentSize
        let titleSize = (currentTitle?.isEmpty == false) ? title : .zero
        let imageSize = currentImage?.size ?? .zero
        // The image+title rect oracle floors the title's half-point
        // intrinsic width ("Go": 20.5 -> 20), while the established
        // title-only UIButton rule continues to ceil it.
        let titleWidth = imageSize.width > 0 && titleSize.width > 0
            ? titleSize.width.rounded(.down) : titleSize.width.rounded(.up)
        let contentWidth = titleWidth + imageSize.width
        let contentHeight = Swift.max(titleSize.height, imageSize.height)
        return CGSize(width: contentWidth, height: contentHeight + 12)
    }

    open override var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                            height: CGFloat.greatestFiniteMagnitude))
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateTitleView()
        updateImageView()
        let scale = _titleLabel.layoutScale
        let intr = _titleLabel.intrinsicContentSize
        let imageSize = currentImage?.size ?? .zero
        let hasTitle = currentTitle?.isEmpty == false
        let availableTitleWidth = Swift.max(0, bounds.width - imageSize.width)
        var w = hasTitle
            ? (imageSize.width > 0 ? intr.width.rounded(.down) : intr.width.rounded(.up))
            : 0
        // Overflowing titles (see file header): squeeze case gets the full
        // bounds width; true truncation hugs the truncated middle line.
        if w > availableTitleWidth {
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
                for u in t.text.unicodeScalars where u.value != 0x2026 { count += 1 }
                let drawn = FontEngine.measure(t.text, font: font)
                    + t.delta * CGFloat(count)
                w = Swift.min(availableTitleWidth,
                              Swift.max(0, drawn.rounded(.up)))
            }
        }
        let h = Swift.min(intr.height, bounds.height)
        // Center, offsets rounded half-up to the pixel grid (same rounding
        // the label uses for its text block).
        func pixelRound(_ v: CGFloat) -> CGFloat { (v * scale + 0.5).rounded(.down) / scale }
        let totalWidth = imageSize.width + w
        let x = pixelRound((bounds.width - totalWidth) / 2)
        if let image = currentImage {
            let iw = Swift.min(image.size.width, bounds.width)
            let ih = Swift.min(image.size.height, bounds.height)
            _imageView.frame = CGRect(x: x,
                                      y: pixelRound((bounds.height - ih) / 2),
                                      width: iw, height: ih)
        } else {
            _imageView.frame = .zero
        }
        if hasTitle {
            _titleLabel.frame = CGRect(x: x + imageSize.width,
                                       y: pixelRound((bounds.height - h) / 2),
                                       width: w, height: h)
        } else {
            _titleLabel.frame = .zero
        }
    }
}
