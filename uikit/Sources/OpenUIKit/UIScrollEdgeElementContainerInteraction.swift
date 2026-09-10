// UIScrollEdgeElementContainerInteraction — iOS 26's "this view sits on a
// scroll edge" declaration. Owner: scroll module.
//
// MEASURED 2026-09-09, Tools/oracle2/signalrowsprobe (iPhone 16 / iOS 26.1,
// ios-26.1-iphone16.json + edge-ios-26.1-iphone16.json), Signal's exact
// pattern (ConversationViewController, StickerPackViewController,
// OWSTableViewController2: `init()`, `edge = .top/.bottom`, `scrollView =`,
// `container.addInteraction(_:)`, scroll view inset by the container):
//
//   STATE   NSObject subclass; `edge` starts EMPTY (rawValue 0, not .top),
//           `scrollView` nil and weak (a released scroll view reads nil),
//           `view` nil until `addInteraction`. Assigning `[.top, .bottom]`
//           stores 5, `.left` stores 2 — plain storage.
//   TREE    The container's frame, subviews, sublayers, mask, filters and
//           background do not change; its superview's subviews do not
//           change. Apple appends a private `_UIScrollPocketInteraction` to
//           the container's `interactions` (not reproduced: a private type
//           in a public list) and, once the container holds an ELEMENT,
//           inserts two `_UITouchPassthroughView`s into the scroll view
//           (one per attached edge). A label or a `UIVisualEffectView`
//           counts as an element; a plain `UIView` strip or an opaque
//           `backgroundColor` does not.
//   PIXELS  drawHierarchy snapshots never show the effect; render-server
//           screenshots do. Nothing at rest (offset == -inset). Once content
//           passes under an element-holding container, the pocket zone is a
//           black scrim at 24.7 % over the container band (red (255,0,0)
//           reads (192,0,0), white reads 192), fading to 0 about 20 pt past
//           the container's inner edge, plus a ~6 pt content blur that this
//           port does not have (docs/KNOWN_GAPS.md). Same profile for
//           `.bottom`, mirrored. `topEdgeEffect.style = .hard` and any
//           later `.automatic` switch the material to a LIGHT scrim (white
//           83 %, flat to the inner edge for `.hard`); so does attaching to
//           an EMPTY container and adding elements later. Those variants are
//           recorded, not modelled: Signal attaches once, with content,
//           and never touches the style.
//   UNMEASURED  dark interface style with the dark variant, `.left/.right`
//           edges (stored only), engagement between 0 and 100 pt of
//           penetration (measured off at 0, on at 100), hidden elements.

#if canImport(Foundation)
import class Foundation.NSObject
import class Foundation.NSCoder
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
import class ObjectiveC.NSCoder
#else
#error("UIScrollEdgeElementContainerInteraction requires NSObject")
#endif

@preconcurrency @MainActor
open class UIScrollEdgeElementContainerInteraction: NSObject, UIInteraction {
    public private(set) weak var view: UIView?

    /// The scroll edge the container sits on. Empty by default (measured).
    open var edge: UIRectEdge = [] {
        didSet { if edge != oldValue { _update() } }
    }

    /// The scroll view whose content passes under the container. Weak.
    open weak var scrollView: UIScrollView? {
        didSet {
            guard scrollView !== oldValue else { return }
            oldValue?._removeScrollEdgeInteraction(self)
            pocket?.removeFromSuperview()
            pocket = nil
            scrollView?._addScrollEdgeInteraction(self)
            _update()
        }
    }

    public override init() {}

    public func willMove(to view: UIView?) {}

    public func didMove(to view: UIView?) {
        self.view = view
        if view == nil {
            pocket?.removeFromSuperview()
            pocket = nil
        }
        _update()
    }

    // MARK: Pocket

    var pocket: _UITouchPassthroughView?

    /// Distance past the inner edge where the measured scrim reaches 0.
    static let fadeOvershoot: CGFloat = 20

    /// Measured scrim alpha by distance `d` inside the container from its
    /// inner edge (negative = past the edge, into the content). Header
    /// (`under100`, x 380) and footer (`bottomUnder`) columns over red
    /// bands, 1 pt profile: full 0.247 from d ≥ 60, then a straight run to
    /// ~0.10 at d 16–21, then an ease-out that is 0.035 at the edge and 0
    /// twenty points past it.
    static let alphaProfile: [(d: CGFloat, alpha: CGFloat)] = [
        (-20, 0), (-16, 0.004), (-8, 0.016), (0, 0.035), (8, 0.063),
        (16, 0.10), (56, 0.235), (60, 0.247),
    ]

    static func scrimAlpha(at d: CGFloat) -> CGFloat {
        let table = alphaProfile
        if d <= table[0].d { return 0 }
        if d >= table[table.count - 1].d { return table[table.count - 1].alpha }
        for i in 1..<table.count where d <= table[i].d {
            let (d0, a0) = table[i - 1], (d1, a1) = table[i]
            return a0 + (a1 - a0) * (d - d0) / (d1 - d0)
        }
        return table[table.count - 1].alpha
    }

    /// Apple's pocket appears for a label or a visual-effect view inside the
    /// container and not for a bare `UIView`: "element" is any descendant
    /// whose class is not exactly `UIView`.
    static func holdsElement(_ view: UIView) -> Bool {
        for sub in view.subviews {
            if type(of: sub) != UIView.self { return true }
            if holdsElement(sub) { return true }
        }
        return false
    }

    /// Recompute pocket presence, frame and visibility. Called by the scroll
    /// view on every scroll step and layout pass, and on our own changes.
    func _update() {
        guard let container = view, let scroll = scrollView,
              edge == .top || edge == .bottom else {
            pocket?.isHidden = true
            return
        }
        guard UIScrollEdgeElementContainerInteraction.holdsElement(container) else {
            pocket?.isHidden = true
            return
        }
        let pocketView: _UITouchPassthroughView
        if let existing = pocket, existing.superview === scroll {
            pocketView = existing
        } else {
            pocket?.removeFromSuperview()
            pocketView = _UITouchPassthroughView(edge: edge)
            scroll.addSubview(pocketView)
            pocket = pocketView
        }
        pocketView.edge = edge
        let band = container.convert(container.bounds, to: scroll)
        let overshoot = UIScrollEdgeElementContainerInteraction.fadeOvershoot
        let frame = edge == .top
            ? CGRect(x: band.minX, y: band.minY, width: band.width, height: band.height + overshoot)
            : CGRect(x: band.minX, y: band.minY - overshoot, width: band.width, height: band.height + overshoot)
        if pocketView.frame != frame {
            pocketView.frame = frame
            pocketView.setNeedsDisplay()
        }
        let offset = scroll.contentOffset
        let engaged = edge == .top
            ? offset.y > scroll.minContentOffset.y + 0.5
            : offset.y < scroll.maxContentOffset.y - 0.5
        pocketView.isHidden = !engaged
        scroll.bringSubviewToFront(pocketView)
        scroll._frontIndicatorsOverPockets()
    }
}

/// Weak slot in `UIScrollView._scrollEdgeInteractions`.
@preconcurrency @MainActor
final class _UIScrollEdgeInteractionRef {
    weak var interaction: UIScrollEdgeElementContainerInteraction?
    init(_ interaction: UIScrollEdgeElementContainerInteraction) { self.interaction = interaction }
}

/// The scroll-edge pocket: Apple's private view of the same name, inserted
/// into the scroll view once an element-holding container is attached. It
/// paints the measured scrim and passes touches through.
@preconcurrency @MainActor
final class _UITouchPassthroughView: UIView {
    var edge: UIRectEdge

    init(edge: UIRectEdge) {
        self.edge = edge
        super.init(frame: .zero)
        isUserInteractionEnabled = false
        backgroundColor = nil
    }

    required init?(coder: NSCoder) {
        edge = .top
        super.init(coder: coder)
    }

    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? { nil }

    override func drawContent(in canvas: Canvas, bounds: CGRect) {
        guard bounds.width > 0, bounds.height > 0 else { return }
        let overshoot = UIScrollEdgeElementContainerInteraction.fadeOvershoot
        let inner = edge == .top ? bounds.height - overshoot : overshoot
        let black = UIColor.black.cgColor
        var y: CGFloat = 0
        while y < bounds.height {
            let mid = y + 0.5
            let d = edge == .top ? inner - mid : mid - inner
            let alpha = UIScrollEdgeElementContainerInteraction.scrimAlpha(at: d)
            // Rows deeper than the profile's last knot share one fill.
            let last = UIScrollEdgeElementContainerInteraction.alphaProfile.last!.d
            var height: CGFloat = 1
            if d >= last {
                height = edge == .top ? max(1, inner - last - y) : bounds.height - y
            }
            if alpha > 0 {
                canvas.fill(rect: CGRect(x: 0, y: y, width: bounds.width, height: height),
                            color: black.withAlpha(alpha))
            }
            y += height
        }
    }
}
