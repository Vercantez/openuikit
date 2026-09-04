// TableEditor — the second CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A plain-style UITableView of subtitle cells with an Edit button: the
// interaction a mail / reminders list has. Named actions drive editing,
// a fade delete, an automatic insert, and a programmatic selection. The
// same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app TableEditor`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/TableEditor/script.json. Captures
// sit at rest after every step and once mid-flight (+0.15 s) for the
// delete and the insert, so a difference is a LAYOUT or RENDER difference
// (or a missing row-animation curve), not a hit-test difference. See
// NavFlowApp.swift for why the interaction is a named action.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation), the same
// device NavFlow uses (status bar hidden, window safe area [0, 0, 0, 0]).
//
// "swipe-actions" is deliberately a no-op: UIKit has no public API that
// reveals a UIContextualAction without a pan gesture, and a synthesised
// touch would compare two hit-test implementations before it compared
// rendering (the same reason NavFlow has no "back-swipe").
import UIKit

/// One row of the editable list. A plain value type, the way a reminders
/// list models its rows.
struct TableEditorItem {
    let title: String
    let subtitle: String
}

@MainActor
public enum TableEditorApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The navigation controller `perform(_:)` drives. Held strongly: the
    /// host's window owns the hierarchy, and this is the harness's handle.
    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let root = TableEditorRootViewController(style: .plain)
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        navigationController = nav
        return nav
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// would reach, so the two replays exercise the app, not the harness.
    public static func perform(_ action: String) {
        guard let nav = navigationController,
              let root = nav.viewControllers.first as? TableEditorRootViewController else {
            print("TableEditor: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "edit":
            root.setTableEditing(true)
        case "delete-row-2":
            root.deleteRow(at: 2)
        case "insert-row-0":
            root.insertRow(at: 0)
        case "select-row-3":
            root.selectRow(at: 3)
        case "swipe-actions":
            // No public UIKit API reveals leading/trailing swipe actions
            // without a pan. Skipped; see the file header.
            break
        case "done":
            root.setTableEditing(false)
        default:
            print("TableEditor: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerTableEditor: Void = register("TableEditor", windowSize: TableEditorApp.windowSize, makeRoot: TableEditorApp.makeRoot, perform: TableEditorApp.perform, scriptPath: "Sources/ConformanceApps/TableEditor/script.json") }
