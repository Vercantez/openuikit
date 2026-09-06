// UIAccessibilityCustomAction / UIAccessibilityCustomRotor — storage for
// assistive-technology actions. OpenUIKit has no VoiceOver; these types
// exist so corpus apps compile and round-trip the values they set.
//
// MEASURED ValuesProbe, iPhone SE 3rd gen / iOS 26.1
// (`OpenUIKit-2x-uikit-tail-values`):
//   `name` and `attributedName.string` stay in lockstep: setting either
//   rewrites the other (Delete → Erase via attributedName, Erase → Wipe
//   via name).
//   Handler-form `actionHandler` is non-nil; `category` defaults to nil;
//   `UIAccessibilityCustomAction.editCategory` is the iOS 18 constant.
//   Rotor `systemRotorType` defaults to `.none` (rawValue 0); name and
//   attributedName lockstep the same way.
//   `UIView.accessibilityCustomActions` / `accessibilityCustomRotors`
//   store the array they were given.

#if canImport(Foundation)
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

public let UIAccessibilityCustomActionCategoryEdit =
    "UIAccessibilityCustomActionCategoryEdit"

@preconcurrency @MainActor
open class UIAccessibilityCustomAction: NSObject {
    public typealias Handler = (UIAccessibilityCustomAction) -> Bool

    private var _name: String
    private var _attributedName: NSAttributedString
    open var image: UIImage?
    public weak var target: AnyObject?
    open var selector: Selector
    open var actionHandler: Handler?
    open var category: String?

    open var name: String {
        get { _name }
        set {
            _name = newValue
            _attributedName = NSAttributedString(string: newValue)
        }
    }

    open var attributedName: NSAttributedString {
        get { _attributedName }
        set {
            _attributedName = newValue
            _name = newValue.string
        }
    }

    public init(name: String, target: AnyObject?, selector: Selector) {
        _name = name
        _attributedName = NSAttributedString(string: name)
        self.target = target
        self.selector = selector
        super.init()
    }

    public init(attributedName: NSAttributedString, target: AnyObject?,
                selector: Selector) {
        _name = attributedName.string
        _attributedName = attributedName
        self.target = target
        self.selector = selector
        super.init()
    }

    public init(name: String, image: UIImage?, target: AnyObject?,
                selector: Selector) {
        _name = name
        _attributedName = NSAttributedString(string: name)
        self.image = image
        self.target = target
        self.selector = selector
        super.init()
    }

    public init(attributedName: NSAttributedString, image: UIImage?,
                target: AnyObject?, selector: Selector) {
        _name = attributedName.string
        _attributedName = attributedName
        self.image = image
        self.target = target
        self.selector = selector
        super.init()
    }

    public init(name: String, actionHandler: @escaping Handler) {
        _name = name
        _attributedName = NSAttributedString(string: name)
        self.selector = Selector.named("")
        self.actionHandler = actionHandler
        super.init()
    }

    public init(attributedName: NSAttributedString,
                actionHandler: @escaping Handler) {
        _name = attributedName.string
        _attributedName = attributedName
        self.selector = Selector.named("")
        self.actionHandler = actionHandler
        super.init()
    }

    public init(name: String, image: UIImage?,
                actionHandler: @escaping Handler) {
        _name = name
        _attributedName = NSAttributedString(string: name)
        self.image = image
        self.selector = Selector.named("")
        self.actionHandler = actionHandler
        super.init()
    }

    public init(attributedName: NSAttributedString, image: UIImage?,
                actionHandler: @escaping Handler) {
        _name = attributedName.string
        _attributedName = attributedName
        self.image = image
        self.selector = Selector.named("")
        self.actionHandler = actionHandler
        super.init()
    }

    /// Perform the handler if one is set, otherwise the target/selector.
    /// Handler is preferred (UIAccessibilityCustomAction.h).
    @discardableResult
    open func perform() -> Bool {
        if let actionHandler { return actionHandler(self) }
        guard let target else { return false }
        return SelectorDispatch.trySend(selector, to: target, sender: self)
    }
}

extension UIAccessibilityCustomAction {
    public static let editCategory = UIAccessibilityCustomActionCategoryEdit
}

public enum UIAccessibilityCustomRotorDirection: Int, Sendable {
    case previous = 0
    case next = 1
}

public enum UIAccessibilityCustomSystemRotorType: Int, Sendable {
    case none = 0
    case link = 1
    case visitedLink = 2
    case heading = 3
    case headingLevel1 = 4
    case headingLevel2 = 5
    case headingLevel3 = 6
    case headingLevel4 = 7
    case headingLevel5 = 8
    case headingLevel6 = 9
    case boldText = 10
    case italicText = 11
    case underlineText = 12
    case misspelledWord = 13
    case image = 14
    case textField = 15
    case table = 16
    case list = 17
    case landmark = 18
}

@preconcurrency @MainActor
open class UIAccessibilityCustomRotorItemResult: NSObject {
    public weak var targetElement: AnyObject?
    public var targetRange: UITextRange?

    public init(targetElement: AnyObject, targetRange: UITextRange?) {
        self.targetElement = targetElement
        self.targetRange = targetRange
        super.init()
    }
}

@preconcurrency @MainActor
open class UIAccessibilityCustomRotorSearchPredicate: NSObject {
    public var currentItem: UIAccessibilityCustomRotorItemResult
    public var searchDirection: UIAccessibilityCustomRotorDirection

    public init(currentItem: UIAccessibilityCustomRotorItemResult,
                searchDirection: UIAccessibilityCustomRotorDirection) {
        self.currentItem = currentItem
        self.searchDirection = searchDirection
        super.init()
    }
}

@preconcurrency @MainActor
open class UIAccessibilityCustomRotor: NSObject {
    public typealias Search = (UIAccessibilityCustomRotorSearchPredicate)
        -> UIAccessibilityCustomRotorItemResult?

    private var _name: String
    private var _attributedName: NSAttributedString
    open var itemSearchBlock: Search
    public private(set) var systemRotorType: UIAccessibilityCustomSystemRotorType

    open var name: String {
        get { _name }
        set {
            _name = newValue
            _attributedName = NSAttributedString(string: newValue)
        }
    }

    open var attributedName: NSAttributedString {
        get { _attributedName }
        set {
            _attributedName = newValue
            _name = newValue.string
        }
    }

    public init(name: String, itemSearchBlock: @escaping Search) {
        _name = name
        _attributedName = NSAttributedString(string: name)
        self.itemSearchBlock = itemSearchBlock
        self.systemRotorType = .none
        super.init()
    }

    public init(attributedName: NSAttributedString,
                itemSearchBlock: @escaping Search) {
        _name = attributedName.string
        _attributedName = attributedName
        self.itemSearchBlock = itemSearchBlock
        self.systemRotorType = .none
        super.init()
    }

    public init(systemType: UIAccessibilityCustomSystemRotorType,
                itemSearchBlock: @escaping Search) {
        _name = ""
        _attributedName = NSAttributedString(string: "")
        self.itemSearchBlock = itemSearchBlock
        self.systemRotorType = systemType
        super.init()
    }
}
