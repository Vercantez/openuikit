// AlertProbe: iOS Simulator ALERT oracle (M12 alerts cluster).
//
// Sibling of SheetProbe (interactive sheets) and SimProbe (scroll physics).
// Mac Catalyst renders UIAlertController as an AppKit-bridged alert panel —
// nothing like the iOS look — so every metric of the iOS alert / action sheet
// has to come from real iOS UIKit running in the simulator.
//
// What it measures, per configuration:
//   1. the full private view hierarchy in WINDOW coordinates (frames, corner
//      radii, background colours, alpha) — alert width, button heights,
//      separator hairlines, action-sheet insets
//   2. every UILabel's text, resolved colour, font family/size/weight and
//      alignment — title/message typography, destructive/cancel typography
//   3. the visual-effect views UIKit uses for the platter and the button
//      highlights (we have no UIVisualEffectView — see docs/KNOWN_GAPS.md)
//   4. a window SNAPSHOT per configuration, so the flat colour equivalent of
//      the blur can be solved from the pixels over known base colours
//
// Output: <Documents>/alert_<name>.json + alert_<name>.png per config,
// plus probe.log. Build + run end-to-end: scripts/alert_probe_sim.sh <outdir>
import UIKit

let docsDir = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]

var logLines: [String] = []
func log(_ s: String) {
    print(s)
    logLines.append(s)
}

func rgba(_ c: UIColor, _ traits: UITraitCollection) -> [Double] {
    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
    c.resolvedColor(with: traits).getRed(&r, green: &g, blue: &b, alpha: &a)
    return [Double(r), Double(g), Double(b), Double(a)]
}

func dumpHierarchy(_ v: UIView, in window: UIWindow, depth: Int = 0,
                   path: String = "", into out: inout [[String: Any]]) {
    let f = v.convert(v.bounds, to: window)
    var e: [String: Any] = [
        "path": path,
        "class": NSStringFromClass(type(of: v)),
        "depth": depth,
        "frame": [Double(f.minX), Double(f.minY), Double(f.width), Double(f.height)],
        "bounds": [Double(v.bounds.width), Double(v.bounds.height)],
        "alpha": Double(v.alpha),
        "hidden": v.isHidden,
        "cornerRadius": Double(v.layer.cornerRadius),
        "cornerCurve": "\(v.layer.cornerCurve.rawValue)",
        "opacity": Double(v.layer.opacity),
        "masksToBounds": v.layer.masksToBounds,
    ]
    if let bg = v.backgroundColor { e["bg"] = rgba(bg, v.traitCollection) }
    if let bgcg = v.layer.backgroundColor, v.backgroundColor == nil {
        e["layerBg"] = rgba(UIColor(cgColor: bgcg), v.traitCollection)
    }
    if v.layer.shadowOpacity > 0 {
        e["shadow"] = [
            "opacity": Double(v.layer.shadowOpacity),
            "radius": Double(v.layer.shadowRadius),
            "offset": [Double(v.layer.shadowOffset.width), Double(v.layer.shadowOffset.height)],
            "color": v.layer.shadowColor.map { rgba(UIColor(cgColor: $0), v.traitCollection) } ?? [],
        ]
    }
    if let l = v as? UILabel {
        e["text"] = l.text ?? ""
        e["font"] = [
            "name": l.font.fontName,
            "family": l.font.familyName,
            "size": Double(l.font.pointSize),
            "weightTrait": (l.font.fontDescriptor.object(forKey: .traits) as? [UIFontDescriptor.TraitKey: Any])
                .flatMap { ($0[.weight] as? NSNumber)?.doubleValue } ?? 0,
        ]
        e["textColor"] = rgba(l.textColor, l.traitCollection)
        e["tint"] = rgba(l.tintColor, l.traitCollection)
        e["alignment"] = l.textAlignment.rawValue
        e["numberOfLines"] = l.numberOfLines
        // The action labels report textColor black even for a destructive
        // action — UIKit carries the real colour on the attributed string.
        if let at = l.attributedText, at.length > 0,
           let fg = at.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            e["attrColor"] = rgba(fg, l.traitCollection)
        }
    }
    if let tf = v as? UITextField {
        e["placeholder"] = tf.placeholder ?? ""
        e["borderStyle"] = tf.borderStyle.rawValue
        e["tfFontSize"] = Double(tf.font?.pointSize ?? 0)
    }
    if let ve = v as? UIVisualEffectView {
        e["effect"] = "\(String(describing: ve.effect))"
    }
    if let iv = v as? UIImageView {
        e["hasImage"] = iv.image != nil
    }
    out.append(e)
    for (i, s) in v.subviews.enumerated() {
        dumpHierarchy(s, in: window, depth: depth + 1,
                      path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

// MARK: - Configurations

struct AlertConfig {
    var name: String
    var style: UIAlertController.Style = .alert
    var title: String?
    var message: String?
    /// (title, style, isPreferred)
    var actions: [(String, UIAlertAction.Style, Bool)] = []
    var textFields: [String] = []
    var dark = false
    /// Base screen colour behind the alert — a second, non-white base lets the
    /// blur be solved as (flat colour, alpha) rather than fit to one backdrop.
    var base: UIColor = .white
}

let configs: [AlertConfig] = [
    AlertConfig(name: "two_light", title: "Delete File?",
                message: "This item will be deleted immediately. You can't undo this action.",
                actions: [("Cancel", .cancel, false), ("Delete", .destructive, false)]),
    AlertConfig(name: "two_dark", title: "Delete File?",
                message: "This item will be deleted immediately. You can't undo this action.",
                actions: [("Cancel", .cancel, false), ("Delete", .destructive, false)],
                dark: true, base: .black),
    AlertConfig(name: "one_light", title: "Saved", message: "Your changes were saved.",
                actions: [("OK", .default, false)]),
    AlertConfig(name: "title_only", title: "Title only", message: nil,
                actions: [("OK", .default, false)]),
    AlertConfig(name: "message_only", title: nil, message: "Message only.",
                actions: [("OK", .default, false)]),
    AlertConfig(name: "three_light", title: "Choose", message: "Pick one option.",
                actions: [("First", .default, false), ("Second", .default, false),
                          ("Cancel", .cancel, false)]),
    AlertConfig(name: "preferred", title: "Confirm", message: "Preferred action test.",
                actions: [("Cancel", .cancel, false), ("Send", .default, true)]),
    AlertConfig(name: "textfield", title: "Sign In", message: "Enter your name.",
                actions: [("Cancel", .cancel, false), ("OK", .default, false)],
                textFields: ["Name"]),
    AlertConfig(name: "two_textfields", title: "Sign In", message: "Enter credentials.",
                actions: [("Cancel", .cancel, false), ("OK", .default, false)],
                textFields: ["User", "Password"]),
    AlertConfig(name: "long_title", title: "A rather long alert title that must wrap onto two lines",
                message: "And a message that is also long enough to wrap across several lines of text in the alert body.",
                actions: [("OK", .default, false)]),
    AlertConfig(name: "sheet_light", style: .actionSheet, title: "Photo",
                message: "Choose a source for the photo.",
                actions: [("Take Photo", .default, false), ("Choose Existing", .default, false),
                          ("Delete", .destructive, false), ("Cancel", .cancel, false)]),
    AlertConfig(name: "sheet_dark", style: .actionSheet, title: "Photo",
                message: "Choose a source for the photo.",
                actions: [("Take Photo", .default, false), ("Choose Existing", .default, false),
                          ("Delete", .destructive, false), ("Cancel", .cancel, false)],
                dark: true, base: .black),
    AlertConfig(name: "sheet_notitle", style: .actionSheet, title: nil, message: nil,
                actions: [("Take Photo", .default, false), ("Cancel", .cancel, false)]),
    // ORDERING: cancel added LAST (does UIKit move it?), and a destructive
    // action paired with a cancel.
    AlertConfig(name: "cancel_last", title: "Order", message: "Cancel added last.",
                actions: [("OK", .default, false), ("Cancel", .cancel, false)]),
    AlertConfig(name: "cancel_first_of_three", title: "Order",
                message: "Cancel added first of three.",
                actions: [("Cancel", .cancel, false), ("One", .default, false),
                          ("Two", .default, false)]),
    AlertConfig(name: "sheet_cancel_first", style: .actionSheet, title: "Order",
                message: "Cancel added first.",
                actions: [("Cancel", .cancel, false), ("One", .default, false),
                          ("Two", .default, false)]),
    // Blur solving: identical alert over two saturated bases.
    AlertConfig(name: "base_red", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)],
                base: UIColor(red: 1, green: 0, blue: 0, alpha: 1)),
    AlertConfig(name: "base_blue", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)],
                base: UIColor(red: 0, green: 0, blue: 1, alpha: 1)),
    AlertConfig(name: "base_gray", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)],
                base: UIColor(white: 0.5, alpha: 1)),
    AlertConfig(name: "base_gray25", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)],
                base: UIColor(white: 0.25, alpha: 1)),
    AlertConfig(name: "dark_base_white", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)], dark: true, base: .white),
    AlertConfig(name: "dark_base_gray", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)], dark: true,
                base: UIColor(white: 0.5, alpha: 1)),
    AlertConfig(name: "dark_base_gray25", title: "Blur", message: "Solve the platter.",
                actions: [("OK", .default, false)], dark: true,
                base: UIColor(white: 0.25, alpha: 1)),
]

final class Probe {
    let window: UIWindow
    /// Recreated per configuration — see `runOne`.
    var hostVC = UIViewController()

    init(window: UIWindow) {
        self.window = window
    }

    func snapshot() -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: window.bounds.size, format: fmt).image { _ in
            window.drawHierarchy(in: window.bounds, afterScreenUpdates: true)
        }
    }

    /// ONE configuration per app launch (the name comes in as argv[1]).
    ///
    /// Running the whole matrix in one process does not work: a dismissed
    /// alert's views survive long enough that the next alert stacks on top
    /// (measured — the dumped view count grew monotonically), and replacing
    /// the window's root view controller does not evict them either, because
    /// the presentation lives in a sibling `UITransitionView` of the window,
    /// not under the root. A fresh process is the only isolation that holds.
    func run(_ name: String) {
        guard let c = configs.first(where: { $0.name == name }) else {
            log("unknown configuration '\(name)'")
            try? "unknown configuration '\(name)'"
                .write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
            exit(2)
        }
        runOne(c)
        try? logLines.joined(separator: "\n")
            .write(toFile: docsDir + "/probe_\(name).log", atomically: true, encoding: .utf8)
        try? "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
    }

    func settle(_ s: TimeInterval = 0.45) {
        RunLoop.current.run(until: Date().addingTimeInterval(s))
    }

    func runOne(_ c: AlertConfig) {
        // Every configuration gets a FRESH root view controller. Presenting
        // and dismissing alerts back to back on ONE host does not settle
        // between configurations (verified: the dumps silently lagged a
        // configuration behind and then started stacking two live alerts);
        // replacing the root tears the whole presentation down synchronously.
        let host = UIViewController()
        host.view.backgroundColor = c.base
        window.rootViewController = host
        hostVC = host
        window.overrideUserInterfaceStyle = c.dark ? .dark : .light
        settle(0.3)

        let ac = UIAlertController(title: c.title, message: c.message, preferredStyle: c.style)
        ac.overrideUserInterfaceStyle = c.dark ? .dark : .light
        for ph in c.textFields {
            ac.addTextField { tf in tf.placeholder = ph }
        }
        var preferred: UIAlertAction?
        for (t, s, isPreferred) in c.actions {
            let a = UIAlertAction(title: t, style: s, handler: nil)
            ac.addAction(a)
            if isPreferred { preferred = a }
        }
        if let p = preferred { ac.preferredAction = p }
        // NOTE: do NOT touch `popoverPresentationController` — merely reading
        // it and setting a sourceView flips an iPhone action sheet into a
        // POPOVER presentation (verified: the dump came back as
        // _UIPopoverView with the cancel action silently dropped).
        hostVC.present(ac, animated: false)
        settle(0.6)
        window.layoutIfNeeded()
        settle(0.2)
        if hostVC.presentedViewController !== ac { log("WARNING \(c.name): not presented") }

        var views: [[String: Any]] = []
        dumpHierarchy(window, in: window, into: &views)

        // Action ORDER as UIKit reports it back (cancel placement etc.).
        let actionDump: [[String: Any]] = ac.actions.map {
            ["title": $0.title ?? "", "style": $0.style.rawValue, "enabled": $0.isEnabled]
        }
        let out: [String: Any] = [
            "name": c.name,
            "style": c.style == .alert ? "alert" : "actionSheet",
            "dark": c.dark,
            "base": rgba(c.base, window.traitCollection),
            "windowSize": [Double(window.bounds.width), Double(window.bounds.height)],
            "safeArea": [Double(window.safeAreaInsets.top), Double(window.safeAreaInsets.left),
                         Double(window.safeAreaInsets.bottom), Double(window.safeAreaInsets.right)],
            "actions": actionDump,
            "preferredActionTitle": ac.preferredAction?.title ?? "",
            "views": views,
        ]
        let data = try! JSONSerialization.data(withJSONObject: out,
                                               options: [.prettyPrinted, .sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/alert_\(c.name).json"))
        let img = snapshot()
        try! img.pngData()!.write(to: URL(fileURLWithPath: "\(docsDir)/alert_\(c.name).png"))
        log("probed \(c.name): \(views.count) views")

        // A text-field alert makes its field first responder; leaving the
        // keyboard up blocks the teardown and the next alert stacks on top
        // (verified: the view count grew monotonically from the first
        // text-field configuration onwards).
        window.endEditing(true)
        ac.dismiss(animated: false)
        settle(0.4)
    }
}

// MARK: - Animation probe
//
// Samples the PRESENTATION layers of the alert card and the dimming view per
// display-link frame across an animated present and an animated dismiss.
// This is the only way to measure the transition: the alert's own layers
// carry the CAAnimations and `presentation()` is the composited truth.
final class AnimProbe {
    let window: UIWindow
    let hostVC: UIViewController
    var link: CADisplayLink?
    var samples: [[String: Any]] = []
    var t0: CFTimeInterval = 0
    weak var card: UIView?
    weak var dim: UIView?

    init(window: UIWindow, hostVC: UIViewController) {
        self.window = window
        self.hostVC = hostVC
    }

    func findViews() {
        var found: [UIView] = []
        func walk(_ v: UIView) {
            found.append(v)
            for s in v.subviews { walk(s) }
        }
        walk(window)
        card = found.first { NSStringFromClass(type(of: $0)).contains("AlertControllerPhone") }
        dim = found.first {
            NSStringFromClass(type(of: $0)) == "UIView" && $0.superview?.superview === window
                && ($0.backgroundColor?.cgColor.alpha ?? 0) > 0
                && $0.bounds.size == window.bounds.size
        }
    }

    @objc func tick() {
        let t = CACurrentMediaTime() - t0
        var e: [String: Any] = ["t": t]
        if let c = card, let p = c.layer.presentation() {
            let tr = p.transform
            e["cardScaleX"] = Double(tr.m11)
            e["cardScaleY"] = Double(tr.m22)
            e["cardOpacity"] = Double(p.opacity)
            let f = p.frame
            e["cardFrame"] = [Double(f.minX), Double(f.minY), Double(f.width), Double(f.height)]
        }
        if let d = dim, let p = d.layer.presentation() {
            e["dimOpacity"] = Double(p.opacity)
            e["dimAlpha"] = Double(UIColor(cgColor: p.backgroundColor ?? UIColor.clear.cgColor).cgColor.alpha)
        }
        // The card's own layer is never transformed — walk its ancestors so
        // the scale/fade (if any) is found wherever UIKit put it.
        var chain: [[String: Any]] = []
        var v: UIView? = card
        var depth = 0
        while let cur = v, depth < 6 {
            if let p = cur.layer.presentation() {
                chain.append([
                    "class": NSStringFromClass(type(of: cur)),
                    "opacity": Double(p.opacity),
                    "sx": Double(p.transform.m11), "sy": Double(p.transform.m22),
                    "ty": Double(p.transform.m42),
                ])
            }
            v = cur.superview
            depth += 1
        }
        e["chain"] = chain
        samples.append(e)
    }

    func run() {
        let ac = UIAlertController(title: "Animate", message: "Measure the transition.",
                                   preferredStyle: .alert)
        ac.addAction(UIAlertAction(title: "OK", style: .default))
        ac.overrideUserInterfaceStyle = .light
        hostVC.present(ac, animated: true)
        // The layers only exist once the presentation has been committed.
        RunLoop.current.run(until: Date().addingTimeInterval(0.02))
        findViews()
        t0 = CACurrentMediaTime()
        let l = CADisplayLink(target: self, selector: #selector(tick))
        l.add(to: .main, forMode: .common)
        link = l
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        let present = samples
        samples = []
        RunLoop.current.run(until: Date().addingTimeInterval(0.3))
        findViews()
        t0 = CACurrentMediaTime()
        ac.dismiss(animated: true)
        RunLoop.current.run(until: Date().addingTimeInterval(1.2))
        l.invalidate()
        let out: [String: Any] = ["present": present, "dismiss": samples]
        try? JSONSerialization.data(withJSONObject: out, options: [.prettyPrinted])
            .write(to: URL(fileURLWithPath: "\(docsDir)/alert_anim.json"))
        log("anim: \(present.count) present samples, \(samples.count) dismiss samples")
        try? logLines.joined(separator: "\n")
            .write(toFile: docsDir + "/probe_anim.log", atomically: true, encoding: .utf8)
        try? "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { exit(0) }
    }
}

final class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var probe: Probe?
    var animProbe: AnimProbe?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        win.rootViewController = UIViewController()
        win.makeKeyAndVisible()
        let p = Probe(window: win)
        probe = p
        let name = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "list"
        if name == "anim" {
            let host = UIViewController()
            host.view.backgroundColor = .white
            win.rootViewController = host
            let ap = AnimProbe(window: win, hostVC: host)
            animProbe = ap
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { ap.run() }
            return true
        }
        if name == "list" {
            print((configs.map(\.name) + ["anim"]).joined(separator: " "))
            try? (configs.map(\.name) + ["anim"]).joined(separator: " ")
                .write(toFile: docsDir + "/configs.txt", atomically: true, encoding: .utf8)
            try? "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) { exit(0) }
            return true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) { p.run(name) }
        return true
    }
}

DispatchQueue.main.asyncAfter(deadline: .now() + 180) {
    try? "watchdog timeout".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(AppDelegate.self))
