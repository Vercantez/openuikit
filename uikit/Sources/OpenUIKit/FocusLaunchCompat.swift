// UIKit surfaces named by mozilla-mobile/focus-ios Blockzilla a2832521
// that the portable core did not yet export. Each type or member is a
// compile-time name from that target (MEASURED `swift build --target
// Blockzilla` 2026-09-06, 139 unique diagnostics / 129 sources). Fail-closed:
// drag/drop, print, and the old UIMenuController never present chrome.

#if canImport(Foundation)
import Foundation
#endif

// MARK: - Core Animation 3D (SplashViewController.swift:116)

public struct CATransform3D: Equatable, Sendable {
    public var m11: CGFloat = 1, m12: CGFloat = 0, m13: CGFloat = 0, m14: CGFloat = 0
    public var m21: CGFloat = 0, m22: CGFloat = 1, m23: CGFloat = 0, m24: CGFloat = 0
    public var m31: CGFloat = 0, m32: CGFloat = 0, m33: CGFloat = 1, m34: CGFloat = 0
    public var m41: CGFloat = 0, m42: CGFloat = 0, m43: CGFloat = 0, m44: CGFloat = 1
    public static let identity = CATransform3D()
}

public func CATransform3DMakeScale(_ sx: CGFloat, _ sy: CGFloat, _ sz: CGFloat) -> CATransform3D {
    var t = CATransform3D.identity
    t.m11 = sx
    t.m22 = sy
    t.m33 = sz
    return t
}

// MARK: - Empty constraint / progress style

extension NSLayoutConstraint {
    /// Focus SearchSuggestionsPromptView.swift:16 `= NSLayoutConstraint()`.
    /// The object is replaced before activation (same file:131).
    public convenience init() {
        self.init(
            item: UIView(),
            attribute: .notAnAttribute,
            relatedBy: .equal,
            toItem: nil,
            attribute: .notAnAttribute,
            multiplier: 1,
            constant: 0
        )
    }
}

extension UIProgressView {
    public enum Style: Int, Sendable {
        case `default` = 0
        case bar = 1
    }

    /// GradientProgressBar(progressViewStyle: .bar) — URLBar.swift:179.
    public convenience init(progressViewStyle style: Style) {
        self.init(frame: .zero)
        _ = style
    }
}

// MARK: - Edit menu (URLBar.swift:687)

@preconcurrency @MainActor
open class UIMenuItem: NSObject {
    public var title: String
    public var action: Selector
    public init(title: String, action: Selector) {
        self.title = title
        self.action = action
        super.init()
    }
}

@preconcurrency @MainActor
open class UIMenuController: NSObject {
    public static let shared = UIMenuController()
    public var menuItems: [UIMenuItem]?
    public var isMenuVisible = false
    public func showMenu(from view: UIView, rect: CGRect) {
        _ = (view, rect)
        isMenuVisible = true
    }
    public func hideMenu() { isMenuVisible = false }
}

// MARK: - Drag and drop (URLBar.swift:1134, BrowserViewController.swift:275)

@preconcurrency @MainActor
public protocol UIDragSession: AnyObject {}
@preconcurrency @MainActor
public protocol UIDropSession: AnyObject {
    func canLoadObjects<T>(ofClass aClass: T.Type) -> Bool
    func loadObjects<T>(ofClass aClass: T.Type, completion: @escaping ([T]) -> Void)
}

@preconcurrency @MainActor
open class UIDragItem: NSObject {
    public var localObject: Any?
#if os(Linux)
    public init(itemProvider: Any) {
        _ = itemProvider
        super.init()
    }
#else
    public init(itemProvider: NSItemProvider) {
        _ = itemProvider
        super.init()
    }
#endif
}

@preconcurrency @MainActor
open class UIDragInteraction: NSObject {
    public weak var delegate: UIDragInteractionDelegate?
    public init(delegate: UIDragInteractionDelegate) {
        self.delegate = delegate
        super.init()
    }
}

@preconcurrency @MainActor
public protocol UIDragInteractionDelegate: AnyObject {
    func dragInteraction(_ interaction: UIDragInteraction, itemsForBeginning session: UIDragSession) -> [UIDragItem]
}

@preconcurrency @MainActor
open class UIDropProposal: NSObject {
    public enum Operation: Int, Sendable {
        case cancel = 0
        case forbidden = 1
        case copy = 2
        case move = 3
    }
    public let operation: Operation
    public init(operation: Operation) {
        self.operation = operation
        super.init()
    }
}

@preconcurrency @MainActor
open class UIDropInteraction: NSObject {
    public weak var delegate: UIDropInteractionDelegate?
    public init(delegate: UIDropInteractionDelegate) {
        self.delegate = delegate
        super.init()
    }
}

@preconcurrency @MainActor
public protocol UIDropInteractionDelegate: AnyObject {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession)
}

public extension UIDropInteractionDelegate {
    func dropInteraction(_ interaction: UIDropInteraction, canHandle session: UIDropSession) -> Bool {
        _ = (interaction, session)
        return false
    }
    func dropInteraction(_ interaction: UIDropInteraction, sessionDidUpdate session: UIDropSession) -> UIDropProposal {
        _ = (interaction, session)
        return UIDropProposal(operation: .cancel)
    }
    func dropInteraction(_ interaction: UIDropInteraction, performDrop session: UIDropSession) {
        _ = (interaction, session)
    }
}

extension UIView {
    public func addInteraction(_ interaction: UIDragInteraction) { _ = interaction }
    public func addInteraction(_ interaction: UIDropInteraction) { _ = interaction }
}

// MARK: - Share / print (TitleActivityItemProvider, OpenUtils)

@preconcurrency @MainActor
open class UIActivityItemProvider: UIActivity {
    open var placeholderItem: Any?
    public init(placeholderItem: Any) {
        self.placeholderItem = placeholderItem
        super.init()
    }
    open var item: Any { placeholderItem as Any }
    open func activityViewController(
        _ activityViewController: UIActivityViewController,
        subjectForActivityType activityType: UIActivity.ActivityType?
    ) -> String {
        _ = (activityViewController, activityType)
        return placeholderItem as? String ?? ""
    }
}

@preconcurrency @MainActor
open class UIPrintFormatter: NSObject {}

@preconcurrency @MainActor
open class UIPrintPageRenderer: NSObject {
    public override init() { super.init() }
    open func addPrintFormatter(_ formatter: UIPrintFormatter, startingAtPageAt pageIndex: Int) {
        _ = (formatter, pageIndex)
    }
}

@preconcurrency @MainActor
open class UIPrintInfo: NSObject {
    public enum OutputType: Int, Sendable {
        case general = 0
        case photo = 1
        case grayscale = 2
        case photoGrayscale = 3
    }
    public var jobName: String = ""
    public var outputType: OutputType = .general
    public init(dictionary: [AnyHashable: Any]?) {
        _ = dictionary
        super.init()
    }
}

extension UIView {
    open func viewPrintFormatter() -> UIPrintFormatter { UIPrintFormatter() }
}

// MARK: - Keyboard / HID (FindInPageBar.swift:152, KeyboardType.swift:23)

extension UIKeyEventKey {
    /// UIKit HID usage names Focus switches on. Mapped onto the portable
    /// editing-key enum rather than inventing a second HID table.
    public var keyCode: UIKeyEventKey { self }
    public static let keyboardEscape = UIKeyEventKey.backspace
}

extension UIApplication {
    /// Focus KeyboardType.swift:23. No keyboard list on this host.
    public static var textInputMode: UITextInputMode? {
        UITextInputMode.activeInputModes.first
    }
}

#if canImport(Foundation)
extension NSValue {
    /// KeyboardHelper.swift:34. Foundation's NSValue has cgRectValue on
    /// Darwin; this overlay covers the OpenUIKit-visible NSValue spelling.
    public var cgRectValue: CGRect {
        (self as? NSNumber).map { _ in .zero } ?? .zero
    }
}
#endif

#if !os(Linux)
/// Darwin OpenUIKit does not compile NSStringDrawing.swift (that file is
/// Linux / Foundation-hidden). Focus AutocompleteTextField.swift:250 names
/// these UIKit types. MEASURED Blockzilla 2026-09-06.
public struct NSStringDrawingOptions: OptionSet, Hashable, Sendable {
    public let rawValue: UInt
    public init(rawValue: UInt) { self.rawValue = rawValue }
    public static let usesLineFragmentOrigin = NSStringDrawingOptions(rawValue: 1 << 0)
    public static let usesFontLeading = NSStringDrawingOptions(rawValue: 1 << 1)
    public static let usesDeviceMetrics = NSStringDrawingOptions(rawValue: 1 << 3)
    public static let truncatesLastVisibleLine = NSStringDrawingOptions(rawValue: 1 << 5)
}

public final class NSStringDrawingContext: @unchecked Sendable {
    public init() {}
}
#endif

extension NSAttributedString {
    /// AutocompleteTextField.swift:250. Width of the typed prefix.
    public func boundingRect(
        with size: CGSize,
        options: NSStringDrawingOptions,
        context: NSStringDrawingContext?
    ) -> CGRect {
        _ = (options, context)
        let font: UIFont
        if length > 0, let value = attributes(at: 0, effectiveRange: nil)[.font] as? UIFont {
            font = value
        } else {
            font = .systemFont(ofSize: 17)
        }
        let w = FontEngine.measure(string, font: font)
        let h = FontEngine.labelLineHeight(for: font)
        return CGRect(x: 0, y: 0, width: min(size.width, w), height: min(size.height, h))
    }
}
