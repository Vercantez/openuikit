// Notes — a small conformance app whose body is a UITextView, so a
// first-responder capture includes the software keyboard (the Forms
// name field and Tabs search field are the other two). Empty body so
// the default alphabetic layout is shift-on / uppercase, matching Forms
// focus-name (kbprobe notes_white_light with existing text was lowercase).
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app Notes`.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation).
import UIKit

@MainActor
public enum NotesApp {
    public static let windowSize = CGSize(width: 375, height: 667)

    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let root = NotesRootViewController()
        let nav = UINavigationController(rootViewController: root)
        navigationController = nav
        return nav
    }

    public static func perform(_ action: String) {
        guard let nav = navigationController,
              let notes = nav.viewControllers.first as? NotesRootViewController else {
            print("Notes: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "focus-body":
            notes.focusBody()
        case "blur":
            notes.blur()
        default:
            print("Notes: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerNotes: Void = register("Notes", windowSize: NotesApp.windowSize, makeRoot: NotesApp.makeRoot, perform: NotesApp.perform, scriptPath: "Sources/ConformanceApps/Notes/script.json") }
