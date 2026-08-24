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
//     title does not fit, the label width clamps to bounds.width - 4
//     (2pt each side; oracle: 80pt-wide button -> 76pt label at x = 2).
//   - Title color: explicit .normal color wins in EVERY state (oracle:
//     a disabled button with explicit titleColor renders that color).
//     Default enabled = tintColor; default disabled = a private gray,
//     light rgba(0.52 0.52 0.52 / 0.45), dark rgba(0.55 0.55 0.55 / 0.45)
//     (measured from oracle renders at 80pt: peak text pixels
//     light (133,133,133,115) / dark (140,140,140,115)).

/// The title label subclass real UIKit uses; the layout dump prints the
/// dynamic class name, so the oracle's "UIButtonLabel" entries match.
public final class UIButtonLabel: UILabel {}

open class UIButton: UIView {
    public enum ButtonType: Sendable {
        case custom, system
    }

    /// Minimal UIControl.State stand-in (OpenUIKit has no UIControl).
    public struct State: OptionSet, Hashable, Sendable {
        public let rawValue: UInt
        public init(rawValue: UInt) { self.rawValue = rawValue }
        public static let normal = State([])
        public static let highlighted = State(rawValue: 1 << 0)
        public static let disabled = State(rawValue: 1 << 1)
    }

    public let buttonType: ButtonType
    private let _titleLabel: UIButtonLabel

    /// Real UIKit exposes `titleLabel` as optional UILabel.
    public var titleLabel: UILabel? { _titleLabel }

    public var isEnabled: Bool = true {
        didSet { setNeedsLayout() }
    }

    public var state: State { isEnabled ? .normal : .disabled }

    private var titles: [UInt: String] = [:]
    private var titleColors: [UInt: UIColor] = [:]

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
        super.init(frame: .zero)
        isOpaque = false
        _titleLabel.font = .systemFont(ofSize: 15)
        addSubview(_titleLabel)
        updateTitleView()
    }

    public convenience override init(frame: CGRect = .zero) {
        self.init(type: .custom)
        self.frame = frame
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

    public func setTitleColor(_ color: UIColor?, for state: State) {
        titleColors[state.rawValue] = color
        updateTitleView()
    }

    public func titleColor(for state: State) -> UIColor? {
        titleColors[state.rawValue] ?? titleColors[State.normal.rawValue]
    }

    public var currentTitleColor: UIColor {
        // Explicit color (any-state fallback to .normal) wins even when
        // disabled; otherwise tint when enabled, system gray when disabled.
        if let c = titleColor(for: state) { return c }
        if !isEnabled { return UIButton.systemDisabledTitleColor }
        return tintColor
    }

    private func updateTitleView() {
        _titleLabel.text = currentTitle
        _titleLabel.textColor = currentTitleColor
    }

    // MARK: - Sizing

    /// Legacy plain buttons ignore the constraint entirely (oracle:
    /// sizeThatFits(200) of a 211pt title reports 211).
    open override func sizeThatFits(_ size: CGSize) -> CGSize {
        let intr = _titleLabel.intrinsicContentSize
        return CGSize(width: intr.width.rounded(.up), height: intr.height + 12)
    }

    open override var intrinsicContentSize: CGSize {
        sizeThatFits(CGSize(width: CGFloat.greatestFiniteMagnitude,
                            height: CGFloat.greatestFiniteMagnitude))
    }

    // MARK: - Layout

    open override func layoutSubviews() {
        super.layoutSubviews()
        updateTitleView()
        let scale = _titleLabel.layoutScale
        let intr = _titleLabel.intrinsicContentSize
        var w = intr.width.rounded(.up)
        // The 2pt-per-side horizontal inset only bites when the title does
        // NOT fit: oracle probes show an 80pt button with a long title gets
        // a 76pt label, but a sizeToFit button (title width == bounds width)
        // keeps the full-width label.
        if w > bounds.width { w = Swift.max(0, bounds.width - 4) }
        let h = Swift.min(intr.height, bounds.height)
        // Center, offsets rounded half-up to the pixel grid (same rounding
        // the label uses for its text block).
        func pixelRound(_ v: CGFloat) -> CGFloat { (v * scale + 0.5).rounded(.down) / scale }
        _titleLabel.frame = CGRect(x: pixelRound((bounds.width - w) / 2),
                                   y: pixelRound((bounds.height - h) / 2),
                                   width: w, height: h)
    }
}
