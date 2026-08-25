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

    private final class ViewVars {
        let view: UIView
        let left: Cassowary.Variable
        let top: Cassowary.Variable
        let width: Cassowary.Variable
        let height: Cassowary.Variable
        init(_ view: UIView) {
            self.view = view
            left = Cassowary.Variable("L")
            top = Cassowary.Variable("T")
            width = Cassowary.Variable("W")
            height = Cassowary.Variable("H")
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

        involve(root)
        for c in constraints {
            if let f = c.firstItem { involve(f) }
            if let s = c.secondItem { involve(s) }
        }

        let solver = Cassowary.Solver()

        func addRequired(_ expr: Cassowary.Expression, _ rel: Cassowary.Relation) {
            try? solver.addConstraint(Cassowary.Constraint(expr, rel))
        }

        // Anchoring constraints per involved view.
        for vv in ordered {
            let v = vv.view
            if v === root || v.translatesAutoresizingMaskIntoConstraints {
                // Frame-based: required left/top/width/height from the
                // current frame (relative to the superview's variables when
                // involved; the root anchors at its bounds space's origin).
                let f = v.frame
                let sup = v.superview.flatMap { vars[ObjectIdentifier($0)] }
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
        // per-view in LOCAL (superview) coordinates.
        for vv in ordered {
            let v = vv.view
            guard v !== root, !v.translatesAutoresizingMaskIntoConstraints else { continue }
            guard let sup = v.superview.flatMap({ vars[ObjectIdentifier($0)] }) else { continue }
            let exactX = solver.value(of: vv.left) - solver.value(of: sup.left)
            let exactY = solver.value(of: vv.top) - solver.value(of: sup.top)
            let exactW = solver.value(of: vv.width)
            let exactH = solver.value(of: vv.height)
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
                if let b = vv.view._constraintBaselines() {
                    e.add(vv.top, 1); e.constant = Double(b.firstFromTop)
                } else {
                    e.add(vv.top, 1); e.add(vv.height, 1)  // plain views: bottom
                }
            case .lastBaseline:
                if let b = vv.view._constraintBaselines() {
                    e.add(vv.top, 1); e.add(vv.height, 1)
                    e.constant = -Double(b.lastFromBottom)
                } else {
                    e.add(vv.top, 1); e.add(vv.height, 1)
                }
            case .notAnAttribute:
                break
            }
            return e
        }
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
