// Auto Layout (M9) tests. Owner: autolayout module.
// Solver simplex edge cases + NSLayoutConstraint/anchor API + the
// oracle-fitted rounding quirks (docs/SCENE_SPEC.md "Constraints (v4.3)").

import XCTest
@testable import OpenUIKit

@MainActor
final class CassowarySolverTests: XCTestCase {

    private func eq(_ e: Cassowary.Expression, _ strength: Double = Cassowary.requiredStrength)
        -> Cassowary.Constraint { Cassowary.Constraint(e, .equal, strength: strength) }

    func testSimpleChain() throws {
        // x = 10; y = x + 5; z = 2y  ->  z = 30
        let s = Cassowary.Solver()
        let x = Cassowary.Variable("x")
        let y = Cassowary.Variable("y")
        let z = Cassowary.Variable("z")
        try s.addConstraint(eq(Cassowary.Expression(x, constant: -10)))
        var e2 = Cassowary.Expression(y)
        e2.add(x, -1); e2.constant = -5
        try s.addConstraint(eq(e2))
        var e3 = Cassowary.Expression(z)
        e3.add(y, -2)
        try s.addConstraint(eq(e3))
        XCTAssertEqual(s.value(of: x), 10, accuracy: 1e-9)
        XCTAssertEqual(s.value(of: y), 15, accuracy: 1e-9)
        XCTAssertEqual(s.value(of: z), 30, accuracy: 1e-9)
    }

    func testConflictingOptionalConstraintsResolveByPriority() throws {
        // w = 60 @750 vs w = 140 @749: the 750 wins outright (winner-take-all
        // at the LP vertex, not a weighted average).
        let s = Cassowary.Solver()
        let w = Cassowary.Variable("w")
        try s.addConstraint(eq(Cassowary.Expression(w, constant: -60), 750))
        try s.addConstraint(eq(Cassowary.Expression(w, constant: -140), 749))
        XCTAssertEqual(s.value(of: w), 60, accuracy: 1e-9)
    }

    func testRequiredBeatsHighOptional() throws {
        // w = 30 @999 vs w >= 90 required -> w = 90 (constraints_inequalities).
        let s = Cassowary.Solver()
        let w = Cassowary.Variable("w")
        try s.addConstraint(eq(Cassowary.Expression(w, constant: -30), 999))
        try s.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(w, constant: -90), .greaterThanOrEqual))
        XCTAssertEqual(s.value(of: w), 90, accuracy: 1e-9)
    }

    func testInequalityActivation() throws {
        // 80 <= w <= 200 required, w = 300 @500: the upper bound activates.
        let s = Cassowary.Solver()
        let w = Cassowary.Variable("w")
        try s.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(w, constant: -80), .greaterThanOrEqual))
        try s.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(w, constant: -200), .lessThanOrEqual))
        try s.addConstraint(eq(Cassowary.Expression(w, constant: -300), 500))
        XCTAssertEqual(s.value(of: w), 200, accuracy: 1e-9)
        // Pull the optional target below both bounds: lower bound activates.
        let s2 = Cassowary.Solver()
        let w2 = Cassowary.Variable("w")
        try s2.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(w2, constant: -80), .greaterThanOrEqual))
        try s2.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(w2, constant: -200), .lessThanOrEqual))
        try s2.addConstraint(eq(Cassowary.Expression(w2, constant: -10), 500))
        XCTAssertEqual(s2.value(of: w2), 80, accuracy: 1e-9)
    }

    func testInactiveInequalityDoesNotPin() throws {
        // w >= 10 with w = 50 @250: inequality is slack, optional holds.
        let s = Cassowary.Solver()
        let w = Cassowary.Variable("w")
        try s.addConstraint(Cassowary.Constraint(
            Cassowary.Expression(w, constant: -10), .greaterThanOrEqual))
        try s.addConstraint(eq(Cassowary.Expression(w, constant: -50), 250))
        XCTAssertEqual(s.value(of: w), 50, accuracy: 1e-9)
    }

    func testUnsatisfiableRequiredThrows() throws {
        let s = Cassowary.Solver()
        let x = Cassowary.Variable("x")
        try s.addConstraint(eq(Cassowary.Expression(x, constant: -10)))
        XCTAssertThrowsError(try s.addConstraint(eq(Cassowary.Expression(x, constant: -20))))
        // Solver stays usable and keeps the original solution.
        XCTAssertEqual(s.value(of: x), 10, accuracy: 1e-9)
    }

    func testRemovalAndReAdd() throws {
        let s = Cassowary.Solver()
        let x = Cassowary.Variable("x")
        let pin10 = eq(Cassowary.Expression(x, constant: -10))
        let prefer99 = eq(Cassowary.Expression(x, constant: -99), 300)
        try s.addConstraint(prefer99)
        try s.addConstraint(pin10)
        XCTAssertEqual(s.value(of: x), 10, accuracy: 1e-9)
        try s.removeConstraint(pin10)
        XCTAssertEqual(s.value(of: x), 99, accuracy: 1e-9)
        try s.addConstraint(pin10)   // re-add after removal
        XCTAssertEqual(s.value(of: x), 10, accuracy: 1e-9)
        try s.removeConstraint(pin10)
        try s.removeConstraint(prefer99)
        XCTAssertThrowsError(try s.removeConstraint(pin10)) // unknown now
        XCTAssertEqual(s.constraintCount, 0)
    }

    func testRemoveInequalityReactivatesOptional() throws {
        let s = Cassowary.Solver()
        let w = Cassowary.Variable("w")
        let cap = Cassowary.Constraint(
            Cassowary.Expression(w, constant: -40), .lessThanOrEqual)
        try s.addConstraint(eq(Cassowary.Expression(w, constant: -70), 500))
        try s.addConstraint(cap)
        XCTAssertEqual(s.value(of: w), 40, accuracy: 1e-9)
        try s.removeConstraint(cap)
        XCTAssertEqual(s.value(of: w), 70, accuracy: 1e-9)
    }

    func testNegativeValues() throws {
        // Variables are unrestricted (frame coordinates can go negative).
        let s = Cassowary.Solver()
        let x = Cassowary.Variable("x")
        let y = Cassowary.Variable("y")
        try s.addConstraint(eq(Cassowary.Expression(x, constant: 25)))  // x = -25
        var e = Cassowary.Expression(y)
        e.add(x, -1); e.constant = -5                                    // y = x + 5
        try s.addConstraint(eq(e))
        XCTAssertEqual(s.value(of: x), -25, accuracy: 1e-9)
        XCTAssertEqual(s.value(of: y), -20, accuracy: 1e-9)
    }

    func testEqualDistributionChain() throws {
        // Three equal widths in 280 -> exactly 93.3333... each.
        let s = Cassowary.Solver()
        let a = Cassowary.Variable("a")
        let b = Cassowary.Variable("b")
        let c = Cassowary.Variable("c")
        var sum = Cassowary.Expression(a)
        sum.add(b, 1); sum.add(c, 1); sum.constant = -280
        try s.addConstraint(eq(sum))
        var ab = Cassowary.Expression(a); ab.add(b, -1)
        try s.addConstraint(eq(ab))
        var bc = Cassowary.Expression(b); bc.add(c, -1)
        try s.addConstraint(eq(bc))
        XCTAssertEqual(s.value(of: a), 280.0 / 3, accuracy: 1e-9)
        XCTAssertEqual(s.value(of: c), 280.0 / 3, accuracy: 1e-9)
    }
}

@MainActor
final class AutoLayoutEngineTests: XCTestCase {

    func testOriginAndSizeRounding() {
        // Oracle quirks: origins -> nearest integer point, ties away from
        // zero; sizes -> nearest 0.5 pt, ties away from zero.
        XCTAssertEqual(LayoutEngine.roundOrigin(47.5), 48)
        XCTAssertEqual(LayoutEngine.roundOrigin(117.5), 118)
        XCTAssertEqual(LayoutEngine.roundOrigin(219.5), 220)
        XCTAssertEqual(LayoutEngine.roundOrigin(113.333), 113)
        XCTAssertEqual(LayoutEngine.roundOrigin(214.667), 215)
        XCTAssertEqual(LayoutEngine.roundOrigin(-2.5), -3)
        XCTAssertEqual(LayoutEngine.roundSize(93.0 + 1.0 / 3), 93.5)
        XCTAssertEqual(LayoutEngine.roundSize(190.0 + 2.0 / 3), 190.5)
        XCTAssertEqual(LayoutEngine.roundSize(106.656), 106.5)
        XCTAssertEqual(LayoutEngine.roundSize(0.5), 0.5)   // on-grid survives
        XCTAssertEqual(LayoutEngine.roundSize(93.25), 93.5) // tie away
    }

    func testAnchorsAndActivation() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(child)
        let cs = [
            child.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            child.topAnchor.constraint(equalTo: root.topAnchor, constant: 20),
            child.widthAnchor.constraint(equalTo: root.widthAnchor, multiplier: 0.5),
            child.heightAnchor.constraint(equalToConstant: 44),
        ]
        NSLayoutConstraint.activate(cs)
        // Binary constraints install on the common ancestor, unary on the item.
        XCTAssertEqual(root.constraints.count, 3)
        XCTAssertEqual(child.constraints.count, 1)
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame, CGRect(x: 16, y: 20, width: 160, height: 44))
        // Deactivation removes the install and stops solving the view.
        NSLayoutConstraint.deactivate(cs)
        XCTAssertEqual(root.constraints.count, 0)
        XCTAssertEqual(child.constraints.count, 0)
    }

    func testConstantChangeAndResolve() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(child)
        let lead = child.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 10)
        NSLayoutConstraint.activate([
            lead,
            child.topAnchor.constraint(equalTo: root.topAnchor),
            child.widthAnchor.constraint(equalToConstant: 30),
            child.heightAnchor.constraint(equalToConstant: 30),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame.origin.x, 10)
        lead.constant = 25
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame.origin.x, 25)
        // Re-solving without changes is idempotent.
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame, CGRect(x: 25, y: 0, width: 30, height: 30))
    }

    func testFrameBasedParentKeepsExactLocalFrame() {
        // constraints_mixed_frames probe: constraint child of a frame-based
        // parent at x = 199.5 keeps its exact LOCAL frame (rounding is
        // per-view in local coordinates, not window space).
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 240))
        let parent = UIView(frame: CGRect(x: 199.5, y: 20, width: 80, height: 80))
        root.addSubview(parent)
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        parent.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 10),
            child.topAnchor.constraint(equalTo: parent.topAnchor, constant: 10),
            child.widthAnchor.constraint(equalToConstant: 25),
            child.heightAnchor.constraint(equalToConstant: 25),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(parent.frame.origin.x, 199.5)  // frame views never move
        XCTAssertEqual(child.frame, CGRect(x: 10, y: 10, width: 25, height: 25))
    }

    func testIntrinsicSizeHuggingCompressionDefaults() {
        // A label with no size constraints sizes to its intrinsic content
        // size (hugging <= meets compression >=).
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 320, height: 100))
        let label = UILabel()
        label.text = "Hello UIKit"
        label.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(label)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 12),
            label.topAnchor.constraint(equalTo: root.topAnchor, constant: 10),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(label.frame.size, label.intrinsicContentSize)
        XCTAssertEqual(label.frame.origin, CGPoint(x: 12, y: 10))
        // UIKit defaults: 250/750, labels 251 vertical hugging.
        XCTAssertEqual(label.contentHuggingPriority(for: .horizontal).rawValue, 250)
        XCTAssertEqual(label.contentHuggingPriority(for: .vertical).rawValue, 251)
        XCTAssertEqual(label.contentCompressionResistancePriority(for: .horizontal).rawValue, 750)
        XCTAssertEqual(UIView().contentHuggingPriority(for: .vertical).rawValue, 250)
    }

    func testCompressionSqueeze() {
        // Required space forces the weaker (749) label to compress while the
        // 750 label keeps its intrinsic width — constraints_compression row 1.
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
        let a = UILabel(); a.text = "left label text"
        let b = UILabel(); b.text = "right label text"
        a.translatesAutoresizingMaskIntoConstraints = false
        b.translatesAutoresizingMaskIntoConstraints = false
        b.setContentCompressionResistancePriority(UILayoutPriority(rawValue: 749),
                                                  for: .horizontal)
        root.addSubview(a)
        root.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            b.leadingAnchor.constraint(equalTo: a.trailingAnchor, constant: 8),
            b.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            a.topAnchor.constraint(equalTo: root.topAnchor),
            b.topAnchor.constraint(equalTo: root.topAnchor),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(a.frame.width, a.intrinsicContentSize.width)   // 750 holds
        XCTAssertEqual(b.frame.width,
                       LayoutEngine.roundSize(200 - 8 - a.intrinsicContentSize.width))
        XCTAssertLessThan(b.frame.width, b.intrinsicContentSize.width) // 749 gives
    }

    func testDeactivateRestoresPlainLayout() {
        // With every constraint gone the solver never runs; frames stay
        // wherever the last solve put them and setting frames works again.
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 100, height: 100))
        let child = UIView()
        child.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(child)
        let cs = [
            child.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 5),
            child.topAnchor.constraint(equalTo: root.topAnchor, constant: 5),
            child.widthAnchor.constraint(equalToConstant: 10),
            child.heightAnchor.constraint(equalToConstant: 10),
        ]
        NSLayoutConstraint.activate(cs)
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame, CGRect(x: 5, y: 5, width: 10, height: 10))
        NSLayoutConstraint.deactivate(cs)
        child.frame = CGRect(x: 1, y: 2, width: 3, height: 4)
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame, CGRect(x: 1, y: 2, width: 3, height: 4))
    }

    func testLeadingTrailingFollowItemLayoutDirection() {
        // MEASURED Forms t200.rtl (Enabled abs.x 297.5, switch x=16) and
        // NavFlow t3900.rtl (switch abs.x 32 vs LTR 282), iPhone SE 2x /
        // iOS 26.1. `leading = leading + 16` in RTL pins the child's
        // right edge 16 pt from the parent's right. Unspecified (the
        // test above) still resolves LTR.
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        root.semanticContentAttribute = .forceRightToLeft
        let child = UIView()
        child.semanticContentAttribute = .forceRightToLeft
        child.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(child)
        NSLayoutConstraint.activate([
            child.leadingAnchor.constraint(equalTo: root.leadingAnchor, constant: 16),
            child.topAnchor.constraint(equalTo: root.topAnchor, constant: 8),
            child.widthAnchor.constraint(equalToConstant: 40),
            child.heightAnchor.constraint(equalToConstant: 20),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame, CGRect(x: 144, y: 8, width: 40, height: 20))
    }

    func testTrailingControlPinsToPhysicalLeftInRTL() {
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 200, height: 100))
        root.semanticContentAttribute = .forceRightToLeft
        let child = UIView()
        child.semanticContentAttribute = .forceRightToLeft
        child.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(child)
        NSLayoutConstraint.activate([
            child.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            child.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            child.widthAnchor.constraint(equalToConstant: 51),
            child.heightAnchor.constraint(equalToConstant: 31),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(child.frame.origin.x, 0)
        XCTAssertEqual(child.frame.width, 51)
    }

    func testRTLMinGapKeepsIntrinsicWidthOnLeadingSide() {
        // MEASURED Forms t200.rtl, iPhone SE 2x / iOS 26.1: Enabled
        // `[297.5, …, 61.5, …]` — hugging the leading (right) edge, not
        // stretched across the cell by the trailing≤leading−8 spacer.
        let root = UIView(frame: CGRect(x: 0, y: 0, width: 343, height: 44))
        root.semanticContentAttribute = .forceRightToLeft
        let label = UILabel()
        label.semanticContentAttribute = .forceRightToLeft
        label.text = "Enabled"
        label.translatesAutoresizingMaskIntoConstraints = false
        let control = UIView()
        control.semanticContentAttribute = .forceRightToLeft
        control.translatesAutoresizingMaskIntoConstraints = false
        root.addSubview(label)
        root.addSubview(control)
        NSLayoutConstraint.activate([
            label.leadingAnchor.constraint(equalTo: root.leadingAnchor),
            label.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            control.trailingAnchor.constraint(equalTo: root.trailingAnchor),
            control.centerYAnchor.constraint(equalTo: root.centerYAnchor),
            control.widthAnchor.constraint(equalToConstant: 51),
            control.heightAnchor.constraint(equalToConstant: 31),
            label.trailingAnchor.constraint(lessThanOrEqualTo: control.leadingAnchor,
                                            constant: -8),
        ])
        root.layoutIfNeeded()
        XCTAssertEqual(control.frame.origin.x, 0, accuracy: 0.51)
        XCTAssertEqual(label.frame.width, label.intrinsicContentSize.width, accuracy: 0.51)
        XCTAssertEqual(label.frame.maxX, 343, accuracy: 0.51)
    }
}
