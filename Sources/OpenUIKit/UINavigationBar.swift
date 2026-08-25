// UINavigationBar. Owner: viewcontroller module (M7.5 navigation).
//
// Visuals per docs/APP_FEEL.md "Navigation transitions":
//   - 44pt content bar below a 20pt status inset (simple constant; the host
//     window has no real status bar). Background: systemBackground with a
//     0.5pt separator hairline at the bottom (blur can wait).
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
// The bar is driven by UINavigationController; it holds no item stack of its
// own (no UINavigationItem — title/backTitle come from the VC stack).

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

public final class UINavigationBar: UIView {
    /// Content bar height (below the status inset), like UIKit's compact
    /// portrait bar.
    public static let contentHeight: CGFloat = 44
    /// Simple status inset constant appropriate for the host window (no
    /// real status bar exists; see docs/APP_FEEL.md).
    public static let statusBarInset: CGFloat = 20
    /// Total bar height.
    public static var barHeight: CGFloat { statusBarInset + contentHeight }

    /// Set by UINavigationController; fired on back-button touchUpInside.
    var onBackTapped: (() -> Void)?

    // Current (settled) elements.
    var titleLabel: UILabel
    var backButton: _UINavigationBarBackButton?
    let hairline: UIView

    public override init(frame: CGRect = .zero) {
        titleLabel = UINavigationBar.makeTitleLabel(nil)
        hairline = UIView()
        super.init(frame: frame)
        backgroundColor = .systemBackground
        hairline.backgroundColor = .separator
        addSubview(hairline)
        addSubview(titleLabel)
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
        setNeedsLayout()
        layoutIfNeeded()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        hairline.frame = CGRect(x: 0, y: bounds.height - 0.5,
                                width: bounds.width, height: 0.5)
        // While a transition drives element centers, keep hands off.
        guard transition == nil else { return }
        place(title: titleLabel, centerX: bounds.width / 2, alpha: 1)
        if let b = backButton { place(back: b, alpha: 1) }
    }

    private var contentMidY: CGFloat {
        UINavigationBar.statusBarInset + UINavigationBar.contentHeight / 2
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
        let backX = t.newBack?.backTitleCenterX
            ?? t.oldBack?.backTitleCenterX ?? mid - slide
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
}
