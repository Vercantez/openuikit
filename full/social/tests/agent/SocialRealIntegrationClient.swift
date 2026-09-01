import Accounts
import Foundation
import Social
import UIKit

/// Compile-only real-integration client.
///
/// Accepts dependency values by parameter. Does not construct `ACAccount()`
/// or assume any other fake zero-argument dependency initializer.
func assignAccountsAccount(_ request: SLRequest, _ account: Accounts.ACAccount) {
    request.account = account
}

@MainActor
func asUIKitViewController(
    _ controller: SLComposeServiceViewController
) -> UIKit.UIViewController {
    controller
}

@MainActor
func asUIKitTextViewDelegate(
    _ controller: SLComposeServiceViewController
) -> UIKit.UITextViewDelegate {
    controller
}

@MainActor
func asUIKitTextView(_ controller: SLComposeServiceViewController) -> UIKit.UITextView {
    controller.textView
}

@MainActor
func addUIKitImage(_ composer: SLComposeViewController, _ image: UIKit.UIImage) -> Bool {
    composer.add(image)
}

@MainActor
func pushUIKitController(
    _ sheet: SLComposeServiceViewController,
    _ controller: UIKit.UIViewController
) {
    sheet.pushConfigurationViewController(controller)
}

@MainActor
func setAutoCompletion(
    _ sheet: SLComposeServiceViewController,
    _ controller: UIKit.UIViewController
) {
    sheet.autoCompletionViewController = controller
}
