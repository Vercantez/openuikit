// UIAlertAction. Owner: viewcontroller module (M12 alerts cluster).
//
// One button in a UIAlertController. Raw style values match real UIKit's
// (`default` 0, `cancel` 1, `destructive` 2 — read straight off
// `UIAlertAction.style.rawValue` by Tools/oracle2/alertprobe).
//
// NSObject-derived, as in UIKit (UIAlertController.h: `@interface
// UIAlertAction : NSObject <NSCopying>`; MEASURED objcsurfaceprobe
// `## superclasses`), so Objective-C can create actions and pass them to
// `-[UIAlertController addAction:]` (Simplenote: "receiver 'UIAlertAction'
// for class message is a forward declaration"). Equality stays identity.
#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

@preconcurrency @MainActor
public final class UIAlertAction: NSObject {
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
        super.init()
    }

    /// Invoke the action's handler (UIKit calls it AFTER the alert has been
    /// dismissed).
    func _fire() { handler?(self) }
}
