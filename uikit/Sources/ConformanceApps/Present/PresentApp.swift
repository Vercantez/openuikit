// Present — ninth CONFORMANCE APP. Exercises SafariServices, MessageUI and
// LinkPresentation so those modules stay on the board (docs/HILLCLIMB.md).
//
// The same source is compiled twice:
//   * against REAL UIKit + Apple's SafariServices/MessageUI/LinkPresentation,
//     into Tools/oracle2/confprobe;
//   * against OpenUIKit + the port modules, into `openhost --app Present`.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation).
//
// Mail is NOT presented: PresentProbe on iPhone SE 2x / iOS 26.1 measured
// canSendMail() == false and present() hung (~40 s, no completion). Both
// sides skip the compose sheet and show the boolean on the root. Safari
// uses http://127.0.0.1/ (SFSafariViewController rejects data:/file: with
// NSInvalidArgumentException; chrome still paints when the page fails).
import UIKit
import SafariServices
import MessageUI
import LinkPresentation

@MainActor
public enum PresentApp {
    public static let windowSize = CGSize(width: 375, height: 667)

    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let root = PresentRootViewController()
        let nav = UINavigationController(rootViewController: root)
        navigationController = nav
        return nav
    }

    public static func perform(_ action: String) {
        guard let nav = navigationController,
              let root = nav.viewControllers.first as? PresentRootViewController else {
            print("Present: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "present-safari":
            root.presentSafari()
        case "dismiss":
            root.dismissPresented()
        default:
            print("Present: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerPresent: Void = register("Present", windowSize: PresentApp.windowSize, makeRoot: PresentApp.makeRoot, perform: PresentApp.perform, scriptPath: "Sources/ConformanceApps/Present/script.json") }
