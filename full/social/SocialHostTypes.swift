import Foundation

#if canImport(UIKit)
import UIKit
#elseif canImport(OpenUIKit)
import OpenUIKit
#else
/// Local UIKit stand-ins so this leaf module compiles before central review
/// links the shared OpenUIKit product. These types are not Apple UIKit and
/// implement only the members Social needs to type-check.

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

@MainActor
open class UIImage: NSObject {
    public override init() {
        super.init()
    }
}

@MainActor
open class UITextView: UIView {
    public var text: String = ""
}
#endif

#if canImport(Accounts)
import Accounts
#else
/// Fail-closed stand-in for `Accounts.ACAccount`.
///
/// Social's declared Linux dependencies are Foundation and UIKit only.
/// Assigning this object never authorizes, signs, or sends a request.
open class ACAccount: NSObject {
    public override init() {
        super.init()
    }
}
#endif
