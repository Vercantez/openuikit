import Foundation
import SharedWithYou

#if canImport(UIKit)
import UIKit
#endif
#if false
import UIKit
#endif

/// Future clean EC2 dependency-identity client. Isolated host-gate success
/// against toolchain Foundation is not integrated guest UIKit success.
///
/// Expected EC2 steps (no local Docker):
/// 1. Build staged platform Foundation and UIKit modules/dylibs.
/// 2. Build SharedWithYou with those modules on `-I` / `-L` and no lookalikes.
/// 3. Link this file as a client that imports SharedWithYou, Foundation, and UIKit.
/// 4. Assign `SWAttributionView` / `SWCollaborationView` to `UIKit.UIView`,
///    `headerImage` to `UIKit.UIImage`, and pass `Foundation.URL` into
///    `SWHighlightCenter.getHighlightFor`.
/// 5. Confirm `SHAREDWITHYOU_DEPENDENCY_IDENTITY_OK` only after those assignments.

enum SharedWithYouDependencyIdentity {
    static func main() {
        let url = URL(string: "https://example.invalid/shared/identity")!
        let center = SWHighlightCenter()
        var seenURL: URL?
        center.getHighlightFor(url) { _, _ in
            seenURL = url
        }
        if seenURL != url {
            fatalError("getHighlightFor did not preserve Foundation.URL")
        }

        let eventURL = URL(string: "https://example.invalid/shared/event")!
        _ = eventURL
        let _: String = SWCollaborationMetadataTypeIdentifier
        let _: String = SWHighlightCenter.highlightCollectionTitle

        #if canImport(UIKit)
        let attribution = SWAttributionView()
        let _: UIKit.UIView = attribution
        let collaboration = SWCollaborationView(itemProvider: NSItemProvider())
        let _: UIKit.UIView = collaboration
        let _: UIKit.UIImage = collaboration.headerImage
        let _: UIKit.UIMenu = attribution.highlightMenu
        #endif

        print("SHAREDWITHYOU_DEPENDENCY_IDENTITY_OK foundation=URL")
    }
}

SharedWithYouDependencyIdentity.main()
