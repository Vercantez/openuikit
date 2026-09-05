import PencilKit
import Foundation

final class CanvasProbe: PKCanvasViewDelegate {
    var changes = 0
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        changes += 1
    }
    func canvasViewDidBeginUsingTool(_ canvasView: PKCanvasView) {}
    func canvasViewDidEndUsingTool(_ canvasView: PKCanvasView) {}
    func canvasViewDidFinishRendering(_ canvasView: PKCanvasView) {}
}

func testPKCanvasViewDrawingState() {
    let view = PKCanvasView(frame: CGRect(x: 0, y: 0, width: 100, height: 80))
    pkExpectEqual(view.frame.width, 100, "frame")
    pkExpect(view.isDrawingEnabled, "enabled default")
    pkExpectEqual(view.drawingPolicy, .default, "policy")
    pkExpect(!view.isRulerActive, "ruler")
    pkExpectEqual(view.maximumSupportedContentVersion, .latest, "version")
    view.drawing = pkSampleDrawing()
    pkExpectEqual(view.drawing.strokes.count, 1, "drawing set")
    view.isDrawingEnabled = false
    pkExpect(!view.isDrawingEnabled, "disabled")
    _ = view.drawingGestureRecognizer
}

func testPKCanvasViewFingerDrawingPolicy() {
    let view = PKCanvasView(frame: .zero)
    view.drawingPolicy = .pencilOnly
    pkExpect(!view.allowsFingerDrawing, "pencil only")
    view.allowsFingerDrawing = true
    pkExpectEqual(view.drawingPolicy, .anyInput, "any input")
    view.allowsFingerDrawing = false
    pkExpectEqual(view.drawingPolicy, .pencilOnly, "back to pencil")
    view.drawingPolicy = .default
    pkExpect(view.allowsFingerDrawing, "default allows finger")
}

func testPKCanvasViewDelegateChange() {
    let view = PKCanvasView(frame: .zero)
    let probe = CanvasProbe()
    view.delegate = probe
    view.drawing = pkSampleDrawing()
    pkExpectEqual(probe.changes, 1, "didChange")
    probe.canvasViewDidBeginUsingTool(view)
    probe.canvasViewDidEndUsingTool(view)
    probe.canvasViewDidFinishRendering(view)
}

func testPKCanvasViewToolAndRuler() {
    let view = PKCanvasView(frame: .zero)
    view.tool = PKEraserTool(.vector)
    pkExpect((view.tool as? PKEraserTool)?.eraserType == .vector, "eraser tool")
    view.tool = PKLassoTool()
    pkExpect(view.tool is PKLassoTool, "lasso")
    view.isRulerActive = true
    pkExpect(view.isRulerActive, "ruler on")
}
