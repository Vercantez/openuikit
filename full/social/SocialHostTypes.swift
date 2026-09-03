import Foundation

#if canImport(UIKit)
import UIKit
#elseif os(Linux) || SOCIAL_STANDALONE_TEST_FIXTURES
// Isolated-host / standalone-unit-fixture types. These compile the sealed
// `test_host.sh` gate, which does not pass `-I` for UIKit. They are **not**
// Apple UIKit identities. A production build that can import UIKit never
// emits `Social.UIView` / `Social.UIViewController` / `Social.UIImage` /
// `Social.UITextView` / `Social.UITextViewDelegate`.
//
// Missing UIKit on a non-Linux host without `-D SOCIAL_STANDALONE_TEST_FIXTURES`
// is a hard dependency blocker (see `#else` below).

@MainActor
open class UIView: NSObject {
    public override init() {
        super.init()
    }
}

@MainActor
open class UIViewController: NSObject {
    public override init() {
        super.init()
    }
}

open class UIImage: NSObject {
    public override init() {
        super.init()
    }
}

@MainActor
public protocol UITextViewDelegate: AnyObject {
    func textViewDidChange(_ textView: UITextView)
}

@MainActor
extension UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {}
}

@MainActor
open class UITextView: UIView {
    open var text: String! = ""
    open weak var delegate: UITextViewDelegate?

    public override init() {
        super.init()
        text = ""
    }
}
#else
#error("Social requires the canonical UIKit module. Isolated host tests: compile with -D SOCIAL_STANDALONE_TEST_FIXTURES")
#endif

#if canImport(Accounts)
import Accounts
#elseif os(Linux) || SOCIAL_STANDALONE_TEST_FIXTURES
// Standalone-unit-fixture `ACAccount`. Not `Accounts.ACAccount`. Production
// that can import Accounts never emits `Social.ACAccount`.

open class ACAccount: NSObject {
    public override init() {
        super.init()
    }
}
#else
#error("Social.SLRequest.account requires the canonical Accounts.ACAccount type")
#endif
