// UIRefreshControl + its UIScrollView pull-to-refresh integration.
// Owner: controls module (app-compat cluster "controls2").
//
// GEOMETRY — ALL MEASURED from real UIKit (Mac Catalyst iOS 26.1) through
// the offscreen oracle, which renders this control faithfully (unlike the
// search bar and the stepper, whose chrome is a private material / a SwiftUI
// hosting view). Probe: a UIRefreshControl attached to a UIScrollView, view
// tree + CALayer tree dumped, then rendered with `layer.render(in:)` and the
// ink measured off the pixels.
//
//   * The control's frame is (0, contentOffset.y, scrollView.width, 60):
//     60 pt tall (`controlHeight`), full width, and its ORIGIN TRACKS the
//     scroll offset — measured over a −0…−200 pt sweep, rc.frame.y == offset
//     at every step. It is `isHidden == true` whenever it is not refreshing.
//   * The spinner is a CAReplicatorLayer with `instanceCount == 8` and an
//     `instanceTransform` of exactly 45 degrees, hosted in a 100x100 box
//     CENTRED in the control (measured (110, −20, 100, 100) in a 320x60
//     control). The seed blade is a 3.5 x 10 pt rounded rect with corner
//     radius 1.75, at (48.5, 35) in that box — i.e. a capsule whose long
//     axis is radial, whose centre sits 10 pt from the graphic centre, and
//     whose ink therefore spans radius 5…15. The rendered PNG confirms it:
//     the ink bounding box is exactly 30 x 30 pt centred on the control.
//   * Blade colour: `label` at alpha 216/255 = 0.847059 (read off the
//     rendered pixels; the layer's own CGColor reports the same 0.847059).
//     All eight blades share it.
//
// WHAT IS **NOT** MEASURED, and why
//
//   * The BLADE-CHASE ANIMATION. Real UIKit animates the replicator's
//     `instanceAlphaOffset` (the layer dump lists an "instanceAlphaOffset"
//     animation), and Core Animation discards animations on a layer with no
//     render context, so the offscreen oracle can only ever see the REST
//     pose — eight blades at one uniform alpha. That rest pose is what the
//     golden pins and what this file draws. There is no fade ladder and no
//     spin here; `UIActivityIndicatorView`'s ladder is NOT transferable
//     because its ladder lives in the layers themselves, which is why that
//     control could reproduce it and this one cannot. Measuring it needs the
//     windowed oracle with a display-link sample, exactly like the
//     activity indicator's timing (docs/KNOWN_GAPS.md).
//   * The PULL THRESHOLD and the refreshing content inset. Neither is
//     observable offscreen: driving `contentOffset` to −200 pt through the
//     property never fires `.valueChanged` and never sets `isRefreshing`,
//     because UIKit arms the trigger from the real pan gesture's end, which
//     an offscreen scroll view has no way to receive. The numbers used here
//     — trigger at a drag past `controlHeight` (60 pt) beyond the top edge,
//     released; hold `contentInset.top += controlHeight` while refreshing —
//     are UIKit's DOCUMENTED behaviour, not a measurement. Pinning them
//     needs a synthetic drag in the iOS Simulator, the route
//     `Tools/oracle2/scrollprobe.swift` already established for the scroll
//     physics (golden/scroll_traces/SCHEMA.md).
//   * `attributedTitle` is stored and NOT drawn. Real UIKit puts a 12 pt
//     label at (10, 48.5, width−20, 0) under the spinner — height ZERO and
//     alpha 0 with no title, i.e. the fixture cannot see it either.

open class UIRefreshControl: UIControl {
    /// Measured: the control is always 60 pt tall.
    public static let controlHeight: CGFloat = 60

    /// Measured blade geometry (file header).
    static let bladeCount = 8
    static let bladeLength: CGFloat = 10
    static let bladeThickness: CGFloat = 3.5
    /// Distance from the graphic centre to a blade's centre (vertical).
    static let bladeRing: CGFloat = 10
    /// Horizontal offset of the seed blade's centre from the graphic centre:
    /// the measured seed sits at x 48.5…52 in a 100 pt box, centre 50.25.
    static let bladeSeedDX: CGFloat = 0.25
    /// Measured uniform blade alpha, 216/255.
    static let bladeAlpha: CGFloat = 216.0 / 255.0

    public private(set) var isRefreshing = false

    /// Stored, never drawn — see the file header.
    public var attributedTitle: NSAttributedString?

    /// The scroll view this control is installed in.
    weak var _scrollView: UIScrollView?
    /// The scroll view's `contentInset.top` before this control claimed it.
    var _baseTopInset: CGFloat = 0
    /// True while the finger has pulled past the trigger distance, so a
    /// release starts a refresh.
    var _armed = false

    public override init(frame: CGRect) {
        super.init(frame: frame)
        isHidden = true
        isUserInteractionEnabled = false
    }

    public convenience init() {
        self.init(frame: CGRect(x: 0, y: 0, width: 0,
                                height: UIRefreshControl.controlHeight))
    }

    /// True while this control is holding the scroll view's top inset open
    /// so the spinner stays on screen. Only a USER-STARTED refresh does
    /// that — see `beginRefreshing()`.
    var _holdsInset = false

    /// Starts the spinner. It does **not** scroll the view: UIKit documents
    /// that a programmatic `beginRefreshing()` leaves `contentOffset` alone
    /// and the app must scroll to reveal the control itself, and the oracle
    /// agrees (a refreshing control offscreen keeps frame (0, 0, W, 60), i.e.
    /// the untouched offset — golden/control_refresh.layout.json). A refresh
    /// the USER pulled for is different: that path holds the inset open, in
    /// `_scrollDidEndDrag()`.
    public func beginRefreshing() {
        guard !isRefreshing else { return }
        isRefreshing = true
        isHidden = false
        setNeedsDisplay()
    }

    /// Stops the spinner and gives back any inset this control was holding.
    public func endRefreshing() {
        guard isRefreshing else { return }
        isRefreshing = false
        isHidden = true
        _armed = false
        setNeedsDisplay()
        guard _holdsInset, let sv = _scrollView else { return }
        _holdsInset = false
        let restored = _baseTopInset
        let wasAtTop = sv.contentOffset.y <= -sv.contentInset.top + 0.5
        sv.contentInset.top = restored
        if wasAtTop { sv.contentOffset.y = -restored }
        sv.setNeedsLayout()
    }

    /// Hold the scroll view open at the control's height (documented UIKit
    /// behaviour for a user-started refresh; NOT measured — file header).
    private func _holdInsetOpen() {
        guard !_holdsInset, let sv = _scrollView else { return }
        _holdsInset = true
        _baseTopInset = sv.contentInset.top
        sv.contentInset.top = _baseTopInset + UIRefreshControl.controlHeight
        if sv.contentOffset.y <= -_baseTopInset {
            sv.contentOffset.y = -sv.contentInset.top
        }
        sv.setNeedsLayout()
    }

    // MARK: Scroll-view driven state (see the file header for what is and is
    // not measured)

    /// Called by the scroll view on every offset change while dragging.
    func _scrollDidDrag(to offsetY: CGFloat, topEdge: CGFloat) {
        guard !isRefreshing else { return }
        let pulled = topEdge - offsetY
        isHidden = pulled <= 0
        if pulled >= UIRefreshControl.controlHeight { _armed = true }
        setNeedsDisplay()
    }

    /// Called by the scroll view when the drag ends.
    func _scrollDidEndDrag() {
        guard !isRefreshing else { return }
        guard _armed else { isHidden = true; return }
        _armed = false
        beginRefreshing()
        _holdInsetOpen()
        sendActions(for: .valueChanged)
    }

    // MARK: Drawing

    public override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        // Measured: `rc.tintColor` is nil on a fresh control even inside a
        // scroll view, and the seed layer's colour is `labelColor` — so the
        // default is `.label`, NOT the inherited tint (UIView's tintColor
        // getter would hand back systemBlue). An explicit tint still wins.
        let base = (_tintColor ?? UIColor.label).resolvedCGColor(with: traitCollection)
        guard base.alpha > 0 else { return }
        let color = base.withAlpha(base.alpha * UIRefreshControl.bladeAlpha)
        let cx = bounds.midX
        let cy = bounds.midY
        // The SEED blade, in the graphic's own coordinates. Measured frame is
        // (48.5, 35, 3.5, 10) inside the 100x100 replicator box, so the blade
        // is axis-aligned, points UP, and its centre is (50.25, 40) — a
        // quarter point RIGHT of the box centre (50, 50) and 10 pt above it.
        // That 0.25 pt is not noise: without it every diagonal blade lands
        // half a point off the golden.
        let seed = CGRect(x: cx + UIRefreshControl.bladeSeedDX
                             - UIRefreshControl.bladeThickness / 2,
                          y: cy - UIRefreshControl.bladeRing
                             - UIRefreshControl.bladeLength / 2,
                          width: UIRefreshControl.bladeThickness,
                          height: UIRefreshControl.bladeLength)
        let capsule = Path.roundedRect(seed,
                                       cornerRadius: UIRefreshControl.bladeThickness / 2)
        for k in 0..<UIRefreshControl.bladeCount {
            // The replicator rotates each instance a further 45 degrees about
            // the graphic centre (measured instanceTransform).
            let phi = CGFloat(k) * .pi / 4
            let t = CGAffineTransform(translationX: -cx, y: -cy)
                .concatenating(CGAffineTransform(rotationAngle: phi))
                .concatenating(CGAffineTransform(translationX: cx, y: cy))
            canvas.fill(capsule.applying(t), color: color)
        }
    }
}

// MARK: - UIScrollView integration

extension UIScrollView {
    /// The pull-to-refresh control. Assigning one installs it as the scroll
    /// view's FIRST subview, which is where real UIKit puts it (measured:
    /// `subviews == [UIRefreshControl, _UIScrollerImpContainerView, …]`).
    public var refreshControl: UIRefreshControl? {
        get { _refreshControl }
        set {
            guard _refreshControl !== newValue else { return }
            if let old = _refreshControl {
                old.removeFromSuperview()
                old._scrollView = nil
            }
            _refreshControl = newValue
            guard let rc = newValue else { return }
            rc._scrollView = self
            insertSubview(rc, at: 0)
            setNeedsLayout()
        }
    }

    /// Measured: frame = (0, contentOffset.y, width, 60).
    func _layoutRefreshControl() {
        guard let rc = _refreshControl else { return }
        rc.frame = CGRect(x: 0, y: contentOffset.y, width: bounds.width,
                          height: UIRefreshControl.controlHeight)
    }

    /// The offset at which the content's top edge is flush with the top of
    /// the scroll view — `-contentInset.top`, minus the inset the refresh
    /// control itself is holding open while it spins.
    var _refreshTopEdge: CGFloat {
        guard let rc = _refreshControl, rc._holdsInset else { return -contentInset.top }
        return -rc._baseTopInset
    }
}
