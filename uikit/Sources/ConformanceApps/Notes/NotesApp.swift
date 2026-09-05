// Notes — a CONFORMANCE APP written for the Linux-only trial
// (docs/agent_reports/linux-trial.md).
//
// A UITabBarController with two tabs: (1) a notes list (inset-grouped
// UITableView, eight seeded notes, UISearchController, delete alert) whose
// selection pushes a UITextView detail with a Done bar button; (2) a
// settings screen whose UISwitch and UISegmentedControl persist through
// UserDefaults. Nothing here is a fixture or a scene: the ONLY import is
// UIKit (Foundation rides in on UIKit's re-export, exactly as on iOS).
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh) — the operator captures this on
//     the iOS simulator after the Linux trial;
//   * against OpenUIKit, into `openhost --app Notes`
//     (Sources/openhost/ConformanceMode.swift), which this trial runs
//     inside the Linux container with no Mac Swift.
//
// Both replay Sources/ConformanceApps/Notes/script.json. Captures sit at
// rest after every step, so a difference is a LAYOUT or RENDER difference,
// not a hit-test difference. See NavFlowApp.swift for why the interaction
// is a named action.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation), the same
// device NavFlow uses (status bar hidden, window safe area [0, 0, 0, 0]).
import UIKit

/// One seeded note. Title, two-line body, and a timestamp string produced
/// by DateFormatter (dateStyle `.medium`, timeStyle `.short`).
struct NotesItem {
    let title: String
    let body: String
    let timestamp: String
}

@MainActor
public enum NotesApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// Settings keys. Reset + re-registered in `makeRoot()` so a replay
    /// never depends on what an earlier replay left on disk.
    public static let iCloudKey = "Notes.iCloudEnabled"
    public static let sortKey = "Notes.sortIndex"

    /// The tab controller `perform(_:)` drives. Held strongly: the host's
    /// window owns the hierarchy, and this is the harness's handle.
    static var tabBarController: UITabBarController?

    public static func makeRoot() -> UIViewController {
        let defaults = UserDefaults.standard
        defaults.removeObject(forKey: iCloudKey)
        defaults.removeObject(forKey: sortKey)
        defaults.register(defaults: [iCloudKey: false, sortKey: 0])

        let list = NotesListViewController(style: .insetGrouped)
        let listNav = UINavigationController(rootViewController: list)
        listNav.tabBarItem = UITabBarItem(title: "Notes",
                                          image: UIImage(systemName: "note.text"),
                                          tag: 0)

        let settings = NotesSettingsViewController(style: .insetGrouped)
        let settingsNav = UINavigationController(rootViewController: settings)
        settingsNav.tabBarItem = UITabBarItem(title: "Settings",
                                             image: UIImage(systemName: "gear"),
                                             tag: 1)

        let tab = UITabBarController()
        tab.viewControllers = [listNav, settingsNav]
        tabBarController = tab
        return tab
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// (or key) would reach, so the two replays exercise the app, not the
    /// harness.
    public static func perform(_ action: String) {
        guard tabBarController != nil else {
            print("Notes: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "push":
            listRoot()?.openNote(at: 0)
        case "done":
            (listNav()?.topViewController as? NotesDetailViewController)?.done()
        case "focus-body":
            (listNav()?.topViewController as? NotesDetailViewController)?.focusBody()
        case "focus-search":
            listRoot()?.focusSearch()
        case "type-search":
            listRoot()?.typeSearch()
        case "cancel-search":
            listRoot()?.cancelSearch()
        case "select-tab-settings":
            tabBarController?.selectedIndex = 1
        case "select-tab-notes":
            tabBarController?.selectedIndex = 0
        case "toggle":
            settingsRoot()?.toggleICloud()
        case "segment-1":
            settingsRoot()?.selectSegment(1)
        case "delete":
            listRoot()?.presentDeleteAlert()
        case "confirm-delete":
            listRoot()?.confirmDelete()
        default:
            print("Notes: unknown action \"\(action)\"")
        }
    }

    static func listNav() -> UINavigationController? {
        tabBarController?.viewControllers?.first as? UINavigationController
    }

    static func listRoot() -> NotesListViewController? {
        listNav()?.viewControllers.first as? NotesListViewController
    }

    static func settingsRoot() -> NotesSettingsViewController? {
        guard let nav = tabBarController?.viewControllers?[1] as? UINavigationController else {
            return nil
        }
        return nav.viewControllers.first as? NotesSettingsViewController
    }

    /// Format a pinned UTC date the way the spec asks: DateFormatter
    /// dateStyle `.medium`, timeStyle `.short`. Locale `en_US` and GMT so
    /// the string does not depend on the host clock or the container's
    /// LANG. The eight seeds call this once in `makeRoot`'s list.
    ///
    /// Linux finding: this is corelibs-foundation DateFormatter (the
    /// docker ELF path). The arm64-apple-macos guest's port Foundation
    /// has no DateFormatter (docs/AGENT_BRIEF_ORACLE.md); that path is
    /// out of this trial's container.
    static func timestampString(year: Int, month: Int, day: Int,
                                hour: Int, minute: Int) -> String {
        var calendar = Calendar(identifier: .gregorian)
        calendar.locale = Locale(identifier: "en_US_POSIX")
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let date = calendar.date(from: DateComponents(
            calendar: calendar, timeZone: calendar.timeZone,
            year: year, month: month, day: day,
            hour: hour, minute: minute))!
        let formatter = DateFormatter()
        formatter.calendar = calendar
        formatter.locale = Locale(identifier: "en_US")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }

    /// Eight seeded notes. Bodies are two sentences so a 2-line label
    /// wraps; timestamps are the DateFormatter strings above.
    static func seededNotes() -> [NotesItem] {
        [
            NotesItem(title: "Meeting notes",
                      body: "Bring the quarterly slides and the draft agenda.\nRoom 4B after lunch.",
                      timestamp: timestampString(year: 2026, month: 9, day: 4, hour: 10, minute: 30)),
            NotesItem(title: "Grocery list",
                      body: "Oat milk, rye bread, and the sharp cheddar.\nSkip the sparkling water.",
                      timestamp: timestampString(year: 2026, month: 9, day: 3, hour: 16, minute: 5)),
            NotesItem(title: "Weekend hike",
                      body: "Trailhead parking fills by nine on Saturday.\nPack water and the paper map.",
                      timestamp: timestampString(year: 2026, month: 8, day: 30, hour: 8, minute: 15)),
            NotesItem(title: "Project brief",
                      body: "Scope the Linux trial as one conformance app.\nCapture rest frames, not hits.",
                      timestamp: timestampString(year: 2026, month: 9, day: 1, hour: 14, minute: 0)),
            NotesItem(title: "Call recap",
                      body: "Ship the Notes app from the container only.\nOperator grades on the simulator.",
                      timestamp: timestampString(year: 2026, month: 9, day: 2, hour: 11, minute: 45)),
            NotesItem(title: "Reading list",
                      body: "Finish the oracle flow notes this week.\nThen the portability matrix.",
                      timestamp: timestampString(year: 2026, month: 8, day: 28, hour: 19, minute: 20)),
            NotesItem(title: "Travel plan",
                      body: "Train at 7:40, not the later one.\nSeat reservation is already paid.",
                      timestamp: timestampString(year: 2026, month: 8, day: 22, hour: 7, minute: 40)),
            NotesItem(title: "Kitchen ideas",
                      body: "Replace the dull knives before Sunday.\nKeep the cedar board oil nearby.",
                      timestamp: timestampString(year: 2026, month: 8, day: 18, hour: 12, minute: 10)),
        ]
    }
}

extension ConformanceApps { static let _registerNotes: Void = register("Notes", windowSize: NotesApp.windowSize, makeRoot: NotesApp.makeRoot, perform: NotesApp.perform, scriptPath: "Sources/ConformanceApps/Notes/script.json") }
