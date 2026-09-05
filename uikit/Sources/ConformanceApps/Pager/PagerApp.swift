// Pager — the seventh CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A UIPageViewController (scroll, horizontal, three coloured pages with a
// centred label and UIPageControl below), a paging UIScrollView of four
// 200 pt cards, a large UIActivityIndicatorView, and a UIRefreshControl
// started at a named frame. Nothing here is a fixture or a scene: the ONLY
// imports are UIKit and (through UIKit's own re-export, exactly as on iOS)
// Foundation.
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe
//     (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app Pager`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/Pager/script.json. Mid-flight
// captures are named 60 Hz frames of the page transition (0/6/12/18), the
// paging `setContentOffset(animated:)` curve (0/8/16/30), and the activity
// indicator at frame 9 after startAnimating (Feed t700 still carries a
// 32 pt² blob from spinner phase). Rest captures sit at least 0.5 s after
// the action that precedes them.
//
// Window: 375 x 667 at scale 2 — the iPhone SE (3rd generation), the same
// device NavFlow uses (status bar hidden, window safe area [0, 0, 0, 0]).
import UIKit

@MainActor
public enum PagerApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The root controller `perform(_:)` drives. Held strongly: the host's
    /// window owns the hierarchy, and this is the harness's handle on it.
    static var root: PagerRootViewController?

    public static func makeRoot() -> UIViewController {
        let root = PagerRootViewController()
        self.root = root
        return root
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// (or flick) would reach, so the two replays exercise the app, not the
    /// harness.
    public static func perform(_ action: String) {
        guard let root else {
            print("Pager: perform(\(action)) before makeRoot()")
            return
        }
        switch action {
        case "page-next":
            root.pageNext()
        case "page-previous":
            root.pagePrevious()
        case "fling":
            root.fling()
        case "spinner-frame-9":
            root.startSpinners()
        default:
            print("Pager: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerPager: Void = register("Pager", windowSize: PagerApp.windowSize, makeRoot: PagerApp.makeRoot, perform: PagerApp.perform, scriptPath: "Sources/ConformanceApps/Pager/script.json") }
