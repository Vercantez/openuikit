// Carried-golden test for UNSATISFIABLE required constraints: which one the
// engine breaks, and the frames that result. The scenarios are
// Tools/oracle2/breakprobe/scenarios.json (gen_scenarios.py); the answers in
// golden/layout_break_ios.json were written by Tools/oracle2/breakprobe on
// the iPhone SE (3rd gen) / iOS 26.1 simulator on 2026-09-23. Re-measure
// with `scripts/break_probe_sim.sh <dir>` and copy the JSON over.
//
// The engine's rule (LayoutEngine.solve, "UNSATISFIABLE REQUIRED
// CONSTRAINTS") is a MODEL of UIKit's choice; this test keeps it honest,
// scenario by scenario, including the history cases (a broken constraint
// stays broken).
import XCTest
@testable import OpenUIKit

typealias NSLayoutConstraint = OpenUIKit.NSLayoutConstraint

#if !os(Linux)
@MainActor
#endif
final class LayoutBreakTests: XCTestCase {
    struct Scenario: Decodable {
        let name: String
        let mode: String
        let views: [String]
        let viewCreate: [String]?
        let viewAdd: [String]?
        let create: [String]
        let steps: [String]
        let constraints: [String: [Spec]]
        let intrinsic: [String: [Double]]?
    }
    final class IntrinsicView: UIView {
        var size = CGSize.zero
        override var intrinsicContentSize: CGSize { size }
    }
    enum Spec: Decodable {
        case s(String), n(Double), null
        init(from d: Decoder) throws {
            let c = try d.singleValueContainer()
            if c.decodeNil() { self = .null }
            else if let x = try? c.decode(Double.self) { self = .n(x) }
            else { self = .s(try c.decode(String.self)) }
        }
        var string: String? { if case .s(let v) = self { return v }; return nil }
        var number: Double { if case .n(let v) = self { return v }; return 0 }
    }
    struct Scenarios: Decodable { let scenarios: [Scenario] }
    struct Break: Decodable { let broken: String }
    struct Result: Decodable { let name: String; let breaks: [Break]; let frames: [String: [Double]] }
    struct Golden: Decodable { let results: [Result] }

    static func attribute(_ s: String?) -> NSLayoutConstraint.Attribute {
        switch s {
        case "leading": return .leading
        case "trailing": return .trailing
        case "left": return .left
        case "right": return .right
        case "top": return .top
        case "bottom": return .bottom
        case "width": return .width
        case "height": return .height
        case "centerX": return .centerX
        case "centerY": return .centerY
        default: return .notAnAttribute
        }
    }

    /// Run one scenario the way the probe does. Returns frames by view name.
    func run(_ s: Scenario, root: UIView) -> [String: CGRect] {
        let c = UIView(frame: CGRect(x: 0, y: 0, width: 300, height: 300))
        var views: [String: UIView] = ["c": c]
        for name in s.viewCreate ?? s.views {
            let v: UIView
            if let spec = s.intrinsic?[name] {
                let k = IntrinsicView()
                k.size = CGSize(width: spec[0], height: spec[1])
                k.setContentHuggingPriority(UILayoutPriority(Float(spec[2])), for: .horizontal)
                k.setContentCompressionResistancePriority(UILayoutPriority(Float(spec[3])), for: .horizontal)
                v = k
            } else {
                v = UIView()
            }
            v.translatesAutoresizingMaskIntoConstraints = false
            views[name] = v
        }
        for name in s.viewAdd ?? s.views where name != "u" { c.addSubview(views[name]!) }
        if let u = views["u"] { views["v"]!.addSubview(u) }
        var cons: [String: NSLayoutConstraint] = [:]
        for tag in s.create {
            let spec = s.constraints[tag]!
            let rel: NSLayoutConstraint.Relation = spec[2].string == "<=" ? .lessThanOrEqual
                : spec[2].string == ">=" ? .greaterThanOrEqual : .equal
            let k = NSLayoutConstraint(item: views[spec[0].string!]!, attribute: Self.attribute(spec[1].string),
                                       relatedBy: rel, toItem: spec[3].string.map { views[$0]! },
                                       attribute: Self.attribute(spec[4].string),
                                       multiplier: CGFloat(spec[5].number), constant: CGFloat(spec[6].number))
            k.priority = UILayoutPriority(Float(spec[7].number))
            cons[tag] = k
        }
        let live = s.mode == "live"
        if live { root.addSubview(c); root.layoutIfNeeded() }
        for step in s.steps {
            cons[String(step.dropFirst())]!.isActive = step.hasPrefix("+")
            // Live: UIKit's engine sees each activation as it happens.
            if live { root.setNeedsLayout(); root.layoutIfNeeded() }
        }
        if !live { root.addSubview(c) }
        root.setNeedsLayout()
        root.layoutIfNeeded()
        var out: [String: CGRect] = [:]
        for (name, v) in views where name != "c" { out[name] = v.frame }
        c.removeFromSuperview()
        return out
    }

    func testBreakChoiceMatchesRealUIKit() throws {
        let scenarios = try JSONDecoder().decode(
            Scenarios.self, from: Data(contentsOf: URL(fileURLWithPath: "Tools/oracle2/breakprobe/scenarios.json")))
        let golden = try JSONDecoder().decode(
            Golden.self, from: Data(contentsOf: URL(fileURLWithPath: "golden/layout_break_ios.json")))
        let byName = Dictionary(uniqueKeysWithValues: golden.results.map { ($0.name, $0) })
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 375, height: 667))
        let vc = UIViewController()
        window.rootViewController = vc
        window.makeKeyAndVisible()
        // Measured choices the model does not reproduce (the frame-based
        // container written as FIRST item against a child; see LayoutEngine).
        let knownDivergent: Set<String> = [
            "V4tie.live.flip2.abzz", "V4tie.live.flip2.azzb", "V4tie.live.flip2.bazz",
            "V4tie.live.flip2.bzza", "V4tie.live.flip2.zzab", "V4tie.live.flip2.zzba",
        ]
        var matched = 0, divergent: [String] = []
        for s in scenarios.scenarios {
            guard let g = byName[s.name] else { XCTFail("no golden for \(s.name)"); continue }
            let frames = run(s, root: vc.view)
            var ok = true
            for (name, f) in g.frames {
                let got = frames[name]!
                let want = CGRect(x: f[0], y: f[1], width: f[2], height: f[3])
                if abs(got.minX - want.minX) > 0.01 || abs(got.minY - want.minY) > 0.01
                    || abs(got.width - want.width) > 0.01 || abs(got.height - want.height) > 0.01 {
                    ok = false
                    if !knownDivergent.contains(s.name) {
                        XCTFail("\(s.name) \(name): port \(got) iOS \(want) (iOS broke \(g.breaks.map(\.broken)))")
                    }
                }
            }
            if ok { matched += 1 } else { divergent.append(s.name) }
        }
        print("LayoutBreakTests: \(matched)/\(scenarios.scenarios.count) scenarios match iOS 26.1; divergent: \(divergent)")
        for name in knownDivergent where !divergent.contains(name) {
            XCTFail("\(name) now matches iOS: remove it from knownDivergent")
        }
    }
}
