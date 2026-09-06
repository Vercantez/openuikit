import Foundation

/// Standard insertion / edit UI for a `PaperMarkupViewController`.
///
/// Linux stores the supported feature set and additional actions. It never
/// presents a markup toolbar, photo picker, or shape palette.
#if canImport(UIKit)
@MainActor
#endif
open class MarkupEditViewController: UIViewController {
    public protocol Delegate: AnyObject {
        func markupEditViewController(
            _ markupEditViewController: MarkupEditViewController,
            insertNewShape type: ShapeConfiguration.Shape
        )
        func markupEditViewController(
            _ markupEditViewController: MarkupEditViewController,
            insertNewContents toInsert: PaperMarkup
        )
        func markupEditViewController(
            _ markupEditViewController: MarkupEditViewController,
            insertNewLineWithStartMarker lineStartMarker: Bool,
            endMarker lineEndMarker: Bool
        )
        func markupEditViewControllerInsertNewTextbox(_ markupEditViewController: MarkupEditViewController)
    }

    /// The supported features of this edit UI.
    public let supportedFeatureSet: FeatureSet

    /// The delegate for responding to user actions.
    public weak var delegate: (any Delegate)?

    let additionalActions: [UIMenuElement]
    private var didLoadView = false

    /// Creates a markup edit view controller.
    public init(supportedFeatureSet: FeatureSet, additionalActions: [UIMenuElement] = []) {
        self.supportedFeatureSet = supportedFeatureSet
        self.additionalActions = additionalActions
#if canImport(UIKit)
        super.init(nibName: nil, bundle: nil)
#else
        super.init()
#endif
    }

    #if canImport(UIKit)
    public required init?(coder: NSCoder) {
        self.supportedFeatureSet = .empty
        self.additionalActions = []
        super.init(coder: coder)
    }
    #endif

    open override func viewDidLoad() {
        super.viewDidLoad()
        didLoadView = true
    }

    var hostDidLoadView: Bool { didLoadView }

    /// Linux test SPI: forwards a shape-insert action. Darwin would emit this
    /// from toolbar chrome that Linux does not present.
    public func hostInsertNewShape(_ type: ShapeConfiguration.Shape) {
        delegate?.markupEditViewController(self, insertNewShape: type)
    }

    /// Linux test SPI: forwards a contents-insert action.
    public func hostInsertNewContents(_ toInsert: PaperMarkup) {
        delegate?.markupEditViewController(self, insertNewContents: toInsert)
    }

    /// Linux test SPI: forwards a line-insert action.
    public func hostInsertNewLine(startMarker: Bool, endMarker: Bool) {
        delegate?.markupEditViewController(
            self,
            insertNewLineWithStartMarker: startMarker,
            endMarker: endMarker
        )
    }

    /// Linux test SPI: forwards a text-box insert action.
    public func hostInsertNewTextbox() {
        delegate?.markupEditViewControllerInsertNewTextbox(self)
    }
}
