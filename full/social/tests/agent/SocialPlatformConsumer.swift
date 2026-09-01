import Accounts
import Foundation
import Social
import UIKit

func require(_ condition: Bool, _ message: String) {
    if !condition {
        fputs("SOCIAL_PLATFORM_IDENTITY_FAIL: \(message)\n", stderr)
        exit(1)
    }
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

func assignAccountsAccount(_ request: SLRequest, _ account: Accounts.ACAccount) {
    request.account = account
}

await MainActor.run {
    let sheet = SLComposeServiceViewController()
    let uiViewController: UIKit.UIViewController = asUIKitViewController(sheet)
    let uiDelegate: UIKit.UITextViewDelegate = asUIKitTextViewDelegate(sheet)
    let uiTextView: UIKit.UITextView = asUIKitTextView(sheet)
    require(uiViewController === sheet, "service controller is UIKit.UIViewController")
    require(uiDelegate === sheet, "service controller is UIKit.UITextViewDelegate")
    require(uiTextView === sheet.textView, "textView is UIKit.UITextView")

    let composer = SLComposeViewController(forServiceType: SLServiceTypeTwitter)
    require(composer != nil, "compose init")
    guard let composer else { return }
    let image = UIKit.UIImage()
    require(addUIKitImage(composer, image), "add UIKit.UIImage")
    pushUIKitController(sheet, UIKit.UIViewController(nibName: nil, bundle: nil))

    let request = SLRequest(
        forServiceType: SLServiceTypeTwitter,
        requestMethod: .GET,
        url: URL(string: "https://api.example.com/1.1/statuses/home_timeline.json")!,
        parameters: nil
    )
    require(request != nil, "request init")
    guard let request else { return }
    let account = Accounts.ACAccount()
    assignAccountsAccount(request, account)
    require(request.account === account, "account is Accounts.ACAccount")
    require(request.preparedURLRequest() == nil, "account without OAuth signer fails closed")

    print("SOCIAL_PLATFORM_IDENTITY_OK")
}
