import PaperKit
import Foundation

final class PaperKitMarkupDelegate: PaperMarkupViewController.Delegate {
    var markupChanges = 0
    var selectionChanges = 0
    var beganDrawing = 0
    var frameChanges = 0

    func paperMarkupViewControllerDidChangeMarkup(_ paperMarkupViewController: PaperMarkupViewController) {
        markupChanges += 1
        _ = paperMarkupViewController
    }

    func paperMarkupViewControllerDidChangeSelection(_ paperMarkupViewController: PaperMarkupViewController) {
        selectionChanges += 1
        _ = paperMarkupViewController
    }

    func paperMarkupViewControllerDidBeginDrawing(_ paperMarkupViewController: PaperMarkupViewController) {
        beganDrawing += 1
        _ = paperMarkupViewController
    }

    func paperMarkupViewControllerDidChangeContentVisibleFrame(_ paperMarkupViewController: PaperMarkupViewController) {
        frameChanges += 1
        _ = paperMarkupViewController
    }
}

func testPaperMarkupViewControllerInit() {
    let markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 200, height: 100))
    let controller = PaperMarkupViewController(markup: markup, supportedFeatureSet: .latest)
    precondition(controller.markup == markup)
    precondition(controller.supportedFeatureSet == FeatureSet.latest)
    precondition(controller.contentVisibleFrame == markup.bounds)
}

func testPaperMarkupViewControllerNilMarkupDefault() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .empty)
    precondition(controller.markup == nil)
    precondition(controller.supportedFeatureSet == FeatureSet.empty)
}

func testPaperMarkupViewControllerEditableDefault() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(controller.isEditable)
    controller.isEditable = false
    precondition(!controller.isEditable)
}

func testPaperMarkupViewControllerDrawingToolDefault() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    let tool = controller.drawingTool as? PKInkingTool
    precondition(tool?.inkType == .pen)
    controller.drawingTool = PKInkingTool(.pencil)
    let updated = controller.drawingTool as? PKInkingTool
    precondition(updated?.inkType == .pencil)
}

func testPaperMarkupViewControllerTouchModeDefaults() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(controller.directTouchMode == .selection)
    precondition(controller.indirectPointerTouchMode == .selection)
    precondition(controller.directTouchAutomaticallyDraws)
    controller.directTouchMode = .drawing
    controller.indirectPointerTouchMode = .drawing
    controller.directTouchAutomaticallyDraws = false
    precondition(controller.directTouchMode == .drawing)
    precondition(controller.indirectPointerTouchMode == .drawing)
    precondition(!controller.directTouchAutomaticallyDraws)
}

func testPaperMarkupViewControllerTouchModeHashable() {
    precondition(PaperMarkupViewController.TouchMode.selection == .selection)
    precondition(PaperMarkupViewController.TouchMode.selection != .drawing)
    var hasher = Hasher()
    PaperMarkupViewController.TouchMode.drawing.hash(into: &hasher)
    _ = PaperMarkupViewController.TouchMode.selection.hashValue
}

func testPaperMarkupViewControllerScrollIndicators() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(controller.showsVerticalScrollIndicator)
    precondition(controller.showsHorizontalScrollIndicator)
    controller.showsVerticalScrollIndicator = false
    controller.showsHorizontalScrollIndicator = false
    precondition(!controller.showsVerticalScrollIndicator)
    precondition(!controller.showsHorizontalScrollIndicator)
}

func testPaperMarkupViewControllerZoomRangeDefault() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(controller.zoomRange == 1.0...1.0)
    controller.zoomRange = 0.5...4.0
    precondition(controller.zoomRange.lowerBound == 0.5)
    precondition(controller.zoomRange.upperBound == 4.0)
}

func testPaperMarkupViewControllerContentViewDefault() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(controller.contentView == nil)
    let view = UIView(frame: CGRect(x: 0, y: 0, width: 10, height: 10))
    controller.contentView = view
    precondition(controller.contentView === view)
}

func testPaperMarkupViewControllerFirstResponderAndUndo() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(controller.canBecomeFirstResponder)
    precondition(controller.undoManager != nil)
    controller.viewDidLoad()
    precondition(controller.undoManager != nil)
}

func testPaperMarkupViewControllerSelectedMarkup() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitMarkupDelegate()
    controller.delegate = delegate
    precondition(controller.selectedMarkup.bounds == .zero)
    controller.selectedMarkup = PaperMarkup(bounds: CGRect(x: 1, y: 1, width: 2, height: 2))
    precondition(delegate.selectionChanges >= 1)
    precondition(controller.delegate === delegate)
}

func testPaperMarkupViewControllerMarkupDidChange() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitMarkupDelegate()
    controller.delegate = delegate
    controller.markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 8, height: 8))
    precondition(delegate.markupChanges >= 1)
}

func testPaperMarkupViewControllerContentVisibleFrame() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitMarkupDelegate()
    controller.delegate = delegate
    let rect = CGRect(x: 4, y: 5, width: 6, height: 7)
    controller.setContentVisibleFrame(rect, animated: true)
    precondition(controller.contentVisibleFrame == rect)
    precondition(delegate.frameChanges >= 1)
    controller.contentVisibleFrame = CGRect(x: 1, y: 1, width: 2, height: 2)
    precondition(controller.contentVisibleFrame.width == 2)
}

func testPaperMarkupViewControllerSuggestedFrame() {
    let markup = PaperMarkup(bounds: CGRect(x: 0, y: 0, width: 200, height: 100))
    let controller = PaperMarkupViewController(markup: markup, supportedFeatureSet: .latest)
    let inserted = CGRect(x: 0, y: 0, width: 20, height: 10)
    let suggested = controller.suggestedFrameForInserting(contentInFrame: inserted)
    precondition(suggested.size == inserted.size)
    precondition(abs(suggested.midX - controller.contentVisibleFrame.midX) < 0.001)
}

func testPaperMarkupViewControllerRulerAndToolPicker() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    precondition(!controller.isRulerActive)
    let picker = PKToolPicker()
    picker.isRulerActive = true
    picker.selectedTool = PKInkingTool(.marker)
    controller.toolPickerIsRulerActiveDidChange(picker)
    controller.toolPickerSelectedToolItemDidChange(picker)
    precondition(controller.isRulerActive)
    let tool = controller.drawingTool as? PKInkingTool
    precondition(tool?.inkType == .marker)
}

func testPaperMarkupViewControllerDidBeginDrawingProtocol() {
    let controller = PaperMarkupViewController(supportedFeatureSet: .latest)
    let delegate = PaperKitMarkupDelegate()
    controller.delegate = delegate
    delegate.paperMarkupViewControllerDidBeginDrawing(controller)
    precondition(delegate.beganDrawing == 1)
}
