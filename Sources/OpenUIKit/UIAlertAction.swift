// UIAlertAction. Owner: viewcontroller module (M12 alerts cluster).
//
// One button in a UIAlertController. Raw style values match real UIKit's
// (`default` 0, `cancel` 1, `destructive` 2 — read straight off
// `UIAlertAction.style.rawValue` by Tools/oracle2/alertprobe).

public final class UIAlertAction {
    public enum Style: Int, Sendable {
        case `default` = 0
        case cancel = 1
        case destructive = 2
    }

    public let title: String?
    public let style: Style
    /// A disabled action still occupies its slot; its title renders dimmed.
    public var isEnabled: Bool = true {
        didSet { onChange?() }
    }

    let handler: ((UIAlertAction) -> Void)?
    /// Set by UIAlertController so `isEnabled` can refresh the button.
    var onChange: (() -> Void)?

    public init(title: String?, style: Style,
                handler: ((UIAlertAction) -> Void)? = nil) {
        self.title = title
        self.style = style
        self.handler = handler
    }

    /// Invoke the action's handler (UIKit calls it AFTER the alert has been
    /// dismissed).
    func _fire() { handler?(self) }
}
