// UIStackView. Owner: stack module.
//
// Direct frame computation (no Auto Layout engine). The fractional-position
// rounding was reverse-engineered from the Mac Catalyst oracle (iOS 26.1)
// with fillEqually probes at scales 1, 2 and 3 (see golden/stack_vertical:
// 300pt / 3 with spacing 10 -> heights 93.5 at y 0, 103, 207):
//
// - Along the axis, each arranged view's EXACT origin/size are computed
//   first (exact equal split for fillEqually, exact cumulative positions),
//   then rounded INDEPENDENTLY of display scale:
//     * size   -> nearest 0.5pt, ties away from zero (93.3333 -> 93.5,
//                 57.25 -> 57.5, 24.75 -> 25)
//     * origin -> nearest whole point, ties away from zero (103.333 -> 103,
//                 206.667 -> 207, 49.5 -> 50 even though 49.5 is
//                 pixel-aligned at 2x; identical results at scale 1 and 3)
//   The last view may overhang the stack bounds by up to 0.5pt, exactly
//   like real UIKit (golden stack_vertical: 207 + 93.5 = 300.5 > 300).
// - Hidden arranged views take NO space and their spacing collapses; the
//   view is parked with zero axis size at the junction midpoint
//   (oracle probe: 4 views, spacing 8, view 2 hidden -> frame
//   [215, 0, 0, 100]: round(218.667 - 8/2) = 215; cross axis still laid
//   out per alignment).

// NSLayoutConstraint.Axis (previously a stand-alone namespace enum here)
// moved into the real NSLayoutConstraint class with M9
// (AutoLayout/NSLayoutConstraint.swift); UIStackView keeps using it as-is.

// M15: a DEFAULT ARGUMENT or an `@inlinable` body may only use members whose
// defining module THIS FILE imports -- `CGRect.zero` and `CGFloat.pi` do not
// ride in on OpenCoreGraphics' typealias the way ordinary uses do. These are
// SCOPED imports on purpose: they satisfy that rule without pulling in
// CoreGraphics' CGColor / CGAffineTransform, which would collide with
// OpenCoreGraphics' own.
#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif


open class UIStackView: UIView {
    public enum Distribution: Sendable {
        case fill, fillEqually, fillProportionally, equalSpacing, equalCentering
    }
    public enum Alignment: Sendable {
        case fill, leading, center, trailing, top, bottom, firstBaseline, lastBaseline
    }

    public var axis: NSLayoutConstraint.Axis = .horizontal {
        didSet { setNeedsLayout() }
    }
    public var spacing: CGFloat = 0 {
        didSet { setNeedsLayout() }
    }
    public var distribution: Distribution = .fill {
        didSet { setNeedsLayout() }
    }
    public var alignment: Alignment = .fill {
        didSet { setNeedsLayout() }
    }

    public private(set) var arrangedSubviews: [UIView] = []

    public override init(frame: CGRect = .zero) {
        super.init(frame: frame)
    }

    public func addArrangedSubview(_ view: UIView) {
        if !arrangedSubviews.contains(where: { $0 === view }) {
            arrangedSubviews.append(view)
        }
        addSubview(view)
        // UIKit does this too: an arranged view is positioned by the stack,
        // never by its autoresizing mask. Without it, a real app's
        // `stackView.addArrangedSubview(v)` followed by
        // `v.heightAnchor.constraint(...)` puts a REQUIRED frame constraint
        // and a REQUIRED height constraint into the same solve and one of
        // them gets dropped. Found by the real-app harness (M14).
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    public func insertArrangedSubview(_ view: UIView, at index: Int) {
        arrangedSubviews.removeAll { $0 === view }
        arrangedSubviews.insert(view, at: index)
        addSubview(view)
        view.translatesAutoresizingMaskIntoConstraints = false
    }

    /// Like UIKit: stops arranging but does NOT remove from subviews.
    public func removeArrangedSubview(_ view: UIView) {
        arrangedSubviews.removeAll { $0 === view }
        setNeedsLayout()
    }

    // MARK: Rounding (oracle-verified, display-scale independent)

    /// Axis origins: nearest whole point, ties away from zero.
    static func roundOrigin(_ v: CGFloat) -> CGFloat {
        v.rounded(.toNearestOrAwayFromZero)
    }
    /// Axis sizes: nearest half point, ties away from zero.
    static func roundSize(_ v: CGFloat) -> CGFloat {
        (v * 2).rounded(.toNearestOrAwayFromZero) / 2
    }

    // MARK: Content measurement

    /// Preferred size of an arranged view: intrinsicContentSize where
    /// provided, else sizeThatFits of the stack bounds (plain UIViews
    /// report their current size; nested stacks their fitting size).
    private func contentSize(of view: UIView) -> CGSize {
        let intrinsic = view.intrinsicContentSize
        var s = view.sizeThatFits(bounds.size)
        if intrinsic.width != UIView.noIntrinsicMetric { s.width = intrinsic.width }
        if intrinsic.height != UIView.noIntrinsicMetric { s.height = intrinsic.height }
        // Explicit size constraints count as content (M14 — see
        // naturalFittingSize).
        if let w = view._explicitSizeConstraint(.width) { s.width = Swift.max(s.width, w) }
        if let h = view._explicitSizeConstraint(.height) { s.height = Swift.max(s.height, h) }
        return s
    }

    /// True when `view` has no intrinsic metric along our axis, so real
    /// UIKit generates no content-hugging/compression constraint for it on
    /// that axis: plain UIViews, nested stacks, UIProgressView width, ...
    /// Under .fill these views soak up the slack before any intrinsic-sized
    /// sibling is stretched or compressed (oracle probes probe_fill_nested,
    /// probe_fill_twospacers; golden stack_mixed).
    private func isAxisFlexible(_ view: UIView) -> Bool {
        // A row with its own size constraint on the axis is NOT flexible —
        // it asked for a length, exactly like an intrinsic one. Without this
        // a stack of constraint-sized rows collapses every row but the last
        // (M14, docs/REAL_APP_TEST.md).
        if view._explicitSizeConstraint(axis == .horizontal ? .width : .height) != nil {
            return false
        }
        // A NESTED stack stays flexible even though M14 gave stacks an
        // intrinsic content size: oracle probe probe_fill_nested measures the
        // nested stack, not its intrinsic-sized sibling, absorbing the slack
        // (Tests/OpenUIKitTests/ProgressStackTests.testFillNestedStackIsFlexible).
        // Real UIKit gets there through hugging priority; the intrinsic size
        // must not be read as "inflexible".
        if view is UIStackView { return true }
        let i = view.intrinsicContentSize
        return (axis == .horizontal ? i.width : i.height) == UIView.noIntrinsicMetric
    }

    /// Natural size a child contributes to this stack's own fitting size:
    /// intrinsic metrics where present, a nested stack's fitting size, else
    /// zero — under Auto Layout a plain view's current frame is meaningless,
    /// so unlike contentSize(of:) this never reads the child's frame.
    private func naturalFittingSize(of view: UIView) -> CGSize {
        var s = (view as? UIStackView)?.sizeThatFits(bounds.size) ?? .zero
        let intrinsic = view.intrinsicContentSize
        if intrinsic.width != UIView.noIntrinsicMetric { s.width = intrinsic.width }
        if intrinsic.height != UIView.noIntrinsicMetric { s.height = intrinsic.height }
        // A view with an explicit SIZE CONSTRAINT of its own contributes that
        // size, exactly as it would through UIKit's solver. Real apps size
        // stack rows this way (`row.heightAnchor.constraint(...)`) far more
        // often than by intrinsic content — M14, docs/REAL_APP_TEST.md.
        if let w = view._explicitSizeConstraint(.width) { s.width = max(s.width, w) }
        if let h = view._explicitSizeConstraint(.height) { s.height = max(s.height, h) }
        return s
    }

    /// UIKit's stack reports a content size derived from its arranged views,
    /// which is what lets a constraint-driven stack size itself (and its
    /// scroll view's contentSize) from its rows. Reported only when the stack
    /// itself is constraint-driven, so every frame-based fixture scene keeps
    /// its measured behaviour unchanged.
    open override var intrinsicContentSize: CGSize {
        guard !translatesAutoresizingMaskIntoConstraints,
              !arrangedSubviews.isEmpty else { return super.intrinsicContentSize }
        let s = sizeThatFits(bounds.size)
        return CGSize(width: s.width == 0 ? UIView.noIntrinsicMetric : s.width,
                      height: s.height == 0 ? UIView.noIntrinsicMetric : s.height)
    }

    /// Fitting ("natural") size, the analogue of systemLayoutSizeFitting
    /// (compressed): along the axis the arranged natural lengths (their
    /// maximum times the count for fillEqually) plus spacing; across it the
    /// largest natural cross length. Oracle: golden label_stack_mix inner
    /// vertical stacks report height 19+3+16+3+16 = 57 when measured by the
    /// outer alignment-top stack.
    public override func sizeThatFits(_ size: CGSize) -> CGSize {
        let visible = arrangedSubviews.filter { $0.superview === self && !$0.isHidden }
        guard !visible.isEmpty else { return .zero }
        var axisSum: CGFloat = 0
        var axisMax: CGFloat = 0
        var crossMax: CGFloat = 0
        for view in visible {
            let natural = naturalFittingSize(of: view)
            axisSum += axisLength(natural)
            axisMax = max(axisMax, axisLength(natural))
            crossMax = max(crossMax, crossLength(natural))
        }
        let spacingTotal = spacing * CGFloat(visible.count - 1)
        let along = (distribution == .fillEqually
                     ? axisMax * CGFloat(visible.count) : axisSum) + spacingTotal
        return axis == .horizontal ? CGSize(width: along, height: crossMax)
                                   : CGSize(width: crossMax, height: along)
    }

    private func axisLength(_ s: CGSize) -> CGFloat { axis == .horizontal ? s.width : s.height }
    private func crossLength(_ s: CGSize) -> CGFloat { axis == .horizontal ? s.height : s.width }

    // MARK: Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        // Views un-parented behind our back are not arranged anymore.
        let arranged = arrangedSubviews.filter { $0.superview === self }
        guard !arranged.isEmpty else { return }
        let visible = arranged.filter { !$0.isHidden }

        let total = axisLength(bounds.size)
        let n = CGFloat(visible.count)
        let spacingTotal = spacing * max(0, n - 1)
        let contents = arranged.map { contentSize(of: $0) }

        // Exact (unrounded) axis origin & length per arranged view.
        var exact: [(origin: CGFloat, length: CGFloat)] = []
        if visible.isEmpty {
            exact = arranged.map { _ in (0, 0) }
        } else {
            exact = axisPositions(arranged: arranged, contents: contents,
                                  total: total, visibleCount: n,
                                  spacingTotal: spacingTotal)
        }

        for (i, view) in arranged.enumerated() {
            let (o, l) = exact[i]
            let axisOrigin = UIStackView.roundOrigin(o)
            let axisLen = view.isHidden ? 0 : UIStackView.roundSize(l)
            let (crossOrigin, crossLen) = crossPlacement(content: crossLength(contents[i]))
            if axis == .horizontal {
                view.frame = CGRect(x: axisOrigin, y: crossOrigin,
                                    width: axisLen, height: crossLen)
            } else {
                view.frame = CGRect(x: crossOrigin, y: axisOrigin,
                                    width: crossLen, height: axisLen)
            }
        }
    }

    /// Exact axis (origin, length) for every arranged view, hidden ones
    /// included (hidden: zero length, parked at the collapsed junction).
    private func axisPositions(arranged: [UIView], contents: [CGSize],
                               total: CGFloat, visibleCount n: CGFloat,
                               spacingTotal: CGFloat) -> [(CGFloat, CGFloat)] {
        let available = total - spacingTotal
        let visiblePairs = zip(arranged, contents).filter { !$0.0.isHidden }
        let visibleContents = visiblePairs.map { axisLength($0.1) }
        let contentTotal = visibleContents.reduce(0, +)

        // Length of each VISIBLE view (in arranged order), exact.
        var lengths: [CGFloat] = []
        switch distribution {
        case .fillEqually:
            lengths = visibleContents.map { _ in available / n }
        case .fillProportionally:
            if contentTotal > 0 {
                lengths = visibleContents.map { available * $0 / contentTotal }
            } else {
                lengths = visibleContents.map { _ in available / n }
            }
        case .fill:
            // Views with no intrinsic axis metric are unconstrained in real
            // UIKit and soak up the slack; intrinsic-sized views keep their
            // natural length. Oracle probes:
            //  - one/two spacers: the LAST flexible view takes all the
            //    slack, earlier ones collapse to 0 (probe_fill_twospacers,
            //    golden stack_mixed);
            //  - no flexible view: the FIRST view is stretched — or, when
            //    the content overflows, compressed (probe_fill_labels
            //    213.5/29/41.5 in 300; probe_fill_compress 18/94 in 120).
            lengths = visibleContents
            let flexible = visiblePairs.indices.filter { isAxisFlexible(visiblePairs[$0].0) }
            if let lastFlexible = flexible.last {
                for i in flexible { lengths[i] = 0 }
                let slack = available - lengths.reduce(CGFloat(0), +)
                if slack >= 0 {
                    lengths[lastFlexible] = slack
                } else if let firstRigid = lengths.indices.first(where: { !flexible.contains($0) }) {
                    lengths[firstRigid] += slack
                }
            } else if !lengths.isEmpty {
                lengths[0] += available - contentTotal
            }
        case .equalSpacing, .equalCentering:
            lengths = visibleContents
        }

        // Gap between consecutive visible views, exact.
        var gap = spacing
        if distribution == .equalSpacing && n > 1 {
            gap = max(spacing, (total - contentTotal) / (n - 1))
        }

        var result: [(CGFloat, CGFloat)] = []
        if distribution == .equalCentering && n > 1 {
            // Centers equally spaced; first leading at 0, last trailing at total.
            let firstCenter = lengths.first! / 2
            let lastCenter = total - lengths.last! / 2
            let step = (lastCenter - firstCenter) / (n - 1)
            var vi = 0
            var lastJunction: CGFloat = 0
            for view in arranged {
                if view.isHidden {
                    result.append((lastJunction, 0))
                    continue
                }
                let center = firstCenter + step * CGFloat(vi)
                let len = lengths[vi]
                result.append((center - len / 2, len))
                lastJunction = center + len / 2 + spacing / 2
                vi += 1
            }
            return result
        }

        var cursor: CGFloat = 0
        var placedVisible = false
        var vi = 0
        for view in arranged {
            if view.isHidden {
                // Collapsed: parked at the junction midpoint (spacing already
                // added to the cursor after the previous visible view).
                result.append((placedVisible ? cursor - gap / 2 : 0, 0))
                continue
            }
            let len = lengths[vi]
            result.append((cursor, len))
            cursor += len + gap
            placedVisible = true
            vi += 1
        }
        return result
    }

    /// Exact cross-axis (origin, length) for one view given its content
    /// cross length, before rounding (then rounded like the main axis).
    private func crossPlacement(content: CGFloat) -> (CGFloat, CGFloat) {
        let total = crossLength(bounds.size)
        var origin: CGFloat = 0
        var length: CGFloat = total
        switch alignment {
        case .fill:
            break
        case .leading, .top, .firstBaseline:
            length = content
        case .trailing, .bottom, .lastBaseline:
            length = content
            origin = total - content
        case .center:
            length = content
            origin = (total - content) / 2
        }
        return (UIStackView.roundOrigin(origin), UIStackView.roundSize(length))
    }
}
