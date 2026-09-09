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
    /// Print the intrinsic entry order per solve (tie-break debugging).
    static var trace = false

    // MARK: - Fitting solves (systemLayoutSizeFitting)

    /// A fitting solve runs the engine BACKWARDS: instead of pinning the
    /// root's size and solving for its subviews, it pins the target axes and
    /// leaves the others free, so the root's own size becomes the answer. That
    /// is what `systemLayoutSizeFitting` asks for, and it is the only way a
    /// view whose height is decided by its content ever gets a height — a
    /// self-sizing table row, or pocket-casts' SettingsTableHeader, whose
    /// height is `max(38, its label's wrapped height)` and appears nowhere
    /// else (measured: golden realapp_storage_light headers are 38 pt tall
    /// with the delegate supplying no height at all).
    struct FittingRequest {
        var target: CGSize
        var freeWidth: Bool
        var freeHeight: Bool
        /// Written by `solve`.
        var solved = CGSize.zero
    }
    private static var fitting: FittingRequest?

    /// Solve `root`'s subtree for `root`'s own size. Returns nil when the
    /// subtree installs no constraints, so the caller can fall back to the
    /// subview-extent estimate.
    static func fittingSize(root: UIView, target: CGSize,
                            freeWidth: Bool, freeHeight: Bool) -> CGSize? {
        guard installedConstraintCount > 0 else { return nil }
        var constraints: [NSLayoutConstraint] = []
        collectConstraints(root, into: &constraints)
        guard !constraints.isEmpty else { return nil }
        var request = FittingRequest(target: target, freeWidth: freeWidth,
                                     freeHeight: freeHeight)
        fitting = request
        solve(root: root, constraints: constraints)
        request.solved = fitting?.solved ?? .zero
        fitting = nil
        return request.solved
    }

    /// Priority of the pull that collapses a free axis. UIKit's own
    /// `fittingSizeLevel`, so any real constraint on the axis outranks it.
    private static let fittingPull = Double(UILayoutPriority.fittingSizeLevel.rawValue)

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
        /// Constraint-based views in ENTRY order (first reference by a
        /// constraint), for the intrinsic-size pass below.
        var intrinsicViews: [ViewVars] = []
        /// The root's variables, for reading a fitting solve's answer back.
        var rootVars: ViewVars?

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
                guard let owner = g.owningView,
                      let ov = vars[ObjectIdentifier(owner)],
                      let ins = systemGuideInsets(g) else { continue }
                // The guide is FOUR EDGE RELATIONS to its owner, not a frozen
                // rect: `guide.bottom = owner.bottom - inset.bottom` must hold
                // for whatever size the solver gives the owner. Pinning the
                // guide to the owner's CURRENT bounds (the previous model)
                // froze a zero-height guide for a constraint-sized owner that
                // had never been laid out, so an app's
                // `sub.top = owner.top; sub.height = 44;
                //  sub.bottom = owner.safeAreaLayoutGuide.bottom` was
                // unsatisfiable, the height dropped and the owner stretched.
                // MEASURED probe_toolbar_guide_bottom{0,34} (iPhone SE 3rd
                // gen 2x / iOS 26.1, forced safe area [20,0,B,0]): the owner
                // is [0,623,375,44] at B=0 and [0,589,375,78] at B=34 — its
                // height is 44 + B — where the frozen model gave
                // [0,0,375,667]. Same rule in Focus' HomeViewToolbar:
                // golden realapp_focus_browser_light has it at [0,603,375,44]
                // (parent-relative) against our [0,122,375,525].
                var ex = Cassowary.Expression(vv.left, constant: -Double(ins.left))
                ex.add(ov.left, -1)
                addRequired(ex, .equal)
                var ey = Cassowary.Expression(vv.top, constant: -Double(ins.top))
                ey.add(ov.top, -1)
                addRequired(ey, .equal)
                var ew = Cassowary.Expression(vv.width,
                                              constant: Double(ins.left + ins.right))
                ew.add(ov.width, -1)
                addRequired(ew, .equal)
                var eh = Cassowary.Expression(vv.height,
                                              constant: Double(ins.top + ins.bottom))
                eh.add(ov.height, -1)
                addRequired(eh, .equal)
                continue
            }
            let v = vv.view!
            // A stack's ARRANGED subview is placed and sized by the stack
            // (UIKit does it with required constraints of its own; OpenUIKit's
            // stack is frame-based), so it enters the solver as a FIXED frame
            // like any frame-based view. MEASURED 2026-09-04
            // (layoutprobe "approw_in_stack_*"): with the row's width left
            // free, both labels could hug by shrinking the row and the
            // tie-break never arose; real UIKit stretches "Download".
            let arrangedByStack = (v.superview as? UIStackView)?
                .arrangedSubviews.contains(where: { $0 === v }) ?? false
            if v === root || v.translatesAutoresizingMaskIntoConstraints || arrangedByStack {
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
                    // A fitting solve pins the root's size only on the axes
                    // the caller fixed; a free axis gets the target as a
                    // ceiling and a weak pull to zero, so it collapses onto
                    // whatever the content requires.
                    if let f = fitting, v === root {
                        rootVars = vv
                        if f.freeWidth {
                            addRequired(Cassowary.Expression(vv.width), .greaterThanOrEqual)
                            try? solver.addConstraint(Cassowary.Constraint(
                                Cassowary.Expression(vv.width), .equal,
                                strength: fittingPull))
                        } else {
                            addRequired(Cassowary.Expression(vv.width,
                                                             constant: -Double(f.target.width)),
                                        .equal)
                        }
                        if f.freeHeight {
                            addRequired(Cassowary.Expression(vv.height), .greaterThanOrEqual)
                            try? solver.addConstraint(Cassowary.Constraint(
                                Cassowary.Expression(vv.height), .equal,
                                strength: fittingPull))
                        } else {
                            addRequired(Cassowary.Expression(vv.height,
                                                             constant: -Double(f.target.height)),
                                        .equal)
                        }
                        continue
                    }
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
                // and compression-resistance (>=) priorities per axis —
                // added AFTER the user constraints, see below.
                intrinsicViews.append(vv)
            }
        }

        // Intrinsic content sizes — their ORDER is the tie-break. When two
        // views' hugging (or compression) constraints have equal priority
        // and cannot both hold, the LP has many optimal vertices and which
        // one the solver reaches is decided by insertion order and pivoting.
        // Real UIKit's outcomes, MEASURED 2026-09-04 with
        // Tools/oracle2/layoutprobe on iOS 26.1 (20 scenarios,
        // golden/layout_tiebreak_ios.json, Tests/…/LayoutTieBreakTests), are
        // reproduced by: intrinsic constraints in ENTRY order (first
        // reference by a constraint) BEFORE the user constraints — the view
        // referenced first takes the space in a tie ("Download" stretches
        // beside "Wi-Fi only"; in a compression tie it keeps its width) — and
        // then, after the user constraints, a wrapping label (numberOfLines
        // != 1) has its intrinsic constraints removed and re-added in entry
        // order (UIKit's preferredMaxLayoutWidth second pass): a constraint
        // added into a tie stays violated, which is why the app's own row
        // (both labels numberOfLines 0) hugs "Download" and stretches
        // "Wi-Fi only".
        var intrinsicConstraints: [ObjectIdentifier: [Cassowary.Constraint]] = [:]
        func addIntrinsics(_ vv: ViewVars, wrapAt width: CGFloat? = nil) {
            let v = vv.view!
            // A wrapping label's `intrinsicContentSize` is its ONE-LINE size:
            // nothing has told it how wide it will be. In the second pass the
            // solver has, so re-measure at the width it solved — UIKit's
            // `preferredMaxLayoutWidth`. MEASURED (realapp_storage_light,
            // iPhone 16 / iOS 26.1): the usage footer's label is 46.667 pt
            // (three wrapped lines at 361 pt) and the footer 70.667; with the
            // one-line intrinsic they came out 15.667 and 39.667.
            let s = width.map {
                v.sizeThatFits(CGSize(width: $0, height: CGFloat.greatestFiniteMagnitude))
            } ?? v.intrinsicContentSize
            var cs: [Cassowary.Constraint] = []
            if s.width != UIView.noIntrinsicMetric {
                cs += addIntrinsic(solver, vv.width, Double(s.width),
                                   hugging: v.contentHuggingPriority(for: .horizontal),
                                   compression: v.contentCompressionResistancePriority(for: .horizontal))
            }
            if s.height != UIView.noIntrinsicMetric {
                cs += addIntrinsic(solver, vv.height, Double(s.height),
                                   hugging: v.contentHuggingPriority(for: .vertical),
                                   compression: v.contentCompressionResistancePriority(for: .vertical))
            }
            intrinsicConstraints[ObjectIdentifier(v)] = cs
        }
        for vv in intrinsicViews { addIntrinsics(vv) }
        if LayoutEngine.trace {
            print("LayoutEngine.solve root=\(type(of: root)) entry order: " +
                  intrinsicViews.map { "\(type(of: $0.view!))#\(($0.view as? UILabel)?.text ?? "")" }.joined(separator: ", "))
        }

        // Scene/user constraints.
        for c in constraints {
            guard let first = c.firstItem,
                  let firstVV = vars[ObjectIdentifier(first)] else { continue }
            var expr = attributeExpression(firstVV)(c.firstAttribute)
            var constant = Double(c.constant)
            var flipAxis = false
            if let second = c.secondItem {
                guard let secondVV = vars[ObjectIdentifier(second)] else { continue }
                let rhs = attributeExpression(secondVV)(c.secondAttribute)
                expr.add(rhs, multiplier: -Double(c.multiplier))
                // MEASURED NavFlow t3900.rtl, iPhone SE 2x / iOS 26.1:
                // `switchLabel.leading = card.leading + 16` puts "Allow
                // Notifications" at abs.x 201.5 (16 pt inward from the
                // card's right). Forms t200.rtl: `label.trailing <=
                // control.leading - 8` is still a MINIMUM 8 pt gap after
                // the axis reverse (Enabled stays 61.5 wide at x 297.5,
                // not stretched). Negate the constant and swap ≤/≥.
                if (isLogicalHorizontal(c.firstAttribute) && isRTL(firstVV))
                    || (isLogicalHorizontal(c.secondAttribute) && isRTL(secondVV)) {
                    flipAxis = true
                }
            } else if isLogicalHorizontal(c.firstAttribute) && isRTL(firstVV) {
                flipAxis = true
            }
            if flipAxis { constant = -constant }
            expr.constant -= constant
            var rel: Cassowary.Relation
            switch c.relation {
            case .equal: rel = .equal
            case .lessThanOrEqual: rel = .lessThanOrEqual
            case .greaterThanOrEqual: rel = .greaterThanOrEqual
            }
            if flipAxis {
                switch rel {
                case .lessThanOrEqual: rel = .greaterThanOrEqual
                case .greaterThanOrEqual: rel = .lessThanOrEqual
                case .equal: break
                default: break
                }
            }
            let p = c.priority.rawValue
            let strength = p >= 1000 ? Cassowary.requiredStrength : Double(p)
            // UIKit "breaks a constraint" on unsatisfiable required systems;
            // dropping the late-comer approximates that.
            try? solver.addConstraint(Cassowary.Constraint(expr, rel,
                                                           strength: strength))
        }

        // Wrapping labels: second pass (see the intrinsic note above).
        for vv in intrinsicViews {
            guard let l = vv.view as? UILabel, l.numberOfLines != 1 else { continue }
            for c in intrinsicConstraints[ObjectIdentifier(l)] ?? [] { try? solver.removeConstraint(c) }
            // Fitting solves always re-measure at the solved width. Ordinary
            // solves keep the one-line intrinsic on Catalyst and for
            // numberOfLines == 0 (the tie-break goldens). On the iOS cut a
            // CAPPED wrapping label (numberOfLines > 1) re-measures too:
            // Feed t200, iPhone SE 2x / iOS 26.1, a 2-line subheadline body
            // pinned leading/trailing in a 343 pt card is abs.h 38, not
            // the one-line 18. The remaining 38 vs a 15 pt system font's
            // 36 is preferred-font leading (FontEngine.labelBlockHeight).
            let wrapWidth: CGFloat?
            if fitting != nil {
                wrapWidth = CGFloat(solver.value(of: vv.width))
            } else if OpenUIKitRuntime.systemFontCut == .iOS, l.numberOfLines > 1 {
                wrapWidth = CGFloat(solver.value(of: vv.width))
            } else {
                wrapWidth = nil
            }
            addIntrinsics(vv, wrapAt: wrapWidth)
        }


        // A fitting solve answers with the root's own size and writes no
        // frames: the caller is measuring, not laying out, and the hierarchy
        // it measured is usually about to be laid out at a different size.
        if fitting != nil, let rootVars {
            // UNROUNDED, unlike a written-back frame: `roundSize`'s half-point
            // grid is the measured rule for a constraint-positioned view's
            // SIZE, and a fitting answer is not one — it is a number the
            // caller is about to add to others. MEASURED
            // (realapp_storage_light): the usage footer wants 70.667 pt, and
            // rounding it to 71 pushed the two views below it 0.333 pt down.
            fitting?.solved = CGSize(
                width: CGFloat(solver.value(of: rootVars.width)),
                height: CGFloat(solver.value(of: rootVars.height)))
            return
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

    /// How far a SYSTEM guide sits inside each edge of its owning view, from
    /// the measured rules in AutoLayout/UILayoutGuide.swift. The solver pins
    /// the guide to the owner's edge VARIABLES by these insets, so the guide
    /// follows a size the solve itself decides. `nil` for a custom guide (it
    /// is free) and for `contentLayoutGuide` (origin-only, handled inline).
    private static func systemGuideInsets(_ g: UILayoutGuide) -> UIEdgeInsets? {
        guard let v = g.owningView else { return nil }
        switch g.kind {
        case .custom, .scrollContent:
            return nil
        case .safeArea:
            return v.safeAreaInsets
        case .layoutMargins:
            return v.layoutMargins
        case .readableContent where g.systemFrame() == v.bounds.inset(by: v.layoutMargins):
            // Below the 920 pt cap the readable guide IS the margins guide.
            return v.layoutMargins
        case .scrollFrame, .readableContent:
            // `frameLayoutGuide` is the scroll view's bounds in CONTENT space
            // (origin = content offset); the readable band, once its width
            // cap engages, is centred on the CURRENT bounds. Both are the
            // bounds-derived rect expressed as insets of that same bounds
            // rect, which is exactly the previous frozen anchoring for these
            // two kinds.
            guard let f = g.systemFrame() else { return nil }
            let b = v.bounds
            return UIEdgeInsets(top: f.minY - b.minY, left: f.minX - b.minX,
                                bottom: b.maxY - f.maxY, right: b.maxX - f.maxX)
        }
    }

    /// Adds the two intrinsic-size constraints of one axis and returns them
    /// (the wrapping-label pass removes and re-adds them).
    @discardableResult
    private static func addIntrinsic(_ solver: Cassowary.Solver,
                                     _ dim: Cassowary.Variable, _ value: Double,
                                     hugging: UILayoutPriority,
                                     compression: UILayoutPriority) -> [Cassowary.Constraint] {
        func strength(_ p: UILayoutPriority) -> Double {
            p.rawValue >= 1000 ? Cassowary.requiredStrength : Double(p.rawValue)
        }
        // width <= intrinsic @ hugging; width >= intrinsic @ compression.
        let hug = Cassowary.Constraint(
            Cassowary.Expression(dim, constant: -value), .lessThanOrEqual,
            strength: strength(hugging))
        let resist = Cassowary.Constraint(
            Cassowary.Expression(dim, constant: -value), .greaterThanOrEqual,
            strength: strength(compression))
        try? solver.addConstraint(hug)
        try? solver.addConstraint(resist)
        return [hug, resist]
    }

    /// Expression for a UIKit attribute in root-space variables.
    /// `.left` / `.right` stay physical. `.leading` / `.trailing` follow
    /// the item's `effectiveUserInterfaceLayoutDirection`.
    private static func attributeExpression(
        _ vv: ViewVars
    ) -> (NSLayoutConstraint.Attribute) -> Cassowary.Expression {
        { attr in
            var e = Cassowary.Expression()
            switch attr {
            case .left:
                e.add(vv.left, 1)
            case .right:
                e.add(vv.left, 1); e.add(vv.width, 1)
            // MEASURED Forms t200.rtl + NavFlow t3900.rtl, iPhone SE 2x /
            // iOS 26.1: appearance-RTL `label.leading = guide.leading`
            // (constant 0) puts Enabled at abs.x 297.5 (physical right);
            // `switch.trailing = guide.trailing` puts the switch at x=16.
            // The constant is not flipped — leading is the right edge,
            // trailing is the left edge. Unspecified still resolves LTR.
            case .leading:
                if isRTL(vv) {
                    e.add(vv.left, 1); e.add(vv.width, 1)
                } else {
                    e.add(vv.left, 1)
                }
            case .trailing:
                if isRTL(vv) {
                    e.add(vv.left, 1)
                } else {
                    e.add(vv.left, 1); e.add(vv.width, 1)
                }
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
            // spelled as an attribute. `leftMargin` / `rightMargin` stay
            // physical; `.leadingMargin` / `.trailingMargin` follow the
            // item direction (same samples as `.leading` / `.trailing`).
            case .leftMargin:
                e.add(vv.left, 1); e.constant = Double(margins(vv).left)
            case .rightMargin:
                e.add(vv.left, 1); e.add(vv.width, 1)
                e.constant = -Double(margins(vv).right)
            case .leadingMargin:
                if isRTL(vv) {
                    e.add(vv.left, 1); e.add(vv.width, 1)
                    e.constant = -Double(margins(vv).right)
                } else {
                    e.add(vv.left, 1); e.constant = Double(margins(vv).left)
                }
            case .trailingMargin:
                if isRTL(vv) {
                    e.add(vv.left, 1); e.constant = Double(margins(vv).left)
                } else {
                    e.add(vv.left, 1); e.add(vv.width, 1)
                    e.constant = -Double(margins(vv).right)
                }
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

    /// Direction of the constrained item. A layout guide follows its
    /// owning view (Forms `contentView.layoutMarginsGuide.leading` with the
    /// appearance stamp on contentView).
    private static func isRTL(_ vv: ViewVars) -> Bool {
        (vv.view ?? vv.guide?.owningView)?._layoutIsRTL == true
    }

    private static func isLogicalHorizontal(_ attr: NSLayoutConstraint.Attribute) -> Bool {
        switch attr {
        case .leading, .trailing, .leadingMargin, .trailingMargin: return true
        default: return false
        }
    }

    // MARK: - Oracle-fitted rounding (docs/SCENE_SPEC.md, Constraints v4.3)

    /// Frame ORIGIN components: nearest integer point, ties away from zero
    /// (47.5 -> 48, 113.333 -> 113, 214.667 -> 215) — NOT the pixel grid.
    static func roundOrigin(_ v: CGFloat) -> CGFloat {
        if let s = iOSPixelScale { return (v * s).rounded(.toNearestOrAwayFromZero) / s }
        return v.rounded(.toNearestOrAwayFromZero)
    }

    /// iOS cut, MEASURED 2026-09-04 (realappprobe, iPhone 16 3x, iOS 26.1):
    /// origins and sizes both land on the PIXEL grid — a label centred in a
    /// 72 pt row sits at y 25.333 ((72 - 21.667) / 2 = 25.167 -> 25.333) and
    /// a trailing label starts at x 127.667 — where Catalyst rounds origins
    /// to whole points. nil selects the Catalyst rules below.
    static var iOSPixelScale: CGFloat? {
        OpenUIKitRuntime.systemFontCut == .iOS ? max(1, UIScreen.main.scale) : nil
    }

    /// Frame SIZE components: nearest 0.5 pt (pixel at 2x), ties away from
    /// zero (93.333 -> 93.5, 190.667 -> 190.5; an on-grid 0.5 survives).
    static func roundSize(_ v: CGFloat) -> CGFloat {
        if let s = iOSPixelScale { return (v * s).rounded(.toNearestOrAwayFromZero) / s }
        return (v * 2).rounded(.toNearestOrAwayFromZero) / 2
    }
}
