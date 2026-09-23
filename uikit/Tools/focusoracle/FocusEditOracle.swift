// Observation-only harness (edit-state variant of FocusOracle.swift), compiled
// beside unmodified Blockzilla by scripts/focus_edit_probe_sim.sh.
//
// Question it answers: when Focus's URL bar enters editing, its constraints
// are unsatisfiable. WHICH constraint does iOS 26.1 break, and what frames
// result? It records:
//   - every call of UIView's engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:
//     (the method that prints "Will attempt to recover by breaking constraint"),
//     with the broken constraint and the mutually exclusive set, in call order;
//   - the URL bar subtree's frames and every constraint installed in it
//     (SnapKit's description carries file#line), at launch (editing), after
//     cancel, after re-activation, and after typing "mozilla";
//   - a screenshot of each state.
// Output: Documents/focus_edit.<state>.{png,json}, focus_edit.breaks.json, DONE.
import UIKit
import Onboarding
import ObjectiveC

nonisolated(unsafe) var focusEditBreaks: [[String: Any]] = []
nonisolated(unsafe) var focusEditStage = "launch"

private func describe(_ c: NSLayoutConstraint) -> [String: Any] {
    func item(_ o: AnyObject?) -> String {
        guard let o else { return "nil" }
        if let v = o as? UIView { return "\(type(of: v))" + (v.accessibilityIdentifier.map { "#\($0)" } ?? "") }
        if let g = o as? UILayoutGuide { return "UILayoutGuide:" + g.identifier + "@" + (g.owningView.map { "\(type(of: $0))" } ?? "nil") }
        return "\(type(of: o))"
    }
    return ["description": String(describing: c),
            "first": item(c.firstItem), "firstAttribute": c.firstAttribute.rawValue,
            "relation": c.relation.rawValue,
            "second": item(c.secondItem), "secondAttribute": c.secondAttribute.rawValue,
            "multiplier": Double(c.multiplier), "constant": Double(c.constant),
            "priority": Double(c.priority.rawValue), "active": c.isActive,
            "identifier": c.identifier ?? ""]
}

@_cdecl("FocusOracleStart")
func focusOracleStart() {
    let shown: Set<ToolTipRoute> = [.onboarding(.v1), .onboarding(.v2), .searchBar, .menu]
    UserDefaults.standard.set(try! JSONEncoder().encode(shown), forKey: OnboardingConstants.shownTips)
    UserDefaults.standard.set(true, forKey: OnboardingConstants.onboardingDidAppear)
    UserDefaults.standard.set(true, forKey: OnboardingConstants.showOldOnboarding)
    installBreakRecorder()
    NotificationCenter.default.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
        let steps: [(Double, () -> Void)] = [
            (1.0, { capture("launch") }),
            (1.2, { focusEditStage = "cancel"; tapIdentifier("URLBar.cancelButton") }),
            (2.2, { capture("cancelled") }),
            (2.4, { focusEditStage = "activate"; activateURLBar() }),
            (3.4, { capture("activated") }),
            (3.6, { focusEditStage = "type"; typeInto("mozilla") }),
            (4.6, { capture("typed") }),
            (4.8, { writeBreaks() }),
        ]
        for (t, f) in steps { DispatchQueue.main.asyncAfter(deadline: .now() + t, execute: f) }
    }
}

private func window() -> UIWindow? { (UIApplication.shared.delegate as? AppDelegate)?.window }

private func find(_ v: UIView, _ pred: (UIView) -> Bool) -> UIView? {
    if pred(v) { return v }
    for c in v.subviews { if let f = find(c, pred) { return f } }
    return nil
}

private func tapIdentifier(_ id: String) {
    guard let w = window(), let b = find(w, { $0.accessibilityIdentifier == id }) as? UIButton else { return }
    b.sendActions(for: .touchUpInside)
}

private func activateURLBar() {
    // The same path a tap takes: URLBar's single-tap recognizer calls
    // setTextForURL -> enterOverlayMode -> becomeFirstResponder. Reached
    // through the public selector the recognizer targets is not possible
    // (private), so focus the field the way activateTextField() does.
    guard let w = window(), let bar = find(w, { String(describing: type(of: $0)) == "URLBar" }) else { return }
    _ = bar.perform(NSSelectorFromString("activateTextField"))
}

private func typeInto(_ s: String) {
    guard let w = window(), let tf = find(w, { $0.accessibilityIdentifier == "URLBar.urlText" }) as? UITextField else { return }
    for ch in s { tf.insertText(String(ch)) }
}

private func installBreakRecorder() {
    let sel = NSSelectorFromString("engine:willBreakConstraint:dueToMutuallyExclusiveConstraints:")
    guard let m = class_getInstanceMethod(UIView.self, sel) else {
        focusEditBreaks.append(["error": "no engine:willBreakConstraint: on UIView"]); return
    }
    typealias Orig = @convention(c) (AnyObject, Selector, AnyObject, NSLayoutConstraint, NSArray) -> Void
    let orig = unsafeBitCast(method_getImplementation(m), to: Orig.self)
    let block: @convention(block) (AnyObject, AnyObject, NSLayoutConstraint, NSArray) -> Void = { me, engine, broken, set in
        var entry: [String: Any] = ["stage": focusEditStage, "view": "\(type(of: me))",
                                    "broken": describe(broken)]
        entry["exclusive"] = (set as? [NSLayoutConstraint] ?? []).map(describe)
        focusEditBreaks.append(entry)
        orig(me, sel, engine, broken, set)
    }
    method_setImplementation(m, imp_implementationWithBlock(block))
}

private func rect(_ r: CGRect) -> [Double] {
    [r.minX, r.minY, r.width, r.height].map { (Double($0) * 1000).rounded() / 1000 }
}

private func capture(_ state: String) {
    guard let w = window() else { return }
    w.layoutIfNeeded()
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    let format = UIGraphicsImageRendererFormat()
    format.scale = w.screen.scale
    format.opaque = true
    let image = UIGraphicsImageRenderer(bounds: w.bounds, format: format).image { _ in
        w.drawHierarchy(in: w.bounds, afterScreenUpdates: true)
    }
    try! image.pngData()!.write(to: docs.appendingPathComponent("focus_edit.\(state).png"))
    guard let bar = find(w, { String(describing: type(of: $0)) == "URLBar" }) else { return }
    var views: [[String: Any]] = []
    var constraints: [[String: Any]] = []
    func walk(_ v: UIView, _ path: String) {
        var row: [String: Any] = ["path": path, "class": "\(type(of: v))",
                                  "id": v.accessibilityIdentifier ?? "",
                                  "frame": rect(v.frame), "inBar": rect(v.convert(v.bounds, to: bar)),
                                  "hidden": v.isHidden, "alpha": Double(v.alpha)]
        if let tf = v as? UITextField { row["text"] = tf.text ?? ""; row["firstResponder"] = tf.isFirstResponder }
        views.append(row)
        for c in v.constraints { var d = describe(c); d["installedOn"] = path; constraints.append(d) }
        for (i, s) in v.subviews.enumerated() { walk(s, path.isEmpty ? "\(i)" : "\(path).\(i)") }
    }
    walk(bar, "")
    let guides = bar.layoutGuides.map { g -> [String: Any] in
        ["identifier": g.identifier, "frame": rect(g.layoutFrame)]
    }
    let payload: [String: Any] = ["state": state, "barInWindow": rect(bar.convert(bar.bounds, to: w)),
                                  "views": views, "guides": guides, "constraints": constraints]
    try! JSONSerialization.data(withJSONObject: payload, options: [.prettyPrinted, .sortedKeys])
        .write(to: docs.appendingPathComponent("focus_edit.\(state).json"))
}

private func writeBreaks() {
    let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    try! JSONSerialization.data(withJSONObject: ["breaks": focusEditBreaks], options: [.prettyPrinted, .sortedKeys])
        .write(to: docs.appendingPathComponent("focus_edit.breaks.json"))
    try! Data("done".utf8).write(to: docs.appendingPathComponent("DONE"))
}
