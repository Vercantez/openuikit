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
        if prefersLargeTitles {
            largeTitleLabel?.text = title
            largeTitleLabel?.setNeedsDisplay()
        }
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
        if prefersLargeTitles { updateFromScroll() }
    }

    private var contentMidY: CGFloat {
        prefersLargeTitles
            ? UINavigationBar.largeInlineTitleCenterY
            : UINavigationBar.statusBarInset + UINavigationBar.contentHeight / 2
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
            backgroundColor = .systemBackground
            hairline.isHidden = false
            largeTitleLabel?.removeFromSuperview()
            largeTitleLabel = nil
            pocketView.removeFromSuperview()
            trackedScrollView = nil
        }
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
        var taps = [CGFloat](repeating: 0, count: 2 * radius + 1)
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
        var flat = [CGFloat](repeating: 0, count: w * workH * 3)
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
        var hpass = [CGFloat](repeating: 0, count: w * workH * 3)
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
