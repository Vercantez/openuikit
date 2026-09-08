import UIKit

// A real window contains a regular-width child split at the requested bounds.
// Each sample owns a fresh controller, so a previous display-mode transition
// cannot become an implicit input to the next width measurement.
@MainActor final class App: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    var host: UIViewController!
    var active: UISplitViewController?
    var samples: [(CGFloat, Int)] = []
    var profile: String { CommandLine.arguments.last ?? "main" }
    var minima: [CGFloat] {
        switch profile {
        case "primary": return [300, 240, 464]
        case "supplementary": return [240, 300, 464]
        case "secondary": return [240, 240, 500]
        default: return [UISplitViewController.automaticDimension, UISplitViewController.automaticDimension, UISplitViewController.automaticDimension]
        }
    }
    var rows: [[String: Any]] = []

    func application(_ application: UIApplication, didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        host = UIViewController()
        window = UIWindow(frame: UIScreen.main.bounds)
        window!.rootViewController = host
        window!.makeKeyAndVisible()
        let widths: [CGFloat]
        switch profile {
        case "boundary": widths = [954.001, 954.24, 954.249, 954.25, 954.251, 954.26, 954.499, 954.5]
        case "primary", "supplementary": widths = [1000, 1014, 1014.24, 1014.25, 1014.5, 1024]
        case "secondary": widths = [980, 990, 990.24, 990.25, 990.5, 1000]
        case "resize": widths = [820, 1180]
        default: widths = [600, 820, 940, 954, 954.5, 960, 1000, 1180, 1366]
        }
        for width in widths { for mode in 0...6 { samples.append((width, mode)) } }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { self.next() }
        return true
    }

    func next() {
        if let active {
            active.willMove(toParent: nil)
            active.view.removeFromSuperview()
            active.removeFromParent()
        }
        guard !samples.isEmpty else {
            let document: [String: Any] = ["os": UIDevice.current.systemVersion, "screen": [UIScreen.main.bounds.width, UIScreen.main.bounds.height], "scale": UIScreen.main.scale, "profile": profile, "samples": rows]
            let data = try! JSONSerialization.data(withJSONObject: document, options: [.prettyPrinted, .sortedKeys])
            try! data.write(to: URL.documentsDirectory.appending(path: "splitwidth.json"))
            exit(0)
        }
        let (width, mode) = samples.removeFirst()
        let split = UISplitViewController(style: .tripleColumn)
        for column in [UISplitViewController.Column.primary, .supplementary, .secondary] {
            let child = UIViewController()
            child.title = "column\(column.rawValue)"
            split.setViewController(child, for: column)
        }
        split.minimumPrimaryColumnWidth = minima[0]
        split.minimumSupplementaryColumnWidth = minima[1]
        split.minimumSecondaryColumnWidth = minima[2]
        split.preferredDisplayMode = UISplitViewController.DisplayMode(rawValue: mode)!
        host.addChild(split)
        host.view.addSubview(split.view)
        split.view.frame = CGRect(x: 0, y: 0, width: width, height: 700)
        split.didMove(toParent: host)
        active = split
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.15) {
            split.view.layoutIfNeeded()
            self.record(split, width: width, requested: mode, phase: "initial")
            if self.profile == "resize" {
                split.view.frame.size.width = width == 820 ? 1180 : 820
                split.view.layoutIfNeeded()
                self.record(split, width: split.view.bounds.width, requested: mode, phase: "resized.immediate")
            }
            split.preferredDisplayMode = .secondaryOnly
            split.preferredDisplayMode = UISplitViewController.DisplayMode(rawValue: mode)!
            split.view.layoutIfNeeded()
            self.record(split, width: width, requested: mode, phase: "mounted.immediate")
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                split.view.layoutIfNeeded()
                self.record(split, width: width, requested: mode, phase: "mounted.settled")
                if self.profile == "resize" {
                    split.view.frame.size.width = width
                    split.view.layoutIfNeeded()
                    self.record(split, width: width, requested: mode, phase: "requested.resized.immediate")
                }
                self.next()
            }
        }
    }

    func record(_ split: UISplitViewController, width: CGFloat, requested mode: Int, phase: String) {
        rows.append([
                "phase": phase, "minima": minima,
                "requestedWidth": width, "boundsWidth": split.view.bounds.width,
                "horizontalSizeClass": split.traitCollection.horizontalSizeClass.rawValue,
                "requestedMode": mode, "preferredMode": split.preferredDisplayMode.rawValue,
                "displayMode": split.displayMode.rawValue, "collapsed": split.isCollapsed,
                "splitBehavior": split.splitBehavior.rawValue, "preferredBehavior": split.preferredSplitBehavior.rawValue,
                "primaryWidth": split.primaryColumnWidth, "supplementaryWidth": split.supplementaryColumnWidth,
                "containers": split.children.map { child -> [String: Any] in
                    let frame = child.view.convert(child.view.bounds, to: split.view)
                    return ["frame": [frame.minX, frame.minY, frame.width, frame.height], "safeArea": [child.view.safeAreaInsets.top, child.view.safeAreaInsets.left, child.view.safeAreaInsets.bottom, child.view.safeAreaInsets.right]]
                }
            ])
    }
}
UIApplicationMain(CommandLine.argc, CommandLine.unsafeArgv, nil, NSStringFromClass(App.self))
