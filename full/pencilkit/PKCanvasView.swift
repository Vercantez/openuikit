import Foundation

#if canImport(UIKit)
@MainActor
#endif
open class PKCanvasView: PencilKitScrollView {
    public weak var delegate: (any PKCanvasViewDelegate)?
    public var drawing: PKDrawing = PKDrawing() {
        didSet { delegate?.canvasViewDrawingDidChange(self) }
    }
    public var isDrawingEnabled: Bool = true
    public var drawingPolicy: PKCanvasViewDrawingPolicy = .default
    public var isRulerActive: Bool = false
    public var maximumSupportedContentVersion: PKContentVersion = .latest
    public var tool: any PKTool = PKInkingTool(.pen)
    public private(set) var drawingGestureRecognizer: PencilKitGestureRecognizer = PencilKitGestureRecognizer()

    public var allowsFingerDrawing: Bool {
        get { drawingPolicy != .pencilOnly }
        set { drawingPolicy = newValue ? .anyInput : .pencilOnly }
    }

    public override init(frame: CGRect) {
        super.init(frame: frame)
    }
}

#if canImport(UIKit)
@MainActor
#endif
public protocol PKCanvasViewDelegate: PencilKitScrollViewDelegate {
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView)
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView)
    func canvasViewDidFinishRendering(_ canvasView: PKCanvasView)
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView)
}

public extension PKCanvasViewDelegate {
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {}
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {}
    func canvasViewDidFinishRendering(_ canvasView: PKCanvasView) {}
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {}
}
