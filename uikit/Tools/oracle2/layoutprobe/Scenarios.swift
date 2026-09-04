// Auto Layout tie-break scenarios, shared by the REAL-iOS probe
// (Tools/oracle2/layoutprobe/main.swift, `import UIKit`) and the port's
// carried-golden test (Tests/OpenUIKitTests/LayoutTieBreakTests.swift,
// `import OpenUIKit`, via a symlink) — one source, two engines. The oracle's
// answers live in golden/layout_tiebreak_ios.json.
#if canImport(OpenUIKit)
import OpenUIKit
#else
import UIKit
#endif

public func r3(_ v: CGFloat) -> Double { v.isFinite ? (Double(v) * 1000).rounded() / 1000 : -1 }

public func label(_ text: String, size: CGFloat = 18, weight: UIFont.Weight = .semibold) -> UILabel {
    let l = UILabel()
    l.text = text
    l.font = .systemFont(ofSize: size, weight: weight)
    l.translatesAutoresizingMaskIntoConstraints = false
    return l
}


/// The app's row shape exactly (SimpleActionView): label top >= 8, bottom <= -8,
/// centerY; secondary the same; A.trailing = B.leading - 24; row.trailing = B.trailing + 20.
public func appRow(_ row: UIView, linesA: Int = 1, linesB: Int = 1, rightB: Bool = false, metrics: Bool = false) -> [(String, UIView)] {
    let a = label("Download"), b = label("Wi-Fi only", size: 16)
    a.numberOfLines = linesA; b.numberOfLines = linesB
    if rightB { b.textAlignment = .right }
    if metrics {
        a.font = UIFontMetrics(forTextStyle: .headline).scaledFont(for: .systemFont(ofSize: 18, weight: .semibold))
        b.font = UIFontMetrics(forTextStyle: .callout).scaledFont(for: .systemFont(ofSize: 16, weight: .semibold))
        a.adjustsFontForContentSizeCategory = true; b.adjustsFontForContentSizeCategory = true
    }
    a.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
    row.addSubview(a)
    NSLayoutConstraint.activate([
        a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
        a.topAnchor.constraint(greaterThanOrEqualTo: row.topAnchor, constant: 8),
        a.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -8),
        a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    b.setContentCompressionResistancePriority(UILayoutPriority(749), for: .horizontal)
    row.addSubview(b)
    NSLayoutConstraint.activate([
        b.topAnchor.constraint(greaterThanOrEqualTo: row.topAnchor, constant: 8),
        b.bottomAnchor.constraint(lessThanOrEqualTo: row.bottomAnchor, constant: -8),
        b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
    ])
    a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24).isActive = true
    row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20).isActive = true
    return [("A", a), ("B", b)]
}

public struct Scenario {
    public let name: String
    /// Build the row's subviews and constraints inside `row` (393x72).
    public let build: (UIView) -> [(String, UIView)]
    /// Build the row before it is in the window (then add it).
    public var detached = false
    /// Put the row in a vertical UIStackView pinned to the container width.
    public var inStack = false
    public init(name: String, detached: Bool = false, inStack: Bool = false, _ build: @escaping (UIView) -> [(String, UIView)]) {
        self.name = name; self.build = build; self.detached = detached; self.inStack = inStack
    }
}

public let layoutScenarios: [Scenario] = [
    // The app's own shape: A.leading 20, A.trailing = B.leading - 24, B.trailing -20.
    Scenario(name: "two_labels_app_order") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Same constraints activated in reverse order.
    Scenario(name: "two_labels_reverse_constraints") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // B added as a subview before A.
    Scenario(name: "two_labels_reverse_subviews") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        row.addSubview(b); row.addSubview(a)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Same fonts on both labels (rules out a font/intrinsic-size effect).
    Scenario(name: "two_labels_same_font") { row in
        let a = label("Download"), b = label("Wi-Fi only")
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Three labels in a row.
    Scenario(name: "three_labels") { row in
        let a = label("One"), b = label("Two"), c = label("Three")
        row.addSubview(a); row.addSubview(b); row.addSubview(c)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            c.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            b.trailingAnchor.constraint(equalTo: c.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b), ("C", c)]
    },
    // Control: A hugs harder (251) — B must stretch whatever the tie rule.
    Scenario(name: "two_labels_a_hugs_251") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        a.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Control: B hugs harder (251) — A must stretch.
    Scenario(name: "two_labels_b_hugs_251") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        b.setContentHuggingPriority(UILayoutPriority(251), for: .horizontal)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Vertical: two labels stacked, equal hugging, pinned top and bottom.
    Scenario(name: "two_labels_vertical") { row in
        let a = label("Top"), b = label("Bottom", size: 16)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.topAnchor.constraint(equalTo: row.topAnchor, constant: 4),
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            b.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.bottomAnchor.constraint(equalTo: b.topAnchor, constant: -4),
            row.bottomAnchor.constraint(equalTo: b.bottomAnchor, constant: 4),
        ])
        return [("A", a), ("B", b)]
    },
    // Compression tie: not enough room, equal resistance (750) on both.
    Scenario(name: "two_labels_compression_tie") { row in
        let a = label("A rather long leading label text"), b = label("and a long trailing one too", size: 16)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // The app's real priorities: A resists 751, B resists 749 (room enough).
    Scenario(name: "two_labels_app_priorities") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        a.setContentCompressionResistancePriority(UILayoutPriority(751), for: .horizontal)
        b.setContentCompressionResistancePriority(UILayoutPriority(749), for: .horizontal)
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Two plain views with fixed intrinsic-less widths? No intrinsic: give
    // both a low-priority width preference instead (width == 50 @ 250).
    Scenario(name: "two_views_width_preference_tie") { row in
        let a = UIView(), b = UIView()
        a.translatesAutoresizingMaskIntoConstraints = false
        b.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(a); row.addSubview(b)
        let wa = a.widthAnchor.constraint(equalToConstant: 50); wa.priority = UILayoutPriority(250)
        let wb = b.widthAnchor.constraint(equalToConstant: 50); wb.priority = UILayoutPriority(250)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.topAnchor.constraint(equalTo: row.topAnchor), a.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            b.topAnchor.constraint(equalTo: row.topAnchor), b.bottomAnchor.constraint(equalTo: row.bottomAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
            wa, wb,
        ])
        return [("A", a), ("B", b)]
    },
    // The app's exact row, built while already in the window.
    Scenario(name: "approw_attached") { row in appRow(row) },
    // The app's exact row built DETACHED: constraints activated before the
    // row joins any window (SimpleActionView builds itself in init).
    Scenario(name: "approw_detached", detached: true) { row in appRow(row) },
    // The app's exact row inside a vertical UIStackView pinned to the
    // container's width, built detached (the app's structure).
    Scenario(name: "approw_in_stack_detached", detached: true, inStack: true) { row in appRow(row) },
    Scenario(name: "approw_in_stack_attached", detached: false, inStack: true) { row in appRow(row) },
    // numberOfLines = 0 on both labels (the app's setting): a wrapping label
    // gets UIKit's two-pass preferredMaxLayoutWidth treatment.
    Scenario(name: "approw_lines0_both") { row in appRow(row, linesA: 0, linesB: 0) },
    Scenario(name: "approw_lines0_a") { row in appRow(row, linesA: 0, linesB: 1) },
    Scenario(name: "approw_lines0_b") { row in appRow(row, linesA: 1, linesB: 0) },
    Scenario(name: "approw_lines0_both_rightB") { row in appRow(row, linesA: 0, linesB: 0, rightB: true) },
    Scenario(name: "approw_full_app_settings", detached: true, inStack: true) { row in appRow(row, linesA: 0, linesB: 0, rightB: true, metrics: true) },
    // Multi-line variants that decide the rule's shape.
    Scenario(name: "three_labels_all_lines0") { row in
        let a = label("One"), b = label("Two"), c = label("Three")
        for l in [a, b, c] { l.numberOfLines = 0 }
        row.addSubview(a); row.addSubview(b); row.addSubview(c)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            c.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            b.trailingAnchor.constraint(equalTo: c.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b), ("C", c)]
    },
    Scenario(name: "three_labels_middle_lines0") { row in
        let a = label("One"), b = label("Two"), c = label("Three")
        b.numberOfLines = 0
        row.addSubview(a); row.addSubview(b); row.addSubview(c)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            c.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            b.trailingAnchor.constraint(equalTo: c.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b), ("C", c)]
    },
    Scenario(name: "three_labels_ab_lines0") { row in
        let a = label("One"), b = label("Two"), c = label("Three")
        a.numberOfLines = 0; b.numberOfLines = 0
        row.addSubview(a); row.addSubview(b); row.addSubview(c)
        NSLayoutConstraint.activate([
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            c.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            b.trailingAnchor.constraint(equalTo: c.leadingAnchor, constant: -24),
            row.trailingAnchor.constraint(equalTo: c.trailingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b), ("C", c)]
    },
    // Both multi-line, constraints in reverse order (B referenced first).
    Scenario(name: "two_labels_lines0_reverse_constraints") { row in
        let a = label("Download"), b = label("Wi-Fi only", size: 16)
        a.numberOfLines = 0; b.numberOfLines = 0
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            row.trailingAnchor.constraint(equalTo: b.trailingAnchor, constant: 20),
            a.trailingAnchor.constraint(equalTo: b.leadingAnchor, constant: -24),
            b.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
        ])
        return [("A", a), ("B", b)]
    },
    // Multi-line label with a multi-line row height: does wrapping change it?
    Scenario(name: "two_labels_lines0_vertical") { row in
        let a = label("Top"), b = label("Bottom", size: 16)
        a.numberOfLines = 0; b.numberOfLines = 0
        row.addSubview(a); row.addSubview(b)
        NSLayoutConstraint.activate([
            a.topAnchor.constraint(equalTo: row.topAnchor, constant: 4),
            a.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            b.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            a.bottomAnchor.constraint(equalTo: b.topAnchor, constant: -4),
            row.bottomAnchor.constraint(equalTo: b.bottomAnchor, constant: 4),
        ])
        return [("A", a), ("B", b)]
    },
]


/// Builds scenario `s` into `container` (a laid-out view at least 393 pt
/// wide) the way the probe does — attached, detached, or inside a vertical
/// stack — lays it out, and returns the tagged views.
@discardableResult
public func runLayoutScenario(_ s: Scenario, in container: UIView, index i: Int) -> [(String, UIView)] {
    let row = UIView(frame: CGRect(x: 0, y: 100 + CGFloat(i) * 80, width: 393, height: 72))
    var tagged: [(String, UIView)] = []
    if s.inStack {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.translatesAutoresizingMaskIntoConstraints = false
        row.translatesAutoresizingMaskIntoConstraints = false
        row.heightAnchor.constraint(greaterThanOrEqualToConstant: 72).isActive = true
        if s.detached { tagged = s.build(row) }
        stack.addArrangedSubview(row)
        if !s.detached { container.addSubview(stack); tagged = s.build(row) }
        else { container.addSubview(stack) }
        NSLayoutConstraint.activate([
            stack.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            stack.widthAnchor.constraint(equalToConstant: 393),
            stack.topAnchor.constraint(equalTo: container.topAnchor, constant: 100 + CGFloat(i) * 80),
        ])
    } else if s.detached {
        tagged = s.build(row)
        container.addSubview(row)
    } else {
        container.addSubview(row)
        tagged = s.build(row)
    }
    row.setNeedsLayout(); row.layoutIfNeeded()
    container.layoutIfNeeded()
    return tagged
}
