// Forms — the third CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A grouped UITableView form written the way a real settings screen is
// written: Auto Layout against each cell's `contentView.layoutMarginsGuide`,
// a UITextField (placeholder, then typed text), a UITextView, a UISwitch,
// a UISlider, a UISegmentedControl, a compact UIDatePicker and a UIStepper.
// Nothing here is a fixture or a scene: the ONLY imports are UIKit and
// (through UIKit's own re-export, exactly as on iOS) Foundation.
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe, run on the iOS 26
//     simulator (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app Forms`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/Forms/script.json and capture at the
// same times, at the same scale, so the difference between the two PNGs is
// the port's, not the harness's. scripts/conformance_flow.sh runs the pair.
//
// Why the interaction is a NAMED ACTION and not a synthesised touch: a
// touch replay would compare two hit-test implementations before it compared
// anything about rendering. `perform(_:)` calls the same app method a tap
// would call, on both sides, so a capture difference is a LAYOUT or RENDER
// difference. "focus-name" is `becomeFirstResponder()` — on the simulator
// that raises the keyboard and the table's content inset changes; that
// settled inset is what the capture is for.
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

@MainActor
public enum FormsApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The navigation controller `perform(_:)` drives. Held strongly: the
    /// host's window owns the hierarchy, and this is the harness's handle on
    /// it (openhost keeps its app delegate the same way).
    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let root = FormsRootViewController(style: .grouped)
        let nav = UINavigationController(rootViewController: root)
        navigationController = nav
        return nav
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// (or key) would reach, so the two replays exercise the app, not the
    /// harness.
    public static func perform(_ action: String) {
        guard let nav = navigationController else {
            print("Forms: perform(\(action)) before makeRoot()")
            return
        }
        guard let form = nav.viewControllers.first as? FormsRootViewController else {
            print("Forms: perform(\(action)) with no form controller")
            return
        }
        switch action {
        case "focus-name":
            form.focusName()
        case "type":
            form.typeName()
        case "toggle":
            form.toggleEnabled()
        case "slide-0.7":
            form.slide(to: 0.7)
        case "segment-2":
            form.selectSegment(2)
        case "blur":
            form.blur()
        default:
            print("Forms: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerForms: Void = register("Forms", windowSize: FormsApp.windowSize, makeRoot: FormsApp.makeRoot, perform: FormsApp.perform, scriptPath: "Sources/ConformanceApps/Forms/script.json") }
