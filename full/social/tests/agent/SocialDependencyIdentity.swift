#if canImport(Accounts)
import Accounts
#endif
import Foundation
@_spi(OpenUIKitHost) import Social
#if canImport(UIKit)
import UIKit
#endif

#if false
import Accounts
import UIKit
#endif

/// Future clean EC2 dependency-identity client. Isolated host-gate success
/// against Social standalone fixtures is not UIKit/Accounts integration.
///
/// Expected EC2 steps (no local Docker):
/// 1. Build staged platform Foundation, UIKit (OpenUIKit implementation),
///    and Accounts modules/dylibs.
/// 2. Build Social with those modules on `-I` / `-L` and no fallback path.
/// 3. Link this file as a client that imports Social, UIKit, and Accounts.
/// 4. Assign `SLComposeServiceViewController` to `UIKit.UIViewController` and
///    `UIKit.UITextViewDelegate`, `textView` to `UIKit.UITextView`, images to
///    `UIKit.UIImage`, and `SLRequest.account` to `Accounts.ACAccount`.
/// 5. Inspect the Social interface/symbol graph for the absence of
///    `Social.UIView*`, `Social.UITextViewDelegate`, and `Social.ACAccount`.
/// 6. Confirm `SOCIAL_DEPENDENCY_IDENTITY_OK` only after those assignments.

func socialDependencyIdentityProbe() {
    #if canImport(UIKit) && canImport(Accounts)
    let controller = SLComposeServiceViewController()
    let _: UIKit.UIViewController = controller
    let _: UIKit.UITextViewDelegate = controller
    let _: UIKit.UITextView = controller.textView
    let _: UIKit.UIView = controller.loadPreviewView()
    let compose = SocialHostControl.makeComposeViewController(serviceType: "identity")
    precondition(compose.add(UIKit.UIImage()))
    let request = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .GET,
        url: URL(string: "https://example.invalid/"),
        parameters: [:]
    )!
    let _: Accounts.ACAccount? = request.account
    #else
    FileHandle.standardError.write(
        Data("UNAVAILABLE dependency=UIKit+Accounts reason=not-staged-on-isolated-host\n".utf8)
    )
    #endif
}

#if SOCIAL_IDENTITY_MAIN
socialDependencyIdentityProbe()
print("SOCIAL_DEPENDENCY_IDENTITY_OK")
#endif
