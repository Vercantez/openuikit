// UIAlertController. Owner: viewcontroller module (M12 alerts cluster).
//
// 332 uses in the app census (docs/APP_COMPAT.md) — the third-largest
// cluster. Every number below is MEASURED from real iOS 26.1 UIKit in the
// headless iPhone-16 simulator by `Tools/oracle2/alertprobe`
// (scripts/alert_probe_sim.sh): it presents 20 alert/action-sheet
// configurations, dumps the whole private view tree in window coordinates
// (frames, corner radii, resolved colours, fonts) and snapshots the window
// so the blurred materials can be solved from pixels over known bases.
// Mac Catalyst cannot be used here at all — it bridges UIAlertController
// into an AppKit alert panel.
//
// WHAT iOS 26.1 ACTUALLY DRAWS (this is not the classic alert):
//
//   - A 320 pt wide CARD, centred horizontally and centred in the window's
//     SAFE AREA vertically (measured: card centre y = 438.5 on a 393x852
//     window with safe insets 59/34 — exactly (59 + 818)/2, not the window
//     centre 426).
//   - Corner radius 34, `continuous` curve. Buttons are PILLS, 48 pt tall,
//     radius 24, inset 16 pt from the card's sides, 8 pt apart.
//   - EXACTLY TWO actions lay out side by side (140 pt each, 8 pt gap) with
//     the CANCEL action on the LEFT regardless of the order it was added
//     (measured both ways). Three or more stack vertically with the cancel
//     action LAST (measured both ways). `actions` itself keeps add order.
//   - `.actionSheet` on iPhone is laid out IDENTICALLY to `.alert` — same
//     320 pt card, same centring, same pills. iOS 26 retired the slide-up
//     bottom sheet; a probe run that set `popoverPresentationController`
//     got a popover instead (and silently dropped the cancel action), so
//     this file never touches that property.
//   - Title 17 pt semibold `label`, message 15 pt regular `secondaryLabel`,
//     both LEFT aligned at a 30 pt inset. When only ONE of title/message is
//     set, UIKit renders that single string as 17 pt REGULAR and CENTRES it.
//   - Action titles are 17 pt medium in `label` — not tint blue.
//     `.destructive` is systemRed. The `preferredAction` gets a filled
//     tint-blue pill with a 17 pt semibold WHITE title.
//
// MATERIALS (we have no UIVisualEffectView — see docs/KNOWN_GAPS.md): the
// card and the button fills are live blurs of whatever is behind them. Both
// were solved as "flat colour at alpha over the backdrop" by rendering the
// same alert over four known neutral bases per appearance and least-squares
// fitting; the residual is under 1.5 counts over the whole range, and the
// divergence that remains is the missing spatial blur (a strongly patterned
// backdrop shows through flat instead of smeared).
//
// TRANSITION: measured by sampling every layer's `presentation()` per
// display-link frame across an animated present. Only the DIMMING view
// animates — its layer opacity runs a critically damped spring, ω measured
// 22.88 rad/s (converged from 24 independent frames), i.e. a UIKit spring of
// duration 9.2334/22.88 = 0.4036 s. The card carries NO animation on its own
// layer or on any ancestor up to the window: no scale, no fade. See the
// caveat in docs/KNOWN_GAPS.md.

// MARK: - Measured metrics

/// Every constant here comes from `Tools/oracle2/alertprobe` dumps; the
/// fixture family `alert_*` locks them in against real-iOS goldens.
public enum UIAlertMetrics {
    /// Card width. Constant across every probed configuration on a 393 pt
    /// window.
    public static let cardWidth: CGFloat = 320
    public static let cardCornerRadius: CGFloat = 34

    /// Title/message inset from the card's sides (measured 30; label width
    /// 260 = 320 − 2×30).
    public static let textInsetX: CGFloat = 30
    /// Card top edge to the first label's top.
    public static let topPadding: CGFloat = 22
    /// Title label bottom to message label top.
    public static let titleMessageGap: CGFloat = 7.0 + 2.0 / 3.0
    /// Last label's bottom to the end of the header zone — 4.333 when both a
    /// title and a message are present, 4 when only one label is.
    public static let headerBottomPadding: CGFloat = 4.0 + 1.0 / 3.0
    public static let headerBottomPaddingSingle: CGFloat = 4

    /// Label box heights, MEASURED off the alert's own labels rather than
    /// taken from `UIFont.labelLineHeight`: the alert lays its labels out on
    /// the device's 1/3 pt grid, so a 17 pt line box is 20.333 (the font
    /// engine's general-purpose rounding gives 20) and a 15 pt one is 18
    /// (the font engine gives 19). Using the measured numbers puts every
    /// probed configuration's card height exactly on the golden.
    public static let titleLineHeight: CGFloat = 20.0 + 1.0 / 3.0
    public static let messageLineHeight: CGFloat = 18
    /// Extra pitch between wrapped lines: the title label measures 20.333 pt
    /// for one line and 42.333 for two (pitch 22); the message measures
    /// 18 / 38 / 58 for one / two / three lines (pitch 20).
    public static let titleLinePitch: CGFloat = 22
    public static let messageLinePitch: CGFloat = 20

    /// The actions zone: 16 pt padding on all four sides, 48 pt pills 8 pt
    /// apart, corner radius 24.
    public static let actionsPadding: CGFloat = 16
    public static let actionHeight: CGFloat = 48
    public static let actionSpacing: CGFloat = 8
    public static let actionCornerRadius: CGFloat = 24

    /// Text fields (`.alert` only): a 48 pt pill inset 15 pt from the card's
    /// sides, the field itself inset 30 pt, 16.333 pt below the message and
    /// 4 pt of slack under the last one.
    public static let textFieldGap: CGFloat = 16.0 + 1.0 / 3.0
    public static let textFieldHeight: CGFloat = 48
    public static let textFieldInsetX: CGFloat = 15
    public static let textFieldBottomPadding: CGFloat = 4

    public static let titleFont = UIFont.systemFont(ofSize: 17, weight: .semibold)
    public static let messageFont = UIFont.systemFont(ofSize: 15, weight: .regular)
    /// The 17 pt REGULAR font UIKit uses when an alert has only a title or
    /// only a message.
    public static let soloFont = UIFont.systemFont(ofSize: 17, weight: .regular)
    public static let actionFont = UIFont.systemFont(ofSize: 17, weight: .medium)
    public static let preferredActionFont = UIFont.systemFont(ofSize: 17, weight: .semibold)

    /// Dimming behind the card. MEASURED: black at 0.2 in light, 0.48 in
    /// dark (the page sheet uses 0.2 in both).
    public static let dimAlphaLight: CGFloat = 0.2
    public static let dimAlphaDark: CGFloat = 0.48

    /// The card's blur, as a flat colour over the (already dimmed) backdrop.
    /// Least-squares fit over four neutral bases per appearance:
    ///   light  out = 0.2857·base + 181.0  ->  alpha 0.7143 of 0.9937 white
    ///   dark   out = 0.3494·base +  16.4  ->  alpha 0.6506 of 0.0989 black
    static let cardFill = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 0.0989, alpha: 0.6506)
            : UIColor(white: 0.9937, alpha: 0.7143)
    })

    /// The button pill's fill, re-expressed as a flat colour over the CARD
    /// (the probe measures both against the base; dividing the two fits
    /// gives button = 0.8628·card + 3.83 light, 0.8903·card + 27.97 dark).
    static let actionFill = UIColor(dynamicProvider: { traits in
        traits.userInterfaceStyle == .dark
            ? UIColor(white: 1.0, alpha: 0.1097)
            : UIColor(white: 0.109, alpha: 0.1372)
    })

    /// The preferred action's filled pill and its title. MEASURED from the
    /// rendered pixels (the dump's nominal tintColor (0,136,255) is not what
    /// the render server draws).
    static let preferredActionFill = UIColor(red: 55.0 / 255, green: 126.0 / 255,
                                             blue: 239.0 / 255, alpha: 1)
    static let preferredActionTitleColor = UIColor(white: 1, alpha: 1)

    /// Card shadow, fitted to the measured edge profiles over a 204-count
    /// backdrop: the darkening reaches ~33 pt to the SIDE, ~25 pt ABOVE and
    /// ~41 pt BELOW the card — a symmetric blur pushed 8 pt down (33 − 8 = 25,
    /// 33 + 8 = 41) — and peaks at 9 counts beside the card and 12 under it.
    public static let shadowOffsetY: CGFloat = 8
    public static let shadowBlur: CGFloat = 22
    public static let shadowAlpha: CGFloat = 0.085
    /// How far outside the card the shadow view reaches.
    static let shadowSpill: CGFloat = 44

    /// Dim-fade spring: MEASURED ω = 22.88 rad/s, critically damped, which is
    /// a UIKit spring of duration ω·D = 9.2334134764.
    public static let dimSpringOmega: Double = 22.88
    public static var transitionDuration: Double { 9.2334134764515865 / dimSpringOmega }
}

/// Screen metrics the portable core has no model for. The alert centres in
/// the safe area, and the page sheet's 59 pt top inset is the same measured
/// number — both come from the reference device (iPhone 16, iOS 26.1).
/// A host that knows better may overwrite these before presenting.
public enum UIScreenMetrics {
    public static var safeAreaTop: CGFloat = 59
    public static var safeAreaBottom: CGFloat = 34
}

// MARK: - The card

/// The alert's view: the blurred platter with its rounded corners. Built
/// entirely in `UIAlertController._layoutCard`.
@preconcurrency @MainActor
final class _UIAlertCardView: UIView {
    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        backgroundColor = UIAlertMetrics.cardFill
        layer.cornerRadius = UIAlertMetrics.cardCornerRadius
    }
}

/// The card's shadow, drawn as a RING.
///
/// It cannot be a `layer.shadow*` on the card: CoreAnimation draws a layer's
/// shadow under the whole layer tree and does NOT occlude it with the layer's
/// own content (that is measured — golden/alpha_shadow_group — and our
/// compositor reproduces it), so a shadow on a 71 %-opaque card shows THROUGH
/// the card and darkens its interior by 4–7 counts, unevenly (the offset
/// makes the bottom darker). Real iOS keeps the card interior perfectly flat
/// at the blur's own value, so its shadow is not composited under the
/// platter. Drawing the blurred silhouette clipped to the OUTSIDE of the
/// card's shape reproduces that: the ring path is the view's bounds wound one
/// way plus the card's rounded rect wound the other, which the non-zero
/// winding rule turns into "everything except the card".
@preconcurrency @MainActor
final class _UIAlertShadowView: UIView {
    /// The card's rect in this view's coordinates.
    var cardRect: CGRect = .zero
    var cornerRadius: CGFloat = UIAlertMetrics.cardCornerRadius

    override init(frame: CGRect = .zero) {
        super.init(frame: frame)
        isOpaque = false
        isUserInteractionEnabled = false
    }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard !cardRect.isEmpty else { return }
        var ring = Path.rect(bounds)
        ring.elements += _reversedRoundedRect(cardRect, cornerRadius: cornerRadius).elements
        canvas.save()
        canvas.clip(to: ring)
        canvas.setShadow(color: CGColor(red: 0, green: 0, blue: 0,
                                        alpha: UIAlertMetrics.shadowAlpha),
                         offset: CGSize(width: 0, height: UIAlertMetrics.shadowOffsetY),
                         blur: UIAlertMetrics.shadowBlur)
        canvas.drawShadow(of: Path.roundedRect(cardRect, cornerRadius: cornerRadius))
        canvas.restore()
    }

    /// `Path.roundedRect` traversed the other way round, so that adding it to
    /// an enclosing rect yields a ring under the non-zero winding rule.
    private func _reversedRoundedRect(_ r: CGRect, cornerRadius: CGFloat) -> Path {
        let radius = Swift.min(cornerRadius, Swift.min(r.width, r.height) / 2)
        var p = Path()
        guard radius > 0 else {
            p.move(to: CGPoint(x: r.minX, y: r.minY))
            p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
            p.addLine(to: CGPoint(x: r.maxX, y: r.minY))
            p.close()
            return p
        }
        let k: CGFloat = 0.5522847498307936
        let kr = k * radius
        p.move(to: CGPoint(x: r.minX + radius, y: r.minY))
        p.addCurve(to: CGPoint(x: r.minX, y: r.minY + radius),
                   control1: CGPoint(x: r.minX + radius - kr, y: r.minY),
                   control2: CGPoint(x: r.minX, y: r.minY + radius - kr))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY - radius))
        p.addCurve(to: CGPoint(x: r.minX + radius, y: r.maxY),
                   control1: CGPoint(x: r.minX, y: r.maxY - radius + kr),
                   control2: CGPoint(x: r.minX + radius - kr, y: r.maxY))
        p.addLine(to: CGPoint(x: r.maxX - radius, y: r.maxY))
        p.addCurve(to: CGPoint(x: r.maxX, y: r.maxY - radius),
                   control1: CGPoint(x: r.maxX - radius + kr, y: r.maxY),
                   control2: CGPoint(x: r.maxX, y: r.maxY - radius + kr))
        p.addLine(to: CGPoint(x: r.maxX, y: r.minY + radius))
        p.addCurve(to: CGPoint(x: r.maxX - radius, y: r.minY),
                   control1: CGPoint(x: r.maxX, y: r.minY + radius - kr),
                   control2: CGPoint(x: r.maxX - radius + kr, y: r.minY))
        p.close()
        return p
    }
}

/// One action pill. A UIControl so a tap runs the action and dismisses.
@preconcurrency @MainActor
final class _UIAlertActionView: UIControl {
    let action: UIAlertAction
    let label = UILabel()
    /// Filled tint pill (the alert's `preferredAction`).
    var isPreferred = false { didSet { applyStyle() } }

    init(action: UIAlertAction) {
        self.action = action
        super.init(frame: .zero)
        layer.cornerRadius = UIAlertMetrics.actionCornerRadius
        label.textAlignment = .center
        label.text = action.title
        addSubview(label)
        applyStyle()
    }

    func applyStyle() {
        backgroundColor = isPreferred ? UIAlertMetrics.preferredActionFill
                                      : UIAlertMetrics.actionFill
        label.font = isPreferred ? UIAlertMetrics.preferredActionFont
                                 : UIAlertMetrics.actionFont
        let base: UIColor
        if isPreferred {
            base = UIAlertMetrics.preferredActionTitleColor
        } else if action.style == .destructive {
            base = .systemRed
        } else {
            base = .label
        }
        // A disabled action renders dimmed (UIKit's own disabled treatment;
        // not separately measured — see docs/KNOWN_GAPS.md).
        label.textColor = action.isEnabled ? base : .tertiaryLabel
        isEnabled = action.isEnabled
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        let h = label.font.labelLineHeight
        label.frame = CGRect(x: 0, y: ((bounds.height - h) / 2).rounded(),
                             width: bounds.width, height: h)
    }
}

// MARK: - UIAlertController

@preconcurrency @MainActor
open class UIAlertController: UIViewController {
    public enum Style: Int, Sendable {
        case actionSheet = 0
        case alert = 1
    }

    public private(set) var actions: [UIAlertAction] = []
    /// UIKit renders this action as a filled tint pill with a semibold
    /// title. Must be one of `actions`.
    public var preferredAction: UIAlertAction? {
        didSet { _refreshActionStyles() }
    }
    public var message: String?
    public private(set) var preferredStyle: Style = .alert
    /// Non-nil once `addTextField` has been called (UIKit returns nil until
    /// then).
    public private(set) var textFields: [UITextField]?

    var actionViews: [_UIAlertActionView] = []

    public convenience init(title: String?, message: String?, preferredStyle: Style) {
        self.init()
        self.title = title
        self.message = message
        self.preferredStyle = preferredStyle
        // An alert is always modal over the presenter.
        modalPresentationStyle = .alert
    }

    public func addAction(_ action: UIAlertAction) {
        actions.append(action)
        action.onChange = { [weak self] in self?._refreshActionStyles() }
    }

    /// `.alert` only, like UIKit (an action sheet ignores it).
    public func addTextField(configurationHandler: ((UITextField) -> Void)? = nil) {
        guard preferredStyle == .alert else { return }
        let tf = UITextField()
        tf.font = .systemFont(ofSize: 17)
        configurationHandler?(tf)
        if textFields == nil { textFields = [] }
        textFields?.append(tf)
    }

    open override func loadView() {
        view = _UIAlertCardView()
    }

    func _refreshActionStyles() {
        for v in actionViews {
            v.isPreferred = (preferredAction === v.action)
            v.applyStyle()
        }
    }

    // MARK: Layout (all constants measured — see the file header)

    /// The order the pills are laid out in, which is NOT the order actions
    /// were added: MEASURED, the cancel action goes LEFT in a two-up row and
    /// LAST in a vertical stack.
    var _layoutOrderedActions: [UIAlertAction] {
        guard let cancelIndex = actions.firstIndex(where: { $0.style == .cancel })
        else { return actions }
        var rest = actions
        let cancel = rest.remove(at: cancelIndex)
        return actions.count == 2 ? [cancel] + rest : rest + [cancel]
    }

    /// Number of lines `text` wraps to inside the card's text column.
    func _lineCount(_ text: String, font: UIFont) -> Int {
        let width = UIAlertMetrics.cardWidth - 2 * UIAlertMetrics.textInsetX
        return Swift.max(1, TextLayout.wrap(text, font: font, maxWidth: width,
                                            maxLines: 0).count)
    }

    /// Build (or rebuild) the card's subviews for `width` and return the
    /// card's total height.
    @discardableResult
    func _layoutCard(width: CGFloat) -> CGFloat {
        let card = view!
        for sub in card.subviews { sub.removeFromSuperview() }
        actionViews = []

        let inset = UIAlertMetrics.textInsetX
        let textWidth = width - 2 * inset
        var y: CGFloat = 0

        let hasTitle = !(title ?? "").isEmpty
        let hasMessage = !(message ?? "").isEmpty
        let solo = hasTitle != hasMessage

        if hasTitle || hasMessage {
            y += UIAlertMetrics.topPadding
            if solo {
                // MEASURED: a lone title (or a lone message) renders 17 pt
                // REGULAR and centred.
                let text = hasTitle ? title! : message!
                let f = UIAlertMetrics.soloFont
                let h = UIAlertMetrics.titleLineHeight
                    + CGFloat(_lineCount(text, font: f) - 1) * UIAlertMetrics.titleLinePitch
                card.addSubview(_makeLabel(text, font: f, color: .label,
                                           alignment: .center,
                                           frame: CGRect(x: inset, y: y,
                                                         width: textWidth, height: h)))
                y += h
            } else {
                let tf = UIAlertMetrics.titleFont
                let th = UIAlertMetrics.titleLineHeight
                    + CGFloat(_lineCount(title!, font: tf) - 1) * UIAlertMetrics.titleLinePitch
                card.addSubview(_makeLabel(title!, font: tf, color: .label,
                                           alignment: .left,
                                           frame: CGRect(x: inset, y: y,
                                                         width: textWidth, height: th)))
                y += th + UIAlertMetrics.titleMessageGap
                let mf = UIAlertMetrics.messageFont
                let mh = UIAlertMetrics.messageLineHeight
                    + CGFloat(_lineCount(message!, font: mf) - 1) * UIAlertMetrics.messageLinePitch
                card.addSubview(_makeLabel(message!, font: mf, color: .secondaryLabel,
                                           alignment: .left,
                                           frame: CGRect(x: inset, y: y,
                                                         width: textWidth, height: mh)))
                y += mh
            }
        }

        if let fields = textFields, !fields.isEmpty {
            // With no header the field block starts at the ordinary top
            // padding; with one it hangs 16.333 pt below the last label.
            y += (hasTitle || hasMessage) ? UIAlertMetrics.textFieldGap
                                          : UIAlertMetrics.topPadding
            for tf in fields {
                let pill = UIView(frame: CGRect(
                    x: UIAlertMetrics.textFieldInsetX, y: y,
                    width: width - 2 * UIAlertMetrics.textFieldInsetX,
                    height: UIAlertMetrics.textFieldHeight))
                pill.backgroundColor = UIAlertMetrics.actionFill
                pill.layer.cornerRadius = UIAlertMetrics.actionCornerRadius
                let fh = tf.font.labelLineHeight
                tf.frame = CGRect(x: inset - UIAlertMetrics.textFieldInsetX,
                                  y: (UIAlertMetrics.textFieldHeight - fh) / 2,
                                  width: textWidth, height: fh)
                pill.addSubview(tf)
                card.addSubview(pill)
                y += UIAlertMetrics.textFieldHeight + UIAlertMetrics.actionSpacing
            }
            y -= UIAlertMetrics.actionSpacing
            y += UIAlertMetrics.textFieldBottomPadding
        } else if hasTitle || hasMessage {
            y += solo ? UIAlertMetrics.headerBottomPaddingSingle
                      : UIAlertMetrics.headerBottomPadding
        }

        let ordered = _layoutOrderedActions
        guard !ordered.isEmpty else { return y }
        let pad = UIAlertMetrics.actionsPadding
        y += pad
        let rowWidth = width - 2 * pad
        if ordered.count == 2 {
            // MEASURED: exactly two actions sit side by side, cancel LEFT.
            let w = (rowWidth - UIAlertMetrics.actionSpacing) / 2
            for (i, a) in ordered.enumerated() {
                let v = _makeActionView(a)
                v.frame = CGRect(x: pad + CGFloat(i) * (w + UIAlertMetrics.actionSpacing),
                                 y: y, width: w, height: UIAlertMetrics.actionHeight)
                card.addSubview(v)
            }
            y += UIAlertMetrics.actionHeight
        } else {
            for (i, a) in ordered.enumerated() {
                let v = _makeActionView(a)
                v.frame = CGRect(
                    x: pad,
                    y: y + CGFloat(i) * (UIAlertMetrics.actionHeight + UIAlertMetrics.actionSpacing),
                    width: rowWidth, height: UIAlertMetrics.actionHeight)
                card.addSubview(v)
            }
            y += CGFloat(ordered.count) * UIAlertMetrics.actionHeight
                + CGFloat(ordered.count - 1) * UIAlertMetrics.actionSpacing
        }
        y += pad
        _refreshActionStyles()
        return y
    }

    private func _makeLabel(_ text: String, font: UIFont, color: UIColor,
                            alignment: NSTextAlignment, frame: CGRect) -> UILabel {
        let l = UILabel(frame: frame)
        l.text = text
        l.font = font
        l.textColor = color
        l.textAlignment = alignment
        l.numberOfLines = 0
        return l
    }

    private func _makeActionView(_ a: UIAlertAction) -> _UIAlertActionView {
        let v = _UIAlertActionView(action: a)
        v.addTarget(for: .touchUpInside) { [weak self] _, _ in
            self?._perform(a)
        }
        actionViews.append(v)
        return v
    }

    /// UIKit dismisses first, then runs the handler.
    func _perform(_ a: UIAlertAction) {
        guard a.isEnabled else { return }
        let presenter = presentingViewController
        presenter?.dismiss(animated: true) { a._fire() }
        if presenter == nil { a._fire() }
    }

    // MARK: Presentation plumbing

    override func _makeDefaultPresentationController(presenting: UIViewController)
        -> UIPresentationController {
        _UIAlertPresentationController(presentedViewController: self, presenting: presenting)
    }
    override func _makeDefaultPresentAnimator() -> UIViewControllerAnimatedTransitioning {
        _UIAlertAnimator(presenting: true)
    }
    override func _makeDefaultDismissAnimator() -> UIViewControllerAnimatedTransitioning {
        _UIAlertAnimator(presenting: false)
    }
}

// MARK: - Presentation controller

/// Owns the dim behind an alert and sizes the card. The card IS the
/// presented controller's view, so `presentedView` is the default.
@preconcurrency @MainActor
final class _UIAlertPresentationController: UIPresentationController {
    let dim = _UIDimmingView()
    let shadow = _UIAlertShadowView()

    var alert: UIAlertController? { presentedViewController as? UIAlertController }

    /// Computing the frame LAYS THE CARD OUT (its height is its content's),
    /// and `present` reads the frame three times — cache it so the subviews
    /// are built once.
    private var cachedFrame: CGRect?

    /// MEASURED: 320 wide, centred horizontally, centred in the SAFE AREA
    /// vertically (not in the container).
    override var frameOfPresentedViewInContainerView: CGRect {
        if let cachedFrame { return cachedFrame }
        guard let c = containerView, let alert else { return .zero }
        let w = UIAlertMetrics.cardWidth
        let h = alert._layoutCard(width: w)
        let top = UIScreenMetrics.safeAreaTop
        let bottom = c.bounds.height - UIScreenMetrics.safeAreaBottom
        let f = CGRect(x: ((c.bounds.width - w) / 2),
                       y: (top + bottom) / 2 - h / 2, width: w, height: h)
        cachedFrame = f
        return f
    }

    override func presentationTransitionWillBegin() {
        guard let container = containerView else { return }
        dim.frame = container.bounds
        dim.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        dim.backgroundColor = .black
        dim.alpha = container.traitCollection.userInterfaceStyle == .dark
            ? UIAlertMetrics.dimAlphaDark : UIAlertMetrics.dimAlphaLight
        container.addSubview(dim)

        presentedViewController.loadViewIfNeeded()
        let card = presentedViewController.view!
        let frame = frameOfPresentedViewInContainerView
        card.frame = frame
        card.autoresizingMask = [.flexibleLeftMargin, .flexibleRightMargin,
                                 .flexibleTopMargin, .flexibleBottomMargin]

        let spill = UIAlertMetrics.shadowSpill
        shadow.frame = frame.insetBy(dx: -spill, dy: -spill)
        shadow.cardRect = CGRect(x: spill, y: spill,
                                 width: frame.width, height: frame.height)
        shadow.autoresizingMask = card.autoresizingMask
        shadow.setNeedsDisplay()
        container.addSubview(shadow)
        container.addSubview(card)
    }

    override func dismissalTransitionDidEnd(_ completed: Bool) {
        guard completed else { return }
        presentedViewController.viewIfLoaded?.removeFromSuperview()
        shadow.removeFromSuperview()
        containerView?.removeFromSuperview()
    }
}

/// MEASURED alert transition: only the dim animates, on a critically damped
/// spring. The card carries no animation on its layer or on any ancestor —
/// see the file header and docs/KNOWN_GAPS.md.
@preconcurrency @MainActor
final class _UIAlertAnimator: UIViewControllerAnimatedTransitioning {
    let presenting: Bool
    init(presenting: Bool) { self.presenting = presenting }

    func transitionDuration(using _: UIViewControllerContextTransitioning?) -> TimeInterval {
        UIAlertMetrics.transitionDuration
    }

    func animateTransition(using ctx: UIViewControllerContextTransitioning) {
        let dim = ctx.containerView.subviews.first { $0 is _UIDimmingView }
        let duration = transitionDuration(using: ctx)
        let target: CGFloat
        if presenting {
            target = dim?.alpha ?? 0
            dim?.alpha = 0
        } else {
            target = 0
        }
        UIView.animate(withDuration: duration, delay: 0, usingSpringWithDamping: 1,
                       initialSpringVelocity: 0, options: [], animations: {
            dim?.alpha = target
        }, completion: { _ in ctx.completeTransition(true) })
    }
}
