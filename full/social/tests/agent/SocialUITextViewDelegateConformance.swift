import UIKit
import Social

@MainActor
enum SocialUITextViewDelegateConformanceTest {
    static func accept(_ delegate: UITextViewDelegate) {
        _ = delegate
    }

    static func prove(_ controller: SLComposeServiceViewController) {
        accept(controller)
        let _: UIKit.UITextViewDelegate = controller
        let _: UIKit.UIViewController = controller
        let _: UIKit.UITextView = controller.textView
    }
}
