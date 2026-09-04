// Modal — the fifth CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A root screen of buttons that present, in turn, a medium page sheet
// (medium+large detents, grabber), a large sheet, a three-action alert, an
// action sheet, and a phone popover from a bar button item (iOS adapts it
// to a sheet). Nothing here is a fixture or a scene: the ONLY imports are
// UIKit and (through UIKit's own re-export, exactly as on iOS) Foundation.
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app Modal`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/Modal/script.json. Captures sit at
// rest after every present and every dismiss, plus one mid-flight frame
// for the medium sheet at +0.2 s, so a difference is a LAYOUT or RENDER
// difference (or a missing present curve), not a hit-test difference. See
// NavFlowApp.swift for why the interaction is a named action.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation), the same
// device NavFlow uses (status bar hidden, window safe area [0, 0, 0, 0]).
import UIKit

@MainActor
public enum ModalApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The navigation controller `perform(_:)` drives. Held strongly: the
    /// host's window owns the hierarchy, and this is the harness's handle.
    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let root = ModalRootViewController()
        let nav = UINavigationController(rootViewController: root)
        navigationController = nav
        return nav
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// would reach, so the two replays exercise the app, not the harness.
    public static func perform(_ action: String) {
        guard let nav = navigationController,
              let root = nav.viewControllers.first as? ModalRootViewController else {
            print("Modal: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "sheet-medium":
            root.presentMediumSheet()
        case "sheet-large":
            root.presentLargeSheet()
        case "alert":
            root.presentAlert()
        case "action-sheet":
            root.presentActionSheet()
        case "popover":
            root.presentPopover()
        case "dismiss":
            root.dismissPresented()
        default:
            print("Modal: unknown action \"\(action)\"")
        }
    }
}
