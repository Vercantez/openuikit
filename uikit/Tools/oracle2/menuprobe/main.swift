// MenuProbe: iOS Simulator MENU oracle (M13 menus & actions cluster).
//
// Sibling of AlertProbe / SheetProbe / SimProbe. A UIMenu presented from a
// UIButton (`showsMenuAsPrimaryAction`) or from a UIContextMenuInteraction is
// drawn by the same private `_UIContextMenu*` chrome, and NONE of it exists
// on Mac Catalyst (Catalyst turns a UIMenu into an AppKit NSMenu), so every
// metric of the iOS menu platter has to come from real iOS UIKit in the
// simulator.
//
// What it measures, per configuration:
//   1. every window in the scene (a context menu may be hosted in a window of
//      its own) with its full private view hierarchy in SCREEN coordinates —
//      platter frame, corner radius, row heights, separators
//   2. every UILabel's text / resolved colour / font family+size+weight
//   3. a snapshot per window, so the platter's blur can be solved as a flat
//      colour over known base colours
//
// Output: <Documents>/menu_<name>.json + menu_<name>_w<i>.png per config,
// plus probe_<name>.log. End-to-end: scripts/menu_probe_sim.sh <outdir>
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

func dumpHierarchy(_ v: UIView, depth: Int = 0,
                   path: String = "", into out: inout [[String: Any]]) {
    // Screen coordinates: the menu may live in a different window than the
    // app's, so window-relative frames would not be comparable.
    let f = v.convert(v.bounds, to: nil)
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
        e["alignment"] = l.textAlignment.rawValue
        if let at = l.attributedText, at.length > 0,
           let fg = at.attribute(.foregroundColor, at: 0, effectiveRange: nil) as? UIColor {
            e["attrColor"] = rgba(fg, l.traitCollection)
        }
    }
    if let ve = v as? UIVisualEffectView {
        e["effect"] = "\(String(describing: ve.effect))"
    }
    if let iv = v as? UIImageView {
        e["hasImage"] = iv.image != nil
    }
    out.append(e)
    for (i, s) in v.subviews.enumerated() {
        dumpHierarchy(s, depth: depth + 1,
                      path: path.isEmpty ? "\(i)" : "\(path).\(i)", into: &out)
    }
}

// MARK: - Configurations

struct MenuItem {
    var title: String
    var subtitle: String? = nil
    var systemImage: String? = nil
    var attributes: UIMenuElement.Attributes = []
    var state: UIMenuElement.State = .off
}

struct MenuConfig {
    var name: String
    var items: [MenuItem] = []
    /// Nested submenu: (title, child titles). Appended after `items`.
    var submenu: (String, [String])? = nil
    /// Inline section appended after `items` (UIMenu.Options.displayInline).
    var inlineSection: [String]? = nil
    var menuTitle: String = ""
    var dark = false
    var base: UIColor = .white
    /// Where the source button sits in the window.
    var buttonOrigin = CGPoint(x: 40, y: 120)
}

let configs: [MenuConfig] = [
    MenuConfig(name: "three_light",
               items: [MenuItem(title: "Copy"), MenuItem(title: "Duplicate"),
                       MenuItem(title: "Delete", attributes: .destructive)]),
    MenuConfig(name: "three_dark",
               items: [MenuItem(title: "Copy"), MenuItem(title: "Duplicate"),
                       MenuItem(title: "Delete", attributes: .destructive)],
               dark: true, base: .black),
    MenuConfig(name: "one_light", items: [MenuItem(title: "Copy")]),
    MenuConfig(name: "titled",
               items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               menuTitle: "Actions"),
    MenuConfig(name: "images",
               items: [MenuItem(title: "Copy", systemImage: "doc.on.doc"),
                       MenuItem(title: "Share", systemImage: "square.and.arrow.up"),
                       MenuItem(title: "Delete", systemImage: "trash",
                                attributes: .destructive)]),
    MenuConfig(name: "state",
               items: [MenuItem(title: "Small", state: .off),
                       MenuItem(title: "Medium", state: .on),
                       MenuItem(title: "Large", state: .off)]),
    MenuConfig(name: "subtitle",
               items: [MenuItem(title: "Copy", subtitle: "Copy this item"),
                       MenuItem(title: "Move", subtitle: "Move elsewhere")]),
    MenuConfig(name: "disabled",
               items: [MenuItem(title: "Copy"),
                       MenuItem(title: "Paste", attributes: .disabled)]),
    MenuConfig(name: "nested",
               items: [MenuItem(title: "Copy")],
               submenu: ("More", ["Alpha", "Beta"])),
    MenuConfig(name: "inline",
               items: [MenuItem(title: "Copy"), MenuItem(title: "Duplicate")],
               inlineSection: ["Delete"]),
    MenuConfig(name: "long",
               items: [MenuItem(title: "A considerably longer menu item title"),
                       MenuItem(title: "Short")]),
    // Blur solving: the same menu over saturated / neutral bases.
    MenuConfig(name: "base_gray", items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               base: UIColor(white: 0.5, alpha: 1)),
    MenuConfig(name: "base_gray25", items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               base: UIColor(white: 0.25, alpha: 1)),
    MenuConfig(name: "base_black", items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               base: .black),
    MenuConfig(name: "dark_base_white", items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               dark: true, base: .white),
    MenuConfig(name: "dark_base_gray", items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               dark: true, base: UIColor(white: 0.5, alpha: 1)),
    MenuConfig(name: "dark_base_gray25", items: [MenuItem(title: "Copy"), MenuItem(title: "Paste")],
               dark: true, base: UIColor(white: 0.25, alpha: 1)),
]

/// Framebuffer captures include SpringBoard's status bar; hiding it makes a
/// `simctl io screenshot` equal to the app window's own content.
final class StatusBarlessViewController: UIViewController {
    override var prefersStatusBarHidden: Bool { true }
}

final class Probe {
    let window: UIWindow
    var hostVC = UIViewController()

    init(window: UIWindow) { self.window = window }

    func snapshot(_ w: UIWindow) -> UIImage {
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 2
        fmt.opaque = false
        return UIGraphicsImageRenderer(size: w.bounds.size, format: fmt).image { _ in
            w.drawHierarchy(in: w.bounds, afterScreenUpdates: true)
        }
    }

    func settle(_ s: TimeInterval = 0.45) {
        RunLoop.current.run(until: Date().addingTimeInterval(s))
    }

    /// ONE configuration per app launch (name in argv[1]) — same isolation
    /// reasoning as AlertProbe: a dismissed presentation's views outlive the
    /// dismissal and the next one stacks on top.
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
        // "hold" keeps the menu on screen so the driver script can grab the
        // DEVICE FRAMEBUFFER (`xcrun simctl io screenshot`) — the only way to
        // see iOS 26's menu platter, which draws in the render server and
        // comes back blank through drawHierarchy (see the file header).
        let hold = CommandLine.arguments.count > 2 && CommandLine.arguments[2] == "hold"
        DispatchQueue.main.asyncAfter(deadline: .now() + (hold ? 25 : 0.2)) { exit(0) }
    }

    func buildMenu(_ c: MenuConfig) -> UIMenu {
        var children: [UIMenuElement] = c.items.map { item in
            let a = UIAction(title: item.title,
                             subtitle: item.subtitle,
                             image: item.systemImage.flatMap { UIImage(systemName: $0) },
                             attributes: item.attributes,
                             state: item.state) { _ in }
            return a
        }
        if let (t, kids) = c.submenu {
            children.append(UIMenu(title: t, children: kids.map { k in
                UIAction(title: k) { _ in }
            }))
        }
        if let inline = c.inlineSection {
            children.append(UIMenu(title: "", options: .displayInline,
                                   children: inline.map { k in UIAction(title: k) { _ in } }))
        }
        return UIMenu(title: c.menuTitle, children: children)
    }

    func runOne(_ c: MenuConfig) {
        let host = StatusBarlessViewController()
        host.view.backgroundColor = c.base
        window.rootViewController = host
        hostVC = host
        window.overrideUserInterfaceStyle = c.dark ? .dark : .light
        settle(0.3)

        let button = UIButton(type: .system)
        button.setTitle("Menu", for: .normal)
        button.frame = CGRect(origin: c.buttonOrigin, size: CGSize(width: 100, height: 44))
        button.menu = buildMenu(c)
        button.showsMenuAsPrimaryAction = true
        host.view.addSubview(button)
        settle(0.3)

        // iOS 17+: fires the primary action, which for a
        // showsMenuAsPrimaryAction button PRESENTS the menu — no touch
        // synthesis needed.
        button.performPrimaryAction()
        // iOS 26 presents the menu behind a "magic morph" animation. Snapshot
        // a LADDER of settle times so a capture that lands mid-animation is
        // visible as such rather than silently becoming the golden.
        for (i, t) in [0.6, 1.0, 2.0].enumerated() {
            settle(t)
            let img = snapshot(window)
            try? img.pngData()!
                .write(to: URL(fileURLWithPath: "\(docsDir)/menu_\(c.name)_t\(i).png"))
        }

        var windows: [[String: Any]] = []
        var idx = 0
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for w in ws.windows {
                var views: [[String: Any]] = []
                dumpHierarchy(w, into: &views)
                windows.append([
                    "index": idx,
                    "class": NSStringFromClass(type(of: w)),
                    "level": Double(w.windowLevel.rawValue),
                    "hidden": w.isHidden,
                    "frame": [Double(w.frame.minX), Double(w.frame.minY),
                              Double(w.frame.width), Double(w.frame.height)],
                    "views": views,
                ])
                let img = snapshot(w)
                try? img.pngData()!
                    .write(to: URL(fileURLWithPath: "\(docsDir)/menu_\(c.name)_w\(idx).png"))
                log("window \(idx) \(NSStringFromClass(type(of: w))): \(views.count) views")
                idx += 1
            }
        }

        let out: [String: Any] = [
            "name": c.name,
            "dark": c.dark,
            "base": rgba(c.base, window.traitCollection),
            "windowSize": [Double(window.bounds.width), Double(window.bounds.height)],
            "safeArea": [Double(window.safeAreaInsets.top), Double(window.safeAreaInsets.left),
                         Double(window.safeAreaInsets.bottom), Double(window.safeAreaInsets.right)],
            "buttonFrame": [Double(button.frame.minX), Double(button.frame.minY),
                            Double(button.frame.width), Double(button.frame.height)],
            "windows": windows,
        ]
        let data = try! JSONSerialization.data(withJSONObject: out,
                                               options: [.prettyPrinted, .sortedKeys])
        try! data.write(to: URL(fileURLWithPath: "\(docsDir)/menu_\(c.name).json"))
        log("probed \(c.name): \(windows.count) windows")
    }
}

final class MenuProbeAppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var probe: Probe?

    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        let win = UIWindow(frame: UIScreen.main.bounds)
        window = win
        win.rootViewController = UIViewController()
        win.makeKeyAndVisible()
        let p = Probe(window: win)
        probe = p
        let name = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "list"
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            if name == "list" {
                try? configs.map(\.name).joined(separator: " ")
                    .write(toFile: docsDir + "/configs.txt", atomically: true, encoding: .utf8)
                try? "ok".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
                exit(0)
            }
            p.run(name)
        }
        return true
    }
}

// Watchdog — never wedge the simulator boot pipeline.
DispatchQueue.main.asyncAfter(deadline: .now() + 120) {
    try? "watchdog timeout".write(toFile: docsDir + "/DONE", atomically: true, encoding: .utf8)
    exit(3)
}

_ = UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil,
                      NSStringFromClass(MenuProbeAppDelegate.self))
