// Runtime oracle: scripts/editmenu_probe_sim.sh /tmp/uikit-editmenu-oracle
import UIKit

private func point(_ p: CGPoint) -> [Double] { [Double(p.x), Double(p.y)] }
private func rect(_ r: CGRect) -> [Double] { [Double(r.origin.x), Double(r.origin.y), Double(r.width), Double(r.height)] }

private final class MenuDelegate: NSObject, UIEditMenuInteractionDelegate {
    var events: [String] = []
    var mode = "one"
    var targets: [[Double]] = []
    var suggestions: [[String]] = []
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, menuFor configuration: UIEditMenuConfiguration, suggestedActions: [UIMenuElement]) -> UIMenu? {
        events.append("menu:\(configuration.identifier)")
        suggestions.append(suggestedActions.map { String(describing: type(of: $0)) + ":" + $0.title })
        if mode == "nil" { return nil }
        if mode == "empty" { return UIMenu(children: []) }
        return UIMenu(children: [UIAction(title: "Probe action") { _ in self.events.append("action") }])
    }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, targetRectFor configuration: UIEditMenuConfiguration) -> CGRect {
        events.append("target:\(configuration.identifier)")
        let r = CGRect(origin: configuration.sourcePoint, size: .zero)
        targets.append(rect(r))
        return .null
    }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, willPresentMenuFor configuration: UIEditMenuConfiguration, animator: UIEditMenuInteractionAnimating) {
        events.append("willPresent:\(configuration.identifier)")
        animator.addAnimations { self.events.append("present.animations") }
        animator.addCompletion { self.events.append("present.completion") }
        events.append("willPresent.return")
    }
    func editMenuInteraction(_ interaction: UIEditMenuInteraction, willDismissMenuFor configuration: UIEditMenuConfiguration, animator: UIEditMenuInteractionAnimating) {
        events.append("willDismiss:\(configuration.identifier)")
        animator.addAnimations { self.events.append("dismiss.animations") }
        animator.addCompletion { self.events.append("dismiss.completion") }
        events.append("willDismiss.return")
    }
}

private final class EditMenuProbeApp: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    let spy = MenuDelegate()
    var interaction: UIEditMenuInteraction!
    let source = UIView(frame: CGRect(x: 40, y: 120, width: 260, height: 240))
    var records: [[String: Any]] = []
    var steps: [() -> Void] = []
    var index = 0
    let config = UIEditMenuConfiguration(identifier: "sample", sourcePoint: CGPoint(x: 70, y: 90))

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let w = UIWindow(frame: UIScreen.main.bounds)
        let vc = UIViewController()
        vc.view.backgroundColor = .white
        vc.view.addSubview(source)
        w.rootViewController = vc
        w.makeKeyAndVisible()
        window = w
        interaction = UIEditMenuInteraction(delegate: spy)
        let nilConfig = UIEditMenuConfiguration(identifier: nil, sourcePoint: CGPoint(x: -2.25, y: 3.5))
        let otherNilConfig = UIEditMenuConfiguration(identifier: nil, sourcePoint: .zero)
        records.append(["stage": "configuration", "identifier": String(describing: config.identifier), "source": point(config.sourcePoint), "arrow": config.preferredArrowDirection.rawValue, "nilIdentifierType": String(describing: type(of: nilConfig.identifier.base)), "nilIdentifierUnique": nilConfig.identifier != otherNilConfig.identifier, "nilIdentifierHasUUIDDescription": UUID(uuidString: String(describing: nilConfig.identifier)) != nil, "nilIdentifierUUID": nilConfig.identifier.base is UUID, "nilIdentifierEqualsDescription": nilConfig.identifier == AnyHashable(String(describing: nilConfig.identifier)), "nilSource": point(nilConfig.sourcePoint), "arrows": [UIEditMenuArrowDirection.automatic, .up, .down, .left, .right].map { direction -> Int in config.preferredArrowDirection = direction; return config.preferredArrowDirection.rawValue }])
        config.preferredArrowDirection = .automatic
        var weakDelegate: MenuDelegate? = MenuDelegate()
        let weakInteraction = UIEditMenuInteraction(delegate: weakDelegate)
        weakDelegate = nil
        let mutable = NSMutableString(string: "before")
        let copied = UIEditMenuConfiguration(identifier: AnyHashable(mutable), sourcePoint: .zero)
        mutable.append("-after")
        records.append(["stage":"copyIdentifier", "value":String(describing:copied.identifier)])
        records.append(["stage":"weakDelegate", "released":weakInteraction.delegate == nil])
        record("detached.initial")
        let initialInteraction = interaction
        interaction = UIEditMenuInteraction(delegate: spy)
        let unwindowedView = UIView(frame: CGRect(x: 11, y: 22, width: 100, height: 100))
        unwindowedView.addInteraction(interaction)
        record("unwindowed.attached")
        interaction.presentEditMenu(with: config)
        record("unwindowed.present.immediate")
        unwindowedView.removeInteraction(interaction)
        record("unwindowed.removed")
        interaction.reloadVisibleMenu(); interaction.updateVisibleMenuPosition(animated: false); interaction.dismissMenu()
        record("unwindowed.removed.idleMethods")
        interaction = initialInteraction
        interaction.reloadVisibleMenu(); interaction.updateVisibleMenuPosition(animated: false); interaction.dismissMenu()
        record("detached.idleMethods")
        interaction.presentEditMenu(with: config)
        record("detached.present.immediate")
        steps = [
            { self.record("detached.present.settled"); self.source.addInteraction(self.interaction); self.record("attached.initial") },
            { self.interaction.presentEditMenu(with: self.config); self.record("attached.present.immediate") },
            { self.record("attached.present.settled"); self.interaction.updateVisibleMenuPosition(animated: false); self.record("attached.update.immediate") },
            { self.record("attached.update.settled"); self.interaction.reloadVisibleMenu(); self.record("attached.reload.immediate") },
            { self.record("attached.reload.settled"); self.interaction.dismissMenu(); self.record("attached.dismiss.immediate") },
            { self.record("attached.dismiss.settled"); self.interaction.dismissMenu(); self.interaction.reloadVisibleMenu(); self.interaction.updateVisibleMenuPosition(animated: true); self.record("attached.idleMethods") },
            { self.spy.mode = "empty"; self.interaction.presentEditMenu(with: self.config); self.record("empty.present.immediate") },
            { self.record("empty.present.settled"); self.spy.mode = "nil"; self.interaction.presentEditMenu(with: self.config); self.record("nil.present.immediate") },
            { self.record("nil.present.settled"); self.interaction.dismissMenu(); self.record("nil.dismiss"); self.interaction.reloadVisibleMenu(); self.interaction.updateVisibleMenuPosition(animated: true); self.record("nil.idleMethods"); self.source.removeInteraction(self.interaction); self.record("removed"); self.finish() }
        ]
        next()
        return true
    }
    func record(_ stage: String) {
        records.append(["stage":stage, "events":spy.events, "suggestions":spy.suggestions, "targets":spy.targets, "attached":interaction.view === source, "locationSource":point(interaction.location(in:source)), "locationWindow":point(interaction.location(in:window)), "locationNil":point(interaction.location(in:nil)), "gestures":source.gestureRecognizers?.count ?? 0])
        spy.events = []; spy.targets = []; spy.suggestions = []
    }
    func next() {
        guard index < steps.count else { return }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { self.steps[self.index](); self.index += 1; self.next() }
    }
    func finish() {
        let output: [String:Any] = ["systemVersion":UIDevice.current.systemVersion, "device":UIDevice.current.model, "screen":rect(UIScreen.main.bounds), "scale":UIScreen.main.scale, "records":records]
        let data = try! JSONSerialization.data(withJSONObject: output, options: [.prettyPrinted, .sortedKeys])
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        try! data.write(to: docs.appendingPathComponent("editmenu.json"))
        print(String(data: data, encoding: .utf8)!)
        exit(0)
    }
}
_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(EditMenuProbeApp.self))
