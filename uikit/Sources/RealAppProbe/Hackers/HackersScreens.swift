// Harness, not app source: the Hackers row of RealAppScreen's table and
// its builder. Compiled into RealAppProbe on every route (SwiftPM and
// the guest builder's Hackers/ glob).

import OpenUIKit
import Shared
import SwiftUI

extension RealAppScreen {
    static let hackersScreenTable: [Screen] = [
        // weiran/Hackers feed (Features/Feed FeedView) at 83016de.
        // Captured on the iPhone 16 @3x (scripts/realapp_probe_sim.sh).
        Screen(name: "realapp_hackers_feed_light", variant: .hackersFeed,
               theme: .light, style: .light, contentSizeCategory: .large,
               presentsSheet: false),
    ]

    /// Hackers presents the feed inside a UINavigationController (the app's
    /// NavigationStack chrome). The capture is that nav+list as the window
    /// root. Sample posts are already on FeedViewModel (LoadingStateManager
    /// seeds [Post] — openrender has no run loop for `.task`).
    static func makeHackersFeedScreen() -> UIViewController {
        let store = HackersNavigationStore()
        let feed = FeedView<HackersNavigationStore>(
            viewModel: FeedViewModel(),
            isSidebar: false,
            whatsNewPanel: nil
        )
        .environment(store)
        let host = UIHostingController(rootView: feed)
        return UINavigationController(rootViewController: host)
    }
}
