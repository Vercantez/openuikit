#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
#error(
    "Social imports the canonical UIKit module; OpenUIKit is only a staged implementation dependency. Stage OpenUIKit as UIKit before compiling Social."
)
#elseif SOCIAL_STANDALONE_TEST_FIXTURES
import Foundation

// standalone-unit-fixture-only
// These nominal UIKit identities exist only when compiling with
// `-D SOCIAL_STANDALONE_TEST_FIXTURES`. They are not production Social ABI.
// Ordinary production compilation without UIKit must fail instead of
// publishing Social.UIView / Social.UIViewController / Social.UIImage /
// Social.UITextView / Social.UITextViewDelegate.

@MainActor
public protocol UITextViewDelegate: AnyObject {
    func textViewDidChange(_ textView: UITextView)
}

@MainActor
public extension UITextViewDelegate {
    func textViewDidChange(_ textView: UITextView) {}
}

@MainActor
open class UIView: NSObject {
    public override init() {
        super.init()
    }
}

@MainActor
open class UIViewController: NSObject {
    public init(nibName: String?, bundle: Bundle?) {
        super.init()
    }
}

open class UIImage: NSObject {
    public override init() {
        super.init()
    }
}

@MainActor
open class UITextView: UIView {
    public weak var delegate: UITextViewDelegate?
    public var text: String = ""
}
#else
#error(
    "Social requires the canonical UIKit module. Missing UIKit is a production dependency blocker. Isolated tests must compile with -D SOCIAL_STANDALONE_TEST_FIXTURES; that dylib is standalone-unit-fixture-only and must not be treated as production Social ABI. Social must never silently acquire UIView, UIViewController, UIImage, UITextView, or UITextViewDelegate."
)
#endif
