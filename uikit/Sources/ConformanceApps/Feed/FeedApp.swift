// Feed — the fourth CONFORMANCE APP (docs/HILLCLIMB.md "What is climbed").
//
// A UICollectionView with a compositional layout: a horizontally scrolling
// "stories" section of 72 pt circles, then a vertical list of cards (16:9
// generated image, title, two-line body), a UIRefreshControl, a section
// header supplementary, and a selection highlight. Nothing here is a
// fixture or a scene: the ONLY imports are UIKit and (through UIKit's own
// re-export, exactly as on iOS) Foundation.
//
// The same source is compiled twice:
//
//   * against REAL UIKit, into Tools/oracle2/confprobe, run on the iOS 26
//     simulator (scripts/conformance_probe_sim.sh);
//   * against OpenUIKit, into `openhost --app Feed`
//     (Sources/openhost/ConformanceMode.swift).
//
// Both replay Sources/ConformanceApps/Feed/script.json and capture at the
// same times, at the same scale, so the difference between the two PNGs is
// the port's, not the harness's. scripts/conformance_flow.sh runs the pair.
//
// Why the interaction is a NAMED ACTION and not a synthesised touch: a
// touch replay would compare two hit-test implementations before it
// compared anything about rendering. `perform(_:)` calls the same app
// method a tap would call, on both sides, so a capture difference is a
// LAYOUT or RENDER difference. "refresh" is `beginRefreshing()` — the
// script captures mid-spin at +0.3 s and again after `endRefreshing()`.
// "scroll-stories" is `scrollToItem` on an orthogonally scrolling section,
// which is the public API that reaches UIKit's nested scroller.
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
public enum FeedApp {
    /// The app's window, on both sides of the comparison (see the header).
    public static let windowSize = CGSize(width: 375, height: 667)

    /// The navigation controller `perform(_:)` drives. Held strongly: the
    /// host's window owns the hierarchy, and this is the harness's handle on
    /// it (openhost keeps its app delegate the same way).
    static var navigationController: UINavigationController?

    public static func makeRoot() -> UIViewController {
        let root = FeedRootViewController()
        let nav = UINavigationController(rootViewController: root)
        nav.navigationBar.prefersLargeTitles = true
        navigationController = nav
        return nav
    }

    /// One scripted step. Every case is the method the corresponding tap
    /// (or pull) would reach, so the two replays exercise the app, not the
    /// harness.
    public static func perform(_ action: String) {
        guard let nav = navigationController else {
            print("Feed: perform(\(action)) before makeRoot()")
            return
        }
        guard let feed = nav.viewControllers.first as? FeedRootViewController else {
            print("Feed: perform(\(action)) with no feed controller")
            return
        }
        switch action {
        case "scroll-300":
            feed.scrollMain(to: 300)
        case "refresh":
            feed.beginFeedRefresh()
        case "end-refresh":
            feed.endFeedRefresh()
        case "select-card-1":
            feed.selectCard(at: 1)
        case "scroll-stories":
            feed.scrollStories()
        default:
            print("Feed: unknown action \"\(action)\"")
        }
    }
}

extension ConformanceApps { static let _registerFeed: Void = register("Feed", windowSize: FeedApp.windowSize, makeRoot: FeedApp.makeRoot, perform: FeedApp.perform, scriptPath: "Sources/ConformanceApps/Feed/script.json") }
