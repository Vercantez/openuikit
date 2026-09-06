import Foundation

/// A view controller for interactively creating, and showing markup.
///
/// Linux keeps documented defaults and in-memory selection / viewport state.
/// It does not present Pencil chrome, host a scroll view, or rasterize
/// markup. Touch routing, "Draw with Finger", and ruler geometry stay
/// fail-closed.
#if canImport(UIKit)
@MainActor
#endif
open class PaperMarkupViewController: UIViewController {
    /// The canvas behavior for touches.
    public enum TouchMode: Equatable, Hashable, Sendable {
        /// Select strokes/elements on a canvas.
        case selection
        /// Draw with the PencilKit tool.
        case drawing
    }

    public protocol Delegate: AnyObject {
        /// Tells the delegate when the markup changes.
        func paperMarkupViewControllerDidChangeMarkup(_ paperMarkupViewController: PaperMarkupViewController)
        /// Tells the delegate when the selection changes.
        func paperMarkupViewControllerDidChangeSelection(_ paperMarkupViewController: PaperMarkupViewController)
        /// Called when the user starts drawing.
        func paperMarkupViewControllerDidBeginDrawing(_ paperMarkupViewController: PaperMarkupViewController)
        /// Tells the delegate when the user scrolls or zooms the content.
        func paperMarkupViewControllerDidChangeContentVisibleFrame(_ paperMarkupViewController: PaperMarkupViewController)
    }

    /// The delegate for responding to user actions.
    public weak var delegate: (any Delegate)?

    /// The paper data shown in this view controller.
    public var markup: PaperMarkup? {
        didSet {
            if let markup {
                if contentVisibleFrame == .null || contentVisibleFrame == .zero {
                    contentVisibleFrame = markup.bounds
                }
            }
            delegate?.paperMarkupViewControllerDidChangeMarkup(self)
        }
    }

    /// The supported PaperKit features on this canvas.
    public private(set) var supportedFeatureSet: FeatureSet

    /// The content that markup happens on top of.
    ///
    /// Default is `nil`.
    public var contentView: UIView?

    /// A Boolean value that indicates whether the contents of the canvas is
    /// editable.
    ///
    /// The default value is `true`.
    public var isEditable: Bool = true

    /// The tool used to draw on the canvas.
    ///
    /// Default is `PKInkingTool(.pen)`.
    public var drawingTool: any PKTool = PKInkingTool(.pen)

    /// The interaction mode for direct touches on the canvas.
    ///
    /// Default is `.selection`.
    public var directTouchMode: TouchMode = .selection

    /// A Boolean value that indicates that direct touches should automatically
    /// draw based on system state.
    ///
    /// Default is `true`. Linux never reads the Darwin "Draw with Finger"
    /// setting.
    public var directTouchAutomaticallyDraws: Bool = true

    /// The interaction mode for indirect pointer touches on the canvas.
    ///
    /// Default is `.selection`.
    public var indirectPointerTouchMode: TouchMode = .selection

    /// The selected contents in the UI.
    public var selectedMarkup: PaperMarkup = PaperMarkup(bounds: .zero) {
        didSet {
            delegate?.paperMarkupViewControllerDidChangeSelection(self)
        }
    }

    /// A Boolean value that indicates whether a ruler view is visible on the
    /// canvas.
    ///
    /// Linux stores the flag and never shows ruler chrome.
    public var isRulerActive: Bool = false

    /// A Boolean value that controls whether the vertical scroll indicator is
    /// visible.
    ///
    /// Default is `true`.
    public var showsVerticalScrollIndicator: Bool = true

    /// A Boolean value that controls whether the horizontal scroll indicator
    /// is visible.
    ///
    /// Default is `true`.
    public var showsHorizontalScrollIndicator: Bool = true

    /// The visible area of content in the scroll view.
    public var contentVisibleFrame: CGRect = .zero {
        didSet {
            delegate?.paperMarkupViewControllerDidChangeContentVisibleFrame(self)
        }
    }

    /// A floating-point range that specifies the minimum and maximum scale
    /// factor that can apply to the canvas' content.
    ///
    /// The default value is `1.0...1.0`.
    public var zoomRange: ClosedRange<CGFloat> = 1.0...1.0

    private var hostedUndoManager: UndoManager = UndoManager()
    private var didLoadView = false

    /// Create a new `PaperMarkupViewController` with the provided data model.
    public init(markup: PaperMarkup? = nil, supportedFeatureSet: FeatureSet) {
        self.markup = markup
        self.supportedFeatureSet = supportedFeatureSet
        if let markup {
            self.contentVisibleFrame = markup.bounds
        }
#if canImport(UIKit)
        super.init(nibName: nil, bundle: nil)
#else
        super.init()
#endif
    }

    #if canImport(UIKit)
    public required init?(coder: NSCoder) {
        self.supportedFeatureSet = .empty
        super.init(coder: coder)
    }
    #endif

    open override var canBecomeFirstResponder: Bool { true }

    open override var undoManager: UndoManager? { hostedUndoManager }

    open override func viewDidLoad() {
        super.viewDidLoad()
        didLoadView = true
    }

    /// The frame that should be used for inserting shapes and other content.
    ///
    /// Linux centers `frame.size` inside `contentVisibleFrame` when that
    /// viewport is non-empty; otherwise it returns `frame` unchanged. Apple's
    /// exact placement relative to selection is an oracle question.
    public func suggestedFrameForInserting(contentInFrame frame: CGRect) -> CGRect {
        let viewport = contentVisibleFrame
        if viewport.isNull || viewport.isEmpty {
            return frame
        }
        let origin = CGPoint(
            x: viewport.midX - frame.width / 2,
            y: viewport.midY - frame.height / 2
        )
        return CGRect(origin: origin, size: frame.size)
    }

    /// Zooms to a specific area of the content so that it’s visible in the
    /// scroll view.
    ///
    /// Linux assigns `contentVisibleFrame` immediately. `animated` is
    /// recorded as a no-op: there is no scroll view to animate.
    public func setContentVisibleFrame(_ rect: CGRect, animated: Bool) {
        _ = animated
        contentVisibleFrame = rect
    }

    public func toolPickerSelectedToolItemDidChange(_ toolPicker: PKToolPicker) {
        drawingTool = toolPicker.selectedTool
    }

    public func toolPickerIsRulerActiveDidChange(_ toolPicker: PKToolPicker) {
        isRulerActive = toolPicker.isRulerActive
    }

    var hostDidLoadView: Bool { didLoadView }
}
