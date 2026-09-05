// Ledger — ninth CONFORMANCE APP (docs/agent_reports/guest-trial.md).
//
// A UINavigationController over an inset-grouped list of transactions whose
// on-screen strings come from the Foundation the guest just gained:
// NumberFormatter (currency, en_US and de_DE), DateFormatter (dateStyle
// .medium), ISO8601DateFormatter (export), DateComponentsFormatter
// (duration), JSONSerialization + UserDefaults (round trip),
// NSRegularExpression (search field), URLSession.data(for:) against a
// 127.0.0.1 socket server the app starts itself.
//
// Same source compiles twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh) — the operator captures this on
//     the iOS simulator after the guest trial;
//   * against OpenUIKit, into `openhost --app Ledger`
//     (Sources/openhost/ConformanceMode.swift).
//
// The first screen is also compiled into RealAppProbe (duplicate sources
// under Sources/RealAppProbe/Ledger*.swift) so `render_full realapp` on
// the arm64 guest emits it as screen 13 (GUEST_REALAPP_SCREENS).
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation), the same
// device NavFlow uses (status bar hidden, window safe area [0, 0, 0, 0]).
import UIKit

@MainActor
public enum LedgerApp {
    public static let windowSize = CGSize(width: 375, height: 667)

    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        UserDefaults.standard.removeObject(forKey: LedgerStore.persistKey)
        let list = LedgerListViewController(style: .insetGrouped)
        let nav = UINavigationController(rootViewController: list)
        navigationController = nav
        return nav
    }

    public static func perform(_ action: String) {
        guard navigationController != nil else {
            print("Ledger: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "push":
            listRoot()?.openItem(at: 0)
        case "done":
            (navigationController?.topViewController as? LedgerDetailViewController)?.done()
        case "focus-search":
            listRoot()?.focusSearch()
        case "type-search":
            listRoot()?.typeSearch()
        case "cancel-search":
            listRoot()?.cancelSearch()
        case "export":
            listRoot()?.presentExport()
        case "confirm-export":
            listRoot()?.confirmExport()
        default:
            print("Ledger: unknown action \"\(action)\"")
        }
    }

    static func listRoot() -> LedgerListViewController? {
        navigationController?.viewControllers.first as? LedgerListViewController
    }
}

extension ConformanceApps { static let _registerLedger: Void = register("Ledger", windowSize: LedgerApp.windowSize, makeRoot: LedgerApp.makeRoot, perform: LedgerApp.perform, scriptPath: "Sources/ConformanceApps/Ledger/script.json") }
