// UIFontPickerViewController — fail-closed. The system font picker is
// remote UI. Cancel / `_hostCancel()` call `fontPickerViewControllerDidCancel`.
// `_hostPick(descriptor:)` is the only successful-pick path.

#if canImport(CoreGraphics)
import struct CoreFoundation.CGFloat
import struct CoreGraphics.CGPoint
import struct CoreGraphics.CGRect
import struct CoreGraphics.CGSize
#elseif canImport(Foundation)
import Foundation
#endif
#if canImport(Foundation)
import Foundation
import class Foundation.NSObject
#elseif canImport(ObjectiveC)
import class ObjectiveC.NSObject
#endif

@preconcurrency @MainActor
public protocol UIFontPickerViewControllerDelegate: AnyObject {
    func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController)
    func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController)
}

extension UIFontPickerViewControllerDelegate {
    public func fontPickerViewControllerDidCancel(_ viewController: UIFontPickerViewController) {}
    public func fontPickerViewControllerDidPickFont(_ viewController: UIFontPickerViewController) {}
}

@preconcurrency @MainActor
open class UIFontPickerViewController: UIViewController {
    public typealias Configuration = UIFontPickerViewControllerConfiguration

    public let configuration: Configuration
    public weak var delegate: UIFontPickerViewControllerDelegate?
    public var selectedFontDescriptor: UIFontDescriptor?

    private var didFinish = false

    public convenience override init() {
        self.init(configuration: Configuration())
    }

    public init(configuration: Configuration) {
        self.configuration = configuration.copy() as! Configuration
        super.init()
        modalPresentationStyle = .pageSheet
    }

    open override func loadView() {
        let body = _UIUnavailableSystemUIView(
            message: "Font picker is unavailable.",
            cancelTitle: "Cancel")
        body.onCancel = { [weak self] in self?._finishCancelled() }
        view = body
    }

    open override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if !didFinish { _finishCancelled() }
    }

    @_spi(OpenUIKitHost)
    public func _hostCancel() { _finishCancelled() }

    @_spi(OpenUIKitHost)
    public func _hostPick(descriptor: UIFontDescriptor) {
        guard !didFinish else { return }
        didFinish = true
        selectedFontDescriptor = descriptor
        delegate?.fontPickerViewControllerDidPickFont(self)
        if presentingViewController != nil { dismiss(animated: true) }
    }

    private func _finishCancelled() {
        guard !didFinish else { return }
        didFinish = true
        delegate?.fontPickerViewControllerDidCancel(self)
        if presentingViewController != nil { dismiss(animated: true) }
    }
}

@preconcurrency @MainActor
open class UIFontPickerViewControllerConfiguration: NSObject {
    public var includeFaces: Bool = false
    public var displayUsingSystemFont: Bool = false
    public var filteredTraits: UIFontDescriptor.SymbolicTraits = []
    public var filteredLanguagesPredicate: NSPredicate?

    public override init() { super.init() }

    public override func copy() -> Any {
        let copied = UIFontPickerViewControllerConfiguration()
        copied.includeFaces = includeFaces
        copied.displayUsingSystemFont = displayUsingSystemFont
        copied.filteredTraits = filteredTraits
        copied.filteredLanguagesPredicate = filteredLanguagesPredicate
        return copied
    }

    public class func filterPredicate(forFilteredLanguages filteredLanguages: [String]) -> NSPredicate? {
        _ = filteredLanguages
        return nil
    }
}
