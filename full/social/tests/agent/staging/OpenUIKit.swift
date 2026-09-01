import Foundation

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
