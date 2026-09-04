// NavFlow — the first CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A small UIKit app written the way a real app is written: a
// UINavigationController with large titles, a grouped UITableViewController
// built from a data source, an Auto Layout detail screen whose UISwitch is
// bound to UserDefaults, and a modal sheet raised from a bar button. Nothing
// here is a fixture or a scene: the ONLY imports are UIKit and (through
// UIKit's own re-export, exactly as on iOS) Foundation.
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe, run on the iOS 26
//     simulator (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app NavFlow`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/NavFlow/script.json and capture at the
// same times, at the same scale, so the difference between the two PNGs is
// the port's, not the harness's. scripts/conformance_flow.sh runs the pair.
//
// Why the interaction is a NAMED ACTION and not a synthesised touch: a
// touch replay would compare two hit-test implementations before it compared
// anything about rendering, and the iOS side would need private UITouch
// spelunking (Tools/oracle2/scrollshared.swift) that the portable side has no
// counterpart for. `perform(_:)` calls the same app method a tap would call,
// on both sides, so a capture difference is a LAYOUT or RENDER difference.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation) point size.
// The SE is the only device in the fleet whose window safe area is entirely
// removable (no notch, no home indicator: the 20 pt status-bar inset goes to
// zero with UIStatusBarHidden), and OpenUIKit's UIWindow has no safe area at
// all, so this is the one device on which the two windows are the same
// window. Measured 2026-09-04 by confprobe's own dump: windowSafeArea
// [0, 0, 0, 0]. It is also the 2x device docs/ORACLE_FLOW.md's capture
// hazards require for a scale-2 capture.
import UIKit

/// One row of the root list. A plain value type built by the data source,
/// the way an app models a settings list.
struct NavFlowItem {
    let title: String
    let detail: String
    let body: String
}

@MainActor
public enum NavFlowApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The switch on the detail screen persists here, like a real settings
    /// screen. Reset + re-registered in `makeRoot()` so a replay never
    /// depends on what an earlier replay left on disk.
    public static let notificationsKey = "NavFlow.notificationsEnabled"

    /// The navigation controller `perform(_:)` drives. Held strongly: the
    /// host's window owns the hierarchy, and this is the harness's handle on
    /// it (openhost keeps its app delegate the same way).
    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: notificationsKey)
        defaults.register(defaults: [notificationsKey: false])

        let root = NavFlowRootViewController(style: .insetGrouped)
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        navigationController = nav
        return nav
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// would reach, so the two replays exercise the app, not the harness.
    ///
    /// "back-swipe" is deliberately absent: an interactive pop is a gesture
    /// recogniser reading real touches, and neither UIKit nor OpenUIKit
    /// exposes a way to drive one that means the same thing on both sides
    /// (see REPORT.md, open questions).
    public static func perform(_ action: String) {
        guard let nav = navigationController else {
            print("NavFlow: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "present":
            (nav.viewControllers.first as? NavFlowRootViewController)?.showFilters()
        case "dismiss":
            nav.viewControllers.first?.dismiss(animated: true, completion: nil)
        case "push":
            (nav.viewControllers.first as? NavFlowRootViewController)?
                .openItem(at: IndexPath(row: 0, section: 0))
        case "toggle":
            (nav.topViewController as? NavFlowDetailViewController)?.toggleNotifications()
        case "pop":
            nav.popViewController(animated: true)
        default:
            print("NavFlow: unknown action \"\(action)\"")
        }
    }
}
