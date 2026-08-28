// Auto Layout engine. Owner: autolayout module (M9).
//
// Maps installed NSLayoutConstraints onto the Cassowary solver and writes the
// solved frames back, reproducing real UIKit's oracle-observed behavior
// (docs/SCENE_SPEC.md "Constraints (v4.3)"):
//
// - Solving happens in the coordinate space of the layout root (per
//   constraint-ownership subtree: constraints install on the nearest common
//   ancestor of their items; layoutIfNeeded solves from the hierarchy root
//   before the layoutSubviews recursion).
// - Frame-based views (translatesAutoresizingMaskIntoConstraints == true)
//   enter as REQUIRED left/top/width/height constraints from their current
//   frame and are never written back — a frame-based parent at x = 199.5
//   keeps that exact frame, and its constraint children keep exact LOCAL
//   frames (rounding is per-view in local coordinates).
// - Intrinsic content size enters as optional constraints per axis:
//   width/height <= intrinsic at the content-hugging priority and
//   >= intrinsic at the compression-resistance priority (defaults 250/750;
//   UILabel vertical hugging 251).
// - Solver rounding (oracle-fitted, scale-independent): each
//   constraint-positioned view's LOCAL origin rounds to the nearest integer
//   POINT (ties away from zero) and its size to the nearest 0.5 pt (ties
//   away from zero), applied AFTER solving with no error redistribution.

@preconcurrency @MainActor
enum LayoutEngine {
    /// Global count of active constraints — fast bail-out so hierarchies
    /// without Auto Layout pay one integer compare per layoutIfNeeded.
    static var installedConstraintCount = 0

    /// Solve every constraint installed in `root`'s subtree and write the
    /// solved frames to constraint-based views. Idempotent: re-solving an
    /// already-solved hierarchy computes identical frames (the solve reads
    /// only constraints, intrinsic sizes and frame-based views' frames).
    static func solveIfNeeded(root: UIView) {
        guard installedConstraintCount > 0 else { return }
        var constraints: [NSLayoutConstraint] = []
        collectConstraints(root, into: &constraints)
        guard !constraints.isEmpty else { return }
        solve(root: root, constraints: constraints)
    }

    private static func collectConstraints(_ v: UIView,
                                           into out: inout [NSLayoutConstraint]) {
        out.append(contentsOf: v._installedConstraints)
        for s in v.subviews { collectConstraints(s, into: &out) }
    }

    // MARK: - Per-view solver variables

    /// Solver variables for one layout ITEM — a `UIView` or a
    /// ``UILayoutGuide``. A guide gets exactly the same four variables; the
    /// only differences are that its "superview" is its `owningView` and that
    /// the solution is written to `layoutFrame` rather than to a frame
    /// (AutoLayout/UILayoutGuide.swift).
    @MainActor
    private final class ViewVars {
        let view: UIView?
        let guide: UILayoutGuide?
        let left: Cassowary.Variable
        let top: Cassowary.Variable
        let width: Cassowary.Variable
        let height: Cassowary.Variable
        /// The view whose coordinate space this item's origin is measured in.
        var parent: UIView? { view?.superview ?? guide?.owningView }
        init(_ view: UIView) {
            self.view = view
            self.guide = nil
            left = Cassowary.Variable("L")
            top = Cassowary.Variable("T")
            width = Cassowary.Variable("W")
            height = Cassowary.Variable("H")
        }
        init(_ guide: UILayoutGuide) {
            self.view = nil
            self.guide = guide
            left = Cassowary.Variable("gL")
            top = Cassowary.Variable("gT")
            width = Cassowary.Variable("gW")
            height = Cassowary.Variable("gH")
        }
    }

    private static func solve(root: UIView, constraints: [NSLayoutConstraint]) {
        // Involved views: constraint items plus every ancestor up to `root`
        // (ancestor chains anchor the root-space coordinates of nested and
        // frame-based views).
        var vars: [ObjectIdentifier: ViewVars] = [:]
        var ordered: [ViewVars] = []   // deterministic solve order

        func involve(_ v: UIView) {
            var chain: [UIView] = []
            var cur: UIView? = v
            while let c = cur {
                if vars[ObjectIdentifier(c)] != nil { break }
                chain.append(c)
                if c === root { break }
                cur = c.superview
            }
            // Guard: item outside root's subtree — skip whole chain if it
            // never reached a known view or the root.
            for c in chain.reversed() {
                let vv = ViewVars(c)
                vars[ObjectIdentifier(c)] = vv
                ordered.append(vv)
            }
        }

        func involveItem(_ item: AnyObject) {
            if let v = item as? UIView { involve(v); return }
            guard let g = item as? UILayoutGuide, let owner = g.owningView else { return }
            involve(owner)
            guard vars[ObjectIdentifier(g)] == nil else { return }
            let vv = ViewVars(g)
            vars[ObjectIdentifier(g)] = vv
            ordered.append(vv)
        }

        involve(root)
        for c in constraints {
            if let f = c.firstItem { involveItem(f) }
            if let s = c.secondItem { involveItem(s) }
        }

        let solver = Cassowary.Solver()

        func addRequired(_ expr: Cassowary.Expression, _ rel: Cassowary.Relation) {
            try? solver.addConstraint(Cassowary.Constraint(expr, rel))
        }

        // Anchoring constraints per involved item.
        for vv in ordered {
            if let g = vv.guide {
                // A SYSTEM guide is pinned to its owning view by required
                // constraints built from the measured insets; a CUSTOM guide
                // is free and positioned entirely by the app's constraints.
                //
                // `UIScrollView.contentLayoutGuide` is a third case: its
                // ORIGIN is the scroll view's content origin (0,0 in content
                // space, i.e. the same point the scroll view's own left/top
                // variables denote) while its SIZE stays free, because the
                // app's constraints against it are exactly what determines
                // `contentSize`.
                if g.kind == .scrollContent {
                    if let owner = g.owningView,
                       let ov = vars[ObjectIdentifier(owner)] {
                        var ex = Cassowary.Expression(vv.left)
                        ex.add(ov.left, -1)
                        addRequired(ex, .equal)
                        var ey = Cassowary.Expression(vv.top)
                        ey.add(ov.top, -1)
                        addRequired(ey, .equal)
                    }
                    continue
                }
                guard let f = g.systemFrame(),
                      let owner = g.owningView,
                      let ov = vars[ObjectIdentifier(owner)] else { continue }
                var ex = Cassowary.Expression(vv.left, constant: -Double(f.origin.x))
                ex.add(ov.left, -1)
                addRequired(ex, .equal)
                var ey = Cassowary.Expression(vv.top, constant: -Double(f.origin.y))
                ey.add(ov.top, -1)
                addRequired(ey, .equal)
                addRequired(Cassowary.Expression(vv.width,
                                                 constant: -Double(f.width)), .equal)
                addRequired(Cassowary.Expression(vv.height,
                                                 constant: -Double(f.height)), .equal)
                continue
            }
            let v = vv.view!
            if v === root || v.translatesAutoresizingMaskIntoConstraints {
                // Frame-based: required left/top/width/height from the
                // current frame (relative to the superview's variables when
                // involved; the root anchors at its bounds space's origin).
                let f = v.frame
                let sup = vv.parent.flatMap { vars[ObjectIdentifier($0)] }
                if v === root || sup == nil {
                    // Root-space origin: subviews of the root are laid out in
                    // its bounds space.
                    addRequired(Cassowary.Expression(vv.left), .equal)
                    addRequired(Cassowary.Expression(vv.top), .equal)
                    addRequired(Cassowary.Expression(vv.width,
                                                     constant: -Double(v.bounds.width)),
                                .equal)
                    addRequired(Cassowary.Expression(vv.height,
                                                     constant: -Double(v.bounds.height)),
                                .equal)
                } else {
                    let sup = sup!
                    var ex = Cassowary.Expression(vv.left, constant: -Double(f.origin.x))
                    ex.add(sup.left, -1)
                    addRequired(ex, .equal)
                    var ey = Cassowary.Expression(vv.top, constant: -Double(f.origin.y))
                    ey.add(sup.top, -1)
                    addRequired(ey, .equal)
                    addRequired(Cassowary.Expression(vv.width,
                                                     constant: -Double(f.width)), .equal)
                    addRequired(Cassowary.Expression(vv.height,
                                                     constant: -Double(f.height)), .equal)
                }
            } else {
                // Constraint-based: intrinsic content size at hugging (<=)
                // and compression-resistance (>=) priorities per axis.
                let s = v.intrinsicContentSize
                if s.width != UIView.noIntrinsicMetric {
                    addIntrinsic(solver, vv.width, Double(s.width),
                                 hugging: v.contentHuggingPriority(for: .horizontal),
                                 compression: v.contentCompressionResistancePriority(for: .horizontal))
                }
                if s.height != UIView.noIntrinsicMetric {
                    addIntrinsic(solver, vv.height, Double(s.height),
                                 hugging: v.contentHuggingPriority(for: .vertical),
                                 compression: v.contentCompressionResistancePriority(for: .vertical))
                }
            }
        }

        // Scene/user constraints.
        for c in constraints {
            guard let first = c.firstItem,
                  let firstVV = vars[ObjectIdentifier(first)] else { continue }
            var expr = attributeExpression(firstVV)(c.firstAttribute)
            if let second = c.secondItem {
                guard let secondVV = vars[ObjectIdentifier(second)] else { continue }
                let rhs = attributeExpression(secondVV)(c.secondAttribute)
                expr.add(rhs, multiplier: -Double(c.multiplier))
            }
            expr.constant -= Double(c.constant)
            let rel: Cassowary.Relation
            switch c.relation {
            case .equal: rel = .equal
            case .lessThanOrEqual: rel = .lessThanOrEqual
            case .greaterThanOrEqual: rel = .greaterThanOrEqual
            }
            let p = c.priority.rawValue
            let strength = p >= 1000 ? Cassowary.requiredStrength : Double(p)
            // UIKit "breaks a constraint" on unsatisfiable required systems;
            // dropping the late-comer approximates that.
            try? solver.addConstraint(Cassowary.Constraint(expr, rel,
                                                           strength: strength))
        }

        // Write back solved frames (constraint-based views only), rounding
        // per-view in LOCAL (superview) coordinates. Layout guides get the
        // same treatment into `layoutFrame`; a SYSTEM guide keeps the exact
        // measured rect it was anchored to (rounding it would move a pinned
        // view off the safe-area edge by up to half a point).
        for vv in ordered {
            guard let sup = vv.parent.flatMap({ vars[ObjectIdentifier($0)] }) else { continue }
            let exactX = solver.value(of: vv.left) - solver.value(of: sup.left)
            let exactY = solver.value(of: vv.top) - solver.value(of: sup.top)
            let exactW = solver.value(of: vv.width)
            let exactH = solver.value(of: vv.height)
            if let g = vv.guide {
                if g.systemFrame() == nil {
                    g._solvedFrame = CGRect(x: roundOrigin(CGFloat(exactX)),
                                            y: roundOrigin(CGFloat(exactY)),
                                            width: roundSize(CGFloat(exactW)),
                                            height: roundSize(CGFloat(exactH)))
                }
                continue
            }
            let v = vv.view!
            guard v !== root, !v.translatesAutoresizingMaskIntoConstraints else { continue }
            // A stack's ARRANGED subviews are placed by the stack, not by the
            // solver: OpenUIKit's UIStackView is a frame-based layout (see
            // UIStackView.swift) and writing a solved frame here would fight
            // it — the app's `row.leadingAnchor == stack.leadingAnchor` style
            // constraints leave the cross-axis position under-determined, so
            // the solver's answer is arbitrary. The stack still SEES the row's
            // size constraints, through `_explicitSizeConstraint`. M14.
            if let stack = v.superview as? UIStackView,
               stack.arrangedSubviews.contains(where: { $0 === v }) { continue }
            let f = CGRect(x: roundOrigin(CGFloat(exactX)),
                           y: roundOrigin(CGFloat(exactY)),
                           width: roundSize(CGFloat(exactW)),
                           height: roundSize(CGFloat(exactH)))
            if v.frame != f { v.frame = f }
        }
    }

    private static func addIntrinsic(_ solver: Cassowary.Solver,
                                     _ dim: Cassowary.Variable, _ value: Double,
                                     hugging: UILayoutPriority,
                                     compression: UILayoutPriority) {
        func strength(_ p: UILayoutPriority) -> Double {
            p.rawValue >= 1000 ? Cassowary.requiredStrength : Double(p.rawValue)
        }
        // width <= intrinsic @ hugging; width >= intrinsic @ compression.
        try? solver.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(dim, constant: -value), .lessThanOrEqual,
            strength: strength(hugging)))
        try? solver.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(dim, constant: -value), .greaterThanOrEqual,
            strength: strength(compression)))
    }

    /// Expression for a UIKit attribute in root-space variables.
    /// Leading/trailing assume LTR (no RTL support yet).
    private static func attributeExpression(
        _ vv: ViewVars
    ) -> (NSLayoutConstraint.Attribute) -> Cassowary.Expression {
        { attr in
            var e = Cassowary.Expression()
            switch attr {
            case .left, .leading:
                e.add(vv.left, 1)
            case .right, .trailing:
                e.add(vv.left, 1); e.add(vv.width, 1)
            case .top:
                e.add(vv.top, 1)
            case .bottom:
                e.add(vv.top, 1); e.add(vv.height, 1)
            case .width:
                e.add(vv.width, 1)
            case .height:
                e.add(vv.height, 1)
            case .centerX:
                e.add(vv.left, 1); e.add(vv.width, 0.5)
            case .centerY:
                e.add(vv.top, 1); e.add(vv.height, 0.5)
            case .firstBaseline:
                if let b = vv.view?._constraintBaselines() {
                    e.add(vv.top, 1); e.constant = Double(b.firstFromTop)
                } else {
                    e.add(vv.top, 1); e.add(vv.height, 1)  // plain views: bottom
                }
            case .lastBaseline:
                if let b = vv.view?._constraintBaselines() {
                    e.add(vv.top, 1); e.add(vv.height, 1)
                    e.constant = -Double(b.lastFromBottom)
                } else {
                    e.add(vv.top, 1); e.add(vv.height, 1)
                }
            // The margin attributes are the item's own layout-margins guide
            // spelled as an attribute: UIKit resolves `leftMargin` to the same
            // edge as `layoutMarginsGuide.leadingAnchor`. Margins are read as
            // a constant at solve time, exactly as intrinsic sizes and
            // baselines above are — `layoutMargins` already folds in the safe
            // area (UILayoutGuide.swift). LTR only, like leading/trailing.
            case .leftMargin, .leadingMargin:
                e.add(vv.left, 1); e.constant = Double(margins(vv).left)
            case .rightMargin, .trailingMargin:
                e.add(vv.left, 1); e.add(vv.width, 1)
                e.constant = -Double(margins(vv).right)
            case .topMargin:
                e.add(vv.top, 1); e.constant = Double(margins(vv).top)
            case .bottomMargin:
                e.add(vv.top, 1); e.add(vv.height, 1)
                e.constant = -Double(margins(vv).bottom)
            case .centerXWithinMargins:
                let m = margins(vv)
                e.add(vv.left, 1); e.add(vv.width, 0.5)
                e.constant = Double(m.left - m.right) / 2
            case .centerYWithinMargins:
                let m = margins(vv)
                e.add(vv.top, 1); e.add(vv.height, 0.5)
                e.constant = Double(m.top - m.bottom) / 2
            case .notAnAttribute:
                break
            }
            return e
        }
    }

    /// Layout margins of the constrained item. A layout guide has none of its
    /// own — UIKit's margin attributes are declared on views — so a guide
    /// contributes zero and the attribute degenerates to its plain edge.
    private static func margins(_ vv: ViewVars) -> UIEdgeInsets {
        vv.view?.layoutMargins ?? .zero
    }

    // MARK: - Oracle-fitted rounding (docs/SCENE_SPEC.md, Constraints v4.3)

    /// Frame ORIGIN components: nearest integer point, ties away from zero
    /// (47.5 -> 48, 113.333 -> 113, 214.667 -> 215) — NOT the pixel grid.
    static func roundOrigin(_ v: CGFloat) -> CGFloat {
        v.rounded(.toNearestOrAwayFromZero)
    }

    /// Frame SIZE components: nearest 0.5 pt (pixel at 2x), ties away from
    /// zero (93.333 -> 93.5, 190.667 -> 190.5; an on-grid 0.5 survives).
    static func roundSize(_ v: CGFloat) -> CGFloat {
        (v * 2).rounded(.toNearestOrAwayFromZero) / 2
    }
}
